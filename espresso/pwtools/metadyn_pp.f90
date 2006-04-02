!
! Copyright (C) 2005-2006 Carlo Sbraccia
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
PROGRAM metadyn_PP
  !----------------------------------------------------------------------------
  !
  ! ... This program can be used to post-process a meta-dynamics run to
  ! ... obtain the free-energy landscape. If more than two collective 
  ! ... coordinates have been used the program plots the projection on a 
  ! ... specified plane.
  !
  ! ... The input is in the form of a namelist (&INPUT). The output consists
  ! ... in a file prefix.dat containing the reconstructed free-energy and
  ! ... (if the PGPLOT libraries are available) a file prefix.ps containing
  ! ... a plot of the iso-energy profiles.
  !
  ! ... Input keywords :
  !
  ! ...   filename        CHARACTER ( default = '' )
  ! ...                   the file containing the output of a meta-dynamics
  ! ...                   run ( the ***.metadyn file ).
  !
  ! ...   prefix          CHARACTER ( default = 'metadyn_pp' )
  ! ...                   prefix used for the output files.
  !
  ! ...   ix              INTEGER ( default = 1 )
  ! ...   iy              INTEGER ( default = 1 )
  ! ...                   First and second index of the collective coordinates
  ! ...                   that have to be used to reconstruct the free-energy.
  !                       
  ! ...   lsym            LOGICAL ( default = .FALSE. )
  ! ...                   If true the free-energy is assumed to have 
  !
  ! ...   lrun_dynamics   LOGICAL ( default = .FALSE. )
  ! ...                   If true, the meta-dynamics trajectory is shown in
  ! ...                   the prefix.ps file.
  !
  ! ... This program works at best when the PGPLOT libraries are available
  ! ... (see www.astro.caltech.edu/~tjp/pgplot/).
  ! ... To use them add in the make.sys file the preprocessor flag __PGPLOT 
  ! ... to DFLAGS and add :
  ! ...   -lm -lc -L/.../pgplot.d -lpgplot -L/usr/X11R6/lib -lX11 
  ! ... to LIBS
  !
  ! ... Written by Carlo Sbraccia (sbraccia@princeton.edu)
  !
  IMPLICIT NONE
  !
  INTEGER, PARAMETER :: SP = KIND( 1.0 )
  !
  INTEGER,       PARAMETER :: grid_points = 100
  INTEGER,       PARAMETER :: num_lev = 20
  REAL(KIND=SP)            :: E_min = -0.20, & 
                              E_max =  0.00
  REAL(KIND=SP)            :: x_min =  1.00, &
                              x_max = 16.00, &
                              y_min =  1.00, &
                              y_max = 16.00
  !
  REAL(KIND=SP) :: delta_x, delta_y, r_min(2)
  REAL(KIND=SP) :: delta_E
  REAL(KIND=SP) :: tr_array(6)
  REAL(KIND=SP) :: level(num_lev)
  REAL(KIND=SP) :: surf(grid_points,grid_points)
  !
  CHARACTER(LEN=256)            :: filename, prefix
  INTEGER                       :: ix, iy
  LOGICAL                       :: lsym, loptimise, lrun_dynamics
  INTEGER                       :: nconstr, nstep
  REAL(KIND=SP)                 :: A, sigma(2)
  REAL(KIND=SP),    ALLOCATABLE :: sigma_tmp(:)
  REAL(KIND=SP),    ALLOCATABLE :: s(:,:), s_tmp(:,:), sg(:,:), sg_tmp(:,:)
  REAL(KIND=SP),    ALLOCATABLE :: pes(:), fe_grad(:,:)
  CHARACTER(LEN=5), ALLOCATABLE :: label(:)
  !
  INTEGER       :: i, j, idum, counter
  REAL(KIND=SP) :: x, y
  !
  NAMELIST / INPUT / filename, prefix, ix, iy, lsym, lrun_dynamics
  !
  INTEGER, EXTERNAL :: PGOPEN
  !
  ! ... the code starts here
  !
  filename      = ''
  prefix        = 'metadyn_pp'
  ix            = 1
  iy            = 2
  lsym          = .FALSE.
  lrun_dynamics = .FALSE.
  !
  READ( *, NML = INPUT )
  !
  OPEN( UNIT = 10, FILE = filename, STATUS = "OLD" )
  !
  READ( 10, * ) nconstr, nstep
  READ( 10, * ) A
  !
  ALLOCATE( sigma_tmp( nconstr ) )
  !
  READ( 10, * ) sigma_tmp(:)
  !
  ALLOCATE( s(             2, nstep ) )
  ALLOCATE( s_tmp(   nconstr, nstep ) )
  ALLOCATE( sg(            2, nstep ) )
  ALLOCATE( sg_tmp(  nconstr, nstep ) )
  ALLOCATE( pes(              nstep ) )
  ALLOCATE( fe_grad( nconstr, nstep ) )
  ALLOCATE( label(            nstep ) )
  !
  counter = 0
  !
  DO i = 1, nstep
     !
     READ( 10, *, END = 9 ) &
        label(i), s_tmp(:,i), pes(i), sg_tmp(:,i), fe_grad(:,i)
     !
     counter = counter + 1
     !
  END DO
  !
