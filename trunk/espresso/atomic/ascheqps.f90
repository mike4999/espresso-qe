!
!---------------------------------------------------------------
      subroutine ascheqps(nn,lam,jam,e,mesh,ndm,dx,r,r2,sqr,vpot, &
                  thresh,y,beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk)
!---------------------------------------------------------------
!
!  numerical integration of the radial schroedinger equation for
!  bound states in a local potential.
!  thresh dermines the absolute accuracy for the eigenvalue
!
!  This routine allows a nonlocal potential and a overlap
!  operator. Therefore it can solve a general schroedinger
!  equation as in the US pseudopotential case. The other
!  pseudopotentials are particular cases
!
      implicit none
      
      integer, parameter :: dp=kind(1.d0)

      integer :: &
              nn, &       ! main quantum number for node number
              lam,&       ! l angular momentum
              mesh, &     ! size of radial mesh
              ndm,  &     ! maximum radial mesh 
              nbeta,&     ! number of beta function  
              nwfx, &     ! maximum number of beta functions
              lls(nbeta),&! for each beta the angular momentum
              ikk(nbeta) ! for each beta the point where it become zero

      real(kind=dp) :: &
              e,de,    &     ! output eigenvalue
              dx,      &  ! linear delta x for radial mesh
              jam, &      ! j angular momentum
              r(mesh), &  ! radial mesh
              r2(mesh),&  ! square of radial mesh
              sqr(mesh), &! square root of radial mesh
              vpot(mesh),&! the local potential 
              thresh,  &  ! precision of eigenvalue
              y(mesh), &  ! the output solution
              jjs(nwfx), & ! the j angular momentum
              beta(ndm,nwfx), & ! the beta functions
              ddd(nwfx,nwfx),qq(nwfx,nwfx) ! parameters for computing B_ij
!
!    the local variables
!
      integer, parameter :: maxter=100

      real(kind=dp) :: &
           sqlhf,      &  ! the term for angular momentum in equation
           det,detup,detlw,detold, &! the determinant
           eup0,elw0,  &  ! limits imposed by node counter
           eup,elw,eold  ! actual energy interval
      
      integer ::  &
              n,  &    ! counter on mesh points
              iter, &  ! counter on iteration
              ns,   &  ! counter on beta functions
              ncross,& ! the number of nodes
              count   ! counter on energy intervals 

      logical :: &
              nosol
!
!  set up constants and allocate variables the 
!
      sqlhf=(dble(lam)+0.5d0)**2
!
!     first try to find the zero with newton method
!
      eold=e
      eup0=0.d0
      elw0=0.d0
      nosol=.false.
      do iter=1,maxter

         elw=e
         call compute_det(nn,lam,jam,elw,mesh,ndm,dx,r,r2,sqr,vpot, &
                 beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk, &
                 detlw)
         if (iter.eq.1) detold=detlw
         eup=e*0.99  
         call compute_det(nn,lam,jam,eup,mesh,ndm,dx,r,r2,sqr,vpot, &
                  beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk, &
                  detup)
         de=-detlw*(eup-elw)/(detup-detlw)
!
!    if an asintote has been found use bisection
!
         if (abs(de).gt.1.d3*abs(eold)) goto 800
!
!    check for convergence
!
         if (abs(de/e).lt.thresh) goto 900
         e=e+de
!         write(6,*) 'newton', e, de
      enddo
!
!    if the program arrives here newton method does not work
!    try bisection, first bracket the zero
!
800   e=eold
      if (eup0.eq.0.d0) then
         eup=vpot(mesh)+sqlhf/r2(mesh)
      else
         eup=eup0
      endif
      if (elw0.eq.0.d0) then  
         elw=eup
         do n=1,mesh
            elw=dmin1(elw,vpot(n)+sqlhf/r2(n))
         enddo  
      else
         elw=elw0
      endif
      write(6,*) 'Try bisec', elw,eup       
      if(e.gt.eup) e=0.9d0*eup+0.1d0*elw
      if(e.lt.elw) e=0.9d0*elw+0.1d0*eup

      call compute_det(nn,lam,jam,elw,mesh,ndm,dx,r,r2,sqr,vpot, &
                  beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk,detlw)

      de=(eup-elw)/51.d0
      do n=1,50
         eup=elw+de
         call compute_det(nn,lam,jam,eup,mesh,ndm,dx,r,r2,sqr,vpot, &
                  beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk, &
                  detup)
         if (detup*detlw.lt.0.d0) goto 100
!         write(6,*) 'bracketing;',elw,eup,detup
         elw=eup
         detlw=detup  
      enddo
      count=0
100   continue
      if(e.gt.eup) e=0.9d0*eup+0.1d0*elw
      if(e.lt.elw) e=0.9d0*elw+0.1d0*eup
!
!    and find the detailed value
!      
      do iter=1,maxter

         call compute_det(nn,lam,jam,e,mesh,ndm,dx,r,r2,sqr,vpot, &
                  beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk,det)

!         write(6,'(i11,3f20.10)') iter,detlw,det,detup
!         write(6,'(''energy'',i5,3f20.10)') iter,elw,e,eup
!
!     convergence check
!
         if (abs((eup-elw)/elw).lt.thresh) goto 900
!
!     treatement of asintotes
!
         if (abs(det).gt.1d4) then 
             if (e.gt.eold) then
                count=count+1
                elw=eold
                detlw=detold
                eup=e-0.001d0
                call compute_det(nn,lam,jam,eup,mesh,ndm,dx, &
                                 r,r2,sqr,vpot,beta,ddd,qq,&
                                 nbeta,nwfx,lls,jjs,ikk,detup)

                if (count.gt.30) &
                   call errore('ascheqps','too many try ',1)
                goto 100
             else
                count=count+1
                elw=e+0.001d0
                eup=eold
                detup=detold
                call compute_det(nn,lam,jam,elw,mesh,ndm,dx,  &
                                 r,r2,sqr,vpot,beta,ddd,qq, &
                                 nbeta,nwfx,lls,jjs,ikk,detlw)
                if (count.gt.6) &
                   call errore('ascheqps','too many try ',1)
                goto 100
             endif
         endif
!
!     bisection method
!             
         if (det*detup.gt.0.d0) then
            detup=det
            eup=e
            e=(eup+elw)*0.5d0
         else
            detlw=det
            elw=e
            e=(eup+elw)*0.5d0
         endif
      enddo
      write(6,'('' solution not found in ascheqps'')')
      nosol=.true.
 900  continue
!
!   The eigenvalue has been found, compute the solution
!
      if (e.gt.0.d0) then
         e=0.d0
         y=0.d0
         write(6,'('' solution not found in ascheqps'')')
         nosol=.true.
      else
         call compute_solution(nn,lam,jam,e,mesh,ndm,dx,r, &
                  r2,sqr,vpot,y,beta,ddd,qq,nbeta,nwfx,lls,jjs,ikk)
      endif
!
!    count the node number and compare with the required n
!
      if (nosol) return
      ncross=0
      do n=1,mesh-1
         if ( y(n).ne.sign(y(n),y(n+1)) ) then
             if (abs(y(n+1)).gt.1.d-10) ncross=ncross+1
         endif
      enddo
!      write(6,*) ncross, nn-lam-1
      if (ncross.gt.nn-lam-1) then
         eup0=e-1.d-6
      elseif (ncross.lt.nn-lam-1) then
         elw0=e+1.d-6
      else
         return
      endif
!
!    if the program arrives here the number of nodes is wrong, try bisection 
!    with the new limits
!
      goto 800
      return
      end
