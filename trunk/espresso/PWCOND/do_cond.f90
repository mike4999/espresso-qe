!
! Copyright (C) 2003 A. Smogunov 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
SUBROUTINE do_cond(nodenumber)
!  
!   This is the main driver of the pwcond.x program.
!   It calculates the complex band structure, solves the
!   scattering problem and calculates the transmission coefficient. 
!
  USE ions_base,  ONLY : nat, ityp, ntyp => nsp, tau
  USE pwcom
  USE cond 
  USE io_files 
  USE io_global, ONLY : ionode, ionode_id

  USE mp

  IMPLICIT NONE

  CHARACTER(len=3) nodenumber
  REAL(kind=DP) :: wtot
  INTEGER :: ik, ien, ios 

  NAMELIST /inputcond/ outdir, prefixt, prefixl, prefixs, prefixr,     &
                       band_file, tran_file, save_file, fil_loc,       &
                       lwrite_loc, lread_loc, lwrite_cond, lread_cond, & 
                       orbj_in,orbj_fin,ikind,iofspin,llocal,llapack,  & 
                       bdl, bds, bdr, nz1, energy0, denergy, ecut2d,   &
                       ewind, epsproj, delgep, cutplot
                                                                               
  CHARACTER (LEN=80)  :: input_file
  INTEGER             :: nargs, iiarg, ierr, ILEN
  INTEGER, EXTERNAL   :: iargc

  nd_nmbr=nodenumber
  CALL init_clocks(.TRUE.)
  CALL start_clock('PWCOND')
  CALL start_clock('init')
!
!   set default values for variables in namelist
!                                             
  outdir = './'
  prefixt = ' '
  prefixl = ' '
  prefixs = ' '
  prefixr = ' '
  band_file = ' '
  tran_file = ' '
  save_file = ' ' 
  fil_loc = ' '
  lwrite_loc = .FALSE.
  lread_loc = .FALSE.
  lwrite_cond = .FALSE.
  lread_cond  = .FALSE.
  orbj_in = 0
  orbj_fin = 0
  iofspin = 1
  ikind = 0
  bdl = 0.d0
  bds = 0.d0
  bdr = 0.d0
  nz1 = 11
  energy0 = 0.d0
  denergy = 0.d0
  ecut2d = 0.d0
  ewind = 1.d0
  llocal = .FALSE.
  llapack = .TRUE.
  epsproj = 1.d-3
  delgep = 5.d-10
  cutplot = 2.d0

  IF ( ionode )  THEN
     !
     ! ... Input from file ?
     !
     nargs = iargc()
     !
     DO iiarg = 1, ( nargs - 1 )
        !
        CALL getarg( iiarg, input_file )
        IF ( TRIM( input_file ) == '-input' .OR. &
             TRIM( input_file ) == '-inp'   .OR. &
             TRIM( input_file ) == '-in' ) THEN
           !
           CALL getarg( ( iiarg + 1 ) , input_file )
           OPEN ( UNIT = 5, FILE = input_file, FORM = 'FORMATTED', &
                STATUS = 'OLD', IOSTAT = ierr )
           CALL errore( 'iosys', 'input file ' // TRIM( input_file ) // &
                & ' not found' , ierr )
           !
        END IF
        !
     END DO
     !
     !     reading the namelist inputpp
     !
     READ (5, inputcond, err=200, iostat=ios )
200  CALL errore ('do_cond','reading inputcond namelist',ABS(ios))
     tmp_dir=TRIM(outdir)
     !
     !     Reading 2D k-point
     READ(5, *, err=300, iostat=ios ) nkpts
     ALLOCATE( xyk(2,nkpts) )
     ALLOCATE( wkpt(nkpts) )
     wtot = 0.d0
     DO ik = 1, nkpts
        READ(5, *, err=300, iostat=ios) xyk(1,ik), xyk(2,ik), wkpt(ik)
        wtot = wtot + wkpt(ik)
     ENDDO
     DO ik = 1, nkpts
        wkpt(ik) = wkpt(ik)/wtot
     ENDDO
300  CALL errore ('do_cond','2D k-point',ABS(ios))

     !
     !     To form the array of energies for calculation
     !
     READ(5, *, err=400, iostat=ios ) nenergy
     ALLOCATE( earr(nenergy) )
     ALLOCATE( tran_tot(nenergy) )
     IF(ABS(denergy).LE.1.d-8) THEN
        !   the list of energies is read
        DO ien = 1, nenergy
           READ(5, *, err=400, iostat=ios) earr(ien)
        ENDDO
     ELSE
        !   the array of energies is automatically formed
        DO ien = 1, nenergy
           earr(ien) = energy0 + (ien-1)*denergy
           tran_tot(ien) = 0.d0 
        ENDDO
     ENDIF
400  CALL errore ('do_cond','reading energy list',ABS(ios))
     !
  END IF

