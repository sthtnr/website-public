package WormBase::API::Object::Molecule;
use Moose;

with 'WormBase::API::Role::Object';
extends 'WormBase::API::Object';

=pod

=head1 NAME

WormBase::API::Object::Molecule

=head1 SYNPOSIS

Model for the Ace ?Molecule class.

=head1 URL

http://wormbase.org/species/*/molecule

=cut

#######################################
#
# CLASS METHODS
#
#######################################

#######################################
#
# INSTANCE METHODS
#
#######################################

#######################################
#
# The Overview Widget
#
#######################################

# name { }
# Supplied by Role

# remarks {}
# Supplied by Role

# synonyms { }
# This method will return a data structure with synonyms for the molecule name.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/synonyms

sub synonyms {
    my $self    = shift;
    my $object  = $self->object;
    my @data    = map {"$_"} $object->Synonym;
    return {
        'data'        => @data ? \@data : undef,
        'description' => 'synonyms for the molecule name'
    };
}


# gene_regulation { }
# This method will return a data structure with gene regulation processes involving the molecule.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/gene_regulation

# molecule_use { }
# This method will return a data structure with information on how the molecule is used.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/molecule_use

sub molecule_use {
    my $self = shift;
    my $object = $self->object;
    # TODO: deal with evidence
    my @uses = map {text=>"$_", evidence=>$self->_get_evidence($_)}, $object->Molecule_use;
    # (use, evidence type, evidence)
    return {
        'data'        => @uses ? \@uses : undef,
        'description' => 'uses for the molecule'
    };
}

############################
#
# The Phenotype Widget
#
############################

# affected_variations { }
# This method will return a data structure with variations affected by the molecule.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/affected_variations

sub affected_variations {
    my $self      = shift;

    sub get_affected_gene {
        my ($variation, $phenotype, $phenotype_tag_name) = @_;

        my ($phenotype_info) = grep {
            "$_" eq "$phenotype" ? ($_) : ();
        } ($variation->$phenotype_tag_name);

        my @affected_gene = $variation->Gene;

        return @affected_gene ? ($phenotype_info, @affected_gene) : ($phenotype_info);
    }

    my $data_pack = $self->_affects('Variation', \&get_affected_gene);

    return {
        data        => $data_pack,
        description => 'variations affected by molecule'

    };
}

# affected_strains { }
# This method will return a data structure with strains affected by the molecule.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/affected_strains

sub affected_strains {
    my $self      = shift;
    my $data_pack = $self->_affects('Strain');

    return {
        data        => $data_pack,
        description => 'strain affected by molecule'
    };
}

# affected_transgenes { }
# This method will return a data structure with transgenes affected by the molecule.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/affected_transgenes

sub affected_transgenes {
    my $self      = shift;
    my $that_self = $self; # some closure issue and name collision

    sub get_caused_by_gene {
        my ($transgene, $phenotype, $phenotype_tag_name) = @_;

        my ($phenotype_info) = grep {
            "$_" eq "$phenotype" ? ($_) : ();
        } ($transgene->$phenotype_tag_name);

        my @genes;
        if ($phenotype_info) {

            my ($remark) = $phenotype_info->at('Remark');
            my $remark_evidence = $that_self->_get_evidence($remark) if $remark;
            my $remark_evidence_tag = $remark_evidence ? { text => "$remark", evidence => $remark_evidence } : "$remark";

            @genes = eval { $phenotype_info->at('Caused_by')->at() }  #worm genes
                || eval { $phenotype_info->at('Caused_by_other')->at() } ;  #other genes
            # foreach (@genes) {
            #     $_->{remark} = $remark_evidence_tag;
            #     $_->{$phenotype_tag_name} = 1;
            # }

            use Data::Dumper; print Dumper $remark . '';
        }
        return ($phenotype_info, @genes);
    }

    my $data_pack = $self->_affects('Transgene', \&get_caused_by_gene);

    return {
        data        => $data_pack,
        description => 'transgenes affected by molecule'
    };
}

# affected_rnai { }
# This method will return a data structure with rnais affected by the molecule.
# eg: curl -H content-type:application/json http://api.wormbase.org/rest/field/molecule/D054852/affected_rnai

sub affected_rnai {
    my $self      = shift;

    sub get_primary_targets {
        my ($rnai, $phenotype) = @_;
        return $rnai->Gene;
    }

    my $data_pack = $self->_affects('RNAi', \&get_primary_targets);

    return {
        data        => $data_pack,
        description => 'rnai affected by molecule'
    };
}


#######################################
#
# The External Links widget
#   template: shared/widgets/xrefs.tt2
#
#######################################

# xrefs {}
# Supplied by Role

##########################
#
# Internal methods
#
##########################

sub _affects {
    my ($self, $tag, $affected_gene_function) = @_;
    my $object = $self->object;

    my @data;
    foreach my $affected ($object->$tag){

        my $phenotype = $affected->right;

        my @affected_packed;
        my $phenotype_info;
        my $phenotype_tag;

        if ($affected_gene_function) {
            my ($phenotype_info, @affected_genes) = $affected_gene_function->($affected, $phenotype, 'Phenotype');
            if (@affected_genes) {
                $phenotype_tag = 'phenotype';
            }else{
                ($phenotype_info, @affected_genes) = $affected_gene_function->($affected, $phenotype, 'Phenotype_not_observed');
                $phenotype_tag = 'phenotype_not' if @affected_genes;
            }
            @affected_packed = $self->_pack_list(\@affected_genes);

            my ($remark) = $phenotype_info->at('Remark') if $phenotype_info;
            my $evidence = {text => [$self->_pack_obj($affected), "$remark"], evidence => $self->_get_evidence($phenotype)} if $affected->right(2);

            my $data_per_phenotype =  {
                affected  =>  $evidence ? $evidence : $self->_pack_obj($affected),
                affected_gene => @affected_packed ? \@affected_packed : undef,
            };

            $data_per_phenotype->{$phenotype_tag} = $self->_pack_obj($phenotype);

            push @data, $data_per_phenotype;
        }
    }
    return @data ? \@data : undef;
}

__PACKAGE__->meta->make_immutable;

1;
