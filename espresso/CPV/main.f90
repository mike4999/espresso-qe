!
! Copyright (C) 2002 FPMD group
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
!  list of Fortran I/O units used by the program
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
      USE phase_factors_module, ONLY : strucf
      USE restart_file, ONLY : writefile, readfile
      USE parameters, ONLY: nacx, nspinx
      USE runcp_module, ONLY: runcp, runcp_force_pairing
      USE runcg_module, ONLY: runcg
      USE runcg_ion_module, ONLY: runcg_ion
      USE control_flags, ONLY: tbeg, nomore, &
                  nbeg, newnfi, tnewnfi, isave, iprint, tv0rd, nv0rd, tzeroc, tzerop, &
                  tfor, thdyn, tzeroe, tsde, tsdp, tsdc, taurdr, ndr, &
                  ndw, tortho, tstress, prn, timing, memchk, &
                  tconjgrad, tprnsfac, toptical, tcarpar, &
                  rhoout, tdipole, t_diis, t_diis_simple, t_diis_rot, &
                  tnosee, tnosep, force_pairing, tconvthrs, convergence_criteria, tionstep, nstepe, &
                  tsteepdesc, ekin_conv_thr, ekin_maxiter, ionic_conjugate_gradient, &
                  tconjgrad_ion, conv_elec, lneb, tnoseh, tuspp, etot_conv_thr
      USE init_fpmd
      USE cp_types
      USE atoms_type_module, ONLY: atoms_type, deallocate_atoms_type
      USE print_out_module, ONLY: print_legend, printout, print_time, print_sfac, &
          printacc
      USE cell_module, ONLY: movecell, press, boxdimensions, updatecell, get_celldm
      USE empty_states, ONLY: empty
      USE polarization, ONLY: deallocate_polarization, ddipole
      USE energies, ONLY: dft_energy_type, debug_energies
      USE recvecs_indexes, ONLY: deallocate_recvecs_indexes
      USE turbo, ONLY: tturbo, deallocate_turbo
      USE nose_ions, ONLY: movenosep, nosep_velocity, update_nose_ions
      USE nose_electrons, ONLY: movenosee, nosee_velocity, update_nose_electrons
      USE pseudopotential
      USE potentials, ONLY: vofrhos, localisation
      USE ions_module, ONLY: taui, cdmi, moveions, max_ion_forces, &
          deallocate_ions, neighbo, update_ions, tneighbo, neighbo_radius, &
          resort_position
      USE fft, ONLY : fft_closeup
      USE electrons_module, ONLY: ei, nspin, deallocate_electrons
      USE diis, ONLY: allocate_diis, deallocate_diis
      USE pseudo_projector, ONLY: projector, deallocate_projector
      USE charge_density, ONLY: rhoofr, printrho
      USE stick, ONLY: deallocate_stick, dfftp, dffts
      USE check_stop, ONLY: check_stop_now
      USE nl, ONLY: nlrh_m
      USE time_step, ONLY: tps, delt
      USE brillouin, ONLY: kp
      USE rundiis_module, ONLY: rundiis, runsdiis
      USE from_scratch_module, ONLY: from_scratch
      USE from_restart_module, ONLY: from_restart
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
      USE charge_mix, ONLY: deallocate_charge_mix
      USE chi2, ONLY: deallocate_chi2
      USE guess, ONLY: guess_closeup
      USE input, ONLY: iosys
      USE problem_size, ONLY: cpsizes
      USE cell_base, ONLY: alat, a1, a2, a3, cell_kinene
      USE cell_base, ONLY: frich, greash
      USE stick_base, ONLY: pstickset
      USE electrons_module, ONLY: bmeshset
      USE mp_global, ONLY: nproc, mpime, group
      USE input_parameters, ONLY: nr1b, nr2b, nr3b
      USE ions_base, ONLY: deallocate_ions_base, ind_localisation, pos_localisation
      USE ions_base, ONLY: nat_localisation, self_interaction, si_epsilon, rad_localisation
      USE ions_base, ONLY: ind_srt, ions_thermal_stress
      USE constants, ONLY: au, au_ps
      USE electrons_base, ONLY: nupdwn, deallocate_elct
      USE cell_nose, ONLY: cell_nosevel, cell_noseupd, vnhh, xnhh0, xnhhm, xnhhp, qnh, temph
      USE cell_base, ONLY: cell_gamma
      USE grid_subroutines, ONLY: realspace_grids_init, realspace_grids_para
      !
      USE reciprocal_space_mesh, ONLY: gmeshinfo, newg, gindex_closeup
      !
      USE reciprocal_vectors, ONLY: &
           gcutw, & ! Wave function cut-off ( units of (2PI/alat)^2 => tpiba2 )
           gcutp, & ! Potentials and Charge density cut-off  ( same units )
           gcuts, & ! Smooth mesh Potentials and Charge density cut-off  ( same units )
           gkcut, & ! Wave function augmented cut-off (take into account all G + k_i , same units)
           ngw, & !
           ngm, & !
           ngs, & !
           deallocate_recvecs
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

      IMPLICIT NONE

      REAL(dbl) :: tau( :, : )
      REAL(dbl) :: fion( :, : )
      REAL(dbl) :: etot

