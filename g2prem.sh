#!/bin/bash
#    @@@@@@@@           @@@@@@@@@@          @@@@     @@@@          @@@@@@@    @@@@@@ 
#   @@//////@@         /////@@///          /@@/@@   @@/@@  @@   @@/@@////@@  @@////@@
#  @@      //   @@@@@@     /@@      @@@@@@ /@@//@@ @@ /@@ //@@ @@ /@@   /@@ @@    // 
# /@@          @@////@@    /@@     @@////@@/@@ //@@@  /@@  //@@@  /@@@@@@@ /@@       
# /@@    @@@@@/@@   /@@    /@@    /@@   /@@/@@  //@   /@@   /@@   /@@////  /@@       
# //@@  ////@@/@@   /@@    /@@    /@@   /@@/@@   /    /@@   @@    /@@      //@@    @@
#  //@@@@@@@@ //@@@@@@     /@@    //@@@@@@ /@@        /@@  @@     /@@       //@@@@@@ 
#   ////////   //////      //      //////  //         //  //      //         //////  
#  @@@@@@@                                                    @@   @@@@@@@@@@                    @@
# /@@////@@                                                  /@@  /////@@///                    /@@
# /@@   /@@   @@@@@  @@@@@@@@@@   @@@@@@  @@    @@  @@@@@@   /@@      /@@      @@@@@@   @@@@@@  /@@
# /@@@@@@@   @@///@@//@@//@@//@@ @@////@@/@@   /@@ //////@@  /@@      /@@     @@////@@ @@////@@ /@@
# /@@///@@  /@@@@@@@ /@@ /@@ /@@/@@   /@@//@@ /@@   @@@@@@@  /@@      /@@    /@@   /@@/@@   /@@ /@@
# /@@  //@@ /@@////  /@@ /@@ /@@/@@   /@@ //@@@@   @@////@@  /@@      /@@    /@@   /@@/@@   /@@ /@@
# /@@   //@@//@@@@@@ @@@ /@@ /@@//@@@@@@   //@@   //@@@@@@@@ @@@      /@@    //@@@@@@ //@@@@@@  @@@
# //     //  ////// ///  //  //  //////     //     //////// ///       //      //////   //////  /// 
# GoToMyPC Removal Tool v.1.0.0
#
# Description:
# Removes GoToMyPC Host and client files.
#
# Homepage:
# https://github.com/robotmachine/GoToMyPC-Removal-Tool
#
# Maintained by:
# Brian A Carter (robotmachine@gmail.com)
#
#  @@@@@@                   @@         
# /@////@@           @@@@@ //          
# /@   /@@   @@@@@  @@///@@ @@ @@@@@@@ 
# /@@@@@@   @@///@@/@@  /@@/@@//@@///@@
# /@//// @@/@@@@@@@//@@@@@@/@@ /@@  /@@
# /@    /@@/@@////  /////@@/@@ /@@  /@@
# /@@@@@@@ //@@@@@@  @@@@@ /@@ @@@  /@@
# ///////   //////  /////  // ///   // 
#
## Functions
# Creates a local function to move to trash instead of permanently deleting.
function trash () {
  local path
  for path in "$@"; do
    # ignore any arguments
    if [[ "$path" = -* ]]; then :
    else
      # remove trailing slash
      local mindtrailingslash=${path%/}
      # remove preceding directory path
      local dst=${mindtrailingslash##*/}
      # append the time if necessary
      while [ -e ~/.Trash/"$dst" ]; do
        dst="`expr "$dst" : '\(.*\)\.[^.]*'` `date +%H-%M-%S`.`expr "$dst" : '.*\.\([^.]*\)'`"
      done
      mv "$path" ~/.Trash/"$dst" && echo "$path moved to trash" || echo "Failed to trash $path"
    fi
  done
}
#
# Sets variables for the script.
logFile=~/Library/Logs/com.citrixonline.g2prem.log
echo "GoToMyPC Removal Tool .:. Log started $(date)\n" > $logFile
# Remove the temp directory when the script exits even if due to error
cleanup() {
	echo "Cleanup Triggered" >> $logFile 2>&1
	rm ~/Desktop/.g2puninstall.sh >> $logFile 2>&1
}
trap "cleanup" EXIT

# Commenting in the log
logcomment() {
	echo "" >> $logFile
	echo "### $@ ###" >> $logFile
}

# Prompt user to select a product.
userSelect=$(osascript <<'END'
on run {}
	set productList to {"Host", "Client"}
	set userSelect to {choose from list productList with title "GoToMyPC Removal Tool" with prompt "Please select an option." default items "Host"}
	return userSelect
end run
END)
# Catch if the user hits cancel.
if [[ "$userSelect" == false ]] ; then
	exit
fi

#  @@      @@                    @@  
# /@@     /@@                   /@@  
# /@@     /@@  @@@@@@   @@@@@@ @@@@@@
# /@@@@@@@@@@ @@////@@ @@//// ///@@/ 
# /@@//////@@/@@   /@@//@@@@@   /@@  
# /@@     /@@/@@   /@@ /////@@  /@@  
# /@@     /@@//@@@@@@  @@@@@@   //@@ 
# //      //  //////  //////     //  

if [[ "$userSelect" == "Host" ]]; then
	logcomment "GoToMyPC Host Selected"
	if [[ -e "/Library/Application Support/CitrixOnline/GoToMyPC.app/Contents/Helpers/uninstall" ]]; then
		osascript -e 'do shell script "sudo sh /Library/Application Support/CitrixOnline/GoToMyPC.app/Contents/Helpers/uninstall" with administrator privileges'
		exit
	else
		curl -o ~/Desktop/.g2puninstall https://raw.githubusercontent.com/robotmachine/GoToMyPC-Removal-Tool/master/g2phostuninstall.sh || osascript -e 'display notification "Unable to retrieve uninstall tool." with title "GoToMyPC Removal Tool"'
		osascript -e 'do shell script "sudo sh ~/Desktop/.g2puninstall.sh" with administrator privileges'
		rm ~/Desktop/.g2puninstall.sh
		exit
	fi
fi
#    @@@@@@   @@ @@                    @@  
#   @@////@@ /@@//                    /@@  
#  @@    //  /@@ @@  @@@@@  @@@@@@@  @@@@@@
# /@@        /@@/@@ @@///@@//@@///@@///@@/ 
# /@@        /@@/@@/@@@@@@@ /@@  /@@  /@@  
# //@@    @@ /@@/@@/@@////  /@@  /@@  /@@  
#  //@@@@@@  @@@/@@//@@@@@@ @@@  /@@  //@@ 
#   //////  /// //  ////// ///   //    //  
if [[ "$userSelect" == "Client" ]]; then
	logcomment "Delete Plists"
	find ~/Library/Preferences -iname "*gotomypc*" -print0 | xargs -0 -I {} trash {} >> $logFile 2>&1
	logcomment "Trash using MDFind"
	mdfind kind:app gotomypc | grep -iv Removal | xargs -I {} trash {} >> $logFile 2>&1
	appLocations=("/Applications" "$HOME/Applications" "$HOME/Desktop" "$HOME/Library/Application Support/CitrixOnline")
	for x in ${locations[@]}
	do
		trash "$x"/GoToMyPC* >> $logFile 2>&1
	done
fi
