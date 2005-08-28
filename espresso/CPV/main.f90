!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!  AB INITIO COSTANT PRESSURE MOLECULAR DYNAMICS
!  ----------------------------------------------

!=----------------------------------------------------------------------------=!
  MODULE main_module
!=----------------------------------------------------------------------------=!
 
    IMPLICIT NONE
    SAVE

    PRIVATE

    PUBLIC :: cpmain

!=----------------------------------------------------------------------------=!
  CONTAINS
!=----------------------------------------------------------------------------=!

!  ----------------------------------------------
!  BEGIN manual

    SUBROUTINE cpmain( tau, fion, etot )

!  this routine does some initialization, then handles for the main loop
!  for Car-Parrinello dynamics
!  ----------------------------------------------
!  this version features:
!  Parrinello-Rahman dynamics
!  generic k-points calculation
!  Nose' thermostat for ions and electrons
!  velocity rescaling for ions
!  Kleinman-Bylander fully non-local pseudopotentials
!  support for local and s, p and d nonlocality
!  generalized gradient corrections
!  core corrections
!  calculus of polarizability
!  DIIS minimization for electrons
!  ions dynamics with DIIS electronic minimization at each step
!  --------------------------------------------
!
!  input units
!  NDR > 50: system configuration at start (not used if nbeg.LT.0)
!            (generated by a previous run, see NDW below)
!  5       : standard input (may be redirected, see start.F)
!  10      : pseudopotential data (must exist for the program to run)
!
!  output units
!  NDW > 50: system configuration (may be used to restart the program,
!            see NDR above)
!  6       : standard output (may be redirected, see start.F)
!  17      : charge density ( file name CHARGE_DENSITY )
!  18      : Kohn Sham states ( file name KS... )
!  19      : file EMPTY_STATES.WF
!  20      : file STRUCTUR_FACTOR
!  28      : loops timing
!  29      : atomic velocities
!  30      : conductivity
!  31      : eigenvalues
!  32      : polarization
!  33      : energies + pressure + volume + msd
!  34      : energies
!  35      : atomic trajectories
!  36      : cell trajectories
!  37      : atomic forces
!  38      : internal stress tensor
!  39      : thermostats energies
!  40      : thermal stress tensor
!  41      : stress timing
!  42      : ortho timing
!  43      : vofrho timing
!  ----------------------------------------------
!  END manual

