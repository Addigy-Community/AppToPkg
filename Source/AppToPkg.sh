#!/usr/bin/env bash

###############################################################################
#   Copyright 2017 Benjamin Moralez                                           #
#                                                                             #
#   Licensed under the Apache License, Version 2.0 (the "License");           #
#   you may not use this file except in compliance with the License.          #
#   You may obtain a copy of the License at                                   #
#                                                                             #
#       http://www.apache.org/licenses/LICENSE-2.0                            #
#                                                                             #
#   Unless required by applicable law or agreed to in writing, software       #
#   distributed under the License is distributed on an "AS IS" BASIS,         #
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  #
#   See the License for the specific language governing permissions and       #
#   limitations under the License.                                            #
###############################################################################

function setVariables() {
    FILE_NAME="$(printf "$(basename "${f}")" | sed 's/\.[^.]*$//')"
    FILE_PATH=${f%/*}
    APP_VERSION=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleShortVersionString)
    SHORT_VERSION=$(echo ${APP_VERSION} | cut -d. -f-3)
    PKG_NAME="${FILE_NAME}-${SHORT_VERSION}.pkg"
    WORKING_DIRECTORY="$HOME/Documents/AppToPKG/${FILE_NAME} (${SHORT_VERSION})"
    ICON_NAME=$(/usr/bin/defaults read "${f}/Contents/Info.plist" CFBundleIconFile | sed -e 's/\.icns$//')
    APP_ICON="${f}/Contents/Resources/${ICON_NAME}.icns"
    ADDIGY_INFO="${WORKING_DIRECTORY}/Addigy Information.txt"
}

function makeContainers() {
    /bin/mkdir -p "${WORKING_DIRECTORY}"
    /usr/bin/touch "${ADDIGY_INFO}"
}

function printHeader() {
    printf "Use the following information for your Addigy Custom Software Wizard:\n\n" >> "${ADDIGY_INFO}"
    printf "Software Identifier: '%s'\n\n" "${FILE_NAME}" >> "${ADDIGY_INFO}"
    printf "Version: '%s'\n\n" "${SHORT_VERSION}" >> "${ADDIGY_INFO}"
    printf "DETAILS:\n" >> "${ADDIGY_INFO}"
    printf "Software Description: <ADD YOUR DESCRIPTION>\n" >> "${ADDIGY_INFO}"

}

function gatherICNS() {
    /usr/bin/sips -s format png "${APP_ICON}" --out "${WORKING_DIRECTORY}/${ICON_NAME}.png"
#    /bin/cp "${APP_ICON}" "${WORKING_DIRECTORY}"
    printf "Software Icon: " >> "${ADDIGY_INFO}"
    printf "'%s'\n" "${WORKING_DIRECTORY}/${ICON_NAME}.png" >> "${ADDIGY_INFO}"
}

function generatePKG() {
    /usr/bin/productbuild --component "${f}" /Applications "${WORKING_DIRECTORY}/${PKG_NAME}"
    printf "UPLOAD FILES: " >> "${ADDIGY_INFO}"
    printf "'%s'\n\n" "${WORKING_DIRECTORY}/${PKG_NAME}" >> "${ADDIGY_INFO}"
}

function generateInstallScript() {
    printf "INSTALLATION:\n" >> "${ADDIGY_INFO}"
    printf '/usr/sbin/installer -pkg "/Library/Addigy/ansible/packages/%s (%s)/%s" -target /\n\n' \
    "${FILE_NAME}" "${SHORT_VERSION}" "${PKG_NAME}" >> "${ADDIGY_INFO}"
}

function generateConditionalScript() {
    printf "CONDITIONS:\n" >> "${ADDIGY_INFO}"
    printf "Install on Success: True (on)\n" >> "${ADDIGY_INFO}"
    printf "Check for Application Version:\n" >> "${ADDIGY_INFO}"
    printf "\tSet: Success\n" >> "${ADDIGY_INFO}"
    printf "\tif the following installed application: /Applications/%s.app\n" \
    "${FILE_NAME}" >> "${ADDIGY_INFO}"
    printf "\thas version older than\n" >> "${ADDIGY_INFO}"
    printf "\tVersion: '%s'\n\n" "$APP_VERSION" >> "${ADDIGY_INFO}"
}

function generateUninstallScript() {
    printf "REMOVE SCRIPT:\n" >> "${ADDIGY_INFO}"
    printf '/bin/rm -Rf "/Applications/%s.app"\n' "${FILE_NAME}" >> "${ADDIGY_INFO}"
    printf '/bin/rm -Rf "/Library/Addigy/ansible/packages/%s (%s)"' \
    "${FILE_NAME}" "${SHORT_VERSION}" >> "${ADDIGY_INFO}"

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
