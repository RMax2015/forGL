/* UI.hx	This is the UI presentation level of forGL
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * See block comment at end of this file for more information.
 * 
 * ...
 * @author Randy Maxwell
 */

package forGL;

using Sys;

import haxe.Log;

import haxe.CallStack;

#if		js

	import js.Browser;
	import js.html.*;
	
	// Support to send UI data back to Browser from this Web Worker thread
	import WebWorker.sendMessage  as  sendMessage;
	
#end

// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

// cursor positioning and colored text, needed AnsiCon.exe for Win7 CMD window
using hx.strings.ansi.Ansi;
using hx.strings.ansi.AnsiColor;
// using hx.strings.ansi.AnsiCursor;

import forGL.Meanings.ReturnMeanings;

// Allow  Comments  in Haxe generated source file(s) of various programming languages
import  forGL.Comments.comment    as  comment;

using forGL.UI.ForGL_ui;


//		Logical names of Output places in UI
//
@:enum
abstract UI_Out(Int) {
	var WRITE_PREVIOUS  = -1;	// Write or send the previous UI Output cache and then set to Default cache
	
    var MESSAGES_OUT    = 0;	// Messages: Info, Warn, Errors
								// A lot of Info messages are not prefixed with INFORMATION or INFO
								// WARNING or ERROR messages are prefixed

	var STATUS_OUT      = 1;	// HIGH Priority messages that User should think about right away
								// and maybe do something! Text UI may require User to hit a Key.
	
    var DATA_STACK_OUT  = 2;	// Display some of the Interpreter internals that allow User
								// to better understand what their own code is doing as it runs.
    var OP_STACK_OUT    = 3;
    var NOUN_STACK_OUT  = 4;
	
    var VERB_OUT        = 5;	// Show and maybe View commands run from any Verbs
	
	var VERB_TOK_OUT    = 6;	// Verb displayed as (hopefully Colored) Tokens
	
   // var DEFAULT_OUT     = 0;
}


//				User Interface
class ForGL_ui
{
	public static var system_name = "";
	
	public static var error_count_ui = 0;
	public static var error_msgs_ui : String8 = "";
	
	public static var warning_count_ui = 0;
	public static var warning_msgs_ui : String8 = "";
	
	public static var out_buffers = new Array<String8>();
	
	
// 		Colors
//
	public static var COMMENT_COLOR = YELLOW;
	public static var DATA_COLOR    = RED;
	public static var NOUN_COLOR    = CYAN;
	public static var OP_COLOR      = GREEN;
	public static var VERB_COLOR    = BLUE;
	public static var VERB_BI_COLOR = MAGENTA;
	
	public static var DEFAULT_COLOR = WHITE;	// ASSUMES  BLACK  Background Color
	
	public static var current_line   = 0;
	public static var current_column = 0;
	
	private static var blanks78 : String =
		"                                                                              ";
	
	#if ( sys ) // Is stdin, stdout and File I/O available and various APIs ?
		private static var stdin = Sys.stdin();
		
		// Text mode messages with cursor positioning and foreground/background colors
		//
		// writer  supports StringBuf, haxe.io.Ouput and hx.strings.StringBuilder
		private static var stdout = Sys.stdout();
		private static var writer = Ansi.writer( stdout );
		//private static var ui_out = writer.out;

	#else
		// Running in a Web browser (Javascript Web Worker) or Flash or something like it.
		// Graphics mode output available but no direct file I/O.
		// Connecting to Local or Remote Data Store allows file I/O
		// or connect to a Logging utility (Local or Remote)
		// If NO Local or Remote connection wanted, still can run as "Super Calculator"
		//     just NO persistent data will be saved
		
		// These do NOT output on HTML
		//private static var strBuilder = new hx.strings.StringBuilder();
		//private static var writer = Ansi.writer( strBuilder );
		//private static var ui_out = strBuilder.asOutput;
		
		#if js
			
			private static var prev_out_js : UI_Out;
			private static var      out_js : UI_Out;

