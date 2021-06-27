%tic;

%% Create table
% switch testGoal
%     case 'noCollision'
%         T_noColi = cell2table(cell(0,10), 'VariableNames', {'front_vehicleID', 'rear_vehicleID', 'maxspeed_rearVehicle','has_collision', 'min_distance', 'min_TTC', 'min_TTCtime' 'AEBdistance_rearVehicle', 'sensorRange_rearVehicle', 'minDec_rearVehicle'});
% %         load('.\src\Misc\Safety Evaluation Report\test_noColiNormal.mat');
%     case 'Collision'
%         T_Coli = cell2table(cell(0,8), 'VariableNames', {'front_vehicleID', 'rear_vehicleID', 'maxspeed_rearVehicle','has_collision', 'rela_impactSpeed', 'AEBdistance_rearVehicle', 'sensorRange_rearVehicle', 'minDec_rearVehicle'});
% end

%% Set the test goal
%testGoal = 'noCollision'; % the situation with no collision
%testGoal = 'Collision';   % the sitmation with collision
%testGoal = 'M1drivingModeDelay'; % malfunction 1: time delay of switching driving mode of vehicle 3
%testGoal = 'M2sensorFailure'; % malfunction 2: sensor failure of the vehicle 3
testGoal = 'L1ConsDrivingModeDelay'; % limitation: constant time delay of switching driving mode of vehicle 3

