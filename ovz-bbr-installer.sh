#!/bin/sh

: <<-'EOF'
Copyright 2017 Xingwang Liao <kuoruan@gmail.com>
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
	http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Haproxy-lkl ��������
SERVICE_NAME='haproxy-lkl'
# Haproxy-lkl Ĭ�ϰ�װ·�����޸�֮����Ҫͬʱ�޸ķ��������ļ�
HAPROXY_LKL_DIR="/usr/local/$SERVICE_NAME"

BASE_URL='https://github.com/kuoruan/shell-scripts/raw/master/ovz-bbr'
HAPROXY_BIN_URL="${BASE_URL}/bin/haproxy.linux2628_x86_64"
HAPROXY_LKL_BIN_URL="${BASE_URL}/bin/haproxy-lkl.sh"
HAPROXY_LKL_SERVICE_FILE_DEBIAN_URL="${BASE_URL}/startup/haproxy-lkl.init.debain"
HAPROXY_LKL_SERVICE_FILE_REDHAT_URL="${BASE_URL}/startup/haproxy-lkl.init.redhat"
HAPROXY_LKL_SYSTEMD_FILE_URL="${BASE_URL}/startup/haproxy-lkl.systemd"
LKL_LIB_URL="${BASE_URL}/lib64/liblkl-hijack.so-20170724"
LKL_LIB_MD5='b50fc6a7ccfc70c76f44506814e7e18b'

# ��Ҫ BBR ���ٵĶ˿�
ACCELERATE_PORT=

clear

cat >&2 <<-'EOF'
#######################################################
# OpenVZ BBR һ����װ�ű�                             #
# �ýű������� OpenVZ �������ϰ�װ���� Google BBR     #
# �ű�����: Xingwang Liao <kuoruan@gmail.com>         #
# ���߲���: https://blog.kuoruan.com/                 #
# Github: https://github.com/kuoruan/shell-scripts    #
# QQ����Ⱥ: 43391448, 68133628                        #
#           633945405                                 #
#######################################################
EOF

command_exists() {
	command -v "$@" >/dev/null 2>&1
}

check_root() {
	local user="$(id -un 2>/dev/null || true)"
	if [ "$user" != "root" ]; then
		cat >&2 <<-'EOF'
		Ȩ�޴���, ��ʹ�� root �û����д˽ű�!
		EOF
		exit 1
	fi
}

check_ovz() {
	if [ ! -d /proc/vz ]; then
		cat >&2 <<-'EOF'
		��ǰ������������ OpenVZ �ܹ��������ֱ�Ӹ����ں������� BBR��
		��Ȼ����Ҳ���Լ�����װ��
		EOF
		any_key_to_continue
	fi
}

check_ldd() {
	local ldd_version="$(ldd --version 2>/dev/null | grep 'ldd' | rev | cut -d ' ' -f1 | rev)"
	if [ -n "$ldd_version" ]; then
		if [ "${ldd_version%.*}" -eq "2" -a "${ldd_version#*.}" -lt "14" ] || \
		[ "${ldd_version%.*}" -lt "2" ]; then
			cat >&2 <<-EOF
			��ǰ�������� glibc �汾Ϊ $ldd_version��
			��Ͱ汾���� 2.14����������汾�޷�����ʹ�á�
			���ȸ��� glibc ֮�������нű���
			EOF
			exit 1
	  fi
	else
		cat >&2 <<-EOF
		��ȡ glibc �汾ʧ�ܣ����ֶ���飺
		    ldd --version
		��Ͱ汾���� 2.14����������汾�����޷�����ʹ�á�
		EOF

		( set -x; ldd --version 2>/dev/null )
		any_key_to_continue
	fi
}

check_arch() {
	architecture=$(uname -m)
	case $architecture in
		amd64|x86_64)
			;;
		*)
			cat 1>&2 <<-EOF
			��ǰ�ű���֧�� 64 λϵͳ�����ϵͳΪ: $architecture
			����Գ��Դ�Դ����밲װ Linux Kernel Library
			    https://github.com/lkl/linux
			EOF
			exit 1
			;;
	esac
}

any_key_to_continue() {
	echo "�밴����������� Ctrl + C �˳�"
	local saved="$(stty -g)"
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $saved
}

