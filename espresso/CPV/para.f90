!
! Copyright (C) 2002 CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "../include/machine.h"

module para_mod

  USE fft_types, ONLY: fft_dlay_descriptor, fft_dlay_allocate, fft_dlay_deallocate, &
                       fft_dlay_set

  integer maxproc, ncplanex
  parameter (maxproc=64, ncplanex=37000)
  
  character(len=3) :: node
! node:    node number, useful for opening files
  integer nproc, me, mygroup
! nproc:   number of processors
! me:      number of this processor
!
! parallel fft information for the dense grid
!
! npp:     number of plane per processor                      
! n3:      n3(me)+1 = first  plane on proc. me            
! ncp:     number of (density) columns per proc  
! ncp0:    starting column for each processor
! ncplane: number of columns in a plane                   
! nct:     total number of non-zero columns               
! nnr_:    local fft data size                            
! ipc:     index saying which proc owns columns in a plane
! icpl:    index relating columns and pos. in the plane   
!
! n3 -> dfftp%ipp
! ncplane -> dfftp%nnp
! ncp  -> dfftp%nsp
! ncp0 -> dfftp%iss
! npp  -> dfftp%npp
! ipc  -> dfftp%isind
! icpl -> dfftp%ismap
! nnr_ -> dfftp%nnr
!
!  integer  npp(maxproc), n3(maxproc), ncp(maxproc), ncp0(maxproc), &
!           ncplane, nct, nnr_, ipc(ncplanex), icpl(ncplanex)
!
! parallel fft information for the smooth mesh
!
! npps:    number of plane per processor
! ncps:    number of (density) columns per proc 
! ncpw:    number of (wfs) columns per processor
! ncps0:   starting column for each processor
! ncplanes:number of columns in a plane (smooth)
! ncts:    total number of non-zero columns
! nnrs_:   local fft data size
! ipcs:    saying which proc owns columns in a plane
! icpls:   index relating columns and pos. in the plane 
!
! ncpw -> dffts%ncpw
! n3s -> dffts%ipp
! ncplanes -> dffts%nnp
! ncps  -> dffts%nsp
! ncps0 -> dffts%iss
! npps  -> dffts%npp
! ipcs  -> dffts%isind
! icpls -> dffts%ismap
! nnrs_ -> dffts%nnr
!
!  integer npps(maxproc), ncps(maxproc), ncpw(maxproc), ncp0s(maxproc), &
!       ncplanes, ncts,  nnrs_, ipcs(ncplanex), icpls(ncplanex)

  TYPE ( fft_dlay_descriptor ) :: dfftp  ! fft descriptor for potentials
  TYPE ( fft_dlay_descriptor ) :: dffts  ! fft descriptor for smooth mesh

!  PRIVATE :: ipcs, icpls, ipc, icpl, ncp0s, ncp0, npp, npps, ncp, ncps, &
!    ncplane, ncplanes, n3, ncpw, nnr_, nnrs_, nct, ncts


end module para_mod
!
!-----------------------------------------------------------------------
      subroutine startup
!-----------------------------------------------------------------------
!
!  This subroutine initializes the Message Passing environment. 
!  The number of processors "nproc" returned by this routine is 
!  determined by the way the process was started. 
!  This is configuration- and machine-dependent. For inter-
!  active execution it is determined by environment variable MP_PROCS
!
      use para_mod
      use mp, only: mp_start, mp_env
      use global_version
!
      implicit none

      integer ierr
!
      call mp_start()
      call mp_env( nproc, me, mygroup )
      me = me + 1
!
!
! parent process (source) will have me=1 - child process me=2,...,NPROC
! (for historical reasons: MPI uses 0,...,NPROC-1 instead )
!
      if ( nproc > maxproc) &
     &   call errore('startup',' too many processors ',nproc)
!
      if (me < 10) then
         write(node,'(i1,2x)') me
      else if (me < 100) then
         write(node,'(i2,1x)') me
      else if (me < 1000) then
         write(node,'(i3)') me
      else
         call errore('startup','wow, >1000 nodes !!',nproc)
      end if
