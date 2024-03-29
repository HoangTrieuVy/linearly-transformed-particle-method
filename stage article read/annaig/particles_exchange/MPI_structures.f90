   module MPI_structures

   use DNS_DIM 


   ! Particle type
   use PARTICLE_PARALLEL

   use GEOMETRIC_VARIABLE

   use COLLISION_VARIABLE

  implicit none

  integer :: XZ_2PLANES,XY_2PLANES,CORNER
  INTEGER, PARAMETER               :: NB_NEIGHBORS = 8
  INTEGER, DIMENSION(NB_NEIGHBORS) :: NEIGHBOR
  INTEGER, PARAMETER               :: FJ=1,BJ=2,FK=3,BK=4 ! Neighbors : Forward_J, Backward_J, ... 
  INTEGER, PARAMETER               :: FJBK=5,BJFK=6,BJBK=7,FJFK=8 ! Common edge neighbor

  INTEGER :: COUNT_STAY
  integer, dimension(:,:), allocatable :: COUNTER ! nb of particles leaving in each direction  

  integer, dimension(:,:), allocatable :: IND_LEAV
  integer, dimension(:), allocatable :: IND_STAY

  type(PARTTYPE), dimension(:,:), allocatable :: PART_RECV


contains

  SUBROUTINE NEIGHBOURING

    implicit none

    !*******************************************************************
    ! Neighbouring table Initiation
    NEIGHBOR(:) = MPI_PROC_NULL
	
	! forward and bakward process idenity (rank)
    NEIGHBOR(FJ) = MYID+1
    NEIGHBOR(BJ) = MYID-1

    if(mod(MYID+1,JPROC)==0) NEIGHBOR(FJ) = MYID+1-JPROC
    if(mod(MYID  ,JPROC)==0) NEIGHBOR(BJ) = MYID-1+JPROC

    NEIGHBOR(FK) = mod(MYID+JPROC,NPROC)
    NEIGHBOR(BK) = mod(MYID-JPROC+NPROC,NPROC)
  
    NEIGHBOR(FJFK) = NEIGHBOR(FK) + 1
    if(mod(NEIGHBOR(FJFK),JPROC)==0) NEIGHBOR(FJFK) = NEIGHBOR(FK)+1-JPROC
    NEIGHBOR(FJBK) = NEIGHBOR(BK) + 1
    if(mod(NEIGHBOR(FJBK),JPROC)==0) NEIGHBOR(FJBK) = NEIGHBOR(BK)+1-JPROC

    NEIGHBOR(BJFK) = NEIGHBOR(FK) - 1
    if(mod(NEIGHBOR(FK),JPROC)==0) NEIGHBOR(BJFK) = NEIGHBOR(FK)-1+JPROC
    NEIGHBOR(BJBK) = NEIGHBOR(BK) - 1
    if(mod(NEIGHBOR(BK),JPROC)==0) NEIGHBOR(BJBK) = NEIGHBOR(BK)-1+JPROC

  end subroutine NEIGHBOURING


  subroutine INITIATION_EXCHANGE
   ! Index (NPART_LOC array) of particles which stay on the same processor
    allocate(IND_STAY(NPMAX_LOC))
    ! Index (NPART_LOC array) of particles which leav
    allocate(IND_LEAV(NPEXCH_MAX,NB_NEIGHBORS))

    ! Numbers of particles leaving in each direction for each processor 
    allocate(COUNTER(NB_NEIGHBORS,0:NPROC-1))

    ! Temporary array to recieve particle form another processorf
    allocate(PART_RECV(NPEXCH_MAX,NB_NEIGHBORS))
 
  end subroutine INITIATION_EXCHANGE

