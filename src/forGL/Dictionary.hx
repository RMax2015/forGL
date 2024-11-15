/* Dictionary.hx	 forGL Dictionary interface
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

// added to support Parsing inside  SHOW  Dictionary
using forGL.Parse.Parse;
using forGL.Parse.NLToken;

using forGL.NLTypes;
import forGL.NLTypes.NLTypeAs.nlTypeAsStr           as  nlTypeAsStr;

import forGL.Meanings.OpMeanings;
import forGL.Meanings.OpMeaningsValLimits;
import forGL.Meanings.MeansWhat.opMeanAsStr      as  opMeanAsStr;


import forGL.Meanings.ReturnMeanings;

import forGL.UI.ForGL_ui.msg      as   msg;
import forGL.UI.ForGL_ui.error    as   error;
import forGL.UI.ForGL_ui.status   as   status;
import forGL.UI.ForGL_ui.getTypeColor    as   getTypeColor;
import forGL.UI.ForGL_ui.eraseToLineEnd  as   eraseToLineEnd;
import forGL.UI.ForGL_ui.enterYes        as   enterYes;

#if ( !cs && !js )		// for now  C# does not have text Cursor positioning
	import forGL.UI.ForGL_ui.hideCursor      as   hideCursor;
	import forGL.UI.ForGL_ui.savePos         as   savePos;
	import forGL.UI.ForGL_ui.goToPos         as   goToPos;
	import forGL.UI.ForGL_ui.eraseToDispEnd  as   eraseToDispEnd;
	import forGL.UI.ForGL_ui.eraseToLineEnd  as   eraseToLineEnd;
	import forGL.UI.ForGL_ui.restorePos      as   restorePos;
	import forGL.UI.ForGL_ui.showCursor      as   showCursor;
#end

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment    as    comment;

using forGL.Dictionary.NLDictionary;


//
//		Dictionary support as structures in memory
//
class  NLDictionary
{

	public function new() 
	{
	}
	
	public var path_dictionary_file = "";
	
	public var use_Built_In_Dictionary = false;
	
//
//		USE SAME Struct/Class container as Run time
	public var unique_Dictionary_Words = new Array<NLToken>();
	

// Initialize everything needed for a given Dictionary
//
// Pre Conditions:
//     Either a Dictionary file was found and Read into memory
//         OR
//     Running with Default built in Dictionary in some Language ( TODO for other than English )
//
// Invariants:
//     Self consistent Words defined to support forGL
//
// Post Conditions:
//     Fully defined Dictionary ready on return if no SEVERE ERROR
//
//
	public var words_added_by_init = 0;
	
	public function init( path_dict_file : String ) : ReturnMeanings
	{
		comment( "Initialize everything needed for a given Dictionary" );
		var result = RET_IS_OK;
		
		path_dictionary_file = path_dict_file;
		
		// unique_Dictionary_Words = new Array<DictWord>();
		
	/*
		if ( 0 == path_dict_file.length )
		{
			// Caller provides NO Dictionary file name so use Built In Dictionary
			use_Built_In_Dictionary = true;
			return RET_IS_OK;
		}
		else
	*/
			use_Built_In_Dictionary = false;
		
		// Setup support for a complete Default dictionary in memory.
		// This allows forGL to run WITHOUT a dictionary file if wanted.
		// For now  Default is English dictionary.
		//     TODO  support other Languages as a Default (via Resource file perhaps? toml format?) 
		//
		//     NOTE: 
		//         support of other Languages as a Default includes ALL the various MESSAGES and the Dictionary!
		//         English Default still likely to be built in as last resort.
		
		
		// Add known Operators with Default language and known internal names
		
		var i = 1;		// skip Unknown as it should NEVER be an actual word definition MAY be handy in future
		
		var limit = cast( OP_IS_HIGHEST_VAL, Int );
		var name_internal : String8 = "";
		var op_means = OP_IS_UNKNOWN;
		var add_result = RET_IS_OK;
		
		while ( i <= limit )
		{
			op_means = cast( i, OpMeanings );
			name_internal = opMeanAsStr( op_means, true );
			
			if ( 0 < name_internal.length8() )
			{
				add_result = addWord( name_internal, NL_OPERATOR, name_internal, op_means );
			}

			i++;
		}
		
		// Add Built in Alias for some Operators
