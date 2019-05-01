rem   Build Haxe project to output various Programming Languages in different Directories

rem   C++   as Windows .Exe 32 bit
rem
rem haxe  -debug --each -lib haxe-strings -cp src -cpp ./CppD_OUT -D debug -D annotate-source -main Main
rem haxe  -lib haxe-strings -cp src -cpp ./Cpp_OUT -main Main

rem   CppIA           as  .cppia  file
haxe  -lib haxe-strings -cp src -cppia ./CppIA_OUT/main.cppia -main Main

rem   C#           as Windows .Exe
haxe  -lib haxe-strings -cp src -cs ./CSharp_OUT -main Main

rem   Java         as  Main.jar
haxe  -lib haxe-strings -cp src -java ./Java_OUT -main Main

rem   JavaScript   as  forGL_WebWorker.js
cd src
copy /Y  Main.hx  WebWorker.hx
cd..
haxe  build_Worker.hxml

rem   Python       as  main.py
haxe  -lib haxe-strings -cp src -python ./Python_OUT/main.py -main Main