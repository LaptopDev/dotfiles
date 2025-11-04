/* See LICENSE file for copyright and license details. */
// Make linux keys recognized in keybindings
#include <X11/XF86keysym.h>
/* appearance */
static const unsigned int borderpx  = 1;        /* border pixel of windows */
static const unsigned int snap      = 32;       /* snap pixel */
static const int showbar            = 1;        /* 0 means no bar */
static const int topbar             = 1;        /* 0 means bottom bar */
static const char *fonts[]          = { "monospace:size=10" };
static const char dmenufont[]       = "monospace:size=10";
static const char col_gray1[]       = "#222222";
static const char col_gray2[]       = "#444444";
static const char col_gray3[]       = "#bbbbbb";
static const char col_gray4[]       = "#eeeeee";
static const char col_cyan[]        = "#005577";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_gray3, col_gray1, col_gray2 },
	[SchemeSel]  = { col_gray4, col_cyan,  col_cyan  },
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 */
	/* class      instance    title       tags mask     isfloating   monitor */
	{ "Gimp",     NULL,       NULL,       0,            1,           -1 },
	{ "Firefox",  NULL,       NULL,       1 << 8,       0,           -1 },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 1;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
};

/* key definitions */
#define MODKEY Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

    /* spawn()'s shell wrapper used in keys[] */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *termcmd[]  = { "kitty", NULL };

static const Key keys[] = {
	/* modifier                     key        function        argument */
    // my bindings:
    // window/compositor-level bindings
    { Mod4Mask,                     XK_d,      spawn,  SHCMD("/home/user/system-scripts/dwm/toggle-dark.sh") },
    { Mod4Mask,                       XK_n,       spawn,         SHCMD("kill -s USR1 $(pidof deadd-notification-center)") },
    { 0,                       XK_Print,       spawn,         SHCMD("flameshot gui") },
    /* decrease brightness */
    { Mod4Mask|ShiftMask, XK_b, spawn, SHCMD("v=$(ddcutil --display 1 getvcp 10 2>/dev/null | awk 'match($0,/current value[^0-9]*([0-9]+)/,a){print a[1];exit}'); n=$((v-10)); [ \"$n\" -lt 0 ] && n=0; ddcutil --display 1 setvcp 10 -- $n") },
    /* increase brightness */
    { Mod4Mask,           XK_b, spawn, SHCMD("v=$(ddcutil --display 1 getvcp 10 2>/dev/null | awk 'match($0,/current value[^0-9]*([0-9]+)/,a){print a[1];exit}'); n=$((v+10)); [ \"$n\" -gt 100 ] && n=100; ddcutil --display 1 setvcp 10 -- $n") },

    // fn+Delete on perrix keyboard enables function lock to use these keys easier:
    /* screenshot */
    { 0, XK_Print, spawn, SHCMD("flameshot gui") },
    /* volume */
    { 0, XF86XK_AudioRaiseVolume, spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%") },
    { 0, XF86XK_AudioLowerVolume, spawn, SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%") },
    { 0, XF86XK_AudioMute,        spawn, SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle") },
    /* media (requires playerctl + MPRIS support) */
    { 0, XF86XK_AudioPlay,        spawn, SHCMD("playerctl play-pause") },
    { 0, XF86XK_AudioNext,        spawn, SHCMD("playerctl next") },
    { 0, XF86XK_AudioPrev,        spawn, SHCMD("playerctl previous") },

    /* transcription */
    { MODKEY|ControlMask, XK_r, spawn, SHCMD("/home/user/system-scripts/transcribeee.sh me") },
    { MODKEY|ControlMask, XK_d, spawn, SHCMD("/home/user/system-scripts/transcribeee.sh dt") },
    { MODKEY|ControlMask, XK_e, spawn, SHCMD("/home/user/system-scripts/stop-dictations.sh") },
    // Replace clipboard image with OCR
    { MODKEY|ControlMask, XK_i, spawn, SHCMD("/home/user/system-scripts/ocr_clipboard_image.sh") },
    /* text to speech with pipx piper */
    { MODKEY|ControlMask,           XK_s,       spawn,         SHCMD("xsel -bo | /home/user/.local/bin/piper --model /home/user/Downloads/en_US-lessac-medium.onnx --config /home/user/Downloads/en_US-lessac-medium.onnx.json --output_raw | sox -t raw -r 22050 -e signed -b 16 -c 1 - -t raw - gain -3 pitch -300 | aplay -r 22050 -f S16_LE -t raw -") },

	{ MODKEY,                       XK_p,      spawn,          {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_d,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_Return, zoom,           {0} },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY|ShiftMask,             XK_c,      killclient,     {0} },
    // Tiled mode
	{ MODKEY,                       XK_t,      setlayout,      {.v = &layouts[0]} },
    // Monocle mode
	{ MODKEY,                       XK_m,      setlayout,      {.v = &layouts[2]} },
    // switch modes
	{ MODKEY,                       XK_space,  setlayout,      {0} },
	{ MODKEY,                       XK_f,      setlayout,      {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating, {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button2,        spawn,          {.v = termcmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};

