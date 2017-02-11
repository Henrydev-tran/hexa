// MIT License
//
// Copyright (c) 2017 Oleg Petrenko
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import sys.io.File;

using Lambda;
using StringTools;
using haxe.macro.TypedExprTools;
using haxe.macro.Tools;
using Converter;

class Converter {

#if macro

	static var tabs = '';

	// Hexa keywords of choice
	static inline var kwAs = 'as';
	static inline var kwBreak = 'break';
	static inline var kwCase = 'case';
	static inline var kwCatch = 'catch';
	static inline var kwClass = 'class';
	static inline var kwConst = 'let';
	static inline var kwContinue = 'continue';
	static inline var kwDo = 'do';
	static inline var kwElse = 'else';
	static inline var kwEnum = 'enum';
	static inline var kwExtends = 'extends';
	static inline var kwExtern = 'declare';
	static inline var kwFalse = 'false';
	static inline var kwFor = 'for';
	static inline var kwFunction = 'function';
	static inline var kwIf = 'if';
	static inline var kwImplements = 'implements';
	static inline var kwIn = 'in';
	static inline var kwInterface = 'interface';
	static inline var kwNew = 'new';
	static inline var kwNull = 'null';
	static inline var kwPackage = 'module';
	static inline var kwPrivate = 'private';
	static inline var kwReturn = 'return';
	static inline var kwStatic = 'static';
	static inline var kwSuper = 'super';
	static inline var kwSwitch = 'switch';
	static inline var kwThis = 'this';
	static inline var kwThrow = 'throw';
	static inline var kwTrue = 'true';
	static inline var kwTry = 'try';
	static inline var kwType = 'type';
	static inline var kwVar = 'var';
	static inline var kwWhile = 'while';

	// Hexa language parts
	static inline var docBegin = '///'; // Documentational comments
	static inline var docEnd = '';
	static inline var enumIndex = 'index';
	static inline var fileExtention = '.hexa';
	static inline var typeVoid = 'Void';
	static inline var typeString = 'String';
	static inline var typeInt = 'Int';
	static inline var typeBool = 'Bool';
	static inline var typeFloat = 'Float';
	static inline var typeDynamic = 'Any';

	static var renames: Map<String, String> = [
				'let' => 'value',
				'naN' => 'nan',
				'module' => 'container',
				'as' => 'convert',
				'declare' => 'define',
				'type' => 'kind',
			];

	public static function use() Context.onGenerate(proceed);

