!
! Copyright (C) 2002 CP90 group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"

!-----------------------------------------------------------------------
      subroutine add_cc(rhoc,rhog,rhor)
!-----------------------------------------------------------------------
!
! add core correction to the charge density for exch-corr calculation
!
      use elct, only: nspin
      use gvec, only: np, ng

      ! this isn't really needed, but if I remove it, ifc 7.1
      ! gives an "internal compiler error"
      use reciprocal_vectors, only: gstart

      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      !use parm
      use work, only: wrk1
!
      implicit none
      real(kind=8), intent(in)   :: rhoc(nnr)
      real(kind=8), intent(inout):: rhor(nnr,nspin)
      complex(kind=8), intent(inout)::  rhog(ng,nspin)
!
      integer ig, ir, iss, isup, isdw
!
! In r-space:
!
      if (nspin.eq.1) then
         iss=1
         call DAXPY(nnr,1.d0,rhoc,1,rhor(1,iss),1)
      else
         isup=1
         isdw=2
         call DAXPY(nnr,0.5d0,rhoc,1,rhor(1,isup),1)
         call DAXPY(nnr,0.5d0,rhoc,1,rhor(1,isdw),1)
      end if
! rhoc(r) -> rhoc(g)  (wrk1 is used as work space)
      do ir=1,nnr
         wrk1(ir)=rhoc(ir)
      end do
      call fwfft(wrk1,nr1,nr2,nr3,nr1x,nr2x,nr3x)
! In g-space:
      if (nspin.eq.1) then
         do ig=1,ng
            rhog(ig,iss)=rhog(ig,iss)+wrk1(np(ig))
         end do
      else
         do ig=1,ng
            rhog(ig,isup)=rhog(ig,isup)+0.5d0*wrk1(np(ig))
            rhog(ig,isdw)=rhog(ig,isdw)+0.5d0*wrk1(np(ig))
         end do
      end if
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine atomic_wfc(eigr,n_atomic_wfc,wfc)
!-----------------------------------------------------------------------
!
! Compute atomic wavefunctions in G-space
!
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use ions_base, only: nsp, na, nas => nax
      use gvec
      use atom
!
      implicit none
      integer, intent(in) :: n_atomic_wfc
      complex(kind=8), intent(in) ::  eigr(ngw,nas,nsp)
      complex(kind=8), intent(out):: wfc(ngw,n_atomic_wfc)
!
      integer :: natwfc, ndm, is, ia, ir, nb, l, m, lm, i, lmax_wfc
      real(kind=8), allocatable::  ylm(:,:), q(:), jl(:), vchi(:),      &
     &     chiq(:)
!
! calculate max angular momentum required in wavefunctions
!
      lmax_wfc=-1
      do is = 1,nsp
         do nb = 1, nchi(is)
            lmax_wfc = max (lmax_wfc, lchi (nb, is) )
         enddo
      enddo
      allocate(ylm(ngw,(lmax_wfc+1)**2))
      call ylmr2 ((lmax_wfc+1)**2, ngw, gx, g, ylm)
      ndm = MAXVAL(mesh(1:nsp))
      allocate(jl(ndm), vchi(ndm))
      allocate(q(ngw), chiq(ngw))
!
      do i=1,ngw
         q(i) = sqrt(g(i))*tpiba
      end do
!
      natwfc=0
      do is=1,nsp
!
!   radial fourier transform of the chi functions
!   NOTA BENE: chi is r times the radial part of the atomic wavefunction
!
         do nb = 1,nchi(is)
            l = lchi(nb,is)
            do i=1,ngw
               call sph_bes (mesh(is), r(1,is), q(i), l, jl)
               do ir=1,mesh(is)
                  vchi(ir) = chi(ir,nb,is)*r(ir,is)*jl(ir)
               enddo
               call simpson_cp90(mesh(is),vchi,rab(1,is),chiq(i))
            enddo
!
!   multiply by angular part and structure factor
!   NOTA BENE: the factor i^l MUST be present!!!
!
            do m = 1,2*l+1
               lm = l**2 + m
               do ia=1,na(is)
                  natwfc = natwfc + 1
                  wfc(:,natwfc) = (0.d0,1.d0)**l * eigr(:,ia,is)*       &
     &                                ylm(:,lm)*chiq(:)
               enddo
            enddo
         enddo
      enddo
!
      if (natwfc.ne.n_atomic_wfc)                                       &
     &     call errore('atomic_wfc','unexpected error',natwfc)
!
      deallocate(q, chiq, vchi, jl, ylm)
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine box2grid(irb,nfft,qv,vr)
!-----------------------------------------------------------------------
!
! add array qv(r) on box grid to array vr(r) on dense grid
! irb   : position of the box in the dense grid
! nfft=1  add      real part of qv(r) to real part of array vr(r) 
! nfft=2  add imaginary part of qv(r) to real part of array vr(r) 
!
      use parameters, only: natx, nsx
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nnr => nnrx
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nnrb => nnrbx
      use para_mod
      implicit none
      integer, intent(in):: nfft, irb(3)
      real(kind=8), intent(in):: qv(2,nnrb)
      complex(kind=8), intent(inout):: vr(nnr)
!
      integer ir1, ir2, ir3, ir, ibig1, ibig2, ibig3, ibig

      if(nfft.le.0.or.nfft.gt.2) call errore('box2grid','wrong data',nfft)

      do ir3=1,nr3b
         ibig3=irb(3)+ir3-1
         ibig3=1+mod(ibig3-1,nr3)
         if(ibig3.lt.1.or.ibig3.gt.nr3)                                 &
     &        call errore('box2grid','ibig3 wrong',ibig3)
         ibig3=ibig3-dfftp%ipp(me)
         if (ibig3.gt.0.and.ibig3.le. ( dfftp%npp(me) ) ) then
            do ir2=1,nr2b
               ibig2=irb(2)+ir2-1
               ibig2=1+mod(ibig2-1,nr2)
               if(ibig2.lt.1.or.ibig2.gt.nr2)                           &
     &              call errore('box2grid','ibig2 wrong',ibig2)
               do ir1=1,nr1b
                  ibig1=irb(1)+ir1-1
                  ibig1=1+mod(ibig1-1,nr1)
                  if(ibig1.lt.1.or.ibig1.gt.nr1)                        &
     &                 call errore('box2grid','ibig1 wrong',ibig1)
                  ibig=ibig1+(ibig2-1)*nr1x+(ibig3-1)*nr1x*nr2x
                  ir=ir1+(ir2-1)*nr1bx+(ir3-1)*nr1bx*nr2bx
                  vr(ibig) = vr(ibig)+qv(nfft,ir)
               end do
            end do
         end if
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine box2grid2(irb,qv,v)
!-----------------------------------------------------------------------
!
! add array qv(r) on box grid to array v(r) on dense grid
! irb   : position of the box in the dense grid
!
      use parameters, only: nsx, natx
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nnr => nnrx
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nnrb => nnrbx
      use para_mod
      implicit none
      integer, intent(in):: irb(3)
      complex(kind=8), intent(in):: qv(nnrb)
      complex(kind=8), intent(inout):: v(nnr)
!
      integer ir1, ir2, ir3, ir, ibig1, ibig2, ibig3, ibig

      do ir3=1,nr3b
         ibig3=irb(3)+ir3-1
         ibig3=1+mod(ibig3-1,nr3)
         if(ibig3.lt.1.or.ibig3.gt.nr3)                                 &
     &        call errore('box2grid2','ibig3 wrong',ibig3)
         ibig3=ibig3-dfftp%ipp(me)
         if (ibig3.gt.0.and.ibig3.le. dfftp%npp(me) ) then
            do ir2=1,nr2b
               ibig2=irb(2)+ir2-1
               ibig2=1+mod(ibig2-1,nr2)
               if(ibig2.lt.1.or.ibig2.gt.nr2)                           &
     &              call errore('box2grid2','ibig2 wrong',ibig2)
               do ir1=1,nr1b
                  ibig1=irb(1)+ir1-1
                  ibig1=1+mod(ibig1-1,nr1)
                  if(ibig1.lt.1.or.ibig1.gt.nr1)                        &
     &                 call errore('box2grid2','ibig1 wrong',ibig1)
                  ibig=ibig1+(ibig2-1)*nr1x+(ibig3-1)*nr1x*nr2x
                  ir=ir1+(ir2-1)*nr1bx+(ir3-1)*nr1bx*nr2bx
                  v(ibig) = v(ibig)+qv(ir)
               end do
            end do
         end if
      end do

      return
      end
!
!-----------------------------------------------------------------------
      real(kind=8) function boxdotgrid(irb,nfft,qv,vr)
!-----------------------------------------------------------------------
!
! Calculate \sum_i qv(r_i)*vr(r_i)  with r_i on box grid
! array qv(r) is defined on box grid, array vr(r)on dense grid
! irb   : position of the box in the dense grid
! nfft=1 (2): use real (imaginary) part of qv(r)
! Parallel execution: remember to sum the contributions from other nodes
!
      use parameters, only: nsx, natx
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nnr => nnrx
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nnrb => nnrbx
      use para_mod
      implicit none
      integer, intent(in):: nfft, irb(3)
      real(kind=8), intent(in):: qv(2,nnrb), vr(nnr)
!
      integer ir1, ir2, ir3, ir, ibig1, ibig2, ibig3, ibig
!
!
      if(nfft.le.0.or.nfft.gt.2) call errore('box2grid','wrong data',nfft)

      boxdotgrid=0.d0

      do ir3=1,nr3b
         ibig3=irb(3)+ir3-1
         ibig3=1+mod(ibig3-1,nr3)
         ibig3=ibig3-dfftp%ipp(me)
         if (ibig3.gt.0.and.ibig3.le. dfftp%npp(me) ) then
            do ir2=1,nr2b
               ibig2=irb(2)+ir2-1
               ibig2=1+mod(ibig2-1,nr2)
               do ir1=1,nr1b
                  ibig1=irb(1)+ir1-1
                  ibig1=1+mod(ibig1-1,nr1)
                  ibig=ibig1 + (ibig2-1)*nr1x + (ibig3-1)*nr1x*nr2x
                  ir  =ir1 + (ir2-1)*nr1bx + (ir3-1)*nr1bx*nr2bx
                  boxdotgrid = boxdotgrid + qv(nfft,ir)*vr(ibig)
               end do
            end do
         endif
      end do

      return
      end
!
!-----------------------------------------------------------------------
      subroutine calbec (nspmn,nspmx,eigr,c,bec)
!-----------------------------------------------------------------------
!     this routine calculates array bec
!
!        < psi_n | beta_i,i > = c_n(0) beta_i,i(0) +
!                 2 sum_g> re(c_n*(g) (-i)**l beta_i,i(g) e^-ig.r_i)
!
!     routine makes use of c(-g)=c*(g)  and  beta(-g)=beta*(g)
!
      use ions_base, only: na, nas => nax
      use io_global, only: stdout
      use cvan, only: ish
      use elct
      use gvecw, only: ngw
      use control_flags, only: iprint, iprsta
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb
!
      implicit none
      integer nspmn, nspmx
      real(kind=8)  bec(nhsa,n)
      complex(kind=8) c(ngw,n), eigr(ngw,nas,nspmx)
! local variables
      integer is, ia, i , iv
!
!
      call start_clock( 'calbec' )
      call nlsm1(n,nspmn,nspmx,eigr,c,bec)
!
      if (iprsta.gt.2) then
         WRITE( stdout,*)
         do is=1,nspmx
            if(nspmx.gt.1) then
               WRITE( stdout,'(33x,a,i4)') ' calbec: bec (is)',is
               WRITE( stdout,'(8f9.4)')                                       &
     &              ((bec(ish(is)+(iv-1)*na(is)+1,i),iv=1,nh(is)),i=1,n)
            else
               do ia=1,na(is)
                  WRITE( stdout,'(33x,a,i4)') ' calbec: bec (ia)',ia
                  WRITE( stdout,'(8f9.4)')                                    &
     &             ((bec(ish(is)+(iv-1)*na(is)+ia,i),iv=1,nh(is)),i=1,n)
               end do
            end if
         end do
      endif
      call stop_clock( 'calbec' )
!
      return
      end
!-------------------------------------------------------------------------
      subroutine calphi(c0,ema0bg,bec,betae,phi)
