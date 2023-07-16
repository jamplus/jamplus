/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

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

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 91 "jamgram.y"

#include "jam.h"

#include "lists.h"
#include "variable.h"
#include "parse.h"
#include "scan.h"
#include "compile.h"
#include "newstr.h"
#include "rules.h"

# define YYMAXDEPTH 10000	/* for OSF and other less endowed yaccs */

# define F0 (LIST *(*)(PARSE *, LOL *, int *))0
# define P0 (PARSE *)0
# define S0 (char *)0

# define pappend( l,r )    	parse_make( compile_append,l,r,P0,S0,S0,0 )
# define pbreak( l,f )     	parse_make( compile_break,l,P0,P0,S0,S0,f )
# define peval( c,l,r )		parse_make( compile_eval,l,r,P0,S0,S0,c )
# define pfor( s,l,r )    	parse_make( compile_foreach,l,r,P0,s,S0,0 )
# define pif( l,r,t )	  	parse_make( compile_if,l,r,t,S0,S0,0 )
# define pincl( l )       	parse_make( compile_include,l,P0,P0,S0,S0,0 )
# define plist( s )	  	parse_make( compile_list,P0,P0,P0,s,S0,0 )
# define plocal( l,r,t )  	parse_make( compile_local,l,r,t,S0,S0,0 )
# define pnull()	  	parse_make( compile_null,P0,P0,P0,S0,S0,0 )
# define pon( l,r )	  	parse_make( compile_on,l,r,P0,S0,S0,0 )
# define prule( a,p )     	parse_make( compile_rule,a,p,P0,S0,S0,0 )
# define prules( l,r )	  	parse_make( compile_rules,l,r,P0,S0,S0,0 )
# define pset( l,r,a ) 	  	parse_make( compile_set,l,r,P0,S0,S0,a )
# define pset1( l,r,t,a )	parse_make( compile_settings,l,r,t,S0,S0,a )
# define psetc( s,l,r )     	parse_make( compile_setcomp,l,r,P0,s,S0,0 )
# define psete( s,l,s1,f,f2,f3 ) 	parse_make3( compile_setexec,l,P0,P0,s,s1,f,f2,f3 )
# define pswitch( l,r )   	parse_make( compile_switch,l,r,P0,S0,S0,0 )
# define pwhile( l,r )   	parse_make( compile_while,l,r,P0,S0,S0,0 )

# define pnode( l,r )    	parse_make( F0,l,r,P0,S0,S0,0 )
# define psnode( s,l )     	parse_make( F0,l,P0,P0,s,S0,0 )


#line 112 "y.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

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

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;


int yyparse (void);



