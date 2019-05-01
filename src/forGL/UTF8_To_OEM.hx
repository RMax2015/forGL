/**		UTF8_To_OEM.hx		Convert some European UTF8 characters to OEM characters for display
 * ...
 * @author Randy Maxwell
 */

package forGL;

//
//		UTF8 support library
//
using hx.strings.Strings;
using hx.strings.Char;
using hx.strings.String8;


import forGL.UI.ForGL_ui.msg as msg;


// Helper to allow UTF8 (European characters) output on OEM display 
// such as Win7 Cmd.exe window
//
// Windows default code page is 437 (IBM DOS or OEM) at least on Win7 Cmd.exe window
//    Windows has a CHCP (change code page) command
// CHCP   (shows the current code page for Cmd.exe)
// CHCP   437 changes to OEM
// CHCP 65001 changes to UTF8
//
// if CHCP 65001 is run before forGL the cursor positioning and Ansi colors do work
//
// Still may be useful in other ways.
//
class Utf8_to_OEM
{
	public  static var UTF8_TO_OEM = new Array<Int>();
	private static var OEM_TABLE_LIMIT : Int = 256;

// Initialize table used to look up OEM character given a UTF8 character
	public static function init() : Int
	{
		if ( 0 != UTF8_TO_OEM.length )
			return UTF8_TO_OEM.length;		// Table already set

		// Set table with default Same As indexes
		var i : Int = 0;
		while ( i < OEM_TABLE_LIMIT )
		{
			UTF8_TO_OEM.push( i );
			i++;
		}
		
		// Set Values to fix up. 
		// This is for ENGLISH (American) OEM code page and Raster Fonts
		//    == old DOS BIOS OEM characters  See screen capture below
		//
		//	TODO  Update UTF8 hex numbers. NOT ACCURATE. FAIR WARNING!
		//
		// "Ç  ü  é  â  ä  à  å  ç  ê  ë  è  ï  î  ì  Ä  Å"
		//
		//          UTF8     OEM            UTF8                OEM
		//         Decimal  Decimal         Hex! Symbol         Hex is accurate
		//  --------------  -------         ----  -             ----
		UTF8_TO_OEM[ 199 ] = 128;	// UTF8 0xC7 "Ç" now is OEM 0x80
		UTF8_TO_OEM[ 252 ] = 129;	// UTF8 0xFC "ü" now is OEM 0x81
		UTF8_TO_OEM[ 233 ] = 130;	// UTF8 0xE9 "é" now is OEM 0x82
		UTF8_TO_OEM[ 226 ] = 131;	// UTF8 0xE2 "â" now is OEM 0x83
		UTF8_TO_OEM[ 228 ] = 132;	// UTF8 0xE4 "ä" now is OEM 0x84
		UTF8_TO_OEM[ 224 ] = 133;	// UTF8 0xE0 "à" now is OEM 0x85
		UTF8_TO_OEM[ 229 ] = 134;	// UTF8 0xE5 "å" now is OEM 0x86
		UTF8_TO_OEM[ 231 ] = 135;	// UTF8 0xE7 "ç" now is OEM 0x87
		UTF8_TO_OEM[ 234 ] = 136;	// UTF8 0xEA "ê" now is OEM 0x88
		UTF8_TO_OEM[ 235 ] = 137;	// UTF8 0xEB "ë" now is OEM 0x89
		UTF8_TO_OEM[ 232 ] = 138;	// UTF8 0xE8 "è" now is OEM 0x8A
		UTF8_TO_OEM[ 239 ] = 139;	// UTF8 0xEF "ï" now is OEM 0x8B
		UTF8_TO_OEM[ 238 ] = 140;	// UTF8 0xEE "î" now is OEM 0x8C
		UTF8_TO_OEM[ 236 ] = 141;	// UTF8 0xEC "ì" now is OEM 0x8D
		UTF8_TO_OEM[ 196 ] = 142;	// UTF8 0xC4 "Ä" now is OEM 0x8E
		UTF8_TO_OEM[ 197 ] = 143;	// UTF8 0xC5 "Å" now is OEM 0x8F
		
		// "É  æ  Æ  ô  ö  ò  û  ù  ÿ  Ö  Ü  ¢  £  ¥  ₧  ƒ"
		//
		UTF8_TO_OEM[ 201 ] = 144;	// UTF8 0xC7 "É" now is OEM 0x90
		UTF8_TO_OEM[ 230 ] = 145;	// UTF8 0xFC "æ" now is OEM 0x91
		UTF8_TO_OEM[ 198 ] = 146;	// UTF8 0xE9 "Æ" now is OEM 0x92
		UTF8_TO_OEM[ 244 ] = 147;	// UTF8 0xE2 "ô" now is OEM 0x93
		UTF8_TO_OEM[ 246 ] = 148;	// UTF8 0xE4 "ö" now is OEM 0x94
		UTF8_TO_OEM[ 242 ] = 149;	// UTF8 0xE0 "ò" now is OEM 0x95
		UTF8_TO_OEM[ 251 ] = 150;	// UTF8 0xE5 "û" now is OEM 0x96
		UTF8_TO_OEM[ 249 ] = 151;	// UTF8 0xE7 "ù" now is OEM 0x97
		UTF8_TO_OEM[ 255 ] = 152;	// UTF8 0xEA "ÿ" now is OEM 0x98
		UTF8_TO_OEM[ 214 ] = 153;	// UTF8 0xEB "Ö" now is OEM 0x99
		UTF8_TO_OEM[ 220 ] = 154;	// UTF8 0xE8 "Ü" now is OEM 0x9A
		UTF8_TO_OEM[ 162 ] = 155;	// UTF8 0xEF "¢" now is OEM 0x9B
		UTF8_TO_OEM[ 163 ] = 156;	// UTF8 0xEE "£" now is OEM 0x9C
		UTF8_TO_OEM[ 165 ] = 157;	// UTF8 0xEC "¥" now is OEM 0x9D
		
		// Last 2 are handled by code not table
	//	UTF8_TO_OEM[ 8359 ] = 158;	// UTF8 0xC4 "₧" now is OEM 0x9E
	//	UTF8_TO_OEM[  402 ] = 159;	// UTF8 0xC5 "ƒ" now is OEM 0x9F

		// "á  í  ó  ú  ñ  Ñ  ª  º  ¿  ⌐  ¬  ½  ¼  ¡  «  »"
		//
		UTF8_TO_OEM[ 225 ] = 160;	// UTF8 0xC7 "á" now is OEM 0xA0
		UTF8_TO_OEM[ 237 ] = 161;	// UTF8 0xFC "í" now is OEM 0xA1
		UTF8_TO_OEM[ 243 ] = 162;	// UTF8 0xE9 "ó" now is OEM 0xA2
		UTF8_TO_OEM[ 250 ] = 163;	// UTF8 0xE2 "ú" now is OEM 0xA3
		UTF8_TO_OEM[ 241 ] = 164;	// UTF8 0xE4 "ñ" now is OEM 0xA4
		UTF8_TO_OEM[ 209 ] = 165;	// UTF8 0xE0 "Ñ" now is OEM 0xA5
		UTF8_TO_OEM[ 170 ] = 166;	// UTF8 0xE5 "ª" now is OEM 0xA6
		UTF8_TO_OEM[ 186 ] = 167;	// UTF8 0xE7 "º" now is OEM 0xA7
		UTF8_TO_OEM[ 191 ] = 168;	// UTF8 0xEA "¿" now is OEM 0xA8
	//	UTF8_TO_OEM[ 8976 ] = 169;	// UTF8 0xEB "⌐" now is OEM 0xA9
		UTF8_TO_OEM[ 172 ] = 170;	// UTF8 0xE8 "¬" now is OEM 0xAA
		UTF8_TO_OEM[ 189 ] = 171;	// UTF8 0xEF "½" now is OEM 0xAB
		UTF8_TO_OEM[ 188 ] = 172;	// UTF8 0xEE "¼" now is OEM 0xAC
		UTF8_TO_OEM[ 161 ] = 173;	// UTF8 0xEC "¡" now is OEM 0xAD
		UTF8_TO_OEM[ 171 ] = 174;	// UTF8 0xC4 "«" now is OEM 0xAE
		UTF8_TO_OEM[ 187 ] = 175;	// UTF8 0xC5 "»" now is OEM 0xAF
	
		// "░  ▒  ▓  │  ┤  ╡  ╢  ╖  ╕  ╣  ║  ╗  ╝  ╜  ╛  ┐"
	/*
		UTF8_TO_OEM[ 9617 ] = 176;	// UTF8 0xC7 "░" now is OEM 0xB0
		UTF8_TO_OEM[ 9618 ] = 177;	// UTF8 0xFC "▒" now is OEM 0xB1
		UTF8_TO_OEM[ 9619 ] = 178;	// UTF8 0xE9 "▓" now is OEM 0xB2
		UTF8_TO_OEM[ 9474 ] = 179;	// UTF8 0xE2 "│" now is OEM 0xB3
		UTF8_TO_OEM[ 9508 ] = 180;	// UTF8 0xE4 "┤" now is OEM 0xB4
		UTF8_TO_OEM[ 9569 ] = 181;	// UTF8 0xE0 "╡" now is OEM 0xB5
		UTF8_TO_OEM[ 9570 ] = 182;	// UTF8 0xE5 "╢" now is OEM 0xB6
		UTF8_TO_OEM[ 9558 ] = 183;	// UTF8 0xE7 "╖" now is OEM 0xB7
		UTF8_TO_OEM[ 9557 ] = 184;	// UTF8 0xEA "╕" now is OEM 0xB8
		UTF8_TO_OEM[ 9571 ] = 185;	// UTF8 0xEB "╣" now is OEM 0xB9
		UTF8_TO_OEM[ 9553 ] = 186;	// UTF8 0xE8 "║" now is OEM 0xBA
		UTF8_TO_OEM[ 9559 ] = 187;	// UTF8 0xEF "╗" now is OEM 0xBB
		UTF8_TO_OEM[ 9565 ] = 188;	// UTF8 0xEE "╝" now is OEM 0xBC
		UTF8_TO_OEM[ 9564 ] = 189;	// UTF8 0xEC "╜" now is OEM 0xBD
		UTF8_TO_OEM[ 9563 ] = 190;	// UTF8 0xC4 "╛" now is OEM 0xBE
		UTF8_TO_OEM[ 9488 ] = 191;	// UTF8 0xC5 "┐" now is OEM 0xBF
	*/
		// "└  ┴  ┬  ├  ─  ┼  ╞  ╟  ╚  ╔  ╩  ╦  ╠  ═  ╬  ╧"
	/*
		UTF8_TO_OEM[ 9492 ] = 192;	// UTF8 0xC7 "└" now is OEM 0xC0
		UTF8_TO_OEM[ 9524 ] = 193;	// UTF8 0xFC "┴" now is OEM 0xC1
		UTF8_TO_OEM[ 9516 ] = 194;	// UTF8 0xE9 "┬" now is OEM 0xC2
		UTF8_TO_OEM[ 9500 ] = 195;	// UTF8 0xE2 "├" now is OEM 0xC3
		UTF8_TO_OEM[ 9472 ] = 196;	// UTF8 0xE4 "─" now is OEM 0xC4
		UTF8_TO_OEM[ 9532 ] = 197;	// UTF8 0xE0 "┼" now is OEM 0xC5
		UTF8_TO_OEM[ 9566 ] = 198;	// UTF8 0xE5 "╞" now is OEM 0xC6
		UTF8_TO_OEM[ 9567 ] = 199;	// UTF8 0xE7 "╟" now is OEM 0xC7
		UTF8_TO_OEM[ 9562 ] = 200;	// UTF8 0xEA "╚" now is OEM 0xC8
		UTF8_TO_OEM[ 9556 ] = 201;	// UTF8 0xEB "╔" now is OEM 0xC9
		UTF8_TO_OEM[ 9577 ] = 202;	// UTF8 0xE8 "╩" now is OEM 0xCA
		UTF8_TO_OEM[ 9574 ] = 203;	// UTF8 0xEF "╦" now is OEM 0xCB
		UTF8_TO_OEM[ 9568 ] = 204;	// UTF8 0xEE "╠" now is OEM 0xCC
		UTF8_TO_OEM[ 9552 ] = 205;	// UTF8 0xEC "═" now is OEM 0xCD
		UTF8_TO_OEM[ 9580 ] = 206;	// UTF8 0xC4 "╬" now is OEM 0xCE
		UTF8_TO_OEM[ 9575 ] = 207;	// UTF8 0xC5 "╧" now is OEM 0xCF
	*/
		
		// "╨  ╤  ╥  ╙  ╘  ╒  ╓  ╫  ╪  ┘  ┌  █  ▄  ▌  ▐  ▀"
	/*
		UTF8_TO_OEM[ 9576 ] = 208;	// UTF8 0xC7 "╨" now is OEM 0xD0
		UTF8_TO_OEM[ 9572 ] = 209;	// UTF8 0xFC "╤" now is OEM 0xD1
		UTF8_TO_OEM[ 9573 ] = 210;	// UTF8 0xE9 "╥" now is OEM 0xD2
		UTF8_TO_OEM[ 9561 ] = 211;	// UTF8 0xE2 "╙" now is OEM 0xD3
		UTF8_TO_OEM[ 9560 ] = 212;	// UTF8 0xE4 "╘" now is OEM 0xD4
		UTF8_TO_OEM[ 9554 ] = 213;	// UTF8 0xE0 "╒" now is OEM 0xD5
		UTF8_TO_OEM[ 9555 ] = 214;	// UTF8 0xE5 "╓" now is OEM 0xD6
		UTF8_TO_OEM[ 9579 ] = 215;	// UTF8 0xE7 "╫" now is OEM 0xD7
		UTF8_TO_OEM[ 9578 ] = 216;	// UTF8 0xEA "╪" now is OEM 0xD8
		UTF8_TO_OEM[ 9496 ] = 217;	// UTF8 0xEB "┘" now is OEM 0xD9
		UTF8_TO_OEM[ 9484 ] = 218;	// UTF8 0xE8 "┌" now is OEM 0xDA
		UTF8_TO_OEM[ 9608 ] = 219;	// UTF8 0xEF "█" now is OEM 0xDB
		UTF8_TO_OEM[ 9604 ] = 220;	// UTF8 0xEE "▄" now is OEM 0xDC
		UTF8_TO_OEM[ 9612 ] = 221;	// UTF8 0xEC "▌" now is OEM 0xDD
		UTF8_TO_OEM[ 9616 ] = 222;	// UTF8 0xC4 "▐" now is OEM 0xDE
		UTF8_TO_OEM[ 9600 ] = 223;	// UTF8 0xC5 "▀" now is OEM 0xDF
	*/	
	
		return UTF8_TO_OEM.length;
	}
	
//
// Change a single character UTF8 code to OEM (Integer)
// Any UTF8 characters that do not match return 63 (0x3F) same as '?'
//
	public static function to_OEM( char_code : Char ) : Int
	{
		var char_code_int : Int = cast( char_code, Int ); 
		if ( ( char_code_int < OEM_TABLE_LIMIT ) && ( 0 <= char_code_int ) )
			return UTF8_TO_OEM[ char_code_int ];
		
		var result : Int = 0x3F;	// Default is OEM code for '?'
		
		if ( 8359 == char_code_int )
			result = 158;
		else 
		if ( 402 == char_code_int )
			result = 159;
		else
		if ( 8976 == char_code_int )
			result = 169;
		
	/*
		UTF8_TO_OEM[ 9617 ] = 176;	// UTF8 0xC7 "░" now is OEM 0xB0
		UTF8_TO_OEM[ 9618 ] = 177;	// UTF8 0xFC "▒" now is OEM 0xB1
		UTF8_TO_OEM[ 9619 ] = 178;	// UTF8 0xE9 "▓" now is OEM 0xB2
		UTF8_TO_OEM[ 9474 ] = 179;	// UTF8 0xE2 "│" now is OEM 0xB3
		UTF8_TO_OEM[ 9508 ] = 180;	// UTF8 0xE4 "┤" now is OEM 0xB4
		UTF8_TO_OEM[ 9569 ] = 181;	// UTF8 0xE0 "╡" now is OEM 0xB5
		UTF8_TO_OEM[ 9570 ] = 182;	// UTF8 0xE5 "╢" now is OEM 0xB6
		UTF8_TO_OEM[ 9558 ] = 183;	// UTF8 0xE7 "╖" now is OEM 0xB7
		UTF8_TO_OEM[ 9557 ] = 184;	// UTF8 0xEA "╕" now is OEM 0xB8
		UTF8_TO_OEM[ 9571 ] = 185;	// UTF8 0xEB "╣" now is OEM 0xB9
		UTF8_TO_OEM[ 9553 ] = 186;	// UTF8 0xE8 "║" now is OEM 0xBA
		UTF8_TO_OEM[ 9559 ] = 187;	// UTF8 0xEF "╗" now is OEM 0xBB
		UTF8_TO_OEM[ 9565 ] = 188;	// UTF8 0xEE "╝" now is OEM 0xBC
		UTF8_TO_OEM[ 9564 ] = 189;	// UTF8 0xEC "╜" now is OEM 0xBD
		UTF8_TO_OEM[ 9563 ] = 190;	// UTF8 0xC4 "╛" now is OEM 0xBE
		UTF8_TO_OEM[ 9488 ] = 191;	// UTF8 0xC5 "┐" now is OEM 0xBF
	*/
		else
		if ( 9617 == char_code_int )
			result = 176;
		else
		if ( 9618 == char_code_int )
			result = 177;
		else
		if ( 9619 == char_code_int )
			result = 178;
		else
		if ( 9474 == char_code_int )
			result = 179;
		else
		if ( 9508 == char_code_int )
			result = 180;
		else
		if ( 9569 == char_code_int )
			result = 181;
		else
		if ( 9570 == char_code_int )
			result = 182;
		else
		if ( 9558 == char_code_int )
			result = 183;
		else
		if ( 9557 == char_code_int )
			result = 184;
		else
		if ( 9571 == char_code_int )
			result = 185;
		else
		if ( 9553 == char_code_int )
			result = 186;
		else
		if ( 9559 == char_code_int )
			result = 187;
		else
		if ( 9565 == char_code_int )
			result = 188;
		else
		if ( 9564 == char_code_int )
			result = 189;
		else
		if ( 9563 == char_code_int )
			result = 190;
		else
		if ( 9488 == char_code_int )
			result = 191;

	/*
		UTF8_TO_OEM[ 9492 ] = 192;	// UTF8 0xC7 "└" now is OEM 0xC0
		UTF8_TO_OEM[ 9524 ] = 193;	// UTF8 0xFC "┴" now is OEM 0xC1
		UTF8_TO_OEM[ 9516 ] = 194;	// UTF8 0xE9 "┬" now is OEM 0xC2
		UTF8_TO_OEM[ 9500 ] = 195;	// UTF8 0xE2 "├" now is OEM 0xC3
		UTF8_TO_OEM[ 9472 ] = 196;	// UTF8 0xE4 "─" now is OEM 0xC4
		UTF8_TO_OEM[ 9532 ] = 197;	// UTF8 0xE0 "┼" now is OEM 0xC5
		UTF8_TO_OEM[ 9566 ] = 198;	// UTF8 0xE5 "╞" now is OEM 0xC6
		UTF8_TO_OEM[ 9567 ] = 199;	// UTF8 0xE7 "╟" now is OEM 0xC7
		UTF8_TO_OEM[ 9562 ] = 200;	// UTF8 0xEA "╚" now is OEM 0xC8
		UTF8_TO_OEM[ 9556 ] = 201;	// UTF8 0xEB "╔" now is OEM 0xC9
		UTF8_TO_OEM[ 9577 ] = 202;	// UTF8 0xE8 "╩" now is OEM 0xCA
		UTF8_TO_OEM[ 9574 ] = 203;	// UTF8 0xEF "╦" now is OEM 0xCB
		UTF8_TO_OEM[ 9568 ] = 204;	// UTF8 0xEE "╠" now is OEM 0xCC
		UTF8_TO_OEM[ 9552 ] = 205;	// UTF8 0xEC "═" now is OEM 0xCD
		UTF8_TO_OEM[ 9580 ] = 206;	// UTF8 0xC4 "╬" now is OEM 0xCE
		UTF8_TO_OEM[ 9575 ] = 207;	// UTF8 0xC5 "╧" now is OEM 0xCF
	*/
		else
		if ( 9492 == char_code_int )
			result = 192;
		else
		if ( 9524 == char_code_int )
			result = 193;
		else
		if ( 9516 == char_code_int )
			result = 194;
		else
		if ( 9500 == char_code_int )
			result = 195;
		else
		if ( 9472 == char_code_int )
			result = 196;
		else
		if ( 9532 == char_code_int )
			result = 197;
		else
		if ( 9566 == char_code_int )
			result = 198;
		else
		if ( 9567 == char_code_int )
			result = 199;
		else
		if ( 9562 == char_code_int )
			result = 200;
		else
		if ( 9556 == char_code_int )
			result = 201;
		else
		if ( 9577 == char_code_int )
			result = 202;
		else
		if ( 9574 == char_code_int )
			result = 203;
		else
		if ( 9568 == char_code_int )
			result = 204;
		else
		if ( 9552 == char_code_int )
			result = 205;
		else
		if ( 9580 == char_code_int )
			result = 206;
		else
		if ( 9575 == char_code_int )
			result = 207;
		
	/*
		UTF8_TO_OEM[ 9576 ] = 208;	// UTF8 0xC7 "╨" now is OEM 0xD0
		UTF8_TO_OEM[ 9572 ] = 209;	// UTF8 0xFC "╤" now is OEM 0xD1
		UTF8_TO_OEM[ 9573 ] = 210;	// UTF8 0xE9 "╥" now is OEM 0xD2
		UTF8_TO_OEM[ 9561 ] = 211;	// UTF8 0xE2 "╙" now is OEM 0xD3
		UTF8_TO_OEM[ 9560 ] = 212;	// UTF8 0xE4 "╘" now is OEM 0xD4
		UTF8_TO_OEM[ 9554 ] = 213;	// UTF8 0xE0 "╒" now is OEM 0xD5
		UTF8_TO_OEM[ 9555 ] = 214;	// UTF8 0xE5 "╓" now is OEM 0xD6
		UTF8_TO_OEM[ 9579 ] = 215;	// UTF8 0xE7 "╫" now is OEM 0xD7
		UTF8_TO_OEM[ 9578 ] = 216;	// UTF8 0xEA "╪" now is OEM 0xD8
		UTF8_TO_OEM[ 9496 ] = 217;	// UTF8 0xEB "┘" now is OEM 0xD9
		UTF8_TO_OEM[ 9484 ] = 218;	// UTF8 0xE8 "┌" now is OEM 0xDA
		UTF8_TO_OEM[ 9608 ] = 219;	// UTF8 0xEF "█" now is OEM 0xDB
		UTF8_TO_OEM[ 9604 ] = 220;	// UTF8 0xEE "▄" now is OEM 0xDC
		UTF8_TO_OEM[ 9612 ] = 221;	// UTF8 0xEC "▌" now is OEM 0xDD
		UTF8_TO_OEM[ 9616 ] = 222;	// UTF8 0xC4 "▐" now is OEM 0xDE
		UTF8_TO_OEM[ 9600 ] = 223;	// UTF8 0xC5 "▀" now is OEM 0xDF
	*/
		else
		if ( 9576 == char_code_int )
			result = 208;
		else
		if ( 9572 == char_code_int )
			result = 209;
		else
		if ( 9573 == char_code_int )
			result = 210;
		else
		if ( 9561 == char_code_int )
			result = 211;
		else
		if ( 9560 == char_code_int )
			result = 212;
		else
		if ( 9554 == char_code_int )
			result = 213;
		else
		if ( 9555 == char_code_int )
			result = 214;
		else
		if ( 9579 == char_code_int )
			result = 215;
		else
		if ( 9578 == char_code_int )
			result = 216;
		else
		if ( 9496 == char_code_int )
			result = 217;
		else
		if ( 9484 == char_code_int )
			result = 218;
		else
		if ( 9608 == char_code_int )
			result = 219;
		else
		if ( 9604 == char_code_int )
			result = 220;
		else
		if ( 9612 == char_code_int )
			result = 221;
		else
		if ( 9616 == char_code_int )
			result = 222;
		else
		if ( 9600 == char_code_int )
			result = 223;
	
		
			
			
		return result;
	}

//
// Change entire UTF8 string to OEM
//
	public static function oemStr( utf8_str : String8, ?keep_if_unknown : Bool = true ) : String
	{
		if ( 0 == utf8_str.length )
			return "";
		
		var out_str : String = "";
		var i : Int = 0;
		
		var char_code = Strings.charCodeAt8( utf8_str, 0 );
		var char_code_int : Int = cast( char_code, Int );
		
		//var old_1char_str : String8 = " ";
		var new_char_code_int : Int = 0x3F;
		var new_1char_str : String = " ";

		var utf8_str_len : Int = Strings.length8( utf8_str );
		while ( i < utf8_str_len )
		{
			char_code = Strings.charCodeAt8( utf8_str, i );
			char_code_int = cast( char_code, Int );
			
			if ( 0x7F <= char_code_int )
			{
				// Need to get an OEM converted character
				new_char_code_int = Utf8_to_OEM.to_OEM( char_code_int );
			
				// If  ?  is the new character code, check about keeping original
				if ( ( 0x3F == new_char_code_int ) && ( true == keep_if_unknown ) )
				{
					new_1char_str = String.fromCharCode( char_code );	// keep Original character
				}
				else
					new_1char_str = String.fromCharCode( new_char_code_int );
			}
			else
			{
				// No need to change the character
				new_1char_str = String.fromCharCode( char_code );	// keep Original character
			}
			
			out_str += new_1char_str;	// append wanted character
			
			i++;
		}
		
		return out_str;
	}
}


