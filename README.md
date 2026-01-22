# Simulate PIM-SSM Network with VirtualBox, FRRouting and GStreamer on Windows

A comprehensive guide to simulate a PIM-SSM (Protocol Independent Multicast - Source-Specific Multicast) network for testing custom video clients with source-specific multicast video streaming on a Windows computer.

This guide uses completely free and open-source software: **VirtualBox**, **Debian with FRRouting**, and **GStreamer**. The video client runs directly on the Windows host computer.

The various software used is subject to the licence terms of that software.

Shield: [![CC BY-SA 4.0][cc-by-sa-shield]][cc-by-sa]

These instructions are licensed under a
[Creative Commons Attribution-ShareAlike 4.0 International License][cc-by-sa].

[![CC BY-SA 4.0][cc-by-sa-image]][cc-by-sa]

[cc-by-sa]: http://creativecommons.org/licenses/by-sa/4.0/
[cc-by-sa-image]: https://licensebuttons.net/l/by-sa/4.0/88x31.png
[cc-by-sa-shield]: https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg

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
- **RAM**: Minimum 8GB (16GB recommended)
  - Each router VM: ~4GB
  - Each Debian source VM: ~6GB
  - Windows host overhead: ~2-4GB
- **Disk Space**: 40GB free space
- **Network**: Internet connection for initial setup

### Knowledge Requirements

- Basic Linux command line
- Basic networking concepts (IP addressing, routing)
- Understanding of multicast concepts (helpful but not required)

## Architecture Overview

```
┌───────────────────────────────────────────────────────────────┐
│                  Windows Host Computer                        │
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │           VirtualBox Virtual Machines                   │  │
│  │                                                         │  │
│  │       ┌─────────────────┐    ┌─────────────────┐        │  │
│  │       │ Sources-GST VM  │    │ Sources-MKV VM  │        │  │
│  │       │    GStreamer    │    │ GStreamer, MKV  │        │  │
│  │       │   192.168.1.11  │    │   192.168.1.21  │        │  │
│  │       └────────┬────────┘    └────────┬────────┘        │  │
│  │                └───────────┬──────────┘                 │  │
│  │                            │                            │  │
│  │                            │                            │  │
│  │                    ┌───────┴────────┐                   │  │
│  │                    │  192.168.1.1   │                   │  │
│  │                    │   Router R1    │                   │  │
│  │                    │  Debian + FRR  │                   │  │
│  │                    │  PIM-SM (SSM)  │                   │  │
│  │                    │    10.0.1.1    │                   │  │
│  │                    └───────┬────────┘                   │  │
│  │                            │                            │  │
│  │                    ┌───────┴────────┐                   │  │
│  │                    │    10.0.1.2    │                   │  │
│  │                    │   Router R2    │                   │  │
│  │                    │  Debian + FRR  │                   │  │
│  │                    │  PIM-SM (SSM)  │                   │  │
│  │                    │  192.168.2.254 │                   │  │
│  │                    └───────┬────────┘                   │  │
│  │                            │                            │  │
│  └────────────────────────────┼────────────────────────────┘  │
│                               │                               │
│                               │ (Host-Only Network)           │
│                               │ 192.168.2.0/24                │
│                               │                               │
│                      ┌────────┴─────────┐                     │
│                      │  Windows Client  │                     │
│                      │   VLC Player     │                     │
│                      │   192.168.2.1    │                     │
│                      └──────────────────┘                     │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

## Network Topology

### IP Addressing Plan

| Network Segment | Subnet | Purpose |
|----------------|--------|---------|
| Source Network | 192.168.1.0/24 | Multicast video sources |
| Client Network | 192.168.2.0/24 | Windows host video client |
| Core Link | 10.0.1.0/30 | R1 to R2 interconnect |

### Multicast Groups

We'll use the SSM range **232.0.0.0/8** (standard SSM range).

Sources-GST VM will stream the following multicast groups:

| Source | IP Address | Multicast Group | Port | Content |
|--------|------------|-----------------|------|---------|
| Source 1 | 192.168.1.11 | 232.1.1.11 | 5000 | Test Pattern 1 |
| Source 2 | 192.168.1.11 | 232.1.1.12 | 5000 | Test Pattern 2 |
| Source 3 | 192.168.1.11 | 232.1.1.13 | 5000 | Test Pattern 3 |

Sources-MKV VM will stream the following multicast groups:

| Source | IP Address | Multicast Group | Port | Content |
|--------|------------|-----------------|------|---------|
| Sources 1-x | 192.168.1.21 | 232.1.1.21-x | 5000 | MKV files |

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
- Clone the machine 2 times as Router-R2, Sources
- Amend each machine to have the network interfaces detailed below

TODO: Add guest additions install instructions

#### Create Router R1

```cmd
# Create VM
VBoxManage createvm --name "Router-R1" --ostype "Debian_64" --register

