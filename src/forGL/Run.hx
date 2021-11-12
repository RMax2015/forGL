/* Run.hx	This is the Runtime (Interpreter !) component of forGL
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * 			This holds the forGL Interpreter with some related functionality.
 * 
 * See  the block comment at end of runInterpreter( ) for more information.
 * 
 * ...
 * @author Randy Maxwell
 */

package forGL;


// using haxe.io.Output;

// import haxe.ds.GenericStack;

using Date;
import haxe.Int64 as Int64;			// This is a CLASS and NOT a built in TYPE.

#if js
	import js.Browser;
#end

using hx.strings.Strings;
using hx.strings.String8;

using hx.strings.ansi.Ansi;
using hx.strings.ansi.AnsiColor;


// For now, assume UI is available

using  forGL.UI.ForGL_ui;
import forGL.UI.ForGL_ui.DEFAULT_COLOR;
import forGL.UI.ForGL_ui.DATA_COLOR;
import forGL.UI.ForGL_ui.OP_COLOR;
import forGL.UI.ForGL_ui.NOUN_COLOR;
import forGL.UI.ForGL_ui.VERB_COLOR;
import forGL.UI.ForGL_ui.VERB_BI_COLOR;

import forGL.UI.ForGL_ui.setOut   as   setOut;
import forGL.UI.ForGL_ui.outputBuffersUsed   as   outputBuffersUsed;

import forGL.UI.ForGL_ui.msg      as   msg;
import forGL.UI.ForGL_ui.error    as   error;
import forGL.UI.ForGL_ui.warning  as   warning;
import forGL.UI.ForGL_ui.status   as   status;
import forGL.UI.ForGL_ui.getTypeColor    as   getTypeColor;
import forGL.UI.ForGL_ui.enterYourVerb   as   enterYourVerb;
import forGL.UI.ForGL_ui.enterYes        as   enterYes;

#if js
	// import forGL.UI.ForGL_ui.doNothing   as   doNothing;
#end

//import sys.io.Process;

#if ( !cs && !js )		// for now  C# does not have text Cursor positioning
	import forGL.UI.ForGL_ui.hideCursor      as   hideCursor;
	import forGL.UI.ForGL_ui.savePos         as   savePos;
	import forGL.UI.ForGL_ui.goToPos         as   goToPos;
	import forGL.UI.ForGL_ui.goToHome        as   goToHome;
	import forGL.UI.ForGL_ui.eraseToDispEnd  as   eraseToDispEnd;
	import forGL.UI.ForGL_ui.restorePos      as   restorePos;
	import forGL.UI.ForGL_ui.showCursor      as   showCursor;
#end

import forGL.UI.ForGL_ui.eraseToLineEnd      as  eraseToLineEnd;

#if ( sys ) // Is File I/O available and various APIs ?
	import sys.FileSystem;
#end

using forGL.Parse.Parse;
using forGL.Parse.NLToken;

using  forGL.NLTypes;
import forGL.NLTypes.NLTypeAs.nlTypeAsStr    as  nlTypeAsStr;
import forGL.NLTypes.NLTypeAs.resolveType    as  resolveType;

import forGL.Meanings.OpMeanings;
import forGL.Meanings.ReturnMeanings;
import forGL.Meanings.MeansWhat.opMeanAsStr      as  opMeanAsStr;
import forGL.Meanings.MeansWhat.returnMeanAsStr  as  returnMeanAsStr;

import forGL.data.Data;

using   forGL.Dictionary.DictWord;
import  forGL.Dictionary.NLDictionary;

import forGL.NLImport.NLImport    as  NLImport;
import forGL.Export.NLExport      as  NLExport;

import forGL.ExportAs.NLExportAs  as  NLExportAs;

// Allow  Comments  in Haxe generated source file(s) of various programming languages
import  forGL.Comments.comment    as  comment;

using forGL.Run.ForGL_Run;


//
// Define a class for the Data stack
// 
class DataItem
{
	public var data_str       : String8;	// Quoted string or calculated string
	public var data_float     : Float;		// resolved Float value if Float type
	public var data_type      : NLTypes;   	// String, Float or Int
	public var data_int       : Int;		// resolved Integer value or Bool if Int type
	
	public function new( type : NLTypes, str: String8, float : Float, int : Int ) 
	{
		data_type  = type;
		data_str   = str;
		data_float = float;
		data_int   = int;
	}
}


class  ForGL_Run
{
//  	PUBLIC
//
//	These can be set by init() or by top level code directly
//
		public var run_text_line = 0;	// which line number where 0 is the top line

// 		Numbers
/*		
 * 			COMMENTED OUT   Testing using just Haxe  trace( )  API 
 * does not show a problem representing 52 Bit Integers inside a 64 Bit Float
 * 
 * 		More investigation is needed to see where problem really is:
 * 		Inside the utility  ui.msg( )  or the code it uses
 * 			OR  elsewhere ?
 * 
	// Haxe Infers: double precision IEEE 64 bit float, supports a 52 bit integer
	public var MAX_FLOAT_AS_INT         =  9007199254740991;
	
	// 64 bit signed integer, lower 63 bits = 0x7FFFFFFFFFFFFFFF = 9223372036854775807
	public var MAX_INT64       = Int64.make( 0x7FFFFFFF, 0xFFFFFFFF );	// CLASS and NOT a TYPE
	
	// 32 bit signed integer, lower 31 bits = 0x7FFFFFFF = 2147483647
	public var MAX_INT          : Int   =    0x7FFFFFFF;

	public var MIN_FLOAT_AS_INT         = -9007199254740992;
	
	// 64 bit signed integer = -9223372036854775808 = 0x8000000000000000	(using win7 Calculator)
	public var MIN_INT64        = Int64.make( 0x80000000, 0x00000000 );	// CLASS and NOT a TYPE
	
	// public var MIN_INT          : Int   = - (0x7FFFFFFF);		// 32 bit signed integer = -2147483647
	
	// Hex 2's complement form assumed
	public var MIN_INT             : Int   = - (0x80000000);        // 32 bit signed integer = -2147483648
*/


// 				Text UI features
//

	//	Set to true to convert internal UTF8 to OEM for display use only. See init
//	public var use_OEM = false;

//		Export the test Verb and anything it uses as Code in a programming language
//
	public var export_as_code = false;
	public var export_as_code_log = new Array<String8>();
	public var export_as_code_verb_name = "";

//	Set to true if User wants to see a little of how forGL works with internal names
	public var display_internal = false;

//
//	Set this to  true  for helpful details to Debug the Interpreter code
//
	public var show_details = false;
	
	// Show the values of the Words
	public var show_words_table = true;
	
	// Show values in the Data, Operator, and Noun stacks
	public var show_stacks = true;
	
	// Show only the Data stack
	public var show_stacks_Data_Only = false;
	
	// To manually step 1 word at a time
	public var single_step = true;
	
	public var delay_seconds_default = 1.0;
	
	public var delay_seconds = 1.0;  // 2.0; for readable animation

//
//  	PRIVATE
//

#if sys
	var stdin = Sys.stdin();
#end
	private var run_verbose = false;
	
	private var ForGLData : ForGL_data;
	private var nlDict : NLDictionary;
	
	private var nl_Import_used = false;
	private var nl_Import : NLImport;
	
	private var nl_Parse : Parse;
	
	private var in_dictionary_file_name  : String = "";
	
	private var use_Built_In_Dictionary = false;
	
	private var out_dictionary_file_name : String = "";

	
	private var dataOpNoun_text_line = 0;
	private var steps_done = 0;
	private var steps_done_Verb = 0;
	
	
	private var intp_ip = 0;
	
// Support for levels of Verbs and embedded Expressions
//
	private var old_dataStackFrames = new Array<Int>();
	private var old_dataStack       = new Array<DataItem>();
	
	private var old_opStackFrames   = new Array<Int>();
	private var old_opStack         = new Array<Int>();
	
	private var old_nounStackFrames = new Array<Int>();
	private var old_nounStack       = new Array<Int>();
	
	private var old_assignStackFrames = new Array<Int>();
	private var old_assignStack       = new Array<Int>();
	
	
	private var elapsed_intp_time = 0.0;
	
	private var user_def : String8 = "";

	
	public function new() 
	{
		comment( 
	"////////////////////////////////////////////////////////////////////////////////",
"",
"This is the top level class controlling overall Runtime behavior.",
"", 
"      See block comment at end of runInterpreter( ) for more information.",
"", 
"      Key Ideas ...",
"", 
"  Minimum Dependencies:",
"      Source of forGL definitions to work with",
"      Internal format as Source: forGL definitions may have been bound within application",
"          Use Case: User/Programmer has already finished Editing wanted.",
"              So an Internal format is all that is needed to run.",
"      Internal format may not include original source definitions.",
"", 
"      External format: forGL definitions arrived from:",
"          Temporary network connection",
"          Temporary file system connection",
"          IPC from another process running on same HW/OS platform (future?)",
"", 
"      See below for more rationale",
"", 
"  Other Dependencies:",
"      (optional) UI is available for display.",
"          Use Case: Runtime may be in headless Server mode",
"              so not needing UI.",
"", 
"      (optional) Data Store is available to Read/Write persistent data.",
"          Use Case: Runtime may be in Super Calculator mode ",
"              so not needing Data Store.",
"", 
"  Pre Conditions:",
"      Minimum Dependancies are true",
"      Optional Other Dependancies may be true as well",
"", 
"  Invariants:",
"",       
"  Post Conditions:",
""
);

		forgl_version = "v" + forgl_ver_major + "." + forgl_ver_minor + "." + forgl_ver_build + " " + forgl_ver_stability;
	}
	
	
	// Really simple Version stuff
	public var forgl_ver_major = "0";

	public var forgl_ver_minor = "0";		//	Increment this when Features are added
	
	public var forgl_ver_build = "1";		//	Increment this when a Build is to be distributed
	
	
	public var forgl_ver_stability = "Prototype"; // Prototype, Alpha, Beta, rc01, dev, Release
		
	// So above would be  v0.001 Prototype
	public var forgl_version = "";
	
//	public function getVersion() : String8
//	{
//		var ret_Ver = "v" + forgl_ver_major + "." + forgl_ver_minor + "." + forgl_ver_build + " " + forgl_ver_stability;
//		return ret_Ver;
//	}
//
//		Allow high level code to initialize the Runtime setup
//
	public function init( in_dict_name : String8, lines_added : Int, ?verbose : Bool = false ) : ReturnMeanings
	{
		comment( "", "Allow high level code to initialize the Runtime setup", "" );
		var ret_val = RET_IS_OK;
	try
	{
		lines_added = 0;
		run_verbose = verbose;

/*
 * 			COMMENTED OUT  see above where the variables are declared for details
 * 
		msg( "Max Integer    = " + Std.string( MAX_INT )  + "\t\tMin Integer    = " + Std.string( MIN_INT ) + "\n" );
		lines_added++;
		
		msg( "Max Integer64  = " + Std.string( MAX_INT64 )  + "\tMin Integer64  = " + Std.string( MIN_INT64 ) + "\n" );
		lines_added++;
		
		msg( "Max Int(float) = " + Std.string( MAX_FLOAT_AS_INT ) + "  Min Int(float) = " + Std.string( MIN_FLOAT_AS_INT ) + "\n" );
		lines_added++;
*/

/*
	#if ( !java && !js )
		msg( "Hit Esc to run not showing 3 stacks or 0 to 9 to set delay between each step" );
		while ( true )
		{
			var char_code = Sys.getChar( false );	// No ECHO of character to display
			if ( 0x1B == char_code )				// Escape ?
			{
				msg( "Will run full speed without showing changes to 3 stacks.\n" );
				single_step = false;
				break;
			}
			else
			{
				if ( ( 0x30 <= char_code )	// keyboard 0 to 9 ?  IF 0 then FULL SPEED Animation (see below)
				  && ( char_code <= 0x39 ) )
				{
					delay_seconds_default = char_code - 0x30;
					delay_seconds = delay_seconds_default;
					msg( "Will single step with " + delay_seconds + "seconds between steps.\n" );
					single_step = true;
					break;
				}
			}
		}
		msg( "Hit the Space bar to continue. " );
		while ( true )
		{
			var char_code = Sys.getChar( false );	// No ECHO of character to display
			
			if ( 0x20 == char_code )
				break;
		}
	#end
*/

		// Set up UI if available
		// Editor UI or
		// Debugger UI or
		// UI for application or
		// no UI if not available (just logging output)


		ForGLData = new forGL.data.ForGL_data();

		in_dictionary_file_name = in_dict_name;
		if ( 0 < in_dictionary_file_name.length )
		{
			// Verify or consistency check Dictionary file contents before use done elsewhere
			
			var init_result = ForGLData.init( in_dictionary_file_name, FILE_IS_DICTIONARY );
			
			in_dictionary_file_name = ForGLData.actual_path_file;
			
			if ( cast( init_result, Int ) < 0 )
			{
				// show what the Error was
				error( "\n    SEVERE ERROR  " + returnMeanAsStr( init_result ) + " trying to Initialize the Data service.  Stopping." );
				lines_added++;
				ret_val = init_result;
				in_dictionary_file_name = "";	// reset back to not do unneeded Read calls
				return ret_val;
			}

			
		
		}
		else
		{
			// USING the Built In Default dictionary.  Just fall through
		}
		
		nlDict = new NLDictionary();

		var dict_result = nlDict.init( in_dictionary_file_name );
	
		use_Built_In_Dictionary = nlDict.use_Built_In_Dictionary;
		
		if ( 0 != cast( dict_result, Int ) )
		{
			ret_val = dict_result;
		}
		else
		{
			lines_added++;
			lines_added++;
			lines_added++;
			
			if ( 0 < in_dictionary_file_name.length )
			{
				nl_Import = new NLImport();
				
				var import_result = nl_Import.importWords( ForGLData, nlDict, in_dictionary_file_name /*, use_OEM */ );
				
				if ( 0 < nl_Import.importWords_msgs.length )
				{
					if ( verbose )
						status( nl_Import.importWords_msgs );
					lines_added++;
					lines_added++;
					lines_added++;
				}
				
				ret_val = import_result;
			}
			else
				status( "No Dictionary name given so no Import of word(s).", YELLOW, false, true );
		}
		
		if ( 0 == cast( ret_val, Int ) )
			nl_Parse = new Parse();
	
//  No longer needed for Windows if using  chcp  65001  UTF8 Code Page command. NEEDS TESTING...
//
	//  Decided to ask about OEM conversion just 1 time when starting (and not for JavaScript)
	//
	//  This was a WORKAROUND (HACK) for Windows as default char Code Page is OEM
	//
/*
	#if !js
		msg( "Change UTF8 to OEM characters for display only (y/n) ? " );
		use_OEM = enterYes( );
		msg( "\r" );
		
		if ( use_OEM )
			// Set up OEM lookup table
			Utf8_to_OEM.init();
	#end
*/	
	}
	catch ( e:Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in forGL_run.init(): " + Std.string( e ) + " \n");
		
		ret_val = RET_IS_INTERNAL_ERROR;
	};
		
		
		return ret_val;
	}


// Release any resources that were acquired
	public function cleanUp() 
	{
		
		ForGLData.cleanUp();
		
		nlDict.cleanUp();
		
		if ( nl_Import_used )
		{
			nl_Import.cleanUp();
			nl_Import_used = false;
		}
	}
	

//
//		Helper to support showing Data stack values
//
	public function dataStackToString( dStack: Array<DataItem> ) : String8
	{
		comment( "Helper to support showing Data stack values" );
		if ( ( 0 == dStack.length )
		  && ( 0 == old_dataStack.length ) )
			return "[]";
		
		var result :String8 = "[";
		var i = 0;
		
		if ( 0 < old_dataStack.length )
		{
			while ( i < old_dataStack.length )
			{
				result += " ";
				if ( NL_INT == old_dataStack[ i ].data_type )
					result += Std.string( old_dataStack[ i ].data_int );
				else
				if ( NL_BOOL == old_dataStack[ i ].data_type )
				{
					if ( 1 == old_dataStack[ i ].data_int )
						result += "true";
					else
						result += "false";
				}
				else
				if ( NL_FLOAT == old_dataStack[ i ].data_type )
					result += Std.string( old_dataStack[ i ].data_float );
				else
				if ( NL_STR == old_dataStack[ i ].data_type )
					result = result.insertAt( result.length, old_dataStack[ i ].data_str );
				else
				{
					error( "INTERNAL ERROR: Some other data type in the Data stack. \n" );
					result += "'?'";
				}
				
				result += " ";
				i++; 
			}
			result += ":";
			i = 0;
		}
		
		while ( i < dStack.length )
		{
			result += " ";
			if ( NL_INT == dStack[ i ].data_type )
				result += Std.string( dStack[ i ].data_int );
			else
			if ( NL_BOOL == dStack[ i ].data_type )
			{
				if ( 1 == dStack[ i ].data_int )
					result += "true";
				else
					result += "false";
			}
			else
			if ( NL_FLOAT == dStack[ i ].data_type )
				result += Std.string( dStack[ i ].data_float );
			else
			if ( NL_STR == dStack[ i ].data_type )
				result = result.insertAt( result.length, dStack[ i ].data_str );
			else
			{
				error( "INTERNAL ERROR: Some other data type in the Data stack. \n" );
				result += "'?'";
			}
			
			result += " ";
			i++; 
		}
		
		result += "]";
		
		return result;
	}
	
//
//		Helper to support showing Operator stack values
//
	public function opStackToString( rStack : Array<NLToken>, oStack: Array<Int> ) : String8
	{
		comment( "Helper to support showing Operator stack values" );
		if ( ( 0 == oStack.length )
		  && ( 0 == old_opStack.length ) )
			return "[]";
		
		var result : String8 = "[";
		var i = 0;
	
	/*
		while ( i < oStack.length )
		{
			result += " ";
			var rIdx = oStack[ i ];
			result += opMeanAsStr( rStack[ rIdx ].token_op_means );
			result += " ";
			i++; 
		}
		
		result += "]";
		
		if ( 6 + result.length >= 79 )
		{
	*/
			// Use the wanted names or symbols
			result = "[";

			if ( 0 < old_opStack.length )
			{
				while ( i < old_opStack.length )
				{
					result += " ";
					var rIdx = old_opStack[ i ];
					
					if ( display_internal )
						result = result.insertAt( result.length, rStack[ rIdx ].internal_token );
					else
						result = result.insertAt( result.length, rStack[ rIdx ].visible_token );
					result += " ";
					i++; 
				}
				result += ":";
				i = 0;
			}
			
			while ( i < oStack.length )
			{
				result += " ";
				var rIdx = oStack[ i ];
				
				if ( display_internal )
					result = result.insertAt( result.length, rStack[ rIdx ].internal_token );
				else
					result = result.insertAt( result.length, rStack[ rIdx ].visible_token );
				result += " ";
				i++; 
			}
			result += "]";
	//	}
		
		return result;
	}	

//
//		Helper to support showing Noun stack values
//
	public function nounStackToString( rStack : Array<NLToken>, nStack: Array<Int> ) : String8
	{
		comment( "Helper to support showing Noun stack values" );
		if ( 0 == nStack.length )
			return "[]";
		
		var result = "[";
		var i = 0;
		
		while ( i < nStack.length )
		{
			var rIdx = nStack[ i ];
			if ( display_internal )
				result += " (" + rStack[ rIdx ].internal_token + ")";
			else
				result += " (" + rStack[ rIdx ].visible_token + ")";
			
			if ( NL_INT == rStack[ rIdx ].token_noun_data )
				result += Std.string( rStack[ rIdx ].token_int );
			else
			if ( NL_BOOL == rStack[ rIdx ].token_noun_data )
			{
				if ( 1 == rStack[ rIdx ].token_int )
					result += "true";
				else
					result += "false";
			}
			else
			if ( NL_FLOAT == rStack[ rIdx ].token_noun_data )
				result += Std.string( rStack[ rIdx ].token_float );
			else
			if ( NL_STR == rStack[ rIdx ].token_noun_data )
				result += rStack[ rIdx ].token_str;
			else
			{
				// Use the Noun name
				// result += rStack[ rIdx ].visible_token;   // Noun name used above already
			}
				
			result += " ";
			i++; 
		}
		
		result += "]";
		
		return result;
	}


//
//		Helper to support showing Data stack if changed from before
//	
	private var prev_dataStackOut : String8 = "";
	private var prev_opStackOut   : String8 = "";
	private var prev_nounStackOut : String8 = "";

