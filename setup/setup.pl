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
    ,"mingw-w64-x86_64-crt-git"
    ,"mingw-w64-x86_64-libmariadbclient"
    ,"procps"
    ,"mingw-w64-x86_64-libwinpthread-git"
    ,"mingw-w64-x86_64-winpthreads-git"
    ,"mingw-w64-x86_64-postgresql"
    ,"mingw-w64-x86_64-doxygen"
    ,"mingw-w64-x86_64-texlive-latex-recommended"
    ,"mercurial"
    ,"cvs"
    ,"wget"
    ,"p7zip"
    ,"perl"
    ,"ruby"
    ,"python3"
    ,"mingw-w64-x86_64-toolchain"
    );


# install initial pkgs first
$debug = 1;

foreach $p ( @pkgs ) {
    $cmd = "pacman -S --noconfirm --needed $p";
    run_cmd( $cmd );
}
    
