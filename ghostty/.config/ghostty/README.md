# Ghostty Terminal Configuration

This repository contains my personal configuration for the [Ghostty](https://github.com/mitchellh/ghostty) terminal emulator.

## Configuration Options

### Font Settings
```
font-family = Berkeley Mono Variable  # Using Berkeley Mono Variable font
font-size = 15                       # Font size in points
```

### Theme Configuration
```
theme = tokyonight                   # Using the Tokyo Night color scheme
```

### Window Settings
```
window-padding-balance = true        # Automatically balance window padding
macos-titlebar-style = hidden       # Hide the macOS titlebar
window-save-state = always          # Always save window state
window-colorspace = "display-p3"    # Use display-p3 color space for better color reproduction
```

### Mouse Settings
```
mouse-hide-while-typing = true      # Hide mouse cursor while typing
copy-on-select = clipboard          # Automatically copy selected text to clipboard
```

### Keybindings



#### Split Management
```
keybind = super+shift+a=new_split:down    # Create new split below
keybind = super+shift+y=new_split:right   # Create new split to the right
```

### Other Settings
```
quit-after-last-window-closed = true    # Quit Ghostty when last window is closed
```
