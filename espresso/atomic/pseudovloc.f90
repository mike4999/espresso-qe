!
!--------------------------------------------------------------------------
      subroutine pseudovloc
!--------------------------------------------------------------------------
!
!     This routine generate a local pseudopotential 
!     The output of the routine are:
!     vpsloc: the local pseudopotential
!
!      
use ld1inc
implicit none

      real(kind=dp) :: &
               fae,   &  ! the value of the all-electron function
               f1ae,  &  ! its first derivative
               f2ae,  &  ! the second derivative
               faenorm   ! the norm of the function

      integer :: &
               nwf0, &  ! used to specify the all electron function
               nst,  &  ! auxiliary
               iok,  &  ! if 0 there are no problems
               ik       ! the point corresponding to rc

      real(kind=dp) ::             &
               f1aep1,f1aem1,jnor, &  ! auxilairy quantities
               p1aep1, p1aem1,     &  ! derivatives of the bessel functions
               xc(8),              &  ! the coefficients of the fit
               bm(2),              &  ! the derivative of the bessel
               vaux(ndm,2),        &  ! keeps the potential
               j1(ndm,4)              ! the bessel functions

      real(kind=dp) :: &
            deriv_7pts, deriv2_7pts
     

      integer ::         &
               n,        &  ! counter on mesh points
               indi,rep, &  ! auxiliary
               nc           ! counter on bessel

      write(6,'(/,5x,'' Generating local potential, lloc= '',i4)') lloc

      if (lloc.lt.0) then
!
!   Compute the potential by smoothing the AE potential
!
!   Compute the ik which correspond to this cutoff radius
!
         ik=0
         do n=1,mesh
            if (r(n).lt.rcloc) ik=n
         enddo
         if (mod(ik,2).eq.0) ik=ik+1
         if (ik.gt.mesh) &
             call errore('gener_rrkj3','ik is wrong ',1)
!
!    compute first and second derivative
!
         fae=vpot(ik,1)
         f1ae=deriv_7pts(vpot,ik,r(ik),dx)
         f2ae=deriv2_7pts(vpot,ik,r(ik),dx)
!
!    find the q_i of the bessel functions
!      
         call find_qi(f1ae/fae,xc(3),ik,0,2,0,iok)
         if (iok.ne.0) &
             call errore('pseudovloc','problems with find_qi',1)
!
!    compute the functions
!
         do nc=1,2
            call sph_bes(ik+1,r,xc(2+nc),0,j1(1,nc))
            jnor=j1(ik,nc)
            do n=1,ik+1
               j1(n,nc)=j1(n,nc)*vpot(ik,1)/jnor
            enddo
         enddo
!
!    compute the second derivative and impose continuity of zero, 
!    first and second derivative
!
       
         do nc=1,2
            p1aep1=(j1(ik+1,nc)-j1(ik,nc))/(r(ik+1)-r(ik))
            p1aem1=(j1(ik,nc)-j1(ik-1,nc))/(r(ik)-r(ik-1))
            bm(nc)=(p1aep1-p1aem1)*2.d0/(r(ik+1)-r(ik-1))
         enddo

         xc(2)=(f2ae-bm(1))/(bm(2)-bm(1))
         xc(1)=1.d0-xc(2)
         write(6, 110) rcloc,xc(4)**2 
110      format (/5x, ' Local pseudo, rcloc=',f6.3, &
          ' Estimated cut-off energy= ', f8.2,' Ry')
!
!    define the local pseudopotential
!
         do n=1,ik
            vpsloc(n)=xc(1)*j1(n,1)+xc(2)*j1(n,2)
         enddo

         do n=ik+1,mesh
            vpsloc(n)=vpot(n,1)
         enddo

      else
!
!    if a given angular momentum gives the local component this is done 
!    here
!
         nst=(lloc+1)*2
         rep=0
         if (rel==2.and.lloc.gt.0) rep=1
         vpsloc=0.d0
         vaux=0.d0
         do indi=0,rep
            nwf0=nstoae(nsloc+indi)
            if (enls(nsloc+indi).eq.0.d0) &
                enls(nsloc+indi)=enl(nstoae(nsloc+indi))
!
!    compute the ik closer to r_cut
!
            ik=0
            do n=1,mesh
               if (r(n).lt.rcut(nsloc+indi)) ik=n
            enddo
            if (mod(ik,2).eq.0) ik=ik+1
            if (ik.eq.1.or.ik.gt.mesh) &
               call errore('pseudovloc','ik is wrong ',1)
            rcloc=rcut(nsloc+indi)
!
!   compute the phi functions
!
            call compute_phipot(lloc,ik,nwf0,nsloc+indi,xc)
!
!     set the local potential equal to the all-electron one at large r
!
            do n=1,mesh
               vaux(n,indi+1)=vpot(n,1)
            enddo
            do n=1,mesh
               if (r(n).lt.9.d0) then
                  vaux(n,indi+1)=chis(n,nsloc+indi)/phis(n,nsloc+indi)
               endif
            enddo
         enddo
         if (rep==0) then
            do n=1,mesh
               vpsloc(n)=vaux(n,1)
            enddo
         else
            do n=1,mesh
               vpsloc(n)=(lloc*vaux(n,1)+(lloc+1.d0)*vaux(n,2))/ &
                                                  (2.d0*lloc+1.d0)
            enddo
         endif
      endif

      return
      end
