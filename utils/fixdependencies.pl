#!/usr/bin/perl

use warnings;
$debug   = 0;
$logfile = "fixdeps.log";

die qq[environment variable QTDIR must be defined, perhaps by ". qt5env"\n] if !$ENV{QTDIR};
die qq[environment variable QWTDIR must be defined, perhaps by ". qt5env"\n] if !$ENV{QWTDIR};
die "$ENV{QTDIR} does not exist as a directory\n" if !-d $ENV{QTDIR};
die "$ENV{QWTDIR} does not exist as a directory\n" if !-d $ENV{QWTDIR};

$notes = "usage: $0 (list|update)

finds all libs of everything in bin

update will copy needed libraries if found

";

$opt = shift || die $notes;

die $notes if $opt !~ /^(update|list)$/;

$update++ if $opt eq 'update';

sub line {
    return '-'x80 . "\n";
}

sub hdrline {
    my $msg = shift;
    return line() . "$msg\n" . line();
}

use File::Basename;
use File::Compare;

$scriptpath = dirname(__FILE__);

## get apps

@apps = `find bin -type f`;

## prune apps

@apps = grep !/(win64|linux64|osx1|manual\.q|\.a$|rasmol|plugins)/, @apps;

## get libs

@libs = `find lib -type f | grep -Pv '\\.a\$'`;
grep chomp, @libs;

## collect all to check

push @all, @apps;

if ( $debug ) {
    open  $debuglog, ">>$logfile";
    print $debuglog `date`;
    print $debuglog "all:\n";
    print $debuglog join '', @all;
    print $debuglog "\n";
    print $debuglog "apps:\n";
    print $debuglog join '', @apps;
    print $debuglog "\n";
    print $debuglog "libs:\n";
    print $debuglog join "\n", @libs;
    print $debuglog "\n";
}
grep chomp, @all;

## check if lib is present in bin
for $f ( @libs ) {
    my $l = $f;
    $l =~ s/^lib/bin/;
    if ( compare( $l, $f ) ) {
        $tochecks{$l}++;
        $copyfrom{$l} = $f;
        $forcecopy{$l}++;
    }
}

for $f ( @all ) {
    print $debuglog "checking $f\n" if $debug;
    {
        my @extra = `ldd $f | grep -vi WINDOWS | grep -v 'not found' | awk '{ print \$3 }' | sort -u`;
        grep chomp, @extra;
        foreach my $j ( @extra ) {
            my $d = $j;
            $d =~ s/^.*\///g;
            print $debuglog "checking $f : found lib bin/$d from $j\n" if $debug;
            $tochecks{"bin/$d"}++;
            $copyfrom{"bin/$d"} = $j if !$copyfrom{"bin/$d"};
        }
    } 
    {
        my @extra = `ldd $f | grep -vi WINDOWS | grep 'not found' | awk '{ print \$1 }' | sort -u`;
        grep chomp, @extra;
        foreach my $j ( @extra ) {
            print $debuglog "checking $f : not found lib $j\n" if $debug;
            $tochecks{"bin/$j"}++;
        }
    }
}

## remove unneeded
@unneeded = (
    "bin/*.a"
    ,"bin/*_linux64*"
    ,"bin/*_osx*"
    );

for $p ( @unneeded ) {
    for my $f ( glob $p ) {
        $toremoves{$f}++;
    }
}

my $cmds;

## extra checks

@extras = (
    "bin/rasmol.exe"
    ,"bin/rasmol.hlp"
    ,"bin/tar.exe"
    ,"bin/manual.qch"
    ,"bin/assistant.exe"
    ,"bin/plugins"
    );

%known_source = (
    "bin/assistant.exe" => "$ENV{QTDIR}/bin/assistant.exe"
    ,"bin/plugins"      => "$ENV{QTDIR}/plugins"
    ,"bin/qwt.dll"      => "$ENV{QWTDIR}/lib/qwt.dll"
    );

for $f ( @extras ) {
    if ( !-e $f ) {
        $tochecks{ $f }++;
        $copyfrom{ $f } = $known_source{$f} if exists $known_source{$f};
    }
}

$revfile = "programs/us/us_revision.h";
if ( !-e $revfile ) {
    $errorsum .= "ERROR: revision file $revfile is missing\n";
} else {
    $rev = `awk -F\\" '{ print \$2 }' $revfile`;
    chomp $rev;
}

### begin reports

print hdrline( "todos" );
for $d ( sort { $a cmp $b } keys %todos ) {
    print "$d\n    " . $todos{$d} . "\n";
}    
$errorsum .= "WARNING: todos present, must be fixed before packaging\n" if keys %todos;

print hdrline( "missing" );
print join "\n", sort { $a cmp $b } keys %missing;
print "\n" if keys %missing;

print hdrline( "toremoves" );
print join "\n", sort { $a cmp $b } keys %toremoves;
print "\n" if keys %toremoves;

### checks
print hdrline( "checking existence of libraries and other files" );
print hdrline( "tochecks" );

for $d ( sort { $a cmp $b } keys %tochecks ) {
    if ( -e $d && !$forcecopy{$d} ) {
        print "ok: $d\n";
    } else {
        my $err = "ERROR: missing: $d - ";
        if ( $copyfrom{ $d } ) {
            $err .= "copy from " .  $copyfrom{ $d };
            $cmds .= "cp -rp " . $copyfrom{ $d } . " $d\n";
        } else {
            if ( $known_source{$d} ) {
                $err .= "copy from " .  $known_source{ $d };
                $cmds .= "cp -rp " . $known_source{ $d } . " $d\n";
            } else {
                $err .= "unknown source";
            }
        }
        print "$err\n";
        $errorsum .= "$err\n";
    }
}

for $d ( sort { $a cmp $b } keys %toremoves ) {
    $cmds .= "rm $d\n";
    $err  = "file to be removed: $d";
    $errorsum .= "$err\n";
}

if ( $warnings ) {
    print hdrline( "warnings" );
    print $warnings;
    print $debuglog hdrline( "warnings" ) if $debug;
    print $debuglog $warnings if $debug;
}

if ( $errorsum ) {
    print hdrline( "error summary" );
    print $errorsum;
    print $debuglog hdrline( "error summary" ) if $debug;
    print $debuglog $errorsum if $debug;
}

if ( $rev && !keys %todos && !$errorsum && !$cmds ) {
    my $branch = `git branch --show-current`;
    chomp $branch;
    $branch = "" if $branch =~ /^(master|main)$/;
    $branch = "-$branch" if $branch;
    my $cmd = "$scriptpath/makepkgdir.pl $rev$branch";
    print hdrline( "build package commands" );
    print "$cmd\n";
    print $debuglog hdrline( "build package commands" ) if $debug;
    print $debuglog "$cmd\n" if $debug;
    exit;
}

print hdrline( "cmds" );
print $cmds;

if ( $cmds && $update ) {
    print `$cmds`;
    print "WARNING: rerun until no cmds nor ERRORs left\n";
}

die "not ready for packaging\n" if $cmds || keys %todos || $errorsum;
