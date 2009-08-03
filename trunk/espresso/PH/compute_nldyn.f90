!
! Copyright (C) 2001-2008 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
!-----------------------------------------------------------------------
subroutine compute_nldyn (wdyn, wgg, becq, alpq)
  !-----------------------------------------------------------------------
  !
  !
  !  This routine computes the term of the dynamical matrix due to
  !  the orthogonality constraint. Only the part which is due to
  !  the nonlocal terms is computed here
  !
  !
  USE kinds,     ONLY : DP
  USE klist,     ONLY : wk
  USE lsda_mod,  ONLY : lsda, current_spin, isk, nspin
  USE ions_base, ONLY : nat, ityp, ntyp => nsp
  USE noncollin_module, ONLY : noncolin, npol
  USE uspp,      ONLY : nkb, qq, qq_so
  USE uspp_param,ONLY : nh, nhm
  USE spin_orb,  ONLY : lspinorb
  USE wvfct,     ONLY : nbnd, et

  USE qpoint,    ONLY : nksq, ikks, ikqs
  USE modes,     ONLY : u
  USE phus,      ONLY : becp1, becp1_nc, alphap, alphap_nc, int1, int2, &
                        int2_so, int1_nc
  USE control_ph, ONLY : nbnd_occ

  USE mp_global, ONLY: intra_pool_comm
  USE mp,        ONLY: mp_sum

  implicit none

  complex(DP) :: becq (nkb, npol, nbnd, nksq), alpq(nkb, npol, nbnd, 3, nksq), &
       wdyn (3 * nat, 3 * nat)
  ! input: the becp with psi_{k+q}
  ! input: the alphap with psi_{k}
  ! output: the term of the dynamical matrix

  real(DP) :: wgg (nbnd, nbnd, nksq)
  ! input: the weights

  complex(DP) :: ps, aux1 (nbnd), aux2 (nbnd)
  complex(DP), allocatable ::  ps1 (:,:), ps2 (:,:,:), ps3 (:,:), ps4 (:,:,:)
  complex(DP), allocatable ::  ps1_nc(:,:,:), ps2_nc(:,:,:,:), &
                               ps3_nc (:,:,:), ps4_nc (:,:,:,:), &
                               deff_nc(:,:,:,:)
  real(DP), allocatable :: deff(:,:,:)
  ! work space
  complex(DP) ::  dynwrk (3 * nat, 3 * nat), ps_nc(2)
  ! auxiliary dynamical matrix

  integer :: ik, ikk, ikq, ibnd, jbnd, ijkb0, ijkb0b, ih, jh, ikb, &
       jkb, ipol, jpol, startb, lastb, na, nb, nt, ntb, nu_i, nu_j, &
       na_icart, na_jcart, mu, nu, is, js, ijs
  ! counters

  IF (noncolin) THEN
     allocate (ps1_nc (  nkb, npol, nbnd))    
     allocate (ps2_nc (  nkb, npol, nbnd , 3))    
     allocate (ps3_nc (  nkb, npol, nbnd))    
     allocate (ps4_nc (  nkb, npol, nbnd , 3))    
     allocate (deff_nc (  nhm, nhm, nat, nspin))    
  ELSE
     allocate (ps1 (  nkb, nbnd))    
     allocate (ps2 (  nkb, nbnd , 3))    
     allocate (ps3 (  nkb, nbnd))    
     allocate (ps4 (  nkb, nbnd , 3))    
     allocate (deff ( nhm, nhm, nat ))    
  END IF

  dynwrk (:,:) = (0.d0, 0.d0)
  call divide (nbnd, startb, lastb)
  do ik = 1, nksq
     ikk = ikks(ik)
     ikq = ikqs(ik)

     if (lsda) current_spin = isk (ikk)
     IF (noncolin) THEN
        ps1_nc = (0.d0, 0.d0)
        ps2_nc = (0.d0, 0.d0)
        ps3_nc = (0.d0, 0.d0)
        ps4_nc = (0.d0, 0.d0)
     ELSE
        ps1 = (0.d0, 0.d0)
        ps2 = (0.d0, 0.d0)
        ps3 = (0.d0, 0.d0)
        ps4 = (0.d0, 0.d0)
     END IF
     !
     !   Here we prepare the two terms
     !
     do ibnd = 1, nbnd
        IF (noncolin) THEN
           CALL compute_deff_nc(deff_nc,et(ibnd,ikk))
        ELSE
           CALL compute_deff(deff,et(ibnd,ikk))
        ENDIF
        ijkb0 = 0
        do nt = 1, ntyp
           do na = 1, nat
              if (ityp (na) == nt) then
                 do ih = 1, nh (nt)
                    ikb = ijkb0 + ih
                    do jh = 1, nh (nt)
                       jkb = ijkb0 + jh
                       IF (noncolin) THEN
                          ijs=0
                          DO is=1,npol
                             DO js=1,npol
                                ijs=ijs+1
                                ps1_nc (ikb, is, ibnd) =      &
                                   ps1_nc (ikb, is, ibnd) +  &
                                   deff_nc(ih,jh,na,ijs)*    &
                                   becp1_nc (jkb, js, ibnd, ik) 
                             END DO
                          END DO
                          IF (lspinorb) THEN
                             ijs=0
                             DO is=1,npol
                                DO js=1,npol
                                   ijs=ijs+1
                                   ps3_nc (ikb, is, ibnd) = &
                                       ps3_nc (ikb, is, ibnd) - &
                                      qq_so(ih,jh,ijs,nt)*becq(jkb,js,ibnd,ik)
                                END DO
                             END DO
                          ELSE
                             DO is=1,npol
                                ps3_nc(ikb,is,ibnd)=ps3_nc(ikb,is,ibnd) - &
                                  qq (ih, jh, nt) * becq (jkb, is, ibnd, ik)
                             ENDDO
                          END IF
                       ELSE
                          ps1 (ikb, ibnd) = ps1 (ikb, ibnd) + &
                            deff(ih,jh,na) *                  &
                            becp1 (jkb, ibnd, ik)
                          ps3 (ikb, ibnd) = ps3 (ikb, ibnd) - &
                            qq (ih, jh, nt) * becq (jkb, 1, ibnd, ik)
                       END IF
                       do ipol = 1, 3
                          IF (noncolin) THEN
                             ijs=0
                             DO is=1,npol
                                DO js=1,npol
                                   ijs=ijs+1
                                   ps2_nc(ikb,is,ibnd,ipol) =               &
                                       ps2_nc(ikb,is,ibnd,ipol) +           &
                                       deff_nc(ih,jh,na,ijs) *              &
                                       alphap_nc (jkb, js, ibnd, ipol, ik)+ &
                                       int1_nc(ih, jh, ipol, na, ijs) *     &
                                        becp1_nc (jkb, js, ibnd, ik)           
                                END DO
                             END DO
                             IF (lspinorb) THEN
                                ijs=0
                                DO is=1,npol
                                   DO js=1,npol
                                      ijs=ijs+1
                                      ps4_nc(ikb,is,ibnd,ipol) =          &
                                             ps4_nc(ikb,is,ibnd,ipol)-    &
                                             qq_so(ih,jh,ijs,nt) *        &
                                             alpq(jkb,js,ibnd,ipol,ik)
                                   END DO
                                END DO
                             ELSE
                                DO is=1,npol
                                   ps4_nc(ikb,is,ibnd,ipol) =                  &
                                     ps4_nc(ikb,is,ibnd,ipol)-              &
                                     qq(ih,jh,nt)*alpq(jkb,is,ibnd,ipol,ik)
                                END DO
                             END IF
                          ELSE
                             ps2 (ikb, ibnd, ipol) = ps2 (ikb, ibnd, ipol) + &
                                deff (ih, jh, na) *                          &
                                   alphap (jkb, ibnd, ipol, ik) +            &
                               int1 (ih, jh, ipol, na, current_spin) *       &
                               becp1 (jkb, ibnd, ik)
                             ps4 (ikb, ibnd, ipol) = ps4 (ikb, ibnd, ipol) - &
                               qq (ih, jh, nt) * alpq (jkb, 1, ibnd, ipol, ik)
                          END IF
                       enddo  ! ipol
                    enddo
                 enddo
                 ijkb0 = ijkb0 + nh (nt)
              endif
           enddo
        enddo
     END DO
     !
     !     Here starts the loop on the atoms (rows)
     !
     ijkb0 = 0
     do nt = 1, ntyp
        do na = 1, nat
           if (ityp (na) .eq.nt) then
              do ipol = 1, 3
                 mu = 3 * (na - 1) + ipol
                 do ibnd = 1, nbnd_occ (ikk)
                    aux1 (:) = (0.d0, 0.d0)
                    do ih = 1, nh (nt)
                       ikb = ijkb0 + ih
                       do jbnd = startb, lastb
                          IF (noncolin) THEN
                             aux1 (jbnd) = aux1 (jbnd) + &
                            CONJG(alpq(ikb,1,jbnd,ipol,ik))*ps1_nc(ikb,1,ibnd)+&
                            CONJG(becq(ikb,1,jbnd,ik))*ps2_nc(ikb,1,ibnd,ipol)+&
                            CONJG(alpq(ikb,2,jbnd,ipol,ik))*ps1_nc(ikb,2,ibnd)+&
                            CONJG(becq(ikb,2,jbnd,ik))*ps2_nc(ikb,2,ibnd,ipol)
                          ELSE
                             aux1 (jbnd) = aux1 (jbnd) + &
                               CONJG(alpq(ikb,1,jbnd,ipol,ik))*ps1(ikb,ibnd)+&
                               CONJG(becq(ikb,1,jbnd,ik))*ps2(ikb,ibnd,ipol)
                          END IF
                       enddo
                    enddo
                    ijkb0b = 0
                    do ntb = 1, ntyp
                       do nb = 1, nat
                          if (ityp (nb) == ntb) then
                             do ih = 1, nh (ntb)
                                ikb = ijkb0b + ih
                                ps_nc =(0.d0,0.d0)
                                ps = (0.d0, 0.d0)
                                do jh = 1, nh (ntb)
                                   jkb = ijkb0b + jh
                                   IF (noncolin) THEN
                                      IF (lspinorb) THEN
                                         ijs=0
                                         DO is=1,npol
                                            DO js=1,npol
                                               ijs=ijs+1
                                               ps_nc(is) = ps_nc(is) + &
                                               int2_so(ih,jh,ipol,na,nb,ijs)*&
                                               becp1_nc(jkb,js,ibnd,ik)    
                                            END DO
                                         END DO
                                      ELSE
                                         DO is=1,npol
                                            ps_nc(is) = ps_nc(is) + &
                                               int2(ih,jh,ipol,na,nb)*&
                                               becp1_nc(jkb,is,ibnd,ik)
                                         END DO
                                      ENDIF
                                   ELSE
                                      ps = ps + int2 (ih, jh, ipol, na, nb) * &
                                             becp1 (jkb, ibnd,ik)
                                   END IF
                                enddo
                                do jbnd = startb, lastb
                                   IF (noncolin) THEN
                                      aux1(jbnd) = aux1 (jbnd) + &
                                        ps_nc(1)*CONJG(becq(ikb,1,jbnd,ik))+&
                                        ps_nc(2)*CONJG(becq(ikb,2,jbnd,ik))
                                   ELSE
                                      aux1(jbnd) = aux1 (jbnd) + &
                                        ps * CONJG(becq(ikb,1,jbnd,ik))
                                   END IF
                                enddo
                             enddo
                             ijkb0b = ijkb0b + nh (ntb)
                          endif
                       enddo
                    enddo
                    !
                    !     here starts the second loop on the atoms
                    !
                    ijkb0b = 0
                    do ntb = 1, ntyp
                       do nb = 1, nat
                          if (ityp (nb) == ntb) then
                             do jpol = 1, 3
                                nu = 3 * (nb - 1) + jpol
                                aux2 (:) = (0.d0, 0.d0)
                                do ih = 1, nh (ntb)
                                   ikb = ijkb0b + ih
                                   do jbnd = startb, lastb
                                      IF (noncolin) THEN
                                         aux2 (jbnd) = aux2 (jbnd) + &
                                           wgg(ibnd, jbnd, ik) * &
                                        (CONJG(alphap_nc(ikb,1,ibnd,jpol,ik))*&
                                            ps3_nc (ikb, 1, jbnd) + &
                                            CONJG(becp1_nc (ikb,1,ibnd, ik)) * &
                                            ps4_nc (ikb, 1, jbnd, jpol) +  &
                                         CONJG(alphap_nc(ikb,2,ibnd,jpol,ik))* &
                                            ps3_nc (ikb,2,jbnd) + &
                                            CONJG(becp1_nc (ikb,2,ibnd,ik)) * &
                                            ps4_nc (ikb, 2, jbnd, jpol) )
                                      ELSE
                                         aux2 (jbnd) = aux2 (jbnd) + &
                                           wgg (ibnd, jbnd, ik) * &
                                           (CONJG(alphap(ikb,ibnd,jpol,ik)) * &
                                            ps3 (ikb, jbnd) + &
                                            CONJG(becp1 (ikb, ibnd, ik) ) * &
                                            ps4 (ikb, jbnd, jpol) )
                                      END IF
                                   enddo
                                enddo
                                do jbnd = startb, lastb
                                   dynwrk (nu, mu) = dynwrk (nu, mu) + &
                                        2.d0*wk(ikk) * aux2(jbnd) * aux1(jbnd)
                                enddo
                             enddo
                             ijkb0b = ijkb0b + nh (ntb)
                          endif
                       enddo
                    enddo
                 enddo
              enddo
              ijkb0 = ijkb0 + nh (nt)
           endif
        enddo
     enddo
  enddo
#ifdef __PARA
  call mp_sum ( dynwrk, intra_pool_comm )
#endif
  do nu_i = 1, 3 * nat
     do nu_j = 1, 3 * nat
        ps = (0.0d0, 0.0d0)
        do na_jcart = 1, 3 * nat
           do na_icart = 1, 3 * nat
              ps = ps + CONJG(u (na_icart, nu_i) ) * dynwrk (na_icart, &
                   na_jcart) * u (na_jcart, nu_j)
           enddo
        enddo
        wdyn (nu_i, nu_j) = wdyn (nu_i, nu_j) + ps
     enddo
  enddo
  !      call tra_write_matrix('nldyn wdyn',wdyn,u,nat)
  !      call stop_ph(.true.)
  IF (noncolin) THEN
     deallocate (ps4_nc)
     deallocate (ps3_nc)
     deallocate (ps2_nc)
     deallocate (ps1_nc)
     deallocate (deff_nc)
  ELSE
     deallocate (ps4)
     deallocate (ps3)
     deallocate (ps2)
     deallocate (ps1)
     deallocate (deff)
  END IF
  return
end subroutine compute_nldyn
