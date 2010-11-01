!
! Copyright (C) 2002-2008 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE read_namelists_module
  !----------------------------------------------------------------------------
  !
  !  ... this module handles the reading of input namelists
  !  ... written by: Carlo Cavazzoni
  !  --------------------------------------------------
  !
  USE kinds,     ONLY : DP
  USE input_parameters
  !
  IMPLICIT NONE
  !
  SAVE
  !
  PRIVATE
  !
  REAL(DP), PARAMETER :: sm_not_set = -20.0_DP
  !
  PUBLIC :: read_namelists, sm_not_set
  !
  ! ... modules needed by read_xml.f90
  !
  PUBLIC :: control_defaults, system_defaults, ee_defaults, &
       electrons_defaults, wannier_ac_defaults, ions_defaults, &
       cell_defaults, press_ai_defaults, wannier_defaults, control_bcast, &
       system_bcast, ee_bcast, electrons_bcast, ions_bcast, cell_bcast, &
       press_ai_bcast, wannier_bcast, wannier_ac_bcast, control_checkin, &
       system_checkin, electrons_checkin, ions_checkin, cell_checkin, &
       wannier_checkin, wannier_ac_checkin, fixval, &
       path_read_namelist, path_defaults, path_checkin, path_bcast
  !
  !  ... end of module-scope declarations
  !
  !  ----------------------------------------------
  !
  CONTAINS
     !
     !=-----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist CONTROL
     !
     !=-----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE control_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       IF ( prog == 'PW' ) THEN
          title = ' '
          calculation = 'scf'
       ELSE
          title = 'MD Simulation'
          calculation = 'cp'
       END IF

       verbosity = 'default'
       IF( prog == 'PW' ) restart_mode = 'from_scratch'
       IF( prog == 'CP' ) restart_mode = 'restart'
       nstep  = 50
       IF( prog == 'PW' ) iprint = 100000
       IF( prog == 'CP' ) iprint = 10
       IF( prog == 'PW' ) isave = 0
       IF( prog == 'CP' ) isave = 100
       !
       tstress = .FALSE.
       tprnfor = .FALSE.
       tabps = .FALSE.
       !
       IF( prog == 'PW' ) dt  = 20.0_DP
       IF( prog == 'CP' ) dt  =  1.0_DP
       !
       ndr = 50
       ndw = 50
       !
       ! ... use the path specified as outdir and the filename prefix
       ! ... to store output data
       !
       CALL get_env( 'ESPRESSO_TMPDIR', outdir )
       IF ( TRIM( outdir ) == ' ' ) outdir = './'
       IF( prog == 'PW' ) prefix = 'pwscf'
       IF( prog == 'CP' ) prefix = 'cp'
       !
       ! ... directory containing the pseudopotentials
       !
       CALL get_env( 'ESPRESSO_PSEUDO', pseudo_dir )
       IF ( TRIM( pseudo_dir ) == ' ') THEN
          CALL get_env( 'HOME', pseudo_dir )
          pseudo_dir = TRIM( pseudo_dir ) // '/espresso/pseudo/'
       END IF
       !
       refg          = 0.05_DP
       max_seconds   = 1.E+7_DP
       ekin_conv_thr = 1.E-6_DP
       etot_conv_thr = 1.E-4_DP
       forc_conv_thr = 1.E-3_DP
       disk_io  = 'default'
       dipfield = .FALSE.
       lberry   = .FALSE.
       gdir     = 0
       nppstr   = 0
       wf_collect = .FALSE.
       IF( prog == 'CP' ) wf_collect = .TRUE.  ! default for CP is true
       printwfc = -1
       lelfield = .FALSE.
       nberrycyc  = 1
       lkpoint_dir = .TRUE.
       lecrpa   = .FALSE.   
       !
       saverho = .TRUE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist SYSTEM
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE system_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       ibrav  = -1
       celldm = (/ 0.0_DP, 0.0_DP, 0.0_DP, 0.0_DP, 0.0_DP, 0.0_DP /)
       a = 0.0_DP
       b = 0.0_DP
       c = 0.0_DP
       cosab = 0.0_DP
       cosac = 0.0_DP
       cosbc = 0.0_DP
       nat    = 0
       ntyp   = 0
       nbnd   = 0
       tot_charge = 0.0_DP
       tot_magnetization = -1
       ecutwfc = 0.0_DP
       ecutrho = 0.0_DP
       nr1  = 0
       nr2  = 0
       nr3  = 0
       nr1s = 0
       nr2s = 0
       nr3s = 0
       nr1b = 0
       nr2b = 0
       nr3b = 0
       occupations = 'fixed'
       smearing = 'gaussian'
       degauss = 0.0_DP
       nspin = 1
       nosym = .FALSE.
       nosym_evc = .FALSE.
       force_symmorphic = .FALSE.
       noinv = .FALSE.
       ecfixed = 0.0_DP
       qcutz   = 0.0_DP
       q2sigma = 0.01_DP
       input_dft = 'none'
!
! ... set starting_magnetization to an invalid value:
! ... in PW starting_magnetization MUST be set for at least one atomic type
! ... (unless the magnetization is set in other ways)
! ... in CP starting_magnetization MUST REMAIN UNSET
!
       starting_magnetization = sm_not_set

       IF ( prog == 'PW' ) THEN
          !
          starting_ns_eigenvalue = -1.0_DP
          U_projection_type = 'atomic'
          !
       END IF
       lda_plus_U = .FALSE.
       Hubbard_U = 0.0_DP
       Hubbard_alpha = 0.0_DP
      step_pen=.false.
      A_pen=0.0_DP
      sigma_pen=0.01_DP
      alpha_pen=0.0_DP
       edir = 1
       emaxpos = 0.5_DP
       eopreg = 0.1_DP
       eamp = 0.0_DP
       !
       !  ... postprocessing of DOS & phonons & el-ph
       la2F = .FALSE.
       !
       ! ... non collinear program variables
       !
       lspinorb = .FALSE.
       noncolin = .FALSE.
       lambda = 1.0_DP
       constrained_magnetization= 'none'
       fixed_magnetization = 0.0_DP
       B_field = 0.0_DP
       angle1 = 0.0_DP
       angle2 = 0.0_DP
       report = 1
       !
       no_t_rev = .FALSE.
       !
       assume_isolated = 'none'
       !
       one_atom_occupations=.FALSE.
       !
       spline_ps = .false.
       ! 
       real_space = .false.
       !
       ! ... DFT-D
       !
       london      = .false.
       london_s6   = 0.75_DP
       london_rcut = 200.00_DP
       !
       RETURN
       !
     END SUBROUTINE
! DCC
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist EE
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE ee_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       ncompx = 1
       ncompy = 1
       ncompz = 1
       mr1 = 0
       mr2 = 0
       mr3 = 0
       ecutcoarse = 100.D0
       errtol = 1.d-22
       nlev = 2
       itmax = 1000
       whichbc = 0
!       centercompx = 0.D0
!       centercompy = 0.D0
!       centercompz = 0.D0
!       spreadcomp = -9999.D0
       mixing_charge_compensation = 1.0D0
       n_charge_compensation = 5
       comp_thr =  1.D-4
!         multipole = 'dipole'
!       poisson_maxiter = 5000
!       poisson_thr = 1.D-6
!       comp_thr = 1.D-2
!       ebc_thr = 1.D-2
!       rhoionmax = 1.D0
!       smoothspr = 0.25D0
!       deltapot = 5.D-1
       nlev = 2
