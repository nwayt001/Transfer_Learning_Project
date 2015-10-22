function [ ensembleScore , ensembleLabel ] = ensembleClassify(trial,model)
% classify test observation with an ensemble of MDRM models 
    M = length(model);
    ensembleScore = zeros(M,1);
    ensembleLabel = ensembleScore;
     
    %parfor    
    for i = 1:M
        SCM = getCovarianceMatrices( trial , model(i).P );
        ensembleScore(i) = distance_riemann( SCM , model(i).mean{1}...
            ) - distance_riemann( SCM , model(i).mean{2} );
        ensembleLabel(i) = sign( ensembleScore(i) );
    end
end