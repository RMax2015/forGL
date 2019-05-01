/* Data.hx	This is the Data level interface of forGL
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * NOTES:
 * See block comment at end of this file for more information.
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
 * ...
 * @author Randy Maxwell
 */

package forGL.data;

using Sys;

//import haxe.Log;

#if ! js
	import sys.FileSystem;
	import sys.io.File;
	import sys.io.FileOutput;
#end

import forGL.UI.ForGL_ui.msg    as  msg;
import forGL.UI.ForGL_ui.error  as  error;

// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

using  forGL.NLTypes;

import forGL.Meanings.ReturnMeanings;

import forGL.FileTypes.FileTypes   as   FileTypes;

import forGL.data.Toml.ForGL_toml     as   ForGL_toml;


using forGL.data.Data.ForGL_data;

 
//				Data Interface to persistent data
class ForGL_data
{
	public function new() 
	{
	}
	
	public  var actual_path_file : String = "";
	public  var actual_file_type : FileTypes = FILE_IS_UNKNOWN;
	
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
	
	private  var toml : ForGL_toml;
	
	
	public function callCount() : Int
	{
		return data_call_count;
	}
	
/* Initialize  Data  file handling */
	public function init( path_file : String, file_type : FileTypes ) : ReturnMeanings
	{
		var result = RET_IS_OK;
		
		data_call_count++;

	#if ( sys || js ) 
		toml = new ForGL_toml();
		
		result = loadFile( path_file, file_type );
		
		
		
	#else
			
		result = RET_IS_NOT_IMPLEMENTED;
		
		
	#end
		
		return result;
	}
	
	
/* Clean up  Data  file handling */	
	public function cleanUp() : ReturnMeanings
	{
		var ret_val = RET_IS_OK;

#if ( sys ) 
	
	try
	{
		toml.cleanUp();
		
		
		
		
	}
	catch ( e:Dynamic ) 
	{  
		error( "\nINTERNAL ERROR: Exception in forGL_data.cleanUp(): " + Std.string( e ) + " \n");
		
		ret_val = RET_IS_INTERNAL_ERROR;
	};
	
#end
	
		return ret_val;
	}
	
	
// Load all or part of a file into memory
//
	public function loadFile( path_name : String, expected_type : FileTypes ) : ReturnMeanings
	{
		var ret_val = RET_IS_OK;
		
		// TODO  sometime add support for SQL or XML or JSON files
		
		// Make sure this is has  .toml  file extension
		var extension = path_name.substr( path_name.length - 5, 5 );
		if ( ".toml" != extension.toLowerCase() )
		{
			error( "ERROR: File extension not .toml : " + path_name + " " + extension + "\n" );
			
			ret_val = RET_IS_USER_ERROR_DATA;
		}
		else
		{
			ret_val = toml.init( path_name, expected_type );	// Start up  toml  file handler
			
			if ( ReturnMeanings.RET_IS_OK == ret_val )
			{
				actual_file_type = toml.actual_file_type;
				actual_path_file = toml.actual_path_file;
			}
		}
		
		return ret_val;
	}
	
	
// Get List of words (returns visible names)
//
	public function getListOfWords( ?warn_if_not_unique = true ) : Array<String8>
	{
		var wordList = toml.getWordList( warn_if_not_unique );
	
		return wordList;
	}
	

// Get details about a word
//
	public var findWordDef_type = NL_TYPE_UNKNOWN;
	
	public function findWordDef( word_visible_name : String8, rInfo : ResolveInfo ) : ReturnMeanings
	{
		findWordDef_type = NL_TYPE_UNKNOWN;
		
		var ret_val = toml.getWord( word_visible_name, rInfo );
		
		if ( 0 == cast( ret_val, Int ) )
		{
			findWordDef_type = toml.getWord_type;
		}
		
		return ret_val;
	}
	
	
// Allow upper level code to see lower level errors
	public function getDataErrors() : Array<String8>
	{
		return toml.error_msgs;
	}
	
	
// Allow upper level code to see lower level errors
	public function getDataWarnings() : Array<String8>
	{
		return toml.warning_msgs;
	}


// Renames a file to a new path and name
//
	public function renameFile( old_path_name : String, new_path_name : String ) : ReturnMeanings
	{
		var ret_val = RET_IS_OK;
	try
	{
	#if ! js
		FileSystem.rename( old_path_name, new_path_name );
	#end
	}
	catch ( e : Dynamic ) 
	{
		// Perhaps the new_path_name already exists?
		
		// msg( "\nException in renameFile(): " + Std.string( e ) + " \n");
		ret_val = RET_IS_INTERNAL_ERROR;
	};
	
		return ret_val;
	}


// Save Data to a File at a path and name
//
	public function saveToFile( new_path_name : String ) : ReturnMeanings
	{
		var save_result = toml.saveData( new_path_name );

		return save_result;
	}


//		Replace contents or Add a new word
//
	public var replaceOrAddWord_replaced = false;

	public function replaceOrAddWord( word_visible_name : String8, word_type : NLTypes, rInfo : ResolveInfo ) : ReturnMeanings
	{
		replaceOrAddWord_replaced = false;
		
		var replaceOrAdd_result = toml.changeOrAddWord( word_visible_name, word_type, rInfo );
		
		if ( 0 == cast( replaceOrAdd_result, Int ) )
		{
			
			replaceOrAddWord_replaced = toml.changeOrAddWord_changed;
		}
		
		return replaceOrAdd_result;
	}

}
