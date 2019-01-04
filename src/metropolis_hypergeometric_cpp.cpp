#include <Rcpp.h>
#include "sis_tbl.h"
#include "hit_and_run_fun.h"
#include "adaptive_fun.h"
using namespace Rcpp;

// [[Rcpp::export]]


List metropolis_hypergeometric_cpp(
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
  bool anyIsNegative;
  IntegerVector move(n);
  double accept_prob = 0;
  
  Function sample("sample");
  whichMove = sample(nMoves, nTotalSamples, 1);
  Function runif("runif");
  unifs = runif(nTotalSamples);
  unifs2 = runif(nTotalSamples);
  unifs3 = runif(nTotalSamples);
  Function print("print");

  NumericVector move_dist = rep(1.0, nMoves);
  double counter = sum(move_dist);
  int which_move;
  
  for(int i = 0; i < iter; ++i){
    for(int j = 0; j < thin; ++j){
      
      if(non_uniform){
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
        
      } else {
      
      // make move
      for(int k = 0; k < n; ++k){
        move[k] = moves(k, whichMove[thin*i+j]-1);
      }

      // make proposal
      if(hit_and_run) proposal = hit_and_run_fun(current, move);
      
      if(adaptive) proposal = adaptive_fun(current, move);
      
      if(hit_and_run == false & adaptive == false & non_uniform == false) {
        for(int k = 0; k < n; ++k){
          proposal[k] = current[k] + move[k];
        }
      }
    }
      if(SIS){
        if(unifs2[i] < .01) proposal = sis_tbl(config, suff_stats);
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
        prob = exp( sum(lgamma(current+1)) - sum(lgamma(proposal+1)) );
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
      } else {
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

