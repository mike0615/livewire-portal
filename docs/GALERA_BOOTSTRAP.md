# Galera Bootstrap Runbook

Use this when the Galera cluster is down or after a total outage. Goal: get a clean, quorate cluster back without split-brain.

## Prerequisites
- Odd number of nodes (3 recommended, one per site).
- `wsrep_cluster_address`, `wsrep_node_name`, `wsrep_node_address` set correctly on every node.
- SSH access to all DB nodes.
- A known-good backup (SST or logical dump) available.

## Steps

1. **Stop MariaDB on ALL nodes.**
   ```bash
   sudo systemctl stop mariadb   # or: galera_recovery on each
   ```
   Confirm nothing is listening on 3306 / 4567.

2. **Pick the bootstrap node.** Choose the node with the most recent, consistent data (check `grastate.dat` `seqno` if present).

3. **Bootstrap that node.**
   ```bash
   sudo galera_new_cluster
   # or: sudo systemctl start mariadb --wsrep-new-cluster
   ```
   Verify: `SHOW STATUS LIKE 'wsrep_ready';` → `ON`, `wsrep_cluster_size` = 1.

4. **Start the other nodes one at a time.**
   ```bash
   sudo systemctl start mariadb
   ```
   Each should join: `wsrep_ready=ON`, `wsrep_cluster_size` increments.

5. **Verify quorum.**
   ```sql
   SHOW STATUS LIKE 'wsrep_ready';
   SHOW STATUS LIKE 'wsrep_cluster_size';
   SHOW STATUS LIKE 'wsrep_connected';
   ```
   All must be ON / full size.

6. **If a node has diverged state**, do not start it. SST it from a healthy node:
   ```bash
   sudo galera_recovery   # inspect
   # then force SST: set wsrep_recover=ON, or wipe datadir and let it SST
   ```

## After recovery
- Run a test write on site A, read on site B.
- Confirm backups are still running.
- Document what caused the outage.

## Never
- Bootstrap more than one node at a time.
- Start nodes in parallel during recovery.
- Ignore `wsrep_ready=OFF` — investigate before adding load.