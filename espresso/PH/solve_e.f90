!
! Copyright (C) 2001 PWSCF group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine solve_e
  !-----------------------------------------------------------------------
  !
  !    This routine is a driver for the solution of the linear system which
  !    defines the change of the wavefunction due to an electric field.
  !    It performs the following tasks:
  !     a) It computes the kinetic energy
  !     b) It adds the term Delta V_{SCF} | psi >
  !     c) It applies P_c^+ to the known part
  !     d) It calls linter to solve the linear system
  !     e) It computes Delta rho, Delta V_{SCF} and symmetrize them
  !
#include "machine.h"
  USE io_global,      ONLY : stdout
  USE io_files, ONLY: iunigk
  use pwcom
  USE wavefunctions_module,  ONLY: evc
  USE kinds, only : DP
  use becmod
  use phcom
  implicit none

  real(kind=DP) ::  thresh, weight, anorm, averlt, dr2
  real(kind=DP), allocatable :: h_diag (:,:), eprec(:)
  ! the diagonal part of the Hamiltonia
  ! the convergence threshold
  ! used for summation over k points
  ! the norm of the error
  ! average number of iterations
  ! cut-off for preconditioning
  ! convergence limit

  complex(kind=DP) , pointer ::      &
                   dvscfin (:,:,:),  & ! change of the scf potential (input)
                   dvscfins (:,:,:)    ! change of the scf potential (smooth)
  complex(kind=DP) , allocatable ::   &
                   dvscfout (:,:,:), & ! change of the scf potential (output)
                   dbecsum(:,:,:,:), & ! the becsum with dpsi
                   auxg (:), aux1 (:), spsi(:), ps (:)

  complex(kind=DP) :: ZDOTC      ! the scalar product function

  logical :: conv_root, exst
  ! true if linter is converged
  ! used to open the recover file

  integer :: kter, ipol, ibnd, jbnd, iter, lter, ltaver, lintercall, &
       ik, ig, irr, ir, is, nrec, nrec1, ios
  ! counter on iterations
  ! counter on perturbations
  ! counter on bands
  ! counter on bands
  ! counter on iterations
  ! counter on iterations of linter
  ! average counter
  ! average number of call to linter
  ! counter on k points
  ! counter on G vectors
  ! the irreducible representation
  ! counter on g vectors
  ! counter on mesh points
  ! the record number
  ! the record number for dpsi
  ! integer variable for I/O control

  real(kind=DP) :: tcpu, get_clock
  ! timing variables

  character (len=42) :: flmixdpot
  ! the name of the file with the
  ! mixing potential

  external ch_psi_all, cg_psi

  if (lsda) call errore ('solve_e', ' LSDA not implemented', 1)

  call start_clock ('solve_e')
  allocate (dvscfin( nrxx, nspin, 3))    
  if (doublegrid) then
     allocate (dvscfins(  nrxxs, nspin, 3))    
  else
     dvscfins => dvscfin
  endif
  allocate (dvscfout( nrxx , nspin, 3))    
  allocate (dbecsum( nhm*(nhm+1)/2, nat, nspin, 3))    
  allocate (auxg(  npwx))    
  allocate (aux1(  nrxxs))    
  allocate (spsi( npwx))    
  allocate (ps(  nbnd))    
  allocate (h_diag( npwx , nbnd))    
  allocate (eprec(  nbnd))    
  if (iter0.ne.0) then
     if (okvan) read(iunrec) int3
     read (iunrec) dr2, dvscfin
     close (unit = iunrec, status = 'keep')
     if (doublegrid) then
        do is=1,nspin
           do ipol=1,3
              call cinterpolate (dvscfin(1,is,ipol), dvscfins(1,is,ipol), -1)
           enddo
        enddo
     endif

  endif
  !
  ! if q=0 for a metal: allocate and compute local DOS at Ef
  !
  if (degauss.ne.0.d0.or..not.lgamma) call errore ('solve_e', &
       'called in the wrong case', 1)
  !
  !   The outside loop is over the iterations
  !
  if (reduce_io) then
     flmixdpot = ' '
  else
     flmixdpot = 'flmixdpot'
  endif

  do kter = 1, niter_ph

     iter = kter + iter0
     convt = .true.
     ltaver = 0
     lintercall = 0

     dvscfout(:,:,:)=(0.d0,0.d0)
     dbecsum(:,:,:,:)=(0.d0,0.d0)

     if (nksq.gt.1) rewind (unit = iunigk)
     do ik = 1, nksq
        if (lsda) current_spin = isk (ik)
        if (nksq.gt.1) then
           read (iunigk, err = 100, iostat = ios) npw, igk
