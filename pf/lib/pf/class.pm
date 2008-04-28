#
# $Id: class.pm,v 1.2 2005/11/17 21:34:56 dgehl Exp $
#
# Copyright 2005 David LaPorte <david@davidlaporte.org>
# Copyright 2005 Kevin Amorin <kev@amorin.org>
#
# See the enclosed file COPYING for license information (GPL).
# If you did not receive this file, see
# http://www.fsf.org/licensing/licenses/gpl.html.
#

package pf::class;

use strict;
use warnings;

our ($class_view_sql, $class_exist_sql, $class_add_sql, $class_delete_sql, $class_cleanup_sql,
     $class_modify_sql, $class_view_all_sql, $class_view_actions_sql, $class_trappable_sql);

BEGIN {
  use Exporter ();
  our (@ISA, @EXPORT);
  @ISA    = qw(Exporter);
  @EXPORT = qw(class_db_prepare class_view class_view_all class_trappable class_view_actions class_add class_delete class_merge);
}


use lib qw(/usr/local/pf/lib);
use pf::config;
use pf::util;
use pf::db;
use pf::action qw(action_delete_all action_add);
use pf::trigger qw(trigger_add);

class_db_prepare($dbh) if (!$thread);

sub class_db_prepare {
  my ($dbh) = @_;
  $class_view_sql=$dbh->prepare( qq [ select class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable,group_concat(action.action order by action.action asc) as action from class left join action on class.vid=action.vid where class.vid=? GROUP BY class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable ]);
  $class_view_all_sql=$dbh->prepare( qq [ select class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable,group_concat(action.action order by action.action asc) as action from class left join action on class.vid=action.vid GROUP BY class.vid,class.description,class.auto_enable,class.max_enables,class.grace_period,class.priority,class.url,class.max_enable_url,class.redirect_url,class.button_text,class.disable ] );
  $class_view_actions_sql=$dbh->prepare( qq [ select vid,action from action where vid=? ]);
  $class_exist_sql=$dbh->prepare( qq [ select vid from class where vid=? ]);
  $class_delete_sql=$dbh->prepare( qq [ delete from class where vid=? ]);
  $class_add_sql=$dbh->prepare( qq [ insert into class(vid,description,auto_enable,max_enables,grace_period,priority,url,max_enable_url,redirect_url,button_text,disable) values(?,?,?,?,?,?,?,?,?,?,?) ]);
  $class_modify_sql=$dbh->prepare( qq [ update class set description=?,auto_enable=?,max_enables=?,grace_period=?,priority=?,url=?,max_enable_url=?,redirect_url=?,button_text=?,disable=? where vid=? ]);
  $class_cleanup_sql=$dbh->prepare( qq [ delete from class where vid not in (?) and vid < 1200000 and vid > 1200100 ]);
  $class_trappable_sql=$dbh->prepare( qq [select c.vid,c.description,c.auto_enable,c.max_enables,c.grace_period,c.priority,c.url,c.max_enable_url,c.redirect_url,c.button_text,c.disable from class c left join action a on c.vid=a.vid where a.action="trap" ]);
}

sub class_exist {
  my ($id) = @_;
  $class_exist_sql->execute($id) || return(0);
  my ($val) = $class_exist_sql->fetchrow_hashref();
  $class_exist_sql->finish();
  return($val);
}

sub class_view {
  my ($id) = @_;
  $class_view_sql->execute($id) || return(0);
  my ($val) = $class_view_sql->fetchrow_hashref();
  $class_view_sql->finish();
  return($val);
}

sub class_view_all {
  return db_data($class_view_all_sql);
}

sub class_trappable {
  return db_data($class_trappable_sql);
}

sub class_view_actions {
  my ($id) = @_;
  return db_data($class_view_actions_sql,$id);
}

sub class_add {
  my $id = $_[0];
  if (class_exist($id)) {
    pflogger("attempt to add existing class $id", 1);
    return(2);
  }
  $class_add_sql->execute(@_) || return(0);
  pflogger("class $id added", 2);
  return(1);
}

sub class_delete {
  my ($id) = @_;
  $class_delete_sql->execute($id) || return(0);
  pflogger("class $id deleted", 2);
  return(1)  
}

sub class_cleanup {
  $class_cleanup_sql->execute() || return(0);
  pflogger("class cleanup completed", 2);
  return(1)  
}

sub class_modify {
  my $id = shift(@_);
  push(@_, $id);
  if (class_exist($id)) {
    pflogger("modify existing existing class $id", 1);
  }
  $class_modify_sql->execute(@_) || return(0);
  pflogger("class $id modified", 2);
  return(1);
}

sub class_merge {
  my $id = shift(@_);
  my $triggers = pop(@_);
  my $actions = pop(@_);

  pflogger("inserting $id",4);
  # delete existing violation actions
  if (!action_delete_all($id)) {
    pflogger("error deleting actions for class $id",1);
    return(0);
  }

  unshift(@_, $id);
  #Check for violations
  if (class_exist($id)) {
    class_modify(@_);
  } else {
    #insert violation class
    class_add(@_);
  }

  # add violation actions
  foreach my $action (split(/\s*,\s*/, $actions)) {
    action_add($id,$action);
  }
  
  #Add scan table id's -> violation class maps
  if (scalar(@{$triggers}) > 0) {
    foreach my $array (@{$triggers}) {
      my ($tid_start,$tid_end,$type) = @{$array};
      trigger_add($id,$tid_start,$tid_end,$type);
    }
  }

  
}

1
