!--------------------------------------------------------
subroutine add_zstar_ue_us(imode0,npe)
!----------===============-------------------------------
  ! add the contribution of the modes imode0+1 -> imode+npe
  ! to the effective charges Z(Us,E) (Us=scf,E=bare)
  ! 
  ! This subroutine is just for the USPP case
  !
  ! trans =.true. is needed for this calculation to be meaningful
  !
#include "machine.h"

  USE pwcom
  USE parameters, ONLY : DP
  USE wavefunctions,    ONLY : evc
  USE phcom
  USE becmod
  implicit none

  integer, intent(in) :: imode0, npe
  
  integer :: ik, jpol, nrec, mode, ipert, ibnd, jbnd, i,j 

  real(kind = dp) :: weight

  complex(kind=DP), allocatable :: pdsp(:,:)
  !  auxiliary space for <psi|ds/du|psi>

  ! 
  !  Here we calculate the dipole of q
  !  (Just to be sure, this has already beeen done in phq_setup)
  !
  call compute_qdipol

  
  allocate (pdsp(nbnd,nbnd))

  if (nksq.gt.1) rewind (iunigk)
  do ik = 1, nksq
     if (nksq.gt.1) read (iunigk) npw, igk
     npwq = npw
     weight = wk (ik)
     if (nksq.gt.1) call davcio (evc, lrwfc, iuwfc, ik, - 1)
     call init_us_2 (npw, igk, xk (1, ik), vkb)
     do ipert = 1, npe
        mode = imode0 + ipert
        do jpol = 1, 3
           dvpsi = (0.d0,0.d0)
           !
           ! calculates the Commutator with the additional term
!                      call dvpsi_e(ik,jpol)
           !
           ! To save time:
           ! Reads the commutator with the additional term
           ! dvpis(G,ibnd) = <k+G | (P_c^+ S x - S x + K(x) x) | psi_ibnd >
           !
           nrec = (jpol - 1) * nksq + ik
           call davcio (dvpsi, lrbar, iubar, nrec, -1)
           !
           ! Calculate the matrix elements <psi_v'k|dS/du|psi_vk>
           ! Note: we need becp1 
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
                 zstarue0(mode,jpol)=zstarue0(mode,jpol) +              &
                      weight *                                          &
                      dot_product(evc(1:npw,ibnd),dvpsi(1:npw,jbnd))*   &
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
           ! Apply the matrix dS/du, the result is stored in dvpsi
           !
           call add_for_charges(ik, u(1,mode))
           !
           ! Add  (dK(r)/du - dS/du) r | psi>
           !
           call add_dkmds(ik, u(1,mode),jpol)
           !
           ! And calculate finally the scalar product 
           !
           do ibnd = 1, nbnd
              zstarue0(mode,jpol)=zstarue0(mode,jpol) - weight *   &
                   dot_product(evc(1:npw,ibnd),dvpsi(1:npw,ibnd))
           enddo
        enddo
     enddo
  enddo
  
  deallocate(pdsp)

  return
end subroutine add_zstar_ue_us





