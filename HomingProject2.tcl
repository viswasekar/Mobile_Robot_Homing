# ===========================================================================
# 
# HomingProject2.tcl --
# 
# ===========================================================================

wm protocol . WM_DELETE_WINDOW quit
#
#steering functions
#
proc forward {} {
	pio setVel 100
	puts "forward"
}
proc turnLeft {} {
	pio deltaHeading 2
	puts "left"
}
proc turnRight {} {
	pio deltaHeading -2
	puts "right"
}
proc backward {} {
	pio setVel -100
	puts "back"
}
proc stop {} {
	pio stop
}
#
# Snapshot Function
#
proc takeSnapshot {videoHandle snapshot} {
	puts "return"
	vid startGrab $videoHandle
	while {![vid checkGrab]} {
		update
		after 100	
	}
	ip image red
	ip image green
	ip image blue
	vid fetchGrab red green blue
	ip showRGBImage input red green blue
	#ip savePPM red green blue "/homes/vsubramaniansekar/projects/homing/snapshot.ppm"
	update
	imageProcessing red green blue snapshot
}

proc imageProcessing {red green blue snapshot} {
	
	#convert to black/white
	ip image GRAY
	ip rgb2bw red green blue GRAY

	#set inner and outer circle for unwrapping
	ip image MAPPEDNN
	set w [ip width GRAY]
	set h [ip height GRAY]
	set xc 95
	set yc 67
	set r1 14
	set r2 61

	#unwrapping panoramic image
	ip polarMapping POLAR $w $h $xc $yc $r1 $r2 b

	ip mapping GRAY POLAR MAPPEDNN

	#apply butterworth-filter
	ip image $snapshot
	ip butterworth MAPPEDNN 0.25 0.0 1 $snapshot
	
}
#
#quit procedure
#
proc quit { } {
    #
    # disconnect from video server
    #
    vid disconnect
    #
    # disconnect from pioneer server
    #
    pio autoSonarOff
    pio disconnect

    
#exit
}

# suggestion for initialization stuff:

set hostname "localhost"

#
# video device parameters
#
set device   "/dev/video0" 
set port     0
set width 176
set height 130


set videoHandle [vid openVideo $hostname $device $port $width $height 1]

pio connect $hostname /dev/ttyS0
pio autoSonarOn


#image stream and key events
ip image stream 320 240
ip showBWImage input stream
bind all <Key> {
	if {"%K" eq "w"} {
		forward
	} elseif {"%K" eq "s"} {
		backward
	} elseif {"%K" eq "d"} {
		turnRight
	} elseif {"%K" eq "a"} {
		turnLeft
	} elseif {"%K" eq "Return"} {
		ip image snapshot
		takeSnapshot $videoHandle snapshot
		ip showBWImage test snapshot
	} elseif {"%K" eq "space"} {
		
	} elseif {"%K" eq "BackSpace"} {
		stop
		
	}
}
#to be checked
#bind .imginput <KeyRelease> {
#	if {"%K" eq "w"} {
#		puts "stop"
#		stop
#	} elseif {"%K" eq "s"} {
#		stop
#	}
#}