		#end
	#end
	

//
//		Helper to Set the Output buffer to use
//
//	Call with WRITE_PREVIOUS to finally output the Previous buffer to display
//
//	This supports a controlled delay of output to a display.
//
//		NOTE:
//	JavaScript is implemented. 
//	Other languages use a more direct approach (see rest of this module:)
//	Called by all programming languages to allow somewhat consistent API view of this UI
//
		public static function setOut( ?outputWhere : UI_Out = MESSAGES_OUT ) : Void
		{
	#if 	js
	
			if ( WRITE_PREVIOUS == outputWhere )
			{
				var idx = cast( prev_out_js, Int );
				if ( 0 < out_buffers[ idx ].length )
				{
					var msg_type_str = "";
					
					switch ( prev_out_js )
					{
						case MESSAGES_OUT:
							msg_type_str = "message";
						
						case STATUS_OUT:
							msg_type_str = "status";
						
						case DATA_STACK_OUT:
							msg_type_str = "data_stack";
											
						case OP_STACK_OUT:
							msg_type_str = "op_stack";
											
						case NOUN_STACK_OUT:
							msg_type_str = "noun_stack";
										
						case VERB_OUT:
							msg_type_str = "verb_output";
											
						case VERB_TOK_OUT:
							msg_type_str = "verb_tokens";
							
						default:
							msg_type_str = "";
					}
					
					if ( 0 < msg_type_str.length )
					{
						ww_msg_out( msg_type_str, out_buffers[ idx ] );
						out_buffers[ idx ] = "";
					}
				}
			}
		
			prev_out_js = out_js;
			out_js = outputWhere;
	#end
		}
	
	
//
//		Helper to display the Output buffers used
//
		public static function outputBuffersUsed( ) : Void
		{
	#if		js
	
			var i     = cast( MESSAGES_OUT, Int );
			var limit = cast( VERB_TOK_OUT, Int );
			var prev  = prev_out_js;
			
			while ( i <= limit )
			{
				setOut( cast( i, UI_Out ) );
				setOut( WRITE_PREVIOUS );
				i++;
			}
			
			setOut( prev );
	#end
		}

		
		public static function eraseToLineEnd( used : Int ) : Void
		{
			#if cs
				// TODO  test with real UTF8 string. Likely to be not correct.
				writer.write( blanks78.substr( used ) );
			#else
				#if !js
				writer.write( Ansi.ESC + "K" ).flush();
				#end
			#end
		}
		
	// These values may NOT be accurate !
		public static function getCurrentPos( line : Int, column : Int ) : Void
		{
			line   = current_line;
			column = current_column;
		}
			
	#if !cs
			// Use ASCII Escape sequences for Cursor Positioning
			public static function hideCursor() : Void
			{
				#if !js
				writer.write( Ansi.ESC + "?25l" );
				#end
			}

			public static function savePos() : Void
			{
				#if !js
				writer.write( Ansi.ESC + "s" );
				#end
			}
			
			public static function goToPos( line: Int, column : Int ) : Void
			{
				#if !js
				writer.write( Ansi.ESC + line + ";" + column + "H" );
				current_line   = line;
				current_column = column;
				#end
			}
			
			public static function eraseToDispEnd() : Void
			{
				#if !js
				writer.write( Ansi.ESC + "J" );
				#end
			}
			
			public static function restorePos() : Void
			{
				#if !js
				writer.write( Ansi.ESC + "u" );
				#end
			}
			
			public static function showCursor() : Void
			{
				#if !js
				writer.write( Ansi.ESC + "?25h" );
				#end
			}

	#end


//		Helper to show some text Messages
//
	public static var msg_call_count = 0;
	
	public static function msg( message:String8, color: AnsiColor = WHITE, end_CR = false ) : Void
	{
		msg_call_count++;
		
	#if js
		var out_str = message;
		var idx = cast( out_js, Int );
		if ( ( DATA_STACK_OUT != out_js )
		  && (  OP_STACK_OUT  != out_js )
		  && ( NOUN_STACK_OUT != out_js )
		  && ( STATUS_OUT     != out_js ) )
			out_str = out_buffers[ idx ].insertAt( out_buffers[ idx ].length8(), message );  // out_js.textContent + message;
		
		if ( true == end_CR )
			out_str += "\n";
		
		out_buffers[ idx ] = out_str;
		
		return;
	#else

	//	#if ( sys ) 
			#if ( cs )
				// C#  so far  does Not do Colored text output
				color = DEFAULT_COLOR;
			#end
			
			if ( DEFAULT_COLOR == color )
			{
				// writer.out.writeString( message );
				// writer.write( message );

				if ( true == end_CR )
					// writer.out.writeString( "\n" );
					//writer.write( "\n" );
					Sys.println( message );
				else
					Sys.print( message );
			}
			else
			{
				// Do NOT change this UNLESS you test with colored UTF8 German or other language text
				// C++ will always work but Java, C# and Python has extra characters on screen
				writer.fg( color ).write( message ).flush();
				writer.fg( DEFAULT_COLOR ).flush();
				if ( true == end_CR )
					writer.write( "\n" ).flush();
			}
	//	#else
			// Use Haxe log
	//		haxe.Log.trace( message, null );
	//	#end
	
	#end
	}
	
