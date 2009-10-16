/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */




/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     _BANG_t = 258,
     _BANG_EQUALS_t = 259,
     _AMPER_t = 260,
     _AMPERAMPER_t = 261,
     _LPAREN_t = 262,
     _RPAREN_t = 263,
     _PLUS_EQUALS_t = 264,
     _MINUS_EQUALS_t = 265,
     _COLON_t = 266,
     _SEMIC_t = 267,
     _LANGLE_t = 268,
     _LANGLE_EQUALS_t = 269,
     _EQUALS_t = 270,
     _RANGLE_t = 271,
     _RANGLE_EQUALS_t = 272,
     _QUESTION_EQUALS_t = 273,
     _LBRACKET_t = 274,
     _RBRACKET_t = 275,
     ACTIONS_t = 276,
     BIND_t = 277,
     BREAK_t = 278,
     CASE_t = 279,
     CONTINUE_t = 280,
     DEFAULT_t = 281,
     ELSE_t = 282,
     EXISTING_t = 283,
     FOR_t = 284,
     IF_t = 285,
     IGNORE_t = 286,
     IN_t = 287,
     INCLUDE_t = 288,
     LOCAL_t = 289,
     LUA_t = 290,
     MAXLINE_t = 291,
     MAXTARGETS_t = 292,
     ON_t = 293,
     PIECEMEAL_t = 294,
     QUIETLY_t = 295,
     REMOVEEMPTYDIRS_t = 296,
     RESPONSE_t = 297,
     RETURN_t = 298,
     RULE_t = 299,
     SCREENOUTPUT_t = 300,
     SWITCH_t = 301,
     TOGETHER_t = 302,
     UPDATED_t = 303,
     WHILE_t = 304,
     _LBRACE_t = 305,
     _BAR_t = 306,
     _BARBAR_t = 307,
     _RBRACE_t = 308,
     ARG = 309,
     STRING = 310
   };
#endif
/* Tokens.  */
#define _BANG_t 258
#define _BANG_EQUALS_t 259
#define _AMPER_t 260
#define _AMPERAMPER_t 261
#define _LPAREN_t 262
#define _RPAREN_t 263
#define _PLUS_EQUALS_t 264
#define _MINUS_EQUALS_t 265
#define _COLON_t 266
#define _SEMIC_t 267
#define _LANGLE_t 268
#define _LANGLE_EQUALS_t 269
#define _EQUALS_t 270
#define _RANGLE_t 271
#define _RANGLE_EQUALS_t 272
#define _QUESTION_EQUALS_t 273
#define _LBRACKET_t 274
#define _RBRACKET_t 275
#define ACTIONS_t 276
#define BIND_t 277
#define BREAK_t 278
#define CASE_t 279
#define CONTINUE_t 280
#define DEFAULT_t 281
#define ELSE_t 282
#define EXISTING_t 283
#define FOR_t 284
#define IF_t 285
#define IGNORE_t 286
#define IN_t 287
#define INCLUDE_t 288
#define LOCAL_t 289
#define LUA_t 290
#define MAXLINE_t 291
#define MAXTARGETS_t 292
#define ON_t 293
#define PIECEMEAL_t 294
#define QUIETLY_t 295
#define REMOVEEMPTYDIRS_t 296
#define RESPONSE_t 297
#define RETURN_t 298
#define RULE_t 299
#define SCREENOUTPUT_t 300
#define SWITCH_t 301
#define TOGETHER_t 302
#define UPDATED_t 303
#define WHILE_t 304
#define _LBRACE_t 305
#define _BAR_t 306
#define _BARBAR_t 307
#define _RBRACE_t 308
#define ARG 309
#define STRING 310


#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;
