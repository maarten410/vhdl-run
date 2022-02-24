#!/usr/bin/env tclsh
package require cmdline
package require fileutil
package require fileutil::traverse

set OPTIONS {
    {dir.arg    "directory"}
    {args.arg   ""}
}

# Part of the usage message;
set USAGE ": vhdl-run.tcl \[options] entity \[entity]\noptions:"

# Initialise some defaults;
set opts(d) ""

try {
    array set opts [cmdline::getoptions argv $OPTIONS $USAGE]
} trap {CMDLINE USAGE} {msg} {
    puts stderr $msg
    exit 1
}
set dir $opts(dir)
set ghdlArgs {--ieee=synopsys}
#lappend ghdlArgs $opts(args)
if {$argc > 0} {
    puts "Using args: $ghdlArgs"
    set curDir [pwd]
    if {[file isdirectory $dir]} {
        set dir [file join "./" $dir]
    } elseif {$dir=="directory"} {
        set dir "./"
    } else {
        puts "Directory $dir does not exist."
        exit 1
    }
    fileutil::traverse t $dir
    set completedFiles ""
    set non_tb ""
    set tb ""
    t foreach file {
        if {[file extension $file] == ".vhd"} {
            set tail [file tail $file]
            if {[lsearch $tail *_tb.vhd] == -1} {
                lappend non_tb $file
            } else {
                lappend tb $file
            }
        }
    }
    foreach testbench $tb {
        lappend non_tb $testbench
    }
    exec ghdl --clean
    foreach file $non_tb {
        set tail [file tail $file]
        if {[file extension $file] == ".vhd" && [lsearch completedFiles $tail] == -1} {
            puts "Analysing file: $file"
            if {[catch {exec -ignorestderr ghdl -a $ghdlArgs $file} result] != 0} { 
                puts "Error in $file"
                puts "To view errors run: ghdl -a $ghdlArgs $file"
            } else { 
                puts "$file OK"
                lappend completedFiles $tail
            }
        } elseif {[lsearch completedFiles $tail] != -1} {
            puts "Ignoring $file as another file $tail was already defined"
        }
    }
    foreach entity $argv {
        puts "Elaborating $entity"
        if {[catch {exec -ignorestderr ghdl -e $ghdlArgs $entity} result] != 0} {
            puts "To view errors run: ghdl -e $ghdlArgs $entity"
        }
        puts "Generating waveform for $entity as [file join $dir $entity].ghw"
        if {[catch {exec -ignorestderr ghdl -r $ghdlArgs $entity --wave=[file join $curDir $entity.ghw]} result]} {
            puts "To view errors run: ghdl -r $ghdlArgs $entity --wave=[file join $curDir $entity.ghw]"
        }
    }
} else {
    puts "Give entities to run as arguments."
}
