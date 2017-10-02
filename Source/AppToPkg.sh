#!/bin/bash

# AppToPkg is designed to automate aspects of the deployment of .apps in Addigy
# which are prone to human error. Passing a .app file path as an argument in
# AppToPkg will generate an installer, gather likely candidates for an icon in
# Addigy custom software, and generate install, conditional, and uninstall scripts
# to be used in Addigy's custom software interface.

function setVariables() {
    fileName=$(printf "${f##*/}" | sed 's/\.[^.]*$//' )
#    echo "$fileName"
    filePath=${f%/*}
#    echo "$filePath"
    appVersion=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleShortVersionString)
#    echo "$appVersion"
    shortVersion=$(echo ${appVersion} | cut -d. -f-3)
#    echo "$shortVersion"
    pkgName="${fileName}-${shortVersion}.pkg"
#    echo "$pkgName"
    workingDir="$HOME/Documents/AppToPKG/${fileName} (${shortVersion})"
#    echo "$workingDir"
    appIconName=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleIconFile | sed -e 's/\.icns$//')
    appIcon="${f}/Contents/Resources/${appIconName}.icns"
    addigyInformation="${workingDir}/Addigy Information.txt"
#    echo "$addigyInformation"
}

function makeContainers() {
    /bin/mkdir -p "${workingDir}"
    /usr/bin/touch "${addigyInformation}"
}

function printHeader() {
    printf "Use the following information for your Addigy Custom Software Wizard:\n\n" >> "${addigyInformation}"
    printf "Software Identifier: '%s'\n\n" "${fileName}" >> "${addigyInformation}"
    printf "Version: '%s'\n\n" "${shortVersion}" >> "${addigyInformation}"
    printf "DETAILS:\n" >> "${addigyInformation}"
    printf "Software Description: <ADD YOUR DESCRIPTION>\n" >> "${addigyInformation}"

}

function gatherICNS() {
    /bin/cp "${appIcon}" "${workingDir}"
    printf "Software Icon: " >> "${addigyInformation}"
    printf "'%s'\n" "${workingDir}/${appIconName}.icns" >> "${addigyInformation}"
    printf "(If no icon shows, then the app stored its icon in an unconventional manner.)\n\n" \
    >> "${addigyInformation}"
}

function generatePKG() {
    /usr/bin/productbuild --component "${f}" /Applications "${workingDir}/${pkgName}"
    printf "UPLOAD FILES: " >> "${addigyInformation}"
    printf "'%s'\n\n" "${workingDir}/${pkgName}" >> "${addigyInformation}"
}

function generateInstallScript() {
    printf "INSTALLATION:\n" >> "${addigyInformation}"
    printf '/usr/sbin/installer -pkg "/Library/Addigy/ansible/packages/%s (%s)/%s" -target /\n\n' \
    "${fileName}" "${shortVersion}" "${pkgName}" >> "${addigyInformation}"
}

function generateConditionalScript() {
    printf "CONDITIONS:\n" >> "${addigyInformation}"
    printf "Install on Success: True (on)\n" >> "${addigyInformation}"
    printf "Check for Application Version:\n" >> "${addigyInformation}"
    printf "\tSet: Success\n" >> "${addigyInformation}"
    printf "\tif the following installed application: /Applications/%s.app\n" \
    "${fileName}" >> "${addigyInformation}"
    printf "\thas version older than\n" >> "${addigyInformation}"
    printf "\tVersion: '%s'\n\n" "$appVersion" >> "${addigyInformation}"
}

function generateUninstallScript() {
    printf "REMOVE SCRIPT:\n" >> "${addigyInformation}"
    printf '/bin/rm -Rf "/Applications/%s.app"\n' "${fileName}" >> "${addigyInformation}"
    printf '/bin/rm -Rf "/Library/Addigy/ansible/packages/%s (%s)"' \
    "${fileName}" "${shortVersion}" >> "${addigyInformation}"

}

for f in "$@"; do
    setVariables
    makeContainers
    printHeader
    gatherICNS
    generatePKG
    generateInstallScript
    generateConditionalScript
    generateUninstallScript
done

exit 0
