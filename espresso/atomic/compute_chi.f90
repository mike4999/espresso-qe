!
! Copyright (C) 2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!--------------------------------------------------------------------------
subroutine compute_chi(lam,ik,ns,xc,lbes4)
  !--------------------------------------------------------------------------
  !
  !     This routine computes the chi functions:
  !          |chi> = (\epsilon -T -V_{loc)) |psi>
  !      
  use kinds, only : DP
  use ld1inc

  implicit none
  integer :: &
       ik,    & ! the point corresponding to rc
       ns,    & ! the wavefunction
       lam      ! the angular momentum
  logical :: &
       lbes4 
  real(DP) :: &
       xc(8)
  !
  real(DP) :: &
       j1(ndm),aux(ndm), &
       b(4),c(4), arow(ndm),brow(ndm),crow(ndm),drow(ndm), &
       b0e, g0, g1, g2, &
       ddx12, &
       x4l6, &
       x6l12, dpoly
  real(DP), external :: pr, d2pr, dpr

  integer :: &
       n, nstart

  !
  !   Troullier-Martins: use the analytic formula
  !
  if (tm) then
     do n=1,ik
        dpoly = dpr(xc,xc(7),r(n))
        ! dpr =  first derivate of polynomial pr
        ! d2pr= second derivate of polynomial pr
        chis(n,ns) = (enls(ns) + (2*lam+2)/r(n)*dpoly + &
             d2pr(xc,xc(7),r(n)) + dpoly**2 - vpsloc(n))*phis(n,ns)
     enddo
     do n = ik+1,mesh
        chis(n,ns) = (vpot(n,1) - vpsloc(n))*phis(n,ns)
     enddo
     return
  end if
  !
  !   RRKJ: first expand in a taylor series the phis function
  !   Since we know that the phis functions are a sum of Bessel 
  !   functions with coefficients xc, we compute analytically
  !   the asymptotic expansion
  !
  !
  ddx12=dx*dx/12.0_dp
  x4l6=4*lam+6
  x6l12=6*lam+12

  do n=1,6
     j1(n)=phis(n,ns)/r(n)**(lam+1)
  enddo
  call seriesbes(j1,r,r2,6,c)
  !
  if (lam == 0) then
     if(lbes4.or.rho0.eq.0.0_dp)then
        c(1)=xc(1)+xc(2)+xc(3)
        c(2)=0.0_dp
        c(3)=-xc(1)*(xc(4)**2/6.0_dp) &
             -xc(2)*(xc(5)**2/6.0_dp) &
             -xc(3)*(xc(6)**2/6.0_dp)
        c(4)=0.0_dp
     else
        c(1)=xc(1)+xc(2)+xc(3)+xc(4)
        c(2)=0.0_dp
        c(3)=-xc(1)*(xc(5)**2/6.0_dp)  &
             -xc(2)*(xc(6)**2/6.0_dp)  &
             -xc(3)*(xc(7)**2/6.0_dp)  &
             -xc(4)*(xc(8)**2/6.0_dp)
        c(4)=0.0_dp
     endif
  elseif (lam == 3) then
     c(1)=xc(1)*(48.0_dp*xc(4)**3/5040.0_dp)+   &
          xc(2)*(48.0_dp*xc(5)**3/5040.0_dp)+   &
          xc(3)*(48.0_dp*xc(6)**3/5040.0_dp)
     c(2)=0.0_dp
     c(3)=-xc(1)*(192.0_dp*xc(4)**5/362880.0_dp)  &
          -xc(2)*(192.0_dp*xc(5)**5/362880.0_dp)  &
          -xc(3)*(192.0_dp*xc(6)**5/362880.0_dp)
     c(4)=0.0_dp
  elseif (lam == 2) then
     c(1)=xc(1)*(xc(4)**2/15.0_dp)+   &
          xc(2)*(xc(5)**2/15.0_dp)+   &
          xc(3)*(xc(6)**2/15.0_dp)
     c(2)=0.0_dp
     c(3)=-xc(1)*(xc(4)**4/210.0_dp)  &
          -xc(2)*(xc(5)**4/210.0_dp)  &
          -xc(3)*(xc(6)**4/210.0_dp)
     c(4)=0.0_dp
  elseif (lam == 1) then
     c(1)=xc(1)*(xc(4)/3.0_dp)+  &
          xc(2)*(xc(5)/3.0_dp)+  &
          xc(3)*(xc(6)/3.0_dp)
     c(2)=0.0_dp
     c(3)=-xc(1)*(xc(4)**3/30.0_dp) &
          -xc(2)*(xc(5)**3/30.0_dp) &
          -xc(3)*(xc(6)**3/30.0_dp)
     c(4)=0.0_dp
  else
     call errore('compute_chi','lam not programmed',1) 
  endif
  !
  !     and the potential
  !
  do n=1,4
     j1(n)=vpsloc(n)
  enddo
  call series(j1,r,r2,b)
  !
  !   and compute the taylor expansion of the chis
  !
  b0e=(b(1)-enls(ns))

  g0=x4l6*c(3)-b0e*c(1)
  g1=x6l12*c(4)-c(1)*b(2)
  g2=-(b0e*c(3)+b(3)*c(1))
  nstart=5
  do n=1,nstart-1
     chis(n,ns)= (g0+r(n)*(g1+g2*r(n)))*r(n)**(lam+3)/sqr(n)
  enddo
  do n=1,mesh
     aux(n)= (g0+r(n)*(g1+g2*r(n)))
  enddo
  !
  !    set up the equation
  !
  do n=1,mesh
     phis(n,ns)=phis(n,ns)/sqr(n)
  enddo
  do n=1,mesh
     j1(n)=r2(n)*(vpsloc(n)-enls(ns))+(lam+0.5_dp)**2
     j1(n)=1.0_dp-ddx12*j1(n)
  enddo

  do n=nstart,mesh-3
     drow(n)= phis(n+1,ns)*j1(n+1)   &
          + phis(n,ns)*(-12.0_dp+10.0_dp*j1(n))+ &
          phis(n-1,ns)*j1(n-1)

     brow(n)=10.0_dp*ddx12
     crow(n)=ddx12
     arow(n)=ddx12
  enddo
  drow(nstart)=drow(nstart)-ddx12*chis(nstart-1,ns)
  chis(mesh-2,ns)=0.0_dp
  chis(mesh-1,ns)=0.0_dp
  chis(mesh,ns)=0.0_dp
  !
  !    and solve it
  !
  call tridiag(arow(nstart),brow(nstart),crow(nstart), &
       drow(nstart),chis(nstart,ns),mesh-3-nstart)
  !
  !   put the correct normalization and r dependence
  !  
  do n=1,mesh
     phis(n,ns)=phis(n,ns)*sqr(n)
     chis(n,ns)=chis(n,ns)*sqr(n)/r2(n)
     !         if(lam.eq.0)
     !     +    write(*,'(5(e20.13,1x))')
     !     +          r(n),chis(n,ns),chis(n,ns)/r(n)**(lam+1),
     !     +          aux(n),aux(n)*r(n)**(lam+1)
  enddo
  !
  !    smooth close to the origin with asymptotic expansion
  !
  do n=nstart,mesh
     if (abs(chis(n,ns)/r(n)**(lam+1)-aux(n))  &
          .lt.1.e-3_dp*abs(aux(n)) ) goto 100
     chis(n,ns)=aux(n)*r(n)**(lam+1)
  enddo

