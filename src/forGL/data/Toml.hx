/* Toml.hx	This is a .toml file Read/Write utility for forGL
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * 
 * 		REQUIRES
 * LOCAL OS system style access to OS file system
 * 			OR
 * LOCAL Network (loopback IP) style access to LOCAL file system through a LOCAL minimal network (Web?) interface
 * 			OR
 * Network interface to REMOTE Data sources that provide persistent Data
 * 
 * 
 *  so far Use LOCAL sys interface direct to file system
 * TODO  put in ACCESS checks to file system and Network
 * 
 * 		TOML Compatability:
 *   This is somewhat compatabile with TOML 0.4 release.
 * There are many capabilities and features of TOML that are not allowed.
 * 
 * Where TOML is case sensitive, forGL ignores case for things like:
 * Names of TOML tables: [Minus] or [minus] is the same (wrong by forGL use).
 *     TOML table name is a placeholder for the start of a word definition.
 * Uniqueness of a word name: all are made lower case and then compared.
 * 
 * In most other ways forGL use of TOML files is MORE strict than TOML.
 * Only certain key names are accepted as valid for a word definition.
 * Uniqueness is roughly checked here but not all information is here
 * for complete Uniqueness tests.
 * 
 * So some sanity checks are done at the TOML level to support dictionaries but
 * are not complete as far as dictionary correctness, which are done elsewhere.
 * 
 *     Testing Status:
 * NOT tested with TOML test suite. 
 * Based on above discussion, testing with a TOML test suite will not help
 * find syntax or logical errors as needed by forGL.
 * 
 * Somewhat tested with forGL files...
 * 
 * See TOML project:
 * https://github.com/mojombo/toml/blob/master/versions/en/toml-v0.4.0.md
 * ...
 * @author Randy Maxwell
 */

package forGL.data;

using Sys;

import haxe.Log;
import forGL.NLTypes.ResolveInfo;

import haxe.io.Eof;

#if ! js
	import sys.io.File;
	import sys.io.FileInput;
	import sys.FileSystem;
#end

import forGL.UI.ForGL_ui.msg      as   msg;
import forGL.UI.ForGL_ui.error    as   error;
import forGL.UI.ForGL_ui.status   as   status;

#if js
	import forGL.UI.ForGL_ui.getDictionaryTextLines_js   as   getDictionaryTextLines_js;
#end

// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

using  forGL.NLTypes;
import forGL.NLTypes.NLTypeAs.nlTypeAsStr    as  nlTypeAsStr;

import forGL.Meanings.ReturnMeanings;
import forGL.Meanings.MeansWhat.returnMeanAsStr  as  returnMeanAsStr;

import forGL.FileTypes.FileTypes   as   FileTypes;

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment    as    comment;

using forGL.data.Toml.ForGL_toml;

 
//				Interface to .toml persistent Dictionaries and data
class ForGL_toml
{
	public function new() 
	{
	}
	
	public  var actual_path_file : String = "";
	public  var actual_file_type : FileTypes = FILE_IS_UNKNOWN;
	
	public  var error_msgs   = new Array<String8>();
	public  var warning_msgs = new Array<String8>();
	
	
	#if ( sys ) // Is stdout and File I/O available and various APIs ?
		// 
		//
		//
		
		
	#else
		// Running in a Web browser or Flash or something like it.
		// Graphics mode output available but no direct file I/O.
		// Connecting to Local or Remote Data Store allows file I/O
		// or connect to a Logging utility (Local or Remote)
		// If NO Local or Remote connection wanted, still can run as "Super Calculator"
		//     just NO persistent data will be saved
		
		
	#end
	
	private  var data_call_count = 0;
	
	
#if js
	private  var fReadHandle = "";
#else
	private  var fReadHandle : FileInput;
#end
	
	private  var ws_chars : Array<hx.strings.Char> = [ " ", "\t" ];

/*
	private  var invalid_chars : Array<hx.strings.Char> = [ "\\", "+", 
	"-", "*", "/", "%", "<", "<=", "==", "=", ">", ">=", "!", "?", "!=",
	"(", ")", "[", "]", "{", "}", ",", ".", ";", ":" ];
*/
	
	private  var fileLines = new Array<String8>();
	
	private  var comment_lines = 0;
	
	// Arrary of indexes to fileLines (same as line numbers - 1)
	private  var sections = new Array<Int>();

	private  var section_names = new Array<String8>();	// Releated name within each section
	
	// These are a slightly shorter arrays
	// with values found each section that have been checked to be valid Word definitions
	// NOTE: Validity is from TOML level and NOT from complete Dictionary viewpoint
	
	private  var word_list = new Array<String8>();
	private  var type_list = new Array<NLTypes>();
	private  var built_in_list = new Array<String8>();
	private  var value_list = new Array<String8>();
	
	#if ( sys ) 
		//private var stdout = Sys.stdout();
		
		
		
