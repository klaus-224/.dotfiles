#!/usr/bin/env bash

branches=(
)

for branch in "${branches[@]}"; do
  git push origin --delete "${branch#origin/}"
done
