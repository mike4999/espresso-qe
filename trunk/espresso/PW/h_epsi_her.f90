!
! Copyright (C) 2005 Paolo Umari
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!

#include "f_defs.h"
!-----------------------------------------------------------------------
subroutine h_epsi_her(lda, n,nbande, ik, psi, hpsi)
  !-----------------------------------------------------------------------
  !
  ! this subrutine applies w_k+w_k* on psi, see strategy in Souza, PRB
  ! the output is pu in hpi
  ! legge le funzioni d'onda vecchie e da queste calcola il gradiente
  ! che trasforma in operatore e poi hermetizza
  !
  ! In evcel must be the unmodified wavefunctions

  USE kinds,    ONLY : DP
  USE us
  USE wvfct,    ONLY : igk, g2kin, npwx, npw, nbnd, nbndx
  USE gsmooth,  ONLY : nls, nr1s, nr2s, nr3s, nrx1s, nrx2s, nrx3s, nrxxs
  USE ldaU,     ONLY : lda_plus_u
  USE lsda_mod, ONLY : current_spin, nspin
  USE scf,      ONLY : vrs  
  USE gvect
  USE uspp
  USE uspp_param
  USE bp
  USE basis
  USE klist
  USE cell_base, ONLY: at, alat, tpiba, omega, tpiba2
  USE ions_base, ONLY: ityp, tau, nat,ntyp => nsp
  USE io_files, ONLY: iunefield, nwordwfc
  USE constants, ONLY : e2, pi, tpi, fpi
  USE fixed_occ
    
  
  implicit none
  !
  INTEGER :: lda, n! leading dimesion, e n numero onde piane
  INTEGER :: nbande!numero bande da processare
  INTEGER :: ik! kapa punto
  
  COMPLEX(DP) :: psi (lda, nbande ), hpsi (lda,nbande)
  !
!  --- Internal definitions ---

   COMPLEX(DP), ALLOCATABLE  :: evct(:,:)!per funzioni d'onda temporanee
   COMPLEX(DP), ALLOCATABLE  :: evcp(:,:)!per gradiente ik+1
   COMPLEX(DP), ALLOCATABLE  :: evcm(:,:)!per gradiente ik-1
   INTEGER :: i
   INTEGER :: igk1(npwx)
   INTEGER :: igk0(npwx)
   INTEGER :: ig
   INTEGER :: ind1
   INTEGER :: info
   INTEGER :: is
   INTEGER :: istring
   INTEGER :: iv
   INTEGER :: ivpt(nbnd)
   INTEGER :: j
   INTEGER :: jkb
   INTEGER :: jkb_bp
   INTEGER :: jkb1
   INTEGER :: job
   INTEGER :: jv
   INTEGER :: kindex
   INTEGER :: kort
   INTEGER :: kpar
   INTEGER :: kpoint
   INTEGER :: kstart
   INTEGER :: m
   INTEGER :: mb
   INTEGER :: mk1
   INTEGER :: mk2
   INTEGER :: mk3
   INTEGER :: mod_elec_dw
   INTEGER :: mod_elec_tot
   INTEGER :: mod_elec_up
   INTEGER :: mod_ion(nat)
   INTEGER :: mod_ion_dw
   INTEGER :: mod_ion_tot
   INTEGER :: mod_ion_up
   INTEGER :: mod_tot
   INTEGER :: n1
   INTEGER :: n2
   INTEGER :: n3
   INTEGER :: na
   INTEGER :: nb
   INTEGER :: ng
   INTEGER :: nhjkb
   INTEGER :: nhjkbm
   INTEGER :: nkbtona(nkb)
   INTEGER :: nkbtonh(nkb)
   INTEGER :: nkort
   INTEGER :: np
   INTEGER :: npw1
   INTEGER :: npw0
   INTEGER :: nstring
   INTEGER :: nt
   INTEGER :: ik_stringa!ik relativo alla stringa di appartenenza
   LOGICAL :: lodd
   REAL(dp) :: dk(3)
   REAL(dp) :: dkm(3)! -dk
   REAL(dp) :: dkmod
   REAL(dp) :: el_loc
   REAL(dp) :: eps
   REAL(dp) :: fac
   REAL(dp) :: g2kin_bp(npwx)
   REAL(dp) :: gpar(3)
   REAL(dp) :: gtr(3)
   REAL(dp) :: gvec
   REAL(dp) :: ln(-nr1:nr1,-nr2:nr2,-nr3:nr3)
   REAL(dp) :: ln0(-nr1:nr1,-nr2:nr2,-nr3:nr3)!corrispondenza tra coordinate g vettore generale e numero g vettore locale a kappa
   REAL(dp) :: pdl_elec_dw
   REAL(dp) :: pdl_elec_tot
   REAL(dp) :: pdl_elec_up
   REAL(dp) :: pdl_ion(nat)
   REAL(dp) :: pdl_ion_dw
   REAL(dp) :: pdl_ion_tot
   REAL(dp) :: pdl_ion_up
   REAL(dp) :: pdl_tot
   REAL(dp) :: phidw
   REAL(dp) :: phiup
   REAL(dp) :: rmod
   REAL(dp) :: qrad_dk(nbrx,nbrx,lmaxq,ntyp)
   REAL(dp) :: upol(3)
   REAL(dp) :: weight
   REAL(dp) :: ylm_dk(lmaxq*lmaxq)
   REAL(dp) :: zeta_mod
   COMPLEX(dp) :: aux(ngm)
   COMPLEX(dp) :: aux0(ngm)
   COMPLEX(dp) :: aux1(ngm)
   COMPLEX(dp) :: becp0(nkb,nbnd)
   COMPLEX(dp) :: becp_bp(nkb,nbnd)
   COMPLEX(dp) :: becp1(nkb,nbnd)!usato solo alla fine 
   COMPLEX(dp) :: cdet(2)
   COMPLEX(dp) :: cdwork(nbnd)
   COMPLEX(dp) :: cave
   COMPLEX(dp) :: cave_dw
   COMPLEX(dp) :: cave_up
   COMPLEX(dp) :: det
   COMPLEX(dp) :: dtheta
   COMPLEX(dp) :: mat(nbnd,nbnd)
   COMPLEX(dp) :: pref
   COMPLEX(dp) :: q_dk(nhm,nhm,ntyp)
   COMPLEX(dp) :: q_dkp(nhm,nhm,ntyp)!corrisponde a T^dagger e^(iGx) T
   COMPLEX(dp) :: struc(nat)
   COMPLEX(dp) :: theta0
   COMPLEX(dp) :: zdotc
   COMPLEX(dp) :: zeta

   
   COMPLEX(dp) :: fact!fattore moltiplicativo con tutto dentro
   COMPLEX(dp) :: sca,sca1!prodotti scalari
   COMPLEX(dp) :: ps(nkb,nbndx)
   INTEGER :: ijkb0,  ibnd,jh, ih, ikb


   LOGICAL :: overlap!se true calcolo ultrasoft
   LOGICAL l_cal!flag for doing mat calculation

  
   if(ik <= 0) return

 

