!
! Copyright (C) 2001-2006 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine dhdrhopsi
  !-----------------------------------------------------------------------
  !
  ! Computes the chi-wavefunction that will be used in the Raman, and
  ! electro-optic tensor calculations.
  !
  ! The first-order derivative of the charge-density and of the wavefunctions
  ! should have been previously calculated by solve_e, and are read from
  ! file.
  !
  ! |chi> is a function that should depend on two polarization indexes.
  ! Since it is symmetric per exchange of the two indexes; we are considering
  ! only one index (running from 1 to 6) that is related to the two polarizat.
  ! by the common variables: jab(3,3),  a1j(6), a2j(6) --see the comment 
  ! written in phcom.f90
  !
  ! |chi> = Pc [ DH , D\rho ] |psi> is computed in two different steps:
  !
  ! 1) |chi> = d/dk (|Du><u|) |u> ; where d/dk is the derivative with
  !         respect to the k-point, |u> is the Bloch-wavefunction, and
  !         |Du> is the derivative of |u> with respect to the electric field
  !    The derivation is done be finite differences, computing in a
  !         non-self consistent way |u_{k+d}> and |Du_{k+d}>, where d is a
  !         small vector
  !
  ! 2) |chi(i)> = |chi(i)> + DH |Du(i)> - sum_j |Du(j)> <u(j)| DH |u(i)>
  !         where DH is the variation of the self-consistent part of the
  !         hamiltonian with respect to the Electric field.
  !         i, j are band indexes

#include "f_defs.h"
  use pwcom
  use mp, only: mp_end
  USE mp_global, ONLY : npool
  use io_files, only: prefix, iunigk
  use kinds, only : DP
  USE wavefunctions_module,  ONLY: evc
  use becmod
  use phcom
  use ramanm
  implicit none

  logical :: d_test
  ! .true. ==> re-calculates the dielectric constant

  integer :: ik, isg, ibnd, jbnd, ir, ipa, ipb, nrec, max_iter
  ! counter on k-points
  ! sign in xk +/- delta_xk
  ! counters on bands
  ! counters on bands
  ! counter on mesh points
  ! counter on G-points
  ! counters on the three polarizations of E
  ! counters on the three polarizations of E
  ! number of the record
  ! max number of iterations in diagonalization

  real(DP) , allocatable ::  et_sw(:)
  ! swap space for diagonalization eigenvalues

  real(DP) :: xk_sw (3), avg_iter1, avg_iter2, tmpr
  ! swap space for k-points
  ! average iteration # in the psi  diagonalizat.
  ! average iteration # in the dpsi diagonalizat.
  ! working space

  complex(DP) , allocatable :: ev_sw (:,:),  chif (:,:,:),  &
         depsi (:,:,:), auxg(:), dvscfs (:,:), &
         auxr (:), au2r (:), ps0 (:), ps1 (:,:), ps2 (:,:,:), &
         becp1_sw (:,:)
  ! wavefunctions swap space
  ! the chi-wavefunction
  ! auxiliary space
  ! auxiliary wavefunct. in G-space
  ! auxiliary wavefunct. in G-space
  ! auxiliary wavefunct. in G-space
  ! potential on the smooth grid
  ! auxiliary wavefunct. in real space
  ! scalar products
  complex(DP) :: itdba, tmpc, ZDOTC
  ! i / ( 2 * delta_xk )
  ! working space
  ! the scalar product function

  allocate (et_sw     (nbnd)          )
  allocate (ev_sw     (npwx,nbnd)     )
  allocate (chif      (npwx,nbnd,6)   )
  allocate (depsi     (npwx,nbnd,3)   )
  allocate (auxg      (npwx)          )
  allocate (dvscfs    (nrxxs,3)       )
  allocate (auxr      (nrxxs)         )
  allocate (au2r      (nrxxs)         )
  allocate (ps0       (nbnd)          )
  allocate (ps1       (nbnd,nbnd)     )
  allocate (ps2       (nbnd,nbnd,3)   )
  allocate (becp1_sw  (nkb,nbnd)      )

  call start_clock('dhdrhopsi')
  write (6,'(/5x,''Derivative coefficient:'',f10.6)') dek
  itdba = CMPLX (0.d0, 0.5d0 / (dek * tpiba))
  npwq = npw
  max_iter = 20
  if (nksq.gt.1) rewind (iunigk)

  !
  ! d_test = .true. ==> computes the dielectric tensor in an alternative way
  !   ( this is used only for testing or debugging purposes )
  !
  d_test = .true.

  !
  ! Read the variation of the charge-density and calculates the
  ! local part of first-order variation of the self-consistent 
  ! Hamiltonian on the smooth grid --kept in dvscfs(nrxxs,3)--
  !
  call set_dvscf(dvscfs)

  do ik = 1, nksq
     write(6,'(/,8x,''k('',i4,'') = ('',3f12.7,'')'',/)') &
             ik, ( xk( ipa, ik), ipa = 1, 3)
     !
     ! -------------------------1-st Step -------------------------
     ! Computes the derivative with respect to the k-point by finite
     !    differentiation
     !
     if (nksq.gt.1) read (iunigk) npw, igk
     npwq = npw
     chif (:,:,:) = (0.d0, 0.d0)
     !
     ! ev_sw contains the wavefunction of the k-point; the real value of the
     !   k-point and of the eigenvalues are written on a swap space
     !
     call DCOPY (3, xk (1, ik), 1, xk_sw, 1)
     call DCOPY (nbnd, et (1, ik), 1, et_sw, 1)
     call ZCOPY (nkb * nbnd, becp1 (1, 1, ik), 1, becp1_sw, 1)
     call davcio (ev_sw, lrwfc, iuwfc, ik, -1)

     avg_iter1 = 0.d0
     avg_iter2 = 0.d0

     do ipa = 1, 3
        do isg = -1, 1, 2
           !
           ! Now xk = xk + dek ; where dek is a small vector
           ! We are deriving with respect to the three crystal axes
           !
           do ipb = 1, 3
              xk(ipb,ik) = xk_sw(ipb) + &
                     DBLE(isg)*dek*at(ipb,ipa)
           enddo
           !
           ! Calculates in a non self-consistent way the wavefunction
           ! at xk+dek and stores in evc
           !
           call ZCOPY (npwx * nbnd, ev_sw, 1, evc, 1) ! set an initial value
           call hdiag ( max_iter, avg_iter1, xk(1,ik), et(1,ik) )

