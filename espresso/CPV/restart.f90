!
! Copyright (C) 2002-2005 Quantum-ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!=----------------------------------------------------------------------------=!
  MODULE restart_file
!=----------------------------------------------------------------------------=!

  USE kinds, ONLY: dbl

  IMPLICIT NONE

  PRIVATE

  SAVE

  REAL(dbl) :: cclock
  EXTERNAL  :: cclock

  PUBLIC :: writefile, readfile

  INTERFACE readfile
    MODULE PROCEDURE readfile_cp, readfile_fpmd
  END INTERFACE

  INTERFACE writefile
    MODULE PROCEDURE writefile_cp, writefile_fpmd
  END INTERFACE
  
!=----------------------------------------------------------------------------=!
     CONTAINS
!=----------------------------------------------------------------------------=!

!-----------------------------------------------------------------------
      subroutine writefile_cp                                         &
     &     ( ndw,h,hold,nfi,c0,cm,taus,tausm,vels,velsm,acc,           &
     &       lambda,lambdam,xnhe0,xnhem,vnhe,xnhp0,xnhpm,vnhp,nhpcl,ekincm,  &
     &       xnhh0,xnhhm,vnhh,velh,ecut,ecutw,delt,pmass,ibrav,celldm, &
     &       fion, tps, mat_z, occ_f )
!-----------------------------------------------------------------------
!
! read from file and distribute data calculated in preceding iterations
!
      USE ions_base,        ONLY: nsp, na
      USE cell_base,        ONLY: s_to_r
      USE cp_restart,       ONLY: cp_writefile
      USE electrons_base,   ONLY: nspin, nbnd, nbsp, iupdwn, nupdwn
      USE electrons_module, ONLY: ei
      USE io_files,         ONLY: scradir
!
      implicit none
      integer, INTENT(IN) :: ndw, nfi
      real(kind=8), INTENT(IN) :: h(3,3), hold(3,3)
      complex(kind=8), INTENT(IN) :: c0(:,:), cm(:,:)
      real(kind=8), INTENT(IN) :: tausm(:,:), taus(:,:), fion(:,:)
      real(kind=8), INTENT(IN) :: vels(:,:), velsm(:,:)
      real(kind=8), INTENT(IN) :: acc(:), lambda(:,:), lambdam(:,:)
      real(kind=8), INTENT(IN) :: xnhe0, xnhem, vnhe, ekincm
      real(kind=8), INTENT(IN) :: xnhp0(:), xnhpm(:), vnhp(:)
      integer,      INTENT(in) :: nhpcl
      real(kind=8), INTENT(IN) :: xnhh0(3,3),xnhhm(3,3),vnhh(3,3),velh(3,3)
      real(kind=8), INTENT(in) :: ecut, ecutw, delt
      real(kind=8), INTENT(in) :: pmass(:)
      real(kind=8), INTENT(in) :: celldm(:)
      real(kind=8), INTENT(in) :: tps
      integer, INTENT(in) :: ibrav
      real(kind=8), INTENT(in) :: mat_z(:,:,:), occ_f(:)

      real(kind=8) :: ht(3,3), htm(3,3), htvel(3,3), gvel(3,3)
      integer :: nk = 1, ispin, i, ib
      real(kind=8) :: xk(3,1) = 0.0d0, wk(1) = 1.0d0
      real(kind=8) :: cdmi_ (3) = 0.0d0
      real(kind=8), ALLOCATABLE :: taui_ (:,:) 
      real(kind=8), ALLOCATABLE :: occ_ ( :, :, : )
      real(kind=8) :: htm1(3,3), omega

!
! Do not write restart file if the unit number 
! is negative, this is used mainly for benchmarks
! and tests
!

      if ( ndw < 1 ) then
        return
      end if

      ht     = TRANSPOSE( h ) 
      htm    = TRANSPOSE( hold ) 
      htvel  = TRANSPOSE( velh ) 
      gvel   = 0.0d0
      

      ALLOCATE( taui_ ( 3, SIZE( taus, 2 ) ) )
      CALL s_to_r( taus, taui_ , na, nsp, h )

      cdmi_ = 0.0d0

      ALLOCATE( occ_ ( nbnd, 1, nspin ) )
      occ_ = 0.0d0
      do ispin = 1, nspin
        do i = iupdwn ( ispin ), iupdwn ( ispin ) - 1 + nupdwn ( ispin )
          occ_ ( i - iupdwn ( ispin ) + 1, 1, ispin ) = occ_f( i ) 
        end do
      end do

      CALL cp_writefile( ndw, scradir, .TRUE., nfi, tps, acc, nk, xk, wk, &
        ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui_ , cdmi_ , taus, &
        vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl, occ_ , &
        occ_ , lambda, lambdam, xnhe0, xnhem, vnhe, ekincm, mat_z, ei, &
        c02 = c0, cm2 = cm  )

      DEALLOCATE( taui_ )
      DEALLOCATE( occ_ )

      return
      end subroutine writefile_cp

