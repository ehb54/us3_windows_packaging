#!/usr/bin/perl

$distd = "$ENV{HOME}/dist"; 

$notes = "usage: $0 revision

makes a /c/dist-$revision directory
copies needed files
builds a template for createinstall free

";

$rev = shift || die $notes;

sub line {
    return '-'x80 . "\n";
}

sub hdrline {
    my $msg = shift;
    return line() . "$msg\n" . line();
}

$run_cmd_last_error;

sub run_cmd {
    my $cmd       = shift || die "run_cmd() requires an argument\n";
    my $no_die    = shift;
    my $repeattry = shift;
    print "$cmd\n" if $debug;
    $run_cmd_last_error = 0;
    my $res = `$cmd`;
    if ( $? ) {
        $run_cmd_last_error = $?;
        if ( $no_die ) {
            warn "run_cmd(\"$cmd\") returned $?\n";
            if ( $repeattry > 0 ) {
                warn "run_cmd(\"$cmd\") repeating failed command tries left = $repeattry )\n";
                return run_cmd( $cmd, $no_die, --$repeattry );
            }
        } else {
            error_exit( "run_cmd(\"$cmd\") returned $?" );
        }
    }

    chomp $res;
    return $res;
}

sub run_cmd_last_error {
    return $run_cmd_last_error;
}

sub error_exit {
    my $msg = shift;
    die "$msg\n";
}

use File::Basename;

$scriptpath = dirname(__FILE__);

$targetd = "$distd-$rev";

die "$targetd is a file, please rename or remove and try again\n" if -e $targetd && !-d $targetd;

mkdir $targetd if !-e $targetd;

die "count not create $targetd\n" if !-d $targetd;

$citemplate = "$scriptpath/../ci/UltraScan3.ci.template";
$cioutput   = "$targetd/UltraScan3-$rev.ci";

die "$citemplate does not exist\n" if !-e $citemplate;

print hdrline( "distribution will be placed in $targetd" );

## make install script
$distd_win = "/msys64$distd";
$distd_win =~ s/\//\\\\/g;

push @cmds, "sed 's/__distdir__/$distd_win/g' $citemplate | sed 's/__version__/$rev/g' > $cioutput";

## copy files

@tocopy = (
    "bin"
    ,"LICENSE.txt"
    ,"somo/doc"
    ,"somo/demo"
    ,"etc"
    );

for $d ( @tocopy ) {
    die "expected file $d does not exist!\n" if !-e $d;
    if ( !-d $d ) {
        push @cmds, "cp $d $targetd/$d";
    } else {
        if ( -e "$targetd/$d" ) {
            push @cmds, "rm -fr $targetd/$d/* 2> /dev/null";
        } else {
            push @cmds, "mkdir -p $targetd/$d 2> /dev/null";
        }
        push @cmds, "rsync -av --delete $d/* $targetd/$d";
    }
}

# print join "\n", @cmds;
# print "\n";

$debug++;
for $cmd ( @cmds ) {
    print run_cmd( $cmd ) . "\n";
}

print hdrline( "now run createinstall from the gui and load '/c/msys64/$cioutput'" );

