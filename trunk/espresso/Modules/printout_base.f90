!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

! This module contains subroutines to print computed quantities to 
! standard output and ASCII file

MODULE printout_base

  IMPLICIT NONE
  SAVE

  CHARACTER(LEN=256) :: fort_unit(30:40)
  ! ...  fort_unit = fortran units for saving physical quantity

  CHARACTER(LEN=256) :: pprefix
  ! ...  prefix combined with the outpur path


CONTAINS


  SUBROUTINE printout_base_setup( outdir, prefix )

     USE io_global, ONLY: ionode, ionode_id
     USE mp_global, ONLY: group
     USE mp, ONLY: mp_bcast

     INTEGER :: iunit, ierr
     CHARACTER(LEN=*), INTENT(IN) :: outdir
     CHARACTER(LEN=*), INTENT(IN) :: prefix
     CHARACTER(LEN=256) :: file_name


     IF( prefix /= ' ' ) THEN
        pprefix = TRIM( prefix )
     ELSE
        pprefix = 'fpmd'
     END IF

     IF( outdir /= ' ' ) THEN
        pprefix = TRIM( outdir ) // '/' // TRIM( pprefix )
     END IF

     ierr = 0

     IF( ionode ) THEN
        fort_unit(30) = trim(pprefix)//'.con'
        fort_unit(31) = trim(pprefix)//'.eig'
        fort_unit(32) = trim(pprefix)//'.pol'
        fort_unit(33) = trim(pprefix)//'.evp'
        fort_unit(34) = trim(pprefix)//'.vel'
        fort_unit(35) = trim(pprefix)//'.pos'
        fort_unit(36) = trim(pprefix)//'.cel'
        fort_unit(37) = trim(pprefix)//'.for'
        fort_unit(38) = trim(pprefix)//'.str'
        fort_unit(39) = trim(pprefix)//'.nos'
        fort_unit(40) = trim(pprefix)//'.the'
        DO iunit = LBOUND( fort_unit, 1 ), UBOUND( fort_unit, 1 )
           OPEN(UNIT=iunit, FILE=fort_unit(iunit), &
               STATUS='unknown', POSITION='append', IOSTAT = ierr )
           CLOSE( iunit )
        END DO
     END IF

     CALL mp_bcast(ierr, ionode_id, group)
     IF( ierr /= 0 ) &
        CALL errore(' printout_base_setup ',' error in opening unit ',iunit)

    RETURN
  END SUBROUTINE printout_base_setup


  SUBROUTINE printout_base_open( )
    INTEGER :: iunit
    ! ...  Open units 30, 31, ... 40 for simulation output
    DO iunit = LBOUND( fort_unit, 1 ), UBOUND( fort_unit, 1 )
       OPEN( UNIT=iunit, FILE=fort_unit(iunit), STATUS='unknown', POSITION='append')
    END DO
    RETURN
  END SUBROUTINE

  SUBROUTINE printout_base_close( )
    INTEGER :: iunit
    LOGICAL :: topen
    ! ...   Close and flush unit 30, ... 40
    DO iunit = LBOUND( fort_unit, 1 ), UBOUND( fort_unit, 1 )
       INQUIRE( UNIT=iunit, OPENED=topen )
       IF (topen) THEN
          CLOSE(iunit)
       END IF
    END DO
    RETURN
  END SUBROUTINE

  
  SUBROUTINE printout_pos( iunit, nfi, tau, nat, simtime, label )
    USE kinds
    INTEGER :: iunit, nfi, nat
    REAL(dbl) :: tau( :, : ), simtime
    CHARACTER(LEN=4), OPTIONAL :: label( : )
    INTEGER :: ia, k
    WRITE( iunit, 30 ) NFI, simtime
    IF( PRESENT( label ) ) THEN
       DO ia = 1, nat
         WRITE( iunit, 255 ) label(ia), (tau(k,ia),k = 1,3)
       END DO
    ELSE
       DO ia = 1, nat
         WRITE( iunit, 252 ) (tau(k,ia),k = 1,3)
       END DO
    END IF
 30 FORMAT(3X,'STEP:',I7,1X,F10.6)
255 FORMAT(3X,A3,3E14.6)
252 FORMAT(3E14.6)
    RETURN
  END SUBROUTINE
 

  SUBROUTINE printout_cell( iunit, nfi, h, simtime )
    USE kinds
    INTEGER :: iunit, nfi
    REAL(dbl) :: h(3,3), simtime
    INTEGER :: i, j
    WRITE( iunit, 30 ) nfi, simtime
    DO i = 1, 3
       WRITE( iunit, 1000 ) (h(i,j),j=1,3)
    END DO
 30 FORMAT(3X,'STEP:',I7,1X,F10.6)
 1000    format(3F14.8)
    RETURN
  END SUBROUTINE


  SUBROUTINE printout_stress( iunit, nfi, str, simtime )
    USE kinds
    INTEGER :: iunit, nfi
    REAL(dbl) :: str(3,3), simtime
    INTEGER :: i, j
    WRITE( iunit, 30 ) nfi, simtime
    DO i = 1, 3
       WRITE( iunit, 1000 ) (str(i,j),j=1,3)
    END DO
 30 FORMAT(3X,'STEP:',I7,1X,F10.6)
 1000    format(3(F18.8,1X))
    RETURN
  END SUBROUTINE



END MODULE
