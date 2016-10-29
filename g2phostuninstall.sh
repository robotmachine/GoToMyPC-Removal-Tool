#!/bin/bash


# =================================================================================================
# Script variables
# =================================================================================================

logPath="/Library/Logs/com.citrixonline.GoToMyPC/Uninstall"
logFilePath="$logPath/uninstall.log"
logTempFilePath="$logFilePath.tmp"
truncateLogLines=3000   # ~100KB given an average log
unloadServices=1
removeApplication=1



# =================================================================================================
# Functions
# =================================================================================================

# -------------------------------------------------------------------------------------------------
# checkPermissions
# -------------------------------------------------------------------------------------------------
checkPermissions() {
    if [[ $(/usr/bin/id -u) != 0 ]] ; then
        # Show a warning to the user, but try to execute the script anyway
        /bin/echo
        /bin/echo "WARNING: You must have root permissions to successfully execute this script!"
        /bin/echo
    fi
}

# -------------------------------------------------------------------------------------------------
# initLog
# -------------------------------------------------------------------------------------------------
initLog() {
    # Ensure external variables are initialized
    : ${logPath:?}
    : ${logFilePath:?}
    : ${logTempFilePath:?}
    
    /bin/mkdir -p "$logPath"
 
    if [ -f "$logFilePath" ] ; then
        # Truncate log based on line count
        /bin/mv -f "$logFilePath" "$logTempFilePath"
        /usr/bin/tail -n $truncateLogLines "$logTempFilePath" >> "$logFilePath"
        /bin/rm -rf "$logTempFilePath"
    fi
    
    # Print out the effective username (should be root) and timestamp
    /bin/echo "----------------------------------------------------------------------------" >> "$logFilePath"
    /bin/echo -n "GoToMyPC Uninstall started by " >> "$logFilePath"
    /usr/bin/id -un | /usr/bin/tr "\n" " " >> "$logFilePath"
    /bin/echo -n "on " >> "$logFilePath"
    /bin/date >> "$logFilePath"
}

