%% Afric_Sim_test_ESPRIT
clc;clear;
%% Initializations
alpha = 1; %ground weighting factor
beta = 1;   %veg weighting factor

Pol_ground = [1;1;0]./sqrt(2);
Pol_vegitation = [1;1;1]./sqrt(3);

eye_4 = -0.15;
eye_2 = 0;
G_O = 30;
ground_offset = G_O*pi/180; % ground interferomitry offset
V_O = 60;
vegitation_offset = V_O*pi/180;    % veg interferomitry offset

Averaged_samples = 1000;
Window_optimal = 81;    %size of window
SNR_samples = 30;

ground_angle_4 = zeros(SNR_samples,1);
ground_angle_2 = zeros(SNR_samples,1);

vegitation_angle_4 = zeros(SNR_samples,1);
vegitation_angle_2 = zeros(SNR_samples,1);


ground_abs_4 = zeros(SNR_samples,1);
ground_abs_2 = zeros(SNR_samples,1);

vegitation_abs_4 = zeros(SNR_samples,1);
vegitation_abs_2 = zeros(SNR_samples,1);
valord = 2;
vecord = 2;

SNR = zeros(1,SNR_samples);
%% Matrix Construction
for SNR_sample = (1:SNR_samples);
    
    SNR(SNR_sample) = SNR_sample-10;
    Noise = (10^(-SNR(SNR_sample)/20))/sqrt(3);
    
    for unusedvariable = 1:Averaged_samples
        
        %% Matrix Construction
        
        g =  Pol_ground*exp(1i*2*pi*rand(1,Window_optimal));
        v =  Pol_vegitation*exp(1i*2*pi*rand(1,Window_optimal));
        
        s1 = alpha*g + beta*v;
        s2 = alpha*exp(1i*ground_offset)*g + beta*exp(1i*vegitation_offset)*v;
        
        s1_Noise = s1 + Noise*sqrt(-2*log(1-rand(3,Window_optimal))).*exp(1i*2*pi*rand(3,Window_optimal));
        s2_Noise = s2 + Noise*sqrt(-2*log(1-rand(3,Window_optimal))).*exp(1i*2*pi*rand(3,Window_optimal));
        
        %% Second Order Stats
        
        S1_2 = [s1_Noise(1,:)
            s1_Noise(2,:)
            s1_Noise(3,:)];
        
        S2_2 = [s2_Noise(1,:)
            s2_Noise(2,:)
            s2_Noise(3,:)];
        
        R1_2 = S1_2*S1_2'/Window_optimal;
        R2_2 = S1_2*S2_2'/Window_optimal;
        
        [eigenvec_2,eigenval_2] =eig((pinv(R1_2 + eye_2*eye(3)))...
            *R2_2,'nobalance');
        
        [~,srt_2]=sort(abs(diag(eigenval_2)),'descend');
        Leig_copol = (eigenval_2(srt_2(1),srt_2(1))^valord)....
            *abs(eigenvec_2(1,srt_2(1)))^vecord....
            + abs(eigenvec_2(2,srt_2(1)))^vecord;
        
        SLeig_copol = (eigenval_2(srt_2(1),srt_2(1))^valord)....
            *abs(eigenvec_2(1,srt_2(2)))^vecord....
            + abs(eigenvec_2(2,srt_2(2)))^vecord;
        if (Leig_copol >= SLeig_copol)
            
            ground_angle_2(SNR_sample) = ground_angle_2(SNR_sample)....
                + ((ground_offset - abs(angle(eigenval_2(srt_2(1),srt_2(1)))))^2)/Averaged_samples;
            
            vegitation_angle_2(SNR_sample) = vegitation_angle_2(SNR_sample)....
                + ((vegitation_offset - abs(angle(eigenval_2(srt_2(2),srt_2(2)))))^2)/Averaged_samples;
            
            ground_abs_2(SNR_sample) = ground_abs_2(SNR_sample)....
                + abs(eigenval_2(srt_2(1),srt_2(1)))/Averaged_samples;
            
            vegitation_abs_2(SNR_sample) = vegitation_abs_2(SNR_sample)....
                + abs(eigenval_2(srt_2(2),srt_2(2)))/Averaged_samples;
        else
            
            ground_angle_2(SNR_sample) = ground_angle_2(SNR_sample)....
                + ((ground_offset - abs(angle(eigenval_2(srt_2(2),srt_2(2)))))^2)/Averaged_samples;
            
            vegitation_angle_2(SNR_sample) = vegitation_angle_2(SNR_sample)....
                + ((vegitation_offset - abs(angle(eigenval_2(srt_2(1),srt_2(1)))))^2)/Averaged_samples;
            
            ground_abs_2(SNR_sample) = ground_abs_2(SNR_sample)....
                + abs(eigenval_2(srt_2(2),srt_2(2)))/Averaged_samples;
            
            vegitation_abs_2(SNR_sample) = vegitation_abs_2(SNR_sample)....
                + abs(eigenval_2(srt_2(1),srt_2(1)))/Averaged_samples;
        end
        
        %% Fourth Order Statistics
        [ Cumulant_11, Cumulant_12 ] = Cumulant( s1_Noise ,s2_Noise,Window_optimal );
        [eigenvec_4,eigenval_4] = eig((pinv(Cumulant_11+eye_4*eye(6)))...
            *Cumulant_12,'nobalance');

        [~,srt_4] = sort(sqrt(abs(diag(eigenval_4))),'descend');
        
        
        LeigTemp  = (abs(eigenval_4(srt_4(1),srt_4(1))))^valord....
            *(abs(eigenvec_4(3,srt_4(1)))^vecord....
            + abs(eigenvec_4(5,srt_4(1)))^vecord....
            + abs(eigenvec_4(6,srt_4(1)))^vecord);
        
        SLeigTemp = (abs(eigenval_4(srt_4(2),srt_4(2))))^valord...
            *(abs(eigenvec_4(3,srt_4(2)))^vecord....
            + abs(eigenvec_4(5,srt_4(2)))^vecord....
            + abs(eigenvec_4(6,srt_4(2)))^vecord);
        
        if LeigTemp >= SLeigTemp
            vegitation_angle_4(SNR_sample) = vegitation_angle_4(SNR_sample)....
                + ((vegitation_offset - abs(0.5*angle(eigenval_4(srt_4(1),srt_4(1)))))^2)/Averaged_samples;
            
            ground_angle_4(SNR_sample) = ground_angle_4(SNR_sample)....
                + ((ground_offset - abs(0.5*angle(eigenval_4(srt_4(2),srt_4(2)))))^2)/Averaged_samples;
            
            vegitation_abs_4(SNR_sample) = vegitation_abs_4(SNR_sample)....
                + sqrt(abs(eigenval_4(srt_4(1),srt_4(1))))/Averaged_samples;
            
            ground_abs_4(SNR_sample) = ground_abs_4(SNR_sample)....
                + sqrt(abs(eigenval_4(srt_4(2),srt_4(2))))/Averaged_samples;
        else
            
            vegitation_angle_4(SNR_sample) = vegitation_angle_4(SNR_sample)....
                + ((vegitation_offset - abs(0.5*angle(eigenval_4(srt_4(2),srt_4(2)))))^2)/Averaged_samples;
            
            ground_angle_4(SNR_sample) = ground_angle_4(SNR_sample)....
                + ((ground_offset - abs(0.5*angle(eigenval_4(srt_4(1),srt_4(1)))))^2)/Averaged_samples;
            
            vegitation_abs_4(SNR_sample) = vegitation_abs_4(SNR_sample)....
                +  sqrt(abs(eigenval_4(srt_4(2),srt_4(2))))/Averaged_samples;
            
            ground_abs_4(SNR_sample) = ground_abs_4(SNR_sample)....
                + sqrt(abs(eigenval_4(srt_4(1),srt_4(1))))/Averaged_samples;
        end
    end
