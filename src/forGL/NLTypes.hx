/* NLTypes.hx	These are the Types used by forGL
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

using forGL.Meanings;

import forGL.UI.ForGL_ui.msg  as  msg;

// Have  Comments  in Haxe generated output programming languages sources
import  forGL.Comments.comment    as    comment;


//     Types of tokens found from simple parsing of Natural Language text

@:enum
abstract NLTypes(Int) {

	var NL_TYPE_UNKNOWN = 0;
	
// A single line Comment
	var NL_COMMENT = 1;    		// starts with: # and continues to end of line (requires a LF or CR/LF to end)
								// READ ONLY for original comment: but may be converted to other NL types
								// other NL types may be put in as a New comment, such as code generation

// Actions that may consume or produce Data  (or both, such as Multiply)
	var NL_OPERATOR = 2;		// Like a Built In Verb. NOT Editable. Like code. A pre defined well known action.
								// Like a Math or Comparison or Logical or Binary Operator or Punctuation

	var NL_VERB_BI  = 3;		// Built In Verb. NOT Editable. Like code.
								// Like a reserved keyword in other programming languages.

// Named actions that were User defined
	var NL_VERB     = 4;		// Editable word definition. Like code.
	
// INTERNAL type used to simplify Interpreter a little
	var NL_VERB_RET = 5;		// RETURN from a Verb. Like return from a code call.

// Named Data items
	var NL_NOUN       = 6;		// Generic data. Handle as if String, Int or Float or Bool in Haxe
	var NL_NOUN_LOCAL = 7;		// Like a local variable within a single Verb definition

// Data types
	var NL_STR    = 8;      	// a string of 0 or more characters
	 
//	var nl_number = ?;			// a known number (not decided if Float or Int, likely Int, NOT USED NOW)
	var NL_INT    = 9;			// a number restricted to integer values. Haxe default Integer
	 
	var NL_BOOL   = 10;			// 1 = true. Everything else is false.  Stored as Int in Haxe
//	var nl_int32  = ?;			// a signed 32 bit integer. Haxe default Integer size.
//	var nl_int64  = ?;			// a signed 64 bit integer. Can be default Int size for Java or 64 bit C++ compiles.
	var NL_FLOAT = 11;			// a 64 bit floating point number. Haxe also has 32 bit Single on some platforms

// Choose WHAT to do next
	var NL_CHOICE = 12;			// if ... else, for, while, do ... while, switch ... case default, break, continue, return
								// typical flow control keywords, maybe use as Operators if easier to do later

}

// Helper to use when calling resolveType
class ResolveInfo
{
// Variables for resolveType to output to avoid some extra type resolving later
//
// ONLY 1 of these is valid after a given call to resolveType. 
//     Based on type_found return value. Others have old data or mangled data.
//
	public var resolve_token_noun_data : NLTypes;
	public var resolve_int             : Int;
	public var resolve_float           : Float;
	public var resolve_str             : String8;
	
	// Allow for substitution while resolving a type
	public var resolve_out_token       : String8;
	
	// True if above out token should be used instead of given in token 
	public var resolve_use_out         : Bool;

	// Allow meaning of an Operator from above list to be returned
	public var resolve_op_meaning      : OpMeanings;

	
	public function new() 
	{
		resolve_token_noun_data = NL_TYPE_UNKNOWN;
		resolve_int             = 0;
		resolve_float           = 0.0;
		resolve_str             = "";
		resolve_out_token       = "";
		resolve_use_out         = false;
		resolve_op_meaning      = OP_IS_UNKNOWN;
	}
}


class  NLTypeAs
{
// Helper to return a readable string of NL types
//
	public static function nlTypeAsStr( nl_type : NLTypes ) : String
	{
		var ret_str = "";
		
		switch ( nl_type )
		{
			case NL_TYPE_UNKNOWN:
				ret_str = "Unknown";
			
			case NL_COMMENT:
				ret_str = "Comment";
				
			case NL_OPERATOR:
				ret_str = "Operator";
				
			// Like a reserved keyword in other programming languages.
			case NL_VERB_BI:
				ret_str = "Verb, Built In";
									
			case NL_VERB:
				ret_str = "Verb";
				
			case NL_VERB_RET:
				ret_str = "Return from Verb";
				
			case NL_NOUN:
				ret_str = "Noun";
				
			case NL_NOUN_LOCAL:
				ret_str = "Noun, Local";

			case NL_STR:
				ret_str = "String";
				
			case NL_INT:
				ret_str = "Integer";
				
			case NL_BOOL:
				ret_str = "Bool";

		/* Commented out to reduce overall number of different types to parse/run
			if ( nl_type == nl_number )	
				ret_str = "Number";
			if ( nl_type == nl_int32 )
				ret_str = "signed 32 bit Integer";
			if ( nl_type == nl_int64 )
				ret_str = "signed 64 bit Integer";
		*/

			case NL_FLOAT:
				ret_str = "Float";
				
			case NL_CHOICE:
				ret_str = "Choice";
		
		// Do NOT have a default: here. Haxe compiler will then complain about missing cases. Nice!
		
		}
		
		/* COMMENTED OUT. As long as there is no default: for switch above.
		if ( 0 == ret_str.length )
		{
			msg( "\nINTERNAL ERROR: Invalid nl_type given \n" );
			ret_str = "INTERNAL ERROR: Invalid nl_type";
		}
		*/
		
		return ret_str;
	}


	
