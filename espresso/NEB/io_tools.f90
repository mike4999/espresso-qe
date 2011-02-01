
! Copyright (C) 2010 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE input_file_name_getarg(myname,lfound)
  !-----------------------------------------------------------------------------
  !
  ! check for presence of command-line option "-inp myname" or "--inp myname"
  ! where "myname" is the name of the input file. Returns the name and if it 
  ! has been found. 
  !
  USE kinds,         ONLY : DP
  !
  USE io_global,     ONLY : stdout
  !
  IMPLICIT NONE
  !
  CHARACTER(len=256), intent(out) :: myname
  LOGICAL, intent(out) :: lfound
  !
  INTEGER  :: iiarg, nargs, iargc, i, i0
  !
  !
#if defined(__ABSOFT)
#   define getarg getarg_
#   define iargc  iargc_
#endif
  !
  nargs = iargc()
  lfound = .false.
  !
  DO iiarg = 1, nargs
    CALL getarg( iiarg, myname)
     !
     IF ( TRIM( myname ) == '-input' .OR. &
          TRIM( myname ) == '-inp'   .OR. &
          TRIM( myname ) == '-in' ) THEN
        !
        CALL getarg( ( iiarg + 1 ) , myname )
        !
        lfound = .true.
        RETURN
        !
     END IF
     !

  ENDDO
  !
  RETURN
  !
END SUBROUTINE input_file_name_getarg
!
SUBROUTINE input_images_getarg(input_images,lfound)
  !-----------------------------------------------------------------------------
  !
  ! check for presence of command-line option "-inp myname" or "--inp myname"
  ! where "myname" is the name of the input file. Returns the name and if it 
  ! has been found. 
  !
  USE kinds,         ONLY : DP
  !
  USE io_global,     ONLY : stdout
  !
  IMPLICIT NONE
  !
  INTEGER, intent(out) :: input_images
  LOGICAL, intent(out) :: lfound
  !
  CHARACTER(len=256) ::  myname
  INTEGER  :: iiarg, nargs, iargc, i, i0
  !
  !
#if defined(__ABSOFT)
#   define getarg getarg_
#   define iargc  iargc_
#endif
  !
  nargs = iargc()
  lfound = .false.
  input_images = 0
  !
  DO iiarg = 1, nargs
    CALL getarg( iiarg, myname)
     !
     IF ( TRIM( myname ) == '-input_images' .OR. &
          TRIM( myname ) == '--input_images' ) THEN
        !
        CALL getarg( ( iiarg + 1 ) , myname )
        !
        READ(myname,*) input_images
        !
        lfound = .true.
        RETURN
        !
     END IF
     !

  ENDDO
  !
  RETURN
  !
END SUBROUTINE input_images_getarg

!----------------------------------------------------------------------------
SUBROUTINE close_io_units(myunit)
  !-----------------------------------------------------------------------------
  !
  IMPLICIT NONE
  !
  INTEGER, intent(in) :: myunit
  !
  LOGICAL :: opnd
  !
  INQUIRE( UNIT = myunit, OPENED = opnd )
  IF ( opnd ) CLOSE( UNIT = myunit )
  !
END SUBROUTINE close_io_units
!
!----------------------------------------------------------------------------
SUBROUTINE open_io_units(myunit,file_name,lappend)
  !-----------------------------------------------------------------------------
  !
  IMPLICIT NONE
  !
  INTEGER, intent(in) :: myunit
  CHARACTER(LEN=256), intent(in) :: file_name
  LOGICAL, intent(in) :: lappend
  !
  LOGICAL :: opnd
  !
  INQUIRE( UNIT = myunit, OPENED = opnd )
  IF ( opnd ) CLOSE( UNIT = myunit )
  OPEN( UNIT = myunit, FILE = TRIM(file_name), &
  STATUS = 'UNKNOWN', POSITION = 'APPEND' )
  !
END SUBROUTINE open_io_units