!!!!
  subroutine PARTICLES_COUNTING(IG)
   
   integer, intent(in) :: IG
   integer :: I,ID
   

  ! Each time step

   ! For MYID-th process
   COUNTER(:,MYID) = 0

   COUNT_STAY = 0
   
   do I = 1, NPART_LOC(IG)

    !!- y-component
    if(PART(I,IG)%YP > (YMESH(IEND(2))+DY)) then
      if(PART(I,IG)%ZP > ZMESH(ISTART(3)) .and. PART(I,IG)%ZP < (ZMESH(IEND(3))+DZ))then
        ! the particule leaves the current proc for the north neightboor 
      COUNTER(FJ,MYID) = COUNTER(FJ,MYID) + 1
      IND_LEAV(COUNTER(FJ,MYID),FJ) = I
    else if(PART(I,IG)%ZP > (ZMESH(IEND(3))+DZ)) then
      COUNTER(FJFK,MYID) = COUNTER(FJFK,MYID) + 1
      IND_LEAV(COUNTER(FJFK,MYID),FJFK) = I
    else
      COUNTER(FJBK,MYID) = COUNTER(FJBK,MYID) + 1 
      IND_LEAV(COUNTER(FJBK,MYID),FJBK) = I
    end if
  end if

  if(PART(I,IG)%YP < YMESH(ISTART(2))) then 
    if(PART(I,IG)%ZP > ZMESH(ISTART(3)) .and. PART(I,IG)%ZP <(ZMESH(IEND(3))+DZ))then
      ! the particule leaves the current proc for the south neightboor 
      COUNTER(BJ,MYID) = COUNTER(BJ,MYID) + 1
      IND_LEAV(COUNTER(BJ,MYID),BJ) = I
    else if(PART(I,IG)%ZP > ZMESH(IEND(3))+DZ) then
      COUNTER(BJFK,MYID) = COUNTER(BJFK,MYID) + 1
      IND_LEAV(COUNTER(BJFK,MYID),BJFK) = I
    else
      COUNTER(BJBK,MYID) = COUNTER(BJBK,MYID) + 1
      IND_LEAV(COUNTER(BJBK,MYID),BJBK) = I
    end if

  end if

!!- z-component
  if(PART(I,IG)%ZP > (ZMESH(IEND(3))+DZ) .and. &
     PART(I,IG)%YP > YMESH(ISTART(2)) .and. PART(I,IG)%YP < (YMESH(IEND(2))+DY))then
    ! the particule leaves the current proc for the forward neightboor 
    COUNTER(FK,MYID) = COUNTER(FK,MYID) + 1
    IND_LEAV(COUNTER(FK,MYID),FK) = I
  end if
  if(PART(I,IG)%ZP < ZMESH(ISTART(3)) .and. &
     PART(I,IG)%YP > YMESH(ISTART(2)) .and. PART(I,IG)%YP < (YMESH(IEND(2))+DY))then
    ! the particule leaves the current proc for the backward neightboor 
    COUNTER(BK,MYID) = COUNTER(BK,MYID) + 1
    IND_LEAV(COUNTER(BK,MYID),BK) = I
  end if

  if(PART(I,IG)%YP > YMESH(ISTART(2)) .and. PART(I,IG)%YP <(YMESH(IEND(2))+DY) .and. &
     PART(I,IG)%ZP > ZMESH(ISTART(3)) .and. PART(I,IG)%ZP <(ZMESH(IEND(3))+DZ) )then 
    ! the particule stay in the current processor domain
    COUNT_STAY = COUNT_STAY + 1
    IND_STAY(COUNT_STAY) = I
  end if

   end do

  ! Check bounds arrays
  if(MAXVAL(COUNTER(:,MYID)) > NPEXCH_MAX)then
    write(*,*) 'Too much particles leave processor ',MYID,'for class ',IG 
    write(*,*) 'NEXCH_MAX ',NPEXCH_MAX,' parameter has to be increased '
    stop
  end if

    if(MYID /= 0) then
      call MPI_SEND(COUNTER(1,MYID),NB_NEIGHBORS,MPI_INTEGER,0,101,MPI_COMM_WORLD,IERR)
    else
      do ID = 1,NPROC - 1

        call MPI_RECV(COUNTER(1,ID),NB_NEIGHBORS,MPI_INTEGER,ID,101,MPI_COMM_WORLD,STATUT,IERR)
      end do
    end if
    call MPI_BCAST(COUNTER,NB_NEIGHBORS*NPROC,MPI_INTEGER,0,MPI_COMM_WORLD,IERR)

  end subroutine PARTICLES_COUNTING
