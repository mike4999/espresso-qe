!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

MODULE fft_types

  IMPLICIT NONE
  SAVE

  TYPE fft_dlay_descriptor
    INTEGER :: nst      ! total number of sticks
    INTEGER, POINTER :: nsp(:)   ! number of sticks per processor ( potential )
    INTEGER, POINTER :: nsw(:)   ! number of sticks per processor ( wave func )
    INTEGER :: nr1      !
    INTEGER :: nr2      ! effective FFT dimensions
    INTEGER :: nr3      ! 
    INTEGER :: nr1x     ! 
    INTEGER :: nr2x     ! FFT grids leading dimensions
    INTEGER :: nr3x     ! 
    INTEGER :: npl      ! number of "Z" planes for this processor = npp( mpime + 1 )
    INTEGER :: nnp      ! number of 0 and non 0 sticks in a plane ( ~nr1*nr2/nproc )
    INTEGER :: nnr      ! local number of FFT grid elements  ( ~nr1*nr2*nr3/proc )
    INTEGER :: ngt      ! total number of non zero elemets (number of G-vec)
    INTEGER, POINTER :: ngl(:)   ! per processor number of non zero elemets 
    INTEGER, POINTER :: npp(:)   ! number of "Z" planes per processor
    INTEGER, POINTER :: ipp(:)   ! index of the first "Z" plane on each proc
    INTEGER, POINTER :: iss(:)   ! index of the first stick on each proc
    INTEGER, POINTER :: isind(:) ! for each position in the plane indicate the stick index
    INTEGER, POINTER :: ismap(:) ! for each stick in the plane indicate the position
    INTEGER, POINTER :: iplp(:)   ! indicate which "Y" plane should be FFTed ( potential )
    INTEGER, POINTER :: iplw(:)   ! indicate which "Y" plane should be FFTed ( wave func )
    INTEGER :: id
    INTEGER :: tptr
  END TYPE

  INTEGER, PRIVATE :: icount = 0


CONTAINS

  SUBROUTINE fft_dlay_allocate( desc, nproc, nx, ny )
    TYPE (fft_dlay_descriptor) :: desc
    INTEGER, INTENT(IN) :: nproc, nx, ny
    ALLOCATE( desc%nsp( nproc ) )
    ALLOCATE( desc%nsw( nproc ) )
    ALLOCATE( desc%ngl( nproc ) )
    ALLOCATE( desc%npp( nproc ) )
    ALLOCATE( desc%ipp( nproc ) )
    ALLOCATE( desc%iss( nproc ) )
    ALLOCATE( desc%isind( nx * ny ) )
    ALLOCATE( desc%ismap( nx * ny ) )
    ALLOCATE( desc%iplp( nx ) )
    ALLOCATE( desc%iplw( nx ) )
    desc%nsp   = 0
    desc%nsw   = 0
    desc%ngl   = 0
    desc%npp   = 0
    desc%ipp   = 0
    desc%iss   = 0
    desc%isind = 0
    desc%ismap = 0
    desc%iplp  = 0
    desc%iplw  = 0
    desc%id    = 0
  END SUBROUTINE

  SUBROUTINE fft_dlay_deallocate( desc )
    TYPE (fft_dlay_descriptor) :: desc
    IF ( ASSOCIATED( desc%nsp ) )    DEALLOCATE( desc%nsp )
    IF ( ASSOCIATED( desc%nsw ) )    DEALLOCATE( desc%nsw )
    IF ( ASSOCIATED( desc%ngl ) )    DEALLOCATE( desc%ngl )
    IF ( ASSOCIATED( desc%npp ) )    DEALLOCATE( desc%npp )
    IF ( ASSOCIATED( desc%ipp ) )    DEALLOCATE( desc%ipp )
    IF ( ASSOCIATED( desc%iss ) )    DEALLOCATE( desc%iss )
    IF ( ASSOCIATED( desc%isind ) )  DEALLOCATE( desc%isind )
    IF ( ASSOCIATED( desc%ismap ) )  DEALLOCATE( desc%ismap )
    IF ( ASSOCIATED( desc%iplp ) )   DEALLOCATE( desc%iplp )
    IF ( ASSOCIATED( desc%iplw ) )   DEALLOCATE( desc%iplw )
    desc%id = 0
  END SUBROUTINE

