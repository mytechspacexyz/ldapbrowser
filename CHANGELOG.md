# Changelog

All notable changes to **ldapbrowser** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-05-2x

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
