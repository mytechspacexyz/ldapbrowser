# ldapbrowser

```
██╗     ██████╗  █████╗ ██████╗ ██████╗ ██████╗  ██████╗ ██╗    ██╗███████╗███████╗██████╗ 
██║     ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔════╝██╔══██╗
██║     ██║  ██║███████║██████╔╝██████╔╝██████╔╝██║   ██║██║ █╗ ██║███████╗█████╗  ██████╔╝
██║     ██║  ██║██╔══██║██╔═══╝ ██╔══██╗██╔══██╗██║   ██║██║███╗██║╚════██║██╔══╝  ██╔══██╗
███████╗██████╔╝██║  ██║██║     ██████╔╝██║  ██║╚██████╔╝╚███╔███╔╝███████║███████╗██║  ██║
╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚══════╝╚══════╝╚═╝  ╚═╝
```                                                                                           

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Shell](https://img.shields.io/badge/shell-bash-orange.svg)
![Version](https://img.shields.io/badge/version-1.0.0-informational.svg)
![LDAP](https://img.shields.io/badge/LDAP-AD%20%7C%20FreeIPA%20%7C%20OpenLDAP%20%7C%20JumpCloud%20%7C%20Foxpass-brightgreen.svg)
![Last Commit](https://img.shields.io/github/last-commit/mytechspacexyz/ldapbrowser?style=for-the-badge)

> **Pure bash+curl+fzf interactive LDAP/AD directory browser for the terminal.**
> No heavy GUI tools. No Java. No Python. No Go. Just bash+curl+fzf+core linux utils.

---

## Table of Contents

* [Demo](#-demo)
* [Why ldapbrowser?](#-why-ldapbrowser)
* [Features](#-features)
* [Known Limitations](#%EF%B8%8F-known-limitations)
* [Requirements](#-requirements)
* [Tested LDAP Directories](#-tested-ldap-directories)
* [Installation](#-installation)
* [Configuration](#%EF%B8%8F-configuration)
* [Usage](#-usage)
* [Navigation & Key Bindings](#-navigation--key-bindings)
* [Uninstallation](#%EF%B8%8F-uninstallation)
* [Architecture](#%EF%B8%8F-architecture)
* [QA Compatibility Matrix](#-qa-compatibility-matrix)
* [Disclaimer](#%EF%B8%8F-disclaimer)
* [License](#-license)
* [Acknowledgements](#-acknowledgements)

---

## 🎬 Demo

![ldapbrowser demo](assets/ldapbrowser-ad-view.gif)

---

## 🤔 Why ldapbrowser?

Browsing LDAP and Active Directory directories has always required heavy tools:
- Apache Directory Studio — Java, heavy, GUI only
- ldap-utils — raw, no UX, hard to navigate large trees
- Web UIs — not always accessible, especially on jump servers

**ldapbrowser fills that gap** — a pure bash+curl+fzf interactive browser that works on any terminal, including jump servers where a browser is not an option.

Zero dependencies beyond what every Linux system already has.

---

## ✨ Features

- 🌳 **Interactive tree browsing** — navigate any LDAP directory tree with fzf
- 🔍 **Object inspection** — view full details of any LDAP object
- 💾 **Snapshot to file** — save object details to file with `Ctrl+S`
- 🎨 **Themes** — customizable terminal UI themes
- 🔐 **Secure** — FQDN + CA certificate validation, no insecure connections
- 🔄 **Replication aware** — supports multiple LDAP hosts in replication setup
- 🤖 **Auto-detection** — LDAP suffix deduced automatically during setup

---

## ⚠️ Known Limitations

- **No LDAP write operations** — ldapbrowser is a read-only tool by design.
                                 Creating, modifying or deleting LDAP objects is not supported.
                                 This is an intentional architectural decision based on the zero-dependency philosophy, 
                                 curl supports LDAP read queries only.

---

## 📋 Requirements

- `bash` 4.x or higher
- `curl` with LDAP support
- `fzf` 0.30+
- FQDN hostname for LDAP host(s) — **no IP addresses**
- Valid certificate issued by internal or external CA
- Valid CA(s) certificate(s) to add to the configuration while setting up
- DNS resolution for the FQDN(s)

---

## 🧪 Tested LDAP Directories

| Directory | Version | Status |
|---|---|---|
| Microsoft Active Directory | 2019, 2022 | ✅ Tested |
| FreeIPA | 4.x | ✅ Tested |
| OpenLDAP | 2.x | ✅ Tested |
| JumpCloud LDAP | Cloud | ✅ Tested |
| Foxpass | Cloud | ✅ Tested |

---

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/mytechspacexyz/ldapbrowser.git

# Add ldapbrowser to PATH via symlink in a folder already in PATH
cd ~/bin; ln -s <ldapbrowser folder>/ldapbrowser ldapbrowser

# Add autocompletion (optional but recommended)
# Add the following to your ~/.bashrc or similar and restart the shell:
_ldapbrowser_completion() {
    local cur prev commands debug_options
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="version describe setup debug themes list help"
    debugopts="on off"

    case "${prev}" in
        ldapbrowser)
            COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
            return 0
            ;;
        debug)
            COMPREPLY=($(compgen -W "${debugopts}" -- "${cur}"))
            return 0
            ;;
        *)
            ;;
    esac
}
complete -F _ldapbrowser_completion ldapbrowser

# Run setup
ldapbrowser setup
```

---

## ⚙️ Configuration

```bash
During `ldapbrowser setup` you will be prompted for:

- LDAP host FQDN(s) — single host or multiple for replication
- Bind DN username — recommeded read-only LDAP administrator account
                     because the ldapbrowser doesn't support LDAP write operations
- Bind DN password — stored as
- LDAP suffix — entered manually or can be deduced automatically
- CA certificate path

Pay SPECIAL attention to the CA certificate(s) that has to be included (and will be copied to the conf folder)
while running 'ldapbrowser setup'.
It is best to issue before any setup such a certificate for you LDAP host(s)/cluster with its FQDN using your internal/external CA
or create a self-signed one as the ldapbrowser is built with curl secure flags to require the CA certificate for a session.
No IP address will be good for this setup.

All configuration is stored inside the ldapbrowser conf folder — nothing written outside the app directory.

For more details see the short video below
```

![ldapbrowser setup](assets/ldapbrowser-ad-setup.gif)

---

## 💻 Usage

```bash
ldapbrowser setup      # configure your LDAP connection
ldapbrowser list       # interactively browse the directory tree
ldapbrowser describe   # show ldapbrowser description information
ldapbrowser themes     # customize the interface
ldapbrowser debug on   # enable debug logging
ldapbrowser debug off  # disable debug logging
ldapbrowser version    # show version
ldapbrowser help       # show usage
```

---

## 🧭 Navigation & Key Bindings

### fzf Navigation
| Key | Action |
|---|---|
| `↑` / `↓` | Move up/down in the list |
| `Shift+↑` / `Shift+↓` | Scroll the preview window |
| `Enter` | Enter object like DN and show its children |
| `Ctrl+S` | Snapshot object details to file in app folder |
| `Esc` / `Ctrl+C` | Exit |

---

## 🗑️ Uninstallation

```bash
# Remove the symlink from PATH
unlink <path to the ldapbrowser symlink>

# Remove bash completion (if added)
# Edit ~/.bashrc or similar and remove:
# - the _ldapbrowser_completion() function block
# - the complete -F _ldapbrowser_completion ldapbrowser line
# Then restart the shell:
exec $SHELL

# Remove the cloned repository
rm -rf <ldapbrowser folder>
```

---

## 🏗️ Architecture

```
ldapbrowser/
├── ldapbrowser.bash         # main entry point
├── ldapbrowser              # symlink → ldapbrowser.bash
├── conf/                    # configuration
│   ├── .common_configvars
│   ├── .configvars
│   └── .deps
├── src/                     # source functions
├── docs/                    # description, help, version
├── data/                    # runtime data like snapshots
├── logs/                    # debug logs
└── examples/                # configuration examples
```
---

## 🧪 QA Compatibility Matrix

| Directory | Browse | Snapshot |
|---|---|---|
| Active Directory | ✅ | ✅ |
| FreeIPA | ✅ | ✅ |
| OpenLDAP | ✅ | ✅ |
| JumpCloud | ✅ | ✅ |
| Foxpass | ✅ | ✅ |

---

## ⚠️ Disclaimer

ldapbrowser is provided as-is. Always test in a non-production environment first. The author is not responsible for any issues arising from use in production environments.

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements
- [fzf](https://github.com/junegunn/fzf) — the fuzzy finder that powers the entire UX
- [curl](https://curl.se) — the curl utility that is the engine
- Some LDAP documentation that makes it all easier and possible:
    - [LDAP for Rocket Scientists](https://www.zytrax.com/books/ldap/)
    - [JumpCloud: Get Started: Cloud LDAP](https://jumpcloud.com/support/use-cloud-ldap)
    - [JumpCloud: Connect to Cloud LDAP with TLS/SSL](https://jumpcloud.com/support/connect-to-ldap-with-tls-ssl)
    - [FoxPass: LDAP Overview & Debugging](https://docs.foxpass.com/docs/ldap-overview-debugging)

- The devops/sysadmin community, MSPs and homelabbers for the inspiration

---

<div align="center">

**Built with ❤️  for MSPs, DevOps, sysadmins and homelabbers who live in the terminal**

[![GitHub stars](https://img.shields.io/github/stars/mytechspacexyz/ldapbrowser?style=social)](https://github.com/mytechspacexyz/ldapbrowser)

</div>