end

%% Root Mean Square
ground_angle_2 = sqrt(ground_angle_2)*180/pi;
vegitation_angle_2 = sqrt(vegitation_angle_2)*180/pi;

ground_angle_4 = sqrt(ground_angle_4)*180/pi;
vegitation_angle_4 = sqrt(vegitation_angle_4)*180/pi;

%% Plotting Results

figure(1);
title('2nd and 4rth Order Modified ESPRIT Interferometric Phases');
xlabel('SNR dB');ylabel('Int Phase (Degrees)');
hold on;
plot(SNR,10*log10(ground_angle_4),'bx');
plot(SNR,10*log10(vegitation_angle_4),'gx');
plot(SNR,10*log10(ground_angle_2),'bo');
plot(SNR,10*log10(vegitation_angle_2),'go');
legend('4rth Order Ground','4rth Order Vegetation','2nd Order Ground','2nd Order Vegetaion','Location','northeast')
hold off

figure(2);
title('2nd and 4rth Order ESPRIT Coherance');
xlabel('SNR dB');ylabel('Magnitude');
hold on;
plot(SNR,abs(ground_abs_4),'bx');
plot(SNR,abs(vegitation_abs_4),'gx');
plot(SNR,abs(ground_abs_2),'bo');
plot(SNR,abs(vegitation_abs_2),'go');
axis([-10,20,0,2]);
legend('4rth Order Ground','4rth Order Vegetation','2nd Order Ground','2nd Order Vegetaion','Location','northwest')
hold off