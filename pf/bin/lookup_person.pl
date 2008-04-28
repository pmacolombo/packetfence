#
# $Id: lookup_person.pl,v 1.2 2005/11/17 21:47:08 dgehl Exp $
#
# Copyright 2005 Dave Laporte <dave@laportestyle.org>
# Copyright 2005 Kevin Amorin <kev@amorin.org>
#
# See the enclosed file COPYING for license information (GPL).
# If you did not receive this file, see
# http://www.fsf.org/licensing/licenses/gpl.html.
#

# define this function to return whatever data you'd like
# it's called via "pfcmd lookup person <pid>", through the administrative GUI,
# or as the content of a violation action

sub lookup_person {
  my($pid) = @_;
  if (person_exist($pid)) {
    return($pid);
  } else {
    return("Person $pid is not a registered user!\n");
  }
}

return(true);