	#end
	
	
	public function callCount() : Int
	{
		return data_call_count;
	}


/*		Initialize  toml  file handling with a given file to Read
*/
	public function init( path_file:String8 = "forGL_Dict.toml", file_type : FileTypes ) : ReturnMeanings
	{
		comment( "Initialize  toml  file handling with a given file to Read" );
		var ret_val = RET_IS_OK;
		
		error_msgs = [ "" ];
		error_msgs.pop();
		
		warning_msgs = [ "" ];
		warning_msgs.pop();
		
		actual_path_file = path_file;
		
		data_call_count++;

	#if ( sys || js ) 
	
	try
	{
	#if js

		fileLines = getDictionaryTextLines_js();
		
		actual_file_type = file_type;
		
	#else
		var does_exist = FileSystem.exists( actual_path_file );
			
		if ( false == does_exist )
		{
			comment( "Try up 1 directory level" );
			does_exist = FileSystem.exists( "../" + actual_path_file );
			
			if ( false == does_exist )
			{
				var err_msg = "ERROR: Path or File not found: " + path_file + "\n";
				error_msgs.push( err_msg );
				error( err_msg );
				return RET_IS_USER_ERROR_DATA;
			}
			else
				actual_path_file = "../" + actual_path_file;
		}
	
		
		comment( "Make sure this has .toml file extension" );
		var extension = actual_path_file.substr( actual_path_file.length - 5, 5 );
		if ( ".toml" != extension.toLowerCase() )
		{
			var err_msg = "ERROR: File extension not .toml : " + actual_path_file + extension + "\n";
			error_msgs.push( err_msg );
			error( err_msg );
			return RET_IS_USER_ERROR_DATA;
		}
				
		comment( "Make sure this is Not a directory" );
		var is_dir = FileSystem.isDirectory( actual_path_file );
		if ( true == is_dir )
		{
			var err_msg = "ERROR: Directory found but should be a File: " + actual_path_file + "\n";
			error( err_msg );
			return RET_IS_USER_ERROR_DATA;
		}
		
	comment( "Read the .toml file" );
		fReadHandle = File.read( actual_path_file, true );
		
		fileLines = [ "" ];
		fileLines.pop();
		
		var temp_line : String8 = "";
		
		
	try 	// catch Eof exception
	{
		while ( true )
		{
			temp_line = fReadHandle.readLine();		// throws Eof eventually
			
			temp_line.trim();
			
			fileLines.push( temp_line );
		}
	}
	catch ( e : Eof ) {
		// Expected, just fall through
	}
	
		// Finished Reading. Close the file to the OS.
		fReadHandle.close();
	
	#end
	
		// msg( "There are " + Std.string( fileLines.length ) + " lines read. \n" );
		
		var i = 0;
		comment_lines = 0;
		
	#if ! js
		actual_file_type = FILE_IS_UNKNOWN;
	#end
	
		var found_file_type = false;
		var first_toml_table = -1;
		
		while ( i < fileLines.length )
		{
			if ( 0 == fileLines[ i ].length )	// Empty line ?
			{
				i++;
				continue;
			}
			
			if ( "#" == fileLines[ i ].charAt8( 0 ) )	// Comment ?
			{
				comment_lines++;
				i++;
				continue;
			}

			if ( "[" == fileLines[ i ].charAt8( 0 ) )
			{
				sections.push( i );		// save where this section starts
				
				section_names.push( fileLines[ i ].trim( "[]" ) );
				
				if ( first_toml_table < 0 )
				{
					first_toml_table = i;
			
					if ( "[forGL_dictionary]" == fileLines[ i ] )
					{
						actual_file_type = FILE_IS_DICTIONARY;
						
						found_file_type = true;
					}
					else
					if ( "[forGL_commands]" == fileLines[ i ] )
					{
						actual_file_type = FILE_IS_COMMANDS;
						
						found_file_type = true;
					}
					else
					if ( "[forGL_data]" == fileLines[ i ] )
					{
						actual_file_type = FILE_IS_DATA;
						
						found_file_type = true;
					}
					else
					{
						// UNKNOWN File Type
						actual_file_type = FILE_IS_UNKNOWN;
var err_msg = "ERROR: Unknown File type. Closing File. First section is: " + fileLines[ i ] + "\n";
						error_msgs.push( err_msg );
						error( err_msg );

						cleanUp();	// Do not try anything else with the file.
						
						return RET_IS_USER_ERROR_DATA;
					}
					
					if ( found_file_type )
					{
						if ( i != first_toml_table )
						{
							error( "ERROR: [forGL_dictionary] is not first section in file.\n" );
						}
						
						// Flip back to false as not needed anymore.
						found_file_type = false;
					}
				}
			}
			
			i++;
		}
		
		if ( ( FileTypes.FILE_IS_UNKNOWN  != file_type )
		  && ( actual_file_type != file_type ) )
		{
		#if ! js
			error( "ERROR: Type of .toml file is not as expected.\n" );
			ret_val = RET_IS_USER_ERROR_DATA;	// TODO  think about how to eliminate or reduce this problem
		#end
		}
		else
		{
			status( Std.string( fileLines.length ) + " lines and " + Std.string( comment_lines ) + " comment lines.\n" );
		}
		
	} 
	catch ( e:Dynamic ) 
	{
		var err_msg = "\nINTERNAL ERROR: Exception in forGL_toml.init(): " + Std.string( e ) + " \n";
		error_msgs.push( err_msg );
		error( err_msg );
		ret_val = RET_IS_INTERNAL_ERROR;
	};
	
	if ( cast( ret_val, Int ) < 0 )
	{
		
	}

		
	#else
		var err_msg = "INTERNAL ERROR: sys Not available. Remote access to data files not Implemented.";
		error_msgs.push( err_msg );
		error( err_msg );
		ret_val = RET_IS_NOT_IMPLEMENTED;
	#end
		
		return ret_val;
	}


/*		Clean up  toml  file handling 
*/	
	public function cleanUp() : ReturnMeanings
	{
		var ret_val = RET_IS_OK;

#if ( sys ) 
	
	try
	{
		// Empty text lines buffer
		fileLines = [ "" ];
		fileLines.pop();
		
		comment_lines = 0;
		
		sections = [ 0 ];
		sections.pop();
		
		section_names = [ "" ];
		section_names.pop();
		
		// Do NOT clean up Errors or Warnings
		
		// fReadHandle.close();  // Called in init already
	}
	catch ( e:Dynamic ) 
	{
		var err_msg = "Exception in forGL_toml.cleanUp(): " + Std.string( e ) + " \n";
		error_msgs.push( err_msg );
		error( err_msg );
		ret_val = RET_IS_INTERNAL_ERROR;
	};
	
#end
	
		return ret_val;
	}
	
	
// Validate a possible word name in a Dictionary
//
// Limited by what is known at data / TOML level
/*
# The first character of any name must Not be a number digit (0 to 9).
#     Other number digits may also be invalid for languages that use them.
#
# A name must Not have any \ (back slash) character.
#
# A User defined name must Not contain:
# reserved Mathematics, Logical, Grouping operators or Punctuation characters.
#   + - * / % < <= == = > >= ! ? != ( ) [ ] { } . , ; : ... 
*/
	public function nameValidate( in_name : String8, ?check_reserved : Bool = true ) : Bool
	{
		comment( "Validate a possible word name in a Dictionary" );
		if ( 0 == in_name.length8() )	// must have 1 or more valid characters
			return false;

		var temp = in_name;
		var result : String8 = "";
		
		// No Quotes or whitespace, CR, LF or \ at all
		var pieces = Strings.split8( temp, [ "'", "\"", " ", "\t", "\r", "\n", "\\" ] );
		var i = 0;
		while ( i < pieces.length )
		{
			if ( 0 < pieces[ i ].length8() )
				result = result.insertAt( result.length8(), pieces[ i ] );
			i++;
		}
		
		if ( result.length8() != temp.length8() )
			return false;

		if ( check_reserved )
		{
			// No already reserved characters
			pieces = Strings.split8( result, [ "+", 
		"-", "*", "/", "%", "<=", "<", "==", "=", ">=", ">", "!=", "!", "?",
		"(", ")", "[", "]", "{", "}", ",", ".", ";", ":" ] );
			result = "";
			i = 0;
			while ( i < pieces.length )
			{
				if ( 0 < pieces[ i ].length8() )
					result = result.insertAt( result.length8(), pieces[ i ] );
				i++;
			}
		
			if ( result.length8() != temp.length8() )
				return false;
		}
		
		// 0 to 9 is Not first character
		if ( ( "0" <= result.charAt8( 0 ) )
		  && ( "9" >= result.charAt8( 0 ) ) )
			return false;

		return true;
	}
	
	
// After = whitespace get contents of Quoted string without the Quotes
	private var getStr_type = NL_TYPE_UNKNOWN;