# -------------------------------------------------------------------------------------------------
# logAndEcho
# -------------------------------------------------------------------------------------------------
logAndEcho() {
    if [[ $# == 2 && "$1" == "-n" ]] ; then
        /bin/echo -n "$2" | /usr/bin/tee -a "$logFilePath" 2> /dev/null
    else
        /bin/echo "$1" | /usr/bin/tee -a "$logFilePath" 2> /dev/null
    fi
}

# -------------------------------------------------------------------------------------------------
# auditUninstall
# -------------------------------------------------------------------------------------------------
auditUninstall() {
    # Audit the major components
    logAndEcho "Auditing uninstall..."
    
    _passed=1
    
    if [ -e "/Library/Application Support/CitrixOnline/GoToMyPC.app" ] ; then
        _passed=0
        logAndEcho "...Main bundle exists..."
    fi
    
    if [ -e "/Library/LaunchAgents/com.citrixonline.GoToMyPC.LaunchAgent.plist" ] ; then
        _passed=0
        logAndEcho "...agent plist exists..."
    fi
    
    if [ -e "/Library/LaunchDaemons/com.citrixonline.GoToMyPC.CommAgent.plist" ] ; then
        _passed=0
        logAndEcho "...daemon plist exists..."
    fi
    
    if [ -e "/Library/PreferencePanes/GoToMyPC.prefPane" ] ; then
        _passed=0
        logAndEcho "...preference pane exists..."
    fi

    if [ -e "/Applications/GoToMyPC Starter.app/" ] ; then
        _passed=0
        logAndEcho "...GoToMyPC Starter.app  exists..."
    fi

    logAndEcho "...audit complete."
    logAndEcho

    if [[ $_passed == 1 ]] ; then
        logAndEcho "  --> Uninstall Successful <--"
    else
        logAndEcho "  *** One or more uninstall steps failed ***"
    fi
    
    logAndEcho
}

# =================================================================================================
# remove a file for all the users, the file name needs to be passed as first parameter
# =================================================================================================
removeFileForAllUsers() {
    for _user in $(users) ; do
        _filename="$1"
        if [ -f "$_filename" ] ; then
            # file exists
            logAndEcho "  Removing $1 file for user $_user..."
            # Enable write permissions for admin group (by default, user prefs file can only be accessed by user)
            /usr/sbin/chown -f :staff "$_filename"
            /bin/chmod -f g+w "$_filename"
            /bin/rm -f "$_filename"
        fi
    done
}

# =================================================================================================
# Script body
# =================================================================================================

checkPermissions
initLog

logAndEcho "Uninstalling GoToMyPC..."


if [ "$1" == "uninstallServiceOnly" -o "$1" == "removePreviousService" ] ; then
    # uninstall and remove previous are the same in current uninstall flow 
    removeApplication=0
fi


if [ $unloadServices != 0 ] ; then

    logAndEcho "Unloading services..."

    for _user in $(users) ; do

        logAndEcho "  Unloading agent for user $_user..."
        _launchd_socket=$(/usr/bin/stat -f "%Su %N" /tmp/launchd*/sock | /usr/bin/grep $_user | /usr/bin/awk '{print $2}')
        logAndEcho "    _launchd_socket=${_launchd_socket}"
        _uid=$(/bin/ps -U $_user -o uid,pid,comm | /usr/bin/grep /Finder.app | /usr/bin/awk '{print $1}')
        logAndEcho "    _uid=${_uid}"
        export LAUNCHD_SOCKET=$_launchd_socket
        
		logAndEcho "    Executing: /bin/launchctl asuser $_uid chroot -u $_user / /bin/launchctl remove com.citrixonline.GoToMyPC.LaunchAgent"
        /bin/launchctl asuser $_uid chroot -u $_user / /bin/launchctl remove com.citrixonline.GoToMyPC.LaunchAgent 2>&1 | /usr/bin/tee -a "$logFilePath" 2> /dev/null

        logAndEcho "    Executing: /bin/launchctl asuser $_uid  chroot -u $_user / /bin/launchctl remove com.cloud.CloudShellExt"
        /bin/launchctl asuser $_uid chroot -u $_user / /bin/launchctl remove com.cloud.CloudShellExt 2>&1 | /usr/bin/tee -a "$logFilePath" 2> /dev/null

    done

    unset LAUNCHD_SOCKET

    logAndEcho "  Unloading daemon..."
    /bin/launchctl remove com.citrixonline.GoToMyPC.CommAgent 2>&1 | /usr/bin/tee -a "$logFilePath" 2> /dev/null

    # give the services time to quit
    for ((i = 0; i < 5; i++)) ; do
        res=$(/bin/launchctl list | /usr/bin/awk '$3 == "com.citrixonline.GoToMyPC.CommAgent" {print $3}')
        if [ "$res" == "" ] ; then
            break
        fi
        sleep 2
    done
fi


if [ $removeApplication != 0 ] ; then
    logAndEcho "Removing application..."

    # Remove SSUIH pref for each logged in user
    logAndEcho "  Removing user preferences..."
	removeFileForAllUsers "/Users/$_user/Library/Preferences/com.citrixonline.GoToMyPC.SystemStatusUIHost.plist"

    logAndEcho "  Removing application files..."
    /bin/rm -rf /Library/LaunchAgents/com.citrixonline.GoToMyPC.LaunchAgent.plist
    /bin/rm -rf /Library/LaunchDaemons/com.citrixonline.GoToMyPC.CommAgent.plist
    /bin/rm -rf /Library/Preferences/com.citrixonline.GoToMyPC.plist
    /bin/rm -rf /Library/PreferencePanes/GoToMyPC.prefPane
    /bin/rm -rf /Library/Receipts/GoToMyPC.pkg
    /bin/rm -rf "/Applications/GoToMyPC Starter.app"

    # In Mac OS X 10.9, the plist remains cached even after file delete. this interferes with subsequent install.
    sleep 10 # it takes a short while for the plist to go
    killall -z cfprefsd

    # G2P v7 Beta 1 mis-spelled the trigger file with citrixlonline - leaving removal to keep things clean
    /bin/rm -rf /var/tmp/com.citrixlonline.GoToMyPC_*.procfactorylaunchagent.trigger
    /bin/rm -rf /var/tmp/com.citrixonline.GoToMyPC_*.procfactorylaunchagent.trigger
    /bin/rm -rf "/Library/Application Support/CitrixOnline/GoToMyPC.app"
    
    if [[ -d "/Library/Application Support/CitrixOnline" && "$(ls '/Library/Application Support/CitrixOnline')" == "" ]] ; then
        /bin/rm -rf "/Library/Application Support/CitrixOnline"
    fi
fi

logAndEcho "...done."
logAndEcho

auditUninstall

exit 0
