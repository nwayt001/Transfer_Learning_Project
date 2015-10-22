function [ features ] = getCovarianceMatrices( TestData, targetERP )


% concatenate the data with the targetERP, then take covariance
for i = 1 : size(TestData, 3)
    temp1 = [targetERP; TestData(:,:,i)];
    %             features(:,:,i) = 1/512 * temp1*temp1';
    features(:,:,i) = cov(temp1');
end

end

