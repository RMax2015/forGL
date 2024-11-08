/* Parse.hx	This is the low level Parser of forGL
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


// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

using hx.strings.ansi.AnsiColor;


// For now, assume UI is available

//using forGL.forGL_ui;
import forGL.UI.ForGL_ui.msg      as   msg;
import forGL.UI.ForGL_ui.error    as   error;
import forGL.UI.ForGL_ui.status   as   status;
import forGL.UI.ForGL_ui.getTypeColor   as   getTypeColor;

using  forGL.NLTypes;
import forGL.NLTypes.NLTypeAs.nlTypeAsStr    as  nlTypeAsStr;
import forGL.NLTypes.NLTypeAs.resolveType    as  resolveType;

import forGL.Meanings.OpMeanings;
import forGL.Meanings.ReturnMeanings;
import forGL.Meanings.MeansWhat.opMeanAsStr      as  opMeanAsStr;

import  forGL.Dictionary.NLDictionary;

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment    as    comment;

using forGL.Parse;

	
// 		Parse styles available
//
//  Parse styles have this program follow the Natural Language reading order
//      when reading text that is displayed for reading.
//
//  Top Down means:
//      Natural Language text is displayed as Horizontal lines.
//      IF there are 2 or more lines of Natural Language text
//          Then the first (top line as displayed) is read first.
//
//  Left to Right means:
//      Reading each Horizontal line starts from the Left and ends at the Right.
//
//  RIGHT to LEFT means:
//      Reading each Horizontal line starts from the RIGHT and ends at the LEFT.
//
//      Hebrew and Ararbic family of Natural Languages read RIGHT to LEFT.
//
//  MATH as a Language:
//
//		Reading is line oriented and Left to Right (like European languages)
//      for more see Wikipedia article
//
//		TODO: Support for Parsing Math style notation
//			Minimum should allow:
//				use of Parens and embedded Parens for grouping
//				use of built-in Haxe Math functions sin, cos, abs, ceil, floor, etc.
//

enum ParseStyle {

	// Top Down, Left to Right, Blank Space (or white space) is a separator
	// Used for European type languages and 
    PARSE_LEFT_TO_RIGHT;
	
	// Top Down, RIGHT to LEFT, 
    PARSE_RIGHT_TO_LEFT;
   
}


//
// Define a class for processing tokens
//
// Used as 1 element in Run stack array
class NLToken
{
	public var internal_token  : String8;	// as used internally
	public var visible_token   : String8;	// as seen in UI
	public var verbose_phrase  : String8;	// verbose expression of meaning
	public var token_str       : String8;	// Quoted string or calculated string
	public var token_float     : Float;		// resolved Float value if Float type
	public var token_type      : NLTypes;	// type: OP, Verb, Noun, float, int, string
	public var token_noun_data : NLTypes;   // token_type is Noun or Noun Local, 
											//   this is type of the Noun's data (string or int or float)
	public var token_int       : Int;		// resolved Integer value if Int type
	public var token_op_means  : OpMeanings;	// details of Operand to do
	
	public function new( internal_word : String8, visible_word : String8,
						verbose : String8,
						data_str : String8, data_float : Float,
						word_type : NLTypes, noun_data : NLTypes, 
						data_int : Int, op_means : OpMeanings ) 
	{
		internal_token  = internal_word;
		visible_token   = visible_word;
		verbose_phrase  = verbose;
		token_str       = data_str;
		token_float     = data_float;
		token_type      = word_type;
		token_noun_data = noun_data;
		token_int       = data_int;
		token_op_means  = op_means;
	}

//	public function new() 
//	{
		// Clear & Init  to Unk / Uninitialized
//		visible_token   = "";
//		internal_token  = "";
//		token_str       = "";
//		token_float     = 0.0;
//		token_type      = NL_TYPE_UNKNOWN;
//		token_noun_data = NL_TYPE_UNKNOWN;
//		token_int       = 0;
//		token_op_means  = OP_IS_UNKNOWN;
//	}
//    Same as  new( "","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN );
}

	
class  Parse
{
	public function new() 
	{
		
	}
	
	public function init()
	{
		
		
	}

//
//		Helper to do a possibly large amount of a definition
//
//  Pre Conditions
//		No Quoted strings to worry about
//
//
//  Post Conditions
//      returned array with added strings that represent tokens to resolve later
//
	public function strChunk( chunk : String8, 		// input to Parse
							prev : Array<String8>,  // previous Parsed input as Array of UTF8 strings
							style : ParseStyle,     // Going from Left to Right (or Right to Left, not implemented)
							?verbose : Bool = false ) : Array<String8>
	{
		comment( "", "    Helper to do a possibly large amount of a definition", 
				"",
				"Pre Conditions",
				"    No Quoted strings to worry about",
				"",
				"Post Conditions",
				"    returned array with added strings that represent tokens to resolve later", "" );

		var unChunks = new Array<String8>();		// return value
		
		var i = 0;
		var code = 0;
		var char = "";
		
		while ( i < prev.length )
		{
			unChunks.push( prev[ i ] );			// what has gone before
			i++;
		}
		
		var prev_char = "";
		var is_prev_num = false;
		var next = "";							// working string to mess with

		// Look for special handling needed. 
		// Insert Blank Space character(s) as wanted.
		var length = chunk.length8();
		i = 0;
		while ( i < length )
		{
			code = chunk.charCodeAt8( i );
			char = chunk.charAt8( i );
			
			if ( 0x20 <= code )
			{
				// normal Blank Space or visible character
				//
				// Check for Character(s) not allowed within a name of a Noun or Verb.
				// These characters already have specific meanings that do not change.
				//
				if ( is_prev_num )
				{
					//  Number of some kind.  0 to 9  use char codes here 
					if ( ( 0x30 <= code )
					  && ( code <= 0x39 ) )
					{
						next += char;
						prev_char = char;
						i++;
						continue;
					}
					else
					{
						// could be 0x or 0X prefix and 0123456789
						//     OR
						// Scientific notation: 1e2 or 1.2E-3
						//
						// so THIS character is only allowed to be x X - + e E or .
						
						if ( ( "." != char )
						  && ( "x" != char )
						  && ( "X" != char )
						  && ( "+" != char )
						  && ( "-" != char )
						  && ( "e" != char )
						  && ( "E" != char ) )
						{
							// Invalid character to be part of a number. Separate it
							//
							// TODO  maybe check for !  Factorial symbol here
							
							// Check for something previous like 5.  If so, insert another .
							if ( ( " " == char )
							  && ( "." == prev_char ) )
							{
								comment( "Remove trailing . and put in Blank and a ." );
								next = next.substr( 0, next.length - 1 );
								next += " ";
								next += ".";
							}

							is_prev_num = false;
							next += " ";
						}
						else
						{
							next += char;
							prev_char = char;
							i++;
							continue;
						}
					}
				}
				else
				if ( ( "0" <= char )
				  && ( char <= "9" ) )
				{
					// Starting a number.
					is_prev_num = true;
					
					if ( " " != prev_char )
						next += " ";
					next += char;
					prev_char = char;
					i++;
					continue;
				}
				
				var insert_blanks = true;
				var insert_str = char;
				switch ( char )
				{
					// TODO think about how to do Factorial like  5!  notation
					// can also be negation
					// could be !=
					case "!":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
					case "%":
						
					// could be &= or && also
					case "&":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "&" == char2 )
									{
										insert_str += "&";
										i++;
									}
									else
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
					case "(":
					case ")":
					
					// May be **  raise to a power
					case "*":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "*" == char2 )
									{
										insert_str += "*";
										i++;
									}
								}
					// May be ++  Increment
					case "+":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "+" == char2 )
									{
										insert_str += "+";
										i++;
									}
								}
					// May be Euro number like ,25  ? ? ?
					case ",":
						
						/* COMMENTED OUT FOR NOW.  NEEDS Testing !
								if ( i < length - 1 )
								{
									var char2 = parse_str.charAt( i + 1 );
									
									// See if next character is a numeral
									if ( ( "0" <= char2 ) && ( char2 <= "9" ) )
										insert_blanks = false;
								}
						*/
					

					
					case "-":
								// May be --  Decrement
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "-" == char2 )
									{
										insert_str += "-";
										i++;
									}
								}
								else
								{
								// may be a number like -5 or -.25		OR   5--7
								//
								//   TODO  COMMENT OUT this case for  Minus symbol to test why code in resolveType
								// produces a Float or Int with the token  5--7  when should be UNKNOWN
								//
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									
									// See if next character is a numeral
									if ( ( char2.isDigits() )
									  || ( "." == char2 ) )
										insert_blanks = false;
								}
								}  //  END  else

					// May be a number like .25
					case ".":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									
									// See if next character is a numeral
									if ( char2.isDigits() )
										insert_blanks = false;
								}
					case "/":
					
					// May be :=
					case ":":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
					case ";":
					
					// could be <= also
					case "<":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
								
					// could be == or =: also
					case "=":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
									else
									if ( ":" == char2 )
									{
										insert_str += ":";
										i++;
									}
								}
					// could be >= also
					case ">":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
					case "?":
					case "@":
					case "[":
					case "\\":
					case "]":
					case "^":
					case "'":
					case "{":
						
					// could be || or |= also
					case "|":
								if ( i < length - 1 )
								{
									var char2 = chunk.charAt8( i + 1 );
									if ( "|" == char2 )
									{
										insert_str += "|";
										i++;
									}
									else
									if ( "=" == char2 )
									{
										insert_str += "=";
										i++;
									}
								}
					case "}":
					
					// TODO  decide how to handle tilde character
					// case "~":
						
					default:
								insert_blanks = false;
				}
				
				if ( insert_blanks )
				{
					next += " " + insert_str + " ";
					prev_char = " ";
				}
				else
				{
					next += char;
					prev_char = char;
				}
			}
			else
			{
				// Check for CR (0x0D) or LF (0x0A) characters
				// If Carriage Return only change to Line Feed
				// If Carriage Return + Line Feed remove Carriage Return
				if ( 0x0D == code )
				{
					// Carriage Return. Check next character
					
					
				}
				else
				{
					
				}
				
				// Substitute a Blank Space for all non Printing characters below 0x20
				next += " ";
				prev_char = " ";
			}

			i++;
		}
		
		
		var io_tokens = next.split( " " );
	
		comment( "", "NOTE: split WILL return an EMPTY STRING if 2 or more Blank spaces are together. ",
		"Go through and remove any EMPTY strings", "" );

		i = 0;
		while ( i < io_tokens.length )
		{
			if ( 0 < io_tokens[ i ].length )
			{
				unChunks.push( io_tokens[ i ] );
			}
			
			i++;
		}
		
		return unChunks;
	}



