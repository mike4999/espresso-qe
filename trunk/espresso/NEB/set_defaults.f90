
! Copyright (C) 2010 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!----------------------------------------------------------------------------
SUBROUTINE set_engine_input_defaults()
  !-----------------------------------------------------------------------------
  !
  USE input_parameters, ONLY : &
                                 tapos, tkpoints, taspc, twannier, &
                                 tconstr, tforces, tocc, tsetnfi, &
                                 tksout, tionvel, tesr, tdipole, &
                                 tcell
  !
  tapos = .false.
  tkpoints = .false.
  taspc = .false.
  twannier = .false.
  tconstr = .false.
  tforces = .false.
  tocc = .false.
  tsetnfi = .false.
  tksout = .false.
  tionvel = .false.
  tesr = .false.
  tdipole = .false.
  tcell = .false.
  !
END SUBROUTINE set_engine_input_defaults
!
!----------------------------------------------------------------------------
SUBROUTINE set_engine_io_units()
  !-----------------------------------------------------------------------------
  !
  USE io_global, ONLY : stdout
  USE io_files,  ONLY : find_free_unit
  !
  stdout = find_free_unit()
  write(0,*) "engine output set to unit: ", stdout 
  !
  !
END SUBROUTINE set_engine_io_units
!
