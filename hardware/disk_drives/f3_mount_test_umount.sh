#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function disktest_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  disktest_fallible_main "$@" || return $?$(echo E: "Failed, rv=$?" >&2)
}


function disktest_fallible_main () {
  set -o pipefail -o errexit
  cd -- /dev/disk/by-id/
  local VAL=
  local PTN_LABEL='f3test'
  local FAT_LABEL="${PTN_LABEL^^}"
  local FAT_OPT="
    flush
    uid=$UID
    nodev
    nosuid
    showexec
    utf8
    "
  FAT_OPT="defaults$(printf -- ',%s' $FAT_OPT)"

  local DISK= PRTN=
  for VAL in usb-*; do
    if [[ "$VAL" == *-part[0-9]* ]]; then
      [ -z "$PRTN" ] || return 4$(
        echo E: "Found too many partitions: $VAL vs $PRTN" >&2)
      PRTN="$VAL"
      continue
    fi
    [ -z "$DISK" ] || return 4$(
      echo E: "Found too many disks: $VAL vs $DISK" >&2)
    DISK="$VAL"
  done
  [ -b "$DISK" ] || return 4$(
    echo E: "Expected a block device: $DISK" >&2)
  echo D: "Found device: $DISK"
  [ -n "$PRTN" ] || disktest_make_prtn || return $?

  diff -sU 999 --label='expected' <(
    echo -e 'Number\tStart\tEnd\tSize\tCode\tName'
    echo -e '1\t…\t…\t…\t0700\t'"$PTN_LABEL"
    ) --label="current partitions on $DISK" <(
    sudo sgdisk --print -- "$DISK" | tail -n 2 | sed -rf <(echo '
      s~\s+~ ~g
      s~^ ~~
      s~ \(\S+\)~~g
      2s~ ([0-9.]+ ){3}MiB ~ … … … ~
      s~ ~\t~g
      ') ) || return $?

  VAL="$(blkid --output=export -- "$PRTN" | sed -nre 's~^TYPE=~~p'
    )" || true
  echo D: "Wait for $PRTN to become stable again after the blkid invocation:"
  sleep 0.5s

  case "$VAL" in
    fat12 ) ;;
    fat16 ) ;;
    fat32 ) ;;
    vfat ) ;;

    swap | \
    '' )
      echo D: "Format $PRTN as FAT (current FS is '$VAL'):"
      # ls -l -- usb-*
      sudo mkfs.fat -n "$FAT_LABEL" -- "$PRTN"
      ;;

    * ) echo E: "Unexpected fs type on partition $PRTN: $VAL" >&2; return 4;;
  esac
  echo -n D: "Found FAT partition $PRTN, "
  local MPNT="/media/$USER/$PTN_LABEL"
  mkdir --parents -- "$MPNT"
  if mount | grep -qFe " on $MPNT type "; then
    echo "already mounted as: $MPNT"
  else
    echo "gonna mount as: $MPNT"
    sudo mount -o "$FAT_OPT" -- "$PRTN" "$MPNT"
    sleep 0.5s
    mount | grep -qFe " on $MPNT type " || return 4$(
      echo E: 'Failed to mount.' >&2)
  fi
  disktest_f3tool f3write
  disktest_f3tool f3read
  echo D: "umount $MPNT:"
  sudo umount "$MPNT"
  rmdir --verbose -- "$MPNT"
}


function disktest_make_prtn () {
  # We probably have no partition table on $DISK, so we should create a
  # GUID partition table using sgdisk with a single huge FAT partition.
  echo "D: Creating a partition on $DISK:"
  local SGD_CMD=(
    sgdisk
    --clear
    --largest-new=1
    --typecode=1:0700
    --change-name=1:"$PTN_LABEL"
    -- "$DISK"
    )
  sudo "${SGD_CMD[@]}" || return $?
  PRTN="$DISK-part1"
  echo D: "Wait a moment for the kernel to detect $PRTN:"
  sleep 2s
}


function disktest_f3tool () {
  printf '[%(%F %T)T] %s start!\n' -1 "$*"
  SECONDS=0
  local RV=0
  "$@" -- "$MPNT" || RV=$?
  printf '[%(%F %T)T] %s exit, t=%s sec, rv=%s\n' -1 "$*" "$SECONDS" "$RV"
  return "$RV"
}










disktest_cli_init "$@"; exit $?