/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL__BANG_t = 3,                    /* _BANG_t  */
  YYSYMBOL__BANG_EQUALS_t = 4,             /* _BANG_EQUALS_t  */
  YYSYMBOL__AMPER_t = 5,                   /* _AMPER_t  */
  YYSYMBOL__AMPERAMPER_t = 6,              /* _AMPERAMPER_t  */
  YYSYMBOL__LPAREN_t = 7,                  /* _LPAREN_t  */
  YYSYMBOL__RPAREN_t = 8,                  /* _RPAREN_t  */
  YYSYMBOL__PLUS_EQUALS_t = 9,             /* _PLUS_EQUALS_t  */
  YYSYMBOL__MINUS_EQUALS_t = 10,           /* _MINUS_EQUALS_t  */
  YYSYMBOL__COLON_t = 11,                  /* _COLON_t  */
  YYSYMBOL__SEMIC_t = 12,                  /* _SEMIC_t  */
  YYSYMBOL__LANGLE_t = 13,                 /* _LANGLE_t  */
  YYSYMBOL__LANGLE_EQUALS_t = 14,          /* _LANGLE_EQUALS_t  */
  YYSYMBOL__EQUALS_t = 15,                 /* _EQUALS_t  */
  YYSYMBOL__RANGLE_t = 16,                 /* _RANGLE_t  */
  YYSYMBOL__RANGLE_EQUALS_t = 17,          /* _RANGLE_EQUALS_t  */
  YYSYMBOL__QUESTION_EQUALS_t = 18,        /* _QUESTION_EQUALS_t  */
  YYSYMBOL__LBRACKET_t = 19,               /* _LBRACKET_t  */
  YYSYMBOL__RBRACKET_t = 20,               /* _RBRACKET_t  */
  YYSYMBOL_ACTIONS_t = 21,                 /* ACTIONS_t  */
  YYSYMBOL_BIND_t = 22,                    /* BIND_t  */
  YYSYMBOL_BREAK_t = 23,                   /* BREAK_t  */
  YYSYMBOL_CASE_t = 24,                    /* CASE_t  */
  YYSYMBOL_CLEANUNUSEDTARGETS_t = 25,      /* CLEANUNUSEDTARGETS_t  */
  YYSYMBOL_CONTINUE_t = 26,                /* CONTINUE_t  */
  YYSYMBOL_DEFAULT_t = 27,                 /* DEFAULT_t  */
  YYSYMBOL_ELSE_t = 28,                    /* ELSE_t  */
  YYSYMBOL_EXISTING_t = 29,                /* EXISTING_t  */
  YYSYMBOL_FOR_t = 30,                     /* FOR_t  */
  YYSYMBOL_IF_t = 31,                      /* IF_t  */
  YYSYMBOL_IGNORE_t = 32,                  /* IGNORE_t  */
  YYSYMBOL_IN_t = 33,                      /* IN_t  */
  YYSYMBOL_INCLUDE_t = 34,                 /* INCLUDE_t  */
  YYSYMBOL_LOCAL_t = 35,                   /* LOCAL_t  */
  YYSYMBOL_LUA_t = 36,                     /* LUA_t  */
  YYSYMBOL_MAXLINE_t = 37,                 /* MAXLINE_t  */
  YYSYMBOL_MAXTARGETS_t = 38,              /* MAXTARGETS_t  */
  YYSYMBOL_ON_t = 39,                      /* ON_t  */
  YYSYMBOL_PIECEMEAL_t = 40,               /* PIECEMEAL_t  */
  YYSYMBOL_QUIETLY_t = 41,                 /* QUIETLY_t  */
  YYSYMBOL_REMOVEEMPTYDIRS_t = 42,         /* REMOVEEMPTYDIRS_t  */
  YYSYMBOL_RESPONSE_t = 43,                /* RESPONSE_t  */
  YYSYMBOL_RETURN_t = 44,                  /* RETURN_t  */
  YYSYMBOL_RULE_t = 45,                    /* RULE_t  */
  YYSYMBOL_SCREENOUTPUT_t = 46,            /* SCREENOUTPUT_t  */
  YYSYMBOL_SWITCH_t = 47,                  /* SWITCH_t  */
  YYSYMBOL_TOGETHER_t = 48,                /* TOGETHER_t  */
  YYSYMBOL_UPDATED_t = 49,                 /* UPDATED_t  */
  YYSYMBOL_WHILE_t = 50,                   /* WHILE_t  */
  YYSYMBOL__LBRACE_t = 51,                 /* _LBRACE_t  */
  YYSYMBOL__BAR_t = 52,                    /* _BAR_t  */
  YYSYMBOL__BARBAR_t = 53,                 /* _BARBAR_t  */
  YYSYMBOL__RBRACE_t = 54,                 /* _RBRACE_t  */
  YYSYMBOL_ARG = 55,                       /* ARG  */
  YYSYMBOL_STRING = 56,                    /* STRING  */
  YYSYMBOL_YYACCEPT = 57,                  /* $accept  */
  YYSYMBOL_run = 58,                       /* run  */
  YYSYMBOL_block = 59,                     /* block  */
  YYSYMBOL_rules = 60,                     /* rules  */
  YYSYMBOL_rule = 61,                      /* rule  */
  YYSYMBOL_62_1 = 62,                      /* $@1  */
  YYSYMBOL_63_2 = 63,                      /* $@2  */
  YYSYMBOL_assign = 64,                    /* assign  */
  YYSYMBOL_expr = 65,                      /* expr  */
  YYSYMBOL_cases = 66,                     /* cases  */
  YYSYMBOL_case = 67,                      /* case  */
  YYSYMBOL_params = 68,                    /* params  */
  YYSYMBOL_lol = 69,                       /* lol  */
  YYSYMBOL_list = 70,                      /* list  */
  YYSYMBOL_listp = 71,                     /* listp  */
  YYSYMBOL_arg = 72,                       /* arg  */
  YYSYMBOL_73_3 = 73,                      /* $@3  */
  YYSYMBOL_func = 74,                      /* func  */
  YYSYMBOL_eflags = 75,                    /* eflags  */
  YYSYMBOL_eflag = 76,                     /* eflag  */
  YYSYMBOL_bindlist = 77                   /* bindlist  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  39
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   272

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  57
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  21
/* YYNRULES -- Number of rules.  */
#define YYNRULES  80
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  162

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   311


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   134,   134,   136,   148,   149,   153,   155,   157,   159,
     163,   165,   167,   169,   171,   173,   175,   177,   179,   181,
     183,   185,   187,   189,   191,   194,   196,   193,   205,   207,
     209,   211,   213,   221,   223,   225,   227,   229,   231,   233,
     235,   237,   239,   241,   243,   245,   247,   258,   259,   263,
     273,   274,   276,   285,   287,   297,   302,   303,   307,   309,
     309,   318,   320,   322,   332,   333,   337,   339,   341,   343,
     345,   347,   349,   351,   353,   355,   357,   359,   361,   371,
     372
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "_BANG_t",
  "_BANG_EQUALS_t", "_AMPER_t", "_AMPERAMPER_t", "_LPAREN_t", "_RPAREN_t",
  "_PLUS_EQUALS_t", "_MINUS_EQUALS_t", "_COLON_t", "_SEMIC_t", "_LANGLE_t",
  "_LANGLE_EQUALS_t", "_EQUALS_t", "_RANGLE_t", "_RANGLE_EQUALS_t",
  "_QUESTION_EQUALS_t", "_LBRACKET_t", "_RBRACKET_t", "ACTIONS_t",
  "BIND_t", "BREAK_t", "CASE_t", "CLEANUNUSEDTARGETS_t", "CONTINUE_t",
  "DEFAULT_t", "ELSE_t", "EXISTING_t", "FOR_t", "IF_t", "IGNORE_t", "IN_t",
  "INCLUDE_t", "LOCAL_t", "LUA_t", "MAXLINE_t", "MAXTARGETS_t", "ON_t",
  "PIECEMEAL_t", "QUIETLY_t", "REMOVEEMPTYDIRS_t", "RESPONSE_t",
  "RETURN_t", "RULE_t", "SCREENOUTPUT_t", "SWITCH_t", "TOGETHER_t",
  "UPDATED_t", "WHILE_t", "_LBRACE_t", "_BAR_t", "_BARBAR_t", "_RBRACE_t",
  "ARG", "STRING", "$accept", "run", "block", "rules", "rule", "$@1",
  "$@2", "assign", "expr", "cases", "case", "params", "lol", "list",
  "listp", "arg", "$@3", "func", "eflags", "eflag", "bindlist", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-67)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     152,   -67,   -67,   -67,   -67,   -51,     8,   -67,   -67,     3,
     -67,   -36,   -67,     8,   152,   -67,    24,   -67,   152,    57,
      -6,   209,    13,     3,    14,     1,     8,     8,    25,    20,
      45,    31,   185,    50,   -19,    19,   128,    10,   -67,   -67,
     -67,   -67,   -67,   -67,   -67,    53,   -67,   -67,    62,    54,
       3,   -67,    59,   -67,   -67,   -67,   -67,    26,    30,   -67,
     -67,   -67,   -67,   -67,   -67,   -67,    58,   -67,   -67,   -67,
     -67,   -67,   -67,   142,     8,     8,     8,     8,     8,     8,
       8,     8,   152,     8,     8,   -67,   -67,   152,   -67,   -67,
     -67,    78,    40,    68,   152,   -67,   -67,   111,    81,   -67,
     -67,    -7,   -67,   -67,   -67,   -67,   -67,    44,    46,   -67,
      38,   148,   148,   -67,   -67,    38,   -67,   -67,    48,   255,
     255,   -67,   -67,    86,   -19,   152,    51,    49,    68,    65,
     -67,   -67,   -67,   -67,   -67,   -67,   -67,   152,    71,   152,
     -67,    69,    89,   -67,   -67,   -67,    93,   -67,   -67,    60,
      70,   185,   -67,   -67,   152,   -67,   -67,   -67,   -67,   -67,
      73,   -67
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       2,    59,    64,    56,    56,     0,     0,    56,    56,     0,
      56,     0,    56,     0,     4,    58,     0,     3,     6,    56,
       0,     0,     0,    55,     0,     0,     0,     0,     0,    33,
       0,     0,     0,     0,    50,     0,     0,     0,     5,     1,
       7,    29,    30,    28,    31,     0,    56,    56,     0,    53,
       0,    56,     0,    78,    71,    68,    74,     0,     0,    70,
      69,    77,    73,    76,    67,    66,    79,    65,    15,    57,
      16,    56,    45,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     4,     0,     0,    56,    11,     4,    56,    24,
      17,    52,     0,    47,     4,    10,    32,     0,     0,    12,
      56,     0,    61,    60,    72,    75,    56,     0,     0,    46,
      35,    40,    41,    36,    37,    34,    38,    39,     0,    42,
      43,    44,     8,     0,    50,     4,     0,     0,    47,     0,
      56,    13,    54,    56,    56,    80,    25,     4,    20,     4,
      51,     0,     0,    19,    48,    22,     0,    63,    62,     0,
       0,     0,     9,    23,     4,    14,    26,    18,    21,    49,
       0,    27
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -67,   -67,   -66,    17,   -29,   -67,   -67,    33,    34,   -21,
     -67,    11,   -44,    -2,   -67,     0,   -67,   -67,   -67,   -67,
     -67
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,    16,    37,    38,    18,   149,   160,    47,    28,   127,
     128,    92,    48,    49,    23,    29,    20,    52,    21,    67,
     107
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_uint8 yytable[] =
{
      19,    22,    24,    89,    25,    30,    31,   102,    33,    32,
      35,    26,     1,     1,    19,    27,   118,    17,    19,    34,
      51,   122,     1,    69,    39,    68,    70,     1,   129,    74,
      75,    76,    19,    50,    71,    40,    91,   133,    77,    78,
      79,    80,    81,    87,    97,    98,    88,    36,    15,    15,
     101,    77,    78,    85,    80,    81,   132,    86,    15,   141,
      72,    73,    90,    15,    95,   100,    41,    42,    96,   108,
      93,   150,    43,   152,    99,    44,    82,    83,    84,   103,
     106,   104,    19,   121,    45,   105,   123,    19,   159,   124,
     148,   125,   126,   131,    19,   136,    46,   137,   139,   151,
     154,   134,   138,   143,   135,   155,   142,   144,   110,   111,
     112,   113,   114,   115,   116,   117,   156,   119,   120,   145,
      41,    42,   158,   153,   157,    19,    43,   161,   146,    44,
     130,   147,    74,    75,    76,   140,     0,    19,    45,    19,
       0,    77,    78,    79,    80,    81,    74,    75,    76,     0,
     109,    19,    74,     0,    19,    77,    78,    79,    80,    81,
       0,    77,    78,    79,    80,    81,     0,     0,     0,     0,
       0,     1,     0,     2,     0,     3,     0,     0,     4,    94,
      83,    84,     5,     6,     0,     0,     7,     8,     0,     0,
       0,     9,     0,     0,    83,    84,    10,    11,     0,    12,
       0,     0,    13,    14,     1,     0,     2,    15,     3,     0,
       0,     4,     0,     0,     0,     5,     6,     0,     0,     7,
       0,     0,     0,     0,     9,     0,     0,     0,     0,    10,
      11,     0,    12,     0,    53,    13,    14,     0,    54,     0,
      15,    55,     0,     0,     0,    56,    57,    58,     0,    59,
      60,    61,    62,     0,     0,    63,     0,    64,    65,    74,
      75,    76,     0,     0,    66,     0,     0,     0,    77,    78,
      79,    80,    81
};