!=----------------------------------------------------------------------------=!

  SUBROUTINE fft_dlay_set( desc, tk, nst, nr1, nr2, nr3, nr1x, nr2x, nr3x, me, &
    nproc, ub, lb, index, in1, in2, ncp, ncpw, ngp, ngpw, st, stw )

    TYPE (fft_dlay_descriptor) :: desc

    LOGICAL, INTENT(IN) :: tk 
    INTEGER, INTENT(IN) :: nst
    INTEGER, INTENT(IN) :: nr1, nr2, nr3, nr1x, nr2x, nr3x
    INTEGER, INTENT(IN) :: me       ! processor index Starting from 1
    INTEGER, INTENT(IN) :: nproc    ! number of processor
    INTEGER, INTENT(IN) :: index(:)
    INTEGER, INTENT(IN) :: in1(:)
    INTEGER, INTENT(IN) :: in2(:)
    INTEGER, INTENT(IN) :: ncp(:)
    INTEGER, INTENT(IN) :: ncpw(:)
    INTEGER, INTENT(IN) :: ngp(:)
    INTEGER, INTENT(IN) :: ngpw(:)
    INTEGER, INTENT(IN) :: lb(:), ub(:)
    INTEGER, INTENT(IN) :: st( lb(1) : ub(1), lb(2) : ub(2) )
    INTEGER, INTENT(IN) :: stw( lb(1) : ub(1), lb(2) : ub(2) )

    INTEGER :: npp( nproc ), n3( nproc ), nsp( nproc )
    INTEGER :: np, nq, i, is, iss, i1, i2, m1, m2, n1, n2, ip

    IF( ( SIZE( desc%ngl ) < nproc ) .OR. ( SIZE( desc%npp ) < nproc ) .OR.  &
        ( SIZE( desc%ipp ) < nproc ) .OR. ( SIZE( desc%iss ) < nproc ) )     &
      CALL errore( ' fft_dlay_set ', ' wrong descriptor dimensions ', 1 )

    IF( ( nr1 > nr1x ) .OR. ( nr2 > nr2x ) .OR. ( nr3 > nr3x ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong fft dimensions ', 2 )

    IF( ( SIZE( index ) < nst ) .OR. ( SIZE( in1 ) < nst ) .OR. ( SIZE( in2 ) < nst ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong number of stick dimensions ', 3 )

    IF( ( SIZE( ncp ) < nproc ) .OR. ( SIZE( ngp ) < nproc ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong stick dimensions ', 4 )


    !  Set the number of "xy" planes for each processor
    !  in other word do a slab partition along the z axis

    npp = 0
    IF ( nproc == 1 ) THEN
      npp(1) = nr3
    ELSE
      np = nr3 / nproc
      nq = nr3 - np * nproc
      DO i = 1, nproc
        npp(i) = np
        IF ( i <= nq ) npp(i) = np + 1
      END DO
    END IF

    desc%npp( 1:nproc )  = npp
    desc%npl = npp( me )

    !  Find out the index of the starting plane on each proc

    n3 = 0
    DO i = 2, nproc
      n3(i) = n3(i-1) + npp(i-1)
    END DO

    desc%ipp( 1:nproc )  = n3

    !  Set the proper number of sticks

    IF( .NOT. tk ) THEN
      desc%nst  = 2*nst - 1
    ELSE
      desc%nst  = nst
    END IF

    !  Set fft actual and leading dimensions

    desc%nr1  = nr1
    desc%nr2  = nr2
    desc%nr3  = nr3
    desc%nr1x = nr1x
    desc%nr2x = nr2x
    desc%nr3x = nr3x
    desc%nnp  = nr1x * nr2x   ! see ncplane

    !  Set fft local workspace dimension

    IF ( nproc == 1 ) THEN
      desc%nnr = nr1x * nr2x * nr3x
    ELSE
      desc%nnr  = MAX( nr3x * ncp(me), nr1x * nr2x * npp(me) )
    END IF

    desc%ngl( 1:nproc )  = ngp( 1:nproc )

    IF( SIZE( desc%isind ) < ( nr1x * nr2x ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong descriptor dimensions, isind ', 5 )

    IF( SIZE( desc%iplp ) < ( nr1x ) .OR. SIZE( desc%iplw ) < ( nr1x ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong descriptor dimensions, ipl ', 5 )

    !
    !  1. Temporarily store in the array "desc%isind" the index of the processor
    !     that own the corresponding stick (index of proc starting from 1)
    !  2. Set the array elements of  "desc%iplw" and "desc%iplp" to one 
    !     for that index corresponding to YZ planes containing at least one stick
    !     this are used in the FFT transform along Y
    !

    desc%isind = 0
    desc%iplp   = 0
    desc%iplw   = 0

    DO iss = 1, nst
      is = index( iss )
      i1 = in1( is )
      i2 = in2( is )
      IF( st( i1, i2 ) > 0 ) THEN
        m1 = i1 + 1; if ( m1 < 1 ) m1 = m1 + nr1
        m2 = i2 + 1; if ( m2 < 1 ) m2 = m2 + nr2
        IF( stw( i1, i2 ) > 0 ) THEN
          desc%isind( m1 + ( m2 - 1 ) * nr1x ) =  st( i1, i2 )
          desc%iplw( m1 ) = 1
        ELSE 
          desc%isind( m1 + ( m2 - 1 ) * nr1x ) = -st( i1, i2 )
        END IF
        desc%iplp( m1 ) = 1
        IF( .NOT. tk ) THEN
          n1 = -i1 + 1; if ( n1 < 1 ) n1 = n1 + nr1
          n2 = -i2 + 1; if ( n2 < 1 ) n2 = n2 + nr2
          IF( stw( -i1, -i2 ) > 0 ) THEN
            desc%isind( n1 + ( n2 - 1 ) * nr1x ) =  st( -i1, -i2 )
            desc%iplw( n1 ) = 1
          ELSE 
            desc%isind( n1 + ( n2 - 1 ) * nr1x ) = -st( -i1, -i2 )
          END IF
          desc%iplp( n1 ) = 1
        END IF
      END IF
    END DO

    !
    !  Compute for each proc the global index ( starting from 0 ) of the first
    !  local stick ( desc%iss )
    !

    DO i = 1, nproc
      IF( i == 1 ) THEN
        desc%iss( i ) = 0
      ELSE
        desc%iss( i ) = desc%iss( i - 1 ) + ncp( i - 1 )
      END IF
    END DO

    IF( SIZE( desc%ismap ) < ( nst ) ) &
      CALL errore( ' fft_dlay_set ', ' wrong descriptor dimensions ', 6 )

    !
    !  1. Set the array desc%ismap which maps stick indexes to 
    !     position in the palne  ( iss )
    !  2. Re-set the array "desc%isind",  that maps position 
    !     in the plane with stick indexes (it is the inverse of desc%ismap )
    !

    !  wave function sticks first

    desc%ismap = 0
    nsp        = 0
    DO iss = 1, SIZE( desc%isind )
      ip = desc%isind( iss )
      IF( ip > 0 ) THEN
        nsp( ip ) = nsp( ip ) + 1
        desc%ismap( nsp( ip ) + desc%iss( ip ) ) = iss
        IF( ip == me ) THEN
          desc%isind( iss ) = nsp( ip )
        ELSE
          desc%isind( iss ) = 0
        END IF
      END IF
    END DO

    !  chack number of stick against the input value

    IF( ANY( nsp( 1:nproc ) /= ncpw( 1:nproc ) ) ) THEN
      DO ip = 1, nproc
        WRITE(6,*)  ' * ', ip, ' * ', nsp( ip ), ' /= ', ncpw( ip )
      END DO
      CALL errore( ' fft_dlay_set ', ' inconsistent number of sticks ', 7 )
    END IF

    desc%nsw( 1:nproc ) = nsp

    !  then add pseudopotential stick 

    DO iss = 1, SIZE( desc%isind )
      ip = desc%isind( iss )
      IF( ip < 0 ) THEN
        nsp( -ip ) = nsp( -ip ) + 1
        desc%ismap( nsp( -ip ) + desc%iss( -ip ) ) = iss
        IF( -ip == me ) THEN
          desc%isind( iss ) = nsp( -ip )
        ELSE
          desc%isind( iss ) = 0
        END IF
      END IF
    END DO

    !  chack number of stick against the input value

    IF( ANY( nsp( 1:nproc ) /= ncp( 1:nproc ) ) ) THEN
      DO ip = 1, nproc
        WRITE(6,*)  ' * ', ip, ' * ', nsp( ip ), ' /= ', ncp( ip )
      END DO
      CALL errore( ' fft_dlay_set ', ' inconsistent number of sticks ', 8 )
    END IF

    desc%nsp( 1:nproc ) = nsp

    icount    = icount + 1
    desc%id   = icount

    !  Initialize the pointer to the fft tables
 
    desc%tptr = icount

    RETURN
  END SUBROUTINE

!=----------------------------------------------------------------------------=!

  SUBROUTINE fft_dlay_scalar( desc, ub, lb, nr1, nr2, nr3, nr1x, nr2x, nr3x, stw )

    implicit none

    TYPE (fft_dlay_descriptor) :: desc
    INTEGER, INTENT(IN) :: lb(:), ub(:)
    INTEGER, INTENT(IN) :: stw( lb(2) : ub(2), lb(3) : ub(3) )

    integer :: nr1, nr2, nr3, nr1x, nr2x, nr3x
    integer :: m1, m2, i1, i2, i3

    IF( SIZE( desc%iplw ) < nr3x .OR. SIZE( desc%isind ) < nr2x * nr3x ) &
      CALL errore(' fft_dlay_scalar ', ' wrong dimensions ', 1 )

    desc%isind = 0
    desc%iplw  = 0
    desc%iplp  = 1
    desc%nr1   = nr1
    desc%nr2   = nr2
    desc%nr3   = nr3
    desc%nr1x  = nr1x
    desc%nr2x  = nr2x
    desc%nr3x  = nr3x

    DO i2 = lb( 2 ), ub( 2 )
      DO i3 = lb( 3 ), ub( 3 )
        m1 = i2 + 1; if ( m1 < 1 ) m1 = m1 + nr2
        m2 = i3 + 1; if ( m2 < 1 ) m2 = m2 + nr3
        IF( stw( i2, i3 ) > 0 ) THEN
          desc%isind( m1 + ( m2 - 1 ) * nr2x ) =  1  ! st( i1, i2 )
          desc%iplw( m2 ) = 1
        END IF
      END DO
    END DO

    return
  end subroutine fft_dlay_scalar


END MODULE fft_types