	public function getStr( in_str : String8, ?get_type = false ) : String8
	{
		comment( "After = whitespace get contents of Quoted string without the Quotes" );
		getStr_type = NL_TYPE_UNKNOWN;
		
		var temp : String8 = in_str;
		
		if ( temp.length8() <= 2 )
		{
			var err_msg = "SYNTAX ERROR: Input string too small from getStr\n";
			error_msgs.push( err_msg );
			error( err_msg );
			return "";
		}
		
		var i = 0;
		while ( ( i < temp.length8() ) && ( "\"" != temp.charAt8( i ) ) )
		{
			i++;
		}
		
		if ( i >= temp.length8() )
		{
			var err_msg = "SYNTAX ERROR: Quote character not found in getStr\n";
			error_msgs.push( err_msg );
			error( err_msg );
			return "";
		}
		
		var temp2 = Strings.substring8( temp, i + 1 ); // we know [ i ] is a double Quote character
		
		if ( 1 <= temp2.length8() )
		{
			if ( "\"" == temp2.charAt8( temp2.length8() - 1 ) )
				temp2 = Strings.substring8( temp2, 0, temp2.length8() -1 );	// trim last Quote character
		}
		else
		{
			var err_msg = "SYNTAX ERROR: Empty String from getStr 2\n";
			error_msgs.push( err_msg );
			error( err_msg );
			temp2 = "";
		}
		
		if ( get_type )
		{
			if ( 0 < temp2.length8() )
			{
				if ( temp2.equalsIgnoreCase( "operator" ) )
					getStr_type = NL_OPERATOR;
				else
				if ( temp2.equalsIgnoreCase( "noun" ) )
					getStr_type = NL_NOUN;
				else
				if ( temp2.equalsIgnoreCase( "verb" ) )
					getStr_type = NL_VERB;
				else
				if ( temp2.equalsIgnoreCase( "choice" ) )
					getStr_type = NL_CHOICE;
			}
		}
		
		return temp2;
	}


// After = whitespace get contents of various value strings without the Quotes
//
// Does Multi-Line strings that start and end with 3 double Quote characters
// Does single line strings that start and end with 1 double Quote character
// Does values for Nouns that may not even have Quote characters
// Does values for Verbs that can be multiple lines. 
// For Verbs, Keeps going until [ found as 1st character of a line or EOF.
//
// Sets end_line to be where the ending Triple double Quote characters were found.
// This uses a line oriented approach as needed.
//
	private var getStrML_end_line = 0;
	
