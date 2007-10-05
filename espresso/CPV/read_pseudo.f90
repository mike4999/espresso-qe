
! Copyright (C) 2002-2005 FPMD-CPV groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"

!=----------------------------------------------------------------------------=!
   MODULE read_pseudo_module_fpmd
!=----------------------------------------------------------------------------=!

        USE kinds
        USE io_files,     ONLY: pseudounit
        USE pseudo_types, ONLY: pseudo_upf
        USE pseudo_types, ONLY: nullify_pseudo_upf, deallocate_pseudo_upf
        USE uspp_param,   ONLY: upf

        IMPLICIT NONE

        SAVE

        PRIVATE

        REAL(DP) :: TOLMESH = 1.d-5
        INTEGER   :: nspnl = 0  ! number of non local species

        PUBLIC :: nspnl, readpp
        PUBLIC :: pseudo_filename, check_file_type

!=----------------------------------------------------------------------------=!
   CONTAINS
!=----------------------------------------------------------------------------=!

CHARACTER(LEN=256) FUNCTION pseudo_filename( is )
  USE io_files, ONLY: psfile, pseudo_dir
  INTEGER, INTENT(IN) :: is
  IF (TRIM(pseudo_dir) == ' ' ) then
     pseudo_filename=TRIM(psfile(is))
  ELSE
     pseudo_filename=TRIM(pseudo_dir)//TRIM(psfile(is))
  END IF
  RETURN
END FUNCTION pseudo_filename

!=----------------------------------------------------------------------------=!

INTEGER FUNCTION check_file_type( is )
  !
  ! ...   This subroutine guesses the pseudopotential type
  ! on return:
  ! -1   file is nonexistent
  !  0   file is unknown (guess: old CPV norm-conserving format) 
  !  1   file is *.vdb or *.van  Vanderbilt US pseudopotential
  !  2   file is *.RRKJ3         Andrea's   US new code 
  ! 11   file is NUMERIC (FPMD only) no more supported use UPF
  ! 12   file is ANALYTIC (FPMD only) no more supported use UPF
  ! 20   file is UPF
  !
  INTEGER, INTENT(IN) :: is
  CHARACTER(LEN=256) :: filename
  CHARACTER(LEN=80) :: dummy
  LOGICAL, EXTERNAL :: matches
  INTEGER :: ios, info, l
  LOGICAL :: exst
  !
  info = 0  
  ios  = 0
  filename = pseudo_filename( is )
  !
  INQUIRE ( FILE = TRIM(filename), EXIST=exst )
  IF ( .NOT. exst) THEN
     check_file_type = -1
     return
  END IF
  OPEN( UNIT = pseudounit, FILE = TRIM(filename), STATUS = 'OLD' )
  header_loop: do while (ios == 0)
    read ( pseudounit, *, iostat = ios, err = 200) dummy  
    if (matches ("<PP_HEADER>", dummy) ) then
      info = 20
      exit header_loop
    endif
  enddo header_loop
  200 continue

  IF( info == 0 ) THEN
    REWIND( pseudounit )
    READ ( pseudounit, *, iostat = ios, err = 300)
    dummy = ' ' 
    READ ( pseudounit, *, iostat = ios, err = 300) dummy  
    IF( matches( "NUMERIC", dummy ) ) THEN
      info = 11
    ELSE IF( matches( "ANALYTIC", dummy ) ) THEN
      info = 12
    END IF
  END IF
  300 continue

  CLOSE( pseudounit )

  IF( info == 0 ) THEN
    l = len_trim ( filename )
    if (filename (l - 3:l) .eq.'.vdb'.or.filename (l - 3:l) .eq.'.van') &
      info = 1
    if (l > 5) then
      if (filename (l - 5:l) .eq.'.RRKJ3') info = 2
    end if
  END IF

  check_file_type = info

  RETURN
END FUNCTION check_file_type

!=----------------------------------------------------------------------------=!

SUBROUTINE check_types_order( )
  USE ions_base, ONLY: nsp
  IMPLICIT NONE
  INTEGER :: is, il
  !
  !   With Vanderbilt, only UPF are allowed
  !
  IF( ANY( upf( 1:nsp )%tvanp  ) ) THEN
    CALL errore( ' check_types_order ', &
                 ' vanderbilt pseudo, not yet implemented in FPMD ', 1 )
  END IF
  !
  !   non-local species must be ahead the local one,
  !
  il = 0
  DO is = 1, nsp
    IF ( upf( is )%nbeta == 0 ) THEN
      il = 1
    ELSE IF ( il == 1 ) THEN
      CALL errore( &
           ' check_types_order ', ' Local pseudopotentials should follow non local ones ', 1 )
    END IF
  END DO
  RETURN