! ... declare functions

! ... declare other variables
      INTEGER :: navgs, nfi, ik, nstep_this_run, iunit, is, i, j, ierr
      INTEGER :: nnrg
      INTEGER :: n1, n2, n3
      INTEGER :: n1s, n2s, n3s
      INTEGER :: ngm_ , ngw_ , ngs_

      REAL(dbl) :: ekinc, ekcell, annee, ekinp, erhoold, maxfion
      REAL(dbl) :: derho
      REAL(dbl) :: ekincs( nspinx )
      REAL(dbl) :: s1, s2, s3, s4, s5, s6, s7, s8
      REAL(dbl) :: timernl, timerho, timevof, timepre
      REAL(dbl) :: timeform, timerd, timeorto, timeloop
      REAL(dbl) :: qk(3) = 0.0d0
      REAL(dbl) :: ekmt(3,3) = 0.0d0
      REAL(dbl) :: velh(3,3) = 0.0d0
      REAL(dbl) :: hgamma(3,3) = 0.0d0
      REAL(dbl) :: temphh(3,3) = 0.0d0

      LOGICAL :: ttforce, ttdiis
      LOGICAL :: ttprint, ttsave, ttdipole, ttoptical, ttexit
      LOGICAL :: tstop, tconv, doions
      LOGICAL :: topen, ttcarpar, ttempst
      LOGICAL :: ttconvchk
      LOGICAL :: ttionstep

      REAL(dbl) ::  avgs( nacx )
      REAL(dbl) ::  avgs_this_run( nacx )

      ! atomic positions 
      TYPE (atoms_type) :: atoms_0, atoms_p, atoms_m

      ! pseudopotentials
      TYPE (pseudo)  :: ps

      ! charge density
      REAL(dbl), ALLOCATABLE :: rhoe(:,:,:,:)     ! charge density in real space
      TYPE (charge_descriptor)  :: desc                  ! charge density descriptor


      TYPE (wave_descriptor) :: wfill, wempt    ! wave function descriptor
                                                ! for filled and empty states

      ! electronic states filling 
      REAL(dbl), ALLOCATABLE :: fi(:,:,:)     ! occupation numbers for filled state

      ! phase and structure factors 
      TYPE (phase_factors)   :: eigr         ! exp (i G dot r)

      ! structure factors  S( s, G ) = sum_(I in s) exp( i G dot R_(s,I) )
      ! s       = index of the atomic specie
      ! R_(s,I) = position of the I-th atom of the "s" specie
      COMPLEX(dbl), ALLOCATABLE :: sfac(:,:)

      ! reciprocal lattice and reciprocal vectors
      TYPE (recvecs) :: gv           ! reciprocal lattice

      ! cell geometry
      TYPE (boxdimensions) :: ht_m2, ht_m, ht_0, ht_p  ! cell metrics

      TYPE (projector), ALLOCATABLE :: fnl( :, : )
      TYPE (dft_energy_type) :: edft

      REAL(dbl), ALLOCATABLE :: vpot(:,:,:,:)
      REAL(dbl) :: vnosee, vnosep

      REAL(dbl) :: celldm( 6 )
      INTEGER :: ibrav
      INTEGER :: lds_wfc

      REAL(dbl), EXTERNAL  :: cclock


