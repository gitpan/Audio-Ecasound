use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Audio::Ecasound',
    VERSION_FROM    => 'Ecasound.pm', 
    PREREQ_PM        => {}, # e.g., Module::Name => 1.1
    # next two could be from libecasoundc-config --libs --cflags
    # not for now since want it to install w/o libecasoundc-config
    # (the -lkvutils shouldn't be required)
    #LIBS            => ['-lecasoundc -lkvutils'], 
    LIBS            => ['-lecasoundc'], 
    INC                => '',
    ABSTRACT_FROM    => 'Ecasound.pm', 
    AUTHOR            => 'Brad Bowman <eci-perl@bereft.net>', 
    dist            => { 
        # expand my tabs to 4
        PREOP => "(cd \$(DISTVNAME); \\
                    perl -MExtUtils::Manifest=maniread \\
                        -pi -e 'BEGIN{\@ARGV=keys \%{maniread()}; } \\
                                s/\\t/    /g' \\
                    )" },
    CONFIGURE         => 
        sub {
            my %cfg;
            use Config;

            unless ($Config{usethreads} eq 'define'
                ||  $Config{ccflags} =~ /\b-D_REENTRANT\b/) 
            {
                print <<EOT;
Your perl was not built with -Dusethreads or -D_REENTRANT
This may cause problems loading the multithreaded library 
ecasoundc  (hanging on loading).  It has worked fine for some.
You are welcome to try...
EOT
                print "Proceed anyway? ";
                for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                    if(/^n/i) { print "Aborting\n"; exit(1); }
                    if(/^y/i) { print "Continuing\n"; last; }
                }
            }
            
            # ecasound 2.4.4 http://www.eca.cx/ecasound-list/2006/12/0007.html
            # old: ecasound < 2.2 (v2.1dev8) mv'd headers and config prgm
            # old: ecasound < 2.0.1 didn't have reentrant C interface
            my $eca_version = `libecasoundc-config --version`;
            if(!defined($eca_version)) {
                warn "Running ecasoundc-config failed: $!\n";
                
                print <<EOT;
The ecasoundc-config program is used to find the version of the
ecasoundc library.  You need 2.4.5 or higher.
EOT
                print "Proceed anyway? ";
                for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                    if(/^n/i) { print "Aborting\n"; exit(1); }
                    if(/^y/i) { print "Continuing\n"; last; }
                }
            } else {
                chomp $eca_version;
                # Compare versions pre v-strings 
                my @ev = split /\./, $eca_version;
                # maj > 2 & rest >= 4.5
                unless($ev[0] >2 || ($ev[0] == 2 && "$ev[1].$ev[2]" >= '4.5')) {
                    print <<EOT;
Version 2.4.5+ of ecasound is required, you have $eca_version.
EOT
                    print "Proceed anyway (bad idea)? ";
                    for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                        if(/^n/i) { print "Aborting\n"; exit; }
                        if(/^y/i) { print "Continuing\n"; last; }
                    }
                }
            }
            unless ($ENV{ECASOUND}) {
                print <<EOT;

ECI now uses the "ECASOUND" env var to find the ecasound executable.
Set it correctly to suppress the library warning. 
(The PATH is searched so ECASOUND=ecasound usually works)

EOT
            }
            unless ($Config{ivsize} >= $Config{longsize}) {
                warn "long int is bigger than IV, may cause problems with last_long_interger\n";
            }
            return \%cfg;
        },
);
