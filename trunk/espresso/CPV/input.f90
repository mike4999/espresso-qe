
!
! Copyright (C) 2002 CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
      subroutine iosys(nbeg,ndr,ndw,nomore,iprint                       &
     &                ,delt,emass,emaec                                 &
     &                ,tsde,frice,grease,twall                          &
     &                ,tortho,eps,maxit                                   &
     &                ,trane,ampre,tranp,amprp                          &
     &                ,tfor,tsdp,fricp,greasp                           &
     &                ,tcp,tcap,tolp,trhor,trhow,tvlocw                 &
     &                ,tnosep,qnp,tempw                                 &
     &                ,tnosee,qne,ekincw                                &
     &                ,tpre,thdyn,thdiag,twmass,wmass                   &
     &                ,frich,greash,press                               &
     &                ,tnoseh,qnh,temph                                 &
     &                ,celldm, ibrav, tau0, ecutw, ecut, iforce)
!-----------------------------------------------------------------------
!   this subroutine reads control variables from standard input (unit 5)
!     ------------------------------------------------------------------
      use control_flags, only: iprsta
      use constants, only: pi, scmass, factem
      use parameters, only: nsx, natx
      use ions_base, only : nat, nsp, na, pmass, rcmax, ipp ! ipp TEMP
      use elct, only: f, nel, nspin, nupdwn, iupdwn, n, nx, ispin
      use grid_dimensions,  only: nr1 ,nr2 ,nr3
      use cell_base, only: omega, alat, a1, a2, a3
      use smallbox_grid_dimensions, only: nr1b,nr2b,nr3b 
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s
      use pres_mod, only: agg, sgg, e0gg
      use psfiles, only: psfile, pseudo_dir
      use io_global, only: ionode
      use mp, only: mp_bcast

      !
      implicit none
      !
      ! output variables
      !
      real(kind=8) ampre, delt, ekincw, emass, emaec, eps,       &
     &       frice, fricp, frich, grease, greasp, greash,        &
     &       press, qnp, qne, qnh, tempw, temph, tolp, wmass,    &
             amprp(nsx), celldm(6), tau0(3,natx,nsx), ecut, ecutw
      integer :: nbeg, ndr,ndw,nomore, iprint, maxit, iforce(3,natx,nsx)

      logical :: trane, tsde, twall, tortho, tnosee, tfor, tsdp, tcp, &
           tcap, tnosep, trhor, trhow, tvlocw, tpre, thdyn, thdiag,   &
           twmass, tnoseh, tranp(nsx)
      !
      ! local variables
      !
      real(kind=8), parameter:: terahertz = 2.418D-5
      real(kind=8) :: taus(3,natx,nsx)
      character (len=30) :: atomic_positions
      integer :: unit = 5, ionode_id = 0, i, ia, ios, is, iss, in
      real(kind=8) :: ocp, fsum
      !
      ! CONTROL namelist

      character(len=256) :: outdir, prefix
      logical :: tstress, tprnfor
      real (kind=8) :: max_seconds, dt
      real (kind=8) :: ekin_conv_thr, etot_conv_thr, forc_conv_thr
      character(len=80) :: restart_mode, disk_io, calculation, verbosity, title
      integer :: isave, nstep
      NAMELIST / control / title, calculation, verbosity, &
           restart_mode, nstep, iprint, isave, tstress, tprnfor, &
           dt, ndr, ndw, outdir, prefix, max_seconds, ekin_conv_thr,&
           etot_conv_thr, forc_conv_thr, pseudo_dir, disk_io

      ! SYSTEM namelist

      character(len=80) :: occupations, xc_type
      integer :: ibrav, ntyp, nbnd, nelec, ngauss, nelup, neldw
      real (kind=8) :: ecutwfc, ecutrho
      logical :: nosym, lda_plus_U
      real (kind=8) :: degauss, ecfixed, qcutz, q2sigma, &
           starting_magnetization(nsx), Hubbard_U(nsx), Hubbard_alpha(nsx)
      NAMELIST / system / ibrav, celldm, nat, ntyp, nbnd, nelec, &
           ecutwfc, ecutrho, nr1, nr2, nr3, nr1s, nr2s, nr3s, &
           nr1b, nr2b, nr3b, nosym, starting_magnetization, &
           occupations, degauss, ngauss, &
           nelup, neldw, nspin, ecfixed, qcutz, q2sigma, xc_type, &
           lda_plus_U, Hubbard_U, Hubbard_alpha

      ! ELECTRONS namelist
  
      character(len=80) :: orthogonalization, &
           electron_dynamics, electron_velocities, electron_temperature
      integer :: electron_maxstep
      real(kind=8) :: emass_cutoff, electron_damping, fnosee, &
           ortho_eps, ortho_max
      integer :: empty_states_nbnd, empty_states_maxstep
      real(kind=8) :: empty_states_delt, empty_states_emass, empty_states_ethr
      integer :: diis_size, diis_nreset, diis_maxstep
      logical :: diis_rot, diis_chguess
      real(kind=8) :: diis_hcut, diis_wthr, diis_delt
      real(kind=8) :: diis_fthr, diis_temp, diis_achmix, diis_g0chmix
      integer :: diis_nchmix, diis_nrot(3)
      real(kind=8) :: diis_g1chmix, diis_rothr(3), diis_ethr
      character(len=80) :: mixing_mode
      real (kind=8) :: mixing_beta
      integer :: mixing_ndim, mixing_fixed_ns
      real (kind=8) :: conv_thr
      character(len=80) :: diagonalization
      integer :: diago_cg_maxiter, diago_david_ndim, diago_diis_buff, &
           diago_diis_start 
      logical :: diago_diis_keep
      character(len=14) :: input_pot, startingwfc

  NAMELIST / electrons / emass, emass_cutoff, orthogonalization, &
       electron_maxstep, ortho_eps, ortho_max, electron_dynamics, &
       electron_damping, electron_velocities, electron_temperature,&
       ekincw, fnosee, ampre, grease, twall, &
       empty_states_nbnd, empty_states_maxstep, empty_states_delt, &
       empty_states_emass, empty_states_ethr, &
       diis_size, diis_nreset, diis_hcut, diis_wthr, diis_delt, &
       diis_maxstep, diis_rot, diis_fthr, diis_temp, diis_achmix, &
       diis_g0chmix, diis_g1chmix, diis_nchmix, diis_nrot, diis_rothr, &
       diis_ethr, diis_chguess, &
       mixing_mode, mixing_beta, mixing_ndim, mixing_fixed_ns, &
       diago_cg_maxiter, diago_david_ndim, diago_diis_buff, &
       diago_diis_start, diago_diis_keep, diagonalization, &
       input_pot, startingwfc, conv_thr

      ! IONS namelist

      character(len=80) :: ion_dynamics, ion_positions, ion_velocities, &
           ion_temperature, potential_extrapolation
      integer :: ion_nstepe
      integer :: ion_maxstep
      real(kind=8) :: ion_radius(nsx), ion_damping, fnosep
      real(kind=8) :: upscale

      NAMELIST / ions / ion_dynamics, ion_radius, ion_damping, ion_positions, &
           ion_velocities, ion_temperature, &
           tempw, fnosep, tranp, amprp, greasp, tolp, &
          ion_nstepe, ion_maxstep, upscale, potential_extrapolation

      ! CELL namelist

      character(len=80) :: cell_parameters, cell_dynamics, cell_velocities, &
          cell_temperature, cell_dofree
      real(kind=8) :: cell_damping, fnoseh, cell_factor

      NAMELIST /cell / cell_parameters, cell_dynamics, cell_velocities, press,&
           wmass, cell_temperature, temph, fnoseh, cell_dofree, greash, &
           cell_factor

      ! PHONON namelist
      
      integer :: modenum
      real(kind=8) :: xqq(3)
      NAMELIST / phonon / modenum, xqq

      ! ...   Variables initialization for CONTROL
      !
      title = ' '
      calculation = 'cp'
      verbosity = 'default'
      max_seconds  = 1.d+6
      restart_mode = 'restart' 
      nstep  = 10
      iprint = 10 
      isave  = 100
      tstress = .FALSE.
      tprnfor = .FALSE.
      dt    = 1.0d0
      ndr = 50
      ndw = 50
      outdir = './'       ! use the path specified as Outdir and
      prefix = 'cpr'      !     the filename prefix to store the output
      ekin_conv_thr = 1.d-6
      etot_conv_thr = 1.d-5
      forc_conv_thr = 1.d-4
      electron_maxstep = 100
      disk_io = 'default'
      pseudo_dir='./'

! ...   Variables initialization for SYSTEM

      ibrav  =-1
      celldm = (/ 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0 /)
      nat    = 0
      ntyp   = 0
      nbnd   = 0
      nelec  = 0
      ecutwfc= 0.d0
      ecutrho= 0.d0
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
      degauss = 0.d0
      ngauss  = 0
      nelup = 0
      neldw = 0
      nspin = 1
      nosym = .TRUE.
      ecfixed = 0.d0
      qcutz   = 0.d0
      q2sigma = 0.01d0
      ! set to a nonzero value so that the modified kinetic functional
      ! is by default disabled and does not yield floating-point error
      xc_type = 'PZ'
      lda_plus_U = .false.
      Hubbard_U(:) = 0.d0
      Hubbard_alpha(:) = 0.d0

