!---------------------------------------------------------------------
subroutine dfx_new(dchi0, vx)
!---------------------------------------------------------------------
#undef DEBUG 

   use constants, only: pi
   use kinds,     only: DP
   use ld1inc,    only: ndm, nwfx, mesh, nwf, nspin, oc, rho, psi, isw, &
                        r, r2, sqr, dx
   implicit none
   ! 
   ! I/O variables
   !
   real(kind=DP) :: dchi0(ndm,nwfx), vx(ndm,2)
   !
   ! local variables
   ! 
   integer, parameter :: niterx = 12 ! 6, 12, 24
   real(kind=DP) :: drho0(ndm,2),appchim1(ndm,2), vslater(ndm,2)
   real(kind=DP) :: int_0_inf_dr
   real(kind=DP) :: vvx(ndm,2,niterx),drhox(ndm,2,niterx), dvh(ndm,2,niterx), &
                    dvh0(ndm,2), aux(ndm), drho1(ndm,2), dvh1(ndm,2)
   real(kind=DP) :: a(niterx,niterx), inva(niterx,niterx), &
                    b1(niterx), b2(niterx), c, c1, work(niterx), x(niterx), uno
   integer :: iwork(niterx), info, iterx
   integer :: i, iter, j, jter, k, nu, is
   real(kind=DP) :: third, fac, capel
   logical :: first = .true.
   save first

!-set the left hand side of the equation
   call drho0ofvx(drho0,dchi0)

   do is=1,nspin
      call hartree(0,2,mesh,r,r2,sqr,dx,drho0(1,is),dvh0(1,is))
   end do

   aux(1:mesh) = drho0(1:mesh,1)*dvh0(1:mesh,1)
   if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                               drho0(1:mesh,2)*dvh0(1:mesh,2) )
   c = int_0_inf_dr(aux,r,r2,dx,mesh,2)

   if (first) then
!      first = .false.
!-slater exchange potential
      do is=1,nspin
         vslater(1:mesh,is) = 0.d0
         do nu=1,nwf
            if (isw(nu) == is) vslater(1:mesh,is) = vslater(1:mesh,is) + &
                                    oc(nu)*psi(1:mesh,1,nu)*dchi0(1:mesh,nu)
         end do
         vslater(1:mesh,is) = vslater(1:mesh,is) / rho(1:mesh,is)
       end do
!      write (*,*) vslater(1:mesh)
   else
      vslater(1:mesh,1:nspin) = vx(1:mesh,1:nspin)
   end if
!- is a reasonable starting guess
   call drhoofv(drho1,vslater)

   drho1(1:mesh,1:nspin) = drho1(1:mesh,1:nspin) - drho0(1:mesh,1:nspin)
   do is=1,nspin
      call hartree(0,2,mesh,r,r2,sqr,dx,drho1(1,is),dvh1(1,is))
   end do
   aux(1:mesh) = drho1(1:mesh,1) * dvh1(1:mesh,1)
   if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                               drho1(1:mesh,2) * dvh1(1:mesh,2) )
   c1 = int_0_inf_dr(aux,r,r2,dx,mesh,2)

#ifdef DEBUG
   write (*,'(a,2f16.10)') "C, C1 ", c, c1
#endif

!- simple Thomas-Fermi approximation to \chi^-1
   third = 1.0d0/3.0d0
   fac   = -(0.75d0*pi)**(2.0d0/3.0d0)
   do is =1, nspin
      appchim1(1:mesh,is) = fac/(r(1:mesh)* &
                            (nspin*rho(1:mesh,is)*r(1:mesh))**third)
   end do

   drhox(1:mesh,1:nspin,1) = drho1(1:mesh,1:nspin)
!- ITERATE !
   do iterx =1,niterx
!- set a new normalized correction vector vvx = chim1*drho/norm
     
      vvx(1:mesh,1:nspin,iterx) = appchim1(1:mesh,1:nspin) * &
                                             drhox(1:mesh,1:nspin,iterx)
      do is=1,nspin
         call hartree(0,2,mesh,r,r2,sqr,dx,vvx(1,is,iterx),dvh(1,is,iterx))
      end do
      aux(1:mesh) =vvx(1:mesh,1,iterx) * dvh(1:mesh,1,iterx)
      if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) +  &
                                  vvx(1:mesh,2,iterx) * dvh(1:mesh,2,iterx) )
      capel = int_0_inf_dr(aux,r,r2,dx,mesh,2)
#ifdef DEBUG
      write (*,*) "norm ", capel
#endif
      if (capel >0) then
         capel = 1.d0/sqrt(capel)
         vvx(1:mesh,1:nspin,iterx) = vvx(1:mesh,1:nspin,iterx) * capel
      end if
