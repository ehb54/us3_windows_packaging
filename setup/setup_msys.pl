#!/usr/bin/perl

die "This script must be run under the MSYS shell\n" if $ENV{MSYSTEM} ne 'MSYS';

## user configuration

$debug            = 1; ## primarily prints commands as they are run

## end user configuration

use File::Basename;
use Cwd 'abs_path';
$scriptdir =  dirname( abs_path( __FILE__ ) );

require "$scriptdir/utility.pm";

initopts(
    "all",    "", "setup everything", 0
    ,"msys2", "", "setup msys2 pacman packages", 0
    ,"tpage", "", "install tpage", 0
    ,"help",  "", "print help", 0
    );

$notes = "usage: $0 options

installs needed components for building us3

" . descopts() . "\n";

procopts();
if ( @ARGV ) {
    error_exit( "unrecognized command line option(s) : " . join( ' ', @ARGV ) . "\n---\n$notes" );
}

if ( !$opts_count || $opts{help}{set} ) {
    print $notes;
    exit;
}

@pkgs = (
    "msys2-devel"
#    ,"msys2-runtime-devel"
    ,"libcrypt-devel"
    ,"libexpat-devel"
    ,"make"
    );

# install initial pkgs first
if ( $opts{msys2}{set} || $opts{all}{set} ) {
    print line('=');
    print "processing msys2\n";
    print line('=');
    
    for my $p ( @pkgs ) {

        my $cmd = "pacman";
        if ( $p =~ /^-R/ ) {
            $p =~ s/^-R //;
            $cmd .= " -R --noconfirm $p";
        } else {
            $cmd .= $p =~ /^https/ ? " -U" : " -S";
            $cmd .= " --noconfirm --needed $p";
        }

        $ok  = 0;
        do {
            print line();
            my $res = run_cmd( $cmd, true );
            print "$res\n";
            if ( run_cmd_last_error() ) {
                ## recursively try to remove any dependencies
                error_exit( "exiting due to errors\n" ) if $res !~ /breaks dependency/m;
                my @l = split /\n/, $res;
                for my $l ( @l ) {
                    my ( $dep ) = $l =~ /breaks dependency .* required by (\S+)\s*$/;
                    if ( $dep ) {
                        remove_pkg( $dep );
                    }
                }
            } else {
                $ok = 1;
            }
        }
        while( !$ok );
    }

    sub remove_pkg {
        my $pkg = shift;
        my $cmd = "pacman -R --noconfirm $pkg";
        
        do {
            print line();
            my $res = run_cmd( $cmd, true );
            print "$res\n";
            if ( run_cmd_last_error() ) {
                ## recursively try to remove any dependencies
                error_exit( "exiting due to errors\n" ) if $res !~ /breaks dependency/m;
                my @l = split /\n/, $res;
                for my $l ( @l ) {
                    my ( $dep ) = $l =~ /breaks dependency .* required by (\S+)\s*$/;
                    if ( $dep ) {
                        remove_pkg( $dep );
                    }
                }
            } else {
                $ok = 1;
            }
        }
        while( !$ok );
    }
}

if ( $opts{tpage}{set} || $opts{all}{set} ) {
    print line('=');
    print "processing tpage\n";
    print line('=');

    # 2024.05.23 MSYS2 HTTP::Tiny doesn't find the CA bundle
    $cmd = "mkdir -p /etc/ssl/certs; cp -p /usr/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt";
    print run_cmd( $cmd );

    ## for dependencies, but doesn't seem to matter
    # my $cmd = "/usr/bin/core_perl/cpan Test YAML XML::Parser Log::Log4perl Template";
    my $cmd = "/usr/bin/core_perl/cpan AppConfig Template";
    print run_cmd( $cmd );
}
