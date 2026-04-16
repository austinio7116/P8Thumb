/*
** $Id: luaconf.h,v 1.176.1.2 2013/11/21 17:26:16 roberto Exp $
** Configuration file for Lua
** See Copyright Notice in lua.h
*/


#ifndef lconfig_h
#define lconfig_h

#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>


/*
** ==================================================================
** Search for "@@" to find all configurable definitions.
** ===================================================================
*/


/*
@@ LUA_ANSI controls the use of non-ansi features.
** CHANGE it (define it) if you want Lua to avoid the use of any
** non-ansi feature or library.
*/
#if !defined(LUA_ANSI) && defined(__STRICT_ANSI__)
#define LUA_ANSI
#endif


#if !defined(LUA_ANSI) && defined(_WIN32) && !defined(_WIN32_WCE)
#define LUA_WIN		/* enable goodies for regular Windows platforms */
#endif

#if defined(LUA_WIN)
#define LUA_DL_DLL
#define LUA_USE_AFORMAT		/* assume 'printf' handles 'aA' specifiers */
#endif



#if defined(LUA_USE_LINUX)
#define LUA_USE_POSIX
#define LUA_USE_DLOPEN		/* needs an extra library: -ldl */
#define LUA_USE_READLINE	/* needs some extra libraries */
#define LUA_USE_STRTODHEX	/* assume 'strtod' handles hex formats */
#define LUA_USE_AFORMAT		/* assume 'printf' handles 'aA' specifiers */
#define LUA_USE_LONGLONG	/* assume support for long long */
#endif

#if defined(LUA_USE_MACOSX)
#define LUA_USE_POSIX
#define LUA_USE_DLOPEN		/* does not need -ldl */
#define LUA_USE_READLINE	/* needs an extra library: -lreadline */
#define LUA_USE_STRTODHEX	/* assume 'strtod' handles hex formats */
#define LUA_USE_AFORMAT		/* assume 'printf' handles 'aA' specifiers */
#define LUA_USE_LONGLONG	/* assume support for long long */
#endif



/*
@@ LUA_USE_POSIX includes all functionality listed as X/Open System
@* Interfaces Extension (XSI).
** CHANGE it (define it) if your system is XSI compatible.
*/
#if defined(LUA_USE_POSIX)
#define LUA_USE_MKSTEMP
#define LUA_USE_ISATTY
#define LUA_USE_POPEN
#define LUA_USE_ULONGJMP
#define LUA_USE_GMTIME_R
#endif



/*
@@ LUA_PATH_DEFAULT is the default path that Lua uses to look for
@* Lua libraries.
@@ LUA_CPATH_DEFAULT is the default path that Lua uses to look for
@* C libraries.
** CHANGE them if your machine has a non-conventional directory
** hierarchy or if you want to install your libraries in
** non-conventional directories.
*/
#if defined(_WIN32)	/* { */
/*
** In Windows, any exclamation mark ('!') in the path is replaced by the
** path of the directory of the executable file of the current process.
*/
#define LUA_LDIR	"!\\lua\\"
#define LUA_CDIR	"!\\"
#define LUA_PATH_DEFAULT  \
		LUA_LDIR"?.lua;"  LUA_LDIR"?\\init.lua;" \
		LUA_CDIR"?.lua;"  LUA_CDIR"?\\init.lua;" ".\\?.lua"
#define LUA_CPATH_DEFAULT \
		LUA_CDIR"?.dll;" LUA_CDIR"loadall.dll;" ".\\?.dll"

#else			/* }{ */

#define LUA_VDIR	LUA_VERSION_MAJOR "." LUA_VERSION_MINOR "/"
#define LUA_ROOT	"/usr/local/"
#define LUA_LDIR	LUA_ROOT "share/lua/" LUA_VDIR
#define LUA_CDIR	LUA_ROOT "lib/lua/" LUA_VDIR
#define LUA_PATH_DEFAULT  \
		LUA_LDIR"?.lua;"  LUA_LDIR"?/init.lua;" \
		LUA_CDIR"?.lua;"  LUA_CDIR"?/init.lua;" "./?.lua"
