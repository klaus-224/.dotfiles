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
# Windows Bloatware Removal via winget
# -----------------------------------------------------
echo -e "${YELLOW}Removing common Windows bloatware...${RESET}"

BLOAT_APPS=(
  "Microsoft.MicrosoftEdge"     # Edge Browser
  "Microsoft.XboxApp"           # Xbox App
  "Microsoft.ZuneMusic"         # Groove Music
  "Microsoft.YourPhone"         # Your Phone
  "Microsoft.GetHelp"           # Help App
  "Microsoft.Getstarted"        # Get Started
  "Microsoft.MicrosoftSolitaireCollection" # Solitaire
)

for app in "${BLOAT_APPS[@]}"; do
  echo -e "${YELLOW}→ Attempting to uninstall $app...${RESET}"
  powershell.exe -Command "winget uninstall --id $app --silent --accept-package-agreements --accept-source-agreements" \
    && echo -e "${GREEN}Successfully uninstalled $app${RESET}" \
    || echo -e "${RED}Failed to uninstall $app or it was not installed.${RESET}"
done

echo -e "${GREEN}Windows bloatware removal complete!${RESET}"

