#!/usr/bin/env perl
use strict;
use warnings;
# use Smart::Comments;

my $action = shift;
&help if !$action;
&help if $action =~ m/\A\s*\Z/;

&help if $action eq 'help';
&part_pstr_output(@ARGV)           if $action eq 'part_pstr_output';
&format_pstr_output_toterm(@ARGV)  if $action eq 'format_pstr_output_toterm';
&format_phoutput_toxml(@ARGV)	   if $action eq 'format_phoutput_toxml';

### Sub Def

# Help Stuff
#
sub help {
print <<EOF
Example:
  part_pstr_output {1-6} {allof-plugin-output}}
  format_pstr_output_toterm  {output-contain-htmlcode-htmlcolor}
  format_phoutput_toxml {allof-plugin-output}  {allof-handler-output}

EOF
;
exit(1);
}

# Read each part of plugin output
# Usage:        part_pstr_output part_num "${content}"  {mode}
# Note:         part_num ~ [1-6]
# Note:		mode ~ perl | print    default: print
# Example:      part_pstr_output 2  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# Example:      part_pstr_output 6  "{level}:{type}:{title | summary | details: item1. ### item2. ### item3. ### }"
# 
sub part_pstr_output {
	my $part = shift;
	my $content = shift;
	my $mode = shift || 'print';
	exit(1) if $part =~ /\D/;
	exit(1) if ($part > 6 || $part < 1);
	exit(1) if !defined $content;
	# exit(1) if $content =~ m/\A\s*\Z/;
	$content =~ m/{\s*(\w+)\s*}\s*:\s*{\s*(\w+)\s*}\s*:\s*{\s*(([^\|]+)(\|([^\|]+))?(\|([^\|]+))?)\s*}/i;
	# print "1: $1\n2: $2\n3: $3\n4: $4\n5: $5\n6: $6\n7: $7\n8: $8\n\n";   # for debug
	my $result = '';
	if($1 && $part eq '1') { $result = $1; };
	if($2 && $part eq '2') { $result = $2; };
	if($3 && $part eq '3') { $result = $3; };
	if($4 && $part eq '4') { $result = $4; };
	if($6 && $part eq '5') { $result = $6; };
	if($8 && $part eq '6') { $result = $8; };
	$result =~ s/\A\s+//g if ($result);   # trim head \s
	if ($mode eq 'perl'){
		return ($result);
	} elsif ($mode eq 'print'){
		print $result;
	}
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
	### processed_content: $content
	open my $fh, "<", \$content;
	  while(<$fh>){
		### process_line: $_
		if (/\A(\w+)\s+:::\s+(.+)\Z/){
			my ($color,$body) = ($1,$2);
			### color: $color
			### color_line: $body
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
			#s/\<[^\<\>]*\>//g;   # trim (most likely) html-tag
			s/\s*###\s*/\n/g;
			print; #  if !(/\A\s+\Z/);
		}
	  }
	close $fh;
}