get_os_info() {
	lsb_dist=''
	dist_version=''
	if command_exists lsb_release; then
		lsb_dist="$(lsb_release -si)"
	fi

	if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
		lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/debian_version ]; then
		lsb_dist='debian'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/fedora-release ]; then
		lsb_dist='fedora'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/oracle-release ]; then
		lsb_dist='oracleserver'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
		lsb_dist='centos'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
		lsb_dist='redhat'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/photon-release ]; then
		lsb_dist='photon'
	fi
	if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
		lsb_dist="$(. /etc/os-release && echo "$ID")"
	fi

	lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"

	if [ "${lsb_dist}" = "redhatenterpriseserver" ]; then
		lsb_dist='redhat'
	fi

	case "$lsb_dist" in
		ubuntu)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/lsb-release ]; then
				dist_version="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")"
			fi
		;;

		debian|raspbian)
			dist_version="$(cat /etc/debian_version | sed 's/\/.*//' | sed 's/\..*//')"
			case "$dist_version" in
				9)
					dist_version="stretch"
				;;
				8)
					dist_version="jessie"
				;;
				7)
					dist_version="wheezy"
				;;
			esac
		;;

		oracleserver)
			lsb_dist="oraclelinux"
			dist_version="$(rpm -q --whatprovides redhat-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//')"
		;;

		fedora|centos|redhat)
			dist_version="$(rpm -q --whatprovides ${lsb_dist}-release --queryformat "%{VERSION}\n" | sed 's/\/.*//' | sed 's/\..*//' | sed 's/Server*//' | sort | tail -1)"
		;;

		"vmware photon")
			lsb_dist="photon"
			dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
		;;

		*)
			if command_exists lsb_release; then
				dist_version="$(lsb_release --codename | cut -f2)"
			fi
			if [ -z "$dist_version" ] && [ -r /etc/os-release ]; then
				dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
			fi
		;;
	esac

	if [ -z "$lsb_dist" -o -z "$dist_version" ]; then
		cat >&2 <<-EOF
		�޷�ȷ��������ϵͳ�汾��Ϣ��
		����ϵ�ű����ߡ�
		EOF
		exit 1
	fi
}

install_deps() {
	ip_support_tuntap() {
		command_exists ip && ip tuntap >/dev/null 2>&1
	}
	case "$lsb_dist" in
		ubuntu|debian|raspbian)
			local did_apt_get_update=
			apt_get_update() {
				if [ -z "$did_apt_get_update" ]; then
					( set -x; sleep 3; apt-get update )
					did_apt_get_update=1
				fi
			}

			if ! command_exists wget; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q wget ca-certificates )
			fi

			if ! command_exists ip; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q iproute )
			fi

			if ! command_exists timeout; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q coreutils )
			fi

			if ! command_exists iptables; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q iptables )
			fi

			if ! ip_support_tuntap; then
				apt_get_update
				( set -x; sleep 3; apt-get install -y -q uml-utilities )
			fi
		;;
		fedora|centos|redhat|oraclelinux|photon)
			if [ "$lsb_dist" = "fedora" ] && [ "$dist_version" -ge "22" ]; then
				if ! command_exists wget; then
					( set -x; sleep 3; dnf -y -q install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; dnf -y -q install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; dnf -y -q install coreutils )
				fi

				if ! command_exists iptables; then
					( set -x; sleep 3; dnf -y -q install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; dnf -y -q install tunctl )
				fi
			elif [ "$lsb_dist" = "photon" ]; then
				if ! command_exists wget; then
					( set -x; sleep 3; tdnf -y install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; tdnf -y install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; tdnf -y install coreutils )
				fi

				if ! command_exists iptables; then
					( set -x; sleep 3; tdnf -y install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; tdnf -y install tunctl )
				fi
			else
				if ! command_exists wget; then
					( set -x; sleep 3; yum -y -q install wget ca-certificates )
				fi

				if ! command_exists ip; then
					( set -x; sleep 3; yum -y -q install iproute )
				fi

				if ! command_exists timeout; then
					( set -x; sleep 3; yum -y -q install coreutils )
				fi

				if ! command_exists iptables firewall-cmd; then
					( set -x; sleep 3; yum -y -q install iptables )
				fi

				if ! ip_support_tuntap && ! command_exists tunctl; then
					( set -x; sleep 3; yum -y -q install tunctl )
				fi
			fi
		;;
		*)
			cat >&2 <<-EOF
			��ʱ��֧�ֵ�ǰϵͳ��${lsb_dist} ${dist_version}
			EOF

			exit 1
		;;
	esac
}

