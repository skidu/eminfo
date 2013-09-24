#!/usr/bin/env perl
use strict;
use warnings;

my $action = shift;
&help if !$action;
&help if $action =~ m/\A\s*\Z/;

&help if $action eq 'help';
&part_pstr_output(@ARGV)           if $action eq 'part_pstr_output';
&format_pstr_output_toplain(@ARGV) if $action eq 'format_pstr_output_toplain';
&format_pstr_output_toterm(@ARGV)  if $action eq 'format_pstr_output_toterm';
&conv_phoutput_toxml(@ARGV)        if $action eq 'conv_phoutput_toxml';


#### Sub Def

# Help Stuff
#
sub help {
print <<EOF
Example:

EOF
;
exit(1);
}

# Trim HTML-TAG in plugin output (last filed)
# Note:		remove <>/&nbsp;
# Note:		output must be one-line.
# Usage:	format_pstr_output_toplain {output-last-filed}
#
sub format_pstr_output_toplain {
	my $content = shift;
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ s/\<[^\<\>]*\>//g;
	$content =~ s/&nbsp;/ /g;
	print $content;
}

# Convert HTML-Color to TERM-Color in plugin output (last filed)
# Note:		remove <>/&nbsp; convert ###/<br> into newline
# Note:		output maybe multi-line.
# Usage:	format_pstr_output_toterm {content-last-filed}
#
sub format_pstr_output_toterm {
	my $content = shift;
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ s/((<\s*font\s+color=(\w+)\s*>)\s*(.+?)\s*(<\s*\/font\s*>))/\n$3 ::: $4\n/ig;
	# print "\nfirst===\n$content";  # for debug
	# print "\nlast===\n";
	open my $fh, "<", \$content;
	  while(<$fh>){
		if (/\A(\w+)\s+:::\s+(.+)\Z/){
			my ($color,$body) = ($1,$2);
			if ($color eq 'green'){
				$body = "\033[1;32m$body\033[0m";
			} elsif ($color eq 'red'){
				$body = "\033[1;31m$body\033[0m";
			} elsif ($color eq 'yellow'){
				$body = "\033[1;33m$body\033[0m";
			}
			$body =~ s/&nbsp;/ /g;
			print $body;
		} else {
			s/[\r\n]//g;
			s/&nbsp;/ /g;
			s/<br>/\n/g;
			s/\<[^\<\>]*\>//g;
			s/\s*###\s*/\n/g;
			print; #  if !(/\A\s+\Z/);
		}
	  }
	close $fh;
}

# Read each part of plugin output
# Usage:        part_pstr_output part_num "${content}"   
# Note:         part_num ~ [1-6]
# Example:      part_pstr_output 2  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# Example:      part_pstr_output 6  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# 
sub part_pstr_output {
	my $part = shift;
	my $content = shift;
	exit(1) if $part =~ /\D/;
	exit(1) if ($part > 6 || $part < 1);
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ m/{\s*(\w+)\s*}\s*:\s*{\s*(\w+)\s*}\s*:\s*{\s*(([^\|]+)(\|([^\|]+))?(\|([^\|]+))?)\s*}/i;
	# print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n6: $6\n7: $7\n8: $8\n\n";   # for debug
	if($1 && $part eq '1') { print $1; };
	if($2 && $part eq '2') { print $2; };
	if($3 && $part eq '3') { print $3; };
	if($4 && $part eq '4') { print $4; };
	if($6 && $part eq '5') { print $6; };
	if($8 && $part eq '6') { print $8; };
}


# Convert plugin/handler output to xml-content
# Note:		called by handler postlog
# Note:  	deal with:   < > & ' " 
# 		&amp; &
# 		&lt;  <
# 		&gt;  >
# 		&quot; "
# 		&apos; '
# Example:      conv_phoutput_toxml  "{level}:{type}:{title | summary | details: item1. ### <font color=red> item2. &nbsp; </font> ### item3. ### }"  "123"
# Example:	conv_phoutput_toxml  "{crit}:{file}:{ /etc/passwd /etc/services /etc/shadow }"  "auto handler result here"
#
sub conv_phoutput_toxml {
	my $debug = 1;
	my $poutput = shift;
	my $houtput = shift;
	exit(1) if !defined $poutput;
	exit(1) if !defined $houtput;
	print "poutput: $poutput\n" if $debug;
	print "houtput: $houtput\n" if $debug;
	my $level = &part_pstr_output(1,$poutput);
	print "level=[$level]\n" if $debug;
	my $type = &part_pstr_output(2,$poutput);
	print "type=[$type]\n" if $debug;
	my $title = &part_pstr_output(4,$poutput);
	print "title=[$title]\n" if $debug;
	my $summary = &part_pstr_output(5,$poutput);
	print "summary=[$summary]\n" if $debug;
	my $body = &part_pstr_output(6,$poutput);
	print "body=[$body]\n" if $debug;
	my @items = split /###/ , $body;
	print "array item=[@items]\n" if $debug;
}