	//		Display 
	public static var status_msgs : String8 = "";
	
	public static function status( message : String8, color = WHITE, end_CR = false, wait = false ) : Void
	{
		var show_msg = true;
		
	#if		js
		setOut( STATUS_OUT );
		msg( message, color );		// 1 Message displayed in GUI
		setOut();
		
		if ( ( 0 < message.length8() ) && wait )
		{
			// REALLY bring to User's attention!
			// Browser.alert( message );
			ww_msg_out( "status", message );
			// trace( "status" + message );
		}
	#end
	
		if ( 0 == message.length8() )
		{
			status_msgs = "";	// Empty the Text buffer here and Clear display below
			end_CR = false;
			wait = false;
		}
		else
		{
			// Update buffer of Status messages with most Recent being first.
			// Put new message first (at top if displayed in UI)
			status_msgs = message.insertAt( message.length8(), status_msgs );
		}
		
	#if js
		return;
	#end

	#if ( !cs )
		savePos();
		goToPos( 1, 20 );
		eraseToLineEnd( 20 );
		if ( show_msg )
			msg( status_msgs, color, end_CR );
	#else
		if ( show_msg )
			msg( message, color, end_CR );
	#end
	
	#if ( !java && !js )
		if ( wait )
			Sys.getChar( false );	// No ECHO of character to display
	#end
		
	#if ( !cs && !js )
		restorePos();
	#end
	}


//		Error message output
//
	public static function error( message : String8, ?color = RED ) : Void
	{
		error_count_ui++;
		error_msgs_ui = error_msgs_ui.insertAt( error_msgs_ui.length8(), message );
		
		status( "" );
		msg( message, color );
		status( message, color, false, true );	// User REALLY needs to know about Errors
	}

	
//		Warning message output
//
	public static function warning( message : String8, ?color = YELLOW ) : Void
	{
		warning_count_ui++;
		warning_msgs_ui = warning_msgs_ui.insertAt( warning_msgs_ui.length8(), message );
		
		status( "" );
		msg( message, color );
		status( message, color, false, true );		// Use needs to know about Warnings as well
	}


//		Helper to support Color Syntax Highlighting by word type
//
	public static function getTypeColor( type: NLTypes ) : AnsiColor
	{
		var color = ForGL_ui.DEFAULT_COLOR;
		
		#if cs
			return color;	// so far  NO Color support for C#
		#end
		
		switch ( type )
		{
			case NL_TYPE_UNKNOWN:
				color = ForGL_ui.DEFAULT_COLOR;
				
			case NL_COMMENT:
				color = COMMENT_COLOR;
					
			case NL_OPERATOR:
				color = OP_COLOR;
				
			// Like a reserved keyword in other programming languages.
			case NL_VERB_BI:
				color = VERB_BI_COLOR;
									
			case NL_VERB:
				color = VERB_COLOR;
				
			case NL_VERB_RET:
				// color = VERB_COLOR;		// use Default and see how it looks

			case NL_NOUN:
				color = NOUN_COLOR;
				
			case NL_NOUN_LOCAL:
				color = NOUN_COLOR;

			case NL_STR:
				color = DATA_COLOR;
			
			case NL_BOOL:
				color = DATA_COLOR;

			case NL_INT:
				color = DATA_COLOR;
					
		/* Commented out to reduce overall number of different types to parse/run
			case NL_INT32:
				color = DATA_COLOR;
			case NL_INT64:
				color = DATA_COLOR;
		*/

			case NL_FLOAT:
				color = DATA_COLOR;
				
			case NL_CHOICE:
				color = VERB_BI_COLOR;  // or maybe separate  CHOICE_COLOR ?
		}
		
		return color;
	}

	

// 		simple		EDITOR
//
	public static var enterYourVerb_return = RET_IS_OK;

