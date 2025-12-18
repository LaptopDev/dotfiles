// gcc mouse_grab.c -o mouse_grab -lX11
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static Display *dpy = NULL;
static Window win = 0;
static Cursor invisible = 0;

static void cleanup(void) {
    if (dpy) {
        XUngrabPointer(dpy, CurrentTime);
        if (invisible)
            XFreeCursor(dpy, invisible);
        if (win)
            XDestroyWindow(dpy, win);
        XCloseDisplay(dpy);
        dpy = NULL;
    }
}

static void on_signal(int sig) {
    cleanup();
    exit(0);
}

static Cursor create_invisible_cursor(Display *dpy, Window root) {
    Pixmap pm = XCreatePixmap(dpy, root, 1, 1, 1);
    XColor black = {0};

    GC gc = XCreateGC(dpy, pm, 0, NULL);
    XDrawPoint(dpy, pm, gc, 0, 0);
    XFreeGC(dpy, gc);

    return XCreatePixmapCursor(dpy, pm, pm, &black, &black, 0, 0);
}

int main(void) {
    dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "mouse_grab: cannot open display\n");
        return 1;
    }

    int scr = DefaultScreen(dpy);
    Window root = RootWindow(dpy, scr);

    XSetWindowAttributes a;
    a.override_redirect = True;
    a.event_mask = ButtonPressMask | ButtonReleaseMask | PointerMotionMask;

    win = XCreateWindow(
        dpy, root,
        0, 0,
        DisplayWidth(dpy, scr),
        DisplayHeight(dpy, scr),
        0,
        0,
        InputOnly,
        CopyFromParent,
        CWOverrideRedirect | CWEventMask,
        &a
    );

    invisible = create_invisible_cursor(dpy, root);
    XDefineCursor(dpy, win, invisible);

    XMapWindow(dpy, win);
    XFlush(dpy);

    if (XGrabPointer(
            dpy, win, True,
            ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
            GrabModeAsync, GrabModeAsync,
            None, invisible, CurrentTime) != GrabSuccess) {
        fprintf(stderr, "mouse_grab: XGrabPointer failed\n");
        cleanup();
        return 1;
    }

    signal(SIGINT,  on_signal);   // Ctrl+C
    signal(SIGTERM, on_signal);   // kill PID
    signal(SIGHUP,  on_signal);   // terminal closed
    signal(SIGQUIT, on_signal);   // Ctrl+\

    /* Wait until killed */
    for (;;) {
        pause();
    }
}
