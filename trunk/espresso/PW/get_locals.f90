!
!---------------------------------------------------------------------------
      subroutine get_locals(rholoc,magloc)
!---------------------------------------------------------------------------
!
!
! Here local integrations are carried out around atoms.
! The points and weights for these integrations are determined in the
! subroutine make_pointlists, the result may be printed in the
! subroutine report_mag. If constraints are present, the results of this
! calculation are used in v_of_rho for determining the penalty functional.
!
      USE kinds,      ONLY : DP
      USE ions_base,  ONLY : nat
      use pwcom
      use noncollin_module

      implicit none
      integer iat,i,ipol
      real(kind=DP) ::   &
          rholoc(nat),   &     ! integrated charge arount the atoms
          magloc(3,nat)        ! integrated magnetic moment around the atom

      do iat = 1,nat
         rholoc(iat) = 0.d0
         do ipol=1,3
            magloc(ipol,iat) = 0.d0
         enddo
         do i=1,pointnum(iat)
            rholoc(iat) = rholoc(iat) + rho(pointlist(i,iat),1) &
                *factlist(i,iat)
            if (noncolin) then
               do ipol = 1,3
                  magloc(ipol,iat) = magloc(ipol,iat) + rho(pointlist(i &
                      ,iat),ipol+1)*factlist(i,iat)
               enddo
            endif
         enddo
         call reduce(1,rholoc(iat))
       
         rholoc(iat) = rholoc(iat)*omega/(nr1*nr2*nr3)

         if (noncolin) then
            call reduce(3,magloc(1,iat))
            do ipol=1,3
               magloc(ipol,iat) = magloc(ipol,iat)*omega/(nr1*nr2*nr3)
            enddo
         endif
         
      enddo

      end