END SUBROUTINE check_types_order

!=----------------------------------------------------------------------------=!

REAL(DP) FUNCTION calculate_dx( a, m )
  USE constants, ONLY: eps14
  REAL(DP), INTENT(IN) :: a(:)
  INTEGER, INTENT(IN) :: m 
  INTEGER :: n, nn
  REAL(DP) :: ra, rb 
  n  = MIN( SIZE( a ), m )
  nn = n
  IF( a(1) < eps14 ) THEN
     ra = a(2)
     nn = n - 1
  ELSE
     ra = a(1)
  END IF
  rb = a(n)
  calculate_dx = LOG( rb / ra ) / DBLE( nn - 1 )
  RETURN
END FUNCTION calculate_dx

!=----------------------------------------------------------------------------=!

   SUBROUTINE readpp( xc_type )

     !  this subroutine reads pseudopotential parameters from file
     !
     !  See check_file_type for Allowed format
     !  
     !  
     !  ----------------------------------------------

      USE mp, ONLY: mp_bcast, mp_sum
      USE io_global, ONLY: stdout, ionode, ionode_id
      USE uspp, ONLY : okvan
      USE uspp_param, ONLY : oldvan
      USE atom, ONLY: numeric, nlcc, oc, lchi, nchi
      USE cvan, ONLY: nvb
      use ions_base, only: zv, nsp
      use read_upf_module, only: read_pseudo_upf
      use read_uspp_module, only: readvan, readrrkj
      use control_flags, only: program_name
      use funct, only: get_iexch, get_icorr, get_igcx, get_igcc, set_dft_from_name, dft_is_hybrid
      USE upf_to_internal, ONLY: set_pseudo_upf

      IMPLICIT NONE

      CHARACTER(LEN=*), INTENT(IN) :: xc_type

! ... declare other variables
      CHARACTER(LEN=20)  :: dft_name
      CHARACTER(LEN=20)  :: pottyp
      CHARACTER(LEN=80)  :: error_msg
      CHARACTER(LEN=256) :: filename
      INTEGER            :: is, ierr, info
      INTEGER            :: iexch_, icorr_, igcx_, igcc_