%% start test
switch testGoal
    case 'noCollision'
        %% Situation without collision
        % Delete the useless data from the table for next test
          load('.\src\Misc\Safety Evaluation Report\test_noColiNormal.mat');
          T_noColi(1:5,:)=[]; 
          save('.\src\Misc\Safety Evaluation Report\test_noColiNormal.mat','T_noColi');
         
        % Start several loops of simulation
        nr_Simulations = 5;
        for k = 1:nr_Simulations
            prepare_simulator("Analysing",0,"FI_id",3,"FI_value",-0.4*k) % for every loop the speed of vehicle 3 is changed by "k"
            evalin('base', 'run_Sim');
            
            % Create table
            %T_noColi = cell2table(cell(0,10), 'VariableNames', {'front_vehicleID', 'rear_vehicleID', 'maxspeed_rearVehicle','has_collision', 'min_distance', 'min_TTC','min_TTCtime', 'AEBdistance_rearVehicle', 'sensorRange_rearVehicle', 'minDec_rearVehicle'});
            load('.\src\Misc\Safety Evaluation Report\test_noColiNormal.mat');
            
            % Log Data + Add Data to Table
            idx = height(T_noColi);
            
            front_vehicleID = Vehicles(3).id;
            rear_vehicleID = Vehicles(4).id;
            maxspeed_rearVehicle = Vehicles(3).dynamics.maxSpeed;
            has_collision = Vehicles(3).status.collided;
            if has_collision == 0
                min_distance = min(allTestData(8,3,:));
                filtTTC = allTestData(7,3,:);  %filter out the negative TTC
                filtTTC(find(filtTTC<0)) = 1000;
                [min_TTC,min_TTCidx]= min(filtTTC); %[minimum TTC, index]
                min_TTCtime = min_TTCidx*Sim_Ts;
            else
                min_distance = 1000;
                min_TTC=1000;
                min_TTCtime = 1000;
            end
            AEBdistance_rearVehicle = Vehicles(3).sensors.AEBdistance;
            sensorRange_rearVehicle = Vehicles(3).sensors.frontSensorRange;
            minDec_rearVehicle = Vehicles(3).dynamics.minDeceleration;
            
            T_noColi(idx+1,:) = {front_vehicleID, rear_vehicleID, maxspeed_rearVehicle, has_collision, min_distance, min_TTC, min_TTCtime, AEBdistance_rearVehicle, sensorRange_rearVehicle, minDec_rearVehicle};
            save('.\src\Misc\Safety Evaluation Report\test_noColiNormal.mat','T_noColi');
        end
        
    case 'M1drivingModeDelay'
        % Delete the previous data
         load('.\src\Misc\Safety Evaluation Report\test_noColiM1.mat');
         T_noColiM1(1:10,:)=[];
         save('.\src\Misc\Safety Evaluation Report\test_noColiM1','T_noColiM1');
         
        nr_Simulations = 5;
        nr_delays = 3;
        
        % Create the matrix of the loops, if we use two layers loop, k will be cleared in prepare_simulations()
        loops_M1 = []; %[nr_delays, nr_Simulations]
        for k = 1:nr_Simulations
            for j =1: nr_delays
                loops_M1 = [loops_M1; j, k];
            end
        end
        save('.\src\Misc\Safety Evaluation Report\MalFunLoops.mat','loops_M1');
        
        for i = 1:size(loops_M1,1)
            load('.\src\Misc\Safety Evaluation Report\MalFunLoops.mat'); % load the value of delay number and simulation number
            prepare_simulator("Analysing",0,"FI_id",3,"FI_value",-0.4*loops_M1(i,2),"FI_delay",0.5*loops_M1(i,1))
            evalin('base', 'run_Sim');
            
            load('.\src\Misc\Safety Evaluation Report\test_noColiM1.mat');
            
            idx = height(T_noColiM1);
            
            delay_time = delayTimeV3; % delay time of the driving mode which is set in longitudinal control of vehicle 3
            front_vehicleID = Vehicles(3).id;
            rear_vehicleID = Vehicles(4).id;
            maxspeed_rearVehicle = Vehicles(3).dynamics.maxSpeed;
            has_collision = Vehicles(3).status.collided;
            if has_collision == 0
                min_distance = min(allTestData(8,3,:));
                filtTTC = allTestData(7,3,:);  %filter out the negative TTC
                filtTTC(find(filtTTC<0)) = 1000;
                [min_TTC,min_TTCidx]= min(filtTTC); %[minimum TTC, index]
                min_TTCtime = min_TTCidx*Sim_Ts;
            else
                min_distance = 1000;
                min_TTC=1000;
                min_TTCtime = 1000;
            end
            AEBdistance_rearVehicle = Vehicles(3).sensors.AEBdistance;
            sensorRange_rearVehicle = Vehicles(3).sensors.frontSensorRange;
            minDec_rearVehicle = Vehicles(3).dynamics.minDeceleration;
            
            T_noColiM1(idx+1,:) = {delay_time, front_vehicleID, rear_vehicleID, maxspeed_rearVehicle, has_collision, min_distance, min_TTC, min_TTCtime, AEBdistance_rearVehicle, sensorRange_rearVehicle, minDec_rearVehicle};
            save('.\src\Misc\Safety Evaluation Report\test_noColiM1.mat','T_noColiM1');
            
        end
        
    case 'M2sensorFailure'
        %% Situation without collision malfunction2- seneor failure
        % Delete the useless data from the table for next test
           load('.\src\Misc\Safety Evaluation Report\test_noColiM2.mat');
           T_noColiM2(1:4,:)=[]; 
           save('.\src\Misc\Safety Evaluation Report\test_noColiM2.mat','T_noColiM2');
          
        nr_Simulations = 5; % test the sensor with different failure rate in the same speed
        nr_failure = 0.9;
        
        % Create the matrix of the loops, if we use two layers loop, k in firs layer will be cleared in prepare_simulations()
        loops_M2 = []; %[nr_failure, nr_Simulations]
        for j =0.3:0.2: nr_failure
            for k = 1:nr_Simulations
                loops_M2 = [loops_M2; j, k];
            end
        end
        save('.\src\Misc\Safety Evaluation Report\MalFunLoops.mat','loops_M2');
         
        % Start several loops of simulation
        for i = 1:size(loops_M2,1)
            load('.\src\Misc\Safety Evaluation Report\MalFunLoops.mat'); % load the value of failure number and simulation number
            prepare_simulator("Analysing",0,"FI_id",3,"FI_value",-0.4*loops_M2(i,2),"FI_failure",loops_M2(i,1)) % for every loop the speed of vehicle 3 and failure rate are changed 
            evalin('base', 'run_Sim');
            
            % Create table
            %T_noColi = cell2table(cell(0,10), 'VariableNames', {'front_vehicleID', 'rear_vehicleID', 'maxspeed_rearVehicle','has_collision', 'min_distance', 'min_TTC','min_TTCtime', 'AEBdistance_rearVehicle', 'sensorRange_rearVehicle', 'minDec_rearVehicle'});
            load('.\src\Misc\Safety Evaluation Report\test_noColiM2.mat');
            
            % Log Data + Add Data to Table
            idx = height(T_noColiM2);
            
            failure_rate = V3_FailureRate;
            front_vehicleID = Vehicles(3).id;
            rear_vehicleID = Vehicles(4).id;
            maxspeed_rearVehicle = Vehicles(3).dynamics.maxSpeed;
            has_collision = Vehicles(3).status.collided;
            if has_collision == 0
                min_distance = min(allTestData(8,3,:));
                filtTTC = allTestData(7,3,:);  %filter out the negative TTC
                filtTTC(find(filtTTC<0)) = 1000;
                [min_TTC,min_TTCidx]= min(filtTTC); %[minimum TTC, index]
                min_TTCtime = min_TTCidx*Sim_Ts;
            else
                min_distance = 1000;
                min_TTC=1000;
                min_TTCtime = 1000;
            end
            AEBdistance_rearVehicle = Vehicles(3).sensors.AEBdistance;
            sensorRange_rearVehicle = Vehicles(3).sensors.frontSensorRange;
            minDec_rearVehicle = Vehicles(3).dynamics.minDeceleration;
            
            T_noColiM2(idx+1,:) = {failure_rate, front_vehicleID, rear_vehicleID, maxspeed_rearVehicle, has_collision, min_distance, min_TTC, min_TTCtime, AEBdistance_rearVehicle, sensorRange_rearVehicle, minDec_rearVehicle};
            save('.\src\Misc\Safety Evaluation Report\test_noColiM2.mat','T_noColiM2');
        end
     
    %% Limitation 1: constant time delay of swiching driving mode of vehicle 3    
    case 'L1ConsDrivingModeDelay'
        % Delete the previous data
        load('.\src\Misc\Safety Evaluation Report\test_noColiL1.mat');
        T_noColiL1(1:4,:)=[];
        save('.\src\Misc\Safety Evaluation Report\test_noColiL1','T_noColiL1');
         
        nr_Simulations = 5;
        for k = 1:nr_Simulations
            
            prepare_simulator("Analysing",0,"FI_id",3,"FI_value",-0.4*k,"FI_delay",2)
            evalin('base', 'run_Sim');
            
            load('.\src\Misc\Safety Evaluation Report\test_noColiL1.mat');
            
            idx = height(T_noColiL1);
            
            delay_time = delayTimeV3; % delay time of the driving mode which is set in longitudinal control of vehicle 3
            front_vehicleID = Vehicles(3).id;
            rear_vehicleID = Vehicles(4).id;
            maxspeed_rearVehicle = Vehicles(3).dynamics.maxSpeed;
            has_collision = Vehicles(3).status.collided;
            if has_collision == 0
                min_distance = min(allTestData(8,3,:));
                filtTTC = allTestData(7,3,:);  %filter out the negative TTC
                filtTTC(find(filtTTC<0)) = 1000;
                [min_TTC,min_TTCidx]= min(filtTTC); %[minimum TTC, index]
                min_TTCtime = min_TTCidx*Sim_Ts;
            else
                min_distance = 1000;
                min_TTC=1000;
                min_TTCtime = 1000;
            end
            AEBdistance_rearVehicle = Vehicles(3).sensors.AEBdistance;
            sensorRange_rearVehicle = Vehicles(3).sensors.frontSensorRange;
            minDec_rearVehicle = Vehicles(3).dynamics.minDeceleration;
            
            T_noColiL1(idx+1,:) = {delay_time, front_vehicleID, rear_vehicleID, maxspeed_rearVehicle, has_collision, min_distance, min_TTC, min_TTCtime, AEBdistance_rearVehicle, sensorRange_rearVehicle, minDec_rearVehicle};
            save('.\src\Misc\Safety Evaluation Report\test_noColiL1.mat','T_noColiL1');           
           
        end    
        
    case 'Collision'
        %% Situation with collision
        % Clear the data in table and array before every loop of test
         load('.\src\Misc\Safety Evaluation Report\test_ColiNormal.mat');
         T_Coli(1:4,:)=[];
         save('.\src\Misc\Safety Evaluation Report\test_ColiNormal.mat','T_Coli');
        
         load('.\src\Misc\Safety Evaluation Report\SpeedPlotV3V4.mat');
         speedV3V4 = [];
         save('.\src\Misc\Safety Evaluation Report\SpeedPlotV3V4.mat','speedV3V4');
         
        % Start simulation loops
        nr_Simulations = 4;
        for k = 1:nr_Simulations
            prepare_simulator("Analysing",0,"FI_id",3,"FI_value",0.45*k)
            evalin('base', 'run_Sim');
            
            % Create table
            % T_Coli = cell2table(cell(0,9), 'VariableNames', {'front_vehicleID', 'rear_vehicleID', 'maxspeed_rearVehicle','has_collision', 'rela_impactSpeed','collisionTime', 'AEBdistance_rearVehicle', 'sensorRange_rearVehicle', 'minDec_rearVehicle'});
            load('.\src\Misc\Safety Evaluation Report\test_ColiNormal.mat');
            %load speed of v3 and v4
            load('.\src\Misc\Safety Evaluation Report\SpeedPlotV3V4.mat');
            
            % Log Data + Add Data to Table
            relaSpeed_calcu = [allTestData(1,3,:), allTestData(1,4,:)]; %[speed_v3,speed_v4]
            speedV3V4 = [speedV3V4; relaSpeed_calcu]; % speed of v3 and v4 for plotting
            save('.\src\Misc\Safety Evaluation Report\SpeedPlotV3V4.mat','speedV3V4');
            
            % Find relative impact speed and colision time
            i=1;
            slopeRange = 100; % the range of the slop for the speed change in collasion
            %slope = abs((speedV3V4(end,1,i+1)-speedV3V4(end,1,i))/Sim_Ts);
            while(abs((speedV3V4(end,1,i+1)-speedV3V4(end,1,i))/Sim_Ts)<slopeRange) % the slope of the speed is big enough
                i=i+1;
            end
            speedColi_V3 = speedV3V4(end,1,i); % the speed of v3 at collision time
            speedColi_V4 = speedV3V4(end,2,i); % the speed of v4 at collision time
            collisionTime = i*Sim_Ts;            
            
            % Start load data
            idx = height(T_Coli);
            
            front_vehicleID = Vehicles(3).id;
            rear_vehicleID = Vehicles(4).id;
            maxspeed_rearVehicle = Vehicles(3).dynamics.maxSpeed;
            has_collision = Vehicles(3).status.collided;
            if has_collision ==1               
                rela_impactSpeed = speedColi_V3 - speedColi_V4;
            else
                rela_impactSpeed = 1000; % if no collision
            end
            AEBdistance_rearVehicle = Vehicles(3).sensors.AEBdistance;
            sensorRange_rearVehicle = Vehicles(3).sensors.frontSensorRange;
            minDec_rearVehicle = Vehicles(3).dynamics.minDeceleration;
            
            T_Coli(idx+1,:) = {front_vehicleID, rear_vehicleID, maxspeed_rearVehicle, has_collision, rela_impactSpeed, collisionTime, AEBdistance_rearVehicle, sensorRange_rearVehicle, minDec_rearVehicle};
            save('.\src\Misc\Safety Evaluation Report\test_ColiNormal.mat','T_Coli');
        end
        
end

%%
    %toc;
    
% function maxSpeeds = changeMaxSpeedofAVehicle(maxSpeeds,vehicleid,FiVal)
% % Change the corresponding vehicle's maxSpeed
%   maxSpeeds(vehicleid) = maxSpeeds(vehicleid) + FiVal;
% end