#define LUA_CPATH_DEFAULT \
		LUA_CDIR"?.so;" LUA_CDIR"loadall.so;" "./?.so"
#endif			/* } */


/*
@@ LUA_DIRSEP is the directory separator (for submodules).
** CHANGE it if your machine does not use "/" as the directory separator
** and is not Windows. (On Windows Lua automatically uses "\".)
*/
#if defined(_WIN32)
#define LUA_DIRSEP	"\\"
#else
#define LUA_DIRSEP	"/"
#endif


/*
@@ LUA_ENV is the name of the variable that holds the current
@@ environment, used to access global names.
** CHANGE it if you do not like this name.
*/
#define LUA_ENV		"_ENV"


/*
@@ LUA_API is a mark for all core API functions.
@@ LUALIB_API is a mark for all auxiliary library functions.
@@ LUAMOD_API is a mark for all standard library opening functions.
** CHANGE them if you need to define those functions in some special way.
** For instance, if you want to create one Windows DLL with the core and
** the libraries, you may want to use the following definition (define
** LUA_BUILD_AS_DLL to get it).
*/
#if defined(LUA_BUILD_AS_DLL)	/* { */

#if defined(LUA_CORE) || defined(LUA_LIB)	/* { */
#define LUA_API __declspec(dllexport)
#else						/* }{ */
#define LUA_API __declspec(dllimport)
#endif						/* } */

#else				/* }{ */

#define LUA_API		extern

#endif				/* } */


/* more often than not the libs go together with the core */
#define LUALIB_API	LUA_API
#define LUAMOD_API	LUALIB_API


/*
@@ LUAI_FUNC is a mark for all extern functions that are not to be
@* exported to outside modules.
@@ LUAI_DDEF and LUAI_DDEC are marks for all extern (const) variables
@* that are not to be exported to outside modules (LUAI_DDEF for
@* definitions and LUAI_DDEC for declarations).
** CHANGE them if you need to mark them in some special way. Elf/gcc
** (versions 3.2 and later) mark them as "hidden" to optimize access
** when Lua is compiled as a shared library. Not all elf targets support
** this attribute. Unfortunately, gcc does not offer a way to check
** whether the target offers that support, and those without support
** give a warning about it. To avoid these warnings, change to the
** default definition.
*/
#if defined(__GNUC__) && ((__GNUC__*100 + __GNUC_MINOR__) >= 302) && \
    defined(__ELF__)		/* { */
#define LUAI_FUNC	__attribute__((visibility("hidden"))) extern
#define LUAI_DDEC	LUAI_FUNC
#define LUAI_DDEF	/* empty */

#else				/* }{ */
#define LUAI_FUNC	extern
#define LUAI_DDEC	extern
#define LUAI_DDEF	/* empty */
#endif				/* } */



/*
@@ LUA_QL describes how error messages quote program elements.
** CHANGE it if you want a different appearance.
*/
#define LUA_QL(x)	"'" x "'"
#define LUA_QS		LUA_QL("%s")


/*
@@ LUA_IDSIZE gives the maximum size for the description of the source
@* of a function in debug information.
** CHANGE it if you want a different size.
*/
#define LUA_IDSIZE	60


/*
@@ luai_writestring/luai_writeline define how 'print' prints its results.
** They are only used in libraries and the stand-alone program. (The #if
** avoids including 'stdio.h' everywhere.)
*/
#if defined(LUA_LIB) || defined(lua_c)
#include <stdio.h>
#define luai_writestring(s,l)	fwrite((s), sizeof(char), (l), stdout)
#define luai_writeline()	(luai_writestring("\n", 1), fflush(stdout))
#endif

/*
@@ luai_writestringerror defines how to print error messages.
** (A format string with one argument is enough for Lua...)
*/
#define luai_writestringerror(s,p) \
	(fprintf(stderr, (s), (p)), fflush(stderr))


/*
@@ LUAI_MAXSHORTLEN is the maximum length for short strings, that is,
** strings that are internalized. (Cannot be smaller than reserved words
** or tags for metamethods, as these strings must be internalized;
** #("function") = 8, #("__newindex") = 10.)
*/
#define LUAI_MAXSHORTLEN        40



