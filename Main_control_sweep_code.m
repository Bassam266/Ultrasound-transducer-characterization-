% try
%     fclose(osc);
%     delete(osc);
%     clear osc
%     gen.disconnect();
%     delete(gen);
% end
clear all; close all; clc;
% try
%     a = instrfind;
%     fclose(a), delete(a)
% end
%% Connect to the new generator
ip  = 'USB0::0x1AB1::0x0647::DG5P272700184::0::INSTR';
gen = DG5000Pro(ip);
gen.connect();
%% Static setup (same on both channels)
burstPeriod = 1e-3;
burstCycles = 3;
burstDelay  = 3.2e-6;
for ch = 1:2
    gen.setWaveform(ch, 'SINE');
    %gen.setImpedance(ch, 'HIGHZ');
    gen.setImpedance(ch, 50);
    gen.setPhase(ch, 0);
    gen.setOffset(ch, 0);
    gen.setBurstState(ch, 'ON');
    gen.setBurstCycles(ch, burstCycles);
    gen.setBurstPeriod(ch, burstPeriod);
    gen.setDelay(ch, burstDelay);
    gen.setBurstSource(ch, 'INT');
end
gen.alignPhase();

%% Initialize oscilloscope
ipAddress = '10.48.7.251';
osc = T3DSO2502A(ipAddress);
osc.setInputBufferSize(2^22);   % Increase input buffer size to 4MB
osc.setTimeout(60);             % Set timeout to 60 seconds
osc.connect();

%% Configure oscilloscope settings
% horizontal settings
timeScale = 2e-6;
osc.setTimeScale(timeScale);
osc.setTimebaseDelay(-8.6e-6);

% acquisition and triggering
osc.setImpedance(1, 'FIFT')
osc.setImpedance(2, 'FIFT')

osc.setAcquisitionType('NORM');
osc.setTriggerType('EDGE');
osc.setTriggerLevel(10e-3);

adcMaxValue = 2^16; % Max value for a 16-bit

fs = 1.0000e+09;
timeMax = 10 * timeScale; % in sec
numSamples = fs * timeMax / 2;
%%
gen.setAmplitude(1,5);
gen.setAmplitude(2,5);
gen.setFrequency(1, 20* 1e6);
gen.setFrequency(2, 20* 1e6);
%%
gen.outputOn(1);
gen.outputOn(2);
gen.alignPhase();
%%
gen.outputOff(1);
gen.outputOff(2);
%% Sweep voltage and frequency, acquiring scope data at each step
%V    = 1:1:5;          % Volts (Vpp)
V = 5;
freq = (1:100) * 1e6;  % Hz

tic
for k_v = 1:length(V)
    gen.setAmplitude(1, V(k_v));
    gen.setAmplitude(2, V(k_v));

    % vertical scale tracks the amplitude on both channels
    osc.setVerticalScale(1, V(k_v)/7.5);
    osc.setVerticalScale(2, 2*1e-3);
    osc.setOffset(1, 0);
    osc.setOffset(2, 0);

    pause(1);

    for k_f = 1:length(freq)
        gen.setFrequency(1, freq(k_f));
        gen.setFrequency(2, freq(k_f));
        gen.outputOn(1);
        gen.outputOn(2);
        gen.alignPhase();

        fprintf('V = %.1f Vpp, freq = %.0f MHz -- acquiring\n', ...
                V(k_v), freq(k_f)/1e6);
        pause(1);   % let the signal stabilize before acquiring
        osc.resetAveragingByOffset(2); % This need to be change based on Channel and the offset level 
        pause(3);  % Wait for motor to settle
        % Acquire data from oscilloscope for both channels
        single_data1 = osc.getData(1, 1, adcMaxValue);
        %single_data2 = osc.getData(2, 1, adcMaxValue);

        single_data2 = osc.getDataAveraged(2, 1, adcMaxValue);

        gen.outputOff(1);
        gen.outputOff(2);

        % Ensure rawData has enough elements for channel 1
        if length(single_data1) >= numSamples
            data1(:, k_f, k_v) = single_data1(1:numSamples);
        else
            error('Insufficient data read from oscilloscope channel 1');
        end

        % Ensure rawData has enough elements for channel 2
        if length(single_data2) >= numSamples
            data2(:, k_f, k_v) = single_data2(1:numSamples);
        else
            error('Insufficient data read from oscilloscope channel 2');
        end

        pause(0.5);
    end
end
toc

%% Disconnect
disconnect(osc);
delete(osc);
clear osc

gen.disconnect();
delete(gen);

%% Save data with timestamp
timestamp = datestr(now, 'yyyy.dd.mm_HH.MM.SS');
filename = ['60MHz_HF_transducer_results_DG5252Pro_ave_16_withamp_focalzoneat100MHz' timestamp '.mat'];
save(filename, 'data1', 'data2', 'V', 'freq', 'fs', 'timeScale', 'numSamples');
fprintf('Data saved to %s\n', filename);
