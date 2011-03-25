!
! Copyright (C) 2001-2008 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE setup()
  !----------------------------------------------------------------------------
  !
  ! ... This routine is called at the beginning of the calculation and
  ! ... 1) determines various parameters of the calculation:
  ! ...    zv        charge of each atomic type
  ! ...    nelec     total number of electrons (if not given in input)
  ! ...    nbnd      total number of bands (if not given in input)
  ! ...    nbndx     max number of bands used in iterative diagonalization
  ! ...    tpiba     2 pi / a (a = lattice parameter)
  ! ...    tpiba2    square of tpiba
  ! ...    gcutm     cut-off in g space for charge/potentials
  ! ...    gcutms    cut-off in g space for smooth charge
  ! ...    ethr      convergence threshold for iterative diagonalization
  ! ... 2) finds actual crystal symmetry:
  ! ...    s         symmetry matrices in the direct lattice vectors basis
  ! ...    nsym      number of crystal symmetry operations
  ! ...    nrot      number of lattice symmetry operations
  ! ...    ftau      fractionary translations
  ! ...    irt       for each atom gives the corresponding symmetric
  ! ...    invsym    if true the system has inversion symmetry
  ! ... 3) generates k-points corresponding to the actual crystal symmetry
  ! ... 4) calculates various quantities used in magnetic, spin-orbit, PAW
  ! ...    electric-field, LDA+U calculations, and for parallelism
  !
  USE kinds,              ONLY : DP
  USE constants,          ONLY : eps8
  USE parameters,         ONLY : npk
  USE io_global,          ONLY : stdout
  USE io_files,           ONLY : tmp_dir, prefix, xmlpun, delete_if_present
  USE constants,          ONLY : pi, degspin
  USE cell_base,          ONLY : at, bg, alat, tpiba, tpiba2, ibrav, &
                                 symm_type, omega
  USE ions_base,          ONLY : nat, tau, ntyp => nsp, ityp, zv
  USE basis,              ONLY : starting_pot, natomwfc
  USE gvect,              ONLY : gcutm
  USE grid_dimensions,    ONLY : nr1, nr2, nr3
  USE grid_subroutines,   ONLY : realspace_grids_init
  USE gvecs,              ONLY : doublegrid, gcutms, dual
  USE klist,              ONLY : xk, wk, nks, nelec, degauss, lgauss, &
                                 lxkcry, nkstot, &
                                 nelup, neldw, two_fermi_energies, &
                                 tot_charge, tot_magnetization
  USE lsda_mod,           ONLY : lsda, nspin, current_spin, isk, &
                                 starting_magnetization
  USE ener,               ONLY : ef
  USE electrons_base,     ONLY : set_nelup_neldw
  USE ktetra,             ONLY : nk1, nk2, nk3, k1, k2, k3, &
                                 tetra, ntetra, ltetra
  USE symm_base,          ONLY : s, t_rev, irt, ftau, nrot, nsym, invsym, &
                                 d1,d2,d3, time_reversal, sname, set_sym_bl, &
                                 find_sym
  USE wvfct,              ONLY : nbnd, nbndx, ecutwfc
  USE control_flags,      ONLY : tr2, ethr, lscf, lmd, david,  &
                                 isolve, niter, noinv, nosym, nosym_evc, &
                                 nofrac, lbands, use_para_diag, gamma_only
  USE cellmd,             ONLY : calc
  USE uspp_param,         ONLY : upf, n_atom_wfc
  USE uspp,               ONLY : okvan
  USE ldaU,               ONLY : lda_plus_u, Hubbard_U, &
                                 Hubbard_l, Hubbard_alpha, Hubbard_lmax, oatwfc
  USE bp,                 ONLY : gdir, lberry, nppstr, lelfield, nx_el, nppstr_3d,l3dstring, efield
  USE fixed_occ,          ONLY : f_inp, tfixed_occ, one_atom_occupations
  USE funct,              ONLY : set_dft_from_name
  USE mp_global,          ONLY : kunit
  USE spin_orb,           ONLY : lspinorb, domag
  USE noncollin_module,   ONLY : noncolin, npol, m_loc, i_cons, &
                                 angle1, angle2, bfield, ux, nspin_lsda, &
                                 nspin_gga, nspin_mag
  USE pw_restart,         ONLY : pw_readfile
  USE input_parameters,   ONLY : restart_mode, lecrpa
