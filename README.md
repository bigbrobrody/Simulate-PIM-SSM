# Simulate PIM-SSM Network for Video Testing

This guide provides step-by-step instructions on how to simulate a PIM-SSM (Protocol Independent Multicast - Source-Specific Multicast) network using GNS3 in VirtualBox on Windows to test multicast video clients.

## Table of Contents
- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Setup Environment](#setup-environment)
- [Network Topology](#network-topology)
- [Router Configuration](#router-configuration)
- [Multicast Source Setup](#multicast-source-setup)
- [Video Client Configuration](#video-client-configuration)
- [Testing and Verification](#testing-and-verification)
- [Troubleshooting](#troubleshooting)
- [References](#references)

## Introduction

PIM-SSM (Source-Specific Multicast) is a multicast routing protocol that allows receivers to specify both the multicast group and the specific source they want to receive traffic from. This is ideal for video streaming applications where clients need to receive streams from known sources.

This simulation environment allows you to:
- Test multicast video streaming applications
- Learn PIM-SSM configuration and operation
- Troubleshoot multicast network issues
- Validate video client behavior in a controlled environment

## Prerequisites

### Software Requirements
- **Windows 10/11** (64-bit)
- **VirtualBox** (version 6.1 or later)
  - Download from: https://www.virtualbox.org/
- **GNS3** (version 2.2 or later)
  - Download from: https://www.gns3.com/
- **GNS3 VM** (for VirtualBox)
  - Download from: https://www.gns3.com/software/download-vm

### Hardware Requirements
- CPU: Intel/AMD processor with VT-x/AMD-V virtualization support
- RAM: Minimum 8GB (16GB recommended)
- Disk Space: 20GB free space
- Network: Internet connection for initial setup

### Additional Software
- **Cisco IOS Router Image** (or alternatives like Cisco IOSv/CSR1000v)
- **VLC Media Player** (for video client testing)
- **Linux VM Image** (Ubuntu or Debian) for multicast source and receivers

## Setup Environment

### Step 1: Install VirtualBox
1. Download VirtualBox installer from the official website
2. Run the installer with administrator privileges
3. Follow the installation wizard
4. Install the VirtualBox Extension Pack for additional features

### Step 2: Install GNS3
1. Download the GNS3 all-in-one installer for Windows
2. Run the installer as administrator
3. During installation:
   - Select "Install GNS3 Desktop"
   - Select "Install VirtualBox" (if not already installed)
   - Choose to install WinPCAP/Npcap for packet capture
4. Complete the installation

### Step 3: Setup GNS3 VM in VirtualBox
1. Download the GNS3 VM OVA file
2. Open VirtualBox
3. Go to **File > Import Appliance**
4. Select the downloaded GNS3 VM OVA file
5. Configure VM settings:
   - Allocate at least 4GB RAM (8GB recommended)
   - Assign 2-4 CPU cores
6. Import the appliance

### Step 4: Configure GNS3
1. Launch GNS3
2. On first run, complete the setup wizard:
   - Select "Run appliances in a virtual machine"
   - Choose VirtualBox as the virtualization software
   - Select the imported GNS3 VM
3. Verify the GNS3 VM starts successfully

## Network Topology

### Recommended Topology

```
                    Internet (Optional)
                           |
                    [NAT Cloud]
                           |
                      [Router R1]
                      (PIM-SSM)
                           |
                    ---------------
                   |               |
              [Router R2]     [Router R3]
              (PIM-SSM)       (PIM-SSM)
                   |               |
            [Multicast          [Video
             Source]             Client]
          (239.1.1.1)         (Receiver)
```

### Topology Components

1. **Router R1** (Core Router)
   - Core multicast router connecting source and client networks
   - Connects to upstream network
   - PIM-SSM enabled

2. **Router R2** (Source Router)
   - Connected to multicast source
   - PIM-SSM enabled
   - Interface towards multicast source

3. **Router R3** (Client Router)
   - Connected to video clients/receivers
   - PIM-SSM enabled
   - IGMP configured for client access

4. **Multicast Source**
   - Linux VM running VLC or FFmpeg
   - Generates multicast video stream
   - IP: 10.2.2.2/24
   - Multicast Group: 239.1.1.1

5. **Video Client**
   - Linux/Windows VM with VLC
   - Subscribes to multicast stream
   - IP: 10.3.3.2/24

### Creating the Topology in GNS3

1. Create a new GNS3 project: **File > New blank project**
2. Name it "PIM-SSM-Video-Network"
3. Add devices from the device panel:
   - Drag 3 router appliances (Cisco routers)
   - Add 2 VPCS or Linux VMs (for source and client)
   - Add an Ethernet switch for each LAN segment
4. Connect devices according to the topology diagram
5. Label all devices appropriately

## Router Configuration

### Router R1 (Core Router) Configuration

```cisco
! Basic configuration
hostname R1
!
! Configure interfaces
interface GigabitEthernet0/0
 description Link to R2
 ip address 10.1.2.1 255.255.255.0
 ip pim sparse-mode
 no shutdown
!
interface GigabitEthernet0/1
 description Link to R3
 ip address 10.1.3.1 255.255.255.0
 ip pim sparse-mode
 no shutdown
!
! Enable IP multicast routing
ip multicast-routing
!
! Configure PIM SSM
ip pim ssm default
!
! Configure SSM range (232.0.0.0/8 is default, but we'll use 239.1.1.0/24)
ip pim ssm range SSM-RANGE
!
access-list SSM-RANGE permit 239.1.1.0 0.0.0.255
!
! Save configuration
end
write memory
```

### Router R2 (Source Router) Configuration

```cisco
! Basic configuration
hostname R2
!
! Configure interfaces
interface GigabitEthernet0/0
 description Link to R1
 ip address 10.1.2.2 255.255.255.0
 ip pim sparse-mode
 no shutdown
!
interface GigabitEthernet0/1
 description Link to Multicast Source
 ip address 10.2.2.1 255.255.255.0
 ip pim sparse-mode
 no shutdown
!
! Enable IP multicast routing
ip multicast-routing
!
! Configure PIM SSM
ip pim ssm default
!
! Configure SSM range
ip pim ssm range SSM-RANGE
!
access-list SSM-RANGE permit 239.1.1.0 0.0.0.255
!
! Optional: Configure MSDP if needed for source discovery
! (Not required for SSM in most cases)
!
! Save configuration
end
write memory
```

### Router R3 (Client Router) Configuration

```cisco
! Basic configuration
hostname R3
!
! Configure interfaces
interface GigabitEthernet0/0
 description Link to R1
 ip address 10.1.3.2 255.255.255.0
 ip pim sparse-mode
 no shutdown
!
interface GigabitEthernet0/1
 description Link to Video Clients
 ip address 10.3.3.1 255.255.255.0
 ip pim sparse-mode
 ip igmp version 3
 no shutdown
!
! Enable IP multicast routing
ip multicast-routing
!
! Configure PIM SSM
ip pim ssm default
!
! Configure SSM range
ip pim ssm range SSM-RANGE
!
access-list SSM-RANGE permit 239.1.1.0 0.0.0.255
!
! Optional: Configure IGMP settings
ip igmp query-interval 60
ip igmp query-max-response-time 10
!
! Save configuration
end
write memory
```

### Important Configuration Notes

- **PIM Sparse Mode**: Required on all multicast-enabled interfaces
- **IGMP v3**: Required for SSM; IGMPv3 supports source-specific joins
- **SSM Range**: Defines which multicast groups use SSM (typically 232.0.0.0/8 or custom range)
- **ip multicast-routing**: Globally enables multicast routing

## Multicast Source Setup

### Option 1: Using VLC (Linux VM)

1. **Create/Import Linux VM in GNS3**
   - Use Ubuntu or Debian
   - Configure network interface: 10.2.2.2/24
   - Set default gateway: 10.2.2.1

2. **Install VLC**
   ```bash
   sudo apt update
   sudo apt install vlc -y
   ```

3. **Prepare a test video file or use a test pattern**

4. **Stream video via multicast**
   ```bash
   cvlc /path/to/video.mp4 --sout '#duplicate{dst=std{access=udp,mux=ts,dst=239.1.1.1:5004}}' --loop
   ```

   Or use a test pattern:
   ```bash
   cvlc -vvv --color screen:// --screen-fps=25 \
     --sout '#transcode{vcodec=mp2v,vb=4096,acodec=mpga,ab=192,scale=1,channels=2,samplerate=44100}:duplicate{dst=std{access=udp,mux=ts,dst=239.1.1.1:5004}}' \
     --loop
   ```

### Option 2: Using FFmpeg (Linux VM)

1. **Install FFmpeg**
   ```bash
   sudo apt update
   sudo apt install ffmpeg -y
   ```

2. **Stream a test pattern**
   ```bash
   ffmpeg -re -f lavfi -i testsrc=duration=3600:size=1280x720:rate=30 \
          -f lavfi -i sine=frequency=1000:duration=3600 \
          -c:v libx264 -b:v 2M -c:a aac -b:a 128k \
          -f mpegts udp://239.1.1.1:5004
   ```

3. **Stream an existing video file**
   ```bash
   ffmpeg -re -i /path/to/video.mp4 -c copy -f mpegts udp://239.1.1.1:5004
   ```

### Verify Multicast Source

On the multicast source VM, verify the stream is being sent:
```bash
# Check network statistics
netstat -g
ifconfig

# Monitor multicast traffic
tcpdump -i eth0 host 239.1.1.1
```

## Video Client Configuration

### Setup Client VM

1. **Create/Import Linux or Windows VM in GNS3**
   - Configure network interface: 10.3.3.2/24
   - Set default gateway: 10.3.3.1

### Linux Client

1. **Install VLC**
   ```bash
   sudo apt update
   sudo apt install vlc -y
   ```

2. **Join multicast group and play stream**
   ```bash
   vlc udp://@239.1.1.1:5004
   ```

3. **Or use command line**
   ```bash
   cvlc udp://@239.1.1.1:5004
   ```

### Windows Client

1. **Install VLC Media Player**
   - Download from https://www.videolan.org/

2. **Open Network Stream**
   - Open VLC
   - Go to **Media > Open Network Stream**
   - Enter: `udp://@239.1.1.1:5004`
   - Click **Play**

### Verify Client is Receiving

**On Linux:**
```bash
# Check IGMP memberships
netstat -g

# Check for incoming multicast traffic
tcpdump -i eth0 host 239.1.1.1
```

**On Windows:**
```powershell
# Check routing table
route print

# Check network statistics
netstat -s -p udp
```

## Testing and Verification

### Verify PIM Neighbors

On each router, verify PIM neighbors are established:
```cisco
R1# show ip pim neighbor
```

Expected output should show adjacent routers.

### Verify Multicast Routes

Check the multicast routing table:
```cisco
R1# show ip mroute

! Look for entries like:
! (10.2.2.2, 239.1.1.1), flags: sTx
```

### Verify PIM SSM Operation

```cisco
R1# show ip pim tunnel
R1# show ip mroute 239.1.1.1
R1# show ip pim interface
```

### Verify IGMP Membership

On Router R3 (connected to clients):
```cisco
R3# show ip igmp groups
R3# show ip igmp membership
```

### Check Multicast Traffic Flow

```cisco
! On all routers
show ip mroute count

! Monitor specific group
show ip mroute 239.1.1.1 10.2.2.2
```

### Debug Commands (use with caution)

```cisco
! Enable debugging
debug ip pim
debug ip igmp
debug ip mpacket

! Disable debugging when done
undebug all
```

### Packet Capture in GNS3

1. Right-click on a link between routers
2. Select **Start capture**
3. Open in Wireshark
4. Filter for IGMP and PIM traffic:
   - `igmp` - IGMP messages
   - `pim` - PIM protocol messages
   - `ip.dst == 239.1.1.1` - Multicast data packets

## Troubleshooting

### Issue 1: Video Client Not Receiving Stream

**Symptoms:**
- VLC shows "waiting for stream"
- No video playback

**Troubleshooting Steps:**

1. **Verify multicast source is streaming**
   ```bash
   # On source VM
   netstat -an | grep 5004
   tcpdump -i eth0 dst 239.1.1.1
   ```

2. **Check IGMP membership on Router R3**
   ```cisco
   R3# show ip igmp groups
   ```
   If no groups are shown, the client's IGMP join isn't reaching the router.

3. **Verify IGMPv3 is enabled**
   ```cisco
   R3# show ip igmp interface GigabitEthernet0/1
   ```
   Should show "IGMP version is 3"

4. **Check multicast route on all routers**
   ```cisco
   show ip mroute 239.1.1.1
   ```

5. **Verify PIM is enabled on interfaces**
   ```cisco
   show ip pim interface
   ```

### Issue 2: PIM Neighbors Not Forming

**Symptoms:**
- `show ip pim neighbor` shows no neighbors

**Solutions:**

1. **Verify PIM is configured on interfaces**
   ```cisco
   show running-config interface <interface>
   ```
   Should have `ip pim sparse-mode`

2. **Check interface status**
   ```cisco
   show ip interface brief
   ```
   Interfaces should be "up/up"

3. **Verify IP connectivity**
   ```cisco
   ping <neighbor-ip>
   ```

### Issue 3: Multicast Traffic Not Forwarding

**Symptoms:**
- Source is streaming
- Client has joined group
- No traffic received

**Solutions:**

1. **Verify SSM range configuration**
   ```cisco
   show ip pim range-list
   ```

2. **Check RPF (Reverse Path Forwarding)**
   ```cisco
   show ip rpf 10.2.2.2
   ```
   Should show correct path back to source

3. **Verify multicast routing is enabled**
   ```cisco
   show running-config | include multicast
   ```

4. **Check for ACLs blocking multicast**
   ```cisco
   show ip access-lists
   ```

### Issue 4: High CPU on Routers

**Symptoms:**
- Router responsiveness is slow
- High CPU utilization

**Solutions:**

1. **Disable debugging**
   ```cisco
   undebug all
   ```

2. **Check multicast traffic rate**
   ```cisco
   show ip mroute count
   ```

3. **Consider hardware limitations** - GNS3 routers are CPU-intensive

### Issue 5: VirtualBox VM Network Issues

**Symptoms:**
- VMs cannot communicate with routers
- No network connectivity

**Solutions:**

1. **Check VM network adapter settings** in VirtualBox
   - Should be set to "Generic Driver" with GNS3 VM network

2. **Verify cloud node configuration** in GNS3
   - Ensure proper bridge/TAP interface

3. **Check GNS3 VM is running**
   ```bash
   # In GNS3 VM console
   ifconfig
   ```

## References

### Documentation
- [Cisco IOS Multicast Configuration Guide](https://www.cisco.com/c/en/us/td/docs/ios-xml/ios/ipmulti/configuration/xe-16/imc-xe-16-book.html)
- [RFC 4607 - Source-Specific Multicast for IP](https://tools.ietf.org/html/rfc4607)
- [GNS3 Documentation](https://docs.gns3.com/)
- [VLC Streaming Guide](https://wiki.videolan.org/Documentation:Streaming_HowTo/)

### Multicast Address Ranges
- **232.0.0.0/8** - Default SSM range (recommended)
- **239.0.0.0/8** - Administratively scoped (used in this guide)
- **224.0.0.0 - 224.0.0.255** - Reserved for local network control

### Useful Commands Quick Reference

**Router Commands:**
```cisco
show ip pim neighbor              ! View PIM neighbors
show ip mroute                    ! Multicast routing table
show ip igmp groups               ! IGMP group memberships
show ip pim interface             ! PIM interface status
show ip rpf <source>              ! RPF check
```

**Linux Commands:**
```bash
netstat -g                        # Multicast group memberships
ip maddr show                     # Multicast addresses
tcpdump -i eth0 multicast         # Capture multicast traffic
```

### Additional Resources
- [GNS3 Community Forums](https://gns3.com/community)
- [Cisco Learning Network](https://learningnetwork.cisco.com/)
- [Multicast Troubleshooting Tools](https://www.cisco.com/c/en/us/support/docs/ip/ip-multicast/16450-mcastguide.html)

---

## Contributing

Feel free to submit issues, fork the repository, and create pull requests for any improvements.

## License

This guide is provided as-is for educational purposes.
