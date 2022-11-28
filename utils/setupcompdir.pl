#!/usr/bin/perl

use File::Basename;

$scriptpath = dirname(__FILE__);

$notes = "usage: $0 dest

copies relevants mods to dest directory

";

$dest = shift || die $notes;

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

die "$dest is not a directory\n" if !-d $dest;

$base = "$scriptpath/../mods/win10-mingw64-latest";

$dest_sed = $dest;
$dest_sed =~ s/\//\\\//g;
    
@files = `cd $base && find * -type f | grep -v \\~`;
grep chomp, @files;
for $f ( @files ) {
    print "file $f\n";
    push @cmds, "sed 's/__ultrascandir__/$dest_sed/g' $base/$f > $dest/$f";
}

# print join "\n", @cmds;
# print "\n";
$debug++;
for $cmd ( @cmds ) {
    print run_cmd( $cmd );
}

