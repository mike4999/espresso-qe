!
! Copyright (C) 2001-2013 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!


MODULE start_end
!this module contains routines to initialize the MPI environment

#ifdef __OPENMP
  INTEGER, SAVE :: ntids
#endif

CONTAINS

  SUBROUTINE startup

  !
  USE io_global,  ONLY : stdout, ionode
  USE mp_world,   ONLY : nproc
  USE mp_global,  ONLY : mp_startup

  IMPLICIT NONE

#ifdef __PARA

  CALL mp_startup()

  if(ionode) then
     write(stdout,*) 'MPI PARALLEL VERSION'
     write(stdout,*) 'Number of procs: ', nproc
  endif

#endif
  return

  END SUBROUTINE startup

  SUBROUTINE stop_run
!this subroutine kills the MPI environment

    USE io_global,         ONLY : stdout, ionode
    USE mp_global          ONLY : mp_global_end

    IMPLICIT NONE

#ifdef __PARA

    if(ionode) write(stdout,*) 'Stopping MPI environment'
    call mp_global_end( )
#endif

    return
  END SUBROUTINE stop_run


END MODULE start_end
