@echo off
REM Batch file to receive 4 multicast streams

echo Starting 4 VLC multicast receivers...
echo.

set "VLC=C:\Program Files\VideoLAN\VLC\VLC.exe"

REM Start each stream in a new window
start "Stream 1" "%VLC%" SDPs\GST1.sdp --no-one-instance
start "Stream 2" "%VLC%" SDPs\GST2.sdp --no-one-instance
start "Stream 3" "%VLC%" SDPs\GST3.sdp --no-one-instance
start "Stream 4" "%VLC%" SDPs\GST4.sdp --no-one-instance

echo.
echo All 4 streams started in separate windows.
echo Close each window individually to stop streams.
pause