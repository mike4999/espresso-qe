!
!---------------------------------------------------------------------
subroutine read_pseudoupf 
  !---------------------------------------------------------------------
  !
  !   read "is"-th pseudopotential in the Unified Pseudopotential Format
  !   from unit "iunps" - convert and copy to internal PWscf variables
  !   return error code in "ierr" (success: ierr=0)
  !
  ! PWSCF modules
  !
  use ld1inc
  use funct
  !
  use pseudo_types_ld1
  use read_pseudo_module_ld1
  !
  implicit none
  !
  integer :: iunps, ierr
  !
  !     Local variables
  !
  integer :: nb, ios
  real(kind=dp) :: fpi
  TYPE (pseudo_upf) :: upf
  !
  !
  iunps=2
  open(unit=iunps,file=file_pseudo,status='old',form='formatted', &
       err=100, iostat=ios)
100   call errore('read_pseudoupf','open error on file '//file_pseudo,ios)
  if (rel.lt.2) then
     call read_pseudo_upf(iunps, upf, ierr)
  else
     call read_pseudo_upf_rel(iunps, upf, ierr)
  endif
  !
  if (ierr .ne. 0) return
  !
  zval  = upf%zp
  nlcc = upf%nlcc
  dft = upf%dft
  call which_dft (dft)

  if (upf%typ.eq.'NC') then
     pseudotype=2
  else
     pseudotype=3
  endif
  etots=upf%etotps
  lmax = upf%lmax
  mesh = upf%mesh
  r(1:mesh) = upf%r  (1:upf%mesh)
  r2(1:mesh)= r(1:mesh)**2
  sqr(1:mesh)=sqrt(r(1:mesh))
  if (rel.lt.2) then
     dx=log(r(2)/r(1))
     rmax=r(mesh)
     xmin=log(zed*r(1))
     zmesh=zed
  else
     dx=upf%dx
     xmin=upf%xmin
     zmesh=upf%zmesh
     rmax=exp(xmin+(mesh-1)*dx)/zmesh
  endif
  if (abs(exp(xmin+(mesh-1)*dx)/zed-rmax).gt.1.e-6_dp) &
   &   call errore('read_pseudoup','mesh not supported',1)

  nwfs = upf%nwfc

  nbeta= upf%nbeta
  lls(1:nbeta)=upf%lll(1:nbeta)

  if (rel.lt.2) then
     jjs=0.0_dp
  else
     jjs(1:nbeta)=upf%jjj(1:nbeta)
  endif
  !
  !
  do nb=1,nbeta
     ikk(nb)=upf%kkbeta(nb)
  end do
  betas(1:mesh, 1:nbeta) = upf%beta(1:upf%mesh, 1:upf%nbeta)
  bmat(1:nbeta, 1:nbeta) = upf%dion(1:upf%nbeta, 1:upf%nbeta)
  !
  if (pseudotype.eq.3) then
     qq(1:nbeta,1:nbeta) = upf%qqq(1:upf%nbeta,1:upf%nbeta)
     qvan (1:mesh, 1:nbeta, 1:nbeta) = &
          upf%qfunc(1:upf%mesh,1:upf%nbeta,1:upf%nbeta)
  else
     qq=0.0_dp
     ddd(1:nbeta,1:nbeta,1)=bmat(1:nbeta,1:nbeta)
  endif
  !
  !
  if ( upf%nlcc) then
     fpi=16.0_dp*atan(1.0_dp)
     rhoc(1:mesh) = upf%rho_atc(1:upf%mesh)*fpi*r2(1:upf%mesh)
  else
     rhoc(:) = 0.0_dp
  end if
  rhos=0.0_dp
  rhos (1:mesh,1) = upf%rho_at (1:upf%mesh)
  phis(1:mesh,1:nwfs)=upf%chi(1:mesh,1:nwfs)
  !!! TEMP
  lloc = -1
  vpsloc(1:mesh) = upf%vloc(1:upf%mesh)
  !!!
  CALL deallocate_pseudo_upf( upf )

end subroutine read_pseudoupf
