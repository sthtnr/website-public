package WormBase::Web::Controller::REST;

use strict;
use warnings;
use parent 'Catalyst::Controller::REST';



__PACKAGE__->config(
   'default' => 'text/x-yaml',
    'map' => {
	'text/html'        => [ 'View', 'TT' ],
    });


=head1 NAME

WormBase::Web::Controller::REST - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 pages() pages_GET()

Return a list of all available pages and their URIs

TODO: This is currently just returning a dummy object

=cut
 
sub search_new :Path('/search_new')  :Args(2) {
    my ($self, $c, $type, $query) = @_;
     
    $c->stash->{'query'} = $query;
    if($type eq 'all' && !(defined $c->req->param("view"))) {
	$c->log->debug(" search all kinds...");
	$c->stash->{template} = "search/full_list.tt2";
	$c->stash->{type} =  [keys %{ $c->config->{pages} } ];
    } else {
	$c->log->debug("$type search");
	 
	my $api = $c->model('WormBaseAPI');
	my $class =  $c->req->param("class") || $type;
	my $search = $type;
	$search = "basic" unless  $api->search->meta->has_method($type);
	my $objs = $api->search->$search({class => $class, pattern => $query, config => $c});
	 
	if(defined $c->req->param("count") ) {
	    my $count=0;
	    $count= scalar @$objs if($objs);
	    $c->response->body($count);
#  	    $c->response->body($objs);
	}

	$c->stash->{'type'} = $type; 
	$c->stash->{'results'} = $objs;
	$c->stash->{noboiler} =  (defined $c->req->param("inline") ) ? 1:0;
        $c->stash->{template} = "search/results.tt2";
    }
}

 
sub search :Path('/rest/search') :Args(2) :ActionClass('REST') {}

sub search_GET {
    my ($self,$c,$class,$name) = @_; 
   
    unless ($c->stash->{object}) {
	
	# Fetch our external model
	my $api = $c->model('WormBaseAPI');
	
	# Fetch the object from our driver	 
	$c->log->debug("WormBaseAPI model is $api " . ref($api));
	$c->log->debug("The requested class is " . ucfirst($class));
	$c->log->debug("The request is " . $name);
	
	# Fetch a WormBase::API::Object::* object
	# But wait. Some methods return lists. Others scalars...
	$c->stash->{object} = $api->fetch({class=> ucfirst($class),
					   name => $name}) or die "$!";
    }
    my $object = $c->stash->{object};

    # TODO: Load up the data content.
    # The widget itself could make a series of REST calls for each field
    
    foreach my $field (@{$c->config->{pages}->{$class}->{search}->{fields}}) {
	my $data = $object->$field if  $object->meta->has_method($field);
	$c->stash->{'fields'}->{$field} = $data;
    }
 
 
    my $uri = $c->uri_for("/rest/search",$class,$name);
    $c->stash->{type}=$class;
    $c->stash->{id}=$name;
    $c->stash->{noboiler} = 1;
    if($class eq 'paper') {
	$c->stash->{template} = "search/$class.tt2";
    } else {
	$c->stash->{template} = "search/generic.tt2";
    }
    $c->forward('WormBase::Web::View::TT');

    $self->status_ok($c, entity => {
	class   => $class,
	name    => $name,
	uri     => "$uri"
		     }
	);
}




sub download : Path('/rest/download') :Args(0) :ActionClass('REST') {}

sub download_GET {
    my ($self,$c) = @_;
     
    my $filename=$c->req->param("type");
    $filename =~ s/\s/_/g;
    $c->response->header('Content-Type' => 'text/html');
    $c->response->header('Content-Disposition' => 'attachment; filename='.$filename);
#     $c->response->header('Content-Description' => 'A test file.'); # Optional line
#         $c->serve_static_file('root/test.html');
    $c->response->body($c->req->param("sequence"));
}



sub pages : Path('/rest/pages') :Args(0) :ActionClass('REST') {}

sub pages_GET {
    my ($self,$c) = @_;
    my @pages = keys %{ $c->config->{pages} };

    my %data;
    foreach my $page (@pages) {
	my $uri = $c->uri_for('/page',$page,'WBGene00006763');
	$data{$page} = "$uri";
    }

    $self->status_ok( $c,
		      entity => { resultset => {  data => \%data,
						  description => 'Available (dynamic) pages at WormBase',
				  }
		      }
	);
}



######################################################
#
#   WIDGETS
#
######################################################

=head2 available_widgets(), available_widgets_GET()

For a given CLASS and OBJECT, return a list of all available WIDGETS

eg http://localhost/rest/available_widgets/gene/WBGene00006763

=cut

sub available_widgets : Path('/rest/available_widgets') :Args(2) :ActionClass('REST') {}

