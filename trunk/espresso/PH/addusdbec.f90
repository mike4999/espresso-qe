!
! Copyright (C) 2001-2008 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine addusdbec (ik, wgt, psi, dbecsum)
  !----------------------------------------------------------------------
  !
  !  This routine adds to the dbecsum the term which correspond to this
  !  k point. After the accumulation the additional part of the charge
  !  is computed in addusddens.
  !
#include "f_defs.h"
  USE kinds, only : DP
  USE cell_base, ONLY : omega
  USE ions_base, ONLY : nat, ityp, ntyp => nsp
  USE becmod, ONLY : calbec
  USE wvfct, only: npw, npwx, nbnd
  USE uspp, only: nkb, vkb, okvan
  USE uspp_param, only: upf, nh, nhm
  USE phus,   ONLY : becp1
  USE qpoint, ONLY : npwq
  USE control_ph, ONLY : nbnd_occ, lgamma
  implicit none
  !
  !   the dummy variables
  !
  complex(DP) :: dbecsum (nhm*(nhm+1)/2, nat), psi(npwx,nbnd)
  ! inp/out: the sum kv of bec *
  ! input  : contains delta psi
  integer :: ik
  ! input: the k point
  real(DP) :: wgt
  ! input: the weight of this k point
  !
  !     here the local variables
  !
  integer :: na, nt, ih, jh, ibnd, ikk, ikb, jkb, ijh, startb, &
       lastb, ijkb0
  ! counter on atoms
  ! counter on atomic type
  ! counter on solid beta functions
  ! counter on solid beta functions
  ! counter on the bands
  ! the real k point
  ! counter on solid becp
  ! counter on solid becp
  ! composite index for dbecsum
  ! divide among processors the sum
  ! auxiliary variable for counting

  complex(DP), allocatable :: dbecq (:,:)
  ! the change of becq

  if (.not.okvan) return

  call start_clock ('addusdbec')

  allocate (dbecq( nkb, nbnd))    
  if (lgamma) then
     ikk = ik
  else
     ikk = 2 * ik - 1
  endif
  !
  !     First compute the product of psi and vkb
  !
  call calbec (npwq, vkb, psi, dbecq)
  !
  !  And then we add the product to becsum
  !
  !  Band parallelization: each processor takes care of its slice of bands
  !
  call divide (nbnd_occ (ikk), startb, lastb)
  !
  ijkb0 = 0
  do nt = 1, ntyp
     if (upf(nt)%tvanp ) then
        do na = 1, nat
           if (ityp (na) .eq.nt) then
              !
              !  And qgmq and becp and dbecq
              !
              ijh = 1
              do ih = 1, nh (nt)
                 ikb = ijkb0 + ih
                 do ibnd = startb, lastb
                    dbecsum (ijh, na) = dbecsum (ijh, na) + &
                         wgt * ( CONJG(becp1(ikb,ibnd,ik)) * dbecq(ikb,ibnd) )
                 enddo
                 ijh = ijh + 1
                 do jh = ih + 1, nh (nt)
                    jkb = ijkb0 + jh
                    do ibnd = startb, lastb
                       dbecsum (ijh, na) = dbecsum (ijh, na) + &
                         wgt*( CONJG(becp1(ikb,ibnd,ik)) * dbecq(jkb,ibnd) + &
                               CONJG(becp1(jkb,ibnd,ik)) * dbecq(ikb,ibnd) )
                    enddo
                    ijh = ijh + 1
                 enddo
              enddo
              ijkb0 = ijkb0 + nh (nt)
           endif
        enddo
     else
        do na = 1, nat
           if (ityp (na) .eq.nt) ijkb0 = ijkb0 + nh (nt)
        enddo
     endif
  enddo
  !
  deallocate (dbecq)

  call stop_clock ('addusdbec')
  return
end subroutine addusdbec
