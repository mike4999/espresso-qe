!--------------------------------------------------------------
subroutine write_results 
  !--------------------------------------------------------------
  use ld1inc
  use funct
  implicit none

  integer :: i, j, n, m, im(40), l, ios
  real(kind=dp):: work(ndm), dum, int_0_inf_dr, ravg, r2avg, sij, ene
  logical :: ok
  !
  !
  write(6,'(5x,20(''-''),'' All-electron run '',30(''-''),/)')
  write(6,1150) title
  if(rel.eq.1) write(6,'(5x,''scalar relativistic calculation'')')
  if(rel.eq.2) write(6,'(5x,''dirac relativistic calculation'')')
1150 format(5x,a75)
  if (zed.ne.0.0) write(6,1250) zed
1250 format(/5x,'atomic number is',f6.2)
  write(6,2300) dft(1:len_trim(dft)),lsd,isic,latt,beta,tr2
2300 format(5x,'dft =',a,'   lsd =',i1,' sic =',i1,' latt =',i1, &
       '  beta=',f4.2,' tr2=',1pe7.1)
  write(6,1270) mesh,r(mesh),xmin,dx
1270 format(5x,'mesh =',i4,' r(mesh) =',f10.5,' xmin =',f6.2,' dx =',f8.5)
  if (rel.lt.2) then
     write(6,1000)
1000 format(/5x, &
          'n l     nl                  e(Ryd)','         e(Ha)          e(eV)')
     write(6,1100) &
          (nn(n),ll(n),el(n),isw(n),oc(n),enl(n),enl(n)*0.5_dp, &
          enl(n)*13.6058_dp, n=1,nwf)
  else
     write(6,1001)
1001 format(/5x, &
          'n l j   nl                  e(Ryd)','         e(Ha)          e(eV)')
     write(6,'(5x,"Spin orbit split results")')
     write(6,1120) &
          (nn(n),ll(n),jj(n),el(n),isw(n),oc(n),enl(n),enl(n)*0.5_dp, &
          enl(n)*13.6058_dp, n=1,nwf)
     write(6,'(5x,"Averaged results")')
     ok=.true.
     do n=1,nwf
        if (ll(n).gt.0.and.ok) then
           ene=(enl(n)*2.0_dp*ll(n) &
                + enl(n+1)*(2.0_dp*ll(n)+2.0_dp))/(4.0_dp*ll(n)+2.0_dp)
           write(6,1100) nn(n),ll(n),el(n), isw(n),oc(n)+oc(n+1), &
                ene,ene*0.5_dp, ene*13.6058_dp
           ok=.false.
        else
           if (ll(n).eq.0) &
                write(6,1100) nn(n),ll(n),el(n),isw(n),oc(n), &
                enl(n),enl(n)*0.5_dp,enl(n)*13.6058_dp
           ok=.true.
        endif
     enddo
  endif
1100 format(4x,2i2,5x,a2,i2,'(',f5.2,')',f15.4,f15.4,f15.4)
1120 format(4x,2i2,f4.1,1x,a2,i2,'(',f5.2,')',f15.4,f15.4,f15.4)
  write(6,1200) eps0,iter
1200 format(/5x,'eps =',1pe8.1,'  iter =',i3)
  write(6,*)
  write(6,'(5x,''Etot ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       etot, etot*0.5_dp, etot*13.6058_dp
  write(6,'(/,5x,''Ekin ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')')&
       ekin, ekin*0.5_dp,  ekin*13.6058_dp
  write(6,'(5x,''Encl ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')')&
       encl, encl*0.5_dp, encl*13.6058_dp
  write(6,'(5x,''Eh   ='',f15.6,'' Ry,'',f15.6, '' Ha,'',f15.6,'' eV'')') &
       ehrt, ehrt*0.5_dp, ehrt*13.6058_dp
  write(6,&
       '(5x,''Exc  ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       ecxc, ecxc*0.5_dp, ecxc*13.6058_dp
  write(6,&
       '(5x,''Evxt ='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       evxt, evxt*0.5_dp, evxt*13.6058_dp
  write(6,&
       '(5x,''Epseu='',f15.6,'' Ry,'',f15.6,'' Ha,'',f15.6,'' eV'')') &
       epseu, epseu*0.5_dp, epseu*13.6058_dp
  if (isic.ne.0) then
     write(6,*)
     write(6,'(5x,"SIC information:")') 
     write(6,1300) dhrsic, dhrsic*0.5_dp, dhrsic*13.6058_dp  
     write(6,2310) dxcsic, dxcsic*0.5_dp, dxcsic*13.6058_dp
     write(6,2320) dxcsic+dhrsic,(dxcsic+dhrsic)*0.5_dp,(dxcsic+dhrsic)*13.6058_dp  
     write(6,*)
     write(6,2311) ecxc-dxcsic-dhrsic, &
          &               (ecxc-dxcsic-dhrsic)*0.5_dp, (ecxc-dxcsic-dhrsic)*13.6058_dp  
     write(6,2312) ecxc-dhrsic, &
          &               (ecxc-dhrsic)*0.5_dp, (ecxc-dhrsic)*13.6058_dp 
     write(6,2313) ehrt+dhrsic, &
          &              (ehrt+dhrsic)*0.5_dp, (ehrt+dhrsic)*13.6058_dp 
1300 format(5x,'Esich=',f15.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2310 format(5x,'Esicxc=',f14.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2311 format(5x,'tot-Exc=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2312 format(5x,'int-Exc=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2313 format(5x,'int-Eh=',f14.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
2320 format(5x,'Esictot=',f13.6,' Ry,',f15.6,' Ha,',f15.6,' eV') 
  endif
  write(6,1310)
1310 format(//5x,'normalization and overlap integrals'/)

  do i=1,nwf
     dum=0.0_dp
     do m=1,mesh
        dum=max(dum,abs(psi(m,i)))
        if(dum.eq.abs(psi(m,i)))im(i)=m
     enddo
  enddo

  do i=1,nwf
     do j=i,nwf
        if (ll(i).eq.ll(j)) then
           do m=1,mesh
              work(m)=psi(m,i)*psi(m,j)
           enddo
           sij = int_0_inf_dr(work,r,r2,dx,mesh,2*ll(i)+2)
           if (i.eq.j) then
              do m=1,mesh
                 work(m)=work(m)*r(m)
              enddo
              ravg = int_0_inf_dr(work,r,r2,dx,mesh,2*ll(i)+3)
              do m=1,mesh
                 work(m)=work(m)*r(m)
              enddo
              r2avg = int_0_inf_dr(work,r,r2,dx,mesh,2*ll(i)+4)
              write(6,1400) el(i),el(j),sij, ravg, r2avg, r(im(i))
           else
              write(6,1401) el(i),el(j),sij
           endif
        endif
     enddo
  enddo
1400 format(5x,'s(',a2,'/',a2,') =',f10.6,2x, &
       '<r> =',f9.4,2x,'<r2> =',f10.4,2x,'r(max) =',f9.4)
1401 format(5x,'s(',a2,'/',a2,') =',f10.6)

  if (file_wavefunctions.ne.' ') then
     open(unit=15,file=file_wavefunctions,status='unknown',  &
          err=1110, iostat=ios,form='formatted')
1110 call errore('write_result','opening file_wavefunctions',abs(ios))
     do n=1,mesh 
        write(15,'(8f10.6)') r(n),(psi(n,i),i=nwf,max(1,nwf-6),-1)
     enddo
     close(15)
  endif
  write(6,'(/,5x,20(''-''), '' End of All-electron run '',22(''-''),/)')

  return
end subroutine write_results
