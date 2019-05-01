@echo off

echo  Cleaning out extra Files not needed to Run before Saving

cd CPP_OUT
rd /S /Q  obj
cd ..

Rem  No need to clean CSharp_OUT
rem  cd CSharp_OUT/bin

cd Java_OUT
rd /S /Q  obj
cd ..

Rem  No need to clean Python_OUT
rem  cd Python_OUT
