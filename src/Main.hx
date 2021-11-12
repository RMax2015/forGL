/*		Main.hx		This is the entry point to begin an application using forGL
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * See block comment at end of  initRunForGL  for more information.
 * 
 * ...
 * @author Randy Maxwell
 */

// This has the  Main  or the  WebWorker  entry point class.
package;


using Sys;

#if		js
	import js.Browser;
#else
	import sys.FileSystem;
#end

//
//		UTF8 support library  includes Ansi Escape codes for Colored text and Cursor Positioning
//
using hx.strings.Strings;
// using hx.strings.Char;

using hx.strings.String8;

// Cursor positioning and Colored text, needed AnsiCon.exe for Win7 CMD window
// C++ and Python and Java  does Colored text and Cursor Positioning  OK.   C# no.
using hx.strings.ansi.Ansi;	
using hx.strings.ansi.AnsiColor;



//
//		forGL support
//
import forGL.*;
import forGL.Run.ForGL_Run		as 				ForGL_Run;
//import forGL.Run.ForGL_Run.forgl_version   as   forGL_Version;

import forGL.UI.ForGL_ui          as   ForGL_ui;
import forGL.UI.ForGL_ui.msg      as   msg;
import forGL.UI.ForGL_ui.error    as   error;
import forGL.UI.ForGL_ui.enterYes as   enterYes;

import forGL.FileTypes.FileTypes   as   FileTypes;

import forGL.Meanings.ReturnMeanings;
import forGL.Meanings.MeansWhat.returnMeanAsStr  as  returnMeanAsStr;

// Have  Comments  in Haxe generated source file(s) of various programming languages
import  forGL.Comments.comment    as  comment;


#if		js

//////////////////////////////////////////////////////////////////////////////
//
//		JavaScript is as a Browser Web Worker (an extra OS thread)
//
//		Browser provides an event driven GUI framework (using HTML controls)
//		JavaScript code here gets Browser messages (as Requests to forGL)
//		As forGL generates results, Reply messages are sent back to Browser
//
//		See  forGL_Load_Run.js  for Browser side details
//
//////////////////////////////////////////////////////////////////////////////
class WebWorker

#else

class Main 

