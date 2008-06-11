c* ///////////////////////////////////////////////////////////////////////////
c* @file    mgfasd.f
c* @author  Michael Holst
c* @brief   Core nonlinear (full approximation scheme) multigrid routines.
c* @version $Id: mgfasd.f,v 1.1 2008-06-11 10:47:38 degironc Exp $
c* @attention
c* @verbatim
c*
c* PMG -- Parallel algebraic MultiGrid
c* Copyright (c) 1994-2006.  Michael Holst.
c*
c* Michael Holst <mholst@math.ucsd.edu>
c* University of California, San Diego
c* Department of Mathematics, 5739 AP&M
c* 9500 Gilman Drive, Dept. 0112
c* La Jolla, CA 92093-0112 USA                                                  
c* http://math.ucsd.edu/~mholst
c*
c* This file is part of PMG.
c*
c* PMG is free software; you can redistribute it and/or modify
c* it under the terms of the GNU General Public License as published by
c* the Free Software Foundation; either version 2 of the License, or
c* (at your option) any later version.
c*
c* PMG is distributed in the hope that it will be useful,
c* but WITHOUT ANY WARRANTY; without even the implied warranty of
c* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
c* GNU General Public License for more details.
c*
c* You should have received a copy of the GNU General Public License
c* along with PMG; if not, write to the Free Software
c* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
c*
c* Linking PMG statically or dynamically with other modules is making a
c* combined work based on PMG. Thus, the terms and conditions of the GNU
c* General Public License cover the whole combination.
c* 
c* SPECIAL GPL EXCEPTION
c* In addition, as a special exception, the copyright holders of PMG
c* give you permission to combine the PMG program with free software
c* programs and libraries that are released under the GNU LGPL or with
c* code included in releases of ISIM, PMV, PyMOL, SMOL, VMD, and Vision.
c* Such combined software may be linked with PMG and redistributed together 
c* in original or modified form as mere aggregation without requirement that 
c* the entire work be under the scope of the GNU General Public License.
c* This special exception permission is also extended to any software listed
c* in the SPECIAL GPL EXCEPTION clauses by the FEtk and APBS libraries.
c* 
c* Note that people who make modified versions of PMG are not obligated
c* to grant this special exception for their modified versions; it is
c* their choice whether to do so. The GNU General Public License gives
c* permission to release a modified version without this exception; this
c* exception also makes it possible to release a modified version which
c* carries forward this exception.
c*
c* @endverbatim
c* ///////////////////////////////////////////////////////////////////////////

