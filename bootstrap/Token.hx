// The Hexa Compiler
// Copyright (C) 2018  Oleg Petrenko
// Copyright (C) 2018  Bogdan Danylchenko
//
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

@:enum abstract Token(Int) {
	// Default
	var Eof          = 0;
	var Default      = 123; // Simplifies some parsing

	// Keywords
	var Underscore   = 1;
	var KBreak       = 3;
	var KCase        = 4;
	var KCatch       = 6;
	var KClass       = 7;
	var KContinue    = 8;
	var KDo          = 9;
	var KElse        = 10;
	var KEnum        = 11;
	var KExtends     = 12;
	var KExtern      = 13;
	var KFalse       = 14;
	var KFor         = 15;
	var KFunction    = 16;
	var KIf          = 17;
	var KImplements  = 18;
	var KImport      = 19;
	var KIn          = 20;
	var KInterface   = 22;
	var KLet         = 23;
	var KNew         = 25;
	var KNull        = 26;
	var KPackage     = 28;
	var KPrivate     = 29;
	var KPublic      = 30;
	var KReturn      = 31;
	var KStatic      = 32;
	var KSwitch      = 33;
	var KThis        = 34;
	var KThrow       = 35;
	var KTrue        = 36;
	var KTry         = 37;
	var KType        = 38;
	var KUsing       = 39;
	var KVar         = 40;
	var KWhile       = 41;
	var KAs          = 58;
	var KSuper       = 59;

	// Literals
	var LFloat       = 60; // 0.123
	var LIdent       = 61; // word
	var LInt         = 62; // 123
	var LString      = 64; // "", '', ``
	var LDoc         = 65; // /** doc **/
	var LCommentLine = 66;
	var LComment	 = 67;

	// Symbols
	var At           = 70; // @
	var BkClose      = 71; // ]
	var BkOpen       = 72; // [
	var BrClose      = 73; // }
	var BrOpen       = 74; // {
	var Comma        = 75; // ,
	var DblDot       = 76; // :
	var Dot          = 77; // .
	var Sharp        = 78; // #
	var PClose       = 79; // )
	var POpen        = 80; // (
	var Question     = 81; // ?
	var Semicolon    = 82; // ;
	var Query        = 83; // $
	var Interval     = 98; // ...

	// Unop
	var OpDecrement  = 86; // --
	var OpIncrement  = 87; // ++
	var OpNegBits    = 88; // ~
	var OpNot        = 89; // !

	// Binop
	var OpArrow      = 90; // =>
	var OpAssign     = 91; // =
	var OpBoolAnd    = 92; // &&
	var OpBoolOr     = 93; // ||
	var OpDiv        = 94; // /
	var OpEq         = 95; // ==
	var OpGt         = 96; // >
	var OpGte        = 97; // >=
	var OpLt         = 99; // <
	var OpLte       = 100; // <=
	var OpMod       = 101; // %
	var OpMult      = 102; // *
	var OpNotEq     = 103; // !=
	var OpOr        = 104; // |
	var OpShl       = 105; // <<
	var OpShr       = 106; // >>
	var OpSub       = 107; // -
	var OpUShr      = 108; // >>>
	var OpXor       = 109; // ^
	var OpIntDiv    = 110; // \
	var OpAdd       = 111; // +
	var OpAnd       = 112; // &
	var OpChain     = 113; // ?.

	public function stringify(?param:String): String {
		var token : Token = cast this;
		return switch (token) {
		case At: "@";
		case Query: "$";
		case Sharp: "#";
		case BkClose: "]";
		case BkOpen: "[";
		case BrClose: "}";
		case BrOpen: "{";
		case Comma: ",";
		case DblDot: ":";
		case Default: "<!--default-->";
		case Dot: ".";
		case Eof: "<!--eof-->";
		case Interval: "...";
		case KAs: "as";
		case KBreak: "break";
		case KCase: "case";
		case KCatch: "catch";
		case KClass: "class";
		case KContinue: "continue";
		case KDo: "do";
		case KElse: "else";
		case KEnum: "enum";
		case KExtends: "extends";
		case KExtern: "declare";
		case KFalse: "false";
		case KFor: "for";
		case KFunction: "function";
		case KIf: "if";
		case KImplements: "implements";
		case KImport: "import";
		case KIn: "in";
		case KInterface: "interface";
		case KLet: "let";
		case KNew: "new";
		case KNull: "null";
		case KPackage: "module";
		case KPrivate: "private";
		case KPublic: "public";
		case KReturn: "return";
		case KStatic: "static";
		case KSuper: "super";
		case KSwitch: "switch";
		case KThis: "this";
		case KThrow: "throw";
		case KTrue: "true";
		case KTry: "try";
		case KType: "type";
		case KUsing: "using";
		case KVar: "var";
		case KWhile: "while";
		case OpAdd: "+";
		case OpAnd: "&";
		case OpArrow: "=>";
		case OpAssign: "=";
		case OpBoolAnd: "&&";
		case OpBoolOr: "||";
		case OpDecrement: "--";
		case OpDiv: "/";
		case OpEq: "==";
		case OpGt: ">";
		case OpGte: ">=";
		case OpIncrement: "++";
		case OpIntDiv: "\\";
		case OpLt: "<";
		case OpLte: "<=";
		case OpMod: "%";
		case OpMult: "*";
		case OpNegBits: "~";
		case OpNot: "!";
		case OpNotEq: "!=";
		case OpOr: "|";
		case OpShl: "<<";
		case OpShr: ">>";
		case OpSub: "-";
		case OpUShr: ">>>";
		case OpXor: "^";
		case OpChain: "?.";
		case PClose: ")";
		case POpen: "(";
		case Question: "?";
		case Semicolon: ";";
		case Underscore: "_";
		case LString: param == null? 'string' : '\'$param\'';
		case LIdent: param == null? 'identifier' : param;
		case LInt: param == null? 'integer' : param;
		case LFloat: param == null? 'float' : param;
		case LDoc: '///$param';
		case LComment: '/*$param*/';
		case LCommentLine: '//$param';
		}
	}
}