#end
{
	public static var forGLRun : ForGL_Run;
	
	public static var text_line = 0;
	
#if		js

//
//		Messages from/to Browser
//

	// Use Request and Reply stacks to support variable times between Request/related Reply
	// and to decouple behavior to allow (perhaps faster?) Interpreter running
	//
	//public static var urgent_request        = false;
	public static var request_stack         = new Array<String>();
	public static var request_details_stack = new Array<String>();
	
	public static var reply_stack         = new Array<String>();
	public static var reply_details_stack = new Array<String>();

	public static var message_handler_installed = false;	// Needed to set up support
	
	public static var debug_msgs_js = true;
	
	public static function __init__() {
		//untyped __js__( "onmessage = WebWorker.messageHandler" );
		js.Syntax.code( "onmessage = WebWorker.messageHandler" );
	}
	
	
	public static function postMessage( message ) 
	{
		//untyped __js__( "postMessage( message )" );		// Worker to Browser message
		js.Syntax.code( "postMessage( message )" );		// Worker to Browser message
	}

//
//	Called when a message is sent from Browser JavaScript
//
	public static var request = "";				// from Browser GUI
	public static var request_details = "";
	
	public static function messageHandler( event ) 
	{
		// We get as an Array of 2 strings
		request         = event.data[ 0 ];
		request_details = event.data[ 1 ];
		
		// Save to Request stacks: allow for decoupled (asynchronous) behavior
		request_stack.push( request );
		request_details_stack.push( request_details );
		
	/*	
		if ( debug_msgs_js )
		{
			var out_msg = "from Browser: " + request + " " + request_details;
			trace( out_msg );
		}
	*/	
		// Check for some Requests that need immediate action (synchronous)
		switch ( request )
		{
			// Browser side sends  this  message first.
			case "using_web_worker": 
				if ( ! message_handler_installed )
				{
					messageSetUp_js( );
					forGLRun = new ForGL_Run();
				}

				var init_result = initRunForGL( );
				if ( 0 != cast( init_result, Int ) )
				{
					// ERROR initializing the runtime
					//
					var err_msg = "ERROR: Unable to initialize forGL runtime for Web Worker\n";
					sendMessage( "error", err_msg );
					trace( err_msg );
				}
				else
				{
					// Already handled. Clean up Request stacks.
					request_stack.pop();
					request_details_stack.pop();
					
					// Start the Interval that helps with deciding what to do
					//untyped __js__( "window.setInterval( 'doRequestReply', 100 )" );
					js.Syntax.code( "window.setInterval( 'doRequestReply', 100 )" );
				}
				
			case "oscpu":
				// TODO  Find correct way to set the INTERNAL variable oscpu in Os.hx of hx-strings library
				
			case "dictionary":
				// Internal default Dictionary already created. This adds to it.
				
				
			// case "initialize":
				// UI support inside forGL already initialized. Do the rest.
				
			
			case "run":
				
				forGLRun.verb_to_run = request_details;
				
				
				//forGLRun.run();
			
			case "single_step":
				forGLRun.single_step = true;
				//forGLRun.runInterpreter( );
				
			case "stop":
				
				//urgent_request = true;
			
			// Testing, send back the data
			// case _: postMessage( event.data[ 0 ] );
			
			default:
				var out_msg = "ERROR: UNKNOWN Request from Browser: " + request + " " + request_details;
				sendMessage( "error", out_msg );
				trace( out_msg );
		}
	}
	
	public static function sendMessage( message_type_str : String, ?message_details : String = "" )
	{
	/*
		if ( debug_msgs_js )
		{
			var message : String = message_type_str + "\n" + message_details;
			trace( message );
		}
	*/
		// reply_stack.push( message_type_str );
		// reply_details_stack.push( message_details );
	
		postMessage( [ message_type_str, message_details ] );
		return;
	}

	public static function installOnMessageHandler ()
	{
		//untyped __js__( "onmessage = WebWorker.messageHandler" );
		js.Syntax.code( "onmessage = WebWorker.messageHandler" );
		message_handler_installed = true;
	}
	

//
//		Coordinate Requests and Replies to do what is wanted
//
//////////////////////////////////////////////////////////////////////////////
	
	public static function doRequestReply( ) : Void
	{
		if ( 0 == request_stack.length )
			return;
		
		if ( request_stack.length != request_details_stack.length )
		{
			// Unexpected INTERNAL ERROR.
			return;
		}
			
		var latest_request         = request_stack[ request_stack.length - 1 ];
		var latest_request_details = request_details_stack[ request_details_stack.length - 1 ];
		
		switch ( latest_request )
		{
			case "dictionary":
				// Internal default Dictionary already created. This adds to it.
				
				
			// case "initialize":
				// UI support inside forGL already initialized. Do the rest.
				
			
			case "run":
				
				forGLRun.verb_to_run = latest_request_details;
				forGLRun.run();
			
			case "single_step":
				forGLRun.single_step = true;
				forGLRun.runInterpreter( );
				
			case "stop":
				
				
			default:
				
		}
		
	}
	

	// webWorker instead of main
	static function webWorker()
#else


	// Change to use command line arguments and have an Error code as return
	static function main() 
//////////////////////////////////////////////////////////////////////////////
//
//	Main is structured as if a full application was using forGL
//
//////////////////////////////////////////////////////////////////////////////

#end
	{
		var start_dir = "";

		ForGL_ui.system_name = "Unknown_system_name";

	#if sys
		ForGL_ui.system_name = Sys.systemName();
	
		start_dir = Sys.getCwd();		// Save original Directory
	
		var stdout = Sys.stdout();
	
		// now let's work with the fluent API:
		var writer = Ansi.writer(stdout); // supports StringBuf, haxe.io.Ouput and hx.strings.StringBuilder

	#else
		#if js
			ForGL_ui.system_name = "Browser";
		#end
	#end

	try
	{

	#if ( sys )
		
		if ( "Windows" == ForGL_ui.system_name )
		{
			// When running on Windows as CLI be sure the code page is UTF8 = 65001 by using chcp command
			
			
		}
	
		
	#else
		//var strBuilder = new hx.strings.StringBuilder();
		//var writer = Ansi.writer( strBuilder );
		
		#if js
		
			// Get GUI event handlers set and related support.
			messageSetUp_js();
			
		#end
	#end
		
		
	#if ( sys && !cs )
		writer
			.fg(GREEN)
			.bg(BLACK)
			.attr(INTENSITY_BOLD)
			.clearScreen()
			.flush();
	#end
		
		var version = "forGL v0.0.2 Prototype in ";
		msg( version );
		
	#if cpp
			msg( "C++\n" );
	#elseif cs
			msg( "C#\n" );
	#elseif java
			msg( "Java\n" );
	#elseif python
			msg( "Python\n" );
	#elseif js
			msg( "JavaScript\n" );	// Easy to tell JavaScript from overall HTML view
	#else
			msg( "? language\n" );
	#end
		
		// popUp( "See any new text ?" );
		
		text_line = 2;	// MUST keep track of the current Text Line. Line 0, Column 0 is top left of window


		// msg( "\n Inside main() \n" );
		
	/*
		#if ( cs || java || python )
			#if python
			var str = "Russelkafer";
			#else
			var str = "Rüsselkäfer";
			#end
			
		#else 
	*/

// TESTING German and Asian characters
// COMMENTED OUT

/*
		var str : String8 = "glücklich";	// happy in German  Haxe are UTF8 which is what we want. Length should be 9

	#if ( ! js && ! python )
		var oem_str = Utf8_to_OEM.oemStr( str );	// Does not help Python 3.6  some other Fix needed.
	#else
	//		Python or JavaScript/HTML is full UTF8 output already
		var oem_str = str;
	#end
	
	
	//	#end
		msg( oem_str, RED, true );
		
		text_line++;
		
		var str_len = oem_str.length;
		msg( Std.string( str_len ) );
		if ( str_len != 9 )
			msg( "  WRONG string length\n" );
		else
			msg( "\n" );
			
		text_line++;
	
		#if ( !python && !js )
		
			var str2:String8 = "はいはい";	// Try some Asian characters. so far NOT displayed correct
			msg( str2, GREEN, true );
			
			text_line++;
			
		#end
*/
		/*
		var str8:String8 = str;
		haxe.Log.trace( str8 + "\n" );
		str_len = str8.length;
		if ( str_len != 11 )
			msg( " WRONG string length" );
		

		var str2:String8 = "はいはい";
		msg( "\n" + str2 + "\n" );
		var str2_len = str2.length;
		haxe.Log.trace( str2_len, null );
		if ( str2_len != 4 )
			msg( " WRONG string length" );
		msg( "\n" );
		*/
		
		// TestUI.simple();
		

		initRunForGL();
		
	

	
	}
	catch ( e:Dynamic ) 
	{
	#if		js
		error( "\nException in webWorker(): " + Std.string( e ) + " \n");
	#else
		error( "\nException in main(): " + Std.string( e ) + " \n");
	#end
	};
	
	
	#if ( sys )
		comment( "", "Restore any changed values before exit", "" );
		
		#if java
			// Java does not allow  setCwd  so use  cd  command with Quotes around Directory path
			Sys.command( "cd \"" + start_dir + "\"" );
		#else
			// Restore original Directory
			Sys.setCwd( start_dir );
		#end
		
		#if ( !cs )
		writer
			.fg(CYAN)
			.bg(BLACK)
			.attr(INTENSITY_BOLD)
			.flush();
		#end


	#end

		return;
	}


#if		js

	private static function messageSetUp_js() : Void
	{
	
		installOnMessageHandler( );

		var init_result = ForGL_ui.init( );
		if ( 0 != cast( init_result, Int ) )
		{
			// ERROR initializing the UI
			//
			var err_msg = "INTERNAL ERROR: Unable to initialize forGL output to Web Worker UI layer\n";
			trace( err_msg );
			sendMessage( "error", err_msg );
			return;
		}
	}
#end
			
//
//		Initialize forGL if JavaScript
//
//		Initialize and Run forGL for all others
//
	
	public static function initRunForGL() : ReturnMeanings
	{
		var ret_val = RET_IS_OK;
		
		
		var init_lines = 0;

		forGLRun = new ForGL_Run();
	
		var init_result = RET_IS_OK;
		var err_str = "";
		
	#if js
		js.Lib.debug;
		init_result = forGLRun.init( "", init_lines );
	#else

		#if ( debug || cs )
			// NEED FULL PATH as Debugger runs in another Dir
			var debug_path_file  = "C:/Randy/Programming/Haxe/Projects/AST_4GL_Proto/forGL_Dictionary_Prototype.toml";

			init_result = forGLRun.init( debug_path_file, init_lines );
		#else

			var actual_path_file = "forGL_Dictionary_Prototype.toml";
			var args = Sys.args();
			if ( 0 < args.length )
			{
				actual_path_file = args[ 0 ];
			}

			var does_exist = FileSystem.exists( actual_path_file );
			if ( false == does_exist )
			{
				// Try up 1 directory level
				does_exist = FileSystem.exists( "../" + actual_path_file );
				if ( true == does_exist )
				{
					actual_path_file = "../" + actual_path_file;
				}
				else
				{
			#if ( !java )
				// See if any .toml files in the current directory.
				var found_file = "";
				
				var file_list = FileSystem.readDirectory( "." );
				var i = 0;
				while ( i < file_list.length )
				{
					// Use first  .toml  file found
					if ( false == FileSystem.isDirectory( file_list[ i ] ) )
					{
						var temp = file_list[ i ].toLowerCase(); 
						if ( 6 <= temp.length )
						{
							var extension = temp.substr( -5 );
							if ( ".toml" == extension )
							{
								found_file = file_list[ i ];
								break;
							}
						}
					}
					
					i++;
				}
				
				
				msg( actual_path_file + " not found. Use " + found_file + " instead (y/n) ?");
				var is_yes = enterYes( );	// ECHO of character to display
				if ( is_yes )
				{
					actual_path_file = found_file;
					does_exist = true;
				}
				
			#end
				}
			}
			if ( true == does_exist )
				init_result = forGLRun.init( actual_path_file, init_lines );
			else
			{
				err_str = " " + actual_path_file;
				init_result = RET_FILE_NOT_FOUND;
			}
		#end
	#end
	
//	#else
//		var init_result = forGLRun.init( "forGL_Dictionary_Prototype.toml", init_lines );
//	#end
		text_line += Math.floor( Math.abs( cast( init_result, Int ) ) );
		text_line++;
		
		if ( cast( init_result, Int ) < 0 )
		{
			// show what the Error was
			error( "\n    SEVERE ERROR  " + returnMeanAsStr( init_result ) + err_str + " trying to Initialize the Runtime service.  Stopping." );
			return init_result;
		}
		
	#if		js
	
		forGLRun.run_text_line = text_line;
		
		ForGL_ui.ui_done = false;
		
	/*
		while ( ! forGL_ui.ui_done )
		{
			Browser.window.setTimeout( "doNothing", 20 );
			if ( forGL_ui.ui_start_run )
			{
				forGL_ui.ui_start_run = false;
				break;
			}
		}
	*/
		
		//	forGLRun.run();	// Running of forGL is done after a message from the Browser
		
	#else
	
		text_line++;
		text_line++;
		forGLRun.run_text_line = text_line;
		
		forGLRun.run();
		
		forGLRun.cleanUp();
		
	#end
		
		return ret_val;
	}
}