//		addWord( "^",    NL_OPERATOR, "pow", OP_IS_POW );
//		addWord( "**",   NL_OPERATOR, "pow", OP_IS_POW );
		addWord( "into", NL_OPERATOR, "=:", OP_IS_ASSIGN_TO );
		addWord( "from", NL_OPERATOR, ":=", OP_IS_ASSIGN_FROM );

		// Add Built in Choice words. 
		// Choice words use ( true or false eventually ) for Boolean condition(s)
		// and { around blocks of statements }
		add_result = addWord( "if", NL_CHOICE, "if" );
		add_result = addWord( "else", NL_CHOICE, "else" );
		add_result = addWord( "while", NL_CHOICE, "while" );
		add_result = addWord( "for", NL_CHOICE, "for" );
		add_result = addWord( "switch", NL_CHOICE, "switch" );
		add_result = addWord( "case", NL_CHOICE, "case" );
		add_result = addWord( "default", NL_CHOICE, "default" );
		add_result = addWord( "break", NL_CHOICE, "break" );
		add_result = addWord( "continue", NL_CHOICE, "continue" );
		add_result = addWord( "return", NL_CHOICE, "return" );

		// Add Built in Verbs
		add_result = addWord( "repeat", NL_VERB_BI, "repeat" );
		add_result = addWord( "show", NL_VERB_BI, "show" );
		add_result = addWord( "view", NL_VERB_BI, "view" );
		
		// Add alias Words to Operators to allow User some variation of expression
		//
		// On second thought, don't clutter dictionary with words the User doesn't want.
		//
		// User can add all the alias words they want (following rules for word types).
		//
		// For a User: a TOML Dictionary only needs to have 
		// the User wanted alias words
		// the User defined Nouns and Verbs
		// the User selected word that starts running first (optional)
		//
		// the Operators and Built In Verbs and Choice words are already supplied
		// to see details of how this works see the TOML Dictionary example
		// and code that calls to findWord, addWord, findSimilar here
		//
		// IF the User wants a language that is NOT English 
		// THEN extra words to support the User language are needed.
		// These extra words are alias words that are in a different language.
		// So far, so good.
		
		// Get the words in order
		words_added_by_init = sortDictionary();
		
		return result;
	}
	

