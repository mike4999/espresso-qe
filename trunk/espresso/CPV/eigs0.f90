!
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
      subroutine eigs0( tprint, nspin, nupdwn, iupdwn, lf, f, nx, lambda, nudx )
!-----------------------------------------------------------------------
!     computes eigenvalues (wr) of the real symmetric matrix lambda
!     Note that lambda as calculated is multiplied by occupation numbers
!     so empty states yield zero. Eigenvalues are printed out in eV
!
      use kinds, only            : DP
      use io_global, only        : stdout
      use constants, only        : au
      use electrons_module, only : ei
      use parallel_toolkit, only : dspev_drv
      USE sic_module, only       : self_interaction

      implicit none
! input
      logical, intent(in) :: tprint, lf
      integer, intent(in) :: nspin, nx, nudx, nupdwn(nspin), iupdwn(nspin)
      real(DP), intent(in) :: lambda( nudx, nudx, nspin ), f( nx )
! local variables
      real(DP), allocatable :: lambdar(:)
      real(DP) wr(nx), fv1(nx),fm1(2,nx), zr(1)
      integer :: iss, j, i, ierr, k, n, nspin_eig, npaired
      logical :: tsic
!
      tsic = ( ABS( self_interaction) /= 0 )

      IF( tsic ) THEN
         nspin_eig = 1
         npaired   = nupdwn(2)
      ELSE
         nspin_eig = nspin
         npaired   = 0
      END IF

      do iss = 1, nspin_eig

         n = nupdwn(iss)

         allocate( lambdar( n * ( n + 1 ) / 2 ) )

         k = 0

         do i = 1, n
            do j = i, n
               k = k + 1
               lambdar( k ) = lambda( j, i, iss )
            end do
         end do

         CALL dspev_drv( 'N', 'L', n, lambdar, wr, zr, 1 )

         if( lf ) then
            do i=1,nupdwn(iss)
               if (f(iupdwn(iss)-1+i).gt.1.e-6) then
                  wr(i)=wr(i)/f(iupdwn(iss)-1+i)
               else
                  wr(i)=0.0
               end if
            end do
         end if
         !
         !     store eigenvalues
         !
         IF( SIZE( ei, 1 ) < nupdwn(iss) ) &
            CALL errore( ' eigs0 ', ' wrong dimension array ei ', 1 )

         IF( tsic ) THEN
            !
            !  only paired states are stored
            !
            ei( 1:npaired, 1, iss )     = wr( 1:npaired )
         ELSE
            ei( 1:nupdwn(iss), 1, iss ) = wr( 1:nupdwn(iss) )
         END IF

         deallocate( lambdar )

      end do
      !
      !
      do iss = 1, nspin

         IF( tsic .AND. iss > 1 ) THEN
            ei( 1:npaired, 1, iss ) = ei( 1:npaired, 1, 1 )
         END IF

         IF( tprint ) THEN
            !
            !     print out eigenvalues
            !
            WRITE( stdout,12) 0., 0., 0.
            WRITE( stdout,14) ( ei( i, 1, iss ) * au, i = 1, nupdwn(iss) )

         ENDIF

      end do

      IF( tprint ) WRITE( stdout,*)

   12 format(//' eigenvalues at k-point: ',3f6.3)
   14 format(10f8.2)
!
      return
      end subroutine eigs0
