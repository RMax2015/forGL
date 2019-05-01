@echo off

cd CPP_OUT
if "%1"=="debug" (
  :: run debug
  Main-Debug.exe
) else (
  :: run release
  Main.exe
)


cd ..