100 if (n.eq.mesh+1.or.r(n).gt.0.05_dp)then
     print*,lam,ns,n,mesh,r(n)
     call errore('compute_chi','n is too large',1)
  endif
  !
  !    clean also after 9 a.u.
  !
  do n=mesh,1,-1
     if (r(n).lt.9.0_dp) goto 200
     chis(n,ns)=0.0_dp
  enddo
200 continue
  return
end subroutine compute_chi


subroutine tridiag(a,b,c,r,u,n)
  !
  !     See Numerical Recipes.
  !
  use kinds, only : DP
  implicit none

  integer :: n
  real(DP) :: a(n),b(n),c(n),r(n),u(n)
  real(DP) :: gam(n), bet

  integer j

  if (abs(b(1)).lt.1.e-10_DP)  &
       call errore('tridiag','b(1) is too small',1)

  bet=b(1)
  u(1)=r(1)/bet
  do j=2,n
     gam(j)=c(j-1)/bet
     bet=b(j)-a(j)*gam(j)
     if (abs(bet) < 1.e-10_DP) &
          call errore('tridiag','bet is too small',1)
     u(j)=(r(j)-a(j)*u(j-1))/bet
  enddo
  do j=n-1,1,-1
     u(j)=u(j)-gam(j+1)*u(j+1)
  enddo
  return
end subroutine tridiag