#if defined (EXX)
  USE exx,                ONLY : exx_grid_init, exx_div_check
#endif
  USE funct,              ONLY : dft_is_meta, dft_is_hybrid, dft_is_gradient
  USE paw_variables,      ONLY : okpaw
  USE start_k,            ONLY : nks_start, xk_start, wk_start
! DCC
!  USE ee_mod,             ONLY : do_coarse, do_mltgrid

  !
  IMPLICIT NONE
  !
  INTEGER  :: na, nt, input_nks, is, ierr, ibnd, ik
  LOGICAL  :: magnetic_sym
  REAL(DP) :: iocc, ionic_charge
  !
  INTEGER, EXTERNAL :: set_Hubbard_l
  !
  ! ... okvan/okpaw = .TRUE. : at least one pseudopotential is US/PAW
  !
  okvan = ANY( upf(:)%tvanp )
  okpaw = ANY( upf(1:ntyp)%tpawp )
  IF ( dft_is_meta() .AND. okvan ) &
     CALL errore( 'setup', 'US and Meta-GGA not yet implemented', 1 )

#if ! defined (EXX)
  IF ( dft_is_hybrid() ) CALL errore( 'setup ', &
                         'HYBRID XC not implemented in PWscf', 1 )
#else
  IF ( dft_is_hybrid() ) THEN
     IF (.NOT. lscf) CALL errore( 'setup ', &
                         'HYBRID XC not allowed in non-scf calculations', 1 )
     IF ( okvan .OR. okpaw ) CALL errore( 'setup ', &
                         'HYBRID XC not implemented for USPP or PAW', 1 )
  END IF
#endif
  !
  ! ... Compute the ionic charge for each atom type and the total ionic charge
  !
  zv(1:ntyp) = upf(1:ntyp)%zp
  !
#if defined (__PGI)
     ionic_charge = 0._DP
     DO na = 1, nat
        ionic_charge = ionic_charge + zv( ityp(na) )
     END DO
#else
     ionic_charge = SUM( zv(ityp(1:nat)) ) 