! ... end of declarations
!  ----------------------------------------------

! *** INITIALIZATION SECTION ***

      s1 = cclock()

! ... input parameter setup routine

      CALL iosys()

      CALL init_dimensions( )

      timepre = 0.0_dbl
      timernl = 0.0_dbl
      timerho = 0.0_dbl
      timevof = 0.0_dbl
      timerd  = 0.0_dbl
      timeorto= 0.0_dbl
      timeform= 0.0_dbl
      timeloop= 0.0_dbl

      nfi     = 0
      nstep_this_run  = 0
      annee   = 0.0_dbl
      ekinc   = 0.0_dbl
      ekcell  = 0.0_dbl
      avgs    = 0.0_dbl
      avgs_this_run = 0.0_dbl
      navgs   = 9

      edft%ent  = 0.0d0
      edft%esr  = 0.0d0
      edft%evdw = 0.0d0
      edft%ekin = 0.0d0
      edft%enl  = 0.0d0
      edft%etot = 0.0d0

      erhoold   = 1.0d+20  ! a very large number
      ekincs    = 0.0d0

      ALLOCATE( fnl( kp%nkpt, nspin ) )

! ... get information
!
      CALL get_celldm(ibrav, celldm)

! ... initialization routines
!
      CALL init0s(gv, kp, ps, atoms_m, atoms_0, atoms_p, wfill, &
        wempt, ht_m2, ht_m, ht_0, fnl, eigr, nspin)

      lds_wfc = wfill%lds
      IF( force_pairing ) lds_wfc = 1

      ALLOCATE( cm( wfill%ldg, wfill%ldb, wfill%ldk, lds_wfc ) )
      ALLOCATE( c0( wfill%ldg, wfill%ldb, wfill%ldk, lds_wfc ) )
      ALLOCATE( cp( wfill%ldg, wfill%ldb, wfill%ldk, lds_wfc ) )
      ALLOCATE( fi( wfill%ldb, wfill%ldk, wfill%lds ) )
      ALLOCATE( ce( wempt%ldg, wempt%ldb, wempt%ldk, wempt%lds ) )

      cm = 0.0d0
      c0 = 0.0d0
      cp = 0.0d0
      ce = 0.0d0
      fi = 0.0d0

      CALL init1s(gv, kp, ps, atoms_m, atoms_0, atoms_p, cm, c0, wfill, &
        ce, wempt, ht_m2, ht_m, ht_0, fnl, eigr, fi )

      CALL print_legend( )

      ALLOCATE( rhoe( dfftp%nr1x, dfftp%nr2x, dfftp%npl, nspin ) )
      CALL charge_descriptor_init( desc, dfftp%nr1, dfftp%nr2, dfftp%nr3, &
             dfftp%nr1, dfftp%nr2, dfftp%npl, dfftp%nr1x, dfftp%nr2x,     &
             dfftp%npl, nspin )


      ALLOCATE( sfac( atoms_0%nsp, gv%ng_l ) ) 

      ALLOCATE( vpot( dfftp%nr1x, dfftp%nr2x, dfftp%npl, nspin), STAT=ierr)

      IF( ierr /= 0 ) &
        CALL errore(' cpmain ', ' allocating vpot ', ierr)

      IF( nbeg < 0 ) THEN
