program test_inter_comms
  use mpi_f08
  implicit none

  integer :: w_r, w_p, r_r, r_p, error
  type(mpi_status) :: status
  integer :: tag = 0, master = 0, appn
  integer(kind=mpi_address_kind) :: app_n
  logical :: flag  
  type(mpi_comm) :: real_comm, intercomm

  integer :: i, m, apps
  logical :: tandem

  !=======================================================
  
  call mpi_init (error)
  call mpi_comm_size (mpi_comm_world, w_p, error)
  call mpi_comm_rank (mpi_comm_world, w_r, error)

  ! Let's create real_comm and find out if we are alone or in tandem
  !  If just using one app, this will be equivalent to mpi_comm_world
  !  If using two apps, mpi_comm_world is splitted into real_comm (as many as apps)
  ! So, we can use real_comm everywhere (in the case of just one app, as if it were mpi_comm_world)
  call mpi_comm_get_attr(mpi_comm_world, mpi_appnum, app_n, flag, error)
  appn = app_n

  ! alone or working in tandem?
  tandem = .false.
  call mpi_allreduce(appn,apps,1,mpi_integer,mpi_max,mpi_comm_world,error)
  if (apps > 1) then
     if (w_r .eq. master) print*, "STOP: only working with 2 apps"
     call mpi_finalize ( error )
     stop
  elseif (apps > 0) then
     tandem = .true.
  end if

  ! create real_comm communicator[s]
  call mpi_comm_split(mpi_comm_world, appn, w_r, real_comm, error)
  call mpi_comm_size (real_comm, r_p, error)
  call mpi_comm_rank (real_comm, r_r, error)


  ! Intra-communicator communication
  if (tandem) then
     if (r_r .eq. master) write(*,'(A,I2)') "Running two apps, I'm the master of group ",appn     
  else
     if (r_r .eq. master) write(*,'(A,I2)') "Running only one app, I'm the master of group ",appn
  end if

  if (r_r .eq. master) then
     do i = 1,r_p-1
        call mpi_recv(m,1,mpi_integer,i,tag,real_comm,status,error)
        write(*,'(A,I2,A,I2,A,I2,A)') "[GROUP:", appn,"] Group master received data from group worker: " &
             ,i, " (rank in MPI_COMM_WORLD: ", m, ")"
     end do
  else
     call mpi_send(w_r,1,mpi_integer,master,tag,real_comm,error)
  end if


  ! Inter-communicators
  if (tandem) then

     !! to create inter-communicators we need to know the remote leaders
     !! since we used w_r for mpi_comm_split, in mpi_comm_world the leaders will be:
     !!   0, for appn=0, and r_p (of appn=0 group) for appn=1
     if (appn .eq. 0) then
        call mpi_intercomm_create(real_comm, master, mpi_comm_world, r_p, tag, intercomm, error)
     elseif (appn .eq. 1) then
        call mpi_intercomm_create(real_comm, master, mpi_comm_world, master, tag, intercomm, error)
     end if

     !! Basic MPI communication between the group leaders
     if (appn .eq. 0) then
        if (r_r .eq. master) then
           call mpi_recv(m,1,mpi_integer,master,tag,intercomm,status,error)
           print*,
           write(*,'(A,I2,A,I2,A)') "Group 0 leader (local rank:", r_r, &
                ") recv'ed data from Group 1 leader (local rank:", status%mpi_source, ")"
           write(*,'(A,I2,A)') " ... Data recv'd:",m," (group 1 leader's world rank)"
           call mpi_send(w_r,1,mpi_integer,master,tag,intercomm,error)
        end if
     elseif (appn .eq. 1) then
        if (r_r .eq. master) then
           call mpi_send(w_r,1,mpi_integer,master,tag,intercomm,error)
           call mpi_recv(m,1,mpi_integer,master,tag,intercomm,status,error)
           print*,
           write(*,'(A,I2,A,I2,A)') "Group 1 leader (local rank:", r_r, &
                ") recv'ed data from Group 0 leader (local rank:", status%mpi_source, ")"
           write(*,'(A,I2,A)') " ... Data recv'd:",m," (group 0 leader's world rank)"
        end if
     end if
  end if
  
  call mpi_finalize ( error )
  
end program test_inter_comms
