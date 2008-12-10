!
! Copyright (C) 2001-2007 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
#include "f_defs.h"
!
!-----------------------------------------------------------------------
subroutine solve_linter (irr, imode0, npe, drhoscf)
  !-----------------------------------------------------------------------
  !
  !    Driver routine for the solution of the linear system which
  !    defines the change of the wavefunction due to a lattice distorsion
  !    It performs the following tasks:
  !     a) computes the bare potential term Delta V | psi > 
  !        and an additional term in the case of US pseudopotentials
  !     b) adds to it the screening term Delta V_{SCF} | psi >
  !     c) applies P_c^+ (orthogonalization to valence states)
  !     d) calls cgsolve_all to solve the linear system
  !     e) computes Delta rho, Delta V_{SCF} and symmetrizes them
  !

  USE kinds,                ONLY : DP
  USE ions_base,            ONLY : nat, ntyp => nsp, ityp
  USE io_global,            ONLY : stdout, ionode
  USE io_files,             ONLY : prefix, iunigk
  USE check_stop,           ONLY : check_stop_now
  USE wavefunctions_module, ONLY : evc
  USE constants,            ONLY : degspin
  USE cell_base,            ONLY : tpiba2
  USE ener,                 ONLY : ef
  USE klist,                ONLY : lgauss, degauss, ngauss, xk, wk
  USE gvect,                ONLY : nrxx, g
  USE gsmooth,              ONLY : doublegrid, nrxxs
  USE becmod,               ONLY : becp, becp_nc, calbec
  USE lsda_mod,             ONLY : lsda, nspin, current_spin, isk
  USE spin_orb,             ONLY : domag
  USE wvfct,                ONLY : nbnd, npw, npwx, igk,g2kin,  et
  USE scf,                  ONLY : rho
  USE uspp,                 ONLY : okvan, vkb
  USE uspp_param,           ONLY : upf, nhm, nh
  USE noncollin_module,     ONLY : noncolin, npol
  USE paw_variables,        ONLY : okpaw
  USE paw_onecenter,        ONLY : paw_dpotential, paw_dusymmetrize, &
                                   paw_dumqsymmetrize
  USE control_ph,           ONLY : rec_code, niter_ph, nmix_ph, elph, tr2_ph, &
                                   alpha_pv, lgamma, lgamma_gamma, convt, &
                                   nbnd_occ, alpha_mix, ldisp, reduce_io, &
                                   recover, where_rec
  USE nlcc_ph,              ONLY : nlcc_any
  USE units_ph,             ONLY : iudrho, lrdrho, iudwf, lrdwf, iubar, lrbar, &
                                   iuwfc, lrwfc, iunrec, iudvscf, &
                                   this_pcxpsi_is_on_file
  USE output,               ONLY : fildrho, fildvscf
  USE phus,                 ONLY : int1, int2, int3, int3_paw, becsumort
  USE eqv,                  ONLY : dvpsi, dpsi, evq
  USE qpoint,               ONLY : npwq, igkq, nksq
  USE modes,                ONLY : npert, u, t, max_irr_dim, irotmq, tmq, &
                                   minus_q, irgq, nsymq, rtau
  USE efield_mod,           ONLY : zstareu0, zstarue0
  USE qpoint,               ONLY : xq
  ! used oly to write the restart file
  USE mp_global,            ONLY : inter_pool_comm, intra_pool_comm
  USE mp,                   ONLY : mp_sum
  !
  implicit none

  integer :: irr, npe, imode0
  ! input: the irreducible representation
  ! input: the number of perturbation
  ! input: the position of the modes

  complex(DP) :: drhoscf (nrxx, nspin, npe)
  ! output: the change of the scf charge

  real(DP) , allocatable :: h_diag (:,:),eprec (:)
  ! h_diag: diagonal part of the Hamiltonian
  ! eprec : array for preconditioning
  real(DP) :: thresh, anorm, averlt, dr2
  ! thresh: convergence threshold
  ! anorm : the norm of the error
  ! averlt: average number of iterations
  ! dr2   : self-consistency error
  real(DP) :: dos_ef, wg1, w0g, wgp, wwg, weight, deltae, theta, &
       aux_avg (2), DNRM2
  ! Misc variables for metals
  ! dos_ef: density of states at Ef
  real(DP), external :: w0gauss, wgauss
  ! functions computing the delta and theta function

  complex(DP), allocatable, target :: dvscfin(:,:,:)
  ! change of the scf potential 
  complex(DP), pointer :: dvscfins (:,:,:)
  ! change of the scf potential (smooth part only)
  complex(DP), allocatable :: drhoscfh (:,:,:), dvscfout (:,:,:)
  ! change of rho / scf potential (output)
  ! change of scf potential (output)
  complex(DP), allocatable :: ldos (:,:), ldoss (:,:), mixin(:), mixout(:), &
       dbecsum (:,:,:,:), dbecsum_nc(:,:,:,:,:), auxg (:), aux1 (:,:), ps (:,:)
  ! Misc work space
  ! ldos : local density of states af Ef
  ! ldoss: as above, without augmentation charges
  ! dbecsum: the derivative of becsum
  complex(DP) :: ZDOTC, sup, sdwn
  ! the scalar product function

  logical :: conv_root,  & ! true if linear system is converged
             exst,       & ! used to open the recover file
             lmetq0        ! true if xq=(0,0,0) in a metal

  integer :: kter,       & ! counter on iterations
             iter0,      & ! starting iteration
             ipert,      & ! counter on perturbations
             ibnd, jbnd, & ! counter on bands
             iter,       & ! counter on iterations
             lter,       & ! counter on iterations of linear system
             ltaver,     & ! average counter
             lintercall, & ! average number of calls to cgsolve_all
             ik, ikk,    & ! counter on k points
             ikq,        & ! counter on k+q points
             ig,         & ! counter on G vectors
             ir,         & ! counter on mesh points
             ndim,       &
             is,         & ! counter on spin polarizations
             nt,         & ! counter on types
             na,         & ! counter on atoms
             nrec, nrec1,& ! the record number for dvpsi and dpsi
             ios,        & ! integer variable for I/O control
             mode          ! mode index
  integer :: ih,jh,ijh

  real(DP) :: tcpu, get_clock ! timing variables

  character (len=256) :: flmixdpot ! name of the file with the mixing potential

  external ch_psi_all, cg_psi
  !
  call start_clock ('solve_linter')
  allocate (ps (nbnd, nbnd))
  allocate (dvscfin ( nrxx , nspin , npe))    
  if (doublegrid) then
     allocate (dvscfins ( nrxxs , nspin , npe))    
  else
     dvscfins => dvscfin
  endif
  allocate (drhoscfh ( nrxx , nspin , npe))    
  allocate (dvscfout ( nrxx , nspin , npe))    
  allocate (auxg (npwx * npol))    
  allocate (dbecsum ( (nhm * (nhm + 1))/2 , nat , nspin , npe))    
  IF (okpaw) THEN
     allocate (mixin(nrxx*nspin*npe+(nhm*(nhm+1)*nat*nspin*npe)/2) )
     allocate (mixout(nrxx*nspin*npe+(nhm*(nhm+1)*nat*nspin*npe)/2) )
  ENDIF
  IF (noncolin) allocate (dbecsum_nc (nhm,nhm, nat , nspin , npe))
  allocate (aux1 ( nrxxs, npol))    
  allocate (h_diag ( npwx*npol, nbnd))    
  allocate (eprec ( nbnd))
  !
  if (rec_code > 2.and.recover) then
     ! restart from Phonon calculation
     read (iunrec) iter0, dr2
     read (iunrec) this_pcxpsi_is_on_file
     read (iunrec) zstareu0, zstarue0
     read (iunrec) dvscfin
     if (okvan) then
        read (iunrec) int1, int2, int3
        if (noncolin) then
           CALL set_int12_nc(0)
           CALL set_int3_nc(npe)
        end if
     end if
     close (unit = iunrec, status = 'keep')
     ! reset rec_code to avoid trouble at next irrep
     rec_code = 0
     if (doublegrid) then
        do is = 1, nspin
           do ipert = 1, npe
              call cinterpolate (dvscfin(1,is,ipert), dvscfins(1,is,ipert), -1)
           enddo
        enddo
     endif
  else
    iter0 = 0
    where_rec='no_recover'
  endif
  !
  ! if q=0 for a metal: allocate and compute local DOS at Ef
  !

  lmetq0 = lgauss.and.lgamma
  if (lmetq0) then
     allocate ( ldos ( nrxx  , nspin) )    
     allocate ( ldoss( nrxxs , nspin) )    
     call localdos ( ldos , ldoss , dos_ef )
  endif
  !
  if (reduce_io) then
     flmixdpot = ' '
  else
     flmixdpot = 'mixd'
  endif
  !
  IF (ionode .AND. fildrho /= ' ') THEN
     INQUIRE (UNIT = iudrho, OPENED = exst)
     IF (exst) CLOSE (UNIT = iudrho, STATUS='keep')
     CALL DIROPN (iudrho, TRIM(fildrho)//'.u', lrdrho, exst)
  END IF
  !
  ! In this case it has recovered after computing the contribution
  ! to the dynamical matrix. This is a new iteration that has to 
  ! start from the beginning.
  !
  IF (iter0==-1000) iter0=0
  !
  !   The outside loop is over the iterations
  !
  IF (okpaw) mixin=(0.0_DP,0.0_DP)
  do kter = 1, niter_ph
     iter = kter + iter0

     ltaver = 0

     lintercall = 0
     drhoscf(:,:,:) = (0.d0, 0.d0)
     dbecsum(:,:,:,:) = (0.d0, 0.d0)
     IF (noncolin) dbecsum_nc = (0.d0, 0.d0)
     !
     if (nksq.gt.1) rewind (unit = iunigk)
     do ik = 1, nksq
        if (nksq.gt.1) then
           read (iunigk, err = 100, iostat = ios) npw, igk
100        call errore ('solve_linter', 'reading igk', abs (ios) )
        endif
        if (lgamma) then
           ikk = ik
           ikq = ik
           npwq = npw
        else
           ikk = 2 * ik - 1
           ikq = ikk + 1
        endif
        if (lsda) current_spin = isk (ikk)
        if (.not.lgamma.and.nksq.gt.1) then
           read (iunigk, err = 200, iostat = ios) npwq, igkq
200        call errore ('solve_linter', 'reading igkq', abs (ios) )

        endif
        call init_us_2 (npwq, igkq, xk (1, ikq), vkb)
        !
        ! reads unperturbed wavefuctions psi(k) and psi(k+q)
        !
        if (nksq.gt.1) then
           if (lgamma) then
              call davcio (evc, lrwfc, iuwfc, ikk, - 1)
           else
              call davcio (evc, lrwfc, iuwfc, ikk, - 1)
              call davcio (evq, lrwfc, iuwfc, ikq, - 1)
           endif

        endif
        !
        ! compute the kinetic energy
        !
        do ig = 1, npwq
           g2kin (ig) = ( (xk (1,ikq) + g (1, igkq(ig)) ) **2 + &
                          (xk (2,ikq) + g (2, igkq(ig)) ) **2 + &
                          (xk (3,ikq) + g (3, igkq(ig)) ) **2 ) * tpiba2
        enddo
        !
        ! diagonal elements of the unperturbed hamiltonian
        !
        do ipert = 1, npert (irr)
           mode = imode0 + ipert
           nrec = (ipert - 1) * nksq + ik
           !
           !  and now adds the contribution of the self consistent term
           !
           if (where_rec =='solve_lint'.or.iter>1) then
              !
              ! After the first iteration dvbare_q*psi_kpoint is read from file
              !
              call davcio (dvpsi, lrbar, iubar, nrec, - 1)
              !
              ! calculates dvscf_q*psi_k in G_space, for all bands, k=kpoint
              ! dvscf_q from previous iteration (mix_potential)
              !
              call start_clock ('vpsifft')
              do ibnd = 1, nbnd_occ (ikk)
                 call cft_wave (evc (1, ibnd), aux1, +1) 
                 IF (noncolin) THEN
                    IF (domag) then
                       do ir = 1, nrxxs
                          sup=aux1(ir,1)*(dvscfins(ir,1,ipert) &
                                      +dvscfins(ir,4,ipert))+ &
                              aux1(ir,2)*(dvscfins(ir,2,ipert)- &
                                           (0.d0,1.d0)*dvscfins(ir,3,ipert))
                          sdwn=aux1(ir,2)*(dvscfins(ir,1,ipert)- &
                                        dvscfins(ir,4,ipert)) + &
                               aux1(ir,1)*(dvscfins(ir,2,ipert)+ &
                                           (0.d0,1.d0)*dvscfins(ir,3,ipert))
                          aux1(ir,1)=sup
                          aux1(ir,2)=sdwn
                       enddo
                    ELSE
                       do ir = 1, nrxxs
                          aux1(ir,1)=aux1(ir,1)*dvscfins(ir,1,ipert)
                          aux1(ir,2)=aux1(ir,2)*dvscfins(ir,1,ipert)
                       enddo
                    ENDIF
                 ELSE
                    do ir = 1, nrxxs
                       aux1(ir,1)=aux1(ir,1)*dvscfins(ir,current_spin,ipert)
                    enddo
                 ENDIF
                 call cft_wave (dvpsi (1, ibnd), aux1, -1)
              ENDDO
              call stop_clock ('vpsifft')
              !
              !  In the case of US pseudopotentials there is an additional 
              !  selfconsist term which comes from the dependence of D on 
              !  V_{eff} on the bare change of the potential
              !
              call adddvscf (ipert, ik)
           else
              !
              !  At the first iteration dvbare_q*psi_kpoint is calculated
              !  and written to file
              !
              call dvqpsi_us (ik, mode, u (1, mode),.false. )
              call davcio (dvpsi, lrbar, iubar, nrec, 1)
           endif
           !
           ! Ortogonalize dvpsi to valence states: ps = <evq|dvpsi>
           !
           call start_clock ('ortho')
           !
           if (lgauss) then
              !
              !  metallic case
              !
              IF (noncolin) THEN
                 CALL ZGEMM( 'C', 'N', nbnd, nbnd_occ (ikk), npwx*npol,   &
                      (1.d0,0.d0), evq(1,1), npwx*npol, dvpsi(1,1), npwx*npol, &
                      (0.d0,0.d0), ps(1,1), nbnd )
              ELSE
                 CALL ZGEMM( 'C', 'N', nbnd, nbnd_occ (ikk), npwq,   &
                      (1.d0,0.d0), evq(1,1), npwx, dvpsi(1,1), npwx, &
                      (0.d0,0.d0), ps(1,1), nbnd )
              END IF
              !
              do ibnd = 1, nbnd_occ (ikk)
                 wg1 = wgauss ((ef-et(ibnd,ikk)) / degauss, ngauss)
                 w0g = w0gauss((ef-et(ibnd,ikk)) / degauss, ngauss) / degauss
                 do jbnd = 1, nbnd
                    wgp = wgauss ( (ef - et (jbnd, ikq) ) / degauss, ngauss)
                    deltae = et (jbnd, ikq) - et (ibnd, ikk)
                    theta = wgauss (deltae / degauss, 0)
                    wwg = wg1 * (1.d0 - theta) + wgp * theta
                    if (jbnd <= nbnd_occ (ikq) ) then
                       if (abs (deltae) > 1.0d-5) then
                          wwg = wwg + alpha_pv * theta * (wgp - wg1) / deltae
                       else
                          !
                          !  if the two energies are too close takes the limit
                          !  of the 0/0 ratio
                          !
                          wwg = wwg - alpha_pv * theta * w0g
                       endif
                    endif
                    !
                    ps(jbnd,ibnd) = wwg * ps(jbnd,ibnd)
                    !
                 enddo
                 IF (noncolin) THEN
                    call DSCAL (2*npwx*npol, wg1, dvpsi(1,ibnd), 1)
                 ELSE
                    call DSCAL (2*npwq, wg1, dvpsi(1,ibnd), 1)
                 END IF
              enddo
           else
              !
              !  insulators
              !
              ps (:,:) = (0.d0, 0.d0)
              IF (noncolin) THEN
                 CALL ZGEMM( 'C', 'N',nbnd_occ(ikq),nbnd_occ(ikk), npwx*npol, &
                     (1.d0,0.d0), evq(1,1), npwx*npol, dvpsi(1,1), npwx*npol, &
                     (0.d0,0.d0), ps(1,1), nbnd )
              ELSE
                 CALL ZGEMM( 'C', 'N', nbnd_occ(ikq), nbnd_occ (ikk), npwq, &
                     (1.d0,0.d0), evq(1,1), npwx, dvpsi(1,1), npwx, &
                     (0.d0,0.d0), ps(1,1), nbnd )
              END IF
           end if
#ifdef __PARA
           call mp_sum ( ps( :, 1:nbnd_occ(ikk) ), intra_pool_comm )
#endif
           !
           ! dpsi is used as work space to store S|evc>
           !
           IF (noncolin) THEN
              CALL calbec ( npwq, vkb, evq, becp_nc )
              CALL s_psi_nc (npwx, npwq, nbnd, evq, dpsi)
           ELSE
              CALL calbec ( npwq, vkb, evq, becp )
              CALL s_psi (npwx, npwq, nbnd, evq, dpsi)
           ENDIF
           !
           ! |dvspi> = - (|dvpsi> - S|evq><evq|dvpsi>)
           !  note the change of sign!
           !
           IF (noncolin) THEN
              CALL ZGEMM( 'N', 'N', npwx*npol, nbnd_occ(ikk), nbnd, &
                  ( 1.d0,0.d0),dpsi(1,1),npwx*npol,ps(1,1),nbnd,(-1.0d0,0.d0), &
                  dvpsi(1,1), npwx*npol )
           ELSE
              CALL ZGEMM( 'N', 'N', npwq, nbnd_occ(ikk), nbnd, &
                  ( 1.d0,0.d0), dpsi(1,1), npwx, ps(1,1), nbnd, (-1.0d0,0.d0), &
                  dvpsi(1,1), npwx )
           END IF
           call stop_clock ('ortho')
           !
           if (where_rec=='solve_lint'.or.iter > 1) then
              !
              ! starting value for delta_psi is read from iudwf
              !
              nrec1 = (ipert - 1) * nksq + ik
              call davcio ( dpsi, lrdwf, iudwf, nrec1, -1)
              !
              ! threshold for iterative solution of the linear system
              !
              thresh = min (1.d-1 * sqrt (dr2), 1.d-2)
           else
              !
              !  At the first iteration dpsi and dvscfin are set to zero
              !
              dpsi(:,:) = (0.d0, 0.d0) 
              dvscfin (:, :, ipert) = (0.d0, 0.d0)
              !
              ! starting threshold for iterative solution of the linear system
              !
              thresh = 1.0d-2
           endif

           !
           ! iterative solution of the linear system (H-eS)*dpsi=dvpsi,
           ! dvpsi=-P_c^+ (dvbare+dvscf)*psi , dvscf fixed.
           !
           do ibnd = 1, nbnd_occ (ikk)
              auxg=(0.d0,0.d0)
              do ig = 1, npwq
                 auxg (ig) = g2kin (ig) * evq (ig, ibnd)
              enddo
              IF (noncolin) THEN
                 do ig = 1, npwq
                    auxg (ig+npwx) = g2kin (ig) * evq (ig+npwx, ibnd)
                 enddo
              END IF
              eprec (ibnd) = 1.35d0 * ZDOTC (npwx*npol,evq(1,ibnd),1,auxg, 1)
           enddo
#ifdef __PARA
           call mp_sum ( eprec( 1:nbnd_occ (ikk) ), intra_pool_comm )
#endif
           h_diag=0.d0
           do ibnd = 1, nbnd_occ (ikk)
              do ig = 1, npwq
                 h_diag(ig,ibnd)=1.d0/max(1.0d0,g2kin(ig)/eprec(ibnd))
              enddo
              IF (noncolin) THEN
                 do ig = 1, npwq
                    h_diag(ig+npwx,ibnd)=1.d0/max(1.0d0,g2kin(ig)/eprec(ibnd))
                 enddo
              END IF
           enddo
           conv_root = .true.

           call cgsolve_all (ch_psi_all, cg_psi, et(1,ikk), dvpsi, dpsi, &
                             h_diag, npwx, npwq, thresh, ik, lter, conv_root, &
                             anorm, nbnd_occ(ikk), npol )

           ltaver = ltaver + lter
           lintercall = lintercall + 1
           if (.not.conv_root) WRITE( stdout, '(5x,"kpoint",i4," ibnd",i4,  &
                &              " solve_linter: root not converged ",e10.3)') &
                &              ik , ibnd, anorm
           !
           ! writes delta_psi on iunit iudwf, k=kpoint,
           !
           nrec1 = (ipert - 1) * nksq + ik
           !               if (nksq.gt.1 .or. npert(irr).gt.1)
           call davcio (dpsi, lrdwf, iudwf, nrec1, + 1)
           !
           ! calculates dvscf, sum over k => dvscf_q_ipert
           !
           weight = wk (ikk)
           IF (noncolin) THEN
              call incdrhoscf_nc(drhoscf(1,1,ipert),weight,ik, &
                                       dbecsum_nc(1,1,1,1,ipert))
           ELSE
              call incdrhoscf (drhoscf(1,current_spin,ipert), weight, ik, &
                            dbecsum(1,1,current_spin,ipert))
           END IF
           ! on perturbations
        enddo
        ! on k-points
     enddo
#ifdef __PARA
     !
     !  The calculation of dbecsum is distributed across processors (see addusdbec)
     !  Sum over processors the contributions coming from each slice of bands
     !
     IF (noncolin) THEN
        call mp_sum ( dbecsum_nc, intra_pool_comm )
     ELSE
        call mp_sum ( dbecsum, intra_pool_comm )
     ENDIF
#endif

     if (doublegrid) then
        do is = 1, nspin
           do ipert = 1, npert (irr)
              call cinterpolate (drhoscfh(1,is,ipert), drhoscf(1,is,ipert), 1)
           enddo
        enddo
     else
        call ZCOPY (npe*nspin*nrxx, drhoscf, 1, drhoscfh, 1)
     endif
!
!  In the noncolinear, spin-orbit case rotate dbecsum
!
     IF (noncolin.and.okvan) THEN
        DO nt = 1, ntyp
           IF ( upf(nt)%tvanp ) THEN
              DO na = 1, nat
                 IF (ityp(na)==nt) THEN
                    IF (upf(nt)%has_so) THEN
                       CALL transform_dbecsum_so(dbecsum_nc,dbecsum,na, &
                                                               npert(irr))
                   ELSE
                       CALL transform_dbecsum_nc(dbecsum_nc,dbecsum,na, &
                                                               npert(irr))
                    END IF
                 END IF
              END DO
           END IF
        END DO
     END IF
     !
     !    Now we compute for all perturbations the total charge and potential
     !
     call addusddens (drhoscfh, dbecsum, irr, imode0, npe, 0)
#ifdef __PARA
     !
     !   Reduce the delta rho across pools
     !
     call mp_sum ( drhoscf, inter_pool_comm )
     call mp_sum ( drhoscfh, inter_pool_comm )
     IF (okpaw) THEN
        IF (noncolin) THEN
           call mp_sum ( dbecsum_nc, inter_pool_comm )
        ELSE
           call mp_sum ( dbecsum, inter_pool_comm )
        ENDIF
     ENDIF
#endif

     !
     ! q=0 in metallic case deserve special care (e_Fermi can shift)
     !

     if (lmetq0) call ef_shift(drhoscfh, ldos, ldoss, dos_ef, irr, npe, .false.)

     IF (okpaw) THEN
        IF (noncolin) THEN
        ELSE
           DO ipert=1,npe
              dbecsum(:,:,:,ipert)=2.0_DP *dbecsum(:,:,:,ipert) &
                               +becsumort(:,:,:,imode0+ipert)
           ENDDO
        ENDIF
     ENDIF
     !
     !   After the loop over the perturbations we have the linear change 
     !   in the charge density for each mode of this representation. 
     !   Here we symmetrize them ...
     !
     IF (.not.lgamma_gamma) THEN
#ifdef __PARA
        call psymdvscf (npert (irr), irr, drhoscfh)
        IF ( noncolin.and.domag ) &
           CALL psym_dmag( npert(irr), irr, drhoscfh)
#else
        call symdvscf (npert (irr), irr, drhoscfh)
        IF ( noncolin.and.domag ) CALL sym_dmag( npert(irr), irr, drhoscfh)
#endif
        IF (okpaw) THEN
           IF (noncolin) THEN
           ELSE
              IF (minus_q) CALL PAW_dumqsymmetrize(dbecsum,npe,irr, &
                             max_irr_dim,irotmq,rtau,xq,tmq)
              CALL  &
                PAW_dusymmetrize(dbecsum,npe,irr,max_irr_dim,nsymq,irgq,rtau,xq,t)
           END IF
        END IF
     ENDIF
     ! 
     !   ... save them on disk and 
     !   compute the corresponding change in scf potential 
     !
     do ipert = 1, npert (irr)
        if (fildrho.ne.' ') call davcio_drho (drhoscfh(1,1,ipert), lrdrho, &
                                              iudrho, imode0+ipert, +1)
        call ZCOPY (nrxx*nspin, drhoscfh(1,1,ipert), 1, dvscfout(1,1,ipert), 1)
        call dv_of_drho (imode0+ipert, dvscfout(1,1,ipert), .true.)
     enddo
     !
     !   And we mix with the old potential
     !
     IF (okpaw) THEN
     !
     !  In this case we mix also dbecsum
     !
        call setmixout(npe*nrxx*nspin,(nhm*(nhm+1)*nat*nspin*npe)/2, &
                    mixout, dvscfout, dbecsum, ndim, -1 )
        call mix_potential (2*npe*nrxx*nspin+2*ndim, &
                         mixout, mixin, &
                         alpha_mix(kter), dr2, npert(irr)*tr2_ph/npol, iter, &
                         nmix_ph, flmixdpot, convt)
        call setmixout(npe*nrxx*nspin,(nhm*(nhm+1)*nat*nspin*npe)/2, &
                       mixin, dvscfin, dbecsum, ndim, 1 )
     ELSE
        call mix_potential (2*npe*nrxx*nspin, dvscfout, dvscfin, &
                         alpha_mix(kter), dr2, npert(irr)*tr2_ph/npol, iter, &
                         nmix_ph, flmixdpot, convt)
     ENDIF
     if (lmetq0.and.convt) &
         call ef_shift (drhoscf, ldos, ldoss, dos_ef, irr, npe, .true.)
     if (doublegrid) then
        do ipert = 1, npe
           do is = 1, nspin
              call cinterpolate (dvscfin(1,is,ipert), dvscfins(1,is,ipert), -1)
           enddo
        enddo
     endif
!
!   calculate here the change of the D1-~D1 coefficients due to the phonon
!   perturbation
!
     IF (okpaw) THEN
        IF (noncolin) THEN
!           call PAW_dpotential(dbecsum_nc,becsum_nc,int3_paw,max_irr_dim)
        ELSE
           CALL PAW_dpotential(dbecsum,rho%bec,int3_paw,npe,max_irr_dim)
        ENDIF
     ENDIF
     !
     !     with the new change of the potential we compute the integrals
     !     of the change of potential and Q
     !
     call newdq (dvscfin, npe)
#ifdef __PARA
     aux_avg (1) = DBLE (ltaver)
     aux_avg (2) = DBLE (lintercall)
     call mp_sum ( aux_avg, inter_pool_comm )
     averlt = aux_avg (1) / aux_avg (2)
#else
     averlt = DBLE (ltaver) / lintercall
#endif
     tcpu = get_clock ('PHONON')

     WRITE( stdout, '(/,5x," iter # ",i3," total cpu time :",f8.1, &
          &      " secs   av.it.: ",f5.1)') iter, tcpu, averlt
     dr2 = dr2 / npert (irr)
     WRITE( stdout, '(5x," thresh=",e10.3, " alpha_mix = ",f6.3, &
          &      " |ddv_scf|^2 = ",e10.3 )') thresh, alpha_mix (kter) , dr2
     !
     !    Here we save the information for recovering the run from this poin
     !
     CALL flush_unit( stdout )
     !
     rec_code=10
     CALL write_rec('solve_lint', irr, dr2, iter, convt, dvscfin, npe)

     if (check_stop_now()) call stop_ph (.false.)
     if (convt) goto 155
  enddo
155 iter0=0
  !
  !    There is a part of the dynamical matrix which requires the integral
  !    self consistent change of the potential and the variation of the ch
  !    due to the displacement of the atoms. We compute it here because ou
  !    this routine the change of the self-consistent potential is lost.
  !
  if (convt) then
     call drhodvus (irr, imode0, dvscfin, npe)
     if (fildvscf.ne.' ') then
        do ipert = 1, npert (irr)
           call davcio_drho ( dvscfin(1,1,ipert),  lrdrho, iudvscf, &
                              imode0 + ipert, +1 )
        end do
        if (elph) call elphel (npe, imode0, dvscfins)
     end if
  endif
  if (convt.and.nlcc_any) call addnlcc (imode0, drhoscfh, npe)
  if (lmetq0) deallocate (ldoss)
  if (lmetq0) deallocate (ldos)
  deallocate (eprec)
  deallocate (h_diag)
  deallocate (aux1)
  deallocate (dbecsum)
  IF (okpaw) THEN
     deallocate (mixin)
     deallocate (mixout)
  ENDIF
  IF (noncolin) deallocate (dbecsum_nc)
  deallocate (auxg)
  deallocate (dvscfout)
  deallocate (drhoscfh)
  if (doublegrid) deallocate (dvscfins)
  deallocate (dvscfin)
  deallocate (ps)

  call stop_clock ('solve_linter')
  return
end subroutine solve_linter

SUBROUTINE setmixout(in1, in2, mix, dvscfout, dbecsum, ndim, flag )
USE kinds, ONLY : DP
USE mp_global, ONLY : intra_pool_comm
USE mp, ONLY : mp_sum
IMPLICIT NONE
INTEGER :: in1, in2, flag, ndim, startb, lastb
COMPLEX(DP) :: mix(in1+in2), dvscfout(in1), dbecsum(in2)

CALL divide (in2, startb, lastb)
ndim=lastb-startb+1

IF (flag==-1) THEN
   mix(1:in1)=dvscfout(1:in1)
   mix(in1+1:in1+ndim)=dbecsum(startb:lastb)
ELSE
   dvscfout(1:in1)=mix(1:in1)
   dbecsum=(0.0_DP,0.0_DP)
   dbecsum(startb:lastb)=mix(in1+1:in1+ndim)
#ifdef __PARA
   CALL mp_sum(dbecsum, intra_pool_comm)
#endif
ENDIF
RETURN
END

