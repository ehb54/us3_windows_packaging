#!/usr/bin/perl

use File::Basename;
$scriptdir = dirname(__FILE__);
require "$scriptdir/utility.pm";

$notes = "usage: $0 run

installs needed components for building us3

";

$opt = shift || die $notes;
die "unknown option $opt\n" if $opt !~ /^run$/i;

@pkgs = (
    "git"
    ,"emacs"
    ,"base-devel"
    ,"openssl-devel"
    ,"mingw-w64-x86_64-toolchain"
    ,"mingw-w64-x86_64-crt-git"
    ,"mingw-w64-x86_64-libmariadbclient"
    ,"procps"
    ,"mingw-w64-x86_64-libwinpthread-git"
    ,"mingw-w64-x86_64-winpthreads-git"
    ,"mingw-w64-x86_64-postgresql"
    ,"mingw-w64-x86_64-doxygen"
    ,"mingw-w64-x86_64-harfbuzz"
    ,"mingw-w64-x86_64-libtiff"
    ,"mingw-w64-x86_64-texlive-latex-recommended"
    ,"mercurial"
    ,"cvs"
    ,"wget"
    ,"p7zip"
    ,"perl"
    ,"ruby"
    ,"python3"
    ,"https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-libs-10.3.0-8-any.pkg.tar.zst"
    ,"https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-10.3.0-8-any.pkg.tar.zst"
    );

@pkgs = (
    "https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-libs-10.3.0-8-any.pkg.tar.zst"
    ,"https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-10.3.0-8-any.pkg.tar.zst"
    );


# install initial pkgs first
$debug = 1;

for my $p ( @pkgs ) {

    my $cmd = "pacman";
    $cmd .= $p =~ /^https/ ? " -U" : " -S";
    $cmd .= " --noconfirm --needed $p";

    $ok  = 0;
    do {
        my $res = run_cmd( $cmd, true );
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
        my $res = run_cmd( $cmd, true );
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