! ... declare modules
      USE kinds
      USE phase_factors_module, ONLY : strucf, phfacs
      USE restart_file, ONLY : writefile, readfile
      USE parameters, ONLY: nacx, nspinx
      USE runcp_module, ONLY: runcp, runcp_force_pairing
      USE runcg_module, ONLY: runcg
      USE runcg_ion_module, ONLY: runcg_ion
      USE control_flags, ONLY: tbeg, nomore, &
                  nbeg, newnfi, tnewnfi, isave, iprint, tv0rd, nv0rd, tzeroc, tzerop, &
                  tfor, thdyn, tzeroe, tsde, tsdp, tsdc, taurdr, ndr, &
                  ndw, tortho, tstress, timing, memchk, iprsta, &
                  tconjgrad, tprnsfac, toptical, tcarpar, &
                  rhoout, tdipole, t_diis, t_diis_simple, t_diis_rot, &
                  tnosee, tnosep, force_pairing, tconvthrs, convergence_criteria, tionstep, nstepe, &
                  tsteepdesc, ekin_conv_thr, ekin_maxiter, ionic_conjugate_gradient, &
                  tconjgrad_ion, conv_elec, lneb, tnoseh, tuspp, etot_conv_thr
      USE atoms_type_module, ONLY: atoms_type
      USE print_out_module, ONLY: printout, print_time, print_sfac, &
          printacc
      USE cell_module, ONLY: movecell, press, boxdimensions, updatecell
      USE empty_states, ONLY: empty
      USE polarization, ONLY: ddipole
      USE energies, ONLY: dft_energy_type, debug_energies
      USE turbo, ONLY: tturbo
      USE pseudopotential
      USE potentials, ONLY: vofrhos, localisation
      USE ions_module, ONLY: moveions, max_ion_forces, update_ions, resort_position
      USE fft, ONLY : fft_closeup
      USE electrons_module, ONLY: ei, nspin, n_emp
      USE diis, ONLY: allocate_diis
      USE charge_density, ONLY: rhoofr, printrho
      USE fft_base, ONLY: dfftp, dffts
      USE check_stop, ONLY: check_stop_now
      USE nl, ONLY: nlrh_m
      USE time_step, ONLY: tps, delt
      USE brillouin, ONLY: kp
      USE rundiis_module, ONLY: rundiis, runsdiis
      USE wave_types
      USE charge_types
      USE kohn_sham_states, ONLY: ks_states, tksout, n_ksout, indx_ksout, ks_states_closeup
      USE kohn_sham_states, ONLY: ks_states_force_pairing
      USE io_global, ONLY: ionode
      USE io_global, ONLY: stdout
      USE optical_properties, ONLY: opticalp, optical_closeup
      USE wave_functions, ONLY: update_wave_functions
      USE mp_buffers, ONLY: mp_report_buffers
      USE mp, ONLY: mp_report, mp_sum, mp_max
      USE runsd_module, ONLY: runsd
      USE guess, ONLY: guess_closeup
      USE input, ONLY: iosys
      USE cell_base, ONLY: alat, a1, a2, a3, cell_kinene, velh
      USE cell_base, ONLY: frich, greash
      USE stick_base, ONLY: pstickset
      USE electrons_module, ONLY: bmeshset
      USE mp_global, ONLY: nproc, mpime, group
      USE smallbox_grid_dimensions, ONLY: nr1b, nr2b, nr3b
      USE ions_base, ONLY: taui, cdmi, nat, nsp
      USE sic_module, ONLY: nat_localisation, self_interaction, si_epsilon, rad_localisation, &
                            ind_localisation, pos_localisation
      USE ions_base, ONLY: if_pos, ind_srt, ions_thermal_stress
      USE constants, ONLY: au, au_ps
      USE electrons_base, ONLY: nupdwn, nbnd
      USE electrons_nose, ONLY: electrons_nosevel, electrons_nose_shiftvar, electrons_noseupd, &
                                vnhe, xnhe0, xnhem, xnhep, qne, ekincw
      USE cell_nose, ONLY: cell_nosevel, cell_noseupd, cell_nose_shiftvar, &
                           vnhh, xnhh0, xnhhm, xnhhp, qnh, temph
      USE cell_base, ONLY: cell_gamma
      USE grid_subroutines, ONLY: realspace_grids_init, realspace_grids_para
      !
      USE reciprocal_space_mesh, ONLY:  gindex_closeup
      !
      USE reciprocal_vectors, ONLY: &
           g,      & ! G-vectors square modulus
           gx,     & ! G-vectors component
           mill_l, & ! G-vectors generators
           gcutw,  & ! Wave function cut-off ( units of (2PI/alat)^2 => tpiba2 )
           gcutp,  & ! Potentials and Charge density cut-off  ( same units )
           gcuts,  & ! Smooth mesh Potentials and Charge density cut-off  ( same units )
           gkcut,  & ! Wave function augmented cut-off (take into account all G + k_i , same units)
           gzero,  & ! 
           ngw,    & !
           ngwt,   & !
           ngm,    & !
           ngs
      !
      USE recvecs_subroutines, ONLY: recvecs_init
      !
      USE wavefunctions_module, ONLY: & ! electronic wave functions
           c0, & ! c0(:,:,:,:)  ! wave functions at time t
           cm, & ! cm(:,:,:,:)  ! wave functions at time t-delta t
           cp, & ! cp(:,:,:,:)  ! wave functions at time t+delta t
           ce    ! ce(:,:,:,:)  ! empty states wave func. at time t
      !
      USE grid_dimensions, ONLY: nr1, nr2, nr3, nr1x, nr2x, nr3x
      USE smooth_grid_dimensions, ONLY: nr1s, nr2s, nr3s, nr1sx, nr2sx, nr3sx
      !
      USE ions_nose, ONLY: ions_nose_shiftvar, vnhp, xnhpp, xnhp0, xnhpm, ions_nosevel, &
                           ions_noseupd, qnp, gkbt, kbt, nhpcl, nhpdim, nhpend, gkbt2nhp, ekin2nhp

      !
      USE uspp_param      , ONLY: nhm
      !
      USE core            , ONLY: deallocate_core
      USE local_pseudo    , ONLY: deallocate_local_pseudo
      !
      USE io_files        , ONLY: outdir, prefix
      USE printout_base   , ONLY: printout_base_init
      USE cp_main_variables, ONLY : atoms0, atomsp, atomsm, ei1, ei2, ei3, eigr, sfac, &
                                    ht0, htm, htp, rhoe, vpot, desc, wfill, wempt,     &
                                    acc, acc_this_run, occn, edft, nfi, bec, becdr

      IMPLICIT NONE

      REAL(DP) :: tau( :, : )
      REAL(DP) :: fion( :, : )
      REAL(DP) :: etot