#endif
  !
  ! ... set the number of electrons 
  !
  nelec = ionic_charge - tot_charge
  !
  ! ... magnetism-related quantities
  !
  ALLOCATE( m_loc( 3, nat ) )
  ! time reversal operation is set up to 0 by default
  t_rev = 0
  IF ( noncolin ) THEN
     !
     ! gamma_only and noncollinear not allowed
     !
     if (gamma_only) call errore('setup', &
                                 'gamma_only and noncolin not allowed',1)
     !
     ! ... wavefunctions are spinors with 2 components
     !
     npol = 2
     !
     ! ... Set the domag variable to make a spin-orbit calculation with zero
     ! ... magnetization
     !
     IF ( lspinorb ) THEN
        !
        domag = ANY ( ABS( starting_magnetization(1:ntyp) ) > 1.D-6 )
        !
     ELSE
        !
        domag = .TRUE.
        !
     END IF
     !
     DO na = 1, nat
        !
        m_loc(1,na) = starting_magnetization(ityp(na)) * &
                      SIN( angle1(ityp(na)) ) * COS( angle2(ityp(na)) )
        m_loc(2,na) = starting_magnetization(ityp(na)) * &
                      SIN( angle1(ityp(na)) ) * SIN( angle2(ityp(na)) )
        m_loc(3,na) = starting_magnetization(ityp(na)) * &
                      COS( angle1(ityp(na)) )
     END DO
     !
     !  initialize the quantization direction for gga
     !
     ux=0.0_DP
     if (dft_is_gradient()) call compute_ux(m_loc,ux,nat)
     !
  ELSE
     !
     ! ... wavefunctions are scalars
     !
     IF (lspinorb)  CALL errore( 'setup ',  &
         'spin orbit requires a non collinear calculation', 1 )
     npol = 1
     !
     !
     IF ( i_cons == 1) then
        do na=1,nat
           m_loc(1,na) = starting_magnetization(ityp(na))
        end do
     end if
     IF ( i_cons /= 0 .AND. nspin ==1) &
        CALL errore( 'setup', 'this i_cons requires a magnetic calculation ', 1 )
     IF ( i_cons /= 0 .AND. i_cons /= 1 ) &
        CALL errore( 'setup', 'this i_cons requires a non colinear run', 1 )
  END IF
  !
  !  Set the different spin indices
  !
  nspin_mag  = nspin
  nspin_lsda = nspin
  nspin_gga  = nspin
  IF (nspin==4) THEN
     nspin_lsda=1
     IF (domag) THEN
        nspin_gga=2
     ELSE
        nspin_gga=1
        nspin_mag=1
     ENDIF
  ENDIF    
  !
  ! ... if this is not a spin-orbit calculation, all spin-orbit pseudopotentials
  ! ... are transformed into standard pseudopotentials
  !
  IF ( lspinorb .AND. ALL ( .NOT. upf(:)%has_so ) ) &
        CALL infomsg ('setup','At least one non s.o. pseudo')
  !
  IF ( .NOT. lspinorb ) CALL average_pp ( ntyp )
  !
  ! ... If the occupations are from input, check the consistency with the
  ! ... number of electrons
  !
  IF ( tfixed_occ ) THEN
     !
     iocc = 0
     !
     DO is = 1, nspin_lsda
        !
#if defined (__PGI)
        DO ibnd = 1, nbnd
           iocc = iocc + f_inp(ibnd,is)
        END DO
#else
        iocc = iocc + SUM( f_inp(1:nbnd,is) )
