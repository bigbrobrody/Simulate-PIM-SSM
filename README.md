# Simulate PIM-SSM Network with VirtualBox, FRRouting and GStreamer on Windows

A comprehensive guide to simulate a PIM-SSM (Protocol Independent Multicast - Source-Specific Multicast) network for testing custom video clients with source-specific multicast video streaming on a Windows computer.

This guide uses completely free and open-source software: **VirtualBox**, **Debian with FRRouting**, and **GStreamer**. The video client runs directly on the Windows host computer.

## Table of Contents
- [Introduction](#introduction)
- [Why This Approach?](#why-this-approach)
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Network Topology](#network-topology)
- [Setup Instructions](#setup-instructions)
  - [Step 1: Install VirtualBox](#step-1-install-virtualbox)
  - [Step 2: Create Router VMs](#step-2-create-router-vms)
  - [Step 3: Configure Network Topology](#step-3-configure-network-topology)
  - [Step 4: Configure FRRouting Routers](#step-4-configure-frrouting-routers)
  - [Step 5: Setup Multicast Sources](#step-5-setup-multicast-sources)
  - [Step 6: Setup Video Client on Windows Host](#step-6-setup-video-client-on-windows-host)
- [Testing and Verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Scenarios](#advanced-scenarios)
- [References](#references)

## Introduction

PIM-SSM (Source-Specific Multicast) is a multicast routing protocol that allows receivers to specify both the multicast group **and** the specific source they want to receive traffic from. This is ideal for:

- **Video streaming applications** where clients subscribe to specific video sources
- **IPTV systems** with multiple channels from different sources
- **Security camera systems** with many video feeds
- **Testing custom multicast video clients** in a controlled environment

This simulation allows you to create a complete PIM-SSM network environment on a single Windows computer using free, open-source tools, with the video client running natively on Windows.

## Why This Approach?

### Advantages of FRRouting over OpenWRT

1. **100% Free and Open Source** - No licensing costs
2. **Industry Standard** - FRRouting is used in production networks worldwide
3. **Full PIM-SM Support** - Comprehensive PIM-SM/SSM implementation with pimd
4. **IGMPv3 Support** - Native support for source-specific multicast
5. **Easy Configuration** - Standard Linux networking with powerful routing daemon
6. **Production Ready** - Battle-tested in enterprise environments
7. **Native Windows client** - Video client runs directly on Windows host without VM overhead

### What You'll Build

- A multi-router PIM-SSM network running FRRouting in VirtualBox VMs
- Multiple multicast video sources streaming different content
- A Windows-native video client that can subscribe to specific sources
- A complete test environment for source-specific multicast applications

## Prerequisites

### Software Requirements

| Software | Version | Purpose | Download |
|----------|---------|---------|----------|
| **VirtualBox** | 6.1 or later | Virtualization platform | [virtualbox.org](https://www.virtualbox.org/wiki/Downloads) |
| **Debian** | 13+ | Router and source OS | [debian.org](https://www.debian.org/) |
| **FRRouting** | 8.0 or later | Routing software with PIM support | [frrouting.org](https://frrouting.org/) |
| **VLC Media Player** | Latest | Video client on Windows | [videolan.org](https://www.videolan.org/vlc/download-windows.html) |

### Hardware Requirements

- **Operating System**: Windows 10 or 11 (64-bit)
- **CPU**: Modern multi-core processor (4+ cores recommended)
- **RAM**: Minimum 8GB (12GB recommended)
  - Each router VM: ~1GB
  - Each Debian source VM: ~2GB
  - Windows host overhead: ~2-4GB
- **Disk Space**: 40GB free space
- **Network**: Internet connection for initial setup

### Knowledge Requirements

- Basic Linux command line
- Basic networking concepts (IP addressing, routing)
- Understanding of multicast concepts (helpful but not required)

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────┐
│                  Windows Host Computer                       │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           VirtualBox Virtual Machines                  │  │
│  │                                                        │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │  │
│  │  │  Source VM 1 │  │  Source VM 2 │  │  Source VM 3 │  │  │
│  │  │  GStreamer   │  │  GStreamer   │  │  GStreamer   │  │  │
│  │  │  192.168.1.10│  │  192.168.1.11│  │  192.168.1.12│  │  │
│  │  └──────┬───────┘  └───────┬──────┘  └────────┬─────┘  │  │
│  │         │                  │                  │        │  │
│  │         └──────────────────┴──────────────────┘        │  │
│  │                            │                           │  │
│  │                    ┌───────┴────────┐                  │  │
│  │                    │   Router R1    │                  │  │
│  │                    │  Debian + FRR  │                  │  │
│  │                    │  PIM-SM (SSM)  │                  │  │
│  │                    └───────┬────────┘                  │  │
│  │                            │                           │  │
│  │                    ┌───────┴────────┐                  │  │
│  │                    │   Router R2    │                  │  │
│  │                    │  Debian + FRR  │                  │  │
│  │                    │  PIM-SM (SSM)  │                  │  │
│  │                    └───────┬────────┘                  │  │
│  │                            │                           │  │
│  └────────────────────────────┼───────────────────────────┘  │
│                               │                              │
│                               │ (Host-Only Network)          │
│                               │ 192.168.2.0/24               │
│                               │                              │
│                      ┌────────┴─────────┐                    │
│                      │  Windows Client  │                    │
│                      │   VLC Player     │                    │
│                      │   192.168.2.1    │                    │
│                      └──────────────────┘                    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

## Network Topology

### IP Addressing Plan

| Network Segment | Subnet | Purpose |
|----------------|--------|---------|
| Source Network | 192.168.1.0/24 | Multicast video sources |
| Client Network | 192.168.2.0/24 | Windows host video client |
| Core Link | 10.0.1.0/30 | R1 to R2 interconnect |

### Multicast Groups

We'll use the SSM range **232.0.0.0/8** (standard SSM range):

| Source | IP Address | Multicast Group | Port | Content |
|--------|------------|-----------------|------|---------|
| Source 1 | 192.168.1.10 | 232.1.1.1 | 5000 | Test Pattern 1 |
| Source 2 | 192.168.1.11 | 232.1.1.2 | 5000 | Test Pattern 2 |
| Source 3 | 192.168.1.12 | 232.1.1.3 | 5000 | Test Pattern 3 |

## Setup Instructions

### Step 1: Install VirtualBox

1. Download VirtualBox from [virtualbox.org](https://www.virtualbox.org/wiki/Downloads)
2. Install VirtualBox for your operating system
3. Download and install the **VirtualBox Extension Pack** (same version as VirtualBox)
4. Add C:\Program Files\Oracle\VirtualBox to path

**Verify installation:**
From a command prompt
```cmd
VBoxManage --version
```

### Step 2: Create Router VMs

We'll create two Debian router VMs (R1, R2) that will run FRRouting.

#### Download Debian ISO

1. Visit [Debian Downloads](https://www.debian.org/distrib/)
2. Download the **netinst ISO** (small installation image)
3. Save it to a convenient location

For all Debian installations:
Leave the root password blank and create a user 'vboxuser' with password 'vboxuser'.
Make sure the NAT adapter is configured during installation to allow Internet access for package installation.
Under "Software selection" only select "SSH server" and "standard system utilities".

#### Alternative approach of using the VirtualBox GUI

Note: This approach will result in a much larger debian installation due to the GUI install.

**Create a new Debian VM using the VirtualBox GUI:**
- Create a new VM
- Set the VM name - e.g. Router-R1
- Select the Debian iso
- Tick unattended install (default after selecting the iso)
- Leave root password blank
- Set user password to vboxuser (same as username)
- Select to install guest additions
- Set RAM to 2048 MB
- Set number of CPUs to 1
- Set hard disk to 20 GB

**Replicate for the other VMs:**
- Clone the machine 2 times as Router-R2, Source-1
- Amend each machine to have the network interfaces detailed below

#### Create Router R1

```cmd
# Create VM
VBoxManage createvm --name "Router-R1" --ostype "Debian_64" --register

# Configure VM
VBoxManage modifyvm "Router-R1" ^
  --memory 1024 ^
  --vram 16 ^
  --cpus 1 ^
  --nic1 intnet --intnet1 "source-network" ^
  --nic2 intnet --intnet2 "core-link1" ^
  --boot1 disk --boot2 dvd

# Add storage controller
VBoxManage storagectl "Router-R1" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Router-R1" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd "C:\Users\[username]\VirtualBox VMs\Router-R1"
VBoxManage createmedium disk --filename Router-R1.vdi --size 20480
VBoxManage storageattach "Router-R1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R1.vdi
```

#### Create Router R2

```cmd
# Create VM
VBoxManage createvm --name "Router-R2" --ostype "Debian_64" --register

# Configure VM
VBoxManage modifyvm "Router-R2" ^
  --memory 1024 ^
  --vram 16 ^
  --cpus 1 ^
  --nic1 intnet --intnet1 "core-link1" ^
  --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" ^
  --boot1 disk --boot2 dvd

# Note: Replace "VirtualBox Host-Only Ethernet Adapter" with your actual adapter name
# Use 'VBoxManage list hostonlyifs' to see available host-only adapters

# Add storage controller
VBoxManage storagectl "Router-R2" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Router-R2" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd ..\Router-R2
VBoxManage createmedium disk --filename Router-R2.vdi --size 20480
VBoxManage storageattach "Router-R2" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R2.vdi
```

**Note**: Router R2's second NIC is configured as a host-only adapter, allowing the Windows host to communicate with the network as a client.

### Step 3: Configure Network Topology

#### Create Source VMs

Create Debian VM for multicast sources (we will clone the VM later):

```cmd
VBoxManage createvm --name "Source-1" --ostype "Debian_64" --register

VBoxManage modifyvm "Source-1" ^
  --memory 2048 ^
  --vram 128 ^
  --cpus 2 ^
  --nic1 intnet --intnet1 "source-network" --nictype1 virtio ^
  --boot1 disk --boot2 dvd

# Add storage controller
VBoxManage storagectl "Source-1" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Source-1" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd ..\Source-1
VBoxManage createmedium disk --filename Source-1.vdi --size 20480
VBoxManage storageattach "Source-1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Source-1.vdi
```

#### Setup VirtualBox Host-Only Network

To allow the Windows host to communicate with the simulated network:

1. Open VirtualBox Manager
2. Go to **Network > Host-only Networks**
3. Modify the configuration of the host-only network adapter:
   - IPv4 Address: 192.168.2.1
   - IPv4 Network Mask: 255.255.255.0
   - DHCP Server: Disabled

This network will allow your Windows host to act as a video client.

#### Enable Internet Connectivity for Package Installation

**Important**: During initial setup, you'll need Internet access to install packages.

Add a NAT network adapter as the third NIC on both routers during installation:

```cmd
# Add NAT adapter to Router-R1
VBoxManage modifyvm "Router-R1" --nic3 nat

# Add NAT adapter to Router-R2
VBoxManage modifyvm "Router-R2" --nic3 nat
```

For Debian source VM, add NAT adapter as second NIC:

```cmd
# Add NAT adapter to source VM
VBoxManage modifyvm "Source-1" --nic2 nat
```

#### Enable SSH access for easier management

Using the GUI add port forwarding to allow SSH access to the routers from the host machine during setup:
 - Host IP 127.0.0.1, host port 2222, guest port 22 for Router-R1
 - Host IP 127.0.0.1, host port 2322, guest port 22 for Router-R2
 - Host IP 127.0.0.1, host port 2422, guest port 22 for Source-1

To connect from Windows use an SSH client such as PuTTY to connect to 127.0.0.1:2222

#### Enable PAE/NX for each VM for better performance:

```cmd
VBoxManage modifyvm "Router-R1" --pae on
VBoxManage modifyvm "Router-R2" --pae on
VBoxManage modifyvm "Source-1" --pae on
```

#### Configure all hard disks as SSD (to match host)

Use the GUI to set each VM's hard disk to be treated as SSD for better performance.

### Step 4: Configure FRRouting Routers

#### Install Debian and FRRouting on Router R1

1. **Install Debian** on Router-R1 VM:
   - See steps above for installation instructions.

2. **Configure network interfaces**:
   
   Edit `/etc/network/interfaces`:
   ```bash
   su [input root password set during install]
   nano /etc/network/interfaces
   ```

   Configuration:
   ```
   # Loopback interface
   auto lo
   iface lo inet loopback

   # LAN interface (to sources)
   auto enp0s3
   iface enp0s3 inet static
       address 192.168.1.1
       netmask 255.255.255.0

   # Core link interface (to R2)
   auto enp0s8
   iface enp0s8 inet static
       address 10.0.1.1
       netmask 255.255.255.252

   # NAT interface (for package installation - remove later)
   # auto enp0s9
   allow-hotplug enp0s9
   iface enp0s9 inet dhcp
   ```

   Apply changes:
   ```bash
   systemctl restart networking
   ```

   Check network config:
   ```bash
   ip a
   ```

   Install other tools
   ```bash
   apt install curl
   ```

4. **Enable IP forwarding**:
   ```bash
   sudo sysctl -w net.ipv4.ip_forward=1
   sudo sysctl -w net.ipv4.conf.all.mc_forwarding=1 *** results in Operation not permitted
   
   # Make persistent
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.conf.all.mc_forwarding=1" | sudo tee -a /etc/sysctl.conf
   ```

5. **Install FRRouting**:
   ```bash
   # Add FRRouting GPG key
   curl -s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null

   # Add FRRouting repository
   echo "deb [signed-by=/usr/share/keyrings/frrouting.gpg] https://deb.frrouting.org/frr $(lsb_release -s -c) frr-stable" | sudo tee /etc/apt/sources.list.d/frr.list

   # Install FRRouting
   sudo apt update
   sudo apt install -y frr frr-pythontools
   ```

6. **Enable PIM daemon**:
   
   Edit `/etc/frr/daemons`:
   ```bash
   sudo nano /etc/frr/daemons
   ```

   Enable pimd:
   ```
   zebra=yes
   bgpd=no
   ospfd=no
   ospf6d=no
   ripd=no
   ripngd=no
   isisd=no
   pimd=yes
   ldpd=no
   nhrpd=no
   eigrpd=no
   babeld=no
   sharpd=no
   staticd=no
   pbrd=no
   bfdd=no
   fabricd=no
   vrrpd=no
   pathd=no
   ```
   I added zebra=yes to enable the zebra daemon for interface management.

7. **Configure FRRouting**:
   
   Edit `/etc/frr/frr.conf`:
   ```bash
   sudo nano /etc/frr/frr.conf
   ```

   Configuration:
   ```
   frr version 8.0
   frr defaults traditional
   hostname Router-R1
   !
   ! Enable IP forwarding
   ip forwarding
   !
   ! Enable IGMP on LAN interface
   interface enp0s3
    ip igmp
    ip igmp version 3
    ip pim
   !
   ! Enable PIM on core interface
   interface enp0s8
    ip pim
   !
   ! PIM configuration for SSM
   router pim
   !
   !
   line vty
   !
   ```

8. **Set file permissions and restart FRRouting**:
   ```bash
   sudo chown frr:frr /etc/frr/frr.conf
   sudo chmod 640 /etc/frr/frr.conf
   sudo systemctl restart frr
   sudo systemctl enable frr
   ```

9. **Add static route to client network**:
   ```bash
   sudo ip route add 192.168.2.0/24 via 10.0.1.2
   
   # Make persistent by adding to /etc/network/interfaces
   sudo nano /etc/network/interfaces
   # Add under enp0s8 interface:
   #    up ip route add 192.168.2.0/24 via 10.0.1.2
   ```

#### Install Debian and FRRouting on Router R2

1. **Install Debian** on Router-R2 VM (same as R1)

2. **Configure network interfaces**:
   
   Edit `/etc/network/interfaces`:
   ```bash
   sudo nano /etc/network/interfaces
   ```

   Configuration:
   ```
   # Loopback interface
   auto lo
   iface lo inet loopback

   # Core link interface (to R1)
   auto enp0s3
   iface enp0s3 inet static
       address 10.0.1.2
       netmask 255.255.255.252
       gateway 10.0.1.1

   # LAN interface (to Windows host)
   auto enp0s8
   iface enp0s8 inet static
       address 192.168.2.254
       netmask 255.255.255.0

   # NAT interface (for package installation - remove later)
   # auto enp0s9
   allow-hotplug enp0s9
   iface enp0s9 inet dhcp
   ```

   Apply changes:
   ```bash
   sudo systemctl restart networking
   ```

3. **Enable IP forwarding** (same as R1)

Disabling other adapters gets Internet access working.

4. **Install FRRouting** (same as R1)

5. **Enable PIM daemon** (same as R1)

6. **Configure FRRouting**:
   
   Edit `/etc/frr/frr.conf`:
   ```bash
   sudo nano /etc/frr/frr.conf
   ```

   Configuration:
   ```
   frr version 8.0
   frr defaults traditional
   hostname Router-R2
   !
   ! Enable IP forwarding
   ip forwarding
   !
   ! Enable PIM on core interface
   interface enp0s3
    ip pim
   !
   ! Enable IGMP on LAN interface (towards Windows host)
   interface enp0s8
    ip igmp
    ip igmp version 3
    ip pim
   !
   ! PIM configuration for SSM
   router pim
    !
   !
   line vty
   !
   ```

7. **Set file permissions and restart FRRouting**:
   ```bash
   sudo chown frr:frr /etc/frr/frr.conf
   sudo chmod 640 /etc/frr/frr.conf
   sudo systemctl restart frr
   sudo systemctl enable frr
   ```

#### Remove NAT Adapters (After Package Installation)

Should be able to just remove cables from NAT adapters in VirtualBox GUI.
Might be better to disable the adapters.

Once all packages are installed on both routers, remove the NAT adapters:

```cmd
# Remove NAT from routers
VBoxManage modifyvm "Router-R1" --nic3 none
VBoxManage modifyvm "Router-R2" --nic3 none
```

Also remove the NAT interface configuration from `/etc/network/interfaces` on both routers.


### Step 5: Setup Multicast Sources

Install Debian on each source VM, then configure static IP and install GStreamer.

#### Install and Configure Source-1

1. **Install Debian** on Source-1 VM

2. **Configure static IP** - Edit `/etc/network/interfaces`:

   ```bash
   sudo nano /etc/network/interfaces
   ```

   Configuration:
   ```
   # Loopback interface
   auto lo
   iface lo inet loopback

   # Primary network interface (source-network)
   auto enp0s3
   iface enp0s3 inet static
       address 192.168.1.10
       netmask 255.255.255.0
       gateway 192.168.1.1
       dns-nameservers 8.8.8.8 8.8.4.4

   # NAT interface (for package installation - remove later)
   allow-hotplug enp0s8
   iface enp0s8 inet dhcp
   ```

   Apply changes:
   ```bash
   sudo systemctl restart networking
   ```

3. **Install GStreamer**:

   ```bash
   ping -c 4 www.bbc.co.uk
   sudo apt update
   sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
     gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
     gstreamer1.0-plugins-ugly gstreamer1.0-libav
   ```

4. **Create streaming script** - Create `/usr/local/bin/stream.sh`:

   ```bash
   sudo nano /usr/local/bin/stream.sh
   ```

   ```bash
   #!/bin/bash
   # Stream test pattern 1 to 232.1.1.1:5000
   gst-launch-1.0 -v \
       videotestsrc is-live=true pattern=smpte horizontal-speed=1 ! \
       video/x-raw,width=720,height=576,framerate=25/1 ! \
       textoverlay text="Source 1 - SMPTE Bars" valignment=top halignment=left font-desc="Sans, 32" ! \
       x264enc tune=zerolatency bitrate=2000 speed-preset=superfast  key-int-max=2 byte-stream=true ! \
       video/x-h264,profile=baseline ! \
       rtph264pay config-interval=1 pt=96 ! \
       udpsink host=232.1.1.1 port=5000 auto-multicast=true ttl-mc=5
   ```

   Make executable:
   ```bash
   chmod +x /usr/local/bin/stream.sh
   ```

5. **Test the stream**:
   ```bash
   /usr/local/bin/stream.sh
   ```

6. Make the stream start on boot

    Create service file:
    ```bash
    sudo nano /etc/systemd/system/stream.service
    ```

    Add:
    ```bash
    [Unit]
    Description=Multicast RTP test stream
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/local/bin/stream.sh
    Restart=on-failure
    User=root

    [Install]
    WantedBy=multi-user.target
    ```

    Enable and start the service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable stream.service
    sudo systemctl start stream.service
    ```

    Check status and logs:
    ```bash
    sudo systemctl status stream.service
    sudo journalctl -u stream.service -b
    ```

    Note: The stream might fail if adapter 1 is disabled because GStreamer cannot join the multicast group.

7. Check on the host machine, with NAT adapter still present, that the stream is being sent.

   ```cmd
   gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.1 multicast-source=192.168.1.10 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false
   ```

8. **Disable NAT adapter** after package installation:

   Shutdown the VM:
   ```bash
   sudo poweroff
   ```

   Finalise:
   - Disable NAT adapter 2 in VirtualBox GUI.
   - Enable network adapter 1 (source-network).
   - Start the VM.

#### Configure Source-2 and Source-3

Clone the Source-1 VM in the VirtualBox GUI as Source-2.

Clone the Source-1 VM in the VirtualBox GUI as Source-3.

In each new VM disable network adapter 1 and enable network adapter 2 (NAT).

Change the Source-2 NAT adapter port forwarding host port to 2522.

Change the Source-2 NAT adapter port forwarding host port to 2622.

Boot each new VM in turn.

**Source-2**:

SSH into the machine using 127.0.0.1:2522

```bash
sudo nano /etc/network/interfaces
```

Update static IP address to 192.168.1.11

Update stream script:

```bash
sudo nano /usr/local/bin/stream.sh
```

```bash
#!/bin/bash
gst-launch-1.0 -v \
    videotestsrc is-live=true pattern=snow horizontal-speed=2 ! \
    video/x-raw,width=720,height=576,framerate=25/1 ! \
    textoverlay text="Source 2 - Snow Pattern" valignment=top halignment=left font-desc="Sans, 32" ! \
    x264enc tune=zerolatency bitrate=2000 speed-preset=superfast  key-int-max=2 byte-stream=true ! \
    video/x-h264,profile=baseline ! \
    rtph264pay config-interval=1 pt=96 ! \
    udpsink host=232.1.1.2 port=5000 auto-multicast=true ttl-mc=5
```

Shutdown the VM:
```bash
sudo poweroff
```

Finalise:
- Disable NAT adapter 2 in VirtualBox GUI.
- Enable network adapter 1 (source-network).
- Start the VM.

**Source-3**:

SSH into the machine using 127.0.0.1:2622

```bash
sudo nano /etc/network/interfaces
```

Update static IP address to 192.168.1.12

Update stream script:

```bash
sudo nano /usr/local/bin/stream.sh
```

```bash
#!/bin/bash
gst-launch-1.0 -v \
    videotestsrc is-live=true pattern=circular horizontal-speed=2 ! \
    video/x-raw,width=720,height=576,framerate=25/1 ! \
    textoverlay text="Source 3 - H265 Circular" valignment=top halignment=left font-desc="Sans, 32" ! \
    x265enc tune=zerolatency bitrate=2000 speed-preset=superfast key-int-max=2 ! \
    video/x-h265,profile=main ! \
    rtph265pay config-interval=1 pt=96 ! \
    udpsink host=232.1.1.3 port=5000 auto-multicast=true ttl-mc=5
```

Shutdown the VM:
```bash
sudo poweroff
```

Finalise:
- Disable NAT adapter 2 in VirtualBox GUI.
- Enable network adapter 1 (source-network).
- Start the VM.

### Step 6: Setup Video Client on Windows Host

The video client runs directly on your Windows host computer.

#### Install GStreamer

1. **Download GStreamer**:
   - Visit [https://gstreamer.freedesktop.org/download/#windows](https://gstreamer.freedesktop.org/download/#windows)
   - Download the latest 64-bit runtime installer

2. **Install GStreamer**:
   - Run the installer
   - Follow the installation wizard

#### Open the streams with GStreamer

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.1 multicast-source=192.168.1.10 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.2 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.3 multicast-source=192.168.1.12 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph265depay ! queue ! decodebin ! queue ! autovideosink sync=false

Note: VLC is unable to decode H264 and H265 without SDP information.

#### Troubleshooting Windows Firewall

If you don't receive multicast traffic:

1. **Allow VLC through Windows Firewall**:
   - Open Windows Defender Firewall
   - Click "Allow an app or feature through Windows Defender Firewall"
   - Find VLC Media Player and enable both Private and Public networks

## Testing and Verification

### Verify FRRouting Status

On each router, check PIM status:

```bash
# Enter FRRouting CLI
sudo vtysh

# Check PIM neighbors
show ip pim neighbor

# Check PIM interface status
show ip pim interface

# Check multicast routing table
show ip mroute

# Check IGMP groups
show ip igmp groups

# Exit
exit
```

### Verify Multicast Routing

On Router R1:
```bash
# Check multicast routes
ip mroute show

# Check IGMP membership
cat /proc/net/igmp

# Monitor multicast traffic
sudo tcpdump -i enp0s3 dst host 232.1.1.1 or dst host 232.1.1.2 or dst host 232.1.1.3
```

### Test Client Reception

1. Start streaming on all source VMs
2. Use GStreamer to receieve video from each multicast group
3. Verify video playback

### Verify Source-Specific Multicast

Use Wireshark on Windows to verify IGMPv3 SOURCE records are being sent when you start playing a stream.

## Troubleshooting

### Issue 1: No Multicast Traffic Reaching Clients

**Solutions**:

1. **Verify IP forwarding and multicast forwarding are enabled**:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   cat /proc/sys/net/ipv4/conf/all/mc_forwarding
   # Both should return 1
   ```

2. **Check FRRouting status**:
   ```bash
   sudo systemctl status frr
   sudo vtysh -c "show ip pim interface"
   ```

3. **Verify firewall allows multicast**:
   ```bash
   sudo iptables -L -v -n
   sudo iptables -A INPUT -d 224.0.0.0/4 -j ACCEPT
   sudo iptables -A FORWARD -d 224.0.0.0/4 -j ACCEPT
   ```

4. **Check PIM neighbors**:
   ```bash
   sudo vtysh -c "show ip pim neighbor"
   ```

### Issue 2: PIM Neighbors Not Forming

**Solutions**:

1. **Verify IP connectivity** between routers:
   ```bash
   ping 10.0.1.1  # From R2 to R1
   ping 10.0.1.2  # From R1 to R2
   ```

2. **Check PIM configuration**:
   ```bash
   sudo vtysh -c "show running-config"
   ```

3. **Restart FRRouting**:
   ```bash
   sudo systemctl restart frr
   ```

### Issue 3: Client Can't Receive Stream

**Solutions**:

1. **Check Windows Firewall** (allow VLC)

2. **Verify routing**:
   ```cmd
   route print
   tracert 192.168.1.10
   ```

3. **Check IGMP membership on Router R2**:
   ```bash
   sudo vtysh -c "show ip igmp groups"
   ```

4. **Increase VLC network caching** (300-1000ms)

### Issue 4: Guest machine not able to reach internet

**Solutions**:

In VirtualBox GUI, with the machine powered off, disable all except the NAT adapter.

If DNS fails, make sure the host DNS settings are correct and disable use of PiHole. 

## Advanced Scenarios

### Create mulitiple sources on one VM

Clone Source-1 VM naming it Sources and selecting to generate all new MAC addresses.

Start the VM and:

TODO NOT NECESSARY AND DIDN'T WORK - configure all sources to use the same source IP, but different multicast groups.

```bash
sudo nano /etc/network/interfaces
```

```bash
# Loopback interface
auto lo
iface lo inet loopback

# Primary network interface (source-network)
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.10/24
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4

iface enp0s3 inet static
    address 192.168.1.11/24
iface enp0s3 inet static
    address 192.168.1.12/24
iface enp0s3 inet static
    address 192.168.1.13/24
iface enp0s3 inet static
    address 192.168.1.14/24
iface enp0s3 inet static
    address 192.168.1.15/24
iface enp0s3 inet static
    address 192.168.1.16/24
iface enp0s3 inet static
    address 192.168.1.17/24
iface enp0s3 inet static
    address 192.168.1.18/24
iface enp0s3 inet static
    address 192.168.1.19/24

# NAT interface (for package installation - remove later)
allow-hotplug enp0s8
iface enp0s8 inet dhcp
```

Check the network configuration:

```bash
ip a
```

Enable the CD drive in the VM settings and point it to the Guest Additions ISO located in the VirtualBox installation folder (e.g. C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso).

Enable the NAT adapter as second NIC for package installation.

Once loaded in the VM, install guest additions:

```bash
sudo apt update
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
sudo mount /dev/cdrom /mnt
sudo /mnt/VBoxLinuxAdditions.run
```

Use VirtualBox manager to add a maximum of 10 number h264 raw video captures to the folder /usr/local/bin/video

Edit the streaming script to start multiple instances of GStreamer:

```bash
sudo nano /usr/local/bin/stream.sh
```

```bash
#!/bin/bash

# Directory containing MKV files
VIDEO_DIR="/usr/local/bin/videos"

# Starting IP address and multicast group
IP_BASE="192.168.1.10"
MCAST_BASE="232.1.1"
START_INDEX=10
PORT=5000

# PID file location
PID_FILE="/var/run/gstreamer_pids.txt"

# Function to cleanup existing streams
cleanup_streams() {
    if [ -f "$PID_FILE" ]; then
        echo "Cleaning up existing streams..."
        while read -r pid; do
            if ps -p "$pid" > /dev/null 2>&1; then
                echo "  Killing process $pid"
                kill "$pid" 2>/dev/null || kill -9 "$pid" 2>/dev/null
            fi
        done < "$PID_FILE"
        rm -f "$PID_FILE"
        echo "Cleanup complete. Waiting for processes to terminate..."
        sleep 2
    fi
}

# Trap signals to cleanup on exit
trap 'cleanup_streams; exit' SIGTERM SIGINT

# Cleanup any existing streams from previous runs
cleanup_streams

# Get list of MKV files
mapfile -t MKV_FILES < <(find "$VIDEO_DIR" -name "*.mkv" | sort)

if [ ${#MKV_FILES[@]} -eq 0 ]; then
    echo "No MKV files found in $VIDEO_DIR"
    exit 1
fi

echo "Found ${#MKV_FILES[@]} MKV file(s)"

# Function to stream a single file with seamless looping
stream_file() {
    local MKV_FILE="$1"
    local SOURCE_IP="$2"
    local MCAST_ADDR="$3"
    local PORT="$4"
    
    # Infinite loop to restart stream when it ends
    while true; do
        gst-launch-1.0 -q \
            filesrc location="$MKV_FILE" ! \
            matroskademux ! \
            h264parse ! \
            rtph264pay config-interval=2 pt=96 mtu=1400 ! \
            udpsink host="$MCAST_ADDR" port="$PORT" \
            bind-address="$SOURCE_IP" auto-multicast=true ttl-mc=5 \
            buffer-size=262144 sync=true
        
        # Brief pause before restarting (adjust if needed)
        sleep 0.05
    done
}

# Start a stream for each MKV file
INDEX=$START_INDEX
for MKV_FILE in "${MKV_FILES[@]}"; do
    SOURCE_IP="${IP_BASE}"
    MCAST_ADDR="${MCAST_BASE}.${INDEX}"
    FILENAME=$(basename "$MKV_FILE")
    
    echo "Starting looping stream $((INDEX - START_INDEX + 1)): $FILENAME"
    echo "  Source IP: $SOURCE_IP"
    echo "  Multicast: $MCAST_ADDR:$PORT"
    
    # Start stream in background with seamless looping
    stream_file "$MKV_FILE" "$SOURCE_IP" "$MCAST_ADDR" "$PORT" &
    
    # Store the PID for cleanup
    echo $! >> "$PID_FILE"
    
    # Increment for next stream
    ((INDEX++))
    
    # Small delay to avoid startup race conditions
    sleep 1
done

echo "All streams started with seamless looping. PIDs stored in $PID_FILE"
echo "Service is running. Press Ctrl+C to stop all streams."

# Keep script running to maintain streams
wait
```

### Add More Routers

You can extend the topology by adding more routers running FRRouting. Simply:
1. Create new Debian VMs
2. Install FRRouting
3. Configure PIM on all interfaces
4. Update routing tables

### Use OSPF for Dynamic Routing

Configure OSPF in FRRouting to automatically distribute routes:

```
router ospf
 network 192.168.1.0/24 area 0
 network 10.0.1.0/30 area 0
 network 192.168.2.0/24 area 0
```

### Monitor with FRR Tools

FRRouting includes powerful monitoring tools:
```bash
# Real-time PIM neighbor monitoring
sudo vtysh -c "show ip pim neighbor" -w

# Debug PIM packets
sudo vtysh -c "debug pim packets"
```

## References

- [FRRouting Documentation](https://docs.frrouting.org/)
- [FRRouting PIM Documentation](https://docs.frrouting.org/en/latest/pim.html)
- [RFC 4607 - Source-Specific Multicast for IP](https://tools.ietf.org/html/rfc4607)
- [GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)
- [VirtualBox Documentation](https://www.virtualbox.org/wiki/Documentation)
- [Debian Documentation](https://www.debian.org/doc/)
