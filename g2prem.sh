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
# GoToMyPC Removal Tool v.1.0.1
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
	curl -o ~/Desktop/.g2puninstall.sh https://raw.githubusercontent.com/robotmachine/GoToMyPC-Removal-Tool/master/g2phostuninstall.sh >> $logFile 2>&1
	osascript -e 'do shell script "sudo sh $HOME/Desktop/.g2puninstall.sh >> $HOME/Library/Logs/com.citrixonline.g2prem.log 2>&1" with administrator privileges'
	rm -v ~/Desktop/.g2puninstall.sh >> $logFile 2>&1
	exit
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
	appLocations=("/Applications" "$HOME/Applications" "$HOME/Desktop" "$HOME/Library/Application Support/CitrixOnline")
	for x in ${locations[@]}
	do
		trash "$x"/GoToMyPC* >> $logFile 2>&1
	done
fi