!           call init_us_2 (npw, igk, xk (1, ik), vkb)
           call ccalbec (nkb, npwx, npw, nbnd, becp1 (1, 1, ik), vkb, evc)
           do ipb = 1, 3
              !
              ! Calculates in a non-scf way the derivative of the
              ! wavefunction at xk+dek.
              !    solve_e_nscf uses:
              !    vkb, g2kin  --common variables previously calcd. by hdiag--
              !    evc         --contains the wavefunction at xk+dek--
              !    dvscfs      --self consist. part of the potential deriv.--
              !    The derivatives of the wavefunctions are stored in dpsi
              !

              call solve_e_nscf( avg_iter2, eth_ns, ik, ipb, dvscfs, auxr )
              !
              ! Now sets chi =  i * d/dk (sum_j |Du(j)><u(j)|) |u>
              !
              do ibnd = 1, nbnd_occ (ik)
                 do jbnd = 1, nbnd_occ (ik)
                    ps1 (jbnd, ibnd) = ZDOTC (npwq, &
                         evc (1, jbnd), 1, ev_sw (1, ibnd), 1)
                 enddo
              enddo
#ifdef __PARA
              call reduce (2 * nbnd * nbnd, ps1)
#endif
              tmpc = DBLE (isg) * itdba
              if (ipb.eq.ipa) tmpc = 2.d0 * tmpc
              do ibnd = 1, nbnd_occ (ik)
                 auxg (:) = (0.d0, 0.d0)
                 do jbnd = 1, nbnd_occ (ik)
                    call ZAXPY (npwq, ps1 (jbnd, ibnd), &
                               dpsi (1, jbnd), 1, auxg, 1)
                 enddo
                 call ZAXPY (npwq, tmpc, auxg, 1, &
                               chif (1, ibnd, jab (ipa, ipb)), 1)
              enddo
          enddo
        enddo
     enddo

#ifdef __PARA
     call poolreduce (1, avg_iter1) 
     call poolreduce (1, avg_iter2) 
     avg_iter1 = avg_iter1 / npool 
     avg_iter2 = avg_iter2 / npool 