! ...   Variables initialization for ELECTRONS
!
      electron_maxstep = 100
      emass = 400.d0
      emass_cutoff = 2.5d0
      orthogonalization = 'ortho'
      ortho_eps = 1.d-8
      ortho_max = 20
      electron_dynamics = 'none'
      ! ( 'sd' | 'cg' | 'damp' | 'verlet' | 'none' | 'diis' )
      electron_damping = 0.1d0
      electron_velocities = 'default'
      ! ( 'zero' | 'default' )
      electron_temperature = 'not_controlled' 
      ! ( 'nose' | 'not_controlled' | 'rescaling')
      ekincw = 0.001d0
      fnosee = 1.0d0
      trane  = .FALSE.
      ampre  = 0.0d0
      grease = 1.0d0
      twall  = .FALSE.
      empty_states_nbnd = 0
      empty_states_maxstep = 100
      empty_states_delt = 0.0d0
      empty_states_emass = 0.0d0
      empty_states_ethr = 0.0d0
      diis_size = 4
      diis_nreset = 3
      diis_hcut = 1.0d0
      diis_wthr = 0.0d0
      diis_delt = 0.0d0
      diis_maxstep = 0
      diis_rot = .FALSE.
      diis_fthr = 0.0d0 
      diis_temp = 0.0d0
      diis_achmix = 0.0d0
      diis_g0chmix = 0.0d0
      diis_g1chmix = 0.0d0
      diis_nchmix = 3
      diis_nrot = 3
      diis_rothr  = 0.0d0
      diis_ethr   = 0.0d0
      diis_chguess = .FALSE.
      mixing_mode ='plain'
      mixing_fixed_ns = 0
      mixing_beta = 0.7
      mixing_ndim = 8

      diago_cg_maxiter = 20
      diago_david_ndim  =4
      diago_diis_buff = 200
      diago_diis_keep = .false.
      diago_diis_start= 0
      startingwfc = 'random'
      input_pot = ' '
      conv_thr = 1.d-6
      trhor =.false.

! ...   Variables initialization for IONS
!
      ion_dynamics = 'none'  ! ( 'sd' | 'cg' | 'damp' | 'verlet' | 'none' )
      ion_radius = 0.5d0
      ion_damping = 0.1
      ion_positions = 'default' ! ( 'default' | 'from_input' )
      ion_velocities = 'default'
      ! ( 'zero' | 'default' | 'random' | 'from_input' )
      ion_temperature = 'not_controlled'
      ! ( 'nose' | 'not_controlled' | 'rescaling' )
      tempw = 300.0d0
      fnosep = 1.0d0
      tranp(:) = .FALSE.
      amprp(:) = 0.0d0
      greasp = 1.0d0
      tolp = 100.d0
      ion_nstepe = 1
      ion_maxstep = 100
      upscale = 10
      potential_extrapolation='default'

! ...   Variables initialization for CELL
!
      cell_parameters = 'default' 
      cell_dynamics = 'none'     
      ! ( 'sd' | 'md' | 'damp' | 'md-w' | 'damp-w' | 'none' )
      cell_velocities = 'default' ! ( 'zero' | 'default' )
      press = 0.0d0
      wmass = 0.0d0
      cell_temperature = 'not_controlled' 
      ! ( 'nose' | 'not_controlled' | 'rescaling' )
      temph = 0.0d0
      fnoseh = 1.0d0
      greash = 1.0d0
      cell_dofree = 'all' 
      ! ('all'* | 'volume' | 'x' | 'y' | 'z' | 'xy' | 'xz' | 'yz' | 'xyz' )
      !
      ! ...   Variables initialization for PHONON
      !
      modenum = 0
      xqq = 0.d0

      if ( ionode )  then

     ios = 0
     READ (unit, control, iostat = ios ) 
     if (ios /= 0) call errore ('reading','namelist &control',1)
     !
     ! reset default values for *_dynamics according to definition 
     ! of calculation in &control
     !
      SELECT CASE ( TRIM(calculation) ) 
      CASE ('scf')
         electron_dynamics = 'damp'
      CASE ('relax')
         electron_dynamics = 'damp'
         ion_dynamics = 'damp'
      CASE ('cp')
         electron_dynamics = 'verlet'
         ion_dynamics = 'verlet'
      CASE ('vc-relax')
         electron_dynamics = 'damp'
         ion_dynamics = 'damp'
         cell_dynamics = 'damp-pr'
      CASE ('vc-cp')
         electron_dynamics = 'verlet'
         ion_dynamics = 'verlet'
         cell_dynamics = 'pr'
      CASE ('nscf')
         occupations = 'bogus'
         electron_dynamics = 'damp'
         trhor =.true.
      CASE DEFAULT
         CALL errore(' iosys ',' calculation not implemented', 1 )
      END SELECT
     !
     READ (unit, system, iostat = ios ) 
     if (ios /= 0) call errore ('reading','namelist &system',2)
     READ (unit, electrons, iostat = ios ) 
     if (ios /= 0) call errore ('reading','namelist &electrons',3)
     READ (unit, ions, iostat = ios ) 
     if (ios /= 0) call errore ('reading','namelist &ions',4)
     if ( TRIM(calculation) == 'vc-cp' .or. &
          TRIM(calculation) == 'vc-relax'  ) then
        READ (unit, cell, iostat = ios ) 
        if (ios /= 0) call errore ('reading','namelist &cell',5)
     end if

     end if
!
! ...   CONTROL Variables Broadcast
!
      CALL mp_bcast( title, ionode_id )
      CALL mp_bcast( calculation, ionode_id )
      CALL mp_bcast( verbosity, ionode_id )
      CALL mp_bcast( restart_mode, ionode_id )
      CALL mp_bcast( nstep, ionode_id )
      CALL mp_bcast( iprint, ionode_id )
      CALL mp_bcast( isave, ionode_id )
      CALL mp_bcast( tstress, ionode_id )
      CALL mp_bcast( tprnfor, ionode_id )
      CALL mp_bcast( dt, ionode_id )
      CALL mp_bcast( ndr, ionode_id )
      CALL mp_bcast( ndw, ionode_id )
      CALL mp_bcast( outdir, ionode_id )
      CALL mp_bcast( prefix, ionode_id )
      CALL mp_bcast( max_seconds, ionode_id )
      CALL mp_bcast( ekin_conv_thr, ionode_id )
      CALL mp_bcast( etot_conv_thr, ionode_id )
      CALL mp_bcast( forc_conv_thr, ionode_id )
      CALL mp_bcast( pseudo_dir, ionode_id )
      CALL mp_bcast( disk_io, ionode_id )
!
! ...   SYSTEM Variables Broadcast
!
      CALL mp_bcast( ibrav, ionode_id  )
      CALL mp_bcast( celldm, ionode_id  )
      CALL mp_bcast( nat, ionode_id  )
      CALL mp_bcast( ntyp, ionode_id  )
      CALL mp_bcast( nbnd, ionode_id  )
      CALL mp_bcast( nelec, ionode_id  )
      CALL mp_bcast( ecutwfc, ionode_id  )
      CALL mp_bcast( ecutrho, ionode_id  )
      CALL mp_bcast( nr1, ionode_id  )
      CALL mp_bcast( nr2, ionode_id  )
      CALL mp_bcast( nr3, ionode_id  )
      CALL mp_bcast( nr1s, ionode_id  )
      CALL mp_bcast( nr2s, ionode_id  )
      CALL mp_bcast( nr3s, ionode_id  )
      CALL mp_bcast( nr1b, ionode_id  )
      CALL mp_bcast( nr2b, ionode_id  )
      CALL mp_bcast( nr3b, ionode_id  )
      CALL mp_bcast( occupations, ionode_id  )
      CALL mp_bcast( degauss, ionode_id  )
      CALL mp_bcast( ngauss, ionode_id )
      CALL mp_bcast( nelup, ionode_id )
      CALL mp_bcast( neldw, ionode_id )
      CALL mp_bcast( nspin, ionode_id )
      CALL mp_bcast( nosym, ionode_id )
      CALL mp_bcast( ecfixed, ionode_id )
      CALL mp_bcast( qcutz, ionode_id )
      CALL mp_bcast( q2sigma, ionode_id )
      CALL mp_bcast( xc_type, ionode_id )
      CALL mp_bcast( lda_plus_U, ionode_id )
      CALL mp_bcast( Hubbard_U, ionode_id )
      CALL mp_bcast( Hubbard_alpha, ionode_id )