//	show the Dictionary words
//
	public function showDictionaryWords( skip_operators = true, wait = true /*, do_OEM = false */ ) : Int
	{
		var lines_added = 1;	// 1  for Question line
		
		if ( 0 == unique_Dictionary_Words.length )
			return 0;
		
	#if ( ! java && !js )
		
		msg( "    Show Dictionary (y/n) ? ", GREEN, false );
		var char_code = Sys.getChar( true );
		
		// msg( "\r" );	// OK to output over the Show Dictionary Question
		msg( "\n" );			// move 1 line down
		eraseToLineEnd( 0 );
		
		// Must be  Y or y  or else not show and done
		if ( ( 0x59 != char_code )
		  && ( 0x79 != char_code ) )
		{
			return 1;
		}

	#end
	
	#if java
		msg( "    Show Dictionary (y/n) ? ", GREEN, false );
		if ( ! enterYes() )
			return 1;
	#end
		
		// show Dictionary name and word count
		// (example)
		// ../../forGL_Dictionary_Prototype.toml has 99 Words
		var message = " has " + Std.string( unique_Dictionary_Words.length ) + " Words";
		if ( words_added_by_init == unique_Dictionary_Words.length )
			message = "Dictionary (built in)" + message;
		else
			message = path_dictionary_file + message;
		
		if ( skip_operators )
			message += ", skipping Operators";
		
		message += "\n";
		lines_added++;

		// show Column names
		message += "Visible ------- Internal ------ Meaning ---------------\n";
		lines_added++;
		
		msg( message, GREEN );
		
		var color = WHITE;
		var word_type = NL_TYPE_UNKNOWN;
		var visible_word  : String8 = "";
		var internal_word : String8 = "";
		var string_data   : String8 = "";
		var j = 0;
		while ( j < unique_Dictionary_Words.length )
		{
			if ( ( skip_operators ) 
			  && ( NL_OPERATOR == unique_Dictionary_Words[ j ].token_type ) )
			{
				j++;
				continue;
			}

			word_type     = unique_Dictionary_Words[ j ].token_type;
			visible_word  = unique_Dictionary_Words[ j ].visible_token;
			internal_word = unique_Dictionary_Words[ j ].internal_token;
			
//			if ( do_OEM )
//			{
//				comment( "", "Change to OEM for display output", "" );
//				visible_word  = Utf8_to_OEM.oemStr( visible_word );
//				internal_word = Utf8_to_OEM.oemStr( internal_word );
//			}
			
		
			color = getTypeColor( word_type );
			
		// For Dictionary display use RED color for  NOUNS  global variables
			if ( NL_NOUN == word_type )
			{
				color = RED;
			}
			
		// Visible word
			if ( 7 < visible_word.length8() )
				msg( visible_word + "\t", color );
			else
				msg( visible_word + "\t\t", color );
			
		// Internal word
			if ( 7 < internal_word.length8() )
				msg( internal_word + "\t", color );
			else
				msg( internal_word + "\t\t", color );

		// Meaning
			if ( NL_OPERATOR == word_type )
				msg( opMeanAsStr( unique_Dictionary_Words[ j ].token_op_means ) + "\n", color );
			else
			{
				msg( nlTypeAsStr( word_type ) + "\t", color );
				
				string_data = unique_Dictionary_Words[ j ].token_str;
//				if  ( do_OEM )
//					string_data = Utf8_to_OEM.oemStr( string_data );
			
				if ( NL_NOUN == word_type )
				{
					if ( NL_STR == unique_Dictionary_Words[ j ].token_noun_data )
						msg( string_data + "\n", color );
					else
					if ( NL_BOOL == unique_Dictionary_Words[ j ].token_noun_data )
					{
						if ( 1 == unique_Dictionary_Words[ j ].token_int )
							msg( "true\n", color );
						else
							msg( "false\n", color );
					}
					else
					if ( NL_INT == unique_Dictionary_Words[ j ].token_noun_data )
						msg( Std.string( unique_Dictionary_Words[ j ].token_int ) + "\n", color );
					else
					if ( NL_FLOAT == unique_Dictionary_Words[ j ].token_noun_data )
						msg( Std.string( unique_Dictionary_Words[ j ].token_float ) + "\n", color );
				}
				else
				if ( NL_VERB == word_type )
				{
					msg( string_data + "\n", color );
					
				// TODO:  Try to show the Verb as correctly colored tokens
				//		best way MAY be to refactor the 
				//		calling context to be AFTER a Dictionary is fully resolved and ready to run Verbs
				// 		the current calling context is BEFORE where less info is available
				//		see code in Run.hx after ~ line 4150  CHECK FOR VERB
				//	var nl_Parse : Parse;
				//	var verb_tokens = nl_Parse.parse( string_data, PARSE_LEFT_TO_RIGHT, false );

				}
				else
				if ( NL_VERB_BI  == word_type )
					msg( "\n" );
				else
				if ( NL_CHOICE  == word_type )
					msg( "\n" );
			}
			
			lines_added++;
			j++;
		}
		
	#if ( !java && !js )
		if ( wait )
		{
			msg( "    Hit a key when ready.\r", GREEN, false );
			var char_code = Sys.getChar( false );
			eraseToLineEnd( 0 );
		}
	#end
		
		return lines_added;
	}
	
//		Find a Word in this Dictionary
//	returns 
//      -1 if Not Found 
//      -2 if no visible name
//      -3 if exact match and no internal name given
//      else index of Dictionary entry
	public function findWord( word_name : String8 ) : Int
//	public function findWord( word_name : String8, word_internal_name : String8, 
//							?exact_match : Bool = true ) : Int
	{
		comment( "Find a Word in this Dictionary" );
		if ( 0 == word_name.length8() )
			return -2;
/*
		if ( exact_match )
		{
			if ( 0 == word_internal_name.length8() )
				return -3;
		}
*/		
		var search_name = Strings.toLowerCase8( word_name );
//		var search_internal_name = Strings.toLowerCase8( word_internal_name );
		
		// See if the Word is in the Dictionary
		var i = 0;
		while ( i < unique_Dictionary_Words.length )
		{
			// Must always match the visible name (Spelling and NOT Capitalization)
			if ( search_name == Strings.toLowerCase8( unique_Dictionary_Words[ i ].visible_token ) )
			{
			/*
				if ( exact_match )
				{
					if ( search_internal_name == unique_Dictionary_Words[ i ].internal_token )
						return i;
				}
				else
			*/
					return i;
			}
			
			i++;
		}
		
		return -1;
	}	
	
	
	