9 nstep = counter
  !
  WRITE( *, '(/,"number of steps = ",I5,/)' ) nstep
  !
  CLOSE( UNIT = 10 )
  !
  sigma(1) = sigma_tmp(ix)
  sigma(2) = sigma_tmp(iy)
  !
  s(1,:)  = s_tmp(ix,:)
  s(2,:)  = s_tmp(iy,:)
  sg(1,:) = sg_tmp(ix,:)
  sg(2,:) = sg_tmp(iy,:)
  !
  DEALLOCATE( sigma_tmp )
  DEALLOCATE( s_tmp )
  DEALLOCATE( sg_tmp )
  !
  x_min = MIN( MINVAL(  s(1,:nstep) ), &
               MINVAL( sg(1,:nstep) ) ) - 4.D0 * sigma(1) / 2.0
  y_min = MIN( MINVAL(  s(2,:nstep) ), &
               MINVAL( sg(2,:nstep) ) ) - 4.D0 * sigma(2) / 2.0
  x_max = MAX( MAXVAL(  s(1,:nstep) ), &
               MAXVAL( sg(1,:nstep) ) ) + 4.D0 * sigma(1) / 2.0
  y_max = MAX( MAXVAL(  s(2,:nstep) ), &
               MAXVAL( sg(2,:nstep) ) ) + 4.D0 * sigma(2) / 2.0
  !
  IF ( lsym ) THEN
     !
     x_min = MIN( x_min, y_min ); y_min = x_min
     x_max = MAX( x_max, y_max ); y_max = x_max
     !
  END IF
  !
  ! ... the surface is generated here
  !
  delta_x = ( x_max - x_min ) / REAL( grid_points - 1 )
  delta_y = ( y_max - y_min ) / REAL( grid_points - 1 )
  !
  surf(:,:) = 0.D0
  !
  DO i = 1, grid_points
     !
     x = x_min + REAL( i - 1 ) * delta_x 
     !
     DO j = 1, grid_points
        !
        y = y_min + REAL( j - 1 ) * delta_y
        !
        surf(i,j) = sum_gaussians( x, y ) 
        !
     END DO
     !
  END DO
  !
  E_min = MINVAL( surf )
  E_max = MAXVAL( surf )
  !
  delta_E = ( E_max - E_min ) / REAL( num_lev )
  !
  WRITE( *, '("MINIMUM VALUE = ",F12.7," eV"  )' ) E_min * 13.605826
  WRITE( *, '("MAXIMUM VALUE = ",F12.7," eV",/)' ) E_max * 13.605826
  WRITE( *, '("ISO-ENERGY SPACING= ",F12.7," eV"/)' ) delta_E * 13.605826
  !
  r_min(:) = MINLOC( surf(:,:) )
  !
  r_min(1) = x_min + ( r_min(1) - 1 ) * delta_x
  r_min(2) = y_min + ( r_min(2) - 1 ) * delta_y
  !
  WRITE( *, '("MINIMUM (X,Y) :  ",2F12.7)' ) r_min(1), r_min(2)
  !
  tr_array(1) = x_min - delta_x
  tr_array(2) = delta_x
  tr_array(3) = 0.0
  tr_array(4) = y_min - delta_y
  tr_array(5) = 0.0
  tr_array(6) = delta_y
  !
  DO i = 1, num_lev
     !
     level(i) = E_min + REAL( i - 1 ) * delta_E
     !
  END DO
  !
