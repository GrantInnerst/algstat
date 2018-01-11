#include <Rcpp.h>
#include "sis_tbl.h"
using namespace Rcpp;

// [[Rcpp::export]]
List metropolis_uniform_cpp(
    IntegerVector current, 
    IntegerMatrix moves,
    IntegerVector suff_stats,
    IntegerMatrix config,
    int iter, int thin, 
    bool hit_and_run, 
    bool SIS, bool non_uniform, 
    bool adaptive
){

  int nTotalSamples = iter * thin;         // total number of steps
  int n = current.size();                  // number of cells
  int nMoves = moves.ncol();               // number of moves
  IntegerMatrix steps(n, iter);            // columns are states
  IntegerVector whichMove(nTotalSamples);  // move selection
  NumericVector unifs(nTotalSamples);      // for transition probabilities
  NumericVector unifs2(nTotalSamples);
  NumericVector unifs3(nTotalSamples);
  IntegerVector proposal(n);               // the proposed moves
  double prob;                             // the probability of transition
  double prob2;
  bool anyIsNegative;
  IntegerVector move(n);
  double accept_prob = 0;
  IntegerVector current_num;
  IntegerVector move_num;
  IntegerVector stepSize;
  IntegerVector upperBound;
  IntegerVector lowerBound;
  int lb;
  int ub;
  IntegerVector constant = IntegerVector::create(-1,1);
  IntegerVector w_current(n);
  IntegerVector w_proposal(n);
  IntegerVector run;

  Function sample("sample");
  whichMove = sample(nMoves, nTotalSamples, 1);
  Function runif("runif");
  unifs = runif(nTotalSamples);
  unifs2 = runif(nTotalSamples);
  unifs3 = runif(nTotalSamples);
  Function print("print");
  
  NumericVector move_dist = rep(1.0, nMoves);
  double counter = moves.ncol();
  int which_move;
  
  for(int i = 0; i < iter; ++i){
    for(int j = 0; j < thin; ++j){
      
      if(non_uniform == true){
        for(int l = 0; l < nMoves; ++l){
          double sums = 0;
          for(int m = 0; m < l+1; ++m){
            sums = sums + move_dist[m];
          }
          
          if(unifs3[thin*i+j] <= sums / counter){
            
            for(int k = 0; k < n; ++k){
              move[k] = moves(k, l);
            }
            which_move = l;
            break;
          }
        }
        for(int k = 0; k < n; ++k){
          proposal[k] = current[k] + move[k];
        }
      }else{
        
        // make move
        for(int k = 0; k < n; ++k){
          move[k] = moves(k, whichMove[thin*i+j]-1);
        }
        if(hit_and_run == true){
          current_num = current[move != 0];
          move_num = move[move != 0];
          stepSize = (-1 * current_num) / move_num;
          lowerBound = stepSize[stepSize < 0];
          upperBound = stepSize[stepSize > 0];
          lb = max(lowerBound);
          ub = min(upperBound);
          
          if(adaptive){
            int line_length = ub-lb;
            for(int m = 0; m < n;++m){
              w_current[m] = current[m];
            }
            
            for(int l = 0; l < line_length;++l){
              int constant2 = as<int>(Rcpp::sample(constant, 1));
              for(int k = 0; k < n;++k){
                w_proposal[k] = w_current[k] + constant2 * move[k];
              }
              bool anyIsNegative2;
              anyIsNegative2 = false;
              for(int k = 0; k < n; ++k){
                if(w_proposal[k] < 0){
                  anyIsNegative2 = true;
                }
              }
              
              if(anyIsNegative2){
                prob2 = 0;
              } else {
                prob2 = exp( sum(lgamma(w_current+1)) - sum(lgamma(w_proposal+1)) );
              }
              
              if(prob2 > 1){
                prob2 = 1;
              }
              
              // make move
              if(unifs[l] < prob2){
                for(int k = 0; k < n; ++k){
                  w_current[k] = w_proposal[k];
                }
              }
            }
            for(int k = 0; k < n; ++k){
              proposal[k] = w_current[k];
            }
            //Attempt at recursively calling MCMC routine 
            //  List MCMC_out = metropolis_hypergeometric_cpp(current, as<IntegerMatrix>(move), suff_stats, config, 50, 1, false, false, false);
            //  IntegerMatrix mini_steps = MCMC_out[0];
            //  int step_length = mini_steps.ncol();
            //  proposal = mini_steps(_, step_length);
          } else {
          
          if(is_true(any(stepSize == 0))){
            IntegerVector test1 = current + lb * move;
            IntegerVector test2 = current + ub * move;
            for(int i = 0; i < n; ++i){
              if(test1[i] < 0) lb = 1;
              if(test2[i] < 0) ub = -1;
            }
          }
          if(lb > ub){
            run[0] = 1;
          }else{
          
          IntegerVector range = seq(lb,ub);
          
          run = Rcpp::sample(range,1);
          
            }
          if(run[0] == 0){
            run[0] = 1;
          }
        }
        if(hit_and_run == TRUE){
          for(int k = 0; k < n; ++k){
            proposal[k] = current[k] + as<int>(run) * move[k];
          }
        }
        } else {
          for(int k = 0; k < n; ++k){
            proposal[k] = current[k] + move[k];
          }
        }
      }
      if(SIS){
        if(unifs2[i] < .05){
          proposal = sis_tbl(config, suff_stats);
        }
      }
      // compute probability of transition
      anyIsNegative = false;
      for(int k = 0; k < n; ++k){
        if(proposal[k] < 0){
          anyIsNegative = true;
        }
      }

      if(anyIsNegative){
        prob = 0;
      } else {
        prob = 1; // accept every proposal = uniform
      }

      if(prob > 1){
        prob = 1;
      }

      // store acceptance probability
      accept_prob = accept_prob + prob / nTotalSamples;

      if(non_uniform == true){
        
        if(unifs[thin*i+j] < prob){
          for(int k = 0; k < n; ++k){
            current[k] = proposal[k];
          }
          
          move_dist[which_move] = move_dist[which_move] + 1;
          ++counter;
        }
      }else{
        // make move
        if(unifs[thin*i+j] < prob){
          
          for(int k = 0; k < n; ++k){
            current[k] = proposal[k];
          }
          
        }
      }

    }

    // assign state move
    for(int k = 0; k < n; ++k){
      steps(k,i) = current[k];
    }
  }

  // create out list
  List out = List::create(
    Rcpp::Named("steps") = steps,
    Rcpp::Named("accept_prob") = accept_prob
  );

  return out;
}

