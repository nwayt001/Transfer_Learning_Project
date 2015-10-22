function weight = applySML(Pmatrix)
% SML function according to Parisi et al PNAS 2014

    % These lines remove classifiers who make only positive predictions or
    % only negative predictions; it causes issues with the
    % eigendecomposition if they are not removed; we assign a weighting of
    % zero to these classifiers
    index = ones(size(Pmatrix,1),1);
    %par
    for i = 1:size(Pmatrix,1)
        if length(unique(Pmatrix(i,:))) == 1
            index(i) = 0;
        end
    end
    index = logical(index);

%     if shrink
%         Q = cov1para( Pmatrix(index,:)' ); % Use identity shrinkage
%     else
        Q = cov( Pmatrix(index,:)' );
%     end
    
    [V,~] = eig(Q); % Using direct eigendecomposition as opposed to a more advanced method
    nu = V(:,end);
%     nu = nu/sum(nu);
    
    weight = zeros(size(Pmatrix,1),1);
    weight(index) = nu;
    weight(index==0)=1/size(Pmatrix,1);
    weight = weight/sum(weight);

end

