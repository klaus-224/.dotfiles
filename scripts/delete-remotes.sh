#!/usr/bin/env bash

branches=(
)

for branch in "${branches[@]}"; do
  # git push origin --delete "${branch#origin/}"
  git branch -D "${branch}"
done
