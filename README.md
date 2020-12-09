# NSense Fan Control

[![test](https://img.shields.io/github/workflow/status/skynet-core/nord-sense/test?style=for-the-badge)](https://github.com/skynet-core/nord-sense/actions?query=workflow%3Atest)
[![last commit](https://img.shields.io/github/last-commit/skynet-core/nord-sense?style=for-the-badge)](https://github.com/skynet-core/nord-sense/releases/latest)
[![last release](https://img.shields.io/github/release-date/skynet-core/nord-sense?color=red&logoColor=green&style=for-the-badge)](https://github.com/skynet-core/nord-sense/releases/latest)

## Daemon service for controlling gaming laptops fans speed on any Linux OS
<h1 align="center">
        <img src="./cold.svg" alt="NSense Logo" width="306" height="344"/>
</p>

## Advantages

1. Zero dependency
2. Flexible and human-friendly config file
3. Service controlled by signal
4. Portable (statically built with musl)


## Installation

Download package for [latest release](https://github.com/skynet-core/nsense/releases/latest) and install it using your package manager 

### Debian derivatives (Ubuntu, Debian etc.)

        sudo dpkg -i ./nsense-<version>.deb // install
        sudo dpkg -P nsense // remove

## RHEL derivatives (Fedora, CentOS etc.)

        sudo rpm -i ./nsense-<version>.rpm // install
        sudo rpm -e nsense // remove
## How to build

        cd /tmp && git clone git@github.com:skynet-core/nsense.git
        cd ./nsense && nimble build -d:release
        nimble setup --configName:AcerP515-51   // install files into your system
        nimble purge                            // uninstall files from system

## TODO list

- [x] Temperature zones and fans speed level switching (ver 0.5.0)
- [x] Systemd sleep hook via SIGTSTP and SIGCONT signals with switching to BIOS auto mode
- [x] Systemd unit file (ver 0.6.0)
- [x] Installation with nimble
- [ ] Simple FAQ 
- [ ] Apt, Rpm packages (ver 1.0.0)
- [ ] command-line front-end client (ver 1.0.0)
- [ ] Snap, Flatpak bundles (ver 1.1.0)
- [ ] Support for different from systemd init systems (ver 1.5.0)
- [ ] Implement communication via `/dev/port` as an option for safety reasons (ver 2.0.0)
- [ ] termgui font-end client (ver 2.5.0)
- [ ] Qt front-end client (ver 3.0.0)
- [ ] Mobile GUI and remote control via mobile application (gRPC) (ver 3.5.0)
