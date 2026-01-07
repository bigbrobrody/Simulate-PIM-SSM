# Simulate PIM-SSM Network with VirtualBox, OpenWRT and GStreamer on Windows

A comprehensive guide to simulate a PIM-SSM (Protocol Independent Multicast - Source-Specific Multicast) network for testing custom video clients with source-specific multicast video streaming on a Windows host computer.

This guide uses completely free and open-source software: **VirtualBox**, **OpenWRT**, and **GStreamer**. The video client runs directly on the Windows host computer.

## Table of Contents
- [Introduction](#introduction)
- [Why This Approach?](#why-this-approach)
- [Prerequisites](#prerequisites)
- [Architecture Overview](#architecture-overview)
- [Network Topology](#network-topology)
- [Setup Instructions](#setup-instructions)
  - [Step 1: Install VirtualBox](#step-1-install-virtualbox)
  - [Step 2: Create OpenWRT Router VMs](#step-2-create-openwrt-router-vms)
  - [Step 3: Configure Network Topology](#step-3-configure-network-topology)
  - [Step 4: Configure OpenWRT Routers](#step-4-configure-openwrt-routers)
  - [Step 5: Setup Multicast Sources](#step-5-setup-multicast-sources)
  - [Step 6: Setup Video Client on Windows Host](#step-6-setup-video-client-on-windows-host)
- [Testing and Verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)
- [Advanced Scenarios](#advanced-scenarios)
- [References](#references)

## Introduction

PIM-SSM (Source-Specific Multicast) is a multicast routing protocol that allows receivers to specify both the multicast group **and** the specific source they want to receive traffic from. This is particularly useful for:

- **Video streaming applications** where clients subscribe to specific video sources
- **IPTV systems** with multiple channels from different sources
- **Security camera systems** with many video feeds
- **Testing custom multicast video clients** in a controlled environment

This simulation allows you to create a complete PIM-SSM network environment on a single Windows computer using free, open-source tools, with the video client running natively on Windows.

## Why This Approach?

### Advantages over GNS3/Commercial Solutions

1. **100% Free and Open Source** - No licensing costs or pirated software needed
2. **Lightweight** - OpenWRT routers use minimal resources
3. **Real-world applicable** - OpenWRT is used in production environments
4. **Easy to replicate** - All software is freely downloadable
5. **Multiple sources** - Easy to simulate many video sources simultaneously
6. **Native Windows client** - Video client runs directly on Windows host without VM overhead

### What You'll Build

- A multi-router PIM-SSM network running in VirtualBox VMs
- Multiple multicast video sources streaming different content
- A Windows-native video client that can subscribe to specific sources
- A complete test environment for source-specific multicast applications

## Prerequisites

### Software Requirements

| Software | Version | Purpose | Download |
|----------|---------|---------|----------|
| **VirtualBox** | 6.1 or later | Virtualization platform | [virtualbox.org](https://www.virtualbox.org/wiki/Downloads) |
| **OpenWRT** | 21.02 or later | Router operating system | [openwrt.org](https://openwrt.org/downloads) |
| **Ubuntu/Debian** | 20.04+ | For source VMs | [ubuntu.com](https://ubuntu.com/download/desktop) |
| **VLC Media Player** | Latest | Video client on Windows | [videolan.org](https://www.videolan.org/vlc/download-windows.html) |

### Hardware Requirements

- **Operating System**: Windows 10 or 11 (64-bit)
- **CPU**: Modern multi-core processor (4+ cores recommended)
- **RAM**: Minimum 8GB (12GB recommended)
  - Each OpenWRT router: ~256MB
  - Each Ubuntu VM: ~2GB
  - Windows host overhead: ~2-4GB
- **Disk Space**: 30GB free space
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
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │  │
│  │         │                  │                  │        │  │
│  │         └──────────────────┴──────────────────┘        │  │
│  │                            │                           │  │
│  │                    ┌───────┴────────┐                  │  │
│  │                    │   Router R1    │                  │  │
│  │                    │   (OpenWRT)    │                  │  │
│  │                    │   PIM-SSM      │                  │  │
│  │                    └───────┬────────┘                  │  │
│  │                            │                           │  │
│  │                    ┌───────┴────────┐                  │  │
│  │                    │   Router R2    │                  │  │
│  │                    │   (OpenWRT)    │                  │  │
│  │                    │   PIM-SSM      │                  │  │
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
```bash
VBoxManage --version
```

### Step 2: Create OpenWRT Router VMs

We'll create two OpenWRT router VMs (R1, R2).

#### Download OpenWRT Image

1. Visit [OpenWRT Downloads](https://openwrt.org/downloads)
2. Download the **x86-64 combined image** (e.g., `openwrt-21.02.3-x86-64-generic-ext4-combined.img.gz`)
3. Extract the image:
   ```bash
   expand openwrt-21.02.3-x86-64-generic-ext4-combined.img.gz openwrt-21.02.3-x86-64-generic-ext4-combined.img
   ```

#### Convert to VirtualBox Format

```bash
VBoxManage convertfromraw openwrt-21.02.3-x86-64-generic-ext4-combined.img openwrt.vdi --format VDI
```

#### Create Router R1

```bash
# Create VM
VBoxManage createvm --name "Router-R1" --ostype "Linux26_64" --register

# Configure VM
VBoxManage modifyvm "Router-R1" \
  --memory 256 \
  --vram 16 \
  --cpus 1 \
  --nic1 intnet --intnet1 "source-network" \
  --nic2 intnet --intnet2 "core-link1" \
  --boot1 disk --boot2 none --boot3 none --boot4 none

# Create and attach storage
VBoxManage storagectl "Router-R1" --name "SATA" --add sata --controller IntelAhci
VBoxManage clonemedium disk openwrt.vdi Router-R1.vdi
VBoxManage storageattach "Router-R1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R1.vdi
```

#### Create Router R2

```bash
# Create VM
VBoxManage createvm --name "Router-R2" --ostype "Linux26_64" --register

# Configure VM
VBoxManage modifyvm "Router-R2" \
  --memory 256 \
  --vram 16 \
  --cpus 1 \
  --nic1 intnet --intnet1 "core-link1" \
  --nic2 hostonly --hostonlyadapter2 "VirtualBox Host-Only Ethernet Adapter" \
  --boot1 disk --boot2 none --boot3 none --boot4 none

# Note: Replace "VirtualBox Host-Only Ethernet Adapter" with your actual adapter name
# Use 'VBoxManage list hostonlyifs' to see available host-only adapters

# Create and attach storage
VBoxManage storagectl "Router-R2" --name "SATA" --add sata --controller IntelAhci
VBoxManage clonemedium disk openwrt.vdi Router-R2.vdi
VBoxManage storageattach "Router-R2" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Router-R2.vdi
```

**Note**: Router R2's second NIC is configured as a host-only adapter, allowing the Windows host to communicate with the network as a client.

### Step 3: Configure Network Topology

#### Create Source VMs

Create 3 Ubuntu VMs for multicast sources:

```bash
# For each source (repeat for Source-1, Source-2, Source-3)
VBoxManage createvm --name "Source-1" --ostype "Ubuntu_64" --register

VBoxManage modifyvm "Source-1" \
  --memory 2048 \
  --vram 128 \
  --cpus 2 \
  --nic1 intnet --intnet1 "source-network" \
  --boot1 disk --boot2 dvd

# Add storage controller
VBoxManage storagectl "Source-1" --name "SATA" --add sata --controller IntelAhci

# Attach Ubuntu ISO for installation
VBoxManage storageattach "Source-1" --storagectl "SATA" --port 1 --device 0 --type dvddrive --medium /path/to/ubuntu-20.04.iso

# Create virtual disk
VBoxManage createmedium disk --filename Source-1.vdi --size 20480
VBoxManage storageattach "Source-1" --storagectl "SATA" --port 0 --device 0 --type hdd --medium Source-1.vdi
```

Repeat for Source-2 and Source-3, adjusting the names accordingly.

#### Setup VirtualBox Host-Only Network

To allow the Windows host to communicate with the simulated network:

1. Open VirtualBox Manager
2. Go to **File > Host Network Manager**
3. Create a new host-only network (or use existing) with:
   - IPv4 Address: 192.168.2.1
   - IPv4 Network Mask: 255.255.255.0
   - DHCP Server: Disabled

This network will allow your Windows host to act as a video client.

### Step 4: Configure OpenWRT Routers

Start each router VM and configure via console.

#### Router R1 Configuration (Core Router)

1. **Start Router-R1 and access console**
   ```bash
   VBoxManage startvm "Router-R1"
   ```

2. **Configure network interfaces** - Login (no password by default) and edit `/etc/config/network`:

   ```bash
   vi /etc/config/network
   ```

   Configuration:
   ```
   config interface 'loopback'
       option device 'lo'
       option proto 'static'
       option ipaddr '127.0.0.1'
       option netmask '255.0.0.0'

   config device
       option name 'br-lan'
       option type 'bridge'
       list ports 'eth0'

   config interface 'lan'
       option device 'br-lan'
       option proto 'static'
       option ipaddr '192.168.1.1'
       option netmask '255.255.255.0'

   config interface 'core1'
       option device 'eth1'
       option proto 'static'
       option ipaddr '10.0.1.1'
       option netmask '255.255.255.252'
   ```

3. **Configure routing**:

   ```bash
   vi /etc/config/network
   ```

   Add static route:
   ```
   config route
       option interface 'core1'
       option target '192.168.2.0'
       option netmask '255.255.255.0'
       option gateway '10.0.1.2'
   ```

4. **Install PIM-SSM packages**:

   ```bash
   opkg update
   opkg install pimd-dense igmpproxy
   ```

5. **Configure PIM** - Create `/etc/pimd.conf`:

   ```bash
   vi /etc/pimd.conf
   ```

   Configuration:
   ```
   # Enable PIM on all interfaces
   phyint eth0 enable
   phyint eth1 enable

   # SSM group range
   # Use 232.0.0.0/8 for SSM
   spt-threshold infinity

   # Bootstrap Router settings
   bsr-candidate eth0 priority 5
   rp-candidate eth0 priority 5
   ```

6. **Enable and start services**:

   ```bash
   /etc/init.d/network restart
   /etc/init.d/pimd enable
   /etc/init.d/pimd start
   ```

#### Router R2 Configuration

1. **Start Router-R2 and configure** `/etc/config/network`:

   ```
   config interface 'loopback'
       option device 'lo'
       option proto 'static'
       option ipaddr '127.0.0.1'
       option netmask '255.0.0.0'

   config interface 'core1'
       option device 'eth0'
       option proto 'static'
       option ipaddr '10.0.1.2'
       option netmask '255.255.255.252'

   config device
       option name 'br-lan'
       option type 'bridge'
       list ports 'eth1'

   config interface 'lan'
       option device 'br-lan'
       option proto 'static'
       option ipaddr '192.168.2.254'
       option netmask '255.255.255.0'
   ```

2. **Add default route**:

   ```
   config route
       option interface 'core1'
       option target '0.0.0.0'
       option netmask '0.0.0.0'
       option gateway '10.0.1.1'
   ```

3. **Install and configure PIM**:

   ```bash
   opkg update
   opkg install pimd-dense igmpproxy
   ```

   Create `/etc/pimd.conf`:
   ```
   phyint eth0 enable
   phyint eth1 enable
   spt-threshold infinity
   ```

4. **Enable IGMP Proxy** - Create `/etc/config/igmpproxy`:

   ```
   config igmpproxy
       option quickleave 1

   config phyint
       option network 'core1'
       option direction 'upstream'
       list altnet '0.0.0.0/0'

   config phyint
       option network 'lan'
       option direction 'downstream'
   ```

5. **Start services**:

   ```bash
   /etc/init.d/network restart
   /etc/init.d/pimd enable
   /etc/init.d/pimd start
   /etc/init.d/igmpproxy enable
   /etc/init.d/igmpproxy start
   ```

**Note**: Router R2's LAN interface (192.168.2.254) is on the same network as the Windows host (192.168.2.1), allowing the host to receive multicast streams.

### Step 5: Setup Multicast Sources

Install Ubuntu on each source VM, then configure static IP and install GStreamer.

#### Install and Configure Source-1

1. **Install Ubuntu** on Source-1 VM through the VirtualBox GUI

2. **Configure static IP** - Edit `/etc/netplan/01-netcfg.yaml`:

   ```yaml
   network:
     version: 2
     ethernets:
       enp0s3:
         addresses:
           - 192.168.1.10/24
         gateway4: 192.168.1.1
         nameservers:
           addresses: [8.8.8.8, 8.8.4.4]
   ```

   Apply:
   ```bash
   sudo netplan apply
   ```

3. **Install GStreamer**:

   ```bash
   sudo apt update
   sudo apt install -y gstreamer1.0-tools gstreamer1.0-plugins-base \
     gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
     gstreamer1.0-plugins-ugly gstreamer1.0-libav
   ```

4. **Create streaming script** - Create `/home/user/stream.sh`:

   ```bash
   #!/bin/bash
   # Stream test pattern 1 to 232.1.1.1:5000
   gst-launch-1.0 -v \
     videotestsrc pattern=smpte horizontal-speed=1 ! \
     video/x-raw,width=1280,height=720,framerate=30/1 ! \
     textoverlay text="Source 1 - SMPTE Bars" valignment=top halignment=left font-desc="Sans, 32" ! \
     x264enc tune=zerolatency bitrate=2000 speed-preset=superfast ! \
     mpegtsmux ! \
     udpsink host=232.1.1.1 port=5000 auto-multicast=true ttl-mc=5
   ```

   Make executable:
   ```bash
   chmod +x /home/user/stream.sh
   ```

5. **Test the stream**:

   ```bash
   ./stream.sh
   ```

#### Configure Source-2 and Source-3

Repeat the above for Source-2 (192.168.1.11) and Source-3 (192.168.1.12), but use different patterns and multicast addresses:

**Source-2 stream script** (`232.1.1.2`):
```bash
#!/bin/bash
gst-launch-1.0 -v \
  videotestsrc pattern=snow horizontal-speed=2 ! \
  video/x-raw,width=1280,height=720,framerate=30/1 ! \
  textoverlay text="Source 2 - Snow Pattern" valignment=top halignment=left font-desc="Sans, 32" ! \
  x264enc tune=zerolatency bitrate=2000 speed-preset=superfast ! \
  mpegtsmux ! \
  udpsink host=232.1.1.2 port=5000 auto-multicast=true ttl-mc=5
```

**Source-3 stream script** (`232.1.1.3`):
```bash
#!/bin/bash
gst-launch-1.0 -v \
  videotestsrc pattern=circular horizontal-speed=3 ! \
  video/x-raw,width=1280,height=720,framerate=30/1 ! \
  textoverlay text="Source 3 - Circular" valignment=top halignment=left font-desc="Sans, 32" ! \
  x264enc tune=zerolatency bitrate=2000 speed-preset=superfast ! \
  mpegtsmux ! \
  udpsink host=232.1.1.3 port=5000 auto-multicast=true ttl-mc=5
```

#### Create Systemd Service (Optional)

To auto-start streams on boot:

```bash
sudo vi /etc/systemd/system/multicast-stream.service
```

```ini
[Unit]
Description=Multicast Video Stream
After=network.target

[Service]
Type=simple
User=yourusername
ExecStart=/home/yourusername/stream.sh
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable multicast-stream.service
sudo systemctl start multicast-stream.service
```

### Step 6: Setup Video Client on Windows Host

The video client runs directly on your Windows host computer, eliminating the need for a separate VM.

#### Configure Windows Network

1. **Open Network Connections**:
   - Press `Win + R`, type `ncpa.cpl`, and press Enter
   - Find the VirtualBox Host-Only Network adapter (e.g., "VirtualBox Host-Only Ethernet Adapter")

2. **Configure Static IP** (if not already configured):
   - Right-click the adapter → Properties
   - Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties
   - Set:
     - IP address: `192.168.2.1`
     - Subnet mask: `255.255.255.0`
     - Default gateway: `192.168.2.254` (Router R2)
   - Click OK

3. **Verify connectivity**:
   ```cmd
   ping 192.168.2.254
   ```

#### Install VLC Media Player

1. **Download VLC**:
   - Visit [https://www.videolan.org/vlc/download-windows.html](https://www.videolan.org/vlc/download-windows.html)
   - Download the latest 64-bit installer

2. **Install VLC**:
   - Run the installer
   - Follow the installation wizard
   - Complete the installation

#### Test Receiving Multicast Stream

1. **Open VLC Media Player**

2. **Open Network Stream**:
   - Go to **Media > Open Network Stream** (or press `Ctrl+N`)
   - Enter the multicast address:
     - For Source 1: `udp://@232.1.1.1:5000`
     - For Source 2: `udp://@232.1.1.2:5000`
     - For Source 3: `udp://@232.1.1.3:5000`
   - Click **Play**

3. **Create a playlist** for easy switching between sources:
   - Go to **Media > Open Multiple Files**
   - Click **Add** and enter each multicast address:
     - `udp://@232.1.1.1:5000`
     - `udp://@232.1.1.2:5000`
     - `udp://@232.1.1.3:5000`
   - Check "Show more options" and set "Caching" to 300ms or higher
   - Click **Play**

#### Alternative: Command Line Playback

You can also use VLC from the Windows command line:

```cmd
"C:\Program Files\VideoLAN\VLC\vlc.exe" udp://@232.1.1.1:5000
```

**Note**: Adjust the path if you installed the 32-bit version (`C:\Program Files (x86)\VideoLAN\VLC\vlc.exe`) or used a custom installation directory.

#### Troubleshooting Windows Firewall

If you don't receive multicast traffic:

1. **Allow VLC through Windows Firewall**:
   - Open Windows Defender Firewall
   - Click "Allow an app or feature through Windows Defender Firewall"
   - Find VLC Media Player and enable both Private and Public networks
   - Click OK

2. **Or temporarily disable firewall for testing** (not recommended for production):
   ```cmd
   netsh advfirewall set allprofiles state off
   ```

   To re-enable:
   ```cmd
   netsh advfirewall set allprofiles state on
   ```

## Testing and Verification

### Step 1: Verify Network Connectivity

From each source VM, ping the router:
```bash
ping 192.168.1.1
```

### Step 2: Verify Multicast Routing

On each OpenWRT router, check PIM neighbors:
```bash
# On Router R1
ip mroute show
cat /proc/net/igmp
```

Check that multicast routes are being established.

### Step 3: Start Multicast Sources

Start the streaming scripts on all three source VMs:
```bash
# On Source-1
./stream.sh

# On Source-2
./stream.sh

# On Source-3
./stream.sh
```

### Step 4: Monitor Multicast Traffic

On Router R1, monitor multicast traffic:
```bash
tcpdump -i eth0 dst host 232.1.1.1 or dst host 232.1.1.2 or dst host 232.1.1.3
```

### Step 5: Test Client Reception

On Windows host, open VLC and receive each source:

1. **Open VLC Media Player**
2. **Media > Open Network Stream**
3. **Enter multicast address**:
   - Source 1: `udp://@232.1.1.1:5000`
   - Source 2: `udp://@232.1.1.2:5000`
   - Source 3: `udp://@232.1.1.3:5000`
4. **Click Play**

You should see the video stream from the selected source.

### Step 6: Verify Source-Specific Multicast

Use Wireshark on Windows to verify SSM is working:

1. **Download and install Wireshark** from [wireshark.org](https://www.wireshark.org/download.html)
2. **Start capture** on the VirtualBox Host-Only adapter
3. **Filter for IGMP**: `igmp`
4. **Look for IGMPv3 Membership Reports** with SOURCE records when you start playing a stream in VLC

### Step 7: Check IGMP Membership

On Router R2:
```bash
cat /proc/net/igmp
```

Should show multicast groups that the Windows client has joined.

## Troubleshooting

### Issue 1: No Multicast Traffic Reaching Clients

**Symptoms**: VLC shows "no input" or blank screen

**Solutions**:

1. **Verify multicast routing is enabled** on all routers:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   # Should return 1
   ```

2. **Check firewall rules**:
   ```bash
   iptables -L -v -n
   ```
   
   Allow multicast if blocked:
   ```bash
   iptables -A INPUT -d 224.0.0.0/4 -j ACCEPT
   iptables -A FORWARD -d 224.0.0.0/4 -j ACCEPT
   ```

3. **Verify PIM is running**:
   ```bash
   ps | grep pimd
   /etc/init.d/pimd status
   ```

4. **Check TTL on source**:
   Ensure multicast TTL is >1 in GStreamer command (`ttl-mc=5`)

### Issue 2: Client Can't Join Multicast Group

**Symptoms**: IGMP membership not showing on router, Windows client not receiving stream

**Solutions**:

1. **Check Windows Firewall**:
   - Ensure VLC is allowed through Windows Firewall
   - Or temporarily disable firewall for testing

2. **Verify network adapter settings**:
   ```cmd
   ipconfig /all
   ```
   Ensure the VirtualBox Host-Only adapter has IP 192.168.2.1

3. **Check routing table**:
   ```cmd
   route print
   ```
   Ensure there's a route to 192.168.2.0/24 via the Host-Only adapter

4. **Verify Router R2 connectivity**:
   ```cmd
   ping 192.168.2.254
   ```

5. **Check IGMP proxy configuration** on Router R2

### Issue 3: Routers Not Forming PIM Adjacencies

**Symptoms**: No multicast routes between routers

**Solutions**:

1. **Check PIM configuration** in `/etc/pimd.conf`

2. **Restart PIM daemon**:
   ```bash
   /etc/init.d/pimd restart
   ```

3. **Verify IP connectivity** between routers:
   ```bash
   ping 10.0.1.1  # From R2 to R1
   ```

### Issue 4: High Packet Loss or Jitter

**Symptoms**: Choppy video playback

**Solutions**:

1. **Increase VirtualBox network performance**:
   - Use paravirtualized network adapters
   - Allocate more CPU to VMs

2. **Lower bitrate** in GStreamer:
   ```bash
   # Change bitrate=2000 to bitrate=1000
   x264enc tune=zerolatency bitrate=1000 speed-preset=superfast
   ```

3. **Check host CPU usage** - Close unnecessary applications

### Issue 5: Stream Not Starting

**Symptoms**: GStreamer errors or no output from source VMs

**Solutions**:

1. **Test GStreamer pipeline** locally first:
   ```bash
   gst-launch-1.0 videotestsrc ! autovideosink
   ```

2. **Check GStreamer plugins**:
   ```bash
   gst-inspect-1.0 x264enc
   gst-inspect-1.0 udpsink
   ```

3. **Verify network interface** is up:
   ```bash
   ip addr show
   ```

### Issue 6: Windows Client Not Receiving Stream

**Symptoms**: VLC shows "no input" or blank screen on Windows

**Solutions**:

1. **Check VLC caching settings**:
   - In VLC: Tools > Preferences > Input/Codecs
   - Increase "Network Caching" to 1000ms or higher

2. **Verify multicast traffic reaching Windows**:
   - Open Command Prompt as Administrator
   - Run: `netsh interface ipv4 show joins`
   - Should show joined multicast groups

3. **Test with different player**:
   - Try FFplay (requires FFmpeg to be installed): `ffplay -i udp://@232.1.1.1:5000`
   - Download FFmpeg from [ffmpeg.org](https://ffmpeg.org/download.html) if needed

4. **Check network statistics**:
   ```cmd
   netstat -s -p udp
   ```
   Look for packet loss or errors

## Advanced Scenarios

### Multiple Clients on Same Network

You can run multiple instances of VLC on Windows to simulate multiple clients subscribing to different sources:

1. **Open multiple VLC windows**
2. **Each window can play a different source**:
   - Window 1: `udp://@232.1.1.1:5000`
   - Window 2: `udp://@232.1.1.2:5000`
   - Window 3: `udp://@232.1.1.3:5000`

Alternatively, you can add additional VMs as clients if needed by connecting them to the same host-only network (192.168.2.0/24).

### Load Testing with Many Sources

Create 10+ source VMs to simulate a large IPTV network:

```bash
# Automated source creation script
for i in {1..10}; do
    IP="192.168.1.$((10+i))"
    MCAST="232.1.1.$i"
    
    echo "Creating source $i: IP=$IP, Multicast=$MCAST"
    # Create VM and configure...
done
```

### Monitoring and Metrics

Install monitoring tools on routers:

```bash
opkg install bwm-ng iftop

# Monitor bandwidth by interface
bwm-ng

# Monitor connections
iftop -i eth0
```

### Custom Video Content

Instead of test patterns, stream actual video files:

```bash
#!/bin/bash
# Stream video file
gst-launch-1.0 -v \
  filesrc location=/path/to/video.mp4 ! \
  qtdemux ! \
  h264parse ! \
  mpegtsmux ! \
  udpsink host=232.1.1.1 port=5000 auto-multicast=true ttl-mc=5
```

### Integration with Custom Applications

Your custom video client can join specific sources using socket programming.

**Python Example (works on Windows)**:
```python
import socket
import struct

# Create UDP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

# Bind to multicast port
sock.bind(('', 5000))

# Join source-specific multicast group
# (S,G) = (192.168.1.10, 232.1.1.1)
mreq = struct.pack("4s4s4s", 
                   socket.inet_aton('232.1.1.1'),    # Group
                   socket.inet_aton('192.168.1.10'),  # Source
                   socket.inet_aton('192.168.2.1'))   # Local interface (Windows host)
sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_SOURCE_MEMBERSHIP, mreq)

# Receive data
while True:
    data, addr = sock.recvfrom(1316)
    # Process video data...
```

**C++ Example (Windows)**:
```cpp
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")

int main() {
    WSADATA wsaData;
    WSAStartup(MAKEWORD(2, 2), &wsaData);
    
    SOCKET sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    
    // Bind to port
    sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(5000);
    addr.sin_addr.s_addr = INADDR_ANY;
    bind(sock, (sockaddr*)&addr, sizeof(addr));
    
    // Join SSM group
    struct ip_mreq_source mreq;
    mreq.imr_multiaddr.s_addr = inet_addr("232.1.1.1");  // Group
    mreq.imr_sourceaddr.s_addr = inet_addr("192.168.1.10"); // Source
    mreq.imr_interface.s_addr = inet_addr("192.168.2.1");   // Local interface
    setsockopt(sock, IPPROTO_IP, IP_ADD_SOURCE_MEMBERSHIP, 
               (char*)&mreq, sizeof(mreq));
    
    // Receive data
    char buffer[1500];
    while (true) {
        int len = recv(sock, buffer, sizeof(buffer), 0);
        // Process video data...
    }
    
    closesocket(sock);
    WSACleanup();
    return 0;
}
```

### Simulating Failover Scenarios

Test source failover by stopping one source and verifying clients can switch:

```bash
# Stop Source-1
# On Source-1 VM
pkill gst-launch-1.0

# Client should detect and switch to backup source
```

## References

### Official Documentation

- [OpenWRT Documentation](https://openwrt.org/docs/start)
- [GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [RFC 4607 - Source-Specific Multicast for IP](https://tools.ietf.org/html/rfc4607)
- [RFC 3376 - IGMPv3](https://tools.ietf.org/html/rfc3376)

### Multicast Resources

- [Multicast Basics](https://www.cisco.com/c/en/us/td/docs/ios/solutions_docs/ip_multicast/White_papers/mcst_ovr.html)
- [PIM-SSM Configuration Guide](https://www.cisco.com/c/en/us/support/docs/ip/ip-multicast/43425-pim-ssm.html)
- [IGMP Snooping](https://en.wikipedia.org/wiki/IGMP_snooping)

### GStreamer Examples

- [GStreamer RTP Examples](https://gstreamer.freedesktop.org/documentation/rtp/index.html)
- [GStreamer Multicast Streaming](https://gstreamer.freedesktop.org/documentation/udp/udpsink.html)
- [GStreamer Command Line Cheat Sheet](https://github.com/matthew1000/gstreamer-cheat-sheet)

### Tools and Utilities

**Linux Tools**:
- **tcpdump**: Network packet analyzer - `sudo apt install tcpdump`
- **Wireshark**: GUI packet analyzer - `sudo apt install wireshark`
- **iperf3**: Network bandwidth testing - `sudo apt install iperf3`
- **mtools**: Multicast testing tools - `sudo apt install mtools`
- **smcroute**: Static multicast routing - `sudo apt install smcroute`

**Windows Tools**:
- **Wireshark**: Download from [wireshark.org](https://www.wireshark.org/download.html)
- **VLC Media Player**: Download from [videolan.org](https://www.videolan.org/vlc/)
- **FFmpeg**: Download from [ffmpeg.org](https://ffmpeg.org/download.html)
- **iperf3**: Download from [iperf.fr](https://iperf.fr/iperf-download.php)

### Useful Commands Reference

**OpenWRT Router Commands**:
```bash
# View multicast routing table
ip mroute show

# View IGMP groups
cat /proc/net/igmp

# View PIM interfaces
cat /proc/net/ip_mr_vif

# Network statistics
netstat -g

# Interface status
ip link show
```

**Linux Client Commands**:
```bash
# Join multicast group (IGMPv3)
smcroute -j <interface> <group> <source>

# Leave multicast group
smcroute -l <interface> <group> <source>

# Monitor multicast traffic
tcpdump -i <interface> multicast

# Check IGMP version
cat /proc/sys/net/ipv4/conf/<interface>/force_igmp_version
```

**Windows Client Commands**:
```cmd
# Show network configuration
ipconfig /all

# Show routing table
route print

# Show multicast group memberships
netsh interface ipv4 show joins

# Show UDP statistics
netstat -s -p udp

# Test connectivity to router
ping 192.168.2.254

# Trace route to source network
tracert 192.168.1.10
```

**GStreamer Testing Commands**:
```bash
# Test video output
gst-launch-1.0 videotestsrc ! autovideosink

# Test UDP receive
gst-launch-1.0 udpsrc uri=udp://232.1.1.1:5000 ! fakesink

# Test decoding
gst-launch-1.0 udpsrc uri=udp://232.1.1.1:5000 ! tsdemux ! h264parse ! avdec_h264 ! autovideosink

# Get pipeline capabilities
gst-launch-1.0 udpsrc uri=udp://232.1.1.1:5000 ! decodebin ! autovideosink -v
```

## Next Steps

1. **Expand the Network**: Add more routers to simulate a larger topology
2. **Add More Clients**: Connect additional Windows machines or VMs to the host-only network
3. **Test Failover**: Implement redundant sources and test failover scenarios
4. **Add Monitoring**: Set up SNMP or other monitoring on routers
5. **Performance Testing**: Measure latency and bandwidth with multiple concurrent streams
6. **Custom Clients**: Develop your own multicast video clients using the simulation
7. **Security**: Add authentication and encryption to streams
8. **QoS**: Implement Quality of Service policies on routers

## Contributing

This guide is open for contributions. If you find issues or have improvements:

1. Fork the repository
2. Make your changes
3. Submit a pull request

## License

This documentation is provided under the MIT License. The referenced software (VirtualBox, OpenWRT, GStreamer) have their own respective licenses.

---

**Questions or Issues?** Open an issue in the GitHub repository or check the troubleshooting section above.
