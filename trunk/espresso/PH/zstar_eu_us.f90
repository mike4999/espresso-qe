!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!--------------------------------------------------------------
subroutine zstar_eu_us
!----------===========-----------------------------------------
  !
  ! Calculates the additional part of the Born effective charges 
  ! in the case of USPP
  !
#include "f_defs.h"
  !
  USE ions_base, ONLY : nat
  USE kinds, only : DP
  USE wavefunctions_module,    ONLY : evc
  USE io_files, ONLY: iunigk
  USE uspp_param,            ONLY : nhm
  use pwcom
  use phcom
  !
  implicit none
  integer :: ibnd, jbnd, ipol, jpol, imode0, irr, imode, nrec, mode
  integer :: ik,  ig, ir, is, i,j 
  integer :: iuhxc, lrhxc
  !
  real(DP) :: weight
  !
  complex(DP) , allocatable :: dbecsum(:,:,:,:), aux1 (:)
  ! the becsum with dpsi
  ! auxillary work space for fft
  complex(DP) , pointer ::      &
      dvscf(:,:,:), &
      dvscfins (:,:,:)    ! change of the scf potential (smooth)
  complex(DP), allocatable :: pdsp(:,:)
  complex(DP), allocatable :: drhoscfh (:,:,:)
  complex(DP), allocatable :: dbecsum2 (:,:,:,:)
  complex(DP), allocatable :: dvkb (:,:,:)
  integer :: npe, irr1, imode1

#ifdef TIMINIG_ZSTAR_US
  call start_clock('zstar_eu_us')
  call start_clock('zstar_us_1')
#endif

  !  auxiliary space for <psi|ds/du|psi>

  allocate (dvscf( nrxx , nspin, 3))
  allocate (dbecsum( nhm*(nhm+1)/2, nat, nspin, 3))
  allocate (aux1(  nrxxs))
  allocate (pdsp(nbnd,nbnd))

  if (doublegrid) then
     allocate (dvscfins(  nrxxs, nspin, 3))    
  else
     dvscfins => dvscf
  endif
  !
  ! Set the initial values to zero
  !
  pdsp    = (0.d0,0.d0)
  dvscf   = (0.d0,0.d0)
  dbecsum = (0.d0,0.d0)
  !
  ! first we calculate the perturbed charge density and the perturbed 
  ! Hartree and exchange and correlation potential , which we need later 
  ! for the calculation of the Hartree and xc part
  !
  if (nksq.gt.1) rewind (iunigk)
  do ik = 1, nksq
     if (nksq.gt.1) read (iunigk) npw, igk
     npwq = npw
     if (nksq.gt.1) call davcio (evc, lrwfc, iuwfc, ik, - 1)
     call init_us_2 (npw, igk, xk(1,ik), vkb)
     weight = wk (ik)
     do jpol = 1, 3
        nrec = (jpol - 1) * nksq + ik
        call davcio (dpsi, lrdwf, iudwf, nrec, - 1)
        call incdrhoscf (dvscf(1,1,jpol),weight,ik,  &
             dbecsum(1,1,1,jpol), 1)
     end do
  end do

#ifdef __PARA
     call reduce (nhm * (nhm + 1) * nat * 3* nspin, dbecsum)
#endif
#ifdef TIMINIG_ZSTAR_US
  call stop_clock('zstar_us_1')
  call start_clock('zstar_us_2')
#endif
  
  if (doublegrid) then
     do is = 1, nspin
        do ipol = 1, 3
           call cinterpolate(dvscf(1,is,ipol),dvscf(1,is,ipol), 1)
        end do
     end do
  end if

  call addusddense (dvscf, dbecsum)

#ifdef __PARA
  call poolreduce (2 * 3 * nrxx *nspin, dvscf)
#endif

#ifdef TIMINIG_ZSTAR_US
  call stop_clock('zstar_us_2')
  call start_clock('zstar_us_3')
#endif

  if (nlcc_any) call addnlcc_zstar_eu_us (dvscf) 

  do ipol = 1, 3
     !
     ! Instead of recalculating the perturbed charge density, 
     ! it can also be read from file
     ! NB: Then the variable fildrho must be set
     !
     ! call davcio_drho(dvscf(1,1,ipol),lrdrho,iudrho,ipol,-1)
     !
     call dv_of_drho (0, dvscf (1, 1, ipol), .false.)
  enddo
#ifdef __PARA
  call psyme (dvscf)
#else
  call syme (dvscf)
#endif

  if (doublegrid) then
     do is=1,nspin
        do ipol = 1, 3
           call cinterpolate (dvscf(1,is,ipol),dvscfins(1,is,ipol),-1)
        enddo
     enddo
  endif