100        call errore ('solve_e', 'reading igk', abs (ios) )
        endif
        !
        ! reads unperturbed wavefuctions psi_k in G_space, for all bands
        !
        if (nksq.gt.1) call davcio (evc, lrwfc, iuwfc, ik, - 1)
        npwq = npw
        call init_us_2 (npw, igk, xk (1, ik), vkb)
        !
        ! compute the kinetic energy
        !
        do ig = 1, npwq
           g2kin (ig) = ( (xk (1,ik ) + g (1,igkq (ig)) ) **2 + &
                          (xk (2,ik ) + g (2,igkq (ig)) ) **2 + &
                          (xk (3,ik ) + g (3,igkq (ig)) ) **2 ) * tpiba2
        enddo
        !
        do ipol = 1, 3
           nrec = (ipol - 1) * nksq + ik
           !
           ! computes/reads P_c^+ x psi_kpoint into dvpsi array
           call dvpsi_e (ik, ipol)
           if (iter.eq.1) then
              !
              !  At the first iteration dpsi and dvscfin are set to zero,
              !
              dpsi(:,:)=(0.d0,0.d0)
              dvscfin(:,:,:)=(0.d0,0.d0)
              !
              ! starting threshold for the iterative solution of the linear
              ! system
              !
              thresh = 1.d-2
           else
              !
              ! calculates dvscf_q*psi_k in G_space, for all bands, k=kpoint
              ! dvscf_q from previous iteration (mix_potential)
              !
              do ibnd = 1, nbnd_occ (ik)
                 aux1(:) = (0.d0, 0.d0)
                 do ig = 1, npw
                    aux1 (nls(igk(ig)))=evc(ig,ibnd)
                 enddo
                 call cft3s (aux1,nr1s,nr2s,nr3s,nrx1s,nrx2s,nrx3s,+2)
                 do ir = 1, nrxxs
                    aux1(ir)=aux1(ir)*dvscfins(ir,current_spin,ipol)
                 enddo
                 call cft3s (aux1,nr1s,nr2s,nr3s,nrx1s,nrx2s,nrx3s,-2)
                 do ig = 1, npwq
                    dvpsi(ig,ibnd)=dvpsi(ig,ibnd)+aux1(nls(igkq(ig)))
                 enddo
              enddo
              call adddvscf(ipol,ik)
              !
              ! starting value for  delta_psi is read from iudwf
              !
              nrec1 = (ipol - 1) * nksq + ik
              call davcio (dpsi, lrdwf, iudwf, nrec1, - 1)
              !
              ! threshold for iterative solution of the linear system
              !
              thresh = min (0.1d0 * sqrt (dr2), 1.0d-2)
           endif
           !
           ! Orthogonalize dvpsi
           !
           do ibnd = 1, nbnd_occ (ik)
              auxg(:) = (0.d0, 0.d0)
              do jbnd = 1, nbnd_occ (ik)
                 ps(jbnd)=-ZDOTC(npw,evc(1,jbnd),1,dvpsi(1,ibnd),1)
              enddo
#ifdef __PARA
              call reduce (2 * nbnd, ps)
#endif
              do jbnd = 1, nbnd_occ (ik)
                 call ZAXPY (npw, ps (jbnd), evc (1, jbnd), 1, auxg, 1)
              enddo
              call ccalbec (nkb, npwx, npw, 1, becp, vkb, auxg)
              call s_psi (npwx, npw, 1, auxg, spsi)
              call DAXPY (2*npw, 1.0d0, spsi, 1, dvpsi (1, ibnd), 1)
           enddo
           !
           !    Here we change the sign of the known term
           !
           call DSCAL (2*npwx*nbnd, -1.d0, dvpsi, 1)
           !
           ! iterative solution of the linear system (H-e)*dpsi=dvpsi
           ! dvpsi=-P_c+ (dvbare+dvscf)*psi , dvscf fixed.
           !
           do ibnd = 1, nbnd_occ (ik)
              do ig = 1, npw
                 auxg (ig) = g2kin (ig) * evc (ig, ibnd)
              enddo
              eprec (ibnd) = 1.35d0*ZDOTC(npwq,evc(1,ibnd),1,auxg,1)
           enddo
#ifdef __PARA
           call reduce (nbnd_occ (ik), eprec)