!      subroutine fmvfas(nx,ny,nz,x,iz,w0,w1,w2,w3,w4,
!     2   istop,itmax,iters,ierror,nlev,ilev,nlev_real,mgsolv,
!     3   iok,iinfo,epsiln,errtol,omega,nu1,nu2,mgsmoo,
!     4   ipc,rpc,pc,ac,cc,fc,tru)
c* *********************************************************************
c* purpose:
c*
c*    nested iteration for a nonlinear multilevel method.
c*
c*    algorithm:  nonlinear multigrid iteration (fas)
c*
c*    this routine is the full multigrid front-end for a multigrid 
c*    v-cycle solver.  in other words, at repeatedly calls the v-cycle
c*    multigrid solver on successively finer and finer grids.
c*
c* author:  michael holst
c* *********************************************************************
!      implicit         none
c*
c*    *** other declarations ***
!      integer          ipc(*),iz(50,*),iok,ilev,iinfo,nlev,itmax
!      integer          iters,ierror,level,itmxd,nlevd,iterd,iokd,istop
!      integer          nx,ny,nz,nxf,nyf,nzf,nxc,nyc,nzc,nlev_real,istpd
!      integer          nu1,nu2,mgsmoo,iinfod,mgsolv
!      double precision epsiln,errd,errtol,omega
!      double precision x(*),w0(*),w1(*),w2(*),w3(*),w4(*)
!      double precision rpc(*),pc(*),ac(*),cc(*),fc(*),tru(*)
c*
c*    *** recover gridsizes ***
!      nxf = nx
!      nyf = ny
!      nzf = nz
!      call mkcors(nlev-1,nxf,nyf,nzf,nxc,nyc,nzc)
c*
c*    *** move up grids: interpolate solution to finer, do v cycle ***
!      if (iinfo.ne.0) then
!         write(6,100)'% FMVFAS: starting: ',nxf,nyf,nzf,nxc,nyc,nzc
! 100     format(a,2(2x,' [',i3,',',i3,',',i3,'] '))
!      endif
!      do 10 level = nlev_real, ilev+1, -1
c*
c*       *** call mv cycle ***
!         errd   = 1.0e-5
!         itmxd  = 1
!         nlevd  = nlev_real - level + 1
!         iterd  = 0
!         iokd   = 2
!         iinfod = iinfo
!         istpd  = istop
!         if (iinfo .ge. 2) iokd = 2
!         call mvfas(nxc,nyc,nzc,x,iz,w0,w1,w2,w3,w4,
!     2      istpd,itmxd,iterd,ierror,nlevd,level,nlev_real,mgsolv,
!     3      iokd,iinfod,epsiln,errtol,omega,nu1,nu2,mgsmoo,
!     4      ipc,rpc,pc,ac,cc,fc,tru)
c*
c*       *** find new grid size ***
!         call mkfine(1,nxc,nyc,nzc,nxf,nyf,nzf)
c*
c*       *** interpolate to next finer grid ***
!         call interp(nxc,nyc,nzc,nxf,nyf,nzf,
!     2      x(iz(1,level)),x(iz(1,level-1)),pc(iz(11,level-1)))
CZZZ     call ninterp(nxc,nyc,nzc,nxf,nyf,nzf,
CZZZ 2      x(iz(1,level)),x(iz(1,level-1)),pc(iz(11,level-1)),
CZZZ 3      ipc(iz(5,level-1)),rpc(iz(6,level-1)),
CZZZ 4      ac(iz(7,level-1)),cc(iz(1,level-1)),fc(iz(1,level-1)))
c*
c*       *** new grid size ***
!         nxc = nxf
!         nyc = nyf
!         nzc = nzf
! 10   continue
c*
c*    *** call mv cycle ***
!      level = ilev 
!      call mvfas(nxf,nyf,nzf,x,iz,w0,w1,w2,w3,w4,
!     2   istop,itmax,iters,ierror,nlev,level,nlev_real,mgsolv,
!     3   iok,iinfo,epsiln,errtol,omega,nu1,nu2,mgsmoo,
!     4   ipc,rpc,pc,ac,cc,fc,tru)
c*
c*    *** return and end ***
!      return
!      end
      subroutine mvfas(nx,ny,nz,x,iz,w0,w1,w2,w3,w4,
     2   istop,itmax,iters,ierror,nlev,ilev,nlev_real,mgsolv,
     3   iok,iinfo,epsiln,errtol,omega,nu1,nu2,mgsmoo,
     4   ipc,rpc,pc,ac,cc,fc,tru)
