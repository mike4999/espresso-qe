!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
!
! ... Common variables for the phonon program
!  
MODULE modes
  USE kinds,  ONLY : DP
  !
  ! ... The variables needed to describe the modes and the small group of q
  !
  SAVE
  !
  INTEGER :: irgq(48), nsymq, irotmq, nirr, nmodes
  ! selects the operations of the small group
  ! the number of symmetry of the small group
  ! selects the symmetry sending q <-> -q+G
  ! the number of irreducible representation
  !    contained in the dynamical matrix
  ! the number of modes
  INTEGER, ALLOCATABLE, TARGET :: npert(:) !3 * nat )
  ! the number of perturbations per IR
  INTEGER :: npertx, invs(48)
  ! max number of perturbations per IR
  ! the inver of each matrix
  REAL (KIND=DP), ALLOCATABLE :: rtau(:,:,:) !3, 48, nat)
  ! coordinates of direct translations
  REAL (kind=DP) :: gi(3,48), gimq(3)
  ! the possible G associated to each symmetry
  ! the G associated to the symmetry q<->-q+G
  INTEGER, PARAMETER :: max_irr_dim = 4    ! maximal allowed dimension for
                                           ! irreducible representattions
  COMPLEX (KIND=DP), POINTER :: &
       u(:,:),                     &!  3 * nat, 3 * nat),
       ubar(:),                    &!  3 * nat), &
       t(:,:,:,:),                 &! max_irr_dim, max_irr_dim, 48,3 * nat),
       tmq(:,:,:)                   ! max_irr_dim, max_irr_dim, 3 * nat)
  ! the transformation modes patterns
  ! the mode for deltarho
  ! the symmetry in the base of the pattern
  ! the symmetry q<->-q in the base of the pa
  LOGICAL :: &
       minus_q       !  if .TRUE. there is the symmetry sending q<->-q
  !     
END MODULE modes
!
!
MODULE dynmat
  USE kinds, ONLY :  DP
  !
  ! ... The dynamical matrix 
  !
  SAVE
  !
  COMPLEX (KIND=DP), ALLOCATABLE :: &
       dyn00(:,:),           &! 3 * nat, 3 * nat),
       dyn(:,:)               ! 3 * nat, 3 * nat)
  ! the initial dynamical matrix
  ! the dynamical matrix
  REAL (kind=DP), ALLOCATABLE :: &
       w2(:)                  ! 3 * nat)
  ! omega^2
  !
END MODULE dynmat
!
!
MODULE qpoint
  USE kinds, ONLY :  DP
  !
  ! ... The q point
  !
  SAVE
  !
  INTEGER, POINTER :: igkq(:)     ! npwx)
  ! correspondence k+q+G <-> G
  INTEGER :: nksq, npwq
  ! the real number of k points
  ! the number of plane waves for q
  REAL (kind=DP) :: xq(3)
  ! the coordinates of the q point
  COMPLEX (KIND=DP), ALLOCATABLE :: eigqts(:) ! nat)
  ! the phases associated to the q
  !
END MODULE qpoint
!
!
MODULE eqv
  USE kinds, ONLY :  DP
  !
  ! ... The wavefunctions at point k+q 
  !
  SAVE
  !
  COMPLEX (KIND=DP), POINTER :: evq(:,:)
  !
  ! ... The variable describing the linear response problem 
  !
  COMPLEX (KIND=DP), ALLOCATABLE :: dvpsi(:,:), dpsi(:,:)
  ! the product of dV psi
  ! the change of the wavefunctions
  REAL (KIND=DP), ALLOCATABLE :: dmuxc(:,:,:)        ! nrxx, nspin, nspin),
  REAL (KIND=DP), ALLOCATABLE, TARGET :: vlocq(:,:)  ! ngm, ntyp)
  ! the derivative of the xc potential
  ! the local potential at q+G
  !