	public function dataStackOut( dStack: Array<DataItem> ) : Int
	{
		comment( "Helper to support showing Data stack if changed from before" );
		var lines_added = 0;
		
		var out = dataStackToString( dStack );
		
		if ( out != prev_dataStackOut )
		{
			setOut( DATA_STACK_OUT );
		#if ! js
			msg( "Data = " + out + "\n" );
		#else
			msg( "Data = " + out );
		#end
			setOut();
			prev_dataStackOut = out;
			
		#if !js
			lines_added++;
		#end
		}
		
		return lines_added;
	}


//
//		Helper to support showing Data, Operator and Noun stack values
//
	private var view_DON_throttle = false;
	private var last_view_DON_time = 0.0;
	
	public function viewDataOpNouns( rStack : Array<NLToken>, dStack : Array<DataItem>, 
									oStack: Array<Int>, nStack: Array<Int>, 
									?textLine : Int = -1, ?first_time : Bool = false ) : Void
	{
		comment( "", "Helper to support showing Data, Operator and Noun stack values", "" );
		if ( first_time )
		{
			prev_dataStackOut = "";
			prev_opStackOut   = "";
			prev_nounStackOut = "";
			last_view_DON_time = Date.now().getTime();
		}
		else
		if ( view_DON_throttle )
		{
			comment( "Display changed Data and other values ONLY a few times a second" );
// 		
//		OK to do as these values are very likely to change in less than a second anyway.
//		And otherwise Humans could only percieve the changes as a blur rather than discrete readable values.
//
// 		THIS is a BIG Performance improvement when running full speed ! (50 times faster or more)
//
			var time = Date.now().getTime();
			if ( time - last_view_DON_time < 0.2 )		// About 5 times a second
				return;

			last_view_DON_time = time;
		}
		
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		if ( 0 <= textLine )
		{
			savePos();
			goToPos( textLine, 0 );
		}
	#end
		var str = "Data  " + dataStackToString( dStack );
		if ( str != prev_dataStackOut )
		{
			setOut( DATA_STACK_OUT );
			msg( str, DATA_COLOR );
			eraseToLineEnd( str.length );
			prev_dataStackOut = str;
		}
	
		if ( ! show_stacks_Data_Only )
		{
		#if cs
			msg( "\n" );
		#end
			
			str = "Ops   " + opStackToString( rStack, oStack );
			if ( str != prev_opStackOut )
			{
				setOut( OP_STACK_OUT );
				
			#if ( !cs && !js )
				if ( 0 <= textLine )
					goToPos( textLine + 1, 0 );
				else
					msg( "\n" );
			#end
			
				msg( str, OP_COLOR );

			#if !js
				eraseToLineEnd( str.length );
			#end
			
			#if cs
				msg( "\n" );
			#end
			
				prev_opStackOut = str;
			}
			
			str = "Nouns " + nounStackToString( rStack, nStack );
			if ( str != prev_nounStackOut )
			{
				setOut( NOUN_STACK_OUT );
				
			#if ( !cs && !js )
				if ( 0 <= textLine )
					goToPos( textLine + 2, 0 );
				else
					msg( "\n" );
			#end
			
				msg( str, NOUN_COLOR );
				
			#if !js
				eraseToLineEnd( str.length );
			#end
			
			#if cs
				msg( "\n" );
			#end
			
				prev_nounStackOut = str;
			}
		}
		
		setOut();
		
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		restorePos();
	#end
		
	}
	
//
//		Show (built in Verb) output support
//
	private var prev_show1_data : String8 = "";
	
