# forGL

**NEWS :  forGL will be presented at the Haxe US Summit 2019 in Seattle in May.**

Exact Time / Date not set yet, some time May 8 to May 10.

See Haxe.org for more details about US Summit.



## **S U M M A R Y**

**forGL Java and Python text style applications are available.**

**Haxe and other source files are available.**

**READ_ME.txt** file is in each directory to help you.




## **forGL . . . F E A T U R E S**

**Want to learn computer programming? forGL can help you.**

**Prior experience with computer programming or even knowing English is not needed. If you can use a Dictionary you are ready to program. Knowing how to use a Calculator may help but is not required.**  

forGL is built now as a text mode cross platform application (also called a command line application).
Later this year forGL will have a graphical interface.

Because forGL allows you to do computer programming, forGL also provides features that computer programmers expect.  
**Colored text to clearly show different types of dictionary words:**  
**Verbs  
Nouns  
Operators  
Punctuation**

**There are also some special types of words that are provided by forGL to make programming easier.**  
**Choice** words (the program may choose to change the next statement base on a true or false comparison).  
**if, else, while** ...

Other choice words are reserved but not yet working.

Another special type is called **Built In Verbs**.  
These are Verbs that are always part of a forGL dictionary when it is built in memory.  
**show, repeat** ...  

**forGL can run your code at full speed  
or automatically but with a delay between steps  
or manually under your control**  

**forGL will give you Warnings or Errors and try to provide useful information about why.**  

## **forGL . . . O P T I O N S**

![forGL_Options_image](https://user-images.githubusercontent.com/12145438/57154617-31cfdb00-6d8e-11e9-801d-f0bc3ca0b0e3.png)

Note: the screen capture above has settings you likely will want after you have good working forGL code.

### **Export test Verb to other programming languages (y/n) ?  y**
forGL allows you to save your working forGL code as source code of other programming languages.  
Below is a simple example: 
**x = sin ( pi / 4 ). "Sine of Pi / 4 = " + x show**

**This calculates the Sine of 45 degrees and then prints a message with the calculated value.
Export as Code does some rearrangement before the forGL interpreter runs to this:**  

**x := sin ( pi / 4 ) ; "Sine of Pi / 4 = " + x show**

**We see that the equal sign = was changed to := giving the side of what is changed.  
x is on the left and so the := indicates the left side.**  

![forGL_Export_As_Code_image](https://user-images.githubusercontent.com/12145438/57165213-4c647d00-6dab-11e9-9c89-e76d8c39e129.png)

**We can see that there is enough information captured in the Export as Code Log output to allow experienced programmers to manually convert to most other programming languages. There will be more work on Export as Code to change as much as possible to a form used by many other programming languages.**   

**When Export as Code is fully working it will automatically generate source file(s) as wanted. The first programming language to save as will be Haxe because Haxe will then allow you to generate source code in about a dozen other programming languages.**  

The Export As Code feature is under active development and (hopefully) will be fully working soon.

### **Show details of various information (y/n) ?  y**  
This option gives details of small steps of various calculations or changes to Nouns as the forGL interpreter runs.  
These details may help you to find a problem with your forGL code.

### **Show details of Words used (y/n) ?  y**  
This option will show details of a Verb when it is ready to run by the forGL interpreter.

### **Show Stacks: *N* = none & no Steps  OR  *D* is only Data  OR  any Key for all ? a**  
forGL interpreter uses 3 stacks internally (and some other stacks and structures as well, see the Run.hx code).
Data, Operators (Ops) and Nouns stacks show current values of each while you Manually step or forGL Automatically steps through your code.

![forGL_Stacks_image](https://user-images.githubusercontent.com/12145438/57164751-ef1bfc00-6da9-11e9-83f6-069cc3885f03.png)

**Above we see that after forGL ran there was a Noun named  x  with a value of  0.707106781186547**  

**Select *D* for Data stack only if you do not want to see the small steps forGL uses to run your code.**  

If you select *N* then no stacks will show and forGL will be somewhat faster than using 0 delay time.

### **Manual stepping and all stacks will show.**  
This lets you know that you will see the 3 stacks and Manual stepping is available.  

### **Stepping Speed: *0 to 9* (each as .2 sec delay)  OR  any Key for Manual ? 2**  
You may use a number to set a delay between steps or any other key to manually step through your code.

If you use 0 meaning no delay, forGL has code that updates the 3 stacks or the Data stack (as you selected) 5 times a second.

### **Automatic stepping with  0.4  seconds delay.**  
This lets you know that the delay between steps you wanted will be done.

### **Show Dictionary (y/n) ? n**  
This will show the full contents of the in memory dictionary. When forGL starts it builds the in memory dictionary and then adds words that are valid that are from the .toml dictionary file.

Later when forGL is stopping, the in memory dictionary is saved back to the dictionary file if there were any changes to Nouns in the dictionary or if any new Verbs were saved.

### **Test_Verb is:**  
### **5 show. show( 7 )**  
### **Type  *test_verb*  OR  your Verb and hit Enter or only Enter to stop.**  
### **testverb**

**When forGL starts the text of a test to try is provided.
The lines above shows the simple test and allows you to use it by typing in "testverb".**

**The screen capture example of Export as Code above used:
x = sin ( pi / 4 ). "Sine of Pi / 4 = " + x show** 

**When you enter a Verb to test forGL will allow you to Save the Verb definition before exiting.**  

### **forGL uses ideas from :**

### **Natural Language :** 

**Ideas of Verbs, Nouns and Punctuation.** Use of a Dictionary of words to support programming in a single or a mix of Natural Languages. You may use words from multiple languages within a single Verb definition.

### **Mathematics as a Language :**

**Ideas of various operations and functions such as : add, subtract, sin, cos ...**

### **Programming Language(s) :** 

**Reserved key words or symbols such as : =, !=, if, then, while ...**

**Declarative key words such as: from, into, show, repeat ...**


### **W A R N I N G !**

**The forGL application is a rough prototype with features that are incomplete, have significant defects (bugs) or even missing entirely.**

**Most of the forGL application is written in Haxe with output to: C++, C#, Java, Python and JavaScript.**

### **Test platforms used :**

Laptops running Windows 7 and 10.

**Languages used to implement forGL tested: C++, Java, Python, (all working OK)**

**C# (no color or cursor positioning),**

JavaScript (not really working).

Very incomplete testing on old Android phone with incomplete JavaScript / HTML / JavaScript Web Worker (from Haxe).

## Links to forGL
**Haxe Community** forum (Very helpful members)
Several references, search for: **4GL** or **forGL**

https://community.haxe.org/t/forgl-information-in-github/1606/9


**Haxe.io** site ... Information about lots of programs using Haxe

https://haxe.io/roundups/478/  


### **If you like forGL please consider donating to the Haxe Foundation.**

**https://opencollective.com/haxe/donate?referral=30077**  



**... More details will be added soon ...**
