!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine dpsidvdpsi (nu_q0)
  !-----------------------------------------------------------------------
  !
#include "machine.h"
  use pwcom
  use phcom
  use d3com

  implicit none
  integer :: nu_q0
!
  integer :: ik, ikk, ikq, ig, ibnd, nu_i, nu_j, nu_z, nrec, ios
  real (8) :: zero (3), wgauss, wga (nbnd), wg1
  complex (8) :: wrk, ZDOTC
  complex (8), allocatable :: dqpsi (:,:), dvloc (:), d3dyn1 (:,:,:), &
       d3dyn2 (:,:,:), d3dyn3 (:,:,:)


  allocate  (dqpsi( npwx, nbnd))    
  allocate  (dvloc( nrxx))    
  allocate  (d3dyn1( 3 * nat, 3 * nat, 3 * nat))    
  if (.not.allmodes) then
     allocate  (d3dyn2( 3 * nat, 3 * nat, 3 * nat))    
     allocate  (d3dyn3( 3 * nat, 3 * nat,3 * nat))    
  endif

  call setv (3, 0.d0, zero, 1)
  call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn1, 1)
  if (.not.allmodes) then
     call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn2, 1)
     call setv (2 * 27 * nat * nat * nat, 0.d0, d3dyn3, 1)
  endif
  nu_z = nu_q0

  call dvscf (nu_z, dvloc, zero)

  rewind (unit = iunigk)

  do ik = 1, nksq
     if (.not.lgamma) read (iunigk, err = 100, iostat = ios) npwq, &
          igkq
     read (iunigk, err = 100, iostat = ios) npwq, igkq
100  call error ('dpsidvdpsi', 'reading iunigk-iunigkq', abs (ios) )
     npw = npwq
     do ig = 1, npwx
        igk (ig) = igkq (ig)
     enddo
     if (lgamma) then
        ikk = ik
        ikq = ik
     else
        ikk = 2 * ik - 1
        ikq = 2 * ik
     endif
     call init_us_2 (npwq, igkq, xk (1, ikq), vkb)

     wg1 = wk (ikk)
     if (degauss.ne.0.d0) then
        do ibnd = 1, nbnd
           wga (ibnd) = wgauss ( (ef - et (ibnd, ikk) ) / degauss, ngauss)
        enddo
     endif
     do nu_i = 1, 3 * nat
        nrec = (nu_i - 1) * nksq + ik
        call davcio (dpsi, lrdwf, iudqwf, nrec, - 1)

        call dvdpsi (nu_z, zero, dvloc, vkb, vkb, dpsi, dvpsi)
        do nu_j = 1, 3 * nat
           nrec = (nu_j - 1) * nksq + ik

           call davcio (dqpsi, lrdwf, iudqwf, nrec, - 1)
           wrk = DCMPLX (0.d0, 0.d0)
           do ibnd = 1, nbnd
              if (degauss.ne.0.d0) wg1 = wk (ikk) * wga (ibnd)
              wrk = wrk + 2.d0 * wg1 * ZDOTC (npwq, dqpsi (1, ibnd), 1, dvpsi ( &
                   1, ibnd), 1)
           enddo
#ifdef PARA
           call reduce (2, wrk)
#endif
           d3dyn1 (nu_z, nu_j, nu_i) = d3dyn1 (nu_z, nu_j, nu_i) + wrk
        enddo
     enddo

  enddo
  if (.not.allmodes) then

     rewind (unit = iunigk)

     do ik = 1, nksq
        read (iunigk, err = 110, iostat = ios) npw, igk
        if (.not.lgamma) read (iunigk, err = 110, iostat = ios) npwq, &
             igkq

110     call error ('dpsidvdpsi', 'reading iunigk-iunigkq', abs (ios) )
        if (lgamma) then
           npwq = npw
           ikk = ik
           ikq = ik
        else
           ikk = 2 * ik - 1
           ikq = 2 * ik
        endif

        call init_us_2 (npw, igk, xk (1, ikk), vkb0)
        call init_us_2 (npwq, igkq, xk (1, ikq), vkb)

        wg1 = wk (ikk)
        if (degauss.ne.0.d0) then
           do ibnd = 1, nbnd
              wga (ibnd) = wgauss ( (ef - et (ibnd, ikk) ) / degauss, &
                   ngauss)
           enddo
        endif

        nu_i = nu_q0
        do nu_z = 1, 3 * nat
           call dvscf (nu_z, dvloc, xq)
           nrec = (nu_i - 1) * nksq + ik
           call davcio (dpsi, lrdwf, iudwf, nrec, - 1)

           call dvdpsi (nu_z, xq, dvloc, vkb0, vkb, dpsi, dvpsi)

           do nu_j = 1, 3 * nat
              nrec = (nu_j - 1) * nksq + ik
              call davcio (dqpsi, lrdwf, iudqwf, nrec, - 1)
              wrk = DCMPLX (0.d0, 0.d0)
              do ibnd = 1, nbnd
                 if (degauss.ne.0.d0) wg1 = wk (ikk) * wga (ibnd)
                 wrk = wrk + 2.d0 * wg1 * ZDOTC (npwq, dvpsi (1, ibnd), 1, &
                      dqpsi (1, ibnd), 1)
              enddo
#ifdef PARA
              call reduce (2, wrk)
#endif
              d3dyn2 (nu_i, nu_z, nu_j) = d3dyn2 (nu_i, nu_z, nu_j) + wrk
              d3dyn3 (nu_i, nu_j, nu_z) = d3dyn3 (nu_i, nu_j, nu_z) + conjg(wrk)
           enddo
        enddo
     enddo

  endif
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
              d3dyn (nu_i, nu_j, nu_z) = d3dyn (nu_i, nu_j, nu_z) + &
                                         d3dyn1(nu_i, nu_j, nu_z) + &
                                         d3dyn1(nu_j, nu_z, nu_i) + &
                                         d3dyn1(nu_z, nu_i, nu_j)
              d3dyn_aux5 (nu_i, nu_j, nu_z) = d3dyn_aux5 (nu_i, nu_j, nu_z) &
                   + d3dyn1 (nu_i, nu_j, nu_z) + d3dyn1 (nu_j, nu_z, nu_i) &
                   + d3dyn1 (nu_z, nu_i, nu_j)
           else
              d3dyn (nu_i, nu_j, nu_z) = d3dyn (nu_i, nu_j, nu_z) + &
                                         d3dyn1(nu_i, nu_j, nu_z) + &
                                         d3dyn2(nu_i, nu_j, nu_z) + &
                                         d3dyn3(nu_i, nu_j, nu_z)
              d3dyn_aux5 (nu_i, nu_j, nu_z) = d3dyn_aux5 (nu_i, nu_j, nu_z) &
                   + d3dyn1 (nu_i, nu_j, nu_z) + d3dyn2 (nu_i, nu_j, nu_z) &
                   + d3dyn3 (nu_i, nu_j, nu_z)
           endif
        enddo
     enddo
  enddo

  if (.not.allmodes) then
     deallocate (d3dyn3)
     deallocate (d3dyn2)
  endif
  deallocate (d3dyn1)
  deallocate (dqpsi)
  deallocate (dvloc)
  return
end subroutine dpsidvdpsi