!  -------------------------------------------------------------------------   !
!                               INITIALIZATIONS
!  -------------------------------------------------------------------------   !

   ALLOCATE( evct(npwx,nbndx))
   ALLOCATE( evcp(npwx,nbndx))
   ALLOCATE( evcm(npwx,nbndx))
  
   overlap=.true.

!determine the spin polarization

   if(nspin==2) then
      if(ik <= nks/2) then
         is = 1
      else
         is = 2
      endif
   else
      is = 1
   end if


   ik_stringa=mod(ik-1,nppstr)+1
   nstring=nks/nppstr

 
 !  --- Define a small number ---
   eps=0.000001

!  --- Recalculate FFT correspondence (see ggen.f90) ---
   DO ng=1,ngm
      mk1=nint(g(1,ng)*at(1,1)+g(2,ng)*at(2,1)+g(3,ng)*at(3,1))
      mk2=nint(g(1,ng)*at(1,2)+g(2,ng)*at(2,2)+g(3,ng)*at(3,2))
      mk3=nint(g(1,ng)*at(1,3)+g(2,ng)*at(2,3)+g(3,ng)*at(3,3))
      ln(mk1,mk2,mk3) = ng
   END DO
 
   if(okvan) then
!  --- Initialize arrays ---
      jkb_bp=0
      DO nt=1,ntyp
         DO na=1,nat
            IF (ityp(na).eq.nt) THEN
               DO i=1, nh(nt)
                  jkb_bp=jkb_bp+1
                  nkbtona(jkb_bp) = na
                  nkbtonh(jkb_bp) = i
               END DO
            END IF
         END DO
      END DO
   endif
   
   

!  --- Allocate memory for arrays ---
  
 

!  -------------------------------------------------------------------------   !
!           electronic polarization: set values for k-points strings           !
!  -------------------------------------------------------------------------   !

! !  --- Find vector along strings ---
    if(nppstr .ne. 1) then
      gpar(1)=(xk(1,nppstr)-xk(1,1))*DBLE(nppstr)/DBLE(nppstr-1)
      gpar(2)=(xk(2,nppstr)-xk(2,1))*DBLE(nppstr)/DBLE(nppstr-1)
      gpar(3)=(xk(3,nppstr)-xk(3,1))*DBLE(nppstr)/DBLE(nppstr-1)
      gpar(:)=gpar(:)!/at(gdir,gdir)!cella ortorombica!ATTENZIONE
      gvec=dsqrt(gpar(1)**2+gpar(2)**2+gpar(3)**2)*tpiba
   else
      gpar(1)=0.
      gpar(2)=0.
      gpar(3)=0.
      gpar(gdir)=1./at(gdir,gdir)!cella ortorombica
!      gvec=dsqrt(gpar(1)**2+gpar(2)**2+gpar(3)**2)*tpiba
      gvec=tpiba/sqrt(at(gdir,1)**2.+at(gdir,2)**2.+at(gdir,3)**2.)
   endif
      
      
!  --- Find vector between consecutive points in strings ---
   if(nppstr.ne.1) then
      dk(1)=xk(1,2)-xk(1,1)
      dk(2)=xk(2,2)-xk(2,1) 
      dk(3)=xk(3,2)-xk(3,1)
      dkmod=SQRT(dk(1)**2+dk(2)**2+dk(3)**2)*tpiba!cella ortorombica
!      dkmod=tpiba/at(gdir,gdir)/DBLE(nppstr)
   else!caso punto gamma, per adesso solo cella cubica
      dk(1)=0.
      dk(2)=0.
      dk(3)=0.
      dk(gdir)=1./at(gdir,gdir)
!      dkmod=tpiba
      dkmod=tpiba/sqrt(at(gdir,1)**2.+at(gdir,2)**2.+at(gdir,3)**2.)
   endif

   dkm(:)=-dk(:)

!calcola fattore fact
!la carica elettronica e' 2. (unita' Rydberg)
!i fattori sono (-i)/2 AIMAG;  2 carica rydberg; campo ele; 2pi/L   
!ho eliminato la multiplicita' di  spin
!ATTENZIONE in fact va diviso per L:
   if(nspin == 1) then
      fact=CMPLX(0.d0,-1.d0)*efield*(2.d0)/2.d0/dkmod
!      fact=CMPLX(0.,-1.)*efield*(2.)/2./(tpiba/sqrt(at(gdir,1)**2.+at(gdir,2)**2.+at(gdir,3)**2.))
   else
     fact=CMPLX(0.d0,-1.d0)*efield*(2.d0)/2.d0/dkmod/DBLE(nspin)
!      fact=CMPLX(0.,-1.)*efield*nspin*(2.)/2./(tpiba/sqrt(at(gdir,1)**2.+at(gdir,2)**2.+at(gdir,3)**2.))
   endif