	public function show1Data( dataStr : String8, ?textLine : Int = -1 ) : Void
	{
		comment( "", "Show (built in Verb) output support", "" );
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		if ( 0 <= textLine )
		{
			savePos();
			goToPos( textLine, 0 );
		}
	#end
		
		prev_show1_data = prev_show1_data.insertAt( prev_show1_data.length8(), dataStr );
		
		setOut( VERB_OUT );
		msg( prev_show1_data );
		setOut();
		
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		if ( 0 <= textLine )
		{
			restorePos();
		}
	#end
	}

//
//		Helper to support showing the Repeat Count
//
	public function viewRepeatCount( repeatCount : Int, ?textLine : Int = -1 ) : Void
	{
		comment( "", "Helper to support showing the Repeat Count", "" );
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		if ( 0 <= textLine )
		{
			savePos();
			goToPos( textLine, 0 );
		}
	#end
		
		msg( Std.string( repeatCount ) );
		
	#if ( !cs && !js )		// so far  C# does NOT support text Cursor Positioning
		if ( 0 <= textLine )
		{
			restorePos();
		}
	#end
		
	}
	
/*
// Helper to support embedded groups of expressions
//
	private function getDataStackLenFenced( dStack : Array<DataItem> ) : Int
	{
		var len = dStack.length - data_stack_fence[ data_stack_fence.length - 1 ];
		
		if ( 0 > len )
			len = 0;
		
		return len;
	}

// Helper to support embedded groups of expressions
//
	private function getOpStackLenFenced( oStack : Array<Int> ) : Int
	{
		var len = oStack.length - op_stack_fence[ op_stack_fence.length - 1 ];
		
		if ( 0 > len )
			len = 0;
		
		return len;
	}
*/
	

// 		Run an Assignment Operator if Data available and Noun available
//
	private function runAssignment( rStack : Array<NLToken>, dStack : Array<DataItem>, 
									oStack : Array<Int>, nStack : Array<Int>, 
									?assign_op : OpMeanings = OP_IS_ASSIGNMENT,
									?op_idx = -1 ) : ReturnMeanings
	{
		comment( "Run an Assignment Operator if Data available and Noun available", 
		"Need 1 Data item (or Noun with values that are pushed as Data) as source",
		"and need a Noun type as destination",
		"If NO Noun destination then Assignment is done later." );
		// ASSUMPTION about correctness here. NEEDS many tests.
		
		if ( ( 0 < nStack.length ) && ( 0 < dStack.length ) )
		{
			steps_done++;	// Presume success
			steps_done_Verb++;
			
			var data_type_OK = true;
			
			// Change the latest Noun but leave the rest of nouns Array alone
			// Get index of Noun and assign Data to it
			var nounIdx = nStack[ nStack.length - 1 ];
			
			if ( 0 <= op_idx )
			{
				//if ( OP_IS_ASSIGN_FROM == assign_op )
				//{
					var noun_name = rStack[ op_idx - 1 ].internal_token;
					
					// Find the same Name using the Noun stack
					var k = 0;
					while ( k < nStack.length )
					{
						if ( rStack[ nStack[ k ] ].internal_token == noun_name )
						{
							nounIdx = nStack[ k ];
							break;
						}
						k++;
					}
				//}
			}
			
			// Get the OLDEST Data
			var dataIdx = 0;								// was dStack.length - 1;
			var dataType = dStack[ dataIdx ].data_type;
			var data1_str = "";
			
			var data1_name = "";
			if ( NL_STR != dataType )
				data1_name = dStack[ dataIdx ].data_str;	// Possible Name of related Noun
			
			if ( ( NL_INT  == dataType )
			  || ( NL_BOOL ==  dataType ) )
			{
				rStack[ nounIdx ].token_noun_data = dataType;
				rStack[ nounIdx ].token_int = dStack[ dataIdx ].data_int;
				data1_str = Std.string( dStack[ dataIdx ].data_int );
			}
			else
			if ( NL_FLOAT == dataType )
			{
				rStack[ nounIdx ].token_noun_data = dataType;
				rStack[ nounIdx ].token_float = dStack[ dataIdx ].data_float;
				data1_str = Std.string( dStack[ dataIdx ].data_float );
			}
			else
			if ( NL_STR == dataType )
			{
				rStack[ nounIdx ].token_noun_data = dataType;
				rStack[ nounIdx ].token_str = dStack[ dataIdx ].data_str;
				data1_str = dStack[ dataIdx ].data_str;
			}
			else
			{
				error( "\n   INTERNAL ERROR: Not valid Data type in the Data Stack\n" );
				run_text_line++;
				run_text_line++;
				steps_done--;
				steps_done_Verb--;
				//data_type_OK = false;
			}
			
			if ( show_details )
			{
				var msg_str = " ";
				if ( display_internal )
					msg_str += rStack[ nounIdx ].internal_token;
				else
					msg_str += rStack[ nounIdx ].visible_token;
				msg_str += "  now is  " + data1_str;
				if ( 0 < data1_name.length )
					msg_str += "(" + data1_name + ")";
				msg_str += "\n";
				msg( msg_str );
				run_text_line++;
			}

		/*
		 * This was done very early when working towards Export As Code
		 * likely not needed after EaC is functional.
		 * 
			if ( export_as_code )
			{
				comment( "", "Use Noun Name if available for Exported Code log", "" );
				var exp_str = data1_str;
				if ( 0 < data1_name.length )
					exp_str = data1_name;
				
				comment( "", "use typical  =  as Assignment operator", "" );
				export_as_code_log.push( rStack[ nounIdx ].visible_token + " = " + exp_str );
			}
		*/
			
			// This consumes the Data so remove it
			if ( data_type_OK )
				dStack.shift();		// remove OLDEST data
				
			if ( show_stacks )
			{
				#if cs
				{
					run_text_line += dataStackOut( dStack );
				}
				#else
					viewDataOpNouns( rStack, dStack, oStack, nStack, dataOpNoun_text_line );
				#end
			}
		}
		else
		if ( 1 < nStack.length )
		{
			// Noun to Noun Assignment
			// 
			// Assignment is in Reading Order so lower Noun index is the Source
			//    and higher Noun index in the Run stack is the Destination
			// Just use most recent ???
			// 
			// ASSUMPTION about correctness here. NEEDS many tests.
			
			steps_done--;
			steps_done_Verb--;
			return RET_IS_NOT_IMPLEMENTED;
		}
		else
		{
			msg( " INFO: Not enough Data or Nouns to do Assignment now. Done later.\n" );
			run_text_line++;
			
			return RET_IS_NEEDS_DATA;	// INFO: Not enough Data
		}
		
		return RET_IS_OK;
	}


//		Helper to add start char Quote and end char Quote
//
	private function addQuotes( str : String8 ) : String8
	{
		comment( "Helper to add start char double Quote and end char double Quote" );
		return "\"" + str + "\"";
	}


//		Helper to remove start char Quote and end char Quote
//
	private function trimQuotes( str : String8 ) : String8
	{
		comment( "Helper to remove start char double Quote and end char double Quote" );
		if ( ( "\"" == str.charAt8( 0 ) )
		  && ( "\"" == str.charAt8( str.length - 1 ) ) )
			return str.trim( "\"" );	// trim Quote characters
		return str;
	}


//		Use 1 number (Float or Int or String) with a Math Operator like  abs  sin  cos  tan
//			Try to convert String to a number if given Data is a String
//
//    Most Results are a Float. Some are Int. None are Bool or String.
//
	private function runMath1Data( rStack : Array<NLToken>, dStack : Array<DataItem>, 
							oStack : Array<Int>, nStack : Array<Int>,
							after_expression : Bool ) : ReturnMeanings
	{
		comment( "Use 1 number (Float or Int or String) with a Math Operator" );
		// Use OLDEST Op, NOT NEWEST, No change to Operator stack yet
		var opIdx = oStack[ 0 ];
		
		// Use OLDEST Data
		var dataIdx = 0;
		
		if ( after_expression )
		{
			// NEWEST IF After end of an Expression
			opIdx   = oStack[ oStack.length - 1 ];
			dataIdx = dStack.length - 1;
		}
		
		var math_1_int   = dStack[ dataIdx ].data_int;
		var math_1_float = dStack[ dataIdx ].data_float;
		var math_1_type  = dStack[ dataIdx ].data_type;
		
		var op_to_do = rStack[ opIdx ].token_op_means;

		var data1_str = "";
		var data1_name = "";

		if ( NL_BOOL == math_1_type )
		{
			// BOOLEAN type is not correct for use as Floating point.
			error( "  Syntax ERROR: " + opMeanAsStr( op_to_do ) + " with a Bool not correct.  Stopping now.\n" );
			run_text_line++;
			return RET_IS_USER_ERROR_DATA;
		}

		// handle Strings.
		if ( NL_STR == math_1_type )
		{
			// Allow User to have Dynamic Data Types.
			// See if String can be converted to Number and then go on.
			var resolve_info = new ResolveInfo();
			
			var type_found = resolveType( dStack[ dataIdx ].data_str, resolve_info, run_verbose, true );
			
			if ( ( NL_FLOAT != type_found )
			  && ( NL_INT   != type_found ) )
			{
				error( " Syntax ERROR: " + opMeanAsStr( op_to_do ) + " with a String " + dStack[ dataIdx ].data_str + " not available. Stopping.\n" );
				run_text_line++;
				
				return RET_IS_USER_ERROR_DATA;	// SEVERE SYNTAX or LOGICAL ERROR in Verb and Noun code.
			}
			
			math_1_type  = type_found;
			math_1_float = resolve_info.resolve_float;
			math_1_int   = resolve_info.resolve_int;
		}
		else
			data1_name = dStack[ dataIdx ].data_str;
		
		// Set Float if needed
		if ( NL_INT == math_1_type )
		{
			math_1_float = math_1_int;
			data1_str = Std.string( math_1_int );
		}
		else
		{
			data1_str = Std.string( math_1_float );
		}

		if ( after_expression )
		{
			dStack.pop();	// Remove the NEWEST Data item
			oStack.pop();	// Remove the NEWEST Operator
		}
		else
		{
			dStack.shift();		// Remove the OLDEST Data item
			oStack.shift();		// Remove the OLDEST Operator
		}

		// do Operator and Push result on Data stack
		//
		// All these Operators use Float data
		
		var result : Float = 0.0;
		var result_int : Int = 0;
		var is_int = false;
		
	try
	{
		switch ( op_to_do )
		{
			case OP_IS_ABS:
				result = Math.abs( math_1_float );
				
			// Convert Radians to Degrees
			case OP_IS_TO_DEGREES:
				result = math_1_float * 180.0 / Math.PI;
				
			// Convert Degrees to Radians
			case OP_IS_TO_RADIANS:
				result = math_1_float * Math.PI / 180.0;
			
			case OP_IS_SIN:
				result = Math.sin( math_1_float );
			case OP_IS_COS:
				result = Math.cos( math_1_float );
			case OP_IS_TAN:
				result = Math.tan( math_1_float );
			case OP_IS_ASIN:
				result = Math.asin( math_1_float );
			case OP_IS_ACOS:
				result = Math.acos( math_1_float );
			case OP_IS_ATAN:
				result = Math.atan( math_1_float );
			case OP_IS_EXP:
				result = Math.exp( math_1_float );

			case OP_IS_LN:
				result = Math.log( math_1_float );	// Haxe only supplies log that is really natural base e log or ln

			case OP_IS_LOG:
				// base 10 log
				// Use base e log (ln) to Convert to base 10 log
				// This looks wrong but remember Haxe math.log is really  ln
				result = Math.log( math_1_float ) / Math.log( 10 );

			case OP_IS_SQRT:
				// Check for NEGATIVE number.  For now  NOT Allowed.
				// TODO  support Complex numbers sometime
				if ( 0.0 > math_1_float )
				{
					error( " ERROR: " + opMeanAsStr( op_to_do ) + " of " + Std.string( math_1_float ) + " not allowed. Stopping now.\n" );
					run_text_line++;
		
					return RET_IS_USER_ERROR_DATA;	// This is a SEVERE LOGICAL ERROR by User code.
				}
				result = Math.sqrt( math_1_float );

			case OP_IS_ROUND:
				is_int = true;
				result_int = Math.round( math_1_float );
			case OP_IS_FLOOR:
				is_int = true;
				result_int = Math.floor( math_1_float );
			case OP_IS_CEIL:
				is_int = true;
				result_int = Math.ceil( math_1_float );
			
			default:
				// Somebody added another Operator perhaps?
				error( "  INTERNAL ERROR: " + opMeanAsStr( op_to_do ) + " of " + Std.string( math_1_float ) + " Unknown. Stopping now.\n" );
				run_text_line++;
				return RET_IS_INTERNAL_ERROR;
		}
	
	}
	catch ( e:Dynamic ) 
	{
		//var except_stack = CallStack.callStack();

		warning( "\nMath ERROR: Exception in  runMath1Data(): " + Std.string( e ) + "\n");
		
		//var calls_str = CallStack.toString( except_stack );

		//warning( Std.string( calls_str ) );

		// TODO: Handle Math Error(s) some more here ...
	};

		// TODO  low priority: See if result was really an Integer
		
		if ( is_int )
		{
			if ( after_expression )
				dStack.push( new DataItem( NL_INT, "", 0.0, result_int ) );		// new NEWEST Data
			else
				dStack.unshift( new DataItem( NL_INT, "", 0.0, result_int ) );  // new OLDEST Data
				
			result = result_int;
		}
		else
		{
			if ( after_expression )
				dStack.push( new DataItem( NL_FLOAT, "", result, 0 ) );		// new NEWEST Data
			else
				dStack.unshift( new DataItem( NL_FLOAT, "", result, 0 ) );  // new OLDEST Data
		}
	
		if ( show_details )
		{
			var msg_str = " " + opMeanAsStr( op_to_do ) + "  of  " + data1_str;
			if ( 0 < data1_name.length )
				msg_str += " ( " + data1_name + " )";
			msg( msg_str + "  is  " + Std.string( result ) + "\n" );
			run_text_line++;
		}

	/*
		if ( export_as_code )
		{
			comment( "", "Use Noun Name if available for Exported Code log", "" );
			var exp_str = data1_str;
			if ( 0 < data1_name.length )
				exp_str = data1_name;
			
			comment( "", "use function call style for Export", "" );
			export_as_code_log.push( opMeanAsStr( op_to_do, true ) + " ( " + exp_str );
		}
	*/

		if ( show_stacks )
		{
			#if cs
			{
				run_text_line += dataStackOut( dStack );
			}
			#else
				viewDataOpNouns( rStack, dStack, oStack, nStack, dataOpNoun_text_line );
			#end
		}

		return RET_IS_OK;
	}


//		Use 2 Strings with Operators:  +  -  *
//
	private function runStr2Data( op_to_do : OpMeanings, dStack : Array<DataItem>,
								after_expression : Bool ) : ReturnMeanings
	{
		comment( " Use 2 Strings with Operators:  +  -  * " );
		// We have the Data count needed or more. Use 2 OLDEST.
		var dataIdx0 = 0;
		var dataIdx1 = 1;
		
		if ( after_expression )
		{
			// NEWEST IF After end of an Expression
			dataIdx0 = dStack.length - 2;
			dataIdx1 = dStack.length - 1;
		}
		
		var str1 = trimQuotes( dStack[ dataIdx0 ].data_str );
		if ( NL_INT == dStack[ dataIdx0 ].data_type )
			str1 = Std.string( dStack[ dataIdx0 ].data_int );
		else
		if ( NL_FLOAT == dStack[ dataIdx0 ].data_type )
			str1 = Std.string( dStack[ dataIdx0 ].data_float );
		else
		if ( NL_BOOL == dStack[ dataIdx0 ].data_type )
		{
			// This is either some clever use of forGL Bool or a problem with User code?
			if ( 1 == dStack[ dataIdx0 ].data_int )
				str1 = "true";
			else
				str1 = "false";
		}
		else
		if ( NL_STR != dStack[ dataIdx0 ].data_type )
		{
error( "\nINTERNAL ERROR: Unknown Data item Type: " + Std.string( dStack[ dataIdx0 ].data_type ) + " Stopping.\n" );
			run_text_line++;
			run_text_line++;
				
			return RET_IS_INTERNAL_ERROR;
		}
		
		var str2 = trimQuotes( dStack[ dataIdx1 ].data_str );
		if ( NL_INT == dStack[ dataIdx1 ].data_type )
			str2 = Std.string( dStack[ dataIdx1 ].data_int );
		else
		if ( NL_FLOAT == dStack[ dataIdx1 ].data_type )
			str2 = Std.string( dStack[ dataIdx1 ].data_float );
		else
		if ( NL_BOOL == dStack[ dataIdx1 ].data_type )
		{
			// This is either some clever use of forGL Bool or a problem with User code?
			if ( 1 == dStack[ dataIdx1 ].data_int )
				str2 = "true";
			else
				str2 = "false";
		}
		else
		if ( NL_STR != dStack[ dataIdx1 ].data_type )
		{
error( "\nINTERNAL ERROR: Unknown Data item Type: " + Std.string( dStack[ dataIdx1 ].data_type ) + " Stopping.\n" );
			run_text_line++;
			run_text_line++;
				
			return RET_IS_INTERNAL_ERROR;
		}
		
		var ret_val = RET_IS_OK;
		var result : String8 = "";
		switch ( op_to_do )
		{
			case OP_IS_PLUS:
				result = str1.insertAt( str1.length8(), str2 );
				
			case OP_IS_CONCAT:
				result = str1.insertAt( str1.length8(), str2 );
				
			case OP_IS_MINUS:
				// Use the split function to get rid of all instances of str2 in str1
				if ( ( 0 < str2.length8() )
				  && ( 0 < str1.length8() ) )
				{
					var pieces = Strings.split8( str1, str2 );
					while ( 0 < pieces.length )
						result += pieces.shift();
				}
				else
					result = str1;
					
			case OP_IS_UNCONCAT:
				// Use the split function to get rid of all instances of str2 in str1
				if ( ( 0 < str2.length )
				  && ( 0 < str1.length ) )
				{
					var pieces = Strings.split8( str1, str2 );
					while ( 0 < pieces.length )
						result += pieces.shift();
				}
				else
					result = str1;
				
			case OP_IS_MULTIPLY:
error( "\nINTERNAL ERROR: Copy a string multiple times is NOT IMPLEMENTED.  Stopping.\n" );
				ret_val = RET_IS_NOT_IMPLEMENTED;
				
			default:
error( "\nINTERNAL ERROR:  " + opMeanAsStr( op_to_do ) + " Wrong Operator to use with a string.  Stopping.\n" );
				ret_val = RET_IS_INTERNAL_ERROR;
		}
		
		if ( RET_IS_OK == ret_val )
		{
			if ( after_expression )
			{
				dStack.pop();
				dStack.pop();
				
				dStack.push( new DataItem( NL_STR, addQuotes( result ), 0, 0 ) ); // new NEWEST Data
			}
			else
			{
				dStack.shift();
				dStack.shift();
				
				dStack.unshift( new DataItem( NL_STR, addQuotes( result ), 0, 0 ) ); // new OLDEST Data
			}
		}
		
		return ret_val;
	}


//		Use 2 numbers with a Math Operator like  +  -  *  /  %
//
	private function runMath2Data( rStack : Array<NLToken>, dStack : Array<DataItem>, 
							oStack : Array<Int>, nStack : Array<Int>,
							after_expression : Bool ) : ReturnMeanings
	{
		comment( "Use 2 numbers with a Math Operator", "" );
		// Use OLDEST op, NOT NEWEST, No change to Operator stack yet
		var opIdx = oStack[ 0 ];
		
		// We have the Data count needed or more. Use 2 OLDEST.
		var dataIdx0 = 0;
		var dataIdx1 = 1;
		
		if ( after_expression )
		{
			opIdx = oStack[ oStack.length - 1 ];	// NEWEST IF After end of an Expression
			dataIdx0 = dStack.length - 2;
			dataIdx1 = dStack.length - 1;
		}

		var op_to_do = rStack[ opIdx ].token_op_means;
		
		var running_msg = "";
		var data1_str = "";
		var data2_str = "";
		var data1_name = "";
		var data2_name = "";
		
		if ( show_details )
		{
			running_msg = "  Running op:  " + opMeanAsStr( op_to_do ) + "\n";
		//	msg( running_msg );
		//	run_text_line++;
		}
		
		var math_1_int   : Int = 0;
		var math_1_float : Float = 0;
		var math_2_int   : Int = 0;
		var math_2_float : Float = 0;
		
		// 2 Data items
		var math_1_type = dStack[ dataIdx0 ].data_type;
		var math_2_type = dStack[ dataIdx1 ].data_type;
		
		if ( NL_STR != math_1_type )
			data1_name = dStack[ dataIdx0 ].data_str;	// Possible Name of related Noun
			
		if ( NL_STR != math_2_type )
			data2_name = dStack[ dataIdx1 ].data_str;	// Possible Name of related Noun
		
		var need_conversion = false;
		
		// Bool only with other Bool
		if ( ( math_1_type != math_2_type )
		  && ( ( NL_BOOL == math_1_type )
		    || ( NL_BOOL == math_2_type ) ) )
		{
			msg( running_msg );
			run_text_line++;
			error( " Syntax ERROR: Only a Bool with a Bool is valid.  Stopping now.\n" );
			run_text_line++;
			return RET_IS_USER_ERROR_DATA;	// This is a SEVERE SYNTAX or LOGICAL ERROR.
		}
		
		// Set Both Integer and Float
		if ( NL_INT == math_1_type )
		{
			math_1_int = dStack[ dataIdx0 ].data_int;
			math_1_float = math_1_int;
			if ( show_details || export_as_code )
				data1_str = Std.string( math_1_int );
		}
		else
		if ( NL_FLOAT == math_1_type )
		{
			math_1_float = dStack[ dataIdx0 ].data_float;
			if ( show_details || export_as_code )
				data1_str = Std.string( math_1_float );
		}
		else
			need_conversion = true;

		if ( NL_INT == math_2_type )
		{
			math_2_int = dStack[ dataIdx1 ].data_int;
			math_2_float = math_2_int;
			if ( show_details || export_as_code )
				data2_str = Std.string( math_2_int );
		}
		else
		if ( NL_FLOAT == math_2_type )
		{
			math_2_float = dStack[ dataIdx1 ].data_float;
			if ( show_details || export_as_code )
				data2_str = Std.string( math_2_float );
		}
		else
			need_conversion = true;
		
		// handle Strings.
		if ( need_conversion )
		{
			// Check for allowed String Operators that need 2 Data items
			//
			// These Operators require use of strings
			if ( ( OP_IS_CONCAT   == op_to_do )
			  || ( OP_IS_UNCONCAT == op_to_do ) )
			{
				var str2result = runStr2Data( op_to_do, dStack, after_expression );
				if ( 0 == cast( str2result, Int ) )
				{
					// Remove the Operator
					if ( after_expression )
						oStack.pop();
					else
						oStack.shift();
				}
					
				return str2result;
			}
			
			// Allow User to have Dynamic Data Types.
			var resolve_info = new ResolveInfo();
			var math_error = false;
			
			// See if String(s) can be converted to Numbers and then go on.
			if ( NL_STR == math_1_type )
			{
				math_1_type = resolveType( dStack[ dataIdx0 ].data_str, resolve_info, run_verbose, true );
				if ( NL_FLOAT == math_1_type )
					math_1_float = resolve_info.resolve_float;
				else
				if ( NL_INT == math_1_type )
				{
					math_1_int = resolve_info.resolve_int;
					math_1_float = math_1_int;
				}
				else
					math_error = true;
			}
			
			if ( ( ! math_error ) 
			  && ( NL_STR == math_2_type ) )
			{
				math_2_type = resolveType( dStack[ dataIdx1 ].data_str, resolve_info, run_verbose, true );
				if ( NL_FLOAT == math_2_type )
					math_2_float = resolve_info.resolve_float;
				else
				if ( NL_INT == math_2_type )
				{
					math_2_int = resolve_info.resolve_int;
					math_2_float = math_2_int;
				}
				else
					math_error = true;
			}
			
			if ( math_error )
			{
				// Check for allowed String Operators that need 2 Data items
				if ( ( OP_IS_PLUS     == op_to_do )
				  || ( OP_IS_MINUS    == op_to_do )
				  || ( OP_IS_MULTIPLY == op_to_do ) )
				{
					var str2result = runStr2Data( op_to_do, dStack, after_expression );
					if ( 0 == cast( str2result, Int ) )
					{
						// Remove the Operator
						if ( after_expression )
							oStack.pop();
						else
							oStack.shift();			
					}
						
					return str2result;
				}
			
				error( " Syntax ERROR: " + opMeanAsStr( op_to_do ) + " with a String not available. Stopping now.\n" );
				run_text_line++;
				
				return RET_IS_USER_ERROR_DATA;	// This is a SEVERE SYNTAX or LOGICAL ERROR.
			}
		}
		else
		{
			// Set Both Integer and Float
			if ( NL_INT == math_1_type )
			{
				math_1_int = dStack[ dataIdx0 ].data_int;
				math_1_float = math_1_int;
				if ( show_details )
					data1_str = Std.string( math_1_int );
			}
			else
			{
				math_1_float = dStack[ dataIdx0 ].data_float;
				if ( show_details )
					data1_str = Std.string( math_1_float );
			}
			
			if ( NL_INT == math_2_type )
			{
				math_2_int = dStack[ dataIdx1 ].data_int;
				math_2_float = math_2_int;
				if ( show_details )
					data2_str = Std.string( math_2_int );
			}
			else
			{
				math_2_float = dStack[ dataIdx1 ].data_float;
				if ( show_details )
					data2_str = Std.string( math_2_float );
			}
		}

		var math_is_float = true;
		if ( ( ( NL_INT == math_1_type ) && ( NL_INT == math_2_type ) )
		    || ( NL_BOOL == math_1_type ) )
		{
			
			if ( ( OP_IS_PLUS == op_to_do )
			  || ( OP_IS_MINUS == op_to_do )
			  || ( OP_IS_MULTIPLY == op_to_do )
			  || ( OP_IS_MODULO == op_to_do )  // Can't be Divide for Integer Operators
			  || ( OP_IS_EQUAL == op_to_do )
			  || ( OP_IS_NOT_EQUAL == op_to_do )
			  || ( OP_IS_LESS_THAN == op_to_do )
			  || ( OP_IS_LESS_OR_EQUAL == op_to_do )
			  || ( OP_IS_GREATER_THAN == op_to_do )
			  || ( OP_IS_GREATER_OR_EQUAL == op_to_do ) )
				math_is_float = false;
		}

		if ( after_expression )
		{
			// Remove NEWEST
			dStack.pop();
			dStack.pop();
			
			oStack.pop();
		}
		else
		{
			dStack.shift();	// Both from Data stack consumed
			dStack.shift();	// Remove 2 OLDEST

			oStack.shift();			// Remove the Operator
		}

		// Do Operator and Push result on Data stack
		//
		// TODO  Use a try catch block. Check for OVERFLOW
	
		var bool_ret : Bool = false;
		var use_bool : Bool = false;
		
		var result_int : Int = 0;
		var result : Float = 0.0;
		
		if ( NL_BOOL == math_1_type )
		{
			use_bool = true;
			switch ( op_to_do )
			{
			// Comparison				(these result in a Bool)
				case OP_IS_EQUAL:
					bool_ret = ( math_1_int == math_2_int );
				
				case OP_IS_NOT_EQUAL:
					bool_ret = ( math_1_int != math_2_int );
					
				case OP_IS_LESS_THAN:
					bool_ret = ( math_1_int < math_2_int );

				case OP_IS_LESS_OR_EQUAL:
					bool_ret = ( math_1_int <= math_2_int );
					
				case OP_IS_GREATER_THAN:
					bool_ret = ( math_1_int > math_2_int );
					
				case OP_IS_GREATER_OR_EQUAL:
					bool_ret = ( math_1_int >= math_2_int );
	
				default:
					// Somebody added another Operator perhaps?
					use_bool = false;
			}
			
			if ( use_bool )
			{
				if ( bool_ret )
					result_int = 1;
				else
					result_int = 0;

				// Bool is stored as Int data but marked as Bool
				if ( after_expression )
					dStack.push( new DataItem( NL_BOOL, "", 0, result_int ) ); // new NEWEST Data
				else
					dStack.unshift( new DataItem( NL_BOOL, "", 0, result_int ) ); // new OLDEST Data
			}
			result = result_int;
		}
		else
		if ( ! math_is_float )
		{
			comment( "Integer part" );
		try
		{
			switch ( op_to_do )
			{
				case OP_IS_PLUS:
					result_int = math_1_int + math_2_int;
				case OP_IS_MINUS:
					result_int = math_1_int - math_2_int;
				case OP_IS_MULTIPLY:
					result_int = math_1_int * math_2_int;
				case OP_IS_DIVIDE:
					// Haxe Divide produces a Float result
					if ( 0 == math_2_int )
					{
						error( "ERROR: Divide by 0 not allowed. Stopping. \n" );
						run_text_line++;
						return RET_IS_USER_ERROR_DATA;
					}
					else
					{
						var temp_float = math_1_int / math_2_int;
						result_int = Math.floor( temp_float );
					}

				case OP_IS_MODULO:
					if ( 0 == math_2_int )
					{
						// Invalid Modulo operand.
						result_int = math_1_int;
					}
					else
						result_int = math_1_int % math_2_int;

			// Comparison				(these result in a Bool)
				case OP_IS_EQUAL:
					bool_ret = ( math_1_int == math_2_int );
					use_bool = true;
				
				case OP_IS_NOT_EQUAL:
					bool_ret = ( math_1_int != math_2_int );
					use_bool = true;
					
				case OP_IS_LESS_THAN:
					bool_ret = ( math_1_int < math_2_int );
					use_bool = true;
				
				case OP_IS_LESS_OR_EQUAL:
					bool_ret = ( math_1_int <= math_2_int );
					use_bool = true;
					
				case OP_IS_GREATER_THAN:
					bool_ret = ( math_1_int > math_2_int );
					use_bool = true;
					
				case OP_IS_GREATER_OR_EQUAL:
					bool_ret = ( math_1_int >= math_2_int );
					use_bool = true;
	
				default:
					// Somebody added another Operator perhaps?
					result_int = 1;
			}
		}
		catch ( e:Dynamic ) 
		{
			//var except_stack = CallStack.callStack();

			warning( "\nMATH ERROR: Exception in  runMath2Data(): Integer part " + Std.string( e ) + "\n");

			//var calls_str = CallStack.toString( except_stack );

			//warning( Std.string( calls_str ) );


		};

			if ( use_bool )
			{
				result_int = 0;
				if ( true == bool_ret )
					result_int = 1;
					
				// Bool is stored as Int data but marked as Bool
				if ( after_expression )
					dStack.push( new DataItem( NL_BOOL, "", 0, result_int ) ); // new NEWEST Data
				else
					dStack.unshift( new DataItem( NL_BOOL, "", 0, result_int ) ); // new OLDEST Data
			}
			else
			{
				if ( after_expression )
					dStack.push( new DataItem( NL_INT, "", 0, result_int ) ); // new NEWEST Data
				else
					dStack.unshift( new DataItem( NL_INT, "", 0, result_int ) ); // new OLDEST Data
			}
			result = result_int;
		}
		else
		{
			comment( "Float part" );
		try
		{
			switch ( op_to_do )
			{
				case OP_IS_PLUS:
					result = math_1_float + math_2_float;
				case OP_IS_MINUS:
					result = math_1_float - math_2_float;
				case OP_IS_MULTIPLY:
					result = math_1_float * math_2_float;
				case OP_IS_DIVIDE:
					if ( 0.0 == math_2_float )
					{
						error( "ERROR: Divide by 0 not allowed. Stopping. \n" );
						run_text_line++;
						return RET_IS_USER_ERROR_DATA;
					}
					else
						result = math_1_float / math_2_float;
				case OP_IS_MODULO:
					result = math_1_float % math_2_float;
				case OP_IS_MIN:
					result = Math.min( math_1_float, math_2_float );
				case OP_IS_MAX:
					result = Math.max( math_1_float, math_2_float );
				case OP_IS_ATAN2:
					result = Math.atan2( math_1_float, math_2_float );
				case OP_IS_POW:
					result = Math.pow( math_1_float, math_2_float );
					
			// Comparison				(these result in a Bool)
				case OP_IS_EQUAL:
					bool_ret = ( math_1_float == math_2_float );
					use_bool = true;
				
				case OP_IS_NOT_EQUAL:
					bool_ret = ( math_1_float != math_2_float );
					use_bool = true;
					
				case OP_IS_LESS_THAN:
					bool_ret = ( math_1_float < math_2_float );
					use_bool = true;
				
				case OP_IS_LESS_OR_EQUAL:
					bool_ret = ( math_1_float <= math_2_float );
					use_bool = true;
					
				case OP_IS_GREATER_THAN:
					bool_ret = ( math_1_float > math_2_float );
					use_bool = true;
					
				case OP_IS_GREATER_OR_EQUAL:
					bool_ret = ( math_1_float >= math_2_float );
					use_bool = true;
	
				default:
					// Somebody added another Operator perhaps?
					result = 1.2;
			}
		}
		catch ( e:Dynamic ) 
		{
			//var except_stack = CallStack.callStack();

			warning( "\nMATH ERROR: Exception in  runMath2Data(): Float part " + Std.string( e ) + "\n");

			//var calls_str = CallStack.toString( except_stack );

			//warning( Std.string( calls_str ) );


		};	
			
			if ( use_bool )
			{
				result_int = 0;
				if ( true == bool_ret )
					result_int = 1;
					
				// Bool is stored as Int data but marked as Bool
				if ( after_expression )
					dStack.push( new DataItem( NL_BOOL, "", 0, result_int ) ); // new NEWEST Data
				else
					dStack.unshift( new DataItem( NL_BOOL, "", 0, result_int ) ); // new OLDEST Data
			}
			else
			{
				// TODO  low priority: See if result was really an Integer
				if ( after_expression )
					dStack.push( new DataItem( NL_FLOAT, "", result, 0 ) ); // new NEWEST Data
				else
					dStack.unshift( new DataItem( NL_FLOAT, "", result, 0 ) ); // new OLDEST Data
			}
		}

		if ( show_details )
		{
			var result_str = Std.string( result );
			if ( use_bool )
			{
				if ( 1 == result )
					result_str = "True";
				else
					result_str = "False";
			}
			
			var msg_str = " ";
			if ( 0 < data1_name.length )
				msg_str += "(" + data1_name + ") ";
			msg_str += data1_str;

			msg_str += "  " + opMeanAsStr( op_to_do ) + "  ";
			if ( 0 < data2_name.length )
				msg_str += "(" + data2_name + ") ";
			msg_str += data2_str;

			msg( msg_str + "  is  " + result_str + "\n" );
			run_text_line++;
		}
		
	/*
		if ( export_as_code )
		{
			comment( "", "Use Noun Name(s) if available for Exported Code log", "" );
			var exp_str = data1_str;
			if ( 0 < data1_name.length )
				exp_str = data1_name;

			var exp_str2 = data2_str;
			if ( 0 < data2_name.length )
				exp_str2 = data2_name;

			export_as_code_log.push( exp_str + " " + opMeanAsStr( op_to_do, true ) + " " + exp_str2 );
		}
	*/
			
		if ( show_stacks )
		{
			#if cs
			{
				run_text_line += dataStackOut( dStack );
			}
			#else
				viewDataOpNouns( rStack, dStack, oStack, nStack, dataOpNoun_text_line );
			#end
		}
			
		return RET_IS_OK;
	}
	

// 		Run 1 or more Operators.
//
	private function runOperators( rStack : Array<NLToken>, dStack : Array<DataItem>, 
									oStack : Array<Int>, nStack : Array<Int>,
									? after_expression = false,
									? punctuation_hit = false ) : ReturnMeanings
	{
		comment( "Run 1 or more Operators",
		"	Pre Conditions  before Running any Operator:",
"		There is at least 1 Operator available to run.",
"		At least 1 Data item available for all except Assignment",
"		At least 2 Data items for Math Operators  +  -  *  /  %",
"			and String Operators  +  concat  concatenate",
"",
"      Optimization Possible:",
"          Pre Conditions are checked and satisfied BEFORE calling here.",
"          Because there may be multiple Operators to do, ",
"          checking for just Pre Condition of first Operator is likely not much help.",
"",
"	Invariants:",
"			Operator Order",
"		Operators stay in order of declaration for ordinary Natural Language reading",
"		Operators stay in innermost to outermost order for Math reading.",
"          Math reading Operator order is enforced by use of Grouping symbols ( )",
"		Overall order of Operators is determined by results of Parsing and runtime looping.",
"",
"			Operator Selection",
"		OLDEST Operators (within the current Group or Stack Frame) are Run first.",
"			Running OLDEST first supports Invariant of Operator Order.  BUT ...",
"      Expressions using ( ) after a Operator enables INFERENCE that a Procedural style was used.",
"          After the end ) is hit, this is called with  after_expression  as true.",
"              The NEWEST and not OLDEST Operator and Data are then run.",
"          Think of cos(x).  x  Data value is pushed as Newest Data ",
"              and then cos is run that uses the just pushed x Data value.",
"",
"			Blocking until Data item(s) are available",
"		If there is not enough Data for an Operator to start then it is blocked.",
"			When an Operator is blocked all other remaining Operators are blocked.",
"				Blocking remaining Operators supports Invariant of Operator Order.",
"",
"			Data item(s) and Operator Use",
"		Operators act like Verbs towards the Data stack.",
"			OLDEST Data item(s) are used.",
"			When an Operator uses a Data item the Data is considered to be consumed.",
"				Consumed Data item(s) are always removed from the Data stack.",
"			If an Operator produces a Result then the Result is saved as OLDEST in Data stack.",
"          A Successful Operator is removed from the OLDEST of the Operator stack.",
"",
"	Post Conditions",
"    Successful:",
"		Result(s) are on the Data stack as OLDEST data.",
"		OLDEST Operator(s) that are Successful were removed from Operator stack.",
"",
"      IF After an Expression is true: (happens only first time through the loop)",
"          1 Result is on the Data stack as NEWEST data.",
"          1 NEWEST Operator and 1 or 2 NEWEST Data are removed.",
"          Then other successful result(s) as above.",
"",   
"    Not Successful:",
"      return value is Not Zero.",
"          Negative return values are Severe Errors.",
"          Positive return values are typically Info about not enough Data available."
);
		var ret_val = RET_IS_OK;
		
		var original_opStack_length = oStack.length;
		var assign_opStack_length = -1;
		
		while ( 0 < oStack.length )
		{
			// Quietly check for enough Data and other Pre Conditions for an Operator
			
			// Use OLDEST op, NOT NEWEST, No change to Operator stack here
			var opIdx = oStack[ 0 ];
			
			if ( after_expression )
				opIdx = oStack[ oStack.length - 1 ];	// NEWEST IF After end of an Expression
			
			var op_to_do = rStack[ opIdx ].token_op_means;
			
			if ( ( OP_IS_ASSIGNMENT  == op_to_do )
			//  || ( OP_IS_ASSIGN_TO   == op_to_do )
			  || ( OP_IS_ASSIGN_FROM == op_to_do ) )
			{
				// Need to handle Prefix, Infix and Postfix notations.
				// Prefix is already handled by the forGL stack based Interpreter:
				//     other Operators, Nouns, Verbs happen before the Assignment.
				// Infix is handled by how ( ) and [ ] and { }
				//     does Grouping of wanted Operators, Nouns and Verbs.
				// Postfix is backwards from how the mostly Prefix Interpreter runs.
				//     Assignment needs to allow other Operators to run first.
				//
				if ( ( 1 < oStack.length ) 
				  && ( oStack[ 0 ] == opIdx ) )
				{
					// Assignment is the OLDEST Operator.
					// There are other NEWER Operators that FOLLOW the Assignment. 
					// This is Postfix notation for Assignment.
					//
					// To keep from having an endless loop see if been here before.
					if ( assign_opStack_length < 0 )
					{
						// Not used. OK to try to run other Operators
						assign_opStack_length = oStack.length;
						after_expression = true;
						continue;
					}
					else
					{
						// Have tried to run other Operators.
						// If number of Operators is lower then they ran OK and can try to run another Operator.
						// If not fall through and allow default behavior.
						if ( oStack.length < assign_opStack_length )
						{
							assign_opStack_length = oStack.length;
							after_expression = true;
							continue;
						}
					}
				}
				
				if ( ! punctuation_hit )
				{
					// Assignment ONLY happens when Punctuation is hit.
					return RET_IS_NEEDS_PUNCTUATION;
				}
				
				if ( 0 < nStack.length )
				{
					if ( show_details )
					{
						msg( "\n  Running op:  " + opMeanAsStr( op_to_do ) + "\n" );
						run_text_line++;
						run_text_line++;
					}
			
					var assign_result = runAssignment( rStack, dStack, oStack, nStack, op_to_do, opIdx );
				
					if ( 0 != cast( assign_result, Int ) )
					{
						// This ALSO means that can't run any other Operators. 
						// MUST keep Operators in order and Assign is blocked 
						// so other Operators are blocked as well.
						return assign_result;
					}
					else
					{
						// Assign done, remove Op
						if ( after_expression )
							oStack.pop();
						else
							oStack.shift();
					}
				}
				else
					// No Noun right now
					return RET_IS_NEEDS_NOUN;
			}
			else
			{
				if ( 0 == dStack.length )
					return RET_IS_NEEDS_DATA;	// all below need 1 or more Data items
			}
			
			// Check for Operators needing 1 Data Item
			if ( ( OP_IS_ABS == op_to_do )
			  || ( OP_IS_TO_DEGREES == op_to_do )
			  || ( OP_IS_TO_RADIANS == op_to_do )
			  || ( OP_IS_SIN == op_to_do )
			  || ( OP_IS_COS == op_to_do )
			  || ( OP_IS_TAN == op_to_do )
			  || ( OP_IS_ASIN == op_to_do ) 
			  || ( OP_IS_ACOS == op_to_do ) 
			  || ( OP_IS_ATAN == op_to_do ) 
			  || ( OP_IS_EXP == op_to_do ) 
			  || ( OP_IS_LN  == op_to_do ) 
			  || ( OP_IS_LOG == op_to_do ) 
			  || ( OP_IS_SQRT == op_to_do ) 
			  || ( OP_IS_ROUND == op_to_do ) 
			  || ( OP_IS_FLOOR == op_to_do ) 
			  || ( OP_IS_CEIL == op_to_do ) )
			{
				// Go ahead and do the Math Operator
				var math_op_result = runMath1Data( rStack, dStack, oStack, nStack, after_expression );
			
				if ( 0 != cast( math_op_result, Int ) )
					return math_op_result;
				
				steps_done++;
				steps_done_Verb++;
			}
			else
			// Check for Operators needing 2 Data Items
			if ( ( OP_IS_PLUS == op_to_do )
			  || ( OP_IS_MINUS == op_to_do )
			  || ( OP_IS_MULTIPLY == op_to_do )
			  || ( OP_IS_DIVIDE == op_to_do )
			  || ( OP_IS_MODULO == op_to_do ) 
			  || ( OP_IS_MIN == op_to_do ) 
			  || ( OP_IS_MAX == op_to_do ) 
			  || ( OP_IS_ATAN2 == op_to_do ) 
			  || ( OP_IS_POW == op_to_do ) 
			  || ( OP_IS_EQUAL == op_to_do ) 
			  || ( OP_IS_NOT_EQUAL == op_to_do ) 
			  || ( OP_IS_LESS_THAN == op_to_do ) 
			  || ( OP_IS_LESS_OR_EQUAL == op_to_do ) 
			  || ( OP_IS_GREATER_THAN == op_to_do ) 
			  || ( OP_IS_GREATER_OR_EQUAL == op_to_do ) 
			  || ( OP_IS_CONCAT == op_to_do ) 
			  || ( OP_IS_UNCONCAT == op_to_do ) )
			{
				if ( 2 <= dStack.length )
				{
					// Go ahead and do the Math Operator
					var math_op_result = runMath2Data( rStack, dStack, oStack, nStack, after_expression );
				
					if ( 0 != cast( math_op_result, Int ) )
						return math_op_result;
					
					steps_done++;
					steps_done_Verb++;
				
					after_expression = false;
					continue;
				}
				else
					// Not enough Data right now
					return RET_IS_NEEDS_DATA;
			}
			
			if ( show_stacks )
			{
				viewDataOpNouns( rStack, dStack, oStack, nStack, dataOpNoun_text_line, true );
			}

			after_expression = false;

		}		//		END		While  there are Operators to do

		return ret_val;
	}

	
	public function procCall( rStack : Array<NLToken>, dStack : Array<DataItem>,
									oStack : Array<Int>, nStack : Array<Int> )
	{
		
		
		
		
		
		
	}

	
	
	
//////////////////////////////////////////////////////////////////////////////
//
//
// 			Runtime level of forGL
//
//
	public var start_session_time = 0.0;
	public var total_intp_time    = 0.0;
	
