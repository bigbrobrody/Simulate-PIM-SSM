@echo off
REM Batch file to receive 10 multicast streams
REM Starting at 232.1.1.21 / 192.168.1.21

echo Starting 10 GStreamer multicast receivers...
echo.

REM Start each stream in a new window
start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.21 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.22 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.23 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.24 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.25 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.26 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.27 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.28 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.29 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

start "" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.30 multicast-source=192.168.1.21 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! videoscale ! video/x-raw,width=400,height=300 ! autovideosink sync=false

echo.
echo All 10 streams started in separate windows.
echo Close each window individually to stop streams.
pause