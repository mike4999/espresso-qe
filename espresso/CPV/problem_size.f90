!
! Copyright (C) 2002 FPMD group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

  MODULE problem_size

     IMPLICIT NONE
     SAVE
     PRIVATE
     PUBLIC :: cpsizes

  CONTAINS

      SUBROUTINE CPSIZES(NPROC) 
                                                                        
      USE kinds
      USE parameters
      use fft 
      use ions_base, only: nsp, nax 
      use electrons_module, only: electrons_info
      use brillouin, only: get_kpoints_number
      use reciprocal_vectors, only: ngwx, ngmx, ngmt
      use pseudopotential, only: lmax, ngh 
      use exchange_correlation, only: narray 
      USE io_global, ONLY: ionode
      USE io_global, ONLY: stdout
      USE fft_base, ONLY: dfftp, dffts
 
      implicit none 
                                                                        
      integer NGWXM_EMP,ngh_EMP,NSAX_EMP,NCHAINX, NPROC 
      integer NNR1X, NNR2X,NNR3X,LM1X 
      integer NR1X, NR2X, NR3X, nr1_l,nr2_l,nr3_l
      integer NSAX,NAMX,NAFX 
      integer nbyte 
      integer nbyte_alloc 
      integer n_emp, itmp 
      integer nel,nx, nspin, nk
      integer :: csiz = 1
      integer :: lsiz = 4
      integer :: isiz = 4
      integer :: dsiz = 8
      integer :: zsiz = 16
                                                                        
      CALL electrons_info(nel, nx, n_emp, nspin)

      nr1_l = dfftp%nr1x
      nr2_l = dfftp%nr2x
      nr3_l = dfftp%npl

      nr1x  = dfftp%nr1x
      nr2x  = dfftp%nr2x
      nr3x  = dfftp%nr3x

      nk = get_kpoints_number()

      ngh_EMP = ngh 
      NGWXM_EMP = ngwx 
      NNR1X  = 2*NR1X-1 
      NNR2X  = 2*NR2X-1 
      NNR3X  = 2*NR3X-1 
      NSAX   = NSP*NAX 
      NAMX   = NSAX 
      NAFX   = NSAX 
      LM1X   = LMAX -1 
      nbyte         = 0 
      nbyte_alloc   = 0 
      NSAX_EMP = NSAX 
      NCHAINX = 1 
                                                                        
                                                                        
! ... Atoms type
      nbyte = nbyte + 3 * ( 4 * isiz + nsx * isiz + 4 * csiz + 2 * ( nsx * isiz ) + nsx * dsiz + &
        3 * ( 3 * dsiz * natx ) + 3 * lsiz * natx + isiz * natx + 3 * lsiz + nsx * dsiz + dsiz )

! ... HG_L mill gx_L
      nbyte = nbyte + 8 * ngmx 
      nbyte = nbyte + 3 * 8 * ngmx
      nbyte = nbyte + 8 * ngmx * 3 

! ... FNL
      nbyte = nbyte + 8 * NSAX * NX * ngh * nspin

! ... WNL RHOPS VPS GNL RW RPS VR
      nbyte = nbyte + 8*ndmx*NSP*3 
      nbyte = nbyte + 8*ngwx*ngh*NSP 
      nbyte = nbyte + 8*NSP*ngmx 
      nbyte = nbyte + 8*NSP*ngmx 
      nbyte = nbyte + 8*ndmx*NSP 
      nbyte = nbyte + 8*ndmx*NSP*LM1X 
      nbyte = nbyte + 8*ndmx*NSP*LM1X 

! ... C0 CM CP C_EMP
      nbyte = nbyte + 16 * ngwx * nx * nspin * nk
      nbyte = nbyte + 3 * 16 * ngwx * nx * nspin * nk

! ... ei1 ei2 ei3, eigr, sfac
      nbyte = nbyte + 3 * 16 * NNR1X * NAX * NSP 
      nbyte = nbyte + 16 * ngwx * nax * nsp 
      nbyte = nbyte + 16 * ngmx * nsp

! ... rhoe and vpot (nr1_l, nr2_l, nr3_l, nspin)
      nbyte = nbyte + ( 8 + 16 )*NR1_L*NR2_L*NR3_L*nspin 

! ... TEMPORARY ALLOCATED MEMORY
                                                                        
      itmp = 2 * 8 * ngmt 
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 

! ... ortho                                                             
      itmp = 8 * ( 8*NX*NX+2*NX ) 
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 

! ... nlsm1 e nlsm2                                                     
      itmp = 8 * 2*ngwx*NSAX + 8*NSAX*NX*ngh
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 
! ... eigsnew                                                           
      itmp = 8 * ( 3*NX + NX*NX + N_EMP + NSAX_EMP*N_EMP*ngh_EMP       &
     &           + NX*(NX+1)/2 + N_EMP*N_EMP + N_EMP + NX )             
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 
! ... phfac                                                             
      itmp = 8 * 2* ( 2*NR1X + 2*NR2X + 2*NR3X ) 
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 
! ... pvofrho & pstress                                                 
      itmp = 8 * (2*3*NAX*NSP+3*NAX*NSP+NR1_L*NR2_L*NR3_L*8 +           &
     &       NSAX*NX*ngh*6 + 6*ngmx + ndmx + 6*ngwx +               &
     &       ngwx*ngh*NSP + 2*ngwx*NSAX)                             
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 
! ... formf                                                             
      itmp = 8 * 3 * ndmx + 8 * 3 * ngmx 
      if(itmp.gt.nbyte_alloc) nbyte_alloc = itmp 
                                                                        
      IF(ionode) THEN
        WRITE( stdout,10) nbyte + nbyte_alloc 
      END IF
                                                                        
   10 FORMAT(//,3X,'Estimated Sizes of the problem',/                   &
     &         ,3X,'------------------------------',/                   &
     &         ,3X,'dimension of the problem (byte/pe) : ',I12)
                                                                        
      return 
      END  SUBROUTINE 

  END MODULE