!
! ...   create a new configuration from scratch
!
        ttprint = .true.
        CALL from_scratch(gv, kp, ps, rhoe, desc, cm, c0, wfill, eigr, sfac, fi, &
          ht_0, atoms_0, fnl, vpot, edft )

        CALL printout(nfi, atoms_0, ekinc, ekcell, ttprint, &
          toptical, ht_0, kp, prn, avgs, avgs_this_run, edft)

      ELSE

! ...   read configuration from a restart file
! ...   (Fortran I/O unit number ndr, file fort.<ndr>)

        CALL readfile( nfi, tps, c0, cm, wfill, fi, &
           atoms_0, atoms_m, avgs, taui, cdmi, ibrav, celldm, ht_m2, ht_m, ht_0, rhoe, &
           desc, vpot, gv, kp)

        CALL from_restart( nfi, avgs, gv, kp, ps, rhoe, desc, cm, c0, wfill, eigr, sfac, &
           fi, ht_m, ht_0, atoms_m, atoms_0, fnl, vpot, edft)

        velh = ht_m%hvel

      END IF


      s2 = cclock() 


      IF( tnewnfi   ) nfi = newnfi
      nomore = nfi + nomore

      MAIN_LOOP: DO                      ! *** START OF MAIN LOOP *** !


        s3 = cclock()

! ...   increment symulation steps counter
        nfi = nfi + 1

! ...   increment run steps counter
        nstep_this_run = nstep_this_run + 1
        
! ...   Increment the integral time of the simulation
        tps = tps + delt * au_ps

! ...   set the right flags for the current MD step
        ttprint   = ( MOD(nfi, iprint) == 0)  .OR. prn
        ttsave    =   MOD(nfi, isave) == 0
        ttconvchk =  tconvthrs%active .AND. ( MOD( nfi, tconvthrs%nstep) == 0 )
        ttdipole  =  ttprint .AND. tdipole
        ttoptical =  ttprint .AND. toptical
        ttforce   =  ttprint .OR.  tfor .OR. ttconvchk
        ttempst   =  ttprint .AND. ( MAXVAL( wempt%nbt ) > 0 )
        ttcarpar  =  tcarpar
        ttdiis    =  t_diis 
        doions    = .TRUE.


        IF( ionode .AND. ttprint ) THEN
          WRITE( stdout, fmt = '(  //, " * MD STEP  <> ",  I6,  " <> "  )' ) nfi
        END IF

        IF(memchk) CALL memstat(0)

        IF( thdyn .AND. tnoseh ) THEN
          ! WRITE(6,*) xnhh0(1:3,1:3)  ! DEBUG
          CALL cell_nosevel( vnhh, xnhh0, xnhhm, delt, velh, ht_0%hmat, ht_m%hmat )
        END IF

        IF( thdyn ) THEN
! ...     the simulation cell isn't fixed, recompute the reciprocal lattice
          CALL newg(gv, kp, ht_0%m1)
        END IF

        IF(memchk) CALL memstat(1)

        IF( tfor .OR. thdyn ) THEN
! ...     ionic positions aren't fixed, recompute structure factors 
          CALL strucf(sfac, atoms_0, eigr, gv)
        END IF

        IF(memchk) CALL memstat(2)

        IF( thdyn ) THEN
! ...     recompute local pseudopotential Fourier expansion
          CALL formf(ht_0, gv, kp, ps)
        END IF

        IF(memchk) CALL memstat(3)

        s4       = cclock()
        timeform = s4 - s3

        IF( ttdiis .AND. t_diis_simple ) THEN
! ...     perform DIIS minimization on electronic states
          CALL runsdiis(ttprint, prn, rhoe, desc, atoms_0, gv, kp, &
               ps, eigr, sfac, c0, cm, cp, wfill, thdyn, ht_0, fi, ei, &
               fnl, vpot, doions, edft )
        ELSE IF (ttdiis .AND. t_diis_rot) THEN
