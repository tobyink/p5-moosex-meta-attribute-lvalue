{
	package MooseX::Meta::Attribute::Lvalue;
	our $VERSION   = '0.05';
	our $AUTHORITY = 'cpan:TOBYINK';
	use Moose::Role;
}

{
	package Moose::Meta::Attribute::Custom::Trait::Lvalue;
	our $VERSION   = '0.05';
	our $AUTHORITY = 'cpan:TOBYINK';
	sub register_implementation { 'MooseX::Meta::Attribute::Trait::Lvalue' }
}

{
	package MooseX::Meta::Attribute::Trait::Lvalue;
	our $VERSION   = '0.05';
	our $AUTHORITY = 'cpan:TOBYINK';
	use Moose::Role;
	has lvalue => (
		is        => 'rw',
		isa       => 'Bool',
		predicate => 'has_lvalue',
		trigger   => sub { require Carp; Carp::carp('setting lvalue=>1 on the attribute is deprecated') },
	);
	around accessor_metaclass => sub
	{
		my $next = shift;
		my $self = shift;
		my $metaclass = $self->$next(@_);
		return Moose::Util::with_traits($metaclass, 'MooseX::Meta::Accessor::Trait::Lvalue');
	};
}

{
	package MooseX::Meta::Accessor::Trait::Lvalue;
	our $VERSION   = '0.05';
	our $AUTHORITY = 'cpan:TOBYINK';
	use Moose::Role;
	
	use Variable::Magic ();
	use Hash::Util::FieldHash::Compat ();
	
	Hash::Util::FieldHash::Compat::fieldhash(our %LVALUES);
	
	override is_inline => sub { 0 };  ## TODO!!
	override _generate_accessor_method => sub
	{
		my $self = shift;
		my $attr = $self->associated_attribute;
		my $attr_name = $attr->name;
		
		return sub :lvalue {
			my $instance = shift;
			
			unless (exists $LVALUES{$instance}{$attr_name})
			{
				my $wiz = Variable::Magic::wizard(
					set => sub { $attr->set_value($instance, ${$_[0]}) },
					get => sub { ${$_[0]} = $attr->get_value($instance) },
				);
				Variable::Magic::cast($LVALUES{$instance}{$attr_name}, $wiz);
			}
			
			@_ and $attr->set_value($instance, $_[0]);
			$LVALUES{$instance}{$attr_name};
		};
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Meta::Attribute::Lvalue - lvalue attributes for Moose

=head1 SYNOPSIS

   package MyThing;
   use Moose;
   
   has name => (
      traits      => ['Lvalue'] ,
      is          => 'rw',
      isa         => 'Str',
      required    => 1,
   );
   
   package main;
   
   my $thing = MyThing->new(name => 'Foo');
   $thing->name = "Bar";
   print $thing->name;   # Bar

=head1 DESCRIPTION

This package provides a Moose attribute trait that provides Lvalue accessors.
Which means that instead of writing:

   $thing->name("Foo");

You can use the more natural looking:

   $thing->name = "Foo";

For details of Lvalue implementation in Perl, please see: 
L<http://perldoc.perl.org/perlsub.html#Lvalue-subroutines>

Type constraints and coercions still work for lvalue attributes. Triggers
still fire. Everything should just work. (Unless it doesn't.)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Meta-Attribute-Lvalue>.

=head1 SEE ALSO

L<MooX::LvalueAttribute>,
L<Object::Tiny::Lvalue>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on work by
Christopher Brown, C<< <cbrown at opendatagroup.com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster;
2008 by Christopher Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