sub available_widgets_GET {
    my ($self,$c,$class,$name) = @_;
#     my (@widgets) = @{ $c->config->{pages}->{$class}->{widget_order} };

    my @widgets = @{$c->config->{pages}->{$class}->{widgets}->{widget}};
    @widgets = map{$_->{name}} @widgets;
    
    my @data;
    foreach my $widget (@widgets) {
	my $uri = $c->uri_for('/widget',$class,$name,$widget);
	push @data, { widgetname => $widget,
				widgeturl  => "$uri"
	};
    }
    

    # Retain the widget order
    $self->status_ok( $c, entity => {
	data => \@data,
	description => "All widgets available for $class:$name",
		      }
	);
}

#
# The OLD widget approach,
# compiled from an independent 
# set of templates
# #
# sub widget_compiled :Path('/rest/widget') :Args(3) :ActionClass('REST') {}
# 
# sub widget_conpiled_GET {
#     my ($self,$c,$class,$name,$widget) = @_; 
# 
#     unless ($c->stash->{object}) {
# 	
# 	# Fetch our external model
# 	my $api = $c->model('WormBaseAPI');
# 	
# 	# Fetch the object from our driver	 
# 	$c->log->debug("WormBaseAPI model is $api " . ref($api));
# 	$c->log->debug("The requested class is " . ucfirst($class));
# 	$c->log->debug("The request is " . $name);
# 	
# 	# Fetch a WormBase::API::Object::* object
# 	# But wait. Some methods return lists. Others scalars...
# 	$c->stash->{object} = $api->fetch({class=> ucfirst($class),
# 					   name => $name}) or die "$!";
#     }
#     my $object = $c->stash->{object};
#     
# 
# 
#     # TODO: Load up the data content.
#     # The widget itself could make a series of REST calls for each field
#     my @fields;
#     foreach (my $widget_config = $c->config->{pages}->{$class}->{widgets}) {
# 	next unless $widget_config->{name} eq $widget; 
# 	@fields = @{ $widget_config->fields };
# 	$c->log->warn(@fields);
#     }
# #$c->config->{pages}->{$class}->{widgets}->{$widget} };
#     my $data = {};
#     foreach my $field (@fields) {
# 	my $data = $object->$field;
# 	$data->{$_} = $data;
# 
# 	# Conditionally load up the stash (for now) for HTML requests.
# 	# Eventually, I can ust format the return JSON.
# 	$c->stash->{$_} = $data;
#       
#     }
#     
#     # TODO: AGAIN THIS IS THE REFERENCE OBJECT
#     # PERHAPS I SHOULD INCLUDE FIELDS?
#     # Include the full uri to the *requested* object.
#     # IE the page on WormBase where this should go.
#     my $uri = $c->uri_for("/page",$class,$name);
#     
#     $c->stash->{template} = $self->_select_template($c,$widget,$class,'widget'); 
# 
#     $self->status_ok($c, entity => {
# 	class   => $class,
# 	name    => $name,
# 	uri     => "$uri",
# 	$widget => $data
# 		     }
# 	);
# } 





#
# The new widget approach, where all 
# widget template has everything we
# need.
# Really, all that changes is the nature of the template
# (and how component fields are called)

=head widget(), widget_GET()

Provided with a class, name, and field, return its content

eg http://localhost/rest/widget/[CLASS]/[NAME]/[FIELD]

=cut

sub widget :Path('/rest/widget') :Args(3) :ActionClass('REST') {}

sub widget_GET {
    my ($self,$c,$class,$name,$widget) = @_; 
    if($widget eq "references") {
      
      my $url= $c->uri_for("/search_new/paper/$name",{class=>$class,,inline=>1});
      $c->response->redirect($url);
      $c->detach;
#        $c->detach('/rest/search',['paper',$class,$name]);
    }
    unless ($c->stash->{object}) {
	
	# Fetch our external model
	my $api = $c->model('WormBaseAPI');
	
	# Fetch the object from our driver	 
	$c->log->debug("WormBaseAPI model is $api " . ref($api));
	$c->log->debug("The requested class is " . ucfirst($class));
	$c->log->debug("The request is " . $name);
	
	# Fetch a WormBase::API::Object::* object
	# But wait. Some methods return lists. Others scalars...
	$c->stash->{object} = $api->fetch({class=> ucfirst($class),
					   name => $name}) or die "$!";
    }
    my $object = $c->stash->{object};
    
    # TODO: Load up the data content.
    # The widget itself could make a series of REST calls for each field
    my @fields;
    foreach my $widget_config (@{$c->config->{pages}->{$class}->{widgets}->{widget}}) {
	# Janky-tastic.
	next unless $widget_config->{name} eq $widget; 
	@fields = @{ $widget_config->{fields} };
    }
    
    
    $c->log->debug("fields are " . @fields);
    $c->stash->{'widget'} = $widget;

    foreach my $field (@fields) {
	$c->log->debug($field);
        my $data = {};
	$data = $object->$field if defined $object->$field;

	# Conditionally load up the stash (for now) for HTML requests.
	# Eventually, I can just format the return JSON.
	$c->stash->{fields}->{$field} = $data; 
    }
    
    # TODO: AGAIN THIS IS THE REFERENCE OBJECT
    # PERHAPS I SHOULD INCLUDE FIELDS?
    # Include the full uri to the *requested* object.
    # IE the page on WormBase where this should go.
    my $uri = $c->uri_for("/page",$class,$name);
    $c->stash->{noboiler} = 1;
    $c->stash->{template} = $self->_select_template($c,$widget,$class,'widget'); 
    $c->forward('WormBase::Web::View::TT');

    $self->status_ok($c, entity => {
	class   => $class,
	name    => $name,
	uri     => "$uri"
		     }
	);
}




