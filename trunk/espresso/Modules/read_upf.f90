
! Copyright (C) 2002-2007 Quantum-Espresso group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

!=----------------------------------------------------------------------------=!
      MODULE read_upf_module
!=----------------------------------------------------------------------------=!

!  this module handles the reading of pseudopotential data

! ...   declare modules
        USE kinds, ONLY: DP
        IMPLICIT NONE
        SAVE
        PRIVATE
        PUBLIC :: read_pseudo_upf, scan_begin, scan_end
      CONTAINS
!
!---------------------------------------------------------------------
subroutine read_pseudo_upf (iunps, upf, ierr, header_only)  
  !---------------------------------------------------------------------
  !
  !   read pseudopotential "upf" in the Unified Pseudopotential Format
  !   from unit "iunps" - return error code in "ierr" (success: ierr=0)
  !
  use pseudo_types
  !
  implicit none
  !
  INTEGER, INTENT(IN) :: iunps
  INTEGER, INTENT(OUT) :: ierr 
  LOGICAL, INTENT(IN), OPTIONAL :: header_only
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  !     Local variables
  !
  integer :: ios
  character (len=80) :: dummy  
  logical, external :: matches
  !
  !
  CALL nullify_pseudo_upf( upf )
  !
  ! First check if this pseudo-potential has spin-orbit information 
  !
  ierr = 1  
  ios = 0
  upf%q_with_l=.false.
  upf%has_so=.false.
  upf%has_paw = .false.
  upf%has_gipaw = .false.
  addinfo_loop: do while (ios == 0)  
     read (iunps, *, iostat = ios, err = 200) dummy  
     if (matches ("<PP_ADDINFO>", dummy) ) then
        upf%has_so=.true.
     endif
     if ( matches ( "<PP_PAW>", dummy ) ) then
        upf%has_paw = .true.
     endif
     if ( matches ( "<PP_GIPAW_RECONSTRUCTION_DATA>", dummy ) ) then
        upf%has_gipaw = .true.
     endif
     if (matches ("<PP_QIJ_WITH_L>", dummy) ) then
        upf%q_with_l=.true. 
     endif
  enddo addinfo_loop
  
  !------->Search for Header
  !     This version doesn't use the new routine scan_begin
  !     because this search must set extra flags for
  !     compatibility with other pp format reading
  ierr = 1  
  ios = 0
  rewind(iunps)
  header_loop: do while (ios == 0)  
     read (iunps, *, iostat = ios, err = 200) dummy  
     if (matches ("<PP_HEADER>", dummy) ) then  
        ierr = 0
        call read_pseudo_header (upf, iunps)  
        exit header_loop
     endif
  enddo header_loop
  !
  ! this should be read from the PP_INFO section
  !
  upf%generated='Generated by new atomic code, or converted to UPF format'

  IF ( PRESENT (header_only) ) THEN
     IF ( header_only ) RETURN
  END IF
  if (ierr .ne. 0) return
  
  call scan_end (iunps, "HEADER")  

  ! WRITE( stdout, * ) "Reading pseudopotential file in UPF format"  

  !-------->Search for mesh information
  call scan_begin (iunps, "MESH", .true.)  
  call read_pseudo_mesh (upf, iunps)  
  call scan_end (iunps, "MESH")  
  !-------->If  present, search for nlcc
  if ( upf%nlcc ) then  
     call scan_begin (iunps, "NLCC", .true.)  
     call read_pseudo_nlcc (upf, iunps)  
     call scan_end (iunps, "NLCC")  
  else
     ALLOCATE( upf%rho_atc( upf%mesh ) )
     upf%rho_atc = 0.0_DP
  endif
  !-------->Fake 1/r potential: do not read PP
  if (.not. matches (upf%typ, "1/r") ) then
  !-------->Search for Local potential
     call scan_begin (iunps, "LOCAL", .true.)  
     call read_pseudo_local (upf, iunps)  
     call scan_end (iunps, "LOCAL")  
  !-------->Search for Nonlocal potential
     call scan_begin (iunps, "NONLOCAL", .true.)  
     call read_pseudo_nl (upf, iunps)  
     call scan_end (iunps, "NONLOCAL")  
  !--------
  end if
  !-------->Search for atomic wavefunctions
  call scan_begin (iunps, "PSWFC", .true.)  
  call read_pseudo_pswfc (upf, iunps)  
  call scan_end (iunps, "PSWFC")  
  !-------->Search for atomic charge
  call scan_begin (iunps, "RHOATOM", .true.)  
  call read_pseudo_rhoatom (upf, iunps)  
  call scan_end (iunps, "RHOATOM")  
  !-------->Search for add_info
  if (upf%has_so) then
     call scan_begin (iunps, "ADDINFO", .true.)  
     call read_pseudo_addinfo (upf, iunps)  
     call scan_end (iunps, "ADDINFO")  
  endif
  !-------->PAW data
  if ( upf%has_paw ) then
     call scan_begin ( iunps, "PAW", .true. )
     call read_pseudo_paw ( upf, iunps )
     call scan_end ( iunps, "PAW" )
  endif