! ...   ELECTRONS Variables Broadcast
!
      CALL mp_bcast( emass, ionode_id )
      CALL mp_bcast( emass_cutoff, ionode_id )
      CALL mp_bcast( orthogonalization, ionode_id )
      CALL mp_bcast( electron_maxstep, ionode_id )
      CALL mp_bcast( ortho_eps, ionode_id )
      CALL mp_bcast( ortho_max, ionode_id )
      CALL mp_bcast( electron_dynamics, ionode_id )
      CALL mp_bcast( electron_damping, ionode_id )
      CALL mp_bcast( electron_velocities, ionode_id )
      CALL mp_bcast( electron_temperature, ionode_id )
      CALL mp_bcast( ekincw, ionode_id )
      CALL mp_bcast( fnosee, ionode_id )
      CALL mp_bcast( ampre, ionode_id )
      CALL mp_bcast( grease, ionode_id )
      CALL mp_bcast( twall, ionode_id )
      CALL mp_bcast( trhor, ionode_id )
      CALL mp_bcast( empty_states_nbnd, ionode_id )
      CALL mp_bcast( empty_states_maxstep, ionode_id )
      CALL mp_bcast( empty_states_delt, ionode_id )
      CALL mp_bcast( empty_states_emass, ionode_id )
      CALL mp_bcast( empty_states_ethr, ionode_id )
      CALL mp_bcast( diis_size, ionode_id )
      CALL mp_bcast( diis_nreset, ionode_id )
      CALL mp_bcast( diis_hcut, ionode_id )
      CALL mp_bcast( diis_wthr, ionode_id )
      CALL mp_bcast( diis_delt, ionode_id )
      CALL mp_bcast( diis_maxstep, ionode_id )
      CALL mp_bcast( diis_rot, ionode_id )
      CALL mp_bcast( diis_fthr, ionode_id )
      CALL mp_bcast( diis_temp, ionode_id )
      CALL mp_bcast( diis_achmix, ionode_id )
      CALL mp_bcast( diis_g0chmix, ionode_id )
      CALL mp_bcast( diis_g1chmix, ionode_id )
      CALL mp_bcast( diis_nchmix, ionode_id )
      CALL mp_bcast( diis_nrot, ionode_id )
      CALL mp_bcast( diis_rothr, ionode_id )
      CALL mp_bcast( diis_ethr, ionode_id )
      CALL mp_bcast( diis_chguess, ionode_id )
      CALL mp_bcast( mixing_mode, ionode_id )
      CALL mp_bcast( mixing_beta, ionode_id )
      CALL mp_bcast( mixing_ndim, ionode_id )
      CALL mp_bcast( mixing_fixed_ns, ionode_id )
      CALL mp_bcast( diagonalization, ionode_id )
      CALL mp_bcast( diago_cg_maxiter, ionode_id )
      CALL mp_bcast( diago_david_ndim, ionode_id )
      CALL mp_bcast( diago_diis_buff, ionode_id )
      CALL mp_bcast( diago_diis_keep, ionode_id )
      CALL mp_bcast( diago_diis_start,ionode_id )
      CALL mp_bcast( startingwfc, ionode_id )
      CALL mp_bcast( input_pot, ionode_id )
      CALL mp_bcast( conv_thr, ionode_id )

! ...   IONS Variables Broadcast
!
      CALL mp_bcast( ion_dynamics, ionode_id )
      CALL mp_bcast( ion_radius, ionode_id )
      CALL mp_bcast( ion_damping, ionode_id )
      CALL mp_bcast( ion_positions, ionode_id )
      CALL mp_bcast( ion_velocities, ionode_id )
      CALL mp_bcast( ion_temperature, ionode_id )
      CALL mp_bcast( tempw, ionode_id )
      CALL mp_bcast( fnosep, ionode_id )
      CALL mp_bcast( tranp, ionode_id )
      CALL mp_bcast( amprp, ionode_id )
      CALL mp_bcast( greasp, ionode_id )
      CALL mp_bcast( tolp, ionode_id )
      CALL mp_bcast( ion_nstepe, ionode_id )
      CALL mp_bcast( ion_maxstep, ionode_id )
      CALL mp_bcast( upscale, ionode_id )
      CALL mp_bcast( potential_extrapolation, ionode_id )

! ...   CELL Variables Broadcast
!
      CALL mp_bcast( cell_parameters, ionode_id )
      CALL mp_bcast( cell_dynamics, ionode_id )
      CALL mp_bcast( cell_velocities, ionode_id )
      CALL mp_bcast( cell_dofree, ionode_id )
      CALL mp_bcast( press, ionode_id )
      CALL mp_bcast( wmass, ionode_id )
      CALL mp_bcast( cell_temperature, ionode_id )
      CALL mp_bcast( temph, ionode_id )
      CALL mp_bcast( fnoseh, ionode_id )
      CALL mp_bcast( cell_factor, ionode_id )

      ! ...   PHONON Variables Broadcast
      !
      CALL mp_bcast( modenum, ionode_id )
      CALL mp_bcast( xqq, ionode_id )
      !

