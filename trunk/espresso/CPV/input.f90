!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE input
   !---------------------------------------------------------------------------
   !
   USE kinds,     ONLY: DP
   USE io_global, ONLY: ionode, stdout
   !
   IMPLICIT NONE
   SAVE
   !
   PRIVATE                      !  Input Subroutines
                                !  should be called in the following order
                                !
   PUBLIC :: read_input_file    !  a) This sub. should be called first
   PUBLIC :: iosys_pseudo       !  b) then read pseudo files
   PUBLIC :: iosys              !  c) finally copy variables to modules
   PUBLIC :: modules_setup
   !
   LOGICAL :: has_been_read = .FALSE.
   !
   CONTAINS
   !
   !-------------------------------------------------------------------------
   SUBROUTINE read_input_file()
     !-------------------------------------------------------------------------
     !
     USE read_namelists_module, ONLY : read_namelists
     USE read_cards_module,     ONLY : read_cards
     USE input_parameters,      ONLY : calculation, title
     USE control_flags,         ONLY : lneb, lsmd, lpath, lwf, program_name
     USE printout_base,         ONLY : title_ => title
     !
     IMPLICIT NONE
     !
     CHARACTER(LEN=2) :: prog
     !
     !
     IF ( program_name == 'FPMD' ) prog = 'FP'
     IF ( program_name == 'CP90' ) prog = 'CP'
     !
     IF ( ionode ) CALL input_from_file()
     !
     ! ... Read NAMELISTS 
     !
     CALL read_namelists( prog )
     !
     ! ... Read CARDS 
     !
     CALL read_cards( prog )
     !
     lneb = ( TRIM( calculation ) == 'neb' )
     !
     lsmd = ( TRIM( calculation ) == 'smd' )
     !
     lpath = ( lneb .OR. lsmd )
     !
     IF ( lsmd .AND. ( program_name == 'FPMD' ) ) &
        CALL errore( 'read_input_file ', &
                     'string dynamics not implemented in FPMD', 1 )
     !
     lwf = ( TRIM( calculation ) == 'cp-wf' )
     !
     IF ( lwf .AND. ( program_name == 'FPMD' ) ) &
        CALL errore( 'read_input_file ', 'cp-wf not implemented in FPMD', 1 )
     !
     ! ... Set job title and print it on standard output
     !
     title_ = title
     !
     WRITE( stdout, '(/,3X,"Job Title: ",A )' ) TRIM( title_ )
     !
     has_been_read = .TRUE.
     !
     RETURN
     !
   END SUBROUTINE read_input_file
   !
   !-------------------------------------------------------------------------
   SUBROUTINE iosys_pseudo()
     !-------------------------------------------------------------------------
     !
     USE input_parameters,        ONLY : atom_pfile, pseudo_dir, ntyp, nat, &
                                         prefix, scradir, outdir, xc_type
     USE control_flags,           ONLY : program_name
     USE parameters,              ONLY : nsx
     USE read_pseudo_module_fpmd, ONLY : readpp
     USE io_files,                ONLY : psfile_     => psfile , &
                                         pseudo_dir_ => pseudo_dir, &
                                         scradir_    => scradir, &
                                         outdir_     => outdir, &
                                         prefix_     => prefix
     USE ions_base,               ONLY : nsp_ => nsp, nat_ => nat
     !
     IMPLICIT NONE
     !
     !
     IF ( .NOT. has_been_read ) &
        CALL errore( 'iosys_pseudo ', 'input file has not been read yet!', 1 )
     !
     prefix_  = TRIM( prefix  )
     scradir_ = TRIM( scradir )
     outdir_  = TRIM( outdir )
     !
     ! ... Set internal variables for the number of species and number of atoms
     !
     nsp_ = ntyp
     nat_ = nat
     !
     psfile_         = ' '
     psfile_(1:nsp_) = atom_pfile(1:nsp_)
     pseudo_dir_     = TRIM( pseudo_dir  )
     !
     ! ... read in pseudopotentials and wavefunctions files
     !
     CALL readpp( xc_type )
     !
     RETURN
     !
   END SUBROUTINE iosys_pseudo
   !
   !-------------------------------------------------------------------------
   SUBROUTINE iosys()
     !-------------------------------------------------------------------------
     !
     USE control_flags, ONLY: fix_dependencies, program_name, lsmd, lneb
     !
     IMPLICIT NONE
     !
     !
     IF ( ionode ) THEN
        !
        WRITE( UNIT = stdout, &
               FMT = "(//,3X,'Main Simulation Parameters (from input)',/ &
                     &   ,3X,'---------------------------------------')" )
        !
     END IF
     !
     ! ... Set internal flags according to the input
     !
     CALL set_control_flags()
     !
     ! ... Write to stdout basic simulation parameters
     !
     CALL input_info()
     !
     ! . CALL the Module specific setup routine
     !
     CALL modules_setup()
     !
     ! ... Initialize SMD variables and path
     !
     IF ( lsmd ) CALL smd_initvar()
     !
     ! ... Fix values for dependencies
     !
     IF ( program_name == 'FPMD' ) CALL fix_dependencies()
     !
     ! ... Write to stdout input module information
     !
     CALL modules_info()
     !
     RETURN
     !
   END SUBROUTINE iosys
   !
   !-------------------------------------------------------------------------
   SUBROUTINE set_control_flags()
     !-------------------------------------------------------------------------
     !
     USE autopilot, ONLY:  auto_check
     USE autopilot, ONLY:  restart_p

     USE control_flags, ONLY : program_name
     USE control_flags, ONLY : ndw_        => ndw, &
                               ndr_        => ndr, &
                               iprint_     => iprint, &
                               isave_      => isave, &
                               tstress_    => tstress, &
                               tprnfor_    => tprnfor, &
                               tprnsfac_   => tprnsfac, &
                               toptical_   => toptical, &
                               ampre_      => ampre, &
                               trane_      => trane, &
                               newnfi_     => newnfi, &
                               tnewnfi_    => tnewnfi, &
                               rhoout_     => rhoout, &
                               tdipole_    => tdipole, &
                               nomore_     => nomore, &
                               memchk_     => memchk, &
                               tpre_       => tpre, &
                               timing_     => timing, &
                               iprsta_     => iprsta, &
                               taurdr_     => taurdr, &
                               nbeg_       => nbeg, &
                               gamma_only_ => gamma_only, &
                               tchi2_      => tchi2, &
                               tatomicwfc_ => tatomicwfc, &
                               printwfc_   => printwfc, &
                               tortho_     => tortho
     USE control_flags, ONLY : t_diis_simple_ => t_diis_simple, &
                               t_diis_        => t_diis, &
                               tsde_          => tsde, &
                               t_diis_rot_    => t_diis_rot, &
                               tconjgrad_     => tconjgrad, &
                               tsteepdesc_    => tsteepdesc, &
                               tzeroe_        => tzeroe, &
                               tdamp_         => tdamp, &
                               trhor_         => trhor, &
                               trhow_         => trhow, &
                               tvlocw_        => tvlocw, &
                               ortho_eps_     => ortho_eps, &
                               ortho_max_     => ortho_max, &
                               tnosee_        => tnosee
     USE control_flags, ONLY : tdampions_ => tdampions, &
                               tfor_      => tfor, &
                               tsdp_      => tsdp, &
                               lfixatom, tconvthrs, tconjgrad_ion
     USE control_flags, ONLY : tnosep_ => tnosep, &
                               tcap_   => tcap, &
                               tcp_    => tcp, &
                               tolp_   => tolp, &
                               tzerop_ => tzerop, &
                               tv0rd_  => tv0rd, &
                               tranp_  => tranp, &
                               amprp_  => amprp
     USE control_flags, ONLY : tionstep_ => tionstep, &
                               nstepe_   => nstepe
     USE control_flags, ONLY : tzeroc_ => tzeroc, &
                               tnoseh_ => tnoseh, &
                               thdyn_  => thdyn, &
                               tsdc_   => tsdc, &
                               tbeg_   => tbeg
     USE control_flags, ONLY : ekin_conv_thr_ => ekin_conv_thr, &
                               etot_conv_thr_ => etot_conv_thr, &
                               forc_conv_thr_ => forc_conv_thr, &
                               ekin_maxiter_  => ekin_maxiter, &
                               etot_maxiter_  => etot_maxiter, &
                               forc_maxiter_  => forc_maxiter
     USE control_flags, ONLY : force_pairing_ => force_pairing
     !
     ! ...  Other modules
     !
     USE wave_base,          ONLY : frice_ => frice
     USE ions_base,          ONLY : fricp_ => fricp
     USE cell_base,          ONLY : frich_ => frich
     USE time_step,          ONLY : set_time_step
     USE cp_electronic_mass, ONLY : emass_ => emass, &
                                    emaec_ => emass_cutoff
     !
     USE input_parameters, ONLY: &
        electron_dynamics, electron_damping, diis_rot, electron_temperature,   &
        ion_dynamics, ekin_conv_thr, etot_conv_thr, forc_conv_thr, ion_maxstep,&
        electron_maxstep, ion_damping, ion_temperature, ion_velocities, tranp, &
        amprp, ion_nstepe, cell_nstepe, cell_dynamics, cell_damping,           &
        cell_parameters, cell_velocities, cell_temperature, force_pairing,     &
        tapos, tavel, ecutwfc, emass, emass_cutoff, taspc, trd_ht, ibrav,      &
        ortho_eps, ortho_max, ntyp, tolp, tchi2_inp, calculation, disk_io, dt, &
        tcg, ndr, ndw, iprint, isave, tstress, k_points, tprnfor, verbosity,   &
        tprnrho, tdipole_card, toptical_card, tnewnfi_card, newnfi_card,       &
        ampre, nstep, restart_mode, ion_positions, startingwfc, printwfc,      &
        orthogonalization, electron_velocities, nat, if_pos
     !
     IMPLICIT NONE
     !
     IF ( .NOT. has_been_read ) &
        CALL errore( 'iosys ', 'input file has not been read yet!', 1 )
     !
     ndr_           = ndr
     ndw_           = ndw
     iprint_        = iprint
     isave_         = isave
     tstress_       = tstress
     tpre_          = tstress
     gamma_only_    = ( TRIM( k_points ) == 'gamma' )
     tprnfor_       = tprnfor
     printwfc_      = printwfc
     tchi2_         = tchi2_inp
     ekin_conv_thr_ = ekin_conv_thr
     etot_conv_thr_ = etot_conv_thr
     forc_conv_thr_ = forc_conv_thr
     ekin_maxiter_  = electron_maxstep
     !
     ! ... Set internal time step variables ( delt, twodelt, dt2 ... )
     !
     CALL set_time_step( dt )
     !
     ! ... Set electronic fictitius mass and its cut-off for fourier
     ! ... acceleration
     !
     emass_ = emass
     emaec_ = emass_cutoff
     !
     ! ... set the level of output, the code verbosity 
     !
     iprsta_ = 1
     timing_ = .FALSE.
          ! The code write to files fort.8 fort.41 fort.42 fort.43
          ! a detailed report of subroutines timing
     rhoout_ = .FALSE.
          ! save charge density to file  CHARGEDENSITY if nspin = 1, and
          ! CHARGEDENSITY.UP CHARGEDENSITY.DOWN if nspin = 2
     memchk_ = .FALSE.
          ! The code performs a memory check, write on standard
          ! output the allocated memory at each step.
          ! Architecture Dependent
     tprnsfac_  = .FALSE.
          ! Print on file STRUCTURE_FACTOR the structure factor
          ! gvectors and charge density, in reciprocal space.
     !
     trhor_  = ( TRIM( calculation ) == 'nscf' )
     trhow_  = ( TRIM( disk_io ) == 'high' )
     tvlocw_ = .FALSE.
     !
     SELECT CASE( TRIM( verbosity ) )
       CASE( 'minimal' )
         !
         iprsta_ = 0
         !
       CASE( 'low', 'default' )
         !
         iprsta_ = 1
         timing_ = .TRUE.
         !
       CASE( 'medium' )
         !
         iprsta_   = 2
         timing_   = .TRUE.
         rhoout_   = .TRUE.
         tprnsfac_ = .TRUE.
         !
       CASE( 'high' )
         !
         iprsta_   = 3
         memchk_   = .TRUE.
         timing_   = .TRUE.
         rhoout_   = .TRUE.
         tprnsfac_ = .TRUE.
         !
       CASE DEFAULT
         !
         CALL errore( 'control_flags ', &
                      'unknown verbosity ' // TRIM( verbosity ), 1 )
         !
     END SELECT
     !
     ! ... If explicitly requested force the charge density to be printed
     !
     IF ( tprnrho ) rhoout_ = .TRUE.
     !
     tdipole_  = tdipole_card
     toptical_ = toptical_card
     newnfi_   = newnfi_card
     tnewnfi_  = tnewnfi_card
     !
     ! ... set the restart flags
     !
     trane_  = .FALSE.
     ampre_  = ampre
     taurdr_ = .FALSE.
     SELECT CASE ( TRIM( restart_mode ) )
       CASE ('from_scratch')
         nbeg_   = -1
         nomore_ = nstep
         trane_  = ( startingwfc == 'random' )
         IF ( ampre_ == 0.d0 ) ampre_ = 0.02
       CASE ('reset_counters')
         nbeg_   =  0
         nomore_ = nstep
       CASE ('restart')
         nbeg_   =  1
         nomore_ = nstep
       CASE ('auto')
          if( auto_check(ndr, ' ') ) then
            write(*,*) 'AuTOPILOT: Auto Check detects restart.xml'
            write(*,*) '      adjusting restart mode to RESTART' 
            restart_mode = 'restart'
            nbeg_ = 1
            ! Also handle NSTEPS adjustment so that
            ! nomore does not include past nfi in cpr.f90
            restart_p = .TRUE.
            nomore_ = nstep
            if ( ion_positions == 'from_input' ) then
               taurdr_ = .TRUE.
               nbeg_ = -1
            end if
         else
            write(*,*) 'AUTOPILOT: Auto Check did not detect restart.xml'
            write(*,*) '     adjusting restart mode to FROM_SCRATCH' 
            restart_mode = 'from_scratch'
            nbeg_ = -2
            if ( ion_positions == 'from_input' ) nbeg_ = -1
            nomore_ = nstep
            trane_  = ( startingwfc == 'random' )
            if ( ampre_ == 0.d0 ) ampre_ = 0.02
         end IF
       CASE DEFAULT
         CALL errore(' iosys ',' unknown restart_mode '//TRIM(restart_mode), 1 )
     END SELECT

     ! ... Starting/Restarting Atomic positions
     !
     SELECT CASE ( TRIM(ion_positions) )
       CASE ( 'from_input' )
         taurdr_ = .TRUE.   ! Positions read from standard input
       CASE ( 'default' )
         taurdr_ = .FALSE.
       CASE DEFAULT
         CALL errore(' control_flags ',' unknown ion_positions '//TRIM(ion_positions), 1 )
     END SELECT

     ! ... Electronic randomization
        
     tatomicwfc_ = .FALSE.
     SELECT CASE ( TRIM(startingwfc) )
       CASE ('default','none')
         trane_ = .FALSE.
       CASE ('random')
         trane_ = .TRUE.
       CASE ('atomic')
         tatomicwfc_ = .TRUE.
       CASE DEFAULT
         CALL errore(' control_flags ',' unknown startingwfc '//TRIM(startingwfc), 1 )
     END SELECT
     IF( ampre_ == 0 ) trane_ = .FALSE.

      ! ...   TORTHO

      SELECT CASE ( orthogonalization )
      CASE ('Gram-Schmidt')
         tortho_ = .FALSE.
      CASE ('ortho')
         tortho_ = .TRUE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown orthogonalization '//&
              TRIM(orthogonalization), 1 )
      END SELECT

      ortho_max_ = ortho_max
      ortho_eps_ = ortho_eps

      ! ... Electrons initial velocity

      SELECT CASE ( TRIM(electron_velocities) )
        CASE ('default')
          tzeroe_ = .FALSE.
        CASE ('zero')
          tzeroe_ = .TRUE.
          IF( program_name == 'CP90' ) &
            WRITE( stdout, &
                   '("Warning: electron_velocities keyword has no effect")' )
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown electron_velocities '//TRIM(electron_velocities), 1 )
      END SELECT

      ! ... Electron dynamics

      tdamp_          = .FALSE.
      tconjgrad_      = .FALSE.
      tsteepdesc_     = .FALSE.
      t_diis_        = .FALSE.
      t_diis_simple_ = .FALSE.
      t_diis_rot_    = .FALSE.
      frice_ = 0.d0
      SELECT CASE ( TRIM(electron_dynamics) )
        CASE ('sd', 'default')
          tsde_ = .TRUE.
        CASE ('verlet')
          tsde_ = .FALSE.
        CASE ('cg')
          tsde_      = .FALSE.
          IF( program_name == 'CP90' ) THEN
             tcg = .TRUE.
          ELSE
             tconjgrad_ = .TRUE.
          ENDIF
        CASE ('damp')
          tsde_   = .FALSE.
          tdamp_  = .TRUE.
          frice_ = electron_damping
        CASE ('diis')
          IF( program_name == 'CP90' ) &
            CALL errore( "iosys ", " electron_dynamics keyword not yet implemented ", 1 )
          tsde_   = .FALSE.
          t_diis_ = .TRUE.
          IF( diis_rot ) THEN
            t_diis_rot_    = .TRUE.
          ELSE
            t_diis_simple_ = .TRUE.
          END IF
        CASE ('none')
          tsde_ = .FALSE.
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown electron_dynamics '//TRIM(electron_dynamics), 1 )
      END SELECT

      ! ... Electronic Temperature

      tnosee_ = .FALSE.
      SELECT CASE ( TRIM(electron_temperature) )
        !         temperature control of electrons via Nose' thermostat
        CASE ('nose')
          tnosee_ = .TRUE.
        CASE ('not_controlled', 'default')
          tnosee_ = .FALSE.
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown electron_temperature '//TRIM(electron_temperature), 1 )
      END SELECT

      ! ... Ions dynamics

      tdampions_       = .FALSE.
      tconvthrs%active = .FALSE.
      tconvthrs%nstep  = 1
      tconvthrs%ekin   = 0.0d0
      tconvthrs%derho  = 0.0d0
      tconvthrs%force  = 0.0d0
      tconjgrad_ion%active = .FALSE.
      tconjgrad_ion%nstepix = 1
      tconjgrad_ion%nstepex = 1
      tconjgrad_ion%ionthr = 1.0d+10
      tconjgrad_ion%elethr = 1.0d+10
      SELECT CASE ( TRIM(ion_dynamics) )
        CASE ('sd')
          tsdp_  = .TRUE.
          tfor_  = .TRUE.
          fricp_ = 0.d0
          tconvthrs%ekin   = ekin_conv_thr
          tconvthrs%derho  = etot_conv_thr
          tconvthrs%force  = forc_conv_thr
          tconvthrs%active = .TRUE.
          tconvthrs%nstep  = 1
        CASE ('verlet')
          tsdp_  = .FALSE.
          tfor_  = .TRUE.
          fricp_ = 0.d0
        CASE ('cg')       ! Conjugate Gradient minimization for ions
          tsdp_ = .FALSE.
          tfor_ = .TRUE.
          tconjgrad_ion%active  = .TRUE.
          tconjgrad_ion%nstepix = ion_maxstep    ! maximum number of iteration
          tconjgrad_ion%nstepex = electron_maxstep  ! maximum number of iteration for the electronic minimization
          tconjgrad_ion%ionthr  = etot_conv_thr ! energy threshold for convergence
          tconjgrad_ion%elethr  = ekin_conv_thr ! energy threshold for convergence in the electrons minimization
          tconvthrs%ekin   = ekin_conv_thr
          tconvthrs%derho  = etot_conv_thr
          tconvthrs%force  = forc_conv_thr
          tconvthrs%active = .TRUE.
          tconvthrs%nstep  = 1
          IF( program_name == 'CP90' ) &
            CALL errore( "iosys ", " ion_dynamics = '//TRIM(ion_dynamics)//' not yet implemented ", 1 )
        CASE ('damp')
          tsdp_      = .FALSE.
          tfor_      = .TRUE.
          tdampions_ = .TRUE.
          fricp_     = ion_damping
          tconvthrs%ekin   = ekin_conv_thr
          tconvthrs%derho  = etot_conv_thr
          tconvthrs%force  = forc_conv_thr
          tconvthrs%active = .TRUE.
          tconvthrs%nstep  = 1
        CASE ('none', 'default')
          tsdp_  = .FALSE.
          tfor_  = .FALSE.
          fricp_ = 0.d0
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown ion_dynamics '//TRIM(ion_dynamics), 1 )
      END SELECT

      IF ( ANY( if_pos(:,1:nat) == 0 ) ) lfixatom = .TRUE.

      ! ... Ionic Temperature

      tcp_      = .FALSE.
      tnosep_   = .FALSE.
      tolp_     = tolp
      SELECT CASE ( TRIM(ion_temperature) )
        !         temperature control of ions via Nose' thermostat
        CASE ('nose')
          tnosep_ = .TRUE.
          tcp_ = .FALSE.
        CASE ('not_controlled', 'default')
          tnosep_ = .FALSE.
          tcp_ = .FALSE.
        CASE ('rescaling' )
          tnosep_ = .FALSE.
          tcp_ = .TRUE.
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown ion_temperature '//TRIM(ion_temperature), 1 )
      END SELECT

      ! ... Starting/Restarting ionic velocities

      tcap_         = .FALSE.
      SELECT CASE ( TRIM(ion_velocities) )
        CASE ('default')
          tzerop_ = .FALSE.
          tv0rd_ = .FALSE.
          tcap_ = .FALSE.
        CASE ('zero')
          tzerop_ = .TRUE.
          tv0rd_ = .FALSE.
        CASE ('from_input')
          tzerop_ = .TRUE.
          tv0rd_  = .TRUE.
        CASE ('random')
          tcap_ = .TRUE.
          IF( program_name == 'FPMD' ) &
            WRITE(stdout) " ion_velocities = '//TRIM(ion_velocities)//' has no effects "
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown ion_velocities '//TRIM(ion_velocities), 1 )
      END SELECT

      ! ... Ionic randomization

      tranp_ ( 1 : ntyp ) =  tranp ( 1 : ntyp )
      amprp_ ( 1 : ntyp ) =  amprp ( 1 : ntyp )

      ! ... Ionic/electronic step ratio

      tionstep_ = .FALSE.
      nstepe_   = 1
      IF( ( ion_nstepe > 1 ) .OR. ( cell_nstepe > 1 ) ) THEN
        !         This card is used to control the ionic step, when active ionic step are
        !         allowed only when the two criteria are met, i.e. the ions are allowed
        !         to move if MOD( NFI, NSTEP ) == 0 and EKIN < EKIN_THR .
        tionstep_ = .TRUE.
        nstepe_   = MAX( ion_nstepe, cell_nstepe )
        IF( program_name == 'CP90' ) &
            WRITE(stdout) " ion_nstepe or cell_nstepe have no effects "
      END IF

      !   Cell dynamics
         
      SELECT CASE ( TRIM(cell_dynamics) )
        CASE ('sd')
          tpre_ = .TRUE.
          thdyn_ = .TRUE.
          tsdc_ = .TRUE.
          frich_= 0.d0
        CASE ( 'damp', 'damp-pr' )
          thdyn_ = .TRUE.
          tsdc_ = .FALSE.
          frich_ = cell_damping
          tpre_  = .TRUE.
        CASE ('pr')
          thdyn_ = .TRUE.
          tsdc_ = .FALSE.
          tpre_ = .TRUE.
          frich_= 0.d0
        CASE ('none', 'default')
          thdyn_ = .FALSE.
          tsdc_ = .FALSE.
          frich_= 0.d0
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown cell_dynamics '//TRIM(cell_dynamics), 1 )
      END SELECT

      ! ... Starting/Restarting Cell parameters

      SELECT CASE ( TRIM(cell_parameters) )
        CASE ('default')
          tbeg_ = .FALSE.
        CASE ('from_input')
          tbeg_ = .TRUE.
          IF( program_name == 'CP90' .AND. force_pairing_) &
            WRITE(stdout) " cell_parameters have no effects "
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown cell_parameters '//TRIM(cell_parameters), 1 )
      END SELECT

      ! ... Cell initial velocities

      SELECT CASE ( TRIM(cell_velocities) )
        CASE ('default')
          tzeroc_ = .FALSE.
        CASE ('zero')
          tzeroc_ = .TRUE.
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown cell_velocities '//TRIM(cell_velocities), 1 )
      END SELECT

      ! ... Cell Temperature

      SELECT CASE ( TRIM(cell_temperature) )
!         cell temperature control of ions via Nose' thermostat
        CASE ('nose')
          tnoseh_ = .TRUE.
        CASE ('not_controlled', 'default')
          tnoseh_ = .FALSE.
        CASE DEFAULT
          CALL errore(' control_flags ',' unknown cell_temperature '//TRIM(cell_temperature), 1 )
      END SELECT

      ! .. If only electron are allowed to move 
      ! .. check for SCF convergence on the ground state
     
      IF( ion_dynamics == 'none' .AND. cell_dynamics == 'none' ) THEN
        tconvthrs%ekin   = ekin_conv_thr
        tconvthrs%derho  = etot_conv_thr
        tconvthrs%force  = 1.D+10
        tconvthrs%active = .TRUE.
        tconvthrs%nstep  = 1
      END IF

      ! force pairing

      force_pairing_ = force_pairing
      IF( program_name == 'CP90' .AND. force_pairing_) &
            WRITE(stdout) " force_pairing have no effects "

      ! . Set internal flags according to the input .......................!

      ! ... the 'ATOMIC_SPECIES' card must be present, check it

      IF( .NOT. taspc ) &
        CALL errore(' iosys ',' ATOMIC_SPECIES not found in stdin ',1)

      ! ... the 'ATOMIC_POSITIONS' card must be present, check it

      IF( .NOT. tapos ) &
        CALL errore(' iosys ',' ATOMIC_POSITIONS not found in stdin ',1)

      IF( .NOT. trd_ht .AND. TRIM(cell_parameters)=='from_input' ) &
        CALL errore(' iosys ',' CELL_PARAMETERS not present in stdin ', 1 )

      IF( .NOT. trd_ht .AND. ibrav == 0 ) &
        CALL errore(' iosys ',' ibrav = 0 but CELL_PARAMETERS not present in stdin ', 1 )

      IF( .NOT. tavel .AND. TRIM(ion_velocities)=='from_input' ) &
        CALL errore(' iosys ',' ION_VELOCITIES not present in stdin ', 1 )

      IF( TRIM(electron_dynamics) /= 'diis' .AND. TRIM(orthogonalization) /= 'ortho' ) THEN
        IF( emass_cutoff < ecutwfc ) &
          CALL errore(' IOSYS ', ' FOURIER ACCELERATION WITHOUT ORTHO',0)
      END IF

      IF( ( TRIM( calculation ) == 'smd' ) .AND. ( TRIM( cell_dynamics ) /= 'none' ) ) THEN
        CALL errore(' smiosys ',' cell_dynamics not implemented : '//TRIM(cell_dynamics), 1 )
      END IF

      RETURN
   END SUBROUTINE set_control_flags
   !
   !-------------------------------------------------------------------------
   SUBROUTINE modules_setup()
     !-------------------------------------------------------------------------
     !
     USE control_flags,    ONLY : program_name, lconstrain, lneb
     USE constants,        ONLY : UMA_AU, pi
     !
     USE input_parameters, ONLY: max_seconds, ibrav , celldm , trd_ht, dt,    &
           cell_symmetry, rd_ht, a, b, c, cosab, cosac, cosbc, ntyp , nat ,   &
           na_inp , sp_pos , rd_pos , rd_vel, atom_mass, atom_label, if_pos,  &
           atomic_positions, id_loc, sic, sic_epsilon, sic_rloc, ecutwfc,     &
           ecutrho, ecfixed, qcutz, q2sigma, tk_inp, wmass,                   &
           ion_radius, emass, emass_cutoff, temph, fnoseh, nr1b, nr2b, nr3b,  &
           tempw, fnosep, nr1, nr2, nr3, nr1s, nr2s, nr3s, ekincw, fnosee,    &
           tturbo_inp, nturbo_inp, outdir, prefix, woptical,                  &
           noptical, boptical, k_points, nkstot, nk1, nk2, nk3, k1, k2, k3,   &
           xk, wk, occupations, n_inner, fermi_energy, rotmass, occmass,      &
           rotation_damping, occupation_damping, occupation_dynamics,         &
           rotation_dynamics, degauss, smearing, nhpcl, nhptyp, ndega,        &
           cell_units, restart_mode

     USE input_parameters, ONLY: diis_achmix, diis_ethr, diis_wthr, diis_delt, &
           diis_nreset, diis_temp, diis_nrot, diis_maxstep, diis_fthr,         &
           diis_size, diis_hcut, diis_rothr, diis_chguess, diis_g0chmix,       &
           diis_nchmix, diis_g1chmix, empty_states_maxstep, empty_states_delt, &
           empty_states_emass, empty_states_ethr, empty_states_nbnd,           &
           tprnks_empty, vhrmax_inp, vhnr_inp, vhiunit_inp, vhrmin_inp,        &
           tvhmean_inp, vhasse_inp, constr_target, constr_target_set,          &
           constr_inp, nconstr_inp, constr_tol_inp, constr_type_inp, iesr_inp, &
           etot_conv_thr, ekin_conv_thr, nspin, f_inp, nelup, neldw, nbnd,     &
           nelec, tprnks, ks_path, press, cell_damping, cell_dofree, tf_inp,   &
           refg, greash, grease, greasp, epol, efield, tcg, maxiter, etresh,   &
           passop
     !
     USE input_parameters, ONLY : nconstr_inp
     USE input_parameters, ONLY : wf_efield, wf_switch, sw_len, efx0, efy0,    &
                                  efz0, efx1, efy1, efz1, wfsd, wfdt, maxwfdt, &
                                  wf_q, wf_friction, nit, nsd, nsteps, tolw,   &
                                  adapt, calwf, nwf, wffort, writev,           &
                                  wannier_index
     !
     USE check_stop,       ONLY : check_stop_init
     USE ions_base,        ONLY : tau, ityp, zv
     USE cell_base,        ONLY : cell_base_init, a1, a2, a3, cell_alat
     USE cell_nose,        ONLY : cell_nose_init
     USE ions_base,        ONLY : ions_base_init, greasp_ => greasp
     USE sic_module,       ONLY : sic_initval
     USE ions_nose,        ONLY : ions_nose_init
     USE wave_base,        ONLY : grease_ => grease
     USE electrons_nose,   ONLY : electrons_nose_init
     USE printout_base,    ONLY : printout_base_init
     USE turbo,            ONLY : turbo_init
     USE efield_module,    ONLY : efield_init
     USE cg_module,        ONLY : cg_init
     !
     USE reciprocal_space_mesh,    ONLY: recvecs_units
     USE smallbox_grid_dimensions, ONLY: &
           nnrbx, &  !  variable is used to workaround internal compiler error (IBM xlf)
           nr1b_ => nr1b, &
           nr2b_ => nr2b, &
           nr3b_ => nr3b
     USE grid_dimensions,          ONLY: &
           nnrx, &  !  variable is used to workaround internal compiler error (IBM xlf)
           nr1_ => nr1, &
           nr2_ => nr2, &
           nr3_ => nr3
     USE smooth_grid_dimensions,   ONLY: &
           nnrsx, &  !  variable is used to workaround internal compiler error (IBM xlf)
           nr1s_ => nr1s, &
           nr2s_ => nr2s, &
           nr3s_ => nr3s
     USE brillouin,                ONLY : kpoint_setup
     USE optical_properties,       ONLY : optical_setup
     USE guess,                    ONLY : guess_setup
     USE empty_states,             ONLY : empty_init
     USE diis,                     ONLY : diis_setup
     USE charge_mix,               ONLY : charge_mix_setup
     USE potentials,               ONLY : potential_init
     USE kohn_sham_states,         ONLY : ks_states_init
     USE electrons_module,         ONLY : electrons_setup
     USE electrons_base,           ONLY : electrons_base_initval
     USE ensemble_dft,             ONLY : ensemble_initval
     USE wannier_base,             ONLY : wannier_init
     USE constraints_module,       ONLY : init_constraint
     USE basic_algebra_routines,   ONLY : norm
     !
     !
     IMPLICIT NONE
     !
     REAL(DP) :: alat_ , massa_totale
     REAL(DP) :: delt_emp_inp, emass_emp_inp, ethr_emp_inp
     ! ...   DIIS
     REAL(DP) :: tol_diis_inp, delt_diis_inp, tolene_inp
     LOGICAL :: o_diis_inp, oqnr_diis_inp
     INTEGER :: ia
     LOGICAL :: ltest
     !
     !   Subroutine Body
     !
     IF( .NOT. has_been_read ) &
       CALL errore( ' modules_setup ', ' input file has not been read yet! ', 1 )
     !
     !
     CALL check_stop_init( max_seconds )

     ! ...  Set cell base module

     massa_totale = SUM( atom_mass(1:ntyp)*na_inp(1:ntyp) )
     !
     CALL cell_base_init( ibrav , celldm , trd_ht, cell_symmetry, rd_ht, &
                          cell_units, a, b, c, cosab, cosac, cosbc , wmass, &
                          massa_totale, press, cell_damping, greash, &
                          cell_dofree )
     !
     alat_ = cell_alat()

     ! ...  Set ions base module

     CALL ions_base_init( ntyp , nat , na_inp , sp_pos , rd_pos , rd_vel,  &
                          atom_mass, atom_label, if_pos, atomic_positions, &
                          alat_ , a1, a2, a3, ion_radius )


     ! ...   Set units for Reciprocal vectors ( 2PI/alat by convention )

     CALL recvecs_units( alat_ )

     ! ...   Set Values for the cutoff

     CALL ecutoffs_setup( ecutwfc, ecutrho, ecfixed, qcutz, q2sigma, refg )

     CALL gcutoffs_setup( alat_ , tk_inp, nkstot, xk )

     ! ... 
     
     grease_ = grease
     greasp_ = greasp
     !
     ! ... set thermostat parameter for cell, ions and electrons
     !
     CALL cell_nose_init( temph, fnoseh )
     !
     CALL ions_nose_init( tempw, fnosep, nhpcl, nhptyp, ndega )
     !
     CALL electrons_nose_init( ekincw , fnosee )

     ! set box grid module variables

     nr1b_ = nr1b  
     nr2b_ = nr2b
     nr3b_ = nr3b

     ! set size for potentials and charge density
     ! (re-calculated automatically)

     nr1_  = nr1
     nr2_  = nr2
     nr3_  = nr3

     ! set size for wavefunctions
     ! (re-calculated automatically)

     nr1s_ = nr1s
     nr2s_ = nr2s
     nr3s_ = nr3s

     CALL turbo_init( tturbo_inp, nturbo_inp )

     IF ( .NOT. lneb ) &
        CALL printout_base_init( outdir, prefix )

     IF ( noptical > 0 ) &
        CALL optical_setup( woptical, noptical, boptical )

     CALL kpoint_setup( k_points, nkstot, nk1, nk2, nk3, k1, k2, k3, xk, wk )

     CALL efield_init( epol, efield )

     CALL cg_init( tcg , maxiter , etresh , passop )
     !
     CALL sic_initval( nat, id_loc, sic, sic_epsilon, sic_rloc  )

     !
     !  empty states
     !
     delt_emp_inp  = dt
     ethr_emp_inp  = ekin_conv_thr
     IF( empty_states_delt > 0.d0 )  delt_emp_inp  = empty_states_delt
     IF( empty_states_ethr > 0.d0 )  ethr_emp_inp  = empty_states_ethr
     CALL empty_init( empty_states_maxstep, delt_emp_inp, ethr_emp_inp )

     !
     CALL potential_init( tvhmean_inp,vhnr_inp, vhiunit_inp, &
                          vhrmin_inp, vhrmax_inp, vhasse_inp, iesr_inp )

     CALL ks_states_init( nspin, tprnks, tprnks_empty )

     CALL electrons_base_initval( zv, na_inp, ntyp, nelec, nelup, &
                                  neldw, nbnd, nspin, occupations, f_inp )

     CALL electrons_setup( empty_states_nbnd, emass, emass_cutoff, nkstot )

     CALL ensemble_initval( occupations, n_inner, fermi_energy, rotmass, &
                            occmass, rotation_damping, occupation_damping, &
                            occupation_dynamics, rotation_dynamics, degauss, &
                            smearing )
     !
     ! ... variables for constrained dynamics are set here
     !
     lconstrain = ( nconstr_inp > 0 )
     !
     IF ( lconstrain ) CALL init_constraint( nat, tau, 1.D0, ityp )
     !
     IF( program_name == 'FPMD' ) THEN
        !
        o_diis_inp        = .TRUE.
        oqnr_diis_inp     = .TRUE.
        tolene_inp        = etot_conv_thr
        tol_diis_inp      = ekin_conv_thr
        delt_diis_inp     = dt
        IF( diis_ethr > 0.0d0 ) tolene_inp    = diis_ethr
        IF( diis_wthr > 0.0d0 ) tol_diis_inp  = diis_wthr
        IF( diis_delt > 0.0d0 ) delt_diis_inp = diis_delt
        CALL diis_setup( diis_fthr, oqnr_diis_inp, o_diis_inp, &
          diis_size, diis_hcut, tol_diis_inp, diis_maxstep, diis_nreset, delt_diis_inp, &
          diis_temp, diis_nrot(1), diis_nrot(2), diis_nrot(3), &
          diis_rothr(1), diis_rothr(2), diis_rothr(3), tolene_inp)
        CALL guess_setup( diis_chguess )
        CALL charge_mix_setup(diis_achmix, diis_g0chmix, diis_nchmix, diis_g1chmix)
        !
     END IF
     !
     CALL wannier_init( wf_efield, wf_switch, sw_len, efx0, efy0, efz0, &
                        efx1, efy1, efz1, wfsd, wfdt, maxwfdt, wf_q,    &
                        wf_friction, nit, nsd, nsteps, tolw, adapt,     &
                        calwf, nwf, wffort, writev, wannier_index,      &
                        restart_mode )
     !
     RETURN
     !
  END SUBROUTINE modules_setup
  !
  !-------------------------------------------------------------------------
  SUBROUTINE smd_initvar()
    !-------------------------------------------------------------------------
    !
    ! ... this subroutine copies SMD variables from input 
    ! ... module to path_variables
    !
      USE input_parameters, ONLY: calculation, &
           smd_polm, smd_kwnp, smd_linr, smd_stcd, smd_stcd1, smd_stcd2, smd_stcd3, smd_codf, &
           smd_forf, smd_smwf, smd_lmfreq, smd_tol, smd_maxlm, smd_smcp, smd_smopt, smd_smlm, &
           num_of_images, smd_ene_ini, smd_ene_fin

      USE path_variables, ONLY: &
           sm_p_ => smd_p, &
           smcp_ => smd_cp, &
           smlm_ => smd_lm, &
           smopt_ => smd_opt, &
           linr_ => smd_linr, &
           polm_ => smd_polm, &
           kwnp_ => smd_kwnp, &
           codfreq_ => smd_codfreq, &
           forfreq_ => smd_forfreq, &
           smwfreq_ => smd_wfreq, &
           tol_ => smd_tol, &
           lmfreq_ => smd_lmfreq, &
           maxlm_ => smd_maxlm, &
           ene_ini_ => smd_ene_ini, &
           ene_fin_ => smd_ene_fin

      USE ions_base,      ONLY: nat, nsp, tions_base_init
      USE control_flags,  ONLY: nbeg
      USE cell_base,      ONLY: cell_alat
      !
      IMPLICIT NONE
      !
      REAL(DP) :: alat_
      !
      IF( .NOT. tions_base_init ) &
        CALL errore( " smd_initvar ", " ions_base_init should be called first ", 1 )
      !
      alat_ = cell_alat()
      !
      ! ... SM_P  
      !
      sm_p_ = num_of_images -1
      !
      ! ... what to do
      !
      smcp_   = smd_smcp
      smopt_  = smd_smopt
      smlm_   = smd_smlm
      !      
      ! ... initial path info
      !
      linr_ = smd_linr
      polm_ = smd_polm
      kwnp_ = smd_kwnp
      !
      ! ...  Frequencey of wiriting
      !
      codfreq_ = smd_codf
      forfreq_ = smd_forf
      smwfreq_ = smd_smwf
      !
      ! ... Lagrange multiplier info.
      !
      lmfreq_ = smd_lmfreq
      tol_    = smd_tol
      maxlm_  = smd_maxlm
      !
      ! ... if smlm
      !
      IF( smd_smlm .AND. ( smd_ene_ini >= 0.d0 .OR. smd_ene_fin >= 0.d0 ) ) THEN
         CALL errore(' start : ',' Check : ene_ini & ene_fin ', 1 )
      END IF
      !
      ene_ini_ = smd_ene_ini
      ene_fin_ = smd_ene_fin
      !
      !
      IF( TRIM( calculation ) == 'smd' ) THEN
         !
         ! How to obtain the initial trial path.
         !
         IF(smd_smopt) THEN
   
          CALL init_path(sm_p_,kwnp_,smd_stcd,nsp,nat,alat_,nbeg,1)

         ELSEIF(smd_linr) THEN

          CALL init_path(sm_p_,kwnp_,smd_stcd,nsp,nat,alat_,nbeg,2)

         ELSEIF(smd_polm .AND. (smd_kwnp < num_of_images) ) THEN

          CALL init_path(sm_p_,kwnp_,smd_stcd,nsp,nat,alat_,nbeg,3)

         ELSEIF(smd_kwnp == num_of_images ) THEN

          CALL init_path(sm_p_,kwnp_,smd_stcd,nsp,nat,alat_,nbeg,4)

         ENDIF

      END IF
      !
      RETURN
  END SUBROUTINE smd_initvar
  !
  !     --------------------------------------------------------
  !
  !     print out heading
  !
  SUBROUTINE input_info()

    ! this subroutine print to standard output some parameters read from input
    ! ----------------------------------------------

    USE input_parameters,   ONLY: restart_mode
    USE control_flags,      ONLY: nbeg, iprint, ndr, ndw, nomore
    USE time_step,          ONLY: delt
    USE cp_electronic_mass, ONLY: emass, emass_cutoff

    IMPLICIT NONE

    IF( .NOT. has_been_read ) &
      CALL errore( ' iosys ', ' input file has not been read yet! ', 1 )

    IF( ionode ) THEN
      WRITE( stdout, 500) nbeg, restart_mode, nomore, iprint, ndr, ndw
      WRITE( stdout, 505) delt
      WRITE( stdout, 510) emass
      WRITE( stdout, 511) emass_cutoff
    END IF

500 FORMAT(   3X,'Restart Mode       = ',I7, 3X, A15, /, &
              3X,'Number of MD Steps = ',I7,  /, &
              3X,'Print out every      ',I7, ' MD Steps',/  &
              3X,'Reads from unit    = ',I7,  /, &
              3X,'Writes to unit     = ',I7)
505 FORMAT(   3X,'MD Simulation time step            = ',F10.2)
510 FORMAT(   3X,'Electronic fictitious mass (emass) = ',F10.2)
511 FORMAT(   3X,'emass cut-off                      = ',F10.2)
509 FORMAT(   3X,'Verlet algorithm for electron dynamics')
502 FORMAT(   3X,'An initial quench is performed')

    RETURN
  END SUBROUTINE input_info
  !
  ! ----------------------------------------------------------------
  !
  SUBROUTINE modules_info()

    USE input_parameters, ONLY: electron_dynamics, electron_temperature, &
      orthogonalization

    USE control_flags, ONLY:  program_name, tortho, tnosee, trane, ampre, &
                              trhor, trhow, tvlocw, tfor, tnosep, iprsta, &
                              thdyn, tnoseh
    !
    USE electrons_nose,       ONLY: electrons_nose_info
    USE empty_states,         ONLY: empty_print_info
    USE diis,                 ONLY: diis_print_info
    USE potentials,           ONLY: potential_print_info
    USE brillouin,            ONLY: kpoint_info
    USE runcg_module,         ONLY: runcg_info
    USE sic_module,           ONLY: sic_info
    USE wave_base,            ONLY: frice, grease
    USE ions_base,            ONLY: fricp
    USE ions_nose,            ONLY: ions_nose_info
    USE cell_nose,            ONLY: cell_nose_info
    USE cell_base,            ONLY: frich
      !
    IMPLICIT NONE

    INTEGER :: is

    IF( .NOT. has_been_read ) &
      CALL errore( ' iosys ', ' input file has not been read yet! ', 1 )

    IF( ionode ) THEN
      !
      CALL cutoffs_print_info( )
      !
      IF( tortho ) THEN
        CALL orthogonalize_info( )
      ELSE
        WRITE( stdout,512)
      END IF
      !
      IF(      TRIM(electron_dynamics) == 'diis' ) THEN
          CALL diis_print_info( stdout )
      ELSE IF( TRIM(electron_dynamics) == 'cg'  ) THEN
          CALL runcg_info( stdout )
      ELSE IF( TRIM(electron_dynamics) == 'sd' ) THEN
          WRITE( stdout,513)
      ELSE IF( TRIM(electron_dynamics) == 'verlet' ) THEN
          WRITE( stdout,510)
          frice = 0.
      ELSE IF( TRIM(electron_dynamics) == 'damp' ) THEN
          tnosee = .FALSE.
          WRITE( stdout,509)
          WRITE( stdout,514) frice, grease
      ELSE
          CALL errore(' input_info ', ' unknown electron dynamics ', 1 )
      END IF
      !
      IF( tnosee ) THEN
        WRITE( stdout,590)
        CALL electrons_nose_info()
      ELSE 
        WRITE( stdout,535)
      END IF
      !
      IF( trane ) THEN
         WRITE( stdout,515) ampre
      ENDIF
      !
      CALL electrons_print_info( )
      !
      CALL exch_corr_print_info( )

      IF ( trhor ) THEN
         WRITE( stdout,720)
      ENDIF
      IF( .NOT. trhor .AND. trhow )THEN
         WRITE( stdout,721)
      ENDIF
      IF( tvlocw )THEN
         WRITE( stdout,722)
      ENDIF
      !
      IF( program_name == 'FPMD' ) THEN
        CALL empty_print_info( stdout )
        CALL kpoint_info( stdout )
      END IF
      !
      IF( tfor .AND. tnosep ) fricp = 0.0d0
      !
      CALL ions_print_info( )
      !
      IF( tfor .AND. tnosep ) CALL ions_nose_info()
      !
      IF( thdyn .AND. tnoseh ) frich = 0.0d0
      !
      CALL cell_print_info( )
      !
      IF( thdyn .AND. tnoseh ) CALL cell_nose_info()
      !
      IF( program_name == 'FPMD' ) THEN
        CALL potential_print_info( stdout )
        CALL sic_info( )
      END IF
      !
      WRITE( stdout,700) iprsta

    END IF


    RETURN

 509  FORMAT(   3X,'verlet algorithm for electron dynamics')
 510  FORMAT(   3X,'Electron dynamics with newton equations')
 512  FORMAT(   3X,'Orthog. with Gram-Schmidt')
 513  FORMAT(   3X,'Electron dynamics with steepest descent')
 514  FORMAT(   3X,'with friction frice = ',f7.4,' , grease = ',f7.4)
 515  FORMAT(   3X,'initial random displacement of el. coordinates with ',   &
     &       ' amplitude=',f10.6)
 535   FORMAT(   3X,'Electron dynamics : the temperature is not controlled')
 540   FORMAT(   3X,'Electron dynamics with rescaling of velocities :',/ &
               ,3X,'Average kinetic energy required = ',F11.6,'(A.U.)' &
                  ,'Tolerance = ',F11.6)
 545   FORMAT(   3X,'Electron dynamics with canonical temp. control : ',/ &
               ,3X,'Average kinetic energy required = ',F11.6,'(A.U.)' &
                  ,'Tolerance = ',F11.6)
 550  FORMAT(' ion dynamics: the temperature is not controlled'//)
 555  FORMAT(' ion dynamics with rescaling of velocities:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 560  FORMAT(' ion dynamics with canonical temp. control:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 562  FORMAT(' ion dynamics with nose` temp. control:'/                 &
     &       ' temperature required=',f10.5,'(kelvin)',' nose` mass = ',&
     &       f10.3//)
563  FORMAT(' ion dynamics with nose` temp. control:'/                 &
     &       ' temperature required=',f10.5,'(kelvin)'/                 &
     &       ' NH chain length= ',i3,' active degrees of freedom=',i3,/ &
     &       ' nose` mass(es) =',20(1X,f10.3)//)
 566  FORMAT(' electronic dynamics with nose` temp. control:'/          &
     &       ' elec. kin. en. required=',f10.5,'(hartree)',             &
     &       ' nose` mass = ',f10.3//)
 580   FORMAT(   3X,'Nstepe = ',I3  &
                  ,' purely electronic steepest descent steps',/ &
               ,3X,'are performed for every ionic step in the program')
 590   FORMAT(   3X,'Electron temperature control via nose thermostat')
    !

 700  FORMAT( /,3X, 'Verbosity: iprsta = ',i2,/)
 720  FORMAT( 3X, 'charge density is read from unit 47')
 721  FORMAT( 3X, 'charge density is written in unit 47')
 722  FORMAT( 3X, 'local potential is written in unit 46')

  END SUBROUTINE modules_info
  !
END MODULE input