200 return

end subroutine read_pseudo_upf
!---------------------------------------------------------------------


subroutine scan_begin (iunps, string, rew)  
  !---------------------------------------------------------------------
  !
  implicit none
  ! Unit of the input file
  integer :: iunps  
  ! Label to be matched
  character (len=*) :: string  
  ! String read from file
  character (len=75) :: rstring  
  ! Flag if .true. rewind the file
  logical, external :: matches
  logical :: rew  
  integer :: ios

  ios = 0
  if (rew) rewind (iunps)  
  do while (ios==0)  
     read (iunps, *, iostat = ios, err = 300) rstring  
     if (matches ("<PP_"//string//">", rstring) ) return  
  enddo
  return
300 call errore ('scan_begin', 'No '//string//' block', abs (ios) )  
end subroutine scan_begin
!---------------------------------------------------------------------

subroutine scan_end (iunps, string)  
  !---------------------------------------------------------------------
  implicit none
  ! Unit of the input file
  integer :: iunps
  ! Label to be matched
  character (len=*) :: string  
  ! String read from file
  character (len=75) :: rstring
  logical, external :: matches

  read (iunps, '(a)', end = 300, err = 300) rstring  
  if (matches ("</PP_"//string//">", rstring) ) return  
  return
300 call errore ('scan_end', &
       'No '//string//' block end statement, possibly corrupted file',  -1)
end subroutine scan_end
!
!---------------------------------------------------------------------

subroutine read_pseudo_header (upf, iunps)  
  !---------------------------------------------------------------------
  !
  USE pseudo_types, ONLY: pseudo_upf
  USE kinds

  implicit none
  !
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  integer :: iunps  
  !
  integer :: nw  
  character (len=80) :: dummy  
  logical, external :: matches

  ! Version number (presently ignored)
  read (iunps, *, err = 100, end = 100) upf%nv , dummy  
  ! Element label
  read (iunps, *, err = 100, end = 100) upf%psd , dummy  
  ! Type of pseudo
  read (iunps, *, err = 100, end = 100) upf%typ  
  if (matches (upf%typ, "US") ) then
     upf%tvanp = .true.  
     upf%tpawp = .false.  
  else if (matches (upf%typ, "PAW") ) then
     ! Note: if tvanp is set to false the results are wrong!
     upf%tvanp = .true.  
     upf%tpawp = .true.  
  else if (matches (upf%typ, "NC") ) then
     upf%tvanp = .false.  
     upf%tpawp = .false.  
  else if (matches (upf%typ, "1/r") ) then
     upf%tvanp = .false.  
     upf%tpawp = .false.  
  else
     call errore ('read_pseudo_header', 'unknown pseudo type', 1)
  endif

  read (iunps, *, err = 100, end = 100) upf%nlcc , dummy  

  read (iunps, '(a20,t24,a)', err = 100, end = 100) upf%dft, dummy  

  read (iunps, * ) upf%zp , dummy  
  read (iunps, * ) upf%etotps, dummy  
  read (iunps, * ) upf%ecutwfc, upf%ecutrho
  read (iunps, * ) upf%lmax , dummy
  read (iunps, *, err = 100, end = 100) upf%mesh , dummy  
  upf%grid%mesh = upf%mesh
  IF ( upf%grid%mesh > SIZE (upf%grid%r) ) &
     CALL errore('read_pseudo_header', 'too many grid points', 1)

  read (iunps, *, err = 100, end = 100) upf%nwfc, upf%nbeta , dummy
  read (iunps, '(a)', err = 100, end = 100) dummy
  ALLOCATE( upf%els( upf%nwfc ), upf%lchi( upf%nwfc ), upf%oc( upf%nwfc ) )
  do nw = 1, upf%nwfc  
     read (iunps, * ) upf%els (nw), upf%lchi (nw), upf%oc (nw)  
  enddo

  return  

100  call errore ('read_pseudo_header', 'Reading pseudo file', 1 )
end subroutine read_pseudo_header

!---------------------------------------------------------------------

subroutine read_pseudo_mesh (upf, iunps)  
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY: pseudo_upf

  implicit none
  !
  integer :: iunps  
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  integer :: ir

  ALLOCATE( upf%r( upf%mesh ), upf%rab( upf%mesh ) )
  upf%r   = 0.0_DP
  upf%rab = 0.0_DP

  call scan_begin (iunps, "R", .false.)  
  read (iunps, *, err = 100, end = 100) (upf%r(ir), ir=1,upf%mesh )
  call scan_end (iunps, "R")  
  call scan_begin (iunps, "RAB", .false.)  
  read (iunps, *, err = 101, end = 101) (upf%rab(ir), ir=1,upf%mesh )
  call scan_end (iunps, "RAB")  

  upf%grid%r(1:upf%mesh)   = upf%r(1:upf%mesh)
  upf%grid%rab(1:upf%mesh) = upf%rab(1:upf%mesh)

  return  

100 call errore ('read_pseudo_mesh', 'Reading pseudo file (R) for '//upf%psd,1)
101 call errore ('read_pseudo_mesh', 'Reading pseudo file (RAB) for '//upf%psd,2)  
end subroutine read_pseudo_mesh


!---------------------------------------------------------------------
subroutine read_pseudo_nlcc (upf, iunps)
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY: pseudo_upf

  implicit none
  !
  integer :: iunps  
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  integer :: ir
  !
  ALLOCATE( upf%rho_atc( upf%mesh ) )
  upf%rho_atc = 0.0_DP

  read (iunps, *, err = 100, end = 100) (upf%rho_atc(ir), ir=1,upf%mesh )
  !
  return

100 call errore ('read_pseudo_nlcc', 'Reading pseudo file', 1)
  return
end subroutine read_pseudo_nlcc

!---------------------------------------------------------------------
subroutine read_pseudo_local (upf, iunps)
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY: pseudo_upf

  implicit none
  !
  integer :: iunps  
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  integer :: ir
  !
  ALLOCATE( upf%vloc( upf%mesh ) )
  upf%vloc = 0.0_DP

  read (iunps, *, err=100, end=100) (upf%vloc(ir) , ir=1,upf%mesh )

  return

100 call errore ('read_pseudo_local','Reading pseudo file', 1)
  return
end subroutine read_pseudo_local

!---------------------------------------------------------------------

subroutine read_pseudo_nl (upf, iunps)  
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY: pseudo_upf

  implicit none
  !
  integer :: iunps  
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  integer :: nb, mb, ijv, n, ir, ios, idum, ldum, icon, lp, i, ikk, l, l1,l2
  ! counters
  character (len=75) :: dummy  
  !
  if ( upf%nbeta == 0) then
     upf%nqf = 0
     upf%nqlc= 0
     upf%kkbeta = 0  
     ALLOCATE( upf%kbeta( 1 ) )
     ALLOCATE( upf%lll( 1 ) )
     ALLOCATE( upf%beta( upf%mesh, 1 ) )
     ALLOCATE( upf%dion( 1, 1 ) )
     ALLOCATE( upf%rinner( 1 ) )
     ALLOCATE( upf%qqq   ( 1, 1 ) )
     ALLOCATE( upf%qfunc ( upf%mesh, 1 ) )
     ALLOCATE( upf%qfcoef( 1, 1, 1, 1 ) )
     ALLOCATE( upf%rcut( 1 ) )
     ALLOCATE( upf%rcutus( 1 ) )
     ALLOCATE( upf%els_beta( 1 ) )
     return
  end if
  ALLOCATE( upf%kbeta( upf%nbeta ) )
  ALLOCATE( upf%lll( upf%nbeta ) )
  ALLOCATE( upf%beta( upf%mesh, upf%nbeta ) )
  ALLOCATE( upf%dion( upf%nbeta, upf%nbeta ) )
  ALLOCATE( upf%rcut( upf%nbeta ) )
  ALLOCATE( upf%rcutus( upf%nbeta ) )
  ALLOCATE( upf%els_beta( upf%nbeta ) )

  upf%kkbeta = 0  
  upf%lll    = 0  
  upf%beta   = 0.0_DP
  upf%dion   = 0.0_DP
  upf%rcut   = 0.0_DP
  upf%rcutus = 0.0_DP
  upf%els_beta = '  '

  do nb = 1, upf%nbeta 
     call scan_begin (iunps, "BETA", .false.)  
     read (iunps, *, err = 100, end = 100) idum, upf%lll(nb), dummy
     read (iunps, *, err = 100, end = 100) ikk  
     upf%kbeta(nb) = ikk
     upf%kkbeta = MAX ( upf%kkbeta, upf%kbeta(nb) )  
     read (iunps, *, err = 100, end = 100) (upf%beta(ir,nb), ir=1,ikk)

     read (iunps, *, err=200,iostat=ios) upf%rcut(nb), upf%rcutus(nb)
     read (iunps, *, err=200,iostat=ios) upf%els_beta(nb)
     call scan_end (iunps, "BETA")  
200  continue
  enddo


  call scan_begin (iunps, "DIJ", .false.)  
  read (iunps, *, err = 101, end = 101) upf%nd, dummy  
  do icon = 1, upf%nd  
     read (iunps, *, err = 101, end = 101) nb, mb, upf%dion(nb,mb)
     upf%dion (mb,nb) = upf%dion (nb,mb)  
  enddo
  call scan_end (iunps, "DIJ")  


  if ( upf%tvanp .and. .not. upf%tpawp) then  
     call scan_begin (iunps, "QIJ", .false.)  
     read (iunps, *, err = 102, end = 102) upf%nqf
     upf%nqlc = 2 * upf%lmax  + 1
     ALLOCATE( upf%rinner( upf%nqlc ) )
     ALLOCATE( upf%qqq   ( upf%nbeta, upf%nbeta ) )
     IF (upf%q_with_l) then
        ALLOCATE( upf%qfuncl ( upf%mesh, upf%nbeta*(upf%nbeta+1)/2, 0:2*upf%lmax ) )
        upf%qfuncl  = 0.0_DP
     ELSE
        ALLOCATE( upf%qfunc ( upf%mesh, upf%nbeta*(upf%nbeta+1)/2 ) )
        upf%qfunc  = 0.0_DP
     ENDIF
     ALLOCATE( upf%qfcoef( MAX( upf%nqf,1 ), upf%nqlc, upf%nbeta, upf%nbeta ) )
     upf%rinner = 0.0_DP
     upf%qqq    = 0.0_DP
     upf%qfcoef = 0.0_DP
     if ( upf%nqf /= 0) then
        call scan_begin (iunps, "RINNER", .false.)  
        read (iunps,*,err=103,end=103) ( idum, upf%rinner(i), i=1,upf%nqlc )
        call scan_end (iunps, "RINNER")  
     end if
     do nb = 1, upf%nbeta
        do mb = nb, upf%nbeta

           read (iunps,*,err=102,end=102) idum, idum, ldum, dummy
           !"  i    j   (l)"
           if (ldum /= upf%lll(mb) ) then
             call errore ('read_pseudo_nl','inconsistent angular momentum for Q_ij', 1)
           end if

           read (iunps,*,err=104,end=104) upf%qqq(nb,mb), dummy
           ! "Q_int"
           upf%qqq(mb,nb) = upf%qqq(nb,mb)  
           ! ijv is the combined (nb,mb) index
           ijv = mb * (mb-1) / 2 + nb
           IF (upf%q_with_l) THEN
              l1=upf%lll(nb)
              l2=upf%lll(mb)
              DO l=abs(l1-l2),l1+l2
                 read (iunps, *, err=105, end=105) (upf%qfuncl(n,ijv,l), &
                                                    n=1,upf%mesh)
              END DO
           ELSE
              read (iunps, *, err=105, end=105) (upf%qfunc(n,ijv), n=1,upf%mesh)
           ENDIF

           if ( upf%nqf > 0 ) then
              call scan_begin (iunps, "QFCOEF", .false.)  
              read (iunps,*,err=106,end=106) &
                        ( ( upf%qfcoef(i,lp,nb,mb), i=1,upf%nqf ), lp=1,upf%nqlc )
              do i = 1, upf%nqf
                 do lp = 1, upf%nqlc
                    upf%qfcoef(i,lp,mb,nb) = upf%qfcoef(i,lp,nb,mb)
                 end do
              end do
              call scan_end (iunps, "QFCOEF")  
           end if

        enddo
     enddo
     call scan_end (iunps, "QIJ")  
  else  
     upf%nqf  = 1
     upf%nqlc = 2 * upf%lmax  + 1
     ALLOCATE( upf%rinner( upf%nqlc ) )
     ALLOCATE( upf%qqq   ( upf%nbeta, upf%nbeta ) )
     ALLOCATE( upf%qfunc ( upf%mesh, upf%nbeta*(upf%nbeta+1)/2 ) )
     ALLOCATE( upf%qfcoef( upf%nqf, upf%nqlc, upf%nbeta, upf%nbeta ) )
     upf%rinner = 0.0_DP
     upf%qqq    = 0.0_DP
     upf%qfunc  = 0.0_DP
     upf%qfcoef = 0.0_DP
  endif


  return  

100 call errore ('read_pseudo_nl', 'Reading pseudo file (BETA)', 1 )  
101 call errore ('read_pseudo_nl', 'Reading pseudo file (DIJ)',  2 )  
102 call errore ('read_pseudo_nl', 'Reading pseudo file (QIJ)',  3 )
103 call errore ('read_pseudo_nl', 'Reading pseudo file (RINNER)',4)
104 call errore ('read_pseudo_nl', 'Reading pseudo file (qqq)',  5 )
105 call errore ('read_pseudo_nl', 'Reading pseudo file (qfunc)',6 )
106 call errore ('read_pseudo_nl', 'Reading pseudo file (qfcoef)',7)
end subroutine read_pseudo_nl


!---------------------------------------------------------------------
subroutine read_pseudo_pswfc (upf, iunps)  
  !---------------------------------------------------------------------
  !
  USE kinds  
  USE pseudo_types, ONLY: pseudo_upf
  !
  implicit none
  !
  integer :: iunps
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  character (len=75) :: dummy  
  integer :: nb, ir

  ALLOCATE( upf%chi( upf%mesh, MAX( upf%nwfc, 1 ) ) )
  upf%chi = 0.0_DP
  do nb = 1, upf%nwfc  
     read (iunps, *, err=100, end=100) dummy  !Wavefunction labels
     read (iunps, *, err=100, end=100) ( upf%chi(ir,nb), ir=1,upf%mesh )
  enddo

  return  

100 call errore ('read_pseudo_pswfc', 'Reading pseudo file', 1)
end subroutine read_pseudo_pswfc

!---------------------------------------------------------------------
subroutine read_pseudo_rhoatom (upf, iunps)  
  !---------------------------------------------------------------------
  !
  USE kinds 
  USE pseudo_types, ONLY: pseudo_upf
  !
  implicit none
  !
  integer :: iunps
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  !
  integer :: ir
  !
  ALLOCATE( upf%rho_at( upf%mesh ) )
  upf%rho_at = 0.0_DP
  read (iunps,*,err=100,end=100) ( upf%rho_at(ir), ir=1,upf%mesh )
  !
  return  

100 call errore ('read_pseudo_rhoatom','Reading pseudo file', 1)
end subroutine read_pseudo_rhoatom
!
!---------------------------------------------------------------------
subroutine read_pseudo_addinfo (upf, iunps)
!---------------------------------------------------------------------
!
!     This routine reads from the new UPF file,
!     and the total angular momentum jjj of the beta and jchi of the
!     wave-functions.
!
  USE pseudo_types, ONLY: pseudo_upf
  USE kinds
  implicit none
  integer :: iunps
  
  TYPE (pseudo_upf), INTENT(INOUT) :: upf
  integer :: nb
  
  ALLOCATE( upf%nn(upf%nwfc) )
  ALLOCATE( upf%epseu(upf%nwfc), upf%jchi(upf%nwfc) )
  ALLOCATE( upf%jjj(upf%nbeta) )

  upf%nn=0
  upf%epseu=0.0_DP
  upf%jchi=0.0_DP
  do nb = 1, upf%nwfc
     read (iunps, *,err=100,end=100) upf%els(nb),  &
          upf%nn(nb), upf%lchi(nb), upf%jchi(nb), upf%oc(nb)
  enddo
  
  upf%jjj=0.0_DP
  do nb = 1, upf%nbeta
     read (iunps, *, err=100,end=100) upf%lll(nb), upf%jjj(nb)
  enddo
  
  read(iunps, *) upf%xmin, upf%rmax, upf%zmesh, upf%dx
  upf%grid%dx   = upf%dx
  upf%grid%xmin = upf%xmin
  upf%grid%zmesh= upf%zmesh
  upf%grid%mesh = upf%mesh

  return
100 call errore ('read_pseudo_addinfo','Reading pseudo file', 1)
end subroutine read_pseudo_addinfo


!<apsi>
!---------------------------------------------------------------------
SUBROUTINE read_pseudo_paw ( upf, iunps )
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY : pseudo_upf
  USE radial_grids, ONLY : read_grid_from_file
  !
  IMPLICIT NONE
  !
  INTEGER :: iunps
  TYPE ( pseudo_upf ), INTENT ( INOUT ) :: upf
  !
  INTEGER :: nb, nb1, l, k
  REAL(DP),ALLOCATABLE :: aux(:,:)
  CHARACTER(len=70) :: dummy
  

  CALL scan_begin ( iunps, "PAW_FORMAT_VERSION", .false. )
  READ ( iunps, *, err=100, end=100 ) upf%paw_data_format
  CALL scan_end ( iunps, "PAW_FORMAT_VERSION" )
  
  IF ( upf%paw_data_format /= 0.1_dp ) THEN
     CALL errore ( 'read_pseudo_paw', 'UPF/PAW in unknown format', 1 )
  END IF
  
  ! Initialize a angular momentum extremes:
  upf%paw%lmax_phi = maxval( upf%lll(1:upf%nbeta) )
  upf%paw%lmax_rho = 2*upf%paw%lmax_phi ! multiplication of Y_lm

  ! Read augmentation charge:
  CALL scan_begin ( iunps, "AUGFUN", .false. )
    read (iunps,'(1pa)') dummy
    read (iunps,'(1pa)') upf%paw%augshape ! shape of augfun
    read (iunps,'(1p1e19.11,i5,a)') upf%paw%raug, upf%paw%iraug, dummy
    read (iunps,'(1pi5,a)') upf%paw%lmax_aug, dummy
    if(upf%paw%lmax_aug /= upf%paw%lmax_rho) &
        call errore('read_pseudo_paw', &
             'Max charge L and max aug.charge L differ: there is an error in the pseudopotential.',&
             upf%paw%lmax_aug +1000* upf%paw%lmax_rho)

    ! maximum radius of integration (for r > rmax PS == AE .and. aug == 0)
    upf%paw%irmax = max(upf%kkbeta, upf%paw%iraug)
    ! temporary WORKAROUND: if augmentation charge extend further than betas
    ! part of it will be dropped in init_us_1 when transformed to Fourier space
    upf%kkbeta = max(upf%kkbeta, upf%paw%iraug)
    !
    ! First read multipoles (they are needed to read the augfuns)
    ALLOCATE( upf%paw%augmom(upf%nbeta,upf%nbeta, 0:upf%paw%lmax_aug) )
    read (iunps,'(1pa)') dummy ! multipolar momenti
    read (iunps,'(1p4e19.11)') (((upf%paw%augmom(nb,nb1,l), nb  = 1,upf%nbeta),&
                                                            nb1 = 1,upf%nbeta),&
                                                            l   = 0,upf%paw%lmax_aug)
    !
    ! Read augmentation charge:
    ALLOCATE( upf%paw%aug(upf%mesh, upf%nbeta,upf%nbeta, 0:upf%paw%lmax_aug) )
    read (iunps,'(1pa)') dummy ! augmentation functions
    do l = 0,upf%paw%lmax_aug
        do nb = 1,upf%nbeta
        do nb1 = 1,upf%nbeta
            if (abs(upf%paw%augmom(nb,nb1,l)) > 1.d-10) then
                read (iunps,'(1x,a)') dummy ! blabla
                read (iunps,'(1p4e19.11)') (upf%paw%aug(k,nb,nb1,l), k  = 1,upf%mesh)
            else
                upf%paw%aug(1:upf%mesh,nb,nb1,l) = 0._dp
            endif
        enddo
        enddo
    enddo
  CALL scan_end ( iunps, "AUGFUN" )

  ! All-electron core correction charge
  ALLOCATE( upf%paw%ae_rho_atc(upf%mesh) )
  CALL scan_begin ( iunps, "AE_RHO_ATC", .false. )
    read (iunps,'(1p4e19.11)') (upf%paw%ae_rho_atc(k), k = 1,upf%mesh)
  CALL scan_end ( iunps, "AE_RHO_ATC" )

  ! pfunc = phi_i * phi_j; ptfunc = phi~_i * phi~_j
  ! Saving the wavefunctions uses less space, so we have to reconstruct the pfuncs
  ALLOCATE( aux(upf%mesh,upf%nbeta) )
  ALLOCATE( upf%paw%pfunc (upf%mesh, upf%nbeta,upf%nbeta),&
            upf%paw%ptfunc(upf%mesh, upf%nbeta,upf%nbeta) )
  ! read AE wfc
  CALL scan_begin ( iunps, "AEWFC", .false. )
    do nb = 1,upf%nbeta
    read (iunps,'(a)') dummy ! blabla
    read (iunps,'(1p4e19.11)') (aux(k,nb), k  = 1,upf%mesh)
    enddo
  CALL scan_end ( iunps, "AEWFC" )
  ! reconstruct pfunc
  do nb=1,upf%nbeta
     do nb1=1,upf%nbeta
        upf%paw%pfunc (1:upf%mesh, nb, nb1) = &
             aux(1:upf%mesh, nb) * aux(1:upf%mesh, nb1)
        upf%paw%pfunc(upf%paw%iraug+1:,nb,nb1) = 0._dp
        !write(10000+100*nb+10*nb1,'(f15.7)') upf%paw%pfunc(:,nb,nb1)
     enddo
  enddo
  ! read pseudo wfc
  ! Note: in USPP only pswfc with occupation > 0 are stored in the UPF file
  !       while for PAW we have to use all of them!
  CALL scan_begin ( iunps, "PSWFC_FULL", .false. )
    do nb = 1,upf%nbeta
    read (iunps,'(a)') dummy ! blabla
    read (iunps,'(1p4e19.11)') (aux(k,nb), k  = 1,upf%mesh)
    enddo
  CALL scan_end ( iunps, "PSWFC_FULL" )
  ! reconstruct \tilde{pfunc}
  do nb=1,upf%nbeta
     do nb1=1,upf%nbeta
        upf%paw%ptfunc (1:upf%mesh, nb, nb1) = &
             aux(1:upf%mesh, nb) * aux(1:upf%mesh, nb1)
        upf%paw%ptfunc(upf%paw%iraug+1:,nb,nb1) = 0._dp
     enddo
  enddo
  DEALLOCATE( aux )

  ALLOCATE( upf%paw%ae_vloc(upf%mesh) )
  CALL scan_begin ( iunps, "AE_VLOC", .false. )
  read (iunps,'(1p4e19.11)') (upf%paw%ae_vloc(k), k = 1,upf%mesh)
  CALL scan_end ( iunps, "AE_VLOC" )

  ALLOCATE( upf%paw%kdiff(upf%nbeta,upf%nbeta) )
  CALL scan_begin ( iunps, "KDIFF", .false. )
  read (iunps,'(1p4e19.11)') ((upf%paw%kdiff(nb,nb1), nb  = 1,upf%nbeta),&
                                                      nb1 = 1,upf%nbeta)
  CALL scan_end ( iunps, "KDIFF" )

  !IF(allocated(upf%oc)) DEALLOCATE(upf%oc)
  ALLOCATE( upf%paw%oc(upf%nbeta) )
  CALL scan_begin ( iunps, "OCCUP", .false. )
  read (iunps,'(1p4e19.11)') (upf%paw%oc(nb), nb  = 1,upf%nbeta)
  CALL scan_end ( iunps, "OCCUP" )
  ! negative occupations has a meaning in ld1, but not here.
  do nb = 1,upf%nbeta
    upf%paw%oc(nb) = MAX(upf%paw%oc(nb),0._dp)
  enddo

  ! WARNING!!! for structural reasons unless I put the grid in the UPF structure
  ! (and I don't whant to do that now!) I have to read the parameters here and
  ! reconstruct the grid later, when I can access the type index...
  ! BTW I'm wondering how all the subroutines that uses the grid can survive
  ! considering that this module don't initialize it for uspp...
  CALL scan_begin ( iunps, "GRID_RECON", .false. )
    read (iunps,'(a)') dummy
    read (iunps,'(1pe19.11,a)') upf%grid%dx,   dummy
    read (iunps,'(1pe19.11,a)') upf%grid%xmin, dummy
    read (iunps,'(1pe19.11,a)') upf%grid%rmax, dummy
    read (iunps,'(1pe19.11,a)') upf%grid%zmesh,dummy
    CALL scan_begin ( iunps, "SQRT_R", .false. )
    read (iunps,'(1p4e19.11)') ( upf%grid%sqr(k), k=1,upf%mesh)
    CALL scan_end ( iunps, "SQRT_R")
    !
    upf%grid%mesh = upf%mesh
    !
    upf%grid%r2(1:upf%mesh) = upf%grid%r(1:upf%mesh)**2
    upf%grid%rm1(1:upf%mesh) = 1._dp/upf%grid%r(1:upf%mesh)
    upf%grid%rm2(1:upf%mesh) = 1._dp/upf%grid%r2(1:upf%mesh)
    upf%grid%rm3(1:upf%mesh) = 1._dp/upf%grid%r2(1:upf%mesh)/upf%grid%r(1:upf%mesh)

  CALL scan_end ( iunps, "GRID_RECON" )


  IF ( upf%has_gipaw ) then
     CALL scan_begin ( iunps, "GIPAW_RECONSTRUCTION_DATA", .false. )
     CALL read_pseudo_gipaw ( upf, iunps )
     CALL scan_end ( iunps, "GIPAW_RECONSTRUCTION_DATA" )
  END IF
  
  RETURN
  
100 CALL errore ( 'read_pseudo_paw', 'Reading pseudo file', 1 )
END SUBROUTINE read_pseudo_paw

!---------------------------------------------------------------------
SUBROUTINE read_pseudo_gipaw ( upf, iunps )
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY : pseudo_upf
  !
  implicit none
  !
  INTEGER :: iunps
  TYPE ( pseudo_upf ), INTENT ( INOUT ) :: upf
  !
  INTEGER :: nb, ir
  
  CALL scan_begin ( iunps, "GIPAW_FORMAT_VERSION", .false. )
  READ ( iunps, *, err=100, end=100 ) upf%gipaw_data_format
  CALL scan_end ( iunps, "GIPAW_FORMAT_VERSION" )
  
  IF ( upf%gipaw_data_format == 0.1_dp ) THEN
     CALL read_pseudo_gipaw_core_orbitals ( upf, iunps )
     CALL read_pseudo_gipaw_local ( upf, iunps )
     CALL read_pseudo_gipaw_orbitals ( upf, iunps )
  ELSE
     CALL errore ( 'read_pseudo_gipaw', 'UPF/GIPAW in unknown format', 1 )
  END IF
  
  RETURN
  
100 CALL errore ( 'read_pseudo_gipaw', 'Reading pseudo file', 1 )
END SUBROUTINE read_pseudo_gipaw

!---------------------------------------------------------------------
SUBROUTINE read_pseudo_gipaw_core_orbitals ( upf, iunps )
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY : pseudo_upf
  !
  IMPLICIT NONE
  !
  INTEGER :: iunps
  TYPE ( pseudo_upf ), INTENT ( INOUT ) :: upf
  !
  CHARACTER ( LEN = 75 ) :: dummy1, dummy2
  INTEGER :: nb, ir
  
  CALL scan_begin ( iunps, "GIPAW_CORE_ORBITALS", .false. )
  READ ( iunps, *, err=100, end=100 ) upf%gipaw_ncore_orbitals
  
  ALLOCATE ( upf%gipaw_core_orbital_n(upf%gipaw_ncore_orbitals) )
  ALLOCATE ( upf%gipaw_core_orbital_l(upf%gipaw_ncore_orbitals) )
  ALLOCATE ( upf%gipaw_core_orbital_el(upf%gipaw_ncore_orbitals) )
  ALLOCATE ( upf%gipaw_core_orbital(upf%mesh,upf%gipaw_ncore_orbitals) )
  upf%gipaw_core_orbital = 0.0_dp
  
  DO nb = 1, upf%gipaw_ncore_orbitals
     CALL scan_begin ( iunps, "GIPAW_CORE_ORBITAL", .false. )
     READ (iunps, *, err=100, end=100) &
          upf%gipaw_core_orbital_n(nb), upf%gipaw_core_orbital_l(nb), &
          dummy1, dummy2, upf%gipaw_core_orbital_el(nb)
     READ ( iunps, *, err=100, end=100 ) &
          ( upf%gipaw_core_orbital(ir,nb), ir = 1, upf%mesh )
     CALL scan_end ( iunps, "GIPAW_CORE_ORBITAL" )
  END DO
  
  CALL scan_end ( iunps, "GIPAW_CORE_ORBITALS" )
  
  RETURN
  
100 CALL errore ( 'read_pseudo_gipaw_core_orbitals', 'Reading pseudo file', 1 )
END SUBROUTINE read_pseudo_gipaw_core_orbitals

!---------------------------------------------------------------------
SUBROUTINE read_pseudo_gipaw_local ( upf, iunps )
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY : pseudo_upf
  !
  IMPLICIT NONE
  !
  INTEGER :: iunps
  TYPE ( pseudo_upf ), INTENT ( INOUT ) :: upf
  !
  CHARACTER ( LEN = 75 ) :: dummy
  INTEGER :: nb, ir
  
  CALL scan_begin ( iunps, "GIPAW_LOCAL_DATA", .false. )
  
  ALLOCATE ( upf%gipaw_vlocal_ae(upf%mesh) )
  ALLOCATE ( upf%gipaw_vlocal_ps(upf%mesh) )
  
  CALL scan_begin ( iunps, "GIPAW_VLOCAL_AE", .false. )
  
  READ ( iunps, *, err=100, end=100 ) &
       ( upf%gipaw_vlocal_ae(ir), ir = 1, upf%mesh )
  
  CALL scan_end ( iunps, "GIPAW_VLOCAL_AE" )
  
  CALL scan_begin ( iunps, "GIPAW_VLOCAL_PS", .false. )
  
  READ ( iunps, *, err=100, end=100 ) &
       ( upf%gipaw_vlocal_ps(ir), ir = 1, upf%mesh )
  
  CALL scan_end ( iunps, "GIPAW_VLOCAL_PS" )
  
  CALL scan_end ( iunps, "GIPAW_LOCAL_DATA" )
  
  RETURN
  
100 CALL errore ( 'read_pseudo_gipaw_local', 'Reading pseudo file', 1 )
END SUBROUTINE read_pseudo_gipaw_local

!---------------------------------------------------------------------
SUBROUTINE read_pseudo_gipaw_orbitals ( upf, iunps )
  !---------------------------------------------------------------------
  !
  USE kinds
  USE pseudo_types, ONLY : pseudo_upf
  !
  IMPLICIT NONE
  !
  INTEGER :: iunps
  TYPE ( pseudo_upf ), INTENT ( INOUT ) :: upf
  !
  CHARACTER ( LEN = 75 ) :: dummy
  INTEGER :: nb, ir
  
  CALL scan_begin ( iunps, "GIPAW_ORBITALS", .false. )
  READ ( iunps, *, err=100, end=100 ) upf%gipaw_wfs_nchannels
  
  ALLOCATE ( upf%gipaw_wfs_el(upf%gipaw_wfs_nchannels) )
  ALLOCATE ( upf%gipaw_wfs_ll(upf%gipaw_wfs_nchannels) )
  ALLOCATE ( upf%gipaw_wfs_rcut(upf%gipaw_wfs_nchannels) )
  ALLOCATE ( upf%gipaw_wfs_rcutus(upf%gipaw_wfs_nchannels) )
  ALLOCATE ( upf%gipaw_wfs_ae(upf%mesh,upf%gipaw_wfs_nchannels) )
  ALLOCATE ( upf%gipaw_wfs_ps(upf%mesh,upf%gipaw_wfs_nchannels) )
  
  inquire ( unit = iunps, name = dummy )
  DO nb = 1, upf%gipaw_wfs_nchannels
     CALL scan_begin ( iunps, "GIPAW_AE_ORBITAL", .false. )
     READ (iunps, *, err=100, end=100) &
          upf%gipaw_wfs_el(nb), upf%gipaw_wfs_ll(nb)
     READ ( iunps, *, err=100, end=100 ) &
          ( upf%gipaw_wfs_ae(ir,nb), ir = 1, upf%mesh )
     CALL scan_end ( iunps, "GIPAW_AE_ORBITAL" )
     
     CALL scan_begin ( iunps, "GIPAW_PS_ORBITAL", .false. )
     READ (iunps, *, err=100, end=100) &
          upf%gipaw_wfs_rcut(nb), upf%gipaw_wfs_rcutus(nb)
     READ ( iunps, *, err=100, end=100 ) &
          ( upf%gipaw_wfs_ps(ir,nb), ir = 1, upf%mesh )
     CALL scan_end ( iunps, "GIPAW_PS_ORBITAL" )
  END DO
  
  CALL scan_end ( iunps, "GIPAW_ORBITALS" )
  
  RETURN
  
100 CALL errore ( 'read_pseudo_gipaw_orbitals', 'Reading pseudo file', 1 )
END SUBROUTINE read_pseudo_gipaw_orbitals
!</apsi>

!=----------------------------------------------------------------------------=!
      END MODULE read_upf_module
!=----------------------------------------------------------------------------=!