#endif
        !
        DO ibnd = 1, nbnd
           if (f_inp(ibnd,is) > 2.d0/nspin_lsda .or. f_inp(ibnd,is) < 0.d0) &
              call errore('setup','wrong fixed occupations',is)
        END DO
     END DO
     !
     IF ( ABS( iocc - nelec ) > 1D-5 ) &
        CALL errore( 'setup', 'strange occupations: '//&
                     'number of electrons from occupations is wrong.', 1 )
     !
  END IF
  !
  ! ... For metals: check whether Gaussian broadening or Tetrahedron method
  ! ...             is used
  !
  lgauss = ( ( degauss /= 0.D0 ) .AND. ( .NOT. tfixed_occ ) )
  !
  ! ... Check: if there is an odd number of electrons, the crystal is a metal
  !
  IF ( lscf .AND. ABS( NINT( nelec / 2.D0 ) - nelec / 2.D0 ) > eps8 &
            .AND. .NOT. lgauss .AND. .NOT. ltetra .AND. .NOT. tfixed_occ ) &
      CALL infomsg( 'setup', 'the system is metallic, specify occupations' )
  !
  ! ... Check: spin-polarized calculations require tetrahedra or broadening
  !            or fixed occupation - the simple filling of levels is not
  !            implemented right now (it will yield an unpolarized system)
  !
  IF ( lscf .AND. lsda &
            .AND. .NOT. lgauss .AND. .NOT. ltetra &
            .AND. .NOT. tfixed_occ .AND. .NOT. two_fermi_energies ) &
      CALL errore( 'setup', 'spin-polarized system, specify occupations', 1 )
  !
  ! ... Check: modern theory of polarization (lefield) does not apply to metals
  !
  IF(lgauss .and. lelfield) &
          CALL errore("setup", "lelfield cannot be used with smearing", 1)
  !
  ! ... setting nelup/neldw 
  !
  call set_nelup_neldw ( tot_magnetization, nelec, nelup, neldw )
  !
  ! ... Set the number of occupied bands if not given in input
  !
  IF ( nbnd == 0 ) THEN
     !
     IF (nat==0) CALL errore('setup','free electrons: nbnd required in input',1)
     !
     nbnd = MAX ( NINT( nelec / degspin ), NINT(nelup), NINT(neldw) )
     !
     IF ( lgauss .OR. ltetra ) THEN
        !
        ! ... metallic case: add 20% more bands, with a minimum of 4
        !
        nbnd = MAX( NINT( 1.2D0 * nelec / degspin ), &
                    NINT( 1.2D0 * nelup), NINT( 1.2d0 * neldw ), &
                    ( nbnd + 4 ) )
        !
     END IF
     !
     ! ... In the case of noncollinear magnetism, bands are NOT
     ! ... twofold degenerate :
     !
     IF ( noncolin ) nbnd = INT( degspin ) * nbnd
     !
  ELSE
     !
     IF ( nbnd < NINT( nelec / degspin ) .AND. lscf ) &
        CALL errore( 'setup', 'too few bands', 1 )
     !
     IF ( nbnd < NINT( nelup ) .AND. lscf ) &
        CALL errore( 'setup', 'too few spin up bands', 1 )
     IF ( nbnd < NINT( neldw ) .AND. lscf ) &
        CALL errore( 'setup', 'too few spin dw bands', 1 )
     !
     IF ( nbnd < NINT( nelec ) .AND. lscf .AND. noncolin ) &
        CALL errore( 'setup', 'too few bands', 1 )
     !
  END IF
  !
  ! ... Here we  set the precision of the diagonalization for the first scf
  ! ... iteration of for the first ionic step
  ! ... for subsequent steps ethr is automatically updated in electrons
  !
  IF ( .NOT. lscf ) THEN
     !
     IF ( ethr == 0.D0 ) ethr = 0.1D0 * MIN( 1.D-2, tr2 / nelec )
     !
  ELSE
     !
     IF ( ethr == 0.D0 ) THEN
        !
        IF ( starting_pot == 'file' ) THEN
           !
           ! ... if you think that the starting potential is good
           ! ... do not spoil it with a lousy first diagonalization :
           ! ... set a strict ethr in the input file (diago_thr_init)
           !
           ethr = 1.D-5
           !
        ELSE
           !
           ! ... starting atomic potential is probably far from scf
           ! ... do not waste iterations in the first diagonalizations
           !
           ethr = 1.0D-2
           !
        END IF
        !
     END IF
     !
  END IF
  !
  IF (nat==0) THEN
     ethr=1.0D-8
!
!  In this case, print the Hartree-Fock energy of free electrons per cell
!  (not per electron).
!
     CALL set_dft_from_name('sla-noc-nogx-nogc')
  END IF
  !
  IF ( .NOT. lscf ) niter = 1
  !
  ! ... set number of atomic wavefunctions
  !
  natomwfc = n_atom_wfc( nat, ityp, noncolin )
  !
  ! ... set the max number of bands used in iterative diagonalization
  !
  nbndx = nbnd
  IF ( isolve == 0 ) nbndx = david * nbnd
  !
#ifdef __PARA
  IF ( use_para_diag )  CALL check_para_diag( nbnd )
#else
  use_para_diag = .FALSE.
#endif
  !
  ! ... Set the units in real and reciprocal space
  !
  tpiba  = 2.D0 * pi / alat
  tpiba2 = tpiba**2
  !
  ! ... Compute the cut-off of the G vectors
  !
  doublegrid = ( dual > 4.D0 )
#if defined (EXX)
  IF ( doublegrid .and.  dft_is_hybrid() ) &
     CALL errore('setup','ecutrho>4*ecutwfc and exact exchange not allowed',1)
