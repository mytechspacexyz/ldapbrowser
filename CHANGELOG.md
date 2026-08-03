# Changelog
All notable changes to **ldapbrowser** will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.0] - 2026-08-03

### Added

#### TLS Support
- **LDAPS support** — added alongside existing StartTLS via `LDAP_TLS_MODE` configuration variable — both TLS modes now fully supported

#### New LDAP Directory Support
- **389 DS 3.1.2** — Red Hat/IBM enterprise directory server (StartTLS + LDAPS)
- **OpenDJ 5.1.1** — Open Identity Platform directory server (StartTLS + LDAPS)
- **ApacheDS 2.0.0.AM26** — Apache Directory Server (StartTLS + LDAPS)
- **OneLogin VLDAP** — cloud LDAP interface (LDAPS only, StartTLS N/A)
- **Okta LDAP** — cloud LDAP interface (StartTLS + LDAPS)
- **JumpCloud** — expanded with LDAPS coverage (previously StartTLS only)
- **FoxPass** — expanded with LDAPS coverage (previously StartTLS only)
- **AD/IPA/OpenLDAP** — expanded with full LDAPS coverage

#### New Commands
- `ldapbrowser completion` — outputs bash completion script to stdout for easy installation:
```bash
  # Per user
  ldapbrowser completion >> ~/.bashrc
  exec $SHELL
  # System-wide
  ldapbrowser completion > /etc/bash_completion.d/ldapbrowser
```

#### Setup Subcommands
- `ldapbrowser setup reset` — reset ldapbrowser configuration to defaults
- `ldapbrowser setup backup` — backup current ldapbrowser configuration
- `ldapbrowser setup restore` — restore ldapbrowser configuration from backup

#### Runtime Checks
- **Bash 4.4+ version guard** — ldapbrowser now checks and enforces minimum bash version (4.4+) on startup

### Fixed
- **`.configvars` corruption on repeated `setup` runs** — CACERT path was being doubled on each successive `setup` run due to missing guard. Fixed by blocking re-run when configuration already exists, preventing path duplication and config corruption.

### Compatibility
- ldapbrowser now tested against **10 LDAP directory implementations** across both StartTLS and LDAPS:

| Directory | Version | StartTLS | LDAPS | Notes |
|---|---|---|---|---|
| Microsoft Active Directory | 2019-2022 | ✅ | ✅ | |
| FreeIPA | 4.x | ✅ | ✅ | |
| OpenLDAP | 2.6.x | ✅ | ✅ | |
| 389 DS | 3.1.2 | ✅ | ✅ | |
| OpenDJ | 5.1.1 | ✅ | ✅ | |
| ApacheDS | 2.0.0.AM26 | ✅ | ✅ | |
| Okta LDAP | Cloud | ✅ | ✅ | Push MFA confirmed to trigger per-query push notification |
| OneLogin VLDAP | Cloud | N/A | ✅ | Push MFA may trigger per-query push notification |
| JumpCloud | Cloud | ✅ | ✅ | Push MFA may trigger per-query push notification |
| FoxPass | Cloud | ✅ | ✅ | Push MFA may trigger per-query push notification |

---

### Known Limitations
- No LDAP write operations — read-only by design.
- OneLogin VLDAP does not support StartTLS — LDAPS only
- Cloud LDAP directories (Okta, OneLogin VLDAP, JumpCloud, FoxPass) with push-based MFA enabled on the bind account will trigger a push notification per LDAP query — functionally correct but tedious for interactive browsing. Recommendation: use a dedicated service/bind/read-only-admin account with MFA disabled.

---

## [1.0.0] - 2026-06-01

### Added

#### LDAP browsing
- `list` — interactive fzf-powered LDAP browsing with LDAP object preview panel

#### Core Features
- Interactive `fzf`-powered LDAP directory view throughout with detailed preview panels
- Selectable fzf UI themes via `ldapbrowser themes`
- Detailed debug/info/error/warning logging via `ldapbrowser debug on/off`
- Interactive setup wizard via `ldapbrowser setup`
- Built-in help via `ldapbrowser help`
- Built-in description via `ldapbrowser describe`
- Bash autocompletion support

#### Key Bindings
- `Enter` — enter object like DN and show its children
- `Ctrl+S` — snapshot object details to file in app folder
- `Shift+↑` / `Shift+↓` — scroll the fzf preview window
- `Esc` — exit

#### Compatibility
- Tested on AD/LDAP directories: AD 2019/2022, IPA 4.x, OpenLDAP 2.x, JumpCloud Cloud LDAP, FoxPass Cloud LDAP

---

### Known Limitations
- No LDAP write operations — read-only by design

---

## Links
- [ldapbrowser on GitHub](https://github.com/mytechspacexyz/ldapbrowser)
- [Report a bug](https://github.com/mytechspacexyz/ldapbrowser/issues)
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
