#include "jam.h"
#include "buffer.h"
#include <stdarg.h>
#include <assert.h>
#include <stddef.h>

/* macro to `unsign' a character */
#define uchar(c)        ((unsigned char)(c))

/*
@@ JMAXCAPTURES is the maximum number of captures that a pattern
@* can do during pattern-matching.
** CHANGE it if you need more captures. This limit is arbitrary.
*/
#define JMAXCAPTURES		32

/*
@@ J_QL describes how error messages quote program elements.
** CHANGE it if you want a different appearance.
*/
#define J_QL(x)	"'" x "'"

/*
** {======================================================
** PATTERN MATCHING
** =======================================================
*/


#define JCAP_UNFINISHED	(-1)
#define JCAP_POSITION	(-2)

typedef struct JMatchState {
  const char *src_init;  /* init of source string */
  const char *src_end;  /* end (`\0') of source string */
  int level;  /* total number of captures (finished or unfinished) */
  struct {
    const char *init;
    ptrdiff_t len;
  } capture[JMAXCAPTURES];
  BUFFER* buff;
} JMatchState;


#define L_ESC		'%'
#define SPECIALS	"^$*+?.([%-"


static int j_gsub_error (const char *fmt) {
  printf("%s\n", fmt);
  exit(1);
  return 0;
}

static int j_check_capture (JMatchState *ms, int l) {
  l -= '1';
  if (l < 0 || l >= ms->level || ms->capture[l].len == JCAP_UNFINISHED)
    return j_gsub_error("invalid capture index");
  return l;
}


static int j_capture_to_close (JMatchState *ms) {
  int level = ms->level;
  for (level--; level>=0; level--)
    if (ms->capture[level].len == JCAP_UNFINISHED) return level;
  return j_gsub_error("invalid pattern capture");
}


static const char *j_classend (JMatchState *ms, const char *p) {
  switch (*p++) {
    case L_ESC: {
      if (*p == '\0')
        j_gsub_error("malformed pattern (ends with " J_QL("%%") ")");
      return p+1;
    }
    case '[': {
      if (*p == '^') p++;
      do {  /* look for a `]' */
        if (*p == '\0')
          j_gsub_error("malformed pattern (missing " J_QL("]") ")");
        if (*(p++) == L_ESC && *p != '\0')
          p++;  /* skip escapes (e.g. `%]') */
      } while (*p != ']');
      return p+1;
    }
    default: {
      return p;
    }
  }
}


static int j_match_class (int c, int cl) {
  int res;
  switch (tolower(cl)) {
    case 'a' : res = isalpha(c); break;
    case 'c' : res = iscntrl(c); break;
    case 'd' : res = isdigit(c); break;
    case 'l' : res = islower(c); break;
    case 'p' : res = ispunct(c); break;
    case 's' : res = isspace(c); break;
    case 'u' : res = isupper(c); break;
    case 'w' : res = isalnum(c); break;
    case 'x' : res = isxdigit(c); break;
    case 'z' : res = (c == 0); break;
    default: return (cl == c);
  }
  return (islower(cl) ? res : !res);
}


static int j_matchbracketclass (int c, const char *p, const char *ec) {
  int sig = 1;
  if (*(p+1) == '^') {
    sig = 0;
    p++;  /* skip the `^' */
  }
  while (++p < ec) {
    if (*p == L_ESC) {
      p++;
      if (j_match_class(c, uchar(*p)))
        return sig;
    }
    else if ((*(p+1) == '-') && (p+2 < ec)) {
      p+=2;
      if (uchar(*(p-2)) <= c && c <= uchar(*p))
        return sig;
    }
    else if (uchar(*p) == c) return sig;
  }
  return !sig;
}


static int j_singlematch (int c, const char *p, const char *ep) {
  switch (*p) {
    case '.': return 1;  /* matches any char */
    case L_ESC: return j_match_class(c, uchar(*(p+1)));
    case '[': return j_matchbracketclass(c, p, ep-1);
    default:  return (uchar(*p) == c);
  }
}


static const char *j_match (JMatchState *ms, const char *s, const char *p);


static const char *j_matchbalance (JMatchState *ms, const char *s,
                                   const char *p) {
  if (*p == 0 || *(p+1) == 0)
    j_gsub_error("unbalanced pattern");
  if (*s != *p) return NULL;
  else {
    int b = *p;
    int e = *(p+1);
    int cont = 1;
    while (++s < ms->src_end) {
      if (*s == e) {
        if (--cont == 0) return s+1;
      }
      else if (*s == b) cont++;
    }
  }
  return NULL;  /* string ends out of balance */
}


