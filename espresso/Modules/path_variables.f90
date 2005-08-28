!
! Copyright (C) 2003-2005 PWSCF-FPMD-CPV group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------------------
MODULE path_variables
  !---------------------------------------------------------------------------
  !
  ! ... This module contains all variables needed by path optimisations
  !
  ! ... Written by Carlo Sbraccia ( 2003-2005 )
  !
  USE kinds,  ONLY : DP
  !
  IMPLICIT NONE
  !
  SAVE
  !
  INTEGER, PARAMETER :: history_ndim = 8
  !
  ! ... "general" variables :
  !
  LOGICAL :: &
       conv_path                  ! .TRUE. if "path" convergence has been
                                  !        achieved
  LOGICAL :: &
       first_last_opt,           &! if .TRUE. the first and the last image
                                  !           are optimised too.
       use_fourier,              &! if .TRUE. a Fourier representation of
                                  !           the path is used
       use_multistep,            &! if .TRUE. a multistep algorithm is used 
                                  !           in smd optimization
       use_masses,               &! if .TRUE. mass weighted coordinates are 
                                  !           used
       write_save,               &! if .TRUE. the save file is written for each
                                  !           image
       free_energy,              &! if .TRUE. a free-energy calculations is done
       fixed_tan,                &! if. TRUE. the projection is done using the
                                  !           tangent of the average path
       use_freezing,             &! if .TRUE. images are optimised according
                                  !           to their error (see frozen array)
       tune_load_balance          ! if .TRUE. the load balance for image
                                  !           parallelisation is tuned at 
                                  !           runtime
  INTEGER :: &
       dim,                      &! dimension of the configuration space
       num_of_images,            &! number of images
       init_num_of_images,       &! number of images used in the initial
                                  ! discretization (SMD only)
       deg_of_freedom,           &! number of degrees of freedom 
                                  ! ( dim - #( of fixed coordinates ) )
       suspended_image            ! last image for which scf has not been
                                  ! achieved
  REAL (DP) :: &
       ds,                       &! the optimization step
       path_thr,                 &! convergence threshold
       damp,                     &! damp coefficient
       temp_req,                 &! required temperature
       activation_energy,        &! forward activatation energy
       err_max,                  &! the largest error
       path_length                ! length of the path
  LOGICAL :: &
       lsteep_des  = .FALSE.,    &! .TRUE. if opt_scheme = "sd"
       lquick_min  = .FALSE.,    &! .TRUE. if opt_scheme = "quick-min"
       ldamped_dyn = .FALSE.,    &! .TRUE. if opt_scheme = "damped-dyn"
       lmol_dyn    = .FALSE.,    &! .TRUE. if opt_scheme = "mol-dyn"
       lbroyden    = .FALSE.,    &! .TRUE. if opt_scheme = "broyden"
       llangevin   = .FALSE.      ! .TRUE. if opt_scheme = "langevin"
  INTEGER :: &                   
       istep_path,               &! iteration in the optimization procedure
       nstep_path                 ! maximum number of iterations
  LOGICAL :: &
       reset_broyden = .FALSE.    ! used to reset the broyden subspace
  !
  ! ... "general" real space arrays
  !
  REAL (DP), ALLOCATABLE :: &
       pes(:),                   &! the potential enrgy along the path
       norm_tangent(:),          &!
       error(:)                   ! the error from the true MEP
  REAL (DP), ALLOCATABLE :: &
       pos(:,:),                 &! 
       grad_pes(:,:),            &!
       tangent(:,:)               !
  LOGICAL, ALLOCATABLE :: &
       frozen(:)                  ! .TRUE. if the image or mode has not 
                                  !        to be optimized
  !
  ! ... "neb specific" variables :
  !
  LOGICAL, ALLOCATABLE :: &
       climbing(:)                ! .TRUE. if the image is required to climb
  CHARACTER (LEN=20) :: &
       CI_scheme                  ! Climbing Image scheme
  INTEGER :: &
       Emax_index                 ! index of the image with the highest energy
  !
  REAL (DP) :: &
       k_max,                    &! 
       k_min,                    &!
       Eref,                     &!
       Emax,                     &!
       Emin                       !
  !
  ! ... real space arrays
  !
  REAL (DP), ALLOCATABLE :: &
       elastic_grad(:),          &!
       mass(:),                  &! atomic masses
       k(:),                     &!  
       react_coord(:),           &! the reaction coordinate (in bohr)
       norm_grad(:)               !
  REAL (DP), ALLOCATABLE :: &
       vel(:,:),                 &! 
       grad(:,:),                &!
       lang(:,:)                  ! langevin random force
  !
  ! ... "smd specific" variables :
  !
  INTEGER :: &
       num_of_modes               ! number of modes
  INTEGER :: &
       Nft,                      &! number of discretization points in the
                                  ! discrete fourier transform
       Nft_smooth                 ! smooth real-space grid
  REAL (DP) :: &
       ft_coeff                   ! normalization in fourier transformation
  !
  !
  ! ... real space arrays
  !
  REAL (DP), ALLOCATABLE :: &
       pos_star(:,:)              !
  !
  ! ... reciprocal space arrays
  !
  REAL (DP), ALLOCATABLE :: &
       ft_pos(:,:)                ! fourier components of the path
  !
  ! ... Y. Kanai variabiles for combined smd/cp dynamics :
  !
  INTEGER, PARAMETER :: smx = 20    ! max number of images
  INTEGER, PARAMETER :: smmi = 4    ! a parameter for  polynomial interpolation
                                    ! # of replicas used for interpolation
  LOGICAL :: &
       smd_cp,                     &! regular CP calculation
       smd_lm,                     &! String method w/ Lagrange Mult.
       smd_opt,                    &! CP for 2 replicas, initial & final
       smd_linr,                   &! linear interpolation
       smd_polm,                   &! polynomial interpolation
       smd_stcd
  INTEGER :: &
       smd_p,                      &! sm_p = 0 .. SM_P replica
       smd_kwnp,                   &! # of points used in polm
       smd_codfreq,                &!
       smd_forfreq,                &! frequency of calculating Lag. Mul
       smd_wfreq,                  &!
       smd_lmfreq,                 &
       smd_maxlm                    ! max_ite = # of such iteration allowed
  REAL(DP) :: &
       smd_tol,                    &! tolrance on const in terms of
                                    ! [alpha(k) - alpha(k-1)] - 1/sm_P
       smd_ene_ini = 1.D0,         &
       smd_ene_fin = 1.D0
  !
  TYPE smd_ptr
    !
    REAL(DP), POINTER :: d3(:,:)
    !
  END TYPE smd_ptr
  !
  CONTAINS
     !
     !----------------------------------------------------------------------
     SUBROUTINE path_allocation( method )
       !----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER (LEN=*), INTENT(IN) :: method
       !
       !
       ALLOCATE( pos( dim, num_of_images ) )
       !
       ALLOCATE( vel( dim, num_of_images ) ) 
       !
       ALLOCATE( grad(     dim, num_of_images ) )
       ALLOCATE( grad_pes( dim, num_of_images ) )
       ALLOCATE( tangent(  dim, num_of_images ) )
       !
       ALLOCATE( react_coord( num_of_images ) )
       ALLOCATE( norm_grad(   num_of_images ) )
       ALLOCATE( pes(         num_of_images ) )
       ALLOCATE( k(           num_of_images ) )
       ALLOCATE( error(       num_of_images ) )
       ALLOCATE( climbing(    num_of_images ) )
       ALLOCATE( frozen(      num_of_images ) )
       !
       ALLOCATE( mass(         dim ) )
       ALLOCATE( elastic_grad( dim ) )
       !
       IF ( method == "smd" ) THEN
          !
          ALLOCATE( pos_star( dim, 0:( Nft - 1 ) ) )
          !
          ALLOCATE( ft_pos( dim, ( Nft - 1 ) ) )
          !
          IF ( llangevin ) THEN
             !
             ALLOCATE( lang( dim, num_of_images ) )
             !
          END IF
          !
       END IF
       !
     END SUBROUTINE path_allocation     
     !
     !
     !----------------------------------------------------------------------
     SUBROUTINE path_deallocation( method )
       !----------------------------------------------------------------------
       !
       IMPLICIT NONE
       !
       CHARACTER (LEN=*), INTENT(IN) :: method
       !
       !
       IF ( ALLOCATED( pos ) )            DEALLOCATE( pos )
       IF ( ALLOCATED( vel ) )            DEALLOCATE( vel )
       IF ( ALLOCATED( grad ) )           DEALLOCATE( grad )
       IF ( ALLOCATED( react_coord ) )    DEALLOCATE( react_coord )
       IF ( ALLOCATED( norm_grad ) )      DEALLOCATE( norm_grad )
       IF ( ALLOCATED( pes ) )            DEALLOCATE( pes )
       IF ( ALLOCATED( grad_pes ) )       DEALLOCATE( grad_pes )
       IF ( ALLOCATED( k ) )              DEALLOCATE( k )
       IF ( ALLOCATED( mass ) )           DEALLOCATE( mass )
       IF ( ALLOCATED( elastic_grad ) )   DEALLOCATE( elastic_grad )
       IF ( ALLOCATED( tangent ) )        DEALLOCATE( tangent ) 
       IF ( ALLOCATED( error ) )          DEALLOCATE( error )
       IF ( ALLOCATED( climbing ) )       DEALLOCATE( climbing )
       IF ( ALLOCATED( frozen ) )         DEALLOCATE( frozen )
       !
       IF ( method == "smd" ) THEN
          !
          IF ( ALLOCATED( pos_star ) )    DEALLOCATE( pos_star )
          !
          IF ( ALLOCATED( ft_pos ) )      DEALLOCATE( ft_pos )
          !
          IF ( llangevin ) THEN
             !
             IF ( ALLOCATED( lang ) )     DEALLOCATE( lang )
             !
          END IF
          !
       END IF
       !
     END SUBROUTINE path_deallocation
     !
END MODULE path_variables