! ...     perform DIIS minimization with wavefunctions rotation
          IF(nspin.GT.1) CALL errore(' cpmain ',' lsd+diis not allowed ',0)
          CALL rundiis(ttprint, prn, rhoe, desc, atoms_0, gv, kp, &
               ps, eigr, sfac, c0, cm, cp, wfill, thdyn, ht_0, fi, ei, &
               fnl, vpot, doions, edft )
        ELSE IF ( tconjgrad ) THEN
! ...     on entry c0 should contain the wavefunctions to be optimized
          CALL runcg(tortho, ttprint, prn, rhoe, desc, atoms_0, gv, kp, &
               ps, eigr, sfac, c0, cm, cp, wfill, thdyn, ht_0, fi, ei, &
               fnl, vpot, doions, edft, ekin_maxiter, etot_conv_thr )
! ...     on exit c0 and cp both contain the updated wave function
! ...     cm are overwritten (used as working space)
        ELSE IF ( tsteepdesc ) THEN
          CALL runsd(tortho, ttprint, ttforce, prn, rhoe, desc, atoms_0, gv, kp, &
               ps, eigr, sfac, c0, cm, cp, wfill, thdyn, ht_0, fi, ei, &
               fnl, vpot, doions, edft, ekin_maxiter, ekin_conv_thr )
        ELSE IF ( tconjgrad_ion%active ) THEN
          CALL runcg_ion(nfi, tortho, ttprint, prn, rhoe, desc, atoms_p, atoms_0, &
               atoms_m, gv, kp, ps, eigr, sfac, c0, cm, cp, wfill, thdyn, ht_0, fi, ei, &
               fnl, vpot, doions, edft, tconvthrs%derho, tconvthrs%force, tconjgrad_ion%nstepix, &
               tconvthrs%ekin, tconjgrad_ion%nstepex )
! ...     when ions are being relaxed by this subroutine they 
! ...     shouldn't be moved by moveions
          doions    = .FALSE.
        ELSE IF ( .NOT. ttcarpar ) THEN
          CALL errore(' main ',' electron panic ',0)
        END IF

        IF(memchk) CALL memstat(4)

! ...   compute nonlocal pseudopotential
        atoms_0%for = 0.0d0
        edft%enl = nlrh_m( c0, wfill, ttforce, atoms_0, fi, gv, kp, fnl, ps%wsg, ps%wnl, eigr)

        IF(memchk) CALL memstat(5)

        s5      = cclock()
        timernl = s5 - s4

! ...   compute the new charge density "rhoe"
        CALL rhoofr(gv, kp, c0, wfill, fi, rhoe, desc, ht_0)
        ! CALL printrho(nfi, rhoe, atoms_0, ht_0) ! DEBUG

        IF(memchk) CALL memstat(6)

        s6      = cclock()
        timerho = s6 - s5

! ...   vofrhos compute the new DFT potential "vpot", and energies "edft",
! ...   ionc forces "fion" and stress "pail".
        CALL vofrhos(ttprint, prn, rhoe, desc, tfor, thdyn, ttforce, atoms_0, &
          gv, kp, fnl, vpot, ps, c0, wfill, fi, eigr, sfac, timepre, ht_0, edft)

        ! .. WRITE( stdout,*) 'DEBUG MAIN', atoms_0%for( 1:3, 1:atoms_0%nat )
        ! CALL debug_energies( edft ) ! DEBUG

        IF(memchk) CALL memstat(7)

        s7      = cclock()
        timevof = s7 - s6

! ...   Car-Parrinello dynamics for the electrons
        IF( ttcarpar ) THEN
! ...     calculate thermostat velocity
          IF(tnosee) THEN
            vnosee = nosee_velocity()
          END IF
