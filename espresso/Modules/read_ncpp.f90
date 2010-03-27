!
! Copyright (C) 2001-2007 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine read_ncpp (iunps, np, upf)
  !-----------------------------------------------------------------------
  !
  USE kinds, only: dp
  USE parameters, ONLY: lmaxx
  use funct, only: set_dft_from_name, dft_is_hybrid
  USE pseudo_types

  implicit none
  !
  TYPE (pseudo_upf) :: upf
  integer :: iunps, np
  !
  real(DP) :: cc(2), alpc(2), aps(6,0:3), alps(3,0:3), &
       a_nlcc, b_nlcc, alpha_nlcc
  real(DP) :: x, vll
  real(DP), allocatable:: vnl(:,:)
  real(DP), parameter :: rcut = 10.d0, e2 = 2.d0
  real(DP), external :: qe_erf
  integer :: nlc, nnl, lmax, lloc
  integer :: nb, i, l, ir, ios=0
  logical :: bhstype,  numeric
  !
  !====================================================================
  ! read norm-conserving PPs
  !
  read (iunps, '(a)', end=300, err=300, iostat=ios) upf%dft
  if (upf%dft(1:2) .eq.'**') upf%dft = 'PZ'
  read (iunps, *, err=300, iostat=ios) upf%psd, upf%zp, lmax, nlc, &
                                       nnl, upf%nlcc, lloc, bhstype
  if (nlc > 2 .or. nnl > 3) &
       call errore ('read_ncpp', 'Wrong nlc or nnl', np)
  if (nlc*nnl < 0) call errore ('read_ncpp', 'nlc*nnl < 0 ? ', np)
  if (upf%zp <= 0d0 .or. upf%zp > 100 ) &
       call errore ('read_ncpp', 'Wrong zp ', np)
  !
  !   In numeric pseudopotentials both nlc and nnl are zero.
  !
  numeric = (nlc <= 0) .and. (nnl <= 0)
  !
  if (lloc == -1000) lloc = lmax
  if (lloc < 0 .or. lmax < 0 .or. &
       .not.numeric .and. (lloc > min(lmax+1,lmaxx+1) .or. &
       lmax > max(lmaxx,lloc)) .or. &
       numeric .and. (lloc > lmax .or. lmax > lmaxx) ) &
       call errore ('read_ncpp', 'wrong lmax and/or lloc', np)
  if (.not.numeric  ) then
     !
     !   read here pseudopotentials in analytic form
     !
     read (iunps, *, err=300, iostat=ios) &
          (alpc(i), i=1,2), (cc(i), i=1,2)
     if (abs (cc(1)+cc(2)-1.d0) > 1.0d-6) &
          call errore ('read_ncpp', 'wrong pseudopotential coefficients', 1)
     do l = 0, lmax
        read (iunps, *, err=300, iostat=ios) (alps(i,l), i=1,3), &
                                             (aps(i,l),  i=1,6)
     enddo
     if (upf%nlcc ) then
        read (iunps, *, err=300, iostat=ios) &
             a_nlcc, b_nlcc, alpha_nlcc
        if (alpha_nlcc <= 0.d0) call errore('read_ncpp','alpha_nlcc=0',np)
     endif
  endif
  read (iunps, *, err=300, iostat=ios) upf%zmesh, upf%xmin, upf%dx, &
                                       upf%mesh, upf%nwfc 
  if ( upf%mesh <= 0) &
       call errore ('read_ncpp', 'wrong number of mesh points', np)
  if ( upf%nwfc < 0 .or. &
       (upf%nwfc < lmax   .and. lloc == lmax) .or. & 
       (upf%nwfc < lmax+1 .and. lloc /= lmax) ) &
       call errore ('read_ncpp', 'wrong no. of wfcts', np)
  !
  !  Here pseudopotentials in numeric form are read
  !
  ALLOCATE ( upf%chi(upf%mesh,upf%nwfc), upf%rho_atc(upf%mesh) )
  upf%rho_atc(:) = 0.d0
  ALLOCATE ( upf%lchi(upf%nwfc), upf%oc(upf%nwfc) )
  allocate (vnl(upf%mesh, 0:lmax))
  if (numeric  ) then
     do l = 0, lmax
        read (iunps, '(a)', err=300, iostat=ios)
        read (iunps, *, err=300, iostat=ios) (vnl(ir,l), ir=1,upf%mesh )
     enddo
     if ( upf%nlcc ) then
        read (iunps, *, err=300, iostat=ios) (upf%rho_atc(ir), ir=1,upf%mesh)
     endif
  endif
  !
  !  Here pseudowavefunctions (in numeric form) are read
  !
  do nb = 1, upf%nwfc
     read (iunps, '(a)', err=300, iostat=ios)
     read (iunps, *, err=300, iostat=ios) upf%lchi(nb), upf%oc(nb)
     !
     !     Test lchi and occupation numbers
     !
     if (nb <= lmax .and. upf%lchi(nb)+1 /= nb) &
          call errore ('read_ncpp', 'order of wavefunctions', 1)
     if (upf%lchi(nb) > lmaxx .or. upf%lchi(nb) < 0) &
                      call errore ('read_ncpp', 'wrong lchi', np)
     if (upf%oc(nb) < 0.d0 .or. upf%oc(nb) > 2.d0*(2*upf%lchi(nb)+1)) &
          call errore ('read_ncpp', 'wrong oc', np)
     read (iunps, *, err=300, iostat=ios) ( upf%chi(ir,nb), ir=1,upf%mesh )
  enddo
  !
  !====================================================================
  ! PP read: now setup 
  !
  IF ( numeric ) THEN
     upf%generated='Generated by old ld1 code (numerical format)'
  ELSE
     upf%generated='From published tables, or generated by old fitcar code (analytical format)'
  END IF
  call set_dft_from_name( upf%dft )
  !