// See if given token matches a Natural Language type
// Returns the Type of the Natural Language token
//
// Preconditions:
//     input string has at least 1 character
//
// Side effects:
//     changed ResolveInfo members in addition to returning the Type of the token 
// 
// 
	public static function resolveType( in_token : String8, rInfo : ResolveInfo, ?run_verbose = false,
										?trim_quotes : Bool = false ) : NLTypes
	{
		comment( "See if given token matches a Natural Language type" );
		comment( "Returns the Type of the Natural Language token" );
		var type_found = NL_TYPE_UNKNOWN;
		var verbose = run_verbose;
		
		rInfo.resolve_use_out = false;
		
		if ( ( "true"  == in_token )
		  || ( "false" == in_token ) )
		{
			if ( "true" == in_token )
				rInfo.resolve_int = 1;
			else
				rInfo.resolve_int = 0;
			return NL_BOOL;
		}
		
		// Check for a Quoted String. Double quote character at start and end.
		if ( ( "\"" == in_token.charAt8( 0 ) )
		  && (  1    < in_token.length8() ) 
		  && ( "\"" == in_token.charAt8( in_token.length8() -1 ) ) )
		{
			// NOTE: An empty string given by "" is valid input here
			rInfo.resolve_str = in_token;
			type_found = NL_STR;
			
			if ( ! trim_quotes )
				return type_found;			// Done. Do NOT drop through.
			else
			{
				if ( 3 <= in_token.length8() )
					in_token = in_token.trim( "\"" );	// trim Quote characters
				else
					return type_found;
			}
		}
		
		rInfo.resolve_str = "";
		rInfo.resolve_float = Std.parseFloat( in_token );
		
		//		SPECIAL CASE
		// forGL Parser allowed a token like  5--7  to here. Parser changed now to do: 5 - -7
		//
		// Important Idea: The length of the Haxe parseFloat float when changed back to a string 
		//     is SHORTER than original token string (in this case 5 the --7 seem to be ignored by Haxe parseFloat). 
		//     It should be same length or longer.
		//     Keep in mind that this is for numbers WITHOUT a decimal point.
		
		if ( ! Math.isNaN( rInfo.resolve_float ) )
		{
		/*
			// Test code for Haxe support of Exponential notation
			{
				var test_str = "-1.000e-7";
				var test_float = Std.parseFloat( test_str );
				if ( ! Math.isNaN( test_float ) )
				{
					msg( "Exponential Notation OK ? " + test_str + " == " + Std.string( test_float ) + " ? \n" );
					
				}
			}
		*/
			
			// Successful Floating point number but may be just 0 (1st character) of 0x123 number string.
			// See if first 2 characters are 0x or 0X for hexadecimal number (so really Integer)
			if ( ( 0.0 == rInfo.resolve_float )  && ( 2 < in_token.length8() ) && ( "0" == in_token.charAt8( 0 ) ) )
			{
				if ( ( "x" == in_token.charAt8( 1 ) ) || ( "X" == in_token.charAt8( 1 ) ) )
				{
					// Hexadecimal so use Integer parser
					rInfo.resolve_int = Std.parseInt( in_token );
					
					if ( verbose )
						msg( "\nHex number " + in_token + " is now " + Std.string( rInfo.resolve_int ) + "\n" );

					return NL_INT;		// Done. Do NOT drop through.
				} 
			}
			
			// Valid Float (but will check more below) and definitely NOT 0x hexadecimal number.
			type_found = NL_FLOAT;
			
			// See if a valid Integer
			// There may be invalid characters (like a decimal point)
			// First check for decimal point
		//	var test_tokens = in_token.split( "." );
			var decimal_idx = in_token.indexOf8( "." );
			var test_tokens : Array<String8> = [ "" ];
			test_tokens.pop();
			
			if ( -1 != decimal_idx )
			{
				test_tokens.push( Strings.substringBefore( in_token, "." ) );
				test_tokens.push( Strings.substringAfter( in_token, "." ) );
			}
			else
				test_tokens.push( in_token );
			
			var test_tokens_len = test_tokens.length;
			
			if ( verbose )
			{
				msg( "test_tokens.length = " + Std.string( test_tokens_len ) + "\n" );
				msg( "test_tokens[0] = " + test_tokens[0] + "\n" );
			}
			
			if ( 2 == test_tokens_len )   // # of elements in array
			{
				// There was 1 decimal point.
				// If fractional part is only digit characters of 0 then really an integer
				//
				// WARNING: This way may FAIL on Exponential notation: -1.000e-7 for example
				//
				if ( 0 == Std.parseInt( test_tokens[1] ) ) 
				{
					// Fractional part is Zero so really an Int
					// Be sure by converting 1st element to Int and subtracting from float
					// Float value of Zero should be if really an Int
					test_tokens_len = 1;
					// fall through to finish checking
				}
			}
				
			if ( 1 == test_tokens_len )   // # of elements in array
			{
				// No decimal point character found or already handled
			
				rInfo.resolve_int = Std.parseInt( test_tokens[0] );
				var cast_float : Float = rInfo.resolve_int;
				var diff_float = rInfo.resolve_float - cast_float;
				
				if ( verbose )
				{
					msg( "resolve_float = " + Std.string( rInfo.resolve_float ) + "\n" );
					msg( "  cast_float  = " + Std.string( cast_float ) + "\n" );
					msg( "  diff_float  = " + Std.string( diff_float ) + "\n" );
				}
				
				// Because Float is OK so if Zero difference then Int is really the type
				if ( 0.0 == diff_float )
				{
					type_found = NL_INT;
				}
			}
			else
			{
				if ( verbose )
					msg( "test_tokens.length = " + Std.string( test_tokens.length ) + "\n" );
			}
		}
		else
		{
			// Not a valid Float number so also Not a valid Integer
			
			
			// Check for being a NL_OPERATOR
			//
			// Operators can be for MATH or see below
			
			// Check for Operators that are 1 or 2 characters and not changed
			type_found = NL_OPERATOR;
			switch ( in_token )
			{
				// Math operators
				case "+":
							rInfo.resolve_op_meaning = OP_IS_PLUS;
				case "-":
							rInfo.resolve_op_meaning = OP_IS_MINUS;
				case "*": 
							rInfo.resolve_op_meaning = OP_IS_MULTIPLY;
				case "/": 
							rInfo.resolve_op_meaning = OP_IS_DIVIDE; 
				case "%": 
							rInfo.resolve_op_meaning = OP_IS_MODULO;
				
				case "^":
							rInfo.resolve_out_token = "^";
							rInfo.resolve_op_meaning = OP_IS_POW;
				case "**":
							rInfo.resolve_out_token = "**";
							rInfo.resolve_op_meaning = OP_IS_POW;
							
				// Comparison
				case "==":
							rInfo.resolve_op_meaning = OP_IS_EQUAL;
				case "!=":
							rInfo.resolve_op_meaning = OP_IS_NOT_EQUAL;
				case "<":
							rInfo.resolve_op_meaning = OP_IS_LESS_THAN;
				case "<=":
							rInfo.resolve_op_meaning = OP_IS_LESS_OR_EQUAL;
				case ">":
							rInfo.resolve_op_meaning = OP_IS_GREATER_THAN;
				case ">=":
							rInfo.resolve_op_meaning = OP_IS_GREATER_OR_EQUAL;
	
				// Grouping operators
				case "(": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_LEFT;
							rInfo.resolve_op_meaning = OP_IS_EXPRESSION_START;
				case ")": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_RIGHT;
							rInfo.resolve_op_meaning = OP_IS_EXPRESSION_END;
				case "[": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_LEFT;
							rInfo.resolve_op_meaning = OP_IS_LIST_START;
				case "]": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_RIGHT;
							rInfo.resolve_op_meaning = OP_IS_LIST_END;
				case "{": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_LEFT;
							rInfo.resolve_op_meaning = OP_IS_BLOCK_START;
				case "}": 
							// rInfo.resolve_op_meaning = OP_IS_PAREN_RIGHT;
							rInfo.resolve_op_meaning = OP_IS_BLOCK_END;

				// Data movement to OR change a Noun or Local Noun
				case "=": 	
							rInfo.resolve_op_meaning = OP_IS_ASSIGNMENT;
				case "=:":
							rInfo.resolve_op_meaning = OP_IS_ASSIGN_TO;
				case ":=":
							rInfo.resolve_op_meaning = OP_IS_ASSIGN_FROM;
				case "--":
							rInfo.resolve_op_meaning = OP_IS_DECREMENT;
				case "++":
							rInfo.resolve_op_meaning = OP_IS_INCREMENT;

				// Punctuation
				case ".":
							rInfo.resolve_op_meaning = OP_IS_PERIOD;	// End of sentance not a decimal point
				case ",":
							rInfo.resolve_op_meaning = OP_IS_COMMA;
				case ":":
							rInfo.resolve_op_meaning = OP_IS_COLON;
				case ";":
							rInfo.resolve_op_meaning = OP_IS_SEMICOLON;
				default:
							type_found = NL_TYPE_UNKNOWN;
			}
			
			if ( NL_OPERATOR == type_found )
				return NL_OPERATOR;
			
			// Check for Operators that are NL characters and same meaning as above
			// Hard coded Words in English   TODO: Use Dictionary
			
			type_found = NL_OPERATOR;
			var in_token_lower : String8 = in_token.toLowerCase8();
			switch ( in_token_lower )
			{
		// Hard coded Math Words in Language of Mathematics, no translation or lookup needed
				case "abs":
							rInfo.resolve_out_token = "abs";
							rInfo.resolve_op_meaning = OP_IS_ABS;
			
			// Convert Radians to Degrees
				case "degree":
							rInfo.resolve_out_token = "degrees";
							rInfo.resolve_op_meaning = OP_IS_TO_DEGREES;
							
				case "degrees":
							rInfo.resolve_out_token = "degrees";
							rInfo.resolve_op_meaning = OP_IS_TO_DEGREES;
			
			// Convert Degrees to Radians
				case "radian":
							rInfo.resolve_out_token = "radians";
							rInfo.resolve_op_meaning = OP_IS_TO_RADIANS;
							
				case "radians":
							rInfo.resolve_out_token = "radians";
							rInfo.resolve_op_meaning = OP_IS_TO_RADIANS;

				case "acos":
							rInfo.resolve_out_token = "acos";
							rInfo.resolve_op_meaning = OP_IS_ACOS;

				case "asin":
							rInfo.resolve_out_token = "asin";
							rInfo.resolve_op_meaning = OP_IS_ASIN;
				case "atan":
							rInfo.resolve_out_token = "atan";
							rInfo.resolve_op_meaning = OP_IS_ATAN;
				case "atan2":
							rInfo.resolve_out_token = "atan2";
							rInfo.resolve_op_meaning = OP_IS_ATAN2;
				case "cos":
							rInfo.resolve_out_token = "cos";
							rInfo.resolve_op_meaning = OP_IS_COS;
				case "ceil":
							rInfo.resolve_out_token = "ceil";
							rInfo.resolve_op_meaning = OP_IS_CEIL;
				case "exp":
							rInfo.resolve_out_token = "exp";
							rInfo.resolve_op_meaning = OP_IS_EXP;
				case "floor":
							rInfo.resolve_out_token = "floor";
							rInfo.resolve_op_meaning = OP_IS_FLOOR;
				case "ln":
							rInfo.resolve_out_token = "ln";
							rInfo.resolve_op_meaning = OP_IS_LN;
				case "log":
							rInfo.resolve_out_token = "log";
							rInfo.resolve_op_meaning = OP_IS_LOG;
				case "max":
							rInfo.resolve_out_token = "max";
							rInfo.resolve_op_meaning = OP_IS_MAX;
				case "min":
							rInfo.resolve_out_token = "min";
							rInfo.resolve_op_meaning = OP_IS_MIN;
				case "pi":
							rInfo.resolve_out_token = "pi";
							rInfo.resolve_op_meaning = OP_IS_PI;
				case "pow":
							rInfo.resolve_out_token = "pow";
							rInfo.resolve_op_meaning = OP_IS_POW;
				case "random":
							rInfo.resolve_out_token = "random";
							rInfo.resolve_op_meaning = OP_IS_RANDOM;
				case "round":
							rInfo.resolve_out_token = "round";
							rInfo.resolve_op_meaning = OP_IS_ROUND;
				case "sin":
							rInfo.resolve_out_token = "sin";
							rInfo.resolve_op_meaning = OP_IS_SIN;
				case "sqrt":
							rInfo.resolve_out_token = "sqrt";
							rInfo.resolve_op_meaning = OP_IS_SQRT;
				case "tan":
							rInfo.resolve_out_token = "tan";
							rInfo.resolve_op_meaning = OP_IS_TAN;

				
		// Hard coded English related to Math or Strings  TODO  Use Dictionary
		//
				case "plus":
							rInfo.resolve_out_token = "+";
							rInfo.resolve_op_meaning = OP_IS_PLUS;
				case "add":
							rInfo.resolve_out_token = "+";
							rInfo.resolve_op_meaning = OP_IS_PLUS;
							
				case "minus":
							rInfo.resolve_out_token = "-";
							rInfo.resolve_op_meaning = OP_IS_MINUS;
				case "subtract":
							rInfo.resolve_out_token = "-";
							rInfo.resolve_op_meaning = OP_IS_MINUS;
							
							// multiply or multiply by or multiplied or multiplied by or times
				case "multiply":
							rInfo.resolve_out_token = "*";
							rInfo.resolve_op_meaning = OP_IS_MULTIPLY;
				case "multiplied":
							rInfo.resolve_out_token = "*";
							rInfo.resolve_op_meaning = OP_IS_MULTIPLY;
				case "times":
							rInfo.resolve_out_token = "*";
							rInfo.resolve_op_meaning = OP_IS_MULTIPLY;
							
							// divide or divide by or divided or divided by 
							// TODO: what if meaning is reversed left to right ???
							// May have to change how operands are done for Divide
				case "divide":
							rInfo.resolve_out_token = "/";
							rInfo.resolve_op_meaning = OP_IS_DIVIDE;		
				case "divided":
							rInfo.resolve_out_token = "/";
							rInfo.resolve_op_meaning = OP_IS_DIVIDE;
							
							// modulo or mod 
				case "modulo":
							rInfo.resolve_out_token = "%";
							rInfo.resolve_op_meaning = OP_IS_MODULO;
				case "mod":
							rInfo.resolve_out_token = "%";
							rInfo.resolve_op_meaning = OP_IS_MODULO;
			
			// Nouns change values
				case "equals":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_ASSIGNMENT;
				case "equal":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_ASSIGNMENT;
							
							// into may not be exactly as assignment
				case "into":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_ASSIGN_TO;
							
							// from may not be exactly as assignment
				case "from":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_ASSIGN_FROM;
			
				case "decrement":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_DECREMENT;
			
				case "increment":
							rInfo.resolve_out_token = "=";
							rInfo.resolve_op_meaning = OP_IS_INCREMENT;

			// require Strings
				case "concat":
							rInfo.resolve_out_token = "concat";
							rInfo.resolve_op_meaning = OP_IS_CONCAT;
				
				case "concatenate":
							rInfo.resolve_out_token = "concat";
							rInfo.resolve_op_meaning = OP_IS_CONCAT;
							
				case "unconcat":
							rInfo.resolve_out_token = "unconcat";
							rInfo.resolve_op_meaning = OP_IS_UNCONCAT;
				
				case "unconcatenate":
							rInfo.resolve_out_token = "unconcat";
							rInfo.resolve_op_meaning = OP_IS_UNCONCAT;
				
				default:
							type_found = NL_TYPE_UNKNOWN;
			}
			
			if ( NL_OPERATOR == type_found )
			{
				rInfo.resolve_use_out = true;
				return NL_OPERATOR;
			}
				
				
			// Check for being a Built In VERB
			// Hard coded Words in English   TODO: Search Dictionary
			type_found = NL_VERB_BI;
			switch ( in_token_lower )
			{
				case "repeat":
				case "show":
				case "view":
				default:
					type_found = NL_TYPE_UNKNOWN;
			}
			
			if ( NL_VERB_BI == type_found )
			{
				rInfo.resolve_out_token = in_token_lower;
				rInfo.resolve_use_out = true;
				return NL_VERB_BI;
			}
		}
		
		return type_found;
	}

	
}
