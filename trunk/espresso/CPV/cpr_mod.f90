!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE stre
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : dbl
  !
  IMPLICIT NONE 
  SAVE
  !
  REAL(KIND=dbl) :: stress(3,3)
  !
END MODULE stre
!
!----------------------------------------------------------------------------
MODULE dqrad_mod
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : dbl
  !
  IMPLICIT NONE 
  SAVE
  !
  REAL(KIND=dbl), ALLOCATABLE :: dqrad(:,:,:,:,:,:,:)
  !
  CONTAINS
  !
  SUBROUTINE deallocate_dqrad_mod()
    !
    IF ( ALLOCATED( dqrad ) ) DEALLOCATE( dqrad )
    !
  END SUBROUTINE deallocate_dqrad_mod
  !
END MODULE dqrad_mod
!
!----------------------------------------------------------------------------
module betax
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : dbl
  !
  IMPLICIT NONE 
  SAVE
  !
  INTEGER, PARAMETER         :: mmx = 5001
  REAL(KIND=dbl)             :: refg
  REAL(KIND=dbl),ALLOCATABLE :: betagx(:,:,:), dbetagx(:,:,:), &
                                qradx(:,:,:,:,:), dqradx(:,:,:,:,:)
  !
  CONTAINS
  !
  SUBROUTINE deallocate_betax()
    !
    IF ( ALLOCATED( betagx ) )  DEALLOCATE( betagx )
    IF ( ALLOCATED( dbetagx ) ) DEALLOCATE( dbetagx )
    IF ( ALLOCATED( qradx ) )   DEALLOCATE( qradx )
    IF ( ALLOCATED( dqradx ) )  DEALLOCATE( dqradx )
    !
  END SUBROUTINE deallocate_betax
  !
