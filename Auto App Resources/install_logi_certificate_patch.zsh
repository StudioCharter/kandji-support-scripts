#!/bin/zsh
###################################################################################################
# Created by Matt Wilson | Iru, Inc. | Systems Engineering
###################################################################################################
# Created on 01/12/2026
###################################################################################################
# Software Information
###################################################################################################
#
# Version 1.0.0
#
# Custom script to run Logitech's certificate patch tool for Logi Options+.
# This script downloads and executes Logitech's official certificate patch tool to resolve the macOS
# certificate issue.
#
# The script does not reinstall the Auto App via Iru/MDM. It only applies the certificate patch
# tool provided by Logitech to fix the certificate validation issue.
#
# See https://support.logi.com/hc/en-us/articles/37493733117847-Options-and-G-HUB-macOS-Certificate-Issue
# for more information.
#
###################################################################################################
# License Information
###################################################################################################
# Copyright 2026 Iru, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
###################################################################################################

##############################
########## VARIABLES #########
##############################

###################################################################################################
########################################## DO NOT MODIFY ##########################################
###################################################################################################

logi_options_plus_path="/Applications/logioptionsplus.app"
tmp_dir="$(/usr/bin/mktemp -d)"
cert_patch_tool_dl="https://download01.logi.com/web/ftp/pub/techsupport/logi_certificate_patch.zip"
cert_patch_tool_zip_name="logi_certificate_patch.zip"
cert_patch_tool_name="Logi Certificate Patch.app"
cert_tool="${tmp_dir}/${cert_patch_tool_name}/Contents/MacOS/Logi Certificate Patch"

##############################
########## FUNCTIONS #########
##############################

##############################################
# Main function to handle script execution
# Validates appropriate run permissions (sudo)
# Checks to see if Logi Options+ is already
# installed
# If so, downloads and runs Logitech's certificate
# patch tool to fix the certificate issue.
# Returns:
#   Exit 0 on successful completion
#   Exit 1 if non-root exec or other error
##############################################
function main() {
    # Check invocation perms
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Script must be run with sudo or as root"
        exit 1
    fi

    # Is logioptionsplus.app installed?
    if [[ -d "${logi_options_plus_path}" ]]; then

        echo "${logi_options_plus_path:t} is installed."

        # Download and unzip cert patch tool
        echo "Downloading cert patch tool..."
        /usr/bin/curl -fsSL --retry 3 --retry-delay 2 -o "${tmp_dir}/${cert_patch_tool_zip_name}" "${cert_patch_tool_dl}"
        if [[ "$?" -ne 0 ]]; then
            echo "Failed to download cert patch tool. Exiting..."
            exit 1
        fi

        echo "Unzipping cert patch tool..."
        /usr/bin/unzip -q "${tmp_dir}/${cert_patch_tool_zip_name}" -d "${tmp_dir}"
        if [[ "$?" -ne 0 ]]; then
            echo "Failed to unzip cert patch tool. Exiting..."
            exit 1
        fi

        # Verify signature before running
        echo "Verifying signature of cert patch tool..."
        /usr/bin/codesign --verify --deep --strict --verbose=2 "${tmp_dir}/${cert_patch_tool_name}"
        if [[ "$?" -ne 0 ]]; then
            echo "Failed to verify signature of cert patch tool. Exiting..."
            exit 1
        fi

        # Run cert patch tool and validate it ran successfully
        echo "Running cert patch tool..."
        if ! "${cert_tool}" >/dev/null 2>&1; then
            echo "Cert patch tool failed to run. Exiting..."
            exit 1
        else
            echo "Cert patch tool ran successfully."
            echo "Cleaning up..."
            /bin/rm -rf "${tmp_dir}"
        fi

    else
        echo "${logi_options_plus_path:t} not installed. Exiting..."
    fi

    exit 0
}

###############
##### MAIN ####
###############
main
