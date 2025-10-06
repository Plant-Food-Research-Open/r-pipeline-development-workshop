
data{
     int N;
     int y[N];
     int majority_first[N];
 }
 parameters{
     simplex[5] p;
 }
 model{
     vector[5] phi;

     // prior
     p ~ dirichlet( rep_vector(4,5) );

     // probability of data
     for ( i in 1:N ) {
         if ( y[i]==2 ) phi[1]=1; else phi[1]=0; // majority
         if ( y[i]==3 ) phi[2]=1; else phi[2]=0; // minority
         if ( y[i]==1 ) phi[3]=1; else phi[3]=0; // maverick
         phi[4]=1.0/3.0;                         // random
         if ( majority_first[i]==1 )             // follow first
             if ( y[i]==2 ) phi[5]=1; else phi[5]=0;
         else
             if ( y[i]==3 ) phi[5]=1; else phi[5]=0;

         // compute log( p_s * Pr(y_i|s )
         for ( j in 1:5 ) phi[j] = log(p[j]) + log(phi[j]);
         // compute average log-probability of y_i
         target += log_sum_exp( phi );
    }
}
