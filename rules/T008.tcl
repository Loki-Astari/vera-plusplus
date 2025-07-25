#!/usr/bin/tclsh
# Keywords catch, for, if and while should be followed by a single space

foreach f [getSourceFileNames] {
    set pp_line -1
    foreach t [getTokens $f 1 0 -1 -1 {catch for if switch while pp_pragma pp_error}] {
        set keyword [lindex $t 0]
        set line [lindex $t 1]
        set column [lindex $t 2]
        set type [lindex $t 3]
        if {($type == "pp_pragma") || ($type == "pp_error")} {
          set pp_line $line
        } elseif {$pp_line != $line} {
            set followingTokens [getTokens $f $line [expr $column + [string length $keyword]] [expr $line + 1] -1 {}]
            if {[llength $followingTokens] < 2} {
                report $f $line "keyword '${keyword}' not followed by a single space"
            } else {
                if {[list [lindex [lindex $followingTokens 0] 0] [lindex [lindex $followingTokens 1] 0]] != [list " " "("]} {
                    if {$keyword == "if"} {
                        if {[list [lindex [lindex $followingTokens 0] 0] [lindex [lindex $followingTokens 1] 0] [lindex [lindex $followingTokens 2] 0] [lindex [lindex $followingTokens 3] 0]  ] != [list " " "constexpr" " " "("]} {
                            report $f $line "keyword '${keyword}' not followed by a single space. >if constexpr (< => <if><space><constepxr><space>("
                        }
                    } else {
                        report $f $line "keyword '${keyword}' not followed by a single space"
                    }
                }
            }
        }
    }
}
