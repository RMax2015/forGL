forGL    R E A D    M E    F I R S T

revised:  April, 2019
by:       Randy Maxwell

	Summary
===============
forGL enables you to begin learning about computer programming.
forGL allows you to run your programs in several different ways.

forGL is an application that sometimes acts like a programming language.
When using forGL you may use your own language and not just English.

forGL allows your programs to be saved to various programming languages,
when the Export feature is implemented and tested.

	Key Ideas
-----------------
No prior experience with programming is needed.
Thinking about Problems/Solutions logically helps.
Some experience with a calculator or calculator program helps.
User/Programmer edits definitions of Words in a Dictionary.
Words may be in any language and not limited to English.

	Word types are:
Nouns  (data)  integers, floats, bools, strings
Local Nouns  Nouns that get added and removed while running and not saved in the Dictionary.
Verbs   (code) any combination of word types you may edit
Verbs Built In    (code)  utility Verbs to do a specific task  Show  is an example.
Operators (ex: Math or Logic, Punctuation)  + - / * exp, log, trig, etc.

The order of Nouns, Verbs and so on is not fixed. Nearly any order will work.
Punctuation is the characters  ; , . :   Punctuation is used naturally to show the end of a phrase or sentence.
European style simplified Natural Languages of course have a period  .  at the end of each sentence.

A Verb may have any mix of Languages within; Ex: English, German, Spanish, Math, Logic, Vulcan, whatever.
Different colors are used to show different Word types.


Setup  (there is no install program)
====================================

Create a directory and copy some files.

Windows OS users need to do a few more steps as below.

Please see the  Operations  section below after you finish setup.


Setup for any OS  (except Windows)
----------------
Create a directory.

Place the files in the new directory.

	Run forGL by:
	IF you have Python 3.x installed
python forGL.py dictionary_file

////   Commented out, does not work with latest Java versions
////   IF you have Java 6 or higher installed (Java 8 or higher recommended)
////   java -jar forGL.jar dictionary_file

Now you are ready to try various forGL features.
Please see the  Operations  section below for more information.


Windows setup
-------------
Create a directory.

Place the files in the new directory.

ansicon.exe is needed to support Color Syntax Highlighting on Windows.
If you are using another OS you can skip this part.

For running on Windows, download ansicon
This is the page of the version I use.
http://adoxa.altervista.org/ansicon/

This is the link for ANSICON v1.87
http://adoxa.altervista.org/ansicon/dl.php?f=ansicon

Put the 2 DLL files (ANSI32 and ANSI64) and ansicon.exe in the same directory as you created.

Start a Windows  Cmd  window.

cd  (to the directory you just created)

    type
ansicon

and you will see the title change to  
Cmd - ansicon

Now if ANSI Escape sequences are sent by forGL 
the cursor will move and colored text will be seen.

    also type
chcp 65001

This changes the Windows text Code Page to UTF8
You only need to do this 1 time 
but because I create / destroy Cmd.exe window instances often
I suggest you create a .bat file with the following contents:

@echo off
chcp 65001
python forGL.py

Now if you do a  dir  command you should see:
ANSI32.dll
ANSI64.dll
ansicon.exe
forGL.jar			(you may not have this, Python works as well)
forGL.py
forGL_Dictionary_Prototype.toml

and the name of your new  .bat  file.




				  Operations  Quick  Start
==============================================================================
forGL has been tested on Windows 7 and 10

but really :
you can run  forGL.py  on any platform with Python 3.x installed


	forGL  Dictionary  (in memory and added to from a file)
	-------------------------------------------------------
forGL builds a default dictionary in memory of English words when starting.

A (optional) dictionary file (such as forGL_Test.toml) 
can be used to add more words to the dictionary in memory.
This allows you to add and run your own defintions of what forGL is to do.

forGL tries to find a dictionary file named: forGL_Dictionary_Prototype.toml
	OR
You can add the path and name of the dictionary file you want to use.


	Dictionary words in languages other than English
	------------------------------------------------
forGL_Dictionary_Prototype.toml  has examples of words in various languages.

There is limited support (now) for non English languages:
forGL messages are (now built in) in English.


	Dictionary file used by forGL
	-----------------------------
This is how you may add a command line argument for a dictionary file.
(Python example)
python  forGL.py  forGL_Test_Dictionary.toml

Dictionary file use is optional but it is very nice to have and recommended.
forGL has a minimum Dictionary that is built in.
The minimum Dictionary is enough to run forGL and access all the features.



... Under Construction ...










