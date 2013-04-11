!
! Copyright (C) 2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
SUBROUTINE save_in_electrons (iter, dr2, et)
  !-----------------------------------------------------------------------
  USE kinds,         ONLY: dp
  USE io_files,      ONLY: iunres, seqopn
  USE klist,         ONLY: nks
  USE wvfct,         ONLY: nbnd
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT (in) :: iter
  REAL(dp), INTENT(in) :: dr2, et(nbnd,nks)
  !
  LOGICAL :: exst
  !
  CALL seqopn (iunres, 'restart_scf', 'formatted', exst)
  WRITE (iunres, *) iter, dr2
  WRITE (iunres, *) et(1:nbnd,1:nks)
!  write (iunres)  exx_is_active(), fock0, fock1, fock2, dexx
!  IF ( exx_is_active() )  write (iunres) &
!     ( (x_occupation (ibnd, ik), ibnd = 1, nbnd), ik = 1, nks)
  CLOSE ( unit=iunres, status='keep')
  !
END SUBROUTINE save_in_electrons
!
!-----------------------------------------------------------------------
SUBROUTINE restart_in_electrons (iter, dr2, et)
  !-----------------------------------------------------------------------
  USE kinds,         ONLY: dp
  USE io_global,     ONLY: stdout
  USE io_files,      ONLY: iunres, seqopn
  USE klist,         ONLY: nks
  USE wvfct,         ONLY: nbnd
  !
  IMPLICIT NONE
  !
  INTEGER, INTENT (out) :: iter
  REAL(dp), INTENT(out) :: dr2, et(nbnd,nks)
  !
  REAL(dp), ALLOCATABLE :: et_(:,:)
  REAL(dp):: dr2_
  INTEGER :: ios
  LOGICAL :: exst
  !
  CALL seqopn (iunres, 'restart_scf', 'formatted', exst)
  IF ( exst ) THEN
     ios = 0
     READ (iunres, *, iostat=ios) iter, dr2_
     IF ( ios /= 0 ) THEN
        iter = 0
     ELSE IF ( iter < 1 ) THEN
        iter = 0
     ELSE
        ALLOCATE (et_(nbnd,nks))
        READ (iunres, *, iostat=ios) et_
        IF ( ios /= 0 ) THEN
           iter = 0
        ELSE
           WRITE( stdout, &
           '(5x,"Calculation restarted from scf iteration #",i6)' ) iter + 1
           dr2 = dr2_
           et (:,:) = et_(:,:)
        END IF
        DEALLOCATE (et_)
     END IF
  ELSE
     iter = 0
  END IF
  CLOSE ( unit=iunres, status='delete')
  !
END SUBROUTINE restart_in_electrons