// Find the difference between 2 strings using Levenshtein Distance algorithm.
// Smaller value is a closer match.
//
// References:
//    This gives a faster and less use of memory approach.
//    Wikipedia article: Levenshtein distance
//       http://en.wikipedia.org/wiki/Levenshtein_distance
//
//    A better C++ approach (ported to Haxe that is used below) was found at 
//    Rosetta Code:  Levenshtein distance  C++ (modified to not use iterators about == 13% faster)
//
// Pre Conditions:
//    Both strings have length > 0.  
//    For Dictionary search length of 1 is not seen here.
//    Strings are not equal.
//
//    Common Prefix characters and common Suffix characters were removed for better performance
//
	public function levenshteinDistance( s1 : String8, s2 : String8 ) : Int
	{
		comment( "Find the difference between 2 strings using Levenshtein Distance algorithm." );
		// See: Rosetta Code:  Levenshtein distance  C++ implementation
		var m = s1.length;
		var n = s2.length;

		// Trivial case: already checked for as part of Precondition
		// if( m == 0 )
		//     return n;
		// if( n == 0 )
		//    return m;

		var costs = new Array<Int>();
		var k = 0;
		while ( k <= n )
		{
			costs.push( k );
			k++;
		}

		var corner = 0;
		var upper = 0;
		var t = 0;
		var j = 0;
		var i = 0;
		var s1_it1;

		var it2 = 0;
		var it1 = 0;
		while ( it1 != m )
		{
			costs[ 0 ] = i + 1;
			corner = i;
			j = 0;
			s1_it1 = s1.charAt8( it1 );  //  s1[ it1 ];

			it2 = 0;
			while ( it2 != n )
			{
				upper = costs[ j + 1 ];
				if ( s1_it1 == s2.charAt8( it2 ) )
				{
					costs[ j + 1 ] = corner;
				}
				else
				{
					t = ( upper < corner ? upper : corner );
					costs[ j + 1 ] = ( costs[ j ] < t ? costs[ j ] : t ) + 1;
				}
				corner = upper;
				it2++;
				j++;
			}
			it1++;
			i++;
		}
		
		var result = costs[ n ];
		return result;
	}
	

// Finds the common Prefix of 2 strings
//
// Haxe NOTE:
//    Haxe does NOT allow modified arguments to be returned except for classes with internal variables
//
//    Typically there would be another Bool to ask to remove the preFix.
//    But for Haxe code the 2 strings would have to be inside another class to have prefix remove work.
//    Goal is to have simple code that also performs somewhat well.
//    So preFix removal is done by Calling code after Return from here.
//
	public function findCommonPrefix( str : String8, str2 : String8 ) : String8
	{
		comment( "Finds the common Prefix of 2 strings" );
		var prefixNew : String8 = "";

		var	count = str.length;
		if ( count > str2.length )
			count = str2.length;

		var i = 0;
		while ( i < count )
		{
			// This does Exact (case sensitive) match
			if ( str.charAt8( i ) == str2.charAt8( i ) )
			{
				prefixNew = prefixNew.insertAt( prefixNew.length8(), str.charAt8( i ) );
			}
			else
				break;
			i++;
		}

		return prefixNew;
	}


// Finds the common Suffix of 2 strings
//
// NOTE:
//   See findCommonPrefix 
//
	public function findCommonSuffix( str : String8, str2 : String8 ) : String8
	{
		comment( "Finds the common Suffix of 2 strings" );
		var suffixNew : String8 = "";

		var size = str.length8();
		var size2 = str2.length8();
		var	count = size;
		if ( count > size2 )
			count = size2;

		if ( 0 == count )
			return suffixNew;

		var	index  = size  - 1;
		var	index2 = size2 - 1;

		var i = 0;
		while ( i < count )
		{
			// Go from END of strings
			if ( str.charAt8( index ) == str2.charAt8( index2 ) )
			{
				suffixNew = suffixNew.insertAt( 0, str.charAt8( index ) );
				index--;
				index2--;
			}
			else
				break;
			i++;
		}

		return suffixNew;
	}


