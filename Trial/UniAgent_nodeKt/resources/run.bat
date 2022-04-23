set CWD=%~dp0

rem  --------------------
rem  configurations
rem  --------------------

set DEVICEID=0_SnmpDevice
set SECRET=1234xxxx

%CWD%node-v12.18.3-win-x64/node.exe %CWD%js/packages/UniAgent/kotlin/UniAgent.js %DEVICEID% %SECRET%
