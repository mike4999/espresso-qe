
# ------------------------------------------------------------------------
#  Page: CONTROL
# ------------------------------------------------------------------------

tracevar calculation w {

    set nat    [varvalue nat]
    set calc   [varvalue calculation]    

    set ion_dynamics [varvalue ion_dynamics] 
    set widget       [getWidgetFromVarident ion_dynamics]
    
    set all {ions cell vc_md constraints_card}
    
    set disable {}
    set enable  {}

    switch -exact -- $calc {
	'scf' - 
	'nscf' {
	    set disable $all
	    varset ion_dynamics -value {}
	}
	'relax' {
	    set enable  {ions constraints_card}
	    set disable {cell vc_md}
	    
	    widget ion_dynamics enable
	    widgetconfigure ion_dynamics -textvalues {
		"BFGS quasi-newton method for structural optimization  <bfgs>"
		"damped dynamics (quick-min Verlet) for structural optimization  <damp>"
	    }

	    if { ! [regexp bfgs|damp $ion_dynamics] } {
		varset ion_dynamics -value {}
	    }
	}
	'vc-relax' {
	    set enable  {ions cell vc_md constraints_card}

	    widget ion_dynamics enable
	    widgetconfigure ion_dynamics -textvalues {
		"BFGS quasi-newton method for structural optimization  <bfgs>"
		"Beeman algorithm for variable cell damped dynamics  <damp>"
	    }

	    if { ! [regexp bfgs|damp $ion_dynamics] } {
		varset ion_dynamics -value {}
	    }

	    widget cell_dynamics enable
	    widgetconfigure cell_dynamics -textvalues {
		"None  <none>"
		"Damped (Beeman) dynamics of the Parrinello-Raman extended lagrangian  <damp-pr>"
		"Damped (Beeman) dynamics of the new Wentzcovitch extended lagrangian  <damp-w>"
		"BFGS quasi-newton algorithm (ion_dynamics must be 'bfgs' too)  <bfgs>"
	    }
	}
	'md' {
	    set enable  {ions constraints_card}
	    set disable {cell vc_md}	
	    
	    widget ion_dynamics enable
	    widgetconfigure ion_dynamics -textvalues {
		"Verlet algorithm for molecular dynamics  <verlet>"
		"over-damped Langevin dynamics  <langevin>"
	    }
	    
	    if { ! [regexp verlet|langevin $ion_dynamics] } {
		varset ion_dynamics -value {}
	    }
	}
	'vc-md' {
	    set enable  {ions cell vc_md constraints_card}

	    widget ion_dynamics enable
	    widgetconfigure ion_dynamics -textvalues {
		"Beeman algorithm for variable cell MD  <beeman>"
	    }

	    if { ! [regexp beeman $ion_dynamics] } {
		varset ion_dynamics -value {}
	    }

	    widgetconfigure ion_temperature -textvalues {
		"velocity rescaling via tempw&tolp  <rescaling>"
		"not controlled  <not_controlled>"
	    }

	    if { ! [regexp rescaling [varvalue ion_temperature]] } {
		varset ion_temperature -value {}
	    }

	    widget cell_dynamics enable
	    widgetconfigure cell_dynamics -textvalues {
		"None  <none>"
		"(Beeman) dynamics of the Parrinello-Raman extended lagrangian  <pr>"
		"(Beeman) dynamics of the new Wentzcovitch extended lagrangian  <w>"
	    }
	}
    }

    foreach group $enable {
	groupwidget $group enable
    }
    foreach group $disable {
	groupwidget $group disable
    }
    
    # force to update the state of widgets by resetting corresponding variables

    varset ion_dynamics       -value [varvalue ion_dynamics]
    varset ion_temperature    -value [varvalue ion_temperature]
    varset cell_dynamics      -value [varvalue cell_dynamics]
    varset constraints_enable -value [varvalue constraints_enable]

    widgetconfigure atomic_coordinates -caption "Enter atomic coordinates:"    	
}



# ------------------------------------------------------------------------
#  Page: SYSTEM
# ------------------------------------------------------------------------

tracevar how_lattice w {
    switch -exact -- [varvalue how_lattice] {
	celldm { 
	    widget celldm enable 
	    groupwidget abc    disable 
	    groupwidget cosABC disable 
	}
	abc {
	    widget celldm disable 
	    groupwidget abc    enable
	    groupwidget cosABC enable
	}
    }
}	    

