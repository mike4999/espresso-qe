!
! Copyright (C) 2002 CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

module bhs
  !     analytical BHS pseudopotential parameters
  use parameters, only: nsx
  implicit none
  save
  real(kind=8) :: rc1(nsx), rc2(nsx), wrc1(nsx), wrc2(nsx), &
       rcl(3,nsx,3), al(3,nsx,3), bl(3,nsx,3)
  integer :: lloc(nsx)
end module bhs

module core
  implicit none
  save
  !     nlcc = 0 no core correction on any atom
  !     rhocb = core charge in G space (box grid)
  integer nlcc
  real(kind=8), allocatable:: rhocb(:,:)
contains
  subroutine deallocate_core()
      IF( ALLOCATED( rhocb ) ) DEALLOCATE( rhocb )
  end subroutine
end module core

module cvan
  !     ionic pseudo-potential variables
  use parameters, only: nsx
  implicit none
  save
  !     nvb    = number of species with Vanderbilt PPs
  !     nh(is) = number of beta functions, including Y_lm, for species is
  !     ish(is)= used for indexing the nonlocal projectors betae
  !              with contiguous indices inl=ish(is)+(iv-1)*na(is)+1
  !              where "is" is the species and iv=1,nh(is)
  !     nhx    = max value of nh(np)
  !     nhsavb = total number of Vanderbilt nonlocal projectors
  !     nhsa   = total number of nonlocal projectors for all atoms
  integer nvb, nhsavb, ish(nsx), nh(nsx), nhsa, nhx
  !     nhtol: nhtol(ind,is)=value of l for projector ind of species is
  !     indv : indv(ind,is) =beta function (without Y_lm) for projector ind
  !     indlm: indlm(ind,is)=Y_lm for projector ind
  integer, allocatable:: nhtol(:,:), indv(:,:), indlm(:,:)
  !     beta = nonlocal projectors in g space without e^(-ig.r) factor
  !     qq   = ionic Q_ij for each species (Vanderbilt only)
  !     dvan = ionic D_ij for each species (Vanderbilt only)
  real(kind=8), allocatable:: beta(:,:,:), qq(:,:,:), dvan(:,:,:)
contains
  subroutine deallocate_cvan()
      IF( ALLOCATED( nhtol ) ) DEALLOCATE( nhtol )
      IF( ALLOCATED( indv ) ) DEALLOCATE( indv )
      IF( ALLOCATED( indlm ) ) DEALLOCATE( indlm )
      IF( ALLOCATED( beta ) ) DEALLOCATE( beta )
      IF( ALLOCATED( qq ) ) DEALLOCATE( qq )
      IF( ALLOCATED( dvan ) ) DEALLOCATE( dvan )
  end subroutine
end module cvan

module elct
  use electrons_base, only: nspin, nel, nupdwn, iupdwn
  use electrons_base, only: n => nbnd, nx => nbndx
  implicit none
  save
  !     f    = occupation numbers
  !     qbac = background neutralizing charge
  real(kind=8), allocatable:: f(:)
  real(kind=8) qbac
  !     nspin = number of spins (1=no spin, 2=LSDA)
  !     nel(nspin) = number of electrons (up, down)
  !     nupdwn= number of states with spin up (1) and down (2)
  !     iupdwn=      first state with spin (1) and down (2)
  !     n     = total number of electronic states
  !     nx    = if n is even, nx=n ; if it is odd, nx=n+1
  !            nx is used only to dimension arrays
  !     ispin = spin of each state
  integer, allocatable:: ispin(:)
  !
contains

  subroutine deallocate_elct()
      IF( ALLOCATED( f ) ) DEALLOCATE( f )
      IF( ALLOCATED( ispin ) ) DEALLOCATE( ispin )
      return
  end subroutine
  !
end module elct

