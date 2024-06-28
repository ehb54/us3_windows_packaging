## perl utilities for setup

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
    die "ERROR: $msg\n";
}

sub line {
    my $char = shift;
    $char = '-' if !$char;
    ${char}x80 . "\n";
}

%opts = ();

@ordered_opts;

sub initopts {
    %opts = ();
    for ( my $i = 0; $i < scalar @_; $i += 4 ) {
        if ( !exists $_[$i+1] || !exists $_[$i+2] || !exists $_[$i+3] ) {
            error_exit( "initopt requires four arguments for each option" );
        }
        push @ordered_opts, $_[$i];
        $opts{$_[$i]}{argdesc} = $_[$i+1];
        $opts{$_[$i]}{desc}    = $_[$i+2];
        $opts{$_[$i]}{count}   = $_[$i+3];
    }
}

sub descopts {
    my $out;
    for my $k ( @ordered_opts ) {
        $out .= sprintf( " --%-20s : %s\n", "$k $opts{$k}{argdesc}", $opts{$k}{desc} );
    }
    $out;
}
    
sub procopts {
    $opts_count = 0;
    while ( exists $ARGV[0] && $ARGV[0] =~ /^--/ ) {
        my $opt = shift @ARGV;
        $opt =~ s/^--//;
        if ( !exists $opts{$opt} ) {
            error_exit( "unrecognized command line option --$opt\n---\n$notes" );
        }
        if ( $opts{$opt}{count} ) {
            for ( my $i = 0; $i < $opts{$opt}{count}; ++$i ) {
                if ( !exists $ARGV[0] ) {
                    error_exit( "missing argument : --$opt requires $opts{$opt}{count} argument(s)\n---\n$notes" );
                }
                $opts{$opt}{args}[$i] = shift @ARGV;
            }
        }
        $opts{$opt}{set} = 1;
        ++$opts_count;
    }
}

1;
