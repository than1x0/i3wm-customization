# Kali Linux & Debian i3 Customization Dotfiles

Modern, lightweight, and aesthetic i3wm setup customized for **Kali Linux** and **Debian 12+ (Bookworm / Testing)**.

![Kali i3 Setup](./b.png)

---

## 🚀 Features

- **Window Manager:** i3 with native gaps support (`i3-gaps`).
- **Terminal:** Alacritty GPU-accelerated terminal (support for modern `alacritty.toml` & legacy `alacritty.yml`).
- **Status Bar:** i3bar + i3blocks with dynamic CPU, RAM, Disk, Dynamic Bandwidth, and VPN/Local IP indicators.
- **Compositor:** Modern `picom` (with fallback to `compton`) for clean shadows, fading, and window transparency.
- **App Launcher:** Rofi with modern `.rasi` configuration and fuzzy application search.
- **VM Integration:** Out-of-the-box clipboard and resolution auto-fix for VMware and VirtualBox.
- **Audio & Brightness:** Multimedia keybindings support.

---

## 🛠️ Quick Installation

Clone this repository to your Kali Linux or Debian system:

```bash
git clone https://github.com/Sathira-Laksahan/Customization-i3.git
cd Customization-i3
bash installer.sh
```

---

## 🖥️ First Boot Setup

1. **Reboot** or **Log out** of your current desktop session.
2. At the login screen (LightDM / GDM), click the session gear icon and select **`i3`**.
3. Log in to your session.
4. Press **`Win + Enter`** to launch the Alacritty terminal.
5. In the terminal, run `lxappearance`:
   - Set **Widget Theme** to **`Arc-Dark`**.
   - Set **Icon Theme** to **`Papirus-Dark`**.
   - Click **Apply**.

---

## ⌨️ Keybindings & Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`Win + Enter`** | Open Alacritty Terminal |
| **`Win + d`** | Open Rofi Application Launcher |
| **`Win + Shift + q`** | Close / Kill focused window |
| **`Win + Shift + Return`** | Open Thunar File Manager |
| **`Win + P`** | Take screenshot with Flameshot |
| **`Win + j / k / l / ;`** or **Arrow Keys** | Focus window (Left, Down, Up, Right) |
| **`Win + Shift + j / k / l / ;`** or **Shift + Arrows** | Move window position |
| **`Win + 1 .. 0`** | Switch to Workspace 1 - 10 |
| **`Win + Shift + 1 .. 0`** | Move focused window to Workspace 1 - 10 |
| **`Win + f`** | Toggle Fullscreen |
| **`Win + Shift + Space`** | Toggle Floating mode |
| **`Win + h` / `Win + v`** | Split layout horizontally / vertically |
| **`Win + r`** | Enter Resize mode (Escape to exit) |
| **`Win + Ctrl + Shift + Arrows`** | Quick window resize |
| **`Win + Shift + c`** | Reload i3 configuration |
| **`Win + Shift + r`** | Restart i3 in-place |
| **`Win + Shift + x`** | Lock screen |
| **`Win + Shift + e`** | Exit i3 (Logout prompt) |
| **Audio Keys (`XF86Audio...`)** | Volume Up / Down / Mute |
| **Brightness Keys** | Screen brightness adjustment |

---

## 🎨 Customization

- **Change Wallpaper:**
  Place your new wallpaper image in `~/.wallpaper/` and update `~/.fehbg`:
  ```bash
  feh --no-fehbg --bg-fill ~/.wallpaper/your_image.jpg
  ```
- **Transparency & Effects:**
  Edit `~/.config/picom/picom.conf` to customize window blur, fading speed, and opacity rules.
- **Status Bar Widgets:**
  Custom status bar scripts are located in `~/.config/i3/scripts/`. Edit `~/.config/i3/i3blocks.conf` to add or modify widgets.
- **Terminal Theme & Font:**
  Edit `~/.config/alacritty/alacritty.toml` (or `alacritty.yml`).
