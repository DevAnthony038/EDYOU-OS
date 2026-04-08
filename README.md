# EDYOU OS – Open-Source School Linux

[![GPL licensed](https://img.shields.io/badge/license-GPL-blue.svg)](https://github.com/DevAnthony038/EDYOU-OS/blob/main/LICENSE)
[![Discussions](https://img.shields.io/badge/discussions-join-blue)](https://github.com/DevAnthony038/EDYOU-OS/discussions)
[![Website Status](https://img.shields.io/website?url=https%3A%2F%2Fhttps://edyou-os.vercel.app/)](https://edyou-os.vercel.app/)
[![Latest Version](https://img.shields.io/badge/version-v1.0.0-red)](https://edyou-os.vercel.app/)

EDYOU OS is a modern, privacy-focused Linux operating system designed specifically for schools, educational institutions, and learners. It combines freedom, performance, and reliability without the limitations of traditional operating systems.

Built on Ubuntu LTS, EDYOU OS offers a Windows-like interface along with the stability, speed, and openness that only Linux can provide.

For more information, visit the official website: [EDYOU OS Website](https://edyou-os.vercel.app/)

![EDYOU OS Screenshot](Image.png)

---

## Key Features

- **Open-Source & Customizable**: Fully free to modify and redistribute.
- **Privacy-First**: No unnecessary data collection or telemetry.
- **Student-Friendly**: Intuitive interface with pre-installed educational tools.
- **Lightweight & Fast**: Optimized for various hardware classes.
- **Stable Foundation**: Based on Ubuntu LTS for long-term support and security.
- **Modern Interface**: Windows-like design for easy adoption in schools.

---

## System Requirements

### EDYOU OS Supports Secure Boot!

EDYOU OS fully supports Secure Boot. During installation, it is highly recommended to enable Secure Boot to ensure the security of your system.

### Minimum System Requirements

| Component       | Requirement                  |
|-----------------|------------------------------|
| Architecture   | x86_64 architecture         |
| Firmware       | UEFI or BIOS                |
| Processor      | 2 GHz processor             |
| RAM            | 4 GB RAM                    |
| Disk Space     | 20 GB free disk space       |
| Screen         | 1024x768 screen resolution  |
| Ports          | USB port or DVD drive       |

### Recommended System Requirements for Best Experience

| Component       | Requirement                          |
|-----------------|--------------------------------------|
| Architecture   | x86_64 architecture                  |
| Firmware       | UEFI firmware with Secure Boot       |
| Processor      | 2.5 GHz quad-core processor          |
| RAM            | 8 GB RAM                             |
| Disk Space     | 50 GB free disk space                |
| Screen         | 2560x1440 resolution (27-inch screen)|
| Internet       | Internet access                      |

**Important Hardware Notes:**

- EDYOU OS currently supports only x86_64 architecture. If you're using a different architecture (e.g., ARM), you won't be able to install EDYOU OS. (ARM is not supported.)
- EDYOU OS supports only ACPI-compliant hardware. If your hardware is not ACPI-compliant, installation may fail. (Legacy hardware is not supported.)
- EDYOU OS supports both UEFI and BIOS boot firmware. Ensure your hardware is ACPI-compliant for proper installation. (U-Boot is not supported.)

---

## Installation Guide

1. Download the EDYOU OS ISO file from the official site: [EDYOU OS Downloads](https://edyou-os.vercel.app/#download)
2. Create a bootable USB drive using tools like Rufus or Etcher.
3. Boot your computer from the USB drive and follow the on-screen instructions.
4. Enjoy a fully open, privacy-friendly school operating system!

Note: EDYOU OS is currently based on Ubuntu LTS version "questing." Official support is planned until 2026; this may change in future versions.

### Build Instructions

To build EDYOU OS yourself, use the included `Makefile`. Common commands:

```
make                 (or `make current`)    Build current language
make all                                    Build all languages
make fast                                   Build fast config languages
make clean                                  Remove build artifacts
make bootstrap                              Validate environment and dependencies
```

- Build parameters (language, timezone, mirrors, input methods, etc.) are configured in `./src/args.sh`. Edit this file to change build behavior.
- Generated ISO images and related artifacts are placed in `./src/dist`.

Run `make fast` to build the fast configuration (currently set for `de_DE` first, then `en_US`).

---

## Community & Support

Join discussions, ask questions, or provide feedback here:  
[GitHub Discussions](https://github.com/DevAnthony038/EDYOU-OS/discussions)

---

## About EDYOU OS

EDYOU OS – a forward-thinking school Linux,  
built on freedom, made for education, with a focus on privacy.

Perfect for students, teachers, and educational institutions seeking a modern, stable, and open-source environment.

---

## License

This project is licensed under the **GNU General Public License**. See the [LICENSE](LICENSE) file for more details.