static const char *j_max_expand (JMatchState *ms, const char *s,
                                 const char *p, const char *ep) {
  ptrdiff_t i = 0;  /* counts maximum expand for item */
  while ((s+i)<ms->src_end && j_singlematch(uchar(*(s+i)), p, ep))
    i++;
  /* keeps trying to j_match with the maximum repetitions */
  while (i>=0) {
    const char *res = j_match(ms, (s+i), ep+1);
    if (res) return res;
    i--;  /* else didn't j_match; reduce 1 repetition to try again */
  }
  return NULL;
}


static const char *j_min_expand (JMatchState *ms, const char *s,
                                 const char *p, const char *ep) {
  for (;;) {
    const char *res = j_match(ms, s, ep+1);
    if (res != NULL)
      return res;
    else if (s<ms->src_end && j_singlematch(uchar(*s), p, ep))
      s++;  /* try with one more repetition */
    else return NULL;
  }
}


static const char *j_start_capture (JMatchState *ms, const char *s,
                                    const char *p, int what) {
  const char *res;
  int level = ms->level;
  if (level >= JMAXCAPTURES) j_gsub_error("too many captures");
  ms->capture[level].init = s;
  ms->capture[level].len = what;
  ms->level = level+1;
  if ((res=j_match(ms, s, p)) == NULL)  /* j_match failed? */
    ms->level--;  /* undo capture */
  return res;
}


static const char *j_end_capture (JMatchState *ms, const char *s,
                                  const char *p) {
  int l = j_capture_to_close(ms);
  const char *res;
  ms->capture[l].len = s - ms->capture[l].init;  /* close capture */
  if ((res = j_match(ms, s, p)) == NULL)  /* j_match failed? */
    ms->capture[l].len = JCAP_UNFINISHED;  /* undo capture */
  return res;
}


static const char *j_match_capture (JMatchState *ms, const char *s, int l) {
  size_t len;
  l = j_check_capture(ms, l);
  len = ms->capture[l].len;
  if ((size_t)(ms->src_end-s) >= len &&
      memcmp(ms->capture[l].init, s, len) == 0)
    return s+len;
  else return NULL;
}


static const char *j_match (JMatchState *ms, const char *s, const char *p) {
  init: /* using goto's to optimize tail recursion */
  switch (*p) {
    case '(': {  /* start capture */
      if (*(p+1) == ')')  /* position capture? */
        return j_start_capture(ms, s, p+2, JCAP_POSITION);
      else
        return j_start_capture(ms, s, p+1, JCAP_UNFINISHED);
    }
    case ')': {  /* end capture */
      return j_end_capture(ms, s, p+1);
    }
    case L_ESC: {
      switch (*(p+1)) {
        case 'b': {  /* balanced string? */
          s = j_matchbalance(ms, s, p+2);
          if (s == NULL) return NULL;
          p+=4; goto init;  /* else return j_match(ms, s, p+4); */
        }
        case 'f': {  /* frontier? */
          const char *ep; char previous;
          p += 2;
          if (*p != '[')
            j_gsub_error("missing " J_QL("[") " after "
                               J_QL("%%f") " in pattern");
          ep = j_classend(ms, p);  /* points to what is next */
          previous = (s == ms->src_init) ? '\0' : *(s-1);
          if (j_matchbracketclass(uchar(previous), p, ep-1) ||
             !j_matchbracketclass(uchar(*s), p, ep-1)) return NULL;
          p=ep; goto init;  /* else return j_match(ms, s, ep); */
        }
        default: {
          if (isdigit(uchar(*(p+1)))) {  /* capture results (%0-%9)? */
            s = j_match_capture(ms, s, uchar(*(p+1)));
            if (s == NULL) return NULL;
            p+=2; goto init;  /* else return j_match(ms, s, p+2) */
          }
          goto dflt;  /* case default */
        }
      }
    }
    case '\0': {  /* end of pattern */
      return s;  /* j_match succeeded */
    }
    case '$': {
      if (*(p+1) == '\0')  /* is the `$' the last char in pattern? */
        return (s == ms->src_end) ? s : NULL;  /* check end of string */
      else goto dflt;
    }
    default: dflt: {  /* it is a pattern item */
      const char *ep = j_classend(ms, p);  /* points to what is next */
      int m = s<ms->src_end && j_singlematch(uchar(*s), p, ep);
      switch (*ep) {
        case '?': {  /* optional */
          const char *res;
          if (m && ((res=j_match(ms, s+1, ep+1)) != NULL))
            return res;
          p=ep+1; goto init;  /* else return j_match(ms, s, ep+1); */
        }
        case '*': {  /* 0 or more repetitions */
          return j_max_expand(ms, s, p, ep);
        }
        case '+': {  /* 1 or more repetitions */
          return (m ? j_max_expand(ms, s+1, p, ep) : NULL);
        }
        case '-': {  /* 0 or more repetitions (minimum) */
          return j_min_expand(ms, s, p, ep);
        }
        default: {
          if (!m) return NULL;
          s++; p=ep; goto init;  /* else return j_match(ms, s+1, ep); */
        }
      }
    }
  }
}



