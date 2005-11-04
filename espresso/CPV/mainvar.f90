!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!----------------------------------------------------------------------------
MODULE cp_main_variables
  !----------------------------------------------------------------------------
  !
  USE kinds,             ONLY : DP
  USE parameters,        ONLY : natx, nsx, nacx
  USE control_flags,     ONLY : program_name
  USE funct,             ONLY : dft_is_meta
  USE metagga,           ONLY : kedtaur, kedtaus, kedtaug
  USE atoms_type_module, ONLY : atoms_type
  USE cell_base,         ONLY : boxdimensions
  USE charge_types,      ONLY : charge_descriptor, charge_descriptor_init
  USE wave_types,        ONLY : wave_descriptor, wave_descriptor_init
  USE energies,          ONLY : dft_energy_type
  !
  IMPLICIT NONE
  SAVE
  !
  ! ... structure factors e^{-ig*R}
  !
  ! ...  G = reciprocal lattice vectors
  ! ...  R_I = ionic positions
  !
  COMPLEX(DP), ALLOCATABLE :: eigr(:,:)        ! exp (i G   dot R_I)
  COMPLEX(DP), ALLOCATABLE :: ei1(:,:)         ! exp (i G_x dot x_I)
  COMPLEX(DP), ALLOCATABLE :: ei2(:,:)         ! exp (i G_y dot y_I)
  COMPLEX(DP), ALLOCATABLE :: ei3(:,:)         ! exp (i G_z dot z_I)
  !
  ! ... structure factors (summed over atoms of the same kind)
  !
  ! S( s, G ) = sum_(I in s) exp( i G dot R_(s,I) )
  ! s       = index of the atomic specie
  ! R_(s,I) = position of the I-th atom of the "s" specie
  !
  COMPLEX(DP), ALLOCATABLE:: sfac(:,:)
  !
  ! ... indexes, positions, and structure factors for the box grid
  !
  REAL(DP)                 :: taub(3,natx)
  COMPLEX(DP), ALLOCATABLE :: eigrb(:,:)
  INTEGER,           ALLOCATABLE :: irb(:,:)
  ! 
  ! ... nonlocal projectors:
  ! ...    bec   = scalar product of projectors and wave functions
  ! ...    betae = nonlocal projectors in g space = beta x e^(-ig.R) 
  ! ...    becdr = <betae|g|psi> used in force calculation
  ! ...    rhovan= \sum_i f(i) <psi(i)|beta_l><beta_m|psi(i)>
  ! ...    deeq  = \int V_eff(r) q_lm(r) dr
  !
  REAL(DP), ALLOCATABLE :: bec(:,:), becdr(:,:,:)
  REAL(DP), ALLOCATABLE :: bephi(:,:), becp(:,:)
  !
  ! ... mass preconditioning
  !
  REAL(DP), ALLOCATABLE :: ema0bg(:)
  !
  ! ... constraints (lambda at t, lambdam at t-dt, lambdap at t+dt)
  !
  REAL(DP), ALLOCATABLE :: lambda(:,:), lambdam(:,:), lambdap(:,:)
  !
  REAL(DP) :: acc(nacx)
  REAL(DP) :: acc_this_run(nacx)
  !
  ! atomic positions
  !
  TYPE (atoms_type) :: atoms0, atomsp, atomsm
  !
  ! cell geometry
  !
  TYPE (boxdimensions) :: htm, ht0, htp  ! cell metrics
  !
  ! charge densities and potentials
  !
  REAL(DP), ALLOCATABLE :: rhoe(:,:,:,:)     ! charge density in real space
  REAL(DP), ALLOCATABLE :: vpot(:,:,:,:)
  TYPE (charge_descriptor)  :: desc           ! charge density descriptor
  !
  ! rhog  = charge density in g space
  ! rhor  = charge density in r space (dense grid)
  ! rhos  = charge density in r space (smooth grid)
  ! rhopr   since rhor is overwritten in vofrho,
  !         this array is used to save rhor for restart file
  !
  COMPLEX(DP), ALLOCATABLE :: rhog(:,:)
  REAL(DP),    ALLOCATABLE :: rhor(:,:), rhos(:,:)
  REAL(DP),    ALLOCATABLE :: rhopr(:,:)  
  !
  TYPE (wave_descriptor) :: wfill, wempt    ! wave function descriptor
                                            ! for filled and empty states
  !
  REAL(DP), ALLOCATABLE :: occn(:,:,:)     ! occupation numbers for filled state
  !
  TYPE (dft_energy_type) :: edft
  !
  INTEGER                :: nfi             ! counter on the electronic iterations
  !
  CONTAINS
    !
    !------------------------------------------------------------------------
    SUBROUTINE allocate_mainvar( ngw, ngwt, ngb, ngs, ng, nr1, nr2, nr3, nr1x, & 
                                 nr2x, npl, nnr, nnrsx, nat, nax, nsp, nspin,  &
                                 n, nx, n_emp, nupdwn, nhsa, gzero, nkpt,      &
                                 kscheme, smd )
      !------------------------------------------------------------------------
      !
      INTEGER,           INTENT(IN) :: ngw, ngwt, ngb, ngs, ng, nr1, nr2, nr3, &
                                       nnr, nnrsx, nat, nax, nsp, nspin, &
                                       n, nx, n_emp, nhsa, nr1x, nr2x, npl
      INTEGER,           INTENT(IN) :: nupdwn(:)
      INTEGER,           INTENT(IN) :: nkpt
      CHARACTER(LEN=*),  INTENT(IN) :: kscheme
      LOGICAL,           INTENT(IN) :: gzero
      LOGICAL, OPTIONAL, INTENT(IN) :: smd
      LOGICAL                       :: nosmd
      INTEGER                       :: neupdwn( nspin )
      !
      ! ... allocation of all arrays not already allocated in init and nlinit
      !
      nosmd = .TRUE.
      !
      IF ( PRESENT( smd ) ) THEN
         !
         IF( smd ) nosmd = .FALSE.
         !
      END IF
      !
      ALLOCATE( eigr( ngw, nat ) )
      ALLOCATE( sfac( ngs, nsp ) )
      ALLOCATE( ei1( -nr1:nr1, nat ) )
      ALLOCATE( ei2( -nr2:nr2, nat ) )
      ALLOCATE( ei3( -nr3:nr3, nat ) )
      ALLOCATE( eigrb( ngb, nat ) )
      ALLOCATE( irb( 3, nat ) )
      !
      IF ( dft_is_meta() ) THEN
         !
         ! ... METAGGA
         !
         ALLOCATE( kedtaur( nnr,   nspin ) )
         ALLOCATE( kedtaus( nnrsx, nspin ) )
         ALLOCATE( kedtaug( ng,    nspin ) )
         !
      ELSE
         !
         ! ... dummy allocation required because this array appears in the
         ! ... list of arguments of some routines
         !
         ALLOCATE( kedtaur( 1, nspin ) )
         ALLOCATE( kedtaus( 1, nspin ) )
         ALLOCATE( kedtaug( 1, nspin ) )
         !
      END IF
      !
      ALLOCATE( ema0bg( ngw ) )
      !
      IF( program_name == 'CP90' ) THEN
         !
         ALLOCATE( rhopr( nnr,   nspin ) )
         ALLOCATE( rhor( nnr,   nspin ) )
         ALLOCATE( rhos( nnrsx, nspin ) )
         ALLOCATE( rhog( ng,    nspin ) )
         !
         IF ( nosmd ) THEN
            !
            ALLOCATE( lambda(  nx, nx ) )
            ALLOCATE( lambdam( nx, nx ) )
            ALLOCATE( lambdap( nx, nx ) )
            !
         END IF
         !
      ELSE IF( program_name == 'FPMD' ) THEN
         !
         ALLOCATE( rhoe( nr1x, nr2x, npl, nspin ) )
         !
         CALL charge_descriptor_init( desc, nr1, nr2, nr3, &
             nr1, nr2, npl, nr1x, nr2x, npl, nspin )
         !
         ALLOCATE( vpot( nr1x, nr2x, npl, nspin ) )
         !
      END IF
      !
      ALLOCATE( becdr( nhsa, n, 3 ) )
      !
      IF ( nosmd ) ALLOCATE( bec( nhsa, n ) )
      !
      ALLOCATE( bephi( nhsa, n ) )
      ALLOCATE( becp(  nhsa, n ) )
      !
      !  empty states, always same number of spin up and down states
      !
      neupdwn( 1:nspin ) = n_emp
      !
      CALL wave_descriptor_init( wfill, ngw, ngwt, nupdwn,  nupdwn, &
            nkpt, nkpt, nspin, kscheme, gzero )
      !
      CALL wave_descriptor_init( wempt, ngw, ngwt, neupdwn, neupdwn, &
            nkpt, nkpt, nspin, kscheme, gzero )
      !
      IF( program_name == 'FPMD' ) THEN
         !
         ALLOCATE( occn( wfill%ldb, wfill%ldk, wfill%lds ) )
         !
      END IF
      !
      RETURN
      !
    END SUBROUTINE allocate_mainvar
    !
    !------------------------------------------------------------------------
    SUBROUTINE deallocate_mainvar()
      !------------------------------------------------------------------------
      !
      IF( ALLOCATED( ei1 ) )     DEALLOCATE( ei1 )
      IF( ALLOCATED( ei2 ) )     DEALLOCATE( ei2 )
      IF( ALLOCATED( ei3 ) )     DEALLOCATE( ei3 )
      IF( ALLOCATED( eigr ) )    DEALLOCATE( eigr )
      IF( ALLOCATED( sfac ) )    DEALLOCATE( sfac )
      IF( ALLOCATED( eigrb ) )   DEALLOCATE( eigrb )
      IF( ALLOCATED( irb ) )     DEALLOCATE( irb )
      IF( ALLOCATED( rhopr ) )   DEALLOCATE( rhopr )
      IF( ALLOCATED( rhor ) )    DEALLOCATE( rhor )
      IF( ALLOCATED( rhos ) )    DEALLOCATE( rhos )
      IF( ALLOCATED( rhog ) )    DEALLOCATE( rhog )
      IF( ALLOCATED( bec ) )     DEALLOCATE( bec )
      IF( ALLOCATED( becdr ) )   DEALLOCATE( becdr )
      IF( ALLOCATED( bephi ) )   DEALLOCATE( bephi )
      IF( ALLOCATED( becp ) )    DEALLOCATE( becp )
      IF( ALLOCATED( ema0bg ) )  DEALLOCATE( ema0bg )
      IF( ALLOCATED( lambda ) )  DEALLOCATE( lambda )
      IF( ALLOCATED( lambdam ) ) DEALLOCATE( lambdam )
      IF( ALLOCATED( lambdap ) ) DEALLOCATE( lambdap )
      IF( ALLOCATED( kedtaur ) ) DEALLOCATE( kedtaur )
      IF( ALLOCATED( kedtaus ) ) DEALLOCATE( kedtaus )
      IF( ALLOCATED( kedtaug ) ) DEALLOCATE( kedtaug )
      IF( ALLOCATED( rhoe ) )    DEALLOCATE( rhoe )
      IF( ALLOCATED( vpot ) )    DEALLOCATE( vpot )
      IF( ALLOCATED( occn ) )    DEALLOCATE( occn )
      !
      RETURN
      !
    END SUBROUTINE deallocate_mainvar
    !
END MODULE cp_main_variables
