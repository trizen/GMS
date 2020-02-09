#!/usr/bin/perl

use 5.020;
use strict;
use warnings;

use autodie qw(:all);
use open IO => 'utf8';
use experimental qw(signatures);

use Date::Parse;
use Time::Piece;

use Data::Dump qw(pp);
use URI::Escape qw(uri_escape_utf8);
use JSON qw(decode_json);
use IO::Uncompress::Unzip qw();
use File::Spec::Functions qw(catfile);

my $dir = 'oeis';

sub escape_markdown ($t) {
    $t =~ s{([*_`^\[\]{}()])}{\\$1}gr;
}

sub make_name ($entry) {
    "# " . escape_markdown($entry->{name});
}

sub make_data ($entry) {
    join(", ", split(/\s*,\s*/, $entry->{data}));
}

sub make_offset ($entry) {
    my ($offset) = split(/\s*\,\s*/, $entry->{offset});
    "## OFFSET\n\n$offset";
}

sub make_properties ($entry) {

    my @properties;

    if ($entry->{keyword} =~ /cofr/) {
        push @properties, "* This sequence is a continued fraction expansion.";
    }

    if ($entry->{keyword} =~ /mult/) {
        push @properties, "* This sequence is multiplicative.";
    }

    if ($entry->{keyword} =~ /fini/ and $entry->{keyword} =~ /full/) {
        push @properties, "* This sequence is finite and all the terms are known.";
    }
    elsif ($entry->{keyword} =~ /fini/) {
        push @properties, "* This sequence is finite.";
    }

    if ($entry->{keyword} =~ /cons/) {
        push @properties, "* This sequence is a decimal expansion of a constant.";
    }

    if ($entry->{keyword} =~ /eigen/) {
        push @properties, "* This is a sequence of eigenvalues.";
    }

    if ($entry->{keyword} =~ /base/) {
        push @properties, "* The results of the calculation depend on a specific positional base.";
    }

    if ($entry->{keyword} =~ /word/) {
        push @properties, "* Depends on the words of a specific language.";
    }

    if ($entry->{keyword} =~ /walk/) {
        push @properties, "* This sequence counts walks (or self-avoiding paths).";
    }

    if ($entry->{keyword} =~ /look/) {
        push @properties, "* This sequence has a visually interesting graph.";
    }

    if ($entry->{keyword} =~ /hard/) {
        push @properties, "* The terms of this sequence cannot be easily calculated.";
    }

    if (@properties) {
        return join("\n\n", "## PROPERTIES", @properties);
    }

    return undef;
}

sub resolve_html_links ($text) {
    $text =~ s{<a href="(.*?)">(.*?)</a>}{
        my $link = $1;
        my $name = $2;
        if ($link =~ m{^/}) {
            $link = "https://oeis.org" . $link;
        }
        "[" . escape_markdown($name) . "]($link)"
    }gre;
}

sub resolve_links ($text) {
    $text =~ s{_([\w\d.\s\-]+)_}{
        my $w = $1;
        my $t = uri_escape_utf8($1);
        "[$w](https://oeis.org/wiki/User:$t)";
    }egr =~ s{\b(A[0-9]{6})\b}{
        "[$1](https://oeis.org/$1)"
    }gre;
}

sub resolve_formula ($x) {
    $x = "`" . $x . "`";
    $x =~ s{(\bA[0-9]{6}\b)}{"`" . resolve_links($1) . "`"}ger =~ s/``//gr;
}

sub make_comments ($entry) {

    if (not exists $entry->{comment}) {
        return undef;
    }

    my @comments;
    my $state = 0;
    my %comment;

    foreach my $comment (@{$entry->{comment}}) {

        if ($state or $comment =~ /^(?:Comments? from|From) (_.*?_[[:punct:]\s]+.*?) \(Start\)/) {
            if (!$state) {
                $state = 1;
                $comment{name} = resolve_links($1) =~ s/:\z//r;
            }
            elsif ($comment =~ s/\(End\)//) {

                $state = 0;

                if ($comment =~ /\S/ and $comment !~ /^\s*\.\s*\z/) {
                    push @{$comment{lines}}, $comment;
                }

                my $sep = '----';

                my @block;
                push @block, $sep;
                push @block, "From $comment{name}: ";

                foreach my $line (@{$comment{lines}}) {
                    push @block, resolve_links(escape_markdown($line));
                }
                push @block, $sep;

                push @comments, join("\n\n", @block);
                undef %comment;
            }
            else {
                push @{$comment{lines}}, $comment;
            }
        }
        elsif (   $comment =~ /^(.*?)\.?\s*-\s*(_.*)/
               or $comment =~ /^(.*?) \[(_.*)\]/
               or $comment =~ /^(.*?) \[From (_.*)\]/) {
            my ($x, $y) = ($1, $2);
            push @comments, resolve_links(escape_markdown($x)) . " ; " . resolve_links($y);
        }
        else {
            push @comments, resolve_links(escape_markdown($comment));
        }
    }

    if (@comments) {
        return join("\n\n", "## COMMENTS", @comments);
    }

    return undef;
}

sub make_formulas ($entry) {

    if (not exists $entry->{formula}) {
        return undef;
    }

    my @formulas;
    my $state = 0;
    my %formula;

    foreach my $formula (@{$entry->{formula}}) {

        if ($state or $formula =~ /^(?:Formulas? from|From) (_.*?_[[:punct:]\s]+.*?) \(Start\)/) {
            if (!$state) {
                $state = 1;
                $formula{name} = resolve_links($1) =~ s/:\z//r;
            }
            elsif ($formula =~ s/\(End\)//) {

                $state = 0;

                if ($formula =~ /\S/ and $formula !~ /^\s*\.\s*\z/) {
                    push @{$formula{lines}}, $formula;
                }

                my $sep = '----';

                my @block;
                push @block, $sep;
                push @block, "From $formula{name}: ";

                foreach my $line (@{$formula{lines}}) {
                    push @block, resolve_formula($line);
                }
                push @block, $sep;

                push @formulas, join("\n\n", @block);
                undef %formula;
            }
            else {
                push @{$formula{lines}}, $formula;
            }
        }
        elsif (   $formula =~ /^(.*?)\.?\s*-\s*(_.*)/
               or $formula =~ /^(.*?) \[(_.*)\]/
               or $formula =~ /^(.*?) \[From (_.*)\]/) {
            my ($x, $y) = ($1, $2);
            push @formulas, resolve_formula($x) . " ; " . resolve_links($y);
        }
        else {
            push @formulas, resolve_formula($formula);
        }
    }

    if (@formulas) {
        return join("\n\n", "## FORMULAS", @formulas);
    }

    return undef;
}

sub make_programs ($entry) {
    return undef;
}

sub make_xrefs ($entry) {

    if (not exists $entry->{xref}) {
        return undef;
    }

    my @xrefs;
    foreach my $xref (@{$entry->{xref}}) {
        push @xrefs, resolve_links($xref);
    }

    if (@xrefs) {
        return join("\n\n", "## CROSS REFERENCES", @xrefs);
    }

    return undef;
}

sub make_author ($entry) {
    if (exists $entry->{author}) {
        my $author = resolve_links($entry->{author});

        if (exists $entry->{created}) {
            my $date = Time::Piece->new(Date::Parse::str2time($entry->{created}));
            $author .= " (" . $date->strftime("%B %d %Y") . ')';
        }

        return "## AUTHOR\n\n" . $author;
    }
    return undef;
}

sub make_links ($entry) {

    #~ if (not exists $entry->{link}) {
        #~ return undef;
    #~ }

    my @links;

    push @links,
      sprintf("* The Online Encyclopedia of Integer Sequences, [A%06d](https://oeis.org/A%06d).",
              $entry->{number}, $entry->{number});

    foreach my $link (@{$entry->{link}}) {
        next if $link =~ m{a href="/index/};
        push @links, "* " . resolve_html_links($link);
    }

    if (@links) {
        return join("\n\n", "## SEE ALSO", @links);
    }

    return undef;
}

sub process_entry($entry) {

    return if !exists($entry->{number});
    return if !exists($entry->{name});
    return if !exists($entry->{offset});

    return if $entry->{keyword} =~ /dead|dumb|obsc|uned|unkn/;

    my @content;
    push @content, make_name($entry);
    push @content, make_data($entry);
    push @content, make_offset($entry);
    push @content, make_comments($entry);
    push @content, make_properties($entry);
    push @content, make_formulas($entry);
    push @content, make_programs($entry);
    push @content, make_xrefs($entry);
    push @content, make_author($entry);
    push @content, make_links($entry);

    @content = grep { defined($_) } @content;

    my $markdown = join("\n\n", @content);
    my $file     = catfile($dir, "G" . $entry->{number} . '.md');

    open my $fh, '>', $file;
    say $fh $markdown;
    close $fh;
}

foreach my $file (glob('*.zip')) {

    say STDERR "Processing: $file";

    my $z = IO::Uncompress::Unzip->new($file);

    while ($z->nextStream) {
        my $entry = "";
        while (defined(my $line = $z->getline)) {
            $entry .= $line;
        }
        process_entry(decode_json($entry));
    }
}
