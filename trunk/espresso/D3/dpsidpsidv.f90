!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine dpsidpsidv  
  !-----------------------------------------------------------------------
#include "machine.h"
  use pwcom
  use phcom
  use d3com
  use allocate

  implicit none
  integer :: ik, ikk, ikq, ibnd, jbnd, nu_i, nu_j, nu_z, nrec  
  real (8) :: wgauss, wga (nbnd), wgq (nbnd), w0gauss, w0g (nbnd), &
       deltae, wg1, wg2, wwg
  complex (8) :: wrk, wrk0, ZDOTC
  complex (8), pointer :: dqpsi (:,:), ps1_ij (:,:),  ps1_ji (:,:), &
       ps3_ij (:,:), ps2_ji (:,:), d3dyn1 (:,:,:), d3dyn2 (:,:,:),&
       d3dyn3 (:,:,:)


  call mallocate (dqpsi, npwx, nbnd)  
  if (degauss.ne.0.d0) then  
     call mallocate (ps1_ij, nbnd, nbnd)  
     call mallocate (ps1_ji, nbnd, nbnd)  
     call mallocate (ps3_ij, nbnd, nbnd)  
     call mallocate (ps2_ji, nbnd, nbnd)  
  endif
  call mallocate (d3dyn1, 3 * nat, 3 * nat, 3 * nat)  
  if (.not.allmodes) then  
     call mallocate (d3dyn2, 3 * nat, 3 * nat, 3 * nat)  
     call mallocate (d3dyn3, 3 * nat, 3 * nat, 3 * nat)  
  endif
  call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn1, 1)  
  if (.not.allmodes) then  
     call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn2, 1)  
     call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn3, 1)  

  endif

  do ik = 1, nksq  
     if (lgamma) then  
        ikk = ik  
        ikq = ik  
     else  
        ikk = 2 * ik - 1  
        ikq = 2 * ik  

     endif
     if (degauss.ne.0.d0) then  
        do ibnd = 1, nbnd  
           wga (ibnd) = wgauss ( (ef - et (ibnd, ikk) ) / degauss, ngauss)  
           wgq (ibnd) = wgauss ( (ef - et (ibnd, ikq) ) / degauss, ngauss)  
           w0g (ibnd) = w0gauss ( (ef - et (ibnd, ikk) ) / degauss, &
                ngauss) / degauss
        enddo

     endif
     do nu_i = 1, 3 * nat  
        nrec = (nu_i - 1) * nksq + ik  

        call davcio (dpsi, lrdwf, iudqwf, nrec, - 1)  
        do nu_j = 1, 3 * nat  
           nrec = (nu_j - 1) * nksq + ik  

           call davcio (dqpsi, lrdwf, iudqwf, nrec, - 1)  
           if (degauss.ne.0.d0) then  
              nrec = nu_i + (nu_j - 1) * 3 * nat + (ik - 1) * 9 * nat * nat  
              call davcio (ps1_ij, lrdpdvp, iudpdvp_1, nrec, - 1)  
              nrec = nu_j + (nu_i - 1) * 3 * nat + (ik - 1) * 9 * nat * nat  
              call davcio (ps1_ji, lrdpdvp, iudpdvp_1, nrec, - 1)  

           endif
           do nu_z = 1, 3 * nat  
              if (q0mode (nu_z) ) then  
                 nrec = nu_z + (ik - 1) * 3 * nat  

                 call davcio (psidqvpsi, lrpdqvp, iupd0vp, nrec, - 1)  
                 wrk0 = DCMPLX (0.d0, 0.d0)  
                 wrk = DCMPLX (0.d0, 0.d0)  
                 do ibnd = 1, nbnd  
                    do jbnd = 1, nbnd  
                       if (degauss.ne.0.d0) then  
                          deltae = et (ibnd, ikk) - et (jbnd, ikk)  
                          if (abs (deltae) .gt.1.0d-5) then  
                             wg1 = wga (ibnd) / deltae  

                             wg2 = wga (jbnd) / deltae  

                             wrk0 = wrk0 + psidqvpsi (jbnd, ibnd) * (wg1 * ps1_ij ( &
                                  ibnd, jbnd) - wg2 * conjg (ps1_ji (jbnd, ibnd) ) )
                          else  
                             wg1 = wga (ibnd)  

                             wwg = w0g (ibnd)  
                             wrk0 = wrk0 - psidqvpsi (jbnd, ibnd) * wwg * ps1_ij ( &
                                  ibnd, jbnd)
                             wrk = wrk - psidqvpsi (jbnd, ibnd) * wg1 * ZDOTC (npwq, &
                                  dpsi (1, ibnd), 1, dqpsi (1, jbnd), 1)
                          endif
                       else  
                          wrk = wrk - psidqvpsi (jbnd, ibnd) * ZDOTC (npwq, dpsi (1, &
                               ibnd), 1, dqpsi (1, jbnd), 1)
                       endif
                    enddo
                 enddo
#ifdef PARA
                 call reduce (2, wrk)  
