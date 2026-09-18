# LiveWire Portal - Installation & Configuration Plan

Start tomorrow. Pull this repo, then follow phases in order.

## Phase 0: Prep (Day 0)
1. Clone repo on a jump host or first XCP-ng VM.
2. Ensure XCP-ng pool has shared storage (NFS/iSCSI/XOSTOR) for HA.
3. Enable HA on the pool: `xe pool-ha-enable heartbeat-sr-uuid=<sr-uuid>`
4. Set up Xen Orchestra (XOA) if not already running.
5. Create 3 VMs per site (or use containers where possible): one for web/proxy, one for DB, one for XMPP/mail.

## Phase 1: Identity & Kerberos (Day 1)
1. Deploy FreeIPA (or use existing AD) as the IdP. Enroll all XCP-ng hosts and service VMs as IPA clients.
2. Create service principals:
   - `HTTP/portal.example.com@REALM` for WordPress
   - `xmpp/xmpp.example.com@REALM` for Prosody
   - `imap/mail.example.com@REALM` for Roundcube/Dovecot
3. Generate keytabs and place in `/etc/krb5.keytab` (or service-specific).
4. Configure Apache `mod_auth_gssapi` (or `mod_auth_kerb`) on the WordPress VM:
   ```
   <Directory /var/www/html>
     AuthType GSSAPI
     AuthName "Kerberos SSO"
     GssapiCredStore keytab:/etc/krb5.keytab
     GssapiLocalName On
     Require valid-user
   </Directory>
   ```
5. Install WordPress plugin: LDAP Login for Intranet Sites + Kerberos/NTLM add-on.
6. Map LDAP groups to WP roles. Test auto-login from a domain-joined machine.

## Phase 2: WordPress Core + Theme (Day 1-2)
1. Install WordPress (single site or multisite if needed).
2. Install child theme `themes/livewire-child` (copy from repo).
3. Set colors, logo, fonts to match brand.
4. Create dashboard page with shortcodes for:
   - Tool links (cards)
   - File manager
   - Chat embed
   - Mail embed
5. Install plugins:
   - Shared Files or User Private Files (file sharing)
   - ConverseJS (XMPP embed)
   - Custom shortcode plugin for unified embeds

## Phase 3: XMPP Chat (Day 2)
1. Deploy Prosody (or ejabberd) on dedicated VM.
2. Enable `mod_auth_cyrus` + Cyrus SASL with GSSAPI, or `mod_auth_ldap`.
3. Configure BOSH/WebSocket on port 5280/5281.
4. Create MUC rooms for teams.
5. In WordPress, add Converse.js via shortcode or block. Theme it with CSS variables to match portal.
6. Test: login via Kerberos, open chat, send message.

## Phase 4: File Sharing (Day 2)
1. Install Shared Files plugin.
2. Configure upload directory outside web root if possible, or protected.
3. Set role-based access.
4. Add shortcode to dashboard.

## Phase 5: Webmail (Day 3)
1. Deploy Roundcube + Dovecot + Postfix (or use existing mail server).
2. Configure Dovecot for Kerberos/GSSAPI auth if possible, or LDAP.
3. Install Roundcube OIDC/Kerberos plugin if available; otherwise use REMOTE_USER from Apache.
4. Embed via iframe or custom shortcode in WordPress (full-height, themed).
5. Test read/send mail from portal.

## Phase 6: Reverse Proxy & HA (Day 3-4)
1. Deploy HAProxy + Keepalived on two VMs per site (or one active + standby).
2. Configure HAProxy to balance WordPress, Prosody, mail backends.
3. Use unicast keepalived for cross-subnet if needed (VRRP may not cross L2).
4. For 3 sites with different subnets: use DNS failover (multiple A records) + health checks, or a global load balancer / Cloudflare / external VIP.
5. XCP-ng: replicate VMs to remote pools via Xen Orchestra continuous replication for DR.
6. Test failover: kill one site's HAProxy, confirm traffic moves.

## Phase 7: Multi-Site & Load Balance (Day 4+)
1. Replicate DB (MariaDB Galera or primary-replica) across sites.
2. Replicate Prosody (cluster mode) and mail (if clustered).
3. Configure XO load-balancing plans across pools.
4. Monitor with Prometheus + Grafana (optional).

## Notes
- All configs are in `configs/`.
- Scripts in `scripts/` for automation.
- Test each phase before moving on.
- Keep a local admin fallback for WordPress in case SSO breaks.