!       which_smoothing = 'sphere'
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist ELECTRONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE electrons_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       emass = 400.0_DP
       emass_cutoff = 2.5_DP
       orthogonalization = 'ortho'
       ortho_eps = 1.E-8_DP
       ortho_max = 20
       electron_maxstep = 100
       !
       ! ... ( 'sd' | 'cg' | 'damp' | 'verlet' | 'none' | 'diis' )
       !
       electron_dynamics = 'none'
       electron_damping = 0.1_DP
       !
       ! ... ( 'zero' | 'default' )
       !
       electron_velocities = 'default'
       !
       ! ... ( 'nose' | 'not_controlled' | 'rescaling')
       !
       electron_temperature = 'not_controlled'
       ekincw = 0.001_DP
       fnosee = 1.0_DP
       ampre  = 0.0_DP
       grease = 1.0_DP
       IF ( prog == 'PW' ) THEN
          !
          startingwfc = 'atomic+random'
          startingpot = 'atomic'
          !
       ELSE
          !
          startingwfc = 'random'
          startingpot = ' '
          !
       END IF
       conv_thr = 1.E-6_DP
       diis_size = 4
       diis_nreset = 3
       diis_hcut = 1.0_DP
       diis_wthr = 0.0_DP
       diis_delt = 0.0_DP
       diis_maxstep = 100
       diis_rot = .FALSE.
       diis_fthr = 0.0_DP
       diis_temp = 0.0_DP
       diis_achmix = 0.0_DP
       diis_g0chmix = 0.0_DP
       diis_g1chmix = 0.0_DP
       diis_nchmix = 3
       diis_nrot = 3
       diis_rothr  = 0.0_DP
       diis_ethr   = 0.0_DP
       diis_chguess = .FALSE.
       mixing_mode = 'plain'
       mixing_fixed_ns = 0
       mixing_beta = 0.7_DP
       mixing_ndim = 8
       diagonalization = 'david'
       diago_thr_init = 0.0_DP
       diago_cg_maxiter = 20
       diago_david_ndim = 4
       diago_full_acc = .FALSE.
       !
       sic = 'none'
       sic_epsilon = 0.0_DP
       sic_alpha = 0.0_DP
       force_pairing = .false.
       !
       fermi_energy = 0.0_DP
       n_inner = 2
       niter_cold_restart=1
       lambda_cold=0.03_DP
       rotation_dynamics = "line-minimization"
       occupation_dynamics = "line-minimization"
       rotmass = 0.0_DP
       occmass = 0.0_DP
       rotation_damping = 0.0_DP
       occupation_damping = 0.0_DP
       !
       tcg     = .FALSE.
       maxiter = 100
       passop  = 0.3_DP
       niter_cg_restart = 20
       etresh  = 1.E-6_DP
       !
       epol   = 3
       efield = 0.0_DP
       epol2  = 3
       efield2 = 0.0_DP
       efield_cart(1)=0.d0
       efield_cart(2)=0.d0
       efield_cart(3)=0.d0
       !
       occupation_constraints = .false.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist WANNIER_AC
     !
     !----------------------------------------------------------------------
     SUBROUTINE wannier_ac_defaults( prog )
       !----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       plot_wannier = .FALSE.
       use_energy_int = .FALSE.
       print_wannier_coeff = .FALSE.
       nwan = 0
       constrain_pot = 0.d0
       plot_wan_num = 0
       plot_wan_spin = 1
       !
       RETURN
       !
     END SUBROUTINE

     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist IONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE ions_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       ! ... ( 'full' | 'coarse-grained' )
       !
       phase_space = 'full'
       !
       ! ... ( 'sd' | 'cg' | 'damp' | 'verlet' | 'none' | 'bfgs' | 'beeman' )
       !
       ion_dynamics = 'none'
       ion_radius   = 0.5_DP
       ion_damping  = 0.1_DP
       !
       ! ... ( 'default' | 'from_input' )
       !
       ion_positions = 'default'
       !
       ! ... ( 'zero' | 'default' | 'from_input' )
       !
       ion_velocities = 'default'
       !
       ! ... ( 'nose' | 'not_controlled' | 'rescaling' | 'berendsen' |
       !       'andersen' | 'langevin' )
       !
       ion_temperature = 'not_controlled'
       !
       tempw       = 300.0_DP
       fnosep      = -1.0_DP
       fnosep(1)   = 1.0_DP
       nhpcl       = 0
       nhptyp      = 0
       ndega       = 0
       tranp       = .FALSE.
       amprp       = 0.0_DP
       greasp      = 1.0_DP
       tolp        = 100.0_DP
       ion_nstepe  = 1
       ion_maxstep = 100
       delta_t     = 1.0_DP
       nraise      = 1
       !
       refold_pos       = .FALSE.
       remove_rigid_rot = .FALSE.
       !
       upscale           = 10.0_DP
       pot_extrapolation = 'atomic'
       wfc_extrapolation = 'none'
       !
       !
       ! ... defaults for "path" optimisations variables
       !