!ATTENZIONE :: solo cella cubica e punti kappa CUBICI!!!!!!!!!!!!!!


  
   evcm=(0.,0.)
   evcp=(0.,0.)
 
 

!ATTENZIONE le inizializzazione US magari farle una sola volta

   if(okvan) then
!  -------------------------------------------------------------------------   !
!                  electronic polarization: structure factor                   !
!  -------------------------------------------------------------------------   !

!  --- Calculate structure factor e^{-i dk*R} ---
      DO na=1,nat
         fac=(dk(1)*tau(1,na)+dk(2)*tau(2,na)+dk(3)*tau(3,na))*tpi 
         struc(na)=CMPLX(cos(fac),-sin(fac))
      END DO


!  -------------------------------------------------------------------------   !
!                     electronic polarization: form factor                     !
!  -------------------------------------------------------------------------   !

!  --- Calculate Bessel transform of Q_ij(|r|) at dk [Q_ij^L(|r|)] ---
      CALL calc_btq(dkmod,qrad_dk,0)
   
!  --- Calculate the q-space real spherical harmonics at dk [Y_LM] --- 
      CALL ylm_q(lmaxq*lmaxq,dk,dkmod,ylm_dk)
  
!  --- Form factor: 4 pi sum_LM c_ij^LM Y_LM(Omega) Q_ij^L(|r|) ---
      q_dk=(0.d0,0.d0)
      DO np =1, ntyp
         if(tvanp(np)) then
            DO iv = 1, nh(np)
               DO jv = iv, nh(np)
                  call qvan3(iv,jv,np,pref,ylm_dk,qrad_dk)
                  q_dk(iv,jv,np) = omega*pref
                  q_dk(jv,iv,np) = omega*pref
               ENDDO
            ENDDO
         endif
      ENDDO
   
!  --- Calculate the q-space real spherical harmonics at -dk [Y_LM] --- 
      CALL ylm_q(lmaxq*lmaxq,dkm,dkmod,ylm_dk)
  
!  --- Form factor: 4 pi sum_LM c_ij^LM Y_LM(Omega) Q_ij^L(|r|) ---

      q_dkp=(0.d0,0.d0)
      DO np =1, ntyp
         if(tvanp(np)) then
            DO iv = 1, nh(np)
               DO jv = iv, nh(np)
                  call qvan3(iv,jv,np,pref,ylm_dk,qrad_dk)
                  q_dkp(iv,jv,np) = omega*pref
                  q_dkp(jv,iv,np) = omega*pref
               ENDDO
            ENDDO
         endif
      ENDDO

   endif

!  -------------------------------------------------------------------------   !
!                   electronic polarization: strings phases                    !
!  -------------------------------------------------------------------------   !
  

 
       
!    

!PARTE S-1(k,k-1)       


!       
   if(ik_stringa /= 1) then
         
      CALL gk_sort(xk(1,ik-1),ngm,g,ecutwfc/tpiba2, &
           &    npw0,igk0,g2kin_bp) 
      CALL davcio(evct,nwordwfc,iunefield,ik-1,-1)
!        
!           --- Calculate dot products between wavefunctions

!              --- Dot wavefunctions and betas for PREVIOUS k-point ---
      if(okvan) then
         CALL init_us_2 (npw0,igk0,xk(1,ik-1),vkb)
         CALL ccalbec(nkb, npwx, npw0, nbnd, becp0, vkb, evct)
      endif
!              --- Dot wavefunctions and betas for CURRENT k-point ---
         
      CALL gk_sort(xk(1,ik),ngm,g,ecutwfc/tpiba2, &
           &            npw1,igk1,g2kin_bp)        
         !  --- Recalculate FFT correspondence (see ggen.f90) ---

      ln0=0!inizializza tutto a 0
      DO ig=1,npw1
         mk1=nint(g(1,igk1(ig))*at(1,1)+g(2,igk1(ig))*at(2,1)+g(3,igk1(ig))*at(3,1))
         mk2=nint(g(1,igk1(ig))*at(1,2)+g(2,igk1(ig))*at(2,2)+g(3,igk1(ig))*at(3,2))
         mk3=nint(g(1,igk1(ig))*at(1,3)+g(2,igk1(ig))*at(2,3)+g(3,igk1(ig))*at(3,3))
         ln0(mk1,mk2,mk3) = ig
      END DO
      
      if(okvan) then
         CALL init_us_2 (npw1,igk1,xk(1,ik),vkb)
         CALL ccalbec(nkb,npwx,npw1,nbnd,becp_bp,vkb,evcel)
      endif




!              --- Matrix elements calculation ---

      mat=(0.d0,0.d0)
      DO nb=1,nbnd
         DO mb=1,nbnd
!added support for spin polarized case
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               aux=(0.d0,0.d0)
               aux0=(0.d0,0.d0)
               DO ig=1,npw1
                  aux0(igk1(ig))=evcel(ig,nb)
               END DO

               DO ig=1,npw0
                  aux(igk0(ig))=evct(ig,mb)
                   
               END DO
               mat(nb,mb) = zdotc(ngm,aux0,1,aux,1)
!                    --- Calculate the augmented part: ij=KB projectors, ---
!                    --- R=atom index: SUM_{ijR} q(ijR) <u_nk|beta_iR>   ---
!                    --- <beta_jR|u_mk'> e^i(k-k')*R =                   ---
!                    --- also <u_nk|beta_iR>=<psi_nk|beta_iR> = becp^*   ---
            end if
         END DO
      END DO
      call  reduce(2*nbnd*nbnd,mat)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               if(okvan) then
                  pref = (0.d0,0.d0)
                  DO jkb=1,nkb
                     nhjkb = nkbtonh(jkb)
                     na = nkbtona(jkb)
                     np = ityp(na)
                     nhjkbm = nh(np)
                     jkb1 = jkb - nhjkb
                     DO j = 1,nhjkbm
                        pref = pref+CONJG(becp_bp(jkb,nb))*becp0(jkb1+j,mb) &
                     &        *q_dkp(nhjkb,j,np)*CONJG(struc(na))
                     ENDDO
                  ENDDO
                  mat(nb,mb) = mat(nb,mb) + pref
               endif
            endif
         ENDDO
      ENDDO

