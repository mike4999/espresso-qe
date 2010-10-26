!
! Copyright (C) 2001-2004 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!------------------------------------------------
SUBROUTINE addnlcc_zstar_eu_us( drhoscf )
!----------===================-------------------

  USE kinds, ONLY : DP
  USE funct, only : dft_is_gradient
  USE scf, only : rho, rho_core
  USE cell_base, ONLY : omega, alat
  USE lsda_mod, ONLY : nspin
  USE gvect, ONLY : ngm, nl, g
  USE grid_dimensions, ONLY : nrxx, nr1, nr2, nr3
  USE noncollin_module, ONLY : nspin_lsda, nspin_gga
  USE efield_mod, ONLY : zstareu0
  USE qpoint, ONLY : xq
  USE nlcc_ph, ONLY : nlcc_any
  USE modes,  ONLY : npert, nirr
  USE eqv,    ONLY : dmuxc
  USE gc_ph,   ONLY: grho, dvxc_rr,  dvxc_sr,  dvxc_ss, dvxc_s

  USE mp_global, ONLY : my_pool_id


  IMPLICIT NONE

  COMPLEX(DP) :: drhoscf (nrxx,nspin,3)


  INTEGER :: nrtot, ipert, jpert, is, is1, irr, ir, mode, mode1
  INTEGER :: imode0, npe, ipol

  REAL(DP) :: fac

  COMPLEX(DP), DIMENSION(nrxx) :: drhoc
  COMPLEX(DP), DIMENSION(nrxx,nspin) :: dvaux

  IF (.NOT.nlcc_any) RETURN

  IF ( my_pool_id /= 0 ) RETURN

  DO ipol = 1, 3
     imode0 = 0
     DO irr = 1, nirr
        npe = npert(irr)
        !
        !  compute the exchange and correlation potential for this mode
        !
        nrtot = nr1 * nr2 * nr3
        fac = 1.d0 / DBLE (nspin_lsda)
        DO ipert = 1, npe
           mode = imode0 + ipert

           dvaux = (0.0_dp,0.0_dp)
           CALL addcore (mode, drhoc)

           DO is = 1, nspin_lsda
              rho%of_r(:,is) = rho%of_r(:,is) + fac * rho_core
           END DO

           DO is = 1, nspin
              DO is1 = 1, nspin
                 DO ir = 1, nrxx
                    dvaux (ir, is) = dvaux (ir, is) +     &
                         dmuxc (ir, is, is1) *            &
                         drhoscf (ir, is1, ipol)
                 ENDDO
              ENDDO
           END DO
           !
           ! add gradient correction to xc, NB: if nlcc is true we need to add here
           ! its contribution. grho contains already the core charge
           !

           IF ( dft_is_gradient() ) &
                CALL dgradcorr (rho%of_r, grho, &
                    dvxc_rr, dvxc_sr, dvxc_ss, dvxc_s, xq, drhoscf (1,1,ipert),&
                    nrxx, nspin, nspin_gga, nl, ngm, g, alat, dvaux)

           DO is = 1, nspin_lsda
              rho%of_r(:,is) = rho%of_r(:,is) - fac * rho_core
           END DO

           DO is = 1, nspin_lsda
              zstareu0(ipol,mode) = zstareu0(ipol,mode) -                  &
                   omega * fac / REAL(nrtot, DP) *         &
                   DOT_PRODUCT(dvaux(1:nrxx,is),drhoc(1:nrxx))
           END DO
        END DO
        imode0 = imode0 + npe
     END DO
  END DO

  RETURN
END SUBROUTINE addnlcc_zstar_eu_us