!!!!


  subroutine EXCHANGE_P(IG) 
    integer, intent(in) :: IG
    integer, dimension(NB_NEIGHBORS) :: OPP
    integer :: NB_PART 
    integer :: I, NEIGHLOOP
    integer :: COUNT_STAY1,COUNT_STAY2
    integer :: NPARRIVE

  ! COMMUNICATION POINT TO POINT IN EACH VOISIN
  OPP = (/2,1,4,3,6,5,8,7/) ! Index of opposed proc (BJ <-> FJ, BJBK <-> FJFK, ...)
  ! Number of particles arriving on processor MYID 
  NPARRIVE = 0
  ! Test to avoid overbound access 
  do NEIGHLOOP = 1,8
    NB_PART = COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
    NPARRIVE = NPARRIVE + NB_PART
  end do
  
  if (COUNT_STAY + NPARRIVE > NPMAX_LOC)then
    write(*,*) 'Too much particles',NPARRIVE,' arrive on processor ',MYID,'for class ',IG 
    write(*,*) 'NPMAX_LOC =',NPMAX_LOC
    write(*,*) 'COUNT_STAY + NPARRIVE=', COUNT_STAY + NPARRIVE
    stop
  end if

  do NEIGHLOOP = 1,8 ! Loop on neighbors
    do I = 1,COUNTER(NEIGHLOOP,MYID)
      call MPI_SEND(PART(IND_LEAV(I,NEIGHLOOP),IG),1,MPI_PARTICLETYPE,&
                  NEIGHBOR(NEIGHLOOP),1001,&
                  MPI_COMM_WORLD,IERR)
    end do
    do I = 1,COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
      call MPI_RECV(PART_RECV(I,OPP(NEIGHLOOP)),1,&
                    MPI_PARTICLETYPE,NEIGHBOR(OPP(NEIGHLOOP)),1001,&
                    MPI_COMM_WORLD,STATUT,IERR)
    end do
  end do
  call MPI_BARRIER(MPI_COMM_WORLD,IERR)

  ! Local particle array "PART" reconstruction
  ! Concatenate particles staying on the processor in PART array
  PART(1:COUNT_STAY,IG) = PART(IND_STAY(1:COUNT_STAY),IG)

  ! Add new particles arriving from each neighbor in array PART 
  COUNT_STAY2 = COUNT_STAY
  do NEIGHLOOP = 1,8
    NB_PART = COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
    COUNT_STAY1 = COUNT_STAY2 + 1
    COUNT_STAY2 = COUNT_STAY2 + NB_PART
    PART(COUNT_STAY1:COUNT_STAY2,IG) = &
                      PART_RECV(1:NB_PART,OPP(NEIGHLOOP))
  end do
  
  ! Update PROC_ID
!  PART(1:COUNT_STAY2,IG)%PROC_ID = MYID
  ! Update number of active particles 
  NPART_LOC(IG) = COUNT_STAY2

end subroutine EXCHANGE_P

