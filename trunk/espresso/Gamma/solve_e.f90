!
!-----------------------------------------------------------------------
subroutine solve_e
  !-----------------------------------------------------------------------
  !
#include "machine.h"
  use allocate
  use pwcom
  use cgcom
  !
  implicit none
  !
  integer :: ipol, nrec, i, ibnd, jbnd, info, iter, kpoint
  real(kind=DP), pointer ::diag(:)
  complex(kind=DP), pointer :: gr(:,:), h(:,:), work(:,:)
  real(kind=DP), pointer :: overlap(:,:)
  logical :: orthonormal, precondition,startwith0,here
  character(len=7) :: fildwf, filbar
  external A_h
  !
  call start_clock('solve_e')
  !
  call mallocate ( diag, npwx)
  call mallocate ( overlap, nbnd, nbnd)
  call mallocate ( work, npwx, nbnd)
  call mallocate ( gr  , npwx, nbnd)
  call mallocate ( h   , npwx, nbnd)
  !
  kpoint = 1
  do i = 1,npw
     g2kin(i) = ( (xk(1,kpoint)+g(1,igk(i)))**2 +                   &
                  (xk(2,kpoint)+g(2,igk(i)))**2 +                   &
                  (xk(3,kpoint)+g(3,igk(i)))**2 ) * tpiba2
  end do
  !
  orthonormal = .false.
  precondition= .true.
 !
  if (precondition) then
     do i = 1,npw
        diag(i) = 1.0/max(1.d0,g2kin(i))
     end do
     call zvscal(npw,npwx,nbnd,diag,evc,work)
     call pw_gemm ('Y',nbnd, nbnd, npw, work, npwx, evc, npwx, overlap, nbnd)
     call DPOTRF('U',nbnd,overlap,nbnd,info)
     if (info.ne.0) call error('solve_e','cannot factorize',info)
  end if
  !
  write (6,'(/'' ***  Starting Conjugate Gradient minimization'',   &
       &            9x,''***'')')
  nrec=0
  !
  do ipol = 1,3
     !  read |b> = dV/dtau*psi
     iubar=ipol
     write(filbar,'(''filbar'',i1)') ipol
     call seqopn (iubar,filbar,'unformatted',here)
     if (.not.here) call error('solve_e','file '//filbar//          &
          &        'mysteriously vanished',ipol)
     read (iubar) dvpsi
     close(unit=iubar,status='keep')
     !
     iudwf=10+ipol
     write(fildwf,'(''fildwx'',i1)') ipol
     call  seqopn (iudwf,fildwf,'unformatted',here)
!!!         if (.not.here) then
     !  calculate Delta*psi  (if not already done)
     call setv(2*nbnd*npwx,0.d0,dpsi,1)
     startwith0= .true.
!!!         else
     !  otherwise restart from Delta*psi that is found on file
!!!            read(iudwf) dpsi
!!!         end if
     call cgsolve (A_h,npw,evc,npwx,nbnd,overlap,nbnd, &
                   orthonormal,precondition,diag,      &
                   startwith0,et(1,kpoint),dvpsi,gr,h, &
                   dvpsi,work,niter_ph,tr2_ph,iter,dpsi)
     !  write Delta*psi for an electric field
     rewind (iudwf)
     write (iudwf) dpsi
     close(unit=iudwf)
     !
     write (6,'('' ***  pol. # '',i3,'' : '',i3,'' iterations'')')  &
          &              ipol, iter
  end do
  !
  call mfree(h)
  call mfree(gr)
  call mfree(overlap)
  call mfree(work)
  call mfree(diag)
  !
  call stop_clock('solve_e')
  !
  return
end subroutine solve_e