! translate from input to internals of CP, various checks


      ! ...   Set the number of species

      IF( ntyp < 1 .OR. ntyp > nsx ) THEN
         CALL errore(' iosys ',' ntyp out of range ', ntyp )
      END IF
      nsp = ntyp

      ! ...   IBRAV and CELLDM

      IF( ibrav /= 0 .and. celldm(1) == 0.d0 ) THEN
         CALL errore(' iosys ',' invalid value in celldm ', 1 )
      END IF
      IF( ibrav < 0 .OR. ibrav > 14 ) THEN
         CALL errore(' iosys ',' ibrav out of range ', 1 )
      END IF

      ! ...   Set Values for bands          

      IF( nbnd < 1 ) THEN
         CALL errore(' iosys ',' nbnd less than 1 ', nbnd )
      END IF
      IF( nspin < 1 .OR. nspin > 2 ) THEN
         CALL errore(' iosys ',' nspin out of range ', nspin )
      END IF
      n   = nbnd*nspin

      ! ...   Set Values for the cutoff

      ecutw = ecutwfc
      IF( ecutwfc <= 0.d0 ) THEN
         CALL errore(' iosys ',' invalid ecutwfc ', INT(ecutwfc) )
      END IF

      if (ecutrho <= 0.d0) ecutrho = 4.d0*ecutwfc
      ecut = ecutrho

      ! ...   nbeg

      SELECT CASE ( restart_mode ) 
         CASE ('from_scratch')
            nbeg = -2
            if (ion_positions == 'from_input') nbeg = -1
            nomore = nstep
            trane = (startingwfc .eq. 'random')
            if (ampre.eq.0.d0) ampre = 0.02
         CASE ('reset_counters')
            nbeg = 0
            nomore = nstep
         CASE ('upto')
            nbeg = 1
            nomore = nstep
         CASE ('restart')
            nbeg = 1
            nomore = nstep
         CASE DEFAULT
            CALL errore(' iosys ',' unknown restart_mode '//trim(restart_mode), 1 )
      END SELECT

      ! ...   TORTHO

      SELECT CASE ( orthogonalization ) 
      CASE ('Gram-Schmidt')
         tortho = .FALSE.
      CASE ('ortho')
         tortho = .TRUE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown orthogonalization '//&
              trim(orthogonalization), 1 )
      END SELECT

      SELECT CASE ( electron_velocities ) 
      CASE ('default')
         continue
      CASE ('zero')
         print '("Warning: electron_velocities keyword has no effect")'
      CASE DEFAULT
         CALL errore(' iosys ',' electron_velocities='// &
              trim(electron_velocities)//' not implemented', 1 )
      END SELECT

      ! ...   TSDE

      SELECT CASE ( electron_dynamics ) 
      CASE ('sd')
         tsde = .TRUE.
         frice= 0.d0
      CASE ('verlet')
         tsde = .FALSE.
         frice= 0.d0
      CASE ('damp')
         tsde = .FALSE.
         frice= electron_damping
      CASE ('none')
         tsde = .FALSE.
         frice= 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown electron_dynamics '//&
              trim(electron_dynamics),1)
      END SELECT

      ! Ion velocities

      SELECT CASE ( ion_velocities ) 
      CASE ('default')
         tcap = .false.
      CASE ('random')
         tcap = .true.
      CASE ('zero')
         print '("Warning: ion_velocities = zero not yet implemented")'
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_velocities '//trim(ion_velocities),1)
      END SELECT

      ! ...   TFOR TSDP

      SELECT CASE ( ion_dynamics ) 
      CASE ('sd')
         tsdp = .TRUE.
         tfor = .TRUE.
         fricp= 0.d0
      CASE ('verlet')
         tsdp = .FALSE.
         tfor = .TRUE.
         fricp= 0.d0
      CASE ('damp')
         tsdp = .FALSE.
         tfor = .TRUE.
         fricp= ion_damping
      CASE ('none')
         tsdp = .FALSE.
         tfor = .FALSE.
         fricp= 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_dynamics '//trim(ion_dynamics), 1 )
      END SELECT

      !

      SELECT CASE ( cell_velocities ) 
      CASE ('default')
         continue
      CASE ('zero')
         print '("Warning: cell_velocities = zero not yet implemented")'
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_velocities '//trim(cell_velocities),1)
      END SELECT
      
      !
      
      SELECT CASE ( cell_dynamics ) 
      CASE ('sd')
         tpre = .TRUE.
         thdyn= .TRUE.
         frich= 0.d0
      CASE ('pr')
         tpre = .TRUE.
         thdyn= .TRUE.
         frich= 0.d0
      CASE ('damp-pr')
         tpre  = .TRUE.
         thdyn= .TRUE.
         frich = cell_damping
      CASE ('none')
         tpre = .FALSE.
         thdyn= .FALSE.
         frich= 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_dynamics '//trim(cell_dynamics), 1 )
      END SELECT

      !

      SELECT CASE ( electron_temperature ) 
         !         temperature control of electrons via Nose' thermostat
         !         EKINW (REAL(DBL))  average kinetic energy (in atomic units)
         !         FNOSEE (REAL(DBL))  frequency (in terahertz)
      CASE ('nose')
         tnosee = .TRUE.
      CASE ('not_controlled')
         tnosee = .FALSE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown electron_temperature '//&
              trim(electron_temperature), 1 )
      END SELECT

      !

      SELECT CASE ( ion_temperature ) 
         !         temperature control of ions via Nose' thermostat
         !         TEMPW (REAL(DBL))  frequency (in which units?)
         !         FNOSEP (REAL(DBL))  temperature (in which units?)
      CASE ('nose')
         tnosep = .TRUE.
         tcp = .false.
      CASE ('not_controlled')
         tnosep = .FALSE.
         tcp = .false.
      CASE ('rescaling' )
         tnosep = .FALSE.
         tcp = .true.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_temperature '//&
              trim(ion_temperature), 1 )
      END SELECT

      SELECT CASE ( cell_temperature ) 
         !         cell temperature control of ions via Nose' thermostat
         !         FNOSEH (REAL(DBL))  frequency (in which units?)
         !         TEMPH (REAL(DBL))  temperature (in which units?)
      CASE ('nose')
         tnoseh = .TRUE.
      CASE ('not_controlled')
         tnoseh = .FALSE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_temperature '//&
              trim(cell_temperature), 1 )
      END SELECT

      SELECT CASE ( cell_dofree )
      CASE ('all')
         thdiag =.false.
      CASE ('xyz')
         thdiag =.true.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_dofree '//trim(cell_dofree), 1 )
      END SELECT

      ! ...  radii, masses

      DO is = 1, nsp
         rcmax(is) = ion_radius(is)
         IF( ion_radius(is) <= 0.d0 ) THEN
            CALL errore(' iosys ',' invalid  ion_radius ', is) 
         END IF
      END DO

      !
      ! compatibility between FPMD and CP90
      !
      iprint = isave 
      if (trim(verbosity)=='high') then
         iprsta = 3
      else
         iprsta = 1
      end if
      delt   = dt
      emaec  = emass_cutoff
      agg = qcutz
      sgg = q2sigma
      e0gg= ecfixed
      eps = ortho_eps
      maxit = ortho_max
      ! wmass is calculated in "init"
      twmass = wmass.eq.0.d0
      if (tstress) tpre=.true.
      trhow = trim(disk_io).eq.'high'
      tvlocw=.false. ! temporaneo
      !
      qne = 4.d0*ekincw/(fnosee*(2.d0*pi)*terahertz)**2
      qnp = 2.d0*(3*nat)*tempw/factem/(fnosep*(2.d0*pi)*terahertz)**2
      qnh = 2.d0*(3*3  )*temph/factem/(fnoseh*(2.d0*pi)*terahertz)**2

      ! read following cards

      call read_cards (ibrav, iforce, tau0, atomic_positions)
      !
      ! set up atomic positions and crystal lattice
      !
      if ( ibrav == 0 ) then
         if (celldm (1) == 0.d0) then
            celldm (1) = sqrt(a1(1)**2+a1(2)**2+a1(3)**2)
            a1(:) = a1(:) / celldm(1)
            a2(:) = a2(:) / celldm(1)
            a3(:) = a3(:) / celldm(1)
         end if
      else
         call latgen(ibrav,celldm,a1,a2,a3,omega)
      end if
      alat = celldm(1)
      !
      SELECT CASE ( atomic_positions ) 
         !
         !  convert input atomic positions to internally used format:
         !  tau0 in atomic units
         !
         CASE ('alat')
            !
            !  input atomic positions are divided by a0
            !
            tau0 = tau0*alat
         CASE ('bohr')
            !
            !  input atomic positions are in a.u.: do nothing
            !
            continue
         CASE ('crystal')
            !
            !  input atomic positions are in crystal axis ("scaled"):
            !
            taus = tau0
            do is=1, nsp
               do ia=1,na(is)
                  do i=1,3
                     tau0(i,ia,is) = a1(i)*taus(1,ia,is) &
                                   + a2(i)*taus(2,ia,is) &
                                   + a3(i)*taus(3,ia,is)
                  end do
               end do
            end do
         CASE ('angstrom')
            !
            !  atomic positions in A
            !
            tau0 = tau0/0.529177
         CASE DEFAULT
            CALL errore(' iosys ',' atomic_positions='//trim(atomic_positions)// &
                 ' not implemented ', 1 )
      END SELECT
      !
      !  set occupancies
      !
      SELECT CASE ( TRIM(occupations) ) 
      CASE ('bogus')
         !
         ! empty-states calculation: occupancies have a (bogus) finite value
         !
         if (allocated(f)) CALL errore(' iosys ',&
              ' do not specify occupations for empty-states calculation', 1 )
         allocate(f(n))
         !
         ! bogus to ensure \sum_i f_i = Nelec  (nelec is integer)
         !
         f(:) = dfloat(nelec)/n         
         if (nspin == 2) then
            !
            ! bogus to ensure Nelec = Nup + Ndw
            !
            nelup = (nelec+1)/2 
            neldw = nelec/2 
         end if
      CASE ('from_input')
         !
         ! occupancies have been read from input
         !
         if (.not.allocated(f)) CALL errore(' iosys ',&
              ' occupations are not there! ', 1 )
         if (nelec == 0) nelec = SUM (f(1:n))
         if (nspin == 2 .and. nelup == 0) nelup = SUM (f(1:nbnd))
         if (nspin == 2 .and. neldw == 0) neldw = SUM (f(nbnd+1:2*nbnd))
      CASE ('fixed')
         if (allocated(f)) CALL errore(' iosys ',&
              ' occupations were specified twice', 1 )
      CASE DEFAULT
         CALL errore(' iosys ',' occupation method not implemented', 1 )
      END SELECT
      !
      IF( nelec < 1 ) THEN
         CALL errore(' iosys ',' nelec less than 1 ', nelec )
      END IF
      iupdwn(1) = 1
      if(nspin == 1) then
         nel(1) = nelec
         nel(2) = 0
         nupdwn(1)=n
      else
         IF ( nelup + neldw .ne. nelec  ) THEN
            CALL errore(' iosys ',' wrong # of up and down spin', 1 )
         END IF
         nel(1) = nelup
         nel(2) = neldw
         nupdwn(1)=nbnd
         nupdwn(2)=nbnd
         iupdwn(2)=nbnd+1
      end if

!     =========================================================
!     ==== species, states, electrons, occupations, odd/ev ====
!     =========================================================
!
!     important: if n is odd then nx=n+1 and c(*,n+1)=0.
!
      if(mod(n,2).ne.0) then
         nx=n+1
      else
         nx=n
      end if

! TEMP: this should be moved to where occupations are read/set
!
      if (.not.allocated(f)) then
         allocate(f(nx))
! ocp = 2 for spinless systems, ocp = 1 for spin-polarized systems
         ocp = 2.d0/nspin
! default filling: attribute ocp electrons to each states
!                  until the good number of electrons is reached
         do iss=1,nspin
            fsum = 0.d0
            do in=iupdwn(iss),iupdwn(iss)-1+nupdwn(iss)
               if (fsum+ocp < nel(iss)+0.0001) then
                  f(in)=ocp
               else
                  f(in)=max(nel(iss)-fsum,0.d0)
               end if
               fsum=fsum + f(in)
            end do
         end do
      end if

      allocate(ispin(nx))
      do iss=1,nspin
         do in=iupdwn(iss),iupdwn(iss)-1+nupdwn(iss)
            ispin(in)=iss
         end do
      end do

!     =========================================================
!     ==== other control parameters
!     =========================================================
      fsum = SUM(f(1:n))
      write(6,*) ' init1:  fsum = ',fsum
      if(nspin == 1 .and. abs(fsum-float(nel(1))) > 0.001 .or.     &
         nspin == 2 .and. abs(fsum-float(nel(1)+nel(2))) > 0.001 ) &
         call errore(' iosys ',' sum f(i) != number of electrons',   &
         nel(1)+nel(2))

!
!     --------------------------------------------------------
!     print out heading
!
      write(6,400) 
      write(6,410) 
      write(6,420) 
      write(6,410) 
      write(6,400) 
      write(6,500) nbeg,nomore,iprint,ndr,ndw
      write(6,505) delt
      write(6,510) emass,emaec
!
      if(tortho) then
         write(6,511) eps,maxit
      else
         write(6,512)
      endif
!
      if(tsde) then
         write(6,513)
      else
         if (tnosee) frice = 0.
         write(6,509)
         write(6,514) frice,grease
      endif
!
      if(trhor)then
         write(6,720)
      endif
!
      if(.not.trhor.and.trhow)then
         write(6,721)
      endif