# Configure VM
VBoxManage modifyvm "Router-R1" ^
  --memory 1024 ^
  --vram 16 ^
  --cpus 3 ^
  --nic1 intnet --intnet1 "source-network" --nictype1 virtio ^
  --nic2 intnet --intnet2 "core-link1" --nictype2 virtio ^
  --nic3 nat --nictype3 virtio ^
  --boot1 disk --boot2 dvd ^
  --ioapic on ^
  --pae on ^
  --audio-driver none

# Add storage controller
VBoxManage storagectl "Router-R1" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Router-R1" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd "C:\Users\[username]\VirtualBox VMs\Router-R1"
VBoxManage createmedium disk --filename Router-R1.vdi --size 20480
VBoxManage storageattach "Router-R1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R1.vdi --nonrotational on
```

#### Create Router R2

```cmd
# Create VM
VBoxManage createvm --name "Router-R2" --ostype "Debian_64" --register

# Configure VM
VBoxManage modifyvm "Router-R2" ^
  --memory 1024 ^
  --vram 16 ^
  --cpus 2 ^
  --nic1 intnet --intnet1 "core-link1" --nictype1 virtio ^
  --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" --nictype2 virtio ^
  --nic3 nat --nictype3 virtio ^
  --boot1 disk --boot2 dvd ^
  --ioapic on ^
  --pae on ^
  --audio-driver none

# Note: Replace "VirtualBox Host-Only Ethernet Adapter" with your actual adapter name
# Use 'VBoxManage list hostonlyifs' to see available host-only adapters

# Add storage controller
VBoxManage storagectl "Router-R2" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Router-R2" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd ..\Router-R2
VBoxManage createmedium disk --filename Router-R2.vdi --size 20480
VBoxManage storageattach "Router-R2" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R2.vdi --nonrotational on
```

**Note**: Router R2's second NIC is configured as a host-only adapter, allowing the Windows host to communicate with the network as a client.

### Step 3: Configure Network Topology

#### Create Sources-GST VM

Create Debian VM for GStreamer generated multicast sources:

```cmd
VBoxManage createvm --name "Sources-GST" --ostype "Debian_64" --register

VBoxManage modifyvm "Sources-GST" ^
  --memory 2048 ^
  --vram 128 ^
  --cpus 2 ^
  --nic1 intnet --intnet1 "source-network" --nictype1 virtio ^
  --nic2 nat --nictype2 virtio ^
  --boot1 disk --boot2 dvd ^
  --pae on

# Add storage controller
VBoxManage storagectl "Sources-GST" --name "SATA" --add sata --controller IntelAhci

# Attach Debian ISO for installation
VBoxManage storageattach "Sources-GST" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium \path\to\debian.iso

# Create virtual disk
cd Sources-GST
VBoxManage createmedium disk --filename Sources-GST.vdi --size 20480
VBoxManage storageattach "Sources-GST" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Sources-GST.vdi --nonrotational on
```

Note: Once this VM is fully configured, we'll clone it to create the Sources-MKV VM.

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

The NAT network adapter in each VM allows this and should be enabled during setup.

The other network adapters can be disabled temporarily if needed.

#### Enable SSH access for easier management

Using the GUI add port forwarding to allow SSH access to the VMs from the host machine during setup:
 - Host IP 127.0.0.1, host port 2222, guest port 22 for Router-R1
 - Host IP 127.0.0.1, host port 2322, guest port 22 for Router-R2
 - Host IP 127.0.0.1, host port 2422, guest port 22 for Sources-GST
 - Host IP 127.0.0.1, host port 2522, guest port 22 for Sources-MKV (Add after the VM is created)

To connect from Windows use an SSH client such as PuTTY to connect to 127.0.0.1:2222 / 127.0.0.1:2322 / 127.0.0.1:2422 / 127.0.0.1:2522

### Step 4: Configure FRRouting Routers

#### Install Debian and FRRouting on Router R1

1. **Install Debian** on Router-R1 VM:
   - See steps above for installation instructions.

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
       up ip route add 192.168.2.0/24 via 10.0.1.2

   # NAT interface (for package installation)
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

#### Disable NAT Adapters (After Package Installation)

Disable the NAT adapter and enable all other network adapters on each VM in VirtualBox GUI.

### Step 5: Setup Multicast Sources

Install Debian on the Sources-GST VM, then configure static IP and install GStreamer.

#### Install and Configure Sources

1. **Install Debian** on Sources-GST VM

2. **Configure static IP** - Edit `/etc/network/interfaces`:

   ```bash
   sudo nano /etc/network/interfaces
   ```

   Configuration:
   ```
   # Loopback interface
   auto lo
   iface lo inet loopback

   # Prinary network interface (source-network)
   auto enp0s3
   iface enp0s3 inet static
       address 192.168.1.11
       netmask 255.255.255.0
       gateway 192.168.1.1

   # NAT interface (for package installation)
   allow-hotplug enp0s8
   iface enp0s8 inet dhcp
   ```

   Apply changes:
   ```bash
   sudo systemctl restart networking
   ```

3. **Install GStreamer**:

   ```bash
   sudo apt update
   sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
     gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
     gstreamer1.0-plugins-ugly gstreamer1.0-libav
   ```

5. **Create streaming script** - Create `/usr/local/bin/streams.sh`:

```bash
sudo nano /usr/local/bin/streams.sh
```

```bash
#!/bin/bash