static const yytype_int16 yycheck[] =
{
       0,     3,     4,    32,    55,     7,     8,    51,    10,     9,
      12,     3,    19,    19,    14,     7,    82,     0,    18,    55,
      20,    87,    19,    23,     0,    12,    12,    19,    94,     4,
       5,     6,    32,    39,    33,    18,    55,    44,    13,    14,
      15,    16,    17,    12,    46,    47,    15,    13,    55,    55,
      50,    13,    14,    33,    16,    17,   100,    12,    55,   125,
      26,    27,    12,    55,    54,    11,     9,    10,    15,    71,
      51,   137,    15,   139,    12,    18,    51,    52,    53,    20,
      22,    55,    82,    85,    27,    55,    88,    87,   154,    11,
     134,    51,    24,    12,    94,    51,    39,    51,    12,    28,
      11,   101,    54,    54,   106,    12,    55,   128,    74,    75,
      76,    77,    78,    79,    80,    81,    56,    83,    84,    54,
       9,    10,   151,    54,    54,   125,    15,    54,   130,    18,
      97,   133,     4,     5,     6,   124,    -1,   137,    27,   139,
      -1,    13,    14,    15,    16,    17,     4,     5,     6,    -1,
       8,   151,     4,    -1,   154,    13,    14,    15,    16,    17,
      -1,    13,    14,    15,    16,    17,    -1,    -1,    -1,    -1,
      -1,    19,    -1,    21,    -1,    23,    -1,    -1,    26,    51,
      52,    53,    30,    31,    -1,    -1,    34,    35,    -1,    -1,
      -1,    39,    -1,    -1,    52,    53,    44,    45,    -1,    47,
      -1,    -1,    50,    51,    19,    -1,    21,    55,    23,    -1,
      -1,    26,    -1,    -1,    -1,    30,    31,    -1,    -1,    34,
      -1,    -1,    -1,    -1,    39,    -1,    -1,    -1,    -1,    44,
      45,    -1,    47,    -1,    25,    50,    51,    -1,    29,    -1,
      55,    32,    -1,    -1,    -1,    36,    37,    38,    -1,    40,
      41,    42,    43,    -1,    -1,    46,    -1,    48,    49,     4,
       5,     6,    -1,    -1,    55,    -1,    -1,    -1,    13,    14,
      15,    16,    17
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    19,    21,    23,    26,    30,    31,    34,    35,    39,
      44,    45,    47,    50,    51,    55,    58,    60,    61,    72,
      73,    75,    70,    71,    70,    55,     3,     7,    65,    72,
      70,    70,    72,    70,    55,    70,    65,    59,    60,     0,
      60,     9,    10,    15,    18,    27,    39,    64,    69,    70,
      39,    72,    74,    25,    29,    32,    36,    37,    38,    40,
      41,    42,    43,    46,    48,    49,    55,    76,    12,    72,
      12,    33,    65,    65,     4,     5,     6,    13,    14,    15,
      16,    17,    51,    52,    53,    33,    12,    12,    15,    61,
      12,    55,    68,    51,    51,    54,    15,    70,    70,    12,
      11,    72,    69,    20,    55,    55,    22,    77,    70,     8,
      65,    65,    65,    65,    65,    65,    65,    65,    59,    65,
      65,    70,    59,    70,    11,    51,    24,    66,    67,    59,
      64,    12,    69,    44,    72,    70,    51,    51,    54,    12,
      68,    59,    55,    54,    66,    54,    70,    70,    69,    62,
      59,    28,    59,    54,    11,    12,    56,    54,    61,    59,
      63,    54
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    57,    58,    58,    59,    59,    60,    60,    60,    60,
      61,    61,    61,    61,    61,    61,    61,    61,    61,    61,
      61,    61,    61,    61,    61,    62,    63,    61,    64,    64,
      64,    64,    64,    65,    65,    65,    65,    65,    65,    65,
      65,    65,    65,    65,    65,    65,    65,    66,    66,    67,
      68,    68,    68,    69,    69,    70,    71,    71,    72,    73,
      72,    74,    74,    74,    75,    75,    76,    76,    76,    76,
      76,    76,    76,    76,    76,    76,    76,    76,    76,    77,
      77
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     0,     1,     0,     1,     1,     2,     4,     6,
       3,     3,     3,     4,     6,     3,     3,     3,     7,     5,
       5,     7,     5,     6,     3,     0,     0,     9,     1,     1,
       1,     1,     2,     1,     3,     3,     3,     3,     3,     3,
       3,     3,     3,     3,     3,     2,     3,     0,     2,     4,
       0,     3,     1,     1,     3,     1,     0,     2,     1,     0,
       4,     2,     4,     4,     0,     2,     1,     1,     1,     1,
       1,     1,     2,     1,     1,     2,     1,     1,     1,     0,
       2
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 3: /* run: rules  */
#line 137 "jamgram.y"
                { parse_save( yyvsp[0].parse ); }
#line 1459 "y.tab.c"
    break;

  case 4: /* block: %empty  */
#line 148 "jamgram.y"
                { yyval.parse = pnull(); }
#line 1465 "y.tab.c"
    break;

  case 5: /* block: rules  */
#line 150 "jamgram.y"
                { yyval.parse = yyvsp[0].parse; }
#line 1471 "y.tab.c"
    break;

  case 6: /* rules: rule  */
#line 154 "jamgram.y"
                { yyval.parse = yyvsp[0].parse; }
#line 1477 "y.tab.c"
    break;

  case 7: /* rules: rule rules  */
#line 156 "jamgram.y"
                { yyval.parse = prules( yyvsp[-1].parse, yyvsp[0].parse ); }
#line 1483 "y.tab.c"
    break;

  case 8: /* rules: LOCAL_t list _SEMIC_t block  */
#line 158 "jamgram.y"
                { yyval.parse = plocal( yyvsp[-2].parse, pnull(), yyvsp[0].parse ); }
#line 1489 "y.tab.c"
    break;

  case 9: /* rules: LOCAL_t list _EQUALS_t list _SEMIC_t block  */
#line 160 "jamgram.y"
                { yyval.parse = plocal( yyvsp[-4].parse, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1495 "y.tab.c"
    break;

  case 10: /* rule: _LBRACE_t block _RBRACE_t  */
#line 164 "jamgram.y"
                { yyval.parse = yyvsp[-1].parse; }
#line 1501 "y.tab.c"
    break;

  case 11: /* rule: INCLUDE_t list _SEMIC_t  */
#line 166 "jamgram.y"
                { yyval.parse = pincl( yyvsp[-1].parse ); }
#line 1507 "y.tab.c"
    break;

  case 12: /* rule: arg lol _SEMIC_t  */
#line 168 "jamgram.y"
                { yyval.parse = prule( yyvsp[-2].parse, yyvsp[-1].parse ); }
#line 1513 "y.tab.c"
    break;

  case 13: /* rule: arg assign list _SEMIC_t  */
#line 170 "jamgram.y"
                { yyval.parse = pset( yyvsp[-3].parse, yyvsp[-1].parse, yyvsp[-2].number ); }
#line 1519 "y.tab.c"
    break;

  case 14: /* rule: arg ON_t list assign list _SEMIC_t  */
#line 172 "jamgram.y"
                { yyval.parse = pset1( yyvsp[-5].parse, yyvsp[-3].parse, yyvsp[-1].parse, yyvsp[-2].number ); }
#line 1525 "y.tab.c"
    break;

  case 15: /* rule: BREAK_t list _SEMIC_t  */
#line 174 "jamgram.y"
                { yyval.parse = pbreak( yyvsp[-1].parse, JMP_BREAK ); }
#line 1531 "y.tab.c"
    break;

  case 16: /* rule: CONTINUE_t list _SEMIC_t  */
#line 176 "jamgram.y"
                { yyval.parse = pbreak( yyvsp[-1].parse, JMP_CONTINUE ); }
#line 1537 "y.tab.c"
    break;

  case 17: /* rule: RETURN_t list _SEMIC_t  */
#line 178 "jamgram.y"
                { yyval.parse = pbreak( yyvsp[-1].parse, JMP_RETURN ); }
#line 1543 "y.tab.c"
    break;

  case 18: /* rule: FOR_t ARG IN_t list _LBRACE_t block _RBRACE_t  */
#line 180 "jamgram.y"
                { yyval.parse = pfor( yyvsp[-5].string, yyvsp[-3].parse, yyvsp[-1].parse ); }
#line 1549 "y.tab.c"
    break;

  case 19: /* rule: SWITCH_t list _LBRACE_t cases _RBRACE_t  */
#line 182 "jamgram.y"
                { yyval.parse = pswitch( yyvsp[-3].parse, yyvsp[-1].parse ); }
#line 1555 "y.tab.c"
    break;

  case 20: /* rule: IF_t expr _LBRACE_t block _RBRACE_t  */
#line 184 "jamgram.y"
                { yyval.parse = pif( yyvsp[-3].parse, yyvsp[-1].parse, pnull() ); }
#line 1561 "y.tab.c"
    break;

  case 21: /* rule: IF_t expr _LBRACE_t block _RBRACE_t ELSE_t rule  */
#line 186 "jamgram.y"
                { yyval.parse = pif( yyvsp[-5].parse, yyvsp[-3].parse, yyvsp[0].parse ); }
#line 1567 "y.tab.c"
    break;

  case 22: /* rule: WHILE_t expr _LBRACE_t block _RBRACE_t  */
#line 188 "jamgram.y"
                { yyval.parse = pwhile( yyvsp[-3].parse, yyvsp[-1].parse ); }
#line 1573 "y.tab.c"
    break;

  case 23: /* rule: RULE_t ARG params _LBRACE_t block _RBRACE_t  */
#line 190 "jamgram.y"
                { yyval.parse = psetc( yyvsp[-4].string, yyvsp[-3].parse, yyvsp[-1].parse ); }
#line 1579 "y.tab.c"
    break;

  case 24: /* rule: ON_t arg rule  */
#line 192 "jamgram.y"
                { yyval.parse = pon( yyvsp[-1].parse, yyvsp[0].parse ); }
#line 1585 "y.tab.c"
    break;

  case 25: /* $@1: %empty  */
#line 194 "jamgram.y"
                { yymode( SCAN_STRING ); }
#line 1591 "y.tab.c"
    break;

  case 26: /* $@2: %empty  */
#line 196 "jamgram.y"
                { yymode( SCAN_NORMAL ); }
#line 1597 "y.tab.c"
    break;

  case 27: /* rule: ACTIONS_t eflags ARG bindlist _LBRACE_t $@1 STRING $@2 _RBRACE_t  */
#line 198 "jamgram.y"
                { yyval.parse = psete( yyvsp[-6].string,yyvsp[-5].parse,yyvsp[-2].string,yyvsp[-7].number,yyvsp[-7].number2,yyvsp[-7].number3 ); }
#line 1603 "y.tab.c"
    break;

  case 28: /* assign: _EQUALS_t  */
#line 206 "jamgram.y"
                { yyval.number = VAR_SET; }
#line 1609 "y.tab.c"
    break;

  case 29: /* assign: _PLUS_EQUALS_t  */
#line 208 "jamgram.y"
                { yyval.number = VAR_APPEND; }
#line 1615 "y.tab.c"
    break;

  case 30: /* assign: _MINUS_EQUALS_t  */
#line 210 "jamgram.y"
                { yyval.number = VAR_REMOVE; }
#line 1621 "y.tab.c"
    break;

  case 31: /* assign: _QUESTION_EQUALS_t  */
#line 212 "jamgram.y"
                { yyval.number = VAR_DEFAULT; }
#line 1627 "y.tab.c"
    break;

  case 32: /* assign: DEFAULT_t _EQUALS_t  */
#line 214 "jamgram.y"
                { yyval.number = VAR_DEFAULT; }
#line 1633 "y.tab.c"
    break;

  case 33: /* expr: arg  */
#line 222 "jamgram.y"
                { yyval.parse = peval( EXPR_EXISTS, yyvsp[0].parse, pnull() ); }
#line 1639 "y.tab.c"
    break;

  case 34: /* expr: expr _EQUALS_t expr  */
#line 224 "jamgram.y"
                { yyval.parse = peval( EXPR_EQUALS, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1645 "y.tab.c"
    break;

  case 35: /* expr: expr _BANG_EQUALS_t expr  */
#line 226 "jamgram.y"
                { yyval.parse = peval( EXPR_NOTEQ, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1651 "y.tab.c"
    break;

  case 36: /* expr: expr _LANGLE_t expr  */
#line 228 "jamgram.y"
                { yyval.parse = peval( EXPR_LESS, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1657 "y.tab.c"
    break;

  case 37: /* expr: expr _LANGLE_EQUALS_t expr  */
#line 230 "jamgram.y"
                { yyval.parse = peval( EXPR_LESSEQ, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1663 "y.tab.c"
    break;

  case 38: /* expr: expr _RANGLE_t expr  */
#line 232 "jamgram.y"
                { yyval.parse = peval( EXPR_MORE, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1669 "y.tab.c"
    break;

  case 39: /* expr: expr _RANGLE_EQUALS_t expr  */
#line 234 "jamgram.y"
                { yyval.parse = peval( EXPR_MOREEQ, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1675 "y.tab.c"
    break;

  case 40: /* expr: expr _AMPER_t expr  */
#line 236 "jamgram.y"
                { yyval.parse = peval( EXPR_AND, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1681 "y.tab.c"
    break;

  case 41: /* expr: expr _AMPERAMPER_t expr  */
#line 238 "jamgram.y"
                { yyval.parse = peval( EXPR_AND, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1687 "y.tab.c"
    break;

  case 42: /* expr: expr _BAR_t expr  */
#line 240 "jamgram.y"
                { yyval.parse = peval( EXPR_OR, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1693 "y.tab.c"
    break;

  case 43: /* expr: expr _BARBAR_t expr  */
#line 242 "jamgram.y"
                { yyval.parse = peval( EXPR_OR, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1699 "y.tab.c"
    break;

  case 44: /* expr: arg IN_t list  */
#line 244 "jamgram.y"
                { yyval.parse = peval( EXPR_IN, yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1705 "y.tab.c"
    break;

  case 45: /* expr: _BANG_t expr  */
#line 246 "jamgram.y"
                { yyval.parse = peval( EXPR_NOT, yyvsp[0].parse, pnull() ); }
#line 1711 "y.tab.c"
    break;

  case 46: /* expr: _LPAREN_t expr _RPAREN_t  */
#line 248 "jamgram.y"
                { yyval.parse = yyvsp[-1].parse; }
#line 1717 "y.tab.c"
    break;

  case 47: /* cases: %empty  */
#line 258 "jamgram.y"
                { yyval.parse = P0; }
#line 1723 "y.tab.c"
    break;

  case 48: /* cases: case cases  */
#line 260 "jamgram.y"
                { yyval.parse = pnode( yyvsp[-1].parse, yyvsp[0].parse ); }
#line 1729 "y.tab.c"
    break;

  case 49: /* case: CASE_t ARG _COLON_t block  */
#line 264 "jamgram.y"
                { yyval.parse = psnode( yyvsp[-2].string, yyvsp[0].parse ); }
#line 1735 "y.tab.c"
    break;

  case 50: /* params: %empty  */
#line 273 "jamgram.y"
                { yyval.parse = P0; }
#line 1741 "y.tab.c"
    break;

  case 51: /* params: ARG _COLON_t params  */
#line 275 "jamgram.y"
                { yyval.parse = psnode( yyvsp[-2].string, yyvsp[0].parse ); }
#line 1747 "y.tab.c"
    break;

  case 52: /* params: ARG  */
#line 277 "jamgram.y"
                { yyval.parse = psnode( yyvsp[0].string, P0 ); }
#line 1753 "y.tab.c"
    break;

  case 53: /* lol: list  */
#line 286 "jamgram.y"
                { yyval.parse = pnode( P0, yyvsp[0].parse ); }
#line 1759 "y.tab.c"
    break;

  case 54: /* lol: list _COLON_t lol  */
#line 288 "jamgram.y"
                { yyval.parse = pnode( yyvsp[0].parse, yyvsp[-2].parse ); }
#line 1765 "y.tab.c"
    break;

  case 55: /* list: listp  */
#line 298 "jamgram.y"
                { yyval.parse = yyvsp[0].parse; yymode( SCAN_NORMAL ); }
#line 1771 "y.tab.c"
    break;

  case 56: /* listp: %empty  */
#line 302 "jamgram.y"
                { yyval.parse = pnull(); yymode( SCAN_PUNCT ); }
#line 1777 "y.tab.c"
    break;

  case 57: /* listp: listp arg  */
#line 304 "jamgram.y"
                { yyval.parse = pappend( yyvsp[-1].parse, yyvsp[0].parse ); }
#line 1783 "y.tab.c"
    break;

  case 58: /* arg: ARG  */
#line 308 "jamgram.y"
                { yyval.parse = plist( yyvsp[0].string ); }
#line 1789 "y.tab.c"
    break;

  case 59: /* $@3: %empty  */
#line 309 "jamgram.y"
                      { yymode( SCAN_NORMAL ); }
#line 1795 "y.tab.c"
    break;

  case 60: /* arg: _LBRACKET_t $@3 func _RBRACKET_t  */
#line 310 "jamgram.y"
                { yyval.parse = yyvsp[-1].parse; }
#line 1801 "y.tab.c"
    break;

  case 61: /* func: arg lol  */
#line 319 "jamgram.y"
                { yyval.parse = prule( yyvsp[-1].parse, yyvsp[0].parse ); }
#line 1807 "y.tab.c"
    break;

  case 62: /* func: ON_t arg arg lol  */
#line 321 "jamgram.y"
                { yyval.parse = pon( yyvsp[-2].parse, prule( yyvsp[-1].parse, yyvsp[0].parse ) ); }
#line 1813 "y.tab.c"
    break;

  case 63: /* func: ON_t arg RETURN_t list  */
#line 323 "jamgram.y"
                { yyval.parse = pon( yyvsp[-2].parse, yyvsp[0].parse ); }
#line 1819 "y.tab.c"
    break;

  case 64: /* eflags: %empty  */
#line 332 "jamgram.y"
                { yyval.number = yyval.number2 = yyval.number3 = 0; }
#line 1825 "y.tab.c"
    break;

  case 65: /* eflags: eflags eflag  */
#line 334 "jamgram.y"
                { yyval.number = yyvsp[-1].number | yyvsp[0].number; if (yyvsp[0].number2 != 0) yyval.number2 = yyvsp[0].number2; if (yyvsp[0].number3 != 0) yyval.number3 = yyvsp[0].number3; }
#line 1831 "y.tab.c"
    break;

  case 66: /* eflag: UPDATED_t  */
#line 338 "jamgram.y"
                { yyval.number = RULE_UPDATED; }
#line 1837 "y.tab.c"
    break;

  case 67: /* eflag: TOGETHER_t  */
#line 340 "jamgram.y"
                { yyval.number = RULE_TOGETHER; }
#line 1843 "y.tab.c"
    break;

  case 68: /* eflag: IGNORE_t  */
#line 342 "jamgram.y"
                { yyval.number = RULE_IGNORE; }
#line 1849 "y.tab.c"
    break;

  case 69: /* eflag: QUIETLY_t  */
#line 344 "jamgram.y"
                { yyval.number = RULE_QUIETLY; }
#line 1855 "y.tab.c"
    break;

  case 70: /* eflag: PIECEMEAL_t  */
#line 346 "jamgram.y"
                { yyval.number = RULE_PIECEMEAL; }
#line 1861 "y.tab.c"
    break;

  case 71: /* eflag: EXISTING_t  */
#line 348 "jamgram.y"
                { yyval.number = RULE_EXISTING; }
#line 1867 "y.tab.c"
    break;

  case 72: /* eflag: MAXLINE_t ARG  */
#line 350 "jamgram.y"
                { yyval.number = RULE_MAXLINE;  yyval.number2 = atoi( yyvsp[0].string ); }
#line 1873 "y.tab.c"
    break;

  case 73: /* eflag: RESPONSE_t  */
#line 352 "jamgram.y"
                { yyval.number = RULE_RESPONSE; }
#line 1879 "y.tab.c"
    break;

  case 74: /* eflag: LUA_t  */
#line 354 "jamgram.y"
                { yyval.number = RULE_LUA; }
#line 1885 "y.tab.c"
    break;

  case 75: /* eflag: MAXTARGETS_t ARG  */
#line 356 "jamgram.y"
                { yyval.number = RULE_MAXTARGETS; yyval.number3 = atoi( yyvsp[0].string ); }
#line 1891 "y.tab.c"
    break;

  case 76: /* eflag: SCREENOUTPUT_t  */
#line 358 "jamgram.y"
                { yyval.number = RULE_SCREENOUTPUT; }
#line 1897 "y.tab.c"
    break;

  case 77: /* eflag: REMOVEEMPTYDIRS_t  */
#line 360 "jamgram.y"
                { yyval.number = RULE_REMOVEEMPTYDIRS; }
#line 1903 "y.tab.c"
    break;

  case 78: /* eflag: CLEANUNUSEDTARGETS_t  */
#line 362 "jamgram.y"
                { yyval.number = RULE_CLEANUNUSEDTARGETS; }
#line 1909 "y.tab.c"
    break;

  case 79: /* bindlist: %empty  */
#line 371 "jamgram.y"
                { yyval.parse = pnull(); }
#line 1915 "y.tab.c"
    break;

  case 80: /* bindlist: BIND_t list  */
#line 373 "jamgram.y"
                { yyval.parse = yyvsp[0].parse; }
#line 1921 "y.tab.c"
    break;


#line 1925 "y.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

