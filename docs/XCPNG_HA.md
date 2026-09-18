# XCP-ng Multi-Site HA & Failover

## Per-Site Pool
- 3+ hosts recommended per pool for HA.
- Shared storage (NFS, iSCSI, or XOSTOR) required for HA.
- Enable: `xe pool-ha-enable heartbeat-sr-uuid=<uuid>`
- Load balancing: Xen Orchestra plugin, plans in performance/density/mixed mode.

## Cross-Site
XCP-ng HA is pool-local only. For 3 locations with different subnets:
1. **VM Replication**: Xen Orchestra continuous replication to remote pools (async, for DR).
2. **Application-level HA**: HAProxy + Keepalived per site; DNS failover or external LB for global VIP.
3. **Database**: Galera cluster or primary + async replicas across sites.
4. **XMPP**: Prosody cluster (mod_cluster) or separate instances with shared MUC via federation.
5. **Mail**: Dovecot replication or shared mailbox backend.

## Keepalived Cross-Subnet
VRRP is L2. For different subnets use unicast:
```
unicast_src_ip 10.1.1.10
unicast_peer {
  10.2.1.10
  10.3.1.10
}
```
Or use a higher-level DNS/health-check failover.

## Testing
- Kill a host → HA restarts VMs on another host in pool.
- Kill a site's HAProxy → DNS or LB routes to another site.
- Kill a DB node → Galera continues.