# SMTP GSSAPI Workaround for Roundcube

Upstream Roundcube's `krb_authentication` plugin supports IMAP GSSAPI but SMTP GSSAPI is incomplete. Sending mail via Kerberos often fails with auth errors.

## Temporary measure (acceptable for go-live)
1. Keep IMAP on GSSAPI (read works).
2. For send, configure a SASL proxy (e.g. `saslauthd` with GSSAPI mech, or `msmtp`/`nullmailer` pointed at an internal relay that accepts the Kerberos ticket).
3. Or accept a password-for-send path for a small set of service accounts, stored in a vault — not in the repo.

## Proper fix (post go-live)
- Deploy a small SMTP submission proxy that:
  - Accepts the user's Kerberos ticket via Apache/mod_auth_gssapi on port 587.
  - Forwards to Dovecot/Postfix using the ticket (GSSAPI) or a service principal.
- Point Roundcube's SMTP at the proxy.
- Remove the password fallback.

## Checklist item
- [ ] Proxy deployed and tested end-to-end (compose → send → receive).
- [ ] Password fallback removed from production config.
- [ ] Documented in the restore runbook.