# Starting IP address and multicast group
IP_BASE="192.168.1"
MCAST_BASE="232.1.1"
START_INDEX=11
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

# Initialize index
INDEX=$START_INDEX
SOURCE_IP="${IP_BASE}.${INDEX}"     # Same for all sources

# Stream test pattern 1
MCAST_ADDR="${MCAST_BASE}.${INDEX}"
gst-launch-1.0 -q \
    videotestsrc is-live=true pattern=smpte horizontal-speed=1 ! \
    video/x-raw,width=720,height=576,framerate=25/1 ! \
    textoverlay text="Source 1 - SMPTE Bars" valignment=top halignment=left font-desc="Sans, 32" ! \
    x264enc tune=zerolatency bitrate=2000 speed-preset=superfast  key-int-max=2 byte-stream=true ! \
    video/x-h264,profile=baseline ! \
    rtph264pay config-interval=-1 pt=96 mtu=1400 ! \
    udpsink host="$MCAST_ADDR" port="$PORT" \
    bind-address="$SOURCE_IP" auto-multicast=true ttl-mc=5 \
    buffer-size=262144 sync=true &

# Store the PID for cleanup
echo $! >> "$PID_FILE"

# Increment for next stream
((INDEX++))

# Stream test pattern 2
MCAST_ADDR="${MCAST_BASE}.${INDEX}"
gst-launch-1.0 -q \
    videotestsrc is-live=true pattern=snow horizontal-speed=2 ! \
    video/x-raw,width=720,height=576,framerate=25/1 ! \
    textoverlay text="Source 2 - Snow Pattern" valignment=top halignment=left font-desc="Sans, 32" ! \
    x264enc tune=zerolatency bitrate=2000 speed-preset=superfast  key-int-max=2 byte-stream=true ! \
    video/x-h264,profile=baseline ! \
    rtph264pay config-interval=-1 pt=96 mtu=1400 ! \
    udpsink host="$MCAST_ADDR" port="$PORT" \
    bind-address="$SOURCE_IP" auto-multicast=true ttl-mc=5 \
    buffer-size=262144 sync=true &

# Store the PID for cleanup
echo $! >> "$PID_FILE"

# Increment for next stream
((INDEX++))

# Stream test pattern 3 (H265)
MCAST_ADDR="${MCAST_BASE}.${INDEX}"
gst-launch-1.0 -q \
    videotestsrc is-live=true pattern=circular horizontal-speed=2 ! \
    video/x-raw,width=360,height=288,framerate=25/1 ! \
    textoverlay text="Source 3 - H265 Circular" valignment=top halignment=left font-desc="Sans, 32" ! \
    x265enc tune=zerolatency bitrate=2000 speed-preset=superfast key-int-max=2 ! \
    video/x-h265,profile=main,stream-format=byte-stream,alignment=au ! \
    rtph265pay config-interval=1 pt=96 mtu=1400 ! \
    udpsink host="$MCAST_ADDR" port="$PORT" \
    bind-address="$SOURCE_IP" auto-multicast=true ttl-mc=5 \
    buffer-size=262144 sync=true &

# Store the PID for cleanup
echo $! >> "$PID_FILE"

# Increment for next stream
((INDEX++))

echo "All streams started. PIDs stored in $PID_FILE"
echo "Service is running. Press Ctrl+C to stop all streams."

