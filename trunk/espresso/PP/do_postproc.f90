!
! Copyright (C) 2001-2003 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine do_postproc (nodenumber)
  !-----------------------------------------------------------------------
  !
  !    This routine reads the output file produced by pw.x
  !    extracts and calculates the desired quantity (rho, V, ...)
  !    writes it to a file for further processing or plotting
  !
  !    DESCRIPTION of the INPUT: see file pwdocs/INPUT_PP
  !
  use pwcom
  use io_files, only: tmp_dir, nd_nmbr, prefix
#ifdef __PARA
  use para, only: me
  use mp
#endif
  implicit none
  character(len=3)  :: nodenumber
  character(len=80) :: filplot

  integer :: n_atom_wfc, plot_num, kpoint, kband, spin_component, ios
  logical :: stm_wfc_matching, lsign
  integer :: ionode_id = 0 

  real(kind=DP) :: emin, emax, sample_bias, z, dz
  ! directory for temporary files
  character(len=256) :: outdir

  namelist / inputpp / outdir, prefix, plot_num, stm_wfc_matching, &
       sample_bias, spin_component, z, dz, emin, emax, kpoint, kband,&
       filplot, lsign
  !
  nd_nmbr = nodenumber
  !
  !   set default values for variables in namelist
  !
  prefix = 'pwscf'
  outdir = './'
  filplot = 'pp.out' 
  plot_num = 0
  spin_component = 0
  sample_bias = 0.01d0
  z = 1.d0
  dz = 0.05d0
  stm_wfc_matching = .true.
  lsign=.false.
  emin = - 999.0d0
  emax = ef*13.6058d0
  !
  !     reading the namelist inputpp
  !
#ifdef __PARA
  if (me == 1)  then
#endif
  read (5, inputpp, err = 200, iostat = ios)
200 call errore ('postproc', 'reading inputpp namelist', abs (ios) )
  tmp_dir = trim(outdir)
#ifdef __PARA
  end if
  !
  ! ... Broadcast variables
  !
  CALL mp_bcast( tmp_dir, ionode_id )
  CALL mp_bcast( prefix, ionode_id )
  CALL mp_bcast( plot_num, ionode_id )
  CALL mp_bcast( stm_wfc_matching, ionode_id )
  CALL mp_bcast( sample_bias, ionode_id )
  CALL mp_bcast( spin_component, ionode_id )
  CALL mp_bcast( z, ionode_id )
  CALL mp_bcast( dz, ionode_id )
  CALL mp_bcast( emin, ionode_id )
  CALL mp_bcast( emax, ionode_id )
  CALL mp_bcast( kpoint, ionode_id )
  CALL mp_bcast( kband, ionode_id )
  CALL mp_bcast( kpoint, ionode_id )
  CALL mp_bcast( filplot, ionode_id )
  CALL mp_bcast( lsign, ionode_id )
#endif
  !     Check of namelist variables
  !
  if (plot_num < 0 .or. plot_num > 12) call errore ('postproc', &
          'Wrong plot_num', abs (plot_num) )

  if ( (plot_num == 0 .or. plot_num == 1) .and.  &
       (spin_component < 0 .or. spin_component > 2) ) call errore &
         ('postproc', 'wrong value of spin_component', 1)

  if (plot_num == 10) then
     emin = emin / 13.6058d0
     emax = emax / 13.6058d0
  end if

  !
  !   Now allocate space for pwscf variables, read and check them.
  !
  call read_file
  call openfil
  call struc_fact (nat, tau, ntyp, ityp, ngm, g, bg, nr1, nr2, nr3, &
       strf, eigts1, eigts2, eigts3)
  call init_us_1
  !
  !   Now do whatever you want
  !
  call punch_plot (filplot, plot_num, sample_bias, z, dz, &
       stm_wfc_matching, emin, emax, kpoint, kband, spin_component, lsign)

  return
end subroutine do_postproc
