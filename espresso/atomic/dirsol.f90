!
! Copyright (C) 2002 Vanderbilt group
! This file is distributed under the terms of the GNU General Public
! License as described in the file 'License' in the current directory.
!
! This routine has been modified in order to be compatible with the
! ld1 code. The numerical algorithm is unchanged.
! ADC Nov 2003
!
!-------------------------------------------------------------------------
!
subroutine dirsol(idim1,mesh,ncur,lcur,jcur,it,e0,thresh,dx,snl,r,rab,ruae)
!
!     subroutine to compute solutions to the full dirac equation
!
!     the dirac equation in rydberg units reads:
!
!     df(r)     k                     alpha
!     ----- = + - f(r) - ( e - v(r) ) ----- g(r)
!      dr       r                       2
!
!     dg(r)     k                          4      alpha
!     ----- = - - g(r) + ( e - v(r) +  -------- ) ----- f(r)
!      dr       r                      alpha**2     2
!
!     where 
!            alpha is the fine structure constant
!            f(r) is r*minor component
!            g(r) is r*major component
!            k is quantum number 
!               k = - (l+1)    if  j = l+0.5
!               k = + l        if  j = l-0.5
!     IMPORTANT: on output, snl(:,1) contains the MAJOR component
!                           snl(:,2) contains the MINOR component
!
!----------------------------------------------------------------------------
!
use kinds, only : DP
implicit none
integer :: idim1 
real(kind=dp) :: r(idim1),     &   ! the radial mesh
                 rab(idim1),   &   ! derivative of the radial mesh
                 ruae(idim1),  &   ! the all electron potential
                 snl(idim1,2)       ! the wavefunction

real(kind=dp) :: e0,       &     ! the starting energy eigenvalue
                 dx,       &     ! dx mesh value
                 jcur,     &     ! the j of the state
                 thresh
                  
integer ::  mesh,  &          ! the dimension of the mesh 
            it,    &          ! the iteration
            ncur,  &          ! the n of the state
            lcur              ! the l of the state

real(kind=dp) :: tbya, abyt,        &  
                 emin, emax,        &
                 zz(idim1,2,2),     &
                 tolinf,alpha2,alpha,  &
                 yy(idim1,2),       &
                 vzero,             &
                 f0,f1,f2,g0,g1,g2, &
                 gout, gpout,       &
                 gin, gpin,         &
                 factor,            &
                 ecur,              &
                 xw, decur, decurp          
real(kind=dp) :: r2(idim1), f(idim1), int_0_inf_dr

integer :: itmax, &     ! maximum number of iterations
           iter,  &     ! current iteration
           ir,    &     ! counter
           ig,    &     ! auxiliary
           kcur,  &     ! current k
           nctp,  &     ! index of the classical turning point
           nodes, &     ! the number of nodes
           ninf         ! practical infinite
!
!               r o u t i n e  i n i t i a l i s a t i o n
do ir=1,mesh
   ruae(ir)=ruae(ir)*r(ir)
enddo
!
!     set the maximum number of iterations for improving wavefunctions
!
itmax = 100
!
!     set ( 2 / fine structure constant )
tbya = 2.0_DP * 137.04_DP
!     set ( fine structure constant / 2 )
abyt = 1.0_DP / tbya

r2=r**2

if (jcur.eq.lcur+0.5_DP) then
    kcur = - ( lcur + 1 )
else
    kcur = lcur
endif
!
!       set initial upper and lower bounds for the eigen value
emin = - 1.0e10_DP
emax = 1.0_DP
ecur=e0
!
do iter = 1,itmax
   yy = 0.0_DP
!
!         define the zz array
!         ===================
!
  if ( iter .eq. 1 ) then
    do ir = 1,mesh
       zz(ir,1,1) = rab(ir) * dble(kcur) / r(ir)
       zz(ir,2,2) = - zz(ir,1,1)
    enddo
  endif
  do ir = 1,mesh
     zz(ir,1,2) = - rab(ir) * ( ecur - ruae(ir) / r(ir) ) * abyt
     zz(ir,2,1) = - zz(ir,1,2) + rab(ir) * tbya
  enddo
