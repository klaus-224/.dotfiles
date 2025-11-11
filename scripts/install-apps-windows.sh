#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------
# Colors for output
# -----------------------------------------------------
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
RESET="\033[0m"

# -----------------------------------------------------
# Windows App Installation via winget
# -----------------------------------------------------
echo -e "${YELLOW}Installing most-used Windows apps...${RESET}"

APPS=(
  "Mozilla.Firefox"         # Firefox Browser
  "Valve.Steam"             # Steam
  "Google.Chrome"           # Chrome (optional)
  "SlackTechnologies.Slack" # Slack
  "Notepad++.Notepad++"     # Notepad++
  "VideoLAN.VLC"            # VLC Media Player
  "Discord.Discord"         # Discord
)

for app in "${APPS[@]}"; do
  echo -e "${YELLOW}→ Installing $app...${RESET}"
  powershell.exe -Command "winget install --id $app --silent --accept-package-agreements --accept-source-agreements" \
    && echo -e "${GREEN}$app installed successfully!${RESET}" \
    || echo -e "${RED}Failed to install $app${RESET}"
done

echo -e "${GREEN}All selected apps installation complete!${RESET}"

