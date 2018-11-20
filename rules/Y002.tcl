#!/usr/bin/tclsh

#
# Rules to help with documentation tool
# So that `inline` does not interfere with deducing the return type
# we need to put it on a line by itself.
#

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
            } elseif [regexp {^typename std::enable_if<.*>::type$} $line] {
                # OK usage of inline
            } elseif [regexp {^std::enable_if_t<.*>$} $line] {
                # OK usage of inline
            } elseif [regexp {std::enable_if} $line] {
                report $f 1  "To use documentation. After a @function 'std::enable_if' must be on its own line"
            }
        }
    }
}