check_nat_create() {
	if ( command_exists ip && ip tuntap >/dev/null 2>&1 ); then
		(
			set -x
			ip tuntap del dev lkl-tap-test mode tap >/dev/null 2>&1
			ip tuntap add dev lkl-tap-test mode tap
		)
	elif command_exists tunctl; then
		(
			set -x
			tunctl -d lkl-tap-test >/dev/null 2>&1
			tunctl -t lkl-tap-test
		)
	else
		cat >&2 <<-'EOF'
		�޷��ҵ��Ѱ�װ�� ip ����(֧�� tuntap) ���� tunctl
		Ӧ���ǽű��Զ���װʧ���ˡ�
		���ֶ���װ iproute �� tunctl
		EOF
		exit 1
	fi

	if [ "$?" != "0" ]; then
		cat >&2 <<-'EOF'
		�޷����� NAT ���硣
		����ĳЩ�����̵� VPS �޷����� NAT ���磬
		���Բ�֧���ô˷������� BBR����װ�ű������˳���
		EOF
		exit 1
	fi
}

download_file() {
	local url=$1
	local file=$2

	( set -x; wget -O "$file" --no-check-certificate "$url" )
	if [ "$?" != "0" ]; then
		cat >&2 <<-EOF
		һЩ�ļ�����ʧ�ܣ���װ�ű���Ҫ�ܷ��ʵ� github.com��������������硣
		ע��: һЩ���ڷ����������޷��������� github.com��
		EOF

		exit 1
	fi
}

install_haproxy() {
	(
		set -x
		mkdir -p "${HAPROXY_LKL_DIR}"/etc \
			"${HAPROXY_LKL_DIR}"/lib64 \
			"${HAPROXY_LKL_DIR}"/sbin
	)

	if ! grep -q '^haproxy:' '/etc/passwd'; then
		(
			set -x
			useradd -U -s '/usr/sbin/nologin' -d '/nonexistent' haproxy 2>/dev/null
		)
	fi

	local haproxy_bin="${HAPROXY_LKL_DIR}/sbin/haproxy"
	download_file "$HAPROXY_BIN_URL" "$haproxy_bin"
	chmod +x "$haproxy_bin"

	if ! ( $haproxy_bin -v 2>/dev/null | grep -q 'HA-Proxy' ); then
		cat >&2 <<-EOF
		HAproxy ��ִ���ļ��޷���������
		������ glibc �汾���ͣ������ļ������������ϵͳ��
		����ϵ�ű����ߣ�Ѱ��֧�֡�
		EOF
		(
			set -x
			ldd --version
		)
		exit 1
	fi

	local haproxy_lkl_bin="${HAPROXY_LKL_DIR}/sbin/${SERVICE_NAME}"
	download_file "$HAPROXY_LKL_BIN_URL" "$haproxy_lkl_bin"

	sed -i -r "s#^HAPROXY_LKL_DIR=.*#HAPROXY_LKL_DIR='"${HAPROXY_LKL_DIR}"'#" \
		"$haproxy_lkl_bin"

	set_interface() {
		local has_vnet=0
		if command_exists ip; then
			ip -o link show | grep -q 'venet0'
			has_vnet=$?
		elif command_exists ifconfig; then
			ifconfig -s | grep -q 'venet0'
			has_vnet=$?
		fi

		if [ "$has_vnet" != 0 ]; then
			cat >&2 <<-EOF
			��ⷢ����Ĺ����ӿڲ��� venet0����Ҫ���ֶ�����һ������ӿ����ơ�
			���ǻ��������ӿ�����ת�������������ӿ��������ò���ȷ��
			�ⲿ���罫�޷��������ʵ��ڲ�����˿ڡ�
			 * ����ӿ��Ǿ��й��� IP �Ľӿ����ơ�

			����Դ��������Ϣ���ҵ���Ĺ����ӿ�����:
			EOF

			if command_exists ip; then
				ip addr show
			else
				ifconfig
			fi

			local input=
			while :
			do
				read -p "�������������ӿ�����(����: eth0): " input
				echo
				if [ -n "$input" ]; then
					sed -i -r "s#^INTERFACE=.*#INTERFACE='"${input}"'#" "$haproxy_lkl_bin"
				else
					echo "������Ϣ����Ϊ�գ����������룡"
					continue
				fi

				break
			done
		fi
	}
	set_interface

	chmod +x "$haproxy_lkl_bin"

	local haproxy_lkl_startup_file=
	local haproxy_lkl_startup_file_url=

	if command_exists systemctl; then
		haproxy_lkl_startup_file="/lib/systemd/system/${SERVICE_NAME}.service"
		haproxy_lkl_startup_file_url="${HAPROXY_LKL_SYSTEMD_FILE_URL}"

		download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
	elif command_exists service; then
		haproxy_lkl_startup_file="/etc/init.d/${SERVICE_NAME}"
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				haproxy_lkl_startup_file_url="${HAPROXY_LKL_SERVICE_FILE_DEBIAN_URL}"

				download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
				chmod +x "$haproxy_lkl_startup_file"
			;;
			fedora|centos|redhat|oraclelinux|photon)
				haproxy_lkl_startup_file_url="${HAPROXY_LKL_SERVICE_FILE_REDHAT_URL}"

				download_file "$haproxy_lkl_startup_file_url" "$haproxy_lkl_startup_file"
				chmod +x "$haproxy_lkl_startup_file"
			;;
			*)
				echo "û���ʺϵ�ǰϵͳ�ķ��������ű��ļ���"
				exit 1
			;;
		esac

	else
		cat >&2 <<-'EOF'
		��ǰ������δ��װ systemctl ���� service ����޷����÷���
		�����ֶ���װ systemd ���� service ֮�������нű���
		EOF

		exit 1
	fi

	echo "$ACCELERATE_PORT" > "${HAPROXY_LKL_DIR}/etc/port-rules"
}

