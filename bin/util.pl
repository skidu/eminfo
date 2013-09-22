#!/usr/bin/env perl
use strict;
use warnings;

my $action = shift;
exit(1) if !defined $action;
exit(1) if $action =~ m/\A\s*\Z/;

# Trim HTML-TAG in plugin output (last filed)
# remove <>/&nbsp;
# output must be one-line.
# usage: format_pstr_output_toplain {output-last-filed}
if ($action eq 'format_pstr_output_toplain'){
	my $content = shift;
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ s/\<[^\<\>]*\>//g;
	$content =~ s/&nbsp;/ /g;
	print $content;
}

# Convert HTML-Color to TERM-Color in plugin output (last filed)
# remove <>/&nbsp; convert ###/<br> into newline
# output maybe multi-line.
# usage: format_pstr_output_toterm {content-last-filed}
if($action eq 'format_pstr_output_toterm'){
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
# part_num ~ [1-6]
# part_pstr_output part_num  {content}
# usage: part_pstr_output {partnum} {output}
if($action eq 'part_pstr_output'){
	my $part = shift;
	my $content = shift;
	exit(1) if $part =~ /\D/;
	exit(1) if ($part > 6 || $part < 1);
	exit(1) if !defined $content;
	exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ m/{\s*(\w+)\s*}:{\s*(\w+)\s*}:{\s*(([^\|]+)(\|([^\|]+))?(\|([^\|]+))?)\s*}/i;
	# print "$1,$2,$3,$4,$5,$6,$7,$8"; print "\n";
	if($1 && $part eq '1') { print $1; };
	if($2 && $part eq '2') { print $2; };
	if($3 && $part eq '3') { print $3; };
	if($4 && $part eq '4') { print $4; };
	if($6 && $part eq '5') { print $6; };
	if($8 && $part eq '6') { print $8; };
}