//		Find Word(s) in this Dictionary that are Similar to given word
//	returns 
//     A Similar Word. MAY be empty string
	public function findSimilar( word_internal_name : String8 ) : String8
	{
		comment( "Find Word(s) in this Dictionary that are Similar to given word" );
		if ( word_internal_name.length8() <= 1 )
			return "";		// Not matching just 1 character

		// See if a Similar Word is in the Dictionary
		var apply_cost = false;
		var cost = 999999999;
		var prev_cost = -1;
		var prev_similar : String8 = "";
		
		var str  : String8 = "";
		var str2 : String8 = "";
		
		var preFix = "";

		var i = 0;
		while ( i < unique_Dictionary_Words.length )
		{
			if ( unique_Dictionary_Words[ i ].internal_token.length8() <= 1 )
			{
				i++;
				continue;	// Skip 1 character Words
			}
			
			// Must always match the internal name
			if ( word_internal_name == unique_Dictionary_Words[ i ].internal_token )
				return word_internal_name;
			
			// See if somewhat Similar
			
			// remove Common Prefix characters and Suffix characters
			str  = word_internal_name;
			str2 = unique_Dictionary_Words[ i ].internal_token;
			if ( str.charAt8( 0 ) == str2.charAt8( 0 ) )
			{
				var prefix = findCommonPrefix( str, str2 );

				// We know prefix length >= 1
				str  = Strings.removeLeading( str, preFix );
				str2 = Strings.removeLeading( str2, preFix );
			}
			
			if ( str.length8() == 0 )
				cost = str2.length8();
			else 
			if ( str2.length8() == 0 )
				cost = str.length8();
			else
			{
				if ( str.charAt8( str.length8() - 1 ) == str2.charAt8( str2.length8() - 1 ) )
				{
					var suffix = findCommonSuffix( str, str2 );

					// We know suffix length >= 1
					str  = Strings.removeTrailing( str, suffix );
					str2 = Strings.removeTrailing( str2, suffix );
				}
			
				if ( str.length8() == 0 )
					cost = str2.length8();
				else if ( str2.length8() == 0 )
					cost = str.length8();
				else
					cost = levenshteinDistance( str, str2 );
			}
				
			apply_cost = false;
			if ( 0 <= prev_cost )
			{
				if ( cost < prev_cost )
					apply_cost = true;
			}
			else
				apply_cost = true;
			
			if ( apply_cost )
			{
				prev_cost = cost;
				prev_similar = unique_Dictionary_Words[ i ].internal_token;
			}
			
			i++;
		}
		
		return prev_similar;
	}	
	

