#
# Copyright 2006-2008 Inverse groupe conseil
#
# See the enclosed file COPYING for license information (GPL).
# If you did not receive this file, see
# http://www.fsf.org/licensing/licenses/gpl.html
#

package pf::SNMP::Dell::PowerConnect3424;

=head1 NAME

pf::SNMP::Dell::PowerConnect3424 - Object oriented module to access SNMP enabled Dell PowerConnect3424 switches


=head1 SYNOPSIS

The pf::SNMP::Dell::PowerConnect3424 module implements an object oriented interface to access SNMP enabled Dell:PowerConnect3424 switches.

=cut

use strict;
use warnings;
use diagnostics;
use Data::Dumper;
use Log::Log4perl;
use Net::Telnet;

use base ('pf::SNMP::Dell');

sub _setVlan {
    my ($this,$ifIndex,$newVlan,$oldVlan,$switch_locker_ref) = @_;
    my $logger = Log::Log4perl::get_logger("pf::SNMP::Dell::PowerConnect3424");
    my $session;

    eval {
        $session = new Net::Telnet(Host => $this->{_ip}, Timeout => 20);
        #$session->dump_log();
        $session->waitfor('/Password:/');
        $session->print($this->{_telnetPwd});
        $session->waitfor('/>/');
    };
    if ($@) {
        $logger->info("ERROR: Can not connect to switch $this->{'_ip'} using Telnet");
        die;
    }

    $session->print('enable');
    $session->waitfor('/Password:/');
    $session->print($this->{_telnetEnablePwd});
    $session->waitfor('/#/');
    $session->print('configure');
    $session->waitfor('/\(config\)#/');
    $session->print('interface ethernet e' . $ifIndex);
    $session->waitfor('/\(config-if\)#/');
    $session->print('switchport access vlan ' .$newVlan);
    $session->waitfor('/\(config-if\)#/');
    $session->print("end");
    $session->waitfor('/#/');

    $session->close();
    return 1;

}

1;

# vim: set shiftwidth=4:
# vim: set expandtab:
# vim: set backspace=indent,eol,start:
