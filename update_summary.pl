#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 April 2015
# Edit: 08 February 2020
# Website: https://github.com/trizen

# Updated the SUMMARY.md file by adding new entries to the summary.

use 5.020;
use strict;
use autodie;
use warnings;

use Cwd qw(getcwd);
use File::Spec qw();

use experimental qw(signatures);
use File::Basename qw(basename dirname);
use URI::Escape qw(uri_escape);

sub add_section ($section, $file) {

    my ($before, $middle);
    open my $fh, '<', $file;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^(#+\h*Summary\s*)$/) {
            $middle = "$1\n";
            last;
        }
        else {
            $before .= $line;
        }
    }
    close $fh;

    open my $out_fh, '>', $file;
    print {$out_fh} $before . $middle . $section;
    close $out_fh;
}

my $summary_file = 'SUMMARY.md';
my $main_dir     = File::Spec->curdir;

sub get_title ($file) {

    if (-f $file and open(my $fh, '<', $file)) {
        my $head = <$fh>;
        if ($head =~ /^# (.*)/) {
            my $title = $1;

            #~ $title =~ s/\[/\\[/g;
            #~ $title =~ s/\]/\\]/g;

            #~ $title =~ s/\(/\\(/g;
            #~ $title =~ s/\)/\\)/g;

            #$title =~ s{([*_`^])}{\\$1}g;
            return $title;
        }
    }

    return undef;
}

{
    my @root;

    sub make_section ($dir, $spaces) {

        my $cwd = getcwd();

        chdir $dir;
#<<<
        my @files =
         sort { fc($a->{title}) cmp fc($b->{title}) }
          map {
            my $path = File::Spec->rel2abs($_);
            {
                title => get_title($path) // $_,
                name => $_,
                path => $path
            }
        } glob('*');
#>>>
        chdir $cwd;

        my $make_section_url = sub {
            my ($name) = @_;
            join('/', basename($main_dir), @root, $name);
        };

        my $section = '';
        foreach my $file (@files) {
            my $title = $file->{title};

            if ($file->{name} =~ /\.(\w{2,3})\z/) {
                next if $1 !~ /^(?:md)\z/i;
            }

            if (-d $file->{path}) {
                $section .= (' ' x $spaces) . "* $title\n";
                push @root, $file->{name};
                $section .= __SUB__->($file->{path}, $spaces + 4);
            }
            else {
                next if $dir eq $main_dir;
                my $url_path = uri_escape($make_section_url->($file->{name}), ' ?');
                $section .= (' ' x $spaces) . "* [$title]($url_path)\n";
            }
        }

        pop @root;
        return $section;
    }
}

my $section         = make_section($main_dir, 0);
my $section_content = add_section($section, $summary_file);

say "** All done!";