subroutine PARTICLES_COUNTING_COLL(IG)
   
   integer, intent(in) :: IG
   integer :: I,ID
   

  ! Each time step

   COUNTER(:,MYID) = 0
   COUNT_STAY = 0

   do I = 1, NPART_LOC(IG)
    !!- y-component
    if(PART(I,IG)%YP > YMESH(IEND(2))+DY-DELTA_COLL) then
     ! the particule information of the current proc should be given to the J-forward neightboor 
     COUNTER(FJ,MYID) = COUNTER(FJ,MYID) + 1
     IND_LEAV(COUNTER(FJ,MYID),FJ) = I
     if (PART(I,IG)%ZP > (ZMESH(IEND(3))+DZ-DELTA_COLL)) then
      COUNTER(FJFK,MYID) = COUNTER(FJFK,MYID) + 1
      IND_LEAV(COUNTER(FJFK,MYID),FJFK) = I
     end if
     if (PART(I,IG)%ZP < ZMESH(ISTART(3))+DELTA_COLL) then
      COUNTER(FJBK,MYID) = COUNTER(FJBK,MYID) + 1 
      IND_LEAV(COUNTER(FJBK,MYID),FJBK) = I
     end if
   end if

   if(PART(I,IG)%YP < YMESH(ISTART(2))+DELTA_COLL) then 
    ! the particule information of the current proc should be given to the J-backward neightboor
    COUNTER(BJ,MYID) = COUNTER(BJ,MYID) + 1
    IND_LEAV(COUNTER(BJ,MYID),BJ) = I
    if(PART(I,IG)%ZP > ZMESH(IEND(3))+DZ-DELTA_COLL) then
     COUNTER(BJFK,MYID) = COUNTER(BJFK,MYID) + 1
     IND_LEAV(COUNTER(BJFK,MYID),BJFK) = I
    end if
    if (PART(I,IG)%ZP < ZMESH(ISTART(3))+DELTA_COLL) then
     COUNTER(BJBK,MYID) = COUNTER(BJBK,MYID) + 1
     IND_LEAV(COUNTER(BJBK,MYID),BJBK) = I
    end if
   end if

   !!- z-component
   if(PART(I,IG)%ZP > ZMESH(IEND(3))+DZ-DELTA_COLL) then
    ! the particule information of the current proc should be given to the K-forward neightboor 
    COUNTER(FK,MYID) = COUNTER(FK,MYID) + 1
    IND_LEAV(COUNTER(FK,MYID),FK) = I
   end if
   if(PART(I,IG)%ZP < ZMESH(ISTART(3))+DELTA_COLL)then
    ! the particule information of the current proc should be given to the K-backward neightboor
    COUNTER(BK,MYID) = COUNTER(BK,MYID) + 1
    IND_LEAV(COUNTER(BK,MYID),BK) = I
   end if

   end do


  ! Check bounds arrays
  if(MAXVAL(COUNTER(:,MYID)) > NPEXCH_MAX)then
    write(*,*) 'Too much particles leave processor ',MYID,'for class ',IG 
    write(*,*) 'NEXCH_MAX parameter has to be increased '
    stop
  end if

    if(MYID /= 0) then
      call MPI_SEND(COUNTER(1,MYID),NB_NEIGHBORS,MPI_INTEGER,0,101,MPI_COMM_WORLD,IERR)
    else
      do ID = 1,NPROC - 1
        call MPI_RECV(COUNTER(1,ID),NB_NEIGHBORS,MPI_INTEGER,ID,101,MPI_COMM_WORLD,STATUT,IERR)
      end do
    end if
    call MPI_BCAST(COUNTER,NB_NEIGHBORS*NPROC,MPI_INTEGER,0,MPI_COMM_WORLD,IERR)

  end subroutine PARTICLES_COUNTING_COLL

!!!!

  subroutine EXCHANGE_P_COLL(IG,NPARRIVE) 

    integer, intent(in) :: IG
    integer, intent(out) :: NPARRIVE
    integer, dimension(NB_NEIGHBORS) :: OPP
    integer :: NB_PART 
    integer :: I, NEIGHLOOP
    integer :: COUNT_STAY1,COUNT_STAY2
    integer, dimension(2*NPEXCH_MAX) :: REQ
    integer :: IREQ

  ! COMMUNICATION POINT TO POINT IN EACH VOISIN
  OPP = (/2,1,4,3,6,5,8,7/) ! Index of opposed proc (BJ <-> FJ, BJBK <-> FJFK, ...)
  ! Number of particles arriving on processor MYID 
  NPARRIVE = 0
  ! Test to avoid overbound access 
  do NEIGHLOOP = 1,8
    NB_PART = COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
    NPARRIVE = NPARRIVE + NB_PART
  end do
  
  if (NPART_LOC(IG) + NPARRIVE > NPMAX_LOC)then
    write(*,*) 'Too much particles to echange for collision detection on processor for class'
    write(*,*) 'MYID =',MYID
    write(*,*) 'IG =',IG
    write(*,*) 'NPARRIVE =',NPARRIVE
    write(*,*) 'NPART_LOC(IG) =',NPART_LOC(IG)
    write(*,*) 'NPART_LOC(IG) + NPARRIVE=', NPART_LOC(IG) + NPARRIVE
    stop
  end if

  do NEIGHLOOP = 1,8 ! Loop on neighbors
    IREQ = 0
    do I = 1,COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
      IREQ = IREQ + 1
      call MPI_IRECV(PART_RECV(I,OPP(NEIGHLOOP)),1,&
                    MPI_PARTICLETYPE,NEIGHBOR(OPP(NEIGHLOOP)),1000+i,&
                    MPI_COMM_WORLD,REQ(IREQ),IERR)
    end do
    do I = 1,COUNTER(NEIGHLOOP,MYID)
      IREQ = IREQ + 1
      call MPI_ISEND(PART(IND_LEAV(I,NEIGHLOOP),IG),1,MPI_PARTICLETYPE,&
                  NEIGHBOR(NEIGHLOOP),1000+i,&
                  MPI_COMM_WORLD,REQ(IREQ),IERR)
      
    end do
    call MPI_WAITALL(IREQ,REQ,MPI_STATUSES_IGNORE,IERR)
  end do
  
  call MPI_BARRIER(MPI_COMM_WORLD,IERR)

  ! Add new particles arriving from each neighbor in array PART 
  COUNT_STAY2 = NPART_LOC(IG) 
  do NEIGHLOOP = 1,8
    NB_PART = COUNTER(NEIGHLOOP,NEIGHBOR(OPP(NEIGHLOOP)))
    COUNT_STAY1 = COUNT_STAY2 + 1
    COUNT_STAY2 = COUNT_STAY2 + NB_PART
    PART(COUNT_STAY1:COUNT_STAY2,IG) = &
                      PART_RECV(1:NB_PART,OPP(NEIGHLOOP))
  end do