!- compute the corresponding drho
      call drhoofv(drhox(1,1,iterx),vvx(1,1,iterx) )
      do is =1,nspin
         call hartree(0,2,mesh,r,r2,sqr,dx,drhox(1,is,iterx),dvh(1,is,iterx))
      end do

      aux(1:mesh) = drhox(1:mesh,1,iterx) * dvh1(1:mesh,1)
      if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                                  drhox(1:mesh,2,iterx) * dvh1(1:mesh,2) )
      b1(iterx) = int_0_inf_dr(aux,r,r2,dx,mesh,2)

      aux(1:mesh) = drho1(1:mesh,1) * dvh(1:mesh,1,iterx)
      if (nspin==2) aux(1:mesh) =  2.d0 * ( aux(1:mesh) + &
                                   drho1(1:mesh,2) * dvh(1:mesh,2,iterx) )
      b2(iterx) = int_0_inf_dr(aux,r,r2,dx,mesh,2)

      do jter =1,iterx
     
         aux(1:mesh) = drhox(1:mesh,1,iterx) * dvh(1:mesh,1,jter)
         if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                                     drhox(1:mesh,2,iterx)*dvh(1:mesh,2,jter) )
         a(iterx,jter) = int_0_inf_dr(aux,r,r2,dx,mesh,2)

         aux(1:mesh) = drhox(1:mesh,1,jter) * dvh(1:mesh,1,iterx)
         if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                                     drhox(1:mesh,2,jter)*dvh(1:mesh,2,iterx) )
         a(jter,iterx) = int_0_inf_dr(aux,r,r2,dx,mesh,2)

      end do
      capel = 0.d0
      do i=1,iterx
         do j=1,iterx
            capel = capel + abs(a(i,j)-a(j,i))
            a(i,j) = 0.5d0*(a(i,j)+a(j,i))
            a(j,i) = a(i,j)
         end do
      end do
#ifdef DEBUG
      write (*,'(a,12f16.10)') "CAPEL a  ", capel
#endif
  
      inva = a

      CALL DSYTRF('U', iterx, inva, niterx, iwork, work, niterx,info)
      if (info.ne.0) stop 'factorization'
      CALL DSYTRI( 'U', iterx, inva, niterx, iwork, work, info )
      if (info.ne.0) stop 'DSYTRI'
      forall ( i=1:iterx, j=1:iterx, j>i ) inva(j,i) = inva(i,j)

!      write (*,*) "INVA "
!      write (*,'(12f16.10)') inva
      capel = 0.d0
      do i=1,iterx
         do j=1,iterx
            uno = 0.d0
            do k=1,iterx
               uno = uno + a(i,k)*inva(k,j)
            end do
            if (i.eq.j) uno = uno - 1.d0
            capel = capel + abs(uno)
         end do
      end do
#ifdef DEBUG
      write (*,'(a,12f16.10)') "CAPEL uno", capel
#endif
    
      x = 0.d0
      capel = c1
      do i=1,iterx
         do j=1,iterx
            x(i) = x(i) - inva(i,j) * 0.5d0*(b1(j)+b2(j))
         end do        
         capel = capel + x(i) * (b1(i)+b2(i)) 
         do j =1,i
            capel = capel + x(i)*a(i,j)*x(j)
         end do
         do j =1,i-1
            capel = capel + x(i)*a(j,i)*x(j)
         end do
      end do        
!      write (*,'(a,12f16.10)') "X ", x
#ifdef DEBUG
      write (*,*) "capel       ", capel
#endif


      vx(1:mesh,1:nspin) = vslater(1:mesh,1:nspin)
      do j=1,iterx
         vx(1:mesh,1:nspin) = vx(1:mesh,1:nspin) + x(j) * vvx(1:mesh,1:nspin,j)
      end do

      if (iterx.eq.niterx) return

      call drhoofv(drhox(1,1,iterx+1), vx )
      drhox(1:mesh,1:nspin,iterx+1) = drhox(1:mesh,1:nspin,iterx+1) - &
                                      drho0(1:mesh,1:nspin)
      do is=1,nspin
         call hartree(0,2,mesh,r,r2,sqr,dx,drhox(1,1,iterx+1),dvh(1,1,iterx+1))
      end do

      aux(1:mesh) = drhox(1:mesh,1,iterx+1)*dvh(1:mesh,1,iterx+1)
      if (nspin==2) aux(1:mesh) = 2.d0 * ( aux(1:mesh) + &
                                  drhox(1:mesh,1,iterx+1)*dvh(1:mesh,1,iterx+1))
      capel = int_0_inf_dr(aux,r,r2,dx,mesh,2)
#ifdef DEBUG
      write (*,*) "capel-check ", capel
#endif
!
   end do
!
   return
end subroutine dfx_new
