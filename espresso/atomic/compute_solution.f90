!
!---------------------------------------------------------------
      subroutine compute_solution(nn,lam,jam,e,mesh,ndm,dx,r, &
                  r2,sqr,vpot, &
                  y,beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk)
!---------------------------------------------------------------
!
!  numerical integration of the radial schroedinger equation for
!  bound states in a local potential.
!
!  This routine works at fixed e
!  It allows a nonlocal potential and an overlap
!  operator. Therefore it can solve a general schroedinger
!  equation necessary to solve a US pseudopotential
!
      implicit none
      
      integer, parameter :: dp=kind(1.d0)

      integer :: &
              nn, &       ! main quantum number for node number
              lam, &      ! l angular momentum
              mesh,&      ! size of radial mesh
              ndm, &      ! maximum radial mesh 
              nbeta,&     ! number of beta function  
              nwfx, &     ! maximum number of beta functions
              itscf, &    ! scf iteration
              lls(nbeta),&! for each beta the angular momentum
              ikk(nbeta) ! for each beta the point where it become zero

      real(kind=dp) :: &
              e,       &  ! output eigenvalue
              dx,      &  ! linear delta x for radial mesh
              jam,     &  ! j angular momentum
              r(mesh), &  ! radial mesh
              r2(mesh),&  ! square of radial mesh
              sqr(mesh),& ! square root of radial mesh
              vpot(mesh),&! the local potential 
              thresh,   & ! precision of eigenvalue
              y(mesh),  & ! the output solution
              jjs(nwfx), & ! the j angular momentum
              beta(ndm,nwfx),& ! the beta functions
              ddd(nwfx,nwfx),qq(nwfx,nwfx) ! parameters for computing B_ij
!
!    the local variables
!
      real(kind=dp) :: &
           ddx12,      &  ! dx**2/12 used for Numerov integration
           sqlhf,      &  ! the term for angular momentum in equation
           xl1, x4l6, x6l12, x8l20,& ! used for starting series expansion
           ze2,        &  ! possible coulomb term aroun the origin (set 0)
           b(0:3),     &  ! coefficients of taylor expansion of potential
           c1,c2,c3,c4,b0e, & ! auxiliary for expansion of wavefunction
           rr1,rr2,    & ! values of y in the first points
           eup,elw,    & ! actual energy interval
           ymx,        & ! the maximum value of the function
           rap,        & ! the ratio between the number of nodes
           fe,sum,dfe,de, &! auxiliary for numerov computation of e
           eps,        & ! the epsilon of the delta e
           yln, xp, expn,& ! used to compute the tail of the solution
           int_0_inf_dr  ! integral function

     real(kind=dp), allocatable :: &
           f(:),    &   ! the f function
           el(:),c(:) ! auxiliary for inward integration
      
      integer :: &
              n,  &    ! counter on mesh points
              iter,&   ! counter on iteration
              ik,  &   ! matching point
              ns,  &   ! counter on beta functions
              l1,  &   ! lam+1
              nst, &   ! used in the integration routine
              ndcr,&    ! the required number of nodes
              npt, &   ! number of points for energy intervals
              ninter,& ! number of possible energy intervals
              icountn,& ! counter on energy intervals 
              ierr, &
              ncross,& ! actual number of nodes
              nstart  ! starting point for inward integration

!
!  set up constants and allocate variables the 
!
      allocate(f(mesh), stat=ierr)
      allocate(el(mesh), stat=ierr)
      allocate(c(mesh), stat=ierr)

      ddx12=dx*dx/12.d0
      l1=lam+1
      nst=l1*2
      sqlhf=(dble(lam)+0.5d0)**2
      xl1=lam+1
      x4l6=4*lam+6
      x6l12=6*lam+12
      x8l20=8*lam+20

      ndcr=nn-lam-1
!
!  series developement of the potential near the origin
!
      ze2=0.d0
      do n=1,4
         y(n)=vpot(n)-ze2/r(n)
      enddo
      call series(y,r,r2,b)
      
!      write(6,*) 'eneter nn,lam,eup,elw,e',nn,lam,nbeta,eup,elw,e
!
!  set up the f-function and determine the position of its last
!  change of sign
!  f < 0 (approximatively) means classically allowed   region
!  f > 0         "           "        "      forbidden   "
!
         ik=0
         f(1)=ddx12*(r2(1)*(vpot(1)-e)+sqlhf)
         do n=2,mesh
            f(n)=ddx12*(r2(n)*(vpot(n)-e)+sqlhf)
            if( f(n).ne.sign(f(n),f(n-1)).and.n.lt.mesh-5 ) ik=n
         enddo
         if (ik.eq.0.and.nbeta.eq.0) ik=mesh*3/4

         if(ik.ge.mesh-2) then
            call errore('compute_solution', &
                      'No point found for matching',-1)
            do n=1,mesh
               write(6,*) r(n), vpot(n), f(n)
            enddo
            stop
         endif
!
!     determine if ik is sufficiently large
!
         do ns=1,nbeta
            if (lls(ns).eq.lam.and.ikk(ns).gt.ik) ik=ikk(ns)
         enddo
!
!     if everything is ok continue the integration and define f
!
         do n=1,mesh
            f(n)=1.0d0-f(n)
         enddo
!
!  determination of the wave-function in the first two points by
!  series developement
!
         b0e=b(0)-e
         c1=0.5*ze2/xl1
         c2=(c1*ze2+b0e)/x4l6
         c3=(c2*ze2+c1*b0e+b(1))/x6l12
         c4=(c3*ze2+c2*b0e+c1*b(1)+b(2))/x8l20
         rr1=(1.d0+r(1)*(c1+r(1)*(c2+r(1)*(c3+r(1)*c4))))*r(1)**l1
         rr2=(1.d0+r(2)*(c1+r(2)*(c2+r(2)*(c3+r(2)*c4))))*r(2)**l1
         y(1)=rr1/sqr(1)
         y(2)=rr2/sqr(2)
!
!    outward integration before ik
!
        call integrate_outward (lam,jam,e,mesh,ndm,dx,r,r2,sqr,f, &
                              b,y,beta,ddd,qq,nbeta,nwfx,lls,jjs,ik)
!
!    inward integration up to ik
!
        call integrate_inward(e,mesh,ndm,dx,r,r2,sqr,f,y, &
                                            c,el,ik,nstart)
!
!   exponential tail of the solution if it was not computed
!
      if (nstart.lt.mesh) then
         do n=nstart,mesh-1
            if (y(n).eq.0.d0) then
               y(n+1)=0.d0
            else
               yln=dlog(dabs(y(n)))
               xp=-dsqrt(12.d0*abs(1.d0-f(n)))
               expn=yln+xp
               if (expn.lt.-80.0) then
                  y(n+1)=0.d0
               else
                  y(n+1)=dsign(dexp(expn),y(n))
               endif
            endif
         enddo
      endif
!
!  normalize the eigenfunction and exit
!
      do n=1,mesh
         el(n)=r(n)*y(n)*y(n)
      enddo
      sum=int_0_inf_dr(el,r,r2,dx,mesh,nst)
      sum=dsqrt(sum)
      do n=1,mesh
         y(n)=sqr(n)*y(n)/sum
      enddo

      deallocate(el)
      deallocate(f )
      deallocate(c )
      return

      end
