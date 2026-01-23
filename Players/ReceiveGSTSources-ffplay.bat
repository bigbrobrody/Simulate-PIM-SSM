@echo off
REM Batch file to receive 3 multicast streams

echo Starting 3 ffplay multicast receivers...
echo.

set "ffplay=C:\ffmpeg-2025-11-17-git-e94439e49b-full_build\bin\ffplay.exe"

REM Start each stream in a new window
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST1.sdp
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST2.sdp
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST3.sdp

echo.
echo All 3 streams started in separate windows.
echo Close each window individually to stop streams.
pause