---
name: nix-check
description: Validate a Nix or Home Manager change using the repository's pinned flake and host conventions.
---

## Inputs

Changed Nix expressions, flake location, and affected host names from the flake.
Read repository instructions; do not guess host names or update flake inputs.

## Procedure

1. Inspect the relevant modules, flake inputs, Home Manager links, and generated
   outputs. Edit source expressions, not installed symlinks or runtime files.
2. Use project formatting when established. Evaluate affected attributes with
   `nix eval --offline`; validate both Darwin hosts when a shared selector changes.
   Use the project's flake check when relevant and available.
3. Review the diff and report evaluation results. Do not activate nix-darwin,
   rebuild a laptop, install dependencies, or update `flake.lock` just to validate.

## Output and missing evidence

Report expressions checked, host attributes, exact commands and results. If Nix
or pinned inputs are unavailable, mark evaluation unverified and give the
repository-specific follow-up command; static inspection is not successful Nix
evaluation.