!-----------------------------------------------------------------------
      subroutine readfile_cp                                        &
     &     ( flag, ndr,h,hold,nfi,c0,cm,taus,tausm,vels,velsm,acc,    &
     &       lambda,lambdam,xnhe0,xnhem,vnhe,xnhp0,xnhpm,vnhp,nhpcl,ekincm, &
     &       xnhh0,xnhhm,vnhh,velh,ecut,ecutw,delt,pmass,ibrav,celldm,&
     &       fion, tps, mat_z, occ_f )
!-----------------------------------------------------------------------
!
! read from file and distribute data calculated in preceding iterations
!
      USE io_files,  ONLY : scradir

      USE electrons_base, ONLY: nbnd, nbsp, nspin, nupdwn, iupdwn
      USE gvecw,          ONLY: ngw, ngwt
      USE ions_base,      ONLY: nsp, na
      USE cp_restart,     ONLY: cp_readfile, cp_read_cell, cp_read_wfc
      USE ensemble_dft,   ONLY: tens
      USE io_files,       ONLY: scradir
!
      implicit none
      integer :: ndr, nfi, flag
      real(kind=8) :: h(3,3), hold(3,3)
      complex(kind=8) :: c0(:,:), cm(:,:)
      real(kind=8) :: tausm(:,:),taus(:,:), fion(:,:)
      real(kind=8) :: vels(:,:), velsm(:,:)
      real(kind=8) :: acc(:),lambda(:,:), lambdam(:,:)
      real(kind=8) :: xnhe0,xnhem,vnhe
      real(kind=8) :: xnhp0(:), xnhpm(:), vnhp(:)
      integer, INTENT(inout) :: nhpcl
      real(kind=8) :: ekincm
      real(kind=8) :: xnhh0(3,3),xnhhm(3,3),vnhh(3,3),velh(3,3)
      real(kind=8), INTENT(in) :: ecut, ecutw, delt
      real(kind=8), INTENT(in) :: pmass(:)
      real(kind=8), INTENT(in) :: celldm(6)
      integer, INTENT(in) :: ibrav
      real(kind=8), INTENT(OUT) :: tps
      real(kind=8), INTENT(INOUT) :: mat_z(:,:,:), occ_f(:)
      !
      real(kind=8) :: ht(3,3), htm(3,3), htvel(3,3), gvel(3,3)
      integer :: nk = 1, ispin, i, ib
      real(kind=8) :: xk(3,1) = 0.0d0, wk(1) = 1.0d0
      real(kind=8) :: cdmi_ (3) = 0.0d0
      real(kind=8), ALLOCATABLE :: taui_ (:,:)
      real(kind=8), ALLOCATABLE :: occ_ ( :, :, : )
      real(kind=8) :: htm1(3,3), b1(3) , b2(3), b3(3), omega


      IF( flag == -1 ) THEN
        CALL cp_read_cell( ndr, scradir, .TRUE., ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh )
        h     = TRANSPOSE( ht )
        hold  = TRANSPOSE( htm )
        velh  = TRANSPOSE( htvel )
        RETURN
      ELSE IF ( flag == 0 ) THEN
        DO ispin = 1, nspin
          CALL cp_read_wfc( ndr, scradir, 1, 1, ispin, nspin, c2 = cm(:,:), tag = 'm' )
        END DO
        RETURN
      END IF

      ALLOCATE( taui_ ( 3, SIZE( taus, 2 ) ) )
      ALLOCATE( occ_ ( nbnd, 1, nspin ) )

      CALL cp_readfile( ndr, scradir, .TRUE., nfi, tps, acc, nk, xk, wk, &
        ht, htm, htvel, gvel, xnhh0, xnhhm, vnhh, taui_ , cdmi_ , taus, &
        vels, tausm, velsm, fion, vnhp, xnhp0, xnhpm, nhpcl , occ_ , &
        occ_ , lambda, lambdam, b1, b2, b3, &
        xnhe0, xnhem, vnhe, ekincm, mat_z, tens, c02 = c0, cm2 = cm  )

      DEALLOCATE( taui_ )

      do ispin = 1, nspin
        do i = iupdwn ( ispin ), iupdwn ( ispin ) - 1 + nupdwn ( ispin )
          occ_f( i ) = occ_ ( i - iupdwn ( ispin ) + 1, 1, ispin )
        end do
      end do
      DEALLOCATE( occ_ )

      h     = TRANSPOSE( ht )
      hold  = TRANSPOSE( htm )
      velh  = TRANSPOSE( htvel )

      return
      end subroutine readfile_cp