!
! ... Broadcast variables
!
  CALL mp_bcast( tmp_dir, ionode_id )
  CALL mp_bcast( prefixt, ionode_id )
  CALL mp_bcast( prefixl, ionode_id )
  CALL mp_bcast( prefixs, ionode_id )
  CALL mp_bcast( prefixr, ionode_id )
  CALL mp_bcast( band_file, ionode_id )
  CALL mp_bcast( tran_file, ionode_id )
  CALL mp_bcast( fil_loc, ionode_id )
  CALL mp_bcast( save_file, ionode_id )
  CALL mp_bcast( lwrite_loc, ionode_id )
  CALL mp_bcast( lread_loc, ionode_id )
  CALL mp_bcast( lwrite_cond, ionode_id )
  CALL mp_bcast( lread_cond, ionode_id )
  CALL mp_bcast( ikind, ionode_id )
  CALL mp_bcast( iofspin, ionode_id )
  CALL mp_bcast( orbj_in, ionode_id )
  CALL mp_bcast( orbj_fin, ionode_id )
  CALL mp_bcast( llocal, ionode_id )
  CALL mp_bcast( bdl, ionode_id )
  CALL mp_bcast( bds, ionode_id )
  CALL mp_bcast( bdr, ionode_id )
  CALL mp_bcast( nz1, ionode_id )
  CALL mp_bcast( energy0, ionode_id )
  CALL mp_bcast( denergy, ionode_id )
  CALL mp_bcast( ecut2d, ionode_id )
  CALL mp_bcast( ewind, ionode_id )
  CALL mp_bcast( epsproj, ionode_id )
  CALL mp_bcast( delgep, ionode_id )
  CALL mp_bcast( cutplot, ionode_id )
  CALL mp_bcast( llapack, ionode_id )
  CALL mp_bcast( nkpts, ionode_id )
  CALL mp_bcast( nenergy, ionode_id )

  IF ( .NOT. ionode ) THEN
     ALLOCATE( xyk(2,nkpts) )
     ALLOCATE( wkpt(nkpts) )
     ALLOCATE( earr(nenergy) )
     ALLOCATE( tran_tot(nenergy) )
  ENDIF
  CALL mp_bcast( xyk, ionode_id )
  CALL mp_bcast( wkpt, ionode_id )
  CALL mp_bcast( earr, ionode_id )
  CALL mp_bcast( tran_tot, ionode_id )


!
! Now allocate space for pwscf variables, read and check them.
!
  
IF (lread_cond) THEN
  call save_cond (.false.,1,efl,nrzl,nocrosl,noinsl,   &
                  norbl,rl,rabl,betarl)
  if(ikind.eq.1) then
    call save_cond (.false.,2,efs,nrzs,-1,      &
                             noinss,norbs,rs,rabs,betars)
    norbr = norbl
    nocrosr = nocrosl
    noinsr = noinsl
  endif
  if(ikind.eq.2) then
    call save_cond (.false.,2,efs,nrzs,-1,      &
                             noinss,norbs,rs,rabs,betars)

    call save_cond (.false.,3,efr,nrzr,nocrosr,&
                             noinsr,norbr,rr,rabr,betarr)
  endif
ELSE
  IF (prefixt.ne.' ') then
    prefix = prefixt
    call read_file
    call init_us_1
    call newd
    IF (ikind.eq.0) then
      CALL init_cond(1,'t')
    ELSEIF (ikind.eq.1) then
      CALL init_cond(2,'t')
    ELSEIF (ikind.eq.2) then
      CALL init_cond(3,'t')
    ENDIF
    CALL clean_pw(.true.)
  ENDIF
  IF (prefixl.ne.' ') then
    prefix = prefixl
    call read_file
    call init_us_1
    call newd
    CALL init_cond(1,'l')
    CALL clean_pw(.true.)
  ENDIF
  IF (prefixs.ne.' ') then
    prefix = prefixs
    call read_file
    call init_us_1
    call newd
    CALL init_cond(1,'s')
    CALL clean_pw(.true.)
  ENDIF
  IF (prefixr.ne.' ') then
    prefix = prefixr
    call read_file
    call init_us_1
    call newd
    CALL init_cond(1,'r')
    CALL clean_pw(.true.)
  ENDIF
ENDIF

IF (lwrite_cond) then
  call save_cond (.true.,1,efl,nrzl,nocrosl,noinsl,         &
                  norbl,rl,rabl,betarl)
  if(ikind.gt.0) call save_cond (.true.,2,efs,nrzs,-1,      &
                             noinss,norbs,rs,rabs,betars)
  if(ikind.gt.1) call save_cond (.true.,3,efr,nrzr,nocrosr,&
                             noinsr,norbr,rr,rabr,betarr)
endif

  call cond_out

  CALL stop_clock('init')

  IF (llocal) &
  CALL local_set(nocrosl,noinsl,norbl,noinss,norbs,nocrosr,noinsr,norbr)

  do ik=1, nkpts

    CALL init_gper(ik)

    call local 

    do ien=1, nenergy
      eryd = earr(ien)/rytoev + efl
      call form_zk(n2d, nrzpl, zkrl, zkl, eryd, tpiba)
      call scatter_forw(nrzl, nrzpl, zl, psiperl, zkl, norbl,     &
                        tblml, crosl, taunewl, rl, rabl, betarl) 
      call compbs(1, nocrosl, norbl, nchanl, kvall, kfunl, kfundl, &
                  kintl, kcoefl) 

      IF (ikind.EQ.2) THEN
        eryd = earr(ien)/rytoev + efr
        call form_zk(n2d, nrzpr, zkrr, zkr, eryd, tpiba)
        call scatter_forw(nrzr, nrzpr, zr, psiperr, zkr, norbr,    &
                          tblmr, crosr, taunewr, rr, rabr, betarr)
        call compbs(0, nocrosr, norbr, nchanr, kvalr, kfunr, kfundr,&
                     kintr, kcoefr) 
      ENDIF

      call summary_band(ik,ien)

      IF (ikind.NE.0) THEN
        eryd = earr(ien)/rytoev + efs
        call form_zk(n2d, nrzps, zkrs, zks, eryd, tpiba)
        call scatter_forw(nrzs, nrzps, zs, psipers, zks, norbs,    &
                          tblms, cross, taunews, rs, rabs, betars)

        write(6,*) 'to transmit'

        call transmit(ik, ien)
      endif


    enddo
   call free_mem
  enddo

  IF(ikind.GT.0.AND.tran_file.NE.' ')  &
   CALL summary_tran()

  CALL print_clock_pwcond()
  CALL stop_clock('PWCOND')

  return

END SUBROUTINE do_cond