end subroutine EXCHANGE_P_COLL

! To write binary file with particles in parallel
subroutine SAVE_PART_MPIIO(PARTLOC,FILENAME)
  

  type(PARTTYPE), dimension(NPMAX_LOC,NIG) :: PARTLOC
  real (kind=8), dimension(NPMAX_LOC) :: TEMP_VAR
  character(len=40) :: FILENAME

  !- File descriptor
  integer :: DESCRIPTEUR
  integer(kind=MPI_OFFSET_KIND) :: POS_FILE, POS_OFFSET
  integer :: FILETYPE
  
  integer :: NOI, NOD, NOL
  integer :: J
  integer :: NB_VARSAVED
  
  ! File opening with writing permission
  call MPI_FILE_OPEN(       MPI_COMM_WORLD, &
                            trim(FILENAME), &
           MPI_MODE_CREATE+MPI_MODE_WRONLY, &
                             MPI_INFO_NULL, &
                               DESCRIPTEUR, &
                                    IERR  )

  ! Position in the file (in bytes)
  POS_FILE = 0

  ! Write the dimensions 
  if(MYID == 0) then
    call MPI_File_write(DESCRIPTEUR, NPROC, 1, MPI_INTEGER,MPI_STATUS_IGNORE,IERR)
    call MPI_File_write(DESCRIPTEUR, NPMAX_LOC, 1, MPI_INTEGER, MPI_STATUS_IGNORE,IERR)
    call MPI_File_write(DESCRIPTEUR, NIG, 1, MPI_INTEGER, MPI_STATUS_IGNORE,IERR)
    call MPI_File_write(DESCRIPTEUR, SOLVE_SCALAR, 1, MPI_LOGICAL, MPI_STATUS_IGNORE,IERR)
  end if

  call mpi_type_size(MPI_INTEGER,NOI,IERR)
  call mpi_type_size(MPI_LOGICAL,NOL,IERR)
  call mpi_type_size(MPI_DOUBLE_PRECISION,NOD,IERR)

  POS_OFFSET = 3 * NOI + NOL

  if (SOLVE_SCALAR) then
    NB_VARSAVED = 7
  else
    NB_VARSAVED = 6
  end if
  
  do J=1,NIG
    POS_FILE = POS_OFFSET + (MYID * NIG + (J-1)) * (NPMAX_LOC * NOD * NB_VARSAVED + NOI)  
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,NPART_LOC(J),1,MPI_INTEGER,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NOI
    TEMP_VAR = PARTLOC(:,J)%XP
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    TEMP_VAR = PARTLOC(:,J)%YP
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    TEMP_VAR = PARTLOC(:,J)%ZP
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    TEMP_VAR = PARTLOC(:,J)%UP
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    TEMP_VAR = PARTLOC(:,J)%VP
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    TEMP_VAR = PARTLOC(:,J)%WP
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    if (SOLVE_SCALAR) then 
      TEMP_VAR = PARTLOC(:,J)%TP
      POS_FILE = POS_FILE + NPMAX_LOC * NOD
      call mpi_file_write_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    end if
  end do

  call MPI_File_close(DESCRIPTEUR, IERR)
 
