use Modern::Perl;
package Renard::Incunabula::Frontend::Gtk3::GooCanvas2;
# ABSTRACT: Helper code for using GooCanvas via Glib::Object::Introspection

use Renard::Incunabula::Frontend::Gtk3;
use Glib::Object::Introspection;

my $_GOOCANVAS_BASENAME = 'GooCanvas';
my $_GOOCANVAS_VERSION = '2.0';
my $_GOOCANVAS_PACKAGE = 'GooCanvas2';

my @_FLATTEN_ARRAY_REF_RETURN_FOR = qw/
	GooCanvas2::Canvas::get_items_at
	GooCanvas2::Canvas::get_items_in_area
	GooCanvas2::CanvasItem::get_items_at
/;

sub import {
	Glib::Object::Introspection->setup(
		basename => $_GOOCANVAS_BASENAME,
		version  => $_GOOCANVAS_VERSION,
		package  => $_GOOCANVAS_PACKAGE,
		flatten_array_ref_return_for => \@_FLATTEN_ARRAY_REF_RETURN_FOR,
	);
}

=method GooCanvas2::CanvasItem::find_child_property

Forwarded to C<GooCanvas2::CanvasItem::class_find_child_property>.

=cut
sub GooCanvas2::CanvasItem::find_child_property {
	return GooCanvas2::CanvasItem::class_find_child_property(@_);
}


=method GooCanvas2::CanvasItem::list_child_properties

Forwarded to C<GooCanvas2::CanvasItem::class_list_child_properties>.

=cut
sub GooCanvas2::CanvasItem::list_child_properties {
	my $ref = GooCanvas2::CanvasItem::class_list_child_properties(@_);
	return if not defined $ref;
	return wantarray ? @$ref : $ref->[$#$ref];
}

=method GooCanvas2::CanvasItemModel::find_child_property

Forwarded to C<GooCanvas2::CanvasItemModel::class_find_child_property>.

=cut
sub GooCanvas2::CanvasItemModel::find_child_property {
	return GooCanvas2::CanvasItemModel::class_find_child_property(@_);
}

=method GooCanvas2::CanvasItemModel::list_child_properties

Forwarded to C<GooCanvas2::CanvasItem::class_list_child_properties>.

See comment in code to see why C<GooCanvas2::CanvasItemModel::class_list_child_properties>
is not used.

=cut
sub GooCanvas2::CanvasItemModel::list_child_properties {
	my $model = shift @_;

	# If an instance, get its package name, otherwise treat it as a package
	# name.
	my $model_refname = ref $model // $model;

	# Hacky way to turn a model into the CanvasItem it represents.
	my $item_refname = $model_refname =~ s/Model$//r;
	unshift @_, $item_refname;

	# Call CanvasItem rather than CanvasItemModel because of a bug in how
	# `element-type` is defined in the annotations.
	my $ref = GooCanvas2::CanvasItem::class_list_child_properties(@_);
	return if not defined $ref;
	return wantarray ? @$ref : $ref->[$#$ref];
}

=head1 OVERRIDES FOR CHILD PROPERTIES

The use of the correct C<GValue> type is applied in the overrides for the following

=for :list
* C<GooCanvas2::CanvasItem::get_child_property>
* C<GooCanvas2::CanvasItem::set_child_property>
* C<GooCanvas2::CanvasItemModel::get_child_property>
* C<GooCanvas2::CanvasItemModel::set_child_property>


=cut
{
	no strict qw(refs); ## no critic (ProhibitNoStrict)
	for my $package (qw( CanvasItem  CanvasItemModel )) {
		*{'GooCanvas2::' . $package . '::get_child_property'} = sub {
			my ($container, $child, $property) = @_;
			my $pspec = $container->find_child_property($property);
			#croak "Cannot find type information for property '$property' on $container"
				#unless defined $pspec;
			my $value_wrapper = Glib::Object::Introspection::GValueWrapper->new (
				$pspec->get_value_type, undef);
			Glib::Object::Introspection->invoke (
				$_GOOCANVAS_BASENAME, $package, 'get_child_property',
				$container, $child, $property, $value_wrapper );

			return $value_wrapper->get_value;
		};

		*{'GooCanvas2::' . $package . '::set_child_property'} = sub {
			my ($container, $child, $property, $value) = @_;
			my $pspec = $container->find_child_property($property);
			#croak "Cannot find type information for property '$property' on $container"
				#unless defined $pspec;
			my $value_wrapper = Glib::Object::Introspection::GValueWrapper->new (
				$pspec->get_value_type, $value);

			Glib::Object::Introspection->invoke (
				$_GOOCANVAS_BASENAME, $package, 'set_child_property',
				$container, $child, $property, $value_wrapper );
		};
	}
}


1;