#if defined (__PGPLOT)
  !
  IF ( PGOPEN( '/XSERVE' ) <= 0 ) STOP
  !
  CALL PGSLS( 1 )
  CALL PGSLW( 1 )
  CALL PGSCI( 1 )
  !
  CALL PGENV( x_min, x_max, y_min, y_max, 1, 0 )
  !
  CALL PGLAB( 'x (bohr)', 'y (bohr)', 'Potential Energy Surface' )
  !
  CALL PGIDEN()
  !
  CALL PGCONS( surf, grid_points, grid_points, 1, &
               grid_points, 1, grid_points, level, num_lev, tr_array )
  !
  CALL PGSCI( 4 )
  CALL PGSLW( 15 )
  CALL PGPT1( r_min(1), r_min(2), -1 )
  !
  IF ( lrun_dynamics ) THEN
     !
     CALL PGSCI( 6 )
     CALL PGSLW( 15 )
     CALL PGPT1( s(1,1), s(2,1), -1 )
     !
     CALL PGSCI( 2 )
     !
     DO i = 2, nstep
        !
        CALL PGSLW( 8 )
        CALL PGPT1( s(1,i), s(2,i), -1 )
        CALL PGSLW( 1 )
        CALL PGLINE( 2, s(1,i-1:i), s(2,i-1:i) )
        !
        CALL delay( 100000 )
        !
     END DO
     !
  END IF
  !
  CALL PGCLOS()
  !
  IF ( PGOPEN( TRIM( prefix ) // '.ps/CPS' ) <= 0 ) STOP
  !
  CALL PGSLS( 1 )
  CALL PGSLW( 1 )
  CALL PGSCI( 1 )     
  !
  CALL PGENV( x_min, x_max, y_min, y_max, 1, 0 )
  !
  CALL PGLAB( 'x (bohr)', 'y (bohr)', 'Potential Energy Surface' )
  !
  CALL PGIDEN()
  !
  CALL PGCONS( surf, grid_points, grid_points, 1, &
               grid_points, 1, grid_points, level, num_lev, tr_array )
  !
  CALL PGSCI( 4 )
  CALL PGSLW( 15 )
  CALL PGPT1( r_min(1), r_min(2), -1 )
  !
  IF ( lrun_dynamics ) THEN
     !
     CALL PGSCI( 6 )
     CALL PGSLW( 15 )
     CALL PGPT1( s(1,1), s(2,1), -1 )
     !
     CALL PGSCI( 2 )
     CALL PGSLW( 8 )
     !
     DO i = 2, nstep
        !
        CALL PGSLW( 8 )
        CALL PGPT1( s(1,i), s(2,i), -1 )
        CALL PGSLW( 1 )
        CALL PGLINE( 2, s(1,i-1:i), s(2,i-1:i) )
        !
     END DO
     !
  END IF
  !
  CALL PGCLOS()
  !
#endif
  !
  OPEN( UNIT = 99, FILE = TRIM( prefix ) // '.dat' )
  !
  DO i = 1, grid_points
     !
     x = x_min + REAL( i - 1 ) * delta_x 
     !
     DO j = 1, grid_points
        !
        y = y_min + REAL( j - 1 ) * delta_y
        !
        WRITE( 99, '(3(2X,F16.10))' ) x, y, surf(i,j)
        !
     END DO
     !
  END DO
  !
  CLOSE( UNIT = 99 )
  !
  DEALLOCATE( s )
  DEALLOCATE( sg )
  DEALLOCATE( pes )
  DEALLOCATE( fe_grad )
  DEALLOCATE( label )
  !
  STOP
  !
  CONTAINS
    !
    !------------------------------------------------------------------------
    FUNCTION sum_gaussians( x, y )
      !------------------------------------------------------------------------
      !
      REAL(KIND=SP), INTENT(IN) :: x, y
      REAL(KIND=SP)             :: sum_gaussians
      !
      INTEGER       :: i
      REAL(KIND=SP) :: exponent
      !
      !
      sum_gaussians = 0.0
      !
      DO i = 1, nstep
         !
         exponent = ( x - sg(1,i) )**2 / ( 2.0 * sigma(1)**2 ) + &
                    ( y - sg(2,i) )**2 / ( 2.0 * sigma(2)**2 )
         !
         sum_gaussians = sum_gaussians - A * EXP( - exponent )
         !
      END DO
      !
      IF ( lsym ) THEN
         !
         DO i = 1, nstep
            !
            exponent = ( x - sg(2,i) )**2 / ( 2.0 * sigma(2)**2 ) + &
                       ( y - sg(1,i) )**2 / ( 2.0 * sigma(1)**2 )
            !
            sum_gaussians = sum_gaussians - A * EXP( - exponent )
            !
         END DO         
         !
      END IF
      !
      RETURN
      !
    END FUNCTION sum_gaussians
    !
    !------------------------------------------------------------------------
    SUBROUTINE delay( iterations )
      !------------------------------------------------------------------------
      !
      IMPLICIT NONE
      !
      INTEGER, INTENT(IN) :: iterations
      !
      INTEGER       :: i
      REAL(KIND=SP) :: xdum
      !
      !
      DO i = 1, iterations
         !
         xdum = SIN( DBLE( i ) )
         !
      END DO
      !
      RETURN
      !
    END SUBROUTINE delay
    !
END PROGRAM metadyn_PP
