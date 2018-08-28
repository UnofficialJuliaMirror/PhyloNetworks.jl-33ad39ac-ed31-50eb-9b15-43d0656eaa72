@testset "testing TICR" begin

@testset "ticr! on data frame, on tree" begin
truenet1 = readTopology("((((D:0.4,C:0.4):4.8,((A:0.8,B:0.8):2.2)#H1:2.2::0.7):4.0,(#H1:0::0.3,E:3.0):6.2):2.0,O:11.2);");
setGamma!(truenet1.edge[9],0.0);
truenet2 = deepcopy(truenet1);
df = CSV.read(joinpath(@__DIR__,"..","examples","buckyCF.csv")); # better for Travis and others
# df = CSV.read(joinpath(Pkg.dir("PhyloNetworks"),"examples","buckyCF.csv")); # easier locally
# without optimizing branch lengths
result1 = ticr!(truenet1,df,false);
# below: when using 4 categories and chi-square test
#@test result1[2] ≈ 25.962962962962965463 # chi-squared statistic obtained from R
#@test result1[1] ≈ 9.7092282251534852702e-06 # p-value obtained from R
# instead: 2 categories and one-sided z-test
@test result1[2] ≈ 1.480872194397731   # z statistic, from R: prop.test(2,15, p=0.05, alternative="greater", correct=F)
@test result1[1] ≈ 0.06932031690660927 # p-value, from R
@test result1[3] == Dict("[0.0, 0.01)" => 2, "[0.05, 0.1)" => 2, "[0.1, 1.0)"  => 11)
@test result1[5] ≈ 48.152697007372566418 # pseudo log-lik obtained from R
@test result1[4] ≈ 10.576940922426542713 atol=1e-5 # alpha obtained from R
# with branch length optimization
result2 = ticr!(truenet2,df,true);
setGamma!(result2[7].edge[9],0.0);
result3 = ticr!(result2[7],df,false);
#@test result3[2] ≈ 25.962962962962965463 # chi-squared statistic obtained from R
#@test result3[1] ≈ 9.7092282251534852702e-06 # p-value obtained from R
@test result3[2] ≈ 1.480872194397731   # z statistic, from R, same as above
@test result3[1] ≈ 0.06932031690660927 # p-value, from R
@test result3[3] == Dict("[0.0, 0.01)" => 2, "[0.05, 0.1)" => 2, "[0.1, 1.0)"  => 11)
@test result3[5] ≈ 54.449883693197676848 # pseudo log-lik obtained from R
@test result3[4] ≈ 20.694991969052374259 atol=1e-6 # alpha obtained from R
end

@testset "ticr! on data frame, on network" begin
truenet3 = readTopology("((((D:0.4,C:0.4):4.8,((A:0.8,B:0.8):2.2)#H1:2.2::0.7):4.0,(#H1:0::0.3,E:3.0):6.2):2.0,O:11.2);");
# without optimizing branch lengths
netresult1 = ticr!(truenet3,df,false);
#@test netresult1[2] ≈ 2.851851851851852 # chi-squared statistic
#@test netresult1[1] ≈ 0.41503515532593677 # p-value
@test netresult1[2] ≈ -0.8885233166386386  # z stat, from R: prop.test(0,15, p=0.05, alternative="greater", correct=F)
@test netresult1[1] ≈ 0.8128703403598878   # p-value, from R
@test netresult1[3] == Dict("[0.05, 0.1)" => 2, "[0.1, 1.0)"  => 13)
@test netresult1[5] ≈ 68.03708830981597 # pseudo log-lik
@test netresult1[4] ≈ 29.34808731515701 atol=1e-5 # alpha
end

@testset "ticr! on data frame, on network, on minimum pvalue, beta dist" begin
truenet3 = readTopology("((((D:0.4,C:0.4):4.8,((A:0.8,B:0.8):2.2)#H1:2.2::0.7):4.0,(#H1:0::0.3,E:3.0):6.2):2.0,O:11.2);");
# without optimizing branch lengths
netresult1 = ticr!(truenet3,df,false,minimum=true, betadist=true)
#@Test netresult1[2] ≈ 2.851851851851852 # chi-squared statistic
#@test netresult1[1] ≈ 0.41503515532593677 # p-value
@test netresult1[2] ≈ 8.589058727506838  # z stat
@test netresult1[1] ≈ 4.384234705965304e-18   # p-value
@test netresult1[3] == Dict("[0.05, 0.1)" => 1, "[0.0, 0.01)"  => 4, "[0.01, 0.05)" => 4, "[0.1, 1.0)"  => 6)
@test netresult1[5] ≈ 68.03708830981597 # pseudo log-lik
@test netresult1[4] ≈ 29.34808731515701 atol=1e-5 # alpha
end

@testset "ticr! on data frame, on network, on minimum pvalue, binomial dist" begin
truenet3 = readTopology("((((D:0.4,C:0.4):4.8,((A:0.8,B:0.8):2.2)#H1:2.2::0.7):4.0,(#H1:0::0.3,E:3.0):6.2):2.0,O:11.2);");
# without optimizing branch lengths
netresult1 = ticr!(truenet3,df,false,minimum=true, betadist=false)
#@Test netresult1[2] ≈ 2.851851851851852 # chi-squared statistic
#@test netresult1[1] ≈ 0.41503515532593677 # p-value
@test netresult1[2] ≈ 0.2961744388795461  # z stat
@test netresult1[1] ≈ 0.3835484342051387   # p-value
@test netresult1[3] == Dict("[0.05, 0.1)" => 4, "[0.0, 0.01)" => 1, "[0.1, 1.0)"  => 10)
@test netresult1[5] ≈ 68.03708830981597 # pseudo log-lik
@test netresult1[4] ≈ 29.34808731515701 atol=1e-5 # alpha
end

end