	// public var verb_to_run = "5 into A. 7 into b. a * b show.";  // DEFECT  Endless loop
	public var verb_to_run = "15 test_factorial";
//        REVERSED     def_test = ".Show 2 * w .w from 21";  
//   ALT  REVERSED     def_test = ". Show 2 * w . w = 21";   // notice into is now =


//////////////////////////////////////////////////////////////////////////////
//
//			Setup to Run 4GL script(s)
//
//////////////////////////////////////////////////////////////////////////////
	public function run( ) : Int
	{
		comment( "", "//////////////////////////////////////////////////////////////////////////////", 
		"", "Setup to Run forGL script(s)",
		"", "//////////////////////////////////////////////////////////////////////////////", "");
		var ret_val = 0;
//
//			Protect with  try  block
try {	
		// Start of this call to Run stuff
		start_session_time = Date.now().getTime();
		

		total_intp_time = 0.0;
		
		// var test_def = "blat = 1024. blat * .25 . show     3   repeat";
		// var test_def = "blat equals 32. blat times 0x12. show   1000   REPEAT";
		// var test_def = "a = 2, b = 3, c = 5. a + b * c show";
		// var test_def = "2 3 5 + * show";
		// var test_def = "+*2 3 5 show";
		// var test_def = "+ 2 * 3 5 show";
		// var test_def = "bb = ( 3 * 4 - 6 + 2 ) . bb show";
		// var test_def = "blat = 10 blat show";
		// var test_def = "45 radians=x. sin(x)/cos(x) show";
		// var test_def = "sin(pi/4)/cos(pi/4)show";
		// var test_def = "x=45 radians sin/cos(45 radians). x show";
		
		// THIS CAUSED ENDLESS LOOP OF INTERPRETER ! ! !  See Backup  March 10 2018 and Defects dir
		//     Messages just before ENDLESS LOOP:
		// Syntax WARNING:  x used without a value.  GUESSING: x = 1.20335930466722 .
		// 
		//var test_def = "x=45 raidans sin/cos(45 radians)x show"; // No Punctuation. raidans Spelling Error.
		
		//var test_def = "2 into x. while( x <= 3 ){x + 1 into x.} x show.";
		//var test_def = "1 into x. if (false){x from 2}else{x from 3}x show";
		//var test_def = "1 into x. if(true){x from 2}else{x from 3}x show";
		
		// var test_def = "45 = x . 67 = y . x = y . x show";
		
		
		// var test_def = "3 into L. 1 into I. while(I<=L){I factorial. " " + show. I+1 into I}";
		// Parse Defect: Missing tokens after " ". Causes endless loop because I never gets incremented.
		// 3 =: L . 1 =: I. while( I <= L ) { I factorial. " " I }
		
		// var test_def = "4 into L. 1 into I. while(I<=L){I factorial. \" \" + show. I+1 into I}";
		// var test_def = "x := 4 ; y := 7 ; z := x * y ; z show";
		// var test_def = "3=L. 1.0=p. 1=i. while(i<=L){ p*i=p. i+1=i.} p.";
		// var test_def = "3=L. 1.0=p. i=1. while(i<=L){p*i=p. i=i+1}p";
		// var test_def = "3=L. 1.0=p. i=1. while(i<=L){p*i=p.i+1=i}p";
		var test_def = "5 show. show( 7 )";
		
		//var test_def = verb_to_run;

		// run_text_line = textLine;	// set before call to here
		
// This is the top left Home position for Run TEXT display
		var verb_display_line = run_text_line;
		
		// Because C# has NO Cursor positioning, do NOT show Stacks
		#if cs
			show_stacks = false;
		#end
		
		var words_saved = 0;

		var run_result = RET_IS_OK;
		
		while ( 0 <= cast( run_result, Int ) )
		{
			elapsed_intp_time = 0.0;
			
			if ( 0 != user_def.length8() )
				test_def = user_def;
			
			run_result = runDef( test_def, verb_display_line );
			
			total_intp_time += elapsed_intp_time;
			
			if ( 0 > cast( run_result, Int ) )		// Negative values mean Errors
				break;
			
//
//		Hit a Key to run again or  S to Save Verb or  F to Finish ?
//
		#if ( sys )

			// Could be running only using internal Dictionary and NO Dictionary file.
			if ( 0 == in_dictionary_file_name.length )
			{
				msg( "\n    Hit a Key to run again or  F to Finish ? " );
			}
			else
			{
				msg( "\n    Hit a Key to run again or  S to Save Verb or  F to Finish ? " );
			}
				run_text_line++;
				run_text_line++;

				var ans : String = stdin.readLine();
				
				var action = "";
				if ( 0 < ans.length )
					action = ans.charAt( 0 ).toUpperCase();

				if ( "F" == action )	// Finish ?
					break;
			
			if ( 0 < in_dictionary_file_name.length )
			{
				if ( "S" == action )
				{
					msg( "\rSave Verb as what Name (no name means not Saving) ?\n" );
					run_text_line++;

					var name : String8 = "";
					var done = false;
					
					while ( ! done )
					{
						ans = stdin.readLine();
						
						if ( 0 == ans.length )	// No name given means Not Saving
							break;

						var name_internal = Strings.toLowerCase8( ans );

						// See if already in Dictionary
						var dict_idx = nlDict.findWord( ans );
						if ( 0 <= dict_idx )
						{
							msg( "\r   That word is in the Dictionary. Please use another name.\n" );
							msg( "\r" );
							eraseToLineEnd( 0 );
							continue;
						}
	//			
	//  TODO: See if Name for Verb is a valid Verb name
	//			
							
						// Save
						var add_result = nlDict.addWord( ans, NL_VERB, name_internal, OP_IS_UNKNOWN, user_def );
						if ( 0 == cast( add_result, Int ) )
						{
							words_saved++;
							break;
						}
						else
						{
							// INTERNAL ERROR:  Adding a Verb to the in memory Dictionary !
							break;
						}
					}
				}
			}

		#end
		}
		
		var show_times = true;
		
	#if ( ! sys )
		if ( 0 <= cast( run_result, Int ) )
			show_times = false;
	#end
		
		if ( show_times ) 
		{
			var end_session_time = Date.now().getTime();
			
			var total_session_time = ( end_session_time - start_session_time ) / 1000.0;
			var elapsed_session : Int = Math.floor( total_session_time * 1000.0 );
			total_session_time = elapsed_session / 1000.0;
			
			msg( "\n  ... Elapsed total Run Time " + Std.string( total_intp_time ) + " Seconds" );
			msg( "\n  Elapsed total session Time " + Std.string( total_session_time ) + " Seconds\n" );
		}
		
		ret_val = cast( run_result, Int );

		
		var errors = ForGLData.getDataErrors();
		if ( 0 < errors.length )
		{
			msg( "\n\t\t" + Std.string( errors.length ) + "  Data  handling  ERRORS\n" );
		
			var i = 0;
			while ( i < errors.length )
			{
				msg( errors[ i ] );
				i++;
			}
		}

		var warnings = ForGLData.getDataWarnings();
		if ( 0 < warnings.length )
		{
			msg( "\t\t" + Std.string( warnings.length ) + "  Data  handling  Warnings\n" );
			
			var i = 0;
			while ( i < warnings.length )
			{
				msg( warnings[ i ] );
				i++;
			}
		}
		
		msg( "\t\tImport   handling  Messages\n" );
		msg( nl_Import.importWords_msgs );
		
	#if  sys
		if ( 0 < words_saved )
		{
			msg( "Save your changes as a new file (y/n) ? ", RED );
			if ( enterYes( ) )
			{
				// Saving
				msg( "\r" );
				eraseToLineEnd( 0 );

				// Use Import .toml file as template if available. TODO  make more flexible
				var export = new NLExport();
				
				var export_result = export.exportWords( nlDict, in_dictionary_file_name, ForGLData );
				
				msg( "\t\tExport  handling  Messages\n" );
				msg( export.exportWords_msgs );
				
				if ( 0 != cast( export_result, Int ) )
				{
					msg( "Problem with Saving your Dictionary. Please check messages and .toml file\n" );
				}
			}
		}
	#end
	
		if ( 0 < export_as_code_log.length )
		{
			comment( "Display the Export info", "" );
			
			msg( "\n" );
			eraseToLineEnd( 0 );
			msg("#    Export as Code Log\n" );
			
			var i = 0;
			while ( i < export_as_code_log.length )
			{
				msg( export_as_code_log[ i ], GREEN, true );
				i++;
			}
			
			msg( "\n" );
			

		#if sys

			comment( "", "Create & Write out Export file", "" );

			var expAs = new NLExportAs();
			
			var expRet = expAs.init( export_as_code_log );
			
			
			
			
		#else
		
			warning( "Please copy/paste the Export info to a file now.", GREEN );
			
		#end
		}
	} 
	catch ( e:Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in run(): " + Std.string( e ) + " \n"); 

		ret_val = cast( RET_IS_INTERNAL_ERROR, Int );
	};
	
		return ret_val;
	}
		

//////////////////////////////////////////////////////////////////////////////
//
//			Run a single forGL script (Verb definition)
//
//////////////////////////////////////////////////////////////////////////////
	private var runStack  : Array<NLToken>;
	
