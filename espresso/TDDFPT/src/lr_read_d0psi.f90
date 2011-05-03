!-----------------------------------------------------------------------
SUBROUTINE lr_read_d0psi()
  !---------------------------------------------------------------------
  ! ... reads in and stores the vectors necessary to
  ! ... restart the Lanczos recursion
  !---------------------------------------------------------------------
  ! Modified by Osman Baris Malcioglu (2009)
  !
#include "f_defs.h"
  !
  USE klist,                ONLY : nks,degauss
  USE io_files,             ONLY : prefix, diropn, tmp_dir, wfc_dir
  USE lr_variables,         ONLY : d0psi, n_ipol,LR_polarization
  USE lr_variables,         ONLY : nwordd0psi, iund0psi
  USE wvfct,                ONLY : nbnd, npwx,et
  USE lr_variables,   ONLY : lr_verbosity,restart
   USE io_global,      ONLY : stdout
 !
  IMPLICIT NONE
  !
  ! local variables
  INTEGER :: ip
  CHARACTER(len=6), EXTERNAL :: int_to_char
  LOGICAL :: exst
  CHARACTER(len=256) :: tmp_dir_saved
  !
  IF (lr_verbosity > 5) THEN
    WRITE(stdout,'("<lr_read_d0psi>")')
  ENDIF
  nwordd0psi = 2 * nbnd * npwx * nks
  !
  ! This is a parallel read, done in wfc_dir
  tmp_dir_saved = tmp_dir
  IF ( wfc_dir /= 'undefined' ) tmp_dir = wfc_dir
  DO ip=1,n_ipol
     !
     IF (n_ipol==1) THEN
       CALL diropn ( iund0psi, 'd0psi.'//trim(int_to_char(LR_polarization)), nwordd0psi, exst)
       IF (.not.exst .and. wfc_dir /= 'undefined') THEN
         WRITE( stdout, '(/5x,"Attempting to read d0psi from outdir instead of wfcdir")' )
         CLOSE( UNIT = iund0psi)
         tmp_dir = tmp_dir_saved
         CALL diropn ( iund0psi, 'd0psi.'//trim(int_to_char(LR_polarization)), nwordd0psi, exst)
         IF (.not.exst) CALL errore('lr_read_d0psi', trim( prefix )//'.d0psi.'//trim(int_to_char(LR_polarization))//' not found',1)
      ENDIF
     ENDIF
     IF (n_ipol==3) THEN
         CALL diropn ( iund0psi, 'd0psi.'//trim(int_to_char(ip)), nwordd0psi, exst)
       IF (.not.exst .and. wfc_dir /= 'undefined') THEN
         WRITE( stdout, '(/5x,"Attempting to read d0psi from outdir instead of wfcdir")' )
         CLOSE( UNIT = iund0psi)
         tmp_dir = tmp_dir_saved
         CALL diropn ( iund0psi, 'd0psi.'//trim(int_to_char(LR_polarization)), nwordd0psi, exst)
         IF (.not.exst) CALL errore('lr_read_d0psi', trim( prefix )//'.d0psi.'//trim(int_to_char(ip))//' not found',1)
       ENDIF
     ENDIF
     !
     CALL davcio(d0psi(1,1,1,ip),nwordd0psi,iund0psi,1,-1)
     !
     CLOSE( UNIT = iund0psi)
     !
  ENDDO
  ! End of file i/o
  tmp_dir = tmp_dir_saved
  !
END SUBROUTINE lr_read_d0psi
!-----------------------------------------------------------------------
