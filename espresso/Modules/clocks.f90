!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
MODULE mytime
  !
  USE parameters, ONLY : DP
  !
  IMPLICIT NONE
  !
  INTEGER, PARAMETER                      :: maxclock = 100
  REAL (KIND=DP), PARAMETER               :: notrunning = - 1.D0 
  REAL (KIND=DP), DIMENSION(maxclock)     :: myclock, t0
  CHARACTER (LEN=12), DIMENSION(maxclock) :: clock_label
  INTEGER, DIMENSION(maxclock)            :: called 
  INTEGER                                 :: nclock
  LOGICAL                                 :: no
  !
END MODULE mytime
!
!
SUBROUTINE init_clocks( go )
  !
  ! flag = .TRUE.  : clocks will run
  ! flag = .FALSE. : only clock #1 will run
  !
  USE parameters, ONLY : DP
  USE mytime
  !
  IMPLICIT NONE
  !
  REAL (KIND=DP) :: scnds
  LOGICAL        :: go
  INTEGER        :: n
  !
  !
  no = .NOT. go
  DO n = 1, maxclock
     called(n) = 0
     myclock(n) = 0.D0
     t0(n) = notrunning
  END DO
  !
  RETURN
  !
END SUBROUTINE init_clocks
!
!
SUBROUTINE start_clock( label )
  !
  USE parameters, ONLY : DP
  USE mytime
  !
  IMPLICIT NONE
  !
  REAL (KIND=DP)    :: scnds
  CHARACTER (LEN=*) :: label
  INTEGER           :: n
  !
  !
  IF ( no .AND. ( nclock == 1 ) ) RETURN
  DO n = 1, nclock
     IF ( label == clock_label(n) ) THEN
        !
        ! found previously defined clock: check if not already started,
        ! store in t0 the starting time
        !
        IF ( t0(n) /= notrunning ) THEN
           WRITE(6, '("start_clock: clock # ",I2," for ",A12, &
                    & " already started")') n, label
        ELSE
           t0(n) = scnds()
        END IF
        !
        RETURN
        !
     END IF
  END DO
  !
  ! clock not found : add new clock for given label
  !
  IF ( nclock == maxclock ) THEN
     WRITE(6, '("start_clock: Too many clocks! call ignored")')
  ELSE
     nclock              = nclock + 1
     clock_label(nclock) = label
     t0(nclock)          = scnds ()
  END IF
  !
  RETURN
  !
END SUBROUTINE start_clock
!
!
SUBROUTINE stop_clock( label )
  !
  USE parameters, ONLY : DP
  USE mytime
  !
  IMPLICIT NONE
  !
  REAL (KIND=DP)    :: scnds
  CHARACTER (LEN=*) :: label
  INTEGER           :: n
  !
  !
  IF ( no ) RETURN
  DO n = 1, nclock
     IF ( label == clock_label(n) ) THEN
        !
        ! found previously defined clock : check if properly initialised,
        ! add elapsed time, increase the counter of calls
        !
        IF ( t0(n) == notrunning ) THEN
           WRITE(6, '("stop_clock: clock # ",I2," for ",A12, &
                    & " not running")') n, label
        ELSE
           myclock(n) = myclock(n) + scnds() - t0(n)
           t0(n)      = notrunning
           called(n)  = called(n) + 1
        END IF
        RETURN
     END IF
  END DO
  !
  ! clock not found
  !
  WRITE(6, '("stop_clock: no clock for ",A12," found !")') label
  !
  RETURN
  !
END SUBROUTINE stop_clock
!
!
SUBROUTINE print_clock( label )
  !
  USE parameters, ONLY : DP  
  use mytime
  !
  IMPLICIT NONE
  !
  REAL (KIND=DP)    :: scnds
  CHARACTER (LEN=*) :: label
  INTEGER           :: n
  !
  !
  IF ( label == ' ' ) THEN
     WRITE(6, * )
     DO n = 1, nclock
        CALL print_this_clock( n )
     END DO
  ELSE
     DO n = 1, nclock
        IF ( label == clock_label(n) ) THEN
           CALL print_this_clock( n )
           RETURN
        END IF
     END DO
     !
     ! clock not found
     !         IF ( .NOT.no ) WRITE(6,'("print_clock: no clock for ",
     !                                   A12," found !")') label
  END IF
  !
  RETURN
  !