/*
** {==================================================================
** Compatibility with previous versions
** ===================================================================
*/

/*
@@ LUA_COMPAT_ALL controls all compatibility options.
** You can define it to get all options, or change specific options
** to fit your specific needs.
*/
#if defined(LUA_COMPAT_ALL)	/* { */

/*
@@ LUA_COMPAT_UNPACK controls the presence of global 'unpack'.
** You can replace it with 'table.unpack'.
*/
#define LUA_COMPAT_UNPACK

/*
@@ LUA_COMPAT_LOADERS controls the presence of table 'package.loaders'.
** You can replace it with 'package.searchers'.
*/
#define LUA_COMPAT_LOADERS

/*
@@ macro 'lua_cpcall' emulates deprecated function lua_cpcall.
** You can call your C function directly (with light C functions).
*/
#define lua_cpcall(L,f,u)  \
	(lua_pushcfunction(L, (f)), \
	 lua_pushlightuserdata(L,(u)), \
	 lua_pcall(L,1,0,0))


/*
@@ LUA_COMPAT_LOG10 defines the function 'log10' in the math library.
** You can rewrite 'log10(x)' as 'log(x, 10)'.
*/
#define LUA_COMPAT_LOG10

/*
@@ LUA_COMPAT_LOADSTRING defines the function 'loadstring' in the base
** library. You can rewrite 'loadstring(s)' as 'load(s)'.
*/
#define LUA_COMPAT_LOADSTRING

/*
@@ LUA_COMPAT_MAXN defines the function 'maxn' in the table library.
*/
#define LUA_COMPAT_MAXN

/*
@@ The following macros supply trivial compatibility for some
** changes in the API. The macros themselves document how to
** change your code to avoid using them.
*/
#define lua_strlen(L,i)		lua_rawlen(L, (i))

#define lua_objlen(L,i)		lua_rawlen(L, (i))

#define lua_equal(L,idx1,idx2)		lua_compare(L,(idx1),(idx2),LUA_OPEQ)
#define lua_lessthan(L,idx1,idx2)	lua_compare(L,(idx1),(idx2),LUA_OPLT)

/*
@@ LUA_COMPAT_MODULE controls compatibility with previous
** module functions 'module' (Lua) and 'luaL_register' (C).
*/
#define LUA_COMPAT_MODULE

#endif				/* } */

/* }================================================================== */



/*
@@ LUAI_BITSINT defines the number of bits in an int.
** CHANGE here if Lua cannot automatically detect the number of bits of
** your machine. Probably you do not need to change this.
*/
/* avoid overflows in comparison */
#if INT_MAX-20 < 32760		/* { */
#define LUAI_BITSINT	16
#elif INT_MAX > 2147483640L	/* }{ */
/* int has at least 32 bits */
#define LUAI_BITSINT	32
#else				/* }{ */
#error "you must define LUA_BITSINT with number of bits in an integer"
#endif				/* } */


/*
@@ LUA_INT32 is a signed integer with exactly 32 bits.
@@ LUAI_UMEM is an unsigned integer big enough to count the total
@* memory used by Lua.
@@ LUAI_MEM is a signed integer big enough to count the total memory
@* used by Lua.
** CHANGE here if for some weird reason the default definitions are not
** good enough for your machine. Probably you do not need to change
** this.
*/
#if LUAI_BITSINT >= 32		/* { */
#define LUA_INT32	int
#define LUAI_UMEM	size_t
#define LUAI_MEM	ptrdiff_t
#else				/* }{ */
/* 16-bit ints */
#define LUA_INT32	long
#define LUAI_UMEM	unsigned long
#define LUAI_MEM	long
#endif				/* } */


/*
@@ LUAI_MAXSTACK limits the size of the Lua stack.
** CHANGE it if you need a different limit. This limit is arbitrary;
** its only purpose is to stop Lua from consuming unlimited stack
** space (and to reserve some numbers for pseudo-indices).
*/
#if LUAI_BITSINT >= 32
#define LUAI_MAXSTACK		1000000
#else
#define LUAI_MAXSTACK		15000
#endif

