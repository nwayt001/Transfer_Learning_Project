function [pi, psi,eta] = balancedAccuracy( pseudoLabels , trueLabels )
    
    index = trueLabels==1;
    psi = sum(pseudoLabels(index) == 1)/sum(index);
    eta = sum(pseudoLabels(~index) == -1)/sum(~index);
    pi = 0.5 * ( psi + eta );

end

