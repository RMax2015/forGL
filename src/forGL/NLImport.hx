/* NLImport.hx	 forGL Import into Dictionary in memory interface
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * 
 * Support adding somewhat validated words from the Data layer to a Dictionary in memory.
 * 
 * ...
 * @author Randy Maxwell
 */

package forGL;


// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

using  forGL.NLTypes;
import forGL.NLTypes.NLTypeAs.resolveType    as  resolveType;

import forGL.Meanings.OpMeanings;
import forGL.Meanings.MeansWhat.opMeanAsStr      as  opMeanAsStr;
import forGL.Meanings.MeansWhat.returnMeanAsStr  as  returnMeanAsStr;

import forGL.data.Data.ForGL_data;

import forGL.Dictionary.NLDictionary;

import forGL.Meanings.ReturnMeanings;


import forGL.UI.ForGL_ui.msg     as  msg;
import forGL.UI.ForGL_ui.error   as  error;
import forGL.UI.ForGL_ui.status  as  status;

// Allow  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment   as  comment;

using forGL.NLImport.NLImport;

//
//		Import support for Dictionaries (or Library Vocabularies?)
//
class  NLImport
{

	public function new() 
	{
		
	}

	
	public function init() 
	{
		
	}
	
	

	public function cleanUp() 
	{
		
	}
	
	public var importWords_msgs : String8 = "";
	
