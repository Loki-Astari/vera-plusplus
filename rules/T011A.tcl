#!/usr/bin/tclsh
# Curly brackets must either:
#
#   1: Normally open brace and close brace must be on the column (i.e. align verticaly).
#   2: After the action: if / else / for / while /do (which must be followed by a block of code)
#       Make sure rule T019 is enabled.
#       If the open brace is on the same line as the action then the close brace must align with the action.
#
#       i.e. Both of these are valid.
#
#           if (test) {
#               // Stuff
#           }
#
#           // or
#
#           if (test)
#           {
#               // Stuff
#           }

proc acceptPairs {} {
    global file parens index end

    while {$index != $end} {
        set nextToken [lindex $parens $index]
        set tokenValue [lindex $nextToken 0]

        if {$tokenValue == "if" || $tokenValue == "else" || $tokenValue == "for" || $tokenValue == "while" || $tokenValue == "do"} {
            incr index
            set paramToken [lindex $parens $index]

            set lineOfAction [lindex $nextToken 1]
            set lineOfBrace  [lindex $paramToken 1]

            if {$lineOfAction != $lineOfBrace} {
                set nextToken $paramToken
            }
            set tokenValue [lindex $paramToken 0]
        }

        if {$tokenValue == "\{"} {
            incr index
            set leftParenLine [lindex $nextToken 1]
            set leftParenColumn [lindex $nextToken 2]

            acceptPairs

            if {$index == $end} {
                report $file $leftParenLine "opening curly bracket is not closed"
                return
            }

            set nextToken [lindex $parens $index]
            incr index
            set tokenValue [lindex $nextToken 0]
            set rightParenLine [lindex $nextToken 1]
            set rightParenColumn [lindex $nextToken 2]

            if {($leftParenLine != $rightParenLine) && ($leftParenColumn != $rightParenColumn)} {
                # make an exception for line continuation
                set leftLine [getLine $file $leftParenLine]
                set rightLine [getLine $file $rightParenLine]
                if {[string index $leftLine end] != "\\" && [string index $rightLine end] != "\\"} {
                    report $file $rightParenLine "closing curly bracket not in the same line or column"
                }
            }
        } else {
            return
        }
    }
}

foreach file [getSourceFileNames] {
    # set parens [getTokens $file 1 0 -1 -1 {leftbrace rightbrace}]
    set parens [getTokens $file 1 0 -1 -1 {for if while do else leftbrace rightbrace}]
    set index 0
    set end [llength $parens]
    acceptPairs
    if {$index != $end} {
        report $file [lindex [lindex $parens $index] 1] "excessive closing bracket?"
    }
}