END MODULE betax
!
!----------------------------------------------------------------------------
MODULE cpr_subroutines
  !----------------------------------------------------------------------------
  !
  USE kinds, ONLY : dbl
  !
  IMPLICIT NONE
  SAVE
  !
  CONTAINS
  !
  subroutine compute_stress( stress, detot, h, omega )
    real(kind=8) :: stress(3,3), detot(3,3), h(3,3), omega
    integer :: i, j
         do i=1,3
            do j=1,3
               stress(i,j)=-1.d0/omega*(detot(i,1)*h(j,1)+              &
     &                      detot(i,2)*h(j,2)+detot(i,3)*h(j,3))
            enddo
         enddo
    return
  end subroutine compute_stress

  subroutine print_atomic_var( var, na, nsp, head, iunit )
    use io_global, only: stdout
    real(kind=8) :: var(:,:)
    integer :: na(:), nsp
    integer, optional :: iunit
    character(len=*), optional :: head
    integer :: i, ia, is, iu, isa
    if( present( iunit ) ) then
      iu = iunit
    else
      iu = stdout
    end if
    if( present( head ) ) then 
      WRITE( iu,*) head
    end if
    isa = 0
    DO is = 1, nsp
      DO ia = 1, na(is)
        isa = isa + 1
        WRITE( iu,'(3f14.8)') ( var(i,isa), i=1, 3 )
      END DO
    END DO
    return
  end subroutine print_atomic_var

  subroutine print_cell_var( var, head, iunit )
    use io_global, only: stdout
    real(kind=8) :: var(3,3)
    integer, optional :: iunit
    character(len=*), optional :: head
    integer :: i, j, iu
    if( present( iunit ) ) then
      iu = iunit
    else
      iu = stdout
    end if
    if( present( head ) ) then 
      WRITE( iu,*)
      WRITE( iu,*) head
      WRITE( iu, 5555 ) ((var(i,j),j=1,3),i=1,3)
 5555    format(1x,f12.5,1x,f12.5,1x,f12.5/                             &
     &          1x,f12.5,1x,f12.5,1x,f12.5/                             &
     &          1x,f12.5,1x,f12.5,1x,f12.5//)
    else
      write(iu,3340) ((var(i,j),i=1,3),j=1,3)
 3340     format(9(1x,f9.5))
    end if
    return
  end subroutine print_cell_var
  !
  !--------------------------------------------------------------------------
  SUBROUTINE ions_cofmsub( tausp, iforce, na, nsp, cdm, cdm0 )
    !--------------------------------------------------------------------------
    !
    IMPLICIT NONE
    !
    REAL(KIND=dbl), INTENT(INOUT) :: tausp(:,:)
    INTEGER,        INTENT(IN)    :: iforce(:,:)
    INTEGER,        INTENT(IN)    :: na(:), nsp
    REAL(KIND=dbl), INTENT(IN)    :: cdm(:), cdm0(:)
    !
    INTEGER :: i, ia, is, isa
    !
    !
    isa = 0
    !
    DO is = 1, nsp
       !
       DO ia = 1, na(is)
          !
          isa = isa + 1
          !
          DO i = 1, 3
             !
             tausp(i,isa) = tausp(i,isa) + &
                            DBLE( iforce(i,isa) ) * ( cdm0(i) - cdm(i) )
             !
          END DO
          !
       END DO
       !
    END DO
    !
    RETURN
    !
  END SUBROUTINE ions_cofmsub
  !
  subroutine elec_fakekine( ekincm, ema0bg, emass, c0, cm, ngw, n, delt )
    use mp, only: mp_sum
    use reciprocal_vectors, only: gstart
    use wave_base, only: wave_speed2
    real(kind=8), intent(out) :: ekincm
    real(kind=8), intent(in)  :: ema0bg(:), delt, emass
    complex(kind=8), intent(in)  :: c0(:,:,:,:), cm(:,:,:,:)
    integer, intent(in) :: ngw, n
    real(kind=8), allocatable :: emainv(:)
    real(kind=8) :: ftmp
    integer :: i

    ALLOCATE( emainv( ngw ) )
    emainv = 1.0d0 / ema0bg
    ftmp = 1.0d0
    if( gstart == 2 ) ftmp = 0.5d0

    ekincm=0.0d0
    do i=1,n
      ekincm = ekincm + 2.0d0 * &
               wave_speed2( c0(:,i,1,1), cm(:,i,1,1), emainv, ftmp )
    end do
    ekincm = ekincm * emass / ( delt * delt )

    CALL mp_sum( ekincm )
    DEALLOCATE( emainv )

    return
  end subroutine elec_fakekine

  subroutine elec_fakekine2( ekincm, ema0bg, emass, c0, cm, ngw, n, delt )
    use mp, only: mp_sum
    use reciprocal_vectors, only: gstart
    use wave_base, only: wave_speed2
    real(kind=8), intent(out) :: ekincm
    real(kind=8), intent(in)  :: ema0bg(:), delt, emass
    complex(kind=8), intent(in)  :: c0(:,:), cm(:,:)
    integer, intent(in) :: ngw, n
    real(kind=8), allocatable :: emainv(:)
    real(kind=8) :: ftmp
    integer :: i

    ALLOCATE( emainv( ngw ) )
    emainv = 1.0d0 / ema0bg
    ftmp = 1.0d0
    if( gstart == 2 ) ftmp = 0.5d0

    ekincm=0.0d0
    do i=1,n
      ekincm = ekincm + 2.0d0 * &
               wave_speed2( c0(:,i), cm(:,i), emainv, ftmp )
    end do
    ekincm = ekincm * emass / ( delt * delt )

    CALL mp_sum( ekincm )
    DEALLOCATE( emainv )

    return
  end subroutine elec_fakekine2

 
  subroutine print_lambda( lambda, n, nshow, ccc, iunit )
    use io_global, only: stdout, ionode
    real(kind=8), intent(in) :: lambda(:,:), ccc
    integer, intent(in) :: n, nshow
    integer, intent(in), optional :: iunit
    integer :: nnn, j, un, i
    if( present( iunit ) ) then
      un = iunit
    else
      un = stdout
    end if
    nnn=min(n,nshow)
    if( ionode ) then
       WRITE( un,*)
       WRITE( un,3370) '    lambda   n = ', n
       IF( nnn < n ) WRITE( un,3370) '    print only first ', nnn
       do i=1,nnn
          WRITE( un,3380) (lambda(i,j)*ccc,j=1,nnn)
       end do
    end if
3370     format(26x,a,i4)
3380     format(9f8.4)
    return
  end subroutine print_lambda

   subroutine add_thermal_stress( stress, pmass, omega, h, vels, nsp, na )
     real(kind=8) :: stress(3,3)
     real(kind=8), intent(in) :: pmass(:), omega, h(3,3), vels(:,:)
     integer, intent(in) :: nsp, na(:)
     integer :: i, j, is, ia, isa
     isa = 0
     do is=1,nsp
       do ia=1,na(is)
       isa = isa + 1
         do i=1,3
           do j=1,3
             stress(i,j)=stress(i,j)+pmass(is)/omega*           &
      &        ((h(i,1)*vels(1,isa)+h(i,2)*vels(2,isa)+    &
      &          h(i,3)*vels(3,isa))*(h(j,1)*vels(1,isa)+  &
      &          h(j,2)*vels(2,isa)+h(j,3)*vels(3,isa)))
           enddo
         enddo
       enddo
     enddo
     return
   end subroutine add_thermal_stress

END MODULE cpr_subroutines