tracevar ibrav w {
    switch -exact -- [vartextvalue ibrav] {
	"Free lattice"             -
	"Cubic P (sc)"             -
	"Cubic F (fcc)"            -
	"Cubic I (bcc)"           { set uses 1 }

	"Hexagonal and Trigonal P" -
	"Tetragonal P (st)"        -       
	"Tetragonal I (bct)"      { set uses {1 3} }
	"Trigonal R, 3fold axis c" -
	"Trigonal R, 3fold axis <111>" { set uses {1 4} }

	"Orthorhombic P"                  -
	"Orthorhombic base-centered(bco)" - 
	"Orthorhombic face-centered"      -
	"Orthorhombic body-centered"     { set uses {1 2 3} }

	"Monoclinic P, unique axis c" -
	"Monoclinic P, unique axis b" -
	"Monoclinic base-centered" { set uses {1 2 3 4} }
	"Triclinic P" { set uses { 1 2 3 4 5 6 } }
	default {
	    set uses {}
	}
    }
    for {set i 1} {$i <= 6} {incr i} {
	if { [lsearch -exact $uses $i] < 0 } {		

	    # the lattice doesn't need the $i-th parameter

	    widget celldm($i) disable 
	} else {
	    widget celldm($i) enable 
	}
    }    

    if { [vartextvalue ibrav] == "Free lattice" } {
	groupwidget cards__CELL_PARAMETERS enable
    } else {
	groupwidget cards__CELL_PARAMETERS disable
    }
}

tracevar nat w {
    set nat [varvalue nat]
    widgetconfigure atomic_coordinates  -rows $nat
    #widgetconfigure atomic_coordinates_last_image -rows $nat
    #
    #set ni [varvalue path_inter_nimages]
    #if { $ni == "" } { set ni 0 }
    #for {set i 1} {$i <= $ni} {incr i} {
    #	widgetconfigure atomic_coordinates_${i}_inter -rows $nat
    #}
}
tracevar ntyp w {
    set ntyp [varvalue ntyp]
    widgetconfigure atomic_species -rows $ntyp
    widgetconfigure starting_magnetization -end $ntyp
    widgetconfigure angle1 -end $ntyp
    widgetconfigure angle2 -end $ntyp
    widgetconfigure Hubbard_U     -end $ntyp
    widgetconfigure Hubbard_alpha -end $ntyp
}


tracevar nspin w {
    if { [vartextvalue nspin] == "Yes" } {
	groupwidget spin_polarization enable
	widgetconfigure starting_magnetization -end [varvalue ntyp]

	varset noncolin -value ""
	groupwidget noncolin_group disable

	foreach var {fixed_magnetization B_field} {
	    widgetconfigure $var -start 3 -end 3
	}    
    } else {
	if { [vartextvalue noncolin] != "Yes" } {
	    groupwidget spin_polarization disable
	}
	groupwidget noncolin_group disable
    }

    # constrained/fixed magnetization
    if { [vartextvalue nspin] == "Yes" || [vartextvalue noncolin] == "Yes" } {
	groupwidget constrained_magnetization_group enable
    } else {
	groupwidget constrained_magnetization_group disable
    }
}


tracevar noncolin w {
    if { [vartextvalue noncolin] == "Yes" } {
	groupwidget spin_polarization enable
	widgetconfigure starting_magnetization -end [varvalue ntyp]

	varset nspin -value ""
	groupwidget noncolin_group enable
	
	foreach var {fixed_magnetization B_field} {
	    widgetconfigure $var -start 1 -end 3
	}
    } else {
	if { [vartextvalue nspin] != "Yes" } {
	    groupwidget spin_polarization disable
	}
	groupwidget noncolin_group disable
    }

    # constrained/fixed magnetization
    if { [vartextvalue nspin] == "Yes" || [vartextvalue noncolin] == "Yes" } {
	groupwidget constrained_magnetization_group enable
    } else {
	groupwidget constrained_magnetization_group disable
    }
}

tracevar tefield w {
    switch -- [vartextvalue tefield] {
	Yes     { groupwidget tefield_group enable  }
	default { groupwidget tefield_group disable }
    }
}

proc lelfield_widgets {status} {
    foreach w {nberrycyc efield efield_cart} {
	widget $w $status
    }
}
tracevar lelfield w {
    switch -- [vartextvalue lelfield] {
	Yes     { foreach w {nberrycyc efield efield_cart} {widget $w enable}  }
	default { foreach w {nberrycyc efield efield_cart} {widget $w disable} }
    }
}

tracevar lda_plus_u w {
    switch -- [vartextvalue lda_plus_u] {
	Yes     { widget mixing_fixed_ns enable;  groupwidget hubbard enable }
	default { widget mixing_fixed_ns disable; groupwidget hubbard disable }
    }
}

tracevar occupations w {
    if { [varvalue occupations] == "'from_input'" } {
	groupwidget occupations_card enable
    } else {
	groupwidget occupations_card disable
    }
}


tracevar assume_isolated w {
    if { [varvalue assume_isolated] == "'esm'" } {
	groupwidget ESM enable
    } else {
	groupwidget ESM disable
    }
}

tracevar london w {
    if { [vartextvalue london] == "Yes" } { 
	widget london_s6   enable 
	widget london_rcut enable
    } else  {
	widget london_s6   disable 
	widget london_rcut disable
    }
}


# ------------------------------------------------------------------------
#  Page: ELECTRONS
# ------------------------------------------------------------------------

