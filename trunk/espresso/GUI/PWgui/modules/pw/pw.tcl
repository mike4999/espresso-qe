source commands.tcl

module PW\#auto -title "PWSCF GUI: module PW.x" -script {
    
    readfilter  ::pwscf::pwReadFilter
    writefilter ::pwscf::pwWriteFilter

    # ------------------------------------------------------------------------
    # devide the GUI on pages (each namelist on its own page)
    # ------------------------------------------------------------------------

    ########################################################################
    ##                                                                    ##
    ##                      &CONTROL NAMELIST                             ##
    ##                                                                    ##
    ########################################################################

    page controlPage -name "Control" {
	namelist control -name "CONTROL" {
	    optional {
		#-default  "'PWSCF sample input'"
		var title -label "Job Title (title):"

		var calculation {
		    -label     "Type of calculation (calculation):"
		    -widget    radiobox
		    -textvalue {
			"Self-Consistent-Field  <scf>"
			"Band structure calculation  <nscf>"
			"Phonon calculation  <phonon>"	
			"Ionic relaxation  <relax>"
			"Ionic relaxation with Variable-Cell  <vc-relax>"
			"Molecular dynamics  <md>"
			"Molecular dynamics with Variable-Cell  <vc-md>"
			"Nudged Elastic Band  <neb>"
                        "String Method Dynamics <smd>"
		    }
		    -value {
			'scf'
			'nscf'
			'phonon'
			'relax'
			'vc-relax'
			'md'
			'vc-md'
			'neb'
                        'smd'
		    }
		    -default "Self-Consistent-Field  <scf>"
		}
		
		var max_seconds {
		    -label    "Maximum CPU time \[in seconds\] (max_seconds):"
		    -validate posint
		}

		var restart_mode {
		    -label    "Restart mode (restart_mode):"
		    -widget   optionmenu
		    -textvalue {
			"from scratch <from_scratch>"
			"from previous interrupted run  <restart>"
		    }
		    -value {
			'from_scratch'
			'restart'
		    }
		    -default  "from scratch <from_scratch>"
		}

		separator -label "--- Directories/Files/Stdout ---"
		
		var outdir {
		    -label     "Temporary directory (outdir):"
		    -widget    entrydirselectquote
		}

		var pseudo_dir \
		    -label    "Directory containing pseudopotential files (pseudo_dir:)" \
		    -widget   [list entrybutton "Directory ..." "::pwscf::pwSelectPseudoDir $this"]

		var prefix -label "Prefix for I/O filenames (prefix):"

		var disk_io {
		    -label    "Disk Input/Output (disk_io):"
		    -textvalue {
			high default low minimal
		    }
		    -value {
			'high' 'default' 'low' 'minimal'
		    }
		    -widget optionmenu
		}

		var verbosity {
		    -label     "Verbosity of output (verbosity):"
		    -widget    optionmenu
		    -textvalue {
			high
			default
			low
			minimal
		    }
		    -value {
			'high'
			'default'
			'low'
			'minimal'
		    }
		}

		var iprint {
		    -label   "Interval (in SCF iterations) for printing band energies (iprint):"
		    -widget   spinint
		    -validate nonnegint
		}

		separator -label "--- Ionic Minimization ---"

		#-text     "threshold on total energy for ionic minimization"
		var etot_conv_thr {
		    -label    "Convergence energy threshold \[in Ryd\] (etot_conv_thr):"
		    -validate fortranposreal
		}

		#-text     "Convergence threshold on forces for ionic minimization"
		var forc_conv_thr {
		    -label    "Convergence force threshold \[in Ryd/Bohr\] (forc_conv_thr):"
		    -validate fortranposreal
		}

		separator -label "--- Miscellaneous control parameters ---"
		
		var nstep {
		    -label    "Number of ionic steps (nstep):"
		    -widget   spinint
		    -validate posint
		}

		var tstress {
		    -label    "Calculate stress (tstress):"
		    -widget   radiobox
		    -textvalue { Yes No }	      
		    -value     { .true. .false. }
		}

		var tprnfor {
		    -label     "Calculate forces (tprnfor):"
		    -variable  tprnfor
		    -widget    radiobox
		    -textvalue { Yes No }	      
		    -value     { .true. .false. }
		}
		
		var dt {
		    -label     "Molecular-Dynamics time step (dt):"
		    -validate  fortranposreal
		}

		var tefield {
		    -label     "Add a sawlike potential to bare ionic potential (tefield):"
		    -widget    radiobox
		    -textvalue { Yes No }	      
		    -value     { .true. .false. }
		}
	    }
	}
    }


    ########################################################################
    ##                                                                    ##
    ##                      &SYSTEM NAMELIST                              ##
    ##                                                                    ##
    ########################################################################

    page systemPage -name "System" {

	# ----------------------------------------------------
	# REQUIRED variables
	# ----------------------------------------------------

	namelist system -name "SYSTEM" {	    
	    required {
		#
		# WARNING: if you change the strings among the possible
		#          ibrav values, then search the "tracevar ibrav"
		#          section in the file pwscf-special.tcl and change
		#          there the strings to match EXACTLY with the 
		#          ones defined here !!!
		#	    
		var ibrav {
		    -label     "Braivas lattice index (ibrav):"
		    -fmt       %d
		    -widget    combobox
		    -textvalue {
			"Free lattice"
			"Cubic P (sc)"
			"Cubic F (fcc)"
			"Cubic I (bcc)"
			"Hexagonal and Trigonal P"
			"Trigonal R"
			"Tetragonal P (st)"
			"Tetragonal I (bct)"
			"Orthorhombic P"
			"Orthorhombic base-centered(bco)"
			"Orthorhombic face-centered"
			"Orthorhombic body-centered"
			"Monoclinic P"
			"Monoclinic base-centered"
			"Triclinic P"
		    }
		    -value {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14}
		}

		group lattice_spec -name "Lattice specification:" -decor normal {
		    auxilvar how_lattice {
			-label     "How to specify lattice:"
			-value     {celldm abc}
			-textvalue {"by celldm()" "by A,B,C,cosAB,cosAC,cosBC"}
			-widget    radiobox
		    }
		    
		    dimension celldm {
			-label "Crystallographic constants (celldm)"
			-validate  fortranreal
			-start 1
			-end   6
		    }
		    
		    group abc {
			packwidgets left
			var A -label "A:" -validate fortranposreal
			var B -label "B:" -validate fortranposreal
			var C -label "C:" -validate fortranposreal
		    }
		    group cosABC {
			packwidgets left
			var cosAB -label "cosAB:" -validate fortranreal		    
			var cosAC -label "cosAC:" -validate fortranreal
			var cosBC -label "cosBC:" -validate fortranreal		    
		    }
		}

		var nat {
		    -label    "Number of atoms in the unit cell (nat):"
		    -fmt       %d
		    -default   1
		    -widget    spinint
		    -validate  posint
		}
		
		var ntyp {
		    -label    "Number of types of atoms in the unit cell (ntyp):"
		    -fmt      %d
		    -default  1
		    -widget   spinint  
		    -validate posint
		}		
		
		var ecutwfc {
		    -label    "Kinetic energy cutoff for WAVEFUNCTION \[in Ryd\] (ecutwfc):"
		    -validate fortranposreal
		}

		var ecutrho {
		    -label    "Kinetic energy cuttof for DENSITY \[in Ryd\] (ecutrho):"
		    -validate fortranposreal
		}
	    }

	    # ----------------------------------------------------
	    # OPTIONAL variables
	    # ----------------------------------------------------

	    optional {		
		var nosym {
		    -label     "Use no-symmetry (nosym):"
		    -widget    radiobox
		    -textvalue { Yes No }	      
		    -value     { .true. .false. }
		}
		
		#-text     "Number of electronic states (bands) to be calculated"
		var nbnd {
		    -label    "Number of electronic states (nbnd):"
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}

		#-text     "Number of electron in the unit cell"
		var nelec {
		    -label    "Number of electrons in unit cell (nelec):"
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}

		separator -label "--- Occupations ---"

		var occupations {
		    -label    "Occupation of states (occupations):"
		    -widget   optionmenu
		    -textvalue {
			smearing tetrahedra fixed "read from input"
		    }
		    -value {
			'smearing' 'tetrahedra' 'fixed' 'from_input'
		    }
		}

		var degauss {
		    -label    "Gaussian spreading for BZ integration \[in Ryd\] (degauss):"
		    -validate fortrannonnegreal
		}

		var smearing {
		    -label    "Type of spreading/smearing (smearing):"
		    -textvalue {
			"first order interpolation in Methfessel-Paxton spreading  <methfessel-paxton>"
			"ordinary Gaussian spreading  <gaussian>"
			"Marzari-Vanderbilt cold smearing  <marzari-vanderbilt>"
			"Fermi-Dirac smearing  <fermi-dirac>"
		    }
		    -value  {
			'methfessel-paxton'
			'gaussian'
			'marzari-vanderbilt'
			'fermi-dirac'
		    }
		    -widget optionmenu
		}

		#var ngauss {
		#    -label    "Interpolation order in Methfessel-Paxton spreading"
		#    -widget   spinint
		#    -validate posint
		#}

		separator -label "--- Spin polarization ---"

		var nspin {
		    -label     "Perform spin-polarized calculation (nspin):"
		    -textvalue {No Yes}
		    -value     {1  2}
		    -widget    radiobox
		}

		dimension starting_magnetization {
		    -label "Starting magnetization (starting_magnetization):"
		    -text  "Specify starting magnetization (between -1 and 1) for each \"magnetic\" atom"
		    -validate  fortranreal
		    -start 1
		    -end   1
		}

		separator -label "--- LDA + U parameters ---"
	       
		var lda_plus_u {
		    -label     "Perform LDA + U calculation (lda_plus_u):"
		    -textvalue {No Yes}
		    -value     {.false.  .true.}
		    -widget    radiobox
		}
		    
		group hubbard -name Hubbard {
		    dimension Hubbard_U {
			-label     "Hubbarb U (Hubbard_U):"
			-validate  fortranreal
			-start 1 -end 1
		    }
		    
		    dimension Hubbard_alpha {
			-label     "Hubbard alpha (Hubbard_alpha):"
			-validate  fortranreal
			-start 1 -end 1
		    }

		    var U_projector_type {
			-label  "Type of projector on localized orbital (U_projector_type):"
			-widget optionmenu
			-textvalue {
			    "use atomic wfc's (as they are) to build the projector <atomic>"
			    "use Lowdin orthogonalized atomic wfc's <ortho-atomic>"
			    " use the information from file \"prefix\".atwfc <file>"
			}
			-value {
			    'atomic'
			    'ortho-atomic'
			    'file'
			}
		    }		
		}

		separator -label "--- Variable cell parameters ---"

		group vc_md -name VC-MD {		    
		    var ecfixed {
			-label     "ecfixed:"
			-validate  fortranreal
		    }
		    var qcutz {
			-label     "qcutz:"
			-validate  fortranreal
		    }
		    var q2sigma {
			-label     "q2sigma:"
			-validate  fortranreal
		    }
		}	
		
		separator -label "--- Saw-like potential parameters ---"

		group tefield_group -name TeField {
		    var edir {
			-label    "Direction of electric field (edir)"
			-widget   optionmenu
			-textvalue {
			    "along 1st reciprocal vector"
			    "along 2nd reciprocal vector"
			    "along 3rd reciprocal vector"
			}
			-value { 1 2 3 }
		    }
		    
		    var emaxpos {
			-text     "Position of maximum of sawlike potential within the unit cell"
			-label    "Position of maximum (emaxpos):"
			-validate fortranreal
		    }

		    var eopreg {
			-text     "Part of the unit cell where the sawlike potential decreases"
			-label    "Where the sawlike potential decreases (eoprog):"
			-validate fortranreal
		    }

		    var eamp -label "Amplitude of the electric field \[in a.u.\] (eamp):"
		}

		separator -label "--- FFT mesh (hard grid) for charge density ---"

		var nr1 {
		    -label    "nr1:"
		    -validate posint
		    -widget   spinint
		}
		var nr2 {
		    -label    "nr2:"
		    -validate posint
		    -widget   spinint
		}
		var nr3 {
		    -label    "nr3:"
		    -validate posint
		    -widget   spinint
		}

		separator -label "--- FFT mesh (soft grid) for wavefunction ---"

		var nr1s {
		    -label    "nr1s:"
		    -validate posint
		    -widget   spinint
		}
		var nr2s {
		    -label    "nr2s:"
		    -validate posint
		    -widget   spinint
		}
		var nr3s {
		    -label    "nr3s:"
		    -validate posint
		    -widget   spinint
		}

		group unused_1 {
		    separator -label "--- Unused variables ---"

		    var nelup {
			-label    "Number of spin-up electrons:"
			-validate fortrannonnegreal
		    }
		    
		    var neldw {
			-label    "Number of spin-down electrons:"
			-validate fortrannonnegreal
		    }
		    var xc_type -label    "Exchange-correlation functional (xc_type):"
		}
	    }
	}
    }

    ########################################################################
    ##                                                                    ##
    ##                      &ELECTRONS NAMELIST                           ##
    ##                                                                    ##
    ########################################################################

    page electronsPage -name "Electrons" {
	namelist electrons -name "ELECTRONS" {
	    optional {
		var electron_maxstep {
		    -label     "Max. \# of iterations in SCF step (electron_maxstep):"
		    -widget    spinint
		    -validate  posint
		    -fmt       %d
		}
		
		var conv_thr {
		    -label     "Convergence threshold for selfconsistency (conv_thr):"
		    -validate  fortranposreal
		}
	       
		var startingpot {
		    -label    "Type of starting potential (startingpot):"
		    -widget   optionmenu
		    -textvalue {
			"from atomic charge superposition  <atomic>"
			{from existing potential "prefix".pot file  <file>}
		    }
		    -value {'atomic' 'file'}
		}

		var startingwfc {
		    -label    "Type of starting wavefunctions (startingwfc):"
		    -widget   optionmenu
		    -textvalue {
			"from superposition of atomic orbitals  <atomic>"
			"from random wavefunctions  <random>"
			"from existing wavefunction file  <file>"
		    }
		    -value {'atomic' 'random' 'file'}
		}

		separator -label "--- SCF Mixing ---"

		var mixing_mode {
		    -label     "Mixing mode (mixing_mode):"
		    -textvalue {
			"charge density Broyden mixing  <plain>"
			"charge density Broyden mixing with simple Thomas-Fermi (TF) screening  <TF>"
			"charge density Broyden mixing with local-density-dependent TF screening  <local-TF>"
			"mixing of potential  <potential>"
		    }
		    -value {
			'plain' 
			'TF'    
			'local-TF'
			'potential'
		    }
		    -widget optionmenu
		}

		var mixing_beta {
		    -label    "Mixing factor for self-consistency (mixing_beta):"
		    -validate  fortranposreal
		}

		var mixing_ndim {
		    -label    "Number of iterations used in mixing scheme (mixing_ndim):"
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}

		var mixing_fixed_ns {
		    -text     "For LDA+U only: ns = atomic density appearing in the Hubbard term"
		    -label    "Number of iterations with fixed ns (mixing_fixed_ns):" 
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}

		separator -label "--- Diagonalization ---"

		var diagonalization {
		    -label    "Type of diagonalization (diagonalization):"
		    -textvalue {
			"Davidson iterative diagonalization with overlap matrix  <david>"
			"DIIS-like diagonalization  <diis>"
			"Conjugate-gradient-like band-by-band diagonalization  <cg>"
		    }
		    -value {
			'david'
			'diis'
			'cg'
		    }
		    -widget optionmenu
		}

		var diago_thr_init {
		    -label "Convergence threshold for 1st iterative diagonalization (diago_thr_init):"
		    -validate fortranreal
		}

		var diago_cg_maxiter {
		    -text     "For CONJUGATE-GRADIENT DIAGONALIZATION only"
		    -label    "Max. \# of iterations (diago_cg_maxiter):"
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}
		
		var diago_david_ndim {
		    -text     "For DAVIDSON DIAGONALIZATION only"
		    -label    "Dimension of workspace (diago_david_ndim):"
		    -widget   spinint
		    -validate posint
		    -fmt      %d
		}

		separator -label "--- DIIS diagonalization ---"
		
		group diis -name "DISS diagonalization" {

		    var diago_diis_ndim {
			-text     "For DIIS only only"
			-label    "Dimension of the reduced space (diago_diis_ndim):"
			-widget   spinint
			-validate posint
			-fmt      %d
		    }
		}
	    }    
	}
    }

    ########################################################################
    ##                                                                    ##
    ##                      &IONS NAMELIST                                ##
    ##                                                                    ##
    ########################################################################

    page ionsPage -name "Ions" {	
	namelist ions -name "IONS" {
	    optional {
		# this should be modified as it is CASE dependent
		var ion_dynamics {
		    -label "Type of ionic dynamics (ion_dynamics):"
		    -widget   optionmenu
		    -textvalue {
			"BFGS quasi-newton method for structural optimization (based on the trust radius procedure) <bfgs>"
			"old BFGS quasi-newton method for structural optimization (based on line minimization) <old-bfgs>"
			"damped dynamics (quick-min velocity Verlet) for structural optimization <damp>"
                        "damped dynamics (quick-min velocity Verlet) for structural optimization with the CONSTRAINT <constrained-damp>"
			"Velocity-Verlet algorithm for Molecular dynamics <verlet>"
			"Velocity-Verlet-MD with the CONSTRAINT <constrained-verlet>"
                        "Beeman algorithm for variable cell damped dynamics <damp>"
			"Beeman algorithm for variable cell MD <beeman>"
		    }
		    -value {
			'bfgs' 
			'old-bfgs'
			'damp' 
			'constrained-damp'
			'verlet' 
			'constrained-verlet'
                        'damp'
			'beeman'
		    }
		}

		var upscale {
		    -text    "Max. reduction factor for conv_thr during structural optimization"
		    -label   "Max. reduction factor (upscale):"
		    -validate  fortranposreal
		}

		var potential_extrapolation {
		    -text "Extrapolation for the potential and the wavefunctions"
		    -label "Type of extrapolation (potential_extrapolation):"
		    -textvalue {
			"no extrapolation  <none>"
			"extrapolate the potential as a sum of atomic-like orbitals  <atomic>"
			"extrapolate potential as above and wave-functions with first-order formula  <wfc>"
			"extrapolate potential as above and wave-functions with second-order formula  <wfc2>"
		    }
		    -value {
			'none' 'atomic' 'wfc' 'wfc2'
		    }
		    -widget optionmenu
		}

		separator -label "--- Molecular Dynamics ---"

		group md {
		    var ion_temperature {
			-label    "Temperature of ions (ion_temperature):"
			-widget   optionmenu
			-textvalue {
			    "velocity rescaling  <rescaling>"
			    "not controlled  <not_controlled>"
			}
			-value {'rescaling' 'not_controlled'}
		    }
		    
		    var tempw {
			-label    "Starting temperature in MD runs (tempw):"
			-validate  fortrannonnegreal
		    }
		    
		    var tolp {
			-label    "Tolerance for velocity rescaling (tolp):"
			-validate fortranreal
		    }
		}

		separator -label "--- BFGS Structural Optimization ---"

		group new_bfgs {
		    var lbfgs_ndim {
			-label "Number of old forces and displacements vectors used in the L-BFGS (lbfgs_ndim):"
			-widget   spinint
			-validate posint
		    }

		    var trust_radius_max {
			-label "Maximum ionic displacement in the structural relaxation (trust_radius_max):"
			-validate fortranposreal
		    }

		    var trust_radius_min {
			-label "Minimum ionic displacement in the structural relaxation (trust_radius_min):"
			-validate fortranposreal
		    }

		    var trust_radius_ini {
			-label "Initial ionic displacement in the structural relaxation (trust_radius_ini):"
			-validate fortranposreal
		    }

		    var trust_radius_end {
			-text "BFGS is stopped when trust_radius < trust_radius_end"
			-label "trust_radius_end:"
			-validate fortranposreal
		    }
		    
		    group w1_w2 -name "Parameters used in line search based on the Wolfe conditions:" -decor normal {
			packwidgets left
			var w_1 {
			    -label    "w_1:"
			    -validate fortranreal
			}
			var w_2 {
			    -label    "w_1:"
			    -validate fortranreal
			}
		    }
		}

		separator -label "--- Nudget Elastic Band (NEB) and String Method Dynamics (SMD) ---"
		
		group path {
		    var num_of_images {
			-label   "Number of images used to discretize the path (num_of_images):"
			-widget   spinint
			-validate posint
		    }
		    
		    var first_last_opt {
			-label "Optimize also the first and the last configurations (first_last_opt):"
			-textvalue { Yes No }
			-value     { .TRUE. .FALSE. }
			-widget    radiobox
		    }
		    		    
		    var minimization_scheme {
			-label "Type of optimization scheme (minimization_scheme):"
			-value {
			    'quick-min' 
			    'sd'
			    'damped-dyn'
			    'mol-dyn'  
			}
			-textvalue {
			    "optimization algorithm based on molecular dynamics  <quick-min>"
			    "steepest descent  <sd>"
			    "damped molecular dynamics  <damped-dyn>"
			    "constant temperature molecular dynamics  <mol-dyn>"
			}
			-widget optionmenu
		    }

		    var damp {
			-label    "Damping coefficent for damped-dyn (damp):"
			-validate fortranreal
		    }
		    
		    var temp_req {
			-label    "Temperature of elastic band for mol-dyn (temp_req):"
			-validate fortranposreal
		    }

		    var ds {
			-label    "Optimization step length (ds):"
			-validate fortranposreal
		    }
		    
		    var path_thr {
			-label "Convergence threshold for path optimization (path_thr):"
			-validate fortranposreal
		    }
                    
                    var reset_vel {
			-label "sort of clean-up of the quick-min history:"
			-textvalue { Yes No }
			-value     { .TRUE. .FALSE. }
			-widget    radiobox
		    }
		}
                
              group neb {
              
		    var CI_scheme {
			-label "Type of Climbing Image (CI) scheme (CI_scheme):"
			-textvalue {
			    "do not use climbing image  <no-CI>"
			    "image highest in energy is allowed to climb  <highest-TS>"
			    "CI is used on all the saddle points  <all-SP>"
			    "climbing images are manually selected  <manual>"
			}
			-value {
			    'no-CI'
			    'highest-TS'
			    'all-SP'
			    'manual'
			}
			-widget optionmenu
		    }
              
		    group elastic_constants -name "Elastic Constants for NEB spring:" -decor normal {
			packwidgets left
			var k_max {
			    -label    "k_max:"
			    -validate fortranposreal
			}
			var k_min {
			    -label    "k_min:"
			    -validate fortranposreal
			}
		    }
              
                }  
	    }
	}
    }


    ########################################################################
    ##                                                                    ##
    ##                      &CELL NAMELIST                                ##
    ##                                                                    ##
    ########################################################################

    page variableCellPage -name "Variable Cell" {

	namelist cell -name "CELL" {
	    var cell_dynamics {
		-label "Type of dynamics for the cell (cell_dynamics):"
		-textvalue {
		    "None  <none>"
		    "Damped (Beeman) dynamics of the Parrinello-Raman extended lagrangian  <damp-pr>"
		    "Damped (Beeman) dynamics of the new Wentzcovitch extended lagrangian  <damp-w>"
		    "(Beeman) dynamics of the Parrinello-Raman extended lagrangian  <pr>"
		    "(Beeman) dynamics of the new Wentzcovitch extended lagrangian  <w>"
		}	    
		-value {
		    'none'
		    'damp-pr'
		    'damp-w'
		    'pr'
		    'w':
		}
		-widget optionmenu
	    }
	    
	    var press {
		-label    "Target pressure \[in KBar\] in a variable-cell MD (press):"
		-validate  fortranreal
	    }
	    
	    var wmass {
		-label    "Ficticious cell mass for variable-cell MD (wmass):"
		-validate  fortranreal

	    }
	    
	    var cell_factor {
		-text     "This variable is used in the construction of the pseudopotential tables. It should exceed the maximum linear contraction of the cell during a simulation"
		-label    "Cell factor (cell_factor):"
		-validate  fortranreal
	    }
	}
    }

    ########################################################################
    ##                                                                    ##
    ##                      &PHONON NAMELIST                              ##
    ##                                                                    ##
    ########################################################################

    page phononPage -name "Phonon" {
	namelist phonon -name "PHONON" {
	    var modenum {
		-label    "Mode number for single-mode phonon calculation (modenum):"
		-widget   spinint
		-validate posint
		-fmt      %d
	    }
	    
	    #packwidgets left
	    dimension xqq {
		-label    "q-point \[in 2pi/a units\] for phonon calculation"
		-validate  fortranreal
		-start    1
		-end      3
		-pack     left
	    }
	}
    }


    ########################################################################
    ##                                                                    ##
    ##     CARDS: CELL_PARAMETERS, ATOMIC_SPECIES, ATOMIC_POSITIONS       ##
    ##                                                                    ##
    ########################################################################

    page latticeAtomdataPage -name "Lattice & Atomic data" {

	#
	# CELL_PARAMETERS
	#
	group cards__CELL_PARAMETERS {
	    line lattice_type_line -name "Lattice type" {
		keyword cell_parameters CELL_PARAMETERS
		var lattice_type {
		    -label    "Lattice type:" 
		    -value    {cubic hexagonal}
		    -widget   radiobox
		    -default  cubic
		}
	    }
	    table lattice {
		-caption  "Enter Lattice Basis Vectors:"
		-head     {X-Component Y-Component Z-Component}
		-validate {real real real}
		-cols     3
		-rows     3
		-outfmt   {"  %14.9f" %14.9f %14.9f}
	    }	
	}

	#
	# ATOMIC_SPECIES
	#
	keyword atomic_species_key ATOMIC_SPECIES\n
	table atomic_species \
	    -caption  "Enter atomic types:" \
	    -head     {Atomic-label Atomic-Mass Pseudopotential-file} \
	    -cols     3 \
	    -rows     1 \
	    -outfmt   {"  %3s" %10.5f " %s"} \
	    -validate {whatever fortranreal whatever} \
	    -widgets  [list entry entry [list entrybutton "Pseudopotential ..." [list ::pwscf::pwSelectPseudopotential $this atomic_species]]]
	
	#
	# ATOMIC_POSITIONS
	#
	line atom_coor_unit -name "Atomic coordinate unit" {
	    keyword atomic_positions ATOMIC_POSITIONS
	    var atmpos_unit {
		-label    "Atomic coordinate length unit:" 
		-textvalue {
		    "Cartesian in ALAT (i.e. in length units of celldm(1))  <alat>"
		    "Cartesian in BOHR  <bohr>"
		    "Cartesian in ANGSTROMS  <angstroms>"
		    "Internal crystal coordinates  <crystal>"
		}
		-value {alat bohr angstrom crystal}	    
		-widget radiobox
		-default "Cartesian in ALAT (i.e. in length units of celldm(1))  <alat>"
	    }
	}
		
	scriptvar old_path_inter_nimages
	auxilvar path_inter_nimages {
	    -label    "Number of intermediate images:"
	    -widget   spinint
	    -validate nonnegint
	    -default  0
	}
	
	# first_image
	
	keyword first_image first_image\n; # only for calculation == 'neb' || 'smd'
	table atomic_coordinates {
	    -caption   "Enter atomic coordinates:"
	    -head      {Atomic-label X-Coordinate Y-Coordinate Z-Coordinate X-iforce Y-iforce Z-iforce}
	    -validate  {string real real real numeric numeric numeric}
	    -cols      7
	    -rows      1
	    -outfmt    {"  %3s" "  %14.9f" %14.9f %14.9f "  %2d" %2d %2d}
	    -widgets   {entry entry entry entry checkbutton}
	    -onvalues  1
	    -offvalues 0
	}
	loaddata atomic_coordinates ::pwscf::pwLoadAtomCoor \
	    "Load atomic coordinates from file ..."    

	# intermediate_image
	    
	# BEWARE: it is assumed that 50 intermediate images is the
	# largest allowed number (this is dirty)
	    	
	for {set i 1} {$i <= 50} {incr i} {
	    keyword intermediate_image_$i intermediate_image\n
	    table atomic_coordinates_${i}_inter [subst {
		-caption   "Enter atomic coordinates for INTERMEDIATE image \#.$i:"
		-head      {Atomic-label X-Coordinate Y-Coordinate Z-Coordinate}
		-validate  {string real real real}
		-cols      4
		-rows      1
		-outfmt    {"  %3s" "  %14.9f" %14.9f %14.9f}
		-widgets   {entry entry entry entry}
		-onvalues  1
		-offvalues 0
	    }]
	    loaddata atomic_coordinates_${i}_inter [list ::pwscf::pwLoadAtomCoorInter $i] \
		"Load atomic coordinates from file ..."    
	}
	
	# last_image
	
	keyword last_image last_image\n
	table atomic_coordinates_last {
	    -caption   "Enter atomic coordinates for LAST image:"
	    -head      {Atomic-label X-Coordinate Y-Coordinate Z-Coordinate}
	    -validate  {string real real real}
	    -cols      4
	    -rows      1
	    -outfmt    {"  %3s" "  %14.9f" %14.9f %14.9f}
	    -widgets   {entry entry entry entry}
	    -onvalues  1
	    -offvalues 0
	}
	loaddata atomic_coordinates_last ::pwscf::pwLoadAtomCoorLast \
	    "Load atomic coordinates from file ..."    
    }    


    ########################################################################
    ##                                                                    ##
    ##                         CARD: K_POINTS                             ##
    ##                                                                    ##
    ########################################################################

    page kpointsPage -name "K-point data" {
	#
	# K_POINTS
	#
	line kpoint_type_line -name "K-point input" {
	    keyword k_points K_POINTS
	    var kpoint_type {
		-label    "K-Point input" 
		-textvalue {
		    "Manual specification in 2pi/a units  <tpiba>"
		    "Manual specification in CRYSTAL units  <crystal>"
		    "Automatic generation  <automatic>"
		    "Gamma point only  <gamma>"
		}
		-value {
		    tpiba crystal automatic gamma
		}
		-widget radiobox
		-default "Manual specification in 2pi/a units  <tpiba>"
	    }
	}

	line nks_line -name "Number of K-points" {
	    var nks -label "Number of K-points:" -widget spinint -validate posint -default 1
	}

	# if nks=0 then enter the mesh and shifts
	line kmesh_line -name "K-point mesh + shift" {
	    group kmesh -name Kmesh {
		packwidgets left
		var nk1 -label "nk1:"  -widget spinint  -validate posint  -outfmt "  %d "  -default 1
		var nk2 -label "nk2:"  -widget spinint  -validate posint  -outfmt "%d "  -default 1
		var nk3 -label "nk3:"  -widget spinint  -validate posint  -outfmt "%d "  -default 1
	    }
	    group kshift -name Kshift {
		packwidgets left
		var sk1 -label "sk1:"  -widget spinint  -validate posint  -outfmt "  %d "  -default 1
		var sk2 -label "sk2:"  -widget spinint  -validate posint  -outfmt "%d "  -default 1
		var sk3 -label "sk3:"  -widget spinint  -validate posint  -outfmt "%d "  -default 1
	    }
	}

	# elseif nks>0 enetr kpoint coordinates
	table kpoints {
	    -caption  "Enter the coordinates of the K-points below:"
	    -head     {KX-Coordinate KY-Coordinate KZ-Coordinate Weight}
	    -cols     4
	    -rows     0
	    -validate {real real real real}
	    -outfmt   {%14.9f %14.9f %14.9f "  %14.9f"}
	}
	loaddata kpoints ::pwscf::pwLoadKPoints \
	    "Load K-point coordinates from file ..."	
    }

    ########################################################################
    ##                                                                    ##
    ##         PAGE: CLIMBING_IMAGES & CONSTRAINTS & OCCUPATIONS          ##
    ##                                                                    ##
    ########################################################################
    page otherPage -name "Other Cards" {

	# CARD: CLIMBING_IMAGES

	group climbing_images -name "Card: CLIMBING_IMAGES" -decor normal {
	    keyword climbing_images_key CLIMBING_IMAGES\n
	    line climbing_images_line -decor none {
		var climbing_images_var {
		    -label "List of climbing images, separated by a comma:"
		    -infmt %S
		}
	    }
	}

	# CARD: CONSTRAINTS
	
	group constraints_card -name "Card: CONSTRAINTS" -decor normal {
	    keyword constraints_key CONSTRAINTS\n
	    line constraints_line1 -decor none {
		var nconstr {
		    -label    "Number of constraints:"
		    -validate posint
		    -widget   spinint
		    -default  1
		}
		var constr_tol {
		    -label    "Tolerance for keeping the constraints satisfied:"
		    -validate fortranposreal
		}
		table constraints_table {
		    -caption  "Enter constraints data:"
		    -head     {constraint-type 1st-atom-index 2nd-atom-index}
		    -validate {posint posint posint}
		    -cols     3
		    -rows     1
		    -outfmt   {"  %d    " "%d " "%d "}
		}
	    }		    
	}

	# CARD: OCCUPATIONS
	
	group occupations_card -name "Card: OCCUPATIONS" -decor normal {	    
	    keyword occupations_key OCCUPATIONS\n
	    text occupations_text \
		-caption "Syntax for NON-spin polarized case:\n     u(1)  ....   ....   ....  u(10)\n     u(11) .... u(nbnd)\n\nSyntax for spin-polarized case:\n     u(1)  ....   ....   ....  u(10)\n     u(11) .... u(nbnd)\n     d(1)   ....  ....   ....  d(10)\n     d(11) .... d(nbnd)" \
		-label   "Specify occupation of each state (from 1 to nbnd) such that 10 occupations per are written per line:" \
		-readvar ::pwscf::pwscf($this,OCCUPATIONS) \
	    
	    #text occupations_text {		
	    #	-caption "Specify occupation of each state (from 1 to nbnd) such that 10 occupations per are written per line.\n\nSyntax for NON-spin polarized case:\n     u(1)  ....   ....   ....  u(10)\n     u(11) .... u(nbnd)\n\nSyntax for spin-polarized case:\n     u(1)  ....   ....  u(10)\n     u(11) .... u(nbnd)\n     d(1)   ....  ....   ....  d(10)\n     d(11) .... d(nbnd)"
	    #	-label   "Specify occupation of each state such (10 occupations per line):"
	    #	-readvar ::pwscf::pwscf($this,OCCUPATIONS)
	    #}
	}
    }
    

    # ----------------------------------------------------------------------
    # take care of specialties
    # ----------------------------------------------------------------------
    source pw-event.tcl

    # ------------------------------------------------------------------------
    # source the HELP file
    # ------------------------------------------------------------------------
    source pw-help.tcl
}
