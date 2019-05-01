/* Meanings.hx	Meanings of Operators and Return values
 * 
 * Prototype (VERY Experimental) of forGL application
 * 
 * ...
 * @author Randy Maxwell
 */

package forGL;


// Improved UTF8 support
using hx.strings.Strings;
using hx.strings.String8;

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment    as    comment;

//    List of Operator Meanings
//
// It is OK if there are gaps in the integer values used.
// However, somewhat (very slightly?) better performance may be found if below has NO gaps. 
//     Needs comparison timing tests.
@:enum
abstract OpMeanings(Int) {

	var OP_IS_UNKNOWN        = 0;
	
	// Arithmetic				(these need 2 Data items)
	var OP_IS_PLUS           = 1;
	var OP_IS_MINUS          = 2;
	var OP_IS_MULTIPLY       = 3;
	var OP_IS_DIVIDE         = 4;
	var OP_IS_MODULO         = 5;
	
	// Math						(these need 2 Data items)
	var OP_IS_MIN			 = 6;
	var OP_IS_MAX			 = 7;
	var OP_IS_ATAN2			 = 8;
	var OP_IS_POW			 = 9;
	
	// Comparison				(these need 2 Data items)
	var OP_IS_EQUAL			 = 10;
	var OP_IS_NOT_EQUAL		 = 11;
	var OP_IS_LESS_THAN		 = 12;
	var OP_IS_LESS_OR_EQUAL	 = 13;
	var OP_IS_GREATER_THAN	 = 14;
	var OP_IS_GREATER_OR_EQUAL = 15;
	
	// Grouping					(grouping must have both a Left and Right side Operator)
	var OP_IS_PAREN_LEFT       = 16;		// Parens ( ) enclose an Expression OR as a call type argument list
	var OP_IS_PAREN_RIGHT      = 17;
	var OP_IS_EXPRESSION_START = 18;
	var OP_IS_EXPRESSION_END   = 19;
	var OP_IS_BRACKET_LEFT     = 20;		// Brackets [ ] enclose a list of values or Array [ elements ]
	var OP_IS_BRACKET_RIGHT    = 21;
	var OP_IS_LIST_START       = 22;
	var OP_IS_LIST_END         = 23;
	var OP_IS_BRACE_LEFT       = 24;		// Braces { } enclose a block of statements
	var OP_IS_BRACE_RIGHT      = 25;
	var OP_IS_BLOCK_START      = 26;
	var OP_IS_BLOCK_END        = 27;
	
	// Require use of string		(must be 2 strings)
	var OP_IS_CONCAT         = 28;
	var OP_IS_UNCONCAT       = 29;
	
	// Math						(these need NO Data items)
	var OP_IS_PI             = 30;
	var OP_IS_RANDOM         = 31;
	
	// Noun change
	var OP_IS_ASSIGNMENT     = 32;	// direction of Assignment determined later =
	var OP_IS_ASSIGN_TO      = 33;	// direction of Assignment  TO  the RIGHT   =:	 : represents the Destination side
	var OP_IS_ASSIGN_FROM    = 34;	// direction of Assignment FROM the RIGHT   :=
	var OP_IS_DECREMENT      = 35;  // Noun or Local Noun is Integer or Float OR String can be made Integer or Float subtract 1 and assign
	var OP_IS_INCREMENT      = 36;  // as for decrement but add 1 and assign
	
	// Punctuation
	var OP_IS_PERIOD         = 45;
	var OP_IS_COMMA          = 46;
	var OP_IS_COLON          = 47;
	var OP_IS_SEMICOLON      = 48;
	
	var OP_IS_PUNCTUATION    = 49;

	// Math Functions			(these need 1 Data item)
	// abs, sin, cos, tan, asin, acos, atan, atan2, 
	// log, sqrt, round, ceil, floor
	var OP_IS_ABS            = 50;
	var OP_IS_TO_DEGREES     = 51;
	var OP_IS_TO_RADIANS     = 52;
	var OP_IS_SIN            = 53;
	var OP_IS_COS            = 54;
	var OP_IS_TAN            = 55;
	var OP_IS_ASIN           = 56;
	var OP_IS_ACOS           = 57;
	var OP_IS_ATAN           = 58;
	var OP_IS_EXP            = 59;
	var OP_IS_LN             = 60;		// natural base e Logarithim == ln
	var OP_IS_LOG            = 61;		// base 10 Logarithim == log
	var OP_IS_SQRT           = 62;
	var OP_IS_ROUND          = 63;
	var OP_IS_FLOOR          = 64;
	var OP_IS_CEIL           = 65;		// IF ANY HIGHER VALUES ARE ADDED UPDATE OpMeaningsValLimits BELOW ! ! !

}


