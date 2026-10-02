@echo off
:: Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    :: Relaunch the batch file as admin
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running with administrative privileges...

route add 192.168.1.11 mask 255.255.255.255 192.168.2.254
route add 192.168.1.10 mask 255.255.255.255 192.168.2.254
route add 192.168.1.21 mask 255.255.255.255 192.168.2.254
route add 10.0.1.0 mask 255.255.255.252 192.168.2.254
pause