	private var dataStack : Array<DataItem>;
	private var opStack   : Array<Int>;
	private var nouns     : Array<Int>;
	
	private var assignStack : Array<Int>;
	
	private var repeat_found = false;
	private var repeat_count = 0;
	private var repeat_limit = -1;
	private var repeat_limit_found = false;
	private var show_text_line = 0;
	
	var start_intp_time = 0.0;

	public function runDef( def_to_run : String8, textLine : Int ) : ReturnMeanings
	{
		comment( "Run a single forGL script (Verb definition)" );
		var ret_val = RET_IS_OK;
//
//			Protect with  try  block
try {
		run_text_line = textLine;
		
	#if ( ! cs && !js )
		goToPos( run_text_line, 0 );
		eraseToDispEnd();
	#end
	
	#if ( sys )
		
	//	var char_code_ignored = Sys.getChar( false );
	//	char_code_ignored = 0;
	
		msg( "\rExport test Verb to other programming languages (y/n) ?  " );
		export_as_code = enterYes( );

		run_text_line++;
		msg( "\r" );
		eraseToLineEnd( 0 );
		
		if ( !export_as_code )
		{
			msg( "\rShow internal Names when running (y/n) ?  " );
			display_internal = enterYes( );

			run_text_line++;
			msg( "\r" );
			eraseToLineEnd( 0 );
		}
		else
			display_internal = true;

		msg( "\rShow details of various information (y/n) ?  " );
		show_details = enterYes( );

		run_text_line++;
		msg( "\r" );
		eraseToLineEnd( 0 );

		msg( "\rShow details of Words used (y/n) ?  " );
		show_words_table = enterYes( );

		run_text_line++;
		msg( "\r" );
		eraseToLineEnd( 0 );
		
		show_stacks = true;
		show_stacks_Data_Only = false;
		single_step = true;
		
		msg( "\rShow Stacks: N = none & no Steps  OR  D is only Data  OR  any Key for all ? " );
		{
			var ans = stdin.readLine();
			if ( 0 < ans.length )
			{
				var char = ans.charAt( 0 );
				
				if ( ( "N" == char )
				  || ( "n" == char ) )
				{
					eraseToLineEnd( 0 );
					msg( "\rNo stepping; will Run full speed and not show stacks.\n" );
					run_text_line++;
					show_stacks = false;
					single_step = false;
					delay_seconds_default = 0;
					delay_seconds = delay_seconds_default;
					view_DON_throttle = true;
				}
				else
				{
					if ( ( "D" == char )	// Data stack only ?
					  || ( "d" == char ) )
					{
						eraseToLineEnd( 0 );
						msg( "\rManual stepping and only Data stack will show.\n" );
						run_text_line++;
						show_stacks = true;
						show_stacks_Data_Only = true;
						single_step = true;
					}
					else
					{
						eraseToLineEnd( 0 );
						msg( "\rManual stepping and all stacks will show.\n" );
						run_text_line++;
						show_stacks = true;
						single_step = true;
					}
				}
			}
		}
		
		run_text_line++;
		msg( "\r" );
		eraseToLineEnd( 0 );
		
		if ( show_stacks )
		{
			single_step = true;
			
			msg( "\rDelay: your # (times .1 seconds)  OR  any Key for Manual ? " );

			var ans = stdin.readLine();
			if ( 0 < ans.length )
			{
				var delay_wanted = Std.parseFloat( ans );
				
				if ( ! Math.isNaN( delay_wanted ) )
				{
					if ( delay_wanted < 0 )
						delay_wanted = 0;

					delay_seconds_default = delay_wanted / 10.0;
					delay_seconds = delay_seconds_default;
					eraseToLineEnd( 0 );
					msg( "\rAutomatic stepping with  " + delay_seconds + "  seconds delay.\n" );
					run_text_line++;
					show_stacks = true;
					single_step = false;
				}
				else
				{
					eraseToLineEnd( 0 );
					msg( "\rManual stepping. Hit a key to do next step.\n" );
					run_text_line++;
					show_stacks = true;
					single_step = true;
				}
			}
			//  else  is already set up above
			
		}
	/*
		msg( "Hit the Space bar to continue. " );
		while ( true )
		{
			var char_code = Sys.getChar( false );	// No ECHO of character to display
			
			if ( 0x20 == char_code )
				break;
		}
	*/
	#end

		run_text_line += nlDict.showDictionaryWords( false /*, use_OEM */ );

		setOut( VERB_TOK_OUT );
		
	#if js
		msg( def_to_run, GREEN );
	#else
		msg( "    Test_Verb is:\n" + def_to_run, GREEN, true );	// extra CR
		run_text_line++;
		run_text_line++;
		
	#end
	
		setOut( WRITE_PREVIOUS );
		
		var user_Verb :String8 = "";


// JavaScript uses a HTML text control for the User to enter Verb definition to run
//
	#if  sys
		user_Verb = enterYourVerb();	// Edit a Verb to run using a simple text mode Editor 
		run_text_line++;
		run_text_line++;
		
		if ( 0 != cast( ForGL_ui.enterYourVerb_return, Int ) )
			return ForGL_ui.enterYourVerb_return;
	#end

		if ( ( "test_verb" == Strings.toLowerCase8( user_Verb ) )
		  || ( "testverb"  == Strings.toLowerCase8( user_Verb ) ) )
			user_Verb = def_to_run;

		user_def = user_Verb;

		if ( export_as_code )
		{
			#if sys
				msg( "\r    Please enter the export Name for this Verb ? " );
				export_as_code_verb_name = stdin.readLine();
				
				comment( "TODO: Check that the Verb Name is OK" );
				run_text_line++;
			#end
			
			export_as_code_log  = new Array<String8>();
			export_as_code_log.push( "# Original Verb  " + export_as_code_verb_name );
			export_as_code_log.push( user_def );
		}
		
		// Parse given User Verb
		// Produce internal representation for later use
		
		// TODO Maybe: Reverse order of each token in test_def
		// Simulates a language like Hebrew or Arabic ?
		//
		// Do MATH tokens get reversed ? No, see wikipedia: Mathematics as a Language
		// Produce internal representation of reversed for later use

		
		repeat_found = false;
		repeat_count = 0;
		repeat_limit = -1;
		repeat_limit_found = false;


		var tokens : Array<String8> = nl_Parse.parse( user_Verb, PARSE_LEFT_TO_RIGHT );
		run_text_line += nl_Parse.parse_text_lines_added;
		
	//	if ( show_details )
	//		msg( "There are " + Std.string( tokens.length ) + " tokens found to resolve\n" );
		
	
		// Check for Syntax Errors or Warnings from Parser
		
		// Recover from Errors / Warnings
		


//
//	 Resolve the Meanings of the Tokens
//
		// Set up to save details of each token in a linear array.
		// Linear array is good to follow the Natural Language reading order.
		runStack  = new Array<NLToken>();

		run_text_line += nl_Parse.resolveTokens( tokens, nlDict, runStack, run_verbose );

		repeat_found = nl_Parse.repeat_verb_found;

		if ( nl_Parse.left_groups != nl_Parse.right_groups )
		{
error( "\nSYNTAX ERROR: count of " + Std.string( nl_Parse.left_groups ) + " Left and " + Std.string( nl_Parse.right_groups ) + " Right group symbols ( ) [ ] { } not equal.\n" );
			run_text_line++;
			run_text_line++;
		}
		
		nl_Parse.resolveAssigns( runStack );

		var choice_result = RET_IS_INTERNAL_ERROR;
		if ( export_as_code )
		{
			var export_runStack = nl_Parse.refactorForExport( runStack );
			choice_result = nl_Parse.resolveChoice( export_runStack );
			runStack = export_runStack;
		}
		else
			choice_result = nl_Parse.resolveChoice( runStack );

		if ( 0 > cast( choice_result, Int ) )
			return choice_result;

		if ( ( show_words_table || export_as_code ) && ( 0 < runStack.length ) )
			run_text_line += nl_Parse.showWordsTable( runStack, show_words_table, false, export_as_code );


		comment( "", "Feedback the results of Type resolution by Colored text.",
		"Colors for different word/symbol types", "" );

		setOut( VERB_TOK_OUT );
		var colored_text_line = run_text_line;	// Home position for Start of Colored text
		var colored_text_no_color = "";
		
		var color = ForGL_ui.DEFAULT_COLOR;
		var i = 0;
		while ( i < runStack.length )
		{
			var str = "";
			if ( display_internal )
				str = runStack[i].internal_token;
			else
				str = runStack[i].visible_token;
			
			var no_color_str = runStack[i].internal_token;

			// C#  so far  does Not do Colored text
			#if cs
				msg( str + " " );
			#else
				color = getTypeColor( runStack[i].token_type );
				msg( str + " ", color );
			#end
			
			colored_text_no_color += no_color_str + " ";
			
			i++;
		}
		
		setOut( WRITE_PREVIOUS );
		
		if ( export_as_code )
		{
			export_as_code_log.push( "# forGL Verb after changes for Export as Code  " + export_as_code_verb_name );
			export_as_code_log.push( colored_text_no_color );
			export_as_code_log.push( "# forGL Verb exact Syntax table  " + export_as_code_verb_name );
			export_as_code_log.push( nl_Parse.words_table_text );
		}
		
	#if 	!js
		msg( "\n" );
		run_text_line++;
	#end
	
	// This needs text Cursor positioning
	#if !cs
		var repeat_text_line = run_text_line;
		if ( repeat_found )
		{
			//eraseToLineEnd( 1 );
			//viewRepeatCount( repeat_count, repeat_text_line );
			
			// Reserve a line for Repeat Count output
			msg( "\n" );
			run_text_line++;
		}
		
		// Reserve a line for Show output
		show_text_line = run_text_line;
		prev_show1_data = "";
		// show1Data( "", show_text_line );
		msg( "\n\n" );
		run_text_line++;
		run_text_line++;
	#end
		
	// Do a pass through the Tokens and apply identified actions
	//
	// Actions include Data Stack push/pop, Operator Stack push/pop, Noun Stack push/pop
	//
//			Haxe Data Structures NOTE:
//
//		Tried using the Generic Stack...
//			But sometimes need to see how many Data items are on the Stack.
//			Haxe Array Data Structure works fine and provides Push/Pop style as well.
//
		// Data Stack
		// original Data sources are: 
		//     simple constants: numbers (float or int) or bool and strings
		//     Nouns with an already set value (float or int or bool or string)
		// Data gets "pushed" by copying from original data or by newly created data (from Math Operators, ...)
		// Data gets "popped" by using the Data as needed. Assignment, Math, Show, ...
		// Math operators typically pop needed value(s) and then push the result
		dataStack = new Array<DataItem>();
		
		// Allow multiple levels of embedded groups 
		// such as: x = ( some expressing to evaluate ( an inner expression ) more eval ).
		//
//		var data_stack_fence = new Array<Int>();
		//old_dataStackFrames.push( 0 );				// default prior Frame is empty
		
		// Pending Operators to do have simple integer indexes back to run stack
		opStack = new Array<Int>();
		
//
//				SPECIAL CASE: Assignment Operator
//
		assignStack = new Array<Int>();
		

		// Allow multiple levels of embedded groups.  See above
//		var op_stack_fence = new Array<Int>();
		//old_opStackFrames.push( 0 );				// default prior Frame is empty

		
		// Nouns found. Searched for already existing before adding any.
		// Local Nouns live here after Unknown NL type is set (TYPE INFERENCE) to Local Noun
		// Expect the Noun stack to NOT be popped until a full definition is exited
		//
		// 		When a VERB is called from a higher level Verb:
		// Nouns that are NOT Local are to be sent back to Dictionary (or Data File) as needed.
		// Then the setup and run for the called Verb is done.
		//
		// Nouns have simple integer indexes back to run stack

		nouns = new Array<Int>();

		// Save where to put the display for Data , Operator, Noun Stacks
		dataOpNoun_text_line = run_text_line;

		// This needs text Cursor positioning
	#if !cs
		if ( show_stacks )
		{
			viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line, true );
			
		#if !js
			msg( "\n\n\n" );
			run_text_line += 3;
		#end
		}
	
		if ( repeat_found )
		{
			// Reserve a line to show Repeat Limit and Count
			var repeat_text_line = run_text_line;
		#if !js
			msg( "\n" );
			run_text_line++;
		#end
		}
	#end


// Start timing the Interpreter run
		start_intp_time = Date.now().getTime();
		
		last_view_DON_time = start_intp_time;

		// Use an Instruction Pointer analogy (really Run stack Array index)
		intp_ip = 0;
		
		steps_done = 0;
		steps_done_Verb = 0;
		intp_return_result = RET_IS_OK;
		
#if js

/*
		Browser.window.setTimeout( "doNothing", 200 );
		
		// Use the Browser to run the Interpreter
		// Browser.window.setTimeout( "runInterpreter", 6 );	// THIS DOES NOT SEEM TO WORK
		// Browser.window.requestAnimationFrame( runInterpreter );
		scheduledAnimationFrame = false;
		Browser.window.requestAnimationFrame( runALittle );
*/

#else
		var intp_done = false;
		
		while ( !intp_done )
		{

			runInterpreter();
			
			if ( intp_ip >= runStack.length )
				break;
				
			if ( 0 != cast ( intp_return_result, Int ) )
				break;
		}
		
		ret_val = runDef_End();
#end

	} 
	catch ( e : Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in runDef(): " + Std.string( e ) + " \n");

		ret_val = RET_IS_INTERNAL_ERROR;
	};

