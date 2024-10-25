package forGL;
//  Above:  Use the same package name as where this code is used.  Change to fit your needs
/*
 * Comments.hx	This supports Haxe inserting Comments in various output target programming languages.
 * 
 * THANKS to Haxe Forum members
 *
 * Information here is correct about Haxe up to  4.0 rc2
 * 
 *    GOAL:
 *      Allow Haxe source code to have a way to put Comments in the generated programming language.
 * 
 *      Some generated language sources are not useful for inserting Comments.
 *      CppIA, HashLink and Neko are examples.
 * 
 *    BACKGROUND:
 *      Haxe compiler (as of 4.0 rc2) does Not support placing Comments from Haxe into target languages.
 *      There is some support of Comments for some target languages, but not all.
 *      And where you see actual Comments the support seems to be mostly to enable Debugging at Haxe source level.
 *      So actually where you see Comments seem to also be limited to inside code and Not anywhere in the source file.
 * 
 *          For more background see:
 *      https://community.haxe.org/t/how-to-have-comments-in-haxe-be-in-target-languages/1501
 * 
 *    LIMITATION:
 *      Because the Haxe macro approach is used to insert a Comment:
 *      Comments can ONLY be inserted from places where a Haxe macro may be used.
 *      So Comments are ONLY allowed within code and not other places in the target language source files.
 *
 *    SOLUTION:
 *      Approach is noted in detail below.
 */


/** 
 * @author  Haxe Forum members
 */

import haxe.macro.Expr;
import haxe.macro.Context;

class Comments 
{
// Insert a Comment OR multiple lines of Comments into a Haxe target programming language.
//
//		Example:
// comment( "Describe WHY this is important", "", "    Alternate approaches to What is going on" );
// The second line will look like a blank line.
//
//      Output looks like:
//
//  Describe WHY this is important                                                 ;
//                                                                                 ;
//      Alternate approaches to What is going on                                   ;
//
// You may use as many quoted strings as you want, each quoted string will be on a separate line.
//
    macro public static function comment( first : Expr, rest : Array< Expr > ) : Expr 
	{
		
//
//		HACK  to avoid macro errors FROM Haxe 4.2.4 or later ?
//
//
		
		// DISABLE COMMENTS FROM BEING OUTPUT
		
		var cmts = [ macro $v{ '' } ];
		return macro $b{ cmts };
		
		
		
		
		// create a Default Warning as an array of just 1 macro Expression
		// idea from  https://code.haxe.org/category/macros/build-arrays.html
		//
		//     NOTE:   the Default is of the format style for  C  family of Comments. 
		// May produce a Compiler Error if target language has different format style of Comments.
		var cmts = [ macro $v{ '/*  Target programming language not checked for in Comments class !  */' } ];

// Languages checked for in Alphabetical order

//  Approach:  All the below use the Single Line comment style of the given target programming language
//  Haxe adds a semicolon ( ; ) after inserting the macro Expression(s), (may not be true for all languages).
//  As Single Line comment style was used, the ending semicolon is included as part of the inserted comment.
//  This allows Haxe to tell that this is really a Comment.
//
//  Looking at above Example the only visual clutter seems to be a vertical line of semicolons spaced out to the right.
//  This approach successfully supports  READABLE  Comments in various Haxe target programming languages.

		if ( Context.defined( "cppia" ) )	// C++ Instructions Assembly extension, set to be empty
			cmts = [ first ].concat( rest ).map( extractNoPadding ).map( x -> macro untyped __cppia__( '' ) );
			
		else
		if ( Context.defined( "cpp" ) )		// C++
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro untyped __cpp__( '//  $x  ' ) );
		
		else
		if ( Context.defined( "cs" ) )		// C#  ( CSharp )
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro untyped __cs__( '//  $x  ' ) );
		
		else
		if ( Context.defined( "fl" ) )		// Flash
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro untyped __fl__( '//  $x  ' ) );

		else
		if ( Context.defined( "hl" ) )		// HashLink   set to be empty return
			cmts = [ first ].concat( rest ).map( extractNoPadding ).map( x -> macro untyped __hl__( '' ) );
			
		else
		if ( Context.defined( "java" ) )
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro untyped __java__( '//  $x  ' ) );
		
		else
		if ( Context.defined( "js" ) )		// JavaScript
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro js.Syntax.code( '//  $x  ' ) );
		
		else
		if ( Context.defined( "lua" ) )
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro untyped __lua__( '--  $x  ' ) );

		else
		if ( Context.defined( "neko" ) )	// Neko   set to be empty return
			cmts = [ first ].concat( rest ).map( extractNoPadding ).map( x -> macro untyped __neko__( '' ) );
		
		else
		if ( Context.defined( "python" ) )	// Python
			cmts = [ first ].concat( rest ).map( extractNoPadding ).map( x -> macro python.Syntax.code( '#  $x' ) );

		else
		if ( Context.defined( "php" ) )		// PHP
			cmts = [ first ].concat( rest ).map( extract ).map( x -> macro php.Syntax.code( '#  $x  ' ) );
		else
		{
			// Default already assigned.  
		}

        return macro $b{ cmts };
    }

// Check that a simple string is used as input.
// The string is padded on the right to a width of 80 with Blank spaces.
// The padding supports better  READABILITY  of the inserted Comment(s).
    static function extract( e : Expr ) return
        switch e.expr {
            case EConst( CString( v ) ): 
				var temp = v;
				if ( temp.length < 80 )
				{
					var str80 = "                                                                                ";
					temp = temp + str80.substr( 0, str80.length - temp.length );
				}
				temp;
            case _: "not a proper Comment";
        }
		
		
// Check that a simple string is used as input.
    static function extractNoPadding( e : Expr ) return
        switch e.expr {
            case EConst( CString( v ) ): 
				var temp = v;
				
// TODO: Python for example will have 2 extra Blank spaces at end (Right side) that should be trimmed


				temp;
            case _: "not a proper Comment 2";
        }
}