c* *********************************************************************
c* purpose:
c*
c*    nonlinear multilevel method.
c*
c*    algorithm:  nonlinear multigrid iteration (fas)
c*
c*    multigrid v-cycle solver.
c*
c*    input:  
c*       (1) fine and coarse grid discrete nonlinear operators: L_h, L_H
c*       (2) fine grid source function: f_h
c*       (3) fine grid approximate solution: u_h
c*
c*    output:
c*       (1) fine grid improved solution: u_h
c*
c*    the two-grid algorithm is:
c*       (1) pre-smooth:               u1_h = smooth(L_h,f_h,u_h)
c*       (2) restrict defect:          d_H  = r(L_h(u1_h) - f_h)
c*           restrict solution:        u_H  = r(u1_h)
c*       (3) form coarse grid rhs:     f_H  = L_H(u_H) - d_H
c*           solve for correction:     c_H  = L_H^{-1}(f_H)
c*       (4) prolongate and correct:   u2_h = u1_h - p(c_H - u_H)
c*       (5) post-smooth:              u_h  = smooth(L_h,f_h,u2_h)
c*
c*    (of course, c_H is determined with another two-grid algorithm)
c*
c*    implementation notes:
c*       (0) "u1_h" and "u_H" must be kept on each level until "c_H" is 
c*           computed, and then all three are used to compute "u2_h".
c*       (1) "u_h" (and then "u1_h") on all levels is stored in the "x" array.
c*       (2) "u_H" on all levels is stored in the "e" array.
c*       (3) "c_h" is identically "u_h" for u_h on the next coarser grid.
c*       (4) "d_H" is stored in the "r" array.
c*       (5) "f_h" and "f_H" are stored in the "fc" array.
c*       (6) "L_h" on all levels is stored in the "ac" array.
c*       (7) signs may be reveresed; i.e., residual is used in place
c*           of the defect in places, etc.
c*
c* author:  michael holst
c* *********************************************************************
      implicit         none
c*
c*    *** other declarations ***
      integer          ipc(*),iz(50,*),iok,ilev,iinfo,nlev,level,lev
      integer          itmax,iters,ierror,istop,nu1,nu2,mgsmoo
      integer          itmax_s,iters_s,nuuu,ivariv,mgsmoo_s,iresid
      integer          nx,ny,nz,nxf,nyf,nzf,nxc,nyc,nzc
      integer          mgsolv,nlev_real,iadjoint
      double precision omega,errtol,epsiln,errtol_s
      double precision rsden,rsnrm,orsnrm,xnrm1,xnrm2,xdot,xdamp
      double precision x(*),w0(*),w1(*),w2(*),w3(*),w4(*)
      double precision rpc(*),pc(*),ac(*),cc(*),fc(*),tru(*)
c*
c*    *** recover level information ***
      level = 1
      lev   = (ilev-1)+level
c*
c*    *** recover gridsizes ***
      nxf = nx
      nyf = ny
      nzf = nz
      call mkcors(nlev-1,nxf,nyf,nzf,nxc,nyc,nzc)
c*
c*    *** do some i/o if requested ***
!      if (iinfo.ne.0) then
!         write(6,100)'% MVFAS: starting:  ',nxf,nyf,nzf,nxc,nyc,nzc
! 100     format(a,2(2x,' [',i3,',',i3,',',i3,'] '))
!      endif
c*
c*    *** initial wall clock ***
!#ifdef _MULTIGRID_VERBOSE
!      if (iok.ne.0) then
!         call prtini(istop)
!         call prtstp(iok,-1,0.0d0,0.0d0,0.0d0)
!      endif
!#endif
c*
c*    **************************************************************
c*    *** note: if (iok.ne.0) then:  use a stopping test.        ***
c*    ***       else:  use just the itmax to stop iteration.     ***
c*    **************************************************************
c*    *** istop=0 most efficient (whatever it is)                ***
c*    *** istop=1 relative residual                              ***
c*    *** istop=2 rms difference of successive iterates          ***
c*    *** istop=3 relative true error (provided for testing)     ***
c*    **************************************************************
c*
c*    *** compute denominator for stopping criterion ***
      if (iok.ne.0) then
         if (istop .eq. 0) then
            rsden = 1.0d0
         elseif (istop .eq. 1) then
