#!/usr/bin/tclsh
# control structures should have complete curly-braced block of code

foreach fileName [getSourceFileNames] {

    set state "start"
    set exprDepth  0
    set addClose   0
    set doWhileDepth 0
    set ignoreWhile 0
    array set doWhile {0 1}
    set pp_line -1
    foreach token [getTokens $fileName 1 0 -1 -1 {}] {
        set value [lindex $token 0]
        set type [lindex $token 3]
        set line [lindex $token 1]

        if {($type == "pp_pragma") || ($type == "pp_error")} {
            set pp_line $line
        }

        if {$line == $pp_line} {
            # Ignore
        } elseif {($type == "space") || ($type == "newline") || ($type == "cppcomment") || ($type == "ccomment")} {
            # Ignore   
        } elseif {$state == "start"} {
            if {$type == "if"} {
                set state "looking-expression-block"
            } elseif {$type == "for"} {
                set state "looking-expression-block"
            } elseif {($type == "while") && ($ignoreWhile == 0)} {
                set state "looking-expression-block"
            } elseif {($type == "while") && ($ignoreWhile == 1)} {
                set ignoreWhile 0
            } elseif {$type == "do"} {
                set state "looking-block-while-expression"
                incr doWhileDepth
                set doWhile($doWhileDepth) 0
            } elseif {$type == "else"} {
                set state "looking-block-or-if"
            }
        } elseif {$state == "looking-expression-block"} {
            if {$type == "leftparen"} {
                set state "looking-expression-end-block"
                incr exprDepth
            } else {
                report File 1 "Error:"
            }
        } elseif {$state == "looking-expression-end-block"} {
            if {$type == "leftparen"} {
                incr exprDepth
            } elseif {$type == "rightparen"} {
                incr exprDepth -1
                if {$exprDepth == 0} {
                    #puts "looking-block"
                    set state "looking-block"
                }
            }
        } elseif {$state == "looking-block-or-if"} {
            if {$type == "if"} {
                set state "looking-expression-block"
            } elseif {$type == "leftbrace"} {
                set state "start"
            } else {
                puts -nonewline "\{"
                set state "looking-semicolon"
                set next $doWhile($doWhileDepth)
                incr next
                set doWhile($doWhileDepth) $next
            }
        } elseif {$state == "looking-block"} {
            if {$type == "leftbrace"} {
                set state "start"
            } else {
                puts -nonewline "\{"
                set next $doWhile($doWhileDepth)
                incr next
                set doWhile($doWhileDepth) $next

                if {$type == "semicolon"} {
                    set state "start"
                    set addClose 1
                } else {
                    set state "looking-semicolon"
                }
            }
        } elseif {$state == "looking-semicolon"} {
            if {$type == "semicolon"} {
                set state "start"
                set addClose 1
            }
        } elseif {$state == "looking-block-while-expression"} {
            if {$type == "leftbrace"} {
                set state "start"
            } else {
                puts -nonewline "\{"
                set state "looking-semicolon"
                set next $doWhile($doWhileDepth)
                incr next
                set doWhile($doWhileDepth) $next
            }
        }

        puts  -nonewline "$value"
        #($type)"
        if {$addClose == 1} {
            set addClose 0
            puts -nonewline "\}"
            set next $doWhile($doWhileDepth)
            incr next -1
            set doWhile($doWhileDepth) $next
        }

        if {$type == "leftbrace"} {
            set next $doWhile($doWhileDepth)
            incr next
            set doWhile($doWhileDepth) $next
        } elseif {$type == "rightbrace"} {
            set next $doWhile($doWhileDepth)
            incr next -1
            if {$next == 0} {
                incr doWhileDepth -1
                set ignoreWhile 1
            } else {
                set doWhile($doWhileDepth) $next
            }
        }
    }
}
