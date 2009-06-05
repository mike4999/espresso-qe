module xspectra
  use kinds, only : DP
  implicit none
  SAVE
   real(kind=DP) :: &
        xgamma,     &           ! xanes broadening parameter 
        xerror,     &           ! error between 2 successive spectra
        xemax,      &           ! max energy of the xanes window
        xemin,      &           ! min energy of the xanes window
        ef_r                    ! Fermi energy in input

   real(kind=DP) ::  &
        xkvec(3)        !coordinates of wave vector

   real(kind=DP) :: &
        xepsilon(3)      !epsilon vector used for quadrupole xanes calculation

   real(kind=DP), allocatable :: xanes_dip(:)      ! The  xanes mat. ele (dipole)
   real(kind=DP), allocatable :: xanes_qua(:)      ! The  xanes mat. ele (quad)

   integer :: &
        xnepoint, &        ! # of energy points in the xanes window
        xniter,   &        ! # of iterations between 2 error-calculations
        xnitermax,  &      ! # of iterations used for dimension of a and b
        xang_mom,   &      ! angular momentum of the final state
        xiabs,          &  ! Identificateur de l'Atom absorbeur
        xcheck_conv        ! Check convergency every xcheck_conv iterations

   logical :: &
        xonly_plot, &         ! key word for only XANES plot job
        xread_wf,   &         ! key word for reading wavefunctions
        xcoordcrys           ! kew word for epsilon and k in crystalline k.

   character(LEN=256) :: x_save_file
   character(LEN=16) :: U_projection_type

   integer :: save_file_version          ! versionning of save file
   character (len=32) :: save_file_kind
   integer :: n_lanczos                  ! number of lanczos computed

   real(dp) :: time_limit                ! after this limit, save a and b
   integer, allocatable :: calculated(:,:) ! list of calculated k-points
   character (len=32) :: restart_mode   

end module xspectra

module cut_valence_green
  use kinds, only : DP
  implicit none
  SAVE
  logical ::&
          cut_occ_states        ! true if you want tou remove occupied states from the spectrum


  real (kind=DP) ::&
          cut_ierror, &    ! convergence tolerance for one step in the integral
          cut_stepu , &    ! integration initial step, upper side
          cut_stepl , &    ! integration initial step, lower side
          cut_startt, &    ! integration start value of the t variable
          cut_tinf  , &    ! maximum value of the lower integration boundary
          cut_tsup  , &    ! minimum value of the upper integration boudary
          cut_desmooth    ! size of the interval near the fermi energy in which cross section
                          ! is smoothed to avoid singuarity, in eV
          

  integer ::&
          cut_nmemu,&      ! size of the memory of the values of the green function, upper side
          cut_nmeml       ! size of the memory of the values of the green function, lower side

  complex (kind=dp), allocatable :: memu(:,:), meml(:,:) ! table of the values of the green function, upper and lower side

end module

module xspectra_paw_variables
use kinds, only : dp
integer :: xspectra_paw_nhm

contains

subroutine init_xspectra_paw_nhm
  use paw_gipaw, only : paw_recon
  USE ions_base,          ONLY : ntyp => nsp
  implicit none
  integer :: i

  xspectra_paw_nhm=0
  do i=1, ntyp
    if (paw_recon(i)%paw_nh>xspectra_paw_nhm) xspectra_paw_nhm=paw_recon(i)%paw_nh
  enddo  

end subroutine init_xspectra_paw_nhm

end module xspectra_paw_variables

module gamma_variable_mod
   use kinds, only : DP
   integer :: gamma_lines        ! # of lines of gamma_file
   real(kind=DP), allocatable :: gamma_tab(:),&    ! to store tabulated values of gamma
                                 gamma_points(:,:)
   character(len=256) :: gamma_mode, gamma_file ! useful for non constant xgamma

end module gamma_variable_mod