// Given a simplified Natural Language text string:
// Return an array of text tokens that are in correct Natural Language reading order.
// Also set number of text lines added for any messages shown.
//
	public var parse_text_lines_added = 0;

	public function parse( in_lang_str : String8, style : ParseStyle, 
							?verbose : Bool = false ) : Array<String8>
	{
		comment( "", "Return an array of text tokens that are in correct Natural Language reading order.",
		"Also set number of text lines added for any messages shown.", "" );
		var ret_val = RET_IS_OK;
		parse_text_lines_added = 0;
		
		// Default values for Euro NL
		var scanning_top_to_bottom = true;
		var scanning_left_to_right = true;
		
		if ( PARSE_RIGHT_TO_LEFT == style )
			scanning_left_to_right = false;
		
		var no_empty = new Array<String8>();		// Results array

	try
	{
		// Parse step 1 produce a List of tokens 
		//       (1D Array access semantics)
		//
		// Lexer = task of this part of Parsing in most references
		// I just think mostly what can be easily extracted
		// 
		// List will be in natural language reading order
		var parse_str = in_lang_str;
		
		// TRIM characters as needed
		//
		// Honor embedded newlines
		// If Carriage Return only change to Line Feed
		// If Carriage Return + Line Feed remove Carriage Return
		// 
		// Remove any other character code below a Blank Space
		// 
		
		// var trimmed_str = "";
		var length = parse_str.length8();
		
		/*  COMMENTED  OUT   use if something strange happens to the simple parser output
		 * This was to make sure that 0x0D is CR and 0x0A is LF ... not needed now?
		 * 
		var code_CR = "\r".charCodeAt(0);
		
		if ( verbose )
			msg( "code for CR is " + String.fromCharCode( code_CR ) + "\n" );
			
		if ( 0x0D != code_CR )
		{
			msg( "code for CR is NOT 0x0D \n" );
		}
		
		var new_line = "\n";
		var code_NL_0 = new_line.charCodeAt(0);
		
		if ( verbose )
			msg( "code for new line 0 is " + String.fromCharCode( code_NL_0 ) + "\n" );
		
		if ( 1 < new_line.length )
		{
			var code_NL_1 = new_line.charCodeAt(1);
			
			if ( verbose )
				msg( "code for new line 1 is " + String.fromCharCode( code_NL_1 ) + "\n" );
		}
		END  OF  COMMENTED  OUT  */
		
		
		
		if ( scanning_left_to_right )
		{
			var i = 0;
			var char = "";
			var str_chunk  : String8 = "";		// Everything except Quoted strings
			var quoted_str : String8 = "";
			var string_depth = 0;	// depth of Quoted strings
			
			while ( i < length )
			{
				//code = parse_str.charCodeAt( i );
				char = parse_str.charAt8( i );
				
				if ( "\"" == char )
				{
					if ( 0 == string_depth )
					{
						// Starting a Quoted string
						// Process what was found before Quoted string
						
						if ( 0 < str_chunk.length8() )
						{
							no_empty = strChunk( str_chunk, no_empty, style, verbose );
							
						//	msg( Std.string( no_empty ) + "\n");
						//	var char_code = Sys.getChar( false );
												
							str_chunk = "";
						}
						
						// Starting a Quoted string
						string_depth++;
						quoted_str = "\"";
					}
					else
					{
						// Ending a Quoted string
						string_depth--;

						if ( 0 == string_depth )
						{
							quoted_str += "\"";
							no_empty.push( quoted_str );
							quoted_str = "";
						}
					}

					i++;
					continue;
				}

				if ( 0 != string_depth )
				{
					// Keep Quoted strings unchanged
					quoted_str += char;
				}
				else
					str_chunk += char;
					
				i++;
			}
			
			if ( 0 < str_chunk.length8() )
			{
				no_empty = strChunk( str_chunk, no_empty, style, verbose );
									
				str_chunk = "";
			}

		}
		else
		{
			// Scanning RIGHT to LEFT
			//
			// MATH remains Left to Right
			//
			// TODO: Implement and test.
			//
			// Test ideas: Use regular English (that works already) with reverse order.
			// Start with a single line of English and see how that goes.
			
			error( "INTERNAL ERROR: Parse style Right to Left not implemented. \n" );
			parse_text_lines_added++;
			ret_val = RET_IS_NOT_IMPLEMENTED;
			verbose = true;
			
			return new Array<String8>();
		}
		
		
		if ( 0 == no_empty.length )
		{
			error( "ERROR: Nothing to parse. \n" );		// Unrecoverable Error. User to fix.
			parse_text_lines_added++;
			ret_val = RET_IS_USER_ERROR_DATA;
			verbose = true;
			return no_empty;
		}
		
		if ( verbose )
		{
			msg( "\nOriginal definition:\n" );
			parse_text_lines_added++;
			parse_text_lines_added++;
			msg( parse_str + "\n" );
			parse_text_lines_added++;
			msg( no_empty.length + " tokens found\n" );
			parse_text_lines_added++;
			msg( Std.string( no_empty ) + "\n");

		#if ( !java && !js )
			// Wait for User to hit a key.
			var char_code = Sys.getChar( false );
		#end
		}
		
	}
	catch ( e:Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in Parse.parse(): " + Std.string( e ) + " \n");
		
		// ret_val = RET_IS_INTERNAL_ERROR;
	};	
		
		return no_empty;
	}
	