#endif
  IF ( doublegrid .AND. (.NOT.okvan .AND. .not.okpaw) ) &
     CALL infomsg ( 'setup', 'no reason to have ecutrho>4*ecutwfc' )
  gcutm = dual * ecutwfc / tpiba2
  !
  IF ( doublegrid ) THEN
     !
     gcutms = 4.D0 * ecutwfc / tpiba2
     !
  ELSE
     !
     gcutms = gcutm
     !
  END IF
  !
  ! ... Test that atoms do not overlap
  !
  call check_atoms ( nat, tau, bg )
  !
  ! ... calculate dimensions of the FFT grid
  !
  CALL realspace_grids_init (at, bg, gcutm, gcutms )
  !
! DCC
!  IF( do_coarse ) CALL set_fft_dim_coarse()
!  IF( do_mltgrid ) CALL set_mltgrid_dim()
  !
  !  ... generate transformation matrices for the crystal point group
  !  ... First we generate all the symmetry matrices of the Bravais lattice
  !
  call set_sym_bl(ibrav, symm_type)
  !
  ! ... If lecrpa is true, nosym must be set to true also
  !
  IF ( lecrpa ) nosym = .TRUE.
  !
  ! ... If nosym is true do not use any point-group symmetry
  !
  IF ( nosym ) nrot = 1
  !
  ! ... time_reversal = use q=>-q symmetry for k-point generation
  !
  magnetic_sym = noncolin .AND. domag 
  time_reversal = .NOT. noinv .AND. .NOT. magnetic_sym
  !
  ! ... If  lxkcry = .TRUE. , the input k-point components in crystal
  ! ... axis are transformed into cartesian coordinates - done here
  ! ... and not in input because the reciprocal lattice is needed
  !
  IF ( lxkcry .AND. nkstot > 0 ) CALL cryst_to_cart( nkstot, xk, bg, 1 )
  !
  ! ... Automatic generation of k-points (if required)
  !
  IF ( nkstot == 0 ) THEN
     !
     IF (lelfield) THEN
         !
        CALL kpoint_grid_efield (at,bg, npk, &
             k1,k2,k3, nk1,nk2,nk3, nkstot, xk, wk, nspin)
        nosym = .TRUE.
        nrot  = 1
        nsym  = 1
        !
     ELSE IF (lberry) THEN
        !
        CALL kp_strings( nppstr, gdir, nrot, s, bg, npk, &
                         k1, k2, k3, nk1, nk2, nk3, nkstot, xk, wk )
        nosym = .TRUE.
        nrot  = 1
        nsym  = 1
        !
     ELSE
        !
        CALL kpoint_grid ( nrot, time_reversal, s, t_rev, bg, npk, &
                         k1,k2,k3, nk1,nk2,nk3, nkstot, xk, wk)
        !
     END IF
     !
  ELSE IF( lelfield) THEN
     !
     allocate(nx_el(nkstot*nspin,3))
     ! <AF>
     IF ( gdir < 0 .OR. gdir > 3 ) CALL errore('setup','invalid gdir value',10) 
     IF ( gdir == 0 )  CALL errore('setup','needed gdir probably not set',10) 
     !
     do ik=1,nkstot
        nx_el(ik,gdir)=ik
     enddo
     !
     if(nspin==2)      nx_el(nkstot+1:2*nkstot,:)=nx_el(1:nkstot,:)+nkstot
     nppstr_3d(gdir)=nppstr
     l3dstring=.false.
     nosym = .TRUE.
     nrot  = 1
     nsym  = 1
     !
  END IF
  !
  !  Save the initial k point for phonon calculation
  !
  IF (nks_start==0) THEN
      nks_start=nkstot
      IF ( .NOT. ALLOCATED( xk_start ) ) ALLOCATE( xk_start( 3, nks_start ) )
      IF ( .NOT. ALLOCATED( wk_start ) ) ALLOCATE( wk_start( nks_start ) )
      xk_start(:,:)=xk(:,1:nkstot)
      wk_start(:)=wk(1:nkstot)
  ENDIF
  !
  IF ( nat==0 ) THEN
     !
     nsym=nrot
     invsym=.true.
     !
  ELSE
     !
     ! ... eliminate rotations that are not symmetry operations
     !
     CALL find_sym ( nat, tau, ityp, nr1, nr2, nr3, nofrac, &
                  magnetic_sym, m_loc, nosym_evc )
     !
  ENDIF
  !
  ! ... if dynamics is done the system should have no symmetries
  ! ... (inversion symmetry alone is allowed)
  !
  IF ( lmd .AND. ( nsym == 2 .AND. .NOT. invsym .OR. nsym > 2 ) &
           .AND. .NOT. ( calc == 'mm' .OR. calc == 'nm' ) ) &
       CALL infomsg( 'setup', 'Dynamics, you should have no symmetries' )
  !
  input_nks = nkstot
  IF ( nat > 0 ) THEN
     !
     ! ... Input k-points are assumed to be  given in the IBZ of the Bravais
     ! ... lattice, with the full point symmetry of the lattice.
     ! ... If some symmetries of the lattice are missing in the crystal,
     ! ... "irreducible_BZ" computes the missing k-points.
     !
     CALL irreducible_BZ (nrot, s, nsym, time_reversal, at, bg, npk, &
                          nkstot, xk, wk, t_rev)
     !
  END IF
  !
  ntetra = 0
  !
  IF ( lbands ) THEN
     !
     ! ... if calculating bands, we leave k-points unchanged and read the
     ! Fermi energy
     !
     nkstot = input_nks
     CALL pw_readfile( 'reset', ierr )
     CALL pw_readfile( 'ef',   ierr )
     CALL errore( 'setup ', 'problem reading ef from file ' // &
             & TRIM( tmp_dir ) // TRIM( prefix ) // '.save', ierr )

!     IF ( restart_mode == 'from_scratch' ) &
!           CALL delete_if_present( TRIM( tmp_dir ) // TRIM( prefix ) &
!                                     //'.save/' // TRIM( xmlpun ) )
     !
  ELSE IF ( ltetra ) THEN
     !
     ! ... Calculate quantities used in tetrahedra method
     !
     ntetra = 6 * nk1 * nk2 * nk3
     !
     ALLOCATE( tetra( 4, ntetra ) )
     !
     CALL tetrahedra( nsym, s, time_reversal, at, bg, npk, k1, k2, k3, &
          nk1, nk2, nk3, nkstot, xk, wk, ntetra, tetra )
     !
  END IF
  !
#if defined (EXX)
  IF ( dft_is_hybrid() ) THEN
     CALL exx_grid_init()
     CALL exx_div_check()
  ENDIF
#endif
  !
  IF ( lsda ) THEN
     !
     ! ... LSDA case: two different spin polarizations,
     ! ...            each with its own kpoints
     !
     if (nspin /= 2) call errore ('setup','nspin should be 2; check iosys',1)
     !
     CALL set_kup_and_kdw( xk, wk, isk, nkstot, npk )
     !
  ELSE IF ( noncolin ) THEN
     !
     ! ... noncolinear magnetism: potential and charge have dimension 4 (1+3)
     !
     if (nspin /= 4) call errore ('setup','nspin should be 4; check iosys',1)
     current_spin = 1
     !
  ELSE
     !
     ! ... LDA case: the two spin polarizations are identical
     !
     wk(1:nkstot)    = wk(1:nkstot) * degspin
     current_spin = 1
     !
     IF ( nspin /= 1 ) &
        CALL errore( 'setup', 'nspin should be 1; check iosys', 1 )
     !
  END IF
  !
  IF ( nkstot > npk ) CALL errore( 'setup', 'too many k points', nkstot )
  !
#ifdef __PARA
  !
  !
  ! ... distribute k-points (and their weights and spin indices)
  !
  kunit = 1
  CALL divide_et_impera( xk, wk, isk, lsda, nkstot, nks )
  !
#else
  !
  nks = nkstot
  !
#endif
  IF (one_atom_occupations) THEN
     DO ik=1,nkstot
        DO ibnd=natomwfc+1, nbnd
           IF (f_inp(ibnd,ik)> 0.0_DP) CALL errore('setup', &
               'no atomic wavefunction for some band',1)
        ENDDO
     ENDDO
  ENDIF
  !
  ! ... initialize d1 and d2 to rotate the spherical harmonics
  !
  IF ( lda_plus_u ) THEN
     !
     Hubbard_lmax = -1
     ! Set the default of Hubbard_l for the species which have
     ! Hubbard_U=0 (in that case set_Hubbard_l will not be called)
     Hubbard_l(:) = -1 
     !
     DO nt = 1, ntyp
        !
        IF ( Hubbard_U(nt) /= 0.D0 .OR. Hubbard_alpha(nt) /= 0.D0 ) THEN
           !
           Hubbard_l(nt) = set_Hubbard_l( upf(nt)%psd )
           !
           Hubbard_lmax = MAX( Hubbard_lmax, Hubbard_l(nt) )
           !
        END IF
        !
     END DO
     !
     IF ( Hubbard_lmax == -1 ) &
        CALL errore( 'setup', &
                   & 'lda_plus_u calculation but Hubbard_l not set', 1 )
     !
     ! compute index of atomic wfcs used as projectors
     ALLOCATE ( oatwfc(nat) )
     CALL offset_atom_wfc ( nat, oatwfc )
     !
  ELSE
     !
     Hubbard_lmax = 0
     !
  END IF
  !
  IF (lda_plus_u .or. okpaw ) CALL d_matrix( d1, d2, d3 )
  !
  RETURN
  !
END SUBROUTINE setup
!
!----------------------------------------------------------------------------
SUBROUTINE check_para_diag( nbnd )
  !
  USE control_flags,    ONLY : use_para_diag, gamma_only
  USE io_global,        ONLY : stdout, ionode, ionode_id
  USE mp_global,        ONLY : nproc_pool, init_ortho_group, nproc_ortho, &
                               np_ortho, intra_pool_comm

  IMPLICIT NONE

  INTEGER, INTENT(IN) :: nbnd
  LOGICAL, SAVE :: first = .TRUE.
  INTEGER :: np

  !  avoid synchronization problems when more images are active 

  IF( .NOT. first ) RETURN

  first = .FALSE.

  use_para_diag = .TRUE.
  !
  !  here we re-initialize the sub group of processors that will take part
  !  in the matrix diagonalization. 
  !  NOTE that the maximum number of processors may not be the optimal one,
  !  and -ndiag N argument can be used to force a given number N of processors
  !
  np = MAX( INT( SQRT( DBLE( nproc_ortho ) + 0.1d0 ) ), 1 )
  !
  IF( nbnd < np ) THEN
      !
      !  Make ortho group compatible with the number of electronic states
      !
      IF ( ionode ) WRITE(stdout,'(5X,"Too few bands for required ortho ", &
                    & "group size ",i4,": reducing to ",i4)') np**2, nbnd**2
      np = MIN( nbnd, np )
      !
  END IF
  !
  CALL init_ortho_group( np * np, intra_pool_comm )

  !  if too few resources for parallel diag. switch back to serial one

  IF ( np_ortho( 1 ) == 1 .AND. np_ortho( 2 ) == 1 ) use_para_diag = .FALSE.

  IF ( ionode ) THEN
     !
     WRITE( stdout, '(/,5X,"Subspace diagonalization in iterative solution ",&
                     &     "of the eigenvalue problem:")' ) 
     !
     IF ( use_para_diag ) THEN
        WRITE( stdout, '(5X,"parallel, distributed-memory algorithm ", &
              & "(size of sub-group: ", I2, "*", I3, " procs)",/)') &
               np_ortho(1), np_ortho(2)
     ELSE
        WRITE( stdout, '(5X,"a serial algorithm will be used",/)' )
     END IF
     !
  END IF

  RETURN
END SUBROUTINE check_para_diag