END MODULE eqv
!
!
MODULE efield
  USE kinds, ONLY :  DP
  !
  ! ... the variables for the electric field perturbation
  !  
  SAVE
  !
  REAL (kind=DP) :: epsilon (3, 3)
  REAL (kind=DP), ALLOCATABLE :: &
       zstareu(:,:,:),       &! 3, 3, nat),
       zstarue(:,:,:)         ! 3, nat, 3)
  ! the dielectric constant
  ! the effective charges Z(E,Us) (E=scf,Us=bare)
  ! the effective charges Z(Us,E) (Us=scf,E=bare)
  COMPLEX (KIND=DP), ALLOCATABLE :: &
       zstareu0(:,:),        &! 3, 3 * nat),
       zstarue0(:,:)          ! 3 * nat, 3)
  ! the effective charges
  !
END MODULE efield
!
!
MODULE nlcc_ph
  USE kinds, ONLY :  DP
  !
  ! ... The variables needed for non-linear core correction
  !
  SAVE
  !
  COMPLEX (KIND=DP), ALLOCATABLE, TARGET :: drc(:,:) ! ngm, ntyp)
  ! contain the rhoc (without structure fac) for all atomic types
  LOGICAL :: nlcc_any
  ! .T. if any atom-type has nlcc
  !
END MODULE nlcc_ph
!
!
MODULE gc_ph
  USE kinds, ONLY :  DP
  !
  ! ... The variables needed for gradient corrected calculations
  !
  SAVE
  !
  REAL (KIND=DP), ALLOCATABLE :: &
       grho(:,:,:),              &! 3, nrxx, nspin),
       dvxc_rr(:,:,:),           &! nrxx, nspin, nspin), &
       dvxc_sr(:,:,:),           &! nrxx, nspin, nspin),
       dvxc_ss(:,:,:),           &! nrxx, nspin, nspin), &
       dvxc_s(:,:,:)              ! nrxx, nspin, nspin)
  ! gradient of the unpert. density
  !
  ! derivatives of the E_xc functiona
  ! r=rho and s=|grad(rho)|
  !
END MODULE gc_ph
!
!
MODULE phus
  USE kinds, ONLY :  DP
  !
  ! ... These are additional variables needed for the linear response
  ! ... program with the US pseudopotentials
  !
  SAVE
  !
  REAL (KIND=DP), ALLOCATABLE :: &
       alphasum(:,:,:,:),   &! nhm*(nhm+1)/2,3,nat,nspin)
                             ! used to compute modes
       dpqq(:,:,:,:)         ! dipole moment of each Q
  COMPLEX (KIND=DP), ALLOCATABLE :: &
       int1(:,:,:,:,:),     &! nhm, nhm, 3, nat, nspin),&
       int2(:,:,:,:,:),     &! nhm, nhm, 3,nat, nat),&
       int3(:,:,:,:,:),     &! nhm, nhm, 3, nat, nspin),&
       int4(:,:,:,:,:),     &! nhm*(nhm+1)/2, 3, 3, nat, nspin),&
       int5(:,:,:,:,:)       ! nhm*(nhm+1)/2, 3, 3, nat, nat),&
  COMPLEX (KIND=DP), ALLOCATABLE, TARGET :: &
       becp1(:,:,:),        &! nkbtot, nbnd, nksq),&
       alphap(:,:,:,:)       ! nkbtot, nbnd, 3, nksq)
  ! integrals of dQ and V_eff
  ! integrals of dQ and V_loc
  ! integrals of Q and dV_Hxc
  ! integrals of d^2Q and V
  ! integrals of dQ and dV_lo
  ! the becq used in ch_psi
  ! the derivative of the bec
  !
