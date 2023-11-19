#!/bin/bash

diff --unified --recursive --no-dereference patches/small-old/ patches/small-new/ > patches/small-patch.diff
