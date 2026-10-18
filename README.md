# Aevis File Manager

Fast, intuitive, and modern file manager designed for the Aevis Desktop Environment.

Part of the **[Project Aevis](https://github.com/project-Aevis)** suite.

![screenshot](screenshots/Screenshot_20211025_151224.png)

## Features

- Clean PC interactive layout with tabbed navigation and split view support
- File previews, tags, search, and bookmarking
- Built-in desktop manager module for handling desktop icons and wallpapers
- Integration with KIO and Solid for storage devices and remote protocols

## Dependencies

### Debian / Ubuntu

```shell
sudo apt install build-essential cmake extra-cmake-modules \
    qt6-base-dev qt6-declarative-dev libkf6kio-dev libkf6solid-dev \
    libkf6windowsystem-dev
```

### Arch Linux

```shell
sudo pacman -S extra-cmake-modules qt6-base qt6-declarative taglib kio
```

## Build and Install

```shell
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make
sudo make install
```

## License

This project is licensed under the GNU General Public License v3.0 (GPLv3).
