#!/bin/bash

# LIBSODIUM
#export LIBSODIUM_VER=1.0.16
#export LIBSODIUM_VER=stable-2017-09-28
#export LIBSODIUM_VER=$(curl -L -s https://github.com/jedisct1/libsodium/releases/latest | grep "/jedisct1/libsodium/releases/download/" |head -n 1 |cut -f6 -d "/" | awk -F "v" '{print $1,$2}' | sed s/[[:space:]]//g )
export LIBSODIUM_VER=$(curl -L -s https://api.github.com/repos/jedisct1/libsodium/releases/latest | grep 'tag_name' | cut -d\" -f4)
#export LIBSODIUM_LINK="https://download.libsodium.org/libsodium/releases/libsodium-${LIBSODIUM_VER}.tar.gz"
export LIBSODIUM_LINK="https://github.com/jedisct1/libsodium/archive/${LIBSODIUM_VER}.tar.gz"

# MBEDTLS
#export MBEDTLS_VER=2.9.0
export MBEDTLS_VER=$(curl -L -s https://tls.mbed.org/download | grep "/download/start/" |head -n 1 | cut -f2 -d \- | sed s/[[:space:]]//g )
export MBEDTLS_LINK="https://tls.mbed.org/download/mbedtls-${MBEDTLS_VER}-gpl.tgz"

# SS_LIBEV
#export SS_LIBEV_VER=3.2.0
#old export SS_LIBEV_VER=$(curl -L -s https://github.com/shadowsocks/shadowsocks-libev/releases/latest | grep "/shadowsocks/shadowsocks-libev/releases/download/" | cut -f4 -d \- | awk -F ".tar" '{print $1}' | sed s/[[:space:]]//g )
#export SS_LIBEV_VER=$(curl -L -s https://github.com/shadowsocks/shadowsocks-libev/releases/latest | grep "/shadowsocks/shadowsocks-libev/releases/download/" |head -n 1 |cut -f6 -d "/" | awk -F "v" '{print $1,$2}' | sed s/[[:space:]]//g )
export SS_LIBEV_VER=$(curl -L -s https://api.github.com/repos/shadowsocks/shadowsocks-libev/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed s/v//g)
export SS_LIBEV_LINK="https://github.com/shadowsocks/shadowsocks-libev/releases/download/v${SS_LIBEV_VER}/shadowsocks-libev-${SS_LIBEV_VER}.tar.gz"
export SS_LIBEV_YUM_INIT="https://raw.githubusercontent.com/Jenking-Zhang/shell_for_ss_ssr_ssrr_kcptun_bbr/master/ss_libev.init"
export SS_LIBEV_APT_INIT="https://raw.githubusercontent.com/onekeyshell/kcptun_for_ss_ssr/master/ss_libev_apt.init"

# SSR
#export SSR_VER=3.4.0
export SSR_VER=$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/onekeyshell/shadowsocksr/manyuser/shadowsocks/version.py | grep return | cut -d\' -f2 | awk '{print $1}' | sed s/[[:space:]]//g )
export SSR_LINK="https://github.com/onekeyshell/shadowsocksr/archive/manyuser.zip"
export SSR_YUM_INIT="https://raw.githubusercontent.com/Jenking-Zhang/shell_for_ss_ssr_ssrr_kcptun_bbr/master/ssr.init"
export SSR_APT_INIT="https://raw.githubusercontent.com/onekeyshell/kcptun_for_ss_ssr/master/ssr_apt.init"
# SSRR
#export SSRR_VER=3.2.2
export SSRR_VER=$(wget --no-check-certificate -qO- https://raw.githubusercontent.com/shadowsocksrr/shadowsocksr/akkariiin/dev/shadowsocks/version.py | grep return | cut -d\' -f2 | awk '{print $2}')
export SSRR_LINK="https://github.com/shadowsocksrr/shadowsocksr/archive/akkariiin/master.zip"
export SSRR_YUM_INIT="https://raw.githubusercontent.com/Jenking-Zhang/shell_for_ss_ssr_ssrr_kcptun_bbr/master/ssrr.init"
export SSRR_APT_INIT="https://raw.githubusercontent.com/onekeyshell/kcptun_for_ss_ssr/master/ssrr_apt.init"
# KCPTUN
#export KCPTUN_VER=20180316
#export KCPTUN_VER=$(curl -L -s https://github.com/xtaci/kcptun/releases/latest | grep "/xtaci/kcptun/releases/download/" |head -n 1 |cut -f6 -d "/" | awk -F "v" '{print $1,$2}' | sed s/[[:space:]]//g )
export KCPTUN_VER=$(curl -L -s https://api.github.com/repos/xtaci/kcptun/releases/latest | grep 'tag_name' | cut -d\" -f4 | sed s/v//g)
export KCPTUN_AMD64_LINK="https://github.com/xtaci/kcptun/releases/download/v${KCPTUN_VER}/kcptun-linux-amd64-${KCPTUN_VER}.tar.gz"
export KCPTUN_386_LINK="https://github.com/xtaci/kcptun/releases/download/v${KCPTUN_VER}/kcptun-linux-386-${KCPTUN_VER}.tar.gz"
export KCPTUN_INIT="https://raw.githubusercontent.com/Jenking-Zhang/shell_for_ss_ssr_ssrr_kcptun_bbr/master/kcptun.init"