!=----------------------------------------------------------------------------=!


   SUBROUTINE writefile_fpmd( nfi, trutime, c0, cm, cdesc, occ, &
     atoms_0, atoms_m, acc, taui, cdmi, &
     ht_m, ht_0, rho, desc, vpot)
                                                                        
        USE cell_module, only: boxdimensions, r_to_s
        USE brillouin, only: kpoints, kp
        USE wave_types, ONLY: wave_descriptor
        USE control_flags, ONLY: ndw, gamma_only
        USE control_flags, ONLY: twfcollect, force_pairing
        USE atoms_type_module, ONLY: atoms_type
        USE io_global, ONLY: ionode, ionode_id
        USE io_global, ONLY: stdout
        USE charge_types, ONLY: charge_descriptor
        USE electrons_nose, ONLY: xnhe0, xnhem, vnhe
        USE electrons_base, ONLY: nbsp, nspin
        USE cell_nose, ONLY: xnhh0, xnhhm, vnhh
        USE ions_nose, ONLY: vnhp, xnhp0, xnhpm, nhpcl
        USE cp_restart, ONLY: cp_writefile
        USE electrons_module, ONLY: ei
        USE io_files, ONLY: scradir

        IMPLICIT NONE 
 
        INTEGER, INTENT(IN) :: nfi
        COMPLEX(dbl), INTENT(IN) :: c0(:,:,:,:), cm(:,:,:,:) 
        REAL(dbl), INTENT(IN) :: occ(:,:,:)
        TYPE (boxdimensions), INTENT(IN) :: ht_m, ht_0
        TYPE (atoms_type), INTENT(IN) :: atoms_0, atoms_m
        REAL(dbl), INTENT(IN) :: rho(:,:,:,:)
        TYPE (charge_descriptor), INTENT(IN) :: desc
        TYPE (wave_descriptor) :: cdesc
        REAL(dbl), INTENT(INOUT) :: vpot(:,:,:,:)
                                                                        
        REAL(dbl), INTENT(IN) :: taui(:,:)
        REAL(dbl), INTENT(IN) :: acc(:), cdmi(:) 
        REAL(dbl), INTENT(IN) :: trutime

        REAL(dbl), ALLOCATABLE :: lambda(:,:)
        REAL(dbl) S0, S1
        REAL(dbl) :: ekincm
        REAL(dbl) :: mat_z(1,1,nspin)
             
        s0 = cclock()

        IF( ndw < 1 ) RETURN
        !
        !   this is used for benchmarking and debug
        !   if ndw < 1 Do not save wave functions and other system
        !   properties on the writefile subroutine

        ALLOCATE( lambda(nbsp,nbsp) )
        lambda  = 0.0d0
        ekincm = 0.0d0
        mat_z = 0.0d0

        CALL cp_writefile( ndw, scradir, .TRUE., nfi, trutime, acc, kp%nkpt, kp%xk, kp%weight, &
          ht_0%a, ht_m%a, ht_0%hvel, ht_0%gvel, xnhh0, xnhhm, vnhh, taui, cdmi, &
          atoms_0%taus, atoms_0%vels, atoms_m%taus, atoms_m%vels, atoms_0%for, vnhp, &
          xnhp0, xnhpm, nhpcl, occ, occ, lambda, lambda,  &
          xnhe0, xnhem, vnhe, ekincm, mat_z, ei, c04 = c0, cm4 = cm )

        DEALLOCATE( lambda )

        s1 = cclock()

!       ==--------------------------------------------------------------==
        IF( ionode ) THEN 
          WRITE( stdout,10) (s1-s0)
   10     FORMAT(/,3X,'RESTART FILE WRITTEN COMPLETED IN ',F8.3,' SEC.',/) 
        END IF 
!       ==--------------------------------------------------------------==

     RETURN 
   END SUBROUTINE writefile_fpmd



