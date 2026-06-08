#!/bin/sh

# Resources:
# https://bgp.he.net
# https://bgp.tools

PROV="ipverse"
URL="https://github.com/ipverse/as-ip-blocks/releases/download/latest/as-ip-blocks.tar.gz"

AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"

DIR_CONF="/etc/bird/bird.conf.d"
DIR_PROV="/etc/bird/${PROV}"

FILE_AS="${DIR_PROV}/as-ip-blocks.tar.gz"
FILE_MAP="/etc/bird/mapping.txt"

if [ ! -d "${DIR_CONF}" ]; then
	echo "Error: Directory ${DIR_CONF} doesn't exist. Exiting."
	exit 1
else
	rm "${DIR_CONF}"/*.${PROV}.conf
fi

if [ ! -d "${DIR_PROV}" ]; then
	echo "Error: Directory ${DIR_PROV} doesn't exist. Exiting."
	exit 1
fi

if [ ! -f "${FILE_MAP}" ]; then
	echo "Error: File ${FILE_MAP} doesn't exist. Exiting."
	exit 1
fi

if [ ! -f "${FILE_AS}" ] || [ "$(($(date +%s)-$(date -r "${FILE_AS}" +%s)))" -gt 86400 ]; then
	if ! curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_AS}" "${URL}"; then
		echo "Error: File ${FILE_AS} is missing or obsolete and can't be downloaded. Exiting."
		exit 1
	else
		tar -xzf "${FILE_AS}" -C "${DIR_PROV}"
	fi
fi

while IFS= read -r LINE || [ -n "${LINE}" ]; do
	IFS=" " read -r ID GROUP NUMBERS <<-EOF
	${LINE}
	EOF

	if [ -n "${GROUP}" ] && [ -n "${NUMBERS}" ] && [ -n "${ID}" ]; then
		GROUP_LC=$(echo "${GROUP}" | tr '[:upper:]' '[:lower:]')

		FILE_IPV4="${DIR_CONF}/${GROUP_LC}.ipv4.${PROV}.conf"
		FILE_IPV6="${DIR_CONF}/${GROUP_LC}.ipv6.${PROV}.conf"
		truncate -s 0 "${FILE_IPV4}"
		truncate -s 0 "${FILE_IPV6}"

		for NUMBER in $(echo "${NUMBERS}" | tr "," "\n"); do
			echo "# AS${NUMBER}" >> "${FILE_IPV4}"
			echo "# AS${NUMBER}" >> "${FILE_IPV6}"

			#FILE_TAB="${DIR_PROV}/${GROUP_LC}.as${NUMBER}.ipv4.txt"
			#truncate -s 0 "${FILE_TAB}"
			#if ! tar -xzOf "${FILE_AS}" "as/${NUMBER}/ipv4-aggregated.txt" > "${FILE_TAB}"; then
			#	rm "${FILE_TAB}"
			#else
			FILE_TAB="${DIR_PROV}/as/${NUMBER}/ipv4-aggregated.txt"
			if [ -f "${FILE_TAB}" ]; then
				#URL="https://github.com/ipverse/as-ip-blocks/raw/refs/heads/master/as/${NUMBER}/ipv4-aggregated.txt"
				#if curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_TAB}" "${URL}"; then
					grep -E "^[^#]" "${FILE_TAB}" | awk '{printf "route %s unreachable;\n", $1}' >> "${FILE_IPV4}"
				#else
				#	echo "Warning: File ${FILE_TAB} is missing or obsolete and can't be downloaded. Skipping."
				#fi
			fi

			#FILE_TAB="${DIR_PROV}/${GROUP_LC}.as${NUMBER}.ipv6.txt"
			#truncate -s 0 "${FILE_TAB}"
			#if ! tar -xzOf "${FILE_AS}" "as/${NUMBER}/ipv6-aggregated.txt" > "${FILE_TAB}"; then
			#	rm "${FILE_TAB}"
			#else
			FILE_TAB="${DIR_PROV}/as/${NUMBER}/ipv6-aggregated.txt"
			if [ -f "${FILE_TAB}" ]; then
				#URL="https://github.com/ipverse/as-ip-blocks/raw/refs/heads/master/as/${NUMBER}/ipv6-aggregated.txt"
				#if curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_TAB}" "${URL}"; then
					grep -E "^[^#]" "${FILE_TAB}" | awk '{printf "route %s unreachable;\n", $1}' >> "${FILE_IPV6}"
				#else
				#	echo "Warning: File ${FILE_TAB} is missing or obsolete and can't be downloaded. Skipping."
				#fi
			fi
		done

		FILE_PROTO="${DIR_CONF}/${GROUP_LC}.proto.${PROV}.conf"
		cat <<-EOF > "${FILE_PROTO}"
		protocol static s4_${GROUP_LC} {
			description "${GROUP} AS ${NUMBERS} IPv4";
			ipv4 {
				import filter {
					bgp_community.add((my_asn, my_com4));
					bgp_community.add((my_asn, ${ID}));
					accept;
				};
				export none;
			};
			include "${DIR_CONF}/${GROUP_LC}.ipv4.${PROV}.conf";
		}

		protocol static s6_${GROUP_LC} {
			description "${GROUP} AS ${NUMBERS} IPv6";
			ipv6 {
				import filter {
					bgp_community.add((my_asn, my_com6));
					bgp_community.add((my_asn, ${ID}));
					accept;
				};
				export none;
			};
			include "${DIR_CONF}/${GROUP_LC}.ipv6.${PROV}.conf";
		}
		EOF
	fi
done < "${FILE_MAP}"

exit 0