To run this script effectively, you need a **Linux** environment running the **X11 (X.Org)** windowing system. Because the script relies on specific X11-only tools like xinput and x11grab, it will not function correctly on a pure Wayland session without an Xwayland compatibility layer (and even then, global key/mouse grabbing may fail).

### **1\. Operating System & Display Server**

* **OS:** Any modern Linux distribution (Ubuntu, Fedora, Arch, Debian, etc.).  
* **Display Server:** **X11** is required.  
  * While many distributions now use Wayland by default, this script is designed for X11 environments like **i3wm, FVWM, Openbox, XFCE, or MATE**.  
  * On GNOME or KDE Plasma, ensure you are logged into the "X11" or "Xorg" session variant.

### **2\. Core Video & Audio Utilities**

These are the heavy lifters for the recording and processing phases:

* **FFmpeg:** Must be compiled with hevc\_nvenc support if you intend to use NVIDIA GPU acceleration.  
* **PulseAudio / PipeWire:** Specifically pactl is used to detect your default audio sink (speakers/headphones) so it can record what you hear.

### **3\. Required User-Space Utilities**

You will need to install these via your package manager (e.g., sudo apt install or sudo pacman \-S):

* **slop (Select Operation):** Used for the interactive mouse-drag selection of screen regions.  
* **xinput:** Essential for the script to listen for global key presses (like Escape/Enter) and to "grab" or disable mouse input during certain phases.  
* **xrandr:** Used to detect the current screen resolution for the initial full-screen capture.  
* **stty:** Usually included by default in coreutils, used for terminal-based key detection.

### **4\. Custom Helper Scripts**

The script refers to three external helpers in the CONFIG section. You must ensure these exist at the specified paths or replace them with your own logic:

1. **border\_drawer:** A utility that draws a colored rectangle on the screen (often a wrapper for slop or a small python-tkinter/cairo script).  
2. **x11\_mouse\_hide:** A utility to hide the cursor during recording (like unclutter).  
3. **x11\_mouse\_grab:** A utility to confine or "lock" the mouse during selection to prevent accidental clicks outside the crop area.

### ---

**Installation Command (Debian/Ubuntu Example)**

Bash

sudo apt update  
sudo apt install ffmpeg slop x11-utils xinput pulseaudio-utils coreutils

### **Hardware Requirement: NVIDIA GPU**

The script is hardcoded to use **NVENC** (hevc\_nvenc) for primary recording.

* **If you have an NVIDIA GPU:** Ensure the nvidia-utils and latest drivers are installed.  
* **If you have AMD/Intel:** You will need to change \-c:v hevc\_nvenc to \-c:v libx264 or \-c:v h264\_vaapi in the recording section of the script.

Would you like me to help you modify the script to work with Intel/AMD (VAAPI) instead of NVIDIA?