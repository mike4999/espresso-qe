!
! Copyright (C) 2010 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!----------------------------------------------------------------------------
MODULE path_io_units_module
  !----------------------------------------------------------------------------
  !
  ! ... this module contains the I/O units and files used by  "path"-routines
  !
  USE io_files, ONLY : find_free_unit
  !
  IMPLICIT NONE
  !
  !
  SAVE
  !
  INTEGER :: iunpath = 6
  INTEGER :: stdinpath = 5
    CHARACTER (LEN=256) :: &
    dat_file      = 'os.dat',    &! file containing the enegy profile
    int_file      = 'os.int',    &! file containing the interpolated energy profile
    crd_file      = 'os.crd',    &! file containing path coordinates in pw.x input format
    path_file     = 'os.path',   &! file containing informations needed to restart a path simulation
    xyz_file      = 'os.xyz',    &! file containing coordinates of all images in xyz format
    axsf_file     = 'os.axsf',   &! file containing coordinates of all images in axsf format
    broy_file     = 'os.broyden'  ! file containing broyden's history
  !
  INTEGER :: iunrestart  = 2021 ! unit for saving the restart file ( neb_file )
  INTEGER :: iundat      = 2022 ! unit for saving the enegy profile
  INTEGER :: iunint      = 2023 ! unit for saving the interpolated energy profile
  INTEGER :: iunxyz      = 2024 ! unit for saving coordinates ( xyz format )
  INTEGER :: iunaxsf     = 2025 ! unit for saving coordinates ( axsf format )
  INTEGER :: iunbroy     = 2026 ! unit for saving broyden's history
  INTEGER :: iuncrd      = 2027 ! unit for saving coordinates in pw.x input format
  INTEGER :: iunnewimage = 28 ! unit for parallelization among images
  !
  !
  CONTAINS
  !
  SUBROUTINE set_io_units()
  !
  IMPLICIT NONE
  !
  iunrestart = find_free_unit()
  iundat = find_free_unit()
  iunint = find_free_unit()
  iunxyz = find_free_unit()
  iunaxsf = find_free_unit()
  iunbroy = find_free_unit()
  iuncrd = find_free_unit()
  iunnewimage = find_free_unit()
  !
  END SUBROUTINE set_io_units
  ! 
  SUBROUTINE set_output_unit()
  !
  IMPLICIT NONE
  !
  iunpath = find_free_unit()
  !
  END SUBROUTINE set_output_unit
  !
  SUBROUTINE set_input_unit()
  !
  IMPLICIT NONE
  !
  stdinpath = find_free_unit()
  !
  END SUBROUTINE set_input_unit
!
END MODULE path_io_units_module