#endif
     write (6, 9000) ik, eth_ns,  avg_iter1 / 6.d0
     write (6, 9010) ik, eth_ns,  avg_iter2 / 18.d0

     if (d_test) then
        do ipa = 1, 6
           nrec = (ipa - 1) * nksq + ik
           call davcio (chif (1, 1, ipa), lrd2w, iud2w, nrec, 1)
        enddo
     endif
     !
     ! Set xk, et , becp1, evc to their original values
     !
     call DCOPY (3, xk_sw, 1, xk (1, ik), 1)
     call DCOPY (nbnd, et_sw, 1, et (1, ik), 1)
     call ZCOPY (nkb * nbnd, becp1_sw, 1, becp1 (1, 1, ik), 1)
     call ZCOPY (npwx * nbnd, ev_sw, 1, evc, 1)
     !
     ! -------------------------2-nd Step -------------------------
     !
     do ipa = 1, 3
        dvpsi (:,:) = (0.d0, 0.d0)
        do ibnd = 1, nbnd_occ (ik)
           call cft_wave (evc (1, ibnd), auxr, +1 )
           do ir = 1, nrxxs
              auxr (ir) = auxr (ir) * dvscfs (ir, ipa)
           enddo
           call cft_wave (dvpsi (1, ibnd), auxr, -1 )
           do jbnd = 1, nbnd_occ (ik)
              ps2 (jbnd, ibnd, ipa ) = &
                     -ZDOTC (npwq, evc (1, jbnd), 1, dvpsi (1, ibnd), 1)
           enddo
        enddo
     enddo
#ifdef __PARA
     call reduce (2 * nbnd * nbnd * 3, ps2 )
#endif
     do ipa = 1, 3
        nrec = (ipa - 1) * nksq + ik
        call davcio (dpsi, lrdwf, iudwf, nrec, -1)
        do ibnd = 1, nbnd_occ (ik)
           call cft_wave (dpsi (1, ibnd), auxr, +1)
           do ipb = 1, 3
              auxg (:) = (0.d0, 0.d0)
              do ir = 1, nrxxs
                 au2r (ir) = auxr (ir) * dvscfs (ir, ipb)
              enddo
              call cft_wave (auxg, au2r, -1)
              do jbnd = 1, nbnd_occ (ik)
                 call ZAXPY (npwq, ps2 (jbnd, ibnd, ipb ), &
                            dpsi (1, jbnd), 1, auxg, 1)
              enddo
              tmpr = 1.d0
              if (ipa.eq.ipb) tmpr = 2.d0
              call DAXPY(2 * npwq, tmpr, auxg, 1, &
                         chif (1, ibnd, jab (ipa, ipb)), 1)
           enddo
        enddo
     enddo
     !
     ! Orthogonalize chi-functions to the valence space
     !
     do ipa = 1, 6
        do ibnd = 1, nbnd_occ (ik)
           auxg (:) = (0.d0, 0.d0)
           do jbnd = 1, nbnd_occ (ik)
              ps0 (jbnd) = -ZDOTC (npw, evc (1, jbnd), 1, &
                                     chif (1, ibnd, ipa), 1)
           enddo
#ifdef __PARA
           call reduce (2 * nbnd, ps0) 
#endif
           do jbnd = 1, nbnd_occ (ik)
              call ZAXPY (npw, ps0 (jbnd), evc (1, jbnd), 1, auxg, 1)
           enddo
           call DAXPY (2 * npw, 1.0d0, auxg, 1, chif (1, ibnd, ipa), 1)
        enddo
     enddo
     !
     ! writes the chi-function on file
     !
     do ipa = 1, 6
        nrec = (ipa - 1) * nksq + ik
        call davcio (chif (1, 1, ipa), lrchf, iuchf, nrec, +1)
     enddo
  enddo

  if (d_test) call dielec_test

  deallocate (et_sw    )
  deallocate (ev_sw    )
  deallocate (chif     )
  deallocate (depsi    )
  deallocate (auxg     )
  deallocate (dvscfs   )
  deallocate (auxr     )
  deallocate (au2r     )
  deallocate (ps0      )
  deallocate (ps1      )
  deallocate (ps2      )
  deallocate (becp1_sw )

9000 format (5x,'Non-scf  u_k:',i4,' ,thr. = ',1pe9.2, &
        &   ', avg iteration # =',0pf5.1 )
9010 format (5x,'Non-scf Du_k:',i4,' ,thr. = ',1pe9.2, &
        &   ', avg iteration # =',0pf5.1 )

  call stop_clock('dhdrhopsi')
  return
end subroutine dhdrhopsi