	public static function enterYourVerb( ) : String8
	{
		enterYourVerb_return = RET_IS_OK;
		
		var user_Verb :String8 = "";
		
	try
	{

// No Java support for getChar
	#if  sys
		msg( "Type  test_verb  OR  your Verb and hit Enter or only Enter to stop.\n" );
		
		comment( "", "EXCEPTION  Happens  Here  IF: ",
		"Running on Windows",
		"and Font does not have information about glyphs", 
		"Outline boxes show  ▯▯▯  instead of expected glyphs", "" );
		user_Verb = stdin.readLine();
		
		user_Verb = user_Verb.trim( " \t" );
		
		if ( 0 == user_Verb.length )
			enterYourVerb_return = RET_IS_USER_ESC;

	#end
	
	}
	catch ( e:Dynamic ) 
	{
		//var except_stack = CallStack.callStack();

		warning( "\nINTERNAL ERROR: Exception in  UI.enterYourVerb():  stdin.readLine()  " + Std.string( e ) + "\n");
		if ( "Windows" == system_name )
		{
			warning( "If you see outline boxes  ▯▯▯  instead of expected text:\nIt usually means the font does not have the data for those characters.\nPlease try the forGL GUI application.");
		}

		//var calls_str = CallStack.toString( except_stack );

		//warning( Std.string( calls_str ) );

		enterYourVerb_return = RET_IS_INTERNAL_ERROR;
	};	

		return user_Verb;
	}



// 		enter Yes or No
//
	public static function enterYes( ) : Bool
	{
		var yes_entered = false;

// No Java support for getChar
	#if ( sys )
		var ans : String8 = stdin.readLine();
		
		if ( 0 < ans.length )
		{
			ans = ans.trim( " \t" );
			if ( ( "Y" == ans.charAt8( 0 ) )
			  || ( "y" == ans.charAt8( 0 ) ) )
				yes_entered = true;
		}
	#end
	
		return yes_entered;
	}


// 		Initialize anything needed to support UI features later
//
	public static function init( ) : ReturnMeanings
	{
		var ret_val = RET_IS_OK;
	
	#if js

		ret_val = init_js( );

	#else
	
	
	#end
	
		return ret_val;
	}


//		DOES NOTHING if NOT JavaScript
//
	public static function popUp( msg : String ) : Void
	{
		#if	js
			// Browser.alert( msg );
		#end
	}
	
#if		js

//
//		Uses existing HTML text element to provide text lines ( TOML style )
//
	public static function getDictionaryTextLines_js( ) : Array<String8>
	{
		var dict_lines = new Array<String8>();
		var length = 0;
		
		//dict_text_element.hidden = false;
		//var attributes = dict_text_element.getAttributeNames();
		//Browser.alert( "Attributes: " + Std.string( attributes ) );
		
		//var dict_text = dict_text_element.innerText;
		//var length = dict_text.length;
		
		//if ( 0 == length )
		//{
			// timer_handle = Browser.window.setTimeout( timerHandler, 10 );
			
			
			//dict_text = dict_text_element.textContent;
			//length = dict_text.length;
			//Browser.alert( Std.string( length ) + " Dictionary data" );
		//}
		//else
			//Browser.alert( Std.string( length ) + " Dictionary data" );

		var line : String8 = "";
		var i = 0;
	/*
		while ( i < length )
		{
			var char_code = dict_text.charCodeAt8( i );
			var char = dict_text.charAt8( i );
			
			if ( 0x0D == char_code )
			{
				i++;
				continue;
			}
			
			if ( 0x0A == char_code )
			{
				dict_lines.push( line );
				line = "";
			}
			else
				line += char;
			
			i++;
		}
	*/	
		if ( 0 < line.length )
			dict_lines.push( line );
		
	//	Browser.alert( Std.string( dict_lines.length ) + " Dictionary lines" );
		
		// dict_text_element.hidden = true;
		
		return dict_lines;
	}


//////////////////////////////////////////////////////////////////////////////
//
//		HTML UI accessed by Haxe changed to JavaScript.  CSS not used?
//
//
//
//////////////////////////////////////////////////////////////////////////////
	
