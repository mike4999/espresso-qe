subroutine compute_qdipol
!
! This routine computes the term dpqq, i.e. the dipole moment of the
! augmentation charge.
!
use pwcom
USE kinds, only: DP
use phcom

implicit none

real(kind=dp), allocatable :: qrad2(:,:,:), qtot(:,:,:), aux(:)

real(kind=dp) :: fact

integer :: nt, l, ir, nb, mb, ilast, ipol, ih, ivl, jh, jvl, lp

call start_clock('cmpt_qdipol')
allocate (qrad2( nbrx , nbrx, ntyp))    
allocate (aux( ndm))    
allocate (qtot( ndm, nbrx, nbrx))    

qrad2(:,:,:)=0.d0
dpqq=0.d0

do nt = 1, ntyp
   if (tvanp (nt) ) then
      l=1
!
!   Only l=1 terms enter in the dipole of Q
!
      do nb = 1, nbeta (nt)
         do mb = nb, nbeta (nt)
            if ((l.ge.abs(lll(nb,nt)-lll(mb,nt))) .and. &
                (l.le.lll(nb,nt)+lll(mb,nt))      .and. &
                (mod (l+lll(nb,nt)+lll(mb,nt),2) .eq.0) ) then
                do ir = 1, kkbeta (nt)
                   if (r(ir, nt).ge.rinner(l+1, nt)) then
                      qtot(ir, nb, mb)=qfunc(ir,nb,mb,nt)
                   else
                      ilast = ir
                   endif
                enddo
                if (rinner(l+1, nt).gt.0.d0) &
                    call setqf(qfcoef (1, l+1, nb, mb, nt), &
                               qtot(1,nb,mb), r(1,nt), nqf(nt),l,ilast)
            endif
         enddo
      enddo
      do nb=1, nbeta(nt)
         !
         !    the Q are symmetric with respect to indices
         !
         do mb=nb, nbeta(nt)
            if ( (l.ge.abs(lll(nb,nt)-lll(mb,nt) ) )    .and.  &
                 (l.le.lll(nb,nt) + lll(mb,nt) )        .and.  &
                 (mod(l+lll(nb,nt)+lll(mb,nt), 2).eq.0) ) then
               do ir = 1, kkbeta (nt)
                  aux(ir)=r(ir, nt)*qtot(ir, nb, mb)
               enddo
               call simpson (kkbeta(nt),aux,rab(1,nt),qrad2(nb,mb,nt))
            endif
         enddo
      enddo
   endif
    ! ntyp
enddo


do ipol = 1,3
   fact=-sqrt(fpi/3.d0)
   if (ipol.eq.1) lp=3
   if (ipol.eq.2) lp=4
   if (ipol.eq.3) then
       lp=2
       fact=-fact
   endif
   do nt = 1,ntyp
      if (tvanp(nt)) then
         do ih = 1, nh(nt)
            ivl = nhtol(ih, nt)*nhtol(ih, nt)+nhtom(ih,nt)
            mb = indv(ih, nt)
            do jh = ih, nh (nt)
               jvl = nhtol(jh, nt)*nhtol(jh,nt)+nhtom(jh,nt)
               nb=indv(jh,nt)
               if (ivl.gt.nlx) call errore('compute_qdipol',' ivl.gt.nlx', ivl)
               if (jvl.gt.nlx) call errore('compute_qdipol',' jvl.gt.nlx', jvl)
               if (nb.gt.nbrx) call errore('compute_qdipol',' nb.gt.nbrx', nb)
               if (mb.gt.nbrx) call errore('compute_qdipol',' mb.gt.nbrx', mb)
               if (mb.gt.nb) call errore('compute_qdipol',' mb.gt.nb', 1)
               dpqq(ih,jh,ipol,nt)=fact*ap(lp,ivl,jvl)*qrad2(mb,nb,nt)
               dpqq(jh,ih,ipol,nt)=dpqq(ih,jh,ipol,nt)
!               WRITE( stdout,'(3i5,2f15.9)') ih,jh,ipol,dpqq(ih,jh,ipol,nt)
            enddo
         enddo
      endif
   enddo
enddo
deallocate(qtot)
deallocate(aux)
deallocate(qrad2)
call stop_clock('cmpt_qdipol')

return
end