# Keep script running to maintain streams
wait
```

   Make executable:
   ```bash
   sudo chmod +x /usr/local/bin/streams.sh
   ```

5. **Test the streams**:
   ```bash
   sudo /usr/local/bin/streams.sh
   ```

   Likely to fail at this point if the source network adapter is not enabled.

6. **Make the streams start on boot**

    Create service file:
    ```bash
    sudo nano /etc/systemd/system/streams.service
    ```

    Add:
```bash
[Unit]
Description=Multicast RTP test streams
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/streams.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

7. **Disable NAT adapter**:

   Shutdown the VM:
   ```bash
   sudo poweroff
   ```

   Modify network adapters:
   - Disable NAT adapter in VirtualBox GUI.
   - Enable all other network adapters (source-network).
   - Start the VM.

8. **Start the streaming service and check status**

    Enable and start the service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable streams.service
    sudo systemctl start streams.service
    ```

    Check status and logs:
    ```bash
    sudo systemctl status streams.service
    sudo journalctl -u streams.service -b
    ```

    Note: The streams will fail if the network adapters are disabled because GStreamer cannot join the multicast group.

9. Clone the Sources-GST VM to create Sources-MKV VM:

 - Power off the Sources-GST VM.
 - In VirtualBox, right-click the Sources-GST VM and select "Clone".
 - Name the new VM "Sources-MKV", choose "Full clone" and create all new MAC addresses.
 - Start the Sources-MKV VM.

10. Use VirtualBox manager to add a maximum of 10 number h264 raw video captures to the folder /usr/local/bin/video

```bash
sudo mkdir -p /usr/local/bin/videos
```

Use the GUI to add MKV files to this folder.

11. **Edit the network settings** `/etc/network/interfaces`:

```bash
sudo nano /etc/network/interfaces
```

   ```
   # Loopback interface
   auto lo
   iface lo inet loopback

   # Prinary network interface (source-network)
   auto enp0s3
   iface enp0s3 inet static
       address 192.168.1.21
       netmask 255.255.255.0
       gateway 192.168.1.1

   # NAT interface (for package installation)
   allow-hotplug enp0s8
   iface enp0s8 inet dhcp
   ```

   Apply changes:
   ```bash
   sudo systemctl restart networking
   ```

12. **Edit the streaming script** `/usr/local/bin/streams.sh`:

```bash
sudo nano /usr/local/bin/streams.sh
```

```bash
#!/bin/bash

# Directory containing MKV files
VIDEO_DIR="/usr/local/bin/videos"

# Starting IP address and multicast group
IP_BASE="192.168.1"
MCAST_BASE="232.1.1"
START_INDEX=21
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
            rtph264pay config-interval=-1 pt=96 mtu=1400 ! \
            udpsink host="$MCAST_ADDR" port="$PORT" \
            bind-address="$SOURCE_IP" auto-multicast=true ttl-mc=5 \
            buffer-size=262144 sync=true
        
        # Brief pause before restarting (adjust if needed)
        sleep 0.05
    done
}

# Initialize index
INDEX=$START_INDEX
SOURCE_IP="${IP_BASE}.${INDEX}"     # Same for all sources

# Start a stream for each MKV file
for MKV_FILE in "${MKV_FILES[@]}"; do
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

   Make executable:
   ```bash
   sudo chmod +x /usr/local/bin/streams.sh
   ```

12. **Test the streams**:
   ```bash
   sudo /usr/local/bin/streams.sh
   ```

   Likely to fail at this point if the source network adapter is not enabled.

13. **Disable NAT adapter**:

   Shutdown the VM:
   ```bash
   sudo poweroff
   ```

   Modify network adapters:
   - Disable NAT adapter in VirtualBox GUI.
   - Enable all other network adapters (source-network).
   - Start the VM.

14. **Start the streaming service and check status**

    Enable and start the service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable streams.service
    sudo systemctl start streams.service
    ```

    Check status and logs:
    ```bash
    sudo systemctl status streams.service
    sudo journalctl -u streams.service -b
    ```

    Note: The streams will fail if the network adapters are disabled because GStreamer cannot join the multicast group.

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

Note: Source IP address is the same for all streams from each Sources VM.

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.11 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.12 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.13 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph265depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.21 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

gst-launch-1.0 -v udpsrc port=5000 multicast-group=232.1.1.22 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

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
sudo tcpdump -i enp0s3 dst host 232.1.1.11 or dst host 232.1.1.12 or dst host 232.1.1.13
```

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
