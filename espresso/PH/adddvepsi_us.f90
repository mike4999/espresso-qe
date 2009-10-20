!
! Copyright (C) 2001-2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
subroutine adddvepsi_us(becp2,ipol,kpoint)
  ! This subdoutine adds to dvpsi the terms which depend on the augmentation
  ! charge. It assumes that the variable dpqq, has been set and it is in
  ! the crystal base.
  ! It calculates the last two terms of Eq.10 in JCP 21, 9934 (2004).
  ! P^+_c is applied in solve_e.
  !

  USE kinds, only : DP
  USE lsda_mod, ONLY : nspin
  USE spin_orb, ONLY : lspinorb
  USE uspp,  ONLY : nkb, vkb, qq, qq_so
  USE wvfct, ONLY : npwx, npw, nbnd
  USE cell_base, ONLY : at
  USE ions_base, ONLY : nat, ityp, ntyp => nsp
  USE noncollin_module, ONLY : noncolin, npol
  USE uspp_param, only: nh
  USE phus,     ONLY : becp1, dpqq, dpqq_so
  USE control_ph, ONLY: nbnd_occ
  USE eqv,      ONLY : dvpsi

  implicit none

  integer, intent(in) :: ipol, kpoint
  complex(DP), intent(in) :: becp2(nkb,npol,nbnd)

  complex(DP), allocatable :: ps(:), ps_nc(:,:)
  integer:: ijkb0, nt, na, ih, jh, ikb, jkb, ibnd, ip, is

  IF (noncolin) THEN
     allocate (ps_nc(nbnd,npol))    
  ELSE
     allocate (ps(nbnd))    
  END IF

  ijkb0 = 0
  do nt = 1, ntyp
     do na = 1, nat
        if (ityp(na).eq.nt) then
           do ih = 1, nh (nt)
              ikb = ijkb0 + ih
              IF (noncolin) THEN
                 ps_nc = (0.d0,0.d0)
              ELSE
                 ps = (0.d0,0.d0)
              END IF
              do jh = 1, nh (nt)
                 jkb = ijkb0 + jh
                 do ibnd=1, nbnd_occ(kpoint)
                    IF (noncolin) THEN
                       DO ip=1,npol
                          IF (lspinorb) THEN
                             ps_nc(ibnd,ip)=ps_nc(ibnd,ip) +          &
                                 (0.d0,1.d0)*(becp2(jkb,1,ibnd)*      &
                                 qq_so(ih,jh,1+(ip-1)*2,nt) +         &
                                 becp2(jkb,2,ibnd) *                  &
                                 qq_so(ih,jh,2+(ip-1)*2,nt) )         &
                               + becp1(kpoint)%nc(jkb,1,ibnd)*        &
                                 dpqq_so(ih,jh,1+(ip-1)*2,ipol,nt)    &
                               + becp1(kpoint)%nc(jkb,2,ibnd)*        &
                                 dpqq_so(ih,jh,2+(ip-1)*2,ipol,nt)    
                          ELSE
                             ps_nc(ibnd,ip)=ps_nc(ibnd,ip)+           &
                                 becp2(jkb,ip,ibnd)*(0.d0,1.d0)*      &
                                 qq(ih,jh,nt)+becp1(kpoint)%nc(jkb,ip,ibnd) &
                                             * dpqq(ih,jh,ipol,nt)
                          END IF
                       END DO
                    ELSE
                       ps(ibnd) = ps(ibnd)                                &
                           + becp2(jkb,1,ibnd)*(0.d0,1.d0)*qq(ih,jh,nt)+  &
                             becp1(kpoint)%k(jkb,ibnd)*dpqq(ih,jh,ipol,nt)
                    END IF
                 enddo
              enddo
              do ibnd = 1, nbnd_occ (kpoint)
                 IF (noncolin) THEN
                    CALL zaxpy(npw,ps_nc(ibnd,1),vkb(1,ikb),1, &
                                                     dvpsi(1,ibnd),1)
                    CALL zaxpy(npw,ps_nc(ibnd,2),vkb(1,ikb),1, &
                                                     dvpsi(1+npwx,ibnd),1)
                 ELSE
                    CALL zaxpy(npw,ps(ibnd),vkb(1,ikb),1,dvpsi(1,ibnd),1)
                 END IF
              enddo
           enddo
           ijkb0=ijkb0+nh(nt)
        endif
     enddo
  enddo
  if (jkb.ne.nkb) call errore ('adddvepsi_us', 'unexpected error', 1)

  IF (noncolin) THEN
     deallocate(ps_nc)
  ELSE
     deallocate(ps)
  END IF
  

  RETURN
END SUBROUTINE adddvepsi_us