!-----------------------------------------------------------------------
!     input: c0 (orthonormal with s(r(t)), bec=<c0|beta>, betae=|beta>
!     computes the matrix phi (with the old positions)
!       where  |phi> = s'|c0> = |c0> + sum q_ij |i><j|c0>
!     where s'=s(r(t))  
!
      use ions_base, only: na, nsp
      use io_global, only: stdout
      use cvan, only: ish, nvb
      use uspp_param, only: nh
      use uspp, only :nhsa=>nkb, nhsavb=>nkbus, qq
      use elct
      use gvecw, only: ngw
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
      use mp, only: mp_sum
!
      implicit none
      complex(kind=8) c0(ngw,n), phi(ngw,n), betae(ngw,nhsa)
      real(kind=8)    ema0bg(ngw), bec(nhsa,n), emtot
! local variables
      integer is, iv, jv, ia, inl, jnl, i, j
      real(kind=8) qtemp(nhsavb,n) ! automatic array
!
      call start_clock( 'calphi' )
      phi(:,:) = (0.d0, 0.d0)
!
      if (nvb.gt.0) then
         qtemp (:,:) = 0.d0
         do is=1,nvb
            do iv=1,nh(is)
               do jv=1,nh(is)
                  if(abs(qq(iv,jv,is)) > 1.e-5) then
                     do ia=1,na(is)
                        inl=ish(is)+(iv-1)*na(is)+ia
                        jnl=ish(is)+(jv-1)*na(is)+ia
                        do i=1,n
                           qtemp(inl,i) = qtemp(inl,i) +                &
     &                                    qq(iv,jv,is)*bec(jnl,i)
                        end do
                     end do
                  endif
               end do
            end do
         end do
!
         call MXMA                                                     &
     &       (betae,1,2*ngw,qtemp,1,nhsavb,phi,1,2*ngw,2*ngw,nhsavb,n)
      end if
!
      do j=1,n
         do i=1,ngw
            phi(i,j)=(phi(i,j)+c0(i,j))*ema0bg(i)
         end do
      end do
!     =================================================================
      if(iprsta > 2) then
         emtot=0.
         do j=1,n
            do i=1,ngw
               emtot=emtot                                              &
     &        +2.*real(phi(i,j)*conjg(c0(i,j)))*ema0bg(i)**(-2.)
            end do
         end do
         emtot=emtot/n

         call mp_sum( emtot )

         WRITE( stdout,*) 'in calphi sqrt(emtot)=',sqrt(emtot)
         WRITE( stdout,*)
         do is=1,nsp
            if(nsp > 1) then
               WRITE( stdout,'(33x,a,i4)') ' calphi: bec (is)',is
               WRITE( stdout,'(8f9.4)')                                       &
     &            ((bec(ish(is)+(iv-1)*na(is)+1,i),iv=1,nh(is)),i=1,n)
            else
               do ia=1,na(is)
                  WRITE( stdout,'(33x,a,i4)') ' calphi: bec (ia)',ia
                  WRITE( stdout,'(8f9.4)')                                    &
     &               ((bec(ish(is)+(iv-1)*na(is)+ia,i),iv=1,nh(is)),i=1,n)
               end do
            end if
         end do
      endif
      call stop_clock( 'calphi' )
!
      return
      end
!-----------------------------------------------------------------------
      real(kind=8) function cscnorm(bec,cp,i)
!-----------------------------------------------------------------------
!     requires in input the updated bec(i)
!
      use ions_base, only: na
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use elct
      use cvan, only: ish, nvb
      use uspp_param, only: nh
      use uspp, only: nhsa=>nkb, nhsavb=>nkbus, qq
      use mp, only: mp_sum
!
      implicit none
      integer i
      real(kind=8) bec(nhsa,n)
      complex(kind=8) cp(ngw,n)
!
      integer ig, is, iv, jv, ia, inl, jnl
      real(kind=8) rsum
      real(kind=8), allocatable:: temp(:)
!
!
      allocate(temp(ngw))
      do ig=1,ngw
         temp(ig)=real(conjg(cp(ig,i))*cp(ig,i))
      end do
      rsum=2.*SUM(temp)
      if (gstart == 2) rsum=rsum-temp(1)

      call mp_sum( rsum )

      deallocate(temp)
!
      do is=1,nvb
         do iv=1,nh(is)
            do jv=1,nh(is)
               if(abs(qq(iv,jv,is)).gt.1.e-5) then 
                  do ia=1,na(is)
                     inl=ish(is)+(iv-1)*na(is)+ia
                     jnl=ish(is)+(jv-1)*na(is)+ia
                     rsum = rsum +                                        &
     &                    qq(iv,jv,is)*bec(inl,i)*bec(jnl,i)
                  end do
               endif
            end do
         end do
      end do
!
      cscnorm=sqrt(rsum)
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine denkin(c,dekin)
!-----------------------------------------------------------------------
!
      use constants, only: pi, fpi
      use elct
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use cell_base, only: ainv
      use gvecw, only: ggp, agg => ecutz, sgg => ecsig, e0gg => ecfix
      use gvec
      use mp, only: mp_sum
!
      implicit none
! input
      complex(kind=8) c(ngw,nx)
! output
      real(kind=8) dekin(3,3)
! local
      integer j, k, ig, i
      real(kind=8), allocatable:: gtmp(:)
      real(kind=8) sk(n)  ! automatic array
!
      allocate (gtmp(ngw))
      dekin=0.d0
      do j=1,3
         do k=1,3
            do ig=1,ngw
               gtmp(ig) = gx(j,ig)*(gx(1,ig)*ainv(k,1)+                 &
     &                              gx(2,ig)*ainv(k,2)+                 &
     &                              gx(3,ig)*ainv(k,3)) *               &
     &                 (1.d0+2.d0*agg/sgg/sqrt(pi)*                     &
     &            exp(-(tpiba2*g(ig)-e0gg)*(tpiba2*g(ig)-e0gg)/sgg/sgg))
            end do
            do i=1,n
               sk(i)=0.d0
               do ig=gstart,ngw
                  sk(i)=sk(i)+real(conjg(c(ig,i))*c(ig,i))*gtmp(ig)
               end do
            end do
            do i=1,n
               dekin(j,k)=dekin(j,k)-2.d0*tpiba2*(f(i)*sk(i))
            end do
         end do
      end do
      deallocate (gtmp)

      call mp_sum( dekin( 1:3, 1:3 ) )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine denh(rhotmp,drhotmp,sfac,vtemp,eh,dh)
!-----------------------------------------------------------------------
!
! derivative of hartree energy wrt cell parameters h
! Output in dh
!
! rhotmp input : total electronic + ionic broadened charge (G)
! drhotmp input and work space
! sfac   input : structure factors
! wtemp work space
! eh input: hartree energy
!
      use constants, only: pi, fpi
      use elct
      use ions_base, only: nsp
      use gvec
      use gvecs
      use reciprocal_vectors, only: gstart
      use cell_base, only: omega
      use cell_base, only: ainv
      !use parm
      use pseu
      use dpseu
      use mp, only: mp_sum

      implicit none
! input
      complex(kind=8) rhotmp(ng), drhotmp(ng,3,3), vtemp(ng), sfac(ngs,nsp)
      real(kind=8) eh
! output
      real(kind=8) dh(3,3)
! local
      integer i, j, ig, is
      real(kind=8) wz
!
!     wz = factor for g.neq.0 because of c*(g)=c(-g)
!
      wz=2.d0
      do j=1,3
         do i=1,3
            do is=1,nsp
               do ig=1,ngs
                  drhotmp(ig,i,j) = drhotmp(ig,i,j) -                   &
     &                    sfac(ig,is)*drhops(ig,is)*                    &
     &                    2.d0*tpiba2*gx(i,ig)*(gx(1,ig)*ainv(j,1)+     &
     &                     gx(2,ig)*ainv(j,2)+gx(3,ig)*ainv(j,3))-      &
     &                    sfac(ig,is)*rhops(ig,is)*ainv(j,i)
               enddo
            enddo
            if (gstart == 2) vtemp(1)=(0.d0,0.d0)
            do ig=gstart,ng
               vtemp(ig)=conjg(rhotmp(ig))*rhotmp(ig)/(tpiba2*g(ig))**2 &
     &                 * tpiba2*gx(i,ig)*(gx(1,ig)*ainv(j,1)+           &
     &                   gx(2,ig)*ainv(j,2)+gx(3,ig)*ainv(j,3)) +       &
     &                 conjg(rhotmp(ig))/(tpiba2*g(ig))*drhotmp(ig,i,j)
            enddo
            dh(i,j)=fpi*omega*real(SUM(vtemp))*wz
         enddo
      enddo

      call mp_sum( dh( 1:3, 1:3 ) )

      do i=1,3
         do j=1,3
            dh(i,j)=dh(i,j)+omega*eh*ainv(j,i)
         end do
      end do

      return
      end
!
!-----------------------------------------------------------------------
      subroutine dennl(bec,denl)
!-----------------------------------------------------------------------
!
      use cvan, only: ish
      use uspp_param, only: nh
      use uspp, only: nhsa=>nkb, dvan
      use cdvan
      use elct
      use reciprocal_vectors, only: gstart
      use ions_base, only: nsp, na
      implicit none
! input
      real(kind=8) bec(nhsa,n)
! output
      real(kind=8) denl(3,3)
! local
      real(kind=8) dsum(3,3),dsums(2,3,3)
      integer is, iv, jv, ijv, inl, jnl, isa, ism, ia, iss, i,j,k
!
      denl=0.d0
      do is=1,nsp
         ijv=0
         do iv=1,nh(is)
            do jv=iv,nh(is)
               ijv=ijv+1
               isa=0
               do ism=1,is-1
                  isa=isa+na(ism)
               end do
               do ia=1,na(is)
                  inl=ish(is)+(iv-1)*na(is)+ia
                  jnl=ish(is)+(jv-1)*na(is)+ia
                  isa=isa+1
                  dsums=0.d0
                  do i=1,n
                     iss=ispin(i) 
                     do k=1,3
                        do j=1,3
                           dsums(iss,k,j)=dsums(iss,k,j)+f(i)*       &
     &                          (dbec(inl,i,k,j)*bec(jnl,i)          &
     &                          + bec(inl,i)*dbec(jnl,i,k,j))
                        enddo
                     enddo
                  end do
                  dsum=0.d0
                  do iss=1,nspin
                     do k=1,3
                        do j=1,3
                           drhovan(ijv,isa,iss,j,k)=dsums(iss,j,k)
                           dsum(j,k)=dsum(j,k)+dsums(iss,j,k)
                        enddo
                     enddo
                  end do
                  if(iv.ne.jv) dsum=2.d0*dsum
                  denl = denl + dsum*dvan(jv,iv,is)
               end do
            end do
         end do
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine denps(rhotmp,drhotmp,sfac,vtemp,dps)
!-----------------------------------------------------------------------
!
! derivative of local potential energy wrt cell parameters h
! Output in dps
!
! rhotmp input : rho(G) (up and down spin components summed)
! drhotmp input
! sfac   input : structure factors
! wtemp work space
!
      use elct
      use ions_base, only: nsp
      use gvec
      use gvecs
      use reciprocal_vectors, only: gstart
      use cell_base, only: omega
      use cell_base, only: ainv
      use pseu
      use dpseu
      use mp, only: mp_sum

      implicit none
! input
      complex(kind=8) rhotmp(ng), drhotmp(ng,3,3), vtemp(ng), sfac(ngs,nsp)
! output
      real(kind=8) dps(3,3)
! local
      integer i, j, ig, is
      real(kind=8) wz
!
!     wz = factor for g.neq.0 because of c*(g)=c(-g)
!
      wz=2.d0
      do i=1,3
         do j=1,3
            do ig=1,ngs
               vtemp(ig)=(0.,0.)
            enddo
            do is=1,nsp
               do ig=1,ngs
                  vtemp(ig)=vtemp(ig)-conjg(rhotmp(ig))*sfac(ig,is)*    &
     &                    dvps(ig,is)*2.d0*tpiba2*gx(i,ig)*             &
     &                    (gx(1,ig)*ainv(j,1) +                         &
     &                     gx(2,ig)*ainv(j,2) +                         &
     &                     gx(3,ig)*ainv(j,3) ) +                       &
     &                    conjg(drhotmp(ig,i,j))*sfac(ig,is)*vps(ig,is)
               enddo
            enddo
            dps(i,j)=omega*real(wz*SUM(vtemp))
            if (gstart == 2) dps(i,j)=dps(i,j)-omega*real(vtemp(1))
         enddo
      enddo

      call mp_sum( dps( 1:3, 1:3 ) )

      return
      end
!
!-------------------------------------------------------------------------
      subroutine dforce (bec,betae,i,c,ca,df,da,v)
!-----------------------------------------------------------------------
!computes: the generalized force df=cmplx(dfr,dfi) acting on the i-th
!          electron state at the gamma point of the brillouin zone
!          represented by the vector c=cmplx(cr,ci)
!
!     d_n(g) = f_n { 0.5 g^2 c_n(g) + [vc_n](g) +
!              sum_i,ij d^q_i,ij (-i)**l beta_i,i(g) 
!                                 e^-ig.r_i < beta_i,j | c_n >}
      use control_flags, only: iprint, tbuff
      use gvec
      use gvecs
      use gvecw, only: ngw
      use cvan, only: ish
      use uspp, only: nhsa=>nkb, dvan, deeq
      use uspp_param, only: nhm, nh
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use elct
      use constants, only: pi, fpi
      use ions_base, only: nsp, na, nat
      use work, only: wrk1
      use gvecw, only: ggp, agg => ecutz, sgg => ecsig, e0gg => ecfix
!
      implicit none
!
      complex(kind=8) betae(ngw,nhsa), c(ngw), ca(ngw), df(ngw), da(ngw)
      real(kind=8) bec(nhsa,n), v(nnrsx,nspin)
      integer i
! local variables
      integer iv, jv, ia, is, isa, ism, ios, iss1, iss2, ir, ig, inl, jnl
      real(kind=8) fi, fip, dd
      complex(kind=8) fp,fm,ci
      real(kind=8) af(nhsa), aa(nhsa) ! automatic arrays
      complex(kind=8)  dtemp(ngw)    !
      complex(kind=8), pointer:: psi(:)
!
!
      call start_clock( 'dforce' ) 
      psi => wrk1
!
!     important: if n is odd => c(*,n+1)=0.
! 
      if (mod(n,2).ne.0.and.i.eq.n) then
         do ig=1,ngw
            ca(ig)=(0.,0.)
         end do
      endif
!
      ci=(0.0,1.0)
!
      if (.not.tbuff) then
!
         psi (:) = (0.d0, 0.d0)
         do ig=1,ngw
            psi(nms(ig))=conjg(c(ig)-ci*ca(ig))
            psi(nps(ig))=c(ig)+ci*ca(ig)
         end do
!
         call ivfftw(psi,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!     
      else
!
!     read psi from buffer 21
!
#if defined(__CRAYY)
         buffer in(21,0) (psi(1),psi(nnrsx))
         ios = unit(21)
#else
         read(21,iostat=ios) psi
#endif
         if(ios.ne.0) call errore                                        &
     &       (' dforce',' error in reading unit 21',ios)
!
      endif
! 
      iss1=ispin(i)
!
! the following avoids a potential out-of-bounds error
!
      if (i.ne.n) then
         iss2=ispin(i+1)
      else
         iss2=iss1
      end if
!
      do ir=1,nnrsx
         psi(ir)=cmplx(v(ir,iss1)* real(psi(ir)),                       &
     &                 v(ir,iss2)*aimag(psi(ir)) )
      end do
!
      call fwfftw(psi,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!
!     note : the factor 0.5 appears 
!       in the kinetic energy because it is defined as 0.5*g**2
!       in the potential part because of the logics
!
      fi =-  f(i)*0.5
      fip=-f(i+1)*0.5
      do ig=1,ngw
         fp= psi(nps(ig)) + psi(nms(ig))
         fm= psi(nps(ig)) - psi(nms(ig))
         df(ig)= fi*(tpiba2*ggp(ig)* c(ig)+cmplx(real(fp), aimag(fm)))
         da(ig)=fip*(tpiba2*ggp(ig)*ca(ig)+cmplx(aimag(fp),-real(fm)))
      end do
!
!     aa_i,i,n = sum_j d_i,ij <beta_i,j|c_n>
! 
      if(nhsa.gt.0)then
         do inl=1,nhsa
            af(inl)=0.
            aa(inl)=0.
         end do
!
         do is=1,nsp
            do iv=1,nh(is)
               do jv=1,nh(is)
                  isa=0
                  do ism=1,is-1
                     isa=isa+na(ism)
                  end do
                  do ia=1,na(is)
                     inl=ish(is)+(iv-1)*na(is)+ia
                     jnl=ish(is)+(jv-1)*na(is)+ia
                     isa=isa+1
                     dd = deeq(iv,jv,isa,iss1)+dvan(iv,jv,is)
                     af(inl)=af(inl)-  f(i)*dd*bec(jnl,  i)
                     dd = deeq(iv,jv,isa,iss2)+dvan(iv,jv,is)
                     if (i.ne.n) aa(inl)=aa(inl)-f(i+1)*dd*bec(jnl,i+1)
                  end do
               end do
            end do
         end do
!
         do ig=1,ngw
            dtemp(ig)=(0.,0.)
         end do
         call MXMA                                                      &
     &        (betae,1,2*ngw,af,1,nhsa,dtemp,1,2*ngw,2*ngw,nhsa,1)
         do ig=1,ngw
            df(ig)=df(ig)+dtemp(ig)
         end do
!
         do ig=1,ngw
            dtemp(ig)=(0.,0.)
         end do
         call MXMA                                                      &
     &        (betae,1,2*ngw,aa,1,nhsa,dtemp,1,2*ngw,2*ngw,nhsa,1)
         do ig=1,ngw
            da(ig)=da(ig)+dtemp(ig)
         end do
      endif
!
      call stop_clock( 'dforce' ) 
!
      return
      end
!-----------------------------------------------------------------------
      subroutine dftname (exfact, dft)
!-----------------------------------------------------------------------
!
      implicit none
      integer :: exfact
      character(len=20) dft
!
      if (exfact == 0) then
         dft = 'PZ'
      elseif (exfact == 1) then
         dft = 'BLYP'
      elseif (exfact == 2) then
         dft = 'B88'
      elseif (exfact ==  - 5 .or. exfact == 3) then
         dft = 'BP'
      elseif (exfact ==  - 6 .or. exfact == 4) then
         dft = 'PW91'
      elseif (exfact == 5) then
         dft = 'PBE'
      elseif (exfact ==-1) then
         dft = 'WIG'
      elseif (exfact ==-2) then
         dft = 'HL'
      elseif (exfact ==-3) then
         dft = 'GL'
      else
         call errore ('dftname','unknown exch-corr functional',exfact)
      end if

      return
      end
!
!-----------------------------------------------------------------------
      subroutine dotcsc(eigr,cp)
!-----------------------------------------------------------------------
!
      use ions_base, only: nas => nax, na, nsp
      use io_global, only: stdout
      use elct
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use cvan, only: ish, nvb
      use uspp, only: nhsa=>nkb, qq
      use uspp_param, only: nh
      use mp, only: mp_sum
!
      implicit none
!
      complex(kind=8)  eigr(ngw,nas,nsp), cp(ngw,n)
! local variables
      real(kind=8) rsum, csc(n) ! automatic array
      complex(kind=8) temp(ngw) ! automatic array
 
      real(kind=8), allocatable::  becp(:,:)
      integer i,kmax,nnn,k,ig,is,ia,iv,jv,inl,jnl
!
      allocate(becp(nhsa,n))
!
!     < beta | phi > is real. only the i lowest:
!
      nnn=min(12,n)
      do i=nnn,1,-1
         kmax=i
         call nlsm1(i,1,nvb,eigr,cp,becp)
!
         do k=1,kmax
            do ig=1,ngw
               temp(ig)=conjg(cp(ig,k))*cp(ig,i)
            end do
            csc(k)=2.*real(SUM(temp))
            if (gstart == 2) csc(k)=csc(k)-real(temp(1))
         end do

         call mp_sum( csc( 1:kmax ) )

         do k=1,kmax
            rsum=0.
            do is=1,nvb
               do iv=1,nh(is)
                  do jv=1,nh(is)
                     do ia=1,na(is)
                        inl=ish(is)+(iv-1)*na(is)+ia
                        jnl=ish(is)+(jv-1)*na(is)+ia
                        rsum = rsum +                                    &
     &                   qq(iv,jv,is)*becp(inl,i)*becp(jnl,k)
                     end do
                  end do
               end do
            end do
            csc(k)=csc(k)+rsum
         end do
!
         WRITE( stdout,'(a,12f18.15)')' dotcsc = ',(csc(k),k=1,i)
!
      end do
      WRITE( stdout,*)
!
      deallocate(becp)
!
      return
      end
!-----------------------------------------------------------------------
      subroutine drhov(irb,eigrb,rhovan,rhog,rhor)
!-----------------------------------------------------------------------
!     this routine calculates arrays drhog drhor, derivatives wrt h of:
!
!        n_v(g) = sum_i,ij rho_i,ij q_i,ji(g) e^-ig.r_i
!
!     Same logic as in routine rhov.
!     On input rhor and rhog must contain the smooth part only !!!
!     Output in module derho (drhor, drhog)
!
      use control_flags, only: iprint
      use parameters, only: natx, nsx
      use ions_base, only: na, nsp, nat, nas => nax
      use gvec
      use cvan
      use uspp_param, only: nhm, nh
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use elct
      use gvecb
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use cell_base, only: ainv
      use qgb_mod
      use work, only: wrk1
      use work_box
      use para_mod
      use cdvan
      use derho
      use dqgb_mod
      implicit none
! input
      integer, intent(in) ::  irb(3,natx,nsx)
      real(kind=8), intent(in)::  rhor(nnr,nspin)
      real(kind=8) ::  rhovan(nhm*(nhm+1)/2,nat,nspin)
      complex(kind=8), intent(in)::  eigrb(ngb,nas,nsp), rhog(ng,nspin)
! local
      integer i, j, isup, isdw, nfft, ifft, iv, jv, ig, ijv, is, iss,   &
     &     isa, ia, ir, irb3, imin3, imax3
      real(kind=8) sum, dsum
      complex(kind=8) fp, fm, ci
      complex(kind=8), pointer:: v(:)
      complex(kind=8), allocatable:: dqgbt(:,:)
!
!
      do j=1,3
         do i=1,3
            do iss=1,nspin
               do ir=1,nnr
                  drhor(ir,iss,i,j)=-rhor(ir,iss)*ainv(j,i)
               end do
               do ig=1,ng
                  drhog(ig,iss,i,j)=-rhog(ig,iss)*ainv(j,i)
               end do
            end do
         end do
      end do
!
      if (nvb.eq.0) return
!
      v => wrk1
      allocate(dqgbt(ngb,2))
      ci=(0.,1.)
!
      if(nspin.eq.1) then
!     ------------------------------------------------------------------
!     nspin=1 : two fft at a time, one per atom, if possible
!     ------------------------------------------------------------------
         do i=1,3
            do j=1,3
!
               v(:) = (0.d0, 0.d0)
!
               iss=1
               isa=1
               do is=1,nvb
#ifdef __PARA
                  do ia=1,na(is)
                     nfft=1
                     irb3=irb(3,ia,is)
                     call parabox(nr3b,irb3,nr3,imin3,imax3)
                     if (imax3-imin3+1.le.0) go to 15
#else
                  do ia=1,na(is),2
                     nfft=2
#endif
                     dqgbt(:,:) = (0.d0, 0.d0) 
                     if (ia.eq.na(is)) nfft=1
!
!  nfft=2 if two ffts at the same time are performed
!
                     do ifft=1,nfft
                        ijv=0
                        do iv=1,nh(is)
                           do jv=iv,nh(is)
                              ijv=ijv+1
                              sum = rhovan(ijv,isa+ifft-1,iss)
                              dsum=drhovan(ijv,isa+ifft-1,iss,i,j)
                              if(iv.ne.jv) then
                                 sum =2.*sum
                                 dsum=2.*dsum
                              endif
                              do ig=1,ngb
                                 dqgbt(ig,ifft)=dqgbt(ig,ifft) +        &
     &                                (sum*dqgb(ig,ijv,is,i,j) +        &
     &                                dsum*qgb(ig,ijv,is) )
                              end do
                           end do
                        end do
                     end do
!     
! add structure factor
!
                     qv(:) = (0.d0, 0.d0)
                     if(nfft.eq.2) then
                        do ig=1,ngb
                           qv(npb(ig)) = eigrb(ig,ia  ,is)*dqgbt(ig,1)  &
     &                        + ci*      eigrb(ig,ia+1,is)*dqgbt(ig,2)
                           qv(nmb(ig))=                                 &
     &                             conjg(eigrb(ig,ia  ,is)*dqgbt(ig,1)) &
     &                        + ci*conjg(eigrb(ig,ia+1,is)*dqgbt(ig,2))
                        end do
                     else
                        do ig=1,ngb
                           qv(npb(ig)) = eigrb(ig,ia,is)*dqgbt(ig,1)
                           qv(nmb(ig)) =                                &
     &                             conjg(eigrb(ig,ia,is)*dqgbt(ig,1))
                        end do
                     endif
!
                     call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
!  qv = US contribution in real space on box grid
!       for atomic species is, real(qv)=atom ia, imag(qv)=atom ia+1
!
!  add qv(r) to v(r), in real space on the dense grid
!
                     call box2grid(irb(1,ia,is),1,qv,v)
                     if (nfft.eq.2) call box2grid(irb(1,ia+1,is),2,qv,v)
  15                 isa=isa+nfft
!
                  end do
               end do
!
               do ir=1,nnr
                  drhor(ir,iss,i,j)=drhor(ir,iss,i,j)+real(v(ir))
               end do
!
               call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
               do ig=1,ng
                  drhog(ig,iss,i,j)=drhog(ig,iss,i,j)+v(np(ig))
               end do
!
            enddo
         enddo
!
      else
!     ------------------------------------------------------------------
!     nspin=2: two fft at a time, one for spin up and one for spin down
!     ------------------------------------------------------------------
         isup=1
         isdw=2
         do i=1,3
            do j=1,3
               v(:) = (0.d0, 0.d0)
               isa=1
               do is=1,nvb
                  do ia=1,na(is)
#ifdef __PARA
                     irb3=irb(3,ia,is)
                     call parabox(nr3b,irb3,nr3,imin3,imax3)
                     if (imax3-imin3+1.le.0) go to 25
#endif
                     do iss=1,2
                        dqgbt(:,iss) = (0.d0, 0.d0)
                        ijv=0
                        do iv= 1,nh(is)
                           do jv=iv,nh(is)
                              ijv=ijv+1
                              sum=rhovan(ijv,isa,iss)
                              dsum =drhovan(ijv,isa,iss,i,j)
                              if(iv.ne.jv) then
                                 sum =2.*sum
                                 dsum=2.*dsum
                              endif
                              do ig=1,ngb
                                 dqgbt(ig,iss)=dqgbt(ig,iss)  +         &
     &                               (sum*dqgb(ig,ijv,is,i,j) +         &
     &                               dsum*qgb(ig,ijv,is))
                              end do
                           end do
                        end do
                     end do
!     
! add structure factor
!
                     qv(:) = (0.d0, 0.d0)
                     do ig=1,ngb
                        qv(npb(ig))= eigrb(ig,ia,is)*dqgbt(ig,1)        &
     &                    + ci*      eigrb(ig,ia,is)*dqgbt(ig,2)
                        qv(nmb(ig))= conjg(eigrb(ig,ia,is)*dqgbt(ig,1)) &
     &                    +       ci*conjg(eigrb(ig,ia,is)*dqgbt(ig,2))
                     end do
!
                     call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
!  qv is the now the US augmentation charge for atomic species is
!  and atom ia: real(qv)=spin up, imag(qv)=spin down
!
!  add qv(r) to v(r), in real space on the dense grid
!
                     call box2grid2(irb(1,ia,is),qv,v)
  25                 isa=isa+1
                  end do
               end do
!
               do ir=1,nnr
                  drhor(ir,isup,i,j) = drhor(ir,isup,i,j) + real(v(ir))
                  drhor(ir,isdw,i,j) = drhor(ir,isdw,i,j) +aimag(v(ir))
               enddo
!
               call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
               do ig=1,ng
                  fp=v(np(ig))+v(nm(ig))
                  fm=v(np(ig))-v(nm(ig))
                  drhog(ig,isup,i,j) = drhog(ig,isup,i,j) +             &
     &                 0.5*cmplx( real(fp),aimag(fm))
                  drhog(ig,isdw,i,j) = drhog(ig,isdw,i,j) +             &
     &                 0.5*cmplx(aimag(fp),-real(fm))
               end do
!
            end do
         end do
      endif
      deallocate(dqgbt)
!
      return
      end
!-----------------------------------------------------------------------
      subroutine eigs(nspin,nx,nupdwn,iupdwn,f,lambda)
!-----------------------------------------------------------------------
!     computes eigenvalues (wr) of the real symmetric matrix lambda
!     Note that lambda as calculated is multiplied by occupation numbers
!     so empty states yield zero. Eigenvalues are printed out in eV
!
      use io_global, only: stdout
      implicit none
! input
      integer, intent(in) :: nspin, nx, nupdwn(nspin), iupdwn(nspin)
      real(kind=8), intent(in) :: lambda(nx,nx), f(nx)
! local variables
      real(kind=8) lambdar(nx,nx), wr(nx), fv1(nx),fm1(2,nx), zr, au
      integer iss,j,i,ierr
!
      au=27.212
!
      do iss=1,nspin
         do i=1,nupdwn(iss)
            do j=1,nupdwn(iss)
               lambdar(j,i)=lambda(iupdwn(iss)-1+j,iupdwn(iss)-1+i)
            end do
         end do
         call rs(nx,nupdwn(iss),lambdar,wr,0,zr,fv1,fm1,ierr)
         do i=1,nupdwn(iss)
            if (f(iupdwn(iss)-1+i).gt.1.e-6) then
               wr(i)=au*wr(i)/f(iupdwn(iss)-1+i)
            else
               wr(i)=0.0
            end if
         end do
!
!     print out eigenvalues
!
         WRITE( stdout,12) 0., 0., 0.
         WRITE( stdout,14) (wr(i),i=1,nupdwn(iss))
      end do
   12 format(//' eigenvalues at k-point: ',3f6.3)
   14 format(10f8.2)
      WRITE( stdout,*)
!
      return
      end
!
!-----------------------------------------------------------------------
      real(kind=8) function enkin(c)
!-----------------------------------------------------------------------
!
! calculation of kinetic energy term
!
      use constants, only: pi, fpi
      use elct
      use gvec
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use gvecw, only: ggp, agg => ecutz, sgg => ecsig, e0gg => ecfix
      use mp, only: mp_sum

      implicit none
! input
      complex(kind=8) c(ngw,nx)
! local
      integer ig, i
      real(kind=8) sk(n)  ! automatic array
!
!
      do i=1,n
         sk(i)=0.0
         do ig=gstart,ngw
            sk(i)=sk(i)+real(conjg(c(ig,i))*c(ig,i))*ggp(ig)
         end do
      end do

      call mp_sum( sk(1:n) )

      enkin=0.0
      do i=1,n
         enkin=enkin+f(i)*sk(i)
      end do
      enkin=enkin*tpiba2
!
      return
      end
!
!-----------------------------------------------------------------------
      real(kind=8) function ennl(rhovan, bec)
!-----------------------------------------------------------------------
!
! calculation of nonlocal potential energy term
!
      use cvan, only: ish
      use uspp_param, only: nhm, nh
      use uspp, only :nhsa=>nkb, dvan
      use elct
      use ions_base, only: nsp, nat, na
      implicit none
! input
      real(kind=8) bec(nhsa,n)
      real(kind=8) rhovan(nhm*(nhm+1)/2,nat,nspin)
! local
      real(kind=8) sum, sums(2)
      integer is, iv, jv, ijv, inl, jnl, isa, ism, ia, iss, i
!
!
      ennl=0.d0
      do is=1,nsp
         ijv=0
         do iv= 1,nh(is)
            do jv=iv,nh(is)
               ijv=ijv+1
               isa=0
               do ism=1,is-1
                  isa=isa+na(ism)
               end do
               do ia=1,na(is)
                  inl=ish(is)+(iv-1)*na(is)+ia
                  jnl=ish(is)+(jv-1)*na(is)+ia
                  isa=isa+1
                  sums=0.d0
                  do i=1,n
                     iss=ispin(i) 
                     sums(iss) = sums(iss) +f(i)*bec(inl,i)*bec(jnl,i)
                  end do
                  sum=0.d0
                  do iss=1,nspin
                     rhovan(ijv,isa,iss) = sums(iss)
                     sum=sum+sums(iss)
                  end do
                  if(iv.ne.jv) sum=2.d0*sum
                  ennl=ennl+sum*dvan(jv,iv,is)
               end do
            end do
         end do
      end do
!
      return
      end
!-------------------------------------------------------------------------
      subroutine expxc(nnr,nspin,rhor,exc)
!----------------------------------------------------------------------
!
!       ceperley & alder's correlation energy
!       after j.p. perdew & a. zunger prb 23, 5048 (1981)
!
!       rhor contains rho(r) on input, vxc(r) on output
!
      use constants, only: pi, fpi
      use mp, only: mp_sum
!
      implicit none
!
      integer nnr, nspin
      real(kind=8) rhor(nnr,nspin), exc
! local variables
      integer ir, iflg, isup, isdw
      real(kind=8) roe, aroe, rs, rsl, rsq, ecca, vcca, eccp, vccp,    &
     &     zeta, onemz, zp, zm, fz, dfzdz, exc1, vxc1, vxc2
! constants
      real(kind=8) x76, x43, x13
      parameter(x76=7.d0/6.d0, x43=4.d0/3.d0, x13=1.d0/3.d0)
      real(kind=8) ax
      parameter (ax = -0.916330586d0)
! Perdew and Zunger parameters
      real(kind=8) ap, bp, cp, dp, af, bf, cf, df,                      &
     &     bp1, cp1, dp1, bf1, cf1, df1
      parameter                                                         &
     &( ap=0.03110*2.0, bp=-0.0480*2.0, cp=0.0020*2.0, dp=-0.0116*2.0   &
     &, af=0.01555*2.0, bf=-0.0269*2.0, cf=0.0007*2.0, df=-0.0048*2.0   &
     &, bp1=bp-ap/3.0, cp1=2.0*cp/3.0, dp1=(2.0*dp-cp)/3.0              &
     &, bf1=bf-af/3.0, cf1=2.0*cf/3.0, df1=(2.0*df-cf)/3.0 )
      real(kind=8) va(2), vb(2), vc(2), vd(2), vbt1(2), vbt2(2)
      real(kind=8)  a(2), b(2), c(2), d(2), g(2), b1(2), b2(2)
      data va/ap ,af /, vb/bp1,bf1/, vc/cp1,cf1/, vd/dp1,df1/,          &
     &     vbt1/1.0529,1.3981/, vbt2/0.3334,0.2611/
      data a/0.0622,0.0311/, b/-0.096,-0.0538/, c/0.0040,0.0014/,       &
     &     d/-0.0232,-0.0096/, b1/1.0529,1.3981/, b2/0.3334,0.2611/,    &
     &     g/-0.2846,-0.1686/
!
      if (nspin.eq.1) then
!
! iflg=1: paramagnetic (unpolarised) results
!
         iflg=1
         do ir=1,nnr
            roe=rhor(ir,1)
            if(roe.lt.1.0d-30) goto 10
            aroe=abs(roe)
            rs= (3.d0/aroe/fpi)**x13
            if(rs.le.1.d0) then
               rsl=log(rs)
               ecca= a(iflg)*rsl+ b(iflg)+ c(iflg)*rs*rsl+ d(iflg)*rs
               vcca=va(iflg)*rsl+vb(iflg)+vc(iflg)*rs*rsl+vd(iflg)*rs
            else
               rsq=sqrt(rs)
               ecca=g(iflg)/(1.d0+b1(iflg)*rsq+b2(iflg)*rs)
               vcca=ecca*(1.d0+x76*vbt1(iflg)*rsq+x43*vbt2(iflg)*rs)/   &
     &                   (1.d0+    vbt1(iflg)*rsq+    vbt2(iflg)*rs)
            end if
            exc1 = ( ax/rs + ecca )/2.
            exc = exc + exc1*roe
            rhor(ir,1)= ( x43*ax/rs + vcca )/2.
 10         continue
         end do
      else
         isup=1
         isdw=2
         do ir=1,nnr
            roe=rhor(ir,isup)+rhor(ir,isdw)
            if(roe.lt.1.0d-30) goto 20
            aroe=abs(roe)
            rs= (3.d0/aroe/fpi)**x13
            zeta=abs(rhor(ir,isup)-rhor(ir,isdw))/aroe
            zp = (1.d0+zeta)**x13
            onemz=max(0.d0,1.d0-zeta)
            zm = onemz**x13
            fz= ((1.d0+zeta)*zp + onemz*zm - 2.d0)/                     &
     &           (2.d0**x43 -2.d0)
            dfzdz= x43*(zp - zm)/(2.d0**x43-2.d0)
!
! iflg=1:  paramagnetic (unpolarised) results
! iflg=2: ferromagnetic (  polarised) results
!
            if(rs.le.1.d0) then
               rsl=log(rs)
               ecca= a(1)*rsl+ b(1)+ c(1)*rs*rsl+ d(1)*rs
               vcca=va(1)*rsl+vb(1)+vc(1)*rs*rsl+vd(1)*rs
               eccp= a(2)*rsl+ b(2)+ c(2)*rs*rsl+ d(2)*rs
               vccp=va(2)*rsl+vb(2)+vc(2)*rs*rsl+vd(2)*rs
            else
               rsq=sqrt(rs)
               ecca=g(1)/(1.d0+b1(1)*rsq+b2(1)*rs)
               vcca=ecca*(1.d0+x76*vbt1(1)*rsq+x43*vbt2(1)*rs)/         &
     &                   (1.d0+    vbt1(1)*rsq+    vbt2(1)*rs)
               eccp=g(2)/(1.d0+b1(2)*rsq+b2(2)*rs)
               vccp=eccp*(1.d0+x76*vbt1(2)*rsq+x43*vbt2(2)*rs)/         &
     &                   (1.d0+    vbt1(2)*rsq+    vbt2(2)*rs)
            end if
! exchange part
            exc1 = ax/rs*((1.d0+zeta)*zp+(1.d0-zeta)*zm)/2.
            vxc1 = x43*ax/rs*zp
            vxc2 = x43*ax/rs*zm
! correlation part
            vxc1 = vxc1 + vcca + fz*(vccp-vcca)                         &
     &           + dfzdz*(eccp-ecca)*( 1.d0-zeta)
            vxc2 = vxc2 + vcca + fz*(vccp-vcca)                         &
     &           + dfzdz*(eccp-ecca)*(-1.d0-zeta)
            exc  = exc + (exc1 + ecca+fz*(eccp-ecca))*roe/2.
            rhor(ir,isup)=vxc1/2.
            rhor(ir,isdw)=vxc2/2.
 20         continue
         end do
      end if

      call mp_sum( exc )

      return
      end
!
!-----------------------------------------------------------------------
      subroutine force_cc(irb,eigrb,vxc,fion1)
!-----------------------------------------------------------------------
!
!     core correction force: f = \int V_xc(r) (d rhoc(r)/d R_i) dr
!     same logic as in newd - uses box grid. For parallel execution: 
!     the sum over node contributions is done in the calling routine
!
      use core
      use elct, only: nspin
      use gvec
      use gvecb
      use grid_dimensions, only: nr1, nr2, nr3, &
            nnr => nnrx
      use reciprocal_vectors, only: gstart
      use cell_base, only: omega
      use ions_base, only: nsp, nas => nax, na
      use parameters, only: natx, nsx
      use small_box, only: tpibab
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use atom, only: nlcc
      use work_box
      use para_mod
      implicit none
! input
      integer, intent(in)        :: irb(3,natx,nsx)
      complex(kind=8), intent(in):: eigrb(ngb,nas,nsp)
      real(kind=8), intent(in)   :: vxc(nnr,nspin)
! output
      real(kind=8), intent(inout):: fion1(3,natx)
! local
      integer iss, ix, ig, is, ia, nfft, irb3, imin3, imax3, isa
      real(kind=8) fcc(3,natx,nsx), fac, boxdotgrid
      complex(kind=8) ci, facg
      external  boxdotgrid
!
!
      call start_clock( 'forcecc' )
      ci = (0.d0,1.d0)
      fac = omega/dble(nr1*nr2*nr3*nspin)
      fcc = 0.d0
      do is=1,nsp
         if(nlcc(is)) go to 10
#ifdef __PARA
         do ia=1,na(is)
            nfft=1
            irb3=irb(3,ia,is)
            call parabox(nr3b,irb3,nr3,imin3,imax3)
            if (imax3-imin3+1.le.0) go to 15
#else
         do ia=1,na(is),2
!
! two fft's on two atoms at the same time (when possible)
!
            nfft=2
            if(ia.eq.na(is)) nfft=1
#endif
            do ix=1,3
               qv(:) = (0.d0, 0.d0)
               if (nfft.eq.2) then
                  do ig=1,ngb
                     facg = tpibab*cmplx(0.d0,gxb(ix,ig))*rhocb(ig,is)
                     qv(npb(ig)) = eigrb(ig,ia,is)*facg                 &
     &                           + ci * eigrb(ig,ia+1,is)*facg 
                     qv(nmb(ig)) = conjg(eigrb(ig,ia,is)*facg)          &
     &                           + ci * conjg(eigrb(ig,ia+1,is)*facg)
                  end do
               else
                  do ig=1,ngb
                     facg = tpibab*cmplx(0.d0,gxb(ix,ig))*rhocb(ig,is)
                     qv(npb(ig)) = eigrb(ig,ia,is)*facg
                     qv(nmb(ig)) = conjg(eigrb(ig,ia,is)*facg)
                  end do
               end if
!
               call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
! note that a factor 1/2 is hidden in fac if nspin=2 
!
               do iss=1,nspin
                  fcc(ix,ia  ,is) = fcc(ix,ia ,is) + fac *               &
     &                 boxdotgrid(irb(1,ia  ,is),1,qv,vxc(1,iss))
                  if (nfft.eq.2)                                         &
     &               fcc(ix,ia+1,is) = fcc(ix,ia+1,is) + fac *           &
     &                    boxdotgrid(irb(1,ia+1,is),2,qv,vxc(1,iss))
               end do
            end do
15          continue
         end do
10       continue
      end do
!
      isa = 0
      do is = 1, nsp
        do ia = 1, na(is)
          isa = isa + 1
          fion1(:,isa) = fion1(:,isa) + fcc(:,ia,is)
        end do
      end do
!
      call stop_clock( 'forcecc' )
      return
      end
!
!-----------------------------------------------------------------------
      subroutine force_ion(tau0,esr,fion,dsr)
!-----------------------------------------------------------------------
!
!     forces on ions, ionic term in real space (also stress if requested)
!
      use parameters, only: nsx, natx
      use control_flags, only: iprint, tpre
      use constants, only: pi, fpi
      use cell_base, only: ainv, a1, a2, a3
      use ions_base, only: nsp, na, rcmax, zv
      implicit none
! input
      real(kind=8) tau0(3,natx)
! output
      real(kind=8) fion(3,natx), dsr(3,3), esr
! local variables
      integer i,j,k,l,m, ii, lax, inf, isak, isaj
      real(kind=8) rlm(3), rckj, rlmn, arg, addesr, addpre, repand, fxx
      real(kind=8), external :: erfc
!
!
      esr=0.d0
      if(tpre) dsr=0.d0
!
      isak = 0
      do k=1,nsp
         isaj = 0
         do j = 1, k-1
           isaj = isaj + na(j)
         end do
         do j=k,nsp
            rckj=sqrt(rcmax(k)**2+rcmax(j)**2)
            lax=na(k)
            if(k.eq.j) lax=lax-1
!
            do l=1,lax
               inf=1
               if(k.eq.j) inf=l+1
!
               do m=inf,na(j)
                  rlm(1) = tau0(1,l + isak) - tau0(1,m + isaj)
                  rlm(2) = tau0(2,l + isak) - tau0(2,m + isaj)
                  rlm(3) = tau0(3,l + isak) - tau0(3,m + isaj)
                  call pbc(rlm,a1,a2,a3,ainv,rlm)
!
                  rlmn=sqrt(rlm(1)**2+rlm(2)**2+rlm(3)**2)
!
                  arg=rlmn/rckj
                  addesr=zv(k)*zv(j)*erfc(arg)/rlmn
                  esr=esr+addesr
                  addpre=2.d0*zv(k)*zv(j)*exp(-arg*arg)/rckj/sqrt(pi)
                  repand=(addesr+addpre)/rlmn/rlmn
!
                  do i=1,3
                     fxx=repand*rlm(i)
                     fion(i,l+isak)=fion(i,l+isak)+fxx
                     fion(i,m+isaj)=fion(i,m+isaj)-fxx
                     if(tpre)then
                        do ii=1,3
                           dsr(i,ii)=dsr(i,ii)-                         &
     &                             repand*rlm(i)*rlm(1)*ainv(ii,1)-     &
     &                             repand*rlm(i)*rlm(2)*ainv(ii,2)-     &
     &                             repand*rlm(i)*rlm(3)*ainv(ii,3)
                        end do
                     endif
                  end do
               end do
            end do
            isaj = isaj + na(j)
         end do
         isak = isak + na(k)
      end do

      return
      end
!
!-----------------------------------------------------------------------
      subroutine force_ps(rhotemp,rhog,vtemp,ei1,ei2,ei3,fion1)
!-----------------------------------------------------------------------
!
! Contribution to ionic forces from local pseudopotential
!
      use constants, only: pi, fpi
      use elct
      use gvec
      use gvecs
      use reciprocal_vectors, only: gstart
      use cell_base, only: omega
      use ions_base, only: nsp, na, nas => nax
      use grid_dimensions, only: nr1, nr2, nr3
      use parameters, only: nsx, natx
      use pseu
!
      implicit none
! input
      complex(kind=8) rhotemp(ng), rhog(ng,nspin), vtemp(ng),           &
     &           ei1(-nr1:nr1,nas,nsp),                                 &
     &           ei2(-nr2:nr2,nas,nsp),                                 &
     &           ei3(-nr3:nr3,nas,nsp)
! output
      real(kind=8) fion1(3,natx)
! local
      integer ig, is, isa, ism, ia, ix, iss, isup, isdw
      integer i, j, k
      real(kind=8)  wz
      complex(kind=8) eigrx, vcgs, cnvg, cvn
!
!     wz = factor for g.neq.0 because of c*(g)=c(-g)
!
      wz=2.0
      do is=1,nsp
         isa=0
         do ism=1,is-1
            isa=isa+na(ism)
         end do
         do ia=1,na(is)
            isa=isa+1
            do ix=1,3
               if(nspin.eq.1)then
                  iss=1
                  if (gstart == 2) vtemp(1)=0.0
                  do ig=gstart,ngs
                     vcgs=conjg(rhotemp(ig))*fpi/(tpiba2*g(ig))
                     cnvg=rhops(ig,is)*vcgs
                     cvn=vps(ig,is)*conjg(rhog(ig,iss))
                     i = mill_l(1,ig)
                     j = mill_l(2,ig)
                     k = mill_l(3,ig)
                     eigrx=ei1(i,ia,is)*ei2(j,ia,is)*ei3(k,ia,is)
                     vtemp(ig)=eigrx*(cnvg+cvn)*cmplx(0.0,gx(ix,ig)) 
                  end do
               else
                  isup=1
                  isdw=2
                  if (gstart == 2) vtemp(1)=0.0
                  do ig=gstart,ngs
                     vcgs=conjg(rhotemp(ig))*fpi/(tpiba2*g(ig))
                     cnvg=rhops(ig,is)*vcgs
                     cvn=vps(ig,is)*conjg(rhog(ig,isup)                 &
     &                                   +rhog(ig,isdw))
                     i = mill_l(1,ig)
                     j = mill_l(2,ig)
                     k = mill_l(3,ig)
                     eigrx=ei1(i,ia,is)*ei2(j,ia,is)*ei3(k,ia,is)
                     vtemp(ig)=eigrx*(cnvg+cvn)*cmplx(0.0,gx(ix,ig)) 
                  end do
               endif
               fion1(ix,isa) = fion1(ix,isa) + tpiba*omega*         &
     &                             wz*real(SUM(vtemp))
            end do
         end do
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine fwfft(f,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!-----------------------------------------------------------------------
! forward fourier transform of potentials and charge density 
! on the dense grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dfftp
      use fft_scalar, only: cfft3d
      complex(kind=8) f(nr1x*nr2x*nr3x)
      integer nr1,nr2,nr3,nr1x,nr2x,nr3x
      call start_clock( 'fft' )
#ifdef __PARA
      call cfft_cp(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,-1,dfftp)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,-1)
# else
      call cfft3(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,-1)
# endif
#endif
      call stop_clock( 'fft' )
      return
      end
!-----------------------------------------------------------------------
      subroutine fwffts(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!-----------------------------------------------------------------------
! forward fourier transform of potentials and charge density 
! on the smooth grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dffts
      use fft_scalar, only: cfft3d
      complex(kind=8) f(nr1sx*nr2sx*nr3sx)
      integer nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx
      call start_clock( 'ffts' ) 
#ifdef __PARA
      call cfft_cp(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-1,dffts)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-1)
# else
      call cfft3s(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-1)
# endif
#endif
      call stop_clock( 'ffts' ) 
      return
      end
!-----------------------------------------------------------------------
      subroutine fwfftw(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!-----------------------------------------------------------------------
! forward fourier transform of potentials and charge density 
! on the smooth grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dffts
      use fft_scalar, only: cfft3d
      complex(kind=8) f(nr1sx*nr2sx*nr3sx)
      integer nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx
      call start_clock( 'fftw' ) 
#ifdef __PARA
      call cfft_cp(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-2,dffts)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-1)
# else
      call cfft3s(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,-1)
# endif
#endif
      call stop_clock( 'fftw' ) 
      return
      end
!-----------------------------------------------------------------------
      subroutine gausin(eigr,cm)
!-----------------------------------------------------------------------
!
! initialize wavefunctions with gaussians - edit to fit your system
!
      use ions_base, only: nas => nax, na, nsp
      use elct, only: n
      use gvecw, only: ngw
      use gvec
!
      implicit none
!
      complex(kind=8) eigr(ngw,nas,nsp), cm(ngw,n)
      real(kind=8)    sigma, auxf
      integer nband, is, ia, ig
!
      sigma=12.0
      nband=0
!!!      do is=1,nsp
      is=1
         do ia=1,na(is)
! s-like gaussians
            nband=nband+1
            do ig=1,ngw
               auxf=exp(-g(ig)/sigma**2)
               cm(ig,nband)=auxf*eigr(ig,ia,is)
            end do
! px-like gaussians
            nband=nband+1
            do ig=1,ngw
               auxf=exp(-g(ig)/sigma**2)
               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(1,ig)
            end do
! py-like gaussians
            nband=nband+1
            do ig=1,ngw
               auxf=exp(-g(ig)/sigma**2)
               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(2,ig)
            end do
! pz-like gaussians
            nband=nband+1
            do ig=1,ngw
               auxf=exp(-g(ig)/sigma**2)
               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(3,ig)
            end do
         end do
      is=2
         do ia=1,na(is)
! s-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)
!            end do
! px-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(1,ig)
!            end do
! py-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(2,ig)
!            end do
! pz-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(3,ig)
!            end do
! dxy-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(1,ig)*gx(2,ig)
!            end do
! dxz-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(1,ig)*gx(3,ig)
!            end do
! dxy-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*gx(2,ig)*gx(3,ig)
!            end do
! dx2-y2-like gaussians
!            nband=nband+1
!            do ig=1,ngw
!               auxf=exp(-g(ig)/sigma**2)
!               cm(ig,nband)=auxf*eigr(ig,ia,is)*                        &
!     &              (gx(1,ig)**2-gx(2,ig)**2)
!            end do
         end do
!!!      end do
      return
      end
!            

!-------------------------------------------------------------------------
      subroutine gracsc(bec,betae,cp,i,csc)
!-----------------------------------------------------------------------
!     requires in input the updated bec(k) for k<i
!     on output: bec(i) is recalculated
!
      use ions_base, only: na
      use cvan, only :nvb, ish
      use uspp, only :nhsa=>nkb, nhsavb=>nkbus, qq
      use uspp_param, only:  nh
      use elct
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use mp, only: mp_sum
!
      implicit none
!
      integer i
      complex(kind=8) betae(ngw,nhsa)
      real(kind=8)  bec(nhsa,n), cp(2,ngw,n)
      real(kind=8)  csc(nx)
      integer k, kmax,ig, is, iv, jv, ia, inl, jnl
      real(kind=8) rsum, temp(ngw) ! automatic array
!
!     calculate csc(k)=<cp(i)|cp(k)>,  k<i
!
      kmax=i-1
      do k=1,kmax
         csc(k)=0.
         if (ispin(i).eq.ispin(k)) then
            do ig=1,ngw
               temp(ig)=cp(1,ig,k)*cp(1,ig,i)+cp(2,ig,k)*cp(2,ig,i)
            end do
            csc(k)=2.*SUM(temp)
            if (gstart == 2) csc(k)=csc(k)-temp(1)
         endif
      end do

      call mp_sum( csc( 1:kmax ) )

!
!     calculate bec(i)=<cp(i)|beta>
!
      do inl=1,nhsavb
         do ig=1,ngw
            temp(ig)=cp(1,ig,i)* real(betae(ig,inl))+             &
     &               cp(2,ig,i)*aimag(betae(ig,inl))
         end do
         bec(inl,i)=2.*SUM(temp)
         if (gstart == 2) bec(inl,i)= bec(inl,i)-temp(1)
      end do

      call mp_sum( bec( 1:nhsavb, i ) )
!
!     calculate csc(k)=<cp(i)|S|cp(k)>,  k<i
!
      do k=1,kmax
         if (ispin(i).eq.ispin(k)) then
            rsum=0.
            do is=1,nvb
               do iv=1,nh(is)
                  do jv=1,nh(is)
                     if(abs(qq(iv,jv,is)).gt.1.e-5) then 
                        do ia=1,na(is)
                           inl=ish(is)+(iv-1)*na(is)+ia
                           jnl=ish(is)+(jv-1)*na(is)+ia
                           rsum = rsum + qq(iv,jv,is)*bec(inl,i)*bec(jnl,k)
                        end do
                     endif
                  end do
               end do
            end do
            csc(k)=csc(k)+rsum
         endif
      end do
!
!     orthogonalized cp(i) : |cp(i)>=|cp(i)>-\sum_k<i csc(k)|cp(k)>
!
!     corresponing bec:  bec(i)=<cp(i)|beta>-csc(k)<cp(k)|beta>
!
      do k=1,kmax
         do inl=1,nhsavb
            bec(inl,i)=bec(inl,i)-csc(k)*bec(inl,k)
         end do
      end do
!
      return
      end
!-------------------------------------------------------------------------
      subroutine graham(betae,bec,cp)
!-----------------------------------------------------------------------
!     gram-schmidt orthogonalization of the set of wavefunctions cp
!
      use uspp, only :nhsa=>nkb, nhsavb=> nkbus
      use elct
      use gvecw, only: ngw
!
      implicit none
!
      real(kind=8)  bec(nhsa,n)
      complex(kind=8)   cp(ngw,n), betae(ngw,nhsa)
!
      real(kind=8) :: anorm, cscnorm
      real(kind=8), allocatable :: csc( : )
      integer :: i,k
      external :: cscnorm
!
      call start_clock( 'graham' )

      allocate( csc( nx ) )
!
      do i=1,n
         call gracsc(bec,betae,cp,i,csc)
!
! calculate orthogonalized cp(i) : |cp(i)>=|cp(i)>-\sum_k<i csc(k)|cp(k)>
!
         do k=1,i-1
            call DAXPY(2*ngw,-csc(k),cp(1,k),1,cp(1,i),1)
         end do
         anorm =cscnorm(bec,cp,i)
         call DSCAL(2*ngw,1.0/anorm,cp(1,i),1)
!
!         these are the final bec's
!
         call DSCAL(nhsavb,1.0/anorm,bec(1,i),1)
      end do
!
      deallocate( csc )

      call stop_clock( 'graham' )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine herman_skillman_grid(mesh,z,cmesh,r)
!-----------------------------------------------------------------------
!
      implicit none
!
      integer mesh
      real(kind=8) z, cmesh, r(mesh)
!
      real(kind=8) deltax
      integer nblock,i,j,k
!
      nblock = mesh/40
      i=1
      r(i)=0.0
      cmesh=0.88534138/z**(1.0/3.0)
      deltax=0.0025*cmesh
      do j=1,nblock
         do k=1,40
            i=i+1
            r(i)=r(i-1)+deltax
         end do
         deltax=deltax+deltax
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine herman_skillman_int(mesh,cmesh,func,asum)
!-----------------------------------------------------------------------
!     simpsons rule integration for herman skillman mesh
!     mesh - # of mesh points
!     c    - 0.8853418/z**(1/3.)
!
      implicit none
      integer mesh
      real(kind=8) cmesh, func(mesh), asum
!
      integer i, j, k, i1, nblock
      real(kind=8) a1, a2e, a2o, a2es, h
!
      a1=0.0
      a2e=0.0
      asum=0.0
      h=0.0025*cmesh
      nblock=mesh/40
      i=1
      func(1)=0.0
      do j=1,nblock
         do k=1,20
            i=i+2
            i1=i-1
            a2es=a2e
            a2o=func(i1)/12.0
            a2e=func(i)/12.0
            a1=a1+5.0*a2es+8.0*a2o-a2e
            func(i1)=asum+a1*h
            a1=a1-a2es+8.0*a2o+5.0*a2e
            func(i)=asum+a1*h
         end do
         asum=func(i)
         a1=0.0
         h=h+h
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine init1( tau, ibrav, celldm, ecutw, ecut)
!-----------------------------------------------------------------------
!
!     initialize G-vectors and related quantities
!
      use gvec
      use funct, only: dft
      use parameters, only: natx, nsx
      use ions_base, only: pmass, rcmax, nsp, na
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use cell_base, only: ainv, a1, a2, a3
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use elct
      use constants, only: pi, fpi
      use small_box, only: a1b, a2b, a3b, omegab, ainvb, tpibab, small_box_set
      use small_box, only: alatb, b1b, b2b, b3b
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use control_flags, only: iprint
      use gvecw, only: ggp, agg => ecutz, sgg => ecsig, e0gg => ecfix
      use gvecb, only: gvecb_set, gcutb
      USE reciprocal_vectors, ONLY : mill_g, g2_g
      use fft_scalar, only: good_fft_dimension, good_fft_order
      use constants, only: scmass
      use cell_base, only: omega, alat
      use io_global, only: stdout
      USE grid_subroutines, ONLY: realspace_grids_init, realspace_grids_para
      USE fft_base, ONLY: dfftp, dffts, fft_dlay_descriptor
      USE stick_base, ONLY: pstickset

      implicit none
! 
      integer ibrav
      real(kind=8) tau(3,natx), celldm(6), ecut
!
      integer idum, ik, k, iss, i, in, is, ia, isat
      real(kind=8) gcut, gcutw, gcuts, ecutw, dual, fsum, ocp, ddum
      real(kind=8) qk(3), rat1, rat2, rat3
      real(kind=8) b1(3), b2(3), b3(3)
      integer :: ng_ , ngs_ , ngm_ , ngw_

!
!     ==============================================================
!     ==== set parameters and cutoffs                           ==== 
!     ==============================================================
!
      dual   = 4.d0
      tpiba  = 2.d0 * pi/alat
      tpiba2 = tpiba*tpiba
      gcutw  = ecutw/tpiba/tpiba
      gcuts  = dual*gcutw
      gcut   = ecut/tpiba/tpiba
!
!     ===================================================
!     ==== initialization for fft                    ====
!     ===================================================
!
      CALL realspace_grids_init( alat, a1, a2, a3, gcut, gcuts, ng_ , ngs_ )

!
!     ===================================================
!     ==== cell dimensions and lattice vectors      =====
!     ===================================================
!
! a1,a2,a3  are the crystal axis (the vectors generating the lattice)
! b1,b2,b3  are reciprocal crystal axis
!
      call recips( a1, a2, a3, b1, b2, b3 )
      b1 = b1 * alat
      b2 = b2 * alat
      b3 = b3 * alat

      WRITE( stdout,*)
      WRITE( stdout,210) 
210   format(' unit vectors of full simulation cell',/,                 &
     &       ' in real space:',25x,'in reciprocal space:')
      WRITE( stdout,'(3f10.4,10x,3f10.4)') a1,b1
      WRITE( stdout,'(3f10.4,10x,3f10.4)') a2,b2
      WRITE( stdout,'(3f10.4,10x,3f10.4)') a3,b3

!     Store the base vectors used to generate the reciprocal space
      bi1 = b1 / alat
      bi2 = b2 / alat
      bi3 = b3 / alat

!
! b1,b2,b3  are the 3 basis vectors generating the reciprocal lattice
!           in 2pi/alat units
!
      do i=1,3
         ainv(1,i)=b1(i)/alat
         ainv(2,i)=b2(i)/alat
         ainv(3,i)=b3(i)/alat
      end do
!
! ainv  is transformation matrix from cartesian to crystal coordinates
!       if r=x1*a1+x2*a2+x3*a3 => x(i)=sum_j ainv(i,j)r(j)
!       Note that ainv is really the inverse of a=(a1,a2,a3)
!       (but only if the axis triplet is right-handed, otherwise
!        for a left-handed triplet, ainv is minus the inverse of a)
!


      CALL pstickset( dfftp, dffts, alat, a1, a2, a3, gcut, gcutw, gcuts, &
        nr1, nr2, nr3, nr1x, nr2x, nr3x, nr1s, nr2s, nr3s, nr1sx, nr2sx,   &
        nr3sx, ngw_ , ngm_ , ngs_ )

!
      CALL realspace_grids_para( dfftp, dffts )
!
!
!     ==============================================================
!     ==== generate g-space                                     ==== 
!     ==============================================================
      call ggencp                                                       &
     &     ( b1, b2, b3, nr1, nr2, nr3, nr1s, nr2s, nr3s,               &
     &       gcut, gcuts, gcutw, .TRUE. )

      !  global arrays are no more needed

      if( allocated( g2_g ) )   deallocate( g2_g )
      if( allocated( mill_g ) ) deallocate( mill_g )
!
!     ==============================================================
!     generation of little box g-vectors
!     ==============================================================
!
      !  sets the small box parameters

      rat1 = DBLE( nr1b ) / DBLE( nr1 )
      rat2 = DBLE( nr2b ) / DBLE( nr2 )
      rat3 = DBLE( nr3b ) / DBLE( nr3 )
      CALL small_box_set( alat, omega, a1, a2, a3, rat1, rat2, rat3 )

      !  now set gcutb

      gcutb = ecut / tpibab / tpibab
!
      CALL ggenb ( b1b, b2b, b3b, nr1b, nr2b, nr3b, nr1bx, nr2bx, nr3bx, gcutb )
!
!     ==============================================================
!
      WRITE( stdout,34) ibrav,alat,omega,gcut,gcuts,gcutw,1
      WRITE( stdout,81) nr1, nr2, nr3, nr1x, nr2x, nr3x,                      &
     &            nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,                     &
     &            nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx
!
      WRITE( stdout,38) dft
      WRITE( stdout,334) ecutw, dual * ecutw, ecut
!
      if(nspin.eq.1)then
         WRITE( stdout,6) nel(1),n
         WRITE( stdout,166) nspin
         WRITE( stdout,74)
         WRITE( stdout,77) (f(i),i=1,n)
      else
         WRITE( stdout,7) nel(1),nel(2), n
         WRITE( stdout,167) nspin,nupdwn(1),nupdwn(2)
         WRITE( stdout,75) 
         WRITE( stdout,77) (f(i),i=iupdwn(1),nupdwn(1))
         WRITE( stdout,76) 
         WRITE( stdout,77) (f(i),i=iupdwn(2),iupdwn(2)-1+nupdwn(2))
      endif
      WRITE( stdout,878) nsp
      isat = 0
      do is=1,nsp
         WRITE( stdout,33) is, na(is), pmass(is)/scmass, rcmax(is)
         WRITE( stdout,9)
         do ia = ( 1 + isat ), ( na(is) + isat )
            WRITE( stdout,555) ( tau(k,ia), k = 1, 3 )
         end do
         isat = isat + na(is)
 555     format((4x,3(1x,f6.2)))
      end do
!
!
   33 format(' is=',i3,/,'  na=',i4,                                    &
     &       '  atomic mass=',f6.2,' gaussian rcmax=',f6.2)
   34 format(' initialization ',//,                                     &
     &       ' ibrav=',i3,' alat=',f7.3,' omega=',f10.4,                &
     &       /,' gcut=',f8.2,3x,' gcuts=',                              &
     &       f8.2,' gcutw=',f8.2,/,                                     &
     &       ' k-points: nkpt=',i2,//)
   81 format(' meshes:',/,                                              &
     &       '  dense grid: nr1 ,nr2, nr3  = ',3i4,                     &
     &                   '  nr1x, nr2x, nr3x = ',3i4,/,                 &
     &       ' smooth grid: nr1s,nr2s,nr3s = ',3i4,                     &
     &                   '  nr1sx,nr2sx,nr3sx= ',3i4,/,                 &
     &       '    box grid: nr1b,nr2b,nr3b = ',3i4,                     &
     &                   '  nr1bx,nr2bx,nr3bx= ',3i4,/)
    6 format(/' # of electrons=',i5,' # of states=',i5,/)
    7 format(/' # of up electrons=',i5,'  of down electrons=',i5,         &
              ' # of states=',i5,/)
   38 format(' exchange-correlation potential: ',a20/)
  334 format(' ecutw=',f7.1,' ryd',3x,                                  &
     &       ' ecuts=',f7.1,' ryd',3x,' ecut=',f7.1,' ryd')
  166 format(/,' nspin=',i2)
  167 format(/,' nspin=',i2,5x,' nup=',i5,5x,' ndown=',i5)
   74 format(' occupation numbers:')
   75 format(' occupation numbers up:')
   76 format(' occupation numbers down:')
   77 format(20f4.1)
  878 format(/' # of atomic species',i5)
    9 format(' atomic coordinates:')
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine initbox ( tau0, taub, irb )
!-----------------------------------------------------------------------
!
!     sets the indexes irb and positions taub for the small boxes 
!     around atoms
!
      use parameters, only: natx, nsx
      use ions_base, only: nsp, na
      use grid_dimensions, only: nr1, nr2, nr3
      use cell_base, only: ainv, a1, a2, a3
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b
      use control_flags, only: iprsta
      use cvan, only: nvb
      use io_global, only: stdout

      implicit none
! input
      real(kind=8), intent(in):: tau0(3,natx)
! output
      integer, intent(out):: irb(3,natx,nsx)
      real(kind=8), intent(out):: taub(3,natx)
! local
      real(kind=8) x(3), xmod
      integer nr(3), nrb(3), xint, is, ia, i, isa
!
      nr (1)=nr1
      nr (2)=nr2
      nr (3)=nr3
      nrb(1)=nr1b
      nrb(2)=nr2b
      nrb(3)=nr3b
!
      isa = 0
      do is=1,nsp
         do ia=1,na(is)
           isa = isa + 1
!
            do i=1,3
!
! bring atomic positions to crystal axis
!
               x(i) = ainv(i,1)*tau0(1,isa) +                         &
     &                ainv(i,2)*tau0(2,isa) +                         &
     &                ainv(i,3)*tau0(3,isa)
!
! bring x in the range between 0 and 1
!
               x(i) = mod(x(i),1.d0)
               if (x(i).lt.0.d0) x(i)=x(i)+1.d0
!
! case of nrb(i) even
!
               if (mod(nrb(i),2).eq.0) then
!
! find irb = index of the grid point at the corner of the small box
!           (the indices of the small box run from irb to irb+nrb-1)
!
                  xint=int(x(i)*nr(i))
                  irb (i,ia,is)=xint+1-nrb(i)/2+1
                  if(irb(i,ia,is).lt.1) irb(i,ia,is)=irb(i,ia,is)+nr(i)
!
! x(i) are the atomic positions in crystal coordinates, where the
! "crystal lattice" is the small box lattice and the origin is at
! the corner of the small box. Used to calculate phases exp(iG*taub)
!
                  xmod=x(i)*nr(i)-xint
                  x(i)=(xmod+nrb(i)/2-1)/nr(i)
               else
!
! case of nrb(i) odd - see above for comments
!
                  xint=nint(x(i)*nr(i))
                  irb (i,ia,is)=xint+1-(nrb(i)-1)/2
                  if(irb(i,ia,is).lt.1) irb(i,ia,is)=irb(i,ia,is)+nr(i)
                  xmod=x(i)*nr(i)-xint
                  x(i)=(xmod+(nrb(i)-1)/2)/nr(i)
               end if
            end do
!
! bring back taub in cartesian coordinates
!
            do i=1,3
               taub(i,isa)= x(1)*a1(i) + x(2)*a2(i) + x(3)*a3(i)
            end do
         end do
      end do

      if( iprsta > 2 ) then
           do is=1,nvb
              WRITE( stdout,'(/,2x,''species= '',i2)') is
              do ia=1,na(is)
                 WRITE( stdout,2000) ia, (irb(i,ia,is),i=1,3)
2000             format(2x,'atom= ',i3,' irb1= ',i3,' irb2= ',i3,' irb3= ',i3)
               end do
            end do
      endif

!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine invfft(f,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!-----------------------------------------------------------------------
! inverse fourier transform of potentials and charge density 
! on the dense grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dfftp
      use fft_scalar, only: cfft3d

      complex(kind=8) f(nr1x*nr2x*nr3x)
      integer nr1,nr2,nr3,nr1x,nr2x,nr3x
      call start_clock( 'fft' )
#ifdef __PARA
      call cfft_cp(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,1,dfftp)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,1)
# else
      call cfft3(f,nr1,nr2,nr3,nr1x,nr2x,nr3x,1)
# endif
#endif
      call stop_clock( 'fft' )
!
      return
      end 
!-----------------------------------------------------------------------
      subroutine ivfftb(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!-----------------------------------------------------------------------
! inverse fourier transform of Q functions (Vanderbilt pseudopotentials)
! on the  box grid . On output, f is overwritten
!
      use fft_scalar, only: cfft3d
      integer nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3
      complex(kind=8) f(nr1bx*nr2bx*nr3bx)

!     in a parallel execution, not all processors calls this routine
!     then we should avoid clocks, otherwise the program hangs in print_clock 
#if ! defined __PARA
      call start_clock( 'fftb' )
#endif

#ifdef __PARA
      call cfftpb(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3,1)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,1)
# else
      call cfft3b(f,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,1)
# endif
#endif

#if ! defined __PARA
      call stop_clock( 'fftb' )
#endif
!
      return
      end
!-----------------------------------------------------------------------
      subroutine ivffts(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!-----------------------------------------------------------------------
! inverse fourier transform of  potentials and charge density
! on the smooth grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dffts
      use fft_scalar, only: cfft3d
      complex(kind=8) f(nr1sx*nr2sx*nr3sx)
      integer nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx
      call start_clock( 'ffts' )
#ifdef __PARA
      call cfft_cp(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,1,dffts)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,1)
# else
      call cfft3s(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,1)
# endif 
#endif
      call stop_clock( 'ffts' )
!
      return
      end
!-----------------------------------------------------------------------
      subroutine ivfftw(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!-----------------------------------------------------------------------
! inverse fourier transform of wavefunctions 
! on the smooth grid . On output, f is overwritten
!
      use fft_cp, only: cfft_cp
      use para_mod, only: dffts
      use fft_scalar, only: cfft3d
      complex(kind=8) f(nr1sx*nr2sx*nr3sx)
      integer nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx
      call start_clock('fftw')
#ifdef __PARA
      call cfft_cp(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,2,dffts)
#else
# if defined __AIX || __FFTW || __COMPLIB || __SCSL
      call cfft3d(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,1)
# else
      call cfft3s(f,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx,1)
# endif
#endif
      call stop_clock('fftw')
!
      return
      end
!
!-------------------------------------------------------------------------
      subroutine newd(vr,irb,eigrb,rhovan,fion)
!-----------------------------------------------------------------------
!     this routine calculates array deeq:
!         deeq_i,lm = \int V_eff(r) q_i,lm(r) dr
!     and the corresponding term in forces
!         fion_i = \int V_eff(r) \sum_lm rho_lm (dq_i,lm(r)/dR_i) dr
!     where
!         rho_lm = \sum_j f_j <psi_j|beta_l><beta_m|psi_j>
!
      use uspp_param, only: nh, nhm
      use uspp, only: deeq
      use cvan, only: nvb
      use ions_base, only: nas => nax, nat, nsp, na
      use parameters, only: natx, nsx
      use constants, only: pi, fpi
      use grid_dimensions, only: nr3, nnr => nnrx
      use gvecb
      use small_box, only: omegab, tpibab
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use qgb_mod
      use elct
      use control_flags, only: iprint, thdyn, tfor, tprnfor
      use work_box
      use para_mod
      use mp, only: mp_sum
!
      implicit none
! input
      integer irb(3,natx,nsx)
      real(kind=8) rhovan(nhm*(nhm+1)/2,nat,nspin)
      complex(kind=8) eigrb(ngb,nas,nsp)
      real(kind=8)  vr(nnr,nspin)
! output
      real(kind=8)  fion(3,natx)
! local
      integer isup,isdw,iss, iv,ijv,jv, ik, nfft, isa, ia, is, ig
      integer irb3, imin3, imax3
      real(kind=8)  fvan(3,natx,nsx), fac, fac1, fac2, boxdotgrid
      complex(kind=8) ci, facg1, facg2
      external boxdotgrid
!
      call start_clock( 'newd' )
      ci=(0.d0,1.d0)
      fac=omegab/float(nr1b*nr2b*nr3b)
      deeq (:,:,:,:) = 0.d0
      fvan (:,:,:) = 0.d0
!
! calculation of deeq_i,lm = \int V_eff(r) q_i,lm(r) dr
!
      isa=1
      do is=1,nvb
#ifdef __PARA
         do ia=1,na(is)
            nfft=1
            irb3=irb(3,ia,is)
            call parabox(nr3b,irb3,nr3,imin3,imax3)
            if (imax3-imin3+1.le.0) go to 15
#else
         do ia=1,na(is),2
            nfft=2
#endif
            if(ia.eq.na(is)) nfft=1
!
! two ffts at the same time, on two atoms (if possible: nfft=2)
!
            ijv=0
            do iv=1,nh(is)
               do jv=iv,nh(is)
                  ijv=ijv+1
                  qv(:) = (0.d0, 0.d0)
                  if (nfft.eq.2) then
                     do ig=1,ngb
                        qv(npb(ig))= eigrb(ig,ia  ,is)*qgb(ig,ijv,is)   &
     &                          + ci*eigrb(ig,ia+1,is)*qgb(ig,ijv,is)
                        qv(nmb(ig))= conjg(                             &
     &                               eigrb(ig,ia  ,is)*qgb(ig,ijv,is))  &
     &                          + ci*conjg(                             &
     &                               eigrb(ig,ia+1,is)*qgb(ig,ijv,is))
                     end do
                  else
                     do ig=1,ngb
                        qv(npb(ig)) = eigrb(ig,ia,is)*qgb(ig,ijv,is)
                        qv(nmb(ig)) = conjg(                            &
     &                                eigrb(ig,ia,is)*qgb(ig,ijv,is))
                     end do
                  end if
!
                  call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
                  do iss=1,nspin
                     deeq(iv,jv,isa,iss) = fac *                        &
     &                    boxdotgrid(irb(1,ia,is),1,qv,vr(1,iss))
                     if (iv.ne.jv)                                      &
     &                    deeq(jv,iv,isa,iss)=deeq(iv,jv,isa,iss)
!
                     if (nfft.eq.2) then
                        deeq(iv,jv,isa+1,iss) = fac*                    &
     &                       boxdotgrid(irb(1,ia+1,is),2,qv,vr(1,iss))
                        if (iv.ne.jv)                                   &
     &                       deeq(jv,iv,isa+1,iss)=deeq(iv,jv,isa+1,iss)
                     end if
                  end do
               end do
            end do
  15        isa=isa+nfft
         end do
      end do

      call reduce(nat*nhm*nhm*nspin,deeq)

      if (.not.( tfor .or. thdyn .or. tprnfor ) ) go to 10
!
! calculation of fion_i = \int V_eff(r) \sum_lm rho_lm (dq_i,lm(r)/dR_i) dr
!
      isa=1
      if(nspin.eq.1) then
!     =================================================================
!     case nspin=1: two ffts at the same time, on two atoms (if possible)
!     -----------------------------------------------------------------
         iss=1
         isa=1
         do is=1,nvb
#ifdef __PARA
            do ia=1,na(is)
               nfft=1
               irb3=irb(3,ia,is)
               call parabox(nr3b,irb3,nr3,imin3,imax3)
               if (imax3-imin3+1.le.0) go to 20
#else
            do ia=1,na(is),2
               nfft=2
#endif
               if( ia.eq.na(is)) nfft=1
               do ik=1,3
                  qv(:) = (0.d0, 0.d0)
                  ijv=0
                  do iv=1,nh(is)
                     do jv=iv,nh(is)
                        ijv=ijv+1
                        if(iv.ne.jv) then
                           fac1=2.d0*fac*tpibab*rhovan(ijv,isa,iss)
                           if (nfft.eq.2) fac2=2.d0*fac*tpibab*         &
     &                                           rhovan(ijv,isa+1,iss)
                        else
                           fac1=     fac*tpibab*rhovan(ijv,isa,iss)
                           if (nfft.eq.2) fac2=     fac*tpibab*        &
     &                                           rhovan(ijv,isa+1,iss)
                        endif
                        if (nfft.eq.2) then
                           do ig=1,ngb
                              facg1 = cmplx(0.d0,-gxb(ik,ig)) *         &
     &                                   qgb(ig,ijv,is) * fac1
                              facg2 = cmplx(0.d0,-gxb(ik,ig)) *         &
     &                                   qgb(ig,ijv,is) * fac2
                              qv(npb(ig)) = qv(npb(ig))                 &
     &                                    +    eigrb(ig,ia  ,is)*facg1  &
     &                                    + ci*eigrb(ig,ia+1,is)*facg2
                              qv(nmb(ig)) = qv(nmb(ig))                 &
     &                                +   conjg(eigrb(ig,ia  ,is)*facg1)&
     &                                +ci*conjg(eigrb(ig,ia+1,is)*facg2)
                           end do
                        else
                           do ig=1,ngb
                              facg1 = cmplx(0.d0,-gxb(ik,ig)) *         &
     &                                   qgb(ig,ijv,is)*fac1
                              qv(npb(ig)) = qv(npb(ig))                 &
     &                                    +    eigrb(ig,ia,is)*facg1
                              qv(nmb(ig)) = qv(nmb(ig))                 &
     &                               +  conjg( eigrb(ig,ia,is)*facg1)
                           end do
                        end if
                     end do
                  end do
!
                  call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
                  fvan(ik,ia,is) =                                      &
     &                    boxdotgrid(irb(1,ia,is),1,qv,vr(1,iss))
!
                  if (nfft.eq.2) fvan(ik,ia+1,is) =                     &
     &                    boxdotgrid(irb(1,ia+1,is),2,qv,vr(1,iss))
               end do
 20            isa = isa+nfft
            end do
         end do
      else
!     =================================================================
!     case nspin=2: up and down spin fft's combined into a single fft
!     -----------------------------------------------------------------
         isup=1
         isdw=2
         isa=1
         do is=1,nvb
            do ia=1,na(is)
#ifdef __PARA
               irb3=irb(3,ia,is)
               call parabox(nr3b,irb3,nr3,imin3,imax3)
               if (imax3-imin3+1.le.0) go to 25
#endif
               do ik=1,3
                  qv(:) = (0.d0, 0.d0)
                  ijv=0
!
                  do iv=1,nh(is)
                     do jv=iv,nh(is)
                        ijv=ijv+1
                        if(iv.ne.jv) then
                           fac1=2.d0*fac*tpibab*rhovan(ijv,isa,isup)
                           fac2=2.d0*fac*tpibab*rhovan(ijv,isa,isdw)
                        else
                           fac1=     fac*tpibab*rhovan(ijv,isa,isup)
                           fac2=     fac*tpibab*rhovan(ijv,isa,isdw)
                        end if
                        do ig=1,ngb
                           facg1 = fac1 * cmplx(0.d0,-gxb(ik,ig)) *     &
     &                                qgb(ig,ijv,is) * eigrb(ig,ia,is)
                           facg2 = fac2 * cmplx(0.d0,-gxb(ik,ig)) *     &
     &                                qgb(ig,ijv,is) * eigrb(ig,ia,is)
                           qv(npb(ig)) = qv(npb(ig))                    &
     &                                    + facg1 + ci*facg2
                           qv(nmb(ig)) = qv(nmb(ig))                    &
     &                                    +conjg(facg1)+ci*conjg(facg2)
                        end do
                     end do
                  end do
!
                  call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
                  fvan(ik,ia,is) =                                      &
     &                    boxdotgrid(irb(1,ia,is),isup,qv,vr(1,isup)) + &
     &                    boxdotgrid(irb(1,ia,is),isdw,qv,vr(1,isdw))
               end do
25             isa = isa+1
            end do
         end do
      end if

      call reduce(3*natx*nvb,fvan)

      isa = 0
      DO is = 1, nvb
        DO ia = 1, na(is)
          isa = isa + 1
          fion(:,isa) = fion(:,isa) - fvan(:,ia,is)
        END DO
      END DO
!
  10  call stop_clock( 'newd' )
!
      return
      end
!-------------------------------------------------------------------------
      subroutine nlfl(bec,becdr,lambda,fion)
!-----------------------------------------------------------------------
!     contribution to fion due to the orthonormality constraint
! 
!
      use io_global, only: stdout
      use ions_base, only: na, nsp
      use parameters, only: natx
      use gvec
      use uspp, only :nhsa=>nkb, qq
      use uspp_param, only: nhm, nh
      use cvan, only: ish, nvb
      use elct
      use constants, only: pi, fpi
!
      implicit none
      real(kind=8) bec(nhsa,n), becdr(nhsa,n,3), lambda(nx,nx)
      real(kind=8) fion(3,natx)
!
      integer k, is, ia, iv, jv, i, j, inl, isa
      real(kind=8) temp(nx,nx), tmpbec(nhm,nx),tmpdr(nx,nhm) ! automatic arrays
!
      call start_clock( 'nlfl' )
      do k=1,3
         isa = 0
         do is=1,nvb
            do ia=1,na(is)
               isa = isa + 1
!
               tmpbec = 0.d0
               tmpdr  = 0.d0
!
               do iv=1,nh(is)
                  do jv=1,nh(is)
                     inl=ish(is)+(jv-1)*na(is)+ia
                     if(abs(qq(iv,jv,is)).gt.1.e-5) then
                        do i=1,n
                           tmpbec(iv,i)=tmpbec(iv,i)                    &
     &                          + qq(iv,jv,is)*bec(inl,i)
                        end do
                     endif
                  end do
               end do
!
               do iv=1,nh(is)
                  inl=ish(is)+(iv-1)*na(is)+ia
                  do i=1,n
                     tmpdr(i,iv)=becdr(inl,i,k)
                  end do
               end do
!
               if(nh(is).gt.0)then
                  temp = 0.d0
!
                  call MXMA                                             &
     &                 (tmpdr,1,nx,tmpbec,1,nhm,temp,1,nx,n,nh(is),n)
!
                  do j=1,n
                     do i=1,n
                        temp(i,j)=temp(i,j)*lambda(i,j)
                     end do
                  end do
!
                  fion(k,isa)=fion(k,isa)+2.*SUM(temp)
               endif
!
            end do
         end do
      end do
!
!     end of x/y/z loop
!
      call stop_clock( 'nlfl' )
      return
      end
!-----------------------------------------------------------------------
      subroutine nlfq(c,eigr,bec,becdr,fion)
!-----------------------------------------------------------------------
!     contribution to fion due to nonlocal part
!
      use gvec
      use uspp, only :nhsa=>nkb, dvan, deeq
      use uspp_param, only: nhm, nh
      use cvan, only: ish, nvb
      use ions_base, only: nas => nax, nat, nsp, na
      use parameters, only: natx, nsx
      use elct
      use gvecw, only: ngw
      use constants, only: pi, fpi
      !use parm
! 
      implicit none
      real(kind=8) bec(nhsa,n), becdr(nhsa,n,3), c(2,ngw,n)
      complex(kind=8) eigr(ngw,nas,nsp)
      real(kind=8) fion(3,natx)
!
      integer k, is, ia, isa, iss, inl, iv, jv, i
      real(kind=8) tmpbec(nhm,n), tmpdr(nhm,n) ! automatic arrays
      real(kind=8) temp
!
!     nlsm2 fills becdr
!
      call start_clock( 'nlfq' )
      call nlsm2(eigr,c,becdr)
!
      do k=1,3
!
         isa=0
         do is=1,nsp
            do ia=1,na(is)
               isa=isa+1
!
               tmpbec = 0.d0
               tmpdr  = 0.d0
!
               do iv=1,nh(is)
                  do jv=1,nh(is)
                     inl=ish(is)+(jv-1)*na(is)+ia
                     do i=1,n
                        iss=ispin(i)
                        temp=dvan(iv,jv,is)+deeq(jv,iv,isa,iss)
                        tmpbec(iv,i)=tmpbec(iv,i)+temp*bec(inl,i)
                     end do
                  end do
               end do
!  
               do iv=1,nh(is)
                  inl=ish(is)+(iv-1)*na(is)+ia
                  do i=1,n
                     tmpdr(iv,i)=f(i)*becdr(inl,i,k)
                  end do
               end do
!
               do i=1,n
                  do iv=1,nh(is)
                     tmpdr(iv,i)=tmpdr(iv,i)*tmpbec(iv,i)
                  end do
               end do
!
               fion(k,isa)=fion(k,isa)-2.*SUM(tmpdr)
!
            end do
         end do
      end do
!
!     end of x/y/z loop
!
      call stop_clock( 'nlfq' )
!
      return
      end
!-----------------------------------------------------------------------
      subroutine nlsm1 (n,nspmn,nspmx,eigr,c,becp)
!-----------------------------------------------------------------------
!     computes: the array becp
!     becp(ia,n,iv,is)=
!         = sum_g [(-i)**l beta(g,iv,is) e^(-ig.r_ia)]^* c(g,n)
!         = delta_l0 beta(g=0,iv,is) c(g=0,n)
!          +sum_g> beta(g,iv,is) 2 re[(i)**l e^(ig.r_ia) c(g,n)]
!
!     routine makes use of c*(g)=c(-g)  (g> see routine ggen)
!     input : beta(ig,l,is), eigr, c
!     output: becp as parameter
!
      use ions_base, only: na, nas => nax
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use constants, only: pi, fpi
      use uspp, only :nhsa=>nkb, nhtol, beta
      use cvan, only: ish
      use uspp_param, only: nh
      use work, only: wrk2
!
      implicit none
      integer n, nspmn, nspmx
      real(kind=8)  eigr(2,ngw,nas,nspmx), c(2,ngw,n)
      real(kind=8)  becp(nhsa,n)
!
      integer ig, is, iv, ia, l, ixr, ixi, inl, i
      real(kind=8) signre, signim, arg
!
      call start_clock( 'nlsm1' )
      do is=nspmn,nspmx
         do iv=1,nh(is)
            l=nhtol(iv,is)
            if (l == 0) then
               ixr = 1
               ixi = 2
               signre =  1.0
               signim =  1.0
            else if (l == 1) then
               ixr = 2
               ixi = 1
               signre =  1.0
               signim = -1.0
            else if (l == 2) then
               ixr = 1
               ixi = 2
               signre = -1.0
               signim = -1.0
            else if (l == 3) then
               ixr = 2
               ixi = 1
               signre = -1.0
               signim =  1.0
            endif
!
            do ia=1,na(is)
               if (gstart == 2) then
!                   q = 0   component (with weight 1.0)
                  wrk2(1,ia)= cmplx(                                   &
     &               signre*beta(1,iv,is)*eigr(ixr,1,ia,is),           &
     &               signim*beta(1,iv,is)*eigr(ixi,1,ia,is) )
!                   q > 0   components (with weight 2.0)
               end if
               do ig=gstart,ngw
                  arg = 2.0*beta(ig,iv,is)
                  wrk2(ig,ia) = cmplx(                                 &
     &                  signre*arg*eigr(ixr,ig,ia,is),                 &
     &                  signim*arg*eigr(ixi,ig,ia,is) )
               end do
            end do
            inl=ish(is)+(iv-1)*na(is)+1
            call MXMA(wrk2,2*ngw,1,c,1,2*ngw,becp(inl,1),1,nhsa,       &
     &           na(is),2*ngw,n)
         end do

#ifdef __PARA
         inl=ish(is)+1
         do i=1,n
            call reduce(na(is)*nh(is),becp(inl,i))
         end do
#endif

      end do
      call stop_clock( 'nlsm1' )
      return
      end
!-------------------------------------------------------------------------
      subroutine nlsm2(eigr,c,becdr)
!-----------------------------------------------------------------------
!     computes: the array becdr 
!     becdr(ia,n,iv,is,k)
!      =2.0 sum_g> g_k beta(g,iv,is) re[ (i)**(l+1) e^(ig.r_ia) c(g,n)]
! 
!     routine makes use of  c*(g)=c(-g)  (g> see routine ggen)
!     input : eigr, c
!     output: becdr
!
      use ions_base, only: nas => nax, nsp, na
      use elct
      use gvec
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use constants, only: pi, fpi
      use uspp, only :nhsa=>nkb, nhtol, beta
      use cvan, only: ish
      use uspp_param, only: nh
      use work, only: wrk2
!
      implicit none
      real(kind=8)  eigr(2,ngw,nas,nsp),c(2,ngw,n), becdr(nhsa,n,3)
      integer ig, is, iv, ia, k, l, ixr, ixi, inl
      real(kind=8) signre, signim, arg
      real(kind=8), allocatable:: gk(:)
!
      call start_clock( 'nlsm2' )
      allocate(gk(ngw))
      becdr = 0.d0
!
      do k=1,3
         do ig=1,ngw
            gk(ig)=gx(k,ig)*tpiba
         end do
!
         do is=1,nsp
            do iv=1,nh(is)
!
!     order of states:  s_1  p_x1  p_z1  p_y1  s_2  p_x2  p_z2  p_y2
!
               l=nhtol(iv,is)
               if (l.eq.0) then
                  ixr = 2
                  ixi = 1
                  signre =  1.0
                  signim = -1.0
               else if (l.eq.1) then
                  ixr = 1
                  ixi = 2
                  signre = -1.0
                  signim = -1.0
               else if (l.eq.2) then
                  ixr = 2
                  ixi = 1
                  signre = -1.0
                  signim =  1.0
               else if (l == 3) then
                  ixr = 1
                  ixi = 2
                  signre =  1.0
                  signim =  1.0
               endif
!     
               do ia=1,na(is)
                  if (gstart == 2) then
!                             q = 0   component (with weight 1.0)
                     wrk2(1,ia) = cmplx (                               &
     &                  signre*gk(1)*beta(1,iv,is)*eigr(ixr,1,ia,is),   &
     &                  signim*gk(1)*beta(1,iv,is)*eigr(ixi,1,ia,is) )
!                            q > 0   components (with weight 2.0)
                  end if
                  do ig=gstart,ngw
                     arg = 2.0*gk(ig)*beta(ig,iv,is)
                     wrk2(ig,ia) = cmplx (                              &
    &                     signre*arg*eigr(ixr,ig,ia,is),                &
    &                     signim*arg*eigr(ixi,ig,ia,is) )
                  end do
               end do
               inl=ish(is)+(iv-1)*na(is)+1
               call MXMA(wrk2,2*ngw,1,c,1,2*ngw,becdr(inl,1,k),1,       &
     &                   nhsa,na(is),2*ngw,n)
            end do
         end do
      end do

      call reduce(3*nhsa*n,becdr)

      deallocate(gk)
      call stop_clock( 'nlsm2' )
!
      return
      end
!-----------------------------------------------------------------------
      subroutine ortho                                                  &
     &      (eigr,cp,phi,x0,diff,iter,ccc,eps,max,delt,bephi,becp)
!-----------------------------------------------------------------------
!     input = cp (non-orthonormal), beta
!     input = phi |phi>=s'|c0>
!     output= cp (orthonormal with s( r(t+dt) ) )
!     output= bephi, becp
!     the method used is similar to the version in les houches 1988
!     'simple molecular systems at..'  p. 462-463  (18-22)
!      xcx + b x + b^t x^t + a = 1
!     where c = <s'c0|s|s'c0>   b = <s'c0|s cp>   a = <cp|s|cp>
!     where s=s(r(t+dt)) and s'=s(r(t))  
!     for vanderbilt pseudo pot - kl & ap
!
      use ions_base, only: na, nsp, nas => nax
      use cvan, only: ish, nvb
      use uspp, only :nhsa=>nkb, qq
      use uspp_param, only: nh
      use elct
      use gvecw, only: ngw
      use control_flags, only: iprint, iprsta
      use io_global, only: stdout
!
      implicit none
!
      complex(kind=8)   cp(ngw,n), phi(ngw,n), eigr(ngw,nas,nsp)
      real(kind=8) x0(nx,nx), diff, ccc, eps, delt
      integer iter, max
      real(kind=8) bephi(nhsa,n), becp(nhsa,n)
!
      real(kind=8) diag(nx),work1(nx),work2(nx),                        &
     &     xloc(nx,nx),tmp1(nx,nx),tmp2(nx,nx),dd(nx,nx),               &
     &     x1(nx,nx),rhos(nx,nx),rhor(nx,nx),con(nx,nx),  u(nx,nx)
      real(kind=8) sig(nx,nx), rho(nx,nx), tau(nx,nx)
! the above are all automatic arrays
      integer istart, nss, ifail, i, j, iss, iv, jv, ia, is, inl, jnl
      real(kind=8), allocatable:: qbephi(:,:), qbecp(:,:)
!
!     calculation of becp and bephi
!
      call start_clock( 'ortho' )
      call nlsm1(n,1,nvb,eigr, cp, becp)
      call nlsm1(n,1,nvb,eigr,phi,bephi)
!
!     calculation of qbephi and qbecp
!
      allocate(qbephi(nhsa,n))
      allocate(qbecp (nhsa,n))
      qbephi = 0.d0
      qbecp  = 0.d0
!
      do is=1,nvb
         do iv=1,nh(is)
            do jv=1,nh(is)
               if(abs(qq(iv,jv,is)).gt.1.e-5) then
                  do ia=1,na(is)
                     inl=ish(is)+(iv-1)*na(is)+ia
                     jnl=ish(is)+(jv-1)*na(is)+ia
                     do i=1,n
                        qbephi(inl,i)= qbephi(inl,i)                    &
     &                       +qq(iv,jv,is)*bephi(jnl,i)
                        qbecp (inl,i)=qbecp (inl,i)                     &
     &                       +qq(iv,jv,is)*becp (jnl,i)
                     end do
                  end do
               endif
            end do
         end do
      end do
!
      do iss=1,nspin
         nss=nupdwn(iss)
         istart=iupdwn(iss)
!
!     rho = <s'c0|s|cp>
!     sig = 1-<cp|s|cp>
!     tau = <s'c0|s|s'c0>
!
         call rhoset(cp,phi,bephi,qbecp,nss,istart,rho)
         call sigset(cp,becp,qbecp,nss,istart,sig)
         call tauset(phi,bephi,qbephi,nss,istart,tau)
!
         if(iprsta.gt.4) then
            WRITE( stdout,*)
            WRITE( stdout,'(26x,a)') '    rho '
            do i=1,nss
               WRITE( stdout,'(7f11.6)') (rho(i,j),j=1,nss)
            end do
            WRITE( stdout,*)
            WRITE( stdout,'(26x,a)') '    sig '
            do i=1,nss
               WRITE( stdout,'(7f11.6)') (sig(i,j),j=1,nss)
            end do
            WRITE( stdout,*)
            WRITE( stdout,'(26x,a)') '    tau '
            do i=1,nss
               WRITE( stdout,'(7f11.6)') (tau(i,j),j=1,nss)
            end do
         endif
!
!
!----------------------------------------------------------------by ap--
! 
         do j=1,nss
            do i=1,nss
               xloc(i,j) = x0(istart-1+i,istart-1+j)*ccc
               dd(i,j) = 0.d0
               x1(i,j) = 0.d0
               tmp1(i,j)=0.d0
               rhos(i,j)=0.5d0*( rho(i,j)+rho(j,i) )
!
! on some machines (IBM RS/6000 for instance) the following test allows
! to distinguish between Numbers and Sodium Nitride (NaN, Not a Number).
! If a matrix of Not-Numbers is passed to rs, the most likely outcome is
! that the program goes on forever doing nothing and writing nothing.
!
               if (rhos(i,j).ne.rhos(i,j))                                &
     &             call errore('ortho','ortho went bananas',1)
               rhor(i,j)=rho(i,j)-rhos(i,j)
            end do
         end do
!     
         do i=1,nss
            tmp1(i,i)=1.d0
         end do
         ifail=0
         call start_clock( 'rsg' )
         call rs(nx,nss,rhos,diag,1,u,work1,work2,ifail) 
         call stop_clock( 'rsg' )
!
!                calculation of lagranges multipliers
!
         do iter=1,max
!
!       the following 4 MXMA-calls do the following matrix 
!       multiplications:
!                       tmp1 = x0*rhor    (1st call)
!                       dd   = x0*tau*x0  (2nd and 3rd call)
!                       tmp2 = x0*rhos    (4th call)
!
            call MXMA( xloc,1,nx,rhor,1,nx,tmp1,1,nx,nss,nss,nss)
            call MXMA( tau ,1,nx,xloc,1,nx,tmp2,1,nx,nss,nss,nss)
            call MXMA( xloc,1,nx,tmp2,1,nx,  dd,1,nx,nss,nss,nss)
            call MXMA( xloc,1,nx,rhos,1,nx,tmp2,1,nx,nss,nss,nss)
            do i=1,nss
               do j=1,nss
                  x1(i,j) = sig(i,j)-tmp1(i,j)-tmp1(j,i)-dd(i,j)       
                  con(i,j)= x1(i,j)-tmp2(i,j)-tmp2(j,i)
               end do
            end do
!
!         x1      = sig      -x0*rho    -x0*rho^t  -x0*tau*x0
!
            diff=0.d0
            do i=1,nss
               do j=1,nss
                  if(abs(con(i,j)).gt.diff) diff=abs(con(i,j))
               end do
            end do
!
            if( diff.le.eps ) go to 20
!     
!     the following two MXMA-calls do:   
!                       tmp1 = x1*u
!                       tmp2 = ut*x1*u
!
            call MXMA(x1,1,nx,   u,1,nx,tmp1,1,nx,nss,nss,nss)
            call MXMA(u ,nx,1,tmp1,1,nx,tmp2,1,nx,nss,nss,nss)   
!
!       g=ut*x1*u/d  (g is stored in tmp1)
! 
            do i=1,nss
               do j=1,nss
                  tmp1(i,j)=tmp2(i,j)/(diag(i)+diag(j))
               end do
            end do
!     
!       the following two MXMA-calls do:   
!                       tmp2 = g*ut
!                       x0 = u*g*ut
!
            call MXMA(tmp1,1,nx,  u,nx,1,tmp2,1,nx,nss,nss,nss)
            call MXMA(   u,1,nx,tmp2,1,nx,xloc,1,nx,nss,nss,nss)
         end do
         WRITE( stdout,*) ' diff= ',diff,' iter= ',iter
         call errore('ortho','max number of iterations exceeded',iter)
!
 20      continue
!
!-----------------------------------------------------------------------
!
         if(iprsta.gt.4) then
            WRITE( stdout,*)
            WRITE( stdout,'(26x,a)') '    lambda '
            do i=1,nss
               WRITE( stdout,'(7f11.6)') (xloc(i,j)/f(i+istart-1),j=1,nss)
            end do
         endif
!     
         if(iprsta.gt.2) then
            WRITE( stdout,*) ' diff= ',diff,' iter= ',iter
         endif
!     
!     lagrange multipliers
!
         do i=1,nss
            do j=1,nss
               x0(istart-1+i,istart-1+j)=xloc(i,j)/ccc
               if (xloc(i,j).ne.xloc(i,j))                                &
     &             call errore('ortho','ortho went bananas',2)
            end do
         end do
!
      end do
!
      deallocate(qbecp )
      deallocate(qbephi)
!
      call stop_clock( 'ortho' )
      return
      end
!
!-----------------------------------------------------------------------
      subroutine pbc(rin,a1,a2,a3,ainv,rout)
!-----------------------------------------------------------------------
!
!     brings atoms inside the unit cell
!
      implicit none
! input
      real(kind=8) rin(3), a1(3),a2(3),a3(3), ainv(3,3)
! output
      real(kind=8) rout(3)
! local
      real(kind=8) x,y,z
!
! bring atomic positions to crystal axis
!
      x = ainv(1,1)*rin(1)+ainv(1,2)*rin(2)+ainv(1,3)*rin(3)
      y = ainv(2,1)*rin(1)+ainv(2,2)*rin(2)+ainv(2,3)*rin(3)
      z = ainv(3,1)*rin(1)+ainv(3,2)*rin(2)+ainv(3,3)*rin(3)
!
! bring x,y,z in the range between -0.5 and 0.5
!
      x = x - nint(x)
      y = y - nint(y)
      z = z - nint(z)
!
! bring atomic positions back in cartesian axis
!
      rout(1) = x*a1(1)+y*a2(1)+z*a3(1)
      rout(2) = x*a1(2)+y*a2(2)+z*a3(2)
      rout(3) = x*a1(3)+y*a2(3)+z*a3(3)
!
      return
      end
!-----------------------------------------------------------------------
      subroutine phbox(taub,eigrb)
!-----------------------------------------------------------------------
!     calculates the phase factors for the g's of the little box
!     eigrt=exp(-i*g*tau) .
!     Uses the same logic for fast calculation as in phfac (see below)
!
      use io_global, only: stdout
      use ions_base, only: nas => nax, nsp, na
      use parameters, only: natx, nsx
      use gvecb
      use cell_base, only: ainv
      use small_box, only: ainvb
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b
      use constants, only: pi, fpi
      use control_flags, only: iprint, iprsta
!
      implicit none
      real(kind=8) :: taub(3,natx)
      complex(kind=8) :: eigrb(ngb,nas,nsp)
! local
      integer :: i,j,k, is, ia, ig, isa
      real(kind=8) taup(3),s,ar1,ar2,ar3
      complex(kind=8), allocatable:: ei1b(:,:,:), ei2b(:,:,:), ei3b(:,:,:)
      complex(kind=8) ctep1,ctep2,ctep3,ctem1,ctem2,ctem3
!
      if(nr1b.lt.3) call errore(' phbox ',' nr1b too small ',nr1b)
      if(nr2b.lt.3) call errore(' phbox ',' nr2b too small ',nr2b)
      if(nr3b.lt.3) call errore(' phbox ',' nr3b too small ',nr3b)
!
      allocate(ei1b(-nr1b:nr1b,nas,nsp))
      allocate(ei2b(-nr2b:nr2b,nas,nsp))
      allocate(ei3b(-nr3b:nr3b,nas,nsp))
!
      if(iprsta.gt.3) then 
         WRITE( stdout,*) ' phbox: taub '
         WRITE( stdout,*) ( (taub(i,isa), i=1, 3 ), isa=1, SUM(na(1:nsp)) ) 
      endif
      isa = 0 
      do is=1,nsp
         do ia=1,na(is)
            isa = isa + 1
            do i=1,3
               s=0.d0
               do j=1,3
                  s = s + ainvb(i,j)*taub(j,isa)
               end do
               taup(i)=s
            end do
!
            ar1=2.d0*pi*taup(1)
            ctep1=cmplx(cos(ar1),-sin(ar1))
            ctem1=conjg(ctep1)
            ei1b( 0,ia,is)=cmplx(1.d0,0.d0)
            ei1b( 1,ia,is)=ctep1
            ei1b(-1,ia,is)=ctem1
            do i=2,nr1b-1
               ei1b( i,ia,is)=ei1b( i-1,ia,is)*ctep1
               ei1b(-i,ia,is)=ei1b(-i+1,ia,is)*ctem1
            end do
!
            ar2=2.d0*pi*taup(2)
            ctep2=cmplx(cos(ar2),-sin(ar2))
            ctem2=conjg(ctep2)
            ei2b( 0,ia,is)=cmplx(1.d0,0.d0)
            ei2b( 1,ia,is)=ctep2
            ei2b(-1,ia,is)=ctem2
            do j=2,nr2b-1
               ei2b( j,ia,is)=ei2b( j-1,ia,is)*ctep2
               ei2b(-j,ia,is)=ei2b(-j+1,ia,is)*ctem2
            end do
!
            ar3=2.d0*pi*taup(3)
            ctep3=cmplx(cos(ar3),-sin(ar3))
            ctem3=conjg(ctep3)
            ei3b( 0,ia,is)=cmplx(1.d0,0.d0)
            ei3b( 1,ia,is)=ctep3
            ei3b(-1,ia,is)=ctem3
            do k=2,nr3b-1
               ei3b( k,ia,is)=ei3b( k-1,ia,is)*ctep3
               ei3b(-k,ia,is)=ei3b(-k+1,ia,is)*ctem3
            end do
!
         end do
      end do
!
!     calculation of eigrb(g,ia,is)=e^(-ig.r(ia,is))
!
      do is=1,nsp
         do ia=1,na(is)
            do ig=1,ngb
               i = mill_b(1,ig)
               j = mill_b(2,ig)
               k = mill_b(3,ig)
               eigrb(ig,ia,is) = ei1b(i,ia,is) * ei2b(j,ia,is) * ei3b(k,ia,is)
            end do
         end do
      end do
!
      if(iprsta.gt.4) then
         WRITE( stdout,*)
         if(nsp.gt.1) then
            do is=1,nsp
               WRITE( stdout,'(33x,a,i4)') ' ei1b, ei2b, ei3b (is)',is
               do ig=1,4
                  WRITE( stdout,'(6f9.4)')                                    &
     &                 ei1b(ig,1,is),ei2b(ig,1,is),ei3b(ig,1,is)
               end do
               WRITE( stdout,*)
            end do
         else
            do ia=1,na(1)
               WRITE( stdout,'(33x,a,i4)') ' ei1b, ei2b, ei3b (ia)',ia
               do ig=1,4
                  WRITE( stdout,'(6f9.4)')                                    &
     &                 ei1b(ig,ia,1),ei2b(ig,ia,1),ei3b(ig,ia,1)
               end do
               WRITE( stdout,*)
            end do
         endif
      endif
!
      deallocate(ei3b)
      deallocate(ei2b)
      deallocate(ei1b)
!     
      return
      end
!-----------------------------------------------------------------------
      subroutine phfac(tau0,ei1,ei2,ei3,eigr)
!-----------------------------------------------------------------------
!  this subroutine generates the complex matrices ei1, ei2, and ei3
!  used to compute the structure factor and forces on atoms :
!     ei1(n1,ia,is) = exp(-i*n1*b1*tau(ia,is)) -nr1<n1<nr1
!  and similar definitions for ei2 and ei3 ; and :
!     eigr(n,ia,is) = ei1*ei2*ei3 = exp(-i g*tau(ia,is))
!  The value of n1,n2,n3 for a vector g is supplied by arrays mill_l
!  calculated in ggen .
!
      use ions_base, only: nas => nax, nsp, na
      use io_global, only: stdout
      use parameters, only: natx, nsx
      use gvecw, only: ngw
      use cell_base, only: ainv
      use grid_dimensions, only: nr1, nr2, nr3
      use constants, only: pi, fpi
      use gvec
      use control_flags, only: iprint, iprsta
!
      implicit none
      real(kind=8) tau0(3,natx)
!
      complex(kind=8) ei1(-nr1:nr1,nas,nsp), ei2(-nr2:nr2,nas,nsp),      &
     &                ei3(-nr3:nr3,nas,nsp), eigr(ngw,nas,nsp)
!
      integer i,j,k, ia, is, ig, isa
      real(kind=8) taup(3), s, ar1,ar2,ar3
      complex(kind=8) ctep1,ctep2,ctep3,ctem1,ctem2,ctem3
!
      if(nr1.lt.3) call errore(' phfac ',' nr1 too small ',nr1)
      if(nr2.lt.3) call errore(' phfac ',' nr1 too small ',nr2)
      if(nr3.lt.3) call errore(' phfac ',' nr1 too small ',nr3)
!
      if(iprsta.gt.3) then
         WRITE( stdout,*) ' phfac: tau0 '
         WRITE( stdout,*) ( ( tau0(i,isa), i=1, 3 ), isa=1, SUM(na(1:nsp)) )
      endif
      isa = 0
      do is=1,nsp
         do ia=1,na(is)
            isa = isa + 1
            do i=1,3
               s=0.d0
               do j=1,3
                  s=s+ainv(i,j)*tau0(j,isa)
               end do
               taup(i)=s
!
! tau0=x1*a1+x2*a2+x3*a3 => taup(1)=x1=tau0*b1 and so on
!
            end do
!
            ar1=2.d0*pi*taup(1)
            ctep1=cmplx(cos(ar1),-sin(ar1))
            ctem1=conjg(ctep1)
            ei1( 0,ia,is)=cmplx(1.d0,0.d0)
            ei1( 1,ia,is)=ctep1
            ei1(-1,ia,is)=ctem1
            do i=2,nr1-1
               ei1( i,ia,is)=ei1( i-1,ia,is)*ctep1
               ei1(-i,ia,is)=ei1(-i+1,ia,is)*ctem1
            end do
!
            ar2=2.d0*pi*taup(2)
            ctep2=cmplx(cos(ar2),-sin(ar2))
            ctem2=conjg(ctep2)
            ei2( 0,ia,is)=cmplx(1.d0,0.d0)
            ei2( 1,ia,is)=ctep2
            ei2(-1,ia,is)=ctem2
            do j=2,nr2-1
               ei2( j,ia,is)=ei2( j-1,ia,is)*ctep2
               ei2(-j,ia,is)=ei2(-j+1,ia,is)*ctem2
            end do
!
            ar3=2.d0*pi*taup(3)
            ctep3=cmplx(cos(ar3),-sin(ar3))
            ctem3=conjg(ctep3)
            ei3( 0,ia,is)=cmplx(1.d0,0.d0)
            ei3( 1,ia,is)=ctep3
            ei3(-1,ia,is)=ctem3
            do k=2,nr3-1
               ei3( k,ia,is)=ei3( k-1,ia,is)*ctep3
               ei3(-k,ia,is)=ei3(-k+1,ia,is)*ctem3
            end do
!
         end do
      end do
!
      if(iprsta.gt.4) then
         WRITE( stdout,*)
         if(nsp.gt.1) then
            do is=1,nsp
               WRITE( stdout,'(33x,a,i4)') ' ei1, ei2, ei3 (is)',is
               do ig=1,4
                  WRITE( stdout,'(6f9.4)')                                    &
     &                 ei1(ig,1,is),ei3(ig,1,is),ei3(ig,1,is)
               end do
               WRITE( stdout,*)
            end do
         else
            do ia=1,na(1)
               WRITE( stdout,'(33x,a,i4)') ' ei1, ei2, ei3 (ia)',ia
               do ig=1,4
                  WRITE( stdout,'(6f9.4)')                                    &
     &                 ei1(ig,ia,1),ei3(ig,ia,1),ei3(ig,ia,1)
               end do
               WRITE( stdout,*)
            end do
         endif
      endif
!
!     calculation of eigr(g,ia,is)=e^(-ig.r(ia,is))
!
      do is=1,nsp
         do ia=1,na(is)
            do ig=1,ngw
               i = mill_l(1,ig)
               j = mill_l(2,ig)
               k = mill_l(3,ig)
               eigr(ig,ia,is) = ei1(i,ia,is) * ei2(j,ia,is) * ei3(k,ia,is)
            end do
         end do
      end do
!
      return
      end
!
!-------------------------------------------------------------------------
      subroutine prefor(eigr,betae)
!-----------------------------------------------------------------------
!
!     input :        eigr =  e^-ig.r_i
!     output:        betae_i,i(g) = (-i)**l beta_i,i(g) e^-ig.r_i 
!
      use ions_base, only: nas => nax, nsp, na
      use gvecw, only: ngw
      use cvan, only: ish
      use uspp, only :nhsa=>nkb, beta, nhtol
      use uspp_param, only: nh
      use elct
!
      implicit none
      complex(kind=8) eigr(ngw,nas,nsp)
      complex(kind=8) betae(ngw,nhsa)
!
      integer is, iv, ia, inl, ig
      complex(kind=8) ci
!
      call start_clock( 'prefor' )
      do is=1,nsp
         do iv=1,nh(is)
            ci=(0.,-1.)**nhtol(iv,is)
            do ia=1,na(is)
               inl=ish(is)+(iv-1)*na(is)+ia
               do ig=1,ngw
                  betae(ig,inl)=ci*beta(ig,iv,is)*eigr(ig,ia,is)
               end do
            end do
         end do
      end do
      call stop_clock( 'prefor' )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine projwfc(c,eigr,betae)
!-----------------------------------------------------------------------
!
! Projection on atomic wavefunctions
!
      use io_global, only: stdout
      use elct, only: n, nx
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use ions_base, only: nsp, na, nas => nax
      use uspp, only: nhsa => nkb
      use atom
!
      implicit none
      complex(kind=8), intent(in) :: c(ngw,nx), eigr(ngw,nas,nsp),      &
     &                               betae(ngw,nhsa)
!
      complex(kind=8), allocatable:: wfc(:,:), swfc(:,:), becwfc(:,:)
      real(kind=8), allocatable   :: overlap(:,:), e(:), z(:,:),        &
     &                               proj(:,:), temp(:)
      real(kind=8)                :: somma
      integer n_atomic_wfc
      integer is, ia, nb, l, m, k, i
!
! calculate number of atomic states
!
      n_atomic_wfc=0
      do is=1,nsp
         do nb = 1,nchi(is)
            l = lchi(nb,is)
            n_atomic_wfc = n_atomic_wfc + (2*l+1)*na(is)
         end do
      end do
      if (n_atomic_wfc.eq.0) return
!
      allocate(wfc(ngw,n_atomic_wfc))
!
! calculate wfc = atomic states
!
      call atomic_wfc(eigr,n_atomic_wfc,wfc)
!
! calculate bec = <beta|wfc>
!
      allocate(becwfc(nhsa,n_atomic_wfc))
      call nlsm1 (n_atomic_wfc,1,nsp,eigr,wfc,becwfc)

! calculate swfc = S|wfc>
!
      allocate(swfc(ngw,n_atomic_wfc))
      call s_wfc(n_atomic_wfc,becwfc,betae,wfc,swfc)
!
! calculate overlap(i,j) = <wfc_i|S|wfc_j> 
!
      allocate(overlap(n_atomic_wfc,n_atomic_wfc))
!
      call MXMA(wfc,2*ngw,1,swfc,1,2*ngw,overlap,1,                     &
     &          n_atomic_wfc,n_atomic_wfc,2*ngw,n_atomic_wfc)

      call reduce(n_atomic_wfc**2,overlap)

      overlap=overlap*2.d0
      if (gstart == 2) then
         do l=1,n_atomic_wfc
            do m=1,n_atomic_wfc
               overlap(m,l)=overlap(m,l)-real(wfc(1,m))*real(swfc(1,l))
            end do
         end do
      end if
!
! calculate (overlap)^(-1/2)(i,j). An orthonormal set of vectors |wfc_i>
! is obtained by introducing |wfc_j>=(overlap)^(-1/2)(i,j)*S|wfc_i>
!
      allocate(z(n_atomic_wfc,n_atomic_wfc))
      allocate(e(n_atomic_wfc))
      call rdiag(n_atomic_wfc,overlap,n_atomic_wfc,e,z)
      overlap=0.d0
      do l=1,n_atomic_wfc
         do m=1,n_atomic_wfc
            do k=1,n_atomic_wfc
               overlap(l,m)=overlap(l,m)+z(m,k)*z(l,k)/sqrt(e(k))
            end do
         end do
      end do
      deallocate(e)
      deallocate(z)
!
! calculate |wfc_j>=(overlap)^(-1/2)(i,j)*S|wfc_i>   (note the S matrix!)
!
      wfc=0.d0
      do m=1,n_atomic_wfc
         do l=1,n_atomic_wfc
            wfc(:,m)=wfc(:,m)+overlap(l,m)*swfc(:,l)
         end do
      end do
      deallocate(overlap)
      deallocate(swfc)
      deallocate(becwfc)
!
! calculate proj = <c|S|wfc> 
!
      allocate(proj(n,n_atomic_wfc))
      allocate(temp(ngw))
      do m=1,n
         do l=1,n_atomic_wfc
            temp(:)=real(conjg(c(:,m))*wfc(:,l))
            proj(m,l)=2.d0*SUM(temp)
            if (gstart == 2) proj(m,l)=proj(m,l)-temp(1)
         end do
      end do
      deallocate(temp)

      call reduce(n*n_atomic_wfc,proj)

      i=0
      WRITE( stdout,'(/''Projection on atomic states:'')')
      do is=1,nsp
         do nb = 1,nchi(is)
            l=lchi(nb,is)
            do m = -l,l
               do ia=1,na(is)
                  i=i+1
                  WRITE( stdout,'(''atomic state # '',i3,'': atom # '',i3,    &
     &                      ''  species # '',i2,''  wfc # '',i2,        &
     &                      '' (l='',i1,'' m='',i2,'')'')')             &
     &                 i, ia, is, nb, l, m
               end do
            end do
         end do
      end do

      WRITE( stdout,*)
      do m=1,n
         somma=0.d0
         do l=1,n_atomic_wfc
            somma=somma+proj(m,l)**2
         end do
         WRITE( stdout,'(''state # '',i4,''    sum c^2 ='',f7.4)') m,somma
         WRITE( stdout,'(10f7.4)') (abs(proj(m,l)),l=1,n_atomic_wfc)
      end do
!
      deallocate(proj)
      deallocate(wfc)
      return
      end
!-----------------------------------------------------------------------
      subroutine raddrizza(nspin,nx,nupdwn,iupdwn,f,lambda,ngw,c)
!-----------------------------------------------------------------------
!
!     transform wavefunctions into eigenvectors of the hamiltonian
!     via diagonalization of the constraint matrix lambda
!
      implicit none
      integer, intent(in)           :: nspin, nx, ngw, nupdwn(nspin),   &
     &                                 iupdwn(nspin)
      real   (kind=8), intent(in)   :: lambda(nx,nx), f(nx)
      complex(kind=8), intent(inout):: c(ngw,nx)

      real(kind=8)                :: lambdar(nx,nx), wr(nx), zr(nx,nx)
      complex(kind=8), allocatable:: csave(:,:)
      integer                     :: iss, n, j, i, i0
!
      do iss=1,nspin
         n=nupdwn(iss)
         i0=iupdwn(iss)-1
         allocate(csave(ngw,n))
         do i=1,n
            do j=1,n
               lambdar(j,i)=lambda(i0+j,i0+i)
            end do
         end do

         call rdiag(n,lambdar,nx,wr,zr)

         csave=0.d0
         do i=1,n
            do j=1,n
               csave(:,i) = csave(:,i) + zr(j,i)*c(:,i0+j)
            end do
         end do
         do i=1,n
            c(:,i0+i)=csave(:,i)
         end do
         deallocate(csave)

!     uncomment to print out eigenvalues
!         do i=1,n
!            if (f(i0+i).gt.1.e-6) then
!               wr(i)=27.212*wr(i)/f(i0+i)
!            else
!               wr(i)=0.0
!            end if
!         end do
!         WRITE( stdout,'(/10f8.2/)') (wr(i),i=1,nupdwn(iss))
      end do
      return
      end
!
!---------------------------------------------------------------------
      subroutine randin(nmin,nmax,gstart,ngw,ampre,c)
!---------------------------------------------------------------------
!
      implicit none
! input
      integer nmin, nmax, gstart, ngw
      real(kind=8) ampre
! output
      complex(kind=8) c(ngw,nmax)
! local
      integer i,j
      real(kind=8) ranf1, randy, ranf2, ampexp
!
      do i=nmin,nmax
         do j=gstart,ngw
            ranf1=.5-randy()
            ranf2=.5-randy()
            ampexp=ampre*exp(-(4.*j)/ngw)
            c(j,i)=c(j,i)+ampexp*cmplx(ranf1,ranf2)
         end do
      end do
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine rdiag (n,h,ldh,e,v)
!-----------------------------------------------------------------------
!
!   calculates all the eigenvalues and eigenvectors of a complex
!   hermitean matrix H . On output, the matrix H is destroyed
!
      implicit none
      integer, intent(in)           :: n, ldh
      complex(kind=8), intent(inout):: h(ldh,n)
      real   (kind=8), intent(out)  :: e(n)
      complex(kind=8), intent(out)  :: v(ldh,n)
!
      real(kind=8) fv1(n), fv2(n)
      integer ierr
!
      call rs(ldh,n,h,e,1,v,fv1,fv2,ierr)
!
      return
      end
!-----------------------------------------------------------------------
   subroutine rhoofr (nfi,c,irb,eigrb,bec,rhovan,rhor,rhog,rhos,enl,ekin)
!-----------------------------------------------------------------------
!     the normalized electron density rhor in real space
!     the kinetic energy ekin
!     subroutine uses complex fft so it computes two ft's
!     simultaneously
!
!     rho_i,ij = sum_n < beta_i,i | psi_n >< psi_n | beta_i,j >
!     < psi_n | beta_i,i > = c_n(0) beta_i,i(0) +
!                   2 sum_g> re(c_n*(g) (-i)**l beta_i,i(g) e^-ig.r_i)
!
!     e_v = sum_i,ij rho_i,ij d^ion_is,ji
!
      use control_flags, only: iprint, tbuff, iprsta, thdyn, tpre, trhor
      use ions_base, only: nat, nas => nax, nsp
      use parameters, only: natx, nsx
      use gvec
      use gvecs
      use gvecb, only: ngb
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use uspp, only: nhsa => nkb
      use uspp_param, only: nh, nhm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use cell_base, only: omega
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use elct
      use constants, only: pi, fpi
      use pseu
      use work, only: wrk1
!
      use cdvan
      use dener
      use io_global, only: stdout
!
      implicit none
      real(kind=8) bec(nhsa,n), rhovan(nhm*(nhm+1)/2,nat,nspin)
      real(kind=8) rhor(nnr,nspin), rhos(nnrsx,nspin)
      real(kind=8) enl, ekin
      complex(kind=8) eigrb(ngb,nas,nsp), c(ngw,nx), rhog(ng,nspin)
      integer irb(3,natx,nsx), nfi
! local variables
      integer iss, isup, isdw, iss1, iss2, ios, i, ir, ig
      real(kind=8) rsumr(2), rsumg(2), sa1, sa2
      real(kind=8) rnegsum, rmin, rmax, rsum
      real(kind=8), external :: enkin, ennl
      complex(kind=8) ci,fp,fm
      complex(kind=8), pointer:: psi(:), psis(:)
!
!
      call start_clock( 'rhoofr' )
      psi => wrk1
      psis=> wrk1
      ci=(0.0,1.0)
      do iss=1,nspin
         rhor(:,iss) = 0.d0
         rhos(:,iss) = 0.d0
         rhog(:,iss) = (0.d0, 0.d0)
      end do
!
!     ==================================================================
!     calculation of kinetic energy ekin
!     ==================================================================
      ekin=enkin(c)
      if(tpre) call denkin(c,dekin)
!
!     ==================================================================
!     calculation of non-local energy
!     ==================================================================
      enl=ennl(rhovan, bec)
      if(tpre) call dennl(bec,denl)
!    
!    warning! trhor and thdyn are not compatible yet!   
!
      if(trhor.and.(.not.thdyn))then
!     ==================================================================
!     charge density is read from unit 47
!     ==================================================================
#ifdef __PARA
         call read_rho(47,nspin,rhor)
#else
         read(47) ((rhor(ir,iss),ir=1,nnr),iss=1,nspin)
#endif
         rewind 47
!
         if(nspin.eq.1)then
            iss=1
            do ir=1,nnr
               psi(ir)=cmplx(rhor(ir,iss),0.)
            end do
            call fwfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
            do ig=1,ng
               rhog(ig,iss)=psi(np(ig))
            end do
         else
            isup=1
            isdw=2
            do ir=1,nnr
               psi(ir)=cmplx(rhor(ir,isup),rhor(ir,isdw))
            end do
            call fwfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
            do ig=1,ng
               fp=psi(np(ig))+psi(nm(ig))
               fm=psi(np(ig))-psi(nm(ig))
               rhog(ig,isup)=0.5*cmplx( real(fp),aimag(fm))
               rhog(ig,isdw)=0.5*cmplx(aimag(fp),-real(fm))
            end do
         endif
!
      else
!     ==================================================================
!     self-consistent charge
!     ==================================================================
!
!     important: if n is odd then nx must be .ge.n+1 and c(*,n+1)=0.
! 
         if (mod(n,2).ne.0) then
            do ig=1,ngw
               c(ig,n+1)=(0.,0.)
            end do
         endif
!
         do i=1,n,2
            psis (:) = (0.d0, 0.d0)
            do ig=1,ngw
               psis(nms(ig))=conjg(c(ig,i))+ci*conjg(c(ig,i+1))
               psis(nps(ig))=c(ig,i)+ci*c(ig,i+1)
            end do
!
            call ivfftw(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!
!     wavefunctions in unit 21
!
#if defined(__CRAYY)
            if(tbuff) buffer out(21,0) (psis(1),psis(nnrsx))
#else
            if(tbuff) write(21,iostat=ios) psis
#endif
            iss1=ispin(i)
            sa1=f(i)/omega
            if (i.ne.n) then
               iss2=ispin(i+1)
               sa2=f(i+1)/omega
            else
               iss2=iss1
               sa2=0.0
            end if
            do ir=1,nnrsx
               rhos(ir,iss1)=rhos(ir,iss1) + sa1*( real(psis(ir)))**2
               rhos(ir,iss2)=rhos(ir,iss2) + sa2*(aimag(psis(ir)))**2
            end do
!
!       buffer 21
!     
            if(tbuff) then
#if defined(__CRAYY)
               ios=unit(21)
#endif
               if(ios.ne.0) call errore                                  &
     &              (' rhoofr',' error in writing unit 21',ios)
            endif
!
         end do
!
         if(tbuff) rewind 21
!
!     smooth charge in g-space is put into rhog(ig)
!
         if(nspin.eq.1)then
            iss=1
            do ir=1,nnrsx
               psis(ir)=cmplx(rhos(ir,iss),0.)
            end do
            call fwffts(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
            do ig=1,ngs
               rhog(ig,iss)=psis(nps(ig))
            end do
         else
            isup=1
            isdw=2
             do ir=1,nnrsx
               psis(ir)=cmplx(rhos(ir,isup),rhos(ir,isdw))
            end do
            call fwffts(psis,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
            do ig=1,ngs
               fp= psis(nps(ig)) + psis(nms(ig))
               fm= psis(nps(ig)) - psis(nms(ig))
               rhog(ig,isup)=0.5*cmplx( real(fp),aimag(fm))
               rhog(ig,isdw)=0.5*cmplx(aimag(fp),-real(fm))
            end do
         endif
!
         if(nspin.eq.1) then
!     ==================================================================
!     case nspin=1
!     ------------------------------------------------------------------
            iss=1
            psi (:) = (0.d0, 0.d0)
            do ig=1,ngs
               psi(nm(ig))=conjg(rhog(ig,iss))
               psi(np(ig))=      rhog(ig,iss)
            end do
            call invfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
            do ir=1,nnr
               rhor(ir,iss)=real(psi(ir))
            end do
         else 
!     ==================================================================
!     case nspin=2
!     ------------------------------------------------------------------
            isup=1
            isdw=2
            psi (:) = (0.d0, 0.d0)
            do ig=1,ngs
               psi(nm(ig))=conjg(rhog(ig,isup))+ci*conjg(rhog(ig,isdw))
               psi(np(ig))=rhog(ig,isup)+ci*rhog(ig,isdw)
            end do
            call invfft(psi,nr1,nr2,nr3,nr1x,nr2x,nr3x)
            do ir=1,nnr
               rhor(ir,isup)= real(psi(ir))
               rhor(ir,isdw)=aimag(psi(ir))
            end do
         endif
!
         if(iprsta.ge.3)then
            do iss=1,nspin
               rsumg(iss)=omega*real(rhog(1,iss))
               rsumr(iss)=SUM(rhor(:,iss))*omega/dble(nr1*nr2*nr3)
            end do
#ifdef __PARA
            if (gstart.ne.2) then
! in the parallel case, only one processor has G=0 ! 
               do iss=1,nspin
                  rsumg(iss)=0.0
               end do
            end if
            call reduce(nspin,rsumg)
            call reduce(nspin,rsumr)
#endif
            if (nspin.eq.1) then
               WRITE( stdout,1) rsumg(1),rsumr(1)
            else
               WRITE( stdout,2) (rsumg(iss),iss=1,nspin),(rsumr(iss),iss=1,nspin)
            endif
         endif
!     ==================================================================
!
!     add vanderbilt contribution to the charge density
!
!     drhov called before rhov because input rho must be the smooth part
!
         if (tpre) call drhov(irb,eigrb,rhovan,rhog,rhor)
!
         call rhov(irb,eigrb,rhovan,rhog,rhor)
      endif
!     ======================================endif for trhor=============
!
!     here to check the integral of the charge density
!
!
      if(iprsta.ge.2) then
         call checkrho(nnr,nspin,rhor,rmin,rmax,rsum,rnegsum)
         rnegsum=rnegsum*omega/dble(nr1*nr2*nr3)
         rsum=rsum*omega/dble(nr1*nr2*nr3)
         WRITE( stdout,'(a,4(1x,f12.6))')                                     &
     &     ' rhoofr: rmin rmax rnegsum rsum  ',rmin,rmax,rnegsum,rsum
      end if
!
      if(nfi.eq.0.or.mod(nfi-1,iprint).eq.0) then
         do iss=1,nspin
            rsumg(iss)=omega*real(rhog(1,iss))
            rsumr(iss)=SUM(rhor(:,iss),1)*omega/dble(nr1*nr2*nr3)
         end do
#ifdef __PARA
         if (gstart.ne.2) then
! in the parallel case, only one processor has G=0 ! 
            do iss=1,nspin
               rsumg(iss)=0.0
            end do
         end if
         call reduce(nspin,rsumg)
         call reduce(nspin,rsumr)
#endif
         if (nspin.eq.1) then
            WRITE( stdout,1) rsumg(1),rsumr(1)
         else
            if(iprsta.ge.3)                                             &
     &          WRITE( stdout,2) rsumg(1),rsumg(2),rsumr(1),rsumr(2)
            WRITE( stdout,1) rsumg(1)+rsumg(2),rsumr(1)+rsumr(2)
         endif
      endif
!
    2 format(//' subroutine rhoofr: total integrated electronic',       &
     &     ' density'/' in g-space =',f10.6,2x,f10.6,4x,                &
     &     ' in r-space =',f10.6,2x,f10.6)
    1 format(//' subroutine rhoofr: total integrated electronic',       &
     &     ' density'/' in g-space =',f10.6,4x,                         &
     &     ' in r-space =',f10.6)
!
      call stop_clock( 'rhoofr' )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine rhoset(cp,phi,bephi,qbecp,nss,ist,rho)
!-----------------------------------------------------------------------
!     input: cp (non-orthonormal), phi, bephi, qbecp
!     computes the matrix
!       rho = <s'c0|s cp> = <phi|s cp>
!     where  |phi> = s'|c0> = |c0> + sum q_ij |i><j|c0>
!     where s=s(r(t+dt)) and s'=s(r(t))  
!     routine makes use of  c(-q)=c*(q)
!
      use parameters, only: nsx, natx
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use uspp, only: nhsa => nkb, nhsavb=>nkbus
      use cvan, only: nvb
      use elct
!
      implicit none
!
      integer nss, ist
      complex(kind=8)   cp(ngw,n), phi(ngw,n)
      real(kind=8)       bephi(nhsa,n), qbecp(nhsa,n), rho(nx,nx)
      integer i, j
      real(kind=8)    tmp1(nx,nx) ! automatic array
!
      rho (:,:) = 0.d0
!
!     <phi|cp>
!
      call MXMA(phi(1,ist),2*ngw,1,cp(1,ist),1,2*ngw,                   &
     &                              rho,1,nx,nss,2*ngw,nss)
!
!     q >= 0  components with weight 2.0
!
      do j=1,nss
         do i=1,nss
            rho(i,j)=2.*rho(i,j)
         end do
      end do
!
      if (gstart == 2) then
!
!     q = 0  components has weight 1.0
!
         do j=1,nss
            do i=1,nss
               rho(i,j) = rho(i,j) -                                    &
     &              real(phi(1,i+ist-1))*real(cp(1,j+ist-1))
            end do
         end do
      end if

      call reduce(nx*nss,rho)
!
      if(nvb.gt.0)then
         tmp1 (:,:) = 0.d0
!
         call MXMA(bephi(1,ist),nhsa,1,qbecp(1,ist),1,nhsa,               &
     &                                tmp1,1,nx,nss,nhsavb,nss)
!
         do j=1,nss
            do i=1,nss
               rho(i,j)=rho(i,j)+tmp1(i,j)
            end do
         end do
      endif
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine rhov(irb,eigrb,rhovan,rhog,rhor)
!-----------------------------------------------------------------------
!     Add Vanderbilt contribution to rho(r) and rho(g)
!
!        n_v(g) = sum_i,ij rho_i,ij q_i,ji(g) e^-ig.r_i
!
!     routine makes use of c(-g)=c*(g)  and  beta(-g)=beta*(g)
!
      use ions_base, only: nas => nax, nat, na, nsp
      use io_global, only: stdout
      use parameters, only: natx, nsx
      use gvec
      use cvan, only: nvb
      use uspp_param, only: nh, nhm
      use uspp, only: deeq
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use elct
      use gvecb
      use cell_base, only: omega
      use small_box, only: omegab
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use control_flags, only: iprint, iprsta
      use qgb_mod
      use work, only: wrk1
      use work_box
      use para_mod
!
      implicit none
!
      real(kind=8) ::  rhovan(nhm*(nhm+1)/2,nat,nspin)
      integer, intent(in) :: irb(3,natx,nsx)
      complex(kind=8), intent(in):: eigrb(ngb,nas,nsp)
      real(kind=8), intent(inout):: rhor(nnr,nspin)
      complex(kind=8),  intent(inout):: rhog(ng,nspin)
!
      integer isup, isdw, nfft, ifft, iv, jv, ig, ijv, is, iss,           &
     &     isa, ia, ir, irb3, imin3, imax3
      real(kind=8) sumrho
      complex(kind=8) ci, fp, fm, ca
      complex(kind=8), allocatable::  qgbt(:,:)
      complex(kind=8), pointer:: v(:)
!
      if (nvb.eq.0) return
      call start_clock( 'rhov' )
      ci=(0.,1.)
!
      v => wrk1
      v (:) = (0.d0, 0.d0)
      allocate(qgbt(ngb,2))
!
      if(nspin.eq.1) then
!     ------------------------------------------------------------------
!     nspin=1 : two fft at a time, one per atom, if possible
!     ------------------------------------------------------------------
         iss=1
         isa=1
         do is=1,nvb
#ifdef __PARA
            do ia=1,na(is)
               nfft=1
               irb3=irb(3,ia,is)
               call parabox(nr3b,irb3,nr3,imin3,imax3)
               if (imax3-imin3+1.le.0) go to 15
#else
            do ia=1,na(is),2
               nfft=2
               if( ia.eq.na(is)) nfft=1
#endif
!
!  nfft=2 if two ffts at the same time are performed
!
               do ifft=1,nfft
                  qgbt(:,ifft) = (0.d0, 0.d0)
                  ijv=0
                  do iv= 1,nh(is)
                     do jv=iv,nh(is)
                        ijv=ijv+1
                        sumrho=rhovan(ijv,isa+ifft-1,iss)
                        if(iv.ne.jv) sumrho=2.*sumrho
                        do ig=1,ngb
                           qgbt(ig,ifft)=qgbt(ig,ifft) +                &
      &                                  sumrho*qgb(ig,ijv,is)
                        end do
                     end do
                  end do
               end do
!
! add structure factor
!
               qv(:) = (0.d0, 0.d0)
               if(nfft.eq.2)then
                  do ig=1,ngb
                     qv(npb(ig))=  eigrb(ig,ia  ,is)*qgbt(ig,1)         &
     &                  + ci*      eigrb(ig,ia+1,is)*qgbt(ig,2)
                     qv(nmb(ig))=                                       &
     &                       conjg(eigrb(ig,ia  ,is)*qgbt(ig,1))        &
     &                  + ci*conjg(eigrb(ig,ia+1,is)*qgbt(ig,2))
                  end do
               else
                  do ig=1,ngb
                     qv(npb(ig)) = eigrb(ig,ia,is)*qgbt(ig,1)
                     qv(nmb(ig)) = conjg(eigrb(ig,ia,is)*qgbt(ig,1))
                  end do
               endif
!
               call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
!  qv = US augmentation charge in real space on box grid
!       for atomic species is, real(qv)=atom ia, imag(qv)=atom ia+1
!
               if(iprsta.gt.2) then
                  ca = SUM(qv)
                  WRITE( stdout,'(a,f12.8)') ' rhov: 1-atom g-sp = ',         &
     &                 omegab*real(qgbt(1,1))
                  WRITE( stdout,'(a,f12.8)') ' rhov: 1-atom r-sp = ',         &
     &                 omegab*real(ca)/(nr1b*nr2b*nr3b)
                  WRITE( stdout,'(a,f12.8)') ' rhov: 1-atom g-sp = ',         &
     &                 omegab*real(qgbt(1,2))
                  WRITE( stdout,'(a,f12.8)') ' rhov: 1-atom r-sp = ',         &
     &                 omegab*aimag(ca)/(nr1b*nr2b*nr3b)
               endif
!
!  add qv(r) to v(r), in real space on the dense grid
!
               call  box2grid(irb(1,ia,is),1,qv,v)
               if (nfft.eq.2) call  box2grid(irb(1,ia+1,is),2,qv,v)
  15           isa=isa+nfft
!
            end do
         end do
!
!  rhor(r) = total (smooth + US) charge density in real space
!
         do ir=1,nnr
            rhor(ir,iss)=rhor(ir,iss)+real(v(ir))        
         end do
!
         if(iprsta.gt.2) then
            ca = SUM(v)

            call reduce(2,ca)

            WRITE( stdout,'(a,2f12.8)')                                  &
     &           ' rhov: int  n_v(r)  dr = ',omega*ca/(nr1*nr2*nr3)
         endif
!
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         if(iprsta.gt.2) then
            WRITE( stdout,*) ' rhov: smooth ',omega*rhog(1,iss)
            WRITE( stdout,*) ' rhov: vander ',omega*v(1)
            WRITE( stdout,*) ' rhov: all    ',omega*(rhog(1,iss)+v(1))
         endif
!
!  rhog(g) = total (smooth + US) charge density in G-space
!
         do ig=1,ng
            rhog(ig,iss)=rhog(ig,iss)+v(np(ig))
         end do
!
         if(iprsta.gt.1) WRITE( stdout,'(a,2f12.8)')                          &
     &        ' rhov: n_v(g=0) = ',omega*real(rhog(1,iss))
!
      else
!     ------------------------------------------------------------------
!     nspin=2: two fft at a time, one for spin up and one for spin down
!     ------------------------------------------------------------------
         isup=1
         isdw=2
         isa=1
         do is=1,nvb
            do ia=1,na(is)
#ifdef __PARA
               irb3=irb(3,ia,is)
               call parabox(nr3b,irb3,nr3,imin3,imax3)
               if (imax3-imin3+1.le.0) go to 25
#endif
               do iss=1,2
                  qgbt(:,iss) = (0.d0, 0.d0)
                  ijv=0
                  do iv=1,nh(is)
                     do jv=iv,nh(is)
                        ijv=ijv+1
                        sumrho=rhovan(ijv,isa,iss)
                        if(iv.ne.jv) sumrho=2.*sumrho
                        do ig=1,ngb
                           qgbt(ig,iss)=qgbt(ig,iss)+sumrho*qgb(ig,ijv,is)
                        end do
                     end do
                  end do
               end do
!     
! add structure factor
!
               qv(:) = (0.d0, 0.d0)
               do ig=1,ngb
                  qv(npb(ig)) =    eigrb(ig,ia,is)*qgbt(ig,1)           &
     &                  + ci*      eigrb(ig,ia,is)*qgbt(ig,2)
                  qv(nmb(ig)) = conjg(eigrb(ig,ia,is)*qgbt(ig,1))       &
     &                  + ci*   conjg(eigrb(ig,ia,is)*qgbt(ig,2))
               end do
!
               call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
!  qv is the now the US augmentation charge for atomic species is
!  and atom ia: real(qv)=spin up, imag(qv)=spin down
!
               if(iprsta.gt.2) then
                  ca = SUM(qv)
                  WRITE( stdout,'(a,f12.8)') ' rhov: up   g-space = ',        &
     &                 omegab*real(qgbt(1,1))
                  WRITE( stdout,'(a,f12.8)') ' rhov: up r-sp = ',             &
     &                 omegab*real(ca)/(nr1b*nr2b*nr3b)
                  WRITE( stdout,'(a,f12.8)') ' rhov: dw g-space = ',          &
     &                 omegab*real(qgbt(1,2))
                  WRITE( stdout,'(a,f12.8)') ' rhov: dw r-sp = ',             &
     &                 omegab*aimag(ca)/(nr1b*nr2b*nr3b)
               endif
!
!  add qv(r) to v(r), in real space on the dense grid
!
               call box2grid2(irb(1,ia,is),qv,v)
  25           isa=isa+1
!
            end do
         end do
!
         do ir=1,nnr
            rhor(ir,isup)=rhor(ir,isup)+real(v(ir)) 
            rhor(ir,isdw)=rhor(ir,isdw)+aimag(v(ir)) 
         end do
!
         if(iprsta.gt.2) then
            ca = SUM(v)
            call reduce(2,ca)
            WRITE( stdout,'(a,2f12.8)') 'rhov:in n_v  ',omega*ca/(nr1*nr2*nr3)
         endif
!
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         if(iprsta.gt.2) then
            WRITE( stdout,*) 'rhov: smooth up',omega*rhog(1,isup)
            WRITE( stdout,*) 'rhov: smooth dw',omega*rhog(1,isdw)
            WRITE( stdout,*) 'rhov: vander up',omega*real(v(1))
            WRITE( stdout,*) 'rhov: vander dw',omega*aimag(v(1))
            WRITE( stdout,*) 'rhov: all up',                                  &
     &           omega*(rhog(1,isup)+real(v(1)))
            WRITE( stdout,*) 'rhov: all dw',                                  &
     &           omega*(rhog(1,isdw)+aimag(v(1)))
         endif
!
         do ig=1,ng
            fp=  v(np(ig)) + v(nm(ig))
            fm=  v(np(ig)) - v(nm(ig))
            rhog(ig,isup)=rhog(ig,isup) + 0.5*cmplx(real(fp),aimag(fm))
            rhog(ig,isdw)=rhog(ig,isdw) + 0.5*cmplx(aimag(fp),-real(fm))
         end do
!
         if(iprsta.gt.2) WRITE( stdout,'(a,2f12.8)')                          &
     &        ' rhov: n_v(g=0) up   = ',omega*real (rhog(1,isup))
         if(iprsta.gt.2) WRITE( stdout,'(a,2f12.8)')                          &
     &        ' rhov: n_v(g=0) down = ',omega*real(rhog(1,isdw))
!
      endif
      deallocate(qgbt)
      call stop_clock( 'rhov' )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine set_cc(irb,eigrb,rhoc)
!-----------------------------------------------------------------------
!
!     Calculate core charge contribution in real space, rhoc(r)
!     Same logic as for rhov: use box grid for core charges
!
      use ions_base, only: nas => nax, nsp, na
      use parameters, only: natx, nsx
      use atom, only: nlcc
      use gvec
      use grid_dimensions, only: nr3, nnr => nnrx
      use elct
      use gvecb
      use smallbox_grid_dimensions, only: nr1b, nr2b, nr3b, &
            nr1bx, nr2bx, nr3bx, nnrb => nnrbx
      use control_flags, only: iprint
      use core
      use work, only: wrk1
      use work_box
      use para_mod
      implicit none
! input
      integer, intent(in)        :: irb(3,natx,nsx)
      complex(kind=8), intent(in):: eigrb(ngb,nas,nsp)
! output
      real(kind=8), intent(out)  :: rhoc(nnr)
! local
      integer nfft, ig, is, ia, irb3, imin3, imax3
      complex(kind=8) ci
!
      call start_clock( 'set_cc' )
      ci=(0.,1.)
!
      wrk1 (:) = (0.d0, 0.d0)
!
      do is=1,nsp
         if (.not.nlcc(is)) go to 10
#ifdef __PARA
         do ia=1,na(is)
            nfft=1
            irb3=irb(3,ia,is)
            call parabox(nr3b,irb3,nr3,imin3,imax3)
            if (imax3-imin3+1.le.0) go to 15
#else
         do ia=1,na(is),2
            nfft=2
            if( ia.eq.na(is) ) nfft=1
!
! two ffts at the same time, on two atoms (if possible: nfft=2)
!
#endif
            qv(:) = (0.d0, 0.d0)
            if(nfft.eq.2)then
               do ig=1,ngb
                  qv(npb(ig))= eigrb(ig,ia  ,is)*rhocb(ig,is)          &
     &                    + ci*eigrb(ig,ia+1,is)*rhocb(ig,is)
                  qv(nmb(ig))= conjg(eigrb(ig,ia  ,is)*rhocb(ig,is))   &
     &                    + ci*conjg(eigrb(ig,ia+1,is)*rhocb(ig,is))
               end do
            else
               do ig=1,ngb
                  qv(npb(ig)) = eigrb(ig,ia,is)*rhocb(ig,is)
                  qv(nmb(ig)) = conjg(eigrb(ig,ia,is)*rhocb(ig,is))
               end do
            endif
!
            call ivfftb(qv,nr1b,nr2b,nr3b,nr1bx,nr2bx,nr3bx,irb3)
!
            call box2grid(irb(1,ia,is),1,qv,wrk1)
            if (nfft.eq.2) call box2grid(irb(1,ia+1,is),2,qv,wrk1)
!
15          continue
         end do
10       continue
      end do
!
      call DCOPY(nnr,wrk1,2,rhoc,1)
!
      call stop_clock( 'set_cc' )
!
      return
      end
!
!-------------------------------------------------------------------------
      subroutine s_wfc(n_atomic_wfc,becwfc,betae,wfc,swfc)
!-----------------------------------------------------------------------
!
!     input: wfc, becwfc=<wfc|beta>, betae=|beta>
!     output: swfc=S|wfc>
!
      use ions_base, only: na
      use cvan, only: nvb, ish
      use uspp, only: nhsa => nkb, nhsavb=>nkbus, qq
      use uspp_param, only: nh
      use elct
      use gvecw, only: ngw
      !use parm
      use constants, only: pi, fpi
      implicit none
! input
      integer, intent(in)         :: n_atomic_wfc
      complex(kind=8), intent(in) :: betae(ngw,nhsa),                   &
     &                               wfc(ngw,n_atomic_wfc)
      real(kind=8), intent(in)    :: becwfc(nhsa,n_atomic_wfc)
! output
      complex(kind=8), intent(out):: swfc(ngw,n_atomic_wfc)
! local
      integer is, iv, jv, ia, inl, jnl, i
      real(kind=8) qtemp(nhsavb,n_atomic_wfc)
!
      swfc=0.d0
!
      if (nvb.gt.0) then
         qtemp=0.d0
         do is=1,nvb
            do iv=1,nh(is)
               do jv=1,nh(is)
                  if(abs(qq(iv,jv,is)).gt.1.e-5) then
                     do ia=1,na(is)
                        inl=ish(is)+(iv-1)*na(is)+ia
                        jnl=ish(is)+(jv-1)*na(is)+ia
                        do i=1,n_atomic_wfc
                           qtemp(inl,i) = qtemp(inl,i) +                &
     &                                    qq(iv,jv,is)*becwfc(jnl,i)
                        end do
                     end do
                  endif
               end do
            end do
         end do
!
         call MXMA (betae,1,2*ngw,qtemp,1,nhsavb,swfc,1,                &
     &              2*ngw,2*ngw,nhsavb,n_atomic_wfc)
      end if
!
      swfc=swfc+wfc
!
      return
      end

!
!-------------------------------------------------------------------------
      subroutine sigset(cp,becp,qbecp,nss,ist,sig)
!-----------------------------------------------------------------------
!     input: cp (non-orthonormal), becp, qbecp
!     computes the matrix
!       sig = 1 - a ,  a = <cp|s|cp> = <cp|cp> + sum q_ij <cp|i><j|cp>
!     where s=s(r(t+dt)) 
!     routine makes use of c(-q)=c*(q)
!
      use parameters, only: natx, nsx
      use uspp, only: nhsa => nkb, nhsavb=>nkbus
      use cvan, only : nvb
      use elct
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
!
      implicit none
!
      integer nss, ist
      complex(kind=8)  cp(ngw,n)
      real(kind=8) becp(nhsa,n), qbecp(nhsa,n), sig(nx,nx)
!
      integer i, j
      real(kind=8)    tmp1(nx,nx) ! automatic array
!
      sig = 0.d0
      call MXMA(cp(1,ist),2*ngw,1,cp(1,ist),1,2*ngw,                    &
     &                                  sig,1,nx,nss,2*ngw,nss)
!
!     q >= 0  components with weight 2.0
!
      do j=1,nss
         do i=1,nss
            sig(i,j)=-2.*sig(i,j)
         end do
      end do
      if (gstart == 2) then
!
!     q = 0  components has weight 1.0
!
         do j=1,nss
            do i=1,nss
               sig(i,j) = sig(i,j) +                                    &
     &              real(cp(1,i+ist-1))*real(cp(1,j+ist-1))
            end do
         end do
      end if
      call reduce(nx*nss,sig)
      do i=1,nss
         sig(i,i) = sig(i,i)+1.
      end do
!
      if(nvb.gt.0)then
         tmp1 = 0.d0
!
         call MXMA(becp(1,ist),nhsa,1,qbecp(1,ist),1,nhsa,                &
     &                              tmp1,1,nx,nss,nhsavb,nss)
!
         do j=1,nss
            do i=1,nss
               sig(i,j)=sig(i,j)-tmp1(i,j)
            end do
         end do
      endif
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine spinsq (c,bec,rhor)
!-----------------------------------------------------------------------
!
!     estimate of <S^2>=s(s+1) in two different ways.
!     1) using as many-body wavefunction a single Slater determinant
!        constructed with Kohn-Sham orbitals:
!
!        <S^2> = (Nup-Ndw)/2 * (Nup-Ndw)/2+1) + Ndw - 
!                \sum_up\sum_dw < psi_up | psi_dw >
!
!        where Nup, Ndw = number of up and down states, the sum is over 
!        occupied states. Not suitable for fractionary occupancy.
!        In the ultrasoft scheme (c is the smooth part of \psi): 
!
!        < psi_up | psi_dw > = \sum_G c*_up(G) c_dw(G) +
!                              \int Q_ij <c_up|beta_i><beta_j|c_dw>
!
!        This is the usual formula, unsuitable for fractionary occupancy.
!     2) using the "LSD model" of Wang, Becke, Smith, JCP 102, 3477 (1995):
!
!        <S^2> = (Nup-Ndw)/2 * (Nup-Ndw)/2+1) + Ndw -
!                \int max(rhoup(r),rhodw(r)) dr
!
!     Requires on input: c=psi, bec=<c|beta>, rhoup(r), rhodw(r)
!     Assumes real psi, with only half G vectors.
!
      use elct
      use io_global, only: stdout
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
      use grid_dimensions, only: nr1, nr2, nr3, &
            nnr => nnrx
      use cell_base, only: omega
      use cvan, only: nvb, ish
      use uspp, only: nhsa => nkb, nhsavb=>nkbus, qq
      use uspp_param, only: nh
      use ions_base, only: na
!
      implicit none
! input
      real(kind=8) bec(nhsa,n), rhor(nnr,nspin)
      complex(kind=8) c(ngw,nx)
! local variables
      integer nup, ndw, ir, i, j, jj, ig, ia, is, iv, jv, inl, jnl
      real(kind=8) spin0, spin1, spin2, fup, fdw
      real(kind=8), allocatable:: overlap(:,:), temp(:)
      logical frac
!
!
      if (nspin.eq.1) return
!
! find spin-up and spin-down states
!
      fup = 0.0
      do i=iupdwn(1),nupdwn(1)
         fup = fup + f(i)
      end do
      nup = nint(fup)
      ndw = nel(1)+nel(2) - nup
!
! paranoid checks
!
      frac= abs(fup-nup).gt.1.0e-6
      fup = 0.0
      do i=1,nup
         fup = fup + f(i)
      end do
      frac=frac.or.abs(fup-nup).gt.1.0e-6
      fdw = 0.0
      do j=iupdwn(2),iupdwn(2)-1+ndw
         fdw = fdw + f(j)
      end do
      frac=frac.or.abs(fdw-ndw).gt.1.0e-6
!
      spin0 = abs(fup-fdw)/2.d0 * ( abs(fup-fdw)/2.d0 + 1.d0 ) + fdw
!
!     Becke's formula for spin polarization
!
      spin1 = 0.0
      do ir=1,nnr
         spin1 = spin1 - min(rhor(ir,1),rhor(ir,2))
      end do
      call reduce(1,spin1)
      spin1 = spin0 + omega/(nr1*nr2*nr3)*spin1
      if (frac) then
         WRITE( stdout,'(/'' Spin contamination: s(s+1)='',f5.2,'' (Becke) '',&
     &                             f5.2,'' (expected)'')')              &
     &          spin1, abs(fup-fdw)/2.d0*(abs(fup-fdw)/2.d0+1.d0)
         return
      end if
!
!     Slater formula, smooth contribution to  < psi_up | psi_dw >
!
      allocate (overlap(nup,ndw))
      allocate (temp(ngw))
      do j=1,ndw
         jj=j+iupdwn(2)-1
         do i=1,nup
            overlap(i,j)=0.d0
            do ig=1,ngw
               temp(ig)=real(conjg(c(ig,i))*c(ig,jj))
            end do
            overlap(i,j) = 2.d0*SUM(temp)
            if (gstart == 2) overlap(i,j) = overlap(i,j) - temp(1)
         end do
      end do
      deallocate (temp)
      call reduce(nup*ndw,overlap)
      do j=1,ndw
         jj=j+iupdwn(2)-1
         do i=1,nup
!
!     vanderbilt contribution to  < psi_up | psi_dw >
!
            do is=1,nvb
               do iv=1,nh(is)
                  do jv=1,nh(is)
                     if(abs(qq(iv,jv,is)).gt.1.e-5) then 
                        do ia=1,na(is)
                           inl=ish(is)+(iv-1)*na(is)+ia
                           jnl=ish(is)+(jv-1)*na(is)+ia
                           overlap(i,j) = overlap(i,j) +                &
     &                          qq(iv,jv,is)*bec(inl,i)*bec(jnl,jj)
                        end do
                     endif
                  end do
               end do
            end do
         end do
      end do
!
      spin2 = spin0
      do j=1,ndw
         do i=1,nup
            spin2 = spin2 - overlap(i,j)**2
         end do
      end do
!
      deallocate (overlap)
!
      WRITE( stdout,'(/" Spin contamination: s(s+1)=",f5.2," (Slater) ",  &
     &          f5.2," (Becke) ",f5.2," (expected)")')              &
     &     spin2,spin1, abs(fup-fdw)/2.d0*(abs(fup-fdw)/2.d0+1.d0)
!
      return
      end
!-------------------------------------------------------------------------
      subroutine strucf (ei1,ei2,ei3,sfac)
!-----------------------------------------------------------------------
! computes the structure factor sfac(ngs,nsp) and returns it in "pseu"
!
!
      use gvec
      use gvecs
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3
      use constants, only: pi, fpi
      use ions_base, only: nas => nax, nsp, na
!
      implicit none
      complex(kind=8) ei1(-nr1:nr1,nas,nsp), ei2(-nr2:nr2,nas,nsp),          &
     &           ei3(-nr3:nr3,nas,nsp), sfac(ngs,nsp)
      integer is, ig, ia, i, j, k
!
      call start_clock( 'strucf' ) 
      do is=1,nsp
         do ig=1,ngs
            sfac(ig,is)=(0.,0.)
         end do
         do ia=1,na(is)
            do ig=1,ngs 
               i = mill_l( 1, ig )
               j = mill_l( 2, ig )
               k = mill_l( 3, ig )
               sfac(ig,is)=sfac(ig,is) + ei1(i,ia,is) *ei2(j,ia,is) *ei3(k,ia,is)
            end do
         end do
      end do
!
      call stop_clock( 'strucf' ) 
      return
      end
!-------------------------------------------------------------------------
      subroutine tauset(phi,bephi,qbephi,nss,ist,tau)
!-----------------------------------------------------------------------
!     input: phi
!     computes the matrix
!        tau = <s'c0|s|s'c0> = <phi|s|phi>,  where  |phi> = s'|c0>
!     where s=s(r(t+dt)) and s'=s(r(t))  
!     routine makes use of c(-q)=c*(q)
!
      use parameters, only: nsx, natx
      use cvan, only: nvb
      use uspp, only: nhsa => nkb, nhsavb=>nkbus
      use elct
      use gvecw, only: ngw
      use reciprocal_vectors, only: gstart
!
      implicit none
      integer nss, ist
      complex(kind=8) phi(ngw,n)
      real(kind=8)  bephi(nhsa,n), qbephi(nhsa,n), tau(nx,nx)
      integer i, j
      real(kind=8)    tmp1(nx,nx) ! automatic array
!
      tau = 0.d0
      call MXMA(phi(1,ist),2*ngw,1,phi(1,ist),1,2*ngw,                  &
     &                                   tau,1,nx,nss,2*ngw,nss)
!
!     q >= 0  components with weight 2.0
!
      do j=1,nss
         do i=1,nss
            tau(i,j)=2.*tau(i,j)
         end do
      end do
      if (gstart == 2) then
!
!     q = 0  components has weight 1.0
!
         do j=1,nss
            do i=1,nss
               tau(i,j) = tau(i,j) -                                    &
     &              real(phi(1,i+ist-1))*real(phi(1,j+ist-1))
            end do
         end do
      end if
      call reduce(nx*nss,tau)
!
      if(nvb.gt.0)then
         tmp1 = 0.d0
!
         call MXMA(bephi(1,ist),nhsa,1,qbephi(1,ist),1,nhsa,              &
     &                                     tmp1,1,nx,nss,nhsavb,nss)
!
         do j=1,nss
            do i=1,nss
               tau(i,j)=tau(i,j)+tmp1(i,j)
            end do
         end do
      endif
!
      return
      end
!
!-------------------------------------------------------------------------
      subroutine updatc(ccc,x0,phi,bephi,becp,bec,cp)
!-----------------------------------------------------------------------
!     input ccc : dt**2/emass (unchanged in output)
!     input x0  : converged lambdas from ortho-loop (unchanged in output)
!     input cp  : non-orthonormal cp=c0+dh/dc*ccc
!     input bec : <cp|beta_i>
!     input phi 
!     output cp : orthonormal cp=cp+lambda*phi
!     output bec: bec=becp+lambda*bephi
!
      use ions_base, only: nsp, na
      use io_global, only: stdout
      use cvan, only: nvb, ish
      use uspp, only: nhsa => nkb, nhsavb=>nkbus
      use uspp_param, only: nh
      use gvecw, only: ngw
      use elct
      use work, only: wrk2
      use control_flags, only: iprint, iprsta
!
      implicit none
!
      complex(kind=8) cp(ngw,n), phi(ngw,n)
      real(kind=8)   bec(nhsa,n), x0(nx,nx), ccc
      real(kind=8)   bephi(nhsa,n), becp(nhsa,n)
! local variables
      integer i, j, ig, is, iv, ia, inl
      real(kind=8) wtemp(n,nhsa) ! automatic array
!
!     lagrange multipliers
!
      call start_clock( 'updatc' )
      wrk2 = (0.d0, 0.d0)
      do j=1,n
         call DSCAL(n,ccc,x0(1,j),1)
      end do
!
!     wrk2 = sum_m lambda_nm s(r(t+dt))|m>
!
      call MXMA(phi,1,2*ngw,x0,nx,1,wrk2,1,2*ngw,2*ngw,n,n)
!
      do i=1,n
         do ig=1,ngw
            cp(ig,i)=cp(ig,i)+wrk2(ig,i)
         end do
      end do
!    
!     updating of the <beta|c(n,g)>
!
!     bec of vanderbilt species are updated 
!
      if(nvb.gt.0)then
         call MXMA(x0,1,nx,bephi,nhsa,1,wtemp,1,n,n,n,nhsavb)
!
         do i=1,n
            do inl=1,nhsavb
               bec(inl,i)=wtemp(i,inl)+becp(inl,i)
            end do
         end do
      endif
!
      if (iprsta.gt.2) then
         WRITE( stdout,*)
         do is=1,nsp
            if(nsp.gt.1) then
               WRITE( stdout,'(33x,a,i4)') ' updatc: bec (is)',is
               WRITE( stdout,'(8f9.4)')                                       &
     &            ((bec(ish(is)+(iv-1)*na(is)+1,i),iv=1,nh(is)),i=1,n)
            else
               do ia=1,na(is)
                  WRITE( stdout,'(33x,a,i4)') ' updatc: bec (ia)',ia
                  WRITE( stdout,'(8f9.4)')                                    &
     &            ((bec(ish(is)+(iv-1)*na(is)+ia,i),iv=1,nh(is)),i=1,n)
               end do
            end if
            WRITE( stdout,*)
         end do
      endif
!
      do j=1,n
         call DSCAL(n,1.0/ccc,x0(1,j),1)
      end do
!
      call stop_clock( 'updatc' )
!
      return
      end
!
!-----------------------------------------------------------------------
      subroutine vofrho(nfi,rhor,rhog,rhos,rhoc,tfirst,tlast,           &
     &     ei1,ei2,ei3,irb,eigrb,sfac,tau0,fion)
!-----------------------------------------------------------------------
!     computes: the one-particle potential v in real space,
!               the total energy etot,
!               the forces fion acting on the ions,
!               the derivative of total energy to cell parameters h
!     rhor input : electronic charge on dense real space grid
!                  (plus core charge if present)
!     rhog input : electronic charge in g space (up to density cutoff)
!     rhos input : electronic charge on smooth real space grid
!     rhor output: total potential on dense real space grid
!     rhos output: total potential on smooth real space grid
!
      use control_flags, only: iprint, tvlocw, iprsta, thdyn, tpre, tfor, tprnfor
      use io_global, only: stdout
      use parameters, only: natx, nsx
      use ions_base, only: nas => nax, nsp, na
      use gvec
      use gvecs
      use cell_base, only: omega
      use cell_base, only: a1, a2, a3
      use reciprocal_vectors, only: gstart
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use elct
      use constants, only: pi, fpi
      use energies, only: etot, eself, enl, ekin, epseu, esr, eht, exc 
      use pseu
      use core
      use gvecb
      use work, only: wrk1
      use work_box
!
      use dener
      use derho
      use dpseu
!
      implicit none
!
      logical tlast,tfirst
      integer nfi
      real(kind=8)  rhor(nnr,nspin), rhos(nnrsx,nspin), fion(3,natx)
      real(kind=8)  rhoc(nnr), tau0(3,natx)
      complex(kind=8) ei1(-nr1:nr1,nas,nsp), ei2(-nr2:nr2,nas,nsp),     &
     &                ei3(-nr3:nr3,nas,nsp), eigrb(ngb,nas,nsp),        &
     &                rhog(ng,nspin), sfac(ngs,nsp)
!
      integer irb(3,natx,nsx), iss, isup, isdw, ig, ir,i,j,k,is, ia
      real(kind=8) fion1(3,natx), vave, ebac, wz, eh
      complex(kind=8)  fp, fm, ci
      complex(kind=8), pointer:: v(:), vs(:)
      complex(kind=8), allocatable:: rhotmp(:), vtemp(:), drhotmp(:,:,:)
!
      call start_clock( 'vofrho' )
      ci=(0.,1.)
!
!     wz = factor for g.neq.0 because of c*(g)=c(-g)
!
      wz = 2.0
      v => wrk1
      vs=> wrk1
      allocate(vtemp(ng))
      allocate(rhotmp(ng))
      if (tpre) allocate(drhotmp(ng,3,3))
!
!     first routine in which fion is calculated: annihilation
!
      fion =0.d0
      fion1=0.d0
!
!     ===================================================================
!     forces on ions, ionic term in real space
!     -------------------------------------------------------------------
      if( tprnfor .or. tfor .or. tfirst .or. thdyn ) then
        call force_ion(tau0,esr,fion,dsr)
      end if
!
      if(nspin.eq.1) then
         iss=1
         do ig=1,ng
            rhotmp(ig)=rhog(ig,iss)
         end do
         if(tpre)then
            do j=1,3
               do i=1,3
                  do ig=1,ng
                     drhotmp(ig,i,j)=drhog(ig,iss,i,j)
                  enddo
               enddo
            enddo
         endif
      else
         isup=1
         isdw=2
         do ig=1,ng
            rhotmp(ig)=rhog(ig,isup)+rhog(ig,isdw)
         end do
         if(tpre)then
            do i=1,3
               do j=1,3
                  do ig=1,ng
                     drhotmp(ig,i,j) = drhog(ig,isup,i,j) +           &
     &                                 drhog(ig,isdw,i,j)
                  enddo
               enddo
            enddo
         endif
      end if
!     ===================================================================
!     calculation local potential energy
!     -------------------------------------------------------------------
      vtemp=(0.,0.)
      do is=1,nsp
         do ig=1,ngs
            vtemp(ig)=vtemp(ig)+conjg(rhotmp(ig))*sfac(ig,is)*vps(ig,is)
         end do
      end do
!
      epseu=wz*real(SUM(vtemp))
      if (gstart == 2) epseu=epseu-vtemp(1)
      call reduce(1,epseu)
      epseu=epseu*omega
!
      if(tpre) call denps(rhotmp,drhotmp,sfac,vtemp,dps)
!
!     ===================================================================
!     calculation hartree energy
!     -------------------------------------------------------------------
      do is=1,nsp
         do ig=1,ngs
            rhotmp(ig)=rhotmp(ig)+sfac(ig,is)*rhops(ig,is)
         end do
      end do
      if (gstart == 2) vtemp(1)=0.0
      do ig=gstart,ng
         vtemp(ig)=conjg(rhotmp(ig))*rhotmp(ig)/g(ig)
      end do
!
      eh=real(SUM(vtemp))*wz*0.5*fpi/tpiba2
      call reduce(1,eh)
      if(tpre) call denh(rhotmp,drhotmp,sfac,vtemp,eh,dh)
      if(tpre) deallocate(drhotmp)
!     ===================================================================
!     forces on ions, ionic term in reciprocal space
!     -------------------------------------------------------------------
      if( tprnfor .or. tfor .or. thdyn)                                                  &
     &    call force_ps(rhotmp,rhog,vtemp,ei1,ei2,ei3,fion1)
!     ===================================================================
!     calculation hartree + local pseudo potential
!     -------------------------------------------------------------------
!
      if (gstart == 2) vtemp(1)=(0.,0.)
      do ig=gstart,ng
         vtemp(ig)=rhotmp(ig)*fpi/(tpiba2*g(ig))
      end do
!
      do is=1,nsp
         do ig=1,ngs
            vtemp(ig)=vtemp(ig)+sfac(ig,is)*vps(ig,is)
         end do
      end do
!
!     vtemp = v_loc(g) + v_h(g)
!
!     ===================================================================
!      calculation exchange and correlation energy and potential
!     -------------------------------------------------------------------
      if (nlcc_any) call add_cc(rhoc,rhog,rhor)
!
      call exch_corr_h(nspin,rhog,rhor,exc,dxc)
!
!     rhor contains the xc potential in r-space
!
!     ===================================================================
!     fourier transform of xc potential to g-space (dense grid)
!     -------------------------------------------------------------------
!
      if(nspin.eq.1) then
         iss=1
         do ir=1,nnr
            v(ir)=cmplx(rhor(ir,iss),0.0)
         end do
!
!     v_xc(r) --> v_xc(g)
!
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         do ig=1,ng
            rhog(ig,iss)=vtemp(ig)+v(np(ig))
         end do
!
!     v_tot(g) = (v_tot(g) - v_xc(g)) +v_xc(g)
!     rhog contains the total potential in g-space
!
      else
         isup=1
         isdw=2
         do ir=1,nnr
            v(ir)=cmplx(rhor(ir,isup),rhor(ir,isdw))
         end do
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ig=1,ng
            fp=v(np(ig))+v(nm(ig))
            fm=v(np(ig))-v(nm(ig))
            rhog(ig,isup)=vtemp(ig)+0.5*cmplx( real(fp),aimag(fm))
            rhog(ig,isdw)=vtemp(ig)+0.5*cmplx(aimag(fp),-real(fm))
         end do
      endif
!
!     rhog contains now the total (local+Hartree+xc) potential in g-space
!
      if( tprnfor .or. tfor ) then
         if (nlcc_any) call force_cc(irb,eigrb,rhor,fion1)
         call reduce(3*natx,fion1)
!
!    add g-space ionic and core correction contributions to fion
!
         fion = fion + fion1

      end if
!     ===================================================================
!     fourier transform of total potential to r-space (dense grid)
!     -------------------------------------------------------------------
      v(:) = (0.d0, 0.d0)
      if(nspin.eq.1) then
         iss=1
         do ig=1,ng
            v(np(ig))=rhog(ig,iss)
            v(nm(ig))=conjg(rhog(ig,iss))
         end do
!
!     v(g) --> v(r)
!
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         do ir=1,nnr
            rhor(ir,iss)=real(v(ir))
         end do
!
!     calculation of average potential
!
         vave=SUM(rhor(:,iss))/dble(nr1*nr2*nr3)
      else
         isup=1
         isdw=2
         do ig=1,ng
            v(np(ig))=rhog(ig,isup)+ci*rhog(ig,isdw)
            v(nm(ig))=conjg(rhog(ig,isup)) +ci*conjg(rhog(ig,isdw))
         end do
!
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ir=1,nnr
            rhor(ir,isup)= real(v(ir))
            rhor(ir,isdw)=aimag(v(ir))
         end do
!
!     calculation of average potential
!
         vave=(SUM(rhor(:,isup))+SUM(rhor(:,isdw)))       &
     &        /2.0/dble(nr1*nr2*nr3)
      endif
      call reduce(1,vave)
!     ===================================================================
!     fourier transform of total potential to r-space (smooth grid)
!     -------------------------------------------------------------------
      vs (:) = (0.d0, 0.d0)
      if(nspin.eq.1)then
         iss=1
         do ig=1,ngs
            vs(nms(ig))=conjg(rhog(ig,iss))
            vs(nps(ig))=rhog(ig,iss)
         end do
!
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!
         do ir=1,nnrsx
            rhos(ir,iss)=real(vs(ir))
         end do
      else
         isup=1
         isdw=2
         do ig=1,ngs
            vs(nps(ig))=rhog(ig,isup)+ci*rhog(ig,isdw)
            vs(nms(ig))=conjg(rhog(ig,isup)) +ci*conjg(rhog(ig,isdw))
         end do 
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
         do ir=1,nnrsx
            rhos(ir,isup)= real(vs(ir))
            rhos(ir,isdw)=aimag(vs(ir))
         end do
      endif

      ebac=0.0
!
      eht=eh*omega+esr-eself
!
!     etot is the total energy ; ekin, enl were calculated in rhoofr
!
      etot=ekin+eht+epseu+enl+exc+ebac
      if(tpre) detot=dekin+dh+dps+denl+dxc+dsr
!
      if(tvlocw.and.tlast)then
#ifdef __PARA
         call write_rho(46,nspin,rhor)
#else
         write(46) ((rhor(ir,iss),ir=1,nnr),iss=1,nspin)
#endif
      endif
!
      deallocate(rhotmp)
      deallocate(vtemp)
!
!
      call stop_clock( 'vofrho' )
      if((nfi.eq.0).or.tfirst.or.tlast) goto 999
      if(mod(nfi-1,iprint).ne.0 ) return
!
 999  WRITE( stdout,1) etot,ekin,eht,esr,eself,epseu,enl,exc,vave
    1 format(//'                total energy = ',f14.5,' a.u.'/         &
     &         '              kinetic energy = ',f14.5,' a.u.'/         &
     &         '        electrostatic energy = ',f14.5,' a.u.'/         &
     &         '                         esr = ',f14.5,' a.u.'/         &
     &         '                       eself = ',f14.5,' a.u.'/         &
     &         '      pseudopotential energy = ',f14.5,' a.u.'/         &
     &         '  n-l pseudopotential energy = ',f14.5,' a.u.'/         &
     &         ' exchange-correlation energy = ',f14.5,' a.u.'/         &
     &         '           average potential = ',f14.5,' a.u.'//)
!
      if(tpre)then
         WRITE( stdout,*) "cell parameters h"
         WRITE( stdout,5555) (a1(i),a2(i),a3(i),i=1,3)
         WRITE( stdout,*)
         WRITE( stdout,*) "derivative of e(tot)"
         WRITE( stdout,5555) ((detot(i,j),j=1,3),i=1,3)
         WRITE( stdout,*)
         if(tpre.and.iprsta.ge.2) then
            WRITE( stdout,*) "derivative of e(kin)"
            WRITE( stdout,5555) ((dekin(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(electrostatic)"
            WRITE( stdout,5555) (((dh(i,j)+dsr(i,j)),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(h)"
            WRITE( stdout,5555) ((dh(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(sr)"
            WRITE( stdout,5555) ((dsr(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(ps)"
            WRITE( stdout,5555) ((dps(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(nl)"
            WRITE( stdout,5555) ((denl(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(xc)"
            WRITE( stdout,5555) ((dxc(i,j),j=1,3),i=1,3)
         endif
      endif
5555  format(1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5//)
!
      return
      end

!=====================================================================
! exchange-correlation section
!=====================================================================
!______________________________________________________________________
      subroutine ggablyp4(nspin,rhog,gradr,rhor,exc)
!     _________________________________________________________________
!     becke-lee-yang-parr gga
!     
!     exchange: becke, pra 38, 3098 (1988) but derived from
!        pw91 exchange formula given in prb 48, 14944 (1993)
!        by setting "b3" and "b4" to 0.0
!     correlation: miehlich et al., cpl 157, 200 (1989) 
!     method by ja white & dm bird, prb 50, 4954 (1994) 
!
!     spin-polarized version by andras stirling 10/1998,
!     using original gga program of alfredo pasquarello 22/09/1994
!     and spin-unpolarized blyp routine of olivier parisel and 
!     alfredo pasquarello (02/1997)  
!
      use gvec
      !use parm
      use grid_dimensions, only: nnr => nnrx
      use constants, only: pi, fpi
!
      implicit none
! input
      integer nspin
      complex(kind=8) rhog(ng,nspin)
      real(kind=8) gradr(nnr,3,nspin), rhor(nnr,nspin)
! output
! on output: rhor contains the exchange-correlation potential
      real(kind=8)  exc
! local
      integer isdw, isup, isign, ir
!
      real(kind=8) abo, agdr, agdr2, agr, agr2, agur, agur2, arodw,     &
     &      arodw2, aroe, aroe2, aroup, aroup2, ax
      real(kind=8) byagdr, byagr, byagur, cden, cf, cl1, cl11, cl2,     &
     &      cl21, cl22, cl23, cl24, cl25, cl26, cl27, clyp, csum
      real(kind=8) dddn, dexcdg, dexcdgd, dexcdgu, df1d, df1u, df2d,    &
     &     df2u, dfd, dfnum1d, dfnum1u, dfnum2d, dfnum2u, dfs, dfu,     &
     &     dfxdd, dfxdg, dfxdgd, dfxdgu, dfxdu, dilta, dilta119, dl1dn, &
     &     dl1dnd, dl1dnu, dl2dd, dl2dg, dl2dgd, dl2dgu, dl2dn,         &
     &     dl2dnd, dl2dnd1, dl2dnu, dl2dnu1, dl2do, dlt, dodn,          &
     &     disign, dwsign, dys, dysd, dysu
      real(kind=8) ex, excupdt, exd, exu, fac1, fac2, factor1, factor2, &
     &     fx, fxd, fxden, fxdend, fxdenu, fxnum, fxnumd, fxnumu, fxu
      real(kind=8) gkf, gkfd, gkfu, grdx, grdy, grdz, grux, gruy, gruz, &
     &     grx, gry, grz
      real(kind=8) omiga, pd, pi2, pider2, piexch, pu
      real(kind=8) rhodw, rhoup, roe, roedth, roeth, roeuth, rometh
      real(kind=8) s, s2, sd, sd2, sddw, sdup, su, su2, sysl, sysld, syslu
      real(kind=8) t113, upsign, usign
      real(kind=8) x1124, x113, x118, x13, x143, x19, x23, x43,         &
     &     x4718, x53, x672, x718, x772, x83
      real(kind=8) ys, ysd, ysl, ysld, yslu, ysr, ysrd, ysru, ysu   
!===========================================================================
      real(kind=8) bb1, bb2, bb5, aa, bb, cc, dd, delt, eps
      parameter(bb1=0.19644797,bb2=0.2742931,bb5=7.79555418,            &
     &     aa=0.04918,                                                  &
     &     bb=0.132,cc=0.2533,dd=0.349,delt=1.0e-12,eps=1.0e-14)
!
!
      x13=1.0/3.0
      x19=1.0/9.0
      x23=2.0/3.0
      x43=4.0/3.0
      x53=5.0/3.0
      x83=8.0/3.0
      x113=11.0/3.0
      x4718=47.0/18.0
      x718=7.0/18.0
      x118=1.0/18.0
      x1124=11.0/24.0
      x143=14.0/3.0
      x772=7.0/72.0
      x672=6.0/72.0
!     
!     _________________________________________________________________
!     derived parameters from pi
!
      pi2=pi*pi
      ax=-0.75*(3.0/pi)**x13
      piexch=-0.75/pi 
      pider2=(3.0*pi2)**x13
      cf=0.3*pider2*pider2
!     _________________________________________________________________
!     other parameters
!
      t113=2.0**x113
!
      rhodw=0.0
      grdx=0.0
      grdy=0.0
      grdz=0.0
!
      fac1=1.0
!     _________________________________________________________________
!     main loop
!
      isup=1
      isdw=2
      do ir=1,nnr
         rhoup=rhor(ir,isup)
         grux=gradr(ir,1,isup)
         gruy=gradr(ir,2,isup)
         gruz=gradr(ir,3,isup)
         if(nspin.eq.2) then
            rhodw=rhor(ir,isdw)
            grdx=gradr(ir,1,isdw)
            grdy=gradr(ir,2,isdw)
            grdz=gradr(ir,3,isdw)
         else
            rhodw=0.0
            grdx =0.0
            grdy =0.0
            grdz =0.0
         endif
         roe=rhoup+rhodw
         if(roe.eq.0.0) goto 100
         aroup=abs(rhoup)
         arodw=abs(rhodw)
         aroe=abs(roe)
         grx=grux + grdx
         gry=gruy + grdy
         grz=gruz + grdz
         agur2=grux*grux+gruy*gruy+gruz*gruz
         agur=sqrt(agur2)
         agdr2=grdx*grdx+grdy*grdy+grdz*grdz
         agdr=sqrt(agdr2)
         agr2=grx*grx+gry*gry+grz*grz
         agr=sqrt(agr2)
         roeth=aroe**x13
         rometh=1.0/roeth
         gkf=pider2*roeth
         sd=1.0/(2.0*gkf*aroe)
         s=agr*sd
         s2=s*s
!     _________________________________________________________________
!     exchange 
!
         if(nspin.eq.1) then
!
!
            ysr=sqrt(1.0+bb5*bb5*s2)
            ys=bb5*s+ysr
            ysl=log(ys)*bb1
            sysl=s*ysl
            fxnum=1.0+sysl+bb2*s2
            fxden=1.0/(1.0+sysl)
            fx=fxnum*fxden
!
            ex=ax*fx*roeth*aroe
!
!     ### potential contribution ###
!
            dys=bb5*(1.0+bb5*s/ysr)/ys
            dfs=-fxnum*(ysl+bb1*s*dys)*fxden*fxden                      &
     &           +(ysl+bb1*s*dys+2.0*s*bb2)*fxden
            dfxdu=(ax*roeth*x43)*(fx-dfs*s)
            dfxdg=ax*roeth*dfs*sd
!
!     ### end of potential contribution ###
!     
         else
!
            roeuth=(2.0*aroup)**x13
            roedth=(2.0*arodw)**x13
            gkfu=pider2*roeuth*aroup
            gkfd=pider2*roedth*arodw
            upsign=sign(1.d0,gkfu-eps)
            dwsign=sign(1.d0,gkfd-eps)
            factor1=0.5*(1+upsign)/(gkfu+(1-upsign)*eps)
            fac1=gkfu*factor1
            factor2=0.5*(1+dwsign)/(gkfd+(1-dwsign)*eps)
            fac2=gkfd*factor2
            sdup=1.0/2.0*factor1
            sddw=1.0/2.0*factor2
            su=agur*sdup
            su2=su*su
            sd=agdr*sddw
            sd2=sd*sd
!
            ysru=sqrt(1.0+bb5*bb5*su2)
            ysu=bb5*su+ysru
            yslu=log(ysu)*bb1
            syslu=su*yslu
            fxnumu=1.0+syslu+bb2*su2
            fxdenu=1.0/(1.0+syslu)
            fxu=fxnumu*fxdenu
            exu=piexch*2.0*gkfu*fxu*fac1
!
            ysrd=sqrt(1.0+bb5*bb5*sd2)
            ysd=bb5*sd+ysrd
            ysld=log(ysd)*bb1
            sysld=sd*ysld
            fxnumd=1.0+sysld+bb2*sd2
            fxdend=1.0/(1.0+sysld)
            fxd=fxnumd*fxdend
            exd=piexch*2.0*gkfd*fxd*fac2
!
            ex=0.5*(exu+exd)
!
!     ### potential contribution ###
!
            dysu=bb5*(1.0+bb5*su/ysru)/ysu
            pu=2.0*su*bb2
            dfnum1u=yslu+bb1*su*dysu+pu
            df1u=dfnum1u*fxdenu
            dfnum2u=fxnumu*(yslu+bb1*su*dysu)
            df2u=dfnum2u*fxdenu*fxdenu
            dfu=df1u-df2u
            dfxdu=ax*roeuth*x43*1.0*(fxu-dfu*su)*fac1
            dfxdgu=ax*aroup*roeuth*dfu*sdup*fac1
!
            dysd=bb5*(1.0+bb5*sd/ysrd)/ysd
            pd=2.0*sd*bb2
            dfnum1d=ysld+bb1*sd*dysd+pd
            df1d=dfnum1d*fxdend
            dfnum2d=fxnumd*(ysld+bb1*sd*dysd)
            df2d=dfnum2d*fxdend*fxdend
            dfd=df1d-df2d
            dfxdd=ax*roedth*x43*1.0*(fxd-dfd*sd)*fac2
            dfxdgd=ax*arodw*roedth*dfd*sddw*fac2
!     
!     ### end of potential contribution ###
!
         endif
!     _________________________________________________________________
!     correlation lyp(aroe,aroup,arodw,agr,agur,agdr)
!
         cden=1.0+dd*rometh
         cl1=-aa/cden
!
         omiga=exp(-cc*rometh)/cden/aroe**x113
         dilta=rometh*(cc+dd/cden)
         aroe2=aroe*aroe
         abo=aa*bb*omiga
!
         dodn=x13*omiga/aroe*(dilta-11.0)
         dddn=x13*(dd*dd*aroe**(-x53)/cden/cden-dilta/aroe)
!
         if(nspin.eq.1) then
!
            cl1=cl1*aroe
!
            cl21=4.0*cf*aroe**x83
            cl22=(x4718-x718*dilta)*agr2
            cl23=(2.5-x118*dilta)*agr2/2.0
            cl24=(dilta-11.0)/9.0*agr2/4.0
            cl25=x1124*agr2
!
            cl2=-abo*aroe2*(0.25*(cl21+cl22-cl23-cl24)-cl25)
!
!     ### potential contribution ###
!
            dl1dnu=-aa*(1/cden+x13*dd*rometh/cden/cden)
!
            dlt=x672+2.0*x772*dilta
            dl2dn=-abo*aroe*(cf*x143*aroe**x83-dlt*agr2)
            dl2do=cl2/omiga
            dl2dd=abo*aroe2*x772*agr2
            dl2dnu=dl2dn+dl2do*dodn+dl2dd*dddn
!     
            dl2dg=abo*aroe2*agr*dlt
!
!     ### end of potential contribution ###
!
         else
!
            cl11=cl1*4.0/aroe
            cl1=cl11*aroup*arodw
!
            aroup2=aroup*aroup
            arodw2=arodw*arodw
!
            cl21=t113*cf*(aroup**x83+arodw**x83)
            cl22=(x4718-x718*dilta)*agr2
            cl23=(2.5-x118*dilta)*(agur2+agdr2)
            dilta119=(dilta-11.0)/9.0
            cl24=dilta119/aroe*(aroup*agur2+arodw*agdr2)
            cl25=x23*aroe2*agr2
            cl26=(x23*aroe2-aroup2)*agdr2
            cl27=(x23*aroe2-arodw2)*agur2
!
            csum=cl21+cl22-cl23-cl24
            cl2=-abo*(aroup*arodw*csum-cl25+cl26+cl27)
!
!     ### potential contribution ###
!
!     *** cl1 has changed its form! ***
!
            dl1dn=cl1/aroe*(x13*dd/cden*rometh-1.0)
            dl1dnu=dl1dn+cl11*arodw
            dl1dnd=dl1dn+cl11*aroup
!     
            dl2dnu1=arodw*csum+                                         &
     &           arodw*aroup*(t113*cf*x83*aroup**x53-                   &
     &           dilta119*arodw/aroe2*(agur2-agdr2))-x43*aroe*agr2+     &
     &           x23*agdr2*(2.0*arodw-aroup)+x43*aroe*agur2
            dl2dnd1=aroup*csum+                                         &
     &           aroup*arodw*(t113*cf*x83*arodw**x53+                   &
     &           dilta119*aroup/aroe2*(agur2-agdr2))-x43*aroe*agr2+     &
     &           x23*agur2*(2.0*aroup-arodw)+x43*aroe*agdr2
!
            dl2do=cl2/omiga
            dl2dd=-abo*aroup*arodw*                                     &
     &           (-x718*agr2+x118*(agur2+agdr2)-                        &
     &           x19*(aroup*agur2+arodw*agdr2)/aroe)
!
            dl2dnu=-abo*dl2dnu1+dl2do*dodn+dl2dd*dddn
            dl2dnd=-abo*dl2dnd1+dl2do*dodn+dl2dd*dddn
!
            dl2dg=-abo*                                                 &
     &           (aroup*arodw*2.0*(x4718-x718*dilta)*agr-               &
     &           x43*aroe2*agr) 
            dl2dgu=-2.0*abo*agur*((x118*dilta-2.5-                      &
     &           dilta119*aroup/aroe)*aroup*arodw                       &
     &           +x23*aroe2-arodw2)
            dl2dgd=-2.0*abo*agdr*((x118*dilta-2.5-                      &
     &           dilta119*arodw/aroe)*aroup*arodw                       &
     &           +x23*aroe2-aroup2)
!
         endif
!
         clyp=cl1+cl2
!     _________________________________________________________________
!     updating of xc-energy
!
         excupdt=ex+clyp
!
         exc=exc+excupdt
!
!     _________________________________________________________________
!     first part xc-potential construction
!
!
         rhor(ir,isup)=dfxdu+(dl1dnu+dl2dnu)*fac1
         isign=sign(1.d0,agr-delt)
         byagr=0.5*(1+isign)/(agr+(1-isign)*delt)
!
         if(nspin.eq.1) then
!
            dexcdg=(dfxdg*aroe+dl2dg)*byagr
            gradr(ir,1,isup)=grx*dexcdg
            gradr(ir,2,isup)=gry*dexcdg
            gradr(ir,3,isup)=grz*dexcdg
!
         else
!
            rhor(ir,isdw)=dfxdd+(dl1dnd+dl2dnd)*fac2
!
            usign =sign(1.d0,agur-delt)
            disign=sign(1.d0,agdr-delt)
            byagur=0.5*(1+ usign)/(agur+(1- usign)*delt)
            byagdr=0.5*(1+disign)/(agdr+(1-disign)*delt)
!
            dexcdgu=(dfxdgu+dl2dgu)*byagur
            dexcdgd=(dfxdgd+dl2dgd)*byagdr
            dexcdg=dl2dg*byagr
!
            gradr(ir,1,isup)=(dexcdgu*grux+dexcdg*grx)*fac1
            gradr(ir,2,isup)=(dexcdgu*gruy+dexcdg*gry)*fac1
            gradr(ir,3,isup)=(dexcdgu*gruz+dexcdg*grz)*fac1
            gradr(ir,1,isdw)=(dexcdgd*grdx+dexcdg*grx)*fac2
            gradr(ir,2,isdw)=(dexcdgd*grdy+dexcdg*gry)*fac2
            gradr(ir,3,isdw)=(dexcdgd*grdz+dexcdg*grz)*fac2
!
         endif
!          
 100     continue
      end do
!
      call reduce(1,exc)
      return
      end
!
!______________________________________________________________________
      subroutine ggapbe(nspin,rhog,gradr,rhor,excrho)
!     _________________________________________________________________
!     Perdew-Burke-Ernzerhof gga
!     Perdew, et al. PRL 77, 3865, 1996
!
      use gvec
      !use parm
      use grid_dimensions, only: nnr => nnrx
      use constants, only: pi, fpi
!
      implicit none
! input
      integer nspin
      complex(kind=8) rhog(ng,nspin)
      real(kind=8)  gradr(nnr,3,nspin), rhor(nnr,nspin)
! output: excrho: exc * rho ;  E_xc = \int excrho(r) d_r
! output: rhor:   contains the exchange-correlation potential
      real(kind=8)  excrho
! local
      integer ir, icar, iss, isup, isdw, nspinx
      real(kind=8) lim1, lim2
      parameter ( lim1=1.d-8, lim2=1.d-8, nspinx=2 )
      real(kind=8) zet, arho(nspinx), grad(3,nspinx), agrad(nspinx),    &
     &     arhotot, gradtot(3), agradtot,                               &
     &     scl, scl1, wrkup, wrkdw,                                     &
     &     exrho(nspinx), dexdrho(nspinx), dexdg(nspinx),               &
     &     ecrho, decdrho(nspinx), decdg
!
!     main loop
!
      isup=1
      isdw=2
      do ir=1,nnr
!
         arho(isup) = abs(rhor(ir,isup))
         arhotot = arho(isup)
         zet = 0.d0
         do icar = 1, 3
            grad(icar,isup) = gradr(ir,icar,isup)
            gradtot(icar) = gradr(ir,icar,isup)
         enddo
!
         if (nspin.eq.2) then
            arho(isdw) = abs(rhor(ir,isdw))
            arhotot = abs(rhor(ir,isup)+rhor(ir,isdw))
            do icar = 1, 3
               grad(icar,isdw) = gradr(ir,icar,isdw)
               gradtot(icar) = gradr(ir,icar,isup)+gradr(ir,icar,isdw)
            enddo
            zet = (rhor(ir,isup) - rhor(ir,isdw)) / arhotot
            if (zet.ge. 1.d0) zet =  1.d0
            if (zet.le.-1.d0) zet = -1.d0
         endif
!
         do iss = 1, nspin
            agrad(iss) = sqrt( grad(1,iss)*grad(1,iss) +                &
     &                         grad(2,iss)*grad(2,iss) +                &
     &                         grad(3,iss)*grad(3,iss) )
            agradtot = sqrt( gradtot(1)*gradtot(1) +                    &
     &                       gradtot(2)*gradtot(2) +                    &
     &                       gradtot(3)*gradtot(3) )
         enddo
!
!     _________________________________________________________________
!     First it calculates the energy density excrho
!     exrho:  exchange term
!     ecrho:  correlation term
!
         if ( nspin.eq.2 ) then
            scl = 2.d0
            scl1 = 0.5d0
         else
            scl = 1.d0
            scl1 = 1.d0
         endif
         do iss = 1, nspin
            if ( arho(iss).gt.lim1) then
               call exchpbe( scl*arho(iss), scl*agrad(iss),             &
     &                       exrho(iss),dexdrho(iss),dexdg(iss))
               excrho = excrho + scl1*exrho(iss)
            else
               dexdrho(iss) = 0.d0
               dexdg(iss) = 0.d0
            endif
         enddo
         if ( arhotot.gt.lim1) then
            call ecorpbe( arhotot, agradtot, zet, ecrho,                &
     &                    decdrho(1), decdrho(2), decdg, nspin )
            excrho = excrho + ecrho
         else
            decdrho(isup) = 0.d0
            decdrho(isdw) = 0.d0
            decdg = 0.d0
         endif
!     _________________________________________________________________
!     Now it calculates the potential and writes it in rhor
!     it uses the following variables:
!     dexdrho = d ( ex*rho ) / d (rho)
!     decdrho = d ( ec*rho ) / d (rho)
!     dexdg   = (d ( ex*rho ) / d (grad(rho)_i)) * agrad / grad_i
!     decdg   = (d ( ec*rho ) / d (grad(rho)_i)) * agrad / grad_i
!     gradr  here is used as a working array
!
!     _________________________________________________________________
!    first part of the xc-potential : D(rho*exc)/D(rho)
!
         do iss = 1, nspin
            rhor(ir,iss) = dexdrho(iss) + decdrho(iss)
         enddo
!
!     gradr = D(rho*exc)/D(|grad rho|) * (grad rho) / |grad rho|
!
         do iss = 1, nspin
            do icar = 1,3
               wrkup =0.d0
               wrkdw =0.d0
               if (agrad(iss).gt.lim2)                                  &
     &                    wrkup = dexdg(iss)*grad(icar,iss)/agrad(iss)
               if (agradtot.gt.lim2)                                    &
     &                    wrkdw = decdg*gradtot(icar)/agradtot
               gradr(ir,icar,iss) = wrkup + wrkdw
            enddo
         enddo
!
      end do
!
      call reduce(1,excrho)
!
      return
      end
!
!______________________________________________________________________
      subroutine exchpbe(rho,agrad,ex,dexdrho,dexdg)
!     _________________________________________________________________
!
! Perdew-Burke-Ernzerhof gga, Exchange term:
! Calculates the exchange energy density and the two functional derivative
! that will be used to calculate the potential
!
      implicit none
! input
! input rho:     charge density
! input agrad:   abs(grad rho)
      real(kind=8) rho, agrad
! ouput
! output ex: Ex[rho,grad_rho] = \int ex dr
! output dexdrho: d ex / d rho
! output dexdg:   d ex / d grad_rho(i) = dexdg*grad_rho(i)/abs(grad_rho)
      real(kind=8) ex, dexdrho, dexdg
! local
      real(kind=8) thrd, thrd4, pi32td, ax, al, um, uk, ul
      parameter(thrd=.33333333333333333333d0,thrd4=4.d0/3.d0)
      parameter(pi32td=3.09366772628014d0) ! pi32td=(3.d0*pi*pi)**0.333d0
      parameter(al=0.161620459673995d0)    ! al=1.0/(2.0*(pi32)**0.333d0)
      parameter(ax=-0.738558766382022405884230032680836d0)
      parameter(um=0.2195149727645171d0,uk=0.8040d0,ul=um/uk)
!
      real(kind=8) rhothrd, exunif, dexunif, kf, s, s2, p0, fxpbe, fs
!----------------------------------------------------------------------
! construct LDA exchange energy density
!
      rhothrd = rho**thrd
      dexunif = ax*rhothrd
      exunif  = rho*dexunif
!----------------------------------------------------------------------
! construct PBE enhancement factor
!
      kf = pi32td*rhothrd
      s = agrad/(2.d0*kf*rho)
      s2 = s*s
      p0 = 1.d0 + ul*s2
      fxpbe = 1.d0 + uk - uk/p0
      ex = exunif*fxpbe
!----------------------------------------------------------------------
! now calculates the potential terms
!
!  fs=(1/s)*d fxPBE/ ds
!
      fs=2.d0*uk*ul/(p0*p0)
      dexdrho = dexunif*thrd4*(fxpbe-s2*fs)
      dexdg = ax*al*s*fs
!
      return
      end
!----------------------------------------------------------------------
      subroutine ecorpbe(rho,agrad,zet,ectot,decup,decdn,decdg,nspin)
!     -----------------------------------------------------------------
!
!  Adapted from the Official PBE correlation code. K. Burke, May 14, 1996.
!
!   input: rho   = rho_up + rho_down; total  charge density
!   input: agrad = abs( grad(rho) )
!   input: zet   = (rho_up-rho_down)/rho
!   input: nspin
!  output: ectot = ec*rho       ---correlation energy density---
!  output: decup = d ( ec*rho ) / d (rho_up)
!  output: decdn = d ( ec*rho ) / d (rho_down)
!  output: decdg = (d ( ec*rho ) / d (grad(rho)_i)) * agrad / grad_i
!----------------------------------------------------------------------
!----------------------------------------------------------------------
! References:
! [a] J.P.~Perdew, K.~Burke, and M.~Ernzerhof, 
!     {\sl Generalized gradient approximation made simple}, sub.
!     to Phys. Rev.Lett. May 1996.
! [b] J. P. Perdew, K. Burke, and Y. Wang, {\sl Real-space cutoff
!     construction of a generalized gradient approximation:  The PW91
!     density functional}, submitted to Phys. Rev. B, Feb. 1996.
! [c] J. P. Perdew and Y. Wang, Phys. Rev. B {\bf 45}, 13244 (1992).
!----------------------------------------------------------------------
!----------------------------------------------------------------------
      implicit none
      real(kind=8) rho, agrad, zet, ectot, decup, decdn, decdg
      integer nspin
      real(kind=8) pi, pi32, alpha, thrd, thrdm, thrd2, sixthm, thrd4,  &
     &     gam, fzz, gamma, bet, delt, eta
! thrd*=various multiples of 1/3
! numbers for use in LSD energy spin-interpolation formula, [c](9).
!      gam= 2^(4/3)-2
!      fzz=f''(0)= 8/(9*gam)
! numbers for construction of PBE
!      gamma=(1-log(2))/pi^2
!      bet=coefficient in gradient expansion for correlation, [a](4).
!      eta=small number to stop d phi/ dzeta from blowing up at 
!          |zeta|=1.
      parameter(pi=3.1415926535897932384626433832795d0)
      parameter(pi32=29.608813203268075856503472999628d0)
      parameter(alpha=1.91915829267751300662482032624669d0)
      parameter(thrd=1.d0/3.d0,thrdm=-thrd,thrd2=2.d0*thrd)
      parameter(sixthm=thrdm/2.d0)
      parameter(thrd4=4.d0*thrd)
      parameter(gam=0.5198420997897463295344212145565d0)
      parameter(fzz=8.d0/(9.d0*gam))
      parameter(gamma=0.03109069086965489503494086371273d0)
      parameter(bet=0.06672455060314922d0,delt=bet/gamma)
      parameter(eta=1.d-12)
      real(kind=8) g, fk, rs, sk, twoksg, t
      real(kind=8) rtrs, eu, eurs, ep, eprs, alfm, alfrsm, z4, f, ec
      real(kind=8) ecrs, fz, eczet, comm, vcup, vcdn, g3, pon, b, b2, t2, t4
      real(kind=8) q4, q5, h, g4, t6, rsthrd, gz, fac
      real(kind=8) bg, bec, q8, q9, hb, hrs, hz, ht, pref
!----------------------------------------------------------------------
      if (nspin.eq.1) then
         g=1.d0
      else
         g=((1.d0+zet)**thrd2+(1.d0-zet)**thrd2)*0.5d0
      endif
      fk=(pi32*rho)**thrd
      rs=alpha/fk
      sk=sqrt(4.d0*fk/pi)
      twoksg=2.d0*sk*g
      t=agrad/(twoksg*rho)
!----------------------------------------------------------------------
!----------------------------------------------------------------------
! find LSD energy contributions, using [c](10) and Table I[c].
! eu=unpolarized LSD correlation energy
! eurs=deu/drs
! ep=fully polarized LSD correlation energy
! eprs=dep/drs
! alfm=-spin stiffness, [c](3).
! alfrsm=-dalpha/drs
! f=spin-scaling factor from [c](9).
! construct ec, using [c](8)
      rtrs=dsqrt(rs)
      call gcor2(0.0310907d0,0.21370d0,7.5957d0,3.5876d0,1.6382d0,      &
     &    0.49294d0,rtrs,eu,eurs)
      if (nspin.eq.2) then
         call gcor2(0.01554535d0,0.20548d0,14.1189d0,6.1977d0,3.3662d0, &
     &       0.62517d0,rtrs,ep,eprs)
         call gcor2(0.0168869d0,0.11125d0,10.357d0,3.6231d0,0.88026d0,  &
     &       0.49671d0,rtrs,alfm,alfrsm)
         z4 = zet**4
         f=((1.d0+zet)**thrd4+(1.d0-zet)**thrd4-2.d0)/gam
         ec = eu*(1.d0-f*z4)+ep*f*z4-alfm*f*(1.d0-z4)/fzz
!----------------------------------------------------------------------
!----------------------------------------------------------------------
! LSD potential from [c](A1)
! ecrs = dec/drs [c](A2)
! eczet=dec/dzeta [c](A3)
! fz = df/dzeta [c](A4)
         ecrs = eurs*(1.d0-f*z4)+eprs*f*z4-alfrsm*f*(1.d0-z4)/fzz
         fz = thrd4*((1.d0+zet)**thrd-(1.d0-zet)**thrd)/gam
         eczet = 4.d0*(zet**3)*f*(ep-eu+alfm/fzz)+fz*(z4*ep-z4*eu       &
     &           -(1.d0-z4)*alfm/fzz)
         comm = ec -rs*ecrs/3.d0-zet*eczet
         vcup = comm + eczet
         vcdn = comm - eczet
      else
         ecrs = eurs
         ec = eu
         vcup = ec -rs*ecrs/3.d0
      endif
!----------------------------------------------------------------------
!----------------------------------------------------------------------
! PBE correlation energy
! g=phi(zeta), given after [a](3)
! delt=bet/gamma
! b=a of [a](8)
!      g=((1.d0+zet)**thrd2+(1.d0-zet)**thrd2)/2.d0
      g3 = g**3
      pon=-ec/(g3*gamma)
      b = delt/(dexp(pon)-1.d0)
      b2 = b*b
      t2 = t*t
      t4 = t2*t2
      q4 = 1.d0+b*t2
      q5 = 1.d0+b*t2+b2*t4
      h = g3*(bet/delt)*dlog(1.d0+delt*Q4*t2/Q5)
      ectot = rho*(ec + h)
!----------------------------------------------------------------------
!----------------------------------------------------------------------
! energy done. Now the potential, using appendix e of [b].
      t6 = t4*t2
      rsthrd = rs/3.d0
      fac = delt/b+1.d0
      bec = b2*fac/(bet*g3)
      q8 = q5*q5+delt*q4*q5*t2
      q9 = 1.d0+2.d0*b*t2
      hb = -bet*g3*b*t6*(2.d0+b*t2)/q8
      hrs = -rsthrd*hb*bec*ecrs
      ht = 2.d0*bet*g3*q9/q8
      comm = h+hrs-7.d0*t2*ht/6.d0
      if (nspin.eq.2) then
         g4 = g3*g
         bg = -3.d0*b2*ec*fac/(bet*g4)
         gz=(((1.d0+zet)**2+eta)**sixthm-                               &
     &   ((1.d0-zet)**2+eta)**sixthm)/3.d0
         hz = 3.d0*gz*h/g + hb*(bg*gz+bec*eczet)
         pref = hz-gz*t2*ht/g
         decup = vcup + comm + pref*(  1.d0 - zet)
         decdn = vcdn + comm + pref*( -1.d0 - zet)
      else
         decup = vcup + comm
      endif
      decdg = t*ht/twoksg
!
      return
      end
!______________________________________________________________________
      subroutine gcor2(a,a1,b1,b2,b3,b4,rtrs,gg,ggrs)
!     _________________________________________________________________
! slimmed down version of GCOR used in PW91 routines, to interpolate
! LSD correlation energy, as given by (10) of
! J. P. Perdew and Y. Wang, Phys. Rev. B {\bf 45}, 13244 (1992).
! K. Burke, May 11, 1996.
!
      implicit none
      real(kind=8) a, a1, b1, b2, b3, b4, rtrs, gg, ggrs
      real(kind=8) q0, q1, q2, q3
!
      q0 = -2.d0*a*(1.d0+a1*rtrs*rtrs)
      q1 = 2.d0*a*rtrs*(b1+rtrs*(b2+rtrs*(b3+b4*rtrs)))
      q2 = dlog(1.d0+1.d0/q1)
      gg = q0*q2
      q3 = a*(b1/rtrs+2.d0*b2+rtrs*(3.d0*b3+4.d0*b4*rtrs))
      ggrs = -2.d0*a*a1*q2-q0*q3/(q1*(1.d0+q1))
!
      return
      end
!
!______________________________________________________________________
      subroutine ggapw(nspin,rhog,gradr,rhor,exc)
!     _________________________________________________________________
!     perdew-wang gga (PW91)
!
      use gvec
      !use parm
      use grid_dimensions, only: nnr => nnrx
      use constants, only: pi, fpi
!
      implicit none
! input
      integer nspin
      complex(kind=8) rhog(ng,nspin)
      real(kind=8) gradr(nnr,3,nspin), rhor(nnr,nspin)
! output
      real(kind=8) exc
! local
      integer isup, isdw, ir
      real(kind=8) rhoup, rhodw, roe, aroe, rs, zeta
      real(kind=8) grxu, gryu, grzu, grhou, grxd, gryd, grzd, grhod, grho
      real(kind=8) ex, ec,vc, sc, v1x, v2x, v1c, v2c
      real(kind=8) ecrs, eczeta
      real(kind=8) exup, vcup, v1xup, v2xup, v1cup
      real(kind=8) exdw, vcdw, v1xdw, v2xdw, v1cdw
      real(kind=8) pi34, third, small
      parameter (pi34=0.75d0/3.141592653589793d+00,third=1.d0/3.d0)
      parameter(small=1.d-10)
!
!     _________________________________________________________________
!     main loop
!
      isup=1
      isdw=2
      exc=0.0
      do ir=1,nnr
         rhoup=rhor(ir,isup)
         if(nspin.eq.2) then
            rhodw=rhor(ir,isdw)
         else
            rhodw=0.0
         end if
         roe=rhoup+rhodw
         aroe=abs(roe)
         if (aroe.lt.small) then
            rhor(ir,isup)   =0.0
            gradr(ir,1,isup)=0.0
            gradr(ir,2,isup)=0.0
            gradr(ir,3,isup)=0.0
            if(nspin.eq.2) then
               rhor(ir,isdw)   =0.0
               gradr(ir,1,isdw)=0.0
               gradr(ir,2,isdw)=0.0
               gradr(ir,3,isdw)=0.0
            end if
            go to 100
         end if
         grxu =gradr(ir,1,isup)
         gryu =gradr(ir,2,isup)
         grzu =gradr(ir,3,isup)
         grhou=sqrt(grxu**2+gryu**2+grzu**2)
         if(nspin.eq.2) then
            grxd =gradr(ir,1,isdw)
            gryd =gradr(ir,2,isdw)
            grzd =gradr(ir,3,isdw)
            grhod=sqrt(grxd**2+gryd**2+grzd**2)
         else
            grxd =0.0
            gryd =0.0
            grzd =0.0
            grhod=0.0
         endif
         grho=sqrt((grxu+grxd)**2+(gryu+gryd)**2+(grzu+grzd)**2)
!
         rs=(pi34/aroe)**third
         if (nspin.eq.1) then
            call exchpw91(aroe,grho,ex,v1x,v2x)
            call pwlda(rs,ec,vc,ecrs)
            call corpw91ns(rs,grho,ec,ecrs,sc,v1c,v2c)
            exc = exc + roe*(ex+ec) + sc
            rhor(ir,isup) = vc + v1x + v1c
!
!     gradr = D(rho*exc)/D(|grad rho|) * (grad rho) / |grad rho|
!
            gradr(ir,1,isup)=grxu*(v2x+v2c)
            gradr(ir,2,isup)=gryu*(v2x+v2c)
            gradr(ir,3,isup)=grzu*(v2x+v2c)
         else
            zeta=(rhoup-rhodw)/aroe        
            zeta=min(zeta, 1.d0)
            zeta=max(zeta,-1.d0)
            call exchpw91(2.d0*abs(rhoup),2.0*grhou,exup,v1xup,v2xup)
            call exchpw91(2.d0*abs(rhodw),2.0*grhod,exdw,v1xdw,v2xdw)
            call pwlsd(rs,zeta,ec,vcup,vcdw,ecrs,eczeta)
            call corpw91(rs,zeta,grho,ec,ecrs,eczeta,sc,v1cup,v1cdw,v2c)
            rhor(ir,isup) = vcup + v1xup + v1cup
            rhor(ir,isdw) = vcdw + v1xdw + v1cdw
            exc = exc+roe*(0.5*((1.d0+zeta)*exup+(1.d0-zeta)*exdw)+ec) &
    &             + sc
!
!     gradr = D(rho*exc)/D(|grad rho|) * (grad rho) / |grad rho|
!
            gradr(ir,1,isup)=grxu*(2.0*v2xup+v2c)+grxd*v2c
            gradr(ir,2,isup)=gryu*(2.0*v2xup+v2c)+gryd*v2c
            gradr(ir,3,isup)=grzu*(2.0*v2xup+v2c)+grzd*v2c
            gradr(ir,1,isdw)=grxd*(2.0*v2xdw+v2c)+grxu*v2c
            gradr(ir,2,isdw)=gryd*(2.0*v2xdw+v2c)+gryu*v2c
            gradr(ir,3,isdw)=grzd*(2.0*v2xdw+v2c)+grzu*v2c
         end if
 100     continue
      end do
!
      call reduce(1,exc)
!
      return
      end
!
!----------------------------------------------------------------------
      subroutine exchpw91(rho,grho,ex,v1x,v2x)
!----------------------------------------------------------------------
!
!  PW91 exchange for a spin-unpolarized electronic system
!  Modified from the "official" PBE code of Perdew, Burke et al.
!  input rho   : density
!  input grho:  abs(grad rho)
!  output:  exchange energy per electron (ex) and potentials
!          v1x = d(rho*exc)/drho
!          v2x = d(rho*exc)/d|grho| * (1/|grho|)
!
      implicit none
!  input
      real(kind=8) rho, grho
!  output
      real(kind=8) ex, v1x, v2x
! local
      real(kind=8) ex0, kf, s, s2, s4, f, fs, p0,p1,p2,p3,p4,p5,p6,p7
! parameters
      real(kind=8) a1, a2, a3, a4, a, b1, bx, pi34, thrd, thrd4
      parameter(a1=0.19645d0,a2=0.27430d0,a=7.7956d0,a4=100.d0)
! for becke exchange, set a3=b1=0
      parameter(a3=0.15084d0,b1=0.004d0)
! pi34=3/(4pi) ,  bx=(3pi^2)^(1/3)
      parameter(pi34=0.75d0/3.141592653589793d+00, bx=3.09366773d0,    &
     &          thrd=0.333333333333d0, thrd4=4.d0*thrd)
!
      if (rho.lt.1.d-10) then
         ex =0.0
         v1x=0.0
         v2x=0.0
      end if
!
!  kf=k_Fermi, ex0=Slater exchange energy
!
      kf = bx*(rho**thrd)
      ex0=-pi34*kf
      if (grho.lt.1.d-10) then
         ex =ex0
         v1x=ex0*thrd4
         v2x=0.0
      end if
      s  = grho/(2.d0*kf*rho)
      s2 = s*s
      s4 = s2*s2
      p0 = 1.d0/sqrt(1.d0+a*a*s2)
      p1 = log(a*s+1.d0/p0)
      p2 = exp(-a4*s2)
      p3 = 1.d0/(1.d0+a1*s*p1+b1*s4)
      p4 = 1.d0+a1*s*p1+(a2-a3*p2)*s2
!  f is the enhancement factor
      f = p3*p4
      ex = ex0*f
!  energy done. now the potential:
      p5 = b1*s2-(a2-a3*p2)
      p6 = a1*s*(p1+a*s*p0)
      p7 = 2.d0*(a2-a3*p2)+2.d0*a3*a4*s2*p2-4.d0*b1*s2*f
! fs = (1/s) dF(s)/ds
      fs = p3*(p3*p5*p6+p7)
      v1x = ex0*thrd4*(f-s2*fs)
      v2x = 0.5d0*ex0/kf*s*fs/grho
!
      return
      end
!
!----------------------------------------------------------------------
      subroutine corpw91ns(rs,grho,ec,ecrs,h,v1c,v2c)
!----------------------------------------------------------------------
!
!  PW91 correlation (gradient correction term) - no spin case
!  Modified from the "official" PBE code of Perdew, Burke et al.
!
!  input rs:   seitz radius
!  input zeta:  relative spin polarization
!  input grho: abs(grad rho)
!  input ec:   Perdew-Wang correlation energy
!  input ecrs:  d(rho*ec)/d r_s

!  output h  :  nonlocal part of correlation energy per electron
!  output v1c:  nonlocal parts of correlation potential
!         v1c = d(rho*exc)/drho
!         v2c = d(rho*exc)/d|grho|*(1/|grho|)
!
      implicit none
! input
      real(kind=8) rs, grho, ec, ecrs
! output
      real(kind=8) h, v1c, v2c
! local
      real(kind=8) rho, t, ks,  bet, delt, pon, b, b2, t2, t4, t6
      real(kind=8) q4, q5, q6, q7, q8, q9, r0, r1, r2, r3, r4, rs2, rs3
      real(kind=8) ccrs, rsthrd, fac, bec, coeff, cc
      real(kind=8) h0, h0b, h0rs, h0t, h1, h1t, h1rs, hrs, ht
! parameters
      real(kind=8) nu, cc0, cx, alf, c1, c2, c3, c4, c5, c6, a4
      real(kind=8) ax, pi34
      parameter(nu=15.75592d0,cc0=0.004235d0,cx=-0.001667212d0)
      parameter(c1=0.002568d0,c2=0.023266d0,c3=7.389d-6,c4=8.723d0)
      parameter(c5=0.472d0,c6=7.389d-2,a4=100.d0, alf=0.09d0)
! ax=(4*1.9191583/pi)^(1/2), where k_F=1.9191583/r_s, k_s=boh*r_s^(1/2)
      parameter(ax=1.5631853d0, pi34=0.75d0/3.141592653589793d0)
!
!
      rs2 = rs*rs
      rs3 = rs2*rs
      rho=pi34/rs3
!  k_s=(4k_F/pi)^(1/2)
      ks=ax/sqrt(rs)
!  t=abs(grad rho)/(rho*2.*ks)
      t=grho/(2.d0*rho*ks)
      bet = nu*cc0
      delt = 2.d0*alf/bet
      pon = -delt*ec/bet
      b = delt/(exp(pon)-1.d0)
      b2 = b*b
      t2 = t*t
      t4 = t2*t2
      t6 = t4*t2
      q4 = 1.d0+b*t2
      q5 = 1.d0+b*t2+b2*t4
      q6 = c1+c2*rs+c3*rs2
      q7 = 1.d0+c4*rs+c5*rs2+c6*rs3
      cc = -cx + q6/q7
      r0 = 0.663436444d0*rs
      r1 = a4*r0
      coeff = cc-cc0-3.d0*cx/7.d0
      r2 = nu*coeff
      r3 = exp(-r1*t2)
      h0 = (bet/delt)*log(1.d0+delt*q4*t2/q5)
      h1 = r3*r2*t2
      h = (h0+h1)*rho
!  energy done. now the potential:
      ccrs = (c2+2.*c3*rs)/q7 - q6*(c4+2.*c5*rs+3.*c6*rs2)/q7**2
      rsthrd = rs/3.d0
      r4 = rsthrd*ccrs/coeff
      fac = delt/b+1.d0
      bec = b2*fac/bet
      q8 = q5*q5+delt*q4*q5*t2
      q9 = 1.d0+2.d0*b*t2
      h0b = -bet*b*t6*(2.d0+b*t2)/q8
      h0rs = -rsthrd*h0b*bec*ecrs
      h0t = 2.*bet*q9/q8
      h1rs = r3*r2*t2*(-r4+r1*t2/3.d0)
      h1t = 2.d0*r3*r2*(1.d0-r1*t2)
      hrs = h0rs+h1rs
      ht = h0t+h1t
      v1c = h0+h1+hrs-7.d0*t2*ht/6.d0
      v2c = t*ht/(2.d0*ks*grho)
!
      return
      end
!
!----------------------------------------------------------------------
      subroutine corpw91(rs,zeta,grho,ec,ecrs,eczeta,h,v1cup,v1cdn,v2c)
!----------------------------------------------------------------------
!
!  PW91 correlation (gradient correction term)
!  Modified from the "official" PBE code of Perdew, Burke et al.
!
!  input rs:   seitz radius
!  input zeta:  relative spin polarization
!  input grho: abs(grad rho)
!  input ec:   Perdew-Wang correlation energy
!  input ecrs:  d(rho*ec)/d r_s ?
!  input eczeta: d(rho*ec)/d zeta ?

!  output h: nonlocal part of correlation energy per electron
!  output v1cup,v1cdn:  nonlocal parts of correlation potentials
!         v1c** = d(rho*exc)/drho               (up and down components)
!         v2c   = d(rho*exc)/d|grho|*(1/|grho|) (same for up and down)
!
      implicit none
! input
      real(kind=8) rs, zeta, grho, ec, ecrs, eczeta
! output
      real(kind=8) h, v1cup, v1cdn, v2c
! local
      real(kind=8) rho, g, t, ks, gz, bet, delt, g3, g4, pon, b, b2, t2, t4, t6
      real(kind=8) q4, q5, q6, q7, q8, q9, r0, r1, r2, r3, r4, rs2, rs3
      real(kind=8) ccrs, rsthrd, fac, bg, bec, coeff, cc
      real(kind=8) h0, h0b, h0rs, h0z, h0t, h1, h1t, h1rs, h1z
      real(kind=8) hz, hrs, ht, comm, pref
! parameters
      real(kind=8) nu, cc0, cx, alf, c1, c2, c3, c4, c5, c6, a4
      real(kind=8) thrdm, thrd2, ax, pi34, eta
      parameter(nu=15.75592d0,cc0=0.004235d0,cx=-0.001667212d0)
      parameter(c1=0.002568d0,c2=0.023266d0,c3=7.389d-6,c4=8.723d0)
      parameter(c5=0.472d0,c6=7.389d-2,a4=100.d0, alf=0.09d0)
      parameter(thrdm=-0.333333333333d0,thrd2=0.666666666667d0)
! ax=(4*1.9191583/pi)^(1/2), where k_F=1.9191583/r_s, k_s=boh*r_s^(1/2)
      parameter(ax=1.5631853d0, pi34=0.75d0/3.141592653589793d0)
      parameter(eta=1.d-12)
!
!
      if (grho.lt.1.d-10) then
         h=0.0
         v1cup=0.0
         v1cdn=0.0
         v2c=0.0
      end if
      rs2 = rs*rs
      rs3 = rs2*rs
      rho=pi34/rs3
      g=((1.d0+zeta)**thrd2+(1.d0-zeta)**thrd2)/2.d0
!  k_s=(4k_F/pi)^(1/2)
      ks=ax/sqrt(rs)
!  t=abs(grad rho)/(rho*2.*ks*g)
      t=grho/(2.d0*rho*g*ks)
      bet = nu*cc0
      delt = 2.d0*alf/bet
      g3 = g**3
      g4 = g3*g
      pon = -delt*ec/(g3*bet)
      b = delt/(exp(pon)-1.d0)
      b2 = b*b
      t2 = t*t
      t4 = t2*t2
      t6 = t4*t2
      q4 = 1.d0+b*t2
      q5 = 1.d0+b*t2+b2*t4
      q6 = c1+c2*rs+c3*rs2
      q7 = 1.d0+c4*rs+c5*rs2+c6*rs3
      cc = -cx + q6/q7
      r0 = 0.663436444d0*rs
      r1 = a4*r0*g4
      coeff = cc-cc0-3.d0*cx/7.d0
      r2 = nu*coeff*g3
      r3 = dexp(-r1*t2)
      h0 = g3*(bet/delt)*log(1.d0+delt*q4*t2/q5)
      h1 = r3*r2*t2
      h = (h0+h1)*rho
!  energy done. now the potential:
      ccrs = (c2+2.*c3*rs)/q7 - q6*(c4+2.*c5*rs+3.*c6*rs2)/q7**2
      rsthrd = rs/3.d0
      r4 = rsthrd*ccrs/coeff
!  eta is a small quantity that avoids trouble if zeta=+1 or -1
      gz = ((1.d0+zeta+eta)**thrdm - (1.d0-zeta+eta)**thrdm)/3.d0
      fac = delt/b+1.d0
      bg = -3.d0*b2*ec*fac/(bet*g4)
      bec = b2*fac/(bet*g3)
      q8 = q5*q5+delt*q4*q5*t2
      q9 = 1.d0+2.d0*b*t2
      h0b = -bet*g3*b*t6*(2.d0+b*t2)/q8
      h0rs = -rsthrd*h0b*bec*ecrs
      h0z = 3.d0*gz*h0/g + h0b*(bg*gz+bec*eczeta)
      h0t = 2.*bet*g3*q9/q8
      h1rs = r3*r2*t2*(-r4+r1*t2/3.d0)
      h1z = gz*r3*r2*t2*(3.d0-4.d0*r1*t2)/g
      h1t = 2.d0*r3*r2*(1.d0-r1*t2)
      hrs = h0rs+h1rs
      ht = h0t+h1t
      hz = h0z+h1z
      comm = h0+h1+hrs-7.d0*t2*ht/6.d0
      pref = hz-gz*t2*ht/g
      comm = comm-pref*zeta
      v1cup = comm + pref 
      v1cdn = comm - pref
      v2c   = t*ht/(2.d0*ks*g*grho)
!
      return
      end
!----------------------------------------------------------------------
      subroutine pwlda(rs,ec,vc,ecrs)
!----------------------------------------------------------------------
!
!  uniform-gas, spin-unpolarised correlation of perdew and wang 1991
!  input:  rs   seitz radius
!  output: ec   correlation energy per electron
!          vc   potential
!          ecrs derivatives of ec wrt rs
!
      implicit none
! input
      real(kind=8) rs
! output
      real(kind=8) ec, vc, ecrs
!  local
      real(kind=8) q0, rs12, q1, q2, q3
! parameters
      real(kind=8) a, a1, b1, b2, b3, b4
      parameter(a =0.0310907d0, a1=0.21370d0, b1=7.5957d0,              &
     &          b2=3.5876d0,    b3=1.6382d0,  b4=0.49294d0)
!
      q0 = -2.d0*a*(1.d0+a1*rs)
      rs12 = sqrt(rs)
      q1 = 2.d0*a*rs12*(b1+rs12*(b2+rs12*(b3+b4*rs12)))
      q2 = log(1.d0+1.d0/q1)
      ec = q0*q2
      q3 = a*(b1/rs12+2.d0*b2+3.d0*b3*rs12+2.d0*b4*2.d0*rs)
      ecrs = -2.d0*a*a1*q2-q0*q3/(q1**2+q1)
      vc = ec - rs*ecrs/3.d0
!
      return
      end
!----------------------------------------------------------------------
      subroutine pwlsd(rs,zeta,ec,vcup,vcdn,ecrs,eczeta)
!----------------------------------------------------------------------
!
!  uniform-gas correlation of perdew and wang 1991
!  Modified from the "official" PBE code of Perdew, Burke et al.
!  input: seitz radius (rs), relative spin polarization (zeta)
!  output: correlation energy per electron (ec)
!          up- and down-spin potentials (vcup,vcdn)
!          derivatives of ec wrt rs (ecrs) & zeta (eczeta)
!
      implicit none
! input
      real(kind=8) rs, zeta
! output
      real(kind=8) ec, vcup, vcdn, ecrs, eczeta
! local
      real(kind=8) f, eu, ep, eurs, eprs, alfm, alfrsm, z4, fz, comm
      real(kind=8) rs12, q0, q1, q2, q3
! parameters
      real(kind=8) gam, fzz, thrd, thrd4
      parameter(gam=0.5198421d0,fzz=1.709921d0)
      parameter(thrd=0.333333333333d0,thrd4=1.333333333333d0)
!
      real(kind=8) au, au1, bu1, bu2, bu3, bu4
      parameter(au =0.0310907d0, au1=0.21370d0, bu1=7.5957d0,           &
     &          bu2=3.5876d0,    bu3=1.6382d0,  bu4=0.49294d0)
      real(kind=8) ap, ap1, bp1, bp2, bp3, bp4
      parameter(ap =0.01554535d0,ap1=0.20548d0, bp1=14.1189d0,          &
     &          bp2=6.1977d0,    bp3=3.3662d0,  bp4=0.62517d0 )
      real(kind=8) am, am1, bm1, bm2, bm3, bm4
      parameter(am =0.0168869d0, am1=0.11125d0, bm1=10.357d0,           &
     &          bm2=3.6231d0,    bm3=0.88026d0, bm4=0.49671d0 )
!
      rs12 = sqrt(rs)
!
      q0 = -2.d0*au*(1.d0+au1*rs)
      q1 = 2.d0*au*rs12*(bu1+rs12*(bu2+rs12*(bu3+bu4*rs12)))
      q2 = log(1.d0+1.d0/q1)
      eu = q0*q2
      q3 = au*(bu1/rs12+2.d0*bu2+3.d0*bu3*rs12+2.d0*bu4*2.d0*rs)
      eurs = -2.d0*au*au1*q2-q0*q3/(q1**2+q1)
!
      q0 = -2.d0*ap*(1.d0+ap1*rs)
      q1 = 2.d0*ap*rs12*(bp1+rs12*(bp2+rs12*(bp3+bp4*rs12)))
      q2 = log(1.d0+1.d0/q1)
      ep = q0*q2
      q3 = ap*(bp1/rs12+2.d0*bp2+3.d0*bp3*rs12+2.d0*bp4*2.d0*rs)
      eprs = -2.d0*ap*ap1*q2-q0*q3/(q1**2+q1)
!
      q0 = -2.d0*am*(1.d0+am1*rs)
      q1 = 2.d0*am*rs12*(bm1+rs12*(bm2+rs12*(bm3+bm4*rs12)))
      q2 = log(1.d0+1.d0/q1)
!  alfm is minus the spin stiffness alfc
      alfm=q0*q2
      q3 = am*(bm1/rs12+2.d0*bm2+3.d0*bm3*rs12+2.d0*bm4*2.d0*rs)
      alfrsm=-2.d0*am*am1*q2-q0*q3/(q1**2+q1)
!
      f = ((1.d0+zeta)**thrd4+(1.d0-zeta)**thrd4-2.d0)/gam
      z4 = zeta**4
      ec = eu*(1.d0-f*z4)+ep*f*z4-alfm*f*(1.d0-z4)/fzz
!  energy done. now the potential:
      ecrs = eurs*(1.d0-f*z4)+eprs*f*z4-alfrsm*f*(1.d0-z4)/fzz
      fz = thrd4*((1.d0+zeta)**thrd-(1.d0-zeta)**thrd)/gam
      eczeta = 4.d0*(zeta**3)*f*(ep-eu+alfm/fzz)+fz*(z4*ep-z4*eu        &
     &        -(1.d0-z4)*alfm/fzz)
      comm = ec -rs*ecrs/3.d0-zeta*eczeta
      vcup = comm + eczeta
      vcdn = comm - eczeta
!
      return
      end
!
!______________________________________________________________________
      subroutine fillgrad(nspin,rhog,gradr)
!     _________________________________________________________________
!
!     calculates gradient of charge density for gradient corrections
!     in: charge density on G-space    out: gradient in R-space
!
      use gvec
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use work, only: wrk1
!
      implicit none
! input
      integer nspin
      complex(kind=8) rhog(ng,nspin)
! output
      real(kind=8)    gradr(nnr,3,nspin)
! local
      complex(kind=8), pointer:: v(:)
      complex(kind=8) ci
      integer iss, ig, ir
!
!
      v => wrk1
      ci=(0.0,1.0)
      do iss=1,nspin
         do ig=1,nnr
            v(ig)=(0.0,0.0)
         end do
         do ig=1,ng
            v(np(ig))=      ci*tpiba*gx(1,ig)*rhog(ig,iss)
            v(nm(ig))=conjg(ci*tpiba*gx(1,ig)*rhog(ig,iss))
         end do
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ir=1,nnr
            gradr(ir,1,iss)=real(v(ir))
         end do
!
         do ig=1,nnr
            v(ig)=(0.0,0.0)
         end do
         do ig=1,ng
            v(np(ig))= tpiba*(      ci*gx(2,ig)*rhog(ig,iss)-           &
     &                                 gx(3,ig)*rhog(ig,iss) )
            v(nm(ig))= tpiba*(conjg(ci*gx(2,ig)*rhog(ig,iss)+           &
     &                                 gx(3,ig)*rhog(ig,iss)))
         end do
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ir=1,nnr
            gradr(ir,2,iss)= real(v(ir))
            gradr(ir,3,iss)=aimag(v(ir))
         end do
      end do
!
      return
      end
!______________________________________________________________________
      subroutine grad2(nspin,gradr,rhor)
!     _________________________________________________________________
!
!     calculate the second part of gradient corrected xc potential
!     \sum_alpha (D / D r_alpha) ( D(rho*exc)/D(grad_alpha rho) )
!
      use gvec
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use work, only: wrk1
!
      implicit none
! input
      integer nspin
      real(kind=8) gradr(nnr,3,nspin)
! input/output
      real(kind=8) rhor(nnr,nspin)
! local
      complex(kind=8), pointer:: v(:)
      complex(kind=8), allocatable:: x(:)
      complex(kind=8) ci, fp, fm
      integer iss, ig, ir
!
      v => wrk1
      allocate(x(ng))
      ci=(0.0,1.0)
      do iss=1, nspin
!
! x polarization
!
!     copy input gradr(r) into a complex array, v(r)...
!
         do ir=1,nnr
            v(ir)=cmplx(gradr(ir,1,iss),0.0)
         end do
!
!     bring v(r) to G-space, v(G)...
!
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
!     multiply by (iG) to get x=(\grad_x gradr)(G)
!
         do ig=1,ng
            x(ig)=ci*tpiba*gx(1,ig)*v(np(ig))
         end do
!
! y and z polarizations: as above, two fft's together
!
         do ir=1,nnr
            v(ir)=cmplx(gradr(ir,2,iss),gradr(ir,3,iss))
         end do
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ig=1,ng
            fp=v(np(ig))+v(nm(ig))
            fm=v(np(ig))-v(nm(ig))
            x(ig) = x(ig) +                                             &
     &           ci*tpiba*gx(2,ig)*0.5*cmplx( real(fp),aimag(fm))
            x(ig) = x(ig) +                                             &
     &           ci*tpiba*gx(3,ig)*0.5*cmplx(aimag(fp),-real(fm))
         end do
!
!     x = \sum_alpha(\grad_alpha gradr)(G)
!     now bring back to R-space
!
         do ig=1,nnr
            v(ig)=(0.0,0.0)
         end do
         do ig=1,ng
            v(np(ig))=x(ig)
            v(nm(ig))=conjg(x(ig))
         end do
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
!     v = \sum_alpha(\grad_x gradr)(r)
!
         do ir=1,nnr
            rhor(ir,iss)=rhor(ir,iss)-real(v(ir))
         end do
      end do
!
      deallocate(x)
!
      return
      end
!----------------------------------------------------------------------
      subroutine checkrho(nnr,nspin,rhor,rmin,rmax,rsum,rnegsum)
!----------------------------------------------------------------------
!
!     check \int rho(r)dr and the negative part of rho
!
      implicit none
      integer nnr, nspin
      real(kind=8) rhor(nnr,nspin), rmin, rmax, rsum, rnegsum
!
      real(kind=8) roe
      integer ir, iss
!
      rsum   =0.0
      rnegsum=0.0
      rmin   =100.
      rmax   =0.0
      do iss=1,nspin
         do ir=1,nnr
            roe=rhor(ir,iss)
            rsum=rsum+roe
            if (roe.lt.0.0) rnegsum=rnegsum+roe
            rmax=max(rmax,roe)
            rmin=min(rmin,roe)
         end do
      end do
      call reduce(1,rsum)
      call reduce(1,rnegsum)
      return
      end
!______________________________________________________________________
      subroutine ggapwold(nspin,rhog,gradr,rhor,exc)
!     _________________________________________________________________
!     perdew-wang gga 
!     as given in y-m juan & e kaxiras, prb 48, 14944 (1993) 
!     method by ja white & dm bird, prb 50, 4954 (1994) 
!     non-spin polarized case only
!     _________________________________________________________________
!     by alfredo pasquarello 22/09/1994
!
      use gvec
      !use parm
      use grid_dimensions, only: nnr => nnrx
      use constants, only: pi, fpi
!
      implicit none
!
      integer nspin
      complex(kind=8) rhog(ng)
      real(kind=8) gradr(nnr,3), rhor(nnr), exc
!
      real(kind=8) bb1, bb2, bb3, bb4, bb5, alfa, beta, cc0, cc1, delt, &
     &     c1, c2, c3, c4, c5, c6, c7, a, alfa1, bt1, bt2, bt3, bt4
      parameter(bb1=0.19645,bb2=0.27430,bb3=-0.15084,bb4=0.004,         &
     & bb5=7.7956,alfa=0.09,beta=0.0667263212,cc0=15.75592,             &
     & cc1=0.003521,c1=0.001667,c2=0.002568,c3=0.023266,c4=7.389e-6,    &
     & c5=8.723,c6=0.472,c7=7.389e-2,a=0.0621814,alfa1=0.2137,          &
     & bt1=7.5957,bt2=3.5876,bt3=1.6382,bt4=0.49294,delt=1.0e-12) 
      real(kind=8) x13, x43, x76, pi2, ax, pider1, pider2, pider3,      &
     &     abder1, abder2, abder3
      integer isign, ir
      real(kind=8)                                                      &
     &     aexp, abig, abig2, agr, aroe, byagr, ccr, ccrnum, ccrden,    &
     &     dfxd, dfxdg, dys, dfs, dh1ds, dh1dg, dh1d, dh1dt, dexcdg,    &
     &     dexcd, dh1drs, dh0da, dadec, decdrs, decd, dh0dg, dcdrs,     &
     &     dh0d, dh0dt, eclog, ecr, ecden, fx, fxnum, fxden, fxexp,     &
     &     gkf, grx, gry, grz, h0, h1, h0den, h0arg, h0num,             &
     &     roeth, roe, rs, rs12, rs2, rs3, rs32, s, sd, s2, s3, s4,     &
     &     sysl, t, td, t2, t3, t4, xchge, ys, ysl, ysr
!
!
      if (nspin.ne.1) call errore('ggapw','spin not implemented',nspin)
!
      x13=1.0/3.0
      x43=4.0/3.0
      x76=7.0/6.0
!     _________________________________________________________________
!     derived parameters from pi
!
      pi2=pi*pi
      ax=-0.75*(3.0/pi)**x13
      pider1=(0.75/pi)**x13
      pider2=(3.0*pi2)**x13
      pider3=(3.0*pi2/16.0)**x13
!     _________________________________________________________________
!     derived parameters from alfa and beta 
!
      abder1=beta*beta/(2.0*alfa)
      abder2=1.0/abder1
      abder3=2.0*alfa/beta
!     _________________________________________________________________
!     main loop
!
      do ir=1,nnr
         roe=rhor(ir)
         if(roe.eq.0.0) goto 100
         aroe=abs(roe)
         grx=gradr(ir,1)
         gry=gradr(ir,2)
         grz=gradr(ir,3)
         agr=sqrt(grx*grx+gry*gry+grz*grz)
         roeth=aroe**x13 
         rs= pider1/roeth
         gkf=pider2*roeth
         sd=1.0/(2.0*gkf*aroe)
         s=agr*sd
         s2=s*s
         s3=s*s2
         s4=s2*s2
!     _________________________________________________________________
!     exchange 
!
         ysr=sqrt(1.0+bb5*bb5*s2)
         ys=bb5*s+ysr
         ysl=log(ys)*bb1
         sysl=s*ysl
         fxexp=exp(-100.0*s2)
         fxnum=1.0+sysl+(bb2+bb3*fxexp)*s2
         fxden=1.0/(1.0+sysl+bb4*s4)
         fx=fxnum*fxden
         xchge=ax*fx*roeth
!     _________________________________________________________________
!     correlation ecr=ec(rho) 
!
         rs12=sqrt(rs)
         rs32=rs12*rs
         rs2=rs*rs
         rs3=rs*rs2
         ecden=a*(bt1*rs12+bt2*rs+bt3*rs32+bt4*rs2) 
         eclog=log(1.0+(1.0/ecden))
         ecr=-a*(1.0+alfa1*rs)*eclog
!     _________________________________________________________________
!     correlation h0(t,ecr)
!
         td=pider3*sd/rs12
         t=agr*td
         t2=t*t
         t3=t*t2
         t4=t2*t2
         aexp=exp(-abder2*ecr)-1.0
         abig=abder3/aexp
         abig2=abig*abig
         h0num=t2+abig*t4
         h0den=1.0/(1.0+abig*t2+abig2*t4)
         h0arg=1.0+abder3*h0num*h0den
         h0=abder1*log(h0arg)
!     _________________________________________________________________
!     correlation h1(t,s,aroe)
!
         ccrnum=c2+c3*rs+c4*rs2
         ccrden=1.0/(1.0+c5*rs+c6*rs2+c7*rs3)
         ccr=c1+ccrnum*ccrden
         h1=cc0*(ccr-cc1)*t2*fxexp
!     _________________________________________________________________
!     updating of xc-energy
!
         exc=exc+(xchge+ecr+h0+h1)*aroe
!     _________________________________________________________________
!     first part xc-potential from exchange  
!     
         dys=bb5*(1.0+bb5*s/ysr)/ys
         dfs=-fxnum*(ysl+bb1*s*dys+4.0*bb4*s3)*fxden*fxden              &
     &        +(ysl+bb1*s*dys+2.0*s*(bb2+bb3*fxexp)                     &
     &        -200.0*s3*bb3*fxexp)*fxden
         dfxd=(ax*roeth*x43)*(fx-dfs*s)
         dfxdg=ax*roeth*dfs*sd
!     _________________________________________________________________
!     first part xc-potential from ecr 
!
         decdrs=-a*alfa1*eclog*rs + a*(1+alfa1*rs)                      &
     &        *a*(0.5*bt1*rs12+bt2*rs+1.5*bt3*rs32+2.0*bt4*rs2)         &
     &        /(ecden*ecden+ecden)
         decd=-x13*decdrs
!     _________________________________________________________________
!     first part xc-potential from h0 
!     
         dh0da=abder1/h0arg*abder3*h0den*                               &
     &        (t4-h0num*h0den*(t2+2.0*abig*t4))
         dadec=abder3*abder2*(aexp+1.0)/(aexp*aexp)
         dh0d=dh0da*dadec*decd 
         dh0dt=abder1/h0arg*abder3*h0den                                &
     &        *(2.0*t+4.0*abig*t3-h0num*h0den*(2.0*abig*t+4.0*abig2*t3))
         dh0d=dh0d-x76*t*dh0dt
         dh0dg=dh0dt*td
!     _________________________________________________________________
!     first part xc-potential from h1 
!
         dcdrs=(c3+2.0*c4*rs-ccrnum*ccrden*(c5+2.0*c6*rs+3.0*c7*rs2))   &
     &        *ccrden
         dh1drs=cc0*t2*fxexp*dcdrs
         dh1d=-x13*rs*dh1drs
         dh1dt=2.0*t*cc0*(ccr-cc1)*fxexp
         dh1d=dh1d-x76*t*dh1dt
         dh1ds=-200.0*s*cc0*(ccr-cc1)*t2*fxexp
         dh1d=dh1d-x43*s*dh1ds
         dh1dg=dh1dt*td+dh1ds*sd
!     _________________________________________________________________
!     first part of xc-potential: D(rho*exc)/D(rho)
!
         dexcd=dfxd+decd+dh0d+dh1d+ecr+h0+h1
         isign=sign(1.d0,agr-delt)
         byagr=0.5*(1+isign)/(agr+(1-isign)*delt)
         rhor(ir)=dexcd
!
!     gradr = D(rho*exc)/D(|grad rho|) * (grad rho) / |grad rho|
!
         dexcdg=(dfxdg+dh0dg+dh1dg)*aroe*byagr
         gradr(ir,1)=gradr(ir,1)*dexcdg
         gradr(ir,2)=gradr(ir,2)*dexcdg
         gradr(ir,3)=gradr(ir,3)*dexcdg
 100     continue
      end do
!
      call reduce(1,exc)
      return
      end


!-----------------------------------------------------------------------
      subroutine vofrho_wf(nfi,rhor,rhog,rhos,rhoc,tfirst,tlast,           &
     &     ei1,ei2,ei3,irb,eigrb,sfac,tau0,fion)
!-----------------------------------------------------------------------
!     computes: the one-particle potential v in real space,
!               the total energy etot,
!               the forces fion acting on the ions,
!               the derivative of total energy to cell parameters h
!     rhor input : electronic charge on dense real space grid
!                  (plus core charge if present)
!     rhog input : electronic charge in g space (up to density cutoff)
!     rhos input : electronic charge on smooth real space grid
!     rhor output: total potential on dense real space grid
!     rhos output: total potential on smooth real space grid
!
      use control_flags, only: iprint, tvlocw, iprsta, thdyn, tpre, tfor, tprnfor
      use io_global, only: stdout
      use parameters, only: natx, nsx
      use ions_base, only: nas => nax, nsp, na
      use gvec
      use gvecs
      use cell_base, only: omega
      use cell_base, only: a1, a2, a3, alat
      use reciprocal_vectors, only: ng0 => gstart
      !use parm
      use grid_dimensions, only: nr1, nr2, nr3, &
            nr1x, nr2x, nr3x, nnr => nnrx
      use smooth_grid_dimensions, only: nr1s, nr2s, nr3s, &
            nr1sx, nr2sx, nr3sx, nnrsx
      use elct
      use constants, only: pi, fpi
      use energies, only: etot, eself, enl, ekin, epseu, esr, eht, exc 
      use pseu
      use core
      !use ncprm
      use gvecb
      !use dft_mod
      use work, only: wrk1
      use work_box
      use atom, only: nlcc
!
      use dener
      use derho
      use dpseu
!
      implicit none
!
      logical tlast,tfirst
      integer nfi
      real(kind=8)  rhor(nnr,nspin), rhos(nnrsx,nspin), fion(3,natx)
      real(kind=8)  rhoc(nnr), tau0(3,natx)
      complex(kind=8) ei1(-nr1:nr1,nas,nsp), ei2(-nr2:nr2,nas,nsp),     &
     &                ei3(-nr3:nr3,nas,nsp), eigrb(ngb,nas,nsp),        &
     &                rhog(ng,nspin), sfac(ngs,nsp)
!
      integer irb(3,natx,nsx), iss, isup, isdw, ig, ir,i,j,k,is, ia
      real(kind=8) fion1(3,natx), vave, ebac, wz, eh
      complex(kind=8)  fp, fm, ci
      complex(kind=8), pointer:: v(:), vs(:)
      complex(kind=8), allocatable:: rhotmp(:), vtemp(:), drhotmp(:,:,:)

! Makov Payne Variables
!
      real(kind=8) dipole,quadrupole
      real(kind=8) E_dip,E_quad,en1,en2
      real(kind=8), allocatable:: rhortot(:)
      real(kind=8) alpha

!
      call start_clock( 'vofrho_wf' )
      
      ci=(0.,1.)
!
!     wz = factor for g.neq.0 because of c*(g)=c(-g)
!
      wz = 2.0
      v => wrk1
      vs=> wrk1
      allocate(vtemp(ng))
!      write(6,*) 'Allocated vtemp'
      allocate(rhotmp(ng))
!      write(6,*) 'Allocated rhotmp'
      allocate(rhortot(nnr))                ! for Makov Payne
!      write(6,*) 'Allocated rhortot'
      if (tpre) allocate(drhotmp(ng,3,3))
!      write(6,*) 'Allocated all'
!
!     first routine in which fion is calculated: annihilation
!
      fion =0.d0
      fion1=0.d0

!      write(6,*) 'Annihilation'
!
!     ===================================================================
!     forces on ions, ionic term in real space
!     -------------------------------------------------------------------
      if( tprnfor .or. tfor .or. tfirst .or. thdyn ) then
        call force_ion(tau0,esr,fion,dsr)
      end if
!
      if(nspin.eq.1) then
         iss=1
         do ig=1,ng
            rhotmp(ig)=rhog(ig,iss)
         end do
         if(tpre)then
            do j=1,3
               do i=1,3
                  do ig=1,ng
                     drhotmp(ig,i,j)=drhog(ig,iss,i,j)
                  enddo
               enddo
            enddo
         endif
      else
         isup=1
         isdw=2
         do ig=1,ng
            rhotmp(ig)=rhog(ig,isup)+rhog(ig,isdw)
         end do
         if(tpre)then
            do i=1,3
               do j=1,3
                  do ig=1,ng
                     drhotmp(ig,i,j) = drhog(ig,isup,i,j) +           &
     &                                 drhog(ig,isdw,i,j)
                  enddo
               enddo
            enddo
         endif
      end if
!      write(6,*) 'fion'
!     ===================================================================
!     calculation local potential energy
!     -------------------------------------------------------------------
      vtemp=(0.,0.)
      do is=1,nsp
         do ig=1,ngs
            vtemp(ig)=vtemp(ig)+conjg(rhotmp(ig))*sfac(ig,is)*vps(ig,is)
         end do
      end do
!
      epseu=wz*real(SUM(vtemp(1:ngs)))
      if (ng0.eq.2) epseu=epseu-vtemp(1)
      call reduce(1,epseu)
      epseu=epseu*omega
!
      if(tpre) call denps(rhotmp,drhotmp,sfac,vtemp,dps)

!      write(6,*) 'Local Energy'
!
!     ===================================================================
!     calculation hartree energy
!     -------------------------------------------------------------------
      do is=1,nsp
         do ig=1,ngs
            rhotmp(ig)=rhotmp(ig)+sfac(ig,is)*rhops(ig,is)
         end do
      end do
      if (ng0.eq.2) vtemp(1)=0.0
      do ig=ng0,ng
         vtemp(ig)=conjg(rhotmp(ig))*rhotmp(ig)/g(ig)
      end do
!
      eh=real(SUM(vtemp(1:ng)))*wz*0.5*fpi/tpiba2
      call reduce(1,eh)
      if(tpre) call denh(rhotmp,drhotmp,sfac,vtemp,eh,dh)
      if(tpre) deallocate(drhotmp)
!      write(6,*) 'Hartree Energy'
!     ===================================================================
!     forces on ions, ionic term in reciprocal space
!     -------------------------------------------------------------------
      if( tprnfor .or. tfor .or. thdyn)                                                  &
     &    call force_ps(rhotmp,rhog,vtemp,ei1,ei2,ei3,fion1)
!     ===================================================================
!     calculation hartree + local pseudo potential
!     -------------------------------------------------------------------
!
      if (ng0.eq.2) vtemp(1)=(0.,0.)
      do ig=ng0,ng
         vtemp(ig)=rhotmp(ig)*fpi/(tpiba2*g(ig))
      end do
!
      do is=1,nsp
         do ig=1,ngs
            vtemp(ig)=vtemp(ig)+sfac(ig,is)*vps(ig,is)
         end do
      end do
!
!     vtemp = v_loc(g) + v_h(g)
!  
!       write(6,*) 'Hartree + Local'
! Makov-Payne corrections, by Filippo
!
      if(tlast) then
!     ===================================================================
!     fourier transform of total density to r-space (dense grid)
!     -------------------------------------------------------------------
      v(:) = (0.d0, 0.d0)
         do ig=1,ng
            v(nm(ig))=conjg(rhotmp(ig))
            v(np(ig))=rhotmp(ig)
         end do
!
!     v(g) --> v(r)
!
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         do ir=1,nnr
          rhortot(ir)=real(v(ir))
         end do
!
       call poles(rhortot,dipole,quadrupole)
!
!      Madelung constant for cubic lattice (NaCl)

!
       alpha=1.7476
!
       en1=qbac**2.*alpha/(2.*alat)
       en2=2.*pi*qbac*quadrupole/(3.*alat**3)
!
       write (6,*) "en1: ", en1
       write (6,*) "en2: ", en2
!
       E_quad= en1 + en2
!
!      The interaction energy of the background charge (minus the
!      molecular charge) with itself on a lattice (Madelung energy).
!      +
!      The interaction energy of the background charge with the nuclear
!      quadupole moment on a lattice, with reversed sign due to the fact
!      that the electron density is assumed to be positive.
!
      end if
! END of Makov-Payne corrections, written by Filippo
!
!
!     ===================================================================
!      calculation exchange and correlation energy and potential
!     -------------------------------------------------------------------
      if ( ANY( nlcc ) ) call add_cc(rhoc,rhog,rhor)
!
!      write(6,*) 'add_cc'

      call exch_corr_h(nspin,rhog,rhor,exc,dxc)
!
!     rhor contains the xc potential in r-space

!      write(6,*) 'XC R Space'
!
!     ===================================================================
!     fourier transform of xc potential to g-space (dense grid)
!     -------------------------------------------------------------------
!
      if(nspin.eq.1) then
         iss=1
         do ir=1,nnr
            v(ir)=cmplx(rhor(ir,iss),0.0)
         end do
!
!     v_xc(r) --> v_xc(g)
!
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         do ig=1,ng
            rhog(ig,iss)=vtemp(ig)+v(np(ig))
         end do
!
!     v_tot(g) = (v_tot(g) - v_xc(g)) +v_xc(g)
!     rhog contains the total potential in g-space
!
      else
         isup=1
         isdw=2
         do ir=1,nnr
            v(ir)=cmplx(rhor(ir,isup),rhor(ir,isdw))
         end do
         call fwfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ig=1,ng
            fp=v(np(ig))+v(nm(ig))
            fm=v(np(ig))-v(nm(ig))
            rhog(ig,isup)=vtemp(ig)+0.5*cmplx( real(fp),aimag(fm))
            rhog(ig,isdw)=vtemp(ig)+0.5*cmplx(aimag(fp),-real(fm))
         end do
      endif
!
!     rhog contains now the total (local+Hartree+xc) potential in g-space
!
!     write(6,*) 'XC G-Space'

      if( tprnfor .or. tfor ) then
         if ( ANY( nlcc ) ) call force_cc(irb,eigrb,rhor,fion1)
         call reduce(3*natx,fion1)
!
!    add g-space ionic and core correction contributions to fion
!
          fion = fion + fion1
      end if
!     ===================================================================
!     fourier transform of total potential to r-space (dense grid)
!     -------------------------------------------------------------------
      v(:) = (0.d0, 0.d0)
      if(nspin.eq.1) then
         iss=1
         do ig=1,ng
            v(np(ig))=rhog(ig,iss)
            v(nm(ig))=conjg(rhog(ig,iss))
         end do
!
!     v(g) --> v(r)
!
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
!
         do ir=1,nnr
            rhor(ir,iss)=real(v(ir))
         end do
!
!     calculation of average potential
!
         vave=SUM(rhor(1:nnr,iss))/dfloat(nr1*nr2*nr3)
      else
         isup=1
         isdw=2
         do ig=1,ng
            v(np(ig))=rhog(ig,isup)+ci*rhog(ig,isdw)
            v(nm(ig))=conjg(rhog(ig,isup)) +ci*conjg(rhog(ig,isdw))
         end do
!
         call invfft(v,nr1,nr2,nr3,nr1x,nr2x,nr3x)
         do ir=1,nnr
            rhor(ir,isup)= real(v(ir))
            rhor(ir,isdw)=aimag(v(ir))
         end do

!       write(6,*) 'Average Potential'
!
!     calculation of average potential
!
         vave=(SUM(rhor(1:nnr,isup))+SUM(rhor(1:nnr,isdw)))       &
     &        /2.0/dfloat(nr1*nr2*nr3)
      endif
      call reduce(1,vave)
!     ===================================================================
!     fourier transform of total potential to r-space (smooth grid)
!     -------------------------------------------------------------------
      vs (:) = (0.d0, 0.d0)
      if(nspin.eq.1)then
         iss=1
         do ig=1,ngs
            vs(nms(ig))=conjg(rhog(ig,iss))
            vs(nps(ig))=rhog(ig,iss)
         end do
!
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
!
         do ir=1,nnrsx
            rhos(ir,iss)=real(vs(ir))
         end do
      else
         isup=1
         isdw=2
         do ig=1,ngs
            vs(nps(ig))=rhog(ig,isup)+ci*rhog(ig,isdw)
            vs(nms(ig))=conjg(rhog(ig,isup)) +ci*conjg(rhog(ig,isdw))
         end do 
         call ivffts(vs,nr1s,nr2s,nr3s,nr1sx,nr2sx,nr3sx)
         do ir=1,nnrsx
            rhos(ir,isup)= real(vs(ir))
            rhos(ir,isdw)=aimag(vs(ir))
         end do
      endif


!      write(6,*) 'Total Potential r-space'

      ebac=0.0
!
      eht=eh*omega+esr-eself
!
!     etot is the total energy ; ekin, enl were calculated in rhoofr
!
      etot=ekin+eht+epseu+enl+exc+ebac
      if(tpre) detot=dekin+dh+dps+denl+dxc+dsr

     if(tlast) then
         write (6,*)'MAKOV-PAYNE CORRECTED TOTAL ENERGY',etot+E_quad
         write (6,*)'THIS CORRECTION IS VALID ONLY FOR CUBIC LATTICES'
      end if


!
      if(tvlocw.and.tlast)then
#ifdef __PARA
         call write_rho(46,nspin,rhor)
#else
         write(46) ((rhor(ir,iss),ir=1,nnr),iss=1,nspin)
#endif
      endif
!
      deallocate(rhotmp)
      deallocate(vtemp)
      deallocate(rhortot)                ! Makov Payne Variable - M.S

!      write(6,*) 'Deallocations'
!
!
      call stop_clock( 'vofrho_wf' )
      if((nfi.eq.0).or.tfirst.or.tlast) goto 999
      if(mod(nfi-1,iprint).ne.0 ) return
!
 999  WRITE( stdout,1) etot,ekin,eht,esr,eself,epseu,enl,exc,vave
    1 format(//'                total energy = ',f14.5,' a.u.'/         &
     &         '              kinetic energy = ',f14.5,' a.u.'/         &
     &         '        electrostatic energy = ',f14.5,' a.u.'/         &
     &         '                         esr = ',f14.5,' a.u.'/         &
     &         '                       eself = ',f14.5,' a.u.'/         &
     &         '      pseudopotential energy = ',f14.5,' a.u.'/         &
     &         '  n-l pseudopotential energy = ',f14.5,' a.u.'/         &
     &         ' exchange-correlation energy = ',f14.5,' a.u.'/         &
     &         '           average potential = ',f14.5,' a.u.'//)
!
      if(tpre)then
         WRITE( stdout,*) "cell parameters h"
         WRITE( stdout,5555) (a1(i),a2(i),a3(i),i=1,3)
         WRITE( stdout,*)
         WRITE( stdout,*) "derivative of e(tot)"
         WRITE( stdout,5555) ((detot(i,j),j=1,3),i=1,3)
         WRITE( stdout,*)
         if(tpre.and.iprsta.ge.2) then
            WRITE( stdout,*) "derivative of e(kin)"
            WRITE( stdout,5555) ((dekin(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(electrostatic)"
            WRITE( stdout,5555) (((dh(i,j)+dsr(i,j)),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(h)"
            WRITE( stdout,5555) ((dh(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(sr)"
            WRITE( stdout,5555) ((dsr(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(ps)"
            WRITE( stdout,5555) ((dps(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(nl)"
            WRITE( stdout,5555) ((denl(i,j),j=1,3),i=1,3)
            WRITE( stdout,*) "derivative of e(xc)"
            WRITE( stdout,5555) ((dxc(i,j),j=1,3),i=1,3)
         endif
      endif
5555  format(1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5/                                &
     &       1x,f12.5,1x,f12.5,1x,f12.5//)
!
      return
      end

!------------------------------------------------------------------------
      subroutine poles(rhortot,dipole,quadrupole)
!------------------------------------------------------------------------
!
      use para_mod
      use gvec
!      use parm
      use grid_dimensions, only : nr1, nr2, nr3, nr1x, nr2x, nr3x, nnr=> nnrx
      use cell_base, only : a1, a2, a3, omega
      use elct
!
      implicit none
      real(kind=8), parameter :: debye=1./0.39344, angs=1./0.52917726
!
      real(kind=8)  dipole,quadrupole,mu(3),quad(6)
      real(kind=8)  ax,ay,az,XG0,YG0,ZG0,X,Y,Z,D,s,rzero,x0,y0,z0
      real(kind=8)  en1,en2, pass1, pass2, pass3
      real(kind=8)  rhortot(nnr)
!     real(kind=8), allocatable:: x(:),y(:),z(:)
      real(kind=8), allocatable:: dip(:)
      integer (kind=4) ix,ir, i, j, k
!
      allocate(dip(nnr))

!     compute the dipole moment
!
        ax=a1(1)
        ay=a2(2)
        az=a3(3)
!
        XG0 = -ax/2.
        YG0 = -ay/2.
        ZG0 = -az/2.
        pass1=ax/nr1
        pass2=ax/nr2
        pass3=ax/nr3
!        pass1 = ax / (nr1-1)
!        pass2 = ay / (nr2-1)
!        pass3 = az / (nr3-1)
!
        do ix=1,3
        ir=1
!
        do k = dfftp%ipp(me)+1, dfftp%ipp(me)+ dfftp%npp(me)
         do j=1,nr2x
          do i=1,nr1x
            X=XG0+(i-1)*pass1
            Y=YG0+(j-1)*pass2
            Z=ZG0+(k-1)*pass3
            if (ix.eq.1) D=X
            if (ix.eq.2) D=Y
            if (ix.eq.3) D=Z
            dip(ir)=D*rhortot(ir)
            ir=ir+1
           end do
          end do
         end do
!
         mu(ix)=sum(dip(1:nnr))
!
         end do !!!!!!! ix
!
         call reduce(3,mu)
!
        do ix=1,3
         mu(ix)=mu(ix)*omega/dfloat(nr1*nr2*nr3)
        end do
!
        dipole=sqrt(mu(1)**2+mu(2)**2+mu(3)**2)
!
!
!       compute the coordinates which put the dipole moment to zero
!
        if (abs(qbac).gt.1.d-05) then
         x0=mu(1)/abs(qbac)
         y0=mu(2)/abs(qbac)
         z0=mu(3)/abs(qbac)
         rzero=x0**2+y0**2+z0**2
        else
         rzero=0.
        end if
!
!       compute the quadrupole moment
!
        do ix=1,6
!
         ir=1
         do k=dfftp%ipp(me)+1, dfftp%ipp(me) + dfftp%npp(me)
          do j=1,nr2x
           do i=1,nr1x
!
            X=XG0+(i-1)*pass1
            Y=YG0+(j-1)*pass2
            Z=ZG0+(k-1)*pass3
!
            if (ix.eq.1) D=X*X
            if (ix.eq.2) D=Y*Y
            if (ix.eq.3) D=Z*Z
            if (ix.eq.4) D=X*Y
            if (ix.eq.5) D=X*Z
            if (ix.eq.6) D=Y*Z
!
            dip(ir)=D*rhortot(ir)
!
            ir=ir+1
           end do
          end do
         end do
!
        quad(ix)=SUM(dip(1:nnr))
        end do
!
         call reduce(6,quad)

        do ix=1,6
         quad(ix)=quad(ix)*omega/dfloat(nr1*nr2*nr3)
        end do
!
        quadrupole=quad(1)+quad(2)+quad(3)-rzero*qbac
!
!  only the diagonal elements contribute to the inetaction energy
!  the term rzero*qbac is subtracted to zero the dipole moment
!
        write (*,1001)(mu(ix),ix=1,3)
        write (*,1002) dipole
        write (*,*) ' '
        write (*,1003)(quad(ix),ix=1,3)
        write (*,1004)(quad(ix),ix=4,6)
        write (*,1005) quadrupole,rzero*qbac
!
1001  format('DIPOLE XYZ-COMPONENTS (A.U.)',f10.4,2x,f10.4,2x,f10.4)
1002  format('DIPOLE MOMENT         (A.U.)',f10.4)
1003  format('QUADRUPOLE XX-YY-ZZ COMPONENTS (A.U.)',             &
     &f9.4,2x,f9.4,2x,f9.4)
1004  format('QUADRUPOLE XY-XZ-YZ COMPONENTS (A.U.)',             &
     &f9.4,2x,f9.4,2x,f9.4)
1005  format('QUADRUPOLE MOMENT              (A.U.)',2f9.4)
!
      deallocate(dip)
!
      return
      end

