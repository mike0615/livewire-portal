# LiveWire Portal — Go-Live Checklist

Single source of truth for taking the portal from repo to production. Work top to bottom. Do not skip the security items.

---

## 0. Pre-flight (do this first)

- [ ] **Rotate the Keepalived password.** The example config ships `auth_pass livewire2024`. Generate a strong random value, put it only in the real config files on the servers, and remove it from the repo.
- [ ] **Remove the basic-auth fallback** from `configs/apache/kerberos-wordpress.conf`. Keep pure GSSAPI. Add `GssapiSSLonly On` and `GssapiNegotiateOnce On`.
- [ ] Replace every `example.com` / placeholder domain with your real FQDNs (portal, xmpp, mail).
- [ ] Confirm DNS: A/AAAA records for portal, xmpp, mail, plus SRV records for `_xmpp-client`, `_xmpp-server`, `_kerberos`, `_kpasswd`.
- [ ] Confirm NTP is synced on every host (Kerberos is time-sensitive).
- [ ] Confirm all XCP-ng hosts have **static IPs** and a bonded management interface.

---

## 1. Identity — FreeIPA (or AD)

- [ ] FreeIPA deployed and reachable from all three sites.
- [ ] All XCP-ng hosts and service VMs enrolled as IPA clients (`ipa-client-install`).
- [ ] Service principals created:
  - `HTTP/portal.<domain>@REALM`
  - `xmpp/xmpp.<domain>@REALM`
  - `imap/mail.<domain>@REALM`
- [ ] Keytabs generated and placed in `/etc/krb5.keytab` (or service-specific paths), mode `0600`, owned by the service user.
- [ ] `krb5.conf` distributed with correct `auth_to_local` rules so principals map to local usernames.
- [ ] Test: `kinit` as a domain user from a client, then `kvno HTTP/portal.<domain>` succeeds.

---

## 2. Apache + WordPress front-end

