
# Table of Contents

1.  [Introduction](#org1756093)
    1.  [1) Using MPI\_COMM\_SPAWN](#org26b0bfe)
    2.  [2) Using mpirun and MPI\_COMM\_SPLIT](#org555a82b)
2.  [Implementation](#org807e2e0)
3.  [Sample run](#orgbc40438)
    1.  [Running as just one app](#org54ce092)
    2.  [Running as two apps](#org93ee3aa)



<a id="org1756093"></a>

# Introduction

The idea of this sample code is to show how two MPI applications can communicate
via Inter-communicators.

One could do it in two ways:


<a id="org26b0bfe"></a>

## 1) Using MPI\_COMM\_SPAWN

you start running your code with, say 10 processes (group A), and then with
mpi\_comm\_spawn you create another group of, say, 6 processes (group B). Both
groups will have their MPI\_COMM\_WORLD, so they will behave as regular
applications, but then you also have an inter-communicator that will allow you
to send messages from one group to the other. This looks very promising, but the
problem will be if you try to run this in a supercomputer where you are given a
number of "slots" via Slurm or similar. Spawning new processes will not play
nicely with the pre-allocated slots.


<a id="org555a82b"></a>

## 2) Using mpirun and MPI\_COMM\_SPLIT

another option is to use the possibilities of mpirun (for example), to launch
two executables at the same time. This will play nicely with Slurm, but then you
will have to change slightly your application, because MPI\_COMM\_WORLD will be
ALL the processes allocated with Slurm. The idea here would be to split the
communicator into two intra-communicators via MPI\_COMM\_SPLIT (using the "colour"
provided by the MPI\_APPNUM variable). And then create an inter-communicator to
connect these two groups.


<a id="org807e2e0"></a>

# Implementation

Here we go for option 2) above. 


<a id="orgbc40438"></a>

# Sample run


<a id="org54ce092"></a>

## Running as just one app

    $ mpirun -np 3 ./app 
    Running only one app, I'm the master of group  0
    [GROUP: 0] Group master received data from group worker:  1 (rank in MPI_COMM_WORLD:  1)
    [GROUP: 0] Group master received data from group worker:  2 (rank in MPI_COMM_WORLD:  2)


<a id="org93ee3aa"></a>

## Running as two apps

    $ mpirun -np 3 ./app : -np 4 ./app
    Running two apps, I'm the master of group  0
    [GROUP: 0] Group master received data from group worker:  1 (rank in MPI_COMM_WORLD:  1)
    [GROUP: 0] Group master received data from group worker:  2 (rank in MPI_COMM_WORLD:  2)
    Running two apps, I'm the master of group  1
    [GROUP: 1] Group master received data from group worker:  1 (rank in MPI_COMM_WORLD:  4)
    [GROUP: 1] Group master received data from group worker:  2 (rank in MPI_COMM_WORLD:  5)
    [GROUP: 1] Group master received data from group worker:  3 (rank in MPI_COMM_WORLD:  6)
    
    Group 0 leader (local rank: 0) recv'ed data from Group 1 leader (local rank: 0)
     ... Data recv'd: 3 (group 1 leader's world rank)
    
    Group 1 leader (local rank: 0) recv'ed data from Group 0 leader (local rank: 0)
     ... Data recv'd: 0 (group 0 leader's world rank)

