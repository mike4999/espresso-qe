!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

!------------------------------------------------------------------------------!
  MODULE cp_electronic_mass
!------------------------------------------------------------------------------!

    !  This module contains variable and functions relative to the
    !  Car-Parrinello fictitious electronic masse

      USE kinds, ONLY: dbl
!
      IMPLICIT NONE
      SAVE

      REAL(dbl) :: emass        = 1.0d0    !  fictitious electronic mass ( mu )
      REAL(dbl) :: emass_cutoff = 1.0d0    !  kinetic energy cutoff for plane
                                           !  waves to be used for Fourier acceleration
                                           !  preconditioning

!------------------------------------------------------------------------------!
  CONTAINS
!------------------------------------------------------------------------------!

    SUBROUTINE emass_precond( ema0bg, ggp, ngw, tpiba2, emaec )
      USE control_flags, ONLY: iprsta
      IMPLICIT NONE
      REAL(dbl), INTENT(OUT) :: ema0bg(:)
      REAL(dbl), INTENT(IN) :: ggp(:), tpiba2, emaec
      INTEGER, INTENT(IN) :: ngw
      INTEGER :: i
      !  mass preconditioning: ema0bg(i) = ratio of emass(g=0) to emass(g)
      !  for g**2>emaec the electron mass ema0bg(g) rises quadratically
      do i = 1, ngw
         ema0bg(i) = 1.0d0 / MAX( 1.d0, tpiba2 * ggp(i) / emaec )
         IF( iprsta >= 10 ) print *,i,' ema0bg(i) ',ema0bg(i)
      end do

      RETURN
    END SUBROUTINE


!------------------------------------------------------------------------------!
  END MODULE cp_electronic_mass
!------------------------------------------------------------------------------!
