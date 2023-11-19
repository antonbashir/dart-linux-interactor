#!/bin/bash

patch --no-backup-if-mismatch --force --silent --directory=small/ --strip=1 < patches/small-patch.diff > /dev/null