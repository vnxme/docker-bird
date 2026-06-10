#!/bin/sh

# Resources:
# https://bgp.he.net
# https://bgp.tools

PROV="ipverse"
URL_AS="https://github.com/ipverse/as-ip-blocks/releases/download/latest/as-ip-blocks.tar.gz"
# URL_CRY="https://github.com/ipverse/country-ip-blocks/releases/download/latest/country-ip-blocks.tar.gz"
URL_GEO="https://github.com/ipverse/geo-ip-blocks/releases/download/latest/geo-ip-blocks.tar.gz"
# URL_ISO="https://github.com/lukes/ISO-3166-Countries-with-Regional-Codes/raw/refs/heads/master/slim-2/slim-2.csv"

AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36"

DIR_CONF="/etc/bird/bird.conf.d"
DIR_PROV="/etc/bird/${PROV}"

FILE_AS="${DIR_PROV}/as-ip-blocks.tar.gz"
# FILE_CRY="${DIR_PROV}/country-ip-blocks.tar.gz"
FILE_GEO="${DIR_PROV}/geo-ip-blocks.tar.gz"
# FILE_ISO="${DIR_PROV}/iso-3166-slim-2.csv"

FILE_AS_MAP="/etc/bird/as.mapping.txt"
FILE_ISO_MAP="/etc/bird/geo.mapping.txt"

if [ ! -d "${DIR_CONF}" ]; then
	echo "Error: Directory ${DIR_CONF} doesn't exist. Exiting."
	exit 1
else
	rm "${DIR_CONF}"/*.${PROV}.conf
fi

if [ ! -d "${DIR_PROV}" ]; then
	mkdir -p "${DIR_PROV}"
fi

if [ ! -f "${FILE_AS_MAP}" ]; then
	echo "Error: File ${FILE_AS_MAP} doesn't exist. Exiting."
	exit 1
fi

# if [ ! -f "${FILE_ISO}" ] || [ "$(($(date +%s)-$(date -r "${FILE_AS}" +%s)))" -gt 2592000 ]; then
# 	if ! curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_ISO}" "${URL_ISO}"; then
# 		echo "Error: File ${FILE_ISO} is missing and can't be downloaded. Exiting."
# 		exit 1
# 	fi
# fi

if [ ! -f "${FILE_AS}" ] || [ "$(($(date +%s)-$(date -r "${FILE_AS}" +%s)))" -gt 86400 ]; then
	if ! curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_AS}" "${URL_AS}"; then
		echo "Error: File ${FILE_AS} is missing or obsolete and can't be downloaded. Exiting."
		exit 1
	else
		tar -xzf "${FILE_AS}" -C "${DIR_PROV}"
	fi
fi

# if [ ! -f "${FILE_CRY}" ] || [ "$(($(date +%s)-$(date -r "${FILE_CRY}" +%s)))" -gt 86400 ]; then
# 	if ! curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_CRY}" "${URL_CRY}"; then
# 		echo "Error: File ${FILE_CRY} is missing or obsolete and can't be downloaded. Exiting."
# 		exit 1
# 	else
# 		tar -xzf "${FILE_CRY}" -C "${DIR_PROV}"
# 	fi
# fi

if [ ! -f "${FILE_GEO}" ] || [ "$(($(date +%s)-$(date -r "${FILE_GEO}" +%s)))" -gt 86400 ]; then
	if ! curl --fail --silent --location --user-agent "${AGENT}" --output "${FILE_GEO}" "${URL_GEO}"; then
		echo "Error: File ${FILE_GEO} is missing or obsolete and can't be downloaded. Exiting."
		exit 1
	else
		tar -xzf "${FILE_GEO}" -C "${DIR_PROV}"
	fi
fi

while IFS= read -r LINE || [ -n "${LINE}" ]; do
	IFS="," read -r ID GROUP CODES <<-EOF
	${LINE}
	EOF

	if [ -n "${ID}" ] && [ -n "${GROUP}" ] && [ -n "${CODES}" ]; then
		GROUP_LC="$(echo "${GROUP}" | tr '[:upper:]' '[:lower:]')"

		FILE_IPV4="${DIR_CONF}/${GROUP_LC}.ipv4.${PROV}.conf"
		FILE_IPV6="${DIR_CONF}/${GROUP_LC}.ipv6.${PROV}.conf"
		truncate -s 0 "${FILE_IPV4}"
		truncate -s 0 "${FILE_IPV6}"

		for CODE in $(echo "${CODES}" | tr "," "\n"); do
			CODE_LC="$(echo "${CODE}" | tr '[:upper:]' '[:lower:]')"

			FILE_TAB="${DIR_PROV}/country/${CODE_LC}/${CODE_LC}-ipv4.txt"
			if [ -f "${FILE_TAB}" ]; then
				grep -E "^[^#]" "${FILE_TAB}" | awk '{printf "route %s unreachable;\n", $1}' >> "${FILE_IPV4}"
			fi

			FILE_TAB="${DIR_PROV}/country/${CODE_LC}/${CODE_LC}-ipv6.txt"
			if [ -f "${FILE_TAB}" ]; then
				grep -E "^[^#]" "${FILE_TAB}" | awk '{printf "route %s unreachable;\n", $1}' >> "${FILE_IPV6}"
			fi
		done

		FILE_PROTO="${DIR_CONF}/${GROUP_LC}.proto.${PROV}.conf"
		cat <<-EOF > "${FILE_PROTO}"
		protocol static s4_${GROUP_LC} {
			description "${GROUP} ${CODES} IPv4";
			ipv4 {
				import filter {
					bgp_community.add((my_asn, my_com4));
					bgp_community.add((my_asn, my_geo));
					bgp_community.add((geo_asn, ${ID}));
					accept;
				};
				export none;
			};
			include "${DIR_CONF}/${GROUP_LC}.ipv4.${PROV}.conf";
		}

		protocol static s6_${GROUP_LC} {
			description "${GROUP} ${CODES} IPv6";
			ipv6 {
				import filter {
					bgp_community.add((my_asn, my_com6));
					bgp_community.add((my_asn, my_geo));
					bgp_community.add((geo_asn, ${ID}));
					accept;
				};
				export none;
			};
			include "${DIR_CONF}/${GROUP_LC}.ipv6.${PROV}.conf";
		}
		EOF
	fi
done < "${FILE_ISO_MAP}"

while IFS= read -r LINE || [ -n "${LINE}" ]; do
	IFS=" " read -r ID GROUP NUMBERS <<-EOF
	${LINE}
	EOF

	if [ -n "${ID}" ] && [ -n "${GROUP}" ] && [ -n "${NUMBERS}" ]; then
		GROUP_LC="$(echo "${GROUP}" | tr '[:upper:]' '[:lower:]')"

		FILE_IPV4="${DIR_CONF}/${GROUP_LC}.ipv4.${PROV}.conf"
		FILE_IPV6="${DIR_CONF}/${GROUP_LC}.ipv6.${PROV}.conf"
		truncate -s 0 "${FILE_IPV4}"
		truncate -s 0 "${FILE_IPV6}"

		for NUMBER in $(echo "${NUMBERS}" | tr "," "\n"); do
			echo "# AS${NUMBER}" | tee -a "${FILE_IPV4}" "${FILE_IPV6}" > /dev/null

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
done < "${FILE_AS_MAP}"

exit 0