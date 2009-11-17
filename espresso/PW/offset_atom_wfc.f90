!
! Copyright (C) 2001-2008 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE offset_atom_wfc( nat, offset )
  !----------------------------------------------------------------------------
  !
  ! For each Hubbard atom, compute the index of the projector in the
  ! list of atomic wavefunctions
  !
  USE uspp_param,       ONLY : upf
  USE noncollin_module, ONLY : noncolin
  USE ions_base,        ONLY : ityp
  USE basis,            ONLY : natomwfc
  USE ldaU,             ONLY : Hubbard_l
  IMPLICIT NONE
  !
  INTEGER, INTENT(IN)  :: nat
  !
  INTEGER, INTENT(OUT) :: offset(nat)
  !
  INTEGER  :: counter, na, nt, n
  !
  !
  counter = 0
  offset(:) = -99
  !
  !
  DO na = 1, nat
     !
     nt = ityp(na)
     !
     DO n = 1, upf(nt)%nwfc
        !
        IF ( upf(nt)%oc(n) >= 0.D0 ) THEN
           !
           IF ( noncolin ) THEN
              ! N.B.: presently LDA+U not yet implemented for noncolin
              !
              IF ( upf(nt)%has_so ) THEN
                 !
                 counter = counter + 2 * upf(nt)%lchi(n)
                 !
                 IF ( ABS( upf(nt)%jchi(n)-upf(nt)%lchi(n) - 0.5D0 ) < 1.D-6 ) &
                    counter = counter + 2
                 !
              ELSE
                 !
                 counter = counter + 2 * ( 2 * upf(nt)%lchi(n) + 1 )
                 !
              END IF
              !
           ELSE
              !
              IF ( upf(nt)%lchi(n) == Hubbard_l(nt) )  offset(na) = counter
              !
              counter = counter + 2 * upf(nt)%lchi(n) + 1
              !
           END IF
        END IF
     END DO
  END DO
  !
  IF ( counter.NE.natomwfc ) &
     CALL errore ('offset_atom_wfc', 'wrong number of wavefunctions', 1)
  !
  RETURN
  !
END SUBROUTINE offset_atom_wfc
!