!
!   ==============================================
!   classical turning point and practical infinity
!   ==============================================
!
  do nctp = mesh,10,-1
     if ( zz(nctp,1,2) .lt. 0.0_DP ) goto 240
  enddo
  call errore('dirsol', 'no classical turning point found', 1)
!
!         jump point out of classical turning point loop
240   continue

  if ( nctp .gt. mesh - 10 ) then 
!     write(6,*) 'State nlk=', ncur, lcur, kcur, nctp, mesh
!     write(6,*) 'ecur, ecurmax=', ecur, ruae(mesh-10)/r(mesh-10)
     write(6,*) 'classical turning point too close to mesh',ncur,lcur,kcur
     e0=0.0_DP
     goto 700
  endif
!
  tolinf = log(thresh) ** 2
  do ninf = nctp+10,mesh
     alpha2 = (ruae(ninf)/r(ninf)-ecur) * (r(ninf) - r(nctp))**2
     if ( alpha2 .gt. tolinf ) goto 260
  enddo
!
!         jump point out of practical infinity loop
260     continue
!
  if (ninf.gt.mesh) ninf=mesh
!
!         ===========================================================
!         analytic start up of minor and major components from origin
!         ===========================================================
!
!         with finite nucleus so potential constant at origin we have
!
!         f(r) = sum_n f_n r ** ( ig + n )
!         g(r) = sum_n g_n r ** ( ig + n )
!
!         with
!
!         f_n+1 = - (ecur-v(0)) * abyt * g_n / ( ig - kcur + n + 1 )
!         g_n+1 = (ecur-v(0)+tbya**2 ) * abyt * f_n / ( ig + kcur + n + 1)
!
!         if kcur > 0  ig = + kcur , f_0 = 1 , g_0 = 0
!         if kcur < 0  ig = - kcur , f_0 = 0 , g_1 = 1
!
  vzero = ruae(1) / r(1)
!
!         set f0 and g0
  if ( kcur .lt. 0 ) then
     ig = - kcur
     f0 = 0
     g0 = 1
  else
     ig = kcur
     f0 = 1
     g0 = 0
  endif
 
  f1 = - (ecur-vzero) * abyt * g0 / dble( ig - kcur + 1 )
  g1 = (ecur-vzero+tbya**2) * abyt * f0 / dble( ig + kcur + 1 )
  f2 = - (ecur-vzero) * abyt * g1 / dble( ig - kcur + 2 )
  g2 = (ecur-vzero+tbya**2) * abyt * f1 / dble( ig + kcur + 2 )
!
!
  do ir = 1,5
     yy(ir,1) = r(ir)**ig * ( f0 + r(ir) * ( f1 + r(ir) * f2 ) )
     yy(ir,2) = r(ir)**ig * ( g0 + r(ir) * ( g1 + r(ir) * g2 ) )
  enddo

!         ===========================
!         outward integration to nctp
!         ===========================
!
!         fifth order predictor corrector integration routine
  call cfdsol(zz,yy,6,nctp,idim1)
!
!         save major component and its gradient at nctp
  gout = yy(nctp,2)
  gpout = zz(nctp,2,1)*yy(nctp,1) + zz(nctp,2,2)*yy(nctp,2)
  gpout = gpout / rab(nctp)
!
!   ==============================================
!   start up of wavefunction at practical infinity
!   ==============================================
!
  do ir = ninf,ninf-4,-1
     alpha = sqrt( ruae(ir) / r(ir) - ecur )
     yy(ir,2) = exp ( - alpha * ( r(ir) - r(nctp) ) )
     yy(ir,1) = ( dble(kcur)/r(ir) - alpha ) * yy(ir,2)*tbya / &
  &               ( ecur - ruae(ir)/r(ir) + tbya ** 2 )
  enddo
!
!         ==========================
!         inward integration to nctp
!         ==========================
!
!         fifth order predictor corrector integration routine
  call cfdsol(zz,yy,ninf-5,nctp,idim1)
