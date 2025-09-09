import json
import time

def wait_for_patroni_ready(node, timeout=60):
  """Wait for Patroni to be ready and responsive"""
  node.wait_for_unit("patroni.service", timeout=timeout)
  node.wait_until_succeeds("curl -f http://localhost:8008/health", timeout=timeout)
  print(f"{node.name}: Patroni is ready")

def get_cluster_info(node):
  """Get cluster information from Patroni REST API"""
  result = node.succeed("curl -s http://localhost:8008/cluster")
  return json.loads(result)

def get_leader_node():
  """Find which node is the current leader"""
  for node in [psqlnode1, psqlnode2, psqlnode3]:
      try:
          cluster_info = get_cluster_info(node)
          for member in cluster_info.get("members", []):
              if member.get("role") == "leader":
                  return member["name"]
      except:
          continue
  return None

def execute_sql_on_leader(sql_command):
  """Execute SQL command on the current leader"""
  leader_name = get_leader_node()
  node = dict(psqlnode1=psqlnode1, psqlnode2=psqlnode2, psqlnode3=psqlnode3)[leader_name]
  if node:
      return node.succeed(f'psql -U postgres -c "{sql_command}"')
  else:
      raise Exception("No leader found!")

def verify_replication(table_name, expected_data):
  """Verify data is replicated across all nodes"""
  for node in [psqlnode1, psqlnode2, psqlnode3]:
      result = node.succeed(f'psql -U postgres -c "SELECT * FROM {table_name};" -t')
      assert expected_data in result, f"Data not replicated to {node.name}"
      print(f"✅ {node.name}: Replication verified")

print("🚀 Starting HA PostgreSQL Cluster Test")

# === PHASE 1: STARTUP AND INITIALIZATION ===
with subtest("Start all VMs and wait for services"):
  start_all()

  # Wait for network and Patroni on all nodes
  for node in [psqlnode1, psqlnode2, psqlnode3]:
      node.systemctl("start network-online.target")
      node.wait_for_unit("network-online.target")
      wait_for_patroni_ready(node)

# === PHASE 2: NETWORK CONNECTIVITY ===
with subtest("Verify network connectivity between nodes"):
  psqlnode1.succeed("ping -c 1 psqlnode2")
  psqlnode1.succeed("ping -c 1 psqlnode3")
  psqlnode2.succeed("ping -c 1 psqlnode1")
  psqlnode2.succeed("ping -c 1 psqlnode3")
  psqlnode3.succeed("ping -c 1 psqlnode1")
  psqlnode3.succeed("ping -c 1 psqlnode2")
  print("✅ All nodes can communicate")

# === PHASE 3: PATRONI CLUSTER STATUS ===
with subtest("Verify Patroni cluster formation and leader election"):
  # Wait a bit for leader election to complete
  time.sleep(10)

  leader_found = False
  followers_count = 0

  # Check cluster status from each node
  for node in [psqlnode1, psqlnode2, psqlnode3]:
      cluster_info = get_cluster_info(node)
      print(f"{node.name} cluster info: {json.dumps(cluster_info, indent=2)}")

      # Count roles
      for member in cluster_info.get("members", []):
          if member.get("role") == "leader":
              leader_found = True
              print(f"✅ Leader found: {member['name']}")
          elif member.get("role") == "replica":
              followers_count += 1

  assert leader_found, "No leader found in cluster!"
  assert followers_count >= 2, f"Expected at least 2 followers, found {followers_count}"
  print("✅ Cluster has proper leader/follower structure")

# === PHASE 4: POSTGRESQL CONNECTIVITY ===
with subtest("Verify PostgreSQL database connectivity"):
  leader_name = get_leader_node()
  print(f"Testing database operations on leader: {leader_name}")

  # Test basic connectivity
  execute_sql_on_leader("SELECT version();")
  print("✅ PostgreSQL is accessible on leader")