	public function importWords( data : ForGL_data, dict : NLDictionary, dict_path_file : String8 /*, do_OEM = false */ ) : ReturnMeanings
	{
		comment("","Support adding somewhat validated words from the Data layer to a Dictionary in memory.","");
		
		var result = RET_IS_OK;
		
		importWords_msgs = "";
		
		// TODO  Check that path/name matches for both dictionary and data


		var words = data.getListOfWords();
		importWords_msgs += "Information: " + Std.string( words.length ) + " words to import.\n";
		
		if ( 0 == words.length )
			return RET_IS_OK;

		var next_word : String8 = "";
		var words_str = words[ 0 ];

//		if ( do_OEM )
			// Change to OEM characters ONLY for display.  NOT for comparison with internal UTF8.
//			words_str = Utf8_to_OEM.oemStr( words_str );

		var i = 0;
		var line_len = 0;
		while ( i < words.length )
		{
			next_word = words[ i ];

//			if ( do_OEM )
//				next_word = Utf8_to_OEM.oemStr( next_word );

			
			i++;
			
			// Limit string length of exported words per line
			if ( ( line_len + next_word.length ) > 77 )
			{
				// Too long so move to next line and set length
				words_str += ", \n" + next_word;
				line_len = next_word.length;
			}
			else
			{
				words_str += ", " + next_word;
				line_len  +=   2  + next_word.length;
			}
		}
		
		var str = "Words to Import are:\n" + words_str + "\n";
		importWords_msgs += str;
		
		var rInfo = new ResolveInfo();
		
		var rOtherInfo = new ResolveInfo();
		
		var find_result = RET_IS_OK;
		
		i = 0;
		while ( i < words.length )
		{
			find_result = data.findWordDef( words[ i ], rInfo );
			//status( words[ i ] + " " + rInfo.resolve_out_token + " " + opMeanAsStr( rInfo.resolve_op_meaning ), RED, false, true );
			
			if ( RET_IS_OK != find_result )
			{
				// Just got a list of words. WHY is there a PROBLEM HERE?
				importWords_msgs += "INTERNAL ERROR: findWordDef of " + words[ i ] + " has unexpected result of " + returnMeanAsStr( find_result ) + ". Skipping to next word.\n";
				i++;
				continue;
			}

			// The SPELLING of the word at the VISIBLE LEVEL MUST BE UNIQUE.
			// So use lower case of word for comparisons.
			if ( 0 == rInfo.resolve_out_token.length8() )
				rInfo.resolve_out_token = Strings.toLowerCase8( words[ i ] );

			rInfo.resolve_use_out = true;

			// var dictIdx = dict.findWord( rInfo.resolve_out_token, words[ i ] );
			var dictIdx = dict.findWord( words[ i ] );
			
			if ( ( NL_OPERATOR == data.findWordDef_type )
			  && ( OP_IS_UNKNOWN == rInfo.resolve_op_meaning ) )
			{
				var resolve_result = resolveType( rInfo.resolve_out_token, rOtherInfo, false, false );
				
				if ( NL_OPERATOR == resolve_result )
				{
					rInfo.resolve_op_meaning = rOtherInfo.resolve_op_meaning;
					rInfo.resolve_out_token  = rOtherInfo.resolve_out_token;
				}
				else
				{
					comment( "", "Dictionary may have a reference to a Built In Verb rather than an Operator",
					"Example: 'zeigen' is German for 'show' (changed '' to ' for easy reading here)",
					"[_zeigen_]",
					"word_type = 'operator'",
					"name = 'zeigen'",
					"built_in_name = 'show'", "",
					"The above call to resolveType should have set resolve_result to NL_VERB_BI", "");
					if ( NL_VERB_BI == resolve_result )
					{
						rInfo.resolve_op_meaning = rOtherInfo.resolve_op_meaning;
						rInfo.resolve_out_token  = rOtherInfo.resolve_out_token;
						
						comment( "We know this really is a Built In Verb" );
						data.findWordDef_type = NL_VERB_BI;
					}
					else
					{
					
						// Unable to resolve the details of the Operator type. Strange...
var err_msg = "INTERNAL ERROR: Word " + words[ i ] + " unable to resolve details of Operator type. Skipping to next word.\n";
						importWords_msgs += err_msg;
						error( err_msg );
						i++;
						continue;
					}
				}
			}

			if ( NL_OPERATOR == data.findWordDef_type )
			{
				var built_in_op_str = opMeanAsStr( rInfo.resolve_op_meaning, true );
				rInfo.resolve_out_token = built_in_op_str;
			}
			
			if ( NL_NOUN == data.findWordDef_type )
			{
				rInfo.resolve_op_meaning = OP_IS_UNKNOWN;
						
				// Have actual data type of Noun be correct with the data.
				if ( NL_STR == rInfo.resolve_token_noun_data )
				{
					rInfo.resolve_float = 0.0;
					rInfo.resolve_int = 0;
						
					var resolve_result = resolveType( rInfo.resolve_str, rOtherInfo, false, true );
					if ( ( NL_TYPE_UNKNOWN != resolve_result )
					  && ( NL_STR != resolve_result ) )
					{
						rInfo.resolve_token_noun_data = resolve_result;
						rInfo.resolve_str = "";
						
						switch ( resolve_result )
						{
							case NL_BOOL:
								rInfo.resolve_int = rOtherInfo.resolve_int;
							case NL_INT:
								rInfo.resolve_int = rOtherInfo.resolve_int;
							case NL_FLOAT:
								rInfo.resolve_float = rOtherInfo.resolve_float;
							default:
								var err_msg = "INTERNAL ERROR: importWords " + words[ i ] + " Unexpected resolve result. Skipping to next Word.\n";
								
								importWords_msgs += err_msg;
								error( err_msg, RED );
								i++;
								continue;
						}
					}
				}
			}
			
			if ( NL_VERB == data.findWordDef_type )
			{
				rInfo.resolve_token_noun_data = NL_TYPE_UNKNOWN;
				rInfo.resolve_op_meaning = OP_IS_UNKNOWN;
				rInfo.resolve_float = 0.0;
				rInfo.resolve_int = 0;
			}

			if ( 0 <= dictIdx )
			{
				// Word already in Dictionary. Does Dictionary allow Replacement
				var replace_result = dict.addWord( words[ i ], data.findWordDef_type, 
									rInfo.resolve_out_token, rInfo.resolve_op_meaning,
									rInfo.resolve_str, rInfo.resolve_float, 
									rInfo.resolve_int, rInfo.resolve_token_noun_data,
									dictIdx );
				
				if ( ( 0 != cast( replace_result, Int ) )
				  || ( 0 < dict.addWord_msg.length ) )
				{
					status( Std.string( rInfo ) );
					status( dict.addWord_msg );
				}
				
				result = replace_result;
			}
			else
			{
				var add_result = dict.addWord( words[ i ], data.findWordDef_type, 
									rInfo.resolve_out_token, rInfo.resolve_op_meaning,
									rInfo.resolve_str, rInfo.resolve_float, 
									rInfo.resolve_int, rInfo.resolve_token_noun_data );
				
				if ( ( 0 != cast( add_result, Int ) )
				  || ( 0 < dict.addWord_msg.length ) )
				{
					status( Std.string( rInfo ) );
					status( dict.addWord_msg );
				}
				
				result = add_result;
			}
			i++;
		}
		
		if ( 0 < words.length )
		{
			dict.sortDictionary();
		}
		
		return result;
	}
	
	
}