! ...     move electronic degrees of freedom by Verlet's algorithm
! ...     on input, c0 are the wave functions at time "t" , cm at time "t-dt"
! ...     on output cp are the new wave functions at time "t+dt"
          if ( force_pairing ) then 
            ! unpaired electron is assumed of spinup and in highest 
            ! index band; and put equal for paired wf spin up and down
            CALL runcp_force_pairing(ttprint, tortho, tsde, cm, c0, cp, wfill, gv, &
              kp, ps, vpot, eigr, fi, ekincs, timerd, &
              timeorto, ht_0, ei, fnl, vnosee )
              ! ekincs(2) = 0
          ELSE
            CALL runcp(ttprint, tortho, tsde, cm, c0, cp, wfill, gv, &
              kp, ps, vpot, eigr, fi, ekincs, timerd, &
              timeorto, ht_0, ei, fnl, vnosee )
          endif

          ekinc = SUM( ekincs )
! ...     propagate thermostat for the electronic variables
          IF(tnosee) THEN
            CALL movenosee(ekinc)
          END IF
          IF( tfor .AND. tionstep ) THEN
            doions = .FALSE.
            IF( ( ekinc < ekin_conv_thr ) .AND. ( MOD( nfi, nstepe ) == 0 ) ) THEN
              doions = .TRUE.
            END IF
            WRITE( stdout,fmt="(3X,'MAIN: doions = ',L1)") doions
          END IF
        END IF

        IF(memchk) CALL memstat(8)


        IF(memchk) CALL memstat(9)

! ...   Ions Dynamics
        ekinp  = 0.d0  ! kinetic energy of ions
        IF(tfor .AND. doions) THEN
! ...     Determines DXNOS/DT dynamically
          IF (tnosep) THEN
            vnosep = nosep_velocity()
          END IF
! ...     move ionic degrees of freedom
          ! ... WRITE( stdout,*) '* TSDP *', tsdp
          ekinp = moveions(tsdp, thdyn, nfi, atoms_m, atoms_0, atoms_p, ht_m2, ht_m, ht_0, vnosep)
          IF (tnosep) THEN
            CALL movenosep(atoms_0%ekint)
          END IF
        END IF

! ...   Cell Dynamics

        IF(tfor .AND. doions) THEN
          !   Add thermal stress to pail
          ekmt = 0.0d0
          CALL ions_thermal_stress( ekmt, atoms_0%m, 1.0d0, ht_0%hmat, atoms_0%vels, atoms_0%nsp, atoms_0%na )
          ht_0%pail = ht_0%pail + MATMUL( ekmt, ht_0%m1(:,:) )
        END IF

        ekcell = 0.d0  ! kinetic energy of the cell (Parrinello-Rahman scheme)

        IF( thdyn .AND. doions ) THEN

          !   move cell coefficients
          CALL movecell(tsdc, ht_m, ht_0, ht_p, velh)

          velh(:,:) = ( ht_p%hmat(:,:) - ht_m%hmat(:,:) ) / ( 2.0d0 * delt )
          ht_0%hvel = velh

          CALL cell_gamma( hgamma, ht_0%hinv, ht_0%hmat, velh )

          !   Kinetic energy of the box

          CALL cell_kinene( ekcell, temphh, velh )

          IF ( tnoseh ) THEN
            CALL cell_noseupd( xnhhp, xnhh0, xnhhm, delt, qnh, temphh, temph, vnhh )
          END IF

        END IF


        IF(memchk) CALL memstat(10)

! ...   Here find Empty states eigenfunctions and eigenvalues
        IF ( ttempst ) THEN
          CALL empty(tortho, atoms_0, gv, c0, wfill, ce, wempt, kp, vpot, eigr, ps )
        END IF

! ...   dipole
        IF( ttdipole ) THEN
#if defined __ALPHA
          CALL errore( ' main ',' there are still problem on alpha with this routine ', 0 )