/* reserve some space for error handling */
#define LUAI_FIRSTPSEUDOIDX	(-LUAI_MAXSTACK - 1000)




/*
@@ LUAL_BUFFERSIZE is the buffer size used by the lauxlib buffer system.
** CHANGE it if it uses too much C-stack space.
*/
#define LUAL_BUFFERSIZE		BUFSIZ




/*
** {==================================================================
@@ LUA_NUMBER is the type of numbers in Lua.
** CHANGE the following definitions only if you want to build Lua
** with a number type different from double. You may also need to
** change lua_number2int & lua_number2integer.
** ===================================================================
*/

/* ThumbyP8: 32-bit signed fixed-point 16.16 — matches PICO-8's numeric
 * model exactly. Bit patterns are preserved through bitwise ops (so
 * 32-bit bitmask tricks like POOM's work), arithmetic wraps on overflow
 * like two's-complement integers, and float conversion only happens at
 * the libm / native-API boundary. Range: [-32768, 32767.99998]; step
 * 1/65536 ≈ 1.5e-5. */
#include <stdint.h>
#define LUA_NUMBER	int32_t
#define LUA_NUMBER_FIXED	1

/* Fixed-point constants */
#define P8_FIX_ONE        0x00010000
#define P8_FIX_SHIFT      16
#define P8_FIX_FRAC_MASK  0x0000ffff

/* Conversions between fixed-point and native C numeric types */
#define p8_fix_from_int(n)    ((int32_t)((int32_t)(n) << P8_FIX_SHIFT))
#define p8_fix_to_int(x)      ((int)((int32_t)(x) >> P8_FIX_SHIFT))
#define p8_fix_from_float(f)  ((int32_t)((f) * 65536.0f))
#define p8_fix_to_float(x)    ((float)(x) / 65536.0f)
#define p8_fix_from_double(d) ((int32_t)((d) * 65536.0))
#define p8_fix_to_double(x)   ((double)(x) / 65536.0)

/* Fixed-point arithmetic. Defined inline so the compiler can fold
 * constant expressions at compile time. */
static inline int32_t p8_fix_mul(int32_t a, int32_t b) {
    return (int32_t)(((int64_t)a * (int64_t)b) >> P8_FIX_SHIFT);
}
static inline int32_t p8_fix_div(int32_t a, int32_t b) {
    if (b == 0) {
        if (a == 0) return 0;
        return (a < 0) ? (int32_t)0x80000000 : (int32_t)0x7fffffff;
    }
    return (int32_t)(((int64_t)a << P8_FIX_SHIFT) / b);
}
/* Floor toward negative infinity (PICO-8 flr semantics). */
static inline int32_t p8_fix_floor(int32_t a) {
    return (int32_t)((a >> P8_FIX_SHIFT) << P8_FIX_SHIFT);
}
/* Lua-style mod: a - floor(a/b)*b. Sign follows divisor. */
static inline int32_t p8_fix_mod(int32_t a, int32_t b) {
    if (b == 0) return 0;
    int32_t q_fix   = p8_fix_div(a, b);
    int32_t flr_fix = p8_fix_floor(q_fix);
    return (int32_t)((uint32_t)a - (uint32_t)p8_fix_mul(flr_fix, b));
}
static inline int32_t p8_fix_pow(int32_t a, int32_t b) {
    double da = (double)a / 65536.0;
    double db = (double)b / 65536.0;
    double r  = pow(da, db) * 65536.0;
    if (r >= 2147483647.0) return (int32_t)0x7fffffff;
    if (r <= -2147483648.0) return (int32_t)0x80000000;
    return (int32_t)r;
}

/*
@@ LUAI_UACNUMBER is the result of an 'usual argument conversion'
** over a number — int32_t passes unchanged through varargs.
*/
#define LUAI_UACNUMBER	int32_t