!       num_of_images  = 0
!       first_last_opt = .FALSE.
!       use_masses     = .FALSE.
!       use_freezing   = .FALSE.
!       opt_scheme     = 'quick-min'
!       temp_req       = 0.0_DP
!       ds             = 1.0_DP
!       path_thr       = 0.05_DP
!       CI_scheme      = 'no-CI'
!       k_max          = 0.1_DP
!       k_min          = 0.1_DP
!       fixed_tan      = .FALSE.
       !
       ! ... BFGS defaults
       !
       bfgs_ndim        = 1
       trust_radius_max = 0.8_DP   ! bohr
       trust_radius_min = 1.E-4_DP ! bohr
       trust_radius_ini = 0.5_DP   ! bohr
       w_1              = 0.01_DP
       w_2              = 0.50_DP
       !
       sic_rloc = 0.0_DP
       !
       ! ... meta-dynamics defaults
       !
       fe_step     = 0.4_DP
       fe_nstep    = 100
       sw_nstep    = 10
       eq_nstep    = 0
       g_amplitude = 0.005_DP
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist PATH
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE path_defaults( )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       !
       ! ... ( 'full' | 'coarse-grained' )
       !
       ! ... defaults for "path" optimisations variables
       !
         string_method  = 'neb'
         num_of_images  = 0
         first_last_opt = .FALSE.
         use_masses     = .FALSE.
         use_freezing   = .FALSE.
         opt_scheme     = 'quick-min'
         temp_req       = 0.0_DP
         ds             = 1.0_DP
         path_thr       = 0.05_DP
         CI_scheme      = 'no-CI'
         k_max          = 0.1_DP
         k_min          = 0.1_DP
         fixed_tan      = .FALSE.
         nstep_path    = 1
         restart_mode = 'from_scratch'
       !
       ! for reading ions namelist we need to set calculation=relax
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist CELL
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE cell_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       cell_parameters = 'default'
       !
       ! ... ( 'sd' | 'pr' | 'none' | 'w' | 'damp-pr' | 'damp-w' | 'bfgs' )
       !
       cell_dynamics = 'none'
       !
       ! ... ( 'zero' | 'default' )
       !
       cell_velocities = 'default'
       press = 0.0_DP
       wmass = 0.0_DP
       !
       ! ... ( 'nose' | 'not_controlled' | 'rescaling' )
       !
       cell_temperature = 'not_controlled'
       temph = 0.0_DP
       fnoseh = 1.0_DP
       greash = 1.0_DP
       !
       ! ... ('all'* | 'volume' | 'x' | 'y' | 'z' | 'xy' | 'xz' | 'yz' | 'xyz' )
       !
       cell_dofree = 'all'
       cell_factor = 0.0_DP
       cell_nstepe = 1
       cell_damping = 0.0_DP
       press_conv_thr = 0.5_DP
       !
       RETURN
       !
     END SUBROUTINE
     !
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist PRESS_AI
     !
     !=----------------------------------------------------------------------=!
     !
     !----------------------------------------------------------------------
     SUBROUTINE press_ai_defaults( prog )
     !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       abivol = .false.
       abisur = .false.
       pvar = .false.
       fill_vac = .false.
       cntr = .false.
       scale_at = .false.
       t_gauss = .false.
       jellium = .false.

       P_ext = 0.0_DP
       P_in = 0.0_DP
       P_fin = 0.0_DP
       Surf_t = 0.0_DP
       rho_thr = 0.0_DP
       dthr = 0.0_DP
       step_rad = 0.0_DP
       delta_eps = 0.0_DP
       delta_sigma = 0.0_DP
       R_j = 0.0_DP
       h_j = 0.0_DP

       n_cntr = 0
       axis = 3
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Variables initialization for Namelist WANNIER
     !
     !-----------------------------------------------------------------------
     SUBROUTINE wannier_defaults( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
       !
       !
       wf_efield = .FALSE.
       wf_switch = .FALSE.
       !
       sw_len = 1
       !
       efx0 = 0.0_DP
       efy0 = 0.0_DP
       efz0 = 0.0_DP
       efx1 = 0.0_DP
       efy1 = 0.0_DP
       efz1 = 0.0_DP
       !
       wfsd = 1
       !
       wfdt        = 5.0_DP
       maxwfdt     = 0.30_DP
       wf_q        = 1500.0_DP
       wf_friction = 0.3_DP
       !
       nit    = 10
       nsd    = 10
       nsteps = 20
       !
       tolw = 1.E-8_DP
       !
       adapt = .TRUE.
       !
       calwf  = 3
       nwf    = 0
       wffort = 40
       !
       writev = .FALSE.
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist CONTROL
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE control_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY : ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( title,         ionode_id )
       CALL mp_bcast( calculation,   ionode_id )
       CALL mp_bcast( verbosity,     ionode_id )
       CALL mp_bcast( restart_mode,  ionode_id )
       CALL mp_bcast( nstep,         ionode_id )
       CALL mp_bcast( iprint,        ionode_id )
       CALL mp_bcast( isave,         ionode_id )
       CALL mp_bcast( tstress,       ionode_id )
       CALL mp_bcast( tprnfor,       ionode_id )
       CALL mp_bcast( tabps,         ionode_id )
       CALL mp_bcast( dt,            ionode_id )
       CALL mp_bcast( ndr,           ionode_id )
       CALL mp_bcast( ndw,           ionode_id )
       CALL mp_bcast( outdir,        ionode_id )
       CALL mp_bcast( wfcdir,        ionode_id )
       CALL mp_bcast( prefix,        ionode_id )
       CALL mp_bcast( max_seconds,   ionode_id )
       CALL mp_bcast( ekin_conv_thr, ionode_id )
       CALL mp_bcast( etot_conv_thr, ionode_id )
       CALL mp_bcast( forc_conv_thr, ionode_id )
       CALL mp_bcast( pseudo_dir,    ionode_id )
       CALL mp_bcast( refg,          ionode_id )
       CALL mp_bcast( disk_io,       ionode_id )
       CALL mp_bcast( tefield,       ionode_id )
       CALL mp_bcast( tefield2,      ionode_id )
       CALL mp_bcast( dipfield,      ionode_id )
       CALL mp_bcast( lberry,        ionode_id )
       CALL mp_bcast( gdir,          ionode_id )
       CALL mp_bcast( nppstr,        ionode_id )
       CALL mp_bcast( lkpoint_dir,   ionode_id )
       CALL mp_bcast( wf_collect,    ionode_id )
       CALL mp_bcast( printwfc,      ionode_id )
       CALL mp_bcast( lelfield,      ionode_id )
       CALL mp_bcast( nberrycyc,     ionode_id )
       CALL mp_bcast( saverho,       ionode_id )
       CALL mp_bcast( lecrpa,        ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist SYSTEM
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE system_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY : ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( ibrav,             ionode_id )
       CALL mp_bcast( celldm,            ionode_id )
       CALL mp_bcast( a,                 ionode_id )
       CALL mp_bcast( b,                 ionode_id )
       CALL mp_bcast( c,                 ionode_id )
       CALL mp_bcast( cosab,             ionode_id )
       CALL mp_bcast( cosac,             ionode_id )
       CALL mp_bcast( cosbc,             ionode_id )
       CALL mp_bcast( nat,               ionode_id )
       CALL mp_bcast( ntyp,              ionode_id )
       CALL mp_bcast( nbnd,              ionode_id )
       CALL mp_bcast( tot_charge,        ionode_id )
       CALL mp_bcast( tot_magnetization, ionode_id )
       CALL mp_bcast( ecutwfc,           ionode_id )
       CALL mp_bcast( ecutrho,           ionode_id )
       CALL mp_bcast( nr1,               ionode_id )
       CALL mp_bcast( nr2,               ionode_id )
       CALL mp_bcast( nr3,               ionode_id )
       CALL mp_bcast( nr1s,              ionode_id )
       CALL mp_bcast( nr2s,              ionode_id )
       CALL mp_bcast( nr3s,              ionode_id )
       CALL mp_bcast( nr1b,              ionode_id )
       CALL mp_bcast( nr2b,              ionode_id )
       CALL mp_bcast( nr3b,              ionode_id )
       CALL mp_bcast( occupations,       ionode_id )
       CALL mp_bcast( smearing,          ionode_id )
       CALL mp_bcast( degauss,           ionode_id )
       CALL mp_bcast( nspin,             ionode_id )
       CALL mp_bcast( nosym,             ionode_id )
       CALL mp_bcast( nosym_evc,         ionode_id )
       CALL mp_bcast( noinv,             ionode_id )
       CALL mp_bcast( force_symmorphic,  ionode_id )
       CALL mp_bcast( ecfixed,           ionode_id )
       CALL mp_bcast( qcutz,             ionode_id )
       CALL mp_bcast( q2sigma,           ionode_id )
       CALL mp_bcast( input_dft,         ionode_id )
#ifdef EXX
       CALL mp_bcast( nqx1,                   ionode_id )
       CALL mp_bcast( nqx2,                   ionode_id )
       CALL mp_bcast( nqx3,                   ionode_id )
       CALL mp_bcast( exx_fraction,           ionode_id )
       CALL mp_bcast( screening_parameter,    ionode_id ) 
       CALL mp_bcast( exxdiv_treatment,       ionode_id )
       CALL mp_bcast( x_gamma_extrapolation,  ionode_id )
       CALL mp_bcast( yukawa,                 ionode_id )
       CALL mp_bcast( ecutvcut,               ionode_id )
#endif
       CALL mp_bcast( starting_magnetization, ionode_id )
       CALL mp_bcast( starting_ns_eigenvalue, ionode_id )
       CALL mp_bcast( U_projection_type,      ionode_id )
       CALL mp_bcast( lda_plus_U,             ionode_id )
       CALL mp_bcast( Hubbard_U,              ionode_id )
       CALL mp_bcast( Hubbard_alpha,          ionode_id )
       CALL mp_bcast( step_pen,               ionode_id )
       CALL mp_bcast( A_pen,                  ionode_id )
       CALL mp_bcast( sigma_pen,              ionode_id )
       CALL mp_bcast( alpha_pen,              ionode_id )
       CALL mp_bcast( edir,                   ionode_id )
       CALL mp_bcast( emaxpos,                ionode_id )
       CALL mp_bcast( eopreg,                 ionode_id )
       CALL mp_bcast( eamp,                   ionode_id )
       CALL mp_bcast( la2F,                   ionode_id )
       !
       ! ... non collinear broadcast
       !
       CALL mp_bcast( lspinorb,                  ionode_id )
       CALL mp_bcast( noncolin,                  ionode_id )
       CALL mp_bcast( angle1,                    ionode_id )
       CALL mp_bcast( angle2,                    ionode_id )
       CALL mp_bcast( report,                    ionode_id )
       CALL mp_bcast( constrained_magnetization, ionode_id )
       CALL mp_bcast( B_field,                   ionode_id )
       CALL mp_bcast( fixed_magnetization,       ionode_id )
       CALL mp_bcast( lambda,                    ionode_id )
       !
       CALL mp_bcast( assume_isolated,           ionode_id )
       CALL mp_bcast( one_atom_occupations,      ionode_id )
       CALL mp_bcast( spline_ps,                 ionode_id )
       !
       CALL mp_bcast( london,                    ionode_id )
       CALL mp_bcast( london_s6,                 ionode_id )
       CALL mp_bcast( london_rcut,               ionode_id )
       !
       CALL mp_bcast( no_t_rev,                  ionode_id )

       RETURN
       !
     END SUBROUTINE
! DCC
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist EE
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE ee_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY : ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( ecutcoarse,                 ionode_id )
       CALL mp_bcast( mixing_charge_compensation, ionode_id )
       CALL mp_bcast( errtol,                     ionode_id )
       CALL mp_bcast( comp_thr,                   ionode_id )
       CALL mp_bcast( nlev,                       ionode_id )
       CALL mp_bcast( itmax,                      ionode_id )
       CALL mp_bcast( whichbc,                    ionode_id )
       CALL mp_bcast( n_charge_compensation,      ionode_id )
       CALL mp_bcast( ncompx,                     ionode_id )
       CALL mp_bcast( ncompy,                     ionode_id )
       CALL mp_bcast( ncompz,                     ionode_id )
       CALL mp_bcast( mr1,                        ionode_id )
       CALL mp_bcast( mr2,                        ionode_id )
       CALL mp_bcast( mr3,                        ionode_id )
       CALL mp_bcast( cellmin,                    ionode_id )
       CALL mp_bcast( cellmax,                    ionode_id )

       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist ELECTRONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE electrons_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY : ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( emass,                ionode_id )
       CALL mp_bcast( emass_cutoff,         ionode_id )
       CALL mp_bcast( orthogonalization,    ionode_id )
       CALL mp_bcast( electron_maxstep,     ionode_id )
       CALL mp_bcast( ortho_eps,            ionode_id )
       CALL mp_bcast( ortho_max,            ionode_id )
       CALL mp_bcast( electron_dynamics,    ionode_id )
       CALL mp_bcast( electron_damping,     ionode_id )
       CALL mp_bcast( electron_velocities,  ionode_id )
       CALL mp_bcast( electron_temperature, ionode_id )
       CALL mp_bcast( conv_thr,             ionode_id )
       CALL mp_bcast( ekincw,               ionode_id )
       CALL mp_bcast( fnosee,               ionode_id )
       CALL mp_bcast( startingwfc,          ionode_id )
       CALL mp_bcast( ampre,                ionode_id )
       CALL mp_bcast( grease,               ionode_id )
       CALL mp_bcast( startingpot,          ionode_id )
       CALL mp_bcast( diis_size,            ionode_id )
       CALL mp_bcast( diis_nreset,          ionode_id )
       CALL mp_bcast( diis_hcut,            ionode_id )
       CALL mp_bcast( diis_wthr,            ionode_id )
       CALL mp_bcast( diis_delt,            ionode_id )
       CALL mp_bcast( diis_maxstep,         ionode_id )
       CALL mp_bcast( diis_rot,             ionode_id )
       CALL mp_bcast( diis_fthr,            ionode_id )
       CALL mp_bcast( diis_temp,            ionode_id )
       CALL mp_bcast( diis_achmix,          ionode_id )
       CALL mp_bcast( diis_g0chmix,         ionode_id )
       CALL mp_bcast( diis_g1chmix,         ionode_id )
       CALL mp_bcast( diis_nchmix,          ionode_id )
       CALL mp_bcast( diis_nrot,            ionode_id )
       CALL mp_bcast( diis_rothr,           ionode_id )
       CALL mp_bcast( diis_ethr,            ionode_id )
       CALL mp_bcast( diis_chguess,         ionode_id )
       CALL mp_bcast( mixing_fixed_ns,      ionode_id )
       CALL mp_bcast( mixing_mode,          ionode_id )
       CALL mp_bcast( mixing_beta,          ionode_id )
       CALL mp_bcast( mixing_ndim,          ionode_id )
       CALL mp_bcast( tqr,                  ionode_id )
       CALL mp_bcast( diagonalization,      ionode_id )
       CALL mp_bcast( diago_thr_init,       ionode_id )
       CALL mp_bcast( diago_cg_maxiter,     ionode_id )
       CALL mp_bcast( diago_david_ndim,     ionode_id )
       CALL mp_bcast( diago_full_acc,       ionode_id )
       CALL mp_bcast( sic,                  ionode_id )
       CALL mp_bcast( sic_epsilon ,         ionode_id )
       CALL mp_bcast( sic_alpha   ,         ionode_id )
       CALL mp_bcast( force_pairing ,       ionode_id )
       !
       ! ... ensemble-DFT
       !
       CALL mp_bcast( fermi_energy,       ionode_id )
       CALL mp_bcast( n_inner,            ionode_id )
       CALL mp_bcast( niter_cold_restart, ionode_id )
       CALL mp_bcast( lambda_cold,        ionode_id )
       CALL mp_bcast( rotation_dynamics,  ionode_id )
       CALL mp_bcast( occupation_dynamics,ionode_id )
       CALL mp_bcast( rotmass,            ionode_id )
       CALL mp_bcast( occmass,            ionode_id )
       CALL mp_bcast( rotation_damping,   ionode_id )
       CALL mp_bcast( occupation_damping, ionode_id )
       !
       ! ... conjugate gradient
       !
       CALL mp_bcast( tcg,     ionode_id )
       CALL mp_bcast( maxiter, ionode_id )
       CALL mp_bcast( etresh,  ionode_id )
       CALL mp_bcast( passop,  ionode_id )
       CALL mp_bcast( niter_cg_restart, ionode_id )
       !
       ! ... electric field
       !
       CALL mp_bcast( epol,   ionode_id )
       CALL mp_bcast( efield, ionode_id )
       !
       CALL mp_bcast( epol2,   ionode_id )
       CALL mp_bcast( efield2, ionode_id )
       CALL mp_bcast( efield_cart,   ionode_id )
       !
       ! ... occupation constraints ...
       !
       CALL mp_bcast( occupation_constraints, ionode_id )
       !
       ! ... real space ...
       CALL mp_bcast( real_space, ionode_id)
       RETURN
       !
     END SUBROUTINE
     !
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist IONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE ions_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp,        ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( phase_space,       ionode_id )
       CALL mp_bcast( ion_dynamics,      ionode_id )
       CALL mp_bcast( ion_radius,        ionode_id )
       CALL mp_bcast( ion_damping,       ionode_id )
       CALL mp_bcast( ion_positions,     ionode_id )
       CALL mp_bcast( ion_velocities,    ionode_id )
       CALL mp_bcast( ion_temperature,   ionode_id )
       CALL mp_bcast( tempw,             ionode_id )
       CALL mp_bcast( fnosep,            ionode_id )
       CALL mp_bcast( nhgrp,             ionode_id )
       CALL mp_bcast( fnhscl,            ionode_id )
       CALL mp_bcast( nhpcl,             ionode_id )
       CALL mp_bcast( nhptyp,            ionode_id )
       CALL mp_bcast( ndega,             ionode_id )
       CALL mp_bcast( tranp,             ionode_id )
       CALL mp_bcast( amprp,             ionode_id )
       CALL mp_bcast( greasp,            ionode_id )
       CALL mp_bcast( tolp,              ionode_id )
       CALL mp_bcast( ion_nstepe,        ionode_id )
       CALL mp_bcast( ion_maxstep,       ionode_id )
       CALL mp_bcast( delta_t,           ionode_id )
       CALL mp_bcast( nraise,            ionode_id )
       CALL mp_bcast( refold_pos,        ionode_id )
       CALL mp_bcast( remove_rigid_rot,  ionode_id )
       CALL mp_bcast( upscale,           ionode_id )
       CALL mp_bcast( pot_extrapolation, ionode_id )
       CALL mp_bcast( wfc_extrapolation, ionode_id )
       !
       ! ... "path" variables broadcast
       !
!       CALL mp_bcast( num_of_images,      ionode_id )
!       CALL mp_bcast( first_last_opt,     ionode_id )
!       CALL mp_bcast( use_masses,         ionode_id )
!       CALL mp_bcast( use_freezing,       ionode_id )
!       CALL mp_bcast( fixed_tan,          ionode_id )
!       CALL mp_bcast( CI_scheme,          ionode_id )
!       CALL mp_bcast( opt_scheme,         ionode_id )
!       CALL mp_bcast( temp_req,           ionode_id )
!       CALL mp_bcast( ds,                 ionode_id )
!       CALL mp_bcast( k_max,              ionode_id )
!       CALL mp_bcast( k_min,              ionode_id )
!       CALL mp_bcast( path_thr,           ionode_id )
       !
       ! ... BFGS
       !
       CALL mp_bcast( bfgs_ndim,        ionode_id )
       CALL mp_bcast( trust_radius_max, ionode_id )
       CALL mp_bcast( trust_radius_min, ionode_id )
       CALL mp_bcast( trust_radius_ini, ionode_id )
       CALL mp_bcast( w_1,              ionode_id )
       CALL mp_bcast( w_2,              ionode_id )
       !
       CALL mp_bcast( sic_rloc, ionode_id )
       !
       CALL mp_bcast( fe_step,     ionode_id )
       CALL mp_bcast( fe_nstep,    ionode_id )
       CALL mp_bcast( sw_nstep,    ionode_id )
       CALL mp_bcast( eq_nstep,    ionode_id )
       CALL mp_bcast( g_amplitude, ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist NEB
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE path_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp,        ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       ! ... "path" variables broadcast
       !
       CALL mp_bcast ( string_method,     ionode_id ) 
       CALL mp_bcast( num_of_images,      ionode_id )
       CALL mp_bcast( first_last_opt,     ionode_id )
       CALL mp_bcast( use_masses,         ionode_id )
       CALL mp_bcast( use_freezing,       ionode_id )
       CALL mp_bcast( fixed_tan,          ionode_id )
       CALL mp_bcast( CI_scheme,          ionode_id )
       CALL mp_bcast( opt_scheme,         ionode_id )
       CALL mp_bcast( temp_req,           ionode_id )
       CALL mp_bcast( ds,                 ionode_id )
       CALL mp_bcast( k_max,              ionode_id )
       CALL mp_bcast( k_min,              ionode_id )
       CALL mp_bcast( path_thr,           ionode_id )
       CALL mp_bcast( nstep_path,         ionode_id )
       CALL mp_bcast( restart_mode,       ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist CELL
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE cell_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp, ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( cell_parameters,  ionode_id )
       CALL mp_bcast( cell_dynamics,    ionode_id )
       CALL mp_bcast( cell_velocities,  ionode_id )
       CALL mp_bcast( cell_dofree,      ionode_id )
       CALL mp_bcast( press,            ionode_id )
       CALL mp_bcast( wmass,            ionode_id )
       CALL mp_bcast( cell_temperature, ionode_id )
       CALL mp_bcast( temph,            ionode_id )
       CALL mp_bcast( fnoseh,           ionode_id )
       CALL mp_bcast( greash,           ionode_id )
       CALL mp_bcast( cell_factor,      ionode_id )
       CALL mp_bcast( cell_nstepe,      ionode_id )
       CALL mp_bcast( cell_damping,     ionode_id )
       CALL mp_bcast( press_conv_thr,   ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist PRESS_AI
     !
     !=----------------------------------------------------------------------=!
     !
     !----------------------------------------------------------------------
     SUBROUTINE press_ai_bcast()
       !----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp,        ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       !
       CALL mp_bcast( abivol, ionode_id )
       CALL mp_bcast( abisur, ionode_id )
       CALL mp_bcast( t_gauss, ionode_id )
       CALL mp_bcast( cntr, ionode_id )
       CALL mp_bcast( P_ext, ionode_id )
       CALL mp_bcast( Surf_t, ionode_id )
       CALL mp_bcast( pvar, ionode_id )
       CALL mp_bcast( P_in, ionode_id )
       CALL mp_bcast( P_fin, ionode_id )
       CALL mp_bcast( delta_eps, ionode_id )
       CALL mp_bcast( delta_sigma, ionode_id )
       CALL mp_bcast( fill_vac, ionode_id )
       CALL mp_bcast( scale_at, ionode_id )
       CALL mp_bcast( n_cntr, ionode_id )
       CALL mp_bcast( axis, ionode_id )
       CALL mp_bcast( rho_thr, ionode_id )
       CALL mp_bcast( dthr, ionode_id )
       CALL mp_bcast( step_rad, ionode_id )
       CALL mp_bcast( jellium, ionode_id )
       CALL mp_bcast( R_j, ionode_id )
       CALL mp_bcast( h_j, ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist WANNIER
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE wannier_bcast()
       !-----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp,        ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       CALL mp_bcast( wf_efield,   ionode_id )
       CALL mp_bcast( wf_switch,   ionode_id )
       CALL mp_bcast( sw_len,      ionode_id )
       CALL mp_bcast( efx0,        ionode_id )
       CALL mp_bcast( efy0,        ionode_id )
       CALL mp_bcast( efz0,        ionode_id )
       CALL mp_bcast( efx1,        ionode_id )
       CALL mp_bcast( efy1,        ionode_id )
       CALL mp_bcast( efz1,        ionode_id )
       CALL mp_bcast( wfsd,        ionode_id )
       CALL mp_bcast( wfdt,        ionode_id )
       CALL mp_bcast( maxwfdt,     ionode_id )
       CALL mp_bcast( wf_q,        ionode_id )
       CALL mp_bcast( wf_friction, ionode_id )
       CALL mp_bcast( nit,         ionode_id )
       CALL mp_bcast( nsd,         ionode_id )
       CALL mp_bcast( nsteps,      ionode_id )
       CALL mp_bcast( tolw,        ionode_id )
       CALL mp_bcast( adapt,       ionode_id )
       CALL mp_bcast( calwf,       ionode_id )
       CALL mp_bcast( nwf,         ionode_id )
       CALL mp_bcast( wffort,      ionode_id )
       CALL mp_bcast( writev,      ionode_id )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------------=!
     !
     !  Broadcast variables values for Namelist WANNIER_NEW
     !
     !=----------------------------------------------------------------------------=!
     !
     !----------------------------------------------------------------------
     SUBROUTINE wannier_ac_bcast()
       !----------------------------------------------------------------------
       !
       USE io_global, ONLY: ionode_id
       USE mp,        ONLY: mp_bcast
       !
       IMPLICIT NONE
       !
       !
       CALL mp_bcast( plot_wannier,ionode_id )
       CALL mp_bcast( use_energy_int,ionode_id )
       CALL mp_bcast( print_wannier_coeff,ionode_id )
       CALL mp_bcast( nwan,        ionode_id )
       CALL mp_bcast( plot_wan_num,ionode_id )
       CALL mp_bcast( plot_wan_spin,ionode_id )
!       CALL mp_bcast( wan_data,ionode_id )
       CALL mp_bcast( constrain_pot,   ionode_id )
       RETURN
       !
     END SUBROUTINE

     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist CONTROL
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE control_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' control_checkin '
       INTEGER           :: i
       LOGICAL           :: allowed = .FALSE.
       !
       !
       DO i = 1, SIZE( calculation_allowed )
          IF( TRIM(calculation) == calculation_allowed(i) ) allowed = .TRUE.
       END DO
       IF( .NOT. allowed ) &
          CALL errore( sub_name, ' calculation '''// &
                       & TRIM(calculation)//''' not allowed ',1)
       IF( ndr < 50 ) &
          CALL errore( sub_name,' ndr out of range ', 1 )
       IF( ndw > 0 .AND. ndw < 50 ) &
          CALL errore( sub_name,' ndw out of range ', 1 )
       IF( nstep < 0 ) &
          CALL errore( sub_name,' nstep out of range ', 1 )
       IF( iprint < 1 ) &
          CALL errore( sub_name,' iprint out of range ', 1 )

       IF( prog == 'PW' ) THEN
         IF( isave > 0 ) &
           CALL infomsg( sub_name,' isave not used in PW ' )
       ELSE
         IF( isave < 1 ) &
           CALL errore( sub_name,' isave out of range ', 1 )
       END IF

       IF( dt < 0.0_DP ) &
          CALL errore( sub_name,' dt out of range ', 1 )
       IF( max_seconds < 0.0_DP ) &
          CALL errore( sub_name,' max_seconds out of range ', 1 )

       IF( ekin_conv_thr < 0.0_DP ) THEN
          IF( prog == 'PW' ) THEN
            CALL infomsg( sub_name,' ekin_conv_thr not used in PW ')
          ELSE
            CALL errore( sub_name,' ekin_conv_thr out of range ', 1 )
          END IF
       END IF

       IF( etot_conv_thr < 0.0_DP ) &
          CALL errore( sub_name,' etot_conv_thr out of range ', 1 )
       IF( forc_conv_thr < 0.0_DP ) &
          CALL errore( sub_name,' forc_conv_thr out of range ', 1 )
       IF( prog == 'CP' ) THEN
          IF( dipfield ) &
             CALL infomsg( sub_name,' dipfield not yet implemented ')
          IF( lberry ) &
             CALL infomsg( sub_name,' lberry not implemented yet ')
          IF( gdir /= 0 ) &
             CALL infomsg( sub_name,' gdir not used ')
          IF( nppstr /= 0 ) &
             CALL infomsg( sub_name,' nppstr not used ')
       END IF
       !
       IF( prog == 'PW' .AND. TRIM( restart_mode ) == 'reset_counters' ) THEN
         CALL infomsg ( sub_name, ' restart_mode == reset_counters' // &
                    & ' not implemented in PW ' )
       END IF
       !
       IF( refg < 0 ) &
         CALL errore( sub_name, ' wrong table interval refg ', 1 )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist SYSTEM
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE system_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' system_checkin '
#ifdef EXX
       INTEGER           :: i
       LOGICAL           :: allowed
#endif
       !
       !
       IF( ibrav < 0 .OR. ibrav > 14 ) &
          CALL errore( sub_name ,' ibrav out of range ', MAX( 1, ibrav) )
       !
       IF( ( ibrav /= 0 ) .AND. ( celldm(1) == 0.0_DP ) .AND. ( a == 0.0_DP ) ) &
           CALL errore( ' iosys ', &
                      & ' invalid lattice parameters ( celldm or a )', 1 )
       !
       IF( nat < 0 ) &
          CALL errore( sub_name ,' nat less than zero ', MAX( nat, 1) )
       !
       IF( ntyp < 0 ) &
          CALL errore( sub_name ,' ntyp less than zero ', MAX( ntyp, 1) )
       IF( ntyp < 0 .OR. ntyp > nsx ) &
          CALL errore( sub_name , &
                       & ' ntyp too large, increase NSX ', MAX( ntyp, 1) )
       !
       IF( nspin < 1 .OR. nspin > 4 .OR. nspin == 3 ) &
          CALL errore( sub_name ,' nspin out of range ', MAX(nspin, 1 ) )
       !
       IF( ecutwfc <= 0.0_DP ) &
          CALL errore( sub_name ,' ecutwfc out of range ',1)
       IF( ecutrho < 0.0_DP ) &
          CALL errore( sub_name ,' ecutrho out of range ',1)
       !
       IF( prog == 'CP' ) THEN
          IF( degauss /= 0.0_DP ) &
             CALL infomsg( sub_name ,' degauss is not used in CP ')
       END IF
       !
       IF( ecfixed < 0.0_DP ) &
          CALL errore( sub_name ,' ecfixed out of range ',1)
       IF( qcutz < 0.0_DP ) &
          CALL errore( sub_name ,' qcutz out of range ',1)
       IF( q2sigma < 0.0_DP ) &
          CALL errore( sub_name ,' q2sigma out of range ',1)
       IF( prog == 'CP' ) THEN
          IF( ANY(starting_magnetization /= SM_NOT_SET ) ) &
             CALL infomsg( sub_name ,&
                          & ' starting_magnetization is not used in CP ')
!          IF( lda_plus_U ) &
!             CALL infomsg( sub_name ,' lda_plus_U is not used in CP ')
          IF( la2F ) &
             CALL infomsg( sub_name ,' la2F is not used in CP ')
!          IF( ANY(Hubbard_U /= 0.0_DP) ) &
!             CALL infomsg( sub_name ,' Hubbard_U is not used in CP ')
          IF( ANY(Hubbard_alpha /= 0.0_DP) ) &
             CALL infomsg( sub_name ,' Hubbard_alpha is not used in CP ')
          IF( nosym ) &
             CALL infomsg( sub_name ,' nosym not implemented in CP ')
          IF( nosym_evc ) &
             CALL infomsg( sub_name ,' nosym_evc not implemented in CP ')
          IF( noinv ) &
             CALL infomsg( sub_name ,' noinv not implemented in CP ')
       END IF
       !
       ! ... control on SIC variables
       !
       IF ( sic /= 'none' ) THEN
          !
          IF (sic_epsilon > 1.0_DP )  &
             CALL errore( sub_name, &
                        & ' invalid sic_epsilon, greater than 1.',1 )
          IF (sic_epsilon < 0.0_DP )  &
             CALL errore( sub_name, &
                        & ' invalid sic_epsilon, less than 0 ',1 )
          IF (sic_alpha > 1.0_DP )  &
             CALL errore( sub_name, &
                        & ' invalid sic_alpha, greater than 1.',1 )
          IF (sic_alpha < 0.0_DP )  &
             CALL errore( sub_name, &
                        & ' invalid sic_alpha, less than 0 ',1 )
          !
          IF ( .NOT. force_pairing ) &
             CALL errore( sub_name, &
                        & ' invalid force_pairing with sic activated', 1 )
          IF ( nspin /= 2 ) &
             CALL errore( sub_name, &
                        & ' invalid nspin with sic activated', 1 )
          IF ( tot_magnetization /= 1._DP )  &
             CALL errore( sub_name, &
                  & ' invalid tot_magnetization_ with sic activated', 1 )
          !
       ENDIF
       !
       ! ... control on EXX variables
       !
#ifdef EXX       
       !
       DO i = 1, SIZE( exxdiv_treatment_allowed )
          IF( TRIM(exxdiv_treatment) == exxdiv_treatment_allowed(i) ) allowed = .TRUE.
       END DO
       IF( .NOT. allowed ) CALL errore(sub_name, &
           ' invalid exxdiv_treatment: '//TRIM(exxdiv_treatment), 1 )
       !
       IF ( TRIM(exxdiv_treatment) == "yukawa" .AND. yukawa <= 0.0 ) &
          CALL errore(sub_name, ' invalid value for yukawa', 1 )
       !
       IF ( TRIM(exxdiv_treatment) == "vcut_ws" .AND. ecutvcut <= 0.0 ) &
          CALL errore(sub_name, ' invalid value for ecutvcut', 1 )
       !
       IF ( x_gamma_extrapolation .AND. ( TRIM(exxdiv_treatment) == "vcut_ws" .OR. &
                                          TRIM(exxdiv_treatment) == "vcut_spherical" ) ) &
          CALL errore(sub_name, ' x_gamma_extrapolation cannot be used with vcut', 1 )
       !
#endif
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist ELECTRONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE electrons_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' electrons_checkin '
       INTEGER           :: i
       LOGICAL           :: allowed = .FALSE.
       !
       !
       DO i = 1, SIZE(electron_dynamics_allowed)
          IF( TRIM(electron_dynamics) == &
              electron_dynamics_allowed(i) ) allowed = .TRUE.
       END DO
       IF( .NOT. allowed ) &
          CALL errore( sub_name, ' electron_dynamics '''//&
                       & TRIM(electron_dynamics)//''' not allowed ',1)
       IF( emass <= 0.0_DP ) &
          CALL errore( sub_name, ' emass less or equal 0 ',1)
       IF( emass_cutoff <= 0.0_DP ) &
          CALL errore( sub_name, ' emass_cutoff less or equal 0 ',1)
       IF( ortho_eps <= 0.0_DP ) &
          CALL errore( sub_name, ' ortho_eps less or equal 0 ',1)
       IF( ortho_max < 1 ) &
          CALL errore( sub_name, ' ortho_max less than 1 ',1)
       IF( fnosee <= 0.0_DP ) &
          CALL errore( sub_name, ' fnosee less or equal 0 ',1)
       IF( ekincw <= 0.0_DP ) &
          CALL errore( sub_name, ' ekincw less or equal 0 ',1)
       IF( occupation_constraints ) &
          CALL errore( sub_name, ' occupation_constraints not yet implemented ',1)

!
       RETURN
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist IONS
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE ions_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' ions_checkin '
       INTEGER           :: i
       LOGICAL           :: allowed = .FALSE.
       !
       !
       DO i = 1, SIZE( phase_space_allowed )
          IF( TRIM( phase_space ) == phase_space_allowed(i) ) allowed = .TRUE.
       END DO
       IF ( .NOT. allowed ) &
          CALL errore( sub_name, ' phase_space '''// &
                       & TRIM( phase_space )// ''' not allowed ', 1 )
       !
       allowed = .FALSE.
       DO i = 1, SIZE(ion_dynamics_allowed)
          IF( TRIM(ion_dynamics) == ion_dynamics_allowed(i) ) allowed = .TRUE.
       END DO
       IF( .NOT. allowed ) &
          CALL errore( sub_name, ' ion_dynamics '''// &
                       & TRIM(ion_dynamics)//''' not allowed ',1)
       IF( tempw <= 0.0_DP ) &
          CALL errore( sub_name,' tempw out of range ',1)
       IF( fnosep( 1 ) <= 0.0_DP ) &
          CALL errore( sub_name,' fnosep out of range ',1)
       IF( nhpcl > nhclm ) &
          CALL infomsg ( sub_name,' nhpcl should be less than nhclm')
       IF( nhpcl < 0 ) &
          CALL infomsg ( sub_name,' nhpcl out of range ')
       IF( ion_nstepe <= 0 ) &
          CALL errore( sub_name,' ion_nstepe out of range ',1)
       IF( ion_maxstep < 0 ) &
          CALL errore( sub_name,' ion_maxstep out of range ',1)
       !
       ! ... general "path" variables checkin
       !
       !
!       full_phs_path_flag = .FALSE.
!       cg_phs_path_flag   = .FALSE.
       !
       !
       IF (sic /= 'none' .and. sic_rloc == 0.0_DP) &
          CALL errore( sub_name, ' invalid sic_rloc with sic activated ', 1 )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist CELL
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE path_checkin( )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=20) :: sub_name = ' path_checkin '
       INTEGER           :: i
       LOGICAL           :: allowed = .FALSE.
       !
       !
       ! ... general "path" variables checkin
              IF ( ds < 0.0_DP ) &
          CALL errore( sub_name,' ds out of range ',1)
       IF ( temp_req < 0.0_DP ) &
          CALL errore( sub_name,' temp_req out of range ',1)
       !
       allowed = .FALSE.
       DO i = 1, SIZE( opt_scheme_allowed )
          IF ( TRIM( opt_scheme ) == &
               opt_scheme_allowed(i) ) allowed = .TRUE.
       END DO
       IF ( .NOT. allowed ) &
          CALL errore( sub_name, ' opt_scheme '''// &
                     & TRIM( opt_scheme )//''' not allowed ', 1 )
       !
       !
       ! ... NEB(SM) specific checkin
       !
       IF ( k_max < 0.0_DP )  CALL errore( sub_name, 'k_max out of range', 1 )
       IF ( k_min < 0.0_DP )  CALL errore( sub_name, 'k_min out of range', 1 )
       IF ( k_max < k_min ) CALL errore( sub_name, 'k_max < k_min', 1 )
       !
!       IF ( nstep_path < 1 ) CALL errore ( sub_name, 'step_path out of range', 1 )
       !
       allowed = .FALSE.
       DO i = 1, SIZE( CI_scheme_allowed )
          IF ( TRIM( CI_scheme ) == CI_scheme_allowed(i) ) allowed = .TRUE.
       END DO
       !
       IF ( .NOT. allowed ) &
          CALL errore( sub_name, ' CI_scheme ''' // &
                      & TRIM( CI_scheme ) //''' not allowed ', 1 )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE cell_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' cell_checkin '
       INTEGER           :: i
       LOGICAL           :: allowed = .FALSE.
       !
       !
       DO i = 1, SIZE(cell_dynamics_allowed)
          IF( TRIM(cell_dynamics) == &
              cell_dynamics_allowed(i) ) allowed = .TRUE.
       END DO
       IF( .NOT. allowed ) &
          CALL errore( sub_name, ' cell_dynamics '''// &
                       TRIM(cell_dynamics)//''' not allowed ',1)
       IF( wmass < 0.0_DP ) &
          CALL errore( sub_name,' wmass out of range ',1)
       IF( prog == 'CP' ) THEN
          IF( cell_factor /= 0.0_DP ) &
             CALL infomsg( sub_name,' cell_factor not used in CP ')
       END IF
       IF( cell_nstepe <= 0 ) &
          CALL errore( sub_name,' cell_nstepe out of range ',1)
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist WANNIER
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE wannier_checkin( prog )
       !-----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = 'wannier_checkin'
       !
       IF ( calwf < 1 .OR. calwf > 5 ) &
          CALL errore( sub_name, ' calwf out of range ', 1 )
       !
       IF ( wfsd < 1 .OR. wfsd > 3 ) &
          CALL errore( sub_name, ' wfsd out of range ', 1 )      !
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Check input values for Namelist WANNIER_NEW
     !
     !=----------------------------------------------------------------------=!
     !
     !----------------------------------------------------------------------
     SUBROUTINE wannier_ac_checkin( prog )
       !--------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = 'wannier_new_checkin'
       !
       !
       IF ( nwan > nwanx ) &
          CALL errore( sub_name, ' nwan out of range ', 1 )

       IF ( plot_wan_num < 0 .OR. plot_wan_num > nwan ) &
          CALL errore( sub_name, ' plot_wan_num out of range ', 1 )

       IF ( plot_wan_spin < 0 .OR. plot_wan_spin > 2 ) &
          CALL errore( sub_name, ' plot_wan_spin out of range ', 1 )
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Set values according to the "calculation" variable
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE fixval( prog )
       !-----------------------------------------------------------------------
       !
       USE constants, ONLY : e2
       !
       IMPLICIT NONE
       !
       CHARACTER(LEN=2)  :: prog   ! ... specify the calling program
       CHARACTER(LEN=20) :: sub_name = ' fixval '
       !
       !
       SELECT CASE( TRIM( calculation ) )
          CASE ('scf')
             IF( prog == 'CP' ) THEN
                 electron_dynamics = 'damp'
                 ion_dynamics      = 'none'
                 cell_dynamics     = 'none'
             END IF
          CASE ('nscf', 'bands')
             IF( prog == 'CP' ) occupations = 'bogus'
             IF( prog == 'CP' ) electron_dynamics = 'damp'
          CASE ( 'cp-wf' )
             IF( prog == 'CP' ) THEN
                electron_dynamics = 'damp'
                ion_dynamics      = 'damp'
             END IF
             IF ( prog == 'PW' ) &
                CALL errore( sub_name, ' calculation ' // &
                           & TRIM( calculation ) // ' not implemented ', 1 )
          CASE ('relax')
             IF( prog == 'CP' ) THEN
                electron_dynamics = 'damp'
                ion_dynamics      = 'damp'
             ELSE IF( prog == 'PW' ) THEN
                ion_dynamics = 'bfgs'
             END IF
          CASE ( 'md', 'cp' )
             IF( prog == 'CP' ) THEN
                electron_dynamics = 'verlet'
                ion_dynamics      = 'verlet'
             ELSE IF( prog == 'PW' ) THEN
                ion_dynamics = 'verlet'
             END IF
          CASE ('vc-relax')
             IF( prog == 'CP' ) THEN
                electron_dynamics = 'damp'
                ion_dynamics      = 'damp'
                cell_dynamics     = 'damp-pr'
             ELSE IF( prog == 'PW' ) THEN
                ion_dynamics = 'bfgs'
                cell_dynamics= 'bfgs'
             END IF
          CASE ( 'vc-md', 'vc-cp' )
             IF( prog == 'CP' ) THEN
                electron_dynamics = 'verlet'
                ion_dynamics      = 'verlet'
                cell_dynamics     = 'pr'
             ELSE IF( prog == 'PW' ) THEN
                ion_dynamics = 'beeman'
             END IF
          CASE ( 'neb' )
             !
             ! ... "path" optimizations
             !
             IF( prog == 'CP' ) THEN
                !
                electron_dynamics = 'damp'
                ion_dynamics      = 'none'
                cell_dynamics     = 'none'
                !
             END IF
             !
          CASE ( 'smd' )
             !
             IF( prog == 'CP' ) THEN
                !
                electron_dynamics = 'damp'
                ion_dynamics      = 'damp'
                !
             END IF
             !
          CASE DEFAULT
             !
             CALL errore( sub_name,' calculation '// &
                        & TRIM(calculation)//' not implemented ', 1 )
             !
       END SELECT
       !
       IF ( prog == 'PW' ) THEN
          !
          IF ( calculation == 'nscf' .OR. calculation == 'bands'  ) THEN
             !
             startingpot = 'file'
             startingwfc = 'atomic'
             !
          ELSE IF ( restart_mode == "from_scratch" ) THEN
             !
             startingwfc = 'atomic'
             startingpot = 'atomic'
             !
          ELSE
             !
             startingwfc = 'file'
             startingpot = 'file'
             !
          END IF
          !
       END IF
       !
       IF ( TRIM( sic ) /= 'none' ) THEN
         force_pairing = ( nspin == 2 .AND. ( tot_magnetization==0._dp .OR. &
                                              tot_magnetization==1._dp ) )
       END IF
       !
       RETURN
       !
     END SUBROUTINE
     !
     !=----------------------------------------------------------------------=!
     !
     !  Namelist parsing main routine
     !
     !=----------------------------------------------------------------------=!
     !
     !-----------------------------------------------------------------------
     SUBROUTINE read_namelists( prog )
       !-----------------------------------------------------------------------
       !
       !  this routine reads data from standard input and puts them into
       !  module-scope variables (accessible from other routines by including
       !  this module, or the one that contains them)
       !  ----------------------------------------------
       !
       ! ... declare modules
       !
       USE io_global, ONLY : ionode, ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       ! ... declare variables
       !
       CHARACTER(LEN=2) :: prog   ! ... specify the calling program
                                  !     prog = 'PW'  pwscf
                                  !     prog = 'CP'  cpr
       !
       ! ... declare other variables
       !
       INTEGER :: ios
       !
       ! ... end of declarations
       !
       !  ----------------------------------------------
       !
       !
       IF( prog /= 'PW' .AND. prog /= 'CP' .AND. prog /= 'SM' ) &
          CALL errore( ' read_namelists ', ' unknown calling program ', 1 )
       !
       ! ... default settings for all namelists
       !
       IF( prog == 'PW' .OR. prog == 'CP') THEN
         CALL control_defaults( prog )
         CALL system_defaults( prog )
         CALL electrons_defaults( prog )
         CALL ions_defaults( prog )
         CALL cell_defaults( prog )
         CALL ee_defaults( prog )
       ENDIF
       IF( prog == 'SM') THEN
         CALL path_defaults()
       ENDIF
       !
       ! ... Here start reading standard input file
       !
       ! ... CONTROL namelist
       !
       IF(prog == 'PW' .OR. prog == 'CP' ) THEN
       ios = 0
       IF( ionode ) THEN
          READ( 5, control, iostat = ios )
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist control ', ABS(ios) )
       END IF
       !
       CALL control_bcast( )
       CALL control_checkin( prog )
       !
       ! ... fixval changes some default values according to the value
       ! ... of "calculation" read in CONTROL namelist
       !
       CALL fixval( prog )
       !
       ! ... SYSTEM namelist
       !
       ios = 0
       IF( ionode ) THEN
          READ( 5, system, iostat = ios )
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist system ', ABS(ios) )
       END IF
       !
       CALL system_bcast( )
       !
       CALL system_checkin( prog )
       !
       CALL allocate_input_ions( ntyp, nat )
       !
       ! ... ELECTRONS namelist
       !
       ios = 0
       IF( ionode ) THEN
          READ( 5, electrons, iostat = ios )
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist electrons ', ABS(ios) )
       END IF
       !
       CALL electrons_bcast( )
       CALL electrons_checkin( prog )
       !
       ! ... IONS namelist
       !
       ios = 0
       IF ( ionode ) THEN
          !
          IF ( TRIM( calculation ) == 'relax'    .OR. &
               TRIM( calculation ) == 'md'       .OR. &
               TRIM( calculation ) == 'vc-relax' .OR. &
               TRIM( calculation ) == 'vc-md'    .OR. &
               TRIM( calculation ) == 'cp'       .OR. &
               TRIM( calculation ) == 'vc-cp'    .OR. &
               TRIM( calculation ) == 'smd'      .OR. &
               TRIM( calculation ) == 'cp-wf') READ( 5, ions, iostat = ios )
  
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist ions ', ABS(ios) )
       END IF
       !
       CALL ions_bcast( )
       CALL ions_checkin( prog )
       !
       ! ... CELL namelist
       !
       ios = 0
       IF( ionode ) THEN
          IF( TRIM( calculation ) == 'vc-relax' .OR. &
              TRIM( calculation ) == 'vc-cp'    .OR. &
              TRIM( calculation ) == 'vc-md'    .OR. &
              TRIM( calculation ) == 'vc-md' ) THEN
             READ( 5, cell, iostat = ios )
          END IF
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist cell ', ABS(ios) )
       END IF
       !
       CALL cell_bcast()
       CALL cell_checkin( prog )
       !
       ios = 0
       IF( ionode ) THEN
          if (tabps) then
             READ( 5, press_ai, iostat = ios )
          end if
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist press_ai ', ABS(ios) )
       END IF
       !
       CALL press_ai_bcast()
       !
       ! ... EE namelist
       !
       IF ( TRIM( assume_isolated ) == 'dcc' ) THEN
          ios = 0
          IF( ionode ) READ( 5, ee, iostat = ios )
          CALL mp_bcast( ios, ionode_id )
          IF( ios /= 0 ) CALL errore( ' read_namelists ', &
                                    & ' reading namelist ee ', ABS(ios) )
       END IF
       CALL ee_bcast()
       !
       ! ... WANNIER NAMELIST
       !
       CALL wannier_defaults( prog )
       ios = 0
       IF( ionode ) THEN
          IF( TRIM( calculation ) == 'cp-wf' ) THEN
             READ( 5, wannier, iostat = ios )
          END IF
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist wannier ', ABS(ios) )
       END IF
       !
       CALL wannier_bcast()
       CALL wannier_checkin( prog )
       !
       ! ... WANNIER_NEW NAMELIST
       !
       CALL wannier_ac_defaults( prog )
       ios = 0
       IF( ionode ) THEN
          IF( use_wannier ) THEN
             READ( 5, wannier_ac, iostat = ios )
          END IF
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' read_namelists ', &
                     & ' reading namelist wannier_new ', ABS(ios) )
       END IF
       !
       CALL wannier_ac_bcast()
       CALL wannier_ac_checkin( prog )
       !
       ENDIF
       !
       IF (prog == 'SM') THEN
         CALL path_read_namelist(5)
       ENDIF
       !
       RETURN
       !
     END SUBROUTINE read_namelists
     !
     !
     !-----------------------------------------------------------------------
     SUBROUTINE path_read_namelist(unit)
       !-----------------------------------------------------------------------
       !
       !  this routine reads data from standard input and puts them into
       !  module-scope variables (accessible from other routines by including
       !  this module, or the one that contains them)
       !  ----------------------------------------------
       !
       ! ... declare modules
       !
       USE io_global, ONLY : ionode, ionode_id
       USE mp,        ONLY : mp_bcast
       !
       IMPLICIT NONE
       !
       ! ... declare variables
       !
       INTEGER, intent(in) :: unit
       !
       !
       ! ... declare other variables
       !
       INTEGER :: ios
       !
       ! ... end of declarations
       !
       !  ----------------------------------------------
       !
       !
       ! ... default settings for all namelists
       !
       CALL path_defaults( )
       !
       ! ... Here start reading standard input file
       !
       ! ... PATH namelist
       !
       ios = 0
       IF ( ionode ) THEN
          !
          READ( unit, path, iostat = ios )
          !
       END IF
       CALL mp_bcast( ios, ionode_id )
       IF( ios /= 0 ) THEN
          CALL errore( ' path_read_namelists ', &
                     & ' reading namelist path ', ABS(ios) )
       END IF
       !
       CALL path_bcast( )
       CALL path_checkin( )
       !
       RETURN
       !
     END SUBROUTINE path_read_namelist
     !
END MODULE read_namelists_module
