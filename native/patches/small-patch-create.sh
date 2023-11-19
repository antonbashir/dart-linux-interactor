#!/bin/bash

cd patches/
diff --unified --recursive --no-dereference patches/small-old/ patches/small-new/ >> patches/small-patch.diff
rm -rf patches/small-old
rm -rf patches/small-new