install_lkl_lib() {
	local lib_file="${HAPROXY_LKL_DIR}/lib64/liblkl-hijack.so"
	local retry=0
	download_lkl_lib() {
		download_file "$LKL_LIB_URL" "$lib_file"
		if command_exists md5sum; then
			(
				set -x
				echo "${LKL_LIB_MD5}  ${lib_file}" | md5sum -c
			)
			if [ "$?" != "0" ]; then
				if [ "$retry" -lt "3" ]; then
					echo "�ļ�У��ʧ�ܣ�3 �����������..."
					retry=`expr $retry + 1`
					sleep 3
					download_lkl_lib
				else
					cat >&2 <<-EOF
					Linux �ں��ļ�У��ʧ�ܡ�
					ͨ��������ԭ������ļ����ز�ȫ��
					EOF
					exit 1
				fi
			fi
		fi
	}

	download_lkl_lib

	chmod +x "$lib_file"
}

enable_ip_forward() {
	local ip_forword="$(sysctl -n 'net.ipv4.ip_forward' 2>/dev/null)"
	if [ -z "$ip_forword" -o "$ip_forword" != "1" ]; then
		(
			set -x
			echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
			sysctl -p /etc/sysctl.conf 2>/dev/null
		)
	fi
}

set_config() {
	is_port() {
		local port=$1
		expr $port + 1 >/dev/null 2>&1 && \
			[ "$port" -ge "1" -a "$port" -le "65535" ]
	}

	local input=

	if [ -z "$ACCELERATE_PORT" ] || ! is_port "$ACCELERATE_PORT"; then
		while :
		do
			#read -p "��������Ҫ���ٵĶ˿� [1~65535]: " input
			input=443
			echo
			if [ -n "$input" ] && is_port $input; then
					ACCELERATE_PORT="$input"
			else
				echo "��������, ������ 1~65535 ֮�������!"
				continue
			fi
			break
		done
	fi

	cat >&2 <<-EOF
	---------------------------
	���ٶ˿� = ${ACCELERATE_PORT}
	---------------------------
	EOF
	#any_key_to_continue
}