tracevar adaptive_thr w {
    if { [vartextvalue adaptive_thr] == "Yes" } { 
	groupwidget adaptive_thr_group enable 
    } else  {
	groupwidget adaptive_thr_group disable
    }
}


tracevar diagonalization w {
    switch -glob -- [varvalue diagonalization] {
	'david*' {
	    widget diago_cg_maxiter disable
	    widget diago_david_ndim enable
	    widget ortho_para       enable
	    #groupwidget diis        disable
	}
	'cg' {
	    widget diago_cg_maxiter enable
	    widget diago_david_ndim disable
	    widget ortho_para       disable
	    #groupwidget diis        disable
	}
	default {
	    widget diago_cg_maxiter disable
	    widget diago_david_ndim disable
	    widget ortho_para       disable
	    #groupwidget diis        disable
	}
    }
}


# ------------------------------------------------------------------------
#  Page: IONS
# ------------------------------------------------------------------------

tracevar ion_dynamics w {
    set calc [varvalue calculation]
    set iond [varvalue ion_dynamics]

    # MD
    switch -exact -- $calc {
	'scf' - 'nscf' - 'bands' {
	    groupwidget md disable
	}
	'relax' - 'vc-relax' {	    
	    # check !!!
	    switch -exact -- $iond {
		'damp' - 'verlet' - 'langevin' - 'beeman' {
		    groupwidget md enable
		} 
		default {
		    groupwidget md disable
		}
	    }
	}
	'md' - 'vc-md' {	    
	    # check !!!
	    groupwidget md enable
	}
    }

    # BFGS
    if { $iond == "'bfgs'" && ($calc == "'relax'" || $calc == "'vc-relax'") } {
	groupwidget bfgs enable
    } else {
	groupwidget bfgs disable
    }

    ## CONSTRAINTS
    #if { ( $iond == "'constrained-damp'" && $calc == "'relax'" ) \
    #	     || ( $iond == "'constrained-verlet'" && $calc == "'md'" ) } {
    #	groupwidget constraints_card enable
    #} else {
    #	groupwidget constraints_card disable
    #}	     
}

tracevar n_fe_step w {
    widgetconfigure fe_step -end [varvalue n_fe_step]
}

# ------------------------------------------------------------------------
# Page: CELL_PARAMETERS, ATOMIC_SPECIES, ATOMIC_POSITIONS
# ------------------------------------------------------------------------


#
# ------------------------------------------------------------------------
#  Page: K-POINT DATA
# ------------------------------------------------------------------------

tracevar K_POINTS_flags w {
    switch -exact -- [varvalue K_POINTS_flags] {
	tpiba -	crystal - crystal_b - tpiba_b - {} {
	    #widget nks enable
	    groupwidget nks_line   enable
	    groupwidget kmesh_line disable
	    widget kpoints enable
	    widgetconfigure kpoints -cols 4 -rows [varvalue nks]    
	}

	automatic {
	    groupwidget nks_line   disable
	    groupwidget kmesh_line enable
	    widget kpoints disable
	    widgetconfigure kpoints -cols 4 -rows 0
	}

	gamma {
	    groupwidget nks_line   disable
	    groupwidget kmesh_line disable
	    widget kpoints disable
	    widgetconfigure kpoints -cols 4 -rows 0
	}
    }
}

tracevar nks w {
    widgetconfigure kpoints -rows [varvalue nks]    
}


# ------------------------------------------------------------------------
# Page: Other cards
# ------------------------------------------------------------------------

tracevar constraints_enable w {

    set calc [varvalue calculation]

    if { [regexp relax|md $calc] } {
	
	widget constraints_enable enable

	if { [varvalue constraints_enable] } {
	    groupwidget constraints_card enable
	} else {
	    groupwidget constraints_card disable
	}	    	
    } else {
	widget constraints_enable disable
	groupwidget constraints_card disable		
    }
}

tracevar nconstr w {
    set nc [varvalue nconstr]    
    widgetconfigure constraints_table -rows $nc
}

tracevar assume_isolated w {    
    switch -- [varvalue assume_isolated] {
	'dcc' { 
	    groupwidget ee enable 
	}
	default {
	    groupwidget ee disable
	}
    }
}


# ------------------------------------------------------------------------
# POST-PROCESSING: assign default values for "traced" variables, ...
# ------------------------------------------------------------------------
postprocess {    
    varset calculation     -value 'scf'
    varset how_lattice     -value celldm
    varset ibrav           -value {}
    varset nspin           -value {}
    varset tefield         -value {}
    varset lda_plus_u      -value {}
    varset occupations     -value {}
    varset assume_isolated -value {}
    varset london          -value {}
    varset adaptive_thr    -value {}
    varset diagonalization -value {}
    varset ion_dynamics    -value {}
    varset K_POINTS_flags  -value automatic
    varset CELL_PARAMETERS_flags -value cubic

    # so far the only constraint-type is "1"
    #tableset constraints_table 1 1 -value 1

    # unused variables
    groupwidget unused_1 disable
}
