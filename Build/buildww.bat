rem   Build Haxe project to output various Programming Languages in different Directories

rem   JavaScript   as forGL_WebWorker.js
cd src
copy /Y Main.hx WebWorker.hx
cd..
haxe build_Worker.hxml