#!/usr/bin/tclsh
# using namespace are not allowed in header files

foreach fileName [getSourceFileNames] {
    set extension [file extension $fileName]
    if {[lsearch {.h .hh .hpp .hxx .ipp .tpp} $extension] != -1} {

        set state "start"
        set depth 0
        foreach token [getTokens $fileName 1 0 -1 -1 {using namespace identifier leftbrace rightbrace}] {
            set type [lindex $token 3]

            if {$type == "leftbrace"} {
                incr depth
            }
            if {$type == "rightbrace"} {
                incr depth -1
            }
            if {$state == "using" && $type == "namespace" && $depth == 0} {
                report $fileName $usingLine "using namespace not allowed in header file"
            }

            if {$type == "using"} {
                set usingLine [lindex $token 1]
            }

            set state $type
        }
    }
}