		return ret_val;
	}


//
//		Do some checks, messages, and clean up after a Verb and Verbs it uses is Run
//
	public function runDef_End( ) : ReturnMeanings
	{
		comment( "", "Do some checks, messages, and clean up after a Verb and Verbs it uses is Run", "" );
		var ret_val = intp_return_result;
		
		msg( "\n   Finished. No more Natural Language words to process.\n" );
		run_text_line++;
		run_text_line++;
		
		// Show the Data, Nouns and Ops Stacks
		show_stacks_Data_Only = false;
		#if ( cs || js )
			run_text_line++;
			viewDataOpNouns( runStack, dataStack, opStack, nouns, run_text_line, true );
			msg( "\n\n\n" );
			run_text_line += 3;
		#else
			if ( show_stacks )
				viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line, true );
			else
			{
				run_text_line++;
				viewDataOpNouns( runStack, dataStack, opStack, nouns, run_text_line, true );
				msg( "\n\n\n" );
				run_text_line += 3;
			}
			goToPos( run_text_line, 0 );
		#end
		
		if ( dataStack.length > 0 )
		{
			var data_count = dataStack.length;
			if ( data_count > 1 )
			{
				var message = "There are " + Std.string( data_count ) + " Data items.\n";
				message += "You can use the Show built in Verb to take 1 item off the stack and Show it.\n";
				message += "You can use the View built in Verb to View all the stacks with no changes.\n";
				msg( message );
				run_text_line++;
				run_text_line++;
				run_text_line++;
			}
			
		/* Not needed.  All 3 stacks are shown above
			msg( "Final Data =  " );
			var dataIdx = data_count - 1;
			if ( NL_INT == dataStack[dataIdx].data_type )
				msg( Std.string( dataStack[dataIdx].data_int ) + "\n", DATA_COLOR );
			else
			if ( NL_FLOAT == dataStack[dataIdx].data_type )
				msg( Std.string( dataStack[dataIdx].data_float ) + "\n", DATA_COLOR );
			else
			if ( NL_STR == dataStack[dataIdx].data_type )
				msg( dataStack[dataIdx].data_str + "\n", DATA_COLOR );
			else
			{
				error( "\nINTERNAL ERROR: Data item not float, integer or string\n" );
			}
			run_text_line++;
		*/
		}
		
		if ( nouns.length > 0 )
		{
		/* Not needed.  All 3 stacks are shown above
			if ( show_details )
			{
			#if cs
				msg( "Nouns = " + nounStackToString( runStack, nouns ) + "\n" );
			#end
			}
		*/
			var nounIdx = nouns[ nouns.length - 1 ];
			if ( display_internal )
				msg( runStack[nounIdx].internal_token + " ", NOUN_COLOR );
			else
				msg( runStack[nounIdx].visible_token + " ", NOUN_COLOR );
			msg( "is " + nlTypeAsStr( runStack[nounIdx].token_noun_data ) + " " );
			switch ( runStack[nounIdx].token_noun_data )
			{
				case NL_TYPE_UNKNOWN:
					if ( NL_NOUN_LOCAL == runStack[nounIdx].token_type )
					{
						warning( "\nWARNING: Local Noun  " + runStack[nounIdx].visible_token + "  had no value. Likely not used?" );
						run_text_line++;
					}
					else
					if ( NL_NOUN == runStack[nounIdx].token_type )
					{
						error( "\nINTERNAL ERROR: Noun  " + runStack[nounIdx].visible_token + "  data is unknown." );
						run_text_line++;
					}
					
				case NL_STR:
					msg( runStack[nounIdx].token_str, DATA_COLOR );
				
				case NL_INT:
					msg( Std.string( runStack[nounIdx].token_int ), DATA_COLOR );
					
				case NL_BOOL:
					if ( 1 == runStack[nounIdx].token_int )
						msg( "true", DATA_COLOR );
					else
						msg( "false", DATA_COLOR );
						
				case NL_FLOAT:
					 msg( Std.string( runStack[nounIdx].token_float ), DATA_COLOR );
					 
				default:
					error( "\nINTERNAL ERROR: Wrong type of Noun data" );
					run_text_line++;
			}
			msg( "\n" );
			run_text_line++;
		}
		
		if ( 0 < opStack.length ) 
		{
	/* Not needed.  All 3 stacks are shown above
		#if cs
			msg( "Ops = " + opStackToString( runStack, opStack ) + "\n" );
		#end
	*/
			msg( "\n   There are " + Std.string( opStack.length ) + " Operations not done.\n" );
			msg( "This usually indicates a logical problem with the Verb (code).\n" );
			msg( "If you have gotten any ERRORS or WARNINGS those will guide you." );
		}
		
		
		// Run using reversed token stream  EXCEPT Repeat! and maybe SHOW
		 
		
		// Compare original vs reversed token streams results.
		

		

		var end_intp_time = Date.now().getTime();
		
		elapsed_intp_time = ( end_intp_time - start_intp_time ) / 1000.0;
		var elapsed : Int = Math.floor( elapsed_intp_time * 1000.0 );
		elapsed_intp_time = elapsed / 1000.0;

		msg(   "  ... Elapsed       Run time " + Std.string( elapsed_intp_time ) + " Seconds of " + Std.string( steps_done ) + " Internal and " + Std.string( steps_done_Verb ) + " Verb steps.\n" );


		return ret_val;
	}


//		Helper to be polite when running JavaScript in a Browser
//

/*
#if		js

	private var scheduledAnimationFrame = false;
	public function runALittle( timeStamp : Float ) : Void
	{
		if ( ( intp_ip < runStack.length )
		  && ( intp_return_result == RET_IS_OK ) )
		{
			runInterpreter();
			
			if ( ! scheduledAnimationFrame )
			{
				scheduledAnimationFrame = true;
				Browser.window.requestAnimationFrame( runALittle );
			}
			
			Browser.window.setTimeout( "doNothing", 5 );
		}
	}
#end
*/

//////////////////////////////////////////////////////////////////////////////
//	
//				I N T E R P R E T E R			LOOP
//
//////////////////////////////////////////////////////////////////////////////
	
	public var intp_return_result = RET_IS_OK;
	
#if		js
	public function runInterpreter()
#else
	private inline function runInterpreter()
