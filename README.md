# EDYOU OS – Open-Source School Linux

[![GPL licensed](https://img.shields.io/badge/license-GPL-blue.svg)](https://github.com/EDYOU-Systems/EDYOU-OS/blob/main/LICENSE)
[![Discussions](https://img.shields.io/badge/discussions-join-blue)](https://github.com/EDYOU-Systems/EDYOU-OS/discussions)
[![Website Status](https://img.shields.io/website?url=https%3A%2F%2Fedyou-os.vercel.app%2F)](https://edyou-os.vercel.app/)
[![Latest Version](https://img.shields.io/badge/version-v1.0.0-red)](https://edyou-os.vercel.app/#download)

EDYOU OS is a school-first Linux distribution built for learners and educators. It blends Ubuntu LTS reliability with a polished, user-friendly desktop and a strong privacy focus.

Learn more at the official site: [EDYOU OS Website](https://edyou-os.vercel.app/)

![EDYOU OS Screenshot](Image.png)

---

## Highlights

- **Open-source and customizable** — change and redistribute freely.
- **Privacy-first** — no unnecessary telemetry.
- **Student-focused** — easy-to-use layout with preloaded educational software.
- **Fast and lightweight** — tuned for a broad range of systems.
- **Stable Ubuntu base** — built on Ubuntu LTS.
- **Modern appearance** — Windows-like interface for smoother adoption.

---

## System Requirements

### Secure Boot Support

EDYOU OS supports Secure Boot. Enabling Secure Boot during installation is recommended for better system security.

### Minimum Requirements

| Component | Requirement |
|-----------|-------------|
| Architecture | x86_64 |
| Firmware | UEFI or BIOS |
| CPU | 2 GHz processor |
| RAM | 4 GB |
| Disk | 20 GB free |
| Display | 1024×768 |
| Ports | USB or DVD drive |

### Recommended Requirements

| Component | Requirement |
|-----------|-------------|
| Architecture | x86_64 |
| Firmware | UEFI with Secure Boot |
| CPU | 2.5 GHz quad-core |
| RAM | 8 GB |
| Disk | 50 GB free |
| Display | 2560×1440 |
| Internet | Required |

**Important:**

- EDYOU OS only supports x86_64 architecture. ARM is not supported.
- The system requires ACPI-compliant hardware; legacy systems may fail.
- Both UEFI and BIOS boot modes are supported, but U-Boot is not.

---

## Installation Guide

1. Download the ISO from: [EDYOU OS Downloads](https://edyou-systems.github.io/EDYOUOS/#download)
2. Create a bootable USB with Rufus, Etcher, or a similar tool.
3. Boot the computer from that USB.
4. Follow the installer prompts.

Enjoy a fully open, privacy-friendly operating system for education.

> Note: EDYOU OS is currently based on Ubuntu LTS "questing." Official support is planned through 2026 and may change later.

---

## Building EDYOU OS

Use the provided `Makefile` to build locally.

```sh
make                # Build the current language
make all            # Build all languages
make fast           # Build fast configuration languages
make clean          # Remove build artifacts
make bootstrap      # Validate environment and dependencies
```

- Build options like language, timezone, mirrors, and input methods are configured in `./src/args.sh`.
- Generated ISOs and artifacts are placed in `./src/dist`.
- Use `make fast` to build the fast configuration, which currently runs `de_DE` first and then `en_US`.

---

## Community & Support

Join the community and ask questions here:

[GitHub Discussions](https://github.com/edyou-systems/EDYOU-OS/discussions)

---

## About EDYOU OS

EDYOU OS is a school-focused Linux platform designed to offer freedom, privacy, and stability. It is aimed at students, teachers, and institutions looking for a modern educational OS.

---

## License

This project is licensed under the **GNU General Public License**. See the [LICENSE](LICENSE) file for details.
