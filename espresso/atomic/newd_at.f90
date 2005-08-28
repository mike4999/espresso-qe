!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-------------------------------------------------------------------------
subroutine newd_at
  !-------------------------------------------------------------------------
  !
  !     this ruotine computes the new D coeeficients
  !
  !
  use ld1inc

  integer :: &
       ib,jb,n,is,nst

  real(DP) :: &
       int_0_inf_dr, &   ! the integral function
       gi(ndm)          ! the gi function

  !
  !    screening the D coefficients
  !
  if (pseudotype.eq.3) then
     do ib=1,nbeta
        do jb=1,ib
           if (lls(ib).eq.lls(jb).and.abs(jjs(ib)-jjs(jb)).lt.1.0e-7_dp) then
              nst=(lls(ib)+1)*2
              do is=1,nspin
                 do n=1,ikk(ib)
                    gi(n)=qvan(n,ib,jb)*vpstot(n,is)
                 enddo
                 ddd(ib,jb,is)= bmat(ib,jb) &
                      + int_0_inf_dr(gi,r,r2,dx,ikk(ib),nst)
                 ddd(jb,ib,is)=ddd(ib,jb,is)
              enddo
           endif
        enddo
     enddo
  endif

  return
end subroutine newd_at
