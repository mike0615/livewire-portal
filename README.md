# LiveWire Portal

Unified enterprise portal running on WordPress as the front-end.

## Features
- Kerberos / SPNEGO SSO (FreeIPA or AD)
- Embedded XMPP chat (Converse.js + Prosody)
- File sharing & upload/download
- Webmail (Roundcube) embed
- Links to all tools with consistent theme
- Multi-site HA: 3 locations, different subnets, load balance + failover
- Runs on XCP-ng pool with Xen Orchestra

## Quick Start
See `docs/INSTALL_PLAN.md` for the full phased plan.

## Directory Layout
```
livewire-portal/
├── README.md
├── docs/
│   ├── INSTALL_PLAN.md
│   ├── ARCHITECTURE.md
│   └── XCPNG_HA.md
├── configs/
│   ├── apache/
│   ├── nginx/
│   ├── haproxy/
│   ├── keepalived/
│   ├── prosody/
│   ├── roundcube/
│   └── wordpress/
├── themes/
│   └── livewire-child/
├── plugins/
│   └── (custom shortcodes)
├── scripts/
│   └── deploy.sh
└── docker/
    └── (optional compose files)
```

## License
MIT