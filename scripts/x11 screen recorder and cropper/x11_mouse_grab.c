// gcc mouse_grab.c -o mouse_grab -lX11
#include <X11/Xlib.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static Display *dpy = NULL;
static Window win = 0;

static void cleanup(void) {
    if (dpy) {
        XUngrabPointer(dpy, CurrentTime);
        if (win)
            XDestroyWindow(dpy, win);
        XCloseDisplay(dpy);
        dpy = NULL;
    }
}

static void on_signal(int sig) {
    cleanup();
    exit(0);   /* IMPORTANT: exit(), not _exit() */
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

    XMapWindow(dpy, win);
    XFlush(dpy);

    if (XGrabPointer(
            dpy, win, True,
            ButtonPressMask | ButtonReleaseMask | PointerMotionMask,
            GrabModeAsync, GrabModeAsync,
            None, None, CurrentTime) != GrabSuccess) {
        fprintf(stderr, "mouse_grab: XGrabPointer failed\n");
        cleanup();
        return 1;
    }

    signal(SIGINT,  on_signal);  /* Ctrl+C */
    signal(SIGTERM, on_signal);  /* kill PID */
    signal(SIGHUP,  on_signal);  /* terminal closed */
    signal(SIGQUIT, on_signal);  /* Ctrl+\ */

    /* Block forever, until signal */
    for (;;) {
        pause();
    }
}