c*          *** compute initial residual with zero initial guess ***
c*          *** this is analogous to the linear case where one can ***
c*          *** simply take norm of rhs for a zero initial guess ***
            call azeros(nxf,nyf,nzf,w1)
            call nmresid(nxf,nyf,nzf,
     2         ipc(iz(5,lev)),rpc(iz(6,lev)),
     3         ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4         w1,w2,w3)
            rsden = xnrm1(nxf,nyf,nzf,w2)
         elseif (istop .eq. 2) then
            rsden = dsqrt(dble(nxf*nyf*nzf))
         elseif (istop .eq. 3) then
            rsden = xnrm2(nxf,nyf,nzf,tru(iz(1,lev)))
         elseif (istop .eq. 4) then
            rsden = xnrm2(nxf,nyf,nzf,tru(iz(1,lev)))
         elseif (istop .eq. 5) then
            call nmatvec(nxf,nyf,nzf,
     2         ipc(iz(5,lev)),rpc(iz(6,lev)),
     3         ac(iz(7,lev)),cc(iz(1,lev)),
     4         tru(iz(1,lev)),w1,w2)
            rsden = dsqrt(xdot(nxf,nyf,nzf,tru(iz(1,lev)),w1))
         else
!            print*,'% MVFAS: bad istop value... '
         endif
         if (rsden.eq.0.0d0) then
            rsden = 1.0d0
            print*,'% MVFAS:  rhs is zero on finest level '
         endif
         rsnrm = rsden
         orsnrm = rsnrm
!#ifdef _MULTIGRID_VERBOSE
!         call prtstp (iok,0,rsnrm,rsden,orsnrm)
!#endif
      endif
c*
c* *********************************************************************
c* *** solve directly if nlev = 1 
c* *********************************************************************
c*
c*    *** solve directly if on the coarse grid ***
      if (nlev .eq. 1) then
c*
c*       *** solve with ncghs, mgsmoo_s=4 (no residual) ***
         iresid = 0
         iadjoint = 0
         itmax_s  = 100
         iters_s  = 0
         errtol_s = epsiln
         mgsmoo_s = mgsmoo
         call azeros(nxf,nyf,nzf,x(iz(1,lev)))
         call nsmooth (nxf,nyf,nzf,
     2      ipc(iz(5,lev)),rpc(iz(6,lev)),
     3      ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4      x(iz(1,lev)),w1,w2,w3,
     5      itmax_s,iters_s,errtol_s,omega,
     6      iresid,iadjoint,mgsmoo_s)
c*
c* ***** *** check if trouble on the coarse grid ***
c* ***** if (iters_s .ge. itmax_s) then
c* *****    print*,'% MVFAS: smooth iters on coarse grid: ',iters_s
c* ***** endif
c*      
c*       *** compute the stopping test ***
         iters = 1
         if (iok.ne.0) then
            orsnrm = rsnrm
            if (istop .eq. 0) then
               call nmresid(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4            x(iz(1,lev)),w1,w2)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
            elseif (istop .eq. 1) then
               call nmresid(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4            x(iz(1,lev)),w1,w2)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
            elseif (istop .eq. 2) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
               call xcopy(nxf,nyf,nzf,x(iz(1,lev)),tru(iz(1,lev)))
            elseif (istop .eq. 3) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm2(nxf,nyf,nzf,w1)
            elseif (istop .eq. 4) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm2(nxf,nyf,nzf,w1)
            elseif (istop .eq. 5) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               call nmatvec(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),
     4            w1,w2,w3)
               rsnrm = dsqrt(xdot(nxf,nyf,nzf,w1,w2))
            else
               print*,'% MVCS: bad istop value... '
            endif
!#ifdef _MULTIGRID_VERBOSE
!            call prtstp (iok,iters,rsnrm,rsden,orsnrm)
!#endif
         endif
c*
c*       *** return now ***
         goto 99
      endif
c*
c* *********************************************************************
c* *** begin mg iteration (note nxf,nyf,nzf changes during loop)
c* *********************************************************************
c*
c*    *** setup for the v-cycle looping ***
      iters = 0 
 30   continue
c*
c*       *** finest level initialization ***
         level = 1
         lev   = (ilev-1)+level
c*
c*       *** nu1 pre-smoothings on fine grid (with residual) ***
         iresid = 1
         iadjoint = 0
         iters_s  = 0
         errtol_s = 0.0d0
         nuuu = ivariv (nu1,lev)
         call nsmooth(nxf,nyf,nzf,
     2      ipc(iz(5,lev)),rpc(iz(6,lev)),
     3      ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4      x(iz(1,lev)),w2,w3,w1,
     5      nuuu,iters_s,errtol_s,omega,
     6      iresid,iadjoint,mgsmoo)
         call xcopy(nxf,nyf,nzf,w1,w0(iz(1,lev)))