@:enum
abstract OpMeaningsValLimits(Int) {
	var OP_IS_LOWEST_VAL     = 0;   // = cast( OP_IS_UNKNOWN, Int ); Inline variable initialization must be a constant value

	var OP_IS_HIGHEST_VAL    = 65;  // = cast(    OP_IS_CEIL, Int );
}

//    List of Return value Meanings
//
//    Negative numbers are used for Error or Stop Meanings 
//		where Error recovery is unwanted or unlikely by runtime program. 
//		User needs to change something
//			OR
//		There is a Defect in the code running that was hit
//			and reported an INTERNAL ERROR
//
//	Zero means OK, normal results as expected.
//
//	Positive means that some Verb or Operator or something 
//		can not go farther now but other words can be run
//
@:enum
abstract ReturnMeanings(Int) {

// ERRORS about runtime code Defects
	var RET_IS_INTERNAL_ERROR     = -11;    // INTERNAL ERROR found
	var RET_IS_NOT_IMPLEMENTED    = -10;    // INTERNAL ERROR  NOT IMPLEMENTED
	
// ERRORS using runtime services
	var RET_FILE_NOT_FOUND        = -9;
	var RET_FILE_PATH_NOT_FOUND   = -8;
	
// ERRORS about User code
	var RET_IS_USER_ERROR_LOGICAL = -5;     // Ex: Extra Operators 
	var RET_IS_USER_ERROR_SYNTAX  = -4;     // Ex: Using a Local Noun without giving it a value
	var RET_IS_USER_ERROR_DATA    = -3;     // Data missing or type not correct. Ex: String won't convert to Number.
	var RET_IS_USER_ERROR         = -2;		// Non specific
	
// STOP
	var RET_IS_USER_ESC           = -1;     // User stopped runtime by choice
	
// OK
	var RET_IS_OK                 = 0;      // OK, normal results as expected
	
// STATUS giving a little detail
	var RET_IS_NEEDS_DATA         = 1;      // not enough Data  now, will try other words
	var RET_IS_NEEDS_NOUN         = 2;      // not enough Nouns now, will try other words
	var RET_IS_NEEDS_PUNCTUATION  = 3;      // no Punctuation yet, will try other words
}