- [ ] `mod_auth_gssapi` installed (not the legacy `mod_auth_kerb`).
- [ ] Hardened config applied: `GssapiCredStore`, `GssapiLocalName On`, `GssapiSSLonly On`, `GssapiNegotiateOnce On`, `Require valid-user`.
- [ ] TLS cert installed (Let's Encrypt or internal CA) and referenced in HAProxy.
- [ ] WordPress installed (single site is fine to start).
- [ ] Child theme `livewire-child` activated; brand colors/logo set in `style.css`.
- [ ] **LDAP Login for Intranet Sites** plugin installed + Kerberos/NTLM add-on.
- [ ] LDAP groups mapped to WP roles.
- [ ] Custom `livewire-shortcodes` plugin installed; dashboard shortcode renders real tool cards from `tools.json` (data-driven).
- [ ] Local admin fallback account created and password stored in a password manager (in case SSO breaks).
- [ ] Test: domain-joined browser hits portal → silent SSO → lands on dashboard. Non-domain browser gets a clean failure, not a password prompt.

---

## 3. XMPP Chat (Prosody + Converse.js)

- [ ] Prosody installed on dedicated VM.
- [ ] `lua-cyrussasl` installed; `authentication = "cyrus"`, `cyrus_service_name = "xmpp"`.
- [ ] Cyrus SASL config (`/etc/sasl2/prosody.conf` or `/etc/sasl/prosody.conf`) points at saslauthd with `pwcheck_method: saslauthd`, `mech_list: GSSAPI`.
- [ ] BOSH on 5280, WebSocket on 5281, both behind TLS.
- [ ] MUC component enabled; default rooms created for teams.
- [ ] Converse.js themed with the same CSS variables as the portal.
- [ ] Test: log in via Kerberos, open chat, send a message, confirm roster syncs.

---

## 4. Webmail (Roundcube + Dovecot)

- [ ] Dovecot + Postfix (or existing mail infra) deployed.
- [ ] Dovecot configured for GSSAPI/Kerberos auth (or LDAP fallback).
- [ ] Roundcube `krb_authentication` plugin installed and enabled.
- [ ] IMAP GSSAPI works; SMTP GSSAPI is the known weak point — test send, and if it fails, configure a SASL proxy or accept password-for-send as a temporary measure. See `docs/SMTP_GSSAPI_WORKAROUND.md`.
- [ ] Embed via the `livewire_mail` shortcode, full-height, themed.
- [ ] Test: read and send mail entirely from inside the portal.

---

## 5. File Sharing

- [ ] Shared Files (or User Private Files) plugin installed.
- [ ] Upload directory outside web root or protected by Apache rules.
- [ ] Role-based access configured.
- [ ] Shortcode on dashboard works.
- [ ] Test: upload, share link, download as another user.

---

## 6. HAProxy + Keepalived (per site)

- [ ] HAProxy installed; config uses real certs, real backend IPs, `option httpchk` against a real health endpoint (not `/wp-login.php`).
- [ ] `X-Forwarded-Proto`, `X-Real-IP`, and `X-Forwarded-For` set correctly.
- [ ] Keepalived uses the **rotated** password; unicast peers set for cross-subnet if needed.
- [ ] Prefer DNS health-checked failover (or an external LB) for the global VIP across the three sites — do not rely on unicast VRRP across L3 boundaries as the primary mechanism.
- [ ] Test: stop HAProxy on site A → traffic moves to site B within seconds. Kill a backend → it drops out of rotation.

---

## 7. Multi-site data layer

- [ ] MariaDB Galera cluster: odd number of nodes (3 recommended), one per site or 2+1. Bootstrap the first node with `--wsrep-new-cluster`.
- [ ] `wsrep_cluster_address`, `wsrep_node_name`, `wsrep_node_address` set correctly on every node.
- [ ] Quorum and bootstrap procedure documented — see `docs/GALERA_BOOTSTRAP.md`.
- [ ] Prosody cluster mode (or federation) configured if you need shared MUC across sites.
- [ ] Mail replication configured (Dovecot replication or shared mailbox backend).
- [ ] Test: write on site A, read on site B; kill a Galera node → cluster stays quorate.

---

## 8. XCP-ng HA & DR

- [ ] Shared storage (NFS/iSCSI/XOSTOR) ≥ 4 GiB for the heartbeat SR on every pool.
- [ ] `xe pool-ha-enable heartbeat-sr-uuid=<uuid>` run on each pool.
- [ ] All portal VMs have disks on shared storage (agile for HA).
- [ ] Xen Orchestra continuous replication to remote pools for DR.
- [ ] Test: kill a host → VMs restart on another host in the pool. Kill a whole site → XO replication + DNS failover keeps the portal up.

---

## 9. Monitoring, backups, logging

- [ ] Prometheus + Grafana (or at least node_exporter + a dashboard) scraping Apache, Prosody, HAProxy, MariaDB, XCP-ng.
- [ ] Alerts wired to email/Slack for: HAProxy backend down, Galera lost quorum, Prosody down, disk > 80%, replication lag.
- [ ] Automated backups: MariaDB dumps (or Galera SST), Prosody data dir, WordPress uploads + DB, config files. Test a restore.
- [ ] Centralized logs (or at least `journalctl` + logrotate) for httpd, prosody, haproxy, dovecot.
- [ ] Document the restore runbook.

---

## 10. Security hardening (final pass)

- [ ] Firewall: only 80/443 public; 5280/5281, 993, 3306, 4567 restricted to internal networks.
- [ ] `fail2ban` or equivalent on the Apache host (even with Kerberos, to catch brute-force on the fallback).
- [ ] SELinux/AppArmor in enforcing mode; contexts correct for keytabs and web roots.
- [ ] Secrets (keytabs, DB passwords, Keepalived password) in a vault or at least mode `0600`, never in git.
- [ ] TLS everywhere: portal, BOSH, WebSocket, IMAP, SMTP.
- [ ] Review Apache `AllowOverride` and directory permissions.

---

## 11. Cutover

- [ ] Announce maintenance window.
- [ ] Confirm Keepalived/HAProxy on each node already have **rotated** secrets (do **not** run `APPLY_LB=1` over live files).
- [ ] Rolling deploy, secondary sites first, VIP site last:
  - Per node: `REF=<tag-or-main> ./scripts/deploy.sh` (Apache + Prosody; LB left untouched by default).
  - Smoke that node: SSO → dashboard → chat → mail → files → one tool link.
- [ ] Full-path smoke through the VIP.
- [ ] Failover test one more time under light load.
- [ ] Hand the stakeholder deck (now in `docs/stakeholder-presentations/`) to leadership.
- [ ] Go live. Monitor for 24–48 hours.

---

## Known gaps

### Still open (Phase A / right after go-live)

1. **SMTP GSSAPI in Roundcube** is incomplete upstream — plan a SASL proxy or a temporary password-for-send path. See `docs/SMTP_GSSAPI_WORKAROUND.md`.
2. **No IaC** — Ansible or Terraform for the three sites so rebuilds are reproducible. **Phase B+ backlog; not a Phase A blocker.**

### Closed in repo (verify on servers at cutover)

- ~~Dashboard placeholder-driven~~ — `plugins/livewire-shortcodes/tools.json` is data-driven.
- ~~Deploy script swallowed errors~~ — `scripts/deploy.sh` uses `set -euo pipefail`, per-service steps, configtests, and refuses to overwrite live Keepalived/HAProxy by default.
- ~~No Galera total-outage runbook~~ — see `docs/GALERA_BOOTSTRAP.md`.