	private var valid_str_ML = false;
	

	public function getStrML( word_type : NLTypes, in_str : String8, start_line : Int ) : String8
	{
		comment( "After = whitespace get contents of various value strings without the Quotes" );
		var err_msg = "";
		var temp   : String8 = "";
		var result : String8 = "";
		
		getStrML_end_line = start_line;
		valid_str_ML = false;
		
		// Handle first line
		// Keep going past = character
		var i = 0;
		var char_found = in_str.charAt8( i );
		while ( "=" != char_found )
		{
			if ( "" == char_found )
				break;		// end of string hit without finding = character
			i++;
			char_found = in_str.charAt8( i );
		}
		
		if ( "" == char_found )
		{
err_msg = "ERROR: getStrML = character not found at line " + Std.string( start_line );
			error_msgs.push( err_msg );
			status( "" );
			error( err_msg, RED );
			return "";
		}

		i++;	// Skip over whitespace
		char_found = in_str.charAt8( i );
		while ( "" != char_found )
		{
			if ( ( " "  != char_found )
			  && ( "\t" != char_found ) )
				break;		// Not whitespace
			i++;
			char_found = in_str.charAt8( i );
		}
		
		if ( "" == char_found )
		{
err_msg = "ERROR: getStrML no visible character after = at line " + Std.string( start_line );
			error_msgs.push( err_msg );
			status( "" );
			error( err_msg, RED );
			return "";
		}
		
		var is_first_quote  = false;
		var is_triple_quote = false;
		temp = Strings.substring8( in_str, i );

		if ( "\"" == temp.charAt8( 0 ) )
		{
			is_first_quote = true;
			if ( 3 <= temp.length8() )
			{
				if ( ( "\"" == temp.charAt8( 1 ) )
				  && ( "\"" == temp.charAt8( 2 ) ) )
					is_triple_quote = true;
			}
		}
		
		if ( ( ! is_triple_quote )
		  && ( is_first_quote ) )
		{
			var getStr_result = getStr( temp );
			
			valid_str_ML = true;
			return getStr_result;
		}
		
		if ( ! is_triple_quote )
		{
			// Could be a multiline Verb definition
			valid_str_ML = true;
			result = temp;
			
			if ( NL_VERB == word_type )
			{
				// Keep going until a left Square Bracket [ is found as 1st character on a line or EOF.
				var tempLines = new Array<String8>();

				var current_line = start_line + 1;
				while ( current_line < fileLines.length )
				{
					temp = fileLines[ current_line ];
					if ( ( 0 < temp.length8() )
					  && ( "[" == temp.charAt8( 0 ) ) )
							break;

					// result += temp;
					// result = result.insertAt( result.length8(), temp );
					// result += "\n";		// put in a newline as we advance

					tempLines.push( temp );	// save

					getStrML_end_line = current_line;
					current_line++;
				}

				// Remove trailing blank lines
				var t = tempLines.length - 1;
				while ( 0 <= t )
				{
					temp = tempLines[ t ];
					if ( 0 < temp.length8() )
						break;
						
					tempLines.pop();
					t--;
				}

				// Build up result
				t = 0;
				while ( t < tempLines.length )
				{
					result = result.insertAt( result.length8(), tempLines[ t ] );
					t++;
					if ( t == tempLines.length )
						break;

					result += "\n";		// put in a newline as we advance
				}
			}
		
			result.trim();
			return result;
		}
		
		// Start adding to result, drop first 3 double Quotes
		temp = Strings.substring8( temp, 3 );
		var current_line = start_line;
		
		// See if last characters ON THIS LINE are """
		while ( "\"\"\"" != Strings.right( temp, 3 ) )
		{
			// No. Means advance 1 line and try again.
			// result += temp;
			result = result.insertAt( result.length8(), temp );
			result += "\n";		// put in a newline as we advance
			
			current_line++;
			if ( fileLines.length <= current_line )
			{
				getStrML_end_line = current_line;
				err_msg = "ERROR: Missing \"\"\" (3 double quote characters) at end.\n";
				error_msgs.push( err_msg );
				status( "" );
				error( err_msg, RED );
				return "";
			}
			
			temp = fileLines[ current_line ];
		}
		
		// Remove last 3 double Quote characters
		temp = Strings.substring8( temp, 0, temp.length8() - 3 );
		
		//result += temp;
		result = result.insertAt( result.length8(), temp );
		getStrML_end_line = current_line;
		valid_str_ML = true;
		
		return result;
	}


// Get a list of Words declared
//
// Correctness of Words are verified within TOML context, Not Dictionary context
//
	public function getWordList( ?warn_not_unique = true ) : Array<String8>
	{
		comment( "Get a list of Words declared" );
		var i = 0;
		var ret_list = new Array<String8>();
//
//			This can be called multiple times. If list already found just return a Copy.
//
		if ( 0 < word_list.length )
		{
			comment( "This can be called multiple times. If list already found just return a Copy." );
			i = 0;
			while ( i < word_list.length )
			{
				ret_list.push( word_list[ i ] );
				i++;
			}
		
			return ret_list;
		}
		
		var k = 0;
		var k_limit = 0;
		var line_num = "0";
		var line_limit = fileLines.length - 1;
		
		var line_buf : String8 = ""; 
		
		var word_type               = NL_TYPE_UNKNOWN;	// Required and must be before these others.
		var word_name     : String8 = "";	// Required and MUST be Unique
		var built_in_name : String8 = "";	// Required if Operator and can NOT be empty.
		var value         : String8 = "";	// Required if Noun or Verb and can be any valid multi line string or empty

		// Go through and look for valid Words
		// Require word names to be Unique.
		// Require valid word type
		while ( i < sections.length )
		{
			// Look for  word_type = 
			//   OR      name = 
			//   OR      built_in_name =
			//   OR      value =
			
			word_type = NL_TYPE_UNKNOWN;
			word_name = "";
			built_in_name = "";
			value         = "";
			
			k = sections[ i ];		// index into fileLines
			
			// limit for this part of TOML file
			if ( i < sections.length - 1 )
				k_limit = sections[ i + 1 ] - 1;	// including this line
			else
				k_limit = line_limit;
			
			k++;					// skip to next line
			while ( k <= k_limit )
			{
				line_buf = fileLines[ k ];

				line_num = Std.string( k + 1 );
				
				if ( "word_type" == Strings.left( line_buf, 9 ) )
				{
					var temp_word_type_str = getStr( line_buf, true );

					if ( NL_TYPE_UNKNOWN != getStr_type )
					{
						word_type = getStr_type;
					}
					else
					{
var warn_msg = "WARNING: Invalid word type: " + temp_word_type_str + " at line " + line_num + " found. Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
				}
				else
				if ( "name" == Strings.left( line_buf, 4 ) )
				{
					// Word type should be before the name
					if ( NL_TYPE_UNKNOWN == word_type )
					{
var warn_msg = "WARNING: word_type needs to be before name at line " + line_num + " Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
					
					var temp_name = getStr( line_buf );
					var valid_name = false;
					if ( 0 < temp_name.length8() )
					{
						if ( NL_OPERATOR == word_type )
							valid_name = nameValidate( temp_name, false );
						else
							valid_name = nameValidate( temp_name );
						
						if ( ( valid_name )
						  && ( warn_not_unique ) )
						{
							// Word name MUST be Unique
							var n = 0;
							var word_name_lower = Strings.toLowerCase8( temp_name );
							while ( n < word_list.length )
							{
								if ( Strings.toLowerCase8( word_list[ n ] ) == word_name_lower )
								{
									// Not allowed
									break;
								}
								
								n++;
							}
							
							if ( n < word_list.length )
							{
var warn_msg = "\nWARNING: word_name " + temp_name + " at line " + line_num + " is not unique. Spelling matches earlier word.\n";
								warning_msgs.push( warn_msg );
								status( "" );
								status( warn_msg, RED, false, true );
								break;
							}
						}
					}
			
					if ( valid_name )
					{
						word_name = temp_name;
					}
					else
					{
var warn_msg = "WARNING: Invalid name: " + temp_name + " at line " + line_num + ". Skipping.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
				}
				else
				if ( "built_in_name" == Strings.left( line_buf, 13 ) )
				{
					// Word type should be before the built in name
					if ( NL_TYPE_UNKNOWN == word_type )
					{
var warn_msg = "WARNING: word_type needs to be before built_in_name at line " + line_num + " Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
					
					// Name should be before the built in name
					if ( 0 == word_name.length )
					{
var warn_msg = "WARNING: name needs to be before built_in_name at line " + line_num + " Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
					
					var temp_built_in_name = getStr( line_buf );
					var valid_built_in_name = false;
					if ( 0 < temp_built_in_name.length )
					{
						if ( NL_OPERATOR == word_type ) // Don't check for reserved if Operator and built in
							valid_built_in_name = nameValidate( temp_built_in_name, false );
						else
							valid_built_in_name = nameValidate( temp_built_in_name );
					}
					
					if ( valid_built_in_name )
					{
						built_in_name = temp_built_in_name;
					}
					else
					{
var warn_msg = "WARNING: Invalid built in name: " + temp_built_in_name + " at line " + line_num + " found. Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
				}
				else
				if ( "value" == Strings.left( line_buf, 5 ) )
				{
					// Word type should be before the value
					if ( NL_TYPE_UNKNOWN == word_type )
					{
var warn_msg = "WARNING: word_type needs to be before value at line " + line_num + " Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;						
					}
					
					// Name should be before the value
					if ( 0 == word_name.length8() )
					{
var warn_msg = "WARNING: name needs to be before value at line " + line_num + " Skipping to next word.\n";
						warning_msgs.push( warn_msg );
						status( "" );
						status( warn_msg, RED, false, true );
						break;
					}
					
					var temp_value = getStrML( word_type, line_buf, k );
					
					if ( valid_str_ML )
					{
						value = temp_value;
						
						if ( k_limit <= getStrML_end_line )
							k = k_limit;
						else
							k = getStrML_end_line;
					}
				}
				else
				{
					if ( ( line_buf.length8() >= 9 )
				      && ( "#" != line_buf.charAt8( 0 ) ) )
					{
					// Not a comment and not what was expected.
					//
					// Give a Warning and continue
//var warn_msg = "WARNING: Invalid information at line " + line_num + ". Moving to next line.\n";
					//warning_msgs.push( warn_msg );
					// status( warn_msg );			// leave off status area for now
					
					// Fall through to check if ready to Save a Word
					}
				}

				if ( ( k_limit <= k )
				  && ( NL_TYPE_UNKNOWN != word_type )
				  && ( 0 < word_name.length ) )
				{
					// Should have everything for a word definiton here
					
					if ( "" == built_in_name )
					{
						if ( NL_OPERATOR == word_type )
						{
var err_msg = "\nERROR: Operator word_name " + word_name + " near line " + line_num + " missing built_in_name.\n";
							error_msgs.push( err_msg );
							status( "" );
							error( err_msg, RED );
							break;
						}
						built_in_name = Strings.toLowerCase8( word_name );
					}
					
					type_list.push( word_type );
					word_list.push( word_name );
					built_in_list.push( built_in_name );
					value_list.push( value );
					
/*
var info_msg = "Info: Saved Word: " + word_name + " type: " + Std.string( word_type ) + " internal: " + built_in_name + " value: " + value;
					status( "" );
					status( info_msg, GREEN, false, true );
*/
				}

				k++;
			}
			
			i++;
		}

// Return a Copy of the just found Word list
//
		i = 0;
		while ( i < word_list.length )
		{
			ret_list.push( word_list[ i ] );
			i++;
		}
		
		return ret_list;
	}
	
	
// Get details about a known word in a file.
//
// The correctness of the word needs checking by caller at Dictionary level.
//
// Sets  getWord_type  and  getWord_word_idx  as well
//
	public var getWord_type = NL_TYPE_UNKNOWN;
	
	public var getWord_word_idx = -1;

	public function getWord( word_visible_name : String8, rInfo : ResolveInfo ) : ReturnMeanings
	{
		comment( "Get details about a known word in a file." );
		comment( "The correctness of the word needs checking by caller at Dictionary level." );
		comment( "Sets  getWord_type  and  getWord_word_idx  as well" );
		var ret_val = RET_IS_OK;
		
		getWord_type = NL_TYPE_UNKNOWN;
		getWord_word_idx = -1;
		
		rInfo.resolve_op_meaning = OP_IS_UNKNOWN;
		rInfo.resolve_out_token  = "";
		rInfo.resolve_use_out    = false;
		
		rInfo.resolve_token_noun_data = NL_TYPE_UNKNOWN;
		rInfo.resolve_str = "";
		rInfo.resolve_float = 0.0;
		rInfo.resolve_int = 0;
		
		var n = 0;
		var word_name_lower = Strings.toLowerCase8( word_visible_name );
		while ( n < word_list.length )
		{
			if ( word_list[ n ] == word_visible_name )
				break;
			
			if ( Strings.toLowerCase8( word_list[ n ] ) == word_name_lower )
				break;
			
			n++;
		}

		if ( n < word_list.length )
		{
			comment( "Found the word" );
			getWord_word_idx = n;
			
			var word_type = type_list[ n ];
			
			if ( NL_OPERATOR == word_type )
			{
				comment( "", "Also this may be a Built In Verb name in a different language.", 
				"See  NLImport  importWords  for details.", "" );
				getWord_type = NL_OPERATOR;
				rInfo.resolve_use_out = true;
				
				comment( "Example in  importWords" ); 
				rInfo.resolve_str = value_list[ n ];
			}
			else
			if ( NL_NOUN == word_type )
			{
				getWord_type = NL_NOUN;
				rInfo.resolve_token_noun_data = NL_STR;		// May really be Bool, Int or Float also. Resolved elsewhere.
				rInfo.resolve_str = value_list[ n ];
			}
			else
			if ( NL_VERB == word_type )
			{
				getWord_type = NL_VERB;
				rInfo.resolve_str = value_list[ n ];
			}
			else
			if ( NL_CHOICE == word_type )
			{
				getWord_type = NL_CHOICE;
				rInfo.resolve_use_out = true;
			}
			else
			{
				error( "INTERNAL ERROR: Unexpected word type in getWord.", RED );
			}
			
			rInfo.resolve_out_token = built_in_list[ n ];
		}
		else
			ret_val = RET_IS_USER_ERROR_DATA;
		
		return ret_val;
	}
	
	
//		Change contents or Add a new word
//
	public var changeOrAddWord_changed = false;
	
	public var changeOrAddWord_msgs : String8 = "";

	public function changeOrAddWord( word_visible_name : String8, word_type : NLTypes, rInfo : ResolveInfo ) : ReturnMeanings
	{
		comment( "Change contents or Add a new word" );
		var ret_val = RET_IS_OK;
		
		changeOrAddWord_changed = false;
		changeOrAddWord_msgs = "";

		var get_rInfo = new ResolveInfo();

		var value : String8 = "";

		var idx = -1;
		
		// See if word is already known
		
		var getWord_result = getWord( word_visible_name, get_rInfo );
		
		if ( NL_VERB == word_type )
				value = rInfo.resolve_str;
		else
		if ( NL_NOUN == word_type )
		{
			if ( NL_STR == rInfo.resolve_token_noun_data )
			{
				value = rInfo.resolve_str;
				
				// Strings need Quotes around them
				if ( ( value.length8() < 2 )
				  || ( "\"" != value.charAt8( 0 ) )
				  || ( "\"" != value.charAt8( value.length8() - 1 ) ) )
				{
					value = "\"" + value + "\"";
				}
			}
			else
			if ( NL_FLOAT == rInfo.resolve_token_noun_data )
				value = Std.string( rInfo.resolve_float );
			else
			if ( NL_INT == rInfo.resolve_token_noun_data )
				value = Std.string( rInfo.resolve_int );
			else
			if ( NL_BOOL == rInfo.resolve_token_noun_data )
			{
				if ( 1 == rInfo.resolve_int )
					value = "true";
				else
					value = "false";
			}
			else
			{
				// Wrong Noun type !
				changeOrAddWord_msgs += "INTERNAL ERROR: Noun type not recognized: " + nlTypeAsStr( rInfo.resolve_token_noun_data ) + "\n";
				value = "0";
				ret_val = RET_IS_INTERNAL_ERROR;
			}
		}
		
		if ( 0 == cast( getWord_result, Int ) )
		{
			// Word is known, Change values as needed.
			changeOrAddWord_changed = true;
			var idx = getWord_word_idx;
			
			type_list[ idx ] = word_type;
			word_list[ idx ] = word_visible_name;
			
			if ( ( NL_OPERATOR == word_type )
			  || ( NL_CHOICE   == word_type ) )
				built_in_list[ idx ] = rInfo.resolve_out_token;
			else
				value_list[ idx ] = value;
		}
		else
		{
			// Add the word
			word_list.push( word_visible_name );

			type_list.push( word_type );

			if ( ( NL_OPERATOR == word_type )
			  || ( NL_CHOICE   == word_type ) )
			{
				built_in_list.push( rInfo.resolve_out_token );
				value = "";
			}
			else
			{
				// built_in_list.push( Strings.toLowerCase8( word_visible_name ) );
				built_in_list.push( "" );
			}
			
			value_list.push( value );
		}
		
		return ret_val;
	}
	
	
//		Save in memory Data to a File
//
// Pre Conditions:
//     Data was updated from latest Dictionary generation, Import or Interpreter actions on a Dictionary: 
//         Nouns, Verbs, alias words
//             OR
//     Data was updated directly by Interpreter: 
//         Write(s) of new values in a Data file
//
#if js
	public function saveData( new_path_name : String ) : ReturnMeanings
	{
		return RET_IS_NOT_IMPLEMENTED;
	}
	
#else
	public function saveData( new_path_name : String ) : ReturnMeanings
	{
		comment( "Save in memory Data to a File" );
		var ret_val = RET_IS_OK;
	try
	{
		var out_file = File.write( new_path_name, false );	// text mode
		
		var line : String8 = "";
		
		var word_idx      = -1;
		var word_type_idx = -1;
		var name_idx      = -1;
		var built_in_idx  = -1;
		var value_idx     = -1;
		var found_name    = false;
		
		var temp_name : String8 = "";
		var temp_type = NL_TYPE_UNKNOWN;
		var temp_built_in : String8 = "";
		var temp_value : String8 = "";

		var rInfo = new ResolveInfo();

		var words_to_do = getWordList( false );
		if ( 0 == words_to_do.length )
			return RET_IS_OK;

//	Change array of text lines in memory with latest values in memory
//
		var i = 0;
		while ( i < fileLines.length )
		{
			line = fileLines[ i ];
			if ( ( 0 == line.length8() )
			  || ( "#" == line.charAt8( 0 ) ) )
			{
				// Comment or Empty line
				i++;
				continue;
			}

			if ( "word_type" == Strings.left( line, 9 ) )
			{
				word_idx      = -1;
				name_idx      = -1;
				built_in_idx  = -1;
				value_idx     = -1;
				
				word_type_idx = i;
				getStr( line, true );
				temp_type = getStr_type;
			}
			else
			if ( "name" == Strings.left( line, 4 ) )
			{
				name_idx = i;
				temp_name = getStr( line );
				
				// Make sure the name matches
				var getWord_result = getWord( temp_name, rInfo );
				if ( 0 == cast( getWord_result, Int ) )
				{
					word_idx = getWord_word_idx;
					found_name = true;
				}

			}
			else
			if ( "built_in_name" == Strings.left( line, 13 ) )
			{
				built_in_idx = i;
				//temp_built_in = getStr( line );
			}
			else
			if ( "value" == Strings.left( line, 5 ) )
			{
				value_idx = i;
				// temp_value = getStrML( line, i );
			}
			else 
			{
				// other text lines
				i++;
				continue;
			}
			
			if ( ( 0 <= built_in_idx )
			  || ( 0 <= value_idx ) )
			{
				if ( found_name )
				{
					// [ word_idx ]  is correct source data to use

					if ( NL_OPERATOR == type_list[ word_idx ] )
						fileLines[ word_type_idx ] = "word_type = \"operator\"";
					else
					if ( NL_NOUN == type_list[ word_idx ] )
						fileLines[ word_type_idx ] = "word_type = \"noun\"";
					else
					if ( NL_VERB == type_list[ word_idx ] )
						fileLines[ word_type_idx ] = "word_type = \"verb\"";
					else
					if ( NL_CHOICE == type_list[ word_idx ] )
						fileLines[ word_type_idx ] = "word_type = \"choice\"";
					else
					{
						// INTERNAL ERROR
						
					}

					fileLines[ name_idx ] = "name = \"" + word_list[ word_idx ] + "\"";
					
					if ( ( NL_OPERATOR == type_list[ word_idx ] )
					  || ( NL_CHOICE   == type_list[ word_idx ] ) )
						fileLines[ built_in_idx ] = "built_in_name = \"" + built_in_list[ word_idx ] + "\"";
					else
						fileLines[ value_idx ] = "value = " + value_list[ word_idx ];

					words_to_do.remove( temp_name );
					temp_name = "";
					found_name = false;
				}
			}
			
			i++;
		}

	// Write out text lines to file
		i = 0;
		while ( i < fileLines.length )
		{
			line = fileLines[ i ];
			out_file.writeString( line + "\n" );
			i++;
		}

		out_file.flush();

	// Could be extra words not in original text file
		var word_name : String8 = "";
		var k = 0;
		i = 0;
		while ( i < words_to_do.length )
		{
			word_name = words_to_do[ i ];

			// Find index of the word
			k = 0;
			while ( k < word_list.length )
			{
				if ( word_name == word_list[ k ] )
				{
					word_idx = k;
					break;
				}
				k++;
			}
			
			if ( word_list.length <= k )
			{
				// INTERNAL ERROR: Expected word not found
				line = "# INTERNAL ERROR: Expected word " + words_to_do[ i ] + " not found." ;
				out_file.writeString( line + "\n" );
				i++;
				continue;
			}
			
			// add a blank line
			out_file.writeString( "\n" );
			
			// Add a toml Table name (called a Section name by forGL)
			line = "[_" + word_list[ word_idx ] + "_]";
			out_file.writeString( line + "\n" );
			
			line = "word_type = \"";
			if ( NL_OPERATOR == type_list[ word_idx ] )
				line += "operator\"";
			else
			if ( NL_NOUN == type_list[ word_idx ] )
				line += "noun\"";
			else
			if ( NL_VERB == type_list[ word_idx ] )
				line += "verb\"";
			else
			if ( NL_CHOICE == type_list[ word_idx ] )
				line += "choice\"";
			else
			{
				// INTERNAL ERROR  Put in a comment about it and Skip to next word
				line = "# INTERNAL ERROR: word " + word_list[ word_idx ] + " has invalid word_type : " + nlTypeAsStr( type_list[ word_idx ] );
				out_file.writeString( line + "\n" );
				i++;
				continue;
			}

			out_file.writeString( line + "\n" );
			
			line = "name = \"" + word_list[ word_idx ] + "\"";
			out_file.writeString( line + "\n" );
			
			if ( ( NL_NOUN == type_list[ word_idx ] )
			  || ( NL_VERB == type_list[ word_idx ] ) )
			{
				line = "value = " + value_list[ word_idx ];
			}
			else
			{
				line = "built_in_name = \"" + built_in_list[ word_idx ] + "\"";
			}

			out_file.writeString( line + "\n" );

			i++;
		}

		out_file.flush();
		out_file.close();
		
	}
	catch ( e:Dynamic ) 
	{  
		msg( "\nException in saveData(): " + Std.string( e ) + " \n");
		
	//#if !java
	//	Sys.getChar( false );
	//#end
	
		ret_val = RET_IS_INTERNAL_ERROR;
	};

		return ret_val;
	}
#end	
	
}
