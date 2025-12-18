// gcc border_drawer.c -o border_drawer -lX11
// draws border; ex: ./border_drawer 200 120 800 450 green 4 &
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static unsigned long parse_color(Display *dpy, const char *s) {
    XColor c;
    Colormap cmap = DefaultColormap(dpy, DefaultScreen(dpy));

    if (!strcasecmp(s, "red"))    XParseColor(dpy, cmap, "#ff0000", &c);
    else if (!strcasecmp(s, "orange")) XParseColor(dpy, cmap, "#ffa500", &c);
    else if (!strcasecmp(s, "green"))  XParseColor(dpy, cmap, "#00ff00", &c);
    else if (s[0] == '#') XParseColor(dpy, cmap, s, &c);
    else {
        fprintf(stderr, "Invalid color\n");
        exit(1);
    }

    XAllocColor(dpy, cmap, &c);
    return c.pixel;
}

static Window make_bar(Display *dpy,
                       int x, int y, int w, int h,
                       unsigned long color)
{
    int scr = DefaultScreen(dpy);
    Window root = RootWindow(dpy, scr);

    XSetWindowAttributes a;
    a.override_redirect = True;
    a.background_pixel = color;
    a.event_mask = 0;

    Window win = XCreateWindow(
        dpy, root,
        x, y, w, h,
        0,
        CopyFromParent,
        InputOutput,
        CopyFromParent,
        CWOverrideRedirect | CWBackPixel | CWEventMask,
        &a
    );

    /* <<< ADD THIS LINE >>> */
    XDefineCursor(dpy, win, None);

    XMapRaised(dpy, win);
    return win;
}

static void usage(const char *p) {
    fprintf(stderr,
        "Usage:\n"
        "  %s fullscreen <color> <thickness> [seconds]\n"
        "  %s x y w h <color> <thickness> [seconds]\n",
        p, p);
    exit(1);
}

int main(int argc, char **argv) {
    int x, y, w, h, t;
    const char *color_s;
    int seconds = -1;

    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) return 1;

    int scr = DefaultScreen(dpy);

    if (argc >= 4 && !strcmp(argv[1], "fullscreen")) {
        x = y = 0;
        w = DisplayWidth(dpy, scr);
        h = DisplayHeight(dpy, scr);
        color_s = argv[2];
        t = atoi(argv[3]);
        if (argc == 5) seconds = atoi(argv[4]);
    }
    else if (argc >= 7) {
        x = atoi(argv[1]);
        y = atoi(argv[2]);
        w = atoi(argv[3]);
        h = atoi(argv[4]);
        color_s = argv[5];
        t = atoi(argv[6]);
        if (argc == 8) seconds = atoi(argv[7]);
    }
    else usage(argv[0]);

    unsigned long color = parse_color(dpy, color_s);

    // top
    make_bar(dpy, x, y, w, t, color);
    // bottom
    make_bar(dpy, x, y + h - t, w, t, color);
    // left
    make_bar(dpy, x, y, t, h, color);
    // right
    make_bar(dpy, x + w - t, y, t, h, color);

    XFlush(dpy);

    if (seconds > 0)
        sleep(seconds);
    else
        for (;;)
            pause();

    XCloseDisplay(dpy);
    return 0;
}
