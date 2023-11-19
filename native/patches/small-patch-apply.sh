#!/bin/bash

patch --no-backup-if-mismatch -f -t -s --directory=small/ --strip=1 < patches/small-patch.diff