!              --- Calculate matrix inverse ---
      CALL zgefa(mat,nbnd,nbnd,ivpt,info)
      CALL errore('h_epsi_her','error in zgefa',abs(info))
      job=1!in sta maniera calcola la inversa
      CALL zgedi(mat,nbnd,nbnd,ivpt,cdet,cdwork,job)
!    mat=S^-1(k,k-1)
      do ig=1,npw0
         gtr(1)=g(1,igk0(ig))
         gtr(2)=g(2,igk0(ig))         
         gtr(3)=g(3,igk0(ig))         
            !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
            !                          --- and the position ng in the ngm array ---
         IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
            n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
                 &    +gtr(3)*at(3,1))
            n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
                 &   +gtr(3)*at(3,2))
            n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
                 &   +gtr(3)*at(3,3))
            ng=ln0(n1,n2,n3)
            if(ng .gt. 0) then
               do m=1,nbnd
                  do nb=1,nbnd
                     evcm(ng,m)=evcm(ng,m) + mat(nb,m)*evct(ig,nb)
                  enddo
               enddo
            end if
         ENDIF
      enddo

! aggiunge parte US in evcm
! calcola |beta_(ik,na,ih)>Q_dkp(na,ih,ij)<|beta_(ik-1,na,ih)| 
      if(okvan) then
         evct(:,:) =  (0.d0, 0.d0)
         ps (:,:) = (0.d0, 0.d0)
         ijkb0 = 0
         do nt = 1, ntyp
            do na = 1, nat
               if (ityp (na) .eq.nt) then
                  do ibnd = 1, nbnd
                     do jh = 1, nh (nt)
                        jkb = ijkb0 + jh
                        do ih = 1, nh (nt)
                           ikb = ijkb0 + ih
                           ps (ikb, ibnd) = ps (ikb, ibnd) + &
                                q_dkp(ih,jh,ityp(na))*CONJG(struc(na))* becp0(jkb,ibnd)
                        enddo
                     enddo
                  enddo
                  ijkb0 = ijkb0 + nh (nt)
               endif
            enddo
         enddo

         call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
              npwx, ps, nkb, (1.d0, 0.d0) , evct, npwx)
         do m=1,nbnd
            do nb=1,nbnd
               do ig=1,npw1
                  evcm(ig,m)=evcm(ig,m) + mat(nb,m)*evct(ig,nb)
               enddo
            enddo
         enddo
      endif
    
 
!           --- End of dot products between wavefunctions and betas ---
   ELSE!qui mettere caso stringa estremale bassa
       

      CALL gk_sort(xk(1,ik+nppstr-1),ngm,g,ecutwfc/tpiba2, &
           &   npw0,igk0,g2kin_bp) 
      CALL davcio(evct,nwordwfc,iunefield,ik+nppstr-1,-1)
!        

!           --- Calculate dot products between wavefunctions

!              --- Dot wavefunctions and betas for PREVIOUS k-point ---
          
      if(okvan) then
         CALL init_us_2 (npw0,igk0,xk(1,ik+nppstr-1),vkb)
         CALL ccalbec(nkb, npwx, npw0, nbnd, becp0, vkb, evct)
      endif
!              --- Dot wavefunctions and betas for CURRENT k-point ---
         
      CALL gk_sort(xk(1,ik),ngm,g,ecutwfc/tpiba2, &
            &                   npw1,igk1,g2kin_bp)        
         !  --- Recalculate FFT correspondence (see ggen.f90) ---

      ln0=0!inizializza tutto a 0
      DO ig=1,npw1
         mk1=nint(g(1,igk1(ig))*at(1,1)+g(2,igk1(ig))*at(2,1)+g(3,igk1(ig))*at(3,1))
         mk2=nint(g(1,igk1(ig))*at(1,2)+g(2,igk1(ig))*at(2,2)+g(3,igk1(ig))*at(3,2))
         mk3=nint(g(1,igk1(ig))*at(1,3)+g(2,igk1(ig))*at(2,3)+g(3,igk1(ig))*at(3,3))
         ln0(mk1,mk2,mk3) = ig
      END DO
       
      if(okvan) then
         CALL init_us_2 (npw1,igk1,xk(1,ik),vkb)
         CALL ccalbec(nkb,npwx,npw1,nbnd,becp_bp,vkb,evcel)
      endif
!              --- Matrix elements calculation ---

      mat=(0.d0,0.d0)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               aux=(0.d0,0.d0)
               aux0=(0.d0,0.d0)
               DO ig=1,npw1
                  aux0(igk1(ig))=evcel(ig,nb)
               END DO
               
               do ig=1,npw0
!                          --- If k'=k+G_o, the relation psi_k+G_o (G-G_o) ---
!                          --- = psi_k(G) is used, gpar=G_o, gtr = G-G_o ---
                  gtr(1)=g(1,igk0(ig)) + gpar(1)
                  gtr(2)=g(2,igk0(ig)) + gpar(2) 
                  gtr(3)=g(3,igk0(ig)) + gpar(3) 
               !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