	public static function init_js( ?me_worker = true ) : ReturnMeanings
	{
		var ret_val = RET_IS_OK;

		out_buffers.push( "" );		// Messages
		out_buffers.push( "" );		// Status
		out_buffers.push( "" );		// Data stack
		out_buffers.push( "" );		// Op stack
		out_buffers.push( "" );		// Noun stack
		out_buffers.push( "" );		// Verb output
		out_buffers.push( "" );		// Verb Token output
		
		setOut( MESSAGES_OUT );
		
		var set_up = false;
		
		if ( me_worker )
		{
			// Running as Web Worker
			ww_msg_out( "status", "UI support Initialization finished." );
			
			set_up = true;
		}
		else
		if ( Browser.supported )
		{
			// Browser.document.onload
			
			//Browser.document.fgColor = "WHITE";
			//Browser.document.bgColor = "BLACK";
			
			//dict_name_element = Browser.document.getElementById( "dictionaryNameId" );
			//dict_name_element.hidden = true;
			
			//dict_text_element = Browser.document.getElementById( "dictionaryTextId" );
			//dict_text_element.hidden = true;
			
			/*
			var status_text = Browser.document.createTextNode( "Welcome to forGL" );
			//comment.textContent = "Welcome to forGL";
			var status_node = Browser.document.body.appendChild( status_text );
			// Browser.document.body.
			//status_text.
			status_node.nodeValue = "text-align: left;";
			//status_text. //  textAlign = "center"; 
			//Text
			*/
			
			//status_text_element = Browser.document.getElementById( "statusId" );
			
			//status_text_element.textContent = "Welcome to forGL";

			// action_button = Browser.document.createButtonElement();
			// action_button.hidden = true;	// Disable by hiding
			
			
			// action_str = " Run the Verb ";
			
			// action_button.textContent = action_str;
			// style="text-align: center;"
			//action_button.alignSelf( "left" );   // textAlign = "left";
			// Browser.document.body.appendChild( action_button );
			// action_button.onclick = actionButtonOnClick;
			//Browser.document.body.appendChild( start_button );
			
			
			//run_button = Browser.document.getElementById( "runButtonId" );

			//run_button.hidden = true;
			//run_button.onclick = runButtonOnClick;
			
			// user_verb_element = Browser.document.getElementById( "userVerbId" );
			//user_verb_element.setAttribute( "style", "color: white" );  // fgColor = "WHITE";
			//user_verb_element.setAttribute( "style", "background-color: black" ); //bgColor = "BLACK";
			
			
			// verb_colored_element = Browser.document.getElementById( "verbColoredTokensId" );
			//verb_colored_element.fgColor = "WHITE";
			//verb_colored_element.bgColor = "BLACK";
			
			// data_stack_element = Browser.document.getElementById( "dataStackId" );
			
			// op_stack_element = Browser.document.getElementById( "opStackId" );
			
			// noun_stack_element = Browser.document.getElementById( "nounStackId" );
			
			// verb_output_element = Browser.document.getElementById( "verbOutputId" );
			//verb_output_element.fgColor = "WHITE";
			//verb_output_element.bgColor = "BLACK";
			
			// messages_element = Browser.document.getElementById( "messagesId" );
			//messages_element.fgColor = "WHITE";
			//messages_element.bgColor = "BLACK";
			
			
			// messages_element.textContent = "T E S T";
			
			
			
			//run_button.hidden = false;
			
			
			
			//ww_js = new forGL.WebWorker_js();
			
			ww_msg_out( "status", "Init finished." );
			trace( "status Init finished." );
			

			set_up = true;
		}
	
		
/*
		untyped __js__( "else if ( ( window ) && ( window.Worker ) )" );
		{
			setOut( MESSAGES_OUT );
			
			//ww_js = new forGL.WebWorker_js();
			
			Browser.console.log( "status Init finished 2." );
			ww_msg_out( "status", "Init finished 2." );
			
			set_up = true;
		}
*/
		
		if ( ! set_up )
		{
			// Running Javascript without a Browser as in Node.js
			
			
			ret_val = RET_IS_NOT_IMPLEMENTED;
		}
		
		
		return ret_val;
	}


//
//		HTML UI Element Access
//
/*
	private static var dict_name_element : Element;
	private static var dict_text_element : Element;
	
	private static var action_str = "";
	
	private static var status_text_element : Element;

	private static var run_button : Element;
	
	private static var user_verb_element : Element;
	private static var verb_colored_element : Element;
	
	private static var data_stack_element : Element;
	private static var op_stack_element   : Element;
	private static var noun_stack_element : Element;
	
	private static var verb_output_element : Element;
	
	private static var messages_element : Element;
	//private static var out_messages = "";
*/
	
//		Enable a HTML Element by making it visible
//
//	private static function setHidden( element: Element, hide = false ) : Void
//	{
//		element.hidden = hide;
//	}

/*
	public static function doNothing( ) : Void
	{
		
	}
*/	


	public static var ui_done = false;
	
	public static var ui_start_run = false;
	
	
	public static function ww_msg_out( message_type_str : String, ?message_details : String = "" )
	{
		sendMessage( message_type_str, message_details );
	}


//
//		UI  EVENT  Handlers
//

	

	

#end	//  js  block
	
}