END MODULE phus
!
!
MODULE partial
  USE kinds, ONLY :  DP
  !
  ! ... the variables needed for partial computation of dynamical matrix
  !
  SAVE
  !  
  INTEGER, ALLOCATABLE :: &
       comp_irr(:),           &! 3 * nat ),
       ifat(:),               &! nat),
       done_irr(:),           &! 3 * nat), &
       list(:),               &! 3 * nat),
       atomo(:)                ! nat)
  ! if 1 this representation has to be computed
  ! if 1 this matrix element is computed
  ! if 1 this representation has been done
  ! a list of representations
  ! which atom
  INTEGER :: nat_todo, nrapp
  ! number of atoms to compute
  ! The representation to do
  LOGICAL :: all_comp
  ! if .TRUE. all representation have been computed
  !
END MODULE partial
!
!
MODULE control_ph
  USE kinds, ONLY :  DP
  USE parameters, ONLY: npk
  !
  ! ... the variable controlling the phonon run
  !
  SAVE
  !
  INTEGER, PARAMETER :: maxter = 100
  ! maximum number of iterations
  INTEGER :: niter_ph, nmix_ph, nbnd_occ(npk), irr0, iter0, maxirr
  ! maximum number of iterations (read from input)
  ! mixing type
  ! occupated bands in metals
  ! starting representation
  ! starting iteration
  ! maximum number of representation
  REAL (KIND=DP) :: tr2_ph, alpha_mix(maxter), time_now, alpha_pv
  ! convergence threshold
  ! the mixing parameter
  ! CPU time up to now
  ! the alpha value for shifting the bands
  LOGICAL :: lgamma, convt, epsil, trans, elph, zue, recover
  ! if .TRUE. this is a q=0 computation
  ! if .TRUE. the phonon has converged
  ! if .TRUE. computes dielec. const and eff. c
  ! if .TRUE. computes phonons
  ! if .TRUE. computes electron-phonon interact
  ! if .TRUE. computes eff.cha. with ph
  ! if .TRUE. the run restart
  !
END MODULE control_ph
!
!
MODULE char_ph
  !
  ! ... a character common for phonon
  !
  SAVE
  !
  CHARACTER(LEN=75) :: title_ph  ! * 75
  ! title of the phonon run
  !
END MODULE char_ph
!
!
MODULE units_ph
  !
  ! ... the units of the files and the record lengths
  !
  SAVE
  !
  INTEGER :: &
       iuwfc, lrwfc, iuvkb, iubar, lrbar, iuebar, lrebar, iudwf, iupsir, &
       lrdwf, iudrhous, lrdrhous, iudyn, iupdyn, iunrec, iudvscf, iudrho, &
       lrdrho, iucom, lrcom, iudvkb3, lrdvkb3
  ! iunit with the wavefunctions
  ! the length of wavefunction record
  ! unit with vkb
  ! unit with the part DV_{bare}
  ! length of the DV_{bare}
  ! unit with D psi
  ! unit with evc in real space
  ! length of D psi record
  ! the unit with the products
  ! the lenght of the products
  ! the unit for the dynamical matrix
  ! the unit for the partial dynamical matrix
  ! the unit with the recover data
  ! the unit where the delta Vscf is written
  ! the unit where the delta rho is written
  ! the length of the deltarho files
  ! the unit of the bare commutator in US case
  ! the length  of the bare commutator in US case
  logical, ALLOCATABLE :: this_dvkb3_is_on_file(:), &
                          this_pcxpsi_is_on_file(:,:)
  !
END MODULE units_ph
!
!
MODULE output
  !
  ! ... the name of the files
  !
  SAVE
  !
  CHARACTER (LEN=80) :: fildyn, filelph, fildvscf, fildrho
  ! output file for the dynamical matrix
  ! output file for electron-phonon coefficie
  ! output file for deltavscf
  ! output file for deltarho
  !
END MODULE output
!
!
MODULE phcom
  USE modes
  USE dynmat
  USE qpoint
  USE eqv
  USE efield
  USE nlcc_ph
  USE gc_ph
  USE phus
  USE partial
  USE control_ph
  USE char_ph
  USE units_ph
  USE output
END MODULE phcom