!                          --- and the position ng in the ngm array ---
                  IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
                     n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
                          +gtr(3)*at(3,1))
                     n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
                          +gtr(3)*at(3,2))
                     n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
                          +gtr(3)*at(3,3))
                     ng=ln(n1,n2,n3) 
                     IF ((ABS(g(1,ng)-gtr(1)) > eps) .OR. &
                          (ABS(g(2,ng)-gtr(2)) > eps) .OR. &
                          (ABS(g(3,ng)-gtr(3)) > eps)) THEN
                        WRITE(6,*) ' error hepsiher: translated G=', &
                             gtr(1),gtr(2),gtr(3), &
                             ' with crystal coordinates',n1,n2,n3, &
                             ' corresponds to ng=',ng,' but G(ng)=', &
                             g(1,ng),g(2,ng),g(3,ng)
                        WRITE(6,*) ' probably because G_par is NOT', &
                             ' a reciprocal lattice vector '
                        WRITE(6,*) ' Possible choices as smallest ', &
                             ' G_par:'
                        DO i=1,50
                           WRITE(6,*) ' i=',i,'   G=', &
                                g(1,i),g(2,i),g(3,i)
                        ENDDO
                        STOP
                     ENDIF
                  ELSE 
                     WRITE(6,*) ' |gtr| > gcutm  for gtr=', &
                          gtr(1),gtr(2),gtr(3) 
                     STOP
                  END IF  
                  aux(ng)=evct(ig,mb)
               ENDDO
              
               mat(nb,mb) = zdotc(ngm,aux0,1,aux,1)
            endif
         END DO
      END DO
      call reduce(2*nbnd*nbnd,mat)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
!                    --- Calculate the augmented part: ij=KB projectors, ---
!                    --- R=atom index: SUM_{ijR} q(ijR) <u_nk|beta_iR>   ---
!                    --- <beta_jR|u_mk'> e^i(k-k')*R =                   ---
!                    --- also <u_nk|beta_iR>=<psi_nk|beta_iR> = becp^*   ---
               if (okvan) then 
                  pref = (0.d0,0.d0)
                  DO jkb=1,nkb
                     nhjkb = nkbtonh(jkb)
                     na = nkbtona(jkb)
                     np = ityp(na)
                     nhjkbm = nh(np)
                     jkb1 = jkb - nhjkb
                     DO j = 1,nhjkbm
                        pref = pref+CONJG(becp_bp(jkb,nb))*becp0(jkb1+j,mb) &
                             *q_dkp(nhjkb,j,np)*CONJG(struc(na))
                     ENDDO
                  ENDDO
                  mat(nb,mb) = mat(nb,mb) + pref
               endif
            endif
         ENDDO
      ENDDO

!              --- Calculate matrix inverse ---
      CALL zgefa(mat,nbnd,nbnd,ivpt,info)
      CALL errore('h_epsi_her','error in zgefa',abs(info))
      job=1!in sta maniera calcola la inversa
      CALL zgedi(mat,nbnd,nbnd,ivpt,cdet,cdwork,job)
     
!    mat=S^-1(k,k-1)
        
      do ig=1,npw0
         gtr(1)=g(1,igk0(ig)) + gpar(1)
         gtr(2)=g(2,igk0(ig)) + gpar(2)        
         gtr(3)=g(3,igk0(ig)) + gpar(3) 
          
            !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
            !                          --- and the position ng in the ngm array ---
         IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
            n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
              &      +gtr(3)*at(3,1))
            n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
              &      +gtr(3)*at(3,2))
            n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
              &      +gtr(3)*at(3,3))
            ng=ln0(n1,n2,n3) 
            if(ng .gt. 0) then
               do m=1,nbnd
                  do nb=1,nbnd
                     evcm(ng,m)=evcm(ng,m) + mat(nb,m)*evct(ig,nb)
                  enddo
               enddo
            endif
         ENDIF
      enddo
      if(okvan) then
         evct(:,:) =  (0.d0, 0.d0)
         ps (:,:) = (0.d0, 0.d0)
         ijkb0 = 0
         do nt = 1, ntyp
            do na = 1, nat
               if (ityp (na) .eq.nt) then
                  do ibnd = 1, nbnd
                     do jh = 1, nh (nt)
                        jkb = ijkb0 + jh
                        do ih = 1, nh (nt)
                           ikb = ijkb0 + ih
                           ps (ikb, ibnd) = ps (ikb, ibnd) + &
                                q_dkp(ih,jh,ityp(na))*CONJG(struc(na))* becp0(jkb,ibnd)
                        enddo
                     enddo
                  enddo
                  ijkb0 = ijkb0 + nh (nt)
               endif
            enddo
         enddo

         call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
                 npwx, ps, nkb, (1.d0, 0.d0) , evct, npwx)
         do m=1,nbnd
            do nb=1,nbnd
               do ig=1,npw1
                  evcm(ig,m)=evcm(ig,m) + mat(nb,m)*evct(ig,nb)
               enddo
            enddo
         enddo
      endif
   ENDIF

! SECONDA parte S-1(k,k+1)

    
!       
   if(ik_stringa /= nppstr) then
         
      CALL gk_sort(xk(1,ik+1),ngm,g,ecutwfc/tpiba2, &
           &    npw0,igk0,g2kin_bp) 
      CALL davcio(evct,nwordwfc,iunefield,ik+1,-1)
!        

!           --- Calculate dot products between wavefunctions

!              --- Dot wavefunctions and betas for PREVIOUS k-point ---
         
      if(okvan) then
         CALL init_us_2 (npw0,igk0,xk(1,ik+1),vkb)
         CALL ccalbec(nkb, npwx, npw0, nbnd, becp0, vkb, evct)
      endif
!              --- Dot wavefunctions and betas for CURRENT k-point ---
         
      CALL gk_sort(xk(1,ik),ngm,g,ecutwfc/tpiba2, &
           &                    npw1,igk1,g2kin_bp)        
         !  --- Recalculate FFT correspondence (see ggen.f90) ---

      ln0=0!inizializza tutto a 0
      DO ig=1,npw1
         mk1=nint(g(1,igk1(ig))*at(1,1)+g(2,igk1(ig))*at(2,1)+g(3,igk1(ig))*at(3,1))
         mk2=nint(g(1,igk1(ig))*at(1,2)+g(2,igk1(ig))*at(2,2)+g(3,igk1(ig))*at(3,2))
         mk3=nint(g(1,igk1(ig))*at(1,3)+g(2,igk1(ig))*at(2,3)+g(3,igk1(ig))*at(3,3))
         ln0(mk1,mk2,mk3) = ig
      END DO

      if(okvan) then
         CALL init_us_2 (npw1,igk1,xk(1,ik),vkb)
         CALL ccalbec(nkb,npwx,npw1,nbnd,becp_bp,vkb,evcel)
      endif
         



