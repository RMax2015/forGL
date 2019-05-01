rem   Build Haxe project to output various Programming Languages in different Directories


rem   Python  as main.py
haxe  -lib haxe-strings -cp src -python ./Python_OUT/main.py -main Main

cd  Python_OUT
copy /Y *.py ..
cd  ..