# Convert plugin/handler output to xml-content
# Note:		called by handler postlog
# Note:		process chars:  & < > ' "   =====>  &amp; &lt; &gt; &apos; &quot;
# Example:      format_phoutput_toxml  "{level}:{str}:{title | summary | item1. ### <font color=red> item2. &nbsp; </font> ### item3. ### }"  "123"
# Example:      format_phoutput_toxml  "{level}:{type}:{title}"  "123"
# Example:	format_phoutput_toxml  "{crit}:{file}:{ /etc/passwd /etc/services /etc/shadow }"  "auto handler result here"
#
sub format_phoutput_toxml {
	my $poutput = shift;
	my $houtput = shift;

	my $post_length = 0;
	(my $max_length = `/usr/local/eminfo/eminfo view postlog post_max_length 2>&-`) =~ s/[\r\n]//g;
	$max_length = 50000 if (!$max_length || $max_length =~ /\D/ || $max_length >= 50000);

	my $xml_result = "<info>\n";

	my $level = &part_pstr_output(1,$poutput,'perl') || '';
	$xml_result .= "<level>$level</level>\n";

	my $type = &part_pstr_output(2,$poutput,'perl') || '';
	$xml_result .= "<type>$type</type>\n";

	$xml_result .= "<body>\n";
	if ($type eq 'file'){
		my $files = &part_pstr_output(3,$poutput,'perl') || '';
		my @files = split /\s+/, $files;
		for (@files) {
			my $file_size = -s || 'unkn';
			s/&/&amp;/g;
        		s/</&lt;/g;
        		s/>/&gt;/g;
        		s/"/&quot;/g;
        		s/'/&apos;/g;
			$xml_result .= "<file size=$file_size>$_</file>\n";
		}
	} elsif ($type eq 'str'){
		# 1. process titl
		my $title = &part_pstr_output(4,$poutput,'perl') || '';
		$post_length += length($title);
		if ($post_length >= $max_length){
			$xml_result .= "<title>post length exceed $max_length</title>\n";
			goto PLUGIN_END;
		} else {
			$title =~ s/&/&amp;/g;
        		$title =~ s/</&lt;/g;
        		$title =~ s/>/&gt;/g;
        		$title =~ s/"/&quot;/g;
        		$title =~ s/'/&apos;/g;
			$title =~ s/(\A\s+|\s+\Z)//g;
			$xml_result .= "<title>$title</title>\n";
		}
		
		# 2. process summary
		my $summary = &part_pstr_output(5,$poutput,'perl') || '';
		$post_length += length($summary);
		if ($post_length >= $max_length){
			$xml_result .= "<summary>post length exceed $max_length</summary>\n";
			goto PLUGIN_END;
		} else {
                        $summary =~ s/&/&amp;/g;
                        $summary =~ s/</&lt;/g;
                        $summary =~ s/>/&gt;/g;
                        $summary =~ s/"/&quot;/g;
                        $summary =~ s/'/&apos;/g;
			$summary =~ s/(\A\s+|\s+\Z)//g;
			$xml_result .= "<summary>$summary</summary>\n";
		}
		
		# 3. process details
		my $body = &part_pstr_output(6,$poutput,'perl') || '';
		my @lines = split /###/ , $body;
		for (@lines) {
			my ($color,$content);
			# Notice: must be the whole-line matches  <font color=(\w+)>content</font>
			if (m/\A\s*(<\s*font\s+color=(\w+)\s*>)\s*(.+?)\s*(<\s*\/font\s*>)\s*\Z/) { 
				($color,$content) = ($2,$3);
			} else {
				$content = $_;
			}
			$content =~ s/[\r\n]//g;
			$content =~ s/&nbsp;/ /g;
			$content =~ s/&/&amp;/g;
			$content =~ s/</&lt;/g;
			$content =~ s/>/&gt;/g;
			$content =~ s/"/&quot;/g;
			$content =~ s/'/&apos;/g;
			$content =~ s/(\A\s+|\s+\Z)//g;

			my $len = length($content);
			next if $len == 0;

			$post_length += $len;
			if ($post_length >= $max_length){
				$xml_result .= "<line>post length exceed $max_length</line>\n";
				last;
			}

			if ($color) {
				$xml_result .= "<line size=\"$len\" color=\"$color\">$content</line>\n";
			} else {
				$xml_result .= "<line size=\"$len\">$content</line>\n";
			}
		}
	}
	PLUGIN_END: {
		$xml_result .= "</body>\n";
		$xml_result .= "<auto>\n";
		my @hlines = split /###/, $houtput;
		for (@hlines) {
			s/[\r\n]//g;
			s/&nbsp;/ /g;
			s/&/&amp;/g;  
			s/</&lt;/g;
			s/>/&gt;/g;
			s/"/&quot;/g;
			s/'/&apos;/g;
			s/(\A\s+|\s+\Z)//g;
	
			next if length == 0;

			$post_length += length;
			if ($post_length >= $max_length){
				$xml_result .= "<line>post length exceed $max_length</line>\n";
				last;
			}

			$xml_result .= "<line size=\"".length($_)."\">$_</line>\n";
		}
		$xml_result .= "</auto>\n";
		$xml_result .= "</info>\n";
	}
	print $xml_result;
}