#end
	{
		comment( "    I N T E R P R E T E R         LOOP    ", "" );
		var apply_op = false;
		
		var i = 0;
		
		var ip = intp_ip;
		
		
#if	js
		
		//var		loop_limit = 11;
		
		var		start_time = Date.now().getTime();
		
#else

	#if  sys
		
		// Set back to reasonable defaults
		// single_step = true;
		// delay_seconds = delay_seconds_default;
	
	#end

#end
		while ( ip < runStack.length )
		{
			
#if	js
		//	loop_limit--;
		//	if ( 0 >= loop_limit )
		//		break;
				
			var	time = Date.now().getTime();
			if ( time - start_time >= 0.005 )
				break;
#end
		//			Check for Breakpoint
		//
		//		USE a Bit flag somewhere in Run stack structure
		//
		// if ( breakpoint )
		// {
		//		single_step = true;
		//		clear_breakpoint_bit();
		// }

		
// Check if Single Step Debug
//     OR  if
// Delay for easier reading
//
			if ( single_step )
			{
				#if ( sys && !java )

					var char_code = Sys.getChar( false );	// No ECHO of character to display

					if ( 0x1B == char_code )	// Escape ?  Stop Single Stepping and run Automatically
					{
						single_step = false;
						char_code = Sys.getChar( false );		// Empty the character buffer (we hope?)
					}
					else
					{
					if ( ( 0x30 <= char_code )	// keyboard 0 to 9 ?  IF 0 then FULL SPEED Animation (see below)
					  && ( char_code <= 0x39 ) )
						delay_seconds = char_code - 0x30;
						
						char_code = Sys.getChar( false );		// Empty the character buffer (we hope?)
					}
					
				#else
					// Delay a bit for Java or JavaScript
					#if java
						Sys.sleep( 3 );
					#else
						// Browser.window.setTimeout( "doNothing", 1000 );
					#end
				#end
			}
			else
			if ( 0.0 < delay_seconds )
			{
		#if  sys
				Sys.sleep( delay_seconds );
		#else
				// Browser.window.setTimeout( "doNothing", 1000 * delay_seconds );
		#end
			}
			else
			{
				// NOT Single Step and NOT running with a Delay
				//
				// Therefore running full speed Animation style
				//
				// Avoid SOME of UI updating that changes in the next split second anyway.
				// So Updates for Data, Operator, and Noun stacks can happen 
				// maybe 10 times a second instead of hundreds or thousands/second
				//
				// See code in viewDataOpNouns for details
				view_DON_throttle = true;
			}
			
//	Display latest Interpreter values
//
			if ( single_step || show_stacks )
			{
				comment( "Display latest Interpreter values" );
			#if cs
				run_text_line += dataStackOut( dataStack );
			#else
				viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
			#end
			}

//
//		Choose  what to do next is done in detail later
//
			if ( NL_CHOICE == runStack[ ip ].token_type )
			{
				if ( ( "if"     == runStack[ ip ].internal_token )
				  || ( "for"    == runStack[ ip ].internal_token )
				  || ( "switch" == runStack[ ip ].internal_token )
				  || ( "while"  == runStack[ ip ].internal_token )
				  || ( "else"   == runStack[ ip ].internal_token )
				  || ( "return" == runStack[ ip ].internal_token ) )
				{
					
					// Internal values already set in resolveChoice
					steps_done++;
					ip++;
					continue;
				}
			}

//	
// 		DATA
//
			if ( ( NL_INT    == runStack[ ip ].token_type )
			  || ( NL_BOOL   == runStack[ ip ].token_type )
			  || ( NL_FLOAT  == runStack[ ip ].token_type )
			  || ( NL_STR    == runStack[ ip ].token_type )
			//  || ( nl_int32  == runStack[ ip ].token_type )
			//  || ( nl_int64  == runStack[ ip ].token_type )
			//  || ( nl_number == runStack[ ip ].token_type ) 
				)
			{
				comment( "    DATA item. Put on Data stack" );
				dataStack.push( new DataItem( runStack[ ip ].token_type, 
											  runStack[ ip ].token_str,
											  runStack[ ip ].token_float,
											  runStack[ ip ].token_int ) );
											  
				steps_done++;
				ip++;
				continue;
			}
			
//
// 		NOUNS are Named references to Data
//
			if ( ( NL_NOUN         == runStack[ ip ].token_type )
			  || ( NL_TYPE_UNKNOWN == runStack[ ip ].token_type )	//  INFERENCE
			  || ( NL_NOUN_LOCAL   == runStack[ ip ].token_type ) )
			{
				comment( "    NOUNS are Named references to Data" );
			/*      DEBUGGING for NOUN type
				if ( NL_NOUN == runStack[ ip ].token_type )
				{
					var noun_data = nlTypeAsStr( runStack[ ip ].token_noun_data ) + " " + runStack[ ip ].token_str;
					noun_data += " " + Std.string( runStack[ ip ].token_float ) + " " + Std.string( runStack[ ip ].token_int );
					
					status( noun_data, GREEN, false, true );
				}
			*/
				comment( "  Search for a Noun name (internal token) in Noun stack" );
				var name_to_find = runStack[ ip ].internal_token;
				if ( 0 == name_to_find.length8() )
				{
					error( "INTERNAL ERROR: Internal Name of Noun " + runStack[ ip ].visible_token + " is missing\n" );
					run_text_line++;
					name_to_find = runStack[ ip ].visible_token;
					runStack[ ip ].internal_token = runStack[ ip ].visible_token;
				}
				
				// INVARIANT: NO duplicate entries for SAME Noun name
				var nounsIdx = 0;
				var runIdx = 0;
				var already_known = false;
				while ( nounsIdx < nouns.length )
				{
					runIdx = nouns[ nounsIdx ];
					if ( name_to_find == runStack[ runIdx ].internal_token )
					{
						// Noun is already known
						already_known = true;
						break;
					}
					nounsIdx++;
				}
				
				var local_inference = false;
				if ( ( ! already_known )
				  && ( NL_TYPE_UNKNOWN == runStack[ ip ].token_type ) )
				{
					// INFERENCE: Unknown type Not already treated as a Local Noun
					local_inference = true;
					runStack[ ip ].token_type      = NL_NOUN_LOCAL;
					runStack[ ip ].token_noun_data = NL_TYPE_UNKNOWN;
				}
			
				if ( false == already_known )
				{
					comment( "  add NOUN or LOCAL NOUN as NEWEST" );
					nouns.push( ip );
					
					if ( NL_NOUN == runStack[ ip ].token_type )
						nl_Parse.updateNounValues( nlDict, runStack, nouns, true );	// Get current value from Dictionary
					
					nounsIdx = nouns.length - 1;
					runIdx = nouns[ nounsIdx ];
					if ( show_stacks )
					{
						#if cs
						{
							msg( "\nNouns = " + nounStackToString( runStack, nouns ) + "\n", NOUN_COLOR );
							run_text_line++;
							run_text_line++;
						}
						#else
							viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
						#end
					}
						
					// At this point we have INFERRED a LOCAL NOUN but no related DATA
					//
					// TODO?  check if DATA is available for this New LOCAL NOUN
					//    On second thought Lazy evaluation (assignment) is more likely to be correct here.
					//
					//    GUESS: Wait until an Assignment involves this LOCAL NOUN 
					//        OR when the Local Noun is referenced later see if assignment can be done.
				}
				
				if ( ! local_inference )
				{
					// Using a Noun NAME implies that the Noun DATA is referenced.
					// Make sure that the Noun stack has this just referenced Noun as NEWEST.
				
			// COMMENTED OUT !  Keep Nouns in same (reading) Order as they appear.
			//		if ( nounsIdx != nouns.length - 1 )
			//		{
			//			// Move to top of Nouns stack
			//			nouns.remove( runIdx );
			//			nouns.push( runIdx );
			//		}
					
					// Make sure the Noun has VALID Data. May need to assign to this Local Noun.
					if ( NL_TYPE_UNKNOWN == runStack[ runIdx ].token_noun_data )
					{
						if ( 0 < opStack.length )
							runOperators( runStack, dataStack, opStack, nouns );
						
						if ( NL_TYPE_UNKNOWN == runStack[ runIdx ].token_noun_data )
						{
							var name = "";
							if ( display_internal )
								name = runStack[ runIdx ].internal_token;
							else
								name = runStack[ runIdx ].visible_token;
							if ( 0 < assignStack.length )
							{
								// Assignment is available.  Warn and then try.
								// INFERENCE
								var message = "\nInfo:  ";
								message += name;
								// message += "  used with no value. ";
								// message += "Punctuation is missing so no assignment.\n";
								// message += "Please add Punctuation.\n";
								// message += "Assignment done anyway to help.\n";
								message += "  assigned\n";
								warning( message );
								run_text_line++;
								//run_text_line++;
								//run_text_line++;
								//run_text_line++;
								
								// There was an Assignment to do
								//opStack.unshift( assignStack.pop() );
								assignStack.pop();
								
								// INFERENCE  simulate punctuation so Assignment happens
								//runOperators( runStack, dataStack, opStack, nouns );
								// runOperators( runStack, dataStack, opStack, nouns, false, true );
								runAssignment( runStack, dataStack, opStack, nouns );
							}
							else
							{
								// No Assignment available.  Warn and then try it.
								// INFERENCE
								var message = "\nSyntax Problem:  " + name + "  used with no value. = (assignment) is missing.\n";
								message += "Or a Verb was spelled wrong and a loop may not end !\n";
								message += "Solution: Please fix spelling OR add = with Punctuation at end.\n";
								message += "Now trying as local Noun and assignment anyway to help.\n";
								error( message );
								run_text_line++;
								run_text_line++;
								run_text_line++;
								run_text_line++;
								run_text_line++;
								
								// INFERENCE  Try an Assignment to help out.
								runAssignment( runStack, dataStack, opStack, nouns );
							}
							
							if ( NL_TYPE_UNKNOWN == runStack[ runIdx ].token_noun_data )
							{
								if ( 0 < dataStack.length )
								{
									// Use the NEWEST Data item.  MAY BE COMPLETELY WRONG  GUESS  ? ? ? ! ! !
									//
									var dataIdx = dataStack.length - 1;
									
									var data = dataStack[ dataIdx ].data_str;
									runStack[ runIdx ].token_noun_data = dataStack[ dataIdx ].data_type;
									runStack[ runIdx ].token_str = dataStack[ dataIdx ].data_str;
									runStack[ runIdx ].token_float = dataStack[ dataIdx ].data_float;
									runStack[ runIdx ].token_int = dataStack[ dataIdx ].data_int;
									
									if ( NL_INT == dataStack[ dataIdx ].data_type )
										data = Std.string( dataStack[ dataIdx ].data_int );
									else
									if ( NL_BOOL == dataStack[ dataIdx ].data_type )
									{
										if ( 1 == dataStack[ dataIdx ].data_int )
											data = "true";
										else
											data = "false";
									}
									else
										data = Std.string( dataStack[ dataIdx ].data_float );
										
									dataStack.pop();	// STILL MAY BE COMPLETELY WRONG ! ! !
										
									warning( "\nSyntax WARNING:  " + name + " used without a value.  GUESSING: " + name + " = " + data + " .\n" );
									run_text_line++;
									run_text_line++;
								}
								else
								{
									var message = "\nSyntax ERROR:  " + name + " used without a value. Suggest " + name + " = your_data .  Stopping.\n";
									error( message, RED );
									run_text_line++;
									run_text_line++;
									intp_return_result = RET_IS_USER_ERROR_SYNTAX;
									break;
								}
							}
						}
					}
					
			/*  DEBUG  NOUN
					if ( NL_NOUN == runStack[ runIdx ].token_type )
					{
						var noun_data = nlTypeAsStr( runStack[ runIdx ].token_noun_data ) + " " + runStack[ runIdx ].token_str;
						noun_data += " " + Std.string( runStack[ runIdx ].token_float ) + " " + Std.string( runStack[ runIdx ].token_int );
						
						status( noun_data, GREEN, false, true );
					}
			*/
					
					if ( ( ip + 1 < runStack.length - 1 )
					  && ( NL_OPERATOR == runStack[ ip + 1 ].token_type )
					  && ( OP_IS_ASSIGN_FROM == runStack[ ip + 1 ].token_op_means ) )
					{
						// Do Not push Value to Data stack. 
						// This Noun or local Noun will be assigned  From  the right side soon.
					}
					else
					{
						// Put the Noun DATA on the Data stack.
						if ( NL_STR == runStack[ runIdx ].token_noun_data ) 
						{
							// String slot is in use.
							dataStack.push( new DataItem( runStack[ runIdx ].token_noun_data, 
													  runStack[ runIdx ].token_str,
													  runStack[ runIdx ].token_float,
													  runStack[ runIdx ].token_int ) );
						}
						else
						{
							// Put Noun Name in unused string slot on the Data stack to help relate numbers or Bool back to Noun
							var name = "";
							if ( display_internal )
								name = runStack[ runIdx ].internal_token;
							else
								name = runStack[ runIdx ].visible_token;
							dataStack.push( new DataItem( runStack[ runIdx ].token_noun_data, 
													  name,		// Noun Name
													  runStack[ runIdx ].token_float,
													  runStack[ runIdx ].token_int ) );
						}
					}
				}
				
				steps_done++;
				ip++;
				continue;
			}
			
//
//		OPERATORS and VERBS
//
			apply_op = false;

			if ( NL_OPERATOR == runStack[ ip ].token_type )
			{
comment( "  OPERATORS and VERBS    " );
				var op_to_do = runStack[ ip ].token_op_means;
				
	comment( "  Check for Punctuation. Punctuation is never pushed on Operator stack.  " );
				if ( ( OP_IS_PERIOD    == op_to_do )
				  || ( OP_IS_COMMA     == op_to_do )
				  || ( OP_IS_COLON     == op_to_do )
				  || ( OP_IS_SEMICOLON == op_to_do ) )
				{
					apply_op = true;
					// No Operators pending could be normal after a Verb runs.
				
					if ( show_stacks )
					{
						if ( show_details )
						{
							msg( "   running Punctuation  " + runStack[ ip ].internal_token + "\n" );
							run_text_line++;
						}
						#if cs
						{
							msg( "Ops Stack  = " + opStackToString( runStack, opStack ) + "\n" );
							run_text_line++;
						}
						#else
							viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
						#end
					}
					
					if ( 0 < assignStack.length )
						opStack.unshift( assignStack.pop() );
					
					if ( 0 < opStack.length )
					{
						var ops_result = runOperators( runStack, dataStack, opStack, nouns, false, true );
						if ( cast( ops_result, Int ) < 0 )
						{
							// Severe ERROR. Stop Interpreter.
							intp_return_result = ops_result;
							break;
						}
					}
					
				}
				else
				{
		comment( "  Not Punctuation  " );
					if ( ( OP_IS_ASSIGNMENT  == op_to_do )
					  || ( OP_IS_ASSIGN_TO   == op_to_do )
					  || ( OP_IS_ASSIGN_FROM == op_to_do ) )
					{
						if ( OP_IS_ASSIGN_TO == op_to_do )
						{
				comment( " Special Case: We know Assign To has only 1 destination after it. ", "" );
							if ( ( NL_NOUN_LOCAL   != runStack[ ip + 1 ].token_type )
							  && ( NL_TYPE_UNKNOWN != runStack[ ip + 1 ].token_type )		// INFERENCE
							  && ( NL_NOUN         != runStack[ ip + 1 ].token_type ) )
							{
								error( "SYNTAX ERROR: Noun or local Noun must follow Assign into. Stopping\n" );
								run_text_line++;
								intp_return_result = RET_IS_USER_ERROR_SYNTAX;
								break;
							}
							
							if ( 0 == dataStack.length )
							{
								comment( " Try running pending Operators " );
								if ( 0 == opStack.length )
								{
									error( "\nSYNTAX ERROR: Assign into has no data available and nothing to make data. Stopping\n" );
									run_text_line++;
									intp_return_result = RET_IS_USER_ERROR_SYNTAX;
									break;
								}
								
								runOperators( runStack, dataStack, opStack, nouns, false, true );
								if ( 0 == dataStack.length )
								{
									error( "\nSYNTAX ERROR: Assign into has no data available. Stopping\n" );
									run_text_line++;
									intp_return_result = RET_IS_USER_ERROR_SYNTAX;
									break;
								}
							}
							
							if ( 0 < opStack.length )
								runOperators( runStack, dataStack, opStack, nouns, false, true );

							comment( "  Find first reference in the Nouns stack  " );
							var assign_idx = ip + 1;
							var name_to_find = runStack[ ip + 1 ].internal_token;
							
							var nounsIdx = 0;
							var runIdx = 0;
							var already_known = false;
							while ( nounsIdx < nouns.length )
							{
								runIdx = nouns[ nounsIdx ];
								if ( name_to_find == runStack[ runIdx ].internal_token )
								{
									// Already known as Noun or Local Noun
									already_known = true;
									assign_idx = runIdx;
									break;
								}
								nounsIdx++;
							}
							
							if ( ( ! already_known )
							  && ( NL_TYPE_UNKNOWN != runStack[ ip + 1 ].token_type ) )
							{
								// First instance of this Noun so add to Nouns list
								nouns.push( ip + 1 );
							}

					comment( " Assign into following Noun or Local Noun (using Noun stack reference index) " );
							runStack[ assign_idx ].token_noun_data = dataStack[ dataStack.length - 1 ].data_type;
							runStack[ assign_idx ].token_str       = dataStack[ dataStack.length - 1 ].data_str;
							runStack[ assign_idx ].token_float     = dataStack[ dataStack.length - 1 ].data_float;
							runStack[ assign_idx ].token_int       = dataStack[ dataStack.length - 1 ].data_int;
							
							dataStack.pop();
							
							if ( NL_TYPE_UNKNOWN == runStack[ ip + 1 ].token_type )	// INFERENCE this is a Local Noun
							{
								if ( ip + 1 == assign_idx )
								{
									runStack[ ip + 1 ].token_type = NL_NOUN_LOCAL;
									nouns.push( ip + 1 );
								}
							}
							
							if ( NL_OPERATOR == runStack[ ip + 2 ].token_type )
							{
								comment( " If Punctuation then skip it as well. " );
								var next_op = runStack[ ip + 2 ].token_op_means;
								if ( ( OP_IS_PERIOD    == next_op )
								  || ( OP_IS_COMMA     == next_op )
								  || ( OP_IS_COLON     == next_op )
								  || ( OP_IS_SEMICOLON == next_op ) )
								{
									ip = ip + 3;
								}
								else
									ip = ip + 2;	// allow next Operator such as  }  to run
							}
							else
								// Skip over the Noun or Local Noun
								ip = ip + 2;
							
							steps_done++;
							continue;
						}
						else
						{
							comment( " Assign From and Assignment are deferred until punctuation is hit. " );
							assignStack.push( ip );
							ip++;
							continue;
						}
					}
					else
					if ( OP_IS_PI == op_to_do )
					{
						// var result : Float = Math.PI;
						dataStack.push( new DataItem( NL_FLOAT, "", Math.PI, 0 ) );
						
						steps_done++;
						ip++;
						continue;
					}
					else
					if ( OP_IS_RANDOM == op_to_do )
					{
						// var result : Float = Math.random();
						dataStack.push( new DataItem( NL_FLOAT, "", Math.random(), 0 ) );
						
						steps_done++;
						ip++;
						continue;
					}
					else
					// Expression Grouping symbols ?
					if ( ( OP_IS_EXPRESSION_START == op_to_do )
					  || ( OP_IS_EXPRESSION_END   == op_to_do ) )
					{
						// For now  assume EURO languages (Left to Right)  TODO put in other support
						if ( OP_IS_EXPRESSION_START == op_to_do )
						{
					comment( " Entering an expression to evaluate. " );
							
							// Save Operator and Data stacks onto Top of Old from Bottom of existing
							// Using a Stack Frame approach
							old_opStackFrames.push( opStack.length );
							while ( 0 < opStack.length )
								old_opStack.push( opStack.shift() );
								
							old_dataStackFrames.push( dataStack.length );
							while ( 0 < dataStack.length )
								old_dataStack.push( dataStack.shift() );
						}
						else
						{
					comment( "Leaving an Expression that was evaluated.", 
							"Make sure everything was evaluated.",
							"Within a single group to evaluate",
							"there is no starting Operator or Data stack values.",
							"This means if there are any Operators to do then do them now." );
							
							if ( 0 < opStack.length )
							{
								var ops_result = runOperators( runStack, dataStack, opStack, nouns );
								if ( cast( ops_result, Int ) < 0 )
								{
									// Severe ERROR. Stop Interpreter.
									intp_return_result = ops_result;
									break;
								}
							}

							comment( "", "Restore 1 Frame of old underneath (at Bottom of) Operator and Data stacks", "" );
							var num_to_do = 0;
							if ( 0 < old_opStackFrames.length )
								num_to_do = old_opStackFrames.pop();
							while ( 0 < num_to_do )
							{
								opStack.unshift( old_opStack.pop() );
								num_to_do--;
							}
							
							num_to_do = 0;
							if ( 0 < old_dataStackFrames.length )
								num_to_do = old_dataStackFrames.pop();
							while ( 0 < num_to_do )
							{
								dataStack.unshift( old_dataStack.pop() );
								num_to_do--;
							}
/*  to  DEBUG if needed							
viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
							msg( "After adding previous Op and Data stack frames.\n" );
							run_text_line++;
							Sys.getChar( false );
*/							
							
							if ( 0 < runStack[ ip ].token_int )
							{
						comment( "", "There is an indication of a Choice word before this Expression", "" );
								var choice_idx = runStack[ ip ].token_int - 1;  // convert back to index from Logical
								var choice_name = runStack[ choice_idx ].internal_token;
								
								if ( NL_CHOICE == runStack[ choice_idx ].token_type )
								{
									if ( ( "for"    == choice_name )
									  || ( "if"     == choice_name )
									  || ( "switch" == choice_name )
									  || ( "while"  == choice_name ) )
									{
										if ( ( "if"     == choice_name )
										  || ( "while"  == choice_name ) )
										{
									comment( " Must be a Bool on the top of Data stack. Error if not. " );
											if ( ( 0 == dataStack.length )
											  || ( NL_BOOL != dataStack[ dataStack.length - 1 ].data_type ) )
											{
												error( "SYNTAX ERROR: " + choice_name + " expression result is not Bool. Stopping.\n" );
												run_text_line++;
												
												msg( "Error location (word number) is " + Std.string( ip ) + "\n" );
												run_text_line++;

												run_text_line += nl_Parse.showWordsTable( runStack, true, true, false );

												intp_return_result = RET_IS_USER_ERROR_SYNTAX;
												break;
											}
											
											// true will run next and false will skip following Block
											var exp_bool = dataStack[ dataStack.length - 1 ].data_int;
											dataStack.pop();
											
											if ( 1 == exp_bool )
											{
												ip++;
												continue;
											}
											else
											{
												ip = Math.floor( runStack[ choice_idx ].token_float ) + 1;
												continue;
											}
											
										}
										else
										{
											error( "INTERNAL ERROR: " + choice_name + " not implemented. Stopping.\n" );
											run_text_line++;
											intp_return_result = RET_IS_NOT_IMPLEMENTED;
											break;
										}
										
										
									}
								}
								else
								{
									error( "INTERNAL ERROR: Choice indicated but not referenced correctly. Stopping.\n" );
									run_text_line++;
									intp_return_result = RET_IS_INTERNAL_ERROR;
									break;
								}
							}
							
							// there could be something like cos ( x )
							// so x is on the Data stack and now cos needs to run
							if ( 0 < opStack.length )
							{
								// Ask to do NEWEST Operator
								var ops_result = runOperators( runStack, dataStack, opStack, nouns, true );
								if ( cast( ops_result, Int ) < 0 )
								{
									// Severe ERROR. Stop Interpreter.
									intp_return_result = ops_result;
									break;
								}
/*  to  DEBUG if needed								
viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
								msg( "After running previous Op (maybe others).\n" );
								run_text_line++;
								Sys.getChar( false );
*/
							}
						}
						
						// No need to push the Grouping symbols like other Operators
					}
					else
					// List Grouping symbols ?
					if ( ( OP_IS_LIST_START ==  op_to_do )
					  || ( OP_IS_LIST_END   ==  op_to_do ) )
					{
						
						
					}
					else
					// Block Grouping symbols ?
					if ( ( OP_IS_BLOCK_START ==  op_to_do )
					  || ( OP_IS_BLOCK_END   ==  op_to_do ) )
					{
						if ( OP_IS_BLOCK_START ==  op_to_do )
						{
							// Entering a Block of statements.
							
							// Save Operator and Data stacks onto Top of Old from Bottom of existing
							// Using a Stack Frame approach
							old_opStackFrames.push( opStack.length );
							while ( 0 < opStack.length )
								old_opStack.push( opStack.shift() );
								
							old_dataStackFrames.push( dataStack.length );
							while ( 0 < dataStack.length )
								old_dataStack.push( dataStack.shift() );

						}
						else
						{
							// Leaving an Block of statements.
							// Make sure everything was evaluated.
							// Within a single group to evaluate 
							// there is no starting Operator or Data stack values.
							// This means if there are any Operators to do then do them now.
							
							if ( 0 < opStack.length )
							{
								var ops_result = runOperators( runStack, dataStack, opStack, nouns );
								if ( cast( ops_result, Int ) < 0 )
								{
									// Severe ERROR. Stop Interpreter.
									intp_return_result = ops_result;
									break;
								}
							}
							
							if ( 0 < assignStack.length )
							{
								var r_idx = assignStack.pop();
								var assign_op = runStack[ r_idx ].token_op_means;
								runAssignment( runStack, dataStack, opStack, nouns, assign_op );
							}

							// Restore 1 Frame of old underneath (at Bottom of) Operator and Data stacks
							var num_to_do = 0;
							if ( 0 < old_opStackFrames.length )
								num_to_do = old_opStackFrames.pop();
							while ( 0 < num_to_do )
							{
								opStack.unshift( old_opStack.pop() );
								num_to_do--;
							}
							
							num_to_do = 0;
							if ( 0 < old_dataStackFrames.length )
								num_to_do = old_dataStackFrames.pop();
							while ( 0 < num_to_do )
							{
								dataStack.unshift( old_dataStack.pop() );
								num_to_do--;
							}
							
							// Check to see if Block End is with a Choice
							if ( 0 < runStack[ ip ].token_int )
							{
								ip = runStack[ ip ].token_int - 1;
								steps_done++;
								continue;
							}
							
							// Check to see if Block End needs to skip forward
							if ( 0.0 < runStack[ ip ].token_float )
							{
								ip += Math.floor( runStack[ ip ].token_float );
								steps_done++;
								continue;
							}
						}
					}
					else
					{
				comment( " Any Operator that is Not Punctuation is pushed " );
						opStack.push( ip );
						if ( show_stacks )
						{
							#if cs
							{
								msg( "Ops Stack  = " + opStackToString( runStack, opStack ) + "\n" );
								run_text_line++;
							}
							#else
								viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
							#end
						}
						
						var ops_result = runOperators( runStack, dataStack, opStack, nouns );
						if ( cast( ops_result, Int ) < 0 )
						{
							// Severe ERROR. Stop Interpreter.
							intp_return_result = ops_result;
							break;
						}
					}
					
					steps_done++;
					ip++;
					continue;
				}
			}
			
//
//		CHECK FOR VERB
//
			var verb_pending = false;
			if ( ( NL_VERB     == runStack[ ip ].token_type )
			  || ( NL_VERB_RET == runStack[ ip ].token_type )
			  || ( NL_VERB_BI  == runStack[ ip ].token_type ) )
			{
				verb_pending = true;
				
				// If there are any Pending Operations, do them before the Verb
				if ( 0 < opStack.length )
				{
					apply_op = true;
					ip--;				// Back up 1 position so next time Verb is run
				}
			}
			
			if ( apply_op )
			{
				if ( 0 < opStack.length )
				{
					var ops_result = runOperators( runStack, dataStack, opStack, nouns );
					if ( cast( ops_result, Int ) < 0 )
					{
						// Severe ERROR. Stop Interpreter.
						intp_return_result = ops_result;
						break;
					}

					// steps_done++;
					ip++;
					continue;
				}
			}
			
//
// 		VERB 
//
			if ( ( NL_VERB     != runStack[ ip ].token_type )
			  && ( NL_VERB_RET != runStack[ ip ].token_type )
			  && ( NL_VERB_BI  != runStack[ ip ].token_type ) )
			{
				// Not a VERB to run
				ip++;
				continue;
			}
			
//		RUN a VERB
//
			if ( ( show_details ) && ( NL_VERB_RET != runStack[ ip ].token_type ) )
			{
				msg( "\n   running Verb   " + runStack[ ip ].internal_token + "\n" );
				run_text_line++;
				run_text_line++;
			}
			
		//if ( ip + 2 < runStack.length )
		//{
		//	comment( "", "See if ( ) follows the Verb, meaning using Call style syntax", "" );
			
			
		//}
			
			if ( NL_VERB == runStack[ ip ].token_type )
			{
	comment( "","  Run a Verb defined in the Dictionary  " );
				// var verbIdx = nlDict.findWord( runStack[ ip ].internal_token, runStack[ ip ].internal_token, false );
				
				//  ip  'points' to this Verb.
				//
				// Use an invisible command to do a relative Return (subtract number of structures Added below)
				//
				var verb_text = runStack[ ip ].token_str;	// IF ANY CODE CHANGE / GENERATION use  findWord  above
				
				if ( 0 == verb_text.length8() )
				{
					ip++;
					continue;
				}
				
				var verb_tokens = nl_Parse.parse( verb_text, PARSE_LEFT_TO_RIGHT, false );
				
				if ( 0 == verb_tokens.length )
				{
					// Maybe Verb text was all Comments ?
					ip++;
					continue;
				}
				
		comment( "", "Save only Noun values to Dictionary (Not Local Nouns)", "" );
				nl_Parse.saveNounValues( nlDict, runStack, nouns );
				
				var old_length = runStack.length;
				
				comment( "", "ADD more structures AT THE END of existing Run Stack.", 
				"   ? THIS TRIES TO AVOID EXCESSIVE RESOURCE USE ?", "" );
				run_text_line += nl_Parse.resolveTokens( verb_tokens, nlDict, runStack, run_verbose );

				repeat_found = nl_Parse.repeat_verb_found;

				if ( nl_Parse.left_groups != nl_Parse.right_groups )
				{
error( "\nSYNTAX ERROR: count of " + Std.string( nl_Parse.left_groups ) + " Left and " + Std.string( nl_Parse.right_groups ) + " Right group symbols ( ) [ ] { } not same.\n" );
					run_text_line++;
					run_text_line++;
				}
				
				nl_Parse.resolveAssigns( runStack );

				var choice_result = RET_IS_INTERNAL_ERROR;
				if ( export_as_code )
				{
					var export_runStack = nl_Parse.refactorForExport( runStack );
					choice_result = nl_Parse.resolveChoice( export_runStack );
					
					runStack = export_runStack;
				}
				else
					choice_result = nl_Parse.resolveChoice( runStack );

				if ( 0 > cast( choice_result, Int ) )
				{
					intp_return_result = choice_result;
					break;
				}

				if ( ( show_words_table || export_as_code ) && ( 0 < runStack.length ) )
					run_text_line += nl_Parse.showWordsTable( runStack, show_words_table, false, export_as_code );

				if ( export_as_code )
				{
					var j = 0;
					var exp_text = "";
					while ( j < runStack.length )
					{
						var str  = "";
						if ( display_internal )
						{
							str = runStack[j].internal_token;
							if ( "" == str )
								str = runStack[j].visible_token;
						}
						else
							str = runStack[j].visible_token;

						exp_text += str + " ";
						j++;
					}
	
					export_as_code_log.push( exp_text );
				}

				comment( "", "ADD a structure so after the Verb to be called is done,",
				"we can resume running in the original Verb after this called Verb.", "" );
				runStack.push( new NLToken() );
				var rIdx = runStack.length - 1;
				
				var new_length = runStack.length;
				
				runStack[ rIdx ].token_type     = NL_VERB_RET;
				comment( "", "Return placeholder ONLY Slightly Visible by seeing an extra blank space", "" );
				runStack[ rIdx ].internal_token = " ";
				runStack[ rIdx ].visible_token  = " ";
				runStack[ rIdx ].token_int      = ip + 1;		// new  ip  value after Return
				runStack[ rIdx ].token_float    = (new_length - old_length);	// How many structures on Run Stack to remove later

				// Save Assign, Noun, Operator and Data stacks onto Top of Old from Bottom of existing
				// Using a Stack Frame approach

				old_assignStackFrames.push( assignStack.length );
				while ( 0 < assignStack.length )
					old_assignStack.push( assignStack.shift() );
				
				old_nounStackFrames.push( nouns.length );
				while ( 0 < nouns.length )
					old_nounStack.push( nouns.shift() );
				
				old_opStackFrames.push( opStack.length );
				while ( 0 < opStack.length )
					old_opStack.push( opStack.shift() );
				
			//  TODO  Strongly consider having a Procedure call style interface to a Verb
			//  Procedure call interface would look like
			//      myVerb( 47, x )
			//  where you could use Constants, Expressions, Nouns or even other Verbs as arguments.
			//  For a Procedure style ONLY the 2 (in this case) arguments would be on the Data Stack
			//  given to the called Procedure.
			//
			// Until there is a Procedure style for Verbs allow the Data Stack to be passed in.
				
		/*  COMMENTED OUT to allow full Data Stack to be available within called Verb.
				old_dataStackFrames.push( dataStack.length );
				while ( 0 < dataStack.length )
					old_dataStack.push( dataStack.shift() );
		*/
					
				ip = old_length;	// Move to the just set up Verb structures
				continue;
			}
			else
			if ( NL_VERB_RET == runStack[ ip ].token_type )
			{
				comment( "", "Save only Noun values to Dictionary (Not Local Nouns)", "" );
				nl_Parse.saveNounValues( nlDict, runStack, nouns );
				
				comment( "", "EMPTY the Nouns Stack", "" );
				var num_to_do = nouns.length;
				while ( 0 < num_to_do )
				{
					nouns.pop();
					num_to_do--;
				}
				
				comment( "Restore 1 Frame of old underneath (at Bottom of) Assign, Noun, Operator and Data stacks" );
				num_to_do = 0;
				if ( 0 < old_assignStackFrames.length )
					num_to_do = old_assignStackFrames.pop();
				while ( 0 < num_to_do )
				{
					assignStack.unshift( old_assignStack.pop() );
					num_to_do--;
				}
				
				num_to_do = 0;
				if ( 0 < old_nounStackFrames.length )
					num_to_do = old_nounStackFrames.pop();
				while ( 0 < num_to_do )
				{
					nouns.unshift( old_nounStack.pop() );
					num_to_do--;
				}
				
				num_to_do = 0;
				if ( 0 < old_opStackFrames.length )
					num_to_do = old_opStackFrames.pop();
				while ( 0 < num_to_do )
				{
					opStack.unshift( old_opStack.pop() );
					num_to_do--;
				}

			/*  COMMENTED OUT because full Data Stack was passed in earlier. See above.
				num_to_do = 0;
				if ( 0 < old_dataStackFrames.length )
					num_to_do = old_dataStackFrames.pop();
				while ( 0 < num_to_do )
				{
					dataStack.unshift( old_dataStack.pop() );
					num_to_do--;
				}
			*/
	
				var new_ip = runStack[ ip ].token_int;
				
				// Clean up Run stack
				var num_to_remove = Math.floor( runStack[ ip ].token_float );
				num_to_do = num_to_remove;
				while ( 0 < num_to_do )
				{
					runStack.pop();
					num_to_do--;
				}
				
		comment( " Update Noun values from Dictionary (Not Local Nouns) " );
				nl_Parse.updateNounValues( nlDict, runStack, nouns );

				if ( runStack.length - 1 < new_ip )
					break;
				
				ip = new_ip;
				continue;
			}
			else
			if ( NL_VERB_BI == runStack[ ip ].token_type )
			{
				comment( "", "    Built In  VERB", "" );
				if ( "repeat" == runStack[ ip ].internal_token )
				{
					comment( "", "    Repeat built in: Need to set up Limit for number of Repeats ?", "" );
					if ( repeat_limit < 0 )
					{
						if ( 0 < dataStack.length )
						{
							var repeat_data_type = dataStack[ dataStack.length - 1 ].data_type;
							if ( NL_INT == repeat_data_type )
							{
								if ( 0 <= dataStack[ dataStack.length - 1 ].data_int )
								{
									repeat_limit_found = true;
									repeat_limit = dataStack[ dataStack.length - 1 ].data_int;
									// Data Stack gets cleaned up below
								}
							}
						}
						
						if ( repeat_limit < 0 )
							repeat_limit = 0;
					}
					
					repeat_count++;
		
					if ( repeat_count <= repeat_limit )
					{
						if ( repeat_limit_found )
							dataStack.pop();	// Clean up Data stack item just before Repeat word.
							
						comment( "", "    MUST Reset  all LOCAL Nouns to UNKNOWN in Run stack", 
									 "    MUST Remove all LOCAL Nouns in Noun stack", "" );
						i = nouns.length - 1;
						while ( 0 <= i )
						{
							var nounIdx = nouns[ i ];
							if ( NL_NOUN_LOCAL == runStack[ nounIdx ].token_type )
							{
								runStack[ nounIdx ].token_type = NL_TYPE_UNKNOWN;
								nouns.remove( nounIdx );
							}
							
							i--;
						}
						
						if ( 0 < nouns.length )
						{
							if ( show_stacks )
							{
								#if cs
								{
									msg( "Nouns = " + nounStackToString( runStack, nouns ) + "\n", NOUN_COLOR );
									run_text_line++;
								}
								#else
									viewDataOpNouns( runStack, dataStack, opStack, nouns, dataOpNoun_text_line );
								#end
							}
						}
						
						if ( 0 < opStack.length )
						{
							warning( "WARNING: Doing Repeat with leftover Operators: " + opStackToString( runStack, opStack ) + "\n");
							run_text_line++;
						}
						
						
					// Move Cursor back to start of line
						msg( "\r" );
												
					//#if !cs
					//	viewRepeatCount( repeat_count, repeat_text_line );
					//#else
						// C# can make use of \r (Carriage Return only)
						// So put the Repeat Count at the start followed by a TAB for any normal output
						msg( Std.string( repeat_count ) + "\t" );
					//#end
			
						ip = 0;
						continue;
					}
					else
					{
						// Do NOT let the Repeat Count data stack item cross over into running other words.
						// INVARIANT  No suprise behavior to User.
						if ( repeat_limit_found )
							dataStack.pop();	// Clean up Data stack item just before Repeat word.
					}
					
				}
				else
				if ( ( "show" == runStack[ ip ].internal_token )
				  || ( "view" == runStack[ ip ].internal_token ) )
				{
					comment( "","    Show or View what is on the Data stack",
					"Show removes 1 item.",
					"", "    View will display all items without removal. Handy for User Debugging", "",
					"Note: View is specific to forGL and not for Export as Code", "" );
					
					// See if using Procedure Call syntax, ex:  show( 7 )
					//if ( ( ip < runStack.length - 1 )
					//  && ( "(" == runStack[ ip + 1 ].internal_token ) )
					//  ;
					//procCall( ip, runStack, dataStack, opStack, nouns );
					
					var showing = true;
					if ( "view" == runStack[ ip ].internal_token )
					{
						showing = false;
						msg( "\n        Data  Stack\n" );
						run_text_line++;
						run_text_line++;
					}
					
					i = dataStack.length - 1;
					while ( i >= 0 )
					{
						var dataIdx = i;
						var dataStr = "";
						if ( NL_INT == dataStack[dataIdx].data_type )
							dataStr = Std.string( dataStack[dataIdx].data_int );
						else
						if ( NL_BOOL == dataStack[dataIdx].data_type )
						{
							dataStr = "false";
							if ( 1 == dataStack[dataIdx].data_int )
								dataStr = "true";
						}
						else
						if ( NL_FLOAT == dataStack[dataIdx].data_type )
							dataStr = Std.string( dataStack[dataIdx].data_float );
						else
						if ( NL_STR == dataStack[dataIdx].data_type )
						{
							dataStr = dataStack[dataIdx].data_str;
							
							if ( showing )
								dataStr = trimQuotes( dataStr );
						}
						else
						{
							error( " \nINTERNAL ERROR: Data not Float, Integer, Bool or String\n" );
							run_text_line++;
							run_text_line++;
							i--;
							continue;
						}
						
						if ( showing )
						{
							// Show may be used to format Data so no extra characters
							if ( 0 < dataStr.length8() )
							{
							#if !cs
								show1Data( dataStr, show_text_line );
							#else
								msg( dataStr );
							#end
							}
							
							if ( export_as_code )
							{
								var exp = dataStr;
								comment( "Use Noun name if available for Export" );
								if ( ( NL_STR != dataStack[dataIdx].data_type )
								  && ( 0 < dataStack[dataIdx].data_str.length ) )
									exp = dataStack[dataIdx].data_str;
								
								export_as_code_log.push( "show ( " + exp + " )" );
							}
							
							dataStack.pop();
							
							break;
						}
						else
						{
							// View puts 1 data item per line
							msg( dataStr + "\n" );
							run_text_line++;
						}
						
						i--;
					}
				}
			}

			ip++;
			
		} 
//
//  END  OF  INTERPRETER  LOOP
//
comment( "", "    END  OF  INTERPRETER  LOOP    ", "" );

		intp_ip = ip;
		
		outputBuffersUsed();


		// TODO:  use  comment( )  utility here

/*   Overall approaches:
 *   ------------------
 *       Checking for various Warnings or Errors are done as soon as possible.
 *       Messages are intended to give enough information to help fix the Warning/Error.
 * 
 * 
 *   Runtime Functional Blocks:
 *   -------------------------
 * 
 *   Import word definitions from a Dictionary file (.toml format supported)  DONE, Import is OPTIONAL
 *   
 *   Default definitions automatically generated even if no .toml file given.  DONE
 *       This allows a minimum useful working vocabulary if not already defined.
 * 
 *   Text Editor to allow User/Programmer to define a Verb to run  DONE, 
 *       Very simple now, needs several improvements
 * 
 *   Parsing constrained natural language (NL) text to Nouns, Verbs, Operators and/or reserved words.  DONE
 *       Parsing Math as some reserved words with pre, post or infix notation also.
 *       Resolve various unknown tokens to numbers or strings or local variables (local Nouns)
 * 
 *   Do useful things with Nouns (Data) and Verbs (Code or actions on Data)  DONE
 *       and whatever for Operators and Built In reserved words
 *
 *       Useful things involve allow UI for Editing or Running (UI may not be needed) 
 *           parts of a single word's definition
 *           an entire word's definition
 *           several words beginning with a starting word (like a full application)
 * 
 *   Checking for syntax Errors / Warnings (somewhat like Lexicological viewpoint)  DONE
 *       Checks are done as various internal data structures are filled in or at Runtime.
 * 
 *   If Errors or Warnings about something is found run the  Debugger UI.  DONE
 *       Let the User/Programmer have access to details (Views of: Data, Operator and Noun stacks).
 *       Provide suggestions to help fix as much as feasible.
 * 
 * 
 *       Functions list and more excitement:  (Not All Done, only  DONE  are noted)
 * ----------------------------------------
 *   Using Syntax Errors / Warnings to pull up related NL text in Editor UI for fixes.
 * 
 *   About here would be a useful internal representation of Data and Code to run.  DONE
 * 
 *   IF no Severe Errors (unrecoverable or unable to proceed) 
 *       Run the Code with the Data given. 								DONE
 *           UI for Running may not be required.
 *           Or UI may be in another process space (Local or Remote)
 *           In ALL variations given below:
 *               Warn User/Programmer about any problems and give suggestions.  DONE
 * 
 *   Debugger UI
 *       Required:											DONE
 *           Single Step forwards:  needs improvement
 * 	            Built in reserved words may not allow very detailed steps
 *              Each Step will do something with a Noun or Verb
 * 					(or some internal change: push/pop on the Data, Operator or Noun stacks)
 *              UI will show changes as needed after each step
 *              UI currently shows Data, Operator, Noun stacks as Horizontal lists
 *                  See when  
 * show_stacks  
 * 					varialble is True for details.
 * 
 *       Really Nice to Have:
 *           Breakpoints (in Code):
 *               at a given NL position (unconditional)
 *               at a given NL position (after skipping so many times)
 * 
 *           Breakpoints when a logical Expression involving Data and maybe Code
 *               changes from current Expression state to another state
 * 
 *           Ability to run full speed forward until a Breakpoint is hit
 *               Only application UI changes and not the Debugger UI or very little of it
 *
 *           Ability to run in Animated mode (forward)  DONE
 *               Like Single Step but without waiting for User input for next step
 * 
 *       Really Nice to Have (sometime):
 *           Editor available to support Edit and Continue feature of Debugger
 *               At least allow editing Noun (Data) values
 *
 *           Single Step backwards:
 *               Very useful to get details out of the Debugger without having to start over
 * 				 Technically can be very tricky (complex, Error prone) or a memory hog or both.
 *                   Warn User/Programmer about any known problems and give suggestions.
 * 
 *           Animated Step backwards: similar to forwards
 *               
 *           Run full speed backwards: similar to forwards
 * 
 *           Breakpoints should (hopefully) work same when going backwards as forwards.
 * 
 * 
 *     Because of OO Haxe as implementation language:
 * It is possible for 2 or more instances to Run concurrently:
 *     (Upper level of app just needs to use unique dictionary per forGL_run instance)
 *     (Expect added/changed code to support multi access to UI and Data Store)
 *     (Normal cautions about changed state accessed by threads apply)
 *     (Such as static variables in a class instanced by different threads are a problem)
 *     (If too messy, just run 2 different processes of entire app)
 * 
 * One instance could be running a test dictionary normally.
 * This could be like batch or background processing without 
 *     needing much attention from User/Programmer.
 * 
 * Another instance could run more interactively with a UI:
 *     User/Programmer is working in another dictionary
 *     running with Editor, Debugger, etc.
 * 
 * There may be no direct communication between 2 Runs or ???
 * 
 */

 	}
}		// END  of  runInterpreter