/*
@@ LUA_NUMBER_SCAN is the format for reading numbers.
@@ LUA_NUMBER_FMT is the format for writing numbers.
@@ lua_number2str converts a number to a string.
@@ LUAI_MAXNUMBER2STR is maximum size of previous conversion.
*/
/* SCAN/FMT are legacy; we always go through lua_number2str /
 * lua_str2number helpers, which handle the fixed-point pairing. */
#define LUA_NUMBER_SCAN		"%d"
#define LUA_NUMBER_FMT		"%d"
#define LUAI_MAXNUMBER2STR	32

/* Format a fixed-point number as a decimal string. Whole numbers
 * print without a decimal ("47" not "47.0"). Fractional numbers get
 * up to 4 decimal digits with trailing zeros trimmed. Matches PICO-8's
 * tostr(). */
static inline int lua_number2str(char *s, int32_t n) {
    if ((n & P8_FIX_FRAC_MASK) == 0) {
        return sprintf(s, "%d", (int)(n >> P8_FIX_SHIFT));
    }
    int neg = (n < 0);
    /* Use absolute value; handle INT32_MIN by unsigned arithmetic */
    uint32_t un = neg ? (uint32_t)(-n) : (uint32_t)n;
    uint32_t ip = un >> P8_FIX_SHIFT;
    uint32_t fp = un & P8_FIX_FRAC_MASK;
    /* Scale fractional part to 4 decimal digits: f * 10000 / 65536,
     * rounded. Use 64-bit intermediate to avoid overflow. */
    uint32_t frac = (uint32_t)(((uint64_t)fp * 10000u + 32768u) >> P8_FIX_SHIFT);
    /* Carry if rounding pushed frac to 10000 */
    if (frac >= 10000u) { frac = 0; ip++; }
    int len;
    if (frac == 0) {
        len = sprintf(s, "%s%u", neg ? "-" : "", (unsigned)ip);
    } else {
        len = sprintf(s, "%s%u.%04u", neg ? "-" : "",
                      (unsigned)ip, (unsigned)frac);
        /* Trim trailing zeros on the fractional portion */
        while (len > 0 && s[len-1] == '0') len--;
        if (len > 0 && s[len-1] == '.') len--;
        s[len] = '\0';
    }
    return len;
}


/*
@@ l_mathop is a no-op for fixed-point — only used by luai_nummod
** and luai_numpow below, which we redefine directly. Kept as an
** identity macro in case llimits.h references it.
*/
#define l_mathop(op)		op


/*
@@ lua_str2number converts a decimal numeric string to a fixed-point
** number. Uses strtod internally to handle hex float literals
** ("0x1.8p0"), decimal fractions, and scientific notation uniformly,
** then scales by 65536 and wraps on overflow — matching PICO-8's
** two's-complement behaviour so hex literals like 0xbe74 (which in
** 16.16 produce the 32-bit pattern 0xbe740000, a negative int32) keep
** the correct bit pattern for use as an address or bitmask.
*/
static inline int32_t p8_str2fix(const char *s, char **endp) {
    double d = strtod(s, endp);
    double scaled = d * 65536.0;
    /* Reduce to a 64-bit integer first (well-defined for finite doubles
     * in range), then mask to 32 bits — that gives modular wrap. */
    int64_t i64 = (int64_t)scaled;
    return (int32_t)((uint64_t)i64 & 0xffffffffu);
}
#define lua_str2number(s,p)	p8_str2fix((s), (p))
/* C99 strtod already handles "0x1.8p0"-style hex floats, so route
 * hex literals through the same helper to keep one parser. */
#define lua_strx2number(s,p)	p8_str2fix((s), (p))


/*
@@ The luai_num* macros define the primitive operations over numbers.
** Fixed-point: integer add/sub wrap on overflow; mul/div go through
** int64; mod is Lua-style floor-mod; pow goes through double.
*/

#if defined(lobject_c) || defined(lvm_c)
#include <math.h>
#define luai_nummod(L,a,b)	(p8_fix_mod((a), (b)))
#define luai_numpow(L,a,b)	(p8_fix_pow((a), (b)))
#endif

