#!/usr/bin/perl

## user configuration

$qt_major_version = "5.15";
$qt_minor_version = "8";
$qwt_version      = "6.1.6";
$src_dir          = "$ENV{HOME}/src";  ## where qt qwt etc will be compiled
$nprocs           = `nproc` + 1;

## end user configuration

$qt_version = "$qt_major_version.$qt_minor_version";

use File::Basename;
$scriptdir = dirname(__FILE__);
require "$scriptdir/utility.pm";

$notes = "usage: $0 run

installs needed components for building us3 
will use $nprocs processors for parallel makes

";

$opt = shift || die $notes;
die "unknown option $opt\n" if $opt !~ /^run$/i;

@pkgs = (
    "git"
    ,"emacs"
    ,"base-devel"
    ,"openssl-devel"
#    ,"mingw-w64-x86_64-toolchain"
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
#    ,"-R mingw-w64-x86_64-gcc"
    ,"https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-libs-10.3.0-8-any.pkg.tar.zst"
    ,"https://repo.msys2.org/mingw/mingw64/mingw-w64-x86_64-gcc-10.3.0-8-any.pkg.tar.zst"
    );

@pkgs = ();

## setup $src_dir

mkdir $src_dir if !-d $src_dir;
die "$src_dir does not exist as a directory\n" if !-d $src_dir;


# install initial pkgs first
$debug = 1;

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


## download qt

$qtfile = "$src_dir/qt-everywhere-opensource-src-$qt_version.tar.xz";
if ( -e $qtfile ) {
    warn "NOTICE: $qtfile exists, not downloading again. Remove if you want a fresh download\n";
} else {
    $cmd = "cd $src_dir && wget https://download.qt.io/archive/qt/$qt_major_version/$qt_version/single/qt-everywhere-opensource-src-$qt_version.tar.xz";
    print run_cmd( $cmd );
}

## extract qt
$qtsrcname = "qt-everywhere-src-$qt_version";
$qtsrcdir  = "$src_dir/$qtsrcname";
if ( -d $qtsrcdir ) {
    warn "NOTICE: $qtsrcdir exists, not extracting again. Remove if you want a fresh extract\n";
} else {
    $cmd = "cd $src_dir && tar Jxf $qtfile";
    print run_cmd( $cmd );
}
    
## make shadow
$qtshadow = "$qtsrcdir/shadow-build";

if ( -d $qtshadow ) {
    $cmd = "rm -fr $qtshadow";
    warn "NOTICE: removing old qt $qtshadow";
    run_cmd( $cmd );
}

mkdir $qtshadow;
die "could not create directory $qtshadow\n" if !-d $qtshadow;

## remove d3d12 because https://aur.archlinux.org/cgit/aur.git/tree/0003-Disable-d3d12-requiring-fxc.exe.patch?h=mingw-w64-qt5-declarative

$cmd = "sed -i 's/^qtConfig\(d3d12/# qtConfig\(d3d12/' $qtsrcdir/qtdeclarative/src/plugins/scenegraph/scenegraph.pro";
run_cmd( $cmd );

## configure qt
$qtinstalldir = "$src_dir/qt-$qt_version";

$cmd = "cd $qtshadow && MAKEFLAGS=-j$nprocs ../configure -prefix $qtinstalldir -release -opensource -confirm-license -nomake tests -nomake examples -system-proxies -D QT_SHAREDMEMORY -D QT_SYSTEMSEMAPHORE -no-icu -platform win32-g++ -plugin-sql-mysql MYSQL_INCDIR=/mingw64/include/mariadb MYSQL_LIBDIR=/mingw64/lib -openssl-linked -opengl desktop -plugin-sql-psql PSQL_LIBDIR=/mingw64/lib PSQL_INCDIR=/mingw64/include/postgresql > ../last_configure.stdout 2> ../last_configure.stderr";

print run_cmd( $cmd );

## make qt
# export MSYS2_ARG_CONV_EXCL='*'  only needed to build all or a specific pkg?

$cmd = "cd $qtshadow && MSYS2_ARG_CONV_EXCL='*' make -j$nprocs -k > ../build.stdout 2> ../build.stderr";
print run_cmd( $cmd );

### make install

$cmd = "cd $qtshadow && make -j1 -k install > ../install.stdout 2> ../install.stderr";
print run_cmd( $cmd );

### make & install qtdatavis3d


## download qwt
$qwtfile = "$src_dir/qwt-$qwt_version.tar.bz2";
if ( -e $qwtfile ) {
    warn "NOTICE: $qwtfile exists, not downloading again. Remove if you want a fresh download\n";
} else {
    ## possible alternative source
    ## https://sourceforge.net/project/qwt/files/qwt/$qwt_version/qwt-$qwt_version.tar.bz2/download
    ## https://gigenet.dl.sourceforge.net/project/qwt/qwt/$qwt_version/qwt-$qwt_version.tar.bz2
    ## https://versaweb.dl.sourceforge.net/project/qwt/qwt/$qwt_version/qwt-$qwt_version.tar.bz2
    $cmd = "cd $src_dir && wget --no-check-certificate https://versaweb.dl.sourceforge.net/project/qwt/qwt/$qwt_version/qwt-$qwt_version.tar.bz2";
    print run_cmd( $cmd );
}


## make qwt

## download ultrascan

## configure & build ultrascan?

## setup qt5env