!  end of declarations
!  ----------------------------------------------

      nspnl   = 0  ! number of non local pseudo
      nvb     = 0  ! number of Vanderbilt pseudo
      !
      oc      = 0  ! init atomic wf occupation
      lchi    = 0  ! init atomic wf angular momentum
      nchi    = 0  ! init numbero of atomic wf

      IF( nsp < 1 ) THEN
        CALL errore(' READPOT ',' nsp less than one! ', 1 )
      END IF

      IF( ALLOCATED( upf ) ) THEN
        DO is = 1, SIZE( upf )
          CALL deallocate_pseudo_upf( upf( is ) )
          CALL nullify_pseudo_upf( upf( is ) )
        END DO
        DEALLOCATE( upf )
      END IF

      ALLOCATE( upf( nsp ) )

      ierr = 0
      info = 0
      error_msg = 'none'
     
      IF( ionode ) THEN
        WRITE( stdout,4)
    4   FORMAT(//,3X,'Atomic Pseudopotentials Parameters',/, &
                  3X,'----------------------------------' )
      END IF

      DO is = 1, nsp

        filename = TRIM( pseudo_filename( is ) )
        !
        CALL nullify_pseudo_upf( upf( is ) )
        !
        upf(is)%nlcc  = .FALSE.
        upf(is)%nbeta = 0
        upf(is)%tvanp = .FALSE.
        !
        IF( ionode ) THEN
          WRITE( stdout,6) is, TRIM(filename)
    6     FORMAT( /,3X,'Reading pseudopotential for specie # ',I2,' from file :',/,3X,A)
        END IF

        IF( ionode ) THEN
          info = check_file_type( is )
          SELECT CASE (info)
          CASE (0)
             WRITE( stdout,"(3X,'file type is ',I2,': Old CPV NC PP')") info
          CASE (1)
             WRITE( stdout,"(3X,'file type is ',I2,': Vanderbilt US PP')") info
          CASE (2)
             WRITE( stdout,"(3X,'file type is ',I2,': RRKJ3')") info
          CASE (11)
             WRITE( stdout,"(3X,'file type is ',I2,': Old FPMD Numeric')") info
          CASE (12)
             WRITE( stdout,"(3X,'file type is ',I2,': Old FPMD Analytic')") info
          CASE (20)
             WRITE( stdout, "(3X,'file type is ',I2,': UPF')") info
          END SELECT
        END IF
        CALL mp_bcast( info, ionode_id )
        IF (info == -1) CALL errore ('readpp', &
                            'file '//TRIM(filename)//' not found',is)

        !  Now each processor read the pseudopotential file
  
        ierr = 0

        OPEN( UNIT = pseudounit, FILE = filename, STATUS = 'OLD' )

        numeric(is) = .true.
        !
        ! used only by obsolete "bhs" format of CP
        !
        oldvan(is)  = .false.
        !
        ! used only by obsolete Vanderbilt format with Herman-Skillman grid
        !
        IF( info == 20 ) THEN
           !
           !  ...      Pseudopotential form is UPF
           !
           call read_pseudo_upf(pseudounit, upf(is), ierr)
           !
           IF ( ierr /= 0 ) THEN
             CALL deallocate_pseudo_upf( upf(is) )
           ELSE
             call set_pseudo_upf( is, upf( is ) )
           END IF

        ELSE IF( info == 1 ) THEN

           CALL readvan( pseudounit, is, upf(is) )
           CALL set_pseudo_upf( is, upf( is ) )

        ELSE IF( info == 2 ) THEN

           CALL readrrkj( pseudounit, is, upf(is) )
           CALL set_pseudo_upf( is, upf( is ) )

        ELSE IF( info == 11 ) THEN

          error_msg = ' type no more supported, convert to UPF using fpmd2upf '
          ierr = info

        ELSE IF( info == 12 ) THEN

          error_msg = ' type no more supported, convert to UPF using fpmd2upf '
          ierr = info

        ELSE IF( info == 0 ) THEN

          IF( program_name == 'FPMD' ) THEN
            CALL errore(' readpp ', ' file format not supported ', 1 )
          ELSE
            call readbhs(is,pseudounit)
          END IF

        END IF

        CLOSE( pseudounit )

        CALL mp_sum( ierr )
        IF( ierr /= 0 ) THEN
          CALL errore(' readpseudo ', error_msg, ABS(ierr) )
        END IF

        ! ... Zv = valence charge of the (pseudo-)atom, read from PP files,
        ! ... is set equal to Zp = pseudo-charge of the pseudopotential
        !     (should be moved out from here)
 
        zv(is) = upf(is)%zp

        IF( program_name == 'FPMD' ) THEN
          !
          IF( upf(is)%nbeta > 0 ) nspnl = nspnl + 1
          IF( upf(is)%tvanp  )    nvb   = nvb + 1
          IF( ionode ) THEN
            CALL upf_info( upf(is) )
          END IF
          !
        ELSE IF( program_name == 'CP90' ) THEN
          !
          !     Ultrasoft formats: UPF, AdC, Vanderbilt ("old" and new)
          !     norm-conserving formats: hsc, bhs, UPF
          !
          !     check on input ordering: US first, NC later 
          !
          if(is > 1) then
            if ( (.NOT. upf(is-1)%tvanp) .AND. upf(is)%tvanp ) then
               call errore ('readpp', &
                            'ultrasoft PPs must precede norm-conserving',is)
            endif
          endif
          !
          !     count u-s vanderbilt species 
          !
          if (upf(is)%tvanp) nvb=nvb+1
          !
        END IF

        if ( xc_type /= 'none' ) then
          ! 
          !  DFT xc functional, given from input
          !
          dft_name = TRIM( xc_type )
          CALL set_dft_from_name( dft_name )

          WRITE( stdout, fmt="(/,3X,'Warning XC functionals forced to be: ',A)" ) dft_name
          !
        else
          !
          ! check for consistency of DFT
          !
          if (is == 1) then
            iexch_ = get_iexch()
            icorr_ = get_icorr()
            igcx_ =  get_igcx()
            igcc_ =  get_igcc()
          else
            if ( iexch_ /= get_iexch() .or. icorr_ /= get_icorr() .or. &
                 igcx_  /= get_igcx()  .or. igcc_ /= get_igcc() ) then
               CALL errore( 'readpp','inconsistent DFT read',is)
            end if
          end if
        end if
 
        IF ( dft_is_hybrid() ) &
            CALL errore( 'readpp', 'HYBRID XC not implemented in CPV', 1 )

      END DO

      IF( program_name == 'FPMD' ) THEN
        CALL check_types_order()
      END IF

      okvan = ( nvb > 0 )
      !
      RETURN
      END SUBROUTINE readpp

!=----------------------------------------------------------------------------=!
 
      SUBROUTINE compute_lloc( upf, lloc )
        !  Calculate lloc
        USE pseudo_types, ONLY: pseudo_upf
        IMPLICIT NONE
        TYPE (pseudo_upf), INTENT(IN) :: upf
        INTEGER :: lloc
        INTEGER :: which_lloc( 0 : upf%nbeta )
        INTEGER :: l
        !
        lloc = upf%nbeta
        which_lloc = 0
        DO l = 1, upf%nbeta
           which_lloc( upf%lll( l ) ) = 1
        END DO
        !
        !  the first "l" which is not non-local
        !  is taken as the "l" of the local part of the pseudo
        !
        loop_l: DO l = 0, upf%nbeta
           IF( which_lloc( l ) == 0 ) THEN
              lloc = l
              exit loop_l
           END IF
        END DO loop_l
        !
        RETURN
      END SUBROUTINE

!=----------------------------------------------------------------------------=!

      SUBROUTINE upf_info( upf )
        USE pseudo_types, ONLY: pseudo_upf
        USE io_global, ONLY: stdout

        TYPE (pseudo_upf), INTENT(IN) :: upf
        INTEGER   :: in1, in2, in3, in4, m, il, ib, l, i
        INTEGER   :: lloc

        WRITE( stdout, * ) 

        CALL compute_lloc( upf, lloc )

        IF (upf%nbeta > 0) THEN
          WRITE( stdout,10) upf%typ
          WRITE( stdout,50) lloc   
          WRITE( stdout,60) (upf%lll(l),l=1,upf%nbeta)
        ELSE
! ...     A local pseudopotential has been read.
          WRITE( stdout,11) upf%typ
          WRITE( stdout,50) lloc 
        END IF
        IF( upf%nlcc ) THEN
          WRITE( stdout,12)
        END IF

   10   FORMAT(   3X,'Type is ',A10,' and NONLOCAL. ')
  107   FORMAT(   3X,'Mixed reference potential:')
  106   FORMAT(   3X,'  L     :',3(9X,i1))
  105   FORMAT(   3X,'  Weight:',3(2X,F8.5))
   50   FORMAT(   3X,'Local component is ..... : ',I3)
   60   FORMAT(   3X,'Non local components are : ',4I3)
   11   FORMAT(   3X,'Type is ',A10,' and LOCAL. ')
   12   FORMAT(   3X,'Using non local core corcorrections for this pseudo')
   20   FORMAT(   3X,'Pseudo charge : ',F8.3)

        WRITE( stdout,20) upf%zp

        WRITE( stdout,131) upf%nbeta + 1, upf%mesh
        in1=1
        in2=upf%mesh/4
        in3=upf%mesh/2
        in4=upf%mesh
        WRITE( stdout,132)
        WRITE( stdout,120) in1,upf%r(in1),upf%vloc(in1)/2.0,(upf%beta(in1,m)/2.0,m=1,upf%nbeta)
        WRITE( stdout,120) in2,upf%r(in2),upf%vloc(in2)/2.0,(upf%beta(in2,m)/2.0,m=1,upf%nbeta)
        WRITE( stdout,120) in3,upf%r(in3),upf%vloc(in3)/2.0,(upf%beta(in3,m)/2.0,m=1,upf%nbeta)
        WRITE( stdout,120) in4,upf%r(in4),upf%vloc(in4)/2.0,(upf%beta(in4,m)/2.0,m=1,upf%nbeta)
  131   FORMAT(/, 3X,'Pseudopotentials Grid    : Channels = ',I2,&
                   ', Mesh = ',I5,/,30X)
  132   FORMAT(   3X,'point    radius        vloc         ( vnl - vloc )')
  120   FORMAT(I8,E14.6,5E14.6)


        IF( upf%nwfc > 0 .AND. upf%mesh > 0 ) THEN
          WRITE( stdout,141) upf%nwfc, upf%mesh
          in1=1
          in2=upf%mesh/4
          in3=upf%mesh/2
          in4=upf%mesh
          WRITE( stdout,145) (upf%oc(i),i=1,upf%nwfc)
          WRITE( stdout,142)
          WRITE( stdout,120) in1,upf%r(in1),(upf%chi(in1,m),m=1,upf%nwfc)
          WRITE( stdout,120) in2,upf%r(in2),(upf%chi(in2,m),m=1,upf%nwfc)
          WRITE( stdout,120) in3,upf%r(in3),(upf%chi(in3,m),m=1,upf%nwfc)
          WRITE( stdout,120) in4,upf%r(in4),(upf%chi(in4,m),m=1,upf%nwfc)
        END IF

  141   FORMAT(/, 3X,'Atomic wavefunction Grid : Channels = ',I2,&
                   ', Mesh = ',I5,/,30X)
  142   FORMAT(   3X,'point      radius        wavefunction')
  145   FORMAT(   3X,'Channels occupation number : ',5F10.4)

        IF( upf%nlcc ) THEN
          WRITE( stdout,151) upf%mesh
          in1 = 1
          in2 = upf%mesh / 4
          in3 = upf%mesh / 2
          in4 = upf%mesh
          WRITE( stdout,152)
          WRITE( stdout,120) in1,upf%r(in1),upf%rho_atc(in1)
          WRITE( stdout,120) in2,upf%r(in2),upf%rho_atc(in2)
          WRITE( stdout,120) in3,upf%r(in3),upf%rho_atc(in3)
          WRITE( stdout,120) in4,upf%r(in4),upf%rho_atc(in4)
        END IF

  151   FORMAT(/, 3X,'Core correction Grid     : Mesh = ',I5)
  152   FORMAT(   3X,'point      radius        rho core')

        RETURN
      END SUBROUTINE upf_info


!=----------------------------------------------------------------------------=!
   END MODULE read_pseudo_module_fpmd
!=----------------------------------------------------------------------------=!
!
!
!
!     
!---------------------------------------------------------------------
      subroutine readbhs( is, iunps )
!---------------------------------------------------------------------
!
      use atom, only: rgrid, nlcc, rho_atc, numeric
      use uspp_param, only: zp, betar, dion, vloc_at, lll, nbeta, kkbeta
      use bhs, only: rcl, rc2, bl, al, wrc1, lloc, wrc2, rc1
      use funct, only: set_dft_from_name, dft_is_hybrid
      use io_global, only: stdout

!
      implicit none
!
      integer is, iunps
!
      integer meshp, ir, ib, il, i, j, jj
      real(8), allocatable:: fint(:), vnl(:)
      real(8) rdum, alpha, z, zval, cmesh, cmeshp, exfact
      character(len=20) :: dft_name
!
! nlcc is unfortunately not read from file
!
      numeric(is) = .false.
      nlcc(is)=.false.
      read(iunps,*) z,zp(is),nbeta(is),lloc(is),exfact
      if (zp(is) < 1 .or. zp(is) > 100 ) then
         call errore('readbhs','wrong potential read',15)
      endif

      call dftname_cp (nint(exfact), dft_name)
      call set_dft_from_name( dft_name )
      IF ( dft_is_hybrid() ) &
         CALL errore( 'readbhs', 'HYBRID XC not implemented in CPV', 1 )
!
      if(lloc(is).eq.2)then 
         lll(1,is)=0
         lll(2,is)=1
      else if(lloc(is).ne.2) then
         call errore('readbhs','kb-ization for lloc=2 only',10)
      endif
!     
!     see eqs. (2.21) and (2.22) of bhs, prb 26, 4199 (1982).
!
!     wrc1  =c_core(1)
!     wrc2  =c_core(2)
!     rc1   =alpha_core(1)
!     rc2   =alpha_core(2)
!     al(i) =a(i)          i=1,3
!     bl(i) =a(i+3)        i=1,3
!     rcl(i)=alpha(i)      i=1,3 
!
!     ------------------------------------------------------------------
!     pp parameters are read from file iunps
!     bhs 's coefficients have been turned into lengths
!     ------------------------------------------------------------------
      read(iunps,*) wrc1(is),rc1(is),wrc2(is),rc2(is)  
      rc1(is)=1.0d0/sqrt(rc1(is))
      rc2(is)=1.0d0/sqrt(rc2(is))
      do il=1,3
         do ib=1,3
            read(iunps,*) rcl(ib,is,il),al(ib,is,il),bl(ib,is,il)
            rcl(ib,is,il)=1.0d0/sqrt(rcl(ib,is,il))
         end do
      end do
!
!     ------------------------------------------------------------------
!     wavefunctions are read from file iunps
!     ------------------------------------------------------------------
      do il=1,nbeta(is)
         read(iunps,*) rgrid(is)%mesh,cmesh
!
! kkbeta is for compatibility with Vanderbilt PP
!
         kkbeta(is)=rgrid(is)%mesh
         do j=1,rgrid(is)%mesh
            read(iunps,*) jj,rgrid(is)%r(j),betar(j,il,is)
         end do
      end do
!     
!     ------------------------------------------------------------------
!     core charge is read from unit 15
!     ------------------------------------------------------------------
!
      if(nlcc(is)) then
         read(15,*) meshp,cmeshp
         if ( meshp.ne.rgrid(is)%mesh .or. cmeshp.ne.cmesh ) then
            call errore('readbhs','core charge mesh mismatch',is)
         endif
         do ir=1,rgrid(is)%mesh
            read(15,*) rdum, rho_atc(ir,is)
         end do
      endif
!
!  rab(i) is the derivative of the radial mesh
!
      do ir=1,rgrid(is)%mesh
         rgrid(is)%rab(ir)=rgrid(is)%r(ir) * log(cmesh)
      end do
!
!     ------------------------------------------------------------------
!     local potential 
!     ------------------------------------------------------------------
      lloc(is)=lloc(is)+1
!
! NB: the following is NOT the local potential: the -ze^2/r term is missing
!
      do ir=1,rgrid(is)%mesh
         vloc_at(ir,is)=0.d0
         do i=1,3
            vloc_at(ir,is) = vloc_at(ir,is)                             &
     &            +(al(i,is,lloc(is))+bl(i,is,lloc(is))*rgrid(is)%r(ir)**2)    &
     &            *exp(-(rgrid(is)%r(ir)/rcl(i,is,lloc(is)))**2)
         end do
      end do
!
!     ------------------------------------------------------------------
!     nonlocal potentials: kleinman-bylander form 
!     (1) definition of betar   (2) calculation of dion 
!     ------------------------------------------------------------------
      allocate(fint(rgrid(is)%mesh), vnl(rgrid(is)%mesh))
      do il=1,nbeta(is)
         do ir=1,rgrid(is)%mesh
            vnl(ir)=0.d0
            do i=1,3
               vnl(ir) = vnl(ir) + (al(i,is,il)+bl(i,is,il)*rgrid(is)%r(ir)**2)&
     &                    * exp(-(rgrid(is)%r(ir)/rcl(i,is,il))**2)
            end do
            vnl(ir) = vnl(ir) - vloc_at(ir,is)
            fint(ir)= betar(ir,il,is)**2*vnl(ir)
            betar(ir,il,is)=vnl(ir)*betar(ir,il,is)
         end do
         call simpson_cp90(rgrid(is)%mesh,fint,rgrid(is)%rab,dion(il,il,is))
         dion(il,il,is) = 1.0d0/dion(il,il,is)
      end do
      deallocate(vnl, fint)
!     
!     ------------------------------------------------------------------
!     output: pp info 
!     ------------------------------------------------------------------
      WRITE( stdout,3000) z,zp(is)
3000  format(2x,'bhs pp for z=',f3.0,2x,'zv=',f3.0)

      WRITE( stdout,'(2x,a20)') dft_name
      WRITE( stdout,3002) lloc(is)-1 
3002  format(2x,'   local angular momentum: l=',i3)
      WRITE( stdout,3005) nbeta(is)
3005  format(2x,'number of nl ang. mom. nbeta=',i3)
      do il=1,nbeta(is)
         WRITE( stdout,3010) lll(il,is)
3010     format(2x,'nonlocal angular momentum: l=',i3)
      end do
      WRITE( stdout,3030) 
3030  format(2x,'pseudopotential parameters:')
      WRITE( stdout,3035) wrc1(is),1.0d0/rc1(is)**2
3035  format(2x,'core:',2x,'c1_c=',f7.4,' alpha1_c=',f7.4)
      WRITE( stdout,3036) wrc2(is),1.0d0/rc2(is)**2
3036  format(2x,'     ',2x,'c2_c=',f7.4,' alpha2_c=',f7.4)
      WRITE( stdout,3038)
3038  format(2x,'other table parameters:')
      do il=1,3
         WRITE( stdout,3040) il-1
3040     format(2x,'l=',i3)
         do i =1,3
            alpha=1.0d0/rcl(i,is,il)**2
            WRITE( stdout,3050) i,alpha,i,al(i,is,il),i+3,bl(i,is,il)
         end do
      end do
3050  format(2x,'alpha',i1,'=',f6.2,'  a',i1,'=',f16.7,                 &
     &           '  a',i1,'=',f16.7)
      WRITE( stdout,*)
!     
      return
      end subroutine readbhs