static const char *j_lmemfind (const char *s1, size_t l1,
                               const char *s2, size_t l2) {
  if (l2 == 0) return s1;  /* empty strings are everywhere */
  else if (l2 > l1) return NULL;  /* avoids a negative `l1' */
  else {
    const char *init;  /* to search for a `*s2' inside `s1' */
    l2--;  /* 1st char will be checked by `memchr' */
    l1 = l1-l2;  /* `s2' cannot be found after that */
    while (l1 > 0 && (init = (const char *)memchr(s1, *s2, l1)) != NULL) {
      init++;   /* 1st char is already checked */
      if (memcmp(init, s2+1, l2) == 0)
        return init-1;
      else {  /* correct `l1' and `s1' to try again */
        l1 -= init-s1;
        s1 = init;
      }
    }
    return NULL;  /* not found */
  }
}


static void j_push_onecapture (JMatchState *ms, int i, const char *s,
                                                    const char *e) {
  if (i >= ms->level) {
	if (i == 0) { /* ms->level == 0, too */
      buffer_addstring(ms->buff, s, e - s);  /* add whole j_match */
	} else
      j_gsub_error("invalid capture index");
  }
  else {
    ptrdiff_t l = ms->capture[i].len;
    if (l == JCAP_UNFINISHED) j_gsub_error("unfinished capture");
	if (l == JCAP_POSITION) {
      // lua_pushinteger(ms->L, ms->capture[i].init - ms->src_init + 1);
	  assert(0);
	} else
      buffer_addstring(ms->buff, ms->capture[i].init, l);
  }
}


static int j_push_captures (JMatchState *ms, const char *s, const char *e) {
  int i;
  int nlevels = (ms->level == 0 && s) ? 1 : ms->level;
//  luaL_checkstack(ms->L, nlevels, "too many captures");
  for (i = 0; i < nlevels; i++)
    j_push_onecapture(ms, i, s, e);
  return nlevels;  /* number of strings pushed */
}


static void j_add_s (JMatchState *ms, const char *s, const char *e, const char *news, size_t l) {
  size_t i;
  for (i = 0; i < l; i++) {
	if (news[i] != L_ESC) {
	  buffer_addchar(ms->buff, news[i]);
	} else {
      i++;  /* skip ESC */
	  if (!isdigit(uchar(news[i]))) {
        buffer_addchar(ms->buff, news[i]);
	  } else if (news[i] == '0') {
        buffer_addstring(ms->buff, s, e - s);
	  } else {
        j_push_onecapture(ms, news[i] - '1', s, e);
//        luaL_addvalue(b);  /* add capture to accumulated result */
      }
    }
  }
}


int j_str_gsub (BUFFER *buff, const char *src, const char *p, const char *repl, int max_s) {
  int anchor;
  int n = 0;
  JMatchState ms;
  size_t srcl = strlen(src);
  if (max_s == -1)
	max_s = (int)(srcl + 1);
  anchor = (*p == '^') ? (p++, 1) : 0;
  n = 0;
  ms.buff = buff;
  ms.src_init = src;
  ms.src_end = src+srcl;
  while (n < max_s) {
    const char *e;
    ms.level = 0;
    e = j_match(&ms, src, p);
    if (e) {
      n++;
      j_add_s(&ms, src, e, repl, strlen(repl));
    }
    if (e && e>src) /* non empty j_match? */
      src = e;  /* skip it */
	else if (src < ms.src_end) {
      buffer_addchar(ms.buff, *src++);
	} else break;
    if (anchor) break;
  }
  buffer_addstring(ms.buff, src, ms.src_end-src);
  buffer_addchar(ms.buff, 0);
  return n;
}
