!
!---------------------------------------------------------------
subroutine starting_potential &
     (ndm,mesh,zval,zed,nwf,oc,nn,ll,r,enl, &
     vxt,vpot,enne,nspin)
  !---------------------------------------------------------------
  !
  ! starting potential: generalized thomas-fermi atomic potential
  ! it is assumed that the effective charge seen by the reference
  ! electron cannot be smaller than 1 (far from the core)
  !
  use kinds, only : DP
  implicit none
  integer :: nwf, nn(nwf), ll(nwf), ndm, mesh, n, i, nspin
  real(kind=dp) :: r(ndm), vpot(ndm,2), vxt(ndm), enl(nwf), oc(nwf), &
       zed, zval, zz, zen, enne, t,x, vext
  real(kind=dp), parameter :: e2 = 2.0_dp
  external vext
  !
  enne = 0.0_dp
  zz = max(zed,zval)
  do  n=1,nwf
     enne = enne + oc(n)
     zen= 0.0_dp
     do  i=1,nwf
        if(nn(i).lt.nn(n)) zen=zen+oc(i)
        if(nn(i).eq.nn(n).and.ll(i).le.ll(n)) zen=zen+oc(i)
     end do
     zen = max(zz-zen+1.0_dp,1.0_dp)
     enl(n) =-(zen/nn(n))**2
  end do
  !
  do  i=1,mesh
     vxt(i)=vext(r(i))
     x =r(i)*enne**(1.0_dp/3.0_dp)/0.885_dp
     t= zz/(1.0_DP+sqrt(x)*(0.02747_dp-x*(0.1486_dp-0.007298_dp*x)) &
          + x*(1.243_dp+x*(0.2302_dp+0.006944_dp*x)))
     t = max(1.0_dp,t)
     vpot(i,1) = -e2*t/r(i) + vxt(i)
  enddo
  !
  if (nspin.eq.2) then
     do i=1,mesh
        vpot(i,2)=vpot(i,1)
     enddo
  endif
  !
  return
end subroutine starting_potential
