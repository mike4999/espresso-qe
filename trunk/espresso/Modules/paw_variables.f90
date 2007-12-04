MODULE paw_variables
    !
    USE kinds,      ONLY : DP
    !
    IMPLICIT NONE
    PUBLIC
    SAVE

    !!!!!!!!!!!!!!!!!!!!!!!!
    !!!! Control flags: !!!!

    ! Set to true after initialization, to prevent double allocs:
    LOGICAL              :: paw_is_init = .false.
    ! Analogous to okvan in  "uspp_param" (Modules/uspp.f90)
    LOGICAL :: &
         okpaw = .FALSE.          ! if .TRUE. at least one pseudo is PAW

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!! Pseudopotential data: !!!!

    ! There is no pseudopotential data here, it is all stored in the upf type.
    ! See files pseudo_types.f90 and read_paw.f90

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!! Initialization data: !!!!

    INTEGER,PARAMETER    :: xlm = 2     ! Additional angular momentum to
                                        ! integrate to have a good gradcorr
    INTEGER,PARAMETER    :: radial_grad_style = 0 ! = 0 or 1, algorithm to use for d/dr

    TYPE paw_radial_integrator
        ! the following variables are used to integrate radial sampling
        INTEGER          :: lmax   = 0  ! max l component that can be integrated correctly
        INTEGER          :: lm_max = 0  ! as above, but +1 and squared
        INTEGER          :: nx     = 0  ! number of itegration directions
        REAL(DP),POINTER :: ww(:)       ! integration weights (one per direction)
        REAL(DP),POINTER :: ylm(:,:)    ! Y_lm(nx,lm_max)
        REAL(DP),POINTER :: wwylm(:,:)  ! ww(nx) * Y_lm(nx,lm_max)
        ! additional variables for gradient correction
        REAL(DP),POINTER :: dylmt(:,:),&! |d(ylm)/dtheta|**2
                            dylmp(:,:)  ! |d(ylm)/dphi|**2
        REAL(DP),POINTER :: cotg_th(:)  ! cos(theta)/sin(theta)  (for divergence)
        REAL(DP),POINTER :: r(:,:)      ! DEBUG
    END TYPE
    TYPE(paw_radial_integrator), ALLOCATABLE :: &
        rad(:) ! information to integrate different atomic species

    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    !!!! self-consistent variables: !!!!

    ! We need a place to store the radial AE and pseudo potential,
    ! as different atoms may have different max_lm, and different max(|r|)
    ! using a derived type is the way to go
    TYPE paw_saved_potential
        REAL(DP),POINTER :: &
            v(:,:,:,:)  ! indexes: |r|, lm, spin, {AE|PS}
    END TYPE
    TYPE(paw_saved_potential),ALLOCATABLE :: &
         saved(:) ! allocated in PAW_rad_init

    ! This type contains some useful data that has to be passed to all
    ! functions, but cannot stay in global variables for parallel:
    TYPE paw_info
        INTEGER :: a ! atom index
        INTEGER :: t ! atom type index
        INTEGER :: m ! atom mesh = g(nt)%mesh
        INTEGER :: b ! number of beta functions
        INTEGER :: l ! max angular index l+1 -> (l+1)**2 is max
                     ! lm index, it is used to allocate rho
    END TYPE

    ! Analogous to deeq in "uspp_param" (Modules/uspp.f90)
    REAL(DP), ALLOCATABLE :: &
         ddd_paw(:,:,:,:)  ! AE D: D^1_{ij}         (except for K.E.)
                           ! PS D: \tilde{D}^1_{ij} (except for K.E.)

    ! new vectors needed for mixing of augm. channel occupations
    REAL(DP), ALLOCATABLE :: &
         becnew(:,:,:)       ! new augmentation channel occupations

 END MODULE paw_variables
