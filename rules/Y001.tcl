#!/usr/bin/tclsh

set state "start"
foreach f [getSourceFileNames] {
    foreach line [getAllLines $f] {
        if {$state == "start"} {
            if [regexp {@function} $line] {
                set state "function-comment"
            }
        } elseif {$state == "function-comment"} {
            if [regexp {\}} $line] {
                set state "start"
            } elseif [regexp {^inline$} $line] {
                # OK usage of inline
            } elseif [regexp {inline} $line] {
                report $f 1  "To use documentation. After a @function 'inline' must be on its own line"
            }
        }
    }
}

