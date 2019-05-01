rem   Build Haxe project to output various Programming Languages in different Directories

rem   C++    as Windows .Exe  32 bit
haxe  -lib haxe-strings -cp src -cpp ./Cpp_OUT -main Main

rem   C#     as Windows .Exe
haxe  -lib haxe-strings -cp src -cs ./CSharp_OUT -main Main

rem   Java    as Main.jar
haxe  -lib haxe-strings -cp src -java ./Java_OUT -main Main

rem   Python  as main.py
haxe  -lib haxe-strings -cp src -python ./Python_OUT/main.py -main Main