!=----------------------------------------------------------------------------=!

        SUBROUTINE readfile_fpmd( nfi, trutime, &
          c0, cm, cdesc, occ, atoms_0, atoms_m, acc, taui, cdmi, &
          ht_m, ht_0, rho, desc, vpot )
                                                                        
        use electrons_base, only: nbsp
        USE cell_module, only: boxdimensions, cell_init, r_to_s, s_to_r
        USE brillouin, only: kpoints, kp
        use parameters, only: npkx, nsx
        USE mp, ONLY: mp_sum, mp_barrier
        USE mp_global, ONLY: mpime, nproc, group, root
        USE mp_wave, ONLY: mergewf
        USE wave_types, ONLY: wave_descriptor
        USE control_flags, ONLY: ndr, tbeg, gamma_only
        USE atoms_type_module, ONLY: atoms_type
        USE io_global, ONLY: ionode
        USE io_global, ONLY: stdout
        USE gvecw, ONLY: ecutwfc => ecutw
        USE gvecp, ONLY: ecutrho => ecutp
        USE fft, ONLY : pfwfft, pinvfft
        USE charge_types, ONLY: charge_descriptor
        USE ions_base, ONLY: nat, nsp, na
        USE electrons_module, ONLY: nspin
        USE control_flags, ONLY: twfcollect, force_pairing
        USE wave_functions, ONLY: gram
        USE grid_dimensions, ONLY: nr1, nr2, nr3
        USE electrons_nose, ONLY: xnhe0, xnhem, vnhe
        USE cell_nose, ONLY: xnhh0, xnhhm, vnhh
        USE ions_nose, ONLY: vnhp, xnhp0, xnhpm, nhpcl
        USE cp_restart, ONLY: cp_readfile
        USE io_files, ONLY: scradir
 
        IMPLICIT NONE 
 
        INTEGER, INTENT(OUT) :: nfi
        COMPLEX(dbl), INTENT(INOUT) :: c0(:,:,:,:), cm(:,:,:,:) 
        REAL(dbl), INTENT(INOUT) :: occ(:,:,:)
        TYPE (boxdimensions), INTENT(INOUT) :: ht_m, ht_0
        TYPE (atoms_type), INTENT(INOUT) :: atoms_0, atoms_m
        REAL(dbl), INTENT(INOUT) :: rho(:,:,:,:)
        TYPE (charge_descriptor), INTENT(IN) :: desc
        TYPE (wave_descriptor) :: cdesc
        REAL(dbl), INTENT(INOUT) :: vpot(:,:,:,:)
                                                                        
        REAL(dbl), INTENT(OUT) :: taui(:,:)
        REAL(dbl), INTENT(OUT) :: acc(:), cdmi(:) 
        REAL(dbl), INTENT(OUT) :: trutime


        REAL(dbl) :: s0, s1
        REAL(dbl), ALLOCATABLE :: lambda_ ( : , : )
        REAL(dbl) :: ekincm
        REAL(dbl) :: hp0_ (3,3)
        REAL(dbl) :: hm1_ (3,3)
        REAL(dbl) :: gvel_ (3,3)
        REAL(dbl) :: hvel_ (3,3)
        REAL(dbl) :: mat_z_(1,1,nspin)
        REAL(dbl) :: b1(3), b2(3), b3(3)
        LOGICAL :: tens = .FALSE.

        CALL mp_barrier()
        s0 = cclock()

        ALLOCATE( lambda_( nbsp , nbsp ) )
        lambda_  = 0.0d0

        CALL cp_readfile( ndr, scradir, .TRUE., nfi, trutime, acc, kp%nkpt, kp%xk, kp%weight, &
          hp0_ , hm1_ , hvel_ , gvel_ , xnhh0, xnhhm, vnhh, taui, cdmi, &
          atoms_0%taus, atoms_0%vels, atoms_m%taus, atoms_m%vels, atoms_0%for, vnhp, &
          xnhp0, xnhpm, nhpcl, occ, occ, lambda_ , lambda_ , b1, b2,   &
          b3, xnhe0, xnhem, vnhe, ekincm, mat_z_ , tens, c04 = c0, cm4 = cm )

        DEALLOCATE( lambda_ )

        IF( .NOT. tbeg ) THEN
          CALL cell_init( ht_0, hp0_ )
          CALL cell_init( ht_m, hm1_ )
          ht_0%hvel = hvel_  !  set cell velocity
          ht_0%gvel = gvel_  !  set cell velocity
        END IF

        CALL mp_barrier()
        s1 = cclock()

!       ==--------------------------------------------------------------==
        IF( ionode ) THEN 
          WRITE( stdout,20)  (s1-s0)
   20     FORMAT(3X,'DISK READ COMPLETED IN ',F8.3,' SEC.',/) 
        END IF 
!       ==--------------------------------------------------------------==

        RETURN 
        END SUBROUTINE readfile_fpmd

!=----------------------------------------------------------------------------=!

!=----------------------------------------------------------------------------=!
     END MODULE restart_file
!=----------------------------------------------------------------------------=!
