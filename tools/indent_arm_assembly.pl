#!/usr/bin/env perl

use strict;

sub spaces {
    my $n = $_[0];
    my $ret = "";
    while ($n > 0) {
        $ret .= " ";
        $n--;
    }
    return $ret;
}

sub indentcolumns {
    my $input = $_[0];
    my $chars = $_[1];
    my @operands = split(/,/, $input);
    my $num = $#operands + 1;
    my $ret = "";
    for (my $i = 0; $i < $num; $i++) {
        my $cur = $operands[$i];
        $cur =~ s/^\s+|\s+$//g;
        $ret .= $cur;
        if ($i + 1 < $num) {
            my $next = $operands[$i+1];
            my $len = length($cur);
            if ($len > $chars) {
                return $input;
            }
            my $pad = $chars - $len;
            if ($next =~ /[su]xt[bhw]|[la]s[lr]/) {
                $pad = 0;
            }
            $ret .= "," . spaces(1 + $pad);
        }
    }
    return $ret;
}

sub columns {
    my $rest = $_[0];
    if ($rest !~ /,/) {
        return $rest;
    }
    if ($rest =~ /{|[^\w]\[/) {
        return $rest;
    }
    if ($rest =~ /v[0-9]+\.[0-9]+[bhsd]/) {
        return indentcolumns($rest, 7);
    }
    return indentcolumns($rest, 3);
}

while (<STDIN>) {
#    if (not /^ /) {
#        print $_;
#        next;
#    }
    chomp;
    if (/^(\d+:)?(\s+)([\w\\][\w\\\.]*)(\s+)(.*)/) {
        my $label = $1;
        my $indent = $2;
        my $instr = $3;
        my $origspace = $4;
        my $rest = $5; #columns($5);
        my $len = length($instr);

        my $ilen = length($label) + length($indent);
        my $size = 8;
        if ($ilen >= 3 && $ilen <= 5) {
            $size = 4;
        } elsif ($ilen >= 7 && $ilen <= 9) {
            $size = 8;
        } elsif ($ilen == 10 || $ilen == 12) {
            $size = $ilen;
        }
        $size = 8;
        $indent = spaces($size - length($label));

        $ilen = $len + length($origspace);
        $size = 0;
        if ($ilen >= 7 && $ilen <= 9) {
            $size = 8;
        } elsif ($ilen >= 10 && $ilen <= 14) {
            $size = 12;
        } elsif ($ilen >= 15 && $ilen <= 19) {
            $size = 16;
        }
        $size = 16;

        $rest =~ s/(\.[84216]*[BHSD])/lc($1)/ge;
        $rest =~ s/([SU]XT[BWH]|[LA]S[LR])/lc($1)/ge;

        if (0) {
            $_ = $label . $indent . $instr . $origspace . $rest;
            print $_ . "\n";
            next;
        }

        if ($rest eq "") {
            $_ = $label . $indent . $instr;
        } elsif ($len < $size) {
            $_ = $label . $indent . $instr . spaces($size-$len) . $rest;
        } elsif ($size > 0) {
            $_ = $label . $indent . $instr . " " . $rest;
        } else {
            $_ = $label . $indent . $instr . $origspace . $rest;
        }
    }
    print $_ . "\n";
}
