use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Audio::Ecasound',
    VERSION_FROM    => 'Ecasound.pm', 
    PREREQ_PM        => {}, # e.g., Module::Name => 1.1
    # the -lkvutils shouldn't be required
    LIBS            => ['-lecasoundc -lkvutils'], 
    INC                => '', 
    ABSTRACT_FROM    => 'Ecasound.pm', 
    AUTHOR            => 'Brad Bowman <eci-perl@bowman.bs>', 
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
This is likely to cause problems loading the multithreaded
library ecasoundc  (hanging on loading).  
You are welcome to try anyway...
EOT
                print "Proceed anyway? ";
                for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                    if(/^n/i) { print "Aborting\n"; exit; }
                    if(/^y/i) { print "Continuing\n"; last; }
                }
            }
            
            # ecasound < 2.0.1 didn't have reentrant C interface
            my $eca_version = `ecasoundc-config --version`;
            if(!defined($eca_version)) {
                warn "Running ecasoundc-config failed: $!\n";
                
                print <<EOT;
The ecasoundc-config program is used to find the version of the
ecasoundc library.  You need 2.0.1 or higher.
EOT
                print "Proceed anyway? ";
                for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                    if(/^n/i) { print "Aborting\n"; exit; }
                    if(/^y/i) { print "Continuing\n"; last; }
                }
            } else {
                chomp $eca_version;
                # Compare versions pre v-strings 
                my @ev = split /\./, $eca_version;
                unless($ev[0] >= 2 && $ev[1] >= 0 && $ev[2] >= 1) {
                    print <<EOT;
Version 2.0.1 of ecasound is required, you have $eca_version.
EOT
                    print "Proceed anyway (bad idea)? ";
                    for(print "(yn)\n"; $_ = <STDIN>; print "(yn)?\n") {
                        if(/^n/i) { print "Aborting\n"; exit; }
                        if(/^y/i) { print "Continuing\n"; last; }
                    }
                }
            }
            unless ($Config{ivsize} >= $Config{longsize}) {
                warn "long int is bigger than IV, may cause problems with last_long_interger";
            }
            return \%cfg;
        },
);