c*
c* *********************************************************************
c* begin cycling down to coarse grid
c* *********************************************************************
c*
c*       *** go down grids: restrict resid to coarser and smooth ***
         do 40 level = 2, nlev
            lev = (ilev-1)+level
c*
c*          *** find new grid size ***
            call mkcors(1,nxf,nyf,nzf,nxc,nyc,nzc)
c*
c*          *** restrict residual to coarser grid ***
            call restrc(nxf,nyf,nzf,nxc,nyc,nzc,
     2         w1,w0(iz(1,lev)),pc(iz(11,lev-1)))
c*
c*          *** restrict (extract) solution to coarser grid ***
            call extrac(nxf,nyf,nzf,nxc,nyc,nzc,
     2         x(iz(1,lev-1)),w4(iz(1,lev)))
c*
c*          *** new grid size ***
            nxf = nxc
            nyf = nyc
            nzf = nzc
c*
c*          *** apply coarse grid operator to coarse grid soln ***
            call nmatvec(nxf,nyf,nzf,
     2         ipc(iz(5,lev)),rpc(iz(6,lev)),
     3         ac(iz(7,lev)),cc(iz(1,lev)),
     4         w4(iz(1,lev)),fc(iz(1,lev)),w3)
c*
c*          *** build coarse grid right hand side ***
            call xaxpy(nxf,nyf,nzf,(1.0d0),
     2         w0(iz(1,lev)),fc(iz(1,lev)))
c*
c*          *** if not on coarsest level yet... ***
            if (level .ne. nlev) then
c*
c*             *** nu1 pre-smoothings on this level (with residual) ***
               call xcopy(nxf,nyf,nzf,w4(iz(1,lev)),x(iz(1,lev)))
               iresid = 1
               iadjoint = 0
               iters_s  = 0
               errtol_s = 0.0d0
               nuuu = ivariv (nu1,lev)
               call nsmooth(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4            x(iz(1,lev)),w2,w3,w1,
     5            nuuu,iters_s,errtol_s,omega,
     6            iresid,iadjoint,mgsmoo)
            endif
c*
c*       *** end of cycling down to coarse grid loop ***
 40      continue
c*
c* *********************************************************************
c* begin coarse grid
c* *********************************************************************
c*
c*       *** coarsest level ***
         level = nlev
         lev = (ilev-1)+level
c*
c*       *** solve on coarsest grid with ncghs, mgsmoo_s=4 (no residual) ***
         iresid = 0
         iadjoint = 0
         itmax_s  = 100
         iters_s  = 0
         errtol_s = epsiln
         mgsmoo_s = mgsmoo
         call azeros(nxf,nyf,nzf,x(iz(1,lev)))
         call nsmooth (nxf,nyf,nzf,
     2      ipc(iz(5,lev)),rpc(iz(6,lev)),
     3      ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4      x(iz(1,lev)),w1,w2,w3,
     5      itmax_s,iters_s,errtol_s,omega,
     6      iresid,iadjoint,mgsmoo_s)
c*
c* ***** *** check for trouble on the coarse grid ***
c* ***** if (iters_s .ge. itmax_s) then
c* *****    print*,'% MVFAS: smooth iters on coarse grid: ',iters_s
c* ***** endif
c*      
c* *********************************************************************
c* begin cycling back to fine grid
c* *********************************************************************
c*
c*       *** move up grids: interpolate resid to finer and smooth ***
         do 70 level = nlev-1, 1, -1
            lev   = (ilev-1)+level
c*
c*          *** find new grid size ***
            call mkfine(1,nxf,nyf,nzf,nxc,nyc,nzc)
c*
c*          *** form difference of new approx at the coarse grid ***
            call xaxpy(nxf,nyf,nzf,(-1.0d0),
     2         w4(iz(1,lev+1)),x(iz(1,lev+1)))