/*
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * 				Current Status / Priorities:
 *
 * Partition sources (and some builds later on) 
 * 		to support identified separate major function libraries
 * 		Libraries will be Runtime, Data Persistence, and ???
 * 
 * 		UI support for either text mode console app 	(working) 
 * 		or HTML + JavaScript 							(needs more work)
 * 		or perhaps use a UI library like Cocktail 		TODO
 * 
 * 		Prototype is built as all in one (monolithic) application 
 * 			with all needed Libraries.
 * 
 * Licenses are ONLY to be MIT or Apache or BSD or ZIP. 
 * 		This includes all 3rd party open source libraries used.
 * 		NO GPL or LGPL type Licenses.
 * 
 * 1) Simple functionality now working
 * 		Define/Implement simple forGL support
 * 			Define major interfaces
 * 				At least have comments for Design by Contract	TODO
 * 				consider using actual DbC library				TODO
 * 		Define TDD interfaces									TODO
 * 		Define Performance interfaces (optional for now)		TODO
 * 
 * 2)	Play with prototype		Yeeee  Haaaw  ! ! !
 *		Allow automated testing 	TODO
 *	
 * 
 */


 //
 //		Test Colored text and Cursor positioning and some International characters
 //
class TestUI
{
	public static function simple()
	{
		
		trace("Hello ");
		msg( "forGL ?\n" );
		
		
		var f = 0.0;
		var txt = "\n";
		
		while (f < 2.0) {
			txt = f + "\n";
			msg( txt );
			f++;
		}
		
	
		//var str:String = "はいはい";  // create a string with UTF8 chars
		var str:String8 = "Veränderung";		// length should be 11
		//str.length;  // will return different values depending on the default UTF8 support of the target platform
		msg( str + "\n" );
		
		var str_len = str.length;
		haxe.Log.trace( str_len, null );
		if ( str_len != 11 )
			msg( " WRONG string length" );
		msg( "\n" );
		
		var str2:String8 = "はいはい";
		msg( "\n" + str2 + "\n" );
		var str2_len = str2.length;
		haxe.Log.trace( str2_len, null );
		if ( str2_len != 4 )
			msg( " WRONG string length" );
		msg( "\n" );
		
		/* CMD text window output on Win7 
		?:0: πü»πüäπü»πüä
?:0: 12
		or
		Ver├ñnderung	(CPP and Python)
		12
		
		or
		VerΣnderung		(Java)
		11
	
		or
		Veränderung		( CSharp is GOOD! need to find what CSharp used. Font, Win API, etc. )
		11
*/

/*	
		var str8:String8 = str; // we assign the string to a variable of type String8 - because of the nature of Haxe`s abstract types this will not result in the creation of a new object instance
		str8.length;  // will return the correct character length on all platforms
		haxe.Log.trace( str8, null );
		haxe.Log.trace( str8.length, null );
*/
		
	#if ( sys )
        var stdout = Sys.stdout();

        stdout.writeString(Ansi.fg(RED));           // set the text foreground color to red
        stdout.writeString(Ansi.bg(WHITE));         // set the text background color to white
        stdout.writeString(Ansi.attr(INTENSITY_BOLD));        // make the text bold
        stdout.writeString(Ansi.attr(RESET));       // reset all color or text attributes
   //     stdout.writeString(Ansi.clearScreen());     // clears the screen
        stdout.writeString(Ansi.cursor(MoveUp(2))); // moves the cursor 2 lines up

        // now let's work with the fluent API:
        var writer = Ansi.writer(stdout); // supports StringBuf, haxe.io.Ouput and hx.strings.StringBuilder
        writer
          // .clearScreen()
          .cursor(GoToPos(20,10))
          .fg(GREEN).bg(BLACK).attr(ITALIC).write("How are you?").attr(RESET)
          .cursor(MoveDown(2))
          .fg(RED).bg(WHITE).attr(UNDERLINE_SINGLE).write("Hello World! (in color?)").attr(UNDERLINE_OFF)
          .flush();
	#end
		  
	/* CMD text window output on Win7 
		←[31m←[47m←[1m←[0m←[2J←[2A←[10;10H←[32m←[40m←[3mHow are you?←[0m←[2A←[31m←[47m←[
		4mHello World! (in color?)←[24m
		
		above output was default white text on black background 
			WITHOUT using AnsiCon.exe on Win7
			
		Below is correct text positioning output 
		(colors lost inside this file but OK on output)
	
..\Haxe\Projects\forGL_Proto\bin>main
Main.hx:112: Hello
?:0: forGL ?
?:0: 0
?:0: 1
?:0: 2
?:0: 3               Hello World! (in color?)
C:\Randy\Programming\Haxe\Projects\forGL_Proto\bin>
?:0: 5   How are you?
?:0: 6
?:0: 7
?:0: 8
?:0: 9
?:0: Ver├ñnderung
?:0: 12
?:0:  WRONG string length
?:0:
	*/
	
	//var myColor:ColorTraces = ColorTraces;
/*	
	if ( Curses.hasColors() )
		haxe.Log.trace( "  Colors  OK", null );
	else
		haxe.Log.trace( "  NO  Colors", null );
*/	
		
	}
}