#if defined (EXX)
#else
  IF ( dft_is_hybrid() ) &
    CALL errore( 'read_ncpp ', 'HYBRID XC not implemented in PWscf', 1 )
#endif
  !
  !    calculate the number of beta functions
  !
  upf%nbeta = 0
  do l = 0, lmax
     if (l /= lloc ) upf%nbeta = upf%nbeta + 1
  enddo
  ALLOCATE ( upf%lll(upf%nbeta) )
  nb = 0
  do l = 0, lmax
     if (l /= lloc ) then
        nb = nb + 1 
        upf%lll (nb) = l
     end if
  enddo
  !
  !    compute the radial mesh
  !
  ALLOCATE ( upf%r(upf%mesh), upf%rab(upf%mesh) )
  do ir = 1, upf%mesh
     x = upf%xmin + DBLE (ir - 1) * upf%dx
     upf%r(ir) = exp (x) / upf%zmesh 
     upf%rab(ir) = upf%dx * upf%r(ir)
  enddo
  do ir = 1, upf%mesh
     if ( upf%r(ir) > rcut) then
        upf%kkbeta = ir
        go to 5
     end if
  end do
  upf%kkbeta = upf%mesh
  !
  ! ... force kkbeta to be odd for simpson integration (obsolete?)
  !
5 upf%kkbeta = 2 * ( ( upf%kkbeta + 1 ) / 2) - 1
  !
  ALLOCATE ( upf%kbeta(upf%nbeta) )
  upf%kbeta(:) = upf%kkbeta
  ALLOCATE ( upf%vloc(upf%mesh) )
  upf%vloc (:) = 0.d0
  !
  if (.not. numeric) then
     !
     ! bring analytic potentials into numerical form
     !
     IF ( nlc == 2 .AND. nnl == 3 .AND. bhstype ) &
          CALL bachel( alps(1,0), aps(1,0), 1, lmax )
     !
     do i = 1, nlc 
        do ir = 1, upf%kkbeta
           upf%vloc (ir) = upf%vloc (ir) - upf%zp * e2 * cc (i) * &
               qe_erf ( sqrt (alpc(i)) * upf%r(ir) ) / upf%r(ir)
        end do
     end do
     do l = 0, lmax
        vnl (:, l) = upf%vloc (1:upf%mesh)
        do i = 1, nnl 
           vnl (:, l) = vnl (:, l) + e2 * (aps (i, l) + &
                   aps (i + 3, l) * upf%r (:) **2) * &
                   exp ( - upf%r(:) **2 * alps (i, l) )
        enddo
     enddo
     if ( upf%nlcc ) then
          upf%rho_atc(:) = ( a_nlcc + b_nlcc*upf%r(:)**2 ) * &
                      exp ( -upf%r(:)**2 * alpha_nlcc )
     end if
     !
  end if
  !
  ! assume l=lloc as local part and subtract from the other channels
  !
  if (lloc <= lmax ) &
    upf%vloc (:) = vnl (:, lloc)
  ! lloc > lmax is allowed for PP in analytical form only
  ! it means that only the erf part is taken as local part 
  do l = 0, lmax
     if (l /= lloc) vnl (:, l) = vnl(:, l) - upf%vloc(:)
  enddo
  !
  !    compute the atomic charges
  !
  ALLOCATE ( upf%rho_at (upf%mesh) )
  upf%rho_at(:) = 0.d0
  do nb = 1, upf%nwfc
     if ( upf%oc(nb) > 0.d0) then
        do ir = 1, upf%mesh
           upf%rho_at(ir) = upf%rho_at(ir) + upf%oc(nb) * upf%chi(ir,nb)**2
        enddo
     endif
  enddo
  !====================================================================
  ! convert to separable (KB) form
  !
  ALLOCATE ( upf%beta (upf%mesh, upf%nbeta) ) 
  ALLOCATE ( upf%dion (upf%nbeta,upf%nbeta), upf%lll (upf%nbeta) ) 
  upf%dion (:,:) = 0.d0
  nb = 0
  do l = 0, lmax
     if (l /= lloc ) then
        nb = nb + 1
        ! upf%beta is used here as work space
        do ir = 1, upf%kkbeta
           upf%beta (ir, nb) = upf%chi(ir, l+1) **2 * vnl(ir, l)
        end do
        call simpson (upf%kkbeta, upf%beta (1, nb), upf%rab, vll )
        upf%dion (nb, nb) = 1.d0 / vll
        ! upf%beta stores projectors  |beta(r)> = |V_nl(r)phi(r)>
        do ir = 1, upf%kkbeta
           upf%beta (ir, nb) = vnl (ir, l) * upf%chi (ir, l + 1)
        enddo
        upf%lll (nb) = l
     endif
  enddo
  deallocate (vnl)
  !
  ! for compatibility with USPP
  !
  upf%nqf = 0
  upf%nqlc= 0
  upf%tvanp =.false.
  upf%tpawp =.false.
  upf%has_so=.false.
  !
  ! Set additional, not present, variables to dummy values
  allocate(upf%els(upf%nwfc))
  upf%els(:) = 'nX'
  allocate(upf%els_beta(upf%nbeta))
  upf%els_beta(:) = 'nX'
  allocate(upf%rcut(upf%nbeta), upf%rcutus(upf%nbeta))
  upf%rcut(:) = 0._dp
  upf%rcutus(:) = 0._dp
  !
  return

300 call errore ('read_ncpp', 'pseudo file is empty or wrong', abs (np) )
end subroutine read_ncpp

