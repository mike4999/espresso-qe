!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------

subroutine drho
  !-----------------------------------------------------------------------
  !
  !    Here we compute, for each mode the change of the charge density
  !    due to the displacement, at fixed wavefunctions. These terms
  !    are saved on disk. The orthogonality part is included in the
  !    computed change.
  !
  !
#include"machine.h"

  use pwcom
  use parameters, only : DP
  use phcom
  implicit none

  integer :: nt, mode, mu, na, is, ir, irr, iper, npe, nrstot, nu_i, nu_j
  ! counter on atomic types
  ! counter on modes
  ! counter on atoms and polarizations
  ! counter on atoms
  ! counter on spin
  ! counter on perturbations
  ! the number of points
  ! counter on modes

  real(kind=DP), allocatable :: wgg (:,:,:)
  ! the weight of each point


  complex(kind=DP) :: ZDOTC, wdyn (3 * nat, 3 * nat)
  complex(kind=DP), pointer :: becq (:,:,:), alpq (:,:,:,:)
  complex(kind=DP), allocatable :: dvlocin (:), drhous (:,:,:),&
       drhoust (:,:,:), dbecsum(:,:,:,:)
  ! auxiliary to store bec at k+q
  ! auxiliary to store alphap at
  ! the change of the local potential
  ! the change of the charge density
  ! the change of the charge density
  ! the derivative

  if (recover) return
  dyn00(:,:) = (0.d0,0.d0)
  if (.not.okvan) return
  call start_clock ('drho')
  !
  !    first compute the terms needed for the change of the charge density
  !    due to the displacement of the augmentation charge
  !
  call compute_becsum

  call compute_alphasum
  !
  !    then compute the weights
  !
  allocate (wgg (nbnd ,nbnd , nksq))    
  if (lgamma) then
     becq => becp1
     alpq => alphap
  else
     allocate (becq ( nkb, nbnd , nksq))    
     allocate (alpq ( nkb, nbnd, 3, nksq))    
  endif
  call compute_weight (wgg)
  !
  !   we need the scalar products of the beta with the wavefunctions at k+
  !

  if (.not.lgamma) call compute_becalp (becq, alpq)
  !
  !    becq and alpq are sufficient to compute the part of C^3 (See Eq. 37
  !    which does not contain the local potential
  !
  call compute_nldyn (dyn00, wgg, becq, alpq)
  !
  !   now we compute the change of the charge density due to the change of
  !   the orthogonality constraint
  !
  allocate (drhous ( nrxxs , nspin , 3 * nat))    
  allocate (dbecsum( nhm * (nhm + 1) /2 , nat , nspin , 3 * nat))    

  call compute_drhous (drhous, dbecsum, wgg, becq, alpq)
  if (.not.lgamma) then
     deallocate (alpq)
     deallocate (becq)
  endif
  deallocate (wgg)
  !
  !  The part of C^3 (Eq. 37) which contain the local potential can be
  !  evaluated with an integral of this change of potential and drhous
  !
  allocate (dvlocin( nrxxs))    

  wdyn (:,:) = (0.d0, 0.d0)
  nrstot = nr1s * nr2s * nr3s
  do nu_i = 1, 3 * nat
     call compute_dvloc (nu_i, dvlocin)
     do nu_j = 1, 3 * nat
        do is = 1, nspin
           wdyn (nu_j, nu_i) = wdyn (nu_j, nu_i) + &
                ZDOTC (nrxxs, drhous(1,is,nu_j), 1, dvlocin, 1) * &
                omega / float (nrstot)
        enddo
     enddo

  enddo
#ifdef __PARA
  !
  ! collect contributions from all pools (sum over k-points)
  !
  call poolreduce (18 * nat * nat, dyn00)
  call poolreduce (18 * nat * nat, wdyn)
  !
  ! collect contributions from nodes of a pool (sum over G & R space)
  !
  call reduce (18 * nat * nat, wdyn)
#endif
  call ZAXPY (3 * nat * 3 * nat, (1.d0, 0.d0), wdyn, 1, dyn00, 1)
  !
  !     force this term to be hermitean
  !
  do nu_i = 1, 3 * nat
     do nu_j = 1, nu_i
        dyn00(nu_i,nu_j) = 0.5d0*( dyn00(nu_i,nu_j) + conjg(dyn00(nu_j,nu_i))) 
        dyn00(nu_j,nu_i) = conjg(dyn00(nu_i,nu_j))
     enddo
  enddo
  !      call tra_write_matrix('drho dyn00',dyn00,u,nat)
  !
  !    add the augmentation term to the charge density and save it
  !
  allocate (drhoust( nrxx , nspin , 3))    
  call DSCAL (nhm * (nhm + 1) * 3 * nat * nspin * nat, 0.5d0, dbecsum, 1)
#ifdef __PARA
  !
  !  The calculation of dbecsum is distributed across processors (see addusdbec)
  !  Sum over processors the contributions coming from each slice of bands
  !
  call reduce (nhm * (nhm + 1) * nat * nspin * 3 * nat, dbecsum)
#endif
  mode = 0
  do irr = 1, nirr
     npe = npert (irr)
     if (doublegrid) then
        do is = 1, nspin
           do iper = 1, npe
              call cinterpolate (drhoust(1,is,iper), drhous(1,is,mode+iper), 1)
           enddo
        enddo
     else
        call ZCOPY (nrxx*nspin*npe, drhous(1,1,mode+1), 1, drhoust, 1)
     endif

     call DSCAL (2*nrxx*nspin*npe, 0.5d0, drhoust, 1)

     call addusddens (drhoust, dbecsum(1,1,1,mode+1), irr, mode, npe, 1)
     do iper = 1, npe
        nu_i = mode+iper
        call davcio (drhoust (1, 1, iper), lrdrhous, iudrhous, nu_i, 1)
     enddo
     mode = mode+npe
  enddo

  deallocate (drhoust)
  deallocate (dvlocin)
  deallocate (dbecsum)
  deallocate (drhous)

  call stop_clock ('drho')
  return
end subroutine drho