//		Resolve the Meanings of the Tokens
//
	public var resolve_similar_word : String8 = "";
	public var left_groups  = 0;
	public var right_groups = 0;
	public var repeat_verb_found = false;

	public function resolveTokens( tokens : Array<String8>, nlDict : NLDictionary, 
									runStack : Array<NLToken>, ?verbose = false ) : Int
	{
		comment( "Resolve the Meanings of the Tokens" );
		var lines_added = 0;
		resolve_similar_word = "";
		var append_offset = runStack.length;	// support to have a Verb run from inside current verb
		
		left_groups  = 0;
		right_groups = 0;
		repeat_verb_found = false;

		var ri = new ResolveInfo();
		
		var type_found = NL_TYPE_UNKNOWN;
		var i = 0;
		
		var dictIdx = -1;
		
		var token       : String8 = "";
		var token_lower : String8 = "";
		
	try
	{
		
	#if !java
		// Allow answers for replace with similar word to be easier for User.
		var prev_replace : String8 = "";	// was Replaced by similar word
		var no_replace   : String8 = "";	// Do not replace this
	#end

		var a_token = new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN );
		
		var runIdx = append_offset;
		
		var prev_internal_token : String8 = "";
		
		while ( i < tokens.length )
		{
			runIdx = append_offset + i;
			token = tokens[i];
			
			token_lower = Strings.toLowerCase8( token );
			
//	Dictionary search
//
			dictIdx = nlDict.findWord( token );
			if ( dictIdx < 0 )
			{
				// NOT Found in Dictionary
				// Use Built in switch / case for alternate words. 
				//     Ex:  into  from  are both Assignment  =  with a given direction
				// Side Effects: resolveType also produces extra information based on type returned
				type_found = resolveType( token, ri, verbose );
				
		// No Java support for getChar
			#if ( !java && !js )
			
				var ask_similar = true;
				
				if ( NL_TYPE_UNKNOWN == type_found )
				{
					// Perhaps a  Local  Noun
					if ( "=:" == prev_internal_token ) 	// into Assignment operator (L to R)
					{
						// INFERENCE This is a  Local Noun
						type_found = NL_NOUN_LOCAL;
					}
					else
					{
						// See if this was already known earlier in this definition
						// 1 way is to scan from start to find same name.
						
						// is_local_name = nameFound( token_lower )
						// if ( True == is_local_name )
						//
						// FOR NOW just allow Spelling mistakes to 
						// go through until later Run time Error.
						type_found = NL_NOUN_LOCAL;
					}
			
				}
				
				if ( NL_NOUN_LOCAL == type_found )
				{
					// Do Not ask User about any Similar words for this  INFERRENCE  Local Noun.
					ask_similar = false;
				}
				
				if ( ( ask_similar )
				  && ( NL_TYPE_UNKNOWN == type_found )
				  && ( 1 < token_lower.length ) )	// Below not effective for single character unknowns
				{
					// Not found. Try to find a similar word
					var similarWord = nlDict.findSimilar( token_lower );
					if ( 0 < similarWord.length )
					{
						var newline_needed = false;
						if ( ( token_lower != prev_replace )
						  && ( token_lower != no_replace ) )
						{
							// May be a typing or spelling mistake. Ask User.
							msg( token_lower + "  was not found. Use  " + similarWord + "  instead (y/n)? " );

							var ans_done = false;
							while ( !ans_done )
							{
								var char_code = Sys.getChar( true );
								if ( ( 0x0D == char_code ) || ( 0x0A == char_code ) )	// \r or \n ?
								{
									break;
								}
							
								if ( ( 0x59 == char_code )		// Y or y
								  || ( 0x79 == char_code ) )
								{
									comment( "User has selected another SIMILAR Word to run here.", "" );
									prev_replace = token_lower;
									token_lower = similarWord;
									resolve_similar_word = similarWord;
									token = token_lower;
									dictIdx = nlDict.findWord( token );
									newline_needed = true;
									break;
								}
								else
								if ( ( 0x4e == char_code )		// N or n
								  || ( 0x6e == char_code ) )
								{
									no_replace = token_lower;
									newline_needed = true;
									break;
								}
							}
						}
						else
						{
							if ( token_lower == prev_replace )
							{
								// User already allowed this similar word.
								token_lower = similarWord;
								token = token_lower;
								dictIdx = nlDict.findWord( token );
							}
						}

						if ( newline_needed )
						{
							msg( "\n" );
							lines_added++;
						}
					}
				}
			#end
			}
			
			if ( 0 <= dictIdx )
			{
				type_found = nlDict.unique_Dictionary_Words[ dictIdx ].token_type;
				
				ri.resolve_str   = nlDict.unique_Dictionary_Words[ dictIdx ].token_str;
				ri.resolve_float = nlDict.unique_Dictionary_Words[ dictIdx ].token_float;
				ri.resolve_int   = nlDict.unique_Dictionary_Words[ dictIdx ].token_int;
				ri.resolve_op_meaning = nlDict.unique_Dictionary_Words[ dictIdx ].token_op_means;
				ri.resolve_token_noun_data = nlDict.unique_Dictionary_Words[ dictIdx ].token_noun_data;
				
				ri.resolve_use_out = true;
				ri.resolve_out_token = nlDict.unique_Dictionary_Words[ dictIdx ].internal_token;
				
			// Adjust as needed between Dictionary layer and Interpreter
			//
			//		Support for Math and Euro Languages
				if ( OP_IS_PAREN_LEFT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_EXPRESSION_START;
				else
				if ( OP_IS_PAREN_RIGHT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_EXPRESSION_END;
				else
				if ( OP_IS_BRACKET_LEFT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_LIST_START;
				else
				if ( OP_IS_BRACKET_RIGHT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_LIST_END;
				else
				if ( OP_IS_BRACE_LEFT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_BLOCK_START;
				else
				if ( OP_IS_BRACE_RIGHT == ri.resolve_op_meaning )
					ri.resolve_op_meaning = OP_IS_BLOCK_END;
			}

		comment( "Set defaults" );
			a_token.internal_token  = token;
			a_token.visible_token   = token;
			a_token.verbose_phrase  = token;
			a_token.token_str       = "";
			a_token.token_type      = type_found;
			a_token.token_noun_data = NL_TYPE_UNKNOWN;
			a_token.token_float     = 0.0;
			a_token.token_int       = 0;
			a_token.token_op_means  = OP_IS_UNKNOWN;
			
			if ( type_found == NL_INT )
				a_token.token_int = ri.resolve_int;
			else
			if ( type_found == NL_BOOL )
				a_token.token_int = ri.resolve_int;
			else
			if ( type_found == NL_OPERATOR )
			{
				a_token.token_op_means = ri.resolve_op_meaning;
				if ( ( OP_IS_EXPRESSION_START == a_token.token_op_means )
				  || ( OP_IS_LIST_START       == a_token.token_op_means )
				  || ( OP_IS_BLOCK_START      == a_token.token_op_means ) )
					left_groups++;
				else
				if ( ( OP_IS_EXPRESSION_END == a_token.token_op_means )
				  || ( OP_IS_LIST_END       == a_token.token_op_means )
				  || ( OP_IS_BLOCK_END      == a_token.token_op_means ) )
					right_groups++;
			}
			else
			if ( type_found == NL_NOUN )
			{
				comment( "Set up the Noun data found" );
				a_token.token_noun_data = ri.resolve_token_noun_data;
				if ( NL_INT == ri.resolve_token_noun_data )
					a_token.token_int = ri.resolve_int;
				else
				if ( NL_BOOL == ri.resolve_token_noun_data )
					a_token.token_int = ri.resolve_int;
				else
				if ( NL_FLOAT == ri.resolve_token_noun_data )
					a_token.token_float = ri.resolve_float;
				else
				if ( NL_STR == ri.resolve_token_noun_data )
					a_token.token_str = ri.resolve_str;
				else
				{
					msg( "INTERNAL ERROR: Strange value for  resolve_token_noun_data : " + Std.string( ri.resolve_token_noun_data ) + "\n");
					lines_added++;
				}
			}
			else
			if ( type_found == NL_FLOAT )
				a_token.token_float = ri.resolve_float;
			else
			if ( type_found == NL_STR )
				a_token.token_str = ri.resolve_str;
			else
			if ( type_found == NL_VERB )
				a_token.token_str = ri.resolve_str;

				
			// Other types found do not need more handling here
				
			if ( ri.resolve_use_out )
				a_token.internal_token = ri.resolve_out_token;
			
			// Check for Built In Verbs that need some support
			// TODO  use string(s) from Dictionary
			if ( ( "repeat" == a_token.internal_token ) && ( NL_VERB_BI == a_token.token_type ) )
				repeat_verb_found = true;

			// Allocate and save a new class instance to hold this token's details
			runStack.push( new NLToken( a_token.internal_token, a_token.visible_token, 
										a_token.verbose_phrase, a_token.token_str, 
										a_token.token_float, a_token.token_type, a_token.token_noun_data,
										a_token.token_int, a_token.token_op_means) );
			
			prev_internal_token = a_token.internal_token;
			i++;

		} // END of Resolve token meanings pass through the tokens
		
		
	}
	catch ( e:Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in Parse.resolveTokens(): " + Std.string( e ) + " \n");
		
		lines_added++;
	};	
		
		return lines_added;
	}


//		Resolve (indeterminate) Assigns to be either  Assign From  or  Assign Into
//
public function resolveAssigns( runStack : Array<NLToken> )
	{
		comment( "", 
		"Resolve (indeterminate) Assigns to be either  Assign From  or  Assign Into",
		"This only changes the Assign type to  From  or  Into  with no other changes",
		"", 
		"Look for any indeterminate Assignment.", 
		"IF found, see which side has the most terms.",
		"IF each side has only 1 term THEN the side with a Data value must be Source",
		"The side with 2 or more terms MUST be the Source side",
		"IF one side has only 1 term THEN it must be the Assign Destination",
		"",
		"Below are combinations Difficult to Resolve here. Interpreter will Resolve later.",
		"IF both sides have only 1 term AND both are Noun or Local Noun then Interpreter will Resolve.", 
		"Interpreter also will Resolve UNKNOWN type to Local Noun later.", "" );

		var i = 0;
		var assignment_count = 0;
		var statement_start  = 0;
		var statement_end    = -1;
		var assign_pos       = -1;

		while ( i < runStack.length )
		{
			if ( NL_OPERATOR == runStack[ i ].token_type )
			{
				var op_found = runStack[ i ].token_op_means;
				
				if ( OP_IS_BLOCK_START == op_found )
				{
					statement_start = i + 1;
					i++;
					continue;
				}
				
				if ( ( OP_IS_PERIOD    == op_found )
				  || ( OP_IS_COMMA     == op_found )
				  || ( OP_IS_COLON     == op_found )
				  || ( OP_IS_SEMICOLON == op_found )
				  || ( OP_IS_BLOCK_END == op_found ) )
				{
					statement_end = i;
					if ( -1 == assign_pos )
					{
						comment( "No indeterminate Assignment found, so go on." );
						statement_start = statement_end + 1; // Next statement first Token
						statement_end = -1;
						i++;
						continue;
					}
					else
					if ( assign_pos == statement_start )
					{
						comment( "Nothing on Left so this is Assign Into." );
						
						runStack[ assign_pos ].token_op_means = OP_IS_ASSIGN_TO;
						runStack[ assign_pos ].internal_token = opMeanAsStr( OP_IS_ASSIGN_TO, true );

						assign_pos = -1;
						statement_start = statement_end + 1; // Next statement first Token
						statement_end = -1;
						i++;
						continue;
					}

					comment( "", "Count number of Tokens before and after the Assign position.",
					"IF each side has only 1 term THEN the side with a Data value must be Source",
					"OR The side with the most is the source.", "" );
					var left_count  = assign_pos - statement_start;
					var right_count = statement_end - assign_pos - 1; // minus 1 for ending Punctuation or } 
					
					if ( ( 1 ==  left_count )
					  && ( 1 == right_count ) )
					{
						comment( "",
						"IF each side has only 1 term THEN the side with a Data value must be Source", "" );
						var  left_type = runStack[ assign_pos - 1 ].token_type;
						var right_type = runStack[ assign_pos + 1 ].token_type;
						
						if ( ( NL_STR   == left_type )
						  || ( NL_INT   == left_type )
						  || ( NL_BOOL  == left_type )
						  || ( NL_FLOAT == left_type ) )
						{
							comment( "", "Left side is Source so this is Assign INTO", "" );
							runStack[ assign_pos ].token_op_means = OP_IS_ASSIGN_TO;
							runStack[ assign_pos ].internal_token = opMeanAsStr( OP_IS_ASSIGN_TO, true );
						}
						else
						if ( ( NL_STR   == right_type )
						  || ( NL_INT   == right_type )
						  || ( NL_BOOL  == right_type )
						  || ( NL_FLOAT == right_type ) )
						{
							comment( "", "Right side is Source so this is Assign FROM", "" );
							runStack[ assign_pos ].token_op_means = OP_IS_ASSIGN_FROM;
							runStack[ assign_pos ].internal_token = opMeanAsStr( OP_IS_ASSIGN_FROM, true );
						}
						comment( "Otherwise fall through, leave alone and Interpreter will Resolve." );
					}
					else
					if ( ( left_count != right_count )
					  && ( ( 1 ==  left_count )
					    || ( 1 == right_count ) ) )
					{
						comment( "The side with the most is the source.",
						"NEEDS TESTING !", "" );
						
						if ( 1 == left_count )
						{
							runStack[ assign_pos ].token_op_means = OP_IS_ASSIGN_FROM;
							runStack[ assign_pos ].internal_token = opMeanAsStr( OP_IS_ASSIGN_FROM, true );
						}
						else
						{
							runStack[ assign_pos ].token_op_means = OP_IS_ASSIGN_TO;
							runStack[ assign_pos ].internal_token = opMeanAsStr( OP_IS_ASSIGN_TO, true );
						}
					}
					comment( "Otherwise fall through, leave alone and Interpreter will Resolve." );

					assign_pos = -1;
					statement_start = statement_end + 1; // Next statement first Token
					statement_end = -1;
				}
				else
				if ( OP_IS_ASSIGNMENT == op_found )
				{
					assignment_count++;		// Helps with Debugging perhaps
					assign_pos = i;
				}
			}

			i++;
		}

		return;
	}

	
//		Change to more of a style used by various programming languages
//
	public function refactorForExport( runStack : Array<NLToken> ) : Array<NLToken>
	{
		comment( "", "Change to more of a style used by various programming languages",
		"This is a step towards making  Export as Code  easier to implement elsewhere.", "",
		"Change Punctuation to be a Semicolon (typical programming language statement end)",
		"Rearrange any  Assignments Into  to be  Assignments From",
		"Rearrange any  Assignments       to be  Assignments From", 
		"",
		"* Change to Infix form for simple Math Operators  + - / * ^ ", 
		"* Change to call( ) form for Math functions and Verbs", 
		"*  =  Done later at runtime or Export time by Interpreter", "");
		
		var retArray = new Array<NLToken>();
		
		var i = 0;
		var into_assignment_count = 0;
		var assignment_count = 0;
		var changes_done = false;
		
		comment( "", "Change Punctuation to Semicolon can be done without needing a new Array", "" );
		while ( i < runStack.length )
		{
			if ( NL_OPERATOR == runStack[ i ].token_type )
			{
				var op_found = runStack[ i ].token_op_means;
				
				if ( ( OP_IS_PERIOD    == op_found )
				  || ( OP_IS_COMMA     == op_found )
				  || ( OP_IS_COLON     == op_found ) )
				//  || ( OP_IS_SEMICOLON == op_found ) )
				{
					runStack[ i ].token_op_means = OP_IS_SEMICOLON;
					runStack[ i ].internal_token = opMeanAsStr( OP_IS_SEMICOLON, true );
					runStack[ i ].visible_token  = runStack[ i ].internal_token;
					changes_done = true;
				}
				
				if ( OP_IS_ASSIGN_TO == op_found )
					into_assignment_count++;
					
				if ( OP_IS_ASSIGNMENT == op_found )
					assignment_count++;
			}
			
			i++;
		}
		
		if ( ( 0 < into_assignment_count )
		  || ( 0 < assignment_count ) )
		{
			var added_count = 0;
			var statement_start = 0;
			var statement_end   = 0;
			var assign_pos      = -1;
			var assign_type     = OP_IS_UNKNOWN;

		comment( "", "Go forward until a Semicolon or } (Statement end) is found.", 
			"Find any  Assignment  or  Assign To  Operators to change", 
			"It is possible that NO Assignment statement is found.",
			"A value may be added on the Data stack or", 
			"removed from the Data stack without explicit assignment.", "" );

			i = 0;
			while ( i < runStack.length )
			{
				if ( NL_OPERATOR == runStack[ i ].token_type )
				{
					var op_found = runStack[ i ].token_op_means;
					if ( ( OP_IS_SEMICOLON == op_found )
					  || ( OP_IS_BLOCK_END == op_found ) )
					{
						var insert_semicolon = false;
						if ( OP_IS_BLOCK_END == op_found )
							insert_semicolon = true;
						
						statement_end = i;			// either SEMICOLON or } block end
						var j = statement_start;
				
						if ( ( assign_pos < 0 )
						  || ( OP_IS_ASSIGN_FROM == assign_type ) 
						  || ( assign_pos == statement_start ) )	// First may be  Assign Into  skip for now
						{
							comment( "", "No Assignment OR already Assign From, just Copy the elements.", "" );

							while ( j <= statement_end )
							{
								retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
								var idx = retArray.length - 1;

								if ( ( j == statement_end )
								  && ( insert_semicolon ) )
								{
									comment( "Insert a Semicolon" );
									added_count++;

									retArray[ idx ].visible_token   = opMeanAsStr( OP_IS_SEMICOLON, true );
									retArray[ idx ].token_type      = NL_OPERATOR;
									retArray[ idx ].internal_token  = opMeanAsStr( OP_IS_SEMICOLON, true );
									retArray[ idx ].token_noun_data = NL_TYPE_UNKNOWN;
									retArray[ idx ].token_str       = "";
									retArray[ idx ].token_float     = 0.0;
									retArray[ idx ].token_int       = 0;
									retArray[ idx ].token_op_means  = OP_IS_SEMICOLON;
									
									retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
									idx = retArray.length - 1;
								}
								
								retArray[ idx ].visible_token   = runStack[ j ].visible_token;
								retArray[ idx ].token_type      = runStack[ j ].token_type;
								retArray[ idx ].internal_token  = runStack[ j ].internal_token;
								retArray[ idx ].token_noun_data = runStack[ j ].token_noun_data;
								retArray[ idx ].token_str       = runStack[ j ].token_str;
								retArray[ idx ].token_float     = runStack[ j ].token_float;
								retArray[ idx ].token_int       = runStack[ j ].token_int;
								retArray[ idx ].token_op_means  = runStack[ j ].token_op_means;
								
								j++;
							}
							
							statement_start = statement_end + 1;
							assign_pos  = -1;
							assign_type = OP_IS_UNKNOWN;
							i++;
							continue;
						}
						else
						{
						//	comment( "", "Count number of Tokens before and after the Assign position",
						//	"Change so that the most are on the Right side. (later in the Array)", "" );
						//	var left_count  = assign_pos - statement_start;
						//	var right_count = statement_end - assign_pos - 1;
							
							comment( "", "Copy the Right side in original to be the Left side in the new", "" );
							j = assign_pos + 1;
							while ( j < statement_end )
							{
								retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
								var idx = retArray.length - 1;

								retArray[ idx ].visible_token   = runStack[ j ].visible_token;
								retArray[ idx ].token_type      = runStack[ j ].token_type;
								retArray[ idx ].internal_token  = runStack[ j ].internal_token;
								retArray[ idx ].token_noun_data = runStack[ j ].token_noun_data;
								retArray[ idx ].token_str       = runStack[ j ].token_str;
								retArray[ idx ].token_float     = runStack[ j ].token_float;
								retArray[ idx ].token_int       = runStack[ j ].token_int;
								retArray[ idx ].token_op_means  = runStack[ j ].token_op_means;
								
								j++;
							}
							
							comment( "", "Now do the  Assign From  Operator", "" );
							retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
							var idx = retArray.length - 1;

							retArray[ idx ].visible_token   = opMeanAsStr( OP_IS_ASSIGN_FROM, true );
							retArray[ idx ].token_type      = NL_OPERATOR;
							retArray[ idx ].internal_token  = retArray[ idx ].visible_token;
							retArray[ idx ].token_noun_data = NL_TYPE_UNKNOWN;
							retArray[ idx ].token_str       = "";
							retArray[ idx ].token_float     = 0;
							retArray[ idx ].token_int       = 0;
							retArray[ idx ].token_op_means  = OP_IS_ASSIGN_FROM;
							
							comment( "", "Copy the Left side in original to be the Right side in the new", "" );
							j = statement_start;
							while ( j < assign_pos )
							{
								retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
								var idx = retArray.length - 1;

								retArray[ idx ].visible_token   = runStack[ j ].visible_token;
								retArray[ idx ].token_type      = runStack[ j ].token_type;
								retArray[ idx ].internal_token  = runStack[ j ].internal_token;
								retArray[ idx ].token_noun_data = runStack[ j ].token_noun_data;
								retArray[ idx ].token_str       = runStack[ j ].token_str;
								retArray[ idx ].token_float     = runStack[ j ].token_float;
								retArray[ idx ].token_int       = runStack[ j ].token_int;
								retArray[ idx ].token_op_means  = runStack[ j ].token_op_means;
								
								j++;
							}
							
							comment( "", "Add the ending Semicolon", "" );
							retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
							var idx = retArray.length - 1;

							retArray[ idx ].visible_token   = opMeanAsStr( OP_IS_SEMICOLON, true );
							retArray[ idx ].token_type      = NL_OPERATOR;
							retArray[ idx ].internal_token  = retArray[ idx ].visible_token;
							retArray[ idx ].token_noun_data = NL_TYPE_UNKNOWN;
							retArray[ idx ].token_str       = "";
							retArray[ idx ].token_float     = 0;
							retArray[ idx ].token_int       = 0;
							retArray[ idx ].token_op_means  = OP_IS_SEMICOLON;
							
							if ( insert_semicolon )
							{
								comment( "", "Now do the  Block End  character", "" );
								added_count++;

								retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
								idx = retArray.length - 1;
								
								retArray[ idx ].visible_token   = opMeanAsStr( OP_IS_BLOCK_END, true );
								retArray[ idx ].token_type      = NL_OPERATOR;
								retArray[ idx ].internal_token  = retArray[ idx ].visible_token;
								retArray[ idx ].token_noun_data = NL_TYPE_UNKNOWN;
								retArray[ idx ].token_str       = "";
								retArray[ idx ].token_float     = 0;
								retArray[ idx ].token_int       = 0;
								retArray[ idx ].token_op_means  = OP_IS_BLOCK_END;
							}
							
							statement_start = statement_end + 1;
							assign_pos  = -1;
							assign_type = OP_IS_UNKNOWN;
							i++;
							continue;
						}
					}
					else
					if ( ( OP_IS_ASSIGNMENT  == op_found )
					  || ( OP_IS_ASSIGN_TO   == op_found )
					  || ( OP_IS_ASSIGN_FROM == op_found ) )
					{
						comment( "", "Skip over if  Assign Into  is at beginning. Implies Data stack use.", "" );
						if ( ( OP_IS_ASSIGN_TO   == op_found )
						  && ( i == statement_start ) )
						{
							assign_pos  = -1;
							assign_type = OP_IS_UNKNOWN;
							i++;
							continue;
						}
						assign_pos  = i;
						assign_type = op_found;
					}
					else
					if ( ( "{" == runStack[ i ].internal_token )
					  || ( "}" == runStack[ i ].internal_token ) )
					{
						retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
						var idx = retArray.length - 1;

						retArray[ idx ].visible_token   = runStack[ i ].visible_token;
						retArray[ idx ].token_type      = runStack[ i ].token_type;
						retArray[ idx ].internal_token  = runStack[ i ].internal_token;
						retArray[ idx ].token_noun_data = runStack[ i ].token_noun_data;
						retArray[ idx ].token_str       = runStack[ i ].token_str;
						retArray[ idx ].token_float     = runStack[ i ].token_float;
						retArray[ idx ].token_int       = runStack[ i ].token_int;
						retArray[ idx ].token_op_means  = runStack[ i ].token_op_means;
						
						statement_start = i + 1;
					}
					
				}
				else
				if ( NL_CHOICE == runStack[ i ].token_type )
				{
					if ( ( "for"    == runStack[ i ].internal_token )
					  || ( "if"     == runStack[ i ].internal_token )
					  || ( "switch" == runStack[ i ].internal_token )
					  || ( "while"  == runStack[ i ].internal_token ) )
					{
						comment( "", "Skip the Choice and the following ( expression )", "" );
						
						var j = i;
						while ( j < runStack.length )
						{
							retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
							var idx = retArray.length - 1;

							retArray[ idx ].visible_token   = runStack[ j ].visible_token;
							retArray[ idx ].token_type      = runStack[ j ].token_type;
							retArray[ idx ].internal_token  = runStack[ j ].internal_token;
							retArray[ idx ].token_noun_data = runStack[ j ].token_noun_data;
							retArray[ idx ].token_str       = runStack[ j ].token_str;
							retArray[ idx ].token_float     = runStack[ j ].token_float;
							retArray[ idx ].token_int       = runStack[ j ].token_int;
							retArray[ idx ].token_op_means  = runStack[ j ].token_op_means;
							
							if ( ")" == runStack[ j ].internal_token )
							{
								statement_start = j + 1;
								break;
							}
							
							j++;
						}
						
						i = j + 1;
						continue;
					}
				}
					
				i++;
			}
			
			if ( retArray.length - added_count < runStack.length )
			{
				comment( "", "Copy the last few not already done", "" );
				
				var j = statement_start;
				while ( j < runStack.length )
				{
					retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
					var idx = retArray.length - 1;

					retArray[ idx ].visible_token   = runStack[ j ].visible_token;
					retArray[ idx ].token_type      = runStack[ j ].token_type;
					retArray[ idx ].internal_token  = runStack[ j ].internal_token;
					retArray[ idx ].token_noun_data = runStack[ j ].token_noun_data;
					retArray[ idx ].token_str       = runStack[ j ].token_str;
					retArray[ idx ].token_float     = runStack[ j ].token_float;
					retArray[ idx ].token_int       = runStack[ j ].token_int;
					retArray[ idx ].token_op_means  = runStack[ j ].token_op_means;
					
					j++;
				}
			}

			if ( ( opMeanAsStr( OP_IS_BLOCK_END, true ) != retArray[ retArray.length - 1 ].internal_token )
			  && ( opMeanAsStr( OP_IS_SEMICOLON, true ) != retArray[ retArray.length - 1 ].internal_token ) )
			{
				comment( "Last is a Semicolon if NOT a  Block End  character" );
				retArray.push( new NLToken( "","","","",0.0,NL_TYPE_UNKNOWN,NL_TYPE_UNKNOWN,0,OP_IS_UNKNOWN ) );
				var idx = retArray.length - 1;

				retArray[ idx ].visible_token   = opMeanAsStr( OP_IS_SEMICOLON, true );
				retArray[ idx ].token_type      = NL_OPERATOR;
				retArray[ idx ].internal_token  = retArray[ idx ].visible_token;
				retArray[ idx ].token_noun_data = NL_TYPE_UNKNOWN;
				retArray[ idx ].token_str       = "";
				retArray[ idx ].token_float     = 0;
				retArray[ idx ].token_int       = 0;
				retArray[ idx ].token_op_means  = OP_IS_SEMICOLON;
			}
		}
		else
			retArray = runStack;

		return retArray;
	}


//		Resolve settings needed internally by Choice (control flow) tokens
//
//  Pre Conditions:
//      for, if, switch, while  all require ( conditional expression ) to follow immediately
//
	public var resolveChoice_msgs = "";

	public function resolveChoice( rStack : Array<NLToken> ) : ReturnMeanings
	{
		comment( "Resolve settings needed internally by Choice (control flow) tokens" );
		var ret_val = RET_IS_OK;
		
		resolveChoice_msgs = "";
		
		var is_balanced = false;
		var choice_found = "";
		var end_paren_idx = -1;
		var end_block_idx = -1;
		
		var else_found = false;
		var else_start = -1;
		var else_end   = -1;
		
		// Scan for any starting Choice tokens
		var i = 0;
		while ( i < rStack.length )
		{
			choice_found = "";
			else_found = false;
			
			if ( ( "for"    == rStack[ i ].internal_token )
			  || ( "if"     == rStack[ i ].internal_token )
			  || ( "switch" == rStack[ i ].internal_token )
			  || ( "while"  == rStack[ i ].internal_token )
			  || ( "return" == rStack[ i ].internal_token ) )
			{
				choice_found = rStack[ i ].internal_token;
				
				if ( "return" == choice_found )
				{
					// User wants to exit the running Verb. This will be done by Interpreter
					i++;
					continue;
				}
			}
			else
			{
				i++;
				continue;
			}
			
			// Choice token found, are Grouping counts balanced?
			if ( ! is_balanced )
			{
				if ( ( left_groups != right_groups )
				  || ( 0 == left_groups ) )
				{
					// Error message done elsewhere.
					return RET_IS_USER_ERROR_SYNTAX;
				}
				
				is_balanced = true;
			}
			
			if ( ( rStack.length - 4 ) < i )	// ( true ) return   is minimum of 4.
			{
				resolveChoice_msgs += "SYNTAX ERROR: " + choice_found + " missing ( expression ) or statement.\n";
				return RET_IS_USER_ERROR_SYNTAX;
			}
			
			if ( "(" != rStack[ i + 1 ].internal_token )
			{
				resolveChoice_msgs += "SYNTAX ERROR: " + choice_found + " ( expression ) not next.\n";
				return RET_IS_USER_ERROR_SYNTAX;
			}
			
			// Scan forward to find ending )
			// Allow nesting of left and right Parens.
			var left_parens = 0;
			var right_parens = 0;
			var p = i + 2;
			while ( p < rStack.length )
			{
				if ( ")" == rStack[ p ].internal_token )
				{
					if ( left_parens == right_parens )
						break;
						
					right_parens++;
				}
				else
				if ( "(" == rStack[ p ].internal_token )
					left_parens++;
				
				p++;
			}
			
			// Must be at least 1 token after ending )
			if ( ( rStack.length - 2 ) < p )
			{
				resolveChoice_msgs += "SYNTAX ERROR: No statement after " + choice_found + " expression.\n";
				return RET_IS_USER_ERROR_SYNTAX;
			}
			
			end_paren_idx = p;
			
			// Either a single statement OR a Block of statements follows.
			// Switch requires a Block to follow.
			// IF a Block, the very next token will be {
			// else go until punctuation found or end
			
			var b = p + 1;
			var e = -1;
			
			if ( "{" != rStack[ b ].internal_token )
			{
				// Just a single statement.
				if ( "switch" == choice_found )
				{
					resolveChoice_msgs += "SYNTAX ERROR: Single statement not allowed for switch.\n";
					return RET_IS_USER_ERROR_SYNTAX;
				}
				
				// Scan forward to find punctuation
				while ( b < rStack.length )
				{
					if ( NL_OPERATOR == rStack[ b ].token_type )
					{
						var op_to_do = rStack[ b ].token_op_means;
				
						// Check for Punctuation.
						if ( ( OP_IS_PERIOD    == op_to_do )
						  || ( OP_IS_COMMA     == op_to_do )
						  || ( OP_IS_COLON     == op_to_do )
						  || ( OP_IS_SEMICOLON == op_to_do ) )
						{
							break;
						}
					}
					b++;
				}
			}
			else
			{
				// Scan forward to find end of Block
				
				while ( b < rStack.length )
				{
					if ( "}" == rStack[ b ].internal_token )
						break;
					
					b++;
				}
				
				if ( ( "if" == choice_found )
				  && ( b < rStack.length - 3 )
				  && ( "else" == rStack[ b + 1 ].internal_token ) )
				{
					// else Block follows. Curly Braces required: { statement(s) } 
					if ( "{" == rStack[ b + 2 ].internal_token )
					{
						else_start = b + 2;
						else_end   = b + 3;
						
						while ( else_end < rStack.length )
						{
							if ( "}" == rStack[ else_end ].internal_token )
							{
								else_found = true;
								break;
							}
							
							else_end++;
						}
					}
				}
			}
			
			if ( rStack.length <= b )
				b = rStack.length - 1;
			
			end_block_idx = b;
			
			// Set up internal values of Choice operator
			rStack[ i ].token_int   = end_paren_idx;
			rStack[ i ].token_float = end_block_idx;
			
			if ( ( "if" == choice_found )
			  && ( else_found ) )
			{
				// Set up skip forward vale for Block End
				// rStack[ i ].token_float = else_end + 1;
				
				// After True condition Block, Skip forward to after Else block
				rStack[ end_block_idx ].token_float = else_end - end_block_idx + 1;
			}

			// 'point' back to this Choice to do true/false decision after Expression evaluation. 
			// Use Logical index to avoid indeterminite Zero value.
			rStack[ end_paren_idx ].token_int = i + 1;
			
			if ( ( "for"    == choice_found )
			  || ( "while"  == choice_found ) )
			{
				// 'point' back to this Choice to support looping after end of Block.
				// Use Logical index to avoid indeterminite Zero value.
				rStack[ end_block_idx ].token_int = i + 1;
			}
			
			// skip forward to end of conditional expression
			// This allows to have embedded Choice within a Block ? TODO  REALLY NEEDS TESTING ! ! !
			i = end_paren_idx + 1;
		}

		return ret_val;
	}

	
//		Save to Dictionary any Noun values that are Not from Local Nouns
//
	public var saveNounValues_errors : String8 = "";

	public function saveNounValues( nlDict : NLDictionary, runStack : Array<NLToken>,
									nouns : Array<Int> ) : Int
	{
		comment( "Save to Dictionary any Noun values that are Not from Local Nouns" );
		var num_saved = 0;
		
		saveNounValues_errors = "";
		
		var i = 0;
		
		while ( i < nouns.length )
		{
			var runIdx = nouns[ i ];
			
			if ( NL_NOUN != runStack[ runIdx ].token_type )
			{
				i++;
				continue;
			}
			
			//var dictIdx = nlDict.findWord( runStack[ runIdx ].internal_token, runStack[ runIdx ].visible_token );
			var dictIdx = nlDict.findWord( runStack[ runIdx ].visible_token );
			if ( 0 <= dictIdx )
			{
				nlDict.unique_Dictionary_Words[ dictIdx ].token_noun_data = runStack[ runIdx ].token_noun_data;
				nlDict.unique_Dictionary_Words[ dictIdx ].token_str       = runStack[ runIdx ].token_str;
				nlDict.unique_Dictionary_Words[ dictIdx ].token_float     = runStack[ runIdx ].token_float;
				nlDict.unique_Dictionary_Words[ dictIdx ].token_int       = runStack[ runIdx ].token_int;
				num_saved++;
			}
			else
			{
				// This Noun was in the Dictionary earlier. Lookup ERROR or was Noun deleted or ?
				var err_msg = "ERROR not Saving: Noun " + runStack[ runIdx ].visible_token + " not in dictionary.\n";
				saveNounValues_errors += err_msg;
			}
			
			i++;
		}
		
		return num_saved;
	}

	
	
//		Update from Dictionary any Noun values (Not for Local Nouns)
//
	public var updateNounValues_errors : String8 = "";

	public function updateNounValues( nlDict : NLDictionary, runStack : Array<NLToken>,
									nouns : Array<Int>, lastOnly = false ) : Int
	{
		comment( "Update from Dictionary any Noun values (Not for Local Nouns)" );
		var num_updated = 0;
		
		updateNounValues_errors = "";
		
		var i = 0;
		if ( lastOnly )
			i = nouns.length - 1;
			
		while ( i < nouns.length )
		{
			var runIdx = nouns[ i ];
			
			if ( NL_NOUN != runStack[ runIdx ].token_type )
			{
				// For a Local NOUN, No Dictionary entry exists.
				i++;
				continue;
			}
			
			//var dictIdx = nlDict.findWord( runStack[ runIdx ].internal_token, runStack[ runIdx ].visible_token );
			var dictIdx = nlDict.findWord( runStack[ runIdx ].visible_token );
			if ( 0 <= dictIdx )
			{
				runStack[ runIdx ].token_noun_data = nlDict.unique_Dictionary_Words[ dictIdx ].token_noun_data;
				runStack[ runIdx ].token_str       = nlDict.unique_Dictionary_Words[ dictIdx ].token_str;
				runStack[ runIdx ].token_float     = nlDict.unique_Dictionary_Words[ dictIdx ].token_float;
				runStack[ runIdx ].token_int       = nlDict.unique_Dictionary_Words[ dictIdx ].token_int;
				num_updated++;
			}
			else
			{
				// This Noun was in the Dictionary earlier. Lookup ERROR or was Noun deleted or ?
				var err_msg = "ERROR not Updating: Noun " + runStack[ runIdx ].visible_token + " not in dictionary.\n";
				updateNounValues_errors += err_msg;
			}
			
			i++;
		}
		
		return num_updated;
	}


//		Show a Table of resolved Words
//
// Optional capture of only Text (no Colors added)
	public var words_table_text = "";
	
	public function showWordsTable( runStack : Array<NLToken>, show_words = true, show_index = false, text_str = false ) : Int
	{
		comment( "", "Show a Table of resolved Words and/or save to a Text buffer", "" );

		words_table_text = "";

		var lines_added = 0;
		var msg_text = "";
		var len = runStack.length;
		if ( 0 < len )
			return lines_added;

		msg_text = "\n\t\t\t" + Std.string( len ) + "  Words";
		if ( show_words )
			msg( msg_text );
		if ( text_str )
			words_table_text = msg_text;

		if ( show_words )
			lines_added += 2;

		if ( show_index )
		{
			msg_text = "  [ 0 to " + Std.string( len - 1 ) + " ]\n";
			if ( show_words )
				msg( msg_text );
			if ( text_str )
				words_table_text += msg_text;

			msg_text = "Index                 Internal           Word     Verb  or  Noun  Details ...\n";
			if ( show_words )
				msg( msg_text );
			if ( text_str )
				words_table_text += msg_text;

			if ( show_words )
				lines_added++;
			msg_text = "        Name            Name             Type     string, float, integer or bool";
			if ( show_words )
				msg( msg_text );
			if ( text_str )
				words_table_text += msg_text;
		}
		else
		{
			msg_text = "\n              Internal           Word     Verb  or  Noun  Details ...\n";
			if ( show_words )
				msg( msg_text );
			if ( text_str )
				words_table_text += msg_text;

			if ( show_words )
				lines_added++;
			msg_text = "Name            Name             Type     string, float, integer or bool\n";
			if ( show_words )
				msg( msg_text );
			if ( text_str )
				words_table_text += msg_text;
		}
		
		if ( show_words )
			lines_added++;
		msg_text = "--------------------------------------------------------------------------------";
		if ( show_words )
			msg( msg_text );
		if ( text_str )
			words_table_text += msg_text + "\n";
		
		if ( show_words )
			lines_added++;
		
		var used_inference = false;
	
//
// look at each NL token and display as expected
//
		var i = 0;
		while ( i < len )
		{
			// Used  TAB characters here.  Looks somewhat OK on Windows 7 Cmd.exe window
		
		// Index value column will be first if wanted
		//
			if ( show_index )
			{
				msg_text = "[" + Std.string( i ) + "]\t";
				if ( show_words )
					msg( msg_text );
				if ( text_str )
					words_table_text += msg_text;
			}
			
			used_inference = false;
			var nl_type    = runStack[i].token_type;
		
			if ( NL_TYPE_UNKNOWN == nl_type )
			{
				// UNKNOWN type of word is very suspicious here UNLESS
				// the token here really is a Local Noun.
				// Make the Inference that UNKNOWN type === Local Noun
				//
				// BUT it is wise to think in terms of Pre Conditions, Invariants, Post Conditions
				// (Design by Contract) if we are thinking about something messy.
				// 
				// Local Noun (variable) Pre Conditions:
				//    runStack[i].visible_token.length8() must be >= 1
				//    runStack[i].visible_token  must be a name that is valid  (TODO  Valid name spec?)
				//    runStack[i].visible_token  must NOT already be in the Dictionary as any kind of word
				//
				
				// TODO  add remaining preconditions
				// IF pre conditions are not true then give feedback about problem
				//
				
				used_inference = true;
				nl_type        = NL_NOUN_LOCAL;
			}
			
			var type_color = getTypeColor( nl_type );
		//
		// Visible name column
		//
		// Color visible Name by type
			msg_text = runStack[i].visible_token  + "\t\t";
			if ( runStack[i].visible_token.length8() >= 8 )
				msg_text = runStack[i].visible_token  + "\t";

			if ( show_words )
				msg( msg_text, type_color );
			if ( text_str )
				words_table_text += msg_text;
		//
		// Internal name column
		//
		// Color internal Name by type
			comment( "", "  Internal Name is what Run time logic depends on", "" );
			msg_text = runStack[i].internal_token + "\t\t";
			if ( runStack[i].internal_token.length8() >= 8 )
				msg_text = runStack[i].internal_token + "\t";
			
			if ( show_words )
				msg( msg_text, type_color );
			if ( text_str )
				words_table_text += msg_text;
		
		//
		// Column of extra information depending on NL type
		//
			var nl_type_text = nlTypeAsStr( nl_type ) + "\t";
			var nl_type_text_more = "";
			
			msg_text = nl_type_text;
		
			var type_unknown_error = false;
			switch ( nl_type )
			{
				case NL_TYPE_UNKNOWN:
					// Getting here indicates that above Unknown check needs more work
					var err_str : String8 = "INTERNAL LOGIC ERROR: Unknown type not resolved, Name: " + runStack[i].visible_token;
					if ( 0 < runStack[i].internal_token.length )
						err_str += " Internal name is " + runStack[i].internal_token ;
					
					error( err_str, RED );
					if ( show_words )
						msg( msg_text, RED );
						
					words_table_text += err_str;
						
					type_unknown_error = true;

					
				case NL_COMMENT:
					nl_type_text_more = runStack[i].token_str;
				
				case NL_OPERATOR:
					msg_text = opMeanAsStr( runStack[i].token_op_means );
				
				// Like a reserved keyword in other programming languages.
				case NL_VERB_BI:
										
				case NL_VERB:
					nl_type_text_more = " " + runStack[i].token_str;
					
				case NL_VERB_RET:
					
				case NL_NOUN:
					
				case NL_NOUN_LOCAL:

				case NL_STR:
					nl_type_text_more = " " + runStack[i].token_str;
					
				case NL_INT:
					nl_type_text_more = " " + Std.string( runStack[i].token_int );
					
				case NL_BOOL:
					if ( 1 == runStack[i].token_int )
						nl_type_text_more = "true";
					else
						nl_type_text_more = "false";

				case NL_FLOAT:
					nl_type_text_more = " " + Std.string( runStack[i].token_float );
					
				case NL_PUNCTUATION:
					
				case NL_CHOICE:

				// Do NOT have a default: here. Haxe compiler will then complain about missing cases. Nice!
			
			}
			
			// append Extra info if available
			if ( 0 < nl_type_text_more.length )
				msg_text = msg_text + nl_type_text_more;
			
			msg_text = msg_text + "\n";
			lines_added++;

			if ( show_words )
				msg( msg_text );
			
			if ( text_str )
				words_table_text += msg_text;

			i++;

		}  // end of  WHILE  loop  to textualize the given Run stack
		
		return lines_added;
	}
	
	
/*
			if ( NL_TYPE_UNKNOWN == type )
			{
	//
	// UNKNOWN type of word is very suspicious here UNLESS
	// the token here really is a Local Noun.
	// Make the Inference that UNKNOWN type === Local Noun
	//
	// HOW to know IF the Inference is True for this token ? ? ?
	// (inquiring Developers want to know!)
	//
	// At this point there may be no easy answer here.
	// forGL is structured sometimes along various ideas
	// "surface" level that can do dictionary lookup and do simple Parsing
	// "Interpreter running" level that understands things 
	//    such as Choice words and how Conditions, Loops, etc to move to next statement
	//
	// No change to original  runStack[i].token_type
	//
				used_inference = true;
				type = NL_NOUN_LOCAL;		
			}

			var type_color = getTypeColor( type );

			// Color visible Name by type
			msg_text = runStack[i].visible_token  + "\t\t";
			if ( runStack[i].visible_token.length8() >= 8 )
				msg_text = runStack[i].visible_token  + "\t";

			if ( show_words )
				msg( msg_text, type_color );
			if ( text_str )
				words_table_text += msg_text;
			
			comment( "", "  Internal Name is what Run time logic depends on", "" );
			msg_text = runStack[i].internal_token + "\t\t";
			if ( runStack[i].internal_token.length8() >= 8 )
				msg_text = runStack[i].internal_token + "\t";

			if ( show_words )
				msg( msg_text, type_color );
			if ( text_str )
				words_table_text += msg_text;

			if ( NL_OPERATOR == type )
			{
				msg_text = opMeanAsStr( runStack[i].token_op_means );
				if ( show_words )
					msg( msg_text, type_color );
				if ( text_str )
					words_table_text += msg_text;
			}
			else
			{
				msg_text = nlTypeAsStr( type ) + "\t";
				if ( show_words )
					msg( msg_text, type_color );
				if ( text_str )
					words_table_text += msg_text;
			}

			if ( NL_VERB == type )
			{
				msg_text = " " + runStack[i].token_str + "\n";
				if ( show_words )
					msg( msg_text );
				if ( text_str )
					words_table_text += msg_text;

				if ( show_words )
					lines_added++;
			}
			else
			if ( ( NL_NOUN       == type )
			  || ( NL_NOUN_LOCAL == type ) )
			{
				if ( NL_STR == runStack[i].token_noun_data )
				{
					msg_text = "\t s: " + runStack[i].token_str + "\n";
					if ( show_words )
						msg( msg_text );
					if ( text_str )
						words_table_text += msg_text;

					if ( show_words )
						lines_added++;
				}
				else
				if ( NL_FLOAT == runStack[i].token_noun_data )
				{
					msg_text = "\t " + Std.string( runStack[i].token_float ) + "\n";
					if ( show_words )
						msg( msg_text );
					if ( text_str )
						words_table_text += msg_text;

					if ( show_words )
						lines_added++;
				}
				else
				{
					if ( NL_BOOL == runStack[i].token_noun_data )
					{
						if ( 1 == runStack[i].token_int )
							msg_text = "\t true\n";
						else
							msg_text = "\t false\n";

						if ( show_words )
							msg( msg_text );
						if ( text_str )
							words_table_text += msg_text;
					}
					else
					if ( NL_INT == runStack[i].token_noun_data )
					{
						msg_text = "\t " + Std.string( runStack[i].token_int ) + "\n";
						if ( show_words )
							msg( msg_text );
						if ( text_str )
							words_table_text += msg_text;
					}
					else
					{
						if ( used_inference )
						{
							if ( show_words )
								msg( "\n" );
							if ( text_str )
								words_table_text += "\n";
						}
						else
						{
							// Check for Punctuation
							var op_to_do = runStack[ i ].token_op_means;
							
							if ( ( OP_IS_PERIOD    == op_to_do )
							  || ( OP_IS_COMMA     == op_to_do )
							  || ( OP_IS_COLON     == op_to_do )
							  || ( OP_IS_SEMICOLON == op_to_do ) )
							{
								// Display the meaning of Punctuation
								msg_text = opMeanAsStr( runStack[i].token_op_means );
								if ( show_words )
									msg( msg_text, type_color );
								if ( text_str )
									words_table_text += msg_text;
							}
							else
							{
								var err_str : String8 = "INTERNAL LOGIC ERROR: token_noun_data value " + Std.string( cast( runStack[i].token_noun_data, Int ) );
								if ( 0 < runStack[i].internal_token.length  )
									err_str = err_str + " token name is " + runStack[i].internal_token ;
								
								error( err_str, RED );
								words_table_text += err_str;
							}
						}
					}
					
					if ( show_words )
						lines_added++;
				}
			}
			else
			{
				if ( show_words )
					msg( "\n" );
				if ( text_str )
					words_table_text += "\n";

				if ( show_words )
					lines_added++;
			}

			i++;
		}

	
#if debug


#end

*/
	
	
	public function cleanUp()
	{


		// TODO:  use  comment( )  utility here

/*
 * 
// For now Parse as if European style language:
//    blank spaces or whitespace between words
//    blank spaces required around some reserved words
//    Decimal point character also can be Period at end of a sentance.
//    Natural language reading order is 
//        Line oriented top line first, read from Left to Right 
//        continue to next line until no more text and
//        assume that tokens are NOT split across multiple lines

//  There is another reading order that is not processed here but done elsewhere for
//  MATHEMATICS
//
//      Math has MANY branches and each branch MAY have a style that is unique.
//		Each Math branch usually has 2 presentation styles.
//      (Nearly always) Symbolic presentation using special Math symbols from that Math branch.
//      (Usually?) Pictorial (graphs, etc) presentation of various concepts of the Math branch.
//
//      Typical Math styles include visual diagrams (or electronic displays now)
//      Math symbol display uses mostly infix, some prefix (and less often postfix) notation.
//
//      Good examples can be found in Math text books about: 
//          Algebra, Plane or 3 Dimension Geometry, Trigonometry, Calculus, etc.

*/

	}
}