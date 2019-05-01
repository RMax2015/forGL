/* ExportAs.hx	 forGL Export selected Verb(s) As other programming languages
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * 
 * Exporting from the Dictionary in memory to the Data layer 
 * to allow persistent Dictionary changes.
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

import forGL.Dictionary.DictWord;
import forGL.Dictionary.NLDictionary;

import forGL.Meanings.ReturnMeanings;

import forGL.UI.ForGL_ui.msg     as  msg;
import forGL.UI.ForGL_ui.status  as  status;

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment   as  comment;

using forGL.ExportAs.NLExportAs;


@:enum
abstract ExportAsTypes(Int) {

	var EXPORT_AS_UNKNOWN = 0;

	var EXPORT_AS_HAXE = 1;		// YES ! ! !

}


//
//		Import support for Dictionaries (or Library Vocabularies?)
//
class  NLExportAs
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


//		Export a Verb just run as a programming language.
//
	public var exportAsCode_msgs : String8 = "";
	
	public var verbCount = 0;
	
	//public var 
	
/*
	public function exportAsCode( dict : NLDictionary, dict_path_file : String8, data : ForGL_data, ?export_lang = EXPORT_AS_HAXE ) : ReturnMeanings
	{
		comment( "", "Export a Verb just run as a programming language.", "" );
		
		var result = RET_IS_OK;
		
		exportAsCode_msgs = "";
		
		
		
		exportAsCode_msgs += "Information: " + Std.string( verbCount ) + " Verbs to Export as .\n";
		
		if ( 0 == verbCount )
			return RET_IS_OK;
		
		if ( 0 == imported_words.length )
		{
			// TODO  Create a new .toml file perhaps ?
			
			return RET_IS_NOT_IMPLEMENTED;
		}
		
		if ( 0 == dict.path_dictionary_file.length8() )
		{
			exportAsCode_msgs += "INTERNAL ERROR: Export: No physical Dictionary file available to rename.\n";
			return RET_IS_INTERNAL_ERROR;
		}
		
		var str = "Verbs to Export as Code are: " + Std.string( out_words ) + "\n";
		//msg( str );
		exportAsCode_msgs += str;
		
		// TODO  change to use Data layer or Dictionary for some of this
		
		var new_file_name = dict.path_dictionary_file;
		var extension = new_file_name.substr( new_file_name.length - 5, 5 );
		
		var backup_name = new_file_name.substr( 0, new_file_name.length - extension.length8() );
		
		comment( "Date and Time as part of name" );
		var now_date = Date.now();
		var date_raw = now_date.toString();		// YYYY-MM-DD HH:MM:SS  format
		var date_str = "";
		var i = 0;
		while ( i < date_raw.length )
		{
			var char = date_raw.charAt( i );
			if ( ( "-" == char )
			  || ( ":" == char ) )
				date_str += "_";
			else
			if ( " " == char )
				date_str += "__";
			else
				date_str += char;
			
			i++;
		}
		
		backup_name += "_Backup_" + date_str + extension;
		
		data.renameFile( dict.path_dictionary_file, backup_name );
		
		var rInfo = new ResolveInfo();
		
		var dict_idx = -1;
		
		i = 0;
		while ( i < out_words.length )
		{
			dict_idx = dict.findWord( out_words[ i ] );
			if ( dict_idx < 0 )
			{
				// Just got a list of words from Dictionary. WHY is there a PROBLEM HERE?
				exportAsCode_msgs += "INTERNAL ERROR: findWord of " + out_words[ i ] + " was not found. Skipping to next word.\n";
				i++;
				continue;
			}
			
			var dict_word : DictWord = dict.unique_Dictionary_Words[ dict_idx ];
			
			rInfo.resolve_str             = dict_word.token_str;
			rInfo.resolve_float           = dict_word.token_float;
			rInfo.resolve_int             = dict_word.token_int;
			rInfo.resolve_op_meaning      = dict_word.token_op_means;
			rInfo.resolve_token_noun_data = dict_word.token_noun_data;
			rInfo.resolve_out_token       = dict_word.internal_token;
			
			var replaceOrAdd_result = data.replaceOrAddWord( dict_word.visible_token, dict_word.token_type, rInfo );
			
			if ( 0 == cast( replaceOrAdd_result, Int ) )
			{
				if ( data.replaceOrAddWord_replaced )
				{
					exportWords_replaced++;
					
					words_added.push( 0 );
					words_replaced.push( 1 );
				}
				else
				{
					exportWords_added++;
					
					words_added.push( 1 );
					words_replaced.push( 0 );
				}
			}
			else
			{
				result = replaceOrAdd_result;
				
				words_added.push( 0 );
				words_replaced.push( 0 );
			}

			i++;
		}
		
		var save_result = data.saveToFile( dict.path_dictionary_file );
		
		if ( 0 != cast( save_result, Int ) )
		{
			if ( RET_IS_OK == result )
				result = save_result;
		}

		return result;
	}
*/
	
}