module gvec

  use cell_base, only: tpiba, tpiba2
  use reciprocal_vectors, only: &
        gl, g, gx, g2_g, mill_g, mill_l, ig_l2g, igl, bi1, bi2, bi3
  use reciprocal_vectors, only: deallocate_recvecs
  use recvecs_indexes, only: np, nm, in1p, in2p, in3p, deallocate_recvecs_indexes
  use gvecp, only: &
        ng => ngm, &
        ngl => ngml, &
        ng_g => ngmt

  !     tpiba   = 2*pi/alat
  !     tpiba2  = (2*pi/alat)**2
  !     ng      = number of G vectors for density and potential
  !     ngl     = number of shells of G

  !     G-vector quantities for the thick grid - see also doc in ggen 
  !     g       = G^2 in increasing order (in units of tpiba2=(2pi/a)^2)
  !     gl      = shells of G^2           ( "   "   "    "      "      )
  !     gx      = G-vectors               ( "   "   "  tpiba =(2pi/a)  )
  !
  !     g2_g    = all G^2 in increasing order, replicated on all procs
  !     mill_g  = miller index of G vecs (increasing order), replicated on all procs
  !     mill_l  = miller index of G vecs local to the processors
  !     ig_l2g  = "l2g" means local to global, this array convert a local
  !               G-vector index into the global index, in other words
  !               the index of the G-v. in the overall array of G-vectors
  !     bi?     = base vector used to generate the reciprocal space
  !
  !     np      = fft index for G>
  !     nm      = fft index for G<
  !     in1p,in2p,in3p = G components in crystal axis
  !
  implicit none
  save

contains
  subroutine deallocate_gvec
      CALL deallocate_recvecs( )
      CALL deallocate_recvecs_indexes( )
  end subroutine
end module gvec


module ncprm

  use parameters, only: nsx, ndmx, nqfx, nbrx, lqmax
  implicit none
  save
!
!  lqmax:  maximum angular momentum of Q (Vanderbilt augmentation charges)
!  nqfx :  maximum number of coefficients in Q smoothing
!  nbrx :  maximum number of distinct radial beta functions
!  ndmx:  maximum number of points in the radial grid
! 

!  ifpcor   1 if "partial core correction" of louie, froyen,
!                 & cohen to be used; 0 otherwise
!  nbeta    number of beta functions (sum over all l)
!  kkbeta   last radial mesh point used to describe functions
!                 which vanish outside core
!  nqf      coefficients in Q smoothing
!  nqlc     angular momenta present in Q smoothing
!  lll      lll(j) is l quantum number of j'th beta function
!  lqx      highest angular momentum that is present in Q functions
!  lmaxkb   highest angular momentum that is present in beta functions

  integer :: ifpcor(nsx), nbeta(nsx), kkbeta(nsx), &
       nqf(nsx), nqlc(nsx), lll(nbrx,nsx), lqx, lmaxkb

!  rscore   partial core charge (Louie, Froyen, Cohen)
!  dion     bare pseudopotential D_{\mu,\nu} parameters
!              (ionic and screening parts subtracted out)
!  betar    the beta function on a r grid (actually, r*beta)
!  qqq      Q_ij matrix
!  qfunc    Q_ij(r) function (for r>rinner)
!  rinner   radius at which to cut off partial core or Q_ij
!
!  qfcoef   coefficients to pseudize qfunc for different total
!              angular momentum (for r<rinner)
!  rucore   bare local potential

  real(kind=8) :: rscore(ndmx,nsx), dion(nbrx,nbrx,nsx), &
       betar(ndmx,nbrx,nsx), qqq(nbrx,nbrx,nsx), &
       qfunc(ndmx,nbrx,nbrx,nsx), rucore(ndmx,nbrx,nsx), &
       qfcoef(nqfx,lqmax,nbrx,nbrx,nsx), rinner(lqmax,nsx)
!
! qrl       q(r) functions
!
  real(kind=8) :: qrl(ndmx,nbrx,nbrx,lqmax,nsx)

!  mesh     number of radial mesh points
!  r        logarithmic radial mesh
!  rab      derivative of r(i) (used in numerical integration)
!  cmesh    used only for Herman-Skillman mesh (old format)

  integer :: mesh(nsx)
  real(kind=8) :: r(ndmx,nsx), rab(ndmx,nsx), cmesh(nsx)
end module ncprm

module pseu
  implicit none
  save
  !    rhops = ionic pseudocharges (for Ewald term)
  !    vps   = local pseudopotential in G space for each species
  real(kind=8), allocatable:: rhops(:,:), vps(:,:)
contains
  subroutine deallocate_pseu
      IF( ALLOCATED( rhops ) ) DEALLOCATE( rhops )
      IF( ALLOCATED( vps ) ) DEALLOCATE( vps )
  end subroutine
end module pseu

module qgb_mod
  implicit none
  save
  complex(kind=8), allocatable :: qgb(:,:,:)
contains
  subroutine deallocate_qgb_mod
      IF( ALLOCATED( qgb ) ) DEALLOCATE( qgb )
  end subroutine
end module qgb_mod

module qradb_mod
  implicit none
  save
  real(kind=8), allocatable:: qradb(:,:,:,:,:)
contains
  subroutine deallocate_qradb_mod
      IF( ALLOCATED( qradb ) ) DEALLOCATE( qradb )
  end subroutine
end module qradb_mod

module wfc_atomic
  use parameters, only:nsx
  use ncprm, only:ndmx
  implicit none
  save
  !  nchix=  maximum number of pseudo wavefunctions
  !  nchi =  number of atomic (pseudo-)wavefunctions
  !  lchi =  angular momentum of chi
  !  chi  =  atomic (pseudo-)wavefunctions
  integer :: nchix
  parameter (nchix=6)
  real(kind=8) :: chi(ndmx,nchix,nsx)
  integer :: lchi(nchix,nsx), nchi(nsx)
end module wfc_atomic

module work
  use pseudo_types
  implicit none
  save
  complex(kind=8), allocatable, target:: wrk1(:)
  complex(kind=8), allocatable, target:: wrk2(:,:)
  complex(kind=8), allocatable:: aux(:)
contains
  subroutine deallocate_work
      IF( ALLOCATED( wrk1 ) ) DEALLOCATE( wrk1 )
      IF( ALLOCATED( wrk2 ) ) DEALLOCATE( wrk2 )
      IF( ALLOCATED( aux ) ) DEALLOCATE( aux )
  end subroutine
end module work

module work_box
  implicit none
  save
  complex(kind=8), allocatable, target:: qv(:)
contains
  subroutine deallocate_work_box
      IF( ALLOCATED( qv ) ) DEALLOCATE( qv )
  end subroutine
end module work_box

! Variable cell
module derho
  implicit none
  save
  complex(kind=8),allocatable:: drhog(:,:,:,:)
  real(kind=8),allocatable::     drhor(:,:,:,:)
contains
  subroutine deallocate_derho
      IF( ALLOCATED( drhog ) ) DEALLOCATE( drhog )
      IF( ALLOCATED( drhor ) ) DEALLOCATE( drhor )
  end subroutine
end module derho

module dener
  implicit none
  save
  real(kind=8) detot(3,3), dekin(3,3), dh(3,3), dps(3,3), &
  &       denl(3,3), dxc(3,3), dsr(3,3)
end module dener

module dqgb_mod
  implicit none
  save
  complex(kind=8),allocatable:: dqgb(:,:,:,:,:)
contains
  subroutine deallocate_dqgb_mod
      IF( ALLOCATED( dqgb ) ) DEALLOCATE( dqgb )
  end subroutine
end module dqgb_mod

module dpseu
  implicit none
  save
  real(kind=8),allocatable:: dvps(:,:), drhops(:,:)
contains
  subroutine deallocate_dpseu
      IF( ALLOCATED( dvps ) ) DEALLOCATE( dvps )
      IF( ALLOCATED( drhops ) ) DEALLOCATE( drhops )
  end subroutine
end module dpseu

module cdvan
  implicit none
  save
  real(kind=8),allocatable:: dbeta(:,:,:,:,:), dbec(:,:,:,:), &
                             drhovan(:,:,:,:,:)
contains
  subroutine deallocate_cdvan
      IF( ALLOCATED( dbeta ) ) DEALLOCATE( dbeta )
      IF( ALLOCATED( dbec ) ) DEALLOCATE( dbec )
      IF( ALLOCATED( drhovan ) ) DEALLOCATE( drhovan )
  end subroutine
end module cdvan

