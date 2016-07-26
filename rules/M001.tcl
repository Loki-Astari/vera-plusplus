#!/usr/bin/tclsh
# Types have an initial uppercase letter.
# Objects have an initial lowercase letter.
#
#   Looking for variable declarations:
#       TypeName    objectName              ie Identifier Identifier
#
#   Take into account
#       #if defined Value                   ignore pre-processor macro line
#       #error AnyWord AnotherWord          ignore pre-processor macro line
#       #define Word Word                   ignore pre-processor macro line
#       typedef Type Type;                  ignore typedef up-to ';'
#       template<Type TemplateType>         drop template or template< Stuff up-to '>'
#       long long objectName;               built in type behave like an extended identifier
#       Type  NameSpace::Class::object      fully qualified names are ignored.
#                                           these probably belong to a package not owned by
#                                           this project anyway.
#

# States:
#
#
#
#
#          |--------------------------------------------------------------
#          |               |                      |                      |                           Not Greater(>)
#          |          #if or #error            typedef               templatea     Less(<)              -------
#          |          or #define                  |    -----             |    ----------------          |     |
#          |              \/                     \/    |  Not ;         \/    |              \/        \/     |
#          |        ##############         ##############  |      ##############             ##############   |
#          |        # PreProc    #         # Typedef    #  |      # Template   # <|          # Template<  #   |
#          |        ##############         ##############  |      ##############  | Space    ##############   |
#          |               |                     |    /\   |       |          |   |             |        |    |
#          |             New Line                ;     -----  (Not Less(<) && -----        Greater(>)    -----
#          |               |                     |             Not Space( ))
#   ##############         |                     |                 |                            |
#   # start      #<------------------------------<-----------------<-----------------------------
#   ##############
#          |
#          |
#          |
#          |
#      Identifier              ---->-<-----------------<------------------------------      ------
#   or BuiltIn Type            |    |                  |                             |      |    |
#          |         BuiltIn Type   |              Greater(>)                    Identifier |   Space
#          |         or space  |    |                  |                             |      |    |
#          |         or const  |    |                  |                             |      |    |
#          |         or ref    |    |                  |                             |      |    |
#          |         or pointer|    |                  |                             |      |    |
#          |                   |    |                  |                             |      |    |
#          |       ##############   |                  ##############           ##############   |
#          -------># Found1     #<---                  # Found1<    #<---       # Found1::   #<---
#                  ##############                      ##############   |       ##############
#                       |      |                         /\        |    |              /\
#                       |      |                      Less(<)   Not Greater(>)         ::
#                       |      |                         |         ------              |
#                       |      ---------------------------------------------------------
#                       |
#    ##############     |
#    # Hit Check  #     |
#    # Identifer  #     |
#    # Reset to   #<-----
#    # Start      #   Identifier
#    ##############

set builtInTypes {
    void
    bool
    signed
    unsigned
    long
    int
    short
    char
    float
    double
    const
    and
    star
}

proc isBuiltInType {s} {
    global builtInTypes
    return [expr [lsearch $builtInTypes $s] != -1]
}

proc lpop listVar {
        upvar 1 $listVar l
        set r [lindex $l end]
        set l [lreplace $l [set l end] end] ; # Make sure [lreplace] operates on unshared object
        return $r
}

set state "start"
set pp_line -1
lappend classState std

