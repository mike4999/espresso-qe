# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 0 <= __IOTK_MAXRANK

# 64 "iotk_attr.spp"
! This is needed as a workaround for bugged pack 
subroutine iotk_private_pack_COMPLEX1(out,in,n,l)
    use iotk_base
    implicit none
    integer,                                    intent(in)  :: n,l
# 73 "iotk_attr.spp"
    COMPLEX (kind=__IOTK_COMPLEX1), intent(out) :: out(n)
    COMPLEX (kind=__IOTK_COMPLEX1), intent(in)  :: in(n)
# 76 "iotk_attr.spp"
    out = in
end subroutine iotk_private_pack_COMPLEX1

# 81 "iotk_attr.spp"
subroutine iotk_write_COMPLEX1(val,string,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_fmt_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in) :: val(:)
#ifdef __IOTK_WORKAROUND6
  character(len=*)              :: string
#else
  character(len=*), intent(out) :: string
#endif
  integer, intent(out) :: ierr
  character(len=100) :: tmpval
  integer :: index,iostat
  ierr = 0
  iostat = 0 
  string(1:1) = iotk_eos
  if(size(val)==0) return
  if(len(string)==0) then
    call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 103 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
    return
  end if
  do index=1,size(val)
# 120 "iotk_attr.spp"
    write(tmpval,trim(iotk_wfmt("COMPLEX",kind(val),size(val),-1)),iostat=iostat) val(index)
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,' ')
# 122 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
    call iotk_strcat(string,trim(adjustl(tmpval))//" ",ierr)
    if(ierr/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 127 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
      return
    end if
# 131 "iotk_attr.spp"
  end do
! taglio l'ultimo spazio
  string(iotk_strlen(string):iotk_strlen(string)) = iotk_eos
end subroutine iotk_write_COMPLEX1
# 137 "iotk_attr.spp"

# 141 "iotk_attr.spp"
subroutine iotk_read_COMPLEX1(val,string,index,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX1), intent(inout) :: val(:)
  character(len=*), intent(in) :: string
  integer, intent(inout) :: index
  integer, intent(out) :: ierr
  logical :: check
  integer :: pos,pos1,iostat
  integer :: maxindex
# 155 "iotk_attr.spp"
  real(kind=__IOTK_COMPLEX1) :: tmpreal
  complex(kind=__IOTK_COMPLEX1) :: tmpcomplex
# 158 "iotk_attr.spp"
  pos = 0
  pos1= 0
  ierr = 0
  iostat = 0
# 163 "iotk_attr.spp"
   maxindex = 2 * size(val)
# 167 "iotk_attr.spp"
! PER ORA CONSIDERA LE VIRGOLE COME SPAZII
  do
    pos = verify(string(pos1+1:)," ,")+pos1
    if(pos==pos1) exit
    pos = pos - 1
    pos1 = scan(string(pos+1:)," ,")+pos
    if(pos1==pos) pos1 = len(string) + 1
!LEGGI string(pos+1:pos1-1)
    index = index+1
    if(index>maxindex) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,'Too many data')
    end if
# 186 "iotk_attr.spp"
    read(string(pos+1:pos1-1),"(G100.95)",iostat=iostat) tmpreal
    if(modulo(index,2)==1) then
      tmpcomplex = cmplx(tmpreal,aimag((val((index+1)/2))))
    else
      tmpcomplex = cmplx(real(val((index+1)/2)),tmpreal)
    end if
    val((index+1)/2) = tmpcomplex
# 200 "iotk_attr.spp"
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,'Error reading from string')
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"string",string(pos+1:pos1-1))
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
# 205 "iotk_attr.spp"
    if(pos1>=len(string)) exit
  end do