!
      if(tvlocw)then
         write(6,722)
      endif
!
      if(trane) then
         write(6,515) ampre
      endif
      write(6,516)
      do is =1, nsp
         if(tranp(is)) write(6,517) is, amprp(is)
      end do
!
      if(tfor) then
         if(tnosep) fricp=0.
         write(6,520)
         if(tsdp)then
            write(6,521)
         else
            write(6,522) fricp,greasp
         endif
      else
         write(6,518)
      endif
!
      if(tfor) then
         if((tcp.or.tcap.or.tnosep).and.tsdp) then
            call errore(' main',' t contr. for ions when tsdp=.t.',0)
         endif
         if(.not.tcp.and..not.tcap.and..not.tnosep) then
            write(6,550)
         else if(tcp.and.tcap) then
            call errore(' main',' tcp and tcap both true',0)
         else if(tcp.and.tnosep) then
            call errore(' main',' tcp and tnosep both true',0)
         else if(tcap.and.tnosep) then
            call errore(' main',' tcap and tnosep both true',0)
         else if(tcp) then
            write(6,555) tempw,tolp
         else if(tcap) then
            write(6,560) tempw,tolp
         else if(tnosep) then
            write(6,562) tempw,qnp
         end if
         if(tnosee) then
            write(6,566) ekincw,qne
         end if
      end if
!
      if(tpre) then
         write(6,600)
         if(thdyn) then
            if(thdiag) write(6,608)
            if(tnoseh) then
               frich=0.
               write(6,604) temph,qnh,press
            else
               write(6,602) frich,greash,press
            endif
         else
            write(6,606)
         endif
      endif
      if ( agg .ne. 0.d0) then
            write(6,650) agg, sgg, e0gg
      end if
      write(6,700) iprsta