!
! only the first processor writes
!
      if ( me == 1 ) then
         write(6,'(72("*"))')
         write(6,'(4("*"),64x,4("*"))')
         write(6,'(4("*"),"  CPV: variable-cell Car-Parrinello ", &
              &  "molecular dynamics          ",4("*"))') 
         write(6,'(4("*"),"  using ultrasoft Vanderbilt ", &
              &  "pseudopotentials - v.",a6,8x,4("*"))') version_number
         write(6,'(4("*"),64x,4("*"))')
         write(6,'(72("*"))')
         write(6,'(/5x,''Parallel version (MPI)'')')
         write(6,'(5x,''Number of processors in use:   '',i4)') nproc
      else
         open(6,file='/dev/null',status='unknown')
!
! useful for debugging purposes 
!         open(6,file='out.'//node,status='unknown')
      end if
!
      return
      end

#if defined __PARA

!
!----------------------------------------------------------------------
      subroutine read_rho(unit,nspin,rhor)
!----------------------------------------------------------------------
!
! read from file rhor(nnr,nspin) on first node and distribute to other nodes
!
      use para_mod
      use grid_dimensions, only: nr1x, nr2x, nr3x, nnr => nnrx
      implicit none
      include 'mpif.h'
      integer unit, nspin
      real(kind=8) rhor(nnr,nspin)
!
      integer ir, is
      integer root, proc, ierr, n, displs(nproc), sendcount(nproc)
      real(kind=8), allocatable:: rhodist(:)
!
!
      if (me.eq.1) allocate(rhodist(nr1x*nr2x*nr3x))
      root = 0
      do proc=1,nproc
         sendcount(proc) =  dfftp%nnp * ( dfftp%npp(proc) )
         if (proc.eq.1) then
            displs(proc)=0
         else
            displs(proc)=displs(proc-1) + sendcount(proc-1)
         end if
      end do
      do is=1,nspin
!
! read the charge density from unit "unit" on first node only
!
         if (me.eq.1) read(unit) (rhodist(ir),ir=1,nr1x*nr2x*nr3x)
!
! distribute the charge density to the other nodes
!
         call mpi_barrier ( MPI_COMM_WORLD, ierr)
         call mpi_scatterv(rhodist, sendcount, displs, MPI_REAL8,       &
     &                     rhor(1,is),sendcount(me),   MPI_REAL8,       &
     &                     root, MPI_COMM_WORLD, ierr)
         if (ierr.ne.0) call errore('mpi_scatterv','ierr<>0',ierr)
!
! just in case: set to zero unread elements (if any)
!
         do ir=sendcount(me)+1,nnr
            rhor(ir,is)=0.d0
         end do
      end do
      if (me.eq.1) deallocate(rhodist)
!
      return
      end subroutine read_rho
!
!----------------------------------------------------------------------
      subroutine write_rho(unit,nspin,rhor)
!----------------------------------------------------------------------
!
! collect rhor(nnr,nspin) on first node and write to file
!
      use para_mod
      use grid_dimensions, only: nr1x, nr2x, nr3x, nnr => nnrx
      implicit none
      include 'mpif.h'
      integer unit, nspin
      real(kind=8) rhor(nnr,nspin)
!
      integer ir, is
      integer root, proc, ierr, displs(nproc), recvcount(nproc)
      real(kind=8), allocatable:: rhodist(:)
!
!
      if (me.eq.1) allocate(rhodist(nr1x*nr2x*nr3x))
!
      root = 0
      do proc=1,nproc
         recvcount(proc) =  dfftp%nnp  * ( dfftp%npp(proc) )
         if (proc.eq.1) then
            displs(proc)=0
         else
            displs(proc)=displs(proc-1) + recvcount(proc-1)
         end if
      end do
!
      do is=1,nspin
!
! gather the charge density on the first node
!
         call mpi_barrier ( MPI_COMM_WORLD, ierr)
         call mpi_gatherv (rhor(1,is), recvcount(me), MPI_REAL8,        &
     &                     rhodist,recvcount, displs, MPI_REAL8,        &
     &                     root, MPI_COMM_WORLD, ierr)
         if (ierr.ne.0) call errore('mpi_gatherv','ierr<>0',ierr)
!
! write the charge density to unit "unit" from first node only
!
         if (me.eq.1) write(unit) (rhodist(ir),ir=1,nr1x*nr2x*nr3x)
      end do
      if (me.eq.1) deallocate(rhodist)
!
      return
      end subroutine write_rho
!
!
!-----------------------------------------------------------------------
      subroutine set_fft_para( b1, b2, b3, gcut, gcuts, gcutw,          &
     &                        nr1, nr2, nr3, nr1s, nr2s, nr3s, nnr,     &
     &                        nr1x,nr2x,nr3x,nr1sx,nr2sx,nr3sx,nnrs )
!-----------------------------------------------------------------------
!
! distribute columns to processes for parallel fft
! based on code written by Stefano de Gironcoli for PWSCF
! columns are sets of g-vectors along z: g(k) = i1*b1+i2*b2+i3*b3 , 
! with g^2<gcut and (i1,i2) running over the (xy) plane.
! Columns are "active" for a given (i1,i2) if they contain a nonzero
! number of wavevectors
!
      use para_mod
      use stick_base
      use fft_scalar, only: good_fft_dimension
!
      implicit none
      real(kind=8) b1(3), b2(3), b3(3), gcut, gcuts, gcutw
      integer nr1, nr2, nr3, nr1s, nr2s, nr3s, nnr,                     &
     &        nr1x,nr2x,nr3x,nr1sx,nr2sx,nr3sx,nnrs
!
      integer ngc(ncplanex),&! number of g-vectors per column (dense grid)
     &        ngcs(ncplanex),&! number of g-vectors per column (smooth grid
     &        ngcw(ncplanex),&! number of wavefct plane waves per colum
     &        in1(ncplanex),&! index i for column (i1,i2)
     &        in2(ncplanex),&! index j for column (i1,i2)
     &        ic,           &! fft index for this column (dense grid)
     &        ics,          &! as above for the smooth grid
     &        icm,          &! fft index for column (-i1,-i2) (dense grid)
     &        icms,         &! as above for the smooth grid
     &        index(ncplanex),&! used to order column
     &        ncp_(maxproc),&! number of column per processor (work space)
     &        ngp(maxproc), &! number of g-vectors per proc (dense grid)
     &        ngps(maxproc),&! number of g-vectors per proc (smooth grid)
     &        ngpw(maxproc)  ! number of wavefct plane waves per proc
!
      integer np, nps1,            &! counters on planes 
     &        nq, nqs,             &! counters on planes
     &        max1,min1,max2,min2, &! aux. variables
     &        m1, m2, n1, n2, i, mc,&! generic counter
     &        idum, nct_,          &! check variables 
     &        j,jj,                &! counters on processors
     &        n1m1,n2m1,n3m1,      &! nr1-1 and so on
     &        i1, i2, i3            ! counters on G space
      real(kind=8)                                                      &
     &        aux(ncplanex), &! used to order columns
     &        amod            ! modulus of G vectors
!
      integer  ncp0(maxproc), ipc(ncplanex), icpl(ncplanex)
      integer  ncp0s(maxproc), ipcs(ncplanex), icpls(ncplanex)
      integer  npp(maxproc), npps(maxproc)
      integer  ncp(maxproc), ncps(maxproc)
      integer  n3(maxproc)
      integer  ncplane, ncplanes
      integer  ncpw(maxproc)
      integer  nnr_, nnrs_, nct, ncts
!
      integer, allocatable :: st(:,:), stw(:,:), sts(:,:) ! sticks maps
      integer :: ub(3), lb(3)  ! upper and lower bounds for maps
      integer :: nctw
      logical :: tk = .FALSE.
!
      call tictac(27,0)
!
! set the dimensions of fft arrays
!
      nr1x =good_fft_dimension(nr1 )
      nr2x = nr2
      nr3x =good_fft_dimension(nr3 )
!
      nr1sx=good_fft_dimension(nr1s)
      nr2sx=nr2s
      nr3sx=good_fft_dimension(nr3s)
!
!     compute number of columns for each processor
!
      ncplane = nr1x*nr2x
      ncplanes= nr1sx*nr2sx
      if (ncplane.gt.ncplanex .or. ncplanes.gt.ncplanex)                &
     &     call errore('set_fft_para','ncplanex too small',ncplane)
!
! set the number of plane per process
!
      if (nr3.lt.nproc) call errore('set_fft_para',                      &
     &                'some processors have no planes ',-1)      
      if (nr3s.lt.nproc) call errore('set_fft_para',                     &
     &                'some processors have no smooth planes ',-1)      
!
      if (nproc.eq.1) then
         npp(1) = nr3
         npps(1)= nr3s
      else
         np = nr3/nproc
         nq = nr3 - np*nproc
         nps1 = nr3s/nproc
         nqs = nr3s - nps1*nproc
         do i = 1, nproc
            npp(i) = np
            if (i.le.nq) npp(i) = np + 1
            npps(i) = nps1
            if (i.le.nqs) npps(i) = nps1 + 1
         end do
      end if
      n3(1)= 0
      do i = 2, nproc
         n3(i)=n3(i-1)+npp(i-1)
      end do
!
!     Now compute for each point of the big plane how many column have
!     non zero vectors on the smooth and dense grid
!
      ipc  = 0
      ipcs = 0
!
      nct = 0
      ncts= 0
!
! NOTA BENE: the exact limits for a correctly sized FFT grid are:
! -nr/2,..,+nr/2  for nr even; -(nr-1)/2,..,+(nr-1)/2  for nr odd.
! If the following limits are increased, a slightly undersized fft 
! grid, with some degree of G-vector refolding, can be used
! (at your own risk - a check is done in ggen).
!
      n1m1=nr1/2
      n2m1=nr2/2
      n3m1=nr3/2

      lb(1) = -n1m1
      lb(2) = -n2m1
      lb(3) = -n3m1
      ub(1) =  n1m1
      ub(2) =  n2m1
      ub(3) =  n3m1
!
      ALLOCATE( stw ( lb(1):ub(1), lb(2):ub(2) ) )
      ALLOCATE( st  ( lb(1):ub(1), lb(2):ub(2) ) )
      ALLOCATE( sts ( lb(1):ub(1), lb(2):ub(2) ) )

!
! ...     Fill in the stick maps, for given g-space base (b1,b2,b3)
! ...     and cut-offs
! ...     The value of the element (i,j) of the map ( st ) is equal to the
! ...     number of G-vector belonging to the (i,j) stick.
!

      CALL sticks_maps( tk, ub, lb, b1, b2, b3, gcut, gcutw, gcuts, st, stw, sts )

      nct  = COUNT( st  > 0 )
      nctw = COUNT( stw > 0 )
      ncts = COUNT( sts > 0 )

      if ( nct > ncplane )    &
     &    call errore('set_fft_para','too many sticks',1)

      if ( ncts > ncplanes )  &
     &    call errore('set_fft_para','too many sticks',2)

      if ( nct == 0 ) & 
     &    call errore('set_fft_para','number of sticks 0', 1)

      if ( ncts == 0 ) &
     &    call errore('set_fft_para','number smooth sticks 0', 1)

!
! ...     initialize the sticks indexes array ist
! ...     nct counts columns containing G-vectors for the dense grid
! ...     ncts counts columns contaning G-vectors for the smooth grid
!

      CALL sticks_countg( tk, ub, lb, st, stw, sts, in1, in2, ngc, ngcw, ngcs )

!
!   Sort the columns. First the column with the largest number of G
!   vectors on the wavefunction sphere (active columns), 
!   then on the smooth sphere, then on the big sphere. Dirty trick:
!

      CALL sticks_sort( ngc, ngcw, ngcs, nct, index )

!
!   assign columns to processes
!

      CALL sticks_dist( tk, ub, lb, index, in1, in2, ngc, ngcw, ngcs, nct, &
                ncp, ncpw, ncps, ngp, ngpw, ngps, st, stw, sts )

      CALL sticks_pairup( tk, ub, lb, index, in1, in2, ngc, ngcw, ngcs, nct, &
                ncp, ncpw, ncps, ngp, ngpw, ngps, st, stw, sts )

      ! WRITE(*,*) ' DEBUG : ', COUNT( st > 0 ), COUNT( sts > 0 ), COUNT( stw > 0 )


      CALL fft_dlay_allocate( dfftp, nproc, nr1x, nr2x )
      CALL fft_dlay_allocate( dffts, nproc, nr1sx, nr2sx )


      CALL fft_dlay_set( dfftp, tk, nct, nr1, nr2, nr3, nr1x, nr2x, nr3x, me, &
                nproc, ub, lb, index, in1, in2, ncp, ncpw, ngp, ngpw, st, stw)
      CALL fft_dlay_set( dffts, tk, ncts, nr1s, nr2s, nr3s, nr1sx, nr2sx, nr3sx, me, &
                nproc, ub, lb, index, in1, in2, ncps, ncpw, ngps, ngpw, sts, stw)


      DO mc = 1, nct

         i = index(mc)

         i1 = in1(i)
         i2 = in2(i)

         if ( i1.lt.0.or.(i1.eq.0.and.i2.lt.0) ) go to 29
!
! only half of the columns, plus column (0,0), are scanned:
! column (-i1,-i2) must be assigned to the same proc as column (i1,i2)
!
! ic  :  position, in fft notation, in dense grid, of column ( i1, i2)
! icm :      "         "      "          "    "         "    (-i1,-i2)
! ics :      "         "      "        smooth "         "    ( i1, i2)
! icms:      "         "      "        smooth "         "    (-i1,-i2)
!
         m1 = i1 + 1
         if (m1.lt.1) m1 = m1 + nr1
         m2 = i2 + 1
         if (m2.lt.1) m2 = m2 + nr2
         ic = m1 + (m2-1)*nr1x
!
         n1 = -i1 + 1
         if (n1.lt.1) n1 = n1 + nr1
         n2 = -i2 + 1
         if (n2.lt.1) n2 = n2 + nr2
         icm = n1 + (n2-1)*nr1x
!
         m1 = i1 + 1
         if (m1.lt.1) m1 = m1 + nr1s
         m2 = i2 + 1
         if (m2.lt.1) m2 = m2 + nr2s
         ics = m1 + (m2-1)*nr1sx
!
         n1 =-i1 + 1
         if (n1.lt.1) n1 = n1 + nr1s
         n2 =-i2 + 1
         if (n2.lt.1) n2 = n2 + nr2s
         icms = n1 + (n2-1)*nr1sx

         IF( st( i1, i2 ) > 0 .AND. stw( i1, i2 ) > 0 ) THEN
           ipc( ic  ) = st(  i1,  i2 )
           ipc( icm ) = st( -i1, -i2 )
         ELSE IF( st( i1, i2 ) > 0 ) THEN
           ipc( ic  ) = -st(  i1,  i2 )
           ipc( icm ) = -st( -i1, -i2 )
         END IF

         IF( sts( i1, i2 ) > 0 .AND. stw( i1, i2 ) > 0 ) THEN
           ipcs( ics  ) = sts(  i1,  i2 )
           ipcs( icms ) = sts( -i1, -i2 )
         ELSE IF( sts( i1, i2 ) > 0 ) THEN
           ipcs( ics  ) = -sts(  i1,  i2 )
           ipcs( icms ) = -sts( -i1, -i2 )
         END IF

29       CONTINUE

      END DO
      
      DEALLOCATE( st, stw, sts )

      IF( .NOT. tk ) THEN
        nct  = nct*2  - 1
        ncts = ncts*2 - 1
      END IF

!
! ipc  is the processor for this column in the dense grid
! ipcs is the same, for the smooth grid
!
      write(6,"(                                                      &
       & ' Proc  planes cols    G   planes cols    G    columns  G',/,  &
       & '       (dense grid)     (smooth grid)   (wavefct grid)' )" )
      do i=1,nproc
         write(6,'(i3,2x,3(i5,2i7))') i, npp(i),ncp(i),ngp(i),          &
     &        npps(i),ncps(i),ngps(i), ncpw(i), ngpw(i)
      end do
      write(6,'(i3,2x,3(i5,2i7))') 0, SUM(npp(1:nproc)), SUM(ncp(1:nproc)), &
        SUM(ngp(1:nproc)), SUM(npps(1:nproc)), SUM(ncps(1:nproc)), &
        SUM(ngps(1:nproc)), SUM(ncpw(1:nproc)), SUM(ngpw(1:nproc))
!
! nnr_ and nnrs_ are copies of nnr and nnrs, the local fft data size,
! to be stored in "parallel" commons. Not a very elegant solution.
!
      if ( nproc == 1 ) then
         nnr =nr1x*nr2x*nr3x
         nnrs=nr1sx*nr2sx*nr3sx
      else
         nnr = max(nr3x*ncp(me), nr1x*nr2x*npp(me))
         nnrs= max(nr3sx*ncps(me), nr1sx*nr2sx*npps(me))
      end if
      nnr_= nnr
      nnrs_= nnrs
!
!   computing the starting column for each processor
!
      do i=1,nproc
         if(ngpw(i).eq.0)                                               &
     &        call errore('set_fft_para',                                &
     &        'some processors have no pencils, not yet implemented',1)
         if (i.eq.1) then 
            ncp0(i) = 0
            ncp0s(i)= 0
         else
            ncp0(i) = ncp0 (i-1) + ncp (i-1)
            ncp0s(i)= ncp0s(i-1) + ncps(i-1)
         endif
      enddo
!
!  Now compute the arrays ipc and icpl (dense grid):
!     ipc contain the number of the column for that processor.
!         zero if the column do not belong to the processor.
!         Note that input ipc is used and overwritten.
!     icpl contains the point in the plane for each column
!
!- active columns first........
!
      do j=1,nproc
         ncp_(j) = 0
      end do
      do mc =1,ncplane
         if (ipc(mc).gt.0) then
            j = ipc(mc)
            ncp_(j) = ncp_(j) + 1
            icpl(ncp_(j) + ncp0(j)) = mc 
            if (j.eq.me) then
               ipc(mc) = ncp_(j)
            else
               ipc(mc) = 0
            end if 
         end if
      end do
!
!-..... ( intermediate check ) ....
!
      do j=1,nproc
         if (ncp_(j).ne.ncpw(j))                                        &
     &        call errore('set_fft_para','ncp_(j).ne.ncpw(j)',j)
      end do
!
!- ........then the remaining columns
!
      do mc =1,ncplane
         if (ipc(mc).lt.0) then
            j = -ipc(mc)
            ncp_(j) = ncp_(j) + 1
            icpl(ncp_(j) + ncp0(j)) = mc 
            if (j.eq.me) then
               ipc(mc) = ncp_(j)
            else
               ipc(mc) = 0
            end if 
         end if
      end do
!
!-... ( final check )
!
      nct_ = 0
      do j=1,nproc
         if (ncp_(j).ne.ncp(j))                                         &
     &        call errore('set_fft_para','ncp_(j).ne.ncp(j)',j)
         nct_ = nct_ + ncp_(j)
      end do
      if (nct_.ne.nct)                                                  &
     &     call errore('set_fft_para','nct_.ne.nct',1)
!
!   now compute the arrays ipcs and icpls 
!   (as ipc and icpls, for the smooth grid)
!
!   active columns first...
!
      do j=1,nproc
         ncp_(j) = 0
      end do
      do mc =1,ncplanes
         if (ipcs(mc).gt.0) then
            j = ipcs(mc)
            ncp_(j)=ncp_(j) + 1
            icpls(ncp_(j) + ncp0s(j)) = mc
            if (j.eq.me) then
               ipcs(mc) = ncp_(j)
            else
               ipcs(mc) = 0
            endif
         endif
      enddo
!
!-..... ( intermediate check ) ....
!
      do j=1,nproc
         if (ncp_(j).ne.ncpw(j))                                        &
     &        call errore('set_fft_para','ncp_(j).ne.ncpw(j)',j)
      end do
!
!    and then all the others
!
      do mc =1,ncplanes
         if (ipcs(mc).lt.0) then
            j = -ipcs(mc)
            ncp_(j) = ncp_(j) + 1
            icpls(ncp_(j) + ncp0s(j)) = mc
            if (j.eq.me) then
               ipcs(mc) = ncp_(j)
            else
               ipcs(mc) = 0
            end if
         end if
      end do
!
!-... ( final check )
!
      nct_ = 0
      do j=1,nproc
         if (ncp_(j).ne.ncps(j))                                        &
     &        call errore('set_fft_para','ncp_(j).ne.ncps(j)',j)
         nct_ = nct_ + ncp_(j)
      end do
      if (nct_.ne.ncts)                                                 &
     &     call errore('set_fft_para','nct_.ne.ncts',1)
      call tictac(27,1)

!      do i = 1, nproc
!        write(6,fmt="('DEBUG fft_setup ',3I5 )" ) i, npp(i), dfftp%npp(i)
!        write(6,fmt="('DEBUG fft_setup ',3I5 )" ) i, npps(i), dffts%npp(i)
!      end do
!      write(6,fmt="('DEBUG fft_setup ',3I9 )" ) nnr_, dfftp%nnr
!      write(6,fmt="('DEBUG fft_setup ',3I9 )" ) nnrs_, dffts%nnr
!      write(6,fmt="('DEBUG fft_setup ',3I9 )" ) nct, dfftp%nst
!      write(6,fmt="('DEBUG fft_setup ',3I9 )" ) ncts, dffts%nst
!
      return
      end
!
!
!----------------------------------------------------------------------
      subroutine cfftpb(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3,sign)
!----------------------------------------------------------------------
!
!   not-so-parallel 3d fft for box grid, implemented only for sign=1
!   G-space to R-space, output = \sum_G f(G)exp(+iG*R)
!   The array f (overwritten on output) is NOT distributed:
!   a copy is present on each processor.
!   The fft along z  is done on the entire grid.
!   The fft along xy is done only on planes that have components on the
!   dense grid for each processor. Note that the final array will no
!   longer be the same on all processors.
!
      use para_mod
      use grid_dimensions, only: nr3
      use fft_scalar, only: cft_b
!
      implicit none
      integer nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3,sign
      complex(kind=8) f(nr1bx*nr2bx*nr3bx)
!
      integer ir3, ibig3, imin3, imax3, np3
!
      call parabox(nr3b,irb3,nr3,imin3,imax3)
      np3=imax3-imin3+1
! np3 is the number of planes to be transformed
      if (np3.le.0) return
      call cft_b(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,imin3,imax3,sign)
!
      return
      end
!
!----------------------------------------------------------------------
      subroutine parabox(nr3b,irb3,nr3,imin3,imax3)
!----------------------------------------------------------------------
!
! find if box grid planes in the z direction have component on the dense
! grid on this processor, and if, which range imin3-imax3
!
      use para_mod
! input
      integer nr3b,irb3,nr3
! output
      integer imin3,imax3
! local
      integer ir3, ibig3
!
      imin3=nr3b
      imax3=1
      do ir3=1,nr3b
         ibig3=1+mod(irb3+ir3-2,nr3)
         if(ibig3.lt.1.or.ibig3.gt.nr3)                                 &
     &        call errore('cfftpb','ibig3 wrong',ibig3)
         ibig3=ibig3-dfftp%ipp(me)
         if (ibig3.gt.0.and.ibig3.le.dfftp%npp(me)) then
            imin3=min(imin3,ir3)
            imax3=max(imax3,ir3)
         end if
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine reduce(size,ps)
!-----------------------------------------------------------------------
!
!     sums a distributed variable s(size) over the processors.
!     This version uses a fixed-length buffer of appropriate (?) size
!
      use para_mod
!
      implicit none
      integer size
      real(kind=8)  ps(size)
!
      include 'mpif.h'
      integer ierr, n, nbuf
      integer, parameter:: MAXB=10000
      real(kind=8) buff(MAXB)
!
      if (nproc.le.1) return
      if (size.le.0) return
      call tictac(29,0)
!
!  syncronize processes
!
      call mpi_barrier(MPI_COMM_WORLD,ierr)
      if (ierr.ne.0) call errore('reduce','error in barrier',ierr)
!
      nbuf=size/MAXB
!
      do n=1,nbuf
         call mpi_allreduce (ps(1+(n-1)*MAXB), buff, MAXB,              &
     &        MPI_REAL8, MPI_SUM, MPI_COMM_WORLD, ierr)
         if (ierr.ne.0)                                                 &
     &        call errore('reduce','error in allreduce1',ierr)
         call DCOPY(MAXB,buff,1,ps(1+(n-1)*MAXB),1)
      end do
!
!    possible remaining elements < maxb
!
      if (size-nbuf*MAXB.gt.0) then
          call mpi_allreduce (ps(1+nbuf*MAXB), buff, size-nbuf*MAXB,    &
     &          MPI_REAL8, MPI_SUM, MPI_COMM_WORLD, ierr)
          if (ierr.ne.0)                                                &
     &         call errore('reduce','error in allreduce2',ierr)
          call DCOPY(size-nbuf*MAXB,buff,1,ps(1+nbuf*MAXB),1)
      endif
      call tictac(29,1)
!
      return
      end
!
!----------------------------------------------------------------------
      subroutine print_para_times
!----------------------------------------------------------------------
!
      use para_mod
      use timex_mod
!
      implicit none
      include 'mpif.h'
      integer i, ierr
      real(kind=8) mincpu(maxclock), maxcpu(maxclock)
!
!  syncronize processes
!
      call mpi_barrier(MPI_COMM_WORLD,ierr)
      if (ierr.ne.0)                                                    &
     &     call errore('print_all_times','error in barrier',ierr)
!
      call mpi_allreduce (cputime, mincpu, maxclock,                    &
     &     MPI_REAL8, MPI_MIN, MPI_COMM_WORLD, ierr)
      if (ierr.ne.0)                                                    &
     &     call errore('print_para_times','error in minimum',ierr)
      call mpi_allreduce (cputime, maxcpu, maxclock,                    &
     &     MPI_REAL8, MPI_MAX, MPI_COMM_WORLD, ierr)
      if (ierr.ne.0)                                                    &
     &     call errore('print_para_times','error in maximum',ierr)
!
      write(6,*)
      write(6,*) ' routine     calls       cpu time        elapsed'
      write(6,*) '             node0  node0,  min,  max     node0'
      write(6,*)
      do i=1, maxclock
         if (ntimes(i).gt.0) write(6,30) routine(i),                    &
     &        ntimes(i), cputime(i), mincpu(i),maxcpu(i), elapsed(i)
      end do
 30   format(a10,i7,4f8.1)
!
      return
      end
!
!
!----------------------------------------------------------------------
      subroutine nrbounds(ngw,nr1s,nr2s,nr3s,in1p,in2p,in3p,nmin,nmax)
!----------------------------------------------------------------------
!
! find the bounds for (i,j,k) indexes of all wavefunction G-vectors
! The (i,j,k) indexes are defined as: G=i*g(1)+j*g(2)+k*g(3)
! where g(1), g(2), g(3) are basis vectors of the reciprocal lattice
!
      implicit none
! input
      integer ngw,nr1s,nr2s,nr3s,in1p(ngw),in2p(ngw),in3p(ngw)
! output
      integer nmin(3), nmax(3)
! local
      include 'mpif.h'
      integer nmin0(3), nmax0(3), ig, ierr
!
!
      nmin0(1)=  nr1s
      nmax0(1)= -nr1s
      nmin0(2)=  nr2s
      nmax0(2)= -nr2s
      nmin0(3)=  nr3s
      nmax0(3)= -nr3s
!
      do ig=1,ngw
         nmin0(1) = min(nmin0(1),in1p(ig))
         nmin0(2) = min(nmin0(2),in2p(ig))
         nmin0(3) = min(nmin0(3),in3p(ig))
         nmax0(1) = max(nmax0(1),in1p(ig))
         nmax0(2) = max(nmax0(2),in2p(ig))
         nmax0(3) = max(nmax0(3),in3p(ig))
      end do
!
! find minima and maxima for the FFT box across all nodes
!
      call mpi_barrier( MPI_COMM_WORLD, ierr )
      if (ierr.ne.0) call errore('nrbounds','mpi_barrier 1',ierr)
      call mpi_allreduce (nmin0, nmin, 3, MPI_INTEGER, MPI_MIN,         &
     &           MPI_COMM_WORLD, ierr)
      if (ierr.ne.0) call errore('nrbounds','mpi_allreduce min',ierr)
      call mpi_allreduce (nmax0, nmax, 3, MPI_INTEGER, MPI_MAX,         &
     &           MPI_COMM_WORLD, ierr)
      if (ierr.ne.0) call errore('nrbounds','mpi_allreduce max',ierr)

      return
      end subroutine nrbounds

#endif
