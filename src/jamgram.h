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


#pragma once


/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    _BANG_t = 258,                 /* _BANG_t  */
    _BANG_EQUALS_t = 259,          /* _BANG_EQUALS_t  */
    _AMPER_t = 260,                /* _AMPER_t  */
    _AMPERAMPER_t = 261,           /* _AMPERAMPER_t  */
    _LPAREN_t = 262,               /* _LPAREN_t  */
    _RPAREN_t = 263,               /* _RPAREN_t  */
    _PLUS_EQUALS_t = 264,          /* _PLUS_EQUALS_t  */
    _MINUS_EQUALS_t = 265,         /* _MINUS_EQUALS_t  */
    _COLON_t = 266,                /* _COLON_t  */
    _SEMIC_t = 267,                /* _SEMIC_t  */
    _LANGLE_t = 268,               /* _LANGLE_t  */
    _LANGLE_EQUALS_t = 269,        /* _LANGLE_EQUALS_t  */
    _EQUALS_t = 270,               /* _EQUALS_t  */
    _RANGLE_t = 271,               /* _RANGLE_t  */
    _RANGLE_EQUALS_t = 272,        /* _RANGLE_EQUALS_t  */
    _QUESTION_EQUALS_t = 273,      /* _QUESTION_EQUALS_t  */
    _LBRACKET_t = 274,             /* _LBRACKET_t  */
    _RBRACKET_t = 275,             /* _RBRACKET_t  */
    ACTIONS_t = 276,               /* ACTIONS_t  */
    BIND_t = 277,                  /* BIND_t  */
    BREAK_t = 278,                 /* BREAK_t  */
    CASE_t = 279,                  /* CASE_t  */
    CLEANUNUSEDTARGETS_t = 280,    /* CLEANUNUSEDTARGETS_t  */
    CONTINUE_t = 281,              /* CONTINUE_t  */
    DEFAULT_t = 282,               /* DEFAULT_t  */
    ELSE_t = 283,                  /* ELSE_t  */
    EXISTING_t = 284,              /* EXISTING_t  */
    FOR_t = 285,                   /* FOR_t  */
    IF_t = 286,                    /* IF_t  */
    IGNORE_t = 287,                /* IGNORE_t  */
    IN_t = 288,                    /* IN_t  */
    INCLUDE_t = 289,               /* INCLUDE_t  */
    LOCAL_t = 290,                 /* LOCAL_t  */
    LUA_t = 291,                   /* LUA_t  */
    MAXLINE_t = 292,               /* MAXLINE_t  */
    MAXTARGETS_t = 293,            /* MAXTARGETS_t  */
    ON_t = 294,                    /* ON_t  */
    PIECEMEAL_t = 295,             /* PIECEMEAL_t  */
    QUIETLY_t = 296,               /* QUIETLY_t  */
    REMOVEEMPTYDIRS_t = 297,       /* REMOVEEMPTYDIRS_t  */
    RESPONSE_t = 298,              /* RESPONSE_t  */
    RETURN_t = 299,                /* RETURN_t  */
    RULE_t = 300,                  /* RULE_t  */
    SCREENOUTPUT_t = 301,          /* SCREENOUTPUT_t  */
    SWITCH_t = 302,                /* SWITCH_t  */
    TOGETHER_t = 303,              /* TOGETHER_t  */
    UPDATED_t = 304,               /* UPDATED_t  */
    WHILE_t = 305,                 /* WHILE_t  */
    _LBRACE_t = 306,               /* _LBRACE_t  */
    _BAR_t = 307,                  /* _BAR_t  */
    _BARBAR_t = 308,               /* _BARBAR_t  */
    _RBRACE_t = 309,               /* _RBRACE_t  */
    ARG = 310,                     /* ARG  */
    STRING = 311                   /* STRING  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
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
#define CLEANUNUSEDTARGETS_t 280
#define CONTINUE_t 281
#define DEFAULT_t 282
#define ELSE_t 283
#define EXISTING_t 284
#define FOR_t 285
#define IF_t 286
#define IGNORE_t 287
#define IN_t 288
#define INCLUDE_t 289
#define LOCAL_t 290
#define LUA_t 291
#define MAXLINE_t 292
#define MAXTARGETS_t 293
#define ON_t 294
#define PIECEMEAL_t 295
#define QUIETLY_t 296
#define REMOVEEMPTYDIRS_t 297
#define RESPONSE_t 298
#define RETURN_t 299
#define RULE_t 300
#define SCREENOUTPUT_t 301
#define SWITCH_t 302
#define TOGETHER_t 303
#define UPDATED_t 304
#define WHILE_t 305
#define _LBRACE_t 306
#define _BAR_t 307
#define _BARBAR_t 308
#define _RBRACE_t 309
#define ARG 310
#define STRING 311

#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
#endif

extern YYSTYPE yylval;