	static function proceed(types: Array<Type>) {
		trace('Up to ' + types.length + ' types total to convert.');

		for (type in types) {
			var output = '';
			var destination = 'bootstrap\\output\\';

			tabs = '';

			inline function out(string: String) output += string;

			function printClass(c: ClassType) {

				function doField(f: ClassField, sStatic: Bool) {
					var sPrivate = (!f.isPublic) ? '$kwPrivate ' : '';
					var sStatic = sStatic ? '$kwStatic ' : '';
					out(tabs);
					for (meta in f.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
					var name = camelCase(f.name);
					if (f.name != name) out('@rename(\'${f.name}\')\n$tabs');
					out(sPrivate + sStatic);

					switch (f.kind) {
					case FVar(t, e):
						out('$kwVar ');
						out(name);
						out(': ' + stringOfType(f.type));
						if (f.expr() != null) {
							out(' = ' + stringOf(f.expr()));
						}
					case FMethod(k):
						out('$kwFunction ');
						out(name);

						switch (f.type) {
						case TFun(args, ret):
							out(stringOfArgs(args) + ': ' + stringOfType(ret));
						case _: throw 'Unreachable code ' + f.type;
						}

						if (f.expr() != null)
							out(' ' + stringOf(f.expr().bodyOfFunction()) + '\n');
					}

					out('\n');
				}

				for (f in c.fields.get()) doField(f, false);
				for (f in c.statics.get()) doField(f, true);

				if (c.constructor != null) {
					var c = c.constructor.get();
					var sPrivate = (!c.isPublic) ? '$kwPrivate ' : '';
					out(tabs + sPrivate + kwNew);
					switch (c.type) {
					case TFun(args, ret):
						out(stringOfArgs(args));
					case _: throw 'Unreachable code ' + c.type;
					}
					if (c.expr() != null) out(' ' + stringOf(c.expr().bodyOfFunction()));
					out('\n');
				}
			}

			// Sets output file path depending on namespace
			function setDestination(module: String, name: String) {
				if (module != null) {
					if (module == name) {
						destination += name.toLowerCase();
						return ;
					}
					destination += module.toLowerCase();
					if (module.substr(module.lastIndexOf('.') + 1, module.length) != name) {
						destination += '.' + name.toLowerCase();
					}
				} else destination += name.toLowerCase();
			}

			switch (type) {
			// Classes and interfaces
			case TInst(t, pa): {
				var c: ClassType = t.get();
				var module = c.module.toLowerCase();
				if (c.module == c.name) module = null;
				setDestination(c.module, c.name);

				if (module != null) {
					out('$kwPackage $module {\n');
					pushTab();
				}

				out(tabs);
				for (meta in c.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
				var sExternal = c.isExtern ? '$kwExtern ' : '';
				var sPrivate = c.isPrivate ? '$kwPrivate ' : '';
				var sKind = c.isInterface ? '$kwInterface ' : '$kwClass ';
				var params = stringOfParams(pa);

				out(sPrivate + sExternal + sKind + typeCase(c.name) + params);
				if (c.superClass != null) out(' $kwExtends ' + c.superClass.t.get().name.typeCase() + stringOfParams(c.superClass.params));
				for (i in c.interfaces) {
					out(' $kwImplements ' + i.t.get().name.typeCase() + stringOfParams(i.params));
				}
				out(' {\n');
				pushTab();

				printClass(c);

				popTab();
				out(tabs + '}');

				if (c.init != null) {
					out('\n\n$tabs// __init__\n$tabs' + c.init.stringOf());
				}

				if (module != null) {
					popTab();
					out('\n}');
				}

			}
			// Wrappers
			case TAbstract(t, pa): {
				var c = t.get();
				setDestination(c.module, c.name);

				// Skip built-ins
				if (stringOfType(type) == stringOfType(t.get().type)) {
					trace('Passing ' + t.get().name);
					continue ;
				}

				var module = c.module.toLowerCase();
				if (c.module == c.name) module = null;

				if (module != null) {
					out('$kwPackage $module {\n');
					pushTab();
				}

				var sExternal = c.isExtern ? '$kwExtern ' : '';
				var sPrivate = c.isPrivate ? '$kwPrivate ' : '';

				out(tabs);
				for (meta in c.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
				if (c.doc != null) out('$docBegin ${c.doc}$docEnd\n$tabs');
				out(sPrivate + sExternal + kwType + ' ' + typeCase(t.get().name));
				out(stringOfParams(pa));
				out(' : ' + stringOfType(t.get().type) + ' {\n');
				pushTab();

				if (t.get().impl != null)
					printClass(t.get().impl.get());

				/*
				array:Array<ClassField>
				The defined array-access fields of the abstract.
				binops:Array<{op:Binop, field:ClassField}>
				The defined binary operators of the abstract.
				from:Array<{t:Type, field:Null<ClassField>}>
				The available implicit from-casts of the abstract.
				See:
				https://haxe.org/manual/types-abstract-implicit-casts.html
				impl:Null<Ref<ClassType>>
				The implementation class of the abstract, if available.
				pack:Array<String>
				The package of the type.
				resolve:Null<ClassField>
				The method used for resolving unknown field access, if available.
				to:Array<{t:Type, field:Null<ClassField>}>
				The available implicit to-casts of the abstract.
				See:
				https://haxe.org/manual/types-abstract-implicit-casts.html
				type:Type
				The underlying type of the abstract.
				unops:Array<{postFix:Bool, op:Unop, field:ClassField}>
				The defined unary operators of the abstract.
				*/

				popTab();
				out(tabs + '}');

				if (module != null) {
					popTab();
					out('\n}');
				}
			}
			// Typedefs
			case TType(t, pa): {
				var c = t.get();
				var module = c.module.toLowerCase();
				if (c.module == c.name) module = null;
				setDestination(c.module, c.name);

				if (module != null) {
					out('$kwPackage $module {\n');
					pushTab();
				}

				var sExternal = c.isExtern ? '$kwExtern ' : '';
				var sPrivate = c.isPrivate ? '$kwPrivate ' : '';

				out(tabs);
				for (meta in c.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
				out(sPrivate + sExternal + '$kwType ' + typeCase(t.get().name));
				out(stringOfParams(pa));
				out(' = ' + stringOfType(t.get().type));

				if (module != null) {
					popTab();
					out('\n}');
				}
			}
			// Enumeration
			case TEnum(t, pa): {
				var c = t.get();
				var module = c.module.toLowerCase();
				if (c.module == c.name) module = null;
				setDestination(c.module, c.name);

				if (module != null) {
					out('$kwPackage $module {\n');
					pushTab();
				}

				var sExternal = c.isExtern ? '$kwExtern ' : '';
				var sPrivate = c.isPrivate ? '$kwPrivate ' : '';

				out(tabs);
				for (meta in c.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
				out(sPrivate + sExternal + '$kwEnum ' + typeCase(t.get().name));
				out(stringOfParams(pa));
				out(' {\n');
				pushTab();

				for (n in c.names) {
					var f = c.constructs[n];
					out(tabs);
					for (meta in f.meta.get()) out(stringOfMeta(meta) + '\n$tabs');
					out(n);
					switch (f.type) {
					case TFun(args, retType):
						out('(' + [for (arg in args) camelCase(arg.name) + ':' + stringOfType(arg.t)].join(', ') + ')');
					default: {}
					}
					out('\n');
				}

				popTab();
				out(tabs + '}');

				if (module != null) {
					popTab();
					out('\n}');
				}
			}
			case TAnonymous(fields): throw 'Unreachable code';
			case TLazy(f): throw 'Unreachable code';
			case TDynamic(null): throw 'Unreachable code';
			case TDynamic(t): throw 'Unreachable code';
			case TMono(t): throw 'Unreachable code';
			case TFun(args, ret): throw 'Unreachable code';
			}

			trace('Writing ' + destination + '...');
			File.saveContent(destination + fileExtention, output + '\n');
		}
	}

	// Control indentation
	static inline function pushTab() tabs += '\t';
	static inline function popTab() tabs = tabs.substring(0, tabs.length - 1);

	// Binary operators
	static function stringOfBinop(op: Binop): String
	return switch (op) {
	case OpAdd: '+';
	case OpMult: '*';
	case OpDiv: '/';
	case OpSub: '-';
	case OpAssign: '=';
	case OpEq: '==';
	case OpNotEq: '!=';
	case OpGt: '>';
	case OpGte: '>=';
	case OpLt: '<';
	case OpLte: '<=';
	case OpBoolAnd: '&&';
	case OpBoolOr: '||';
	case OpMod: '%';
	case OpInterval: '...';
	case OpOr: '|';
	case OpAnd: '&';
	case OpArrow: '=>';
	case OpShr: '>>';
	case OpUShr: '>>>';
	case OpShl: '<<';
	case OpXor: '^';
	default: throw 'Unreachable code ' + op;
	}

	// Unary operators
	static function stringOfUnop(op: Unop): String
	return switch (op) {
	case OpIncrement: '++';
	case OpDecrement: '--';
	case OpNot: '!';
	case OpNeg: '-';
	case OpNegBits: '~';
	}

	// String representation of expression
	static function stringOf(e: TypedExpr): String {
		var r = '';
		if (e == null) throw 'Unreachable code';
		return switch (e.expr) {
		case TConst(TBool(true)): kwTrue;
		case TConst(TBool(false)): kwFalse;
		case TBreak: kwBreak;
		case TContinue: kwContinue;
		case TConst(TNull): kwNull;
		case TConst(TThis): kwThis;
		case TConst(TInt(i)): '$i';
		case TConst(TFloat(s)): stringOfFloat(s);
		case TConst(TString(s)): stringOfString(s);
		case TConst(TSuper): kwSuper;
		case TLocal(t): t.name.replace('`trace', 'Log.trace').camelCase();
		case TFunction(func):
			var args : Array < {t: Type, opt: Bool, name: String} >
			= [for(a in func.args) {t: a.v.t, opt: a.value != null, name: a.v.name.camelCase()}];
			kwFunction + stringOfArgs(args) + ': ' + stringOfType(func.t)
			+ ' ' + stringOf(func.expr);
		case TBlock([]): '{}';
		case TBlock(el):
			r = '{\n';
			pushTab();
			for (e in el) r += tabs +
				(switch (e.expr) {
			// Make a safe postfix unop (coz Hexa has no semicolons)
			case TUnop(OpNot|OpNegBits|OpNeg, false, e): stringOf(e);
				case TUnop(op, false, e): stringOf(e) + stringOfUnop(op);
				case _: stringOf(e);
				})
			+ '\n';
			popTab();
			r + tabs + '}';

		case TReturn(null): '$kwReturn {}';
		case TReturn(e): '$kwReturn ' + stringOf(e);

		case TBinop(OpAssignOp(op), e1, e2):
			stringOf(e1) + ' ' + stringOfBinop(op) + '= ' + stringOf(e2);
		case TBinop(op, e1, e2):
			stringOf(e1) + ' ' + stringOfBinop(op) + ' ' + stringOf(e2);
		case TUnop(op, post, e):
			post ? stringOf(e) + stringOfUnop(op) : stringOfUnop(op) + stringOf(e);

		case TCall(e, []): stringOf(e) + '()';
		case TCall(e, el):
			r = stringOf(e) + '(';
			for (e in el) {
				if (e != el[0]) r += ', ';
				r += stringOf(e);
			}
			r + ')';
		case TField(e, fa):
			stringOf(e) + '.' + switch (fa) {
			case FAnon(cf): cf.get().name.camelCase();
			case FStatic(c, cf): cf.get().name.camelCase();
			case FInstance(c, params, cf): cf.get().name.camelCase();
			case FDynamic(s): s;
			case FEnum(e, ef): '' + ef.name.camelCase();
			case _: throw fa;
			}
		case TArrayDecl(el):
			'[' + [for(e in el) stringOf(e)].join(', ') + ']';
		case TObjectDecl([]): '{:}';
		case TObjectDecl(el):
			'{' + [for(e in el) e.name.camelCase() + ': ' + stringOf(e.expr)].join(', ') + '}';
		case TArray(e1, e2):
			switch [e1.t, e2.expr] {
				case [TEnum(_), TConst(TInt(1))]: stringOf(e1) + '.$enumIndex';
					case _: stringOf(e1) + '[' + stringOf(e2) + ']';
						}
					case TNew(c, pa, el):
			r = '$kwNew ' + c.get().name.typeCase();
			r += stringOfParams(pa);
			r += '(' + ([for(e in el) stringOf(e)].join(', ')) + ')';
			r;

		case TVar(v, null): '$kwVar ' + v.name.camelCase() + ': ' + stringOfType(v.t);
		case TVar(v, e):
			switch (e.expr) {
			case TEnumParameter(e1, ef, index):
				// Extractor
				r = '$kwConst ' + stringOfType(e1.t) + '.' + ef.name.typeCase() + '(';
				switch (ef.type) {
				case TFun(args, retType): // EnumField(...args)
					for (i in 0...args.length) {
						if (i > 0) r += ', ';
						if (index == i) r += v.name.camelCase();
						if (index != i) r += '_';
					}
				default: throw 'Unreachable code'; // EnumField
				}

				r + ') = ' + stringOf(e1);
			case _: '$kwVar ' + v.name.camelCase() + ': ' + stringOfType(v.t) + ' = ' + stringOf(e);
			}

		case TParenthesis(e): '(' + stringOf(e) + ')';
		case TIf(econd, eif, null):
			kwIf + stringOf(econd) + ' ' + stringOf(eif);
		case TIf(econd, eif, eelse):
			kwIf + stringOf(econd) + ' ' + stringOf(eif) + ' $kwElse ' + stringOf(eelse);

		// Pattern matcher
		// Plain switch
		case TSwitch(e, cases, edef):
			pushTab();
			function casegen(c: Array<TypedExpr>): String {
				return '' + [for(c in c) stringOf(c)].join(', ');
			}
			r = '$kwSwitch ' + stringOf(e) + ' {'
				+ [for(c in cases) '\n$tabs$kwCase ${casegen(c.values)}: ' + stringOf(c.expr)].join('\n')
				+ (edef != null ? '\n' + tabs + '\n${tabs}$kwCase _: ' + stringOf(edef) : '');
			popTab();
			r + '\n$tabs}';

		case TThrow(e): '$kwThrow ' + stringOf(e);
		case TCast(ex, null): '(' + stringOf(ex) + ' $kwAs! ' + stringOfType(e.t) + ')';
		case TCast(e, m): '(' + stringOf(e) + ' $kwAs ' + m.getName() + ')';
		case TWhile(econd, e, true): '$kwWhile' + stringOf(econd) + ' ' + stringOf(e);
		case TWhile(econd, e, false): '$kwDo ' + stringOf(e) + ' $kwWhile' + stringOf(econd) + '';
		case TTry(e, catches):
			'$kwTry ' + stringOf(e) +
			[for(c in catches) ' $kwCatch(' + c.v.name.camelCase() + ':' + stringOfType(c.v.t) + ') ' + stringOf(c.expr) ].join('\n');
		case TMeta(m, e): stringOfMeta(m) + ' ' + stringOf(e);
		case TTypeExpr(TEnumDecl(e)): '' + e;// TODO huh?
		case TTypeExpr(TClassDecl(c)): c.get().name.typeCase();
		case TTypeExpr(TAbstract(e)): '' + e;
		case TTypeExpr(TTypeDecl(t)): '' + t.get();

		// Lets try to extract an enum value and return from block
		case TEnumParameter(e1, ef, index):
			r = '{ $kwConst ';
			r += stringOfType(e1.t);
			r += '.' + ef.name.typeCase();
			r += '(';
			switch (ef.type) {
			case TFun(args, retType): // EnumField(...args)
				for (i in 0...args.length) {
					if (i > 0) r += ', ';
					if (index == i) r += 'value';
					if (index != i) r += '_';
				}
			default: throw 'Unreachable code'; // EnumField
			}

			r += ')';
			r += ' = ' + stringOf(e1);
			r + ' value }';

		case TFor(v, e1, e2): /*throw*/ '$kwFor($v $kwIn $e1) ' + stringOf(e2);
		case e: throw e;
		}
	}

	// Prints the textual representaton of type for value:T definitions
	static function stringOfType(t: Type): String {
		return switch (t) {
		// Built-in
		case TAbstract(_.get().name => 'Void', []): typeVoid;
		case TAbstract(_.get().name => 'Int', []): typeInt;
		case TAbstract(_.get().name => 'Bool', []): typeBool;
		case TAbstract(_.get().name => 'Float', []): typeFloat;
		case TInst(_.get().name => 'String', []): typeString;
		case TInst(_.get().name => 'Array', [p]): '[' + stringOfType(p) + ']';
		case TAbstract(_.get().name => 'Map', [k, v]): '[' + stringOfType(k) + ':' + stringOfType(v) + ']';
		case TType(_.get().name => 'Null', [p]): stringOfType(p) + '?';

		// Non-parametric
		case TAbstract(t, []): t.get().name.typeCase();
		case TType(t, []): t.get().name.typeCase();
		case TEnum(t, []): t.get().name.typeCase();
		case TInst(t, []): t.get().name.typeCase();

		// Parametric
		case TType(t, pa), TAbstract(t, pa):
			t.get().name.typeCase() + stringOfParams(pa);
		case TInst(t, pa):
			t.get().name.typeCase() + stringOfParams(pa);
		case TEnum(t, pa):
			t.get().name.typeCase() + stringOfParams(pa);

		// Empty structure
		case TAnonymous(_.get().fields.length => 0): '{:}';
		case TAnonymous(a):
			var a = a.get();
			var r = '{';
			for (f in a.fields) {
				if (r != '{') r += ', ';
				r += f.name.camelCase() + ': ' + stringOfType(f.type);
			}
			if (a.fields.length == 0) r += ':';
			r + '}';

		case TFun([arg], ret): '' + stringOfType(arg.t) + '=>' + stringOfType(ret);
		case TFun(args, ret): stringOfArgs(args) + '=>' + stringOfType(ret);
		case TDynamic(null): typeDynamic;
		case TMono(t) if (t.get() != null): stringOfType(t.get());
		case TMono(t): typeDynamic;
		case _: throw 'Unreachable code ' + t;
		}
	}

	// Function arguments
	static function stringOfArgs(args: Array < {t: Type, opt: Bool, name: String} > ): String {
		var r = '';
		for (a in args) {
			if (r != '') r += ', ';
			if (a.name != null && a.name != '')
				r += a.name.camelCase() + ': ';
			r += stringOfType(a.t);
		}
		return '(' + r + ')';
	}

	// Polymorphic <parameters>
	static function stringOfParams(pa: Array<Type>): String {
		if (pa.length > 0)
			return '<' + ([for(p in pa) stringOfType(p)].join(', ')) + '>';
		return '';
	}

	// TODO print AST
	// String representation of @meta attributes
	static function stringOfMeta(meta: MetadataEntry): String {
		return '@' + meta.name.replace(':', '').camelCase() +
		(meta.params != null && meta.params.length > 0 ? '(' + [for(m in meta.params) '' + stringOfMetaExpr(m.expr)].join(', ') + ')' : '');
	}

	// Ensures camelCase
	// Makes variable name camel case if it was SNAKE_CASE
	static function camelCase(s: String): String {
		if (s.toUpperCase() == s) {
			var s = s.split('_');
			var r = s.shift().toLowerCase();
			while (s.length > 0) {
				var s = s.shift().toLowerCase();
				r += s.substr(0, 1).toUpperCase() + s.substr(1);
			}
			return rename(r);
		}
		return rename(s.substr(0, 1).toLowerCase() + s.substr(1));
	}

	// Ensures TitleCase
	// Replaces front underscore `_` with `T`
	static function typeCase(s: String): String {
		if (s.startsWith('_')) s = 'T' + s.substr(1);
		return s.substr(0, 1).toUpperCase() + s.substr(1);
	}

	// Avoid name clashing
	static function rename(s: String): String {
		s = s.replace('$$', '_');
		if (renames[s] != null) s = renames[s];
		return s;
	}

	// Prints untyped expression node
	static function stringOfMetaExpr(e: ExprDef): String {
		if (e == null) throw 'Unreachable code';
		return switch (e) {
		case EConst(CString(s)): stringOfString(s);
		case EConst(CInt(s)): stringOfInt(s);
		case EConst(CFloat(s)): stringOfFloat(s);
		case EConst(CIdent(s)): rename(s);
		case EUnop(op, post, e):
			post ? stringOfMetaExpr(e.expr) + stringOfUnop(op) : stringOfUnop(op) + stringOfMetaExpr(e.expr);
		case EBinop(OpAssignOp(op), e1, e2):
			stringOfMetaExpr(e1.expr) + ' ' + stringOfBinop(op) + '= ' + stringOfMetaExpr(e2.expr);
		case EBinop(op, e1, e2):
			stringOfMetaExpr(e1.expr) + ' ' + stringOfBinop(op) + ' ' + stringOfMetaExpr(e2.expr);
		case EArrayDecl(el):
			'[' + [for(e in el) stringOfMetaExpr(e.expr)].join(', ') + ']';
		case EMeta(s, e): stringOfMeta(s) + ' ' + stringOfMetaExpr(e.expr);
		case EField(e, field): stringOfMetaExpr(e.expr) + '.' + field;
		case e: throw e; // Gradually add printing features
		}
	}

	// Converts representation to Hexa
	static function stringOfFloat(s: String): String {
		s = s.replace('E', 'e');
		if (s.startsWith('.')) s = '0' + s;
		if (s.endsWith('.')) s += '0';
		return s;
	}

	// Converts representation to Hexa
	static function stringOfString(s: String): String {
		return '\'' +
		s
		.replace('\\', '\\\\')
		.replace('\n', '\\n')
		.replace('\r', '\\r')
		.replace('\t', '\\t')
		.replace('\'', '\\\'') + '\'';
	}

	// Converts representation to Hexa
	static function stringOfInt(s: String): String {
		return s.toUpperCase().replace('X', 'x');
	}

	// Get a body of function expression
	static function bodyOfFunction(e: TypedExpr): TypedExpr {
		return switch (e.expr) {
		case TFunction(func): func.expr;
		case _: e;
		}
	}

#end
}