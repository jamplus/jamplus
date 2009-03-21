/* Keep JAMVERSYM in sync with VERSION. */
/* It can be accessed as $(JAMVERSION) in the Jamfile. */

#define JAM_VERSION "2.5"
#define JAMPLUS_VERSION "0.3"
#define JAMVERSYM "JAMVERSION=2.5"

#ifdef OPT_PATCHED_VERSION_VAR_EXT
#define PATCHED_VERSION_MAJOR "a"
#define PATCHED_VERSION_MINOR "u"
#endif

/* Update DPG_JAMVERSION's major number when you want the existing
 * Jamfiles to fail when people are using an old version of dpg jam.
 * */
#define DPG_JAMVERSION "DPG_JAMVERSION=1.5"