! ... declare functions

! ... declare other variables
      INTEGER :: ik, nstep_this_run, iunit, is, i, j, ierr
      INTEGER :: nnrg
      INTEGER :: n1, n2, n3
      INTEGER :: n1s, n2s, n3s

      REAL(DP) :: ekinc, ekcell, ekinp, erhoold, maxfion
      REAL(DP) :: derho
      REAL(DP) :: ekincs( nspinx )
      REAL(DP) :: s1, s2, s3, s4, s5, s6, s7, s8
      REAL(DP) :: timernl, timerho, timevof, timepre
      REAL(DP) :: timeform, timerd, timeorto, timeloop
      REAL(DP) :: ekmt(3,3) = 0.0d0
      REAL(DP) :: hgamma(3,3) = 0.0d0
      REAL(DP) :: temphh(3,3) = 0.0d0

      LOGICAL :: ttforce, ttdiis
      LOGICAL :: ttprint, ttsave, ttdipole, ttoptical, ttexit
      LOGICAL :: tstop, tconv, doions
      LOGICAL :: topen, ttcarpar, ttempst
      LOGICAL :: ttconvchk
      LOGICAL :: ttionstep
      LOGICAL :: tconv_cg

      REAL(DP) :: vnosee, vnosep

      REAL(DP), EXTERNAL  :: cclock

      !
      ! ... end of declarations
      !

      IF( t_diis ) THEN 
        CALL allocate_diis( ngw, nbnd, kp%nkpt )
      END IF

      erhoold   = 1.0d+20  ! a very large number
      ekincs    = 0.0d0
      ekinc     = 0.0_DP
      ekcell    = 0.0_DP
      timepre   = 0.0_DP
      timernl   = 0.0_DP
      timerho   = 0.0_DP
      timevof   = 0.0_DP
      timerd    = 0.0_DP
      timeorto  = 0.0_DP
      timeform  = 0.0_DP
      timeloop  = 0.0_DP
      nstep_this_run  = 0

      MAIN_LOOP: DO 

        s3 = cclock()

        ! ...   increment simulation steps counter
        !
        nfi = nfi + 1

        ! ...   increment run steps counter
        !
        nstep_this_run = nstep_this_run + 1
        
        ! ...   Increment the integral time of the simulation
        !
        tps = tps + delt * au_ps

        ! ...   set the right flags for the current MD step
        !
        ttprint   = ( MOD(nfi, iprint) == 0 )  .OR. ( iprsta > 2 )
        ttsave    =   MOD(nfi, isave)  == 0
        !
        ttconvchk =  tconvthrs%active .AND. ( MOD( nfi, tconvthrs%nstep ) == 0 )
        !
        ttdipole  =  ttprint .AND. tdipole
        ttoptical =  ttprint .AND. toptical
        ttforce   =  ttprint .OR.  tfor .OR. ttconvchk
        ttempst   =  ttprint .AND. ( MAXVAL( wempt%nbt ) > 0 )
        ttcarpar  =  tcarpar
        ttdiis    =  t_diis 
        doions    = .TRUE.

        IF( ionode .AND. ttprint ) THEN
           !
           WRITE( stdout, fmt = '( /, " * Physical Quantities at step:",  I6 )' ) nfi
           WRITE( stdout, fmt = '( /, "   Simulated time t = ", D14.8, " ps" )' ) tps
           !
        END IF

        IF( memchk ) CALL memstat(0)

        IF( thdyn .AND. tnoseh ) THEN
           !
           CALL cell_nosevel( vnhh, xnhh0, xnhhm, delt )
           !
           velh(:,:)=2.*(ht0%hmat(:,:)-htm%hmat(:,:))/delt-velh(:,:)
           !
        END IF

        IF( thdyn ) THEN
           !
           ! ...     the simulation cell isn't fixed, recompute the reciprocal lattice
           !
           CALL newinit( ht0%hmat )
           !
           CALL newnlinit( )
           !
        END IF

        IF(memchk) CALL memstat(1)

        IF( tfor .OR. thdyn ) THEN
           !
           ! ...     ionic positions aren't fixed, recompute structure factors 
           !
           CALL phfacs( ei1, ei2, ei3, eigr, mill_l, atoms0%taus, nr1, nr2, nr3, atoms0%nat )
           !
           CALL strucf( sfac, ei1, ei2, ei3, mill_l, ngm )
           !
        END IF

        IF(memchk) CALL memstat(2)

        IF( thdyn ) THEN
           !
           !      the simulation cell isn't fixed, recompute local 
           !      pseudopotential Fourier expansion
           !
           CALL formf( .false. , edft%eself )
           !
        END IF

        IF(memchk) CALL memstat(3)

        s4       = cclock()
        timeform = s4 - s3

        IF( ttdiis .AND. t_diis_simple ) THEN
           !
           ! ...     perform DIIS minimization on electronic states
           !
           CALL runsdiis(ttprint, rhoe, desc, atoms0, bec, becdr, &
               eigr, ei1, ei2, ei3, sfac, c0, cm, cp, wfill, thdyn, ht0, occn, ei, &
               vpot, doions, edft )
           !
        ELSE IF (ttdiis .AND. t_diis_rot) THEN
           !
           ! ...     perform DIIS minimization with wavefunctions rotation
           !
           IF( nspin > 1 ) CALL errore(' cpmain ',' lsd+diis not allowed ',0)
           !
           CALL rundiis(ttprint, rhoe, desc, atoms0, bec, becdr, &
               eigr, ei1, ei2, ei3, sfac, c0, cm, cp, wfill, thdyn, ht0, occn, ei, &
               vpot, doions, edft )
           !
        ELSE IF ( tconjgrad ) THEN
           !
           ! ...     on entry c0 should contain the wavefunctions to be optimized
           !
           CALL runcg(tortho, ttprint, rhoe, desc, atoms0, bec, becdr, &
               eigr, ei1, ei2, ei3, sfac, c0, cm, cp, wfill, thdyn, ht0, occn, ei, &
               vpot, doions, edft, ekin_maxiter, etot_conv_thr, tconv_cg )
           !
           ! ...     on exit c0 and cp both contain the updated wave function
           ! ...     cm are overwritten (used as working space)
           !
        ELSE IF ( tsteepdesc ) THEN
           !
           CALL runsd(tortho, ttprint, ttforce, rhoe, desc, atoms0, bec, becdr, &
               eigr, ei1, ei2, ei3, sfac, c0, cm, cp, wfill, thdyn, ht0, occn, ei, &
               vpot, doions, edft, ekin_maxiter, ekin_conv_thr )
           !
        ELSE IF ( tconjgrad_ion%active ) THEN
           !
           CALL runcg_ion(nfi, tortho, ttprint, rhoe, desc, atomsp, atoms0, &
               atomsm, bec, becdr, eigr, ei1, ei2, ei3, sfac, c0, cm, cp, wfill, thdyn, ht0, occn, ei, &
               vpot, doions, edft, tconvthrs%derho, tconvthrs%force, tconjgrad_ion%nstepix, &
               tconvthrs%ekin, tconjgrad_ion%nstepex )
           !
           ! ...     when ions are being relaxed by this subroutine they 
           ! ...     shouldn't be moved by moveions
           !
           doions    = .FALSE.
           !
        ELSE IF ( .NOT. ttcarpar ) THEN
           !
           CALL errore(' main ',' electron panic ',0)
           !
        END IF

        IF(memchk) CALL memstat(4)

        ! ...   compute nonlocal pseudopotential
        !
        atoms0%for = 0.0d0
        !
        edft%enl = nlrh_m( c0, wfill, ttforce, atoms0, occn, bec, becdr, eigr)

        IF(memchk) CALL memstat(5)

        s5      = cclock()
        timernl = s5 - s4

        ! ...   compute the new charge density "rhoe"
        !
        CALL rhoofr( nfi, c0, wfill, occn, rhoe, desc, ht0)

        IF(memchk) CALL memstat(6)

        s6      = cclock()
        timerho = s6 - s5

        ! ...   vofrhos compute the new DFT potential "vpot", and energies "edft",
        ! ...   ionc forces "fion" and stress "pail".
        !
        CALL vofrhos(ttprint, rhoe, desc, tfor, thdyn, ttforce, atoms0, &
          vpot, bec, c0, wfill, occn, eigr, ei1, ei2, ei3, sfac, timepre, ht0, edft)

        ! CALL debug_energies( edft ) ! DEBUG

        IF(memchk) CALL memstat(7)

        s7      = cclock()
        timevof = s7 - s6

        ! ...   Car-Parrinello dynamics for the electrons
        !
        IF( ttcarpar ) THEN
           !
           ! ...     calculate thermostat velocity
           !
           IF(tnosee) THEN
              call electrons_nosevel( vnhe, xnhe0, xnhem, delt )
              vnosee = vnhe
           END IF

           !    move electronic degrees of freedom by Verlet's algorithm
           !    on input, c0 are the wave functions at time "t" , cm at time "t-dt"
           !    on output cp are the new wave functions at time "t+dt"

           if ( force_pairing ) then 
              !
              ! unpaired electron is assumed of spinup and in highest 
              ! index band; and put equal for paired wf spin up and down
              !
              CALL runcp_force_pairing(ttprint, tortho, tsde, cm, c0, cp, wfill, &
                vpot, eigr, occn, ekincs, timerd, timeorto, ht0, ei, bec, vnosee )
              !
           ELSE
              !
              CALL runcp( ttprint, tortho, tsde, cm, c0, cp, wfill, vpot, eigr, &
                         occn, ekincs, timerd, timeorto, ht0, ei, bec, vnosee )
              !
           END IF

           ekinc = SUM( ekincs )
           !
           !   ...     propagate thermostat for the electronic variables
           !
           IF(tnosee) THEN
              CALL electrons_noseupd( xnhep, xnhe0, xnhem, delt, qne, ekinc, ekincw, vnhe ) 
           END IF
           !
           !  check if ions should be moved
           !
           IF( tfor .AND. tionstep ) THEN
              !
              doions = .FALSE.
              IF( ( ekinc < ekin_conv_thr ) .AND. ( MOD( nfi, nstepe ) == 0 ) ) THEN
                 doions = .TRUE.
              END IF
              WRITE( stdout,fmt="(3X,'MAIN: doions = ',L1)") doions
           END IF
           !
        END IF

        IF(memchk) CALL memstat(8)

        ! ...   Ions Dynamics
        !
        ekinp  = 0.d0  ! kinetic energy of ions
        !
        IF( tfor .AND. doions ) THEN
           !
           ! ...     Determines DXNOS/DT dynamically
           !
           IF (tnosep) THEN
              CALL ions_nosevel( vnhp, xnhp0, xnhpm, delt, 1, 1 )
              vnosep = vnhp(1)
           END IF
           !
           ! ...     move ionic degrees of freedom
           !
           ekinp = moveions(tsdp, thdyn, nfi, atomsm, atoms0, atomsp, htm, ht0, vnosep)
           IF (tnosep) THEN
              !
              ! below one really should have atoms0%ekint and NOT ekin2nhp
              CALL ions_noseupd( xnhpp, xnhp0, xnhpm, delt, qnp, ekin2nhp, gkbt2nhp, vnhp, kbt, nhpcl, nhpdim, nhpend )
              !
           END IF
           !
           !   Add thermal stress to pail
           !
           ekmt = 0.0d0
           CALL ions_thermal_stress( ekmt, atoms0%m, 1.0d0, ht0%hmat, atoms0%vels, atoms0%nsp, atoms0%na )
           !
           ht0%pail = ht0%pail + MATMUL( ekmt, ht0%m1(:,:) )
           !
        END IF

        ! ...   Cell Dynamics

        ekcell = 0.d0  ! kinetic energy of the cell (Parrinello-Rahman scheme)

        IF( thdyn .AND. doions ) THEN

           !   move cell coefficients
           !
           CALL movecell(tsdc, htm, ht0, htp, velh)

           velh(:,:) = ( htp%hmat(:,:) - htm%hmat(:,:) ) / ( 2.0d0 * delt )
           ht0%hvel = velh

           CALL cell_gamma( hgamma, ht0%hinv, ht0%hmat, velh )

           !   Kinetic energy of the box

           CALL cell_kinene( ekcell, temphh, velh )

           IF ( tnoseh ) THEN
              CALL cell_noseupd( xnhhp, xnhh0, xnhhm, delt, qnh, temphh, temph, vnhh )
           END IF

        END IF


        IF(memchk) CALL memstat(10)

        ! ...   Here find Empty states eigenfunctions and eigenvalues
        !
        IF ( ttempst ) THEN
           CALL empty( tortho, atoms0, c0, wfill, ce, wempt, vpot, eigr )
        END IF

        ! ...   dipole
        !
        IF( ttdipole ) THEN

