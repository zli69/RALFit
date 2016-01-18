/* COPYRIGHT (c) 2015 Science and Technology Facilities Council (STFC)
 * All rights reserved
 */
#ifdef __cplusplus
extern "C" {
#else
#include <stdbool.h>
#endif

#ifndef ral_nlls_h
#define ral_nlls_h

#ifndef ral_nlls_options_type
#define ral_nlls_default_options ral_nlls_default_options_d
#define ral_nlls_options ral_nlls_options_d
#define ral_nlls_inform ral_nlls_inform_d
#define nlls_solve nlls_solve_d
#endif

typedef double ral_nllspkgtype_d_;

/* Derived type to hold control parameters for ral_nlls */
struct ral_nlls_options_d {
  int f_arrays; /* Use 1-based indexing if true(!=0) else 0-based */
  
  int error; /* Fortran output stream for error messages */
  int out;   /* Fortran output stream for general messages */
  int print_level; /* levels of print output */
  int maxit; /* maximum number of iterations */
  int model; /* what model to use? */
  int nlls_method; /* what nlls method to use? */
  int lls_solver; /* which lls solver to use? */
  ral_nllspkgtype_d_ stop_g_absolute; /* absolute stopping tolerance */
  ral_nllspkgtype_d_ stop_g_relative; /* relative stopping tolerance */
  ral_nllspkgtype_d_ relative_tr_radius; /* ??? */
  ral_nllspkgtype_d_ initial_radius_scale; /* ??? */
  ral_nllspkgtype_d_ initial_radius; /* initial trust region radius */
  ral_nllspkgtype_d_ maximum_radius; /* maximux trust region radius */
  ral_nllspkgtype_d_ eta_successful; /* trust region step successful level */
  ral_nllspkgtype_d_ eta_very_successful; /* trust region step very successful */
  ral_nllspkgtype_d_ eta_too_successful; /* trust region step too successful */
  ral_nllspkgtype_d_ radius_increase; /* how much to increase the radius by? */
  ral_nllspkgtype_d_ radius_reduce; /* how much to reduce the radius by? */
  ral_nllspkgtype_d_ radius_reduce_max; /* max amount to reduce the radius by */
  ral_nllspkgtype_d_ hybrid_switch;
  bool exact_second_derivatives;
  bool subproblem_eig_fact;
  int more_sorensen_maxits;
  ral_nllspkgtype_d_ more_sorensen_shift;
  ral_nllspkgtype_d_ more_sorensen_tiny;
  ral_nllspkgtype_d_ more_sorensen_tol;
  ral_nllspkgtype_d_ hybrid_tol;
  int hybrid_switch_its;
  bool output_progress_vectors;
};

struct ral_nlls_inform_d {
  int status; /* flag */
  int alloc_status;
  int iter;
  int f_eval;
  int g_eval;
  int h_eval;
  int convergence_normf;
  ral_nllspkgtype_d_ resinf;
  ral_nllspkgtype_d_ gradinf;
  ral_nllspkgtype_d_ obj;
  ral_nllspkgtype_d_ norm_g;
};

/* Set default values of control */
void ral_nlls_default_options_d( struct ral_nlls_options_d *options );

/* define the eval_f_type */
typedef int (*ral_nlls_eval_r_type) (
			     int n, 
			     int m,
			     const void *params,
			     const ral_nllspkgtype_d_ *x, 
			     ral_nllspkgtype_d_ *f
              );
  
typedef int (*ral_nlls_eval_j_type) (
			     int n, 
			     int m,
              const void *params,
			     const ral_nllspkgtype_d_ *x, 
			     ral_nllspkgtype_d_ *j
			     );

typedef int (*ral_nlls_eval_hf_type) (
			      int n, 
			      int m,
			      const void *params,
			      const ral_nllspkgtype_d_ *x, 
			      const ral_nllspkgtype_d_ *f,
			      ral_nllspkgtype_d_ *hf
               );

/* Perform the nlls solve */
void nlls_solve_d( int n, int m, 
		   ral_nllspkgtype_d_ X[],
		   ral_nlls_eval_r_type eval_r,
		   ral_nlls_eval_j_type eval_j,
		   ral_nlls_eval_hf_type eval_hf,
		   void const* params, 
		   struct ral_nlls_inform *status,
		   struct ral_nlls_options const* options);

#endif

#ifdef __cplusplus
} /* extern "C" */
#endif