#else
          IF( wfill%nspin > 1 ) &
            CALL errore( ' main ',' dipole with spin not yet implemented ', 0 )
          CALL ddipole( nfi, ht_0, c0(:,:,1,1), atoms_0, tfor, ngw, wfill%nbl( 1 ), wfill%nbl( 1 ), ngw )
#endif
        END IF

! ...   Optical properties
        IF( ttoptical ) THEN
          CALL opticalp(nfi, ht_0, atoms_0, c0, wfill, fi, ce, wempt, vpot, fnl, eigr, ps, gv, kp)
        END IF

        IF( self_interaction /= 0 ) THEN
          IF ( nat_localisation > 0 .AND. ttprint ) THEN
           CALL localisation( cp( : , nupdwn(1), 1, 1 ), atoms_0, gv, kp, ht_0, desc)
          END IF
        END IF
 

! ---------------------------------------------------------------------------- !
! ...   printout and updating

! ...   report information
        CALL printout(nfi, atoms_0, ekinc, ekcell, ttprint, toptical, ht_0, kp, prn, &
          avgs, avgs_this_run, edft)

        IF(memchk) CALL memstat(11)

! ...   Update variables

        IF ( .NOT. ttdiis ) THEN
          CALL update_wave_functions(cm, c0, cp, wfill)
          IF ( tnosee ) THEN
            CALL update_nose_electrons()
          END IF
        ELSE
          IF( .NOT. tfor ) THEN
            cm = c0
          END IF
        END IF

! ...   if we are going to check convergence, then compute the
! ...   maximum value of the ionic forces

        IF( ttconvchk ) THEN
          maxfion = max_ion_forces( atoms_0 )
          etot = edft%etot
          CALL resort_position( tau, fion, atoms_0, ind_srt, ht_0 )
        END IF


        IF ( doions ) THEN

          IF ( tfor ) THEN
            CALL update_ions(atoms_m, atoms_0, atoms_p)
            IF ( tnosep ) THEN
              CALL update_nose_ions
            END IF
          END IF

          IF ( thdyn ) THEN
            CALL updatecell(ht_m2, ht_m, ht_0, ht_p)
            IF( tnoseh ) THEN
              xnhhm(:,:) = xnhh0(:,:)
              xnhh0(:,:) = xnhhp(:,:)
            END IF
          END IF

        END IF


        IF(memchk) CALL memstat(12)

        frich = frich * greash

! ...   stop the code if either the file .cp_stop is present or the
! ...   cpu time is greater than max_seconds
        tstop =  check_stop_now()

! ...   stop if only the electronic minimization was required
!        IF(.NOT. (tfor .OR. thdyn) .AND. ttdiis ) tstop = .TRUE.

        tconv = .FALSE.
        IF( ttconvchk ) THEN
          derho   = ( erhoold - edft%etot )
          tconv =             ( derho < tconvthrs%derho )
          tconv = tconv .AND. ( ekinc < tconvthrs%ekin )
          tconv = tconv .AND. ( maxfion < tconvthrs%force )
          IF( ionode ) THEN
            IF( ttprint .OR. tconv ) THEN
              WRITE( stdout,fmt= &
                "(/,3X,'MAIN:',10X,'EKINC   (thr)',10X,'DETOT   (thr)',7X,'MAXFORCE   (thr)')" )
              WRITE( stdout,fmt="(3X,'MAIN: ',3(D14.6,1X,D8.1))" ) &
                ekinc, tconvthrs%ekin, derho, tconvthrs%derho, maxfion, tconvthrs%force
              IF( tconv ) THEN
                WRITE( stdout,fmt="(3X,'MAIN: convergence achieved for system relaxation')")
              ELSE
                WRITE( stdout,fmt="(3X,'MAIN: convergence NOT achieved for system relaxation')")
              END IF
            END IF
          END IF
          erhoold = edft%etot
        END IF
        tstop = tstop .OR. tconv

        ttexit = tstop .OR. ( nfi >= nomore )