c*
c*          *** call the line search (on the coarser level) ***
            call linesearch(nxf,nyf,nzf,xdamp,
     2         ipc(iz(5,lev+1)),rpc(iz(6,lev+1)),
     3         ac(iz(7,lev+1)),cc(iz(1,lev+1)),fc(iz(1,lev+1)),
     4         x(iz(1,lev+1)),w4(iz(1,lev+1)),w0(iz(1,lev+1)),
     5         w1,w2,w3)
c*
c*          *** interpolate to next finer grid ***
            call interp(nxf,nyf,nzf,nxc,nyc,nzc,
     2         x(iz(1,lev+1)),w1,pc(iz(11,lev)))
c*
c*          *** new grid size ***
            nxf = nxc
            nyf = nyc
            nzf = nzc
c*
c*          *** call the line search (on the finer level) ***
CZZZ        call linesearch(nxf,nyf,nzf,xdamp,
CZZZ 2         ipc(iz(5,lev)),rpc(iz(6,lev)),
CZZZ 3         ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
CZZZ 4         w1,x(iz(1,lev)),w0(iz(1,lev)),
CZZZ 5         w2,w3,w4)
c*
c*          *** perform the coarse grid correction ***
c* ******** xdamp = 1.0d0
            call xaxpy(nxf,nyf,nzf,xdamp,w1,x(iz(1,lev)))
c*
c*          *** nu2 post-smoothings for correction (no residual) ***
            iresid = 0
            iadjoint = 1
            iters_s  = 0
            errtol_s = 0.0d0
            nuuu = ivariv (nu2,lev)
            call nsmooth(nxf,nyf,nzf,
     2         ipc(iz(5,lev)),rpc(iz(6,lev)),
     3         ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4         x(iz(1,lev)),w1,w2,w3,
     5         nuuu,iters_s,errtol_s,omega,
     6         iresid,iadjoint,mgsmoo)
 70      continue
c*
c* *********************************************************************
c* iteration complete: do some i/o
c* *********************************************************************
c*
c*       *** increment the iteration counter ***
         iters = iters + 1
c*
c*       *** compute/check the current stopping test ***
         if (iok.ne.0) then
            orsnrm = rsnrm
            if (istop .eq. 0) then
               call nmresid(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4            x(iz(1,lev)),w1,w2)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
            elseif (istop .eq. 1) then
               call nmresid(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),fc(iz(1,lev)),
     4            x(iz(1,lev)),w1,w2)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
            elseif (istop .eq. 2) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm1(nxf,nyf,nzf,w1)
               call xcopy(nxf,nyf,nzf,x(iz(1,lev)),tru(iz(1,lev)))
            elseif (istop .eq. 3) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm2(nxf,nyf,nzf,w1)
            elseif (istop .eq. 4) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               rsnrm = xnrm2(nxf,nyf,nzf,w1)
            elseif (istop .eq. 5) then
               call xcopy(nxf,nyf,nzf,tru(iz(1,lev)),w1)
               call xaxpy(nxf,nyf,nzf,(-1.0d0),x(iz(1,lev)),w1)
               call nmatvec(nxf,nyf,nzf,
     2            ipc(iz(5,lev)),rpc(iz(6,lev)),
     3            ac(iz(7,lev)),cc(iz(1,lev)),
     4            w1,w2,w3)
               rsnrm = dsqrt(xdot(nxf,nyf,nzf,w1,w2))
            else
!               print*,'% MVFAS: bad istop value... '
            endif
!#ifdef _MULTIGRID_VERBOSE
!            call prtstp (iok,iters,rsnrm,rsden,orsnrm)
!#endif
            if ((rsnrm/rsden) .le. errtol) goto 99
         endif
         if (iters .ge. itmax) goto 91
      goto 30
c*
c*    *** problems ***
 91   continue
      ierror = 1
c*
c*    *** return and end ***
 99   continue
      return
      end