#if defined __ALPHA
           CALL errore( ' main ',' there are still problem on alpha with this routine ', 0 )
#else
           IF( wfill%nspin > 1 ) &
              CALL errore( ' main ',' dipole with spin not yet implemented ', 0 )
           !
           CALL ddipole( nfi, ht0, c0(:,:,1,1), atoms0, tfor, ngw, wfill%nbl( 1 ), wfill%nbl( 1 ), ngw )
#endif

        END IF

        ! ...   Optical properties
        !
        IF( ttoptical ) THEN
           CALL errore( ' main ',' optical there are still problem ', 0 )
           ! CALL opticalp(nfi, ht0, atoms0, c0, wfill, occn, ce, wempt, vpot, bec, eigr )
        END IF

        IF( self_interaction /= 0 ) THEN
           IF ( nat_localisation > 0 .AND. ttprint ) THEN
              CALL localisation( cp( : , nupdwn(1), 1, 1 ), atoms0, ht0, desc)
           END IF
        END IF

        ! ...   if we are going to check convergence, then compute the
        ! ...   maximum value of the ionic forces

        tconv = .FALSE.
        !
        IF( ttconvchk ) THEN
           !
           maxfion = max_ion_forces( atoms0 )
           !
           IF( tconjgrad ) THEN
              tconv = tconv_cg
              derho = 0.0d0
           ELSE
              derho = ( erhoold - edft%etot )
              tconv =             ( derho < tconvthrs%derho )
              tconv = tconv .AND. ( ekinc < tconvthrs%ekin )
           END IF
           !
           tconv = tconv .AND. ( maxfion < tconvthrs%force )
           !
           IF( ionode ) THEN
              !
              IF( ttprint .OR. tconv ) THEN
                 !
                 WRITE( stdout,fmt= &
                    "(/,3X,'MAIN:',10X,'EKINC   (thr)',10X,'DETOT   (thr)',7X,'MAXFORCE   (thr)')" )
                 !
                 WRITE( stdout,fmt="(3X,'MAIN: ',3(D14.6,1X,D8.1))" ) &
                    ekinc, tconvthrs%ekin, derho, tconvthrs%derho, maxfion, tconvthrs%force
                 !
                 IF( tconv ) THEN
                    WRITE( stdout,fmt="(3X,'MAIN: convergence achieved for system relaxation')")
                 ELSE
                    WRITE( stdout,fmt="(3X,'MAIN: convergence NOT achieved for system relaxation')")
                 END IF
                 !
              END IF
              !
           END IF
           ! 
           erhoold = edft%etot
           !
        END IF

        ! ...   printout 
        !

        CALL printout( nfi, atoms0, ekinc, ekcell, ttprint, ht0, acc, acc_this_run, edft)

        IF(memchk) CALL memstat(11)

        ! ...   Update variables

        IF ( .NOT. ttdiis ) THEN
           !
           CALL update_wave_functions( cm, c0, cp, wfill )
           !
           IF ( tnosee ) THEN
              CALL electrons_nose_shiftvar( xnhep, xnhe0, xnhem )
           END IF
           !
        ELSE
           !
           IF( .NOT. tfor ) THEN
              cm = c0
           END IF
           !
        END IF

        IF ( doions ) THEN

           IF ( tfor ) THEN
              !
              CALL update_ions( atomsm, atoms0, atomsp )
              !
              IF ( tnosep ) THEN
                 CALL ions_nose_shiftvar( xnhpp, xnhp0, xnhpm )
              END IF
              !
           END IF

           IF ( thdyn ) THEN
              !
              CALL updatecell( htm, ht0, htp)
              !
              IF( tnoseh ) THEN
                 CALL cell_nose_shiftvar( xnhhp, xnhh0, xnhhm )
              END IF
              !
           END IF

        END IF


        IF(memchk) CALL memstat(12)

        frich = frich * greash

        ! ...   stop the code if either the file .cp_stop is present or the
        ! ...   cpu time is greater than max_seconds
 
        tstop =  check_stop_now()

        ! ...   stop if only the electronic minimization was required
        !        IF(.NOT. (tfor .OR. thdyn) .AND. ttdiis ) tstop = .TRUE.

        tstop = tstop .OR. tconv

        ttexit = tstop .OR. ( nfi >= nomore )

        ! ...   write the restart file
        !
        IF( ttsave .OR. ttexit ) THEN
          CALL writefile( nfi, tps, c0, cm, wfill, occn, atoms0, atomsm, acc,  &
                          taui, cdmi, htm, ht0, rhoe, desc, vpot )
        END IF

        IF( ttexit .AND. .NOT. ttprint ) THEN
           !
           ! When code stop write to stdout quantities regardles of the value of nfi
           ! but do not print if MOD( nfi, iprint ) == 0  
           !
           CALL printout( nfi, atoms0, ekinc, ekcell, ttexit, ht0, acc, acc_this_run, edft)
           !
        END IF

        s8 = cclock()
        timeloop = s8 - s3

        CALL print_time( ttprint, ttexit, timeform, timernl, timerho,  &
                         timevof, timerd, timeorto, timeloop, timing )

        ! ...   loop back
        !
        IF( ttexit ) EXIT MAIN_LOOP

      END DO MAIN_LOOP


      conv_elec = tconv
      etot      = edft%etot
      !
      CALL resort_position( tau, fion, atoms0, ind_srt, ht0 )
      !
      IF( lneb ) THEN
        DO i = 1, nat
          fion( :, i ) = fion( :, i ) * DBLE( if_pos( :, i ) )
        END DO
      END IF
      !

      IF(tksout) THEN
        IF ( force_pairing ) THEN 
          CALL ks_states_force_pairing(c0, wfill, ce, wempt, occn, vpot, eigr, bec )
        ELSE
          CALL ks_states(c0, wfill, ce, wempt, occn, vpot, eigr, bec )
        END IF
      END IF

      IF(tprnsfac) THEN
        CALL print_sfac(rhoe, desc, sfac)
      END IF

      ! ... report statistics

      CALL printacc(nfi, rhoe, desc, rhoout, atomsm, htm, nstep_this_run, acc, acc_this_run)
      CALL mp_report_buffers()
      CALL mp_report()

      DO iunit = 10, 99
        IF( iunit == stdout ) CYCLE
        INQUIRE(UNIT=iunit,OPENED=topen)
        IF(topen) THEN
          WRITE( stdout,*) '  main: Closing unit :',iunit
          CLOSE(iunit)
        END IF
      END DO

      ! ... free memory

      CALL fft_closeup( )

      IF( allocated( c0 ) ) deallocate(c0)
      IF( allocated( cp ) ) deallocate(cp)
      IF( allocated( cm ) ) deallocate(cm)
      IF( allocated( ce ) ) deallocate(ce)

      CALL optical_closeup()
      CALL gindex_closeup
      CALL guess_closeup
      CALL ks_states_closeup

      CALL deallocate_modules_var()

      RETURN
    END SUBROUTINE cpmain

!=----------------------------------------------------------------------------=!
  END MODULE main_module
!=----------------------------------------------------------------------------=!
