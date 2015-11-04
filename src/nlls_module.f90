! nlls_module :: a nonlinear least squares solver

module nlls_module

  implicit none

  integer, parameter :: wp = kind(1.0d0)
  integer, parameter :: long = selected_int_kind(8)
  real (kind = wp), parameter :: tenm5 = 1.0e-5
  real (kind = wp), parameter :: tenm8 = 1.0e-8
  real (kind = wp), parameter :: epsmch = epsilon(1.0_wp)
  real (kind = wp), parameter :: hundred = 100.0
  real (kind = wp), parameter :: ten = 10.0
  real (kind = wp), parameter :: point9 = 0.9
  real (kind = wp), parameter :: zero = 0.0
  real (kind = wp), parameter :: one = 1.0
  real (kind = wp), parameter :: two = 2.0
  real (kind = wp), parameter :: half = 0.5
  real (kind = wp), parameter :: sixteenth = 0.0625

  
  TYPE, PUBLIC :: NLLS_control_type
     
!   error and warning diagnostics occur on stream error 
     
     INTEGER :: error = 6

!   general output occurs on stream out

     INTEGER :: out = 6

!   the level of output required. <= 0 gives no output, = 1 gives a one-line
!    summary for every iteration, = 2 gives a summary of the inner iteration
!    for each iteration, >= 3 gives increasingly verbose (debugging) output

     INTEGER :: print_level = 0

!   any printing will start on this iteration

!$$     INTEGER :: start_print = - 1

!   any printing will stop on this iteration

!$$     INTEGER :: stop_print = - 1

!   the number of iterations between printing

!$$     INTEGER :: print_gap = 1

!   the maximum number of iterations performed

     INTEGER :: maxit = 100

!   removal of the file alive_file from unit alive_unit terminates execution

!$$     INTEGER :: alive_unit = 40
!$$     CHARACTER ( LEN = 30 ) :: alive_file = 'ALIVE.d'

!   non-monotone <= 0 monotone strategy used, anything else non-monotone
!     strategy with this history length used

!$$     INTEGER :: non_monotone = 1

!   specify the model used. Possible values are
!
!      0  dynamic (*not yet implemented*)
!      1  first-order (no Hessian)
!      2  second-order (exact Hessian)
!      3  barely second-order (identity Hessian)
!      4  secant second-order (sparsity-based)
!      5  secant second-order (limited-memory BFGS, with %lbfgs_vectors history)
!      6  secant second-order (limited-memory SR1, with %lbfgs_vectors history)

     INTEGER :: model = 1

!   specify the norm used. The norm is defined via ||v||^2 = v^T P v,
!    and will define the preconditioner used for iterative methods.
!    Possible values for P are
!
!     -3  user's own norm
!     -2  P = limited-memory BFGS matrix (with %lbfgs_vectors history)
!     -1  identity (= Euclidan two-norm)
!      0  automatic (*not yet implemented*)
!      1  diagonal, P = diag( max( Hessian, %min_diagonal ) )
!      2  banded, P = band( Hessian ) with semi-bandwidth %semi_bandwidth
!      3  re-ordered band, P=band(order(A)) with semi-bandwidth %semi_bandwidth
!      4  full factorization, P = Hessian, Schnabel-Eskow modification
!      5  full factorization, P = Hessian, GMPS modification (*not yet *)
!      6  incomplete factorization of Hessian, Lin-More'
!      7  incomplete factorization of Hessian, HSL_MI28
!      8  incomplete factorization of Hessian, Munskgaard (*not yet *)
!      9  expanding band of Hessian (*not yet implemented*)


     INTEGER :: nlls_method = 1

!   specify the method used to solve the trust-region sub problem
!      1 Powell's dogleg
!      ...


!$$     INTEGER :: norm = 1

!   specify the semi-bandwidth of the band matrix P if required

!$$     INTEGER :: semi_bandwidth = 5

!   number of vectors used by the L-BFGS matrix P if required

!$$     INTEGER :: lbfgs_vectors = 10

!   number of vectors used by the sparsity-based secant Hessian if required

!$$     INTEGER :: max_dxg = 100

!   number of vectors used by the Lin-More' incomplete factorization 
!    matrix P if required

!$$     INTEGER :: icfs_vectors = 10

!  the maximum number of fill entries within each column of the incomplete 
!  factor L computed by HSL_MI28. In general, increasing mi28_lsize improves
!  the quality of the preconditioner but increases the time to compute
!  and then apply the preconditioner. Values less than 0 are treated as 0