!              --- Matrix elements calculation ---

      mat=(0.d0,0.d0)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               aux=(0.d0,0.d0)
               aux0=(0.d0,0.d0)
               DO ig=1,npw1
                  aux0(igk1(ig))=evcel(ig,nb)
               END DO
               DO ig=1,npw0
                  
                  aux(igk0(ig))=evct(ig,mb)
                  
               END DO
               mat(nb,mb) = zdotc(ngm,aux0,1,aux,1)
!                    --- Calculate the augmented part: ij=KB projectors, ---
!                    --- R=atom index: SUM_{ijR} q(ijR) <u_nk|beta_iR>   ---
!                    --- <beta_jR|u_mk'> e^i(k-k')*R =                   ---
!                    --- also <u_nk|beta_iR>=<psi_nk|beta_iR> = becp^*   ---
            endif
         END DO
      END DO
      call reduce(2*nbnd*nbnd,mat)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
              
               if(okvan) then
                  pref = (0.d0,0.d0)
                  DO jkb=1,nkb
                     nhjkb = nkbtonh(jkb)
                     na = nkbtona(jkb)
                     np = ityp(na)
                     nhjkbm = nh(np)
                     jkb1 = jkb - nhjkb
                     DO j = 1,nhjkbm
                        pref = pref+CONJG(becp_bp(jkb,nb))*becp0(jkb1+j,mb) &
                             *q_dk(nhjkb,j,np)*struc(na)
                     ENDDO
                  ENDDO
                  mat(nb,mb) = mat(nb,mb) + pref
               endif
            endif
         ENDDO
      ENDDO

!              --- Calculate matrix inverse ---
      CALL zgefa(mat,nbnd,nbnd,ivpt,info)
      CALL errore('h_epsi_her','error in zgefa',abs(info))
      job=1!in sta maniera calcola la inversa
      CALL zgedi(mat,nbnd,nbnd,ivpt,cdet,cdwork,job)
!    mat=S^-1(k,k-1)
      do ig=1,npw0
         gtr(1)=g(1,igk0(ig))
         gtr(2)=g(2,igk0(ig))         
         gtr(3)=g(3,igk0(ig))         
            !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
            !                          --- and the position ng in the ngm array ---
         IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
            n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
             &       +gtr(3)*at(3,1))
            n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
             &       +gtr(3)*at(3,2))
            n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
             &       +gtr(3)*at(3,3))
            ng=ln0(n1,n2,n3)
            if(ng .gt. 0) then
               do m=1,nbnd
                  do nb=1,nbnd
                     evcp(ng,m)=evcp(ng,m) + mat(nb,m)*evct(ig,nb)
                  enddo
               enddo
            endif
         ENDIF
      enddo
      if(okvan) then
         evct(:,:) =  (0.d0, 0.d0)
         ps (:,:) = (0.d0, 0.d0)
         ijkb0 = 0
         do nt = 1, ntyp
            do na = 1, nat
               if (ityp (na) .eq.nt) then
                  do ibnd = 1, nbnd
                     do jh = 1, nh (nt)
                        jkb = ijkb0 + jh
                        do ih = 1, nh (nt)
                           ikb = ijkb0 + ih
                           ps (ikb, ibnd) = ps (ikb, ibnd) + &
                                q_dk(ih,jh,ityp(na))*struc(na)* becp0(jkb,ibnd)
                        enddo
                     enddo
                  enddo
                  ijkb0 = ijkb0 + nh (nt)
               endif
            enddo
         enddo

         call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
                 npwx, ps, nkb, (1.d0, 0.d0) , evct, npwx)
         do m=1,nbnd
            do nb=1,nbnd
               do ig=1,npw1
                  evcp(ig,m)=evcp(ig,m) + mat(nb,m)*evct(ig,nb)
               enddo
            enddo
         enddo
      endif
         
!           --- End of dot products between wavefunctions and betas ---
   else!qui mettere caso stringa estremale alta
       
      CALL gk_sort(xk(1,ik-nppstr+1),ngm,g,ecutwfc/tpiba2, &
           &    npw0,igk0,g2kin_bp) 
      CALL davcio(evct,nwordwfc,iunefield,ik-nppstr+1,-1)
!        

!           --- Calculate dot products between wavefunctions

!              --- Dot wavefunctions and betas for PREVIOUS k-point ---

      if(okvan) then
         CALL init_us_2 (npw0,igk0,xk(1,ik-nppstr+1),vkb)
         CALL ccalbec(nkb, npwx, npw0, nbnd, becp0, vkb, evct)
      endif
!              --- Dot wavefunctions and betas for CURRENT k-point ---
         
      CALL gk_sort(xk(1,ik),ngm,g,ecutwfc/tpiba2, &
                 &              npw1,igk1,g2kin_bp)        
         !  --- Recalculate FFT correspondence (see ggen.f90) ---

      ln0=0!inizializza tutto a 0
      DO ig=1,npw1
         mk1=nint(g(1,igk1(ig))*at(1,1)+g(2,igk1(ig))*at(2,1)+g(3,igk1(ig))*at(3,1))
         mk2=nint(g(1,igk1(ig))*at(1,2)+g(2,igk1(ig))*at(2,2)+g(3,igk1(ig))*at(3,2))
         mk3=nint(g(1,igk1(ig))*at(1,3)+g(2,igk1(ig))*at(2,3)+g(3,igk1(ig))*at(3,3))
         ln0(mk1,mk2,mk3) = ig
      END DO

      if(okvan) then
         CALL init_us_2 (npw1,igk1,xk(1,ik),vkb)
         CALL ccalbec(nkb,npwx,npw1,nbnd,becp_bp,vkb,evcel)
      endif
!              --- Matrix elements calculation ---

      mat=(0.d0,0.d0)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               aux=(0.d0,0.d0)
               aux0=(0.d0,0.d0)
               DO ig=1,npw1
                  aux0(igk1(ig))=evcel(ig,nb)
               END DO
               do ig=1,npw0