######################################################
#
#   FIELDS
#
######################################################

=head2 available_fields(), available_fields_GET()

Fetch all available fields for a given WIDGET, PAGE, NAME

eg  GET /rest/fields/[WIDGET]/[CLASS]/[NAME]


# This makes more sense than what I have now:
/rest/class/*/available_widgets  - all available widgets
/rest/class/*/widget   - the content for a given widget

/rest/class/*/widget/available_fields - all available fields for a widget
/rest/class/*/widget/field

=cut

sub available_fields : Path('/rest/available_fields') :Args(3) :ActionClass('REST') {}

sub available_fields_GET {
    my ($self,$c,$widget,$class,$name) = @_;
    my @fields = eval { @{ $c->config->{pages}->{$class}->{widgets}->{$widget} }; };

    my %data;
    foreach my $field (@fields) {
	my $uri = $c->uri_for('/rest/field',$class,$name,$field);
	$data{$field} = "$uri";
    }
    
    $self->status_ok( $c, entity => { data => \%data,
				      description => "All fields that comprise the $widget for $class:$name",
		      }
	);
}


=head field(), field_GET()

Provided with a class, name, and field, return its content

eg http://localhost/rest/field/[CLASS]/[NAME]/[FIELD]

=cut

sub field :Path('/rest/field') :Args(3) :ActionClass('REST') {}

sub field_GET {
    my ($self,$c,$class,$name,$field) = @_;

    my $headers = $c->req->headers;
    $c->log->debug($headers->header('Content-Type'));
    $c->log->debug($headers);

    unless ($c->stash->{object}) {
	# Fetch our external model
	my $api = $c->model('WormBaseAPI');
 
	# Fetch the object from our driver	 
	$c->log->debug("WormBaseAPI model is $api " . ref($api));
	$c->log->debug("The requested class is " . ucfirst($class));
	$c->log->debug("The request is " . $name);
	
	# Fetch a WormBase::API::Object::* object
	# But wait. Some methods return lists. Others scalars...
	$c->stash->{object} =  $api->fetch({class=> ucfirst($class),
					    name => $name}) or die "$!";
    }
    
    # Did we request the widget by ajax?
    # Supress boilerplate wrapping.
    if ( $c->is_ajax() ) {
	$c->stash->{noboiler} = 1;
    }


    my $object = $c->stash->{object};
    my $data = $object->$field;

    # Should be conditional based on content type (only need to populate the stash for HTML)
    $c->stash->{$field} = $data;

    # Anything in $c->stash->{rest} will automatically be serialized
#    $c->stash->{rest} = $data;

    
    # Include the full uri to the *requested* object.
    # IE the page on WormBase where this should go.
    my $uri = $c->uri_for("/page",$class,$name);

    $c->stash->{template} = $self->_select_template($c,$field,$class,'field'); 


    $self->status_ok($c, entity => {
	                 class  => $class,
			 name   => $name,
	                 uri    => "$uri",
			 $field => $data
		     }
	);
}


# WHY IS THIS DUPLICATED HERE?  Also in Root.pm
# Template assignment is a bit of a hack.
# Maybe I should just maintain
# a hash, where each field/widget lists its corresponding template
sub _select_template {
    my ($self,$c,$render_target,$class,$type) = @_;

    # Normally, the template defaults to action name.
    # However, we have some generic templates. We will
    # specify the name of the template.  
    # MOST widgets can use a generic template.


# 2010.06.28
# I don't believe the generic field/widget templates are in use any longer
    if ($type eq 'field') {
#	if (defined $c->config->{generic_fields}->{$render_target}) {
#	    return "generic/$type.tt2";    
        # Some templates are shared across Models
	if (defined $c->config->{common_fields}->{$render_target}) {
	    return "shared/fields/$render_target.tt2";
	} else {  
	    return "classes/$class/$render_target.tt2";
	}
    } else {
	# Widget template selection
# return "classes/$class/$render_target.tt2"; 
#	if (defined $c->config->{generic_widgets}->{$render_target}) {
#	    return "generic/$type.tt2";    
	#    # Some are shared across Models
	if (defined $c->config->{common_widgets}->{$render_target}) {
	    return "shared/widgets/$render_target.tt2";
	} else {  
	    return "classes/$class/$render_target.tt2"; 
	}
    }   
}




=cut

=head1 AUTHOR

Todd Harris

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
