#!/bin/sh

# temporary directory where will be downloaded git repo
TMP="/tmp" 

usage(){
echo "======USAGE====="
echo
echo "$ ./reapz-download.sh "reconstructmirror" <manifest.xml> <mirrordirectory>"
echo "to reconstruct a mirror of the archives contained in manifest.xml"
echo
echo "OR"
echo
echo "$ ./reapz-download.sh "processsources" <manifest.xml> <mirrordirectory> <outputdirectory>"
echo "to use a reconstructed mirror to generate sources ready for building"
echo
}

softwareheritageget(){
    CLONEURL="${1}"
    TARGZ="${2}"
	if [ -f "${TARGZ}" ]; then
		return 1
	fi

	if [ ! -d "${TMP}/softwareheritage" ]; then
		mkdir -p "${TMP}/softwareheritage"
	fi
	if [ ! -f "${TMP}/softwareheritage/repositoryID.txt" ]; then
		curl "https://archive.softwareheritage.org/browse/origin/directory/?origin_url=${CLONEURL}&visit_type=git" | grep -o 'visit=.*;' | cut -d = -f 2-3 | cut -d ';' -f 1 > ${TMP}/softwareheritage/repositoryID.txt
		if [ "$?" != 0 ]; then
			if [ -f "${TMP}/softwareheritage/repositoryID.txt" ]; then
				rm -f "${TMP}/softwareheritage/repositoryID.txt"
			fi
			return 1
		fi
	fi

	if [ ! -f "${TMP}/softwareheritage/jsonresponse.txt" ]; then
		curl -XPOST "https://archive.softwareheritage.org/api/1/vault/git-bare/$(cat "${TMP}/softwareheritage/repositoryID.txt")/" > ${TMP}/softwareheritage/jsonresponse.txt
		if [ "$?" != 0 ]; then
			if [ -f "${TMP}/softwareheritage/jsonresponse.txt" ]; then
				rm -f "${TMP}/softwareheritage/jsonresponse.txt"
			fi
			return 1
		fi
	fi

	if [ ! -f "${TARGZ}" ]; then
		curl -L -o "${TARGZ}" "$(printf "%s" "$(cat ${TMP}/softwareheritage/jsonresponse.txt)" | grep -o '"fetch_url":".*"' | cut -d '"' -f 4)"
		if [ "$?" != 0 ]; then
			if [ -f "${TARGZ}" ]; then
				rm -f "${TARGZ}"
			fi
			return 1
		else
			rm -rf "${TMP}/softwareheritage"
			return 0
		fi
	else
		rm -rf "${TMP}/softwareheritage"
		return 0
	fi
}

deleteline(){
	ORIGINS="${1}"
	PROJECTNAME="${2}"
	pos="$(expr $(grep -n "^${PROJECTNAME}\s.*" "${ORIGINS}" | cut -d : -f 1))"
	head -n $(expr ${pos} - 1) "${ORIGINS}"
	tail -n $(expr $(cat "${ORIGINS}" | wc -l) - ${pos}) "${ORIGINS}"
}


if [ ! -f "$2" ]; then
	usage
	exit 1
fi

if [ ! -d "$3" ]; then
	usage
	exit 1
fi

if [ "$1" = "processsources" ]; then
	if [ ! -d "$4" ]; then
		usage
		exit 1
	fi
elif [ "$1" != "reconstructmirror" ]; then
	usage
	exit 1
fi

mirrordirectory="$(realpath "${3}")"

outputdirectory=""
if [ "$4" != "" ]; then
outputdirectory="$(realpath "${4}")"
fi

old_ifs="$IFS"
export IFS='<'
startofmanifest=0
onremote=0
defaultrevision=""
defaultremote=""
remotes=""
projectname=""
projectpath=""
projectremote=""
projectgroups=""

