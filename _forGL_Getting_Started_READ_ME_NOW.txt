forGL Getting Started

April 2019

    Please consider these directories
Applications
Dictionaries
Docs

If you want to USE forGL:
========================

Please:
Create a new directory (folder).

Copy at least 1 file from the Dictionaries directory (folder).

Go to the Applications directory and READ the  READ_ME.txt  file.

Copy the forGL application you selected to the new directory.

Copy from the Dictionaries directory.

Create a simple Windows  .bat  file or a shell script file.

You can also run forGL from the command line without a .bat or script.



If you want to BUILD and run forGL:
==================================

Please consider trying out the USE section above first.

forGL is mostly Haxe sources.
Now building as a Command Line Interface text style application.
Later this year as native GUI apps.
Hopefully soon as mostly working Browser app (instead of poorly working now).

Build
-----
directory has sample Windows .bat files I use to:
Run Haxe transpiler to build all or 1 at a time.
Run 5 different generated programming languages, all or 1 at a time.

forGL built with Haxe 3.4.x and 4.0 up to 4.0 rc2

forGL currently uses Haxe to generate:
C++, C#, Java, Python and JavaScript (a Browser Web Worker)

I also generate CppIA but am not testing with it yet.

1) Choose a Haxe Toolkit version and Install Haxe compiler + tools
or you can choose a nightly 4.0 build from Haxe github site.

See:
https://haxe.org
and
https://community.haxe.org

2) Choose and Install language support:
You do NOT have to install all of these.
You can choose practically any 1 of these 
for Haxe to generate and then you can run.

C++, 	hxcpp (includes CppIA)
C#, 	hxcs
Java	hxjava

There are pages on the Haxe site to help you start with the above languages.

Python and JavaScript support are included as part of Haxe Toolkit.

I installed all of the above on my Windows laptops.
The reasons are:
C++        for performance and cross platform
C#         for Windows centric (also easy to Debug on my old laptop)
Java       for cross platform OK performance
Python     for cross platform
JavaScript for Browser app

3) Install  haxe-strings  library
This provides better UTF8 support (especially if building with Haxe 3.4)
and ANSI Escape sequences to do text Colors and Cursor moves.

Python
------
After Python is built open in an editor of your choice.
I use Notepad++ on Windows.

Searh & Replace
__python__("

with nothing.

The the Python code can be run.
This fixes a minor defect in how Haxe generates Python comments 
in a macro from the Comments.hx file.


Comments ! ! !
forGL uses a Comments.hx source file that embeds Comments in Haxe generated sources.
Having Comments has helped me a lot finding my way around when Debugging forGL.

Comments ALSO are KEY to enabling anyone using forGL to better understand 
their own code (Verbs) when Exported to Haxe and then transpiled to whatever.

If you are running on Windows (like I do)
please see the Read ME files in the Applications directory (ansicon.exe and chcp 65001).

Thanks to Haxe Community Forum members and Haxe Team !

Hope this helps.
Thanks for your support!
Randy Maxwell