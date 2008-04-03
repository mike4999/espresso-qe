! Copyright (C) 2008 Quantum-Espresso group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!=----------------------------------------------------------------------------=!
      MODULE upf_module
!=----------------------------------------------------------------------------=!
!  this module handles reading and writing of unified pseudopotential format (UPF)
!  it can manage v2 read/write and v1 read only.
!
! A macro to trim both from left and right
#define TRIM(a) trim(adjustl(a))
      !
#ifdef __STANDALONE
      USE kinds, ONLY: DP, errore
#else
      USE kinds,        ONLY: DP
#endif
      USE pseudo_types, ONLY: pseudo_upf
      USE iotk_module
      !
      USE read_upf_v1_module
      USE read_upf_v2_module
      USE write_upf_v2_module
      !
      IMPLICIT NONE
      PUBLIC
      !
      CONTAINS

!------------------------------------------------+
SUBROUTINE read_upf(upf, grid, ierr, unit, filename)             !
   !---------------------------------------------+
   ! Read pseudopotential in UPF format version 2, uses iotk
   !
   USE pseudo_types, ONLY: nullify_pseudo_upf, deallocate_pseudo_upf
   USE radial_grids, ONLY: radial_grid_type, nullify_radial_grid
   USE read_upf_v1_module,ONLY: read_upf_v1
   IMPLICIT NONE
   INTEGER,INTENT(IN),OPTIONAL             :: unit      ! i/o unit
   CHARACTER(len=*),INTENT(IN),OPTIONAL    :: filename  ! i/o filename
   TYPE(pseudo_upf),INTENT(INOUT) :: upf       ! the pseudo data
   TYPE(radial_grid_type),OPTIONAL,INTENT(INOUT),TARGET :: grid
   INTEGER,INTENT(OUT) :: ierr
   !
   INTEGER :: u         ! i/o unit

   ierr = 0

   IF(.not. present(unit)) THEN
      IF (.not. present(filename)) &
         CALL errore('write_upf_v2',&
         'You have to specify at least one between filename and unit',1)
      CALL iotk_free_unit(u)
   ELSE
      u = unit
   ENDIF
   !
   IF(present(filename)) &
      open (unit = u, file = filename, status = 'old', form = &
      'formatted', iostat = ierr)
   IF(ierr>0) CALL errore('read_upf', 'Cannot open file: '//TRIM(filename),1)
   !
   CALL read_upf_v2(u,upf,grid,ierr)
   !
   IF(ierr>0) THEN
      REWIND(u)
      CALL read_upf_v1(u,upf,grid,ierr)
   ENDIF

   RETURN

END SUBROUTINE read_upf

!------------------------------------------------+
SUBROUTINE write_upf(upf, meta_info, unit, filename)             !
   !---------------------------------------------+
   ! Read pseudopotential in UPF format version 2, uses iotk
   !
   USE pseudo_types, ONLY: nullify_pseudo_upf, deallocate_pseudo_upf
   USE read_upf_v1_module,ONLY: read_upf_v1
   IMPLICIT NONE
   TYPE(pseudo_upf),INTENT(INOUT)       :: upf       ! the pseudo data
   INTEGER,INTENT(IN),OPTIONAL          :: unit      ! i/o unit
   CHARACTER(len=*),INTENT(IN),OPTIONAL :: filename  ! i/o filename
   TYPE(pseudo_upf_meta_info),OPTIONAL,INTENT(IN) :: meta_info ! additional non mandatory info
   !
   INTEGER :: u, ierr ! i/o unit and error handler

   ierr = 0

   IF(.not. present(unit)) THEN
      IF (.not. present(filename)) &
         CALL errore('read_upf_v2',&
         'You have to specify at least one between filename and unit',1)
      CALL iotk_free_unit(u)
   ELSE
      u = unit
   ENDIF
   !
   IF(present(filename)) &
      open (unit = u, file = filename, status = 'unknown', form = &
      'formatted', iostat = ierr)
   IF(ierr>0) CALL errore('write_upf', 'Cannot open file: '//TRIM(filename),1)
   !
   CALL write_upf_v2(u,upf,meta_info)
   !
   IF(ierr>0) &
      CALL errore('write_upf','Errore while writing pseudopotential file',1)

END SUBROUTINE write_upf


!=----------------------------------------------------------------------------=!
      END MODULE upf_module
!=----------------------------------------------------------------------------=!
#undef TRIM

#ifdef __STANDALONE
   MODULE kinds
      INTEGER, PARAMETER :: DP = selected_real_kind(14,200)
   END MODULE kinds
   !
   MODULE errore_module
   !
   SUBROUTINE errore(sub, msg, ierr)
      character(len=*),intent(IN) :: sub,msg
      integer,intent(IN) :: ierr
      write(*,*) sub,': ',msg,ierr
      stop
   END SUBROUTINE errore
   END MODULE errore_module
#endif