#endif
           do ibnd = 1, nbnd_occ (ik)
              do ig = 1, npw
                 h_diag(ig,ibnd)=1.d0/max(1.0d0,g2kin(ig)/eprec(ibnd))
              enddo
           enddo

           conv_root = .true.

           call cgsolve_all (ch_psi_all,cg_psi,et(1,ik),dvpsi,dpsi, &
              h_diag,npwx,npw,thresh,ik,lter,conv_root,anorm,nbnd_occ(ik) )

           ltaver = ltaver + lter
           lintercall = lintercall + 1
           if (.not.conv_root) WRITE( stdout, "(5x,'kpoint',i4,' ibnd',i4, &
                &         ' linter: root not converged ',e10.3)") ik &
                &, ibnd, anorm
           !
           ! writes delta_psi on iunit iudwf, k=kpoint,
           !
           nrec1 = (ipol - 1) * nksq + ik

           call davcio (dpsi, lrdwf, iudwf, nrec1, + 1)
           !
           ! calculates dvscf, sum over k => dvscf_q_ipert
           !
           weight = wk (ik)
           call incdrhoscf (dvscfout(1,current_spin,ipol), weight, &
                            ik, dbecsum(1,1,current_spin,ipol), 1)
        enddo   ! on perturbation
     enddo      ! on k points
#ifdef __PARA
     !
     !  The calculation of dbecsum is distributed across processors (see addusdbec)
     !  Sum over processors the contributions coming from each slice of bands
     !
     call reduce (nhm * (nhm + 1) * nat * nspin * 3, dbecsum)
#endif

     if (doublegrid) then
        do is=1,nspin
           do ipol=1,3
              call cinterpolate (dvscfout(1,is,ipol), dvscfout(1,is,ipol), 1)
           enddo
        enddo
     endif

     call addusddense (dvscfout, dbecsum)

     !
     !   After the loop over the perturbations we have the change of the pote
     !   for all the modes of this representation. We symmetrize this potenti
     !
#ifdef __PARA
     call poolreduce (2 * 3 * nrxx *nspin, dvscfout)
#endif
     do ipol=1,3
        if (fildrho.ne.' ') call davcio_drho(dvscfout(1,1,ipol),lrdrho, &
             iudrho,ipol,+1)
        call dv_of_drho (0, dvscfout (1, 1, ipol), .false.)
     enddo
#ifdef __PARA
     call psyme (dvscfout)
#else
     call syme (dvscfout)
#endif
     !
     !   And we mix with the old potential
     !

     call mix_potential (2 * 3 * nrxx *nspin, dvscfout, dvscfin, alpha_mix ( &
          kter), dr2, 3 * tr2_ph, iter, nmix_ph, flmixdpot, convt)
     if (doublegrid) then
        do is=1,nspin
           do ipol = 1, 3
              call cinterpolate (dvscfin(1,is,ipol),dvscfins(1,is,ipol),-1)
           enddo
        enddo
     endif

     call newdq(dvscfin,3)

     averlt = dfloat (ltaver) / dfloat (lintercall)
  
     tcpu = get_clock ('PHONON')
     WRITE( stdout, '(//,5x," iter # ",i3," total cpu time : ",f7.1, &
          &      " secs   av.it.: ",f5.1)') iter, tcpu, averlt
     dr2 = dr2 / 3
     WRITE( stdout, "(5x,' thresh=',e10.3, ' alpha_mix = ',f6.3, &
          &      ' |ddv_scf|^2 = ',e10.3 )") thresh, alpha_mix (kter), dr2
#ifdef FLUSH
     call flush (6)
#endif

     call seqopn (iunrec, 'recover', 'unformatted', exst)
     irr = - 2

     write (iunrec) dyn, dyn00, epsilon, zstareu, zstarue, zstareu0, &
          zstarue0
     if (reduce_io) then
        write(iunrec) irr, 0, convt, done_irr, comp_irr, ifat
     else
        write(iunrec) irr, iter, convt, done_irr, comp_irr, ifat
        if (okvan) write(iunrec) int3
        write(iunrec) dr2, dvscfin
     endif

     close (unit = iunrec, status = 'keep')
     tcpu = get_clock ('PHONON')
     if (convt.or.tcpu.gt.time_max) goto 155

  enddo
155 continue
  if (tcpu.gt.time_max) then
     WRITE( stdout, "(/,5x,'Stopping for time limit ',2f10.0)") tcpu, &
          time_max
     call stop_ph (.false.)
  endif
  deallocate (eprec)
  deallocate (h_diag)
  deallocate (ps)
  deallocate (spsi)
  deallocate (aux1)
  deallocate (auxg)
  deallocate (dbecsum)
  deallocate (dvscfout)
  if (doublegrid) deallocate (dvscfins)
  deallocate (dvscfin)

  call stop_clock ('solve_e')
  return
end subroutine solve_e
