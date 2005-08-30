!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!-----------------------------------------------------------------------
SUBROUTINE punch_plot (filplot, plot_num, sample_bias, z, dz, &
     stm_wfc_matching, emin, emax, kpoint, kband, spin_component, &
     lsign, epsilon)
  !-----------------------------------------------------------------------
  !
  !     This subroutine writes on output several quantities
  !     in a real space 3D mesh which can be plotted using chdens.x
  !     The integer variable plot_num is used to choose the output quantity
  !
  !           plot_num                  quantity
  !              0                 self consistent charge density
  !              1                 the total potential V_bare+V_H + V_xc
  !              2                 the local ionic pseudopotential
  !              3                 the local density of states at e_fermi
  !              4                 the local density of electronic entropy
  !              5                 stm images
  !              6                 spin polarisation (rho(up)-rho(down)
  !              7                 square of a wavefunction
  !              8                 electron localization function (ELF)
  !              9                 planar averages of each wavefunction
  !             10                 integrated local dos from emin to emax
  !             11                 the V_bare + V_H potential
  !             12                 The electric field potential
  !             13                 The noncolinear magnetization.
  !                                Unfinished and untested:
  !             14, 15, 16         The polarisation along x, y, z resp.
  !
  !     The output quantity is written (formatted) on file filplot.
  !
  USE kinds,            ONLY : DP
  USE constants,        ONLY : rytoev
  USE cell_base,        ONLY : at, bg, omega, alat, celldm, ibrav
  USE ions_base,        ONLY : nat, ntyp => nsp, ityp, tau, zv, atm
  USE char,             ONLY : title
  USE extfield,         ONLY : tefield, dipfield
  USE gvect
  USE klist,            ONLY : nks, nkstot, xk
  USE lsda_mod,         ONLY : nspin, current_spin
  USE ener,             ONLY : ehart
  USE io_global,        ONLY : stdout, ionode
  USE scf,              ONLY : rho, vltot, vr
  USE wvfct,            ONLY : npw, nbnd, wg, igk, gamma_only
  USE noncollin_module, ONLY : noncolin

  IMPLICIT NONE
  CHARACTER(len=*) :: filplot
  INTEGER :: kpoint, kband, spin_component, plot_num
  LOGICAL :: stm_wfc_matching, lsign
  REAL(DP) :: sample_bias, z, dz, dummy
  REAL(DP) :: emin, emax, wf, charge, epsilon

  INTEGER :: is, ik, ibnd, ir, ninter, nspin_eff, ipol
#ifdef __PARA
  ! auxiliary vector (parallel case)
  REAL(DP), ALLOCATABLE :: raux1 (:)

#endif
  ! auxiliary vector
  REAL(DP), ALLOCATABLE :: raux (:)
  REAL(DP), ALLOCATABLE :: averag (:,:,:), plan (:,:,:)


  IF (filplot == ' ') RETURN
#ifdef __PARA
  ALLOCATE (raux1( nrx1 * nrx2 * nrx3))    
#endif

  WRITE( stdout, '(/5x,"Calling punch_plot, plot_num = ",i3)') plot_num
  IF ( plot_num == 9 .AND. gamma_only) CALL errore('punch_plot', &
      ' planar averge plot with  gamma tricks not yet implemented',1)
  !
  ALLOCATE (raux( nrxx))    
  !
  !     Here we decide which quantity to plot
  !
  IF (plot_num == 0) THEN
     !
     !      plot of the charge density
     !
     IF (noncolin) THEN
        call DCOPY (nrxx, rho, 1, raux, 1)
     ELSE
        IF (spin_component == 0) THEN
           CALL DCOPY (nrxx, rho (1, 1), 1, raux, 1)
           DO is = 2, nspin
              CALL DAXPY (nrxx, 1.d0, rho (1, is), 1, raux, 1)
           ENDDO
        ELSE
           IF (nspin == 2) current_spin = spin_component
           CALL DCOPY (nrxx, rho (1, current_spin), 1, raux, 1)
           CALL DSCAL (nrxx, 0.5d0 * nspin, raux, 1)
        ENDIF
     ENDIF

  ELSEIF (plot_num == 1) THEN
     !
     !       The total self-consistent potential V_H+V_xc on output
     !
     IF (noncolin) THEN
        call DCOPY (nrxx, vr, 1, raux, 1)
     ELSE
        IF (spin_component == 0) THEN
           CALL DCOPY (nrxx, vr, 1, raux, 1)
           DO is = 2, nspin
              CALL DAXPY (nrxx, 1.0d0, vr (1, is), 1, raux, 1)
           ENDDO
           CALL DSCAL (nrxx, 1.d0 / nspin, raux, 1)
        ELSE
           IF (nspin == 2) current_spin = spin_component
           CALL DCOPY (nrxx, vr (1, current_spin), 1, raux, 1)
        ENDIF
     ENDIF
     CALL DAXPY (nrxx, 1.0d0, vltot, 1, raux, 1)

  ELSEIF (plot_num == 2) THEN
     !
     !       The local pseudopotential on output
     !
     CALL DCOPY (nrxx, vltot, 1, raux, 1)

  ELSEIF (plot_num == 3) THEN
     !
     !       The local density of states at e_fermi on output
     !
     if (noncolin) call errore('punch_plot','not implemented yet',1)
     CALL local_dos (1, lsign, kpoint, kband, emin, emax, raux)

  ELSEIF (plot_num == 4) THEN
     !
     !       The local density of electronic entropy on output
     !
     if (noncolin) call errore('punch_plot','not implemented yet',1)
     CALL local_dos (2, lsign, kpoint, kband, emin, emax, raux)

  ELSEIF (plot_num == 5) THEN

     if (noncolin) call errore('punch_plot','not implemented yet',1)
     CALL work_function (wf)
#ifdef __PARA
     CALL stm (wf, sample_bias, z, dz, stm_wfc_matching, raux1)
#else
     CALL stm (wf, sample_bias, z, dz, stm_wfc_matching, raux)
#endif
     IF (stm_wfc_matching) THEN
        WRITE (title, '("Matching z = ",f4.2," dz in a.u. = ", &
             &       f4.2," Bias in eV = ",f10.4," # states",i4)') &
             z, dz * alat, sample_bias * rytoev, NINT (wf)
     ELSE
        WRITE (title, '("No matching, scf wave-functions. ", &
             &       " Bias in eV = ",f10.4," # states",i4)') &
             sample_bias * rytoev, NINT (wf)
     ENDIF

  ELSEIF (plot_num == 6) THEN
     !
     !      plot of the spin polarisation
     !
     IF (nspin == 2) THEN
        CALL DCOPY (nrxx, rho (1, 1), 1, raux, 1)
        CALL DAXPY (nrxx, - 1.d0, rho (1, 2), 1, raux, 1)
     ELSE
        raux(:) = 0.d0
     ENDIF

  ELSEIF (plot_num == 7) THEN

     CALL local_dos (0, lsign, kpoint, kband, emin, emax, raux)

  ELSEIF (plot_num == 8) THEN

     if (noncolin) &
        call errore('punch_plot','elf+noncolin not yet implemented',1)
     CALL do_elf (raux)

  ELSEIF (plot_num == 9) THEN

     if (noncolin) &
        call errore('punch_plot','planar avg+noncolin not yet implemented',1)
     ALLOCATE (averag( nat, nbnd, nkstot))    
     ALLOCATE (plan(nr3, nbnd, nkstot))    
     CALL plan_avg (averag, plan, ninter)

  ELSEIF (plot_num == 10) THEN

     if (noncolin) call errore('punch_plot','not implemented yet',1)
     CALL local_dos (3, lsign, kpoint, kband, emin, emax, raux)

  ELSEIF (plot_num == 11) THEN

     raux(:) = vltot(:) 
     IF (nspin == 2) THEN
        rho(:,1) =  rho(:,1) +  rho(:,2)
        nspin = 1
     END IF
     nspin_eff=nspin
     if (noncolin) nspin_eff=1
     CALL v_h (rho(1,1), nr1, nr2, nr3, nrx1, nrx2, nrx3, nrxx, &
       nl, ngm, gg, gstart, nspin_eff, alat, omega, ehart, charge, raux)
     IF (tefield.AND.dipfield) CALL add_efield(rho,raux,dummy,1)

  ELSEIF (plot_num == 12) THEN

     raux=0.d0
     IF (tefield) THEN
         CALL add_efield(rho,raux,dummy,1)
     ELSE
         CALL infomsg ('punch_plot','e_field is not calculated', -1)
     ENDIF

  ELSEIF (plot_num == 13) THEN

     IF (noncolin) THEN
        IF (spin_component==0) THEN
           raux(:) = SQRT(rho(:,2)**2 + rho(:,3)**2 + rho(:,4)**2 )
        ELSEIF (spin_component >= 1 .OR. spin_component <=3) THEN
           raux(:) = rho(:,spin_component+1)
        ELSE
           CALL errore('punch_plot','spin_component not allowed',1)
        ENDIF
     ELSE
        CALL errore('punch_plot','noncollinear spin required',1)
     ENDIF

  ELSEIF (plot_num == 14 .OR. plot_num == 15 .OR. plot_num == 16 ) THEN

     ipol = plot_num - 13
     call polarization ( spin_component, ipol, epsilon, raux )

  ELSE

     CALL infomsg ('punch_plot', 'plot_num not implemented', -1)

  ENDIF

#ifdef __PARA
  IF (.NOT. (plot_num == 5 .OR. plot_num == 9) ) &
       CALL gather (raux, raux1)
  IF ( ionode ) &
     CALL plot_io (filplot, title, nrx1, &
         nrx2, nrx3, nr1, nr2, nr3, nat, ntyp, ibrav, celldm, at, gcutm, &
         dual, ecutwfc, plot_num, atm, ityp, zv, tau, raux1, + 1)
  DEALLOCATE (raux1)
#else

  CALL plot_io (filplot, title, nrx1, nrx2, nrx3, nr1, nr2, nr3, &
       nat, ntyp, ibrav, celldm, at, gcutm, dual, ecutwfc, plot_num, &
       atm, ityp, zv, tau, raux, + 1)
#endif
  IF (plot_num == 9) THEN
     !
     IF ( ionode ) THEN
        !
        WRITE (4, '(3i8)') ninter, nkstot, nbnd
        DO ik = 1, nkstot
           DO ibnd = 1, nbnd
              WRITE (4, '(3f15.9,i5)') xk (1, ik) , xk (2, ik) , xk (3, &
                   ik) , ibnd
              WRITE (4, '(4(1pe17.9))') (averag (ir, ibnd, ik) , ir = 1, &
                   ninter)
              DO ir = 1, nr3
                 WRITE (4, * ) ir, plan (ir, ibnd, ik)
              ENDDO
           ENDDO
        ENDDO
        !
     ENDIF
     !
     DEALLOCATE (plan)
     DEALLOCATE (averag)
  ENDIF

  DEALLOCATE (raux)
  RETURN
END SUBROUTINE punch_plot

SUBROUTINE polarization ( spin_component, ipol, epsilon, raux )
  !
  USE kinds,     ONLY : DP
  USE constants, ONLY : fpi
  USE gvect, ONLY: nr1, nr2, nr3, nrx1, nrx2, nrx3, nl, nlm, &
       ngm, nrxx, gstart, g, gg
  USE lsda_mod,  ONLY : nspin
  USE scf, ONLY: rho
  USE wvfct,  ONLY: gamma_only
  USE wavefunctions_module,  ONLY: psic
  !
  IMPLICIT NONE
  INTEGER :: spin_component, ipol, ig
  REAL(DP) :: epsilon, raux (nrxx)
  !
  IF (ipol < 1 .OR. ipol > 3) CALL errore('polarization', &
       'wrong component',1)
  !
  IF (spin_component == 0) THEN
     IF (nspin == 1 .OR. nspin == 4 ) THEN
        psic(:) = CMPLX (rho(:,1), 0.d0)
     ELSE IF (nspin == 2) THEN
        psic(:) = CMPLX (rho(:,1) + rho(:,2), 0.d0) 
     END IF
  ELSE 
     IF (spin_component > nspin .OR. spin_component < 1) &
          CALL errore('polarization', 'wrong spin component',1)
     psic(:) = CMPLX (rho(:,spin_component), 0.d0)
  END IF
  !
  !   transform to G space
  !
  call cft3 (psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, - 1)
  !
  IF (gstart == 2) psic (1) = (epsilon - 1.d0) / fpi
  DO ig = gstart, ngm
     psic (nl (ig) ) = psic (nl (ig) ) * g (ipol, ig) / gg (ig) &
       / (0.d0, 1.d0)
     if (gamma_only) psic (nlm(ig) ) = CONJG ( psic (nl (ig) ) )
  END DO
  !
  CALL cft3 (psic, nr1, nr2, nr3, nrx1, nrx2, nrx3, 1)
  !
  raux (:) =  DBLE (psic (:) )
  !
  RETURN
  !
END SUBROUTINE polarization
