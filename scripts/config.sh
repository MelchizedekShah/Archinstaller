#!/bin/bash

# Configuration file whit console keyboard and localelization


# Run, to list all the available console keymap layouts
# localectl list-keymaps


#
# Keymaps
#

keymap="us"
keymap=""




locale=




#echo "${keymap}"
#exit 0

# To set the keyboard layout, pass its name to loadkeys
loadkeys ${keymap}

# A nicer, larger font
setfont ter-132b