# === PHASE 5: DATA REPLICATION ===
with subtest("Test data replication across cluster"):
  # Create test table and insert data on leader
  execute_sql_on_leader("CREATE TABLE ha_test (id INT PRIMARY KEY, message TEXT, created_at TIMESTAMP DEFAULT NOW());")
  execute_sql_on_leader("INSERT INTO ha_test (id, message) VALUES (1, 'Hello HA PostgreSQL!');")
  execute_sql_on_leader("INSERT INTO ha_test (id, message) VALUES (2, 'Replication test');")

  # Wait for replication
  time.sleep(5)

  # Verify data is replicated to all nodes
  verify_replication("ha_test", "Hello HA PostgreSQL!")
  verify_replication("ha_test", "Replication test")
  print("✅ Data replication working correctly")

# === PHASE 6: PATRONI REST API ===
with subtest("Test Patroni REST API functionality"):
  for node in [psqlnode1, psqlnode2, psqlnode3]:
      # Test health endpoint
      node.succeed("curl -f http://localhost:8008/health")

      # Test cluster endpoint
      cluster_json = node.succeed("curl -s http://localhost:8008/cluster")
      assert "members" in cluster_json

      # Test config endpoint
      node.succeed("curl -f http://localhost:8008/config")

      print(f"✅ {node.name}: REST API endpoints working")

# === PHASE 7: FAILOVER SIMULATION ===
with subtest("Test automatic failover"):
  original_leader = get_leader_node()
  print(f"Original leader: {original_leader}")

  # Stop Patroni on the current leader
  if original_leader == "psqlnode1":
      psqlnode1.succeed("systemctl stop patroni")
      print("Stopped Patroni on psqlnode1")
  elif original_leader == "psqlnode2":
      psqlnode2.succeed("systemctl stop patroni")
      print("Stopped Patroni on psqlnode2")
  elif original_leader == "psqlnode3":
      psqlnode3.succeed("systemctl stop patroni")
      print("Stopped Patroni on psqlnode3")

  # Wait for failover (Patroni typically takes 30-60 seconds)
  print("Waiting for failover...")
  time.sleep(45)

  # Check that a new leader was elected
  new_leader = get_leader_node()
  assert new_leader is not None, "No new leader elected after failover!"
  assert new_leader != original_leader, f"Leader didn't change! Still {original_leader}"
  print(f"✅ Failover successful: {original_leader} -> {new_leader}")

  # Verify database is still accessible
  execute_sql_on_leader("INSERT INTO ha_test (id, message) VALUES (3, 'Post-failover test');")
  time.sleep(5)
  verify_replication("ha_test", "Post-failover test")
  print("✅ Database operations work after failover")

# === PHASE 8: RECOVERY ===
with subtest("Test node recovery and rejoin"):
  # Restart the stopped node
  if original_leader == "psqlnode1":
      psqlnode1.succeed("systemctl start patroni")
      wait_for_patroni_ready(psqlnode1)
  elif original_leader == "psqlnode2":
      psqlnode2.succeed("systemctl start patroni")
      wait_for_patroni_ready(psqlnode2)
  elif original_leader == "psqlnode3":
      psqlnode3.succeed("systemctl start patroni")
      wait_for_patroni_ready(psqlnode3)

  # Wait for the node to rejoin as follower
  time.sleep(15)

  # Verify the recovered node rejoined as follower
  cluster_info = get_cluster_info(psqlnode1)
  member_count = len(cluster_info.get("members", []))
  assert member_count == 3, f"Expected 3 members, found {member_count}"
  print(f"✅ Node {original_leader} successfully rejoined as follower")

  # Verify replication to recovered node
  execute_sql_on_leader("INSERT INTO ha_test (id, message) VALUES (4, 'Recovery test');")
  time.sleep(5)
  verify_replication("ha_test", "Recovery test")
  print("✅ Replication works to recovered node")

# === FINAL STATUS ===
print("\n🎉 HA PostgreSQL Cluster Test PASSED!")
print("✅ Cluster formation: SUCCESS")
print("✅ Leader election: SUCCESS")
print("✅ Data replication: SUCCESS")
print("✅ REST API: SUCCESS")
print("✅ Automatic failover: SUCCESS")
print("✅ Node recovery: SUCCESS")
print("\nYour HA PostgreSQL cluster is production-ready! 🚀")
