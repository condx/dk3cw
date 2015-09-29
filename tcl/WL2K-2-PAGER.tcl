#!/bin/sh
# \
exec tclsh "$0" ${1+"$@"}
package require Expect
#USER
# Callsign and Name of Callsign Owner
set user CALLSIGN
set name PASSWORD
#GATEWAY
set timeout 60
#Telnet-Host
set host [read [open "fbb.txt" r]] 
#Packet Radio RMS
set rms [read [open "rms.txt" r]]
#Packet Radio RMS - Backup
set rms2 [read [open "rms2.txt" r]]
#Funkrufmaster
set master [read [open "master.txt" r]]
#DELETING previous OUTPUT
spawn cmd 
expect "\[>\]"
send "del output_$user.txt\r";
expect "\[>\]"
send "del output2_$user.txt\r";
expect "\[>\]"
send "exit\r";
puts "Using RMS $rms!"
#TELNET START
spawn telnet $host
expect "\[Login :\]"
send "$user\r";
expect "=>"
#RMS
send "c $rms igateb\r";
expect "$rms >"
send "lm\r";
expect "\[>\]"
set input [open output_$user.txt a]
set output $expect_out(buffer)
puts $input $output
close $input
send "b\r";
expect "=>"
#Check for new messages in output file
set file [read [open "output_$user.txt" r]]
if [
  regexp -nocase {No pending} $file matchresult
] then {
#DISCONNECT
puts "No new messages, disconnecting..."
send "q\r";
expect "=>"
send "q\r";
} elseif [
  regexp -nocase {link setup} $file matchresult
] then {
#DISCONNECT
puts "Link failure with $rms, trying $rms2..."
send "c $rms2 igateb\r";
expect "$rms2 >"
send "lm\r";
expect "\[>\]"
set input [open output2_$user.txt a]
set output $expect_out(buffer)
puts $input $output
close $input
send "b\r";
expect "=>"
#Check for new messages in output file
set file2 [read [open "output2_$user.txt" r]]
if [
  regexp -nocase {No pending} $file2 matchresult
] then {
#DISCONNECT
puts "No new messages, disconnecting..."
send "q\r";
expect "=>"
send "q\r";
} elseif [
  regexp -nocase {link setup} $file matchresult
] then {
#DISCONNECT
puts "Link failure with $rms2, disconnecting..."
send "q\r";
expect "=>"
send "q\r";
} elseif [
	regexp -nocase {Secure login required} $file2 matchresult
] then {
puts "Secure login activated, briefing user..."
set input [open secure_login.txt a]
set output "$user [clock format [clock seconds] -format "%D, %H:%M %Z"];"
puts $input $output
close $input
send "c $master igateb\r";
expect "$master =>" {
exp_send "p $user $name, bitte deaktiviere Secure Login auf http://winlink.org\r";
}
expect "$master =>"
send "q\r";
expect "=>"
send "q\r";
} else {
#Funkrufmaster
puts "New messages! Paging user..."
send "c $master igateb\r";
expect "$master =>" {
exp_send "p $user [read [open "output2_$user.txt" r]]\r";
}
expect "$master =>"
send "q\r";
expect "=>"
send "q\r";
}
} elseif [
	regexp -nocase {Secure login required} $file matchresult
] then {
puts "Secure login activated, briefing user..."
set input [open secure_login.txt a]
set output "$user [clock format [clock seconds] -format "%D, %H:%M %Z"];"
puts $input $output
close $input
send "c $master igateb\r";
expect "$master =>" {
exp_send "p $user $name, bitte deaktiviere Secure Login auf http://winlink.org\r";
}
expect "$master =>"
send "q\r";
expect "=>"
send "q\r";
} else {
#Funkrufmaster
puts "New messages! Paging user..."
send "c $master igateb\r";
expect "$master =>" {
exp_send "p $user [read [open "output_$user.txt" r]]\r";
}
expect "$master =>"
send "q\r";
expect "=>"
send "q\r";
}