is_running() {
	(
		set -x
		sleep 3
		# https://bugs.centos.org/view.php?id=12407
		# ping may not work with IPv4 under OpenVZ on CentOS 7

		# ping -q -c3 10.0.0.2 2>/dev/null
		timeout 2 bash -c "</dev/tcp/10.0.0.2/${ACCELERATE_PORT}" 2>/dev/null
	)
	return $?
}

enable_service() {
	if command_exists systemctl; then
		(
			set -x
			systemctl daemon-reload
			systemctl enable "${SERVICE_NAME}.service"
		)
	elif command_exists service; then
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				(
					set -x
					update-rc.d -f "${SERVICE_NAME}" defaults
				)
			;;
			fedora|centos|redhat|oraclelinux|photon)
				(
					set -x
					chkconfig --add "${SERVICE_NAME}"
					chkconfig "${SERVICE_NAME}" on
				)
			;;
		esac
	fi
}

start_service() {
	if command_exists systemctl; then
		(
			set -x
			sleep 3
			systemctl start "$SERVICE_NAME"
		)
	else
		(
			set -x
			sleep 3
			service "$SERVICE_NAME" start
		)
	fi

	if [ "$?" != "0" ] || ! is_running; then
		do_uninstall
		cat >&2 <<-EOF
		���ź�����������ʧ�ܡ�
		����Բ鿴�������־����ȡԭ��
		���ߣ�����Ե����ǵ�Ⱥ�ﷴ��һ�¡�
		EOF
		exit 1
	fi
}

end_install() {
	clear

	cat >&2 <<-EOF
	��ϲ��BBR ��װ��ɲ��ɹ�����

	�Ѽ��ٵĶ˿�: ${ACCELERATE_PORT}

	�����ͨ���޸��ļ�:
	    ${HAPROXY_LKL_DIR}/etc/port-rules

	��������Ҫ���ٵĶ˿ڻ�˿ڷ�Χ��
	EOF
	if command_exists systemctl; then

		cat >&2 <<-EOF

		��ʹ�� systemctl {start|stop|restart} ${SERVICE_NAME}
		�� {����|�ر�|����} ����
		EOF
	else

		cat >&2 <<-EOF

		��ʹ�� service ${SERVICE_NAME} {start|stop|restart}
		�� {����|�ر�|����} ����
		EOF
	fi
	cat >&2 <<-EOF

	�������Զ����뿪�������������ʹ�á�

	�������ű��ﵽ���㣬����������ߺ�ƿ����:
	  https://blog.kuoruan.com/donate

	���ܼ��ٵĿ�аɣ�
	EOF
}

do_uninstall() {
	check_root
	get_os_info

	if command_exists systemctl; then
		systemctl stop "${SERVICE_NAME}.service" 2>/dev/null
		(
			set -x
			systemctl disable "${SERVICE_NAME}.service" 2>/dev/null
			rm -f "/lib/systemd/system/${SERVICE_NAME}.service"
		)
	elif command_exists service; then
		service "${SERVICE_NAME}" stop 2>/dev/null
		case "$lsb_dist" in
			ubuntu|debian|raspbian)
				(
					set -x
					update-rc.d -f "${SERVICE_NAME}" remove 2>/dev/null
				)
			;;
			fedora|centos|redhat|oraclelinux|photon)
				(
					set -x
					chkconfig "${SERVICE_NAME}" off 2>/dev/null
					chkconfig --del "${SERVICE_NAME}" 2>/dev/null
				)
			;;
		esac
		(
			set -x
			rm -f "/etc/init.d/${SERVICE_NAME}"
		)
	fi

	(
		set -x
		${HAPROXY_LKL_DIR}/sbin/${SERVICE_NAME} -c 2>/dev/null
		rm -rf "${HAPROXY_LKL_DIR}"
	)
}

do_install() {
	check_root
	check_ovz
	check_ldd
	check_arch
	get_os_info
	set_config
	install_deps
	enable_ip_forward
	check_nat_create
	install_haproxy
	install_lkl_lib
	start_service
	enable_service
	end_install
}

action=${1:-"install"}
case "$action" in
	install|uninstall)
		do_${action}
	;;
	*)
		cat >&2 <<-EOF
		����������ʹ�� $(basename $0) install|uninstall
		EOF
		exit 255
esac