class  MeansWhat
{
// 		Helper to give a readable string for an Operator or an internal string
//
	public static function opMeanAsStr( op_meaning : OpMeanings, ?ret_internal : Bool = false ) : String8
	{
		comment( "Helper to give a readable string for an Operator or an internal string" );
		var ret_str = "";
		
		switch ( op_meaning )
		{
			case OP_IS_UNKNOWN:
				if ( ret_internal )
					ret_str = "";
				else
					ret_str = "Unknown";
		
	// Math operators using 2 Data items
			case OP_IS_PLUS:
				if ( ret_internal )
					ret_str = "+";
				else
					ret_str = "Plus";
		
			case OP_IS_MINUS:
				if ( ret_internal )
					ret_str = "-";
				else
					ret_str = "Minus";
								
			case OP_IS_MULTIPLY:
				if ( ret_internal )
					ret_str = "*";
				else
					ret_str = "Multiply by";
		
			case OP_IS_DIVIDE:
				if ( ret_internal )
					ret_str = "/";
				else
					ret_str = "Divide by";

			case OP_IS_MODULO:
				if ( ret_internal )
					ret_str = "%";
				else
					ret_str = "Modulo";
			
			case OP_IS_MIN:
				if ( ret_internal )
					ret_str = "min";
				else
					ret_str = "Minimum";
			
			case OP_IS_MAX:
				if ( ret_internal )
					ret_str = "max";
				else
					ret_str = "Maximum";
				
			case OP_IS_ATAN2:
				if ( ret_internal )
					ret_str = "atan2";
				else
					ret_str = "ArcTan2";
				
			case OP_IS_POW:
				if ( ret_internal )
					ret_str = "pow";
				else
					ret_str = "to Power of";
				
	// Comparison returning a Bool. These need 2 Data items
			case OP_IS_EQUAL:
				if ( ret_internal )
					ret_str = "==";
				else
					ret_str = "Is Equal?";
		
			case OP_IS_NOT_EQUAL:
				if ( ret_internal )
					ret_str = "!=";
				else
					ret_str = "Is Not Equal?";
				
			case OP_IS_LESS_THAN:
				if ( ret_internal )
					ret_str = "<";
				else
					ret_str = "Is Less Than?";
				
			case OP_IS_LESS_OR_EQUAL:
				if ( ret_internal )
					ret_str = "<=";
				else
					ret_str = "Is Less or Equal?";
				
			case OP_IS_GREATER_THAN:
				if ( ret_internal )
					ret_str = ">";
				else
					ret_str = "Is Greater Than?";
				
			case OP_IS_GREATER_OR_EQUAL:
				if ( ret_internal )
					ret_str = ">=";
				else
					ret_str = "Is Greater or Equal?";
	
	// Grouping
			case OP_IS_PAREN_LEFT:
				if ( ret_internal )
					ret_str = "(";
				else
					ret_str = "Left Paren";
			
			case OP_IS_PAREN_RIGHT:
				if ( ret_internal )
					ret_str = ")";
				else
					ret_str = "Right Paren";
					
			case OP_IS_EXPRESSION_START:
				if ( ret_internal )
					ret_str = "(";
				else
					ret_str = "Expression start";
			
			case OP_IS_EXPRESSION_END:
				if ( ret_internal )
					ret_str = ")";
				else
					ret_str = "Expression end";
			
			case OP_IS_BRACKET_LEFT:
				if ( ret_internal )
					ret_str = "[";
				else
					ret_str = "Left Square Bracket";
			
			case OP_IS_BRACKET_RIGHT:
				if ( ret_internal )
					ret_str = "]";
				else
					ret_str = "Right Square Bracket";
					
			case OP_IS_LIST_START:
				if ( ret_internal )
					ret_str = "(";
				else
					ret_str = "List start";
			
			case OP_IS_LIST_END:
				if ( ret_internal )
					ret_str = ")";
				else
					ret_str = "List end";
				
			case OP_IS_BRACE_LEFT:
				if ( ret_internal )
					ret_str = "{";
				else
					ret_str = "Left Curly Brace";
			
			case OP_IS_BRACE_RIGHT:
				if ( ret_internal )
					ret_str = "}";
				else
					ret_str = "Right Curly Brace";
					
			case OP_IS_BLOCK_START:
				if ( ret_internal )
					ret_str = "{";
				else
					ret_str = "Block start";
			
			case OP_IS_BLOCK_END:
				if ( ret_internal )
					ret_str = "}";
				else
					ret_str = "BLock end";
			
	// Require use of string		(must be 2 strings)
			case OP_IS_CONCAT:
				if ( ret_internal )
					ret_str = "concat";
				else
					ret_str = "Concatenate";
				
			case OP_IS_UNCONCAT:
				if ( ret_internal )
					ret_str = "unconcat";
				else
					ret_str = "Un Concatenate";
	
	// Math Operators that need NO data
			case OP_IS_PI:
				if ( ret_internal )
					ret_str = "pi";
				else
					ret_str = "Pi";
				
			case OP_IS_RANDOM:
				if ( ret_internal )
					ret_str = "random";
				else
					ret_str = "Random";
				
				
		// Noun change
			case OP_IS_ASSIGNMENT:
				if ( ret_internal )
					ret_str = "=";
				else
					ret_str = "Assignment";

			case OP_IS_ASSIGN_TO:
				if ( ret_internal )
					ret_str = "=:";
				else
					ret_str = "Assign into";

			case OP_IS_ASSIGN_FROM:
				if ( ret_internal )
					ret_str = ":=";
				else
					ret_str = "Assign from";
	
			case OP_IS_DECREMENT:
				if ( ret_internal )
					ret_str = "--";
				else
					ret_str = "Decrease by 1";
	
			case OP_IS_INCREMENT:
				if ( ret_internal )
					ret_str = "++";
				else
					ret_str = "Increase by 1";
	
		// Punctuation
			case OP_IS_PERIOD:
				if ( ret_internal )
					ret_str = ".";
				else
					ret_str = "Period";
	
			case OP_IS_COMMA:
				if ( ret_internal )
					ret_str = ",";
				else
					ret_str = "Comma";
			
			case OP_IS_COLON:
				if ( ret_internal )
					ret_str = ":";
				else
					ret_str = "Colon";
		
			case OP_IS_SEMICOLON:
				if ( ret_internal )
					ret_str = ";";
				else
					ret_str = "Semicolon";

			case OP_IS_PUNCTUATION:
				if ( ret_internal )
					ret_str = ".";
				else
					ret_str = "Punctuation";

	// Math operators using 1 Data item
			case OP_IS_ABS:
				if ( ret_internal )
					ret_str = "abs";
				else
					ret_str = "Absolute value";
				
			case OP_IS_TO_DEGREES:
				if ( ret_internal )
					ret_str = "degrees";
				else
					ret_str = "to Degrees";
				
			case OP_IS_TO_RADIANS:
				if ( ret_internal )
					ret_str = "radians";
				else
					ret_str = "to Radians";
				
			case OP_IS_SIN:
				if ( ret_internal )
					ret_str = "sin";
				else
					ret_str = "Sine";
				
			case OP_IS_COS:
				if ( ret_internal )
					ret_str = "cos";
				else
					ret_str = "Cosine";
				
			case OP_IS_TAN:
				if ( ret_internal )
					ret_str = "tan";
				else
					ret_str = "Tangent";
			
			case OP_IS_ASIN:
				if ( ret_internal )
					ret_str = "asin";
				else
					ret_str = "ArcSine";
	
			case OP_IS_ACOS:
				if ( ret_internal )
					ret_str = "acos";
				else
					ret_str = "ArcCosine";
				
			case OP_IS_ATAN:
				if ( ret_internal )
					ret_str = "atan";
				else
					ret_str = "ArcTangent";
				
		// Comment from  Haxe  Math.hx
		//     ln( exp(v) ) is always == v
		//     exp( ln(v) ) is always == v   also true
		
			case OP_IS_EXP:
				if ( ret_internal )
					ret_str = "exp";
				else
					ret_str = "e to the power of";
				
			case OP_IS_LN:
				if ( ret_internal )
					ret_str = "ln";
				else
					ret_str = "natural Logarithm";  //  ln  NOT log base 10
			
			case OP_IS_LOG:
				if ( ret_internal )
					ret_str = "log";
				else
					ret_str = "base 10 Logarithm";  //  log base 10

			case OP_IS_SQRT:
				if ( ret_internal )
					ret_str = "sqrt";
				else
					ret_str = "SquareRoot";
			
			case OP_IS_ROUND:
				if ( ret_internal )
					ret_str = "round";
				else
					ret_str = "Round";
			
			case OP_IS_FLOOR:
				if ( ret_internal )
					ret_str = "floor";
				else
					ret_str = "Floor";
				
			case OP_IS_CEIL:
				if ( ret_internal )
					ret_str = "ceil";
				else
					ret_str = "Ceiling";
				
			// Do NOT have a default: here. Haxe compiler will then complain about missing cases. Nice!
		}
	
	/* COMMENTED OUT. As long as there is no default: for switch above.
		if ( 0 == ret_str.length )
		{
			msg( "\n INTERNAL ERROR: Invalid op_meaning given \n" );
			ret_str = "INTERNAL ERROR: Invalid op_meaning";
		}
	*/
		
		return ret_str;
	}
	
	
// 		Helper to give a readable string for a Return value number
//
	public static function returnMeanAsStr( ret_meaning : ReturnMeanings ) : String8
	{
		comment( "Helper to give a readable string for a Return value number" );
		var ret_str = "";
		
		switch ( ret_meaning )
		{
	// ERRORS about runtime code Defects
			case RET_IS_INTERNAL_ERROR:
				ret_str = "INTERNAL ERROR found";
			case RET_IS_NOT_IMPLEMENTED:
				ret_str = "INTERNAL ERROR: is NOT IMPLEMENTED";
	
	// ERRORS using runtime services
			case RET_FILE_PATH_NOT_FOUND:
				ret_str = "ERROR: File path not found";
			case RET_FILE_NOT_FOUND:
				ret_str = "ERROR: File not found";

	// ERRORS about User code
			case RET_IS_USER_ERROR_LOGICAL:
				ret_str = "User code has a Logical error";
			case RET_IS_USER_ERROR_SYNTAX:
				ret_str = "User code has a Syntax error";
			case RET_IS_USER_ERROR_DATA:
				ret_str = "Data type or value given is not appropriate";
			case RET_IS_USER_ERROR:
				ret_str = "User code has an error";

	// STOP
			case RET_IS_USER_ESC:
				ret_str = "User wanted to Stop";
	// OK
			case RET_IS_OK:
				ret_str = "OK, normal result";
	
	// STATUS giving a little detail
			case RET_IS_NEEDS_DATA:
				ret_str = "Not enough Data now, trying next words";
			case RET_IS_NEEDS_NOUN:
				ret_str = "Not enough Nouns now, trying next words";
			case RET_IS_NEEDS_PUNCTUATION:
				ret_str = "No punctuation yet, trying next words";
		}
		
		return ret_str;
	}
	
}
