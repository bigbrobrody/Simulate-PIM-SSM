@echo off
REM Batch file to receive 4 multicast streams
REM Starting at 232.1.1.11 / 192.168.1.11

echo Starting 4 GStreamer multicast receivers...
echo.

REM Start each stream in a new window
start "Stream 1 - 232.1.1.11" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.11 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

start "Stream 2 - 232.1.1.12" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.12 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

start "Stream 3 - 232.1.1.13" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.13 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph265depay ! queue ! decodebin ! queue ! autovideosink sync=false

start "Stream 4 - 232.1.1.14" /B gst-launch-1.0 -q udpsrc port=5000 multicast-group=232.1.1.14 multicast-source=192.168.1.11 caps="application/x-rtp" buffer-size=2097152 ! queue max-size-buffers=200 max-size-time=0 max-size-bytes=0 ! rtph264depay ! queue ! decodebin ! queue ! autovideosink sync=false

echo.
echo All 4 streams started in separate windows.
echo Close each window individually to stop streams.
pause