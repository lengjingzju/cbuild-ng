#!/bin/bash

############################################
# SPDX-License-Identifier: MIT             #
# Copyright (C) 2026-.... Jing Leng        #
# Contact: Jing Leng <lengjingzju@163.com> #
############################################

# setup_ld_cfg.sh - Generate ld.cfg configuration files for executable directories in a rootfs
# Usage: ./setup_ld_cfg.sh <rootfs>

set -e  # Exit immediately on error

# Display usage information
usage() {
    echo "Usage: $0 <rootfs>"
    exit 1
}

# Check command line argument
[ $# -ne 1 ] && usage
ROOTFS="$1"

# Remove trailing slash if present
ROOTFS="${ROOTFS%/}"

# Validate rootfs directory
if [ ! -d "$ROOTFS" ]; then
    echo "Error: '$ROOTFS' is not a valid directory."
    exit 1
fi

# 1. Find ld*.so* file in syslib (take the first match)
LD_FILE=$(find "$ROOTFS/syslib" -maxdepth 1 -name 'ld*.so*' -type f -print -quit 2>/dev/null || true)

if [ -z "$LD_FILE" ]; then
    echo "No ld*.so* found in $ROOTFS/syslib, exiting."
    exit 0
fi

echo "Found linker: $LD_FILE"

# Get real path (resolve symlinks)
REAL_LD=$(readlink -f "$LD_FILE" 2>/dev/null || echo "$LD_FILE")

# Get path relative to rootfs (e.g., syslib/ld-linux-x86-64.so.2)
LDPATH="${REAL_LD#$ROOTFS/}"

echo "Linker relative path: $LDPATH"

# Helper: check if a directory exists (relative to rootfs)
dir_exists() {
    [ -d "$ROOTFS/$1" ]
}

# Helper: write configuration file
# Arguments: $1 = target config file path (absolute path inside rootfs)
#            $2 = prefix to linker (e.g., "../" or "../../")
#            $3... = rpath entries (space-separated, relative to config file's directory)
write_config() {
    local cfg_file="$1"
    local linker_prefix="$2"
    shift 2
    local rpaths=("$@")   # remaining arguments are rpath entries

    # Ensure target directory exists
    local cfg_dir=$(dirname "$cfg_file")
    if [ ! -d "$cfg_dir" ]; then
        echo "Warning: $cfg_dir does not exist, skipping config creation."
        return
    fi

    # Build rpath string (keep only directories that actually exist)
    local rpath_str=""
    for rp in "${rpaths[@]}"; do
        # rp is relative to config file's directory; we need to check existence under rootfs
        # Handle special case "." (always exists)
        if [ "$rp" = "." ]; then
            rpath_str="${rpath_str}${rpath_str:+;}$rp"
            continue
        fi

        # Construct target path relative to rootfs by combining cfg_dir (relative) and rp
        local rel_cfg_dir="${cfg_dir#$ROOTFS/}"
        local target="$cfg_dir/$rp"
        # Normalize path (resolve ../ etc.) relative to rootfs
        local norm_target=$(cd "$ROOTFS" && realpath --relative-to="$ROOTFS" "$target" 2>/dev/null || echo "")
        if [ -n "$norm_target" ] && dir_exists "$norm_target"; then
            rpath_str="${rpath_str}${rpath_str:+;}$rp"
        else
            echo "  Skipping non-existent rpath: $rp"
        fi
    done

    # Default to "." if no valid rpath found
    [ -z "$rpath_str" ] && rpath_str="."

    # Write configuration file
    cat > "$cfg_file" << EOF
linker="${linker_prefix}${LDPATH}"
rpath="$rpath_str"
EOF
    echo "Created $cfg_file"
}

# 2. Process bin directory
if dir_exists "bin"; then
    rpath_list=("." "../syslib" "../lib" "../usr/lib")
    write_config "$ROOTFS/bin/ld.cfg" "../" "${rpath_list[@]}"
fi

# 3. Process sbin directory
if dir_exists "sbin"; then
    rpath_list=("." "../syslib" "../lib" "../usr/lib")
    write_config "$ROOTFS/sbin/ld.cfg" "../" "${rpath_list[@]}"
fi

# 4. Process usr/bin directory
if dir_exists "usr/bin"; then
    rpath_list=("." "../../syslib" "../../lib" "../lib")
    write_config "$ROOTFS/usr/bin/ld.cfg" "../../" "${rpath_list[@]}"
fi

# 5. Process usr/sbin directory
if dir_exists "usr/sbin"; then
    rpath_list=("." "../../syslib" "../../lib" "../lib")
    write_config "$ROOTFS/usr/sbin/ld.cfg" "../../" "${rpath_list[@]}"
fi
