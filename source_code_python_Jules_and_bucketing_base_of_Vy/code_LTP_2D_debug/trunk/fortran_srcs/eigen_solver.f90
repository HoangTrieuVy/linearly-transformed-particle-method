!---------------------------------------------------------------------------  
!> @author 
!> HoangTrieuVy-LE.
!
! DESCRIPTION: 
!> Name: deformation_eigen_solver
!> Evaluate eigenvalues and eigenvectors of a real symmetric matrix a(n,n): a*x = lambda*x 
!> Method: systeme d'ordre 2 or n, make the choice by uncomment and comment code block below
!===========================================================================================
!> Input:
! a(n,n) - array of coefficients for matrix A
! abserr - abs tolerance [sum of (off-diagonal elements)^2]
!> Output:
! a(i,i) - eigenvalues
! x(i,j) - eigenvectors
!============================================================================================

module deformation_eigen_solver
contains
	subroutine eigen_solver(a,x,abserr)
	
	implicit none
	
	
	double precision, intent(in):: abserr
	double precision, intent(inout) :: a(2,2),x(2,2)
	double precision :: det
	double precision :: trace
	double precision :: lambda1,lambda2

	

	det =  a(1,1)*a(2,2)-a(1,2)*a(2,1)
	trace = a(1,1) + a(2,2)

	lambda1 = trace/2 + sqrt(trace**2/4 - det)
	lambda2 = trace/2 - sqrt(trace**2/4 - det)


	if(a(1,1)-lambda1==0 .and. a(2,2)-lambda2==0) then
		x(1,1) = 1.
		x(1,2) = 0
		x(2,1) = 0
		x(2,2) = 1.
	else 
		x(1,1) = a(1,2)
		x(1,2) = lambda1-a(1,1)
		x(2,1) = lambda2 - a(2,2)
		x(2,2) = a(2,1)
 	end if

 	a(1,1) = lambda1
 	a(2,2) = lambda2
	!===========================================================
	! integer, intent(in):: n
	! double precision ::  b2, bar
	! double precision ::beta, coeff, c, s, cs, sc
	! integer i, j, k
	! ! initialize x(i,j)=0, x(i,i)=1
	! ! *** the array operation x=0.0 is specific for Fortran 90/95
	! x(:,:) = 0.
	! do i=1,n
	!   x(i,i) = 1.0
	! end do
	
	! ! find the sum of all off-diagonal elements (squared)
	! b2 = 0.0
	! do i=1,n
	!   do j=1,n
	!     if (i.ne.j) b2 = b2 + a(i,j)**2
	!   end do
	! end do
	
	! if (b2 <= abserr) return
	
	! ! average for off-diagonal elements /2
	! bar = 0.5*b2/float(n*n)
	
	! do while (b2.gt.abserr)
	!   do i=1,n-1
	!     do j=i+1,n
	!       if (a(j,i)**2 <= bar) cycle  ! do not touch small elements
	!       b2 = b2 - 2.0*a(j,i)**2
	!       bar = 0.5*b2/float(n*n)

	! ! calculate coefficient c and s for Givens matrix
	!       beta = (a(j,j)-a(i,i))/(2.0*a(j,i))
	!       coeff = 0.5*beta/sqrt(1.0+beta**2)
	!       s = sqrt(max(0.5+coeff,0.0))
	!       c = sqrt(max(0.5-coeff,0.0))

	! ! recalculate rows i and j
	!       do k=1,n
	!         cs =  c*a(i,k)+s*a(j,k)
	!         sc = -s*a(i,k)+c*a(j,k)
	!         a(i,k) = cs
	!         a(j,k) = sc
	!       end do

	! ! new matrix a_{k+1} from a_{k}, and eigenvectors 
	!       do k=1,n
	!         cs =  c*a(k,i)+s*a(k,j)
	!         sc = -s*a(k,i)+c*a(k,j)
	!         a(k,i) = cs
	!         a(k,j) = sc
	!         cs =  c*x(k,i)+s*x(k,j)
	!         sc = -s*x(k,i)+c*x(k,j)
	!         x(k,i) = cs
	!         x(k,j) = sc
	!       end do
	!     end do
	!   end do
	! end do
	!===========================================================
	end subroutine eigen_solver
end module deformation_eigen_solver