#if defined(LUA_CORE)
#define luai_numadd(L,a,b)	((int32_t)((uint32_t)(a) + (uint32_t)(b)))
#define luai_numsub(L,a,b)	((int32_t)((uint32_t)(a) - (uint32_t)(b)))
#define luai_nummul(L,a,b)	(p8_fix_mul((a), (b)))
#define luai_numdiv(L,a,b)	(p8_fix_div((a), (b)))
#define luai_numunm(L,a)	((int32_t)(-(uint32_t)(a)))
#define luai_numeq(a,b)		((a)==(b))
#define luai_numlt(L,a,b)	((a)<(b))
#define luai_numle(L,a,b)	((a)<=(b))
#define luai_numisnan(L,a)	(0)  /* fixed-point has no NaN */
#endif



/*
@@ LUA_INTEGER is the integral type used by lua_pushinteger/lua_tointeger.
** CHANGE that if ptrdiff_t is not adequate on your machine. (On most
** machines, ptrdiff_t gives a good choice between int or long.)
*/
#define LUA_INTEGER	ptrdiff_t

/*
@@ LUA_UNSIGNED is the integral type used by lua_pushunsigned/lua_tounsigned.
** It must have at least 32 bits.
*/
#define LUA_UNSIGNED	unsigned LUA_INT32



/*
** Some tricks with doubles
** ThumbyP8: disabled — we use float, not double.
*/

#if 0 && defined(LUA_NUMBER_DOUBLE) && !defined(LUA_ANSI)	/* { */
/*
** The next definitions activate some tricks to speed up the
** conversion from doubles to integer types, mainly to LUA_UNSIGNED.
**
@@ LUA_MSASMTRICK uses Microsoft assembler to avoid clashes with a
** DirectX idiosyncrasy.
**
@@ LUA_IEEE754TRICK uses a trick that should work on any machine
** using IEEE754 with a 32-bit integer type.
**
@@ LUA_IEEELL extends the trick to LUA_INTEGER; should only be
** defined when LUA_INTEGER is a 32-bit integer.
**
@@ LUA_IEEEENDIAN is the endianness of doubles in your machine
** (0 for little endian, 1 for big endian); if not defined, Lua will
** check it dynamically for LUA_IEEE754TRICK (but not for LUA_NANTRICK).
**
@@ LUA_NANTRICK controls the use of a trick to pack all types into
** a single double value, using NaN values to represent non-number
** values. The trick only works on 32-bit machines (ints and pointers
** are 32-bit values) with numbers represented as IEEE 754-2008 doubles
** with conventional endianess (12345678 or 87654321), in CPUs that do
** not produce signaling NaN values (all NaNs are quiet).
*/

/* Microsoft compiler on a Pentium (32 bit) ? */
#if defined(LUA_WIN) && defined(_MSC_VER) && defined(_M_IX86)	/* { */

#define LUA_MSASMTRICK
#define LUA_IEEEENDIAN		0
#define LUA_NANTRICK


/* pentium 32 bits? */
#elif defined(__i386__) || defined(__i386) || defined(__X86__) /* }{ */

#define LUA_IEEE754TRICK
#define LUA_IEEELL
#define LUA_IEEEENDIAN		0
#define LUA_NANTRICK

/* pentium 64 bits? */
#elif defined(__x86_64)						/* }{ */

#define LUA_IEEE754TRICK
#define LUA_IEEEENDIAN		0

#elif defined(__POWERPC__) || defined(__ppc__)			/* }{ */

#define LUA_IEEE754TRICK
#define LUA_IEEEENDIAN		1

#else								/* }{ */

/* ThumbyP8: do NOT use IEEE754TRICK — it assumes lua_Number is double
 * and uses a 64-bit double union for int conversion. With float as
 * lua_Number, the trick produces wrong results. Use the simple cast
 * fallback in llimits.h instead. */
/* #define LUA_IEEE754TRICK */

#endif								/* } */

#endif							/* } */

/* }================================================================== */




/* =================================================================== */

/*
** Local configuration. You can use this space to add your redefinitions
** without modifying the main part of the file.
*/



#endif