/*							forGL  UI 
 * 
 *	2 main types of UI with some Programming Language specific differences
 *  	Graphical User Interface or Command Line Interface (Text UI)
 * 
 * 	User types Verb text and whatever else
 * 		and hits Run button in GUI or Enter key in CLI
 * 
 * UI approaches (so far) by Programming Language:
 * 
 *							GUI
 *				JavaScript using HTML
 * 
 * Uses HTML elements as GUI for Input and Output
 * HTML is hosted by a Browser. 
 * 
 * forGL is NOT a well behaved application for a Browser as ordinary JavaScript:
 * 		forGL is computationally expensive due to being an Interpreter
 * 			also very few performance optimizations
 * 			(You were WARNED forGL Interpreter is a PROTOTYPE)
 * 				MAIN Goal of forGL is CORRECTNESS. PERFORMANCE comes later.
 * 
 * 				A N D  . . .
 * 			JavaScript itself is Interpreted by Browser (and JIT Compiled perhaps)
 * 
 * So Haxe JavaScript (here) is run as a Web Worker (aka native Threads provided by Browser)
 * There is another JavaScript (not Haxe) file that:
 *     Sets up and runs GUI part and loads forGL as Web Worker
 *     Sets up way to Send Commands & Data to forGL and to Receive Results from forGL
 * 
 *  Web Worker characteristics.
 *      Separate thread from Browser HTML GUI thread
 *      NO HTML DOM access
 * 
 * 
 *				JavaScript using Node.js on a Server platform   ( TODO )
 * 
 * 
 * 							Text UI
 * 				C++ or C# (limited) or Java or Python
 * Could add Flash or PHP or some other Languates/Frameworks that Haxe supports :)
 * 		BIG reason I chose Haxe to do forGL prototype :)
 *
 * 
 * Uses Colored text and Cursor position changing (like UNIX Curses)
 * 		EXCEPT  C# 
 * 			does NOT do Colored text or Cursor moves
 * 
 * 
 * 
 * 
 *****************************************************************************
 * 
 *   			WHY use a BLACK Background Color ?
 * 
 *	forGL does a LOT of TEXT style output and NO Graphical Images or Drawing (so far)
 * 
 *  Look at a large view of TEXT (so you can see individual Pixels):
 *  Likely that less than 1/2 of the pixels are Text Color, the rest are Background Color.
 *		Actually more like only about 1/4 of the pixels are Text Color.
 * 
 * 			PHYSICS
 *  On any computer screen (CRT, LCD, Plasma, and TVs as well) it takes EXTRA
 *  Electrical Power to make those Background pixels a Color IF NOT BLACK.
 *  This is due to the display being an ACTIVE (emitter of PHOTONs of LIGHT)
 *  as opposed to a PASSIVE (reflector of existing PHOTONs) device.
 *  So we are comparing a TV to a mirror (Active -- needing power vs. Passive)
 * 
 *  BLACK pixels typically need NO or very little power compared to other Colors.
 *  WHITE pixels typically need the MOST electrical power compared to other Colors.
 * 
 *  		HISTORY		(1960's to early 1990's)
 *	Early GRAPHICAL computer interfaces were (usually?) BLACK background until 
 * 	around when the Internetwork (now called Web) came into use. HTML pages 
 * 	used a Page analogy so that people used to working in labs, offices, classrooms, 
 * 	etc. (working with WHITE paper)
 * 	would better relate to having WHITE as the default Background color.
 * 
 * 			21st Century (and including later 20th Century)
 * 	Electrical Power has to come from some where to power the Active display(s).
 * 	Important to MINIMIZE use of Power for any Battery Powered device.
 * 	Cell Phones, Tablets, Laptops, other mobile devices all would benefit.
 * 
 * 	Paper is (hopefully) being used less than when the Internet was started.
 * 	Electrical Power is being used MUCH MORE now than before.
 * 
 *  So default Color setting of forGL UI will have a BLACK background.
 *  Any User of forGL may change the default Color settings as they wish.
 * 		TODO  change Prototype to allow User selected Colors and persistent settings
 * 
 *  Also some people find that looking at a computer display for a long time
 * 		may be less strain if using a BLACK background color.
 * 
 *  Of course, for your mobile device 
 * 		you may find that other background colors to fit your needs.
 *  Just remember that Batteries need Power from some where :)
*/