end subroutine iotk_read_COMPLEX1
# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_0(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val 
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 264 "iotk_attr.spp"
  call iotk_write((/val/),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_0

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_0(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val 
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val 
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default 
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(1))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*1) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 396 "iotk_attr.spp"
  val = tmpval(1)
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_0
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_0
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_0

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 1 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_1(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_1

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_1(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_1
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_1
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_1

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 2 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_2(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_2

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_2(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_2
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_2
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_2

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 3 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_3(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_3

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_3(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_3
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_3
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_3

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 4 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_4(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_4

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_4(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_4
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_4
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_4

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 5 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_5(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_5

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_5(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_5
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_5
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_5

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 6 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_6(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_6

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_6(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_6
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_6
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_6

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX1
#if 7 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX1_7(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX1), intent(in)  :: val (:,:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX1_7

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX1_7(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX1)                        :: val (:,:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX1), intent(out)           :: val (:,:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX1), optional, intent(in)  :: default (:,:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX1), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX1_7
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX1_7
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX1_7

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 0 <= __IOTK_MAXRANK

# 64 "iotk_attr.spp"
! This is needed as a workaround for bugged pack 
subroutine iotk_private_pack_COMPLEX2(out,in,n,l)
    use iotk_base
    implicit none
    integer,                                    intent(in)  :: n,l
# 73 "iotk_attr.spp"
    COMPLEX (kind=__IOTK_COMPLEX2), intent(out) :: out(n)
    COMPLEX (kind=__IOTK_COMPLEX2), intent(in)  :: in(n)
# 76 "iotk_attr.spp"
    out = in
end subroutine iotk_private_pack_COMPLEX2

# 81 "iotk_attr.spp"
subroutine iotk_write_COMPLEX2(val,string,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_fmt_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in) :: val(:)
#ifdef __IOTK_WORKAROUND6
  character(len=*)              :: string
#else
  character(len=*), intent(out) :: string
#endif
  integer, intent(out) :: ierr
  character(len=100) :: tmpval
  integer :: index,iostat
  ierr = 0
  iostat = 0 
  string(1:1) = iotk_eos
  if(size(val)==0) return
  if(len(string)==0) then
    call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 103 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
    return
  end if
  do index=1,size(val)
# 120 "iotk_attr.spp"
    write(tmpval,trim(iotk_wfmt("COMPLEX",kind(val),size(val),-1)),iostat=iostat) val(index)
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,' ')
# 122 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
    call iotk_strcat(string,trim(adjustl(tmpval))//" ",ierr)
    if(ierr/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 127 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
      return
    end if
# 131 "iotk_attr.spp"
  end do
! taglio l'ultimo spazio
  string(iotk_strlen(string):iotk_strlen(string)) = iotk_eos
end subroutine iotk_write_COMPLEX2
# 137 "iotk_attr.spp"

# 141 "iotk_attr.spp"
subroutine iotk_read_COMPLEX2(val,string,index,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX2), intent(inout) :: val(:)
  character(len=*), intent(in) :: string
  integer, intent(inout) :: index
  integer, intent(out) :: ierr
  logical :: check
  integer :: pos,pos1,iostat
  integer :: maxindex
# 155 "iotk_attr.spp"
  real(kind=__IOTK_COMPLEX2) :: tmpreal
  complex(kind=__IOTK_COMPLEX2) :: tmpcomplex
# 158 "iotk_attr.spp"
  pos = 0
  pos1= 0
  ierr = 0
  iostat = 0
# 163 "iotk_attr.spp"
   maxindex = 2 * size(val)
# 167 "iotk_attr.spp"
! PER ORA CONSIDERA LE VIRGOLE COME SPAZII
  do
    pos = verify(string(pos1+1:)," ,")+pos1
    if(pos==pos1) exit
    pos = pos - 1
    pos1 = scan(string(pos+1:)," ,")+pos
    if(pos1==pos) pos1 = len(string) + 1
!LEGGI string(pos+1:pos1-1)
    index = index+1
    if(index>maxindex) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,'Too many data')
    end if
# 186 "iotk_attr.spp"
    read(string(pos+1:pos1-1),"(G100.95)",iostat=iostat) tmpreal
    if(modulo(index,2)==1) then
      tmpcomplex = cmplx(tmpreal,aimag((val((index+1)/2))))
    else
      tmpcomplex = cmplx(real(val((index+1)/2)),tmpreal)
    end if
    val((index+1)/2) = tmpcomplex
# 200 "iotk_attr.spp"
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,'Error reading from string')
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"string",string(pos+1:pos1-1))
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
# 205 "iotk_attr.spp"
    if(pos1>=len(string)) exit
  end do
end subroutine iotk_read_COMPLEX2
# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_0(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val 
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 264 "iotk_attr.spp"
  call iotk_write((/val/),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_0

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_0(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val 
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val 
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default 
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(1))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*1) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 396 "iotk_attr.spp"
  val = tmpval(1)
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_0
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_0
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_0

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 1 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_1(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_1

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_1(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_1
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_1
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_1

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 2 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_2(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_2

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_2(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_2
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_2
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_2

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 3 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_3(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_3

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_3(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_3
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_3
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_3

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 4 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_4(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_4

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_4(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_4
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_4
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_4

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 5 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_5(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_5

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_5(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_5
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_5
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_5

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 6 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_6(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_6

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_6(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_6
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_6
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_6

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX2
#if 7 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX2_7(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX2), intent(in)  :: val (:,:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX2_7

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX2_7(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX2)                        :: val (:,:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX2), intent(out)           :: val (:,:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX2), optional, intent(in)  :: default (:,:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX2), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX2_7
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX2_7
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX2_7

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 0 <= __IOTK_MAXRANK

# 64 "iotk_attr.spp"
! This is needed as a workaround for bugged pack 
subroutine iotk_private_pack_COMPLEX3(out,in,n,l)
    use iotk_base
    implicit none
    integer,                                    intent(in)  :: n,l
# 73 "iotk_attr.spp"
    COMPLEX (kind=__IOTK_COMPLEX3), intent(out) :: out(n)
    COMPLEX (kind=__IOTK_COMPLEX3), intent(in)  :: in(n)
# 76 "iotk_attr.spp"
    out = in
end subroutine iotk_private_pack_COMPLEX3

# 81 "iotk_attr.spp"
subroutine iotk_write_COMPLEX3(val,string,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_fmt_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in) :: val(:)
#ifdef __IOTK_WORKAROUND6
  character(len=*)              :: string
#else
  character(len=*), intent(out) :: string
#endif
  integer, intent(out) :: ierr
  character(len=100) :: tmpval
  integer :: index,iostat
  ierr = 0
  iostat = 0 
  string(1:1) = iotk_eos
  if(size(val)==0) return
  if(len(string)==0) then
    call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 103 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
    return
  end if
  do index=1,size(val)
# 120 "iotk_attr.spp"
    write(tmpval,trim(iotk_wfmt("COMPLEX",kind(val),size(val),-1)),iostat=iostat) val(index)
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,' ')
# 122 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
    call iotk_strcat(string,trim(adjustl(tmpval))//" ",ierr)
    if(ierr/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 127 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
      return
    end if
# 131 "iotk_attr.spp"
  end do
! taglio l'ultimo spazio
  string(iotk_strlen(string):iotk_strlen(string)) = iotk_eos
end subroutine iotk_write_COMPLEX3
# 137 "iotk_attr.spp"

# 141 "iotk_attr.spp"
subroutine iotk_read_COMPLEX3(val,string,index,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX3), intent(inout) :: val(:)
  character(len=*), intent(in) :: string
  integer, intent(inout) :: index
  integer, intent(out) :: ierr
  logical :: check
  integer :: pos,pos1,iostat
  integer :: maxindex
# 155 "iotk_attr.spp"
  real(kind=__IOTK_COMPLEX3) :: tmpreal
  complex(kind=__IOTK_COMPLEX3) :: tmpcomplex
# 158 "iotk_attr.spp"
  pos = 0
  pos1= 0
  ierr = 0
  iostat = 0
# 163 "iotk_attr.spp"
   maxindex = 2 * size(val)
# 167 "iotk_attr.spp"
! PER ORA CONSIDERA LE VIRGOLE COME SPAZII
  do
    pos = verify(string(pos1+1:)," ,")+pos1
    if(pos==pos1) exit
    pos = pos - 1
    pos1 = scan(string(pos+1:)," ,")+pos
    if(pos1==pos) pos1 = len(string) + 1
!LEGGI string(pos+1:pos1-1)
    index = index+1
    if(index>maxindex) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,'Too many data')
    end if
# 186 "iotk_attr.spp"
    read(string(pos+1:pos1-1),"(G100.95)",iostat=iostat) tmpreal
    if(modulo(index,2)==1) then
      tmpcomplex = cmplx(tmpreal,aimag((val((index+1)/2))))
    else
      tmpcomplex = cmplx(real(val((index+1)/2)),tmpreal)
    end if
    val((index+1)/2) = tmpcomplex
# 200 "iotk_attr.spp"
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,'Error reading from string')
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"string",string(pos+1:pos1-1))
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
# 205 "iotk_attr.spp"
    if(pos1>=len(string)) exit
  end do
end subroutine iotk_read_COMPLEX3
# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_0(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val 
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 264 "iotk_attr.spp"
  call iotk_write((/val/),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_0

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_0(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val 
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val 
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default 
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(1))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*1) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 396 "iotk_attr.spp"
  val = tmpval(1)
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_0
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_0
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_0

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 1 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_1(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_1

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_1(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_1
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_1
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_1

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 2 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_2(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_2

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_2(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_2
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_2
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_2

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 3 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_3(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_3

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_3(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_3
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_3
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_3

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 4 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_4(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_4

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_4(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_4
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_4
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_4

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 5 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_5(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_5

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_5(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_5
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_5
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_5

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 6 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_6(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_6

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_6(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_6
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_6
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_6

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX3
#if 7 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX3_7(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX3), intent(in)  :: val (:,:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX3_7

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX3_7(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX3)                        :: val (:,:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX3), intent(out)           :: val (:,:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX3), optional, intent(in)  :: default (:,:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX3), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX3_7
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX3_7
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX3_7

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 0 <= __IOTK_MAXRANK

# 64 "iotk_attr.spp"
! This is needed as a workaround for bugged pack 
subroutine iotk_private_pack_COMPLEX4(out,in,n,l)
    use iotk_base
    implicit none
    integer,                                    intent(in)  :: n,l
# 73 "iotk_attr.spp"
    COMPLEX (kind=__IOTK_COMPLEX4), intent(out) :: out(n)
    COMPLEX (kind=__IOTK_COMPLEX4), intent(in)  :: in(n)
# 76 "iotk_attr.spp"
    out = in
end subroutine iotk_private_pack_COMPLEX4

# 81 "iotk_attr.spp"
subroutine iotk_write_COMPLEX4(val,string,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_fmt_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in) :: val(:)
#ifdef __IOTK_WORKAROUND6
  character(len=*)              :: string
#else
  character(len=*), intent(out) :: string
#endif
  integer, intent(out) :: ierr
  character(len=100) :: tmpval
  integer :: index,iostat
  ierr = 0
  iostat = 0 
  string(1:1) = iotk_eos
  if(size(val)==0) return
  if(len(string)==0) then
    call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 103 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
    return
  end if
  do index=1,size(val)
# 120 "iotk_attr.spp"
    write(tmpval,trim(iotk_wfmt("COMPLEX",kind(val),size(val),-1)),iostat=iostat) val(index)
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 122 "iotk_attr.spp"
call iotk_error_msg(ierr,' ')
# 122 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
    call iotk_strcat(string,trim(adjustl(tmpval))//" ",ierr)
    if(ierr/=0) then
      call iotk_error_issue(ierr,"iotk_write",__FILE__,__LINE__)
# 127 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
      return
    end if
# 131 "iotk_attr.spp"
  end do
! taglio l'ultimo spazio
  string(iotk_strlen(string):iotk_strlen(string)) = iotk_eos
end subroutine iotk_write_COMPLEX4
# 137 "iotk_attr.spp"

# 141 "iotk_attr.spp"
subroutine iotk_read_COMPLEX4(val,string,index,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_xtox_interf
  use iotk_misc_interf
  implicit none
  COMPLEX(kind=__IOTK_COMPLEX4), intent(inout) :: val(:)
  character(len=*), intent(in) :: string
  integer, intent(inout) :: index
  integer, intent(out) :: ierr
  logical :: check
  integer :: pos,pos1,iostat
  integer :: maxindex
# 155 "iotk_attr.spp"
  real(kind=__IOTK_COMPLEX4) :: tmpreal
  complex(kind=__IOTK_COMPLEX4) :: tmpcomplex
# 158 "iotk_attr.spp"
  pos = 0
  pos1= 0
  ierr = 0
  iostat = 0
# 163 "iotk_attr.spp"
   maxindex = 2 * size(val)
# 167 "iotk_attr.spp"
! PER ORA CONSIDERA LE VIRGOLE COME SPAZII
  do
    pos = verify(string(pos1+1:)," ,")+pos1
    if(pos==pos1) exit
    pos = pos - 1
    pos1 = scan(string(pos+1:)," ,")+pos
    if(pos1==pos) pos1 = len(string) + 1
!LEGGI string(pos+1:pos1-1)
    index = index+1
    if(index>maxindex) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 177 "iotk_attr.spp"
call iotk_error_msg(ierr,'Too many data')
    end if
# 186 "iotk_attr.spp"
    read(string(pos+1:pos1-1),"(G100.95)",iostat=iostat) tmpreal
    if(modulo(index,2)==1) then
      tmpcomplex = cmplx(tmpreal,aimag((val((index+1)/2))))
    else
      tmpcomplex = cmplx(real(val((index+1)/2)),tmpreal)
    end if
    val((index+1)/2) = tmpcomplex
# 200 "iotk_attr.spp"
    if(iostat/=0) then
      call iotk_error_issue(ierr,"iotk_read",__FILE__,__LINE__)
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,"CVS Revision: 1.7 ")
# 201 "iotk_attr.spp"
call iotk_error_msg(ierr,'Error reading from string')
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"string",string(pos+1:pos1-1))
# 201 "iotk_attr.spp"
call iotk_error_write(ierr,"iostat",iostat)
      return
    end if
# 205 "iotk_attr.spp"
    if(pos1>=len(string)) exit
  end do
end subroutine iotk_read_COMPLEX4
# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_0(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val 
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 264 "iotk_attr.spp"
  call iotk_write((/val/),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_0

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_0(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val 
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val 
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default 
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(1))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*1) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 396 "iotk_attr.spp"
  val = tmpval(1)
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_0
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_0
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_0

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 1 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_1(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_1

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_1(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_1
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_1
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_1

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 2 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_2(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_2

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_2(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_2
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_2
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_2

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 3 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_3(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_3

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_3(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_3
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_3
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_3

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 4 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_4(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_4

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_4(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_4
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_4
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_4

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 5 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_5(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_5

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_5(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_5
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_5
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_5

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 6 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_6(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_6

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_6(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_6
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_6
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_6

# 45 "iotk_attr.spp"

# 47 "iotk_attr.spp"

!------------------------------------------------------------------------------!
! Inclusion of configuration file
#include "iotk_config.h"
!------------------------------------------------------------------------------!

# 55 "iotk_attr.spp"
#include "iotk_auxmacros.h"
# 57 "iotk_attr.spp"

# 59 "iotk_attr.spp"

#ifdef __IOTK_COMPLEX4
#if 7 <= __IOTK_MAXRANK

# 137 "iotk_attr.spp"

# 210 "iotk_attr.spp"

# 213 "iotk_attr.spp"
subroutine iotk_write_attr_COMPLEX4_7(attr,name,val,dummy,first,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*), intent(inout) :: attr
  character(*), intent(in)    :: name
  COMPLEX(kind=__IOTK_COMPLEX4), intent(in)  :: val (:,:,:,:,:,:,:)
  type(iotk_dummytype), optional :: dummy
  logical, optional, intent(in)  :: first
  integer, optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen
  integer :: vallen
  integer :: namlen
  integer :: iostat
  character :: delim
# 235 "iotk_attr.spp"
  character(iotk_vallenx) :: tmpval
  ierrl = 0
  iostat = 0
  if(present(first)) then
    if(first) attr(1:1) = iotk_eos
  end if
  if(.not.iotk_check_name(name)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 242 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Wrong tag name')
# 242 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",trim(name))
    goto 1
  end if
  attlen = iotk_strlen(attr)
  if(attlen==len(attr)) attlen = len_trim(attr)
  namlen = len_trim(name)
# 262 "iotk_attr.spp"
  delim = '"'
# 266 "iotk_attr.spp"
  call iotk_write(pack(val,mask=.true.),tmpval,ierrl)
# 268 "iotk_attr.spp"
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 269 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 273 "iotk_attr.spp"
  vallen = iotk_strlen(tmpval)
  if(attlen+vallen+namlen+5>len(attr)) then
    call iotk_error_issue(ierrl,"iotk_write_attr",__FILE__,__LINE__)
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 275 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute dummy argument is too short')
    goto 1
  end if
  attr(attlen+1:attlen+vallen+namlen+5) = " "//trim(name)//"="//delim//tmpval(1:vallen)//delim//iotk_eos
1 continue
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_write_attr_COMPLEX4_7

# 288 "iotk_attr.spp"
subroutine iotk_scan_attr_COMPLEX4_7(attr,name,val,dummy,found,default,eos,ierr)
  use iotk_base
  use iotk_error_interf
  use iotk_attr_interf, only : iotk_read
  use iotk_str_interf
  use iotk_misc_interf
  implicit none
  character(*),             intent(in)  :: attr
  character(*),             intent(in)  :: name
#ifdef __IOTK_WORKAROUND6
  COMPLEX(kind=__IOTK_COMPLEX4)                        :: val (:,:,:,:,:,:,:)
#else
  COMPLEX(kind=__IOTK_COMPLEX4), intent(out)           :: val (:,:,:,:,:,:,:)
#endif
  type(iotk_dummytype), optional :: dummy
  logical,        optional, intent(out) :: found
  COMPLEX(kind=__IOTK_COMPLEX4), optional, intent(in)  :: default (:,:,:,:,:,:,:)
  logical,        optional, intent(in)  :: eos
  integer,        optional, intent(out) :: ierr
  integer :: ierrl
  integer :: attlen,pos,equal
  character :: delim
  logical :: foundl
  character(iotk_vallenx) :: valc
# 317 "iotk_attr.spp"
  integer :: index
  COMPLEX(kind=__IOTK_COMPLEX4), allocatable :: tmpval (:)
# 320 "iotk_attr.spp"
  ierrl = 0
  attlen=iotk_strlen(attr)
  foundl = .false.
  equal = 0
  do
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) exit
    equal = equal + pos
    pos = scan(attr(equal+1:attlen),"=")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 330 "iotk_attr.spp"
call iotk_error_msg(ierrl,'')
# 330 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",attr(equal+1:attlen))
      goto 1
    end if
    equal = equal + pos
    if(trim(attr(equal-pos:equal-1))==trim(name)) foundl = .true.
    pos = verify(attr(equal+1:attlen)," ")
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 337 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    equal = equal + pos
    delim = attr(equal:equal)
    if(delim/="'" .and. delim/='"') then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 343 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    pos = scan(attr(equal+1:attlen),delim)
    if(pos<=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 348 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
    if(foundl) exit
    equal = equal + pos
  end do
  if(foundl) then
    call iotk_strcpy(valc,attr(equal+1:equal+pos-1),ierrl)
    if(ierrl/=0) then
      call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 357 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
      goto 1
    end if
  else
    goto 1
  end if
# 380 "iotk_attr.spp"
  allocate(tmpval(size(val)))
  index = 0
  call iotk_read(tmpval,valc(1:iotk_strlen(valc)),index,ierrl)
  if(ierrl/=0) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 384 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
    goto 1
  end if
# 388 "iotk_attr.spp"
  if(index/=2*size(val)) then
# 392 "iotk_attr.spp"
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 392 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute size does not match')
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"attr",valc)
# 392 "iotk_attr.spp"
call iotk_error_write(ierrl,"size",size(tmpval))
    goto 1
  end if
# 398 "iotk_attr.spp"
  val = reshape (source=tmpval,shape=shape(val))
# 400 "iotk_attr.spp"
  deallocate(tmpval)
# 402 "iotk_attr.spp"
1 continue
  if(ierrl/=0) foundl=.false.
  if(present(found)) found = foundl
  if(ierrl==0 .and. .not. present(found) .and. .not. present(default) .and. .not. foundl) then
    call iotk_error_issue(ierrl,"iotk_scan_attr",__FILE__,__LINE__)
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,"CVS Revision: 1.7 ")
# 406 "iotk_attr.spp"
call iotk_error_msg(ierrl,'Attribute not found')
# 406 "iotk_attr.spp"
call iotk_error_write(ierrl,"name",name)
    ierrl = - ierrl
  end if
  if(present(default) .and. .not. foundl) then
# 419 "iotk_attr.spp"
    val = default
# 421 "iotk_attr.spp"
  end if
  if(present(ierr)) then
    ierr = ierrl
  else
    if(ierrl/=0) call iotk_error_handler(ierrl)
  end if
end subroutine iotk_scan_attr_COMPLEX4_7
# 429 "iotk_attr.spp"

#endif
#endif

subroutine iotk_attr_dummy_COMPLEX4_7
  write(0,*)
end subroutine iotk_attr_dummy_COMPLEX4_7

# 45 "iotk_attr.spp"

