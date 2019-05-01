@echo off


rem   Run  C++  .Exe  debug or not
cd CPP_OUT
if "%1"=="debug" (
  :: run debug
  Main-Debug.exe
) else (
  :: run release
  Main.exe
)

pause
cd ..



rem   Run  C#  .Exe

cd CSharp_OUT/bin
copy Main.exe ..
cd ..

cls

Main.exe

pause

cd ..



rem   Run  Python  .py

cd Python_OUT

python main.py

pause

cd ..

rem   Run  Java  .jar

cd Java_OUT

java -jar Main.jar


pause

cd ..
