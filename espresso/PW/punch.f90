!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------
subroutine punch  
  !-----------------------------------------------------------------------
  !
  !     This routine is called at the end of the run to save on a file
  !     the informations needed to the phonon program.
  !
  !
  use pwcom, only: nks, filpun, reduce_io, evc, nwordwfc, iunwfc, lscf, &
    rho, nspin, iunpun, et, wg, nbnd, nkstot, nbndx, tau, ityp, irt, xk,&
    wk, isk, lforce, force, ltetra, tetra
  use io, only: prefix
#ifdef PARA
  use para
#endif
  use restart_module, only: writefile_new
  !
  implicit none
  !
  integer :: ik, i, ibnd, kunittmp  
  logical :: exst
  logical :: new_punch = .true.  
  !
  if (new_punch) then
     filpun = trim(prefix)//'.save'
  else
     filpun = trim(prefix)//'.pun'
  end if
  !
  kunittmp = 1
  !
  ! if the wavefunction has not been written on file, do it now
  !
  if (nks.eq.1.and.reduce_io) call davcio (evc, nwordwfc, iunwfc, 1, + 1)
  !
  ! The following instruction is used  when more k-points are needed
  ! for finite-q phonon calculations (on fine q-grid) then those needed
  ! for self-consistency. In such a case, a self-consistent calculation
  ! with few k-points is followed by a non-self-consistent one with added
  ! k-points, whose weight is set to zero.
  !
  if (.not.lscf) call sum_band  
  !
  !  Write: general variables (including dimensions of the arrays),
  !  atomic positions, forces, k-points, eigenvalues
  !
#ifdef PARA
  !
  ! xk, wk, isk, et, wg are distributed across pools
  ! the first node has a complete copy of xk, wk, isk,
  ! while eigenvalues et and weights wg must be
  ! explicitely collected to the first node
  !
  call poolrecover (et, nbndx, nkstot, nks)
  call poolrecover (wg, nbnd , nkstot, nks)
  !
  kunittmp = kunit
  !
#endif
  !
  !  Write the charge density on a separate file
  !
  call io_pot ( + 1, trim(prefix)//'.rho', rho, nspin)  
  
  iunpun = 4  
  if (new_punch) then
     !
     ! write one single file with all wavefunctions
     !
     call writefile_new( 'all', iunpun, et, wg, kunittmp )
     !
  else
     !
     ! write old-fashioned file, leave wavefunctions where they are
     !
#ifdef PARA
     ! In parallel execution, only the first node writes this file
     if (me.eq.1.and.mypool.eq.1) then
#endif
     call seqopn (iunpun, filpun, 'unformatted', exst)  
     !
     call saveall (iunpun, 1)  
     write (iunpun) tau  
     write (iunpun) ityp  
     write (iunpun) irt  
     if (lforce) write (iunpun) force  
     if (ltetra) write (iunpun) tetra  
     write (iunpun) ( (xk (i, ik), i = 1, 3), ik = 1, nkstot)  
     write (iunpun) (  wk (ik), ik = 1, nkstot)  
     write (iunpun) ( isk (ik), ik = 1, nkstot)
#ifdef PARA
     write (iunpun) kunit
#endif
     write (iunpun) ( (et (ibnd, ik), ibnd = 1, nbnd), ik = 1, nkstot)  
     write (iunpun) ( (wg (ibnd, ik), ibnd = 1, nbnd), ik = 1, nkstot)
     close (unit = iunpun)  
#ifdef PARA
     end if
#endif
     !
     call writefile_new( 'config', iunpun, et, wg, kunittmp )
     !
  end if

  return  
end subroutine punch
