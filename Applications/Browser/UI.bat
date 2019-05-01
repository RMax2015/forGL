@echo off

:AGAIN
copy /Y  ..\JavaScript_OUT\forGL_WebWorker.js
copy /Y  ..\JavaScript_OUT\forGL_WebWorker.js.map
copy /Y  ..\src\forGL\js\forGL_Load_Run.js

rem "C:\Program Files (x86)\Mozilla Firefox\firefox.exe" index_forGL.html
"C:\Program Files\Mozilla Firefox\firefox.exe" index_forGL.html
rem "C:\Program Files (x86)\Firefox Developer Edition\firefox.exe" index_forGL.html
pause
goto AGAIN