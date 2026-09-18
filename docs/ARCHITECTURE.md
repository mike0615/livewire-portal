# Architecture

## Overview
WordPress is the single front-end. Everything else is a backend service accessed via links, iframes, or APIs, all under one theme and one Kerberos session.

```
[User Browser] --Kerberos--> [HAProxy/Keepalived VIP] --GSSAPI--> [WordPress + Apache]
                                      |
                                      +--> [Prosody XMPP] (WebSocket/BOSH)
                                      +--> [Roundcube + Dovecot] (IMAP)
                                      +--> [File Storage] (Shared Files plugin)
                                      +--> [Other tools] (Nextcloud, Vault, etc.)
```

## Identity Flow
1. User logs into Windows (domain-joined) → Kerberos TGT.
2. Browser hits portal → SPNEGO Negotiate → Apache validates with keytab.
3. Apache sets REMOTE_USER → WordPress plugin creates/logs in user.
4. Same session used for embedded apps (if they support header auth) or re-auth via LDAP.

## Multi-Site
- Site A, B, C each have local XCP-ng pool + HAProxy VIP.
- Cross-site: DNS round-robin or health-checked failover to healthy VIP.
- Data: Galera for DB, Prosody clustering, mail replication.
- DR: XO continuous replication of VMs to remote pools.

## Theme Consistency
- Child theme defines CSS variables for colors, fonts, spacing.
- Converse.js theme uses same variables.
- Iframes load with `sandbox` + postMessage for height if needed.
- Shortcodes wrap all embeds so layout stays uniform.