END SUBROUTINE print_clock
!
!
SUBROUTINE print_this_clock( n )
  !
  USE parameters, ONLY : DP
  USE mytime
  USE mp,         ONLY : mp_max, mp_min
  USE mp_global,  ONLY : group, inter_pool_comm 
  !
  IMPLICIT NONE
  !
  REAL(KIND=DP) :: scnds
  INTEGER       :: n
  REAL(KIND=DP) :: elapsed_cpu_time, nsec
  INTEGER       :: nhour, nmin
  !
  !
  IF ( t0(n) == notrunning ) THEN
     !
     ! ... clock stopped, print the stored value for the cpu time
     !
     elapsed_cpu_time = myclock(n)
  ELSE
     !
     ! ... clock not stopped, print the current value of the cpu time
     !
     elapsed_cpu_time = myclock(n) + scnds() - t0(n)
  END If
#ifdef __PARA
  !
  ! In the parallel case it is far from clear which value to print
  ! The following is the maximum over all nodes and pools. NOTA BENE:
  ! some trouble could arise if a clock is not started on all nodes
  !
  ! by uncommenting the following line the extreme operation is removed
  ! may be useful for testing purpouses
  ! /* #define DEBUG */
  !
#ifndef DEBUG
  CALL mp_max( elapsed_cpu_time, group )
  CALL mp_max( elapsed_cpu_time, inter_pool_comm )
#endif
#endif
  IF ( n == 1 ) THEN
     ! ... The first clock is written as hour/min/sec
     nhour = elapsed_cpu_time / 3600
     nmin  = ( elapsed_cpu_time - 3600 * nhour ) / 60
     nsec  = ( elapsed_cpu_time - 3600 * nhour ) - 60 * nmin
     !
     IF ( nhour > 0 ) THEN
        WRITE(6, '(5X,A12," : ",3X,I2,"h",I2,"m CPU time"/)') &
             clock_label(n), nhour, nmin
     ELSE IF ( nmin > 0 ) THEN
        WRITE(6, '(5X,A12," : ",I2,"m",F5.2,"s CPU time"/)') &
             clock_label(n), nmin, nsec
     ELSE
        WRITE(6, '(5X,A12," : ",3X,F5.2,"s CPU time"/)') &
             clock_label(n), nsec
     END IF
  ELSE IF ( called(n) == 1 .OR. t0(n) /= notrunning ) THEN
     ! For clocks that have been called only once
     WRITE(6, '(5X,A12," :",F9.2,"s CPU")') &
          clock_label(n), elapsed_cpu_time
  ELSE IF ( called(n) == 0 ) THEN
     ! For clocks that have never been called
     WRITE(6, '("print_this: clock # ",I2," for ",A12, &
              & " never called !")') n, clock_label(n)
  ELSE
     ! For all other clocks
     WRITE(6, '(5X,A12," :",F9.2,"s CPU (", &
              & I8," calls,",F8.3," s avg)")') clock_label(n), &
          elapsed_cpu_time, called(n) , ( elapsed_cpu_time / called(n) )
  END IF
  !
  RETURN
  !
END SUBROUTINE print_this_clock
!
!
FUNCTION get_clock( label )
  !
  USE parameters, ONLY : DP
  USE mytime
  USE mp,         ONLY : mp_max, mp_min
  USE mp_global,  ONLY : group, inter_pool_comm 
  !
  IMPLICIT NONE
  !
  REAL(KIND=DP)     :: get_clock
  REAL(KIND=DP)     :: scnds
  CHARACTER (LEN=*) :: label
  INTEGER           :: n
  !
  !
  IF ( no ) THEN
     IF ( label == clock_label(1) ) THEN
        get_clock = scnds()
     ELSE
        get_clock = notrunning
     END IF
     RETURN
  END IF
  DO n = 1, nclock
     IF ( label == clock_label(n) ) THEN
        IF ( t0(n) == notrunning ) THEN
           get_clock = myclock(n)
        ELSE
           get_clock = myclock(n) + scnds() - t0(n)
        END IF
#ifdef __PARA
        !
        ! ... In the parallel case, use the maximum over all nodes and pools
        !
        CALL mp_max( get_clock, group )
        CALL mp_max( get_clock, inter_pool_comm )
#endif
        RETURN
     END IF
  END DO
  !
  ! ... clock not found
  !
  get_clock = notrunning
  !
  WRITE(6, '("get_clock: no clock for ",A12," found !")') label
  !
  RETURN
  !
END FUNCTION get_clock