!                          --- If k'=k+G_o, the relation psi_k+G_o (G-G_o) ---
!                          --- = psi_k(G) is used, gpar=G_o, gtr = G-G_o ---
                  gtr(1)=g(1,igk0(ig)) - gpar(1)
                  gtr(2)=g(2,igk0(ig)) - gpar(2) 
                  gtr(3)=g(3,igk0(ig)) - gpar(3) 
               !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
!                          --- and the position ng in the ngm array ---
                  IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
                     n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
                          +gtr(3)*at(3,1))
                     n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
                          +gtr(3)*at(3,2))
                     n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
                          +gtr(3)*at(3,3))
                     ng=ln(n1,n2,n3) 
                     IF ((ABS(g(1,ng)-gtr(1)) > eps) .OR. &
                          (ABS(g(2,ng)-gtr(2)) > eps) .OR. &
                          (ABS(g(3,ng)-gtr(3)) > eps)) THEN
                        WRITE(6,*) ' error hepsiher: translated G=', &
                             gtr(1),gtr(2),gtr(3), &
                             ' with crystal coordinates',n1,n2,n3, &
                             ' corresponds to ng=',ng,' but G(ng)=', &
                             g(1,ng),g(2,ng),g(3,ng)
                        WRITE(6,*) ' probably because G_par is NOT', &
                             ' a reciprocal lattice vector '
                        WRITE(6,*) ' Possible choices as smallest ', &
                             ' G_par:'
                        DO i=1,50
                           WRITE(6,*) ' i=',i,'   G=', &
                                g(1,i),g(2,i),g(3,i)
                        ENDDO
                        STOP
                     ENDIF
                  ELSE 
                     WRITE(6,*) ' |gtr| > gcutm  for gtr=', &
                          gtr(1),gtr(2),gtr(3) 
                     STOP
                  END IF
                  aux(ng)=evct(ig,mb)
               ENDDO
               mat(nb,mb) = zdotc(ngm,aux0,1,aux,1)
!                    --- Calculate the augmented part: ij=KB projectors, ---
!                    --- R=atom index: SUM_{ijR} q(ijR) <u_nk|beta_iR>   ---
!                    --- <beta_jR|u_mk'> e^i(k-k')*R =                   ---
!                    --- also <u_nk|beta_iR>=<psi_nk|beta_iR> = becp^*   ---
            endif
         END DO
      END DO
      call reduce(2*nbnd*nbnd, mat)
      DO nb=1,nbnd
         DO mb=1,nbnd
            l_cal=.true.
            if( nspin==2 .and. tfixed_occ) then
               if(f_inp(nb,is)==0.d0 .or. f_inp(mb,is)==0.d0) then
                  l_cal=.false.
                  if(nb==mb) then
                     mat(nb,mb)=1.d0
                  else
                     mat(nb,mb)=0.d0
                  endif
               endif
            endif
            if(l_cal) then
               if(okvan) then 
                  pref = (0.d0,0.d0)
                  DO jkb=1,nkb
                     nhjkb = nkbtonh(jkb)
                     na = nkbtona(jkb)
                     np = ityp(na)
                     nhjkbm = nh(np)
                     jkb1 = jkb - nhjkb
                     DO j = 1,nhjkbm
                        pref = pref+CONJG(becp_bp(jkb,nb))*becp0(jkb1+j,mb) &
                             *q_dk(nhjkb,j,np)*struc(na)
                     ENDDO
                  ENDDO
                  mat(nb,mb) = mat(nb,mb) + pref
               endif
            endif
         ENDDO
      ENDDO

!              --- Calculate matrix inverse ---
      CALL zgefa(mat,nbnd,nbnd,ivpt,info)
      CALL errore('h_epsi_her','error in zgefa',abs(info))
      job=1!in sta maniera calcola la inversa
      CALL zgedi(mat,nbnd,nbnd,ivpt,cdet,cdwork,job)
       
!    mat=S^-1(k,k-1)
      do ig=1,npw0
         gtr(1)=g(1,igk0(ig)) - gpar(1)
         gtr(2)=g(2,igk0(ig)) - gpar(2)        
         gtr(3)=g(3,igk0(ig)) - gpar(3)        
            !                          --- Find crystal coordinates of gtr, n1,n2,n3 ---
            !                          --- and the position ng in the ngm array ---
         IF (gtr(1)**2+gtr(2)**2+gtr(3)**2 <= gcutm) THEN
            n1=NINT(gtr(1)*at(1,1)+gtr(2)*at(2,1) &
                &    +gtr(3)*at(3,1))
            n2=NINT(gtr(1)*at(1,2)+gtr(2)*at(2,2) &
                &    +gtr(3)*at(3,2))
            n3=NINT(gtr(1)*at(1,3)+gtr(2)*at(2,3) &
                &    +gtr(3)*at(3,3))
            ng=ln0(n1,n2,n3)
            if(ng .gt. 0) then
               do m=1,nbnd
                  do nb=1,nbnd
                     evcp(ng,m)=evcp(ng,m) + mat(nb,m)*evct(ig,nb)
                  end do
               enddo
            end if
         ENDIF
      enddo
      if(okvan) then
         evct(:,:) =  (0.d0, 0.d0)
         ps (:,:) = (0.d0, 0.d0)
         ijkb0 = 0
         do nt = 1, ntyp
            do na = 1, nat
               if (ityp (na) .eq.nt) then
                  do ibnd = 1, nbnd
                     do jh = 1, nh (nt)
                        jkb = ijkb0 + jh
                        do ih = 1, nh (nt)
                           ikb = ijkb0 + ih
                           ps (ikb, ibnd) = ps (ikb, ibnd) + &
                                q_dk(ih,jh,ityp(na))*struc(na)* becp0(jkb,ibnd)
                        enddo
                     enddo
                  enddo
                  ijkb0 = ijkb0 + nh (nt)
               endif
            enddo
         enddo

         call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
                 npwx, ps, nkb, (1.d0, 0.d0) , evct, npwx)
         do m=1,nbnd
            do nb=1,nbnd
               do ig=1,npw1
                  evcp(ig,m)=evcp(ig,m) + mat(nb,m)*evct(ig,nb)
               enddo
            enddo
         enddo
      endif

   ENDIF


   if(okvan) then
      CALL init_us_2 (npw1,igk1,xk(1,ik),vkb)
      CALL ccalbec(nkb, npwx, npw1, nbande, becp0, vkb, psi)
   endif

   if(okvan) then
