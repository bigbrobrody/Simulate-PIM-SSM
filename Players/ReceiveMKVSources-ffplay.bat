@echo off
REM Batch file to receive 10 multicast streams

echo Starting 10 GStreamer multicast receivers...
echo.

set "ffplay=C:\ffmpeg-2025-11-17-git-e94439e49b-full_build\bin\ffplay.exe"

REM Start each stream in a new window
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV1.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV2.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV3.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV4.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV5.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV6.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV7.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV8.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV9.sdp
start "" /B "%ffplay%" -x 400 -y 300 -loglevel quiet -protocol_whitelist file,rtp,udp SDPs\MKV10.sdp

echo.
echo All 10 streams started in separate windows.
echo Close each window individually to stop streams.
pause