processxml(){
	OPTION="${1}"
	MANIFEST="${2}"
	MIRRORDIRECTORY="${3}"
	REALDIRMANIFEST="${4}"

	for line in $(cat "${MANIFEST}"); do
		#echo "$line<<<<"

		if [ "$(echo "$line" | grep "^manifest>.*")" != "" ]; then
			startofmanifest=1
		fi

		if [ "${startofmanifest}" = 1 ]; then
			if [ "$(echo "$line" | grep "^include .*")" != "" ]; then
				toinclude="$(echo $line | grep -o 'name=".*"')"
				if [ "$toinclude" != "" ]; then
					toinclude="$(printf "%s" "${toinclude}" | cut -d '"' -f 2)"
				fi
				if [ "$toinclude" != "" ]; then
					processxml "${OPTION}" "${REALDIRMANIFEST}/${toinclude}" "${MIRRORDIRECTORY}" "${REALDIRMANIFEST}"
				fi
			elif [ "$(echo "$line" | grep "^remote .*")" != "" ]; then
				onremote=1
				remotename="$(echo $line | grep -o 'name=".*"')"
				if [ "$remotename" != "" ]; then
					remotename="$(printf "%s" "${remotename}" | cut -d '"' -f 2)"
				fi

				remotefetch="$(echo $line | grep -o 'fetch=".*"')"
				if [ "$remotefetch" != "" ]; then
					remotefetch="$(printf "%s" "${remotefetch}" | cut -d '"' -f 2)"
				fi

				remoterevision="$(echo $line | grep -o 'revision=".*"')"
				if [ "$remoterevision" != "" ]; then
					remoterevision="$(printf "%s" "${remoterevision}" | cut -d '"' -f 2)"
				fi
				#echo "${remotename}" "${remotefetch}" "${remoterevision}"

				remotes="$(printf "%s\n%s\t%s\t%s" "${remotes}" "${remotename}" "${remotefetch}" "${remoterevision}")"
			elif [ "$(echo "$line" | grep "^default .*")" != "" ]; then
				defaultrevision="$(echo $line | grep -o 'revision=".*"')"
				if [ "$defaultrevision" != "" ]; then
					defaultrevision="$(printf "%s" "${defaultrevision}" | cut -d '"' -f 2)"
				fi

				defaultremote="$(echo $line | grep -o 'remote=".*"')"
				if [ "$defaultremote" != "" ]; then
					defaultremote="$(printf "%s" "${defaultremote}" | cut -d '"' -f 2)"
				fi
				#echo "DEFAULTREMOTE="${defaultremote}""
			elif [ "$(echo "$line" | grep "^project .*")" != "" ]; then
				if [ "$onremote" = "1" ]; then
					remotes="$(printf "%s\n" "${remotes}")"
					onremote=2
				fi

				projectname=""
				projectpath=""
				projectremote=""
				projectgroups=""

				#echo "$line"
				projectname="$(echo $line | grep -o 'name=".*"')"
				if [ "$projectname" != "" ]; then
					projectname="$(printf "%s" "${projectname}" | cut -d '"' -f 2)"
				fi


				projectpath="$(echo $line | grep -o 'path=".*"')"
				if [ "$projectpath" != "" ]; then
					projectpath="$(printf "%s" "${projectpath}" | cut -d '"' -f 2)"
				fi


				projectremote="$(echo $line | grep -o 'remote=".*"')"
				if [ "$projectremote" != "" ]; then
					projectremote="$(printf "%s" "${projectremote}" | cut -d '"' -f 2)"
				fi
				if [ "$projectremote" = "" ]; then
					projectremote="${defaultremote}"
				fi

				projectgroups="$(echo $line | grep -o 'groups=".*"')"
				if [ "$projectgroups" != "" ]; then
					projectgroups="$(printf "%s" "${projectgroups}" | cut -d '"' -f 2)"
				fi

				projectclonedepth="$(echo $line | grep -o 'clone-depth=".*"')"
				if [ "$projectclonedepth" != "" ]; then
					projectclonedepth="$(printf "%s" "${projectclonedepth}" | cut -d '"' -f 2)"
				fi

				if [ "${projectremote}" != "" ]; then
					remoteline="$(printf "%s" "${remotes}" | grep "^${projectremote}.*$")"
					clonedir="$(printf "%s" "${remoteline}" | cut -f 2)"
					cloneurl="${clonedir}${projectname}" #this may have to have a / put in
					clonedir="$(dirname "${projectname}")"
					clonetag="$(printf "%s" "${remoteline}" | cut -f 3)"
					if [ "${clonetag}" = "" ]; then
						clonetag="${defaultrevision}"
					fi

					if [ "${OPTION}" = "sync" ]; then
						mkdir "${TMP}/replicant_clone"
						mkdir -p "${mirrordirectory}/${clonedir}"
						#echo "cd "${mirrordirectory}/${clonedir}""
						cd "${TMP}/replicant_clone"
						if [ ! -f "$(basename "${projectname}").tar.gz" ]; then
							retries=0
							while true; do
								git clone --mirror ${cloneurl} $(basename "$projectname")
								if [ "$?" = "0" ]; then
									if [ -d "$(basename "${projectname}")" ]; then
										tar -czf "$(basename "${projectname}").tar.gz" "$(basename "${projectname}")"
										if [ "$?" = "0" ]; then
											rm -rf "$(basename "${projectname}")"
										else
											if [ -f "$(basename "${projectname}").tar.gz" ]; then
												rm -rf "$(basename "${projectname}")".tar.gz
											fi
										fi
									fi

									rm -rf "$(basename "${projectname}")"

									checkforline="$(grep -n "^${clonedir}/$(basename "${projectname}")\s.*" "${mirrordirectory}/ORIGINS.TXT")"
									if [ "${checkforline}" = "" ]; then
										#if there is no record of the file, then we need to add it
										if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
											rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
										fi
										mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
										printf "%s/%s\t%s\tvanilla\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
									else
										if [ "$(printf "%s" "$checkforline" | cut -f 3)" = "softwareheritage" ]; then
											#if the archive we have freshly downloaded is from vanilla repository, remove the old software heritage copy and update it
											if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
												rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
											fi
											mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
											deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
											printf "%s/%s\t%s\tvanilla\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"

										else
											if [ "$(printf "%s" "$checkforline" | cut -f 2)" != "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" ]; then
												#if there is file corruption, use the newer version
												if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
													rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												fi
												mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
												printf "%s/%s\t%s\tvanilla\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
											elif [ "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" != "$(sha512sum "$(basename "${mirrordirectory}/${clonedir}/${projectname}").tar.gz" | cut -d ' ' -f 1)" ]; then
												if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
													rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												fi
												mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
												printf "%s/%s\t%s\tvanilla\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
											fi
											
										fi
									fi
									break
								else
									if [ -d "$(basename "${projectname}")" ]; then
										rm -rf "$(basename "${projectname}")"
									fi
									retries="$(expr ${retries} + 1)"
									sleep 60
								fi
								if [ "${retries}" = "10" ]; then
									break
								fi
							done

							if [ "${retries}" = "10" ]; then
								retries=0
								while true; do
									softwareheritageget "${cloneurl}" "$(basename "$projectname").tar.gz"
									if [ "$?" = "0" ]; then
										checkforline="$(grep -n "^${clonedir}/$(basename "${projectname}")\s.*" "${mirrordirectory}/ORIGINS.TXT")"
										if [ "${checkforline}" = "" ]; then
											checkforline="$(grep -n "^${clonedir}/$(basename "${projectname}")\s.*" "${mirrordirectory}/ORIGINS.TXT")"
											if [ "${checkforline}" = "" ]; then
												#if there is no record of the file, then we need to add it
												if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
													rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												fi
												mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
												printf "%s/%s\t%s\tsoftwareheritage\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
											else
												if [ "$(printf "%s" "$checkforline" | cut -f 3)" = "softwareheritage" ]; then
													#if the archive we have freshly downloaded is from vanilla repository, remove the old software heritage copy and update it
													if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
														rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
													fi
													mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
													deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
													printf "%s/%s\t%s\tsoftwareheritage\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
	
												else
													if [ "$(printf "%s" "$checkforline" | cut -f 2)" != "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" ]; then
														#if there is file corruption, use the newer version
														if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
															rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
														fi
														mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
														deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
														printf "%s/%s\t%s\tsoftwareheritage\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
													elif [ "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" != "$(sha512sum "$(basename "${mirrordirectory}/${clonedir}/${projectname}").tar.gz" | cut -d ' ' -f 1)" ]; then
														if [ -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz" ]; then
															rm -f "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
														fi
														mv "$(basename "${projectname}").tar.gz" "${mirrordirectory}/${clonedir}/$(basename "${projectname}").tar.gz"
														deleteline "${mirrordirectory}/ORIGINS.TXT" "${clonedir}/$(basename "${projectname}")"
														printf "%s/%s\t%s\tsoftwareheritage\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
													fi
												
												fi
											fi
										fi
										break
									else
										if [ -d "$(basename "${projectname}")" ]; then
											rm -rf "$(basename "${projectname}")"
										fi
										retries="$(expr ${retries} + 1)"
										sleep 60
									fi
									if [ "${retries}" = "10" ]; then
										echo "UH OH. UNABLE TO DOWNLOAD FROM VANILLAS OR MIRRORS, EXITING."
										exit 1
									fi
								done
							fi
						fi
	
					#echo "git clone ${cloneurl} ${clonetag}"
	
	
					elif [ "${OPTION}" = "reconstructmirror" ]; then
							mkdir -p "${mirrordirectory}/${clonedir}"
						cd "${mirrordirectory}/${clonedir}"
						if [ ! -f "$(basename "${projectname}").tar.gz" ]; then
							retries=0
							while true; do
								git clone --mirror ${cloneurl} $(basename "$projectname")
								if [ "$?" = "0" ]; then
									if [ -d "$(basename "${projectname}")" ]; then
										tar -czf "$(basename "${projectname}").tar.gz" "$(basename "${projectname}")"
										if [ "$?" = "0" ]; then
											rm -rf "$(basename "${projectname}")"
											printf "%s/%s\t%s\tvanilla\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
										else
											if [ -f "$(basename "${projectname}").tar.gz" ]; then
												rm -rf "$(basename "${projectname}")".tar.gz
											fi
										fi
											
									fi
									rm -rf "$(basename "${projectname}")"
									break
								else
									if [ -d "$(basename "${projectname}")" ]; then
										rm -rf "$(basename "${projectname}")"
									fi
									retries="$(expr ${retries} + 1)"
									sleep 60
								fi
								if [ "${retries}" = "10" ]; then
									break
								fi
							done
	
							if [ "${retries}" = "10" ]; then
								retries=0
								while true; do
									softwareheritageget "${cloneurl}" "$(basename "$projectname").tar.gz"
									if [ "$?" = "0" ]; then
										printf "%s/%s\t%s\tsoftwareheritage\t%s\n" "${clonedir}" "$(basename "${projectname}")" "$(sha512sum "$(basename "${projectname}").tar.gz" | cut -d ' ' -f 1)" "$(date)" >> "${mirrordirectory}/ORIGINS.TXT"
										break
									else
										if [ -d "$(basename "${projectname}")" ]; then
											rm -rf "$(basename "${projectname}")"
										fi
										retries="$(expr ${retries} + 1)"
										sleep 60
									fi
									if [ "${retries}" = "10" ]; then
										echo "UH OH. UNABLE TO DOWNLOAD FROM VANILLAS OR MIRRORS, EXITING."
										exit 1
									fi
								done
							fi
						fi
	
					#echo "git clone ${cloneurl} ${clonetag}"
					elif [ "${OPTION}" = "processsources" ]; then
						mkdir -p "${outputdirectory}/$(dirname "${projectpath}")"
						if [ -d "${outputdirectory}/$(dirname "${projectpath}")" ]; then
							mkdir -p ${TMP}/replicant_project_extract
							if [ ! -d "${TMP}/replicant_project_extract" ]; then
								echo "Could not create ${TMP}/replicant_project_extract dir , exiting."
								exit 1
							fi
	
							if [ -f "${mirrordirectory}/${clonedir}/$(basename "$projectname").tar.gz" ]; then
								cd "${TMP}/replicant_project_extract"
								tar -xf "${mirrordirectory}/${clonedir}/$(basename "$projectname").tar.gz"
								echo "cloning "$(find ${TMP}/replicant_project_extract -mindepth 1 -maxdepth 1 -type d | head -n 1)" to "${outputdirectory}/${projectpath}""
								if [ "$projectclonedepth" = "" ]; then
									git clone "$(find ${TMP}/replicant_project_extract -mindepth 1 -maxdepth 1 -type d | head -n 1)" "${outputdirectory}/${projectpath}"
								else
									git clone --depth ${projectclonedepth} "$(find ${TMP}/replicant_project_extract -mindepth 1 -maxdepth 1 -type d | head -n 1)" "${outputdirectory}/${projectpath}"
								fi
								if [ "$?" != 0 ]; then
									echo "Move operation failed, exiting"
									if [ -d "${outputdirectory}/${projectpath}" ]; then
										rm -rf "${outputdirectory}/${projectpath}"
									fi
									exit 1
								fi
								rm -rf ${TMP}/replicant_project_extract
	
								cd "${outputdirectory}/${projectpath}"
								echo "checking out tag ${clonetag}"
								git checkout "${clonetag}" 2>/dev/null 1>/dev/null
								fi
						else
							echo "The directory "${outputdirectory}/${clonedir}" does not exist, exiting."
							exit 1
						fi
					fi
				#echo "git clone --mirror"
				fi
	
	
				#echo "${projectgroups}"
				#echo "${projectname} ${projectpath} ${projectremote} ${projectgroups}"
				elif [ "$(echo "$line" | grep "^copyfile .*")" != "" ] && [ "${OPTION}" = "processsources" ]; then
	
				#echo "$line"
				copyfilesrc="$(echo $line | grep -o 'src=".*"')"
				if [ "$copyfilesrc" != "" ]; then
						copyfilesrc="$(printf "%s" "${copyfilesrc}" | cut -d '"' -f 2)"
				fi
	
		
			copyfiledest="$(echo $line | grep -o 'dest=".*"')"
				if [ "$copyfiledest" != "" ]; then
					copyfiledest="$(printf "%s" "${copyfiledest}" | cut -d '"' -f 2)"
				fi
	
				if [ "${copyfilesrc}" != "" ] && [ "${copyfiledest}" != "" ]; then
					cd "${outputdirectory}/${projectpath}"
					echo "copying ${copyfilesrc} to ${copyfiledest}"
					cp -a "${copyfilesrc}" "${outputdirectory}/${copyfiledest}"
				fi

			fi
			echo
		fi
	done
	export IFS="$old_ifs"
}

processxml "$1" "$2" "$3" "$(dirname "$(realpath $2)")"