class TestChars
{
	// Show a Table of character codes from Blank Space up to 255
	public static function charTable()
	{
		// Set up table if needed
		Utf8_to_OEM.init();
		
/*
 * 	TRYING to have at least SOME European languages display correctly.
 *  German, Spanish, French, Italian,
 * 
 *  I have NO idea if there are similar problems with other OS or Display conventions
 *     I am GUESSING that yes there are other Display related contraints to work around
 * 
 *  ANOTHER important feature is to have COLORED text.
 *  So having the ANSI Escape sequences to position the text cursor and fore/back ground colors
 *  is needed. 
 * 
 *  Am trying for Simplicity but already had to use AnsiCon.exe to get Colors on Win 7.
 * 
 *  Now looking at a character by character lookup table (for those Euro languages)
 * 
 *  For full language support will likely use a full graphics mode window with some
 *  Haxe graphics library with built in UTF8 support or use JavaScript in a Browser.
 * 
 * 
 *  Below is actual capture of output from this table (note OEM character symbols)
 *  on a English (American)  Windows 7 using RASTER Fonts  CMD.exe window
 *  
 * 
	     0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F
-----------------------------------------------------------------------
0x20    ' '  !   "   #   $   %   &   '   (   )   *   +   ,   -   .   /

0x30     0   1   2   3   4   5   6   7   8   9   :   ;   <   =   >   ?

0x40     @   A   B   C   D   E   F   G   H   I   J   K   L   M   N   O

0x50     P   Q   R   S   T   U   V   W   X   Y   Z   [   \   ]   ^   _

0x60     `   a   b   c   d   e   f   g   h   i   j   k   l   m   n   o

0x70     p   q   r   s   t   u   v   w   x   y   z   {   |   }   ~   ⌂

0x80     Ç   ü   é   â   ä   à   å   ç   ê   ë   è   ï   î   ì   Ä   Å

0x90     É   æ   Æ   ô   ö   ò   û   ù   ÿ   Ö   Ü   ¢   £   ¥   ₧   ƒ

0xA0     á   í   ó   ú   ñ   Ñ   ª   º   ¿   ⌐   ¬   ½   ¼   ¡   «   »

0xB0     ░   ▒   ▓   │   ┤   ╡   ╢   ╖   ╕   ╣   ║   ╗   ╝   ╜   ╛   ┐

0xC0     └   ┴   ┬   ├   ─   ┼   ╞   ╟   ╚   ╔   ╩   ╦   ╠   ═   ╬   ╧

0xD0     ╨   ╤   ╥   ╙   ╘   ╒   ╓   ╫   ╪   ┘   ┌   █   ▄   ▌   ▐   ▀

0xE0     α   ß   Γ   π   Σ   σ   µ   τ   Φ   Θ   Ω   δ   ∞   φ   ε   ∩

0xF0     ≡   ±   ≥   ≤   ⌠   ⌡   ÷   ≈   °   ∙   ·   √   ⁿ   ²   ■  ' '


*/		
		msg( "\n" );
		var test_str : String8 = "";
		var oem_str  : String8 = "";
	/*	
		test_str = "   !  \"  #  $  %  &  '  (  )  *  +  ,  -  .  /";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_oem.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "0  1  2  3  4  5  6  7  8  9  :  ;  <  =  >  ?";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_oem.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "@  A  B  C  D  E  F  G  H  I  J  K  L  M  N  O";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_oem.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "P  Q  R  S  T  U  V  W  X  Y  Z  [  \\  ]  ^  _";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_oem.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "`  a  b  c  d  e  f  g  h  i  j  k  l  m  n  o";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_oem.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
	*/	
		test_str = "p  q  r  s  t  u  v  w  x  y  z  {  |  }  ~  ⌂";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "Ç  ü  é  â  ä  à  å  ç  ê  ë  è  ï  î  ì  Ä  Å";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "É  æ  Æ  ô  ö  ò  û  ù  ÿ  Ö  Ü  ¢  £  ¥  ₧  ƒ";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "á  í  ó  ú  ñ  Ñ  ª  º  ¿  ⌐  ¬  ½  ¼  ¡  «  »";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "░  ▒  ▓  │  ┤  ╡  ╢  ╖  ╕  ╣  ║  ╗  ╝  ╜  ╛  ┐";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "└  ┴  ┬  ├  ─  ┼  ╞  ╟  ╚  ╔  ╩  ╦  ╠  ═  ╬  ╧";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		test_str = "╨  ╤  ╥  ╙  ╘  ╒  ╓  ╫  ╪  ┘  ┌  █  ▄  ▌  ▐  ▀";
		msg( " " + test_str + " \n" );
		oem_str = Utf8_to_OEM.oemStr( test_str );
		msg( " " + oem_str  + " \n" );
		
		//msg( test_str + "\n" );
		var i = 0;

		var char_code = Strings.charCodeAt8( test_str, 0 );
		var char_code_int : Int = cast( char_code, Int );
		
		var one_char_str : String8 = " ";
		
		var test_str_len : Int = Strings.length8( test_str );
		while ( i < test_str_len )
		{
			char_code = Strings.charCodeAt8( test_str, i );
			char_code_int = cast( char_code, Int );
			if ( ' ' == char_code )
			{
				i++;
				continue;
			}
			
			one_char_str = String.fromCharCode( char_code );
			
			msg( "  " + one_char_str + "   Char Code = " + Std.string( char_code_int ) + "  Converted = " + String.fromCharCode( Utf8_to_OEM.to_OEM(cast(char_code, Int))) + "\n" );
			
		// Used to find a fixed reference to build up  conversion table
		//	if ( 228 == char_code_int )	// lower case a  with Umlaut
		//	{
		//		msg( "  Substitute character ->  " + Std.string( String.fromCharCode( 132 ) ) + "\n" );  
		//	}
		//
			
			i++;
		}
		
		// Table positions
		var vertical   = 2;		// Same as first Hex
		var horizontal = 0;
		
		var lim = 255;
		var charNum = 32;
		
		var str  : String  = "";
		var str8 : String8 = str;
		var firstHex = "2";
		var hexStr = firstHex + "0";
		
		msg( "\n" );
		msg( "         0   1   2   3   4   5   6   7   8   9   A   B   C   D   E   F" + "\n" );
		msg( "-----------------------------------------------------------------------" + "\n" );
		
		msg( "0x" + hexStr + "   " );
		
		while ( charNum <= lim )
		{
			
			if ( ( 32 == charNum ) || ( 255 == charNum ) )
				msg( " ' '" );	// Invisible character Blank space or 0xFF
			else
			{
				str  = String.fromCharCode( charNum );
				str8 = cast( "  " + str + " ", String8 );
				msg( str8 );
			}
			
			charNum++;
			if ( charNum > lim )
				break;
			
			horizontal++;
			if ( horizontal >= 16 )
			{
				horizontal = 0;
				vertical++;
				msg( "\n\n" );
				
				// use Vertical here to do a Hex number
				// msg( "   " );
				firstHex = Std.string( vertical );
				if ( 10 <= vertical )
					firstHex = String.fromCharCode( 55 + vertical );	// 55 = 'A' (65) + vertical - 10 
				
				hexStr = firstHex + "0";
				msg( "0x" + hexStr + "   " );
			}
		}
		
		msg( "\n" );
	}
}