! ...   write the restart file
        IF( ttsave .OR. ttexit ) THEN
          CALL writefile( nfi, tps, c0, cm, wfill, &
            fi, atoms_0, atoms_m, avgs, taui, cdmi, ibrav, celldm, ht_m2,  &
            ht_m, ht_0, rhoe, desc, vpot, gv, kp)
      
        END IF

        IF( ttexit .AND. .NOT. ttprint ) THEN
          !
          ! When code stop write to stdout quantities regardles of the value of nfi
          ! but do not print if MOD( nfi, iprint ) == 0  
          !
          CALL printout( -nfi, atoms_0, ekinc, ekcell, ttprint, toptical, ht_0, kp, prn, &
            avgs, avgs_this_run, edft)
          !
        END IF

        s8 = cclock()
        timeloop = s8 - s3

        CALL print_time( ttprint, ttexit, timeform, timernl, timerho,  &
                   timevof, timerd, timeorto, timeloop, timing )

        IF( ttexit ) EXIT MAIN_LOOP
! ...   loop back


      END DO MAIN_LOOP                    !  *** END OF MAIN LOOP ***  !

      conv_elec = tconv

      IF(tksout) THEN
        IF ( force_pairing ) THEN 
          CALL ks_states_force_pairing(c0, wfill, ce, wempt, fi, gv, kp, ps, vpot, eigr, fnl)
        ELSE
          CALL ks_states(c0, wfill, ce, wempt, fi, gv, kp, ps, vpot, eigr, fnl)
        END IF
      END IF

      IF(tprnsfac) THEN
        CALL print_sfac(gv, rhoe, desc, sfac)
      END IF

      IF(tneighbo) THEN
        CALL neighbo(atoms_0, neighbo_radius, ht_0)
      END IF


! ... report statistics


      CALL printacc(nfi, rhoe, desc, rhoout, atoms_m, ht_m, nstep_this_run, avgs, avgs_this_run)
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

      CALL deallocate_atoms_type( atoms_0 )
      CALL deallocate_atoms_type( atoms_p )
      CALL deallocate_atoms_type( atoms_m )
      CALL deallocate_ions( )

      CALL deallocate_projector( fnl )
      deallocate(fi)

      DEALLOCATE(vpot, STAT=ierr)
      IF( ierr /= 0 ) CALL errore(' cpmain ', ' deallocating vpot ', ierr)
      DEALLOCATE(rhoe, STAT=ierr)
      IF( ierr /= 0 ) CALL errore(' cpmain ', ' deallocating rhoe ', ierr)
      DEALLOCATE(sfac, STAT=ierr)
      IF( ierr /= 0 ) CALL errore(' cpmain ', ' deallocating sfac ', ierr)
      DEALLOCATE( fnl, STAT=ierr)
      IF( ierr /= 0 ) CALL errore(' cpmain ', ' deallocating fnl ', ierr)

      CALL deallocate_recvecs()
      CALL deallocate_recvecs_indexes()
      CALL deallocate_rvecs(gv)
      CALL deallocate_phfac(eigr)
      CALL deallocate_electrons
      CALL deallocate_elct
      IF(tdipole) THEN
        CALL deallocate_polarization
      END IF
      CALL deallocate_pseudo(ps)
      CALL deallocate_pseudopotential
      CALL deallocate_turbo
      CALL deallocate_diis
      CALL deallocate_stick
      CALL optical_closeup
      CALL deallocate_charge_mix
      CALL deallocate_chi2
      CALL gindex_closeup
      CALL guess_closeup
      CALL ks_states_closeup
      IF( .NOT. lneb ) THEN
        CALL deallocate_ions_base
      END IF

      RETURN
    END SUBROUTINE

!=----------------------------------------------------------------------------=!
  END MODULE main_module
!=----------------------------------------------------------------------------=!