end subroutine SAVE_PART_MPIIO


subroutine READ_PART_MPIIO(PARTLOC,FILENAME)

  type(PARTTYPE), dimension(NPMAX_LOC,NIG) :: PARTLOC
  real (kind=8), dimension(NPMAX_LOC) :: TEMP_VAR
  character(len=40) :: FILENAME

  !- File descriptor
  integer :: DESCRIPTEUR
  integer(kind=MPI_OFFSET_KIND) :: POS_FILE, POS_OFFSET
  integer :: FILETYPE
  
  integer :: NOI, NOD, NOL 
  integer :: NPROC_READ, ERR_CODE
  integer :: J
  integer :: NB_VARSAVED
  logical :: ISCALAR

  ! File opening with writing permission
  call MPI_FILE_OPEN(       MPI_COMM_WORLD, &
                            trim(FILENAME), &
                           MPI_MODE_RDONLY, &
                             MPI_INFO_NULL, &
                               DESCRIPTEUR, &
                                    IERR  )

  ! Position in the file (in bytes)
  POS_FILE = 0

  ! Read the dimensions 
  call MPI_File_read(DESCRIPTEUR, NPROC_READ, 1, MPI_INTEGER,MPI_STATUS_IGNORE,IERR)
  call MPI_File_read(DESCRIPTEUR, NPMAX_LOC, 1, MPI_INTEGER, MPI_STATUS_IGNORE,IERR)
  call MPI_File_read(DESCRIPTEUR, NIG, 1, MPI_INTEGER, MPI_STATUS_IGNORE,IERR)
  call MPI_File_read(DESCRIPTEUR, ISCALAR, 1, MPI_LOGICAL, MPI_STATUS_IGNORE,IERR)

  call mpi_type_size(MPI_INTEGER,NOI,IERR)
  call mpi_type_size(MPI_DOUBLE_PRECISION,NOD,IERR)
  call mpi_type_size(MPI_LOGICAL,NOL,IERR)

  POS_OFFSET = 3 * NOI + NOL

  if (NPROC_READ/=NPROC) then
    write(*,*) 'Particles file should be reread with the following number of processors',NPROC_READ
    ERR_CODE = -1
    call mpi_abort(MPI_COMM_WORLD,ERR_CODE,IERR)
  end if

  if (ISCALAR) then
    NB_VARSAVED = 7
  else
    NB_VARSAVED = 6
  end if
  
  do J=1,NIG
    POS_FILE = POS_OFFSET + (MYID * NIG + (J-1)) * (NPMAX_LOC * NOD * NB_VARSAVED + NOI)  
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,NPART_LOC(J),1,MPI_INTEGER,MPI_STATUS_IGNORE,IERR)
    POS_FILE = POS_FILE + NOI
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%XP = TEMP_VAR
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%YP = TEMP_VAR
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%ZP = TEMP_VAR
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%UP = TEMP_VAR
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%VP = TEMP_VAR
    POS_FILE = POS_FILE + NPMAX_LOC * NOD
    call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
    PARTLOC(:,J)%wP = TEMP_VAR
    if(ISCALAR) then
      POS_FILE = POS_FILE + NPMAX_LOC * NOD
      call mpi_file_read_at(DESCRIPTEUR,POS_FILE,TEMP_VAR,NPART_LOC(J),MPI_DOUBLE_PRECISION,MPI_STATUS_IGNORE,IERR)
      PARTLOC(:,J)%TP = TEMP_VAR
    end if
  end do

  call MPI_File_close(DESCRIPTEUR, IERR)
 
end subroutine READ_PART_MPIIO


end module MPI_structures