! aggiunge S a evcp e evcm

      CALL ccalbec(nkb, npwx, npw1, nbnd, becp1, vkb, evcp)   
      ps (:,:) = (0.d0, 0.d0)
      ijkb0 = 0
      do nt = 1, ntyp
         do na = 1, nat
            if (ityp (na) .eq.nt) then
               do ibnd = 1, nbnd
                  do jh = 1, nh (nt)
                     jkb = ijkb0 + jh
                     do ih = 1, nh (nt)
                        ikb = ijkb0 + ih
                        ps (ikb, ibnd) = ps (ikb, ibnd) + &
                             qqq(ih,jh,ityp(na))* becp1(jkb,ibnd)
                     enddo
                  enddo
               enddo
               ijkb0 = ijkb0 + nh (nt)
            endif
         enddo
      enddo
      call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
           npwx, ps, nkb, (1.d0, 0.d0) , evcp, npwx)
      
      CALL ccalbec(nkb, npwx, npw1, nbnd, becp1, vkb, evcm)   
      ps (:,:) = (0.d0, 0.d0)
      ijkb0 = 0
      do nt = 1, ntyp
         do na = 1, nat
            if (ityp (na) .eq.nt) then
               do ibnd = 1, nbnd
                  do jh = 1, nh (nt)
                     jkb = ijkb0 + jh
                     do ih = 1, nh (nt)
                        ikb = ijkb0 + ih
                        ps (ikb, ibnd) = ps (ikb, ibnd) + &
                             qqq(ih,jh,ityp(na))* becp1(jkb,ibnd)
                     enddo
                  enddo
               enddo
               ijkb0 = ijkb0 + nh (nt)
            endif
         enddo
      enddo
      call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
           npwx, ps, nkb, (1.d0, 0.d0) , evcm, npwx)


   endif

 

   do nb=1,nbande!indice su stati psi
      
!applica w_k     
      do mb=1,nbnd!indice su stati evcel        
!questo deve essere calcolato a la US
         sca = zdotc(npw1,evcel(1,mb),1,psi(1,nb),1)
         call reduce(2,sca)

         if(okvan) then 
            pref = (0.d0,0.d0)
          
            DO jkb=1,nkb
               nhjkb = nkbtonh(jkb)
               na = nkbtona(jkb)
               np = ityp(na)
               nhjkbm = nh(np)
               jkb1 = jkb - nhjkb
               DO j = 1,nhjkbm
                  pref = pref+CONJG(becp_bp(jkb,mb))*becp0(jkb1+j,nb) &!ACHTUNG in becp_bp fattori relativi a ik
                       *qqq(nhjkb,j,np)
               ENDDO
            ENDDO
            sca= sca + pref
         endif
         do ig=1,npw1
            hpsi(ig,nb) = hpsi(ig,nb) + &
            &     fact*sca*(evcm(ig,mb)-evcp(ig,mb))!ATTENZIONE AL SEGNO
         enddo
      enddo 
!applica w_k*

      if(.not.okvan) then
         do mb=1,nbnd!indice su stati evcel        
            sca = zdotc(npw1,evcm(1,mb),1,psi(1,nb),1)
            sca1 = zdotc(npw1,evcp(1,mb),1,psi(1,nb),1)
            call reduce(2,sca)
            call reduce(2, sca1)
            
            do ig=1,npw1
               hpsi(ig,nb) = hpsi(ig,nb) + &
                    &     CONJG(fact)*evcel(ig,mb)*(sca-sca1)
            enddo
         enddo
      
   
      else !caso US

! copia evcel in evct per non sciuparlo
         do ig=1,npwx*nbnd
            evct(ig,1)=evcel(ig,1)
         enddo
!  calcola S|evct>
 
         ps (:,:) = (0.d0, 0.d0)
         ijkb0 = 0
         do nt = 1, ntyp
            do na = 1, nat
               if (ityp (na) .eq.nt) then
                  do ibnd = 1, nbnd
                     do jh = 1, nh (nt)
                        jkb = ijkb0 + jh
                        do ih = 1, nh (nt)
                           ikb = ijkb0 + ih
                           ps (ikb, ibnd) = ps (ikb, ibnd) + &
                                qqq(ih,jh,ityp(na))* becp_bp(jkb,ibnd)
                        enddo
                     enddo
                  enddo
                  ijkb0 = ijkb0 + nh (nt)
               endif
            enddo
         enddo
         call ZGEMM ('N', 'N', npw1, nbnd , nkb, (1.d0, 0.d0) , vkb, &!vkb si riferisce a ik ultimo letto ACHTUNG
              npwx, ps, nkb, (1.d0, 0.d0) , evct, npwx)
         do mb=1,nbnd!indice su stati evcel        
            sca = zdotc(npw1,evcm(1,mb),1,psi(1,nb),1)
            sca1 = zdotc(npw1,evcp(1,mb),1,psi(1,nb),1)         
            call reduce(2,sca)
            call reduce(2,sca1)
            do ig=1,npw1
               hpsi(ig,nb) = hpsi(ig,nb) + &
                    &     CONJG(fact)*evct(ig,mb)*(sca-sca1)
            enddo
         enddo
      endif
   ENDDO

   DEALLOCATE( evct)
   DEALLOCATE( evcp)
   DEALLOCATE( evcm)

!   write(6,*) 'Esce'
  
!  --
!------------------------------------------------------------------------------!
   return
 END SUBROUTINE h_epsi_her

!==============================================================================!