//		Add or Replace a Word in this Dictionary
//
	public var addWord_msg = "";

	public function addWord( word_name : String8, 
							word_type : NLTypes = NL_TYPE_UNKNOWN,
							name_internal : String8 = "", 
							?op_means : OpMeanings = OP_IS_UNKNOWN,
							?data_str : String8 = "",
							?data_float : Float = 0.0,
							?data_int : Int = 0,
							?noun_data : NLTypes = NL_TYPE_UNKNOWN,
							?replaceIdx : Int = -1 ) : ReturnMeanings
	{
		comment( "Add or Replace a Word in this Dictionary" );
		var ret_val = RET_IS_OK;
		
		addWord_msg = "";

		if ( ( 0 == word_name.length8() )
		  || ( 0 == name_internal.length8() ) 
		  || ( NL_TYPE_UNKNOWN == word_type )
		  || ( ( NL_OPERATOR == word_type ) && ( OP_IS_UNKNOWN == op_means ) )
		  || ( ( NL_NOUN  == word_type ) && ( NL_TYPE_UNKNOWN == noun_data ) )
		  || ( ( NL_VERB  == word_type ) && ( "" == data_str ) ) )
		{
			status( "" );
			addWord_msg = "ERROR: Invalid: " + word_name + " " + name_internal + " " + nlTypeAsStr( word_type ) + " ";
			if ( NL_OPERATOR == word_type )
				addWord_msg += opMeanAsStr( op_means );
			else
			if ( NL_NOUN  == word_type )
				addWord_msg += nlTypeAsStr( word_type );
			else
			if ( NL_VERB == word_type )
			{
				if ( 0 == data_str.length8() )
					addWord_msg += "without any Value";
			}
			addWord_msg += "\n";
			
			error( addWord_msg, RED );
			
			RET_IS_USER_ERROR_DATA;
		}
		
		name_internal = Strings.toLowerCase8( name_internal );
		var verbose_phrase = word_name;
		
		if ( 0 <= replaceIdx )
		{
			//  TODO  extra validation ! ! !
			
			
			unique_Dictionary_Words[ replaceIdx ].internal_token  = name_internal;
			unique_Dictionary_Words[ replaceIdx ].visible_token   = word_name;
			unique_Dictionary_Words[ replaceIdx ].verbose_phrase  = verbose_phrase;
			unique_Dictionary_Words[ replaceIdx ].token_str       = data_str;
			unique_Dictionary_Words[ replaceIdx ].token_float     = data_float;
			unique_Dictionary_Words[ replaceIdx ].token_type      = word_type;
			unique_Dictionary_Words[ replaceIdx ].token_noun_data = noun_data;
			unique_Dictionary_Words[ replaceIdx ].token_int       = data_int;
			unique_Dictionary_Words[ replaceIdx ].token_op_means  = op_means;
		}
		else
		{
			// Make sure the Word is NOT already in the Dictionary
			var find_idx = findWord( word_name );
			if ( 0 <= find_idx )
			{
				// Not allowed to add a Word that already exists.
				addWord_msg = "ERROR: Word " + word_name + " already in Dictionary";
				return RET_IS_USER_ERROR_DATA;
			}
		
		
			// TODO  Insert new Word Sorted by internal name
			
			//  for now  insert at end of array
			unique_Dictionary_Words.push( new NLToken( name_internal, word_name,
											verbose_phrase,
											data_str, data_float, word_type, 
											noun_data, data_int, op_means ) );
		}
		
		return ret_val;
	}


//		Sort by visible_token which is required to be Unique in spelling. 
//          Unique in spelling implies Unique also for Ignore Case
//
	public function sortDictionary() : Int
	{
		if ( 1 < unique_Dictionary_Words.length )
		{
			// Use  ignore  case  so that Upper and Lower case word names are grouped together after sort
			unique_Dictionary_Words.sort(function(a, b) return Strings.compareIgnoreCase( a.visible_token, b.visible_token ) );
		}
		
		return unique_Dictionary_Words.length;
	}


//		Get a list of all Dictionary words not automatically generated
//
	public function getCustomWords() : Array<String8>
	{
		comment( "Get a list of all Dictionary words not automatically generated" );
		var custom_words = new Array<String8>();
		
		var i = 0;
		while ( i < unique_Dictionary_Words.length )
		{
			if ( ( NL_NOUN == unique_Dictionary_Words[ i ].token_type )
			  || ( NL_VERB == unique_Dictionary_Words[ i ].token_type ) )
			{
				custom_words.push( unique_Dictionary_Words[ i ].visible_token );
			}
			else
			// See code at the end of init() to see what is being skipped here
			if ( unique_Dictionary_Words[ i ].visible_token != unique_Dictionary_Words[ i ].internal_token )
			{
				// These are Alias words to support various Natural Languages and/or to be easier for User
				custom_words.push( unique_Dictionary_Words[ i ].visible_token );
			}
			i++;
		}
		
		return custom_words;
	}


//		Clean up  Dictionary  resources used 
//	
	public function cleanUp() : ReturnMeanings
	{
		var ret_val = RET_IS_OK;
		
		unique_Dictionary_Words = [ new NLToken( ".", ".", ".",
										"", 0.0, NL_TYPE_UNKNOWN, 
										NL_TYPE_UNKNOWN, 0, OP_IS_UNKNOWN ) ];
		
		unique_Dictionary_Words.pop();
		
		
		return ret_val;
	}

}