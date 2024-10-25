/* FileTypes.hx	Types of forGL files
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


//    List of File types
enum
abstract FileTypes(Int) {

	var FILE_IS_UNKNOWN        = 0;
	
	var FILE_IS_TEXT           = 1;		// .txt or log files like Export log

	var FILE_IS_DICTIONARY     = 2;		// .toml Dictionary
	
//	var FILE_IS_COMMANDS       = 3;		// possible list of commands to forGL app ?
	
//	var FILE_IS_DATA           = 4;		// possible data file to give to forGL app ?
	
}

