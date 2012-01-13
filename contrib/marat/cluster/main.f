       program transform_pdb
       implicit none
       character*255 infile
       character*255 outfile
       character*16  tar
       logical ofile
       integer i,l,istatus 
       character*72 buffer
       integer ntot
c
       i=1
       call my_get_command_argument(i,buffer,l,istatus)
       if(istatus.ne.0) goto 18
       read(buffer,*) infile
18     continue
       write(*,*) "input file is",trim(infile)
       call cluster(infile)
       stop
c
       end

       subroutine cluster(infile)
       implicit none
       character*(*) infile
c
       integer ntot,nres
       double precision, dimension(:,:), allocatable :: c
       double precision, dimension(:,:), allocatable :: cg
       double precision, dimension(:), allocatable :: cd
       integer, dimension(:), allocatable :: ir
       integer, dimension(:), allocatable :: is
       integer, dimension(:), allocatable :: im
       integer, dimension(:,:), allocatable :: p2
       integer, dimension(:,:), allocatable :: p3
       character*16 , dimension(:), allocatable :: ta,tr
       integer i
       integer n2
 
c
       call smd_pdb_natoms(infile,ntot)
       allocate(c(3,ntot))
       allocate(ta(ntot))
       allocate(tr(ntot))
       allocate(ir(ntot))
c
       call smd_pdb_read_coords(infile,ntot,c)
       call smd_pdb_read_atomres(infile,ntot,ta,tr,ir)
       call smd_pdb_sort_byres(ntot,ta,tr,ir,c)
       call smd_pdb_nres0(nres,ntot,ir)
       allocate(cg(3,nres))
       call smd_pdb_cog(ntot,nres,ir,c,cg)
       n2 = nres*(nres-1)/2
       allocate(p2(2,n2))
       call parse_dimers(nres,cg,n2,p2)
       allocate(p3(3,n2))
       call parse_trimers(n2,p2,n2,2,p2,p3)
!      == deallocate arrays ==
       deallocate(p2)
       deallocate(cg)
       deallocate(ir)
       deallocate(tr)
       deallocate(ta)
       deallocate(c)
       end

      subroutine parse_dimers(nres,cg,nb,p2)
      implicit none
      integer nres
      double precision cg(3,nres)
      integer nb
      integer p2(2,nb)
c 
      integer i,j
      integer k
      double precision rd
      double precision dist
      double precision r1(3),r2(3)
      external dist


      k = 0
      do i=1,nres
      r1 = cg(:,i)
      do j=i+1,nres
        r2 = cg(:,j)
        rd  = dist(r1,r2)
        write(*,*) "testing ",i,j,rd,r1,r2
        if(rd.lt.3.0) then
          k = k + 1
          p2(1,k) = i
          p2(2,k) = j
          write(12,*) i,j,rd
        end if 
      end do
      end do
      nb = k
      end subroutine

      subroutine parse_trimers(nb2,p2,nb,l,p,px)
      implicit none
      integer nb2,nb,l
      integer p2(2,nb2)
      integer px(l+1,nb)
      integer p(l,nb)
c 
      integer ptmp(l+1)
      integer i,j
      integer k
      integer tail, head
      logical ohead, otail
      integer ic

      integer i2,i3,j3

      k = 0
      do i2=1,nb2
      head = p2(1,i2)
      tail = p2(2,i2)
      do i=1,nb
        ic = 0
        do j=1,l
           ptmp(j) = p(j,i)
           if(p(j,i).eq.head) then
             ic = ic + 1
             ptmp(l+1) = tail
           end if
           if(p(j,i).eq.tail) then
             ic = ic + 1
             ptmp(l+1) = head
           end if
        end do
        if(ic.eq.1) then
           k = k+1
c          px(1:l,k) = p(:,i)
c          px(l+1,k) = tail
          call sort(l+1,ptmp)
          write(14,*) (p(j,i),j=1,l),head,tail
          write(15,*) (ptmp(j),j=1,l+1)
        end if
      end do
      end do
      end subroutine

      subroutine sort(n,a)
      implicit none
      integer n
      integer a(n)
c
c     local variables:
      integer i
      integer pass
      integer sorted
      integer temp
      character*32 pname

      pass = 1
      sorted = 0
      do while(sorted .eq. 0)
        sorted = 1
        do 2 i = 1,n-pass
          if(a(i) .gt. a(i+1)) then
            temp = a(i)
            a(i) = a(i+1)
            a(i+1) = temp
            sorted = 0
          endif
 2      continue
        pass = pass +1
      end do
      do i=1,n-1
       if(a(i).eq.a(i+1)) a(i)=-1
      end do

      return

      end

      function dist(r1,r2)
      implicit none
      double precision r1(3),r2(3)
      double precision dist
      dist = (r1(1)-r2(1))**2+
     +       (r1(2)-r2(2))**2+
     +       (r1(3)-r2(3))**2

      dist = sqrt(dist)
      return
      end function
      subroutine my_get_command_argument(i,buffer,l,istatus)
      implicit none
      integer i
      integer l
      character*(*) buffer
      integer istatus
c
      istatus = 0
      l = 0
      call getarg(i,buffer)
      if(buffer.eq." ") istatus = 1
c      call get_command_argument(i,buffer,l,istatus)
      end subroutine



c $Id: main.f 21413 2011-11-05 06:53:49Z d3y133 $