#ifdef TIMINIG_ZSTAR_US
  call stop_clock('zstar_us_3')
  call start_clock('zstar_us_4')
#endif
!
! Calculate the parts with the perturbed Hartree and exchange and correlation 
! potenial  
!
  imode1 = 0
  do irr = 1, nirr
     npe = npert(irr)
     imode0 = 0

     allocate(drhoscfh ( nrxx , nspin , npe))    
     allocate(dbecsum2 ( (nhm * (nhm + 1))/2 , nat , nspin , npe))

     do irr1 = 1, irr - 1
        imode0 = imode0 + npert (irr1)
     enddo
     drhoscfh = (0.0_dp,0.0_dp)
     dbecsum2 = (0.0_dp,0.0_dp)  
     call addusddens (drhoscfh, dbecsum2, irr, imode0, npe, 0)
     do imode = 1, npert (irr)
        mode = imode+imode1
        do jpol = 1, 3
           zstareu0(jpol,mode) =  zstareu0(jpol,mode) -                   &
               dot_product(dvscf(1:nrxx,1,jpol),drhoscfh(1:nrxx,1,imode)) &
               * omega / DBLE(nr1*nr2*nr3) 
        end do
     end do
     imode1 = imode1 + npert (irr)

     deallocate (drhoscfh)
     deallocate (dbecsum2)

  end do
#ifdef TIMINIG_ZSTAR_US
  call stop_clock('zstar_us_4')
  call start_clock('zstar_us_5')
#endif
  !
  !  Calculate the part with the position operator
  !
  allocate (dvkb(npwx,nkb,3))
  if (nksq.gt.1) rewind (iunigk)
  do ik = 1, nksq
     if (nksq.gt.1) read (iunigk) npw, igk
     npwq = npw
     weight = wk (ik)
     if (nksq.gt.1) call davcio (evc, lrwfc, iuwfc, ik, - 1)
     call init_us_2 (npw, igk, xk (1, ik), vkb)
     call dvkb3(ik, dvkb)
     imode0 = 0
     do irr = 1, nirr
        do imode = 1, npert (irr)
           mode = imode+imode0
           do jpol = 1, 3
              dvpsi = (0.d0,0.d0)
              ! 
              ! read the Commutator+add. terms
              !
              nrec = (jpol - 1) * nksq + ik
              call davcio (dvpsi, lrebar, iuebar, nrec, - 1)
              !
              pdsp = (0.d0,0.d0)
              call psidspsi (ik, u (1, mode), pdsp,npw)
#ifdef __PARA
          call reduce(2*nbnd*nbnd,pdsp)
#endif
              !
              ! add the term of the double summation
              !
              do ibnd = 1, nbnd
                 do jbnd = 1, nbnd
                    zstareu0(jpol,mode)=zstareu0(jpol, mode) +           &
                         weight *                                        &
                         dot_product(evc(1:npw,ibnd),dvpsi(1:npw,jbnd))* &
                         pdsp(jbnd,ibnd)
                 enddo
              enddo
              dvpsi = (0.d0,0.d0)
              dpsi  = (0.d0,0.d0)
              !
              ! For the last part, we read the commutator from disc, 
              ! but this time we calculate 
              ! dS/du P_c [H-eS]|psi> + (dK(r)/du - dS/du)r|psi>
              !
              ! first we read  P_c [H-eS]|psi> and store it in dpsi
              !
              nrec = (jpol - 1) * nksq + ik
              call davcio (dpsi, lrcom, iucom, nrec, -1)
              !
              ! Apply the matrix dS/du
              !
              call add_for_charges(ik, u(1,mode))
              !
              ! Add  (dK(r)/du - dS/du) r | psi>
              !
              call add_dkmds(ik, u(1,mode), jpol, dvkb)
              !
              ! And calculate finally the scalar product 
              !
              do ibnd = 1, nbnd
                 zstareu0(jpol,mode)=zstareu0(jpol, mode) - weight *  &
                      dot_product(evc(1:npw,ibnd),dvpsi(1:npw,ibnd))
              enddo
           enddo
        enddo
        imode0 = imode0 + npert (irr)
     enddo
  enddo
  deallocate (dvkb)

  imode0 = 0
  deallocate (pdsp)
  deallocate (dbecsum)
  deallocate (dvscf)
  deallocate (aux1)
  if (doublegrid) deallocate (dvscfins)

#ifdef TIMINIG_ZSTAR_US
  call stop_clock('zstar_us_5')
  call stop_clock('zstar_eu_us')
#endif

  return
end subroutine zstar_eu_us