!     
 400  format('************************************',                    &
     &     '************************************')
 410  format('****                                ',                    &
     &       '                                ****')
 420  format('****  ab-initio molecular dynamics: ',                    &
     &       ' car-parrinello vanderbilt bhs  ****')
 500  format(//                                                         &
     &       ' nbeg=',i3,' nomore=',i7,3x,' iprint=',i4,/               &
     &       ' reads from',i3,' writes on',i3)
 505  format(' time step = ',f9.4/)
 510  format(' parameters for electron dynamics:'/                      &
     &       ' emass= ',f10.2,2x,'emaec= ',f10.2,'ry')
 511  format(' orthog. with lagrange multipliers: eps=',e10.2,          &
     &         ' maxit=',i3)
 512  format(' orthog. with gram-schmidt')
 513  format(' electron dynamics with steepest descent')
 509  format(' verlet algorithm for electron dynamics')
 514  format(' with friction frice = ',f7.4,' , grease = ',f7.4)
 720  format(' charge density is read from unit 47',/)
 721  format(' charge density is written in unit 47',/)
 722  format(' local potential is written in unit 46',/)
 515  format(' initial random displacement of el. coordinates with ',   &
     &       ' amplitude=',f10.6,/                                      &
     &       ' trane not to be used with mass preconditioning')
 516  format(/)
 517  format(' initial random displacement of ionic coord. for species ',&
     &       i4,' : amplitude=',f10.6)
 518  format(' ions are not allowed to move'/)
 520  format(' ions are allowed to move')
 521  format(' ion dynamics with steepest descent')
 522  format(' ion dynamics with fricp = ',f7.4,' and greasp = ',f7.4)
 550  format(' ion dynamics: the temperature is not controlled'//)
 555  format(' ion dynamics with rescaling of velocities:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 560  format(' ion dynamics with canonical temp. control:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 562  format(' ion dynamics with nose` temp. control:'/                 &
     &       ' temperature required=',f10.5,'(kelvin)',' nose` mass = ',&
     &       f10.3//)
 566  format(' electronic dynamics with nose` temp. control:'/          &
     &       ' elec. kin. en. required=',f10.5,'(hartree)',             &
     &       ' nose` mass = ',f10.3//)
 600  format(' internal stress tensor calculated')
 602  format(' cell parameters dynamics with frich = ',f7.4,            &
     &       ' and greash = ',f7.4,/                                    &
     &       ' external pressure = ',f11.7,'(gpa)'//)
 604  format(' cell parameters dynamics with nose` temp. control:'/     &
     &       ' cell temperature required = ',f10.5,'(kelvin)',          &
     &       ' nose` mass = ',f10.3,/                                   &
     &       ' external pressure = ',f11.7,'(gpa)'//)
 606  format(' cell parameters are not allowed to move'//)
 608  format(' frozen off-diagonal cell parameters'//)
 650  format(' modified kinetic energy functional, with parameters:'/   &
           & ' agg = ',f8.4,'  sgg = ', f7.4,'  e0gg = ',f6.2)
 700  format(' iprsta = ',i2/)
      return
      end
!
!-----------------------------------------------------------------------
      subroutine read_cards(ibrav, iforce, tau0, atomic_positions)
!-----------------------------------------------------------------------
!
      use parameters, only: nsx, natx
      use ions_base, only : na, nat, nsp, ipp, pmass ! ipp TEMP
      use elct, only: f, n
      use cell_base, only: a1, a2, a3
      use psfiles, only: psfile
      use parser

      implicit none
      integer :: ibrav, iforce(3, natx, nsp)
      real(kind=8) :: tau0(3, natx, nsp)
      character(len=*) :: atomic_positions
      !      
      real(kind=8), allocatable :: tau_inp(:,:)
      real(kind=8) :: kdum1, kdum2, kdum3, wdum
      integer, allocatable :: ityp_inp(:), iforce_inp(:,:)
      character(len=3) :: atom_label(nsp), lb_pos
      character(len=256) :: line, input_line
      character(len=80) :: label
      logical :: tcell=.false., tatms=.false., tatmp=.false., tend
      integer :: unit = 5, i, is, ns, ia, ios, ik, nk
      integer :: ip, nf

      na    = 0
      tau0  = 0.0
      iforce= 0
      ipp   = 0
      psfile= ' '
      a1    = 0.0
      a2    = 0.0
      a3    = 0.0

100   call read_line (line, end_of_file = tend)
      if (tend) go to 200
      if (line(1:1).eq.'#') go to 100
      do i=1,len_trim(line)
         line(i:i) = capital(line(i:i))
      end do
      if (matches('ATOMIC_SPECIES',line)) then
         
         do is = 1, nsp

            call read_line (input_line, end_of_file = tend)
            if (tend) go to 300

            read(input_line,*) atom_label(is), pmass(is), psfile(is), ipp(is)
            IF( pmass(is) <= 0.d0 ) THEN
               CALL errore(' iosys ',' invalid  mass ', is) 
            END IF
         end do
         tatms =.true.

      else if (matches('ATOMIC_POSITIONS',line)) then

         allocate ( ityp_inp(nat) )
         allocate ( tau_inp(3,nat) )
         allocate ( iforce_inp(3,nat) )
         do ia = 1, nat
            CALL read_line (input_line, end_of_file = tend)
            if (tend) go to 300
            CALL field_count(nf,input_line)
            if (nf.eq.4) then
               read(input_line,*) lb_pos, &
                     tau_inp(1,ia), tau_inp(2,ia), tau_inp(3,ia)
               iforce_inp(:,ia) = 1
            else if (nf.eq.7) then
               read(input_line,*) lb_pos, &
                     tau_inp(1,ia), tau_inp(2,ia), tau_inp(3,ia), &
                     iforce_inp(1,ia), iforce_inp(2,ia), iforce_inp(3,ia)
            else
               call errore (' cards','wrong number of tokens', ia)
            end if

            match_label: DO is = 1, nsp
              IF( lb_pos == atom_label(is) ) THEN
                ityp_inp(ia) = is
                EXIT match_label
              END IF
            END DO match_label

            if (ityp_inp(ia) <= 0 .OR. ityp_inp(ia) > nsp) &
                 call errore (' cards','wrong atomic positions', ia)

         end do
         tatmp =.true.

         na = 0
         do is = 1, nsp
            do ia = 1, nat
               if (ityp_inp(ia) == is) then
                  na(is) = na(is) + 1
                  if(na(is).gt.natx) call errore(' cards',' na > natx',na(is))
                  do i = 1, 3
                     tau0(i, na(is), is ) = tau_inp(i, ia)
                     iforce(i, na(is), is ) = iforce_inp(i, ia)
                  end do
               end if
            end do
         end do
         !
         !  read option to card ATOMIC_POSITIONS
         !
         if ( matches('ALAT', line) ) then
            atomic_positions = 'alat'
         else if ( matches('BOHR', line) ) then
            atomic_positions = 'bohr'
         else if ( matches('CRYSTAL', line) ) then
            atomic_positions = 'crystal'
         else if ( matches('ANGSTROM', line) ) then
            atomic_positions = 'angstrom'
         else
            atomic_positions = 'bohr'
         end if
         !
         if ( sum ( na ) .ne. nat) &
              call errore (' cards','unexpected error', 1)
         deallocate (iforce_inp)
         deallocate (tau_inp)
         deallocate (ityp_inp)

      else if (matches('OCCUPATIONS',line)) then
         call read_line (input_line, end_of_file = tend)
         if (tend) go to 300
         allocate (f(n))
         read (input_line, *) (f(i), i=1,n)

      else if (matches('K_POINTS',line)) then

         write (6,'("Warning: k-points ignored ")')

      else if (matches('CELL_PARAMETERS',line)) then

         call read_line (input_line, end_of_file = tend)
         if (tend) go to 300
         read(input_line,*) a1
         call read_line (input_line, end_of_file = tend)
         if (tend) go to 300
         read(input_line,*) a2
         call read_line (input_line, end_of_file = tend)
         if (tend) go to 300
         read(input_line,*) a3

         tcell = .true.

      else

         write (6,'(a)') 'Warning: card '//trim(line)//' ignored'

      end if

      go to 100

200   if (ibrav == 0 .and. .not.tcell ) &
         CALL errore(' cards ',' ibrav=0: must read cell parameters', 1 )
      if (ibrav /= 0 .and. tcell ) &
         CALL errore(' cards ',' redundant data for cell parameters', 2 )
      if (.not.tatms ) &
         CALL errore(' cards ',' atomic species info missing', 1 )
      if (.not.tatmp ) &
         CALL errore(' cards ',' atomic position info missing', 1 )

      return
300   CALL errore(' cards ',' unexpected end of file', 1 )
    end subroutine read_cards

!
! Copyright (C) 2002 CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
      subroutine iosys2( nbeg_ , ndr_ , ndw_ , nomore_ , iprint_                       &
     & , delt_ , emass_ , emaec_  , tsde_ , frice_ , grease_ , twall_                        &
     & , tortho_ , eps_ , max_ , trane_ , ampre_ , tranp_ , amprp_                           &
     & , tfor_ , tsdp_ , fricp_ , greasp_ , tcp_ , tcap_ , tolp_ , trhor_ , trhow_ , tvlocw_ &
     & , tnosep_ , qnp_ , tempw_ , tnosee_ , qne_ , ekincw_                                &
     & , tpre_ , thdyn_ , thdiag_ , twmass_ , wmass_ , frich_ , greash_ , press_           &
     & , tnoseh_ , qnh_ , temph_ , celldm_ , ibrav_ , tau0_ , ecutw_ , ecut_ , iforce_ &
     & , nat_ , nsp_ , na_ , pmass_ , rcmax_ , ipp_ , f_ , nel_ , nspin_ , nupdwn_  &
     & , iupdwn_ , n_ , nx_, nr1_ , nr2_ , nr3_ , omega_ , alat_ , a1_ , a2_ , a3_  & 
     & , nr1b_ , nr2b_ , nr3b_ , nr1s_ , nr2s_ , nr3s_ , agg_ , sgg_ , e0gg_ &
     & , psfile_ , pseudo_dir_, iprsta_, ispin_ )

!-----------------------------------------------------------------------
!   this subroutine reads control variables from standard input (unit 5)
!     ------------------------------------------------------------------

      use input_parameters
      use read_namelists_module, only: read_namelists
      use read_cards_module, only: read_cards

      use constants, only: pi, scmass, factem
      use parameters, only: nsx, natx, nbndxx
      use io_global, only: ionode
      use mp, only: mp_bcast

      !
      implicit none
      !
      !
      real(kind=8) :: ampre_ , delt_ , ekincw_ , emass_ , emaec_ , eps_ ,       &
     &       frice_ , fricp_ , frich_ , grease_ , greasp_ , greash_ ,        &
     &       press_ , qnp_ , qne_ , qnh_ , tempw_ , temph_ , tolp_ , wmass_ ,    &
             amprp_ ( nsx ), celldm_ ( 6 ), tau0_ ( 3, natx, nsx ), ecut_ , ecutw_

      integer :: nbeg_ , ndr_ , ndw_ , nomore_ , iprint_ , max_ , iforce_( 3, natx, nsx )

      logical :: trane_ , tsde_ , twall_ , tortho_ , tnosee_ , tfor_ , tsdp_ , tcp_ , &
           tcap_ , tnosep_ , trhor_ , trhow_ , tvlocw_ , tpre_ , thdyn_ , thdiag_ ,   &
           twmass_ , tnoseh_ , tranp_ ( nsx )

      integer :: nat_ , nsp_ , na_ ( nsx ), ipp_ ( nsx ), nel_ ( 2 ), nspin_ , &
     &     nupdwn_ ( 2 ), iupdwn_ ( 2 ), n_ , nx_ , nr1_ , nr2_ , nr3_ , &
     &     nr1b_ , nr2b_ , nr3b_ , nr1s_ , nr2s_ , nr3s_ , ibrav_, iprsta_

      real(kind=8) :: pmass_ ( nsx ), rcmax_ ( nsx ), f_ ( nbndxx ), ispin_ ( nbndxx ), &
     &     omega_ , alat_ , a1_ ( 3 ), a2_ ( 3 ), a3_ ( 3 ), agg_ , sgg_ , e0gg_


      character(len=80) :: psfile_ ( nsx ) , pseudo_dir_

      !
      ! local variables
      !

      real(kind=8), parameter:: terahertz = 2.418D-5
      real(kind=8) :: taus( 3, natx, nsx ), ocp, fsum
      integer :: unit = 5, ionode_id = 0, i, ia, ios, is, iss, in


      CALL read_namelists( 'CP' )

      IF( TRIM(calculation) == 'nscf' ) trhor_ =.true.
     
!
! translate from input to internals of CP, various checks

      ! ...   Set the number of species

      IF( ntyp < 1 .OR. ntyp > nsx ) THEN
         CALL errore(' iosys ',' ntyp out of range ', ntyp )
      END IF
      nsp_ = ntyp

      ! ...   IBRAV and CELLDM

      IF( ibrav /= 0 .and. celldm(1) == 0.d0 ) THEN
         CALL errore(' iosys ',' invalid value in celldm ', 1 )
      END IF
      IF( ibrav < 0 .OR. ibrav > 14 ) THEN
         CALL errore(' iosys ',' ibrav out of range ', 1 )
      END IF
      ibrav_  = ibrav
      celldm_ = celldm

      ! ...   Set Values for bands          

      IF( nbnd < 1 ) THEN
         CALL errore(' iosys ',' nbnd less than 1 ', nbnd )
      END IF
      IF( nspin < 1 .OR. nspin > 2 ) THEN
         CALL errore(' iosys ',' nspin out of range ', nspin )
      END IF
      n_     = nbnd*nspin
      nspin_ = nspin

      ! ...   Set Values for the cutoff

      ecutw_ = ecutwfc
      IF( ecutwfc <= 0.d0 ) THEN
         CALL errore(' iosys ',' invalid ecutwfc ', INT(ecutwfc) )
      END IF

      if (ecutrho <= 0.d0) ecutrho = 4.d0*ecutwfc
      ecut_ = ecutrho

      ! ...   nbeg

      ampre_ = ampre
      SELECT CASE ( restart_mode ) 
         CASE ('from_scratch')
            nbeg_ = -2
            if (ion_positions == 'from_input') nbeg_ = -1
            nomore_ = nstep
            trane_ = (startingwfc .eq. 'random')
            if ( ampre_ == 0.d0 ) ampre_ = 0.02
         CASE ('reset_counters')
            nbeg_ = 0
            nomore_ = nstep
         CASE ('upto')
            nbeg_ = 1
            nomore_ = nstep
         CASE ('restart')
            nbeg_ = 1
            nomore_ = nstep
         CASE DEFAULT
            CALL errore(' iosys ',' unknown restart_mode '//trim(restart_mode), 1 )
      END SELECT

      ndr_ = ndr
      ndw_ = ndw
      iprint_ = iprint


      ! ...   TORTHO

      SELECT CASE ( orthogonalization ) 
      CASE ('Gram-Schmidt')
         tortho_ = .FALSE.
      CASE ('ortho')
         tortho_ = .TRUE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown orthogonalization '//&
              trim(orthogonalization), 1 )
      END SELECT


      SELECT CASE ( electron_velocities ) 
      CASE ('default')
         continue
      CASE ('zero')
         print '("Warning: electron_velocities keyword has no effect")'
      CASE DEFAULT
         CALL errore(' iosys ',' electron_velocities='// &
              trim(electron_velocities)//' not implemented', 1 )
      END SELECT

      ! ...   TSDE

      SELECT CASE ( electron_dynamics ) 
      CASE ('sd')
         tsde_  = .TRUE.
         frice_ = 0.d0
      CASE ('verlet')
         tsde_  = .FALSE.
         frice_ = 0.d0
      CASE ('damp')
         tsde_  = .FALSE.
         frice_ = electron_damping
      CASE ('none')
         tsde_  = .FALSE.
         frice_ = 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown electron_dynamics '//&
              trim(electron_dynamics),1)
      END SELECT

      ! Ion velocities

      SELECT CASE ( ion_velocities ) 
      CASE ('default')
         tcap_ = .false.
      CASE ('random')
         tcap_ = .true.
      CASE ('zero')
         print '("Warning: ion_velocities = zero not yet implemented")'
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_velocities '//trim(ion_velocities),1)
      END SELECT

      ! ...   TFOR TSDP

      SELECT CASE ( ion_dynamics ) 
      CASE ('sd')
         tsdp_ = .TRUE.
         tfor_ = .TRUE.
         fricp_= 0.d0
      CASE ('verlet')
         tsdp_ = .FALSE.
         tfor_ = .TRUE.
         fricp_= 0.d0
      CASE ('damp')
         tsdp_ = .FALSE.
         tfor_ = .TRUE.
         fricp_= ion_damping
      CASE ('none')
         tsdp_ = .FALSE.
         tfor_ = .FALSE.
         fricp_= 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_dynamics '//trim(ion_dynamics), 1 )
      END SELECT

      !

      SELECT CASE ( cell_velocities ) 
      CASE ('default')
         continue
      CASE ('zero')
         print '("Warning: cell_velocities = zero not yet implemented")'
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_velocities '//trim(cell_velocities),1)
      END SELECT

      !
      
      SELECT CASE ( cell_dynamics ) 
      CASE ('sd')
         tpre_ = .TRUE.
         thdyn_= .TRUE.
         frich_= 0.d0
      CASE ('pr')
         tpre_ = .TRUE.
         thdyn_= .TRUE.
         frich_= 0.d0
      CASE ('damp-pr')
         tpre_  = .TRUE.
         thdyn_= .TRUE.
         frich_ = cell_damping
      CASE ('none')
         tpre_ = .FALSE.
         thdyn_= .FALSE.
         frich_= 0.d0
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_dynamics '//trim(cell_dynamics), 1 )
      END SELECT

      !

      SELECT CASE ( electron_temperature ) 
         !         temperature control of electrons via Nose' thermostat
         !         EKINW (REAL(DBL))  average kinetic energy (in atomic units)
         !         FNOSEE (REAL(DBL))  frequency (in terahertz)
      CASE ('nose')
         tnosee_ = .TRUE.
      CASE ('not_controlled')
         tnosee_ = .FALSE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown electron_temperature '//&
              trim(electron_temperature), 1 )
      END SELECT

      !

      SELECT CASE ( ion_temperature ) 
         !         temperature control of ions via Nose' thermostat
         !         TEMPW (REAL(DBL))  frequency (in which units?)
         !         FNOSEP (REAL(DBL))  temperature (in which units?)
      CASE ('nose')
         tnosep_ = .TRUE.
         tcp_ = .false.
      CASE ('not_controlled')
         tnosep_ = .FALSE.
         tcp_ = .false.
      CASE ('rescaling' )
         tnosep_ = .FALSE.
         tcp_ = .true.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown ion_temperature '//&
              trim(ion_temperature), 1 )
      END SELECT


      SELECT CASE ( cell_temperature ) 
         !         cell temperature control of ions via Nose' thermostat
         !         FNOSEH (REAL(DBL))  frequency (in which units?)
         !         TEMPH (REAL(DBL))  temperature (in which units?)
      CASE ('nose')
         tnoseh_ = .TRUE.
      CASE ('not_controlled')
         tnoseh_ = .FALSE.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_temperature '//&
              trim(cell_temperature), 1 )
      END SELECT


      SELECT CASE ( cell_dofree )
      CASE ('all')
         thdiag_ =.false.
      CASE ('xyz')
         thdiag_ =.true.
      CASE DEFAULT
         CALL errore(' iosys ',' unknown cell_dofree '//trim(cell_dofree), 1 )
      END SELECT


      ! ...  radii, masses

      DO is = 1, nsp_
         rcmax_ (is) = ion_radius(is)
         IF( ion_radius(is) <= 0.d0 ) THEN
            CALL errore(' iosys ',' invalid  ion_radius ', is) 
         END IF
      END DO

      !
      ! compatibility between FPMD and CP90
      !
      iprint_ = isave 
      if ( trim(verbosity)=='high') then
         iprsta_ = 3
      else
         iprsta_ = 1
      end if
      delt_   = dt
      emass_ = emass
      emaec_  = emass_cutoff
      agg_ = qcutz
      sgg_ = q2sigma
      e0gg_= ecfixed
      eps_ = ortho_eps
      max_ = ortho_max
      ! wmass is calculated in "init"
      wmass_ = wmass
      twmass_ = ( wmass == 0.d0 )
      if ( tstress ) tpre_ = .true.
      trhow_ = ( trim( disk_io ) == 'high' )
      tvlocw_ = .false. ! temporaneo
      !
      qne_ = 0.0d0
      qnp_ = 0.0d0
      qnh_ = 0.0d0
      if( fnosee > 0.0d0 ) qne_ = 4.d0*ekincw/(fnosee*(2.d0*pi)*terahertz)**2
      if( fnosep > 0.0d0 ) qnp_ = 2.d0*(3*nat)*tempw/factem/(fnosep*(2.d0*pi)*terahertz)**2
      if( fnoseh > 0.0d0 ) qnh_ = 2.d0*(3*3  )*temph/factem/(fnoseh*(2.d0*pi)*terahertz)**2
      tempw_ = tempw
      temph_ = temph
      ekincw_ = ekincw

      grease_ = grease
      twall_ = twall
      tranp_ ( 1 : nsp_ ) =  tranp ( 1 : nsp_ )
      amprp_ ( 1 : nsp_ ) =  amprp ( 1 : nsp_ )
 
      greasp_ = greasp
      tolp_ = tolp
      greash_ = greash
      press_ = press

      nr1_ = nr1
      nr2_ = nr2
      nr3_ = nr3
      nr1s_ = nr1s
      nr2s_ = nr2s
      nr3s_ = nr3s
      nr1b_ = nr1b
      nr2b_ = nr2b
      nr3b_ = nr3b

      nat_ = nat
      pseudo_dir_ = pseudo_dir
      
      ! read following cards

      call read_cards( 'CP' )

      tau0_  = 0.0
      iforce_= 0
      ipp_   = 0
      psfile_= ' '
      a1_    = 0.0
      a2_    = 0.0
      a3_    = 0.0

      pmass_ ( 1:nsp_ ) = atom_mass( 1:nsp_ )
      psfile_ ( 1:nsp_ ) = atom_pfile( 1:nsp_ )
      ipp_ ( 1:nsp_ ) = atom_ptyp( 1:nsp_ )

      na_ = 0
      do is = 1, nsp_
          do ia = 1, nat_
             if ( sp_pos(ia) == is) then
                na_(is) = na_(is) + 1
                if( na_(is) > natx ) call errore(' cards',' na > natx', na_ (is) )
                do i = 1, 3
                   tau0_ (i, na_ (is), is ) = rd_pos(i, ia)
                   iforce_ (i, na_ (is), is ) = if_pos(i, ia)
                end do
             end if
          end do
       end do

      !
      ! set up atomic positions and crystal lattice
      !
      if ( ibrav_ == 0 ) then
         a1_ = rd_ht( 1, 1:3 )
         a2_ = rd_ht( 2, 1:3 )
         a3_ = rd_ht( 3, 1:3 )
         if ( celldm_ (1) == 0.d0 ) then
            celldm_ (1) = sqrt( a1_ (1) ** 2 + a1_ (2) ** 2 + a1_ (3) ** 2 )
            a1_(:) = a1_(:) / celldm_(1)
            a2_(:) = a2_(:) / celldm_(1)
            a3_(:) = a3_(:) / celldm_(1)
         end if
      else
         call latgen( ibrav_ , celldm_ , a1_ , a2_ , a3_ , omega_ )
      end if
      alat_ = celldm_ (1)

      !
      SELECT CASE ( atomic_positions ) 
         !
         !  convert input atomic positions to internally used format:
         !  tau0 in atomic units
         !
         CASE ('alat')
            !
            !  input atomic positions are divided by a0
            !
            tau0_ = tau0_ * alat_
         CASE ('bohr')
            !
            !  input atomic positions are in a.u.: do nothing
            !
            continue
         CASE ('crystal')
            !
            !  input atomic positions are in crystal axis ("scaled"):
            !
            taus = tau0_
            do is = 1, nsp_
               do ia = 1, na_(is)
                  do i = 1, 3
                     tau0_ ( i, ia, is ) = a1_ (i) * taus( 1, ia, is) &
                                         + a2_ (i) * taus( 2, ia, is) &
                                         + a3_ (i) * taus( 3, ia, is)
                  end do
               end do
            end do
         CASE ('angstrom')
            !
            !  atomic positions in A
            !
            tau0_ = tau0_ / 0.529177
         CASE DEFAULT
            CALL errore(' iosys ',' atomic_positions='//trim(atomic_positions)// &
                 ' not implemented ', 1 )
      END SELECT

      !
      !  set occupancies
      !
      
      IF( nelec < 1 ) THEN
         CALL errore(' iosys ',' nelec less than 1 ', nelec )
      END IF

      if( mod( n_ , 2 ) .ne. 0 ) then
         nx_ = n_ + 1
      else
         nx_= n_
      end if

      iupdwn_ ( 1 ) = 1
      nel_ = 0

      SELECT CASE ( TRIM(occupations) ) 
      CASE ('bogus')
         !
         ! empty-states calculation: occupancies have a (bogus) finite value
         !
         ! bogus to ensure \sum_i f_i = Nelec  (nelec is integer)
         !
         f_ ( : ) = dfloat( nelec ) / n_         
         nel_ (1) = nelec
         nupdwn_ (1) = n_
         if ( nspin_ == 2 ) then
            !
            ! bogus to ensure Nelec = Nup + Ndw
            !
            nel_ (1) = ( nelec + 1 ) / 2
            nel_ (2) =   nelec       / 2
            nupdwn_ (1)=nbnd
            nupdwn_ (2)=nbnd
            iupdwn_ (2)=nbnd+1
         end if
      CASE ('from_input')
         !
         ! occupancies have been read from input
         !
         f_ ( 1:nbnd ) = f_inp( 1:nbnd, 1 )
         if( nspin_ == 2 ) f_ ( nbnd+1 : 2*nbnd ) = f_inp( 1:nbnd, 2 ) 
         if( nelec == 0 ) nelec = SUM ( f_ ( 1:n_ ) )
         if( nspin_ == 2 .and. nelup == 0) nelup = SUM ( f_ ( 1:nbnd ) )
         if( nspin_ == 2 .and. neldw == 0) neldw = SUM ( f_ ( nbnd+1 : 2*nbnd ) )

         if( nspin_ == 1 ) then 
           nel_ (1) = nelec
           nupdwn_ (1) = n_
         else
           IF ( nelup + neldw /= nelec  ) THEN
              CALL errore(' iosys ',' wrong # of up and down spin', 1 )
           END IF
           nel_ (1) = nelup
           nel_ (2) = neldw
           nupdwn_ (1)=nbnd
           nupdwn_ (2)=nbnd
           iupdwn_ (2)=nbnd+1
         end if

      CASE ('fixed')

         if( nspin_ == 1 ) then
            nel_ (1) = nelec
            nupdwn_ (1) = n_
         else
            IF ( nelup + neldw /= nelec  ) THEN
               CALL errore(' iosys ',' wrong # of up and down spin', 1 )
            END IF
            nel_ (1) = nelup
            nel_ (2) = neldw
            nupdwn_ (1)=nbnd
            nupdwn_ (2)=nbnd
            iupdwn_ (2)=nbnd+1
         end if

         ! ocp = 2 for spinless systems, ocp = 1 for spin-polarized systems
         ocp = 2.d0 / nspin_
         ! default filling: attribute ocp electrons to each states
         !                  until the good number of electrons is reached
         do iss = 1, nspin_
            fsum = 0.0d0
            do in = iupdwn_ ( iss ), iupdwn_ ( iss ) - 1 + nupdwn_ ( iss )
               if ( fsum + ocp < nel_ ( iss ) + 0.0001 ) then
                  f_ (in) = ocp
               else
                  f_ (in) = max( nel_ ( iss ) - fsum, 0.d0 )
               end if
                fsum=fsum + f_(in)
            end do
         end do

      CASE DEFAULT
         CALL errore(' iosys ',' occupation method not implemented', 1 )
      END SELECT

      do iss = 1, nspin_
         do in = iupdwn_(iss), iupdwn_(iss) - 1 + nupdwn_(iss)
            ispin_(in) = iss
         end do
      end do

!
!     --------------------------------------------------------
!     print out heading
!
      write(6,400) 
      write(6,410) 
      write(6,420) 
      write(6,410) 
      write(6,400) 
      write(6,500) nbeg_ , nomore_ , iprint_ , ndr_ , ndw_
      write(6,505) delt_
      write(6,510) emass_ , emaec_
!
      if( tortho_ ) then
         write(6,511) eps_ , max_
      else
         write(6,512)
      endif
!
      if( tsde_ ) then
         write(6,513)
      else
         if ( tnosee_ ) frice_ = 0.
         write(6,509)
         write(6,514) frice_ , grease_
      endif
!
      if ( trhor_ ) then
         write(6,720)
      endif
!
      if( .not. trhor_ .and. trhow_ )then
         write(6,721)
      endif
!
      if( tvlocw_ )then
         write(6,722)
      endif
!
      if( trane_ ) then
         write(6,515) ampre_
      endif
      write(6,516)
      do is =1, nsp_
         if(tranp_(is)) write(6,517) is, amprp_(is)
      end do
!
      if(tfor_) then
         if(tnosep_) fricp_ = 0.
         write(6,520)
         if(tsdp_)then
            write(6,521)
         else
            write(6,522) fricp_ , greasp_
         endif
      else
         write(6,518)
      endif
!
      if( tfor_ ) then
         if(( tcp_ .or. tcap_ .or. tnosep_ ) .and. tsdp_ ) then
            call errore(' main',' t contr. for ions when tsdp=.t.',0)
         endif
         if(.not. tcp_ .and. .not. tcap_ .and. .not. tnosep_ ) then
            write(6,550)
         else if(tcp_ .and. tcap_ ) then
            call errore(' main',' tcp and tcap both true',0)
         else if(tcp_ .and. tnosep_ ) then
            call errore(' main',' tcp and tnosep both true',0)
         else if(tcap_ .and. tnosep_ ) then
            call errore(' main',' tcap and tnosep both true',0)
         else if(tcp_ ) then
            write(6,555) tempw_ , tolp_
         else if(tcap_) then
            write(6,560) tempw_ , tolp_
         else if(tnosep_ ) then
            write(6,562) tempw_ , qnp_
         end if
         if(tnosee_) then
            write(6,566) ekincw_ , qne_
         end if
      end if
!
      if(tpre_) then
         write(6,600)
         if(thdyn_) then
            if(thdiag_) write(6,608)
            if(tnoseh_) then
               frich_=0.
               write(6,604) temph_,qnh_,press_
            else
               write(6,602) frich_,greash_,press_
            endif
         else
            write(6,606)
         endif
      endif
      if ( agg_ .ne. 0.d0) then
            write(6,650) agg_, sgg_, e0gg_
      end if
      write(6,700) iprsta_

!     
 400  format('************************************',                    &
     &     '************************************')
 410  format('****                                ',                    &
     &       '                                ****')
 420  format('****  ab-initio molecular dynamics: ',                    &
     &       ' car-parrinello vanderbilt bhs  ****')
 500  format(//                                                         &
     &       ' nbeg=',i3,' nomore=',i7,3x,' iprint=',i4,/               &
     &       ' reads from',i3,' writes on',i3)
 505  format(' time step = ',f9.4/)
 510  format(' parameters for electron dynamics:'/                      &
     &       ' emass= ',f10.2,2x,'emaec= ',f10.2,'ry')
 511  format(' orthog. with lagrange multipliers: eps=',e10.2,          &
     &         ' max=',i3)
 512  format(' orthog. with gram-schmidt')
 513  format(' electron dynamics with steepest descent')
 509  format(' verlet algorithm for electron dynamics')
 514  format(' with friction frice = ',f7.4,' , grease = ',f7.4)
 720  format(' charge density is read from unit 47',/)
 721  format(' charge density is written in unit 47',/)
 722  format(' local potential is written in unit 46',/)
 515  format(' initial random displacement of el. coordinates with ',   &
     &       ' amplitude=',f10.6,/                                      &
     &       ' trane not to be used with mass preconditioning')
 516  format(/)
 517  format(' initial random displacement of ionic coord. for species ',&
     &       i4,' : amplitude=',f10.6)
 518  format(' ions are not allowed to move'/)
 520  format(' ions are allowed to move')
 521  format(' ion dynamics with steepest descent')
 522  format(' ion dynamics with fricp = ',f7.4,' and greasp = ',f7.4)
 550  format(' ion dynamics: the temperature is not controlled'//)
 555  format(' ion dynamics with rescaling of velocities:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 560  format(' ion dynamics with canonical temp. control:'/             &
     &       ' temperature required=',f10.5,'(kelvin)',' tolerance=',   &
     &       f10.5//)
 562  format(' ion dynamics with nose` temp. control:'/                 &
     &       ' temperature required=',f10.5,'(kelvin)',' nose` mass = ',&
     &       f10.3//)
 566  format(' electronic dynamics with nose` temp. control:'/          &
     &       ' elec. kin. en. required=',f10.5,'(hartree)',             &
     &       ' nose` mass = ',f10.3//)
 600  format(' internal stress tensor calculated')
 602  format(' cell parameters dynamics with frich = ',f7.4,            &
     &       ' and greash = ',f7.4,/                                    &
     &       ' external pressure = ',f11.7,'(gpa)'//)
 604  format(' cell parameters dynamics with nose` temp. control:'/     &
     &       ' cell temperature required = ',f10.5,'(kelvin)',          &
     &       ' nose` mass = ',f10.3,/                                   &
     &       ' external pressure = ',f11.7,'(gpa)'//)
 606  format(' cell parameters are not allowed to move'//)
 608  format(' frozen off-diagonal cell parameters'//)
 650  format(' modified kinetic energy functional, with parameters:'/   &
           & ' agg = ',f8.4,'  sgg = ', f7.4,'  e0gg = ',f6.2)
 700  format(' iprsta = ',i2/)
      return
      end
!
