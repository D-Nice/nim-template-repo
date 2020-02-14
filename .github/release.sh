#!/bin/sh
FIRST=""
if [ ! -f CHANGELOG.md ]; then
  FIRST="-f"
fi
npx standard-version@7.1.0 "$FIRST" --header '# CHANGELOG
' \
  && echo "Sign-off commit and tags via 'git commit --amend --signoff' and 'git tag -sf v...'" \
  && echo "Appropriately bump nimble file version as well in the amend..."
