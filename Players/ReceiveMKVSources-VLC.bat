@echo off
REM Batch file to receive 10 multicast streams

echo Starting 10 GStreamer multicast receivers...
echo.

set "VLC=C:\Program Files\VideoLAN\VLC\VLC.exe"

REM Start each stream in a new window
start "Stream 1" "%VLC%" SDPs\MKV1.sdp --no-one-instance
start "Stream 2" "%VLC%" SDPs\MKV2.sdp --no-one-instance
start "Stream 3" "%VLC%" SDPs\MKV3.sdp --no-one-instance
start "Stream 4" "%VLC%" SDPs\MKV4.sdp --no-one-instance
start "Stream 5" "%VLC%" SDPs\MKV5.sdp --no-one-instance
start "Stream 6" "%VLC%" SDPs\MKV6.sdp --no-one-instance
start "Stream 7" "%VLC%" SDPs\MKV7.sdp --no-one-instance
start "Stream 8" "%VLC%" SDPs\MKV8.sdp --no-one-instance
start "Stream 9" "%VLC%" SDPs\MKV9.sdp --no-one-instance
start "Stream 10" "%VLC%" SDPs\MKV10.sdp --no-one-instance

echo.
echo All 10 streams started in separate windows.
echo Close each window individually to stop streams.
pause