!$$     INTEGER :: mi28_lsize = 10

!  the maximum number of entries within each column of the strictly lower 
!  triangular matrix R used in the computation of the preconditioner by 
!  HSL_MI28.  Rank-1 arrays of size mi28_rsize *  n are allocated internally 
!  to hold R. Thus the amount of memory used, as well as the amount of work
!  involved in computing the preconditioner, depends on mi28_rsize. Setting
!  mi28_rsize > 0 generally leads to a higher quality preconditioner than
!  using mi28_rsize = 0, and choosing mi28_rsize >= mi28_lsize is generally 
!  recommended

!$$     INTEGER :: mi28_rsize = 10

!  which linear least squares solver should we use?
     
     INTEGER :: lls_solver
        
!   overall convergence tolerances. The iteration will terminate when the
!     norm of the gradient of the objective function is smaller than 
!       MAX( %stop_g_absolute, %stop_g_relative * norm of the initial gradient
!     or if the step is less than %stop_s

     REAL ( KIND = wp ) :: stop_g_absolute = tenm5
     REAL ( KIND = wp ) :: stop_g_relative = tenm8
!$$     REAL ( KIND = wp ) :: stop_s = epsmch

!   try to pick a good initial trust-region radius using %advanced_start
!    iterates of a variant on the strategy of Sartenaer SISC 18(6)1990:1788-1803
     
!$$     INTEGER :: advanced_start = 0
     
!   initial value for the trust-region radius (-ve => ||g_0||)
     
     REAL ( KIND = wp ) :: initial_radius = hundred
     
!   maximum permitted trust-region radius

     REAL ( KIND = wp ) :: maximum_radius = ten ** 8

!   a potential iterate will only be accepted if the actual decrease
!    f - f(x_new) is larger than %eta_successful times that predicted
!    by a quadratic model of the decrease. The trust-region radius will be
!    increased if this relative decrease is greater than %eta_very_successful
!    but smaller than %eta_too_successful

     REAL ( KIND = wp ) :: eta_successful = ten ** ( - 8 )
     REAL ( KIND = wp ) :: eta_very_successful = point9
     REAL ( KIND = wp ) :: eta_too_successful = two

!   on very successful iterations, the trust-region radius will be increased by
!    the factor %radius_increase, while if the iteration is unsucceful, the 
!    radius will be decreased by a factor %radius_reduce but no more than
!    %radius_reduce_max

     REAL ( KIND = wp ) :: radius_increase = two
     REAL ( KIND = wp ) :: radius_reduce = half
     REAL ( KIND = wp ) :: radius_reduce_max = sixteenth
       
!   the smallest value the onjective function may take before the problem
!    is marked as unbounded

!$$     REAL ( KIND = wp ) :: obj_unbounded = - epsmch ** ( - 2 )

!   the maximum CPU time allowed (-ve means infinite)
     
!$$     REAL ( KIND = wp ) :: cpu_time_limit = - one

!   the maximum elapsed clock time allowed (-ve means infinite)

!$$     REAL ( KIND = wp ) :: clock_time_limit = - one
       
!   is the Hessian matrix of second derivatives available or is access only
!    via matrix-vector products?

!$$     LOGICAL :: hessian_available = .TRUE.

!   use a direct (factorization) or (preconditioned) iterative method to 
!    find the search direction

!$$     LOGICAL :: subproblem_direct = .FALSE.

!   is a retrospective strategy to be used to update the trust-region radius?

!$$     LOGICAL :: retrospective_trust_region = .FALSE.

!   should the radius be renormalized to account for a change in preconditioner?

!$$     LOGICAL :: renormalize_radius = .FALSE.

!   if %space_critical true, every effort will be made to use as little
!    space as possible. This may result in longer computation time
     
!$$     LOGICAL :: space_critical = .FALSE.
       
!   if %deallocate_error_fatal is true, any array/pointer deallocation error
!     will terminate execution. Otherwise, computation will continue

!$$     LOGICAL :: deallocate_error_fatal = .FALSE.

!  all output lines will be prefixed by %prefix(2:LEN(TRIM(%prefix))-1)
!   where %prefix contains the required string enclosed in 
!   quotes, e.g. "string" or 'string'

!$$     CHARACTER ( LEN = 30 ) :: prefix = '""                            '
     
  END TYPE NLLS_control_type

!  - - - - - - - - - - - - - - - - - - - - - - - 
!   inform derived type with component defaults
!  - - - - - - - - - - - - - - - - - - - - - - - 

  TYPE, PUBLIC :: NLLS_inform_type
     
!  return status. See NLLS_solve for details
     
     INTEGER :: status = 0
     
!  the status of the last attempted allocation/deallocation

!$$     INTEGER :: alloc_status = 0

!  the name of the array for which an allocation/deallocation error ocurred

!$$     CHARACTER ( LEN = 80 ) :: bad_alloc = REPEAT( ' ', 80 )

!  the total number of iterations performed
     
!$$     INTEGER :: iter = 0
       
!  the total number of CG iterations performed

!$$     INTEGER :: cg_iter = 0

!  the total number of evaluations of the objection function

!$$     INTEGER :: f_eval = 0

!  the total number of evaluations of the gradient of the objection function

!$$     INTEGER :: g_eval = 0

!  the total number of evaluations of the Hessian of the objection function
     
!$$     INTEGER :: h_eval = 0

!  the maximum number of factorizations in a sub-problem solve

!$$     INTEGER :: factorization_max = 0

!  the return status from the factorization

!$$     INTEGER :: factorization_status = 0

!   the maximum number of entries in the factors

!$$     INTEGER ( KIND = long ) :: max_entries_factors = 0

!  the total integer workspace required for the factorization

!$$     INTEGER :: factorization_integer = - 1

!  the total real workspace required for the factorization

!$$     INTEGER :: factorization_real = - 1

!  the average number of factorizations per sub-problem solve

!$$     REAL ( KIND = wp ) :: factorization_average = zero

!  the value of the objective function at the best estimate of the solution 
!   determined by NLLS_solve

!$$     REAL ( KIND = wp ) :: obj = HUGE( one )

!  the norm of the gradient of the objective function at the best estimate 
!   of the solution determined by NLLS_solve

!$$     REAL ( KIND = wp ) :: norm_g = HUGE( one )

!  the total CPU time spent in the package

!$$     REAL :: cpu_total = 0.0
       
!  the CPU time spent preprocessing the problem

!$$     REAL :: cpu_preprocess = 0.0

!  the CPU time spent analysing the required matrices prior to factorization

!$$     REAL :: cpu_analyse = 0.0

!  the CPU time spent factorizing the required matrices
     
!$$     REAL :: cpu_factorize = 0.0
       
!  the CPU time spent computing the search direction

!$$     REAL :: cpu_solve = 0.0

!  the total clock time spent in the package

!$$     REAL ( KIND = wp ) :: clock_total = 0.0
       
!  the clock time spent preprocessing the problem

!$$     REAL ( KIND = wp ) :: clock_preprocess = 0.0
       
!  the clock time spent analysing the required matrices prior to factorization

!$$     REAL ( KIND = wp ) :: clock_analyse = 0.0
       
!  the clock time spent factorizing the required matrices

!$$     REAL ( KIND = wp ) :: clock_factorize = 0.0
     
!  the clock time spent computing the search direction

!$$     REAL ( KIND = wp ) :: clock_solve = 0.0

  END TYPE NLLS_inform_type

  type params_base_type
     ! deliberately empty
  end type params_base_type
  
  abstract interface
     subroutine eval_f_type(status, n, m, x, f, params)
       import :: params_base_type
       implicit none
       integer, intent(out) :: status
       integer, intent(in) :: n,m 
       double precision, dimension(*), intent(in)  :: x
       double precision, dimension(*), intent(out) :: f
       class(params_base_type), intent(in) :: params
     end subroutine eval_f_type
  end interface

  abstract interface
     subroutine eval_j_type(status, n, m, x, J, params)
       import :: params_base_type
       implicit none
       integer, intent(out) :: status
       integer, intent(in) :: n,m 
       double precision, dimension(*), intent(in)  :: x
       double precision, dimension(*), intent(out) :: J
       class(params_base_type), intent(in) :: params
     end subroutine eval_j_type
  end interface

  abstract interface
     subroutine eval_hf_type(status, n, m, x, f, h, params)
       import :: params_base_type
       implicit none
       integer, intent(out) :: status
       integer, intent(in) :: n,m 
       double precision, dimension(*), intent(in)  :: x
       double precision, dimension(*), intent(in)  :: f
       double precision, dimension(*), intent(out) :: h
       class(params_base_type), intent(in) :: params
     end subroutine eval_hf_type
  end interface
  
contains


  SUBROUTINE RAL_NLLS( n, m, X,                   & 
                       eval_F, eval_J, eval_HF,    & 
                       params,                    &
                       status, options )
    
!  -----------------------------------------------------------------------------
!  RAL_NLLS, a fortran subroutine for finding a first-order critical
!   point (most likely, a local minimizer) of the nonlinear least-squares 
!   objective function 1/2 ||F(x)||_2^2.

!  Authors: RAL NA Group (Iain Duff, Nick Gould, Jonathan Hogg, Tyrone Rees, 
!                         Jennifer Scott)
!  -----------------------------------------------------------------------------

!   Dummy arguments

    USE ISO_FORTRAN_ENV
    INTEGER( int32 ), INTENT( IN ) :: n, m
    REAL( wp ), DIMENSION( n ), INTENT( INOUT ) :: X
    TYPE( NLLS_inform_type ), INTENT( OUT ) :: status
    TYPE( NLLS_control_type ), INTENT( IN ) :: options
    procedure( eval_f_type ) :: eval_F
    procedure( eval_j_type ) :: eval_J
    procedure( eval_hf_type ) :: eval_HF
    class( params_base_type ) :: params
      
    integer :: jstatus=0, fstatus=0, hstatus=0
    integer :: i
    real(wp), DIMENSION(m*n) :: J, Jnew
    real(wp), DIMENSION(m)   :: f, fnew
    real(wp), DIMENSION(n*n) :: hf
    real(wp), DIMENSION(n)   :: d, g, Xnew
    real(wp) :: Delta, rho, normJF0, normF0, md

    if ( options%print_level >= 3 )  write( options%out , 3000 ) 

    Delta = options%initial_radius
    
    call eval_J(jstatus, n, m, X, J, params)
    if (jstatus > 0) write( options%out, 1010) jstatus
    call eval_F(fstatus, n, m, X, f, params)
    if (fstatus > 0) write( options%out, 1020) fstatus
    if (options%model == 2) then
       call eval_HF(hstatus, n, m, X, f, hf, params)
       if (hstatus > 0) write( options%out, 1020) fstatus
    end if

    normF0 = norm2(f)

!    g = -J^Tf
!    call dgemv('T',m,n,-1.0,J,m,f,1,0.0,g,1)
!    g = - matmul(transpose(J),f)
    call mult_Jt(J,n,m,f,g)
    g = -g
    normJF0 = norm2(g)
    
    main_loop: do i = 1,options%maxit
       
       if ( options%print_level >= 3 )  write( options%out , 3030 ) i
       
       !+++++++++++++++++++++++!
       ! Calculate the step... !
       !+++++++++++++++++++++++!

       call calculate_step(J,f,g,n,m,Delta,d,options)
       
       !++++++++++++++++++!
       ! Accept the step? !
       !++++++++++++++++++!

       Xnew = X + d;
       call eval_J(jstatus, n, m, Xnew, Jnew, params)
       if (jstatus > 0) write( options%out, 1010) jstatus
       call eval_F(fstatus, n, m, Xnew, fnew, params)
       if (fstatus > 0) write( options%out, 1020) fstatus
       
       call evaluate_model(f,J,d,md,m,n,options)

       rho = ( norm2(f)**2 - norm2(fnew)**2 ) / &
             ( norm2(f)**2 - md)
       
       if (rho > options%eta_successful) then
          X = Xnew;
          J = Jnew;
          f = fnew;
!          g = - matmul(transpose(J),f);
          ! g = -J^Tf
!          call dgemv('T',m,n,-1.0,J,m,f,1,0.0,g,1)          
          call mult_Jt(J,n,m,f,g)
          g = -g

          if (options%print_level >=3) write(options%out,3010) 0.5 * norm2(f)**2
          if (options%print_level >=3) write(options%out,3060) norm2(g)/norm2(f)

          !++++++++++++++++++!
          ! Test convergence !
          !++++++++++++++++++!
                   
          if ( norm2(f) <= options%stop_g_absolute + &
               options%stop_g_relative * normF0) then
             if (options%print_level > 0 ) write(options%out,3020) i
             return
          end if
          if ( (norm2(g)/norm2(f)) <= options%stop_g_absolute + &
               options%stop_g_relative * (normJF0/normF0)) then
             if (options%print_level > 0 ) write(options%out,3020) i
             return
          end if
          
       end if
          
       !++++++++++++++++++++++!
       ! Update the TR radius !
       !++++++++++++++++++++++!

       if ( (rho > options%eta_very_successful) &
            .and. (rho < options%eta_too_successful) ) then
          if (options%print_level >=3) write(options%out,3040)
          Delta = max(options%maximum_radius, options%radius_increase * Delta )
       else if (rho < options%eta_successful) then
          if (options%print_level >=3) write(options%out,3050)
          Delta = max( options%radius_reduce, options%radius_reduce_max) * Delta
       end if
       
     end do main_loop

    if (options%print_level > 0 ) write(options%out,1040) 

    RETURN

! Non-executable statements

! print level > 0

1010 FORMAT('Error code from eval_J, status = ',I6)
1020 FORMAT('Error code from eval_F, status = ',I6)
1030 FORMAT('Error code from eval_H, status = ',I6)
1040 FORMAT(/,'RAL_NLLS failed to converge in the allowed number of iterations')

! print level > 1

! print level > 2
3000 FORMAT(/,'* Running RAL_NLLS *')
3010 FORMAT('0.5 ||f||^2 = ',ES12.4)
3020 FORMAT('RAL_NLLS converged at iteration ',I6)
3030 FORMAT('== Starting iteration ',i0,' ==')
3040 FORMAT('Very successful step -- increasing Delta')
3050 FORMAT('Successful step -- decreasing Delta')
3060 FORMAT('||J''f||/||f|| = ',ES12.4)
!  End of subroutine RAL_NLLS

  END SUBROUTINE RAL_NLLS
  
  SUBROUTINE calculate_step(J,f,g,n,m,Delta,d,options)
       
! -------------------------------------------------------
! calculate_step, find the next step in the optimization
! -------------------------------------------------------

     REAL(wp), intent(in) :: J(:), f(:), g(:), Delta
     integer, intent(in)  :: n, m
     real(wp), intent(out) :: d(:)
     TYPE( NLLS_control_type ), INTENT( IN ) :: options

     select case (options%nlls_method)
        
     case (1) ! Powell's dogleg
        call dogleg(J,f,g,n,m,Delta,d,options)
     case (2) ! The AINT method
        call AINT_TR(J,f,g,n,m,Delta,d,options)
     case default
        
        if ( options%print_level > 0 ) then
           write(options%error,'(a)') 'Error: unknown value of options%nlls_method'
        end if

     end select

   END SUBROUTINE calculate_step


   SUBROUTINE dogleg(J,f,g,n,m,Delta,d,options)
! -----------------------------------------
! dogleg, implement Powell's dogleg method
! -----------------------------------------

     REAL(wp), intent(in) :: J(:), f(:), g(:), Delta
     integer, intent(in)  :: n, m
     real(wp), intent(out) :: d(:)
     TYPE( NLLS_control_type ), INTENT( IN ) :: options

     real(wp) :: alpha, beta
     real(wp) :: d_sd(n), d_gn(n), ghat(n)
     ! todo: would it be cheaper to allocate this memory in the top loop?
     integer :: slls_status, fb_status
     real(wp) :: Jg(m)
     
!     Jg = 0.0
!     call dgemv('N',m,n,1.0,J,m,g,1,0.0,Jg,1)
     call mult_J(J,n,m,g,Jg)

     alpha = norm2(g)**2 / norm2( Jg )**2
       
     d_sd = alpha * g;

     ! Solve the linear problem...
     select case (options%model)
     case (1)
        ! linear model...
        call solve_LLS(J,f,n,m,options%lls_solver,d_gn,slls_status)
     case default
        if (options%print_level> 0) then
           write(options%error,'(a)') 'Error: model not supported in dogleg'
        end if
        return
     end select

     
     if (norm2(d_gn) <= Delta) then
        d = d_gn
     else if (norm2( alpha * d_sd ) >= Delta) then
        d = (Delta / norm2(d_sd) ) * d_sd
     else
        ghat = d_gn - alpha * d_sd
        call findbeta(d_sd,ghat,alpha,Delta,beta,fb_status)
        d = alpha * d_sd + beta * ghat
     end if
     
   END SUBROUTINE dogleg
     
   SUBROUTINE AINT_tr(J,f,g,n,m,Delta,d,options)
     ! -----------------------------------------
     ! AINT_tr
     ! Solve the trust-region subproblem using 
     ! the method of ADACHI, IWATA, NAKATSUKASA and TAKEDA
     ! -----------------------------------------

     REAL(wp), intent(in) :: J(:), f(:), g(:), Delta
     integer, intent(in)  :: n, m
     real(wp), intent(out) :: d(:)
     TYPE( NLLS_control_type ), INTENT( IN ) :: options
        
     REAL(wp) :: A(n,n), Jtf(n), B(n,n), p0(n), p1(n)
     integer :: solve_status, find_status
     integer :: keep_p0, i, eig_info, size_hard(2)
     real(wp) :: obj_p0, obj_p1
     REAL(wp) :: norm_p0, norm_p1, tau, lam, eta
     REAL(wp) :: M0(2*n,2*n), M1(2*n,2*n), y(2*n), gtg(n,n), q(n)
     REAL(wp), allocatable :: y_hardcase(:,:)

     keep_p0 = 0
     tau = 1e-4
     obj_p0 = (tau + tau)/(tau-tau) ! set a nan....is there a better way?

!     A = matmult(transpose(J),J) 
     call matmult_inner(J,n,m,A)
      
     call mult_Jt(J,n,m,f,Jtf)

     ! Set B to I by hand  
     ! todo: make this an option
     B = 0
     do i = 1,n
        B(i,i) = 1.0
     end do
       
     call solve_spd(A,-Jtf,p0,n,solve_status)

     call matrix_norm(p0,B,norm_p0)
     
     if (norm_p0 < Delta) then
        keep_p0 = 1;
        obj_p0 = dot_product(Jtf,p0) + 0.5 * dot_product(p0,matmul(A,p0))
     end if

     M0(1:n,1:n) = -B
     M0(n+1:2*n,1:n) = A
     M0(1:n,n+1:2*n) = A
     call outer_product(Jtf,n,gtg) ! gtg = Jtg * Jtg^T
     M0(n+1:2*n,n+1:2*n) = (-1.0 / Delta**2) * gtg

     M1 = 0.0
     M1(n+1:2*n,1:n) = -B
     M1(1:n,n+1:2*n) = -B
     
     call max_eig(M0,M1,2*n,lam, y, eig_info, y_hardcase)
     if ( eig_info > 0 ) then
        write(options%error,'(a)') 'Error in the eigenvalue computation of AINT_TR'
        write(options%error,'(a,i0)') 'LAPACK returned info = ', eig_info
        return
     end if

     if (norm2(y(1:n)) < tau) then
        ! Hard case
        ! overwrite H onto M0, and the outer prod onto M1...
        size_hard = shape(y_hardcase)
        call matmult_outer( matmul(B,y_hardcase), size_hard(2), n, M1(1:n,1:n))
        M0(1:n,1:n) = A(:,:) + lam*B(:,:) + M1(1:n,1:n)
        ! solve Hq + g = 0 for q
        call solve_spd(M0(1:n,1:n),-Jtf,q,n,solve_status)
        
        ! find max eta st ||q + eta v(:,1)||_B = Delta
        call findbeta(q,y_hardcase(:,1),1.0_wp,Delta,eta,find_status)
        if ( find_status .ne. 0 ) then
           write(*,*) 'error: no vaild beta found...'
           return
        end if
        !!!!!      ^^TODO^^    !!!!!
        ! currently assumes B = I !!
        !!!!       fixme!!      !!!!
        
        p1(:) = q(:) + eta * y_hardcase(:,1)
        
     else 
        call solve_spd(A + lam*B,-Jtf,p1,n,solve_status)
     end if

     obj_p1 = dot_product(Jtf,p1) + 0.5 * (dot_product(p1,matmul(A,p1)))

     d = p1
     if (obj_p0 < obj_p1) then
        d = p0
     end if


   end SUBROUTINE AINT_tr
   
   SUBROUTINE solve_LLS(J,f,n,m,method,d_gn,status)
       
!  -----------------------------------------------------------------
!  solve_LLS, a subroutine to solve a linear least squares problem
!  -----------------------------------------------------------------

       REAL(wp), DIMENSION(:), INTENT(IN) :: J
       REAL(wp), DIMENSION(:), INTENT(IN) :: f
       INTEGER, INTENT(IN) :: method, n, m
       REAL(wp), DIMENSION(:), INTENT(OUT) :: d_gn
       INTEGER, INTENT(OUT) :: status

       character(1) :: trans = 'N'
       integer :: nrhs = 1, lwork, lda, ldb
       real(wp), allocatable :: temp(:), work(:)
       REAL(wp), DIMENSION(:,:), allocatable :: Jlls
       integer :: i, jit

       lda = m
       ldb = max(m,n)
       allocate(temp(max(m,n)))
       temp(1:m) = f(1:m)
       lwork = max(1, min(m,n) + max(min(m,n), nrhs)*4)
       allocate(work(lwork))
       allocate(Jlls(m,n))

       do i = 1,n
          do jit = 1,m
             Jlls(jit,i) = J((i-1) * m + jit) ! We need to take a copy as dgels overwrites J
          end do
       end do

       call dgels(trans, m, n, nrhs, Jlls, lda, temp, ldb, work, lwork, status)

       d_gn = -temp(1:n)
              
     END SUBROUTINE solve_LLS
     
     SUBROUTINE findbeta(d_sd,ghat,alpha,Delta,beta,status)

!  -----------------------------------------------------------------
!  findbeta, a subroutine to find the optimal beta such that 
!   || d || = Delta, where d = alpha * d_sd + beta * ghat
!  -----------------------------------------------------------------

     real(wp), dimension(:), intent(in) :: d_sd, ghat
     real(wp), intent(in) :: alpha, Delta
     real(wp), intent(out) :: beta
     integer, intent(out) :: status
     
     real(wp) :: a, b, c, discriminant
     
     status = 0

     a = norm2(ghat)**2
     b = 2.0 * alpha * dot_product( ghat, d_sd)
     c = ( alpha * norm2( d_sd ) )**2 - Delta**2
     
     discriminant = b**2 - 4 * a * c
     if ( discriminant < 0) then
        status = 1
        return
     else
        beta = (-b + sqrt(discriminant)) / (2.0 * a)
     end if

     END SUBROUTINE findbeta

     
     subroutine evaluate_model(f,J,d,md,m,n,options)
! --------------------------------------------------
! evaluate_model, evaluate the model at the point d
! --------------------------------------------------       

       real(wp), intent(in)  :: f(:), d(:), J(:)
       integer :: m,n
       real(wp), intent(out) :: md
       TYPE( NLLS_control_type ), INTENT( IN ) :: options

       real(wp) :: Jd(m)
       
       !Jd = J*d
!       call dgemv('N',m,n,1.0,J,m,d,1,0.0,Jd,1)
       call mult_J(J,n,m,d,Jd)

       select case (options%model)
       case (1) ! first-order (no Hessian)
          md = norm2(f + Jd)**2
       case (2) ! second-order (exact hessian)
          if (options%print_level > 0) then
             write(options%error,'(a)') 'Second order methods to be implemented'
             return
          end if
       case (3) ! barely second-order (identity Hessian)
          md = norm2(f + Jd + dot_product(d,d))**2
       case default
          if (options%print_level > 0) then
             write(options%error,'(a)') 'Error: unsupported model specified'
          end if
          return
          
       end select

     end subroutine evaluate_model
     
         
     subroutine mult_J(J,n,m,x,Jx)
       real(wp), intent(in) :: J(*), x(*)
       integer, intent(in) :: n,m
       real(wp), intent(out) :: Jx(*)
       
       real(wp) :: alpha, beta

       Jx(1:m) = 1.0
       alpha = 1.0
       beta  = 0.0

       call dgemv('N',m,n,alpha,J,m,x,1,beta,Jx,1)
       
     end subroutine mult_J

     subroutine mult_Jt(J,n,m,x,Jtx)
       double precision, intent(in) :: J(*), x(*)
       integer, intent(in) :: n,m
       double precision, intent(out) :: Jtx(*)
       
       double precision :: alpha, beta

       Jtx(1:n) = 1.0
       alpha = 1.0
       beta  = 0.0

       call dgemv('T',m,n,alpha,J,m,x,1,beta,Jtx,1)

      end subroutine mult_Jt

      subroutine solve_spd(A,b,x,n,info)
        REAL(wp), intent(in) :: A(:,:), b(:)
        REAL(wp), intent(out) :: x(:)
        integer, intent(in) :: n
        integer, intent(out) :: info

        ! A wrapper for the lapack subroutine dposv.f
        x(1:n) = b(1:n)
        call dposv('U', n, 1, A, n, x, n, info)
        
      end subroutine solve_spd

      subroutine matrix_norm(x,A,norm_A_x)
        REAL(wp), intent(in) :: A(:,:), x(:)
        REAL(wp), intent(out) :: norm_A_x

        ! Calculates norm_A_x = ||x||_A = sqrt(x'*A*x)

        norm_A_x = sqrt(dot_product(x,matmul(A,x)))

      end subroutine matrix_norm

      subroutine matmult_inner(J,n,m,A)
        
        integer, intent(in) :: n,m 
        real(wp), intent(in) :: J(*)
        real(wp), intent(out) :: A(n,n)
        integer :: lengthJ
        
        ! A = J' * J
        
        lengthJ = n*m
        
        call dgemm('T','N',n, n, m, 1.0_wp,&
                   J, m, J, m, & 
                   0.0_wp, A, n)
        
        
      end subroutine matmult_inner

       subroutine matmult_outer(J,n,m,A)
        
        integer, intent(in) :: n,m 
        real(wp), intent(in) :: J(*)
        real(wp), intent(out) :: A(m,m)
        integer :: lengthJ

        ! Takes an m x n matrix J and forms the 
        ! m x m matrix A given by
        ! A = J * J'
        
        lengthJ = n*m
        
        call dgemm('N','T',m, m, n, 1.0_wp,&
                   J, m, J, m, & 
                   0.0_wp, A, m)
        
        
      end subroutine matmult_outer
      
      subroutine outer_product(x,n,xtx)
        
        real(wp), intent(in) :: x(:)
        integer, intent(in) :: n
        real(wp), intent(out) :: xtx(:,:)

        xtx(1:n,1:n) = 0.0_wp
        call dger(n, n, 1.0_wp, x, 1, x, 1, xtx, n)
        
      end subroutine outer_product

      subroutine max_eig(A,B,n,ew,ev,info,nullevs)
        
        real(wp), intent(inout) :: A(:,:), B(:,:)
        integer, intent(in) :: n 
        real(wp), intent(out) :: ew, ev(:)
        integer, intent(out) :: info
        real(wp), intent(out), allocatable :: nullevs(:,:)
        
!        real(wp) :: Aeig(n,n), Beig(n,n)
        real(wp) :: alphaR(n), alphaI(n), beta(n), vr(n,n)
        real(wp), allocatable :: work(:)
        integer :: lwork, maxindex(1), no_null, nullindex(n), halfn
        logical :: vecisreal(n)
        real(wp) :: ew_array(n), tau


        integer :: i 
        
        ! Find the max eigenvalue/vector of the generalized eigenproblem
        !     A * y = lam * B * y

        info = 0
        ! check that n is even (important for hard case -- see below)
        if (modulo(n,2).ne.0) then
           write(*,*) 'error : non-even sized matrix sent to max eig'
           info = 2
           return
        end if
        halfn = n/2

        allocate(work(1))
        ! get length of work...
        call dggev('N', & ! No left eigenvectors
                   'V', &! Yes right eigenvectors
                   n, A, n, B, n, &
                   alphaR, alphaI, beta, & ! eigenvalue data
                   vr, n, & ! not referenced
                   vr, n, & ! right eigenvectors
                   work, -1, info)

        lwork = int(work(1))
        deallocate(work)
        allocate(work(lwork))

        call dggev('N', & ! No left eigenvectors
                   'V', &! Yes right eigenvectors
                   n, A, n, B, n, &
                   alphaR, alphaI, beta, & ! eigenvalue data
                   vr, n, & ! not referenced
                   vr, n, & ! right eigenvectors
                   work, lwork, info)

        ! now find the rightmost real eigenvalue
        vecisreal = .true.
        where ( abs(alphaI) > 1e-8 ) vecisreal = .false.
        
        ew_array(:) = alphaR(:)/beta(:)
        maxindex = maxloc(ew_array,vecisreal)


        if (maxindex(1) == 0) then
           write(*,*) 'Error, all eigs are imaginary'
           info = 1 ! Eigs imaginary error
           return
        end if
        
        tau = 1e-4 ! todo -- pass this through from above...
        ! note n/2 always even -- validated by test on entry
        if (norm2( vr(1:halfn,maxindex(1)) ) < tau) then 
           ! hard case
           ! let's find which ev's are null...
           nullindex = 0
           no_null = 0
           do i = 1,n
!              write(*,*) '||v(',i,')|| = ',norm2(vr(1:halfn,i))
              if (norm2( vr(1:halfn,i)) < 1e-4 ) then
                 no_null = no_null + 1 
                 nullindex(no_null) = i
              end if
           end do
           allocate(nullevs(halfn,no_null))
           nullevs(:,:) = vr(halfn+1 : n,nullindex)
        end if
        
        ew = alphaR(maxindex(1))/beta(maxindex(1))
        ev(:) = vr(:,maxindex(1))
                
      end subroutine max_eig

end module nlls_module