foreach f [getSourceFileNames] {
    foreach t [getTokens $f 1 0 -1 -1 {}] {
        set identifier [lindex $t 0]
        set tokenName [lindex $t 3]
        set lineNumber [lindex $t 1]
        if {$state == "Template" && ($tokenName != "less" && $tokenName != "space")} {
            set state "start"
        }

        if {$tokenName == "pp_if" || $tokenName == "pp_error" || $tokenName == "pp_define"} {
            set pp_line $lineNumber
            #puts "$identifier: => PP Start"
        } elseif {$lineNumber == $pp_line} {
            # Ignore PP line tokens
            #puts "$tokenName -> $identifier: => PP Cont"
        } elseif {$state == "start" && $tokenName == "typedef"} {
            set state "Typedef"
            #puts "$tokenName -> $identifier: => Typedef Start"
        } elseif {$state == "Typedef"} {
            if {$tokenName == "semicolon"} {
                set state "start"
                #puts "$tokenName -> $identifier: => Typedef END"
            } else {
                #puts "$tokenName -> $identifier: => Typedef Continue"
            }
        } elseif {$state == "start" && ($tokenName == "struct" || $tokenName == "class")} {
            set state "Class1"
            # puts "$tokenName -> $identifier: => Class Start"
        } elseif {$state == "Class1" && ($tokenName == "space" || $tokenName == "newline")} {
            set state "Class2"
            # puts "$tokenName -> $identifier: => Class Space"
        } elseif {$state == "Class2" && $tokenName == "identifier"} {
            set state "Class3"
            set className $identifier
            # puts "$tokenName -> $identifier: => Class Identifier"
        } elseif {$state == "Class3" && ($tokenName == "space" || $tokenName == "newline")} { 
            set state "Class4"
            # puts "$tokenName -> $identifier: => Class Extra Space"
        } elseif {$state == "Class4" && ($tokenName == "leftbrace" || $tokenName == "colon")} {
            set state "start"
            lappend classState $className
            # puts "$tokenName -> $identifier: => Class Pushing $className"
        } elseif {$state == "Class4"} {
            set state "start"
            # puts "$tokenName -> $identifier: => Class Back to Start"
        } elseif {$state == "start" && $tokenName == "rightbrace"} {
            set state "CheckClassClose"
            # puts "$tokenName -> $identifier: => Class CheckDone Start"
        } elseif {$state == "CheckClassClose" && ($tokenName == "space" || $tokenName == "newline")} {
            #ignore
            # puts "$tokenName -> $identifier: => Class CheckDone Space"
        } elseif {$state == "CheckClassClose" && $tokenName == "semicolon"} {
            lpop classState
            # puts "$tokenName -> $identifier: => Class CheckDone Pop"
        } elseif {$state == "CheckClassClose"} {
            set state "start"
            # puts "$tokenName -> $identifier: => Class CheckDone Start"
        } elseif {$state == "start" && $tokenName == "template"} {
            set state "Template"
            #puts "$tokenName -> $identifier: => Template Start"
        } elseif {$state == "Template" && $tokenName == "less"} {
            set state "Template<"
            #puts "$tokenName -> $identifier: => Template Open"
        } elseif {$state == "Template<" && $tokenName == "greater"} {
            set state "start"
            #puts "$tokenName -> $identifier: => Template Close (start)"
        } elseif {$state == "start" && $tokenName == "identifier"} {
            set state "Found1"
            #puts "$tokenName -> $identifier: => start -> Found1"
        } elseif {$state == "start" && [isBuiltInType $tokenName]} {
            set state "Found1"
            #puts "$tokenName -> $identifier: => start -> Found1  Built in"
        } elseif {$state == "Found1" && $tokenName == "space"} {
            #ignore
            #puts "$tokenName -> $identifier: => Found1 -> Found1 space"
        } elseif {$state == "Found1" && $tokenName == "colon_colon"} {
            set state "Found1::"
            #puts "$tokenName -> $identifier: => Found1 -> Found1 ::"
        } elseif {$state == "Found1::" && $tokenName == "identifier"} {
            set state "Found1"
            #puts "$tokenName -> $identifier: => Found1:: -> Found1
        } elseif {$state == "Found1::" && $tokenName == "space"} {
            #ignore
            #puts "$tokenName -> $identifier: => Found1:: -> Found1:: space
        } elseif {$state == "Found1" && [isBuiltInType $tokenName]} {
            #ignore 
            #puts "$tokenName -> $identifier: => Found1 -> Found1 Built in"
        } elseif {$state == "Found1" && $tokenName == "less"} {
            set state "Found1<"
            #puts "$tokenName -> $identifier: => Found1 -> Found1< Template Param"
        } elseif {$state == "Found1<" && $tokenName != "great"} {
            #ignore
            #puts "$tokenName -> $identifier: => Found1 -> Found1< Template Param Cont"
        } elseif {$state == "Found1<" && $tokenName == "great"} {
            set state "Found1"
            #puts "$tokenName -> $identifier: => Found1< -> Found1"
        } elseif {$state == "Found1" && $tokenName == "identifier"} {
            #puts "$tokenName -> $identifier: => Found2 -> HIT Checking"
            set state "start"
            # Hit
            set objectName [lindex $t 0]
            set columnNumber [lindex $t 2]
            set nextToken [getTokens $f $lineNumber [expr $columnNumber + [string length $objectName]] [expr $lineNumber + 1] -1 {}]
            set ignore 0
            foreach next $nextToken {
                set nextTokenName [lindex $next 3]
                if {$nextTokenName == "space"} {
                    # Continue to next token
                } elseif {$nextTokenName == "colon_colon"} {
                    # Fully qualified identifier so ignore
                    set ignore 1
                    break
                } elseif {$nextTokenName == "less"} {
                    # Starting a template
                    set ignore 1
                    break
                } else {
                    # Any other token mean we should look at it
                    break
                }
            }
            set identifier [lindex $t 0]
            set identifierFirst [string index $identifier 0]
            # puts "Checking $identifier"
            if {[lsearch -exact $classState $identifier] > 0} {
                # puts "Constructor Destructor"
            } elseif {$ignore == 0 && [expr ! [string is lower $identifierFirst]]} {
                # puts "Failed $identifier"
                report $f $lineNumber "Objects >$identifier< (variables/functions) should have an initial lower case letter"
            }
        } else {
            #puts "$tokenName -> $identifier: => Reset to start"
            set state "start"
        }
    }
}
