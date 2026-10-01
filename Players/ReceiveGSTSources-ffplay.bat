@echo off
REM Batch file to receive 4 multicast streams

echo Starting 4 ffplay multicast receivers...
echo.

set "ffplay=C:\ffmpeg-2025-11-17-git-e94439e49b-full_build\bin\ffplay.exe"

REM Start each stream in a new window
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST1.sdp
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST2.sdp
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST3.sdp
start "" /B "%ffplay%" -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\GST4.sdp

echo.
echo All 4 streams started in separate windows.
echo Close each window individually to stop streams.
pause