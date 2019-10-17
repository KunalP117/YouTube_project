function [x,fval,exitflag,aux_arr] = milp_shannoncost_kkt_dev(J, K, X,joint_prob, cond_prob, prob_act,init_pt)
%MILP_GENERALCOST Summary of this function goes here
%Rational inattention test
%A and b are reserved for Ax <= b
A = zeros(J*(J-1)*K +1,X*J*K + J*K+ 2*K); %24 utility values, 12 cross decision problem maximisers, 2*2 KKT multipliers 
rowcnt = 1;

%Constraint 1 NIAS
for j = 1:J
    for l=1:J
        for k=1:K
            if(j ~= l)
                s_jindx = 1+(j-1)*X+(k-1)*X*J;
                e_jindx = X+(j-1)*X+(k-1)*X*J;
                s_lindx = 1+(l-1)*X+(k-1)*X*J;
                e_lindx = X+(l-1)*X+(k-1)*X*J;
                A(rowcnt, s_jindx:e_jindx) = -cond_prob(s_jindx:e_jindx);
                A(rowcnt,  s_lindx:e_lindx) = cond_prob(s_jindx:e_jindx);
                b(rowcnt) = -1e-3; %small negative to force strict inequality for atleast one
                rowcnt = rowcnt+1;
            end
        end
    end
end

%Constraint 2 NIAC : K=2
A(rowcnt,1:X*J*K)= -joint_prob(1:X*J*K);
A(rowcnt,X*J*K+1 : X*J*K + J*K) = prob_act(1:J*K);
b(rowcnt)=0;


% %Constraint 9 (equality)
% for i=1:X
%     for j=1:J
%         for k=1:K
%             Aeq(rowcnteq, i+(j-1)*X+(k-1)*X*J) = 1;
%             Aeq(rowcnteq, (k-1)*2+2+2*J*(K-1)+2*(J^2)*(K-1)+X*J*K) = 1;
%             if cond_prob(i+(j-1)*X+(k-1)*X*J) ~= 0
%                 Aeq(rowcnteq, (k-1)*2+1+2*J*(K-1)+2*(J^2)*(K-1)+X*J*K) = -log(cond_prob(i+(j-1)*X+(k-1)*X*J));
%             else 
%                 Aeq(rowcnteq, (k-1)*2+1+2*J*(K-1)+2*(J^2)*(K-1)+X*J*K) = 0;
%             end
%             beq(rowcnteq) = 0;
%             rowcnteq = rowcnteq+1;
%         end
%     end
% end

%%
%Solve MILP to construct utility function
%(K=2)
lb = zeros(X*J*K + J*K+ 2*K,1);
lb(X*J*K + J*K+ 2) = -Inf;
lb(X*J*K + J*K+ 4) = -Inf;

ub = ones(X*J*K + J*K+ 2*K,1);
ub(X*J*K + J*K+1 : X*J*K + J*K+ 2*K) = Inf;

nonlcon=@nonlin;

aux_arr=zeros(1,X*J*K);
for i=1:X*J*K
    aux_arr(i)=log(cond_prob(i));
end
one=ones(1,X*J);
%size(aux_arr)
%size(one)
fun = @(x) sum((x(1:X*J) - x(X*J*K + J*K + 1)*aux_arr(1:X*J) + x(X*J*K + J*K + 2)*one).^2)+ ...
    sum((x(X*J+1:X*J*K) - x(X*J*K + J*K + 3)*aux_arr(X*J+1:X*J*K) + x(X*J*K + J*K + 4)*one).^2);
%disp('2');
[x,fval,exitflag] = fmincon(fun, horzcat(init_pt(1:X*J*K+J*K),[0 0 0 0]),A,b,[],[],lb,ub,nonlcon);
%disp('1');
end

function [c,ceq] = nonlin(y)
%load('category_switch_data_mod_zero_rec.mat')
%disp('1');
%global probact;
%global jointprob;
%global stateprob;
global condprob;
%condprob
%Parameters of optimization problem
J = 6; % comments ({low count, negative; low count, neutral; low count, positive;
                %high count, negative; high count, neutral; high count, positive;
K = 2; % decision problems (category of video {most popular; other})
X = 2; % viewcount ({high, low})
c=[];
ceq=zeros(1,J*K);
r=0;
count=0;
max=0;
var=0;
%size(y)
for k=1:K
    for j=1:J
        count=count+1;
        var=0;max=0;
        for r=1:J
            var = condprob((k-1)*X*J + (j-1)*X + 1:(k-1)*X*J + (j-1)*X + X).*...
                y(mod(k,K)*X*J + (j-1)*X + 1 : mod(k,K)*X*J + (j-1)*X + X);
            var=sum(var);
            if max <= var
                max = var;
            end
        end
        ceq(count) = max - y(X*J*K + count)  ;
    end
end
%disp('3');
end