#endif
                 wrk = wrk + wrk0  
                 wrk = 2.d0 * wk (ikk) * wrk  

                 d3dyn1 (nu_z, nu_i, nu_j) = d3dyn1 (nu_z, nu_i, nu_j) + wrk  
              endif
           enddo
        enddo

     enddo
     if (.not.allmodes) then  
        do nu_j = 1, 3 * nat  
           nrec = (nu_j - 1) * nksq + ik  

           call davcio (dqpsi, lrdwf, iudqwf, nrec, - 1)  
           do nu_i = 1, 3 * nat  
              if (q0mode (nu_i) ) then  
                 nrec = (nu_i - 1) * nksq + ik  

                 call davcio (dpsi, lrdwf, iud0qwf, nrec, - 1)  
                 if (degauss.ne.0.d0) then  
                    nrec = nu_i + (nu_j - 1) * 3 * nat + (ik - 1) * 9 * nat * &
                         nat
                    call davcio (ps3_ij, lrdpdvp, iudpdvp_3, nrec, - 1)  
                    nrec = nu_j + (nu_i - 1) * 3 * nat + (ik - 1) * 9 * nat * &
                         nat
                    call davcio (ps2_ji, lrdpdvp, iudpdvp_2, nrec, - 1)  

                 endif
                 do nu_z = 1, 3 * nat  
                    nrec = nu_z + (ik - 1) * 3 * nat  

                    call davcio (psidqvpsi, lrpdqvp, iupdqvp, nrec, - 1)  
                    wrk0 = DCMPLX (0.d0, 0.d0)  
                    wrk = DCMPLX (0.d0, 0.d0)  
                    do ibnd = 1, nbnd  
                       do jbnd = 1, nbnd  
                          if (degauss.ne.0.d0) then  
                             deltae = et (ibnd, ikk) - et (jbnd, ikq)  
                             if (abs (deltae) .gt.1.0d-5) then  
                                wg1 = wga (ibnd) / deltae  

                                wg2 = wgq (jbnd) / deltae  
                                wrk0 = wrk0 + psidqvpsi (jbnd, ibnd) * (wg1 * ps2_ji ( &
                                     ibnd, jbnd) - wg2 * conjg (ps3_ij (jbnd, ibnd) ) )
                             else  
                                wg1 = wga (ibnd)  

                                wwg = w0g (ibnd)  
                                wrk0 = wrk0 - psidqvpsi (jbnd, ibnd) * wwg * ps2_ji ( &
                                     ibnd, jbnd)
                                wrk = wrk - psidqvpsi (jbnd, ibnd) * wg1 * ZDOTC ( &
                                     npwq, dqpsi (1, ibnd), 1, dpsi (1, jbnd), 1)
                             endif
                          else  
                             wrk = wrk - psidqvpsi (jbnd, ibnd) * ZDOTC (npwq, dqpsi ( &
                                  1, ibnd), 1, dpsi (1, jbnd), 1)
                          endif
                       enddo
                    enddo
#ifdef PARA
                    call reduce (2, wrk)  
#endif
                    wrk = wrk + wrk0  
                    wrk = 2.d0 * wk (ikk) * wrk  
                    d3dyn2 (nu_i, nu_j, nu_z) = d3dyn2 (nu_i, nu_j, nu_z) &
                         + wrk

                    d3dyn3 (nu_i, nu_z, nu_j) = d3dyn3 (nu_i, nu_z, nu_j) &
                         + conjg (wrk)
                 enddo
              endif
           enddo
        enddo

     endif
  enddo
#ifdef PARA
  call poolreduce (2 * 27 * nat * nat * nat, d3dyn1)  
  if (.not.allmodes) then  
     call poolreduce (2 * 27 * nat * nat * nat, d3dyn2)  
     call poolreduce (2 * 27 * nat * nat * nat, d3dyn3)  
  endif
#endif
  do nu_i = 1, 3 * nat  
     do nu_j = 1, 3 * nat  
        do nu_z = 1, 3 * nat  
           if (allmodes) then  
              d3dyn (nu_i, nu_j, nu_z) = d3dyn (nu_i, nu_j, nu_z) + d3dyn1 ( &
                   nu_i, nu_j, nu_z) + d3dyn1 (nu_j, nu_z, nu_i) + d3dyn1 (nu_z, &
                   nu_i, nu_j)
              d3dyn_aux6 (nu_i, nu_j, nu_z) = d3dyn_aux6 (nu_i, nu_j, nu_z) &
                   + d3dyn1 (nu_i, nu_j, nu_z) + d3dyn1 (nu_j, nu_z, nu_i) &
                   + d3dyn1 (nu_z, nu_i, nu_j)
           else  
              d3dyn (nu_i, nu_j, nu_z) = d3dyn (nu_i, nu_j, nu_z) + d3dyn1 ( &
                   nu_i, nu_j, nu_z) + d3dyn2 (nu_i, nu_j, nu_z) + d3dyn3 (nu_i, &
                   nu_j, nu_z)
              d3dyn_aux6 (nu_i, nu_j, nu_z) = d3dyn_aux6 (nu_i, nu_j, nu_z) &
                   + d3dyn1 (nu_i, nu_j, nu_z) + d3dyn2 (nu_i, nu_j, nu_z) &
                   + d3dyn3 (nu_i, nu_j, nu_z)
           endif
        enddo
     enddo

  enddo
  call mfree (dqpsi)  
  if (degauss.ne.0.d0) then  
     call mfree (ps1_ij)  
     call mfree (ps1_ji)  
     call mfree (ps3_ij)  
     call mfree (ps2_ji)  
  endif
  call mfree (d3dyn1)  
  if (.not.allmodes) then  
     call mfree (d3dyn2)  
     call mfree (d3dyn3)  

  endif
  return  
end subroutine dpsidpsidv
