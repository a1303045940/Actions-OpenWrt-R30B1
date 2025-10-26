#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

FEEDS_LUCI=${GITHUB_WORKSPACE}/openwrt/package/feeds/luci
FEEDS_PKG=${GITHUB_WORKSPACE}/openwrt/package/feeds/packages

MKDIR() {
	while [[ $1 ]]
	do
		if [[ ! -d $(dirname $1) ]]
		then
			mkdir -p $(dirname $1)
			if [[ $? != 0 ]]
			then
				ECHO "Failed to create parent directory: [$(dirname $1)] ..."
				return 0
			fi
		fi
		if [[ ! -d $1 ]]
		then
			mkdir -p $1 || ECHO "Failed to create sub directory: [$1] ..."
		else
			ECHO "Create directory: [$(dirname $1)] ..."
		fi
		shift
	done
}

ECHO() {
	echo "[$(date "+%H:%M:%S")] $*"
}

DeleteFind() {
  parent_dir=$1
  delete_dir=$2
  mapfile -d $'\0' found_dirs < <(find "$parent_dir" \( -type d -o -type l \) -name "$delete_dir" -print0 2>/dev/null)
  if [ ${#found_dirs[@]} -gt 0 ]; then
    for path in "${found_dirs[@]}"; do
      ECHO "Deleting Directory: $path"
      rm -rf -- "$path"
    done
  fi
}

AddPackage() {
  if [[ $# -lt 4 ]]
  then
    ECHO "Syntax error: [$#] [$*]"
    return 0
  fi
  PKG_DIR=$1
  [[ ! ${PKG_DIR} =~ ${GITHUB_WORKSPACE} ]] && PKG_DIR=package/${PKG_DIR}
  REPO_URL="https://github.com/$2/$3"
  PKG_NAME=$3
  REPO_BRANCH=$4

  MKDIR ${PKG_DIR}
  if [[ -d ${PKG_DIR}/${PKG_NAME} ]]
  then
    ECHO "Removing old package: [${PKG_NAME}] ..."
    rm -rf "${PKG_DIR}/${PKG_NAME}"
  fi

  if [[ -z ${REPO_BRANCH} ]]
  then
    REPO_BRANCH=main
  fi
  ECHO "Downloading package [${PKG_NAME}] to ${PKG_DIR} ..."
  git clone --depth 1 -b ${REPO_BRANCH} ${REPO_URL} ${PKG_DIR}/${PKG_NAME}/ > /dev/null 2>&1
  if [ "$5" ]
  then
    NOT_DEL=$5
    echo "NOT_DEL:${NOT_DEL}"
    RemoveDirWithoutRex ${PKG_DIR}/${PKG_NAME} ${NOT_DEL}
    # find ${PKG_DIR}/${PKG_NAME}/* -type d -maxdepth 0 ! -regex ".*$(echo "$NOT_DEL" | sed 's/|/\\|/g')" -exec rm -rf {} +
    # need [shopt -s extglob] in workflows.yml
    # rm -rf ${PKG_DIR:?}/${PKG_NAME:?}/!(${NOT_DEL:?})
  fi
  for dir in "${PKG_DIR}"/"${PKG_NAME}"/*
  do
    dir_name=$(basename "$dir")
    DeleteFind "$FEEDS_LUCI" "$dir_name"
    DeleteFind "$FEEDS_PKG" "$dir_name"
  done
}

RemoveDirWithoutRex() {
	TARGET_DIR=$1
	REGEX="$2"
	for dir in "$TARGET_DIR"/*
	do
		dir_name=$(basename "$dir")
		if [[ ! "$dir_name" =~ $REGEX ]]
		then
			rm -rf "$dir"
			echo "Deleted folder: $dir_name"
		fi
	done
}

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate

#AddPackage ddns-go sirpdboy luci-app-ddns-go main
#AddPackage other sirpdboy luci-app-advancedplus main
AddPackage other sirpdboy luci-app-lucky main
AddPackage other sbwml luci-app-mosdns v5
#AddPackage themes sirpdboy luci-theme-kucat js
#AddPackage passwall xiaorouji openwrt-passwall main
AddPackage passwall xiaorouji openwrt-passwall2 main
AddPackage passwall xiaorouji openwrt-passwall-packages main
AddPackage OpenClash vernesong OpenClash dev
#AddPackage OpenWrt-nikki nikkinikki-org OpenWrt-nikki main
#AddPackage other sbwml luci-app-openlist2 main
