on run
    set stateDirectory to (POSIX path of (path to home folder)) & ".local/share/homestar-console"
    set launchLog to stateDirectory & "/app.log"
    try
        with timeout of 900 seconds
            do shell script "umask 077; /bin/mkdir -p " & quoted form of stateDirectory & "; " & quoted form of "@launcher@" & " start > " & quoted form of launchLog & " 2>&1"
        end timeout
    on error
        activate
        set answer to display alert "Homestar Console could not start" message "On a new Mac, run workstation apply, then homestar-console configure in your terminal to enter credentials privately. For other failures, inspect homestar-console logs or open the launcher log below." as warning buttons {"Open Log", "OK"} default button "OK"
        if button returned of answer is "Open Log" then
            do shell script "/usr/bin/open -t " & quoted form of launchLog
        end if
    end try
end run
