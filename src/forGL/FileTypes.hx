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
@:enum
abstract FileTypes(Int) {

	var FILE_IS_UNKNOWN        = 0;
	
	var FILE_IS_DICTIONARY     = 1;
	
	var FILE_IS_COMMANDS       = 2;
	
	var FILE_IS_DATA           = 3;
	
}