!
!         save major component and its gradient at nctp
  gin = yy(nctp,2)
  gpin = zz(nctp,2,1)*yy(nctp,1) + zz(nctp,2,2)*yy(nctp,2)
  gpin = gpin / rab(nctp)
!
!
!         ===============================================
!         rescale tail to make major component continuous
!         ===============================================
!
  factor = gout / gin
  do ir = nctp,ninf
     yy(ir,1) = factor * yy(ir,1)
     yy(ir,2) = factor * yy(ir,2)
  enddo
!
  gpin = gpin * factor
!
!         =================================
!         check that the number of nodes ok
!         =================================
!
!         count the number of nodes in major component
  call nodeno(yy(1,2),1,ninf,nodes,idim1)
 
  if ( nodes .lt. ncur - lcur - 1 ) then
!           energy is too low
     emin = ecur
!         write(6,*) 'energy too low'
!         write(6,'(i5,3f12.5,2i5)') &
!    &         iter,emin,ecur,emax,nodes,ncur-lcur-1
     if ( ecur * 0.9_DP .gt. emax ) then
         ecur = 0.5_DP * ecur + 0.5_DP * emax 
     else
         ecur = 0.9_DP * ecur
     endif
     goto 370
  endif
!
  if ( nodes .gt. ncur - lcur - 1 ) then
!           energy is too high
     emax = ecur
!         
!         write(6,*) 'energy too high'
!         write(6,'(i5,3f12.5,2i5)') &
!    &         iter,emin,ecur,emax,nodes,ncur-lcur-1
     if ( ecur * 1.1_DP .lt. emin ) then
        ecur = 0.5_DP * ecur + 0.5_DP * emin
     else
        ecur = 1.1_DP * ecur
     endif
     goto 370
  endif
!
!
!         =======================================================
!         find normalisation of wavefunction 
!         =======================================================
!
   do ir = 1,ninf
      f(ir) = (yy(ir,1)**2 + yy(ir,2)**2)
   enddo
   factor=int_0_inf_dr(f,r,r2,dx,ninf,2*ig)
!
!
!         =========================================
!         variational improvement of the eigenvalue
!         =========================================
!
   decur = gout * ( gpout - gpin ) / factor
!
!         to prevent convergence problems:
!         do not allow decur to exceed 20% of | ecur |
!         do not allow decur to exceed 70% of distance to emin or emax
   if (decur.gt.0.0_DP) then
      emin=ecur
      decurp=min(decur,-0.2_DP*ecur,0.7_DP*(emax-ecur))
   else
      emax=ecur
      decurp=-min(-decur,-0.2_DP*ecur,0.7_DP*(ecur-emin))
   endif
!
!         write(6,'(i5,3f12.5,1p2e12.4)') &
!    &         iter,emin,ecur,emax,decur,decurp
!
!         test to see whether eigenvalue converged
   if ( abs(decur) .lt. thresh ) goto 400
 
   ecur = ecur + decurp
!
!         jump point from node check
370  continue
!
!         =======================================================
!         check that the iterative loop is not about to terminate
!         =======================================================
!
   if ( iter .eq. itmax ) then
!           eigenfunction has not converged in allowed number of iterations
            
!      write(6,999) it,ncur,lcur,jcur,e0,ecur
!999   format('iter',i4,' state',i4,i4,f4.1,' could not be converged.',/,   &
!    &      ' starting energy for calculation was',f10.5, &
!    &      ' and end value =',f10.5)
       write(6,*) 'state nlj',ncur,lcur,jcur, ' not converged'
      goto 700
   endif
!
!       close iterative loop
enddo
!
!       jump point on successful convergence of eigenvalue
400   continue
!
!   normalize the wavefunction and exit
!      
snl=0.0_DP
do ir=1,mesh
   snl(ir,1)=yy(ir,2)/sqrt(factor)
   snl(ir,2)=yy(ir,1)/sqrt(factor)
enddo
e0=ecur
700 continue
do ir=1,mesh
   ruae(ir)=ruae(ir)/r(ir)
enddo
return
end
