!
! ------------------------------------------------------------------
function atomic_number(atom)
  ! ------------------------------------------------------------------
  !
  implicit none
  character(len=2) :: atom
  integer :: atomic_number

  character(len=2) :: elements(94) 
  data elements/' H',                              'He', &
                'Li','Be',' B',' C',' N',' O',' F','Ne', &
                'Na','Mg','Al','Si',' P',' S','Cl','Ar', &
                ' K','Ca','Sc','Ti',' V','Cr','Mn',      &
                          'Fe','Co','Ni','Cu','Zn',      &
                          'Ga','Ge','As','Se','Br','Kr', &
                'Rb','Sr',' Y','Zr','Nb','Mo','Tc',      &
                          'Ru','Rh','Pd','Ag','Cd',      &
                          'In','Sn','Sb','Te',' I','Xe', &
                'Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd', &
                               'Tb','Dy','Ho','Er','Tm','Yb','Lu', &
                               'Hf','Ta',' W','Re','Os', &
                          'Ir','Pt','Au','Hg',           &
                          'Tl','Pb','Bi','Po','At','Rn', &
                'Fr','Ra','Ac','Th','Pa',' U','Np','Pu' /
  character(len=1), external :: capital, lowercase
  integer :: n

  if (len_trim(atom) == 1) then
     atom(2:2)=capital(atom(1:1))
     atom(1:1)=' '
  else if (atom(1:1) == ' ') then
     atom(2:2)=capital(atom(2:2))
  else
     atom(1:1)=capital(atom(1:1))
     atom(2:2)=lowercase(atom(2:2))
  end if
      
  do n=1,94
     if ( atom == elements(n) ) then
        atomic_number=n
        return
     end if
  end do

  atomic_number = 0
  print '(''Atom '',a2,'' not found'')', atom
  stop

end function atomic_number
!
! ------------------------------------------------------------------
function atom_name(atomic_number)
  ! ------------------------------------------------------------------
  !
  integer :: atomic_number
  character(len=2) :: atom_name

  character(len=2) :: elements(94)
  data elements/' H',                              'He', &
                'Li','Be',' B',' C',' N',' O',' F','Ne', &
                'Na','Mg','Al','Si',' P',' S','Cl','Ar', &
                ' K','Ca','Sc','Ti',' V','Cr','Mn',      &
                          'Fe','Co','Ni','Cu','Zn',      &
                          'Ga','Ge','As','Se','Br','Kr', &
                'Rb','Sr',' Y','Zr','Nb','Mo','Tc',      &
                          'Ru','Rh','Pd','Ag','Cd',      &
                          'In','Sn','Sb','Te',' I','Xe', &
                'Cs','Ba','La','Ce','Pr','Nd','Pm','Sm','Eu','Gd', &
                               'Tb','Dy','Ho','Er','Tm','Yb','Lu', &
                               'Hf','Ta',' W','Re','Os', &
                          'Ir','Pt','Au','Hg',           &
                          'Tl','Pb','Bi','Po','At','Rn', &
                'Fr','Ra','Ac','Th','Pa',' U','Np','Pu' /

  if (atomic_number < 1 .or. atomic_number > 94) then
     call errore('atom_name','invalid atomic number',1000+atomic_number)
  else
     atom_name=elements(atomic_number)
  end if
  return

end function atom_name
