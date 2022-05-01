# RPI scripts for kernel compilation

This repository is create in order to build a kernel for Raspberry Pi 3/4 configuration. There are different software requierements you need for a proper kernel building .To ensure it, different choices will work.

These repository allows you to ubild different kernel versions with the same script. Two different choices to build the kernel are availables:
- **Work in your own enviroment:** 
  - You need to ensure following requirements are satisfied: 
`crossbuild-essential-arm64
bison 
flex
device-tree-compiler
pkg-config 
ncurses-dev 
libssl-dev`
- **Work with Dockerfile:**
  - A Dockerfile is provided in this repository. In orther to use the Docker enviroment use given instructions below.
  - In order to build docker you only need to execute following commands:
  ```bash
  cd docker
  source docker_enviroment.sh
  # If you need to build
  docker_build
  # If you only want to run
  docker_run
  ```
---

## USAGE

First of all you need to build the kernel from source. So once you already satisfied the different requierements (via Docker or not), you are able to run mk_kernel script.

### Kernel building

In order to compile the kernel you use **mk_kernel.sh** script. This scripts could be launched with different arguments or flags:
- List requierements: Lists the requierements to build the kernel.
  - `./mk_kernel.sh show_req`
- Install requierments flag: Install the requieremts listed above.
  - `./mk_kernel.sh req` 
- Branch flag: Select the kernel version you want to build:
  - `./mk_kernel.sh -b 4.14` 

This script will create you two new directories, once for the kernel source code and other for the building output required for the **root file system**.

```console
rbn@RBNMachine: ~/Projects/RPiCustomKernel » ls
5.15_bo  5.15_kernel  cmd.txt  config.txt  docker  mk_kernel.sh  mk_rootfs.sh  temp.sh
```

### ROOTFS

Next step is download and prepare the root file system to make it work with the kernel toghether. This repository actually is prepared to install an ubuntu root files system, but once you have a kernel built you would be able to make it work with any other rootfs you want to install.

To install output kernel files in our rootfs you cold execute **mk_rootfs.sh** script. This script accept different flags listed above:
- **-d flag**: Select the distribution you want to use.
- **-v flag**: Selects the version of the distro selected
- **-k flad**: Select the kernel version will be used (**must be already built with previus script**).
- Ex: `./mk_rootfs.sh -d ubuntu -b 20.04.1 -k 5.13`

At this point you would have the rootfs downloaded and the kernel building output installed on your rootfs. The directory tree must show something like this:

```console
rbn@RBNMachine: ~/Projects/RPiCustomKernel/rootfs » tree -L 2
rootfs
└── 20.04.1
    ├── bin -> usr/bin
    ├── boot
    ├── dev
    ├── etc
    ├── home
    ├── lib -> usr/lib
    ├── media
    ├── mnt
    ├── opt
    ├── proc
    ├── root
    ├── run
    ├── sbin -> usr/sbin
    ├── srv
    ├── sys
    ├── tmp
    ├── usr
    └── var
```
