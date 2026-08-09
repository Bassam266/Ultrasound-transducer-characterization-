%% Analysis of the data

%% Check for linearity 
V = V/1000;    %1:.5:5;
% V = 1:.5:5;
freq =(1:15) * 1e6; % Frequencies from 1 MHz to 20 MHz in steps of 1 MHz

peak = zeros(length(freq), length(V));
for kv = 1:length(V) 
    for kf = 1:length(freq)
        peak(kf, kv) = max(data2(:,kf,kv))-min(data2(:,kf,kv)); 
    end 
end

freqMHz = freq*10^(-6);
figure; surf(V, freqMHz, peak)
hold on
ylabel('Frequency [MHz]')
xlabel('Voltage [Vpp]')
zlabel('Voltage [Vpp]')
%title('Linearity of the response of the hydrophone vs V_{in}')
title('Linearity of scope')
colorbar

%% Mean calculation

% Extract peak-to-peak voltage from data for channel 1
vpp1 = zeros(length(freq), 1);
for k = 1:length(freq)
    if all(~isnan(data1(:, k)))
        vpp1(k) = max(data1(:,k)) - min(data1(:,k)); 
    else
        vpp1(k) = NaN;
        warning('NaN values detected in dataVolts1 for frequency index %d', k);
    end
end

% Extract peak-to-peak voltage from data for channel 2
vpp2 = zeros(length(freq), 1);
for k = 1:length(freq)
    if all(~isnan(data2(:, k)))
        vpp2(k) = max(data2(:,k)) - min(data2(:,k)); 
    else
        vpp2(k) = NaN;
        warning('NaN values detected in dataVolts2 for frequency index %d', k);
    end
end

%Calculate the mean peak-to-peak voltage for both channels
meanVpp1 = mean(vpp1(~isnan(vpp1))); % Exclude NaN values from mean calculation
meanVpp2 = mean(vpp2(~isnan(vpp2))); % Exclude NaN values from mean calculation

% meanVpp1
% meanVpp2

%% Plot the Vpp wrt frequency
figure;
subplot(2, 1, 1); 
hold on;
plot(freq * 1e-6, vpp1, '-o', 'DisplayName', 'Channel 1');
yline(meanVpp1, '--r', 'Mean Vpp Ch1'); % Add a horizontal line for the mean Vpp of Channel 1
xlabel('Frequency (MHz)');
ylabel('Vpp (V)');
title('Vpp vs Frequency for Channel 1');
legend;
grid on;
hold off; 

subplot(2, 1, 2);
hold on;
plot(freq * 1e-6, vpp2, '-x', 'DisplayName', 'Channel 2');
yline(meanVpp2, '--b', 'Mean Vpp Ch2'); % Add a horizontal line for the mean Vpp of Channel 2
xlabel('Frequency (MHz)');
ylabel('Vpp (V)');
title('Vpp vs Frequency for Channel 2');
legend;
grid on;
hold off;

%% Plot the waveforms wrt the frequency
figure;
subplot(2, 1, 1);
hold on;
for k = 1:length(freq)
    plot((1:numSamples) / fs * 1e6, data1(:,k)); % Plot each signal
end
xlabel('Time (?s/div)');
ylabel('Voltage (V)');
title('Signal Waveforms for Channel 1');
hold off;

subplot(2, 1, 2);
hold on;
for k = 1:length(freq)
    plot((1:numSamples) / fs * 1e6, data2(:,k)); % Plot each signal
end
xlabel('Time (?s/div)');
ylabel('Voltage (V)');
title('Signal Waveforms for Channel 2');
hold off;
%% Converting Vpp to dB re. 1V/?Pa and plot it

vpp1_db = 20 * log10(vpp1);
vpp2_db = 20 * log10(vpp2);

% Calculate the mean dB for both channels
meanVpp1_db = mean(vpp1_db(~isnan(vpp1_db))); % Exclude NaN values from mean calculation
meanVpp2_db = mean(vpp2_db(~isnan(vpp2_db))); % Exclude NaN values from mean calculation

% Plot as a function of frequency in dB
figure;
subplot(2, 1, 1); 
hold on;
plot(freq * 1e-6, vpp1_db, '-o', 'DisplayName', 'Channel 1');
yline(meanVpp1_db, '--r', 'Mean dB Ch1'); % Add a horizontal line for the mean dB of Channel 1
xlabel('Frequency (MHz)');
ylabel('(dB re. 1V/?Pa)');
title('dB vs Frequency for Channel 1');
legend;
grid on;
hold off;

subplot(2, 1, 2);
hold on;
plot(freq * 1e-6, vpp2_db, '-x', 'DisplayName', 'Channel 2');
yline(meanVpp2_db, '--b', 'Mean dB Ch2'); % Add a horizontal line for the mean dB of Channel 2
xlabel('Frequency (MHz)');
ylabel('Amplitude (dB re. 1V/?Pa)');
title('dB vs Frequency for Channel 2');
legend;
grid on;
hold off;

%% Conversion to pressure
%concatenateddatainv = readtable('/Users/bassamjameel/Documents/Postdoc-Fresnel/ChLab/DR12_UMR7249_ERC-ALPINE/ChLab/Users/Bassam/Characterization/Hydrophone/M_codes/Martina code/data & figures/concatenated_datainv.txt');
%concatenateddatainv = readtable('C:\Users\mosaic-phd\Nextcloud\Partages_recus\DR12_UMR7249_Projet-ERC-ALPINE\ChLab\Users\_archived\Martina\data & figures\concatenated_datainv.txt');
concatenateddatainv = readtable('/Users/bassamjameel/Documents/Postdoc-Fresnel/ChLab/DR12_UMR7249_ERC-ALPINE/ChLab/Users/Bassam/Characterization/Hydrophone/M_codes/Martina code/data & figures/concatenated_datainv_60MHz_interp.txt');

conversionMatrix = table2array(concatenateddatainv);

dataPressure = zeros(size(data2));
P = zeros(1,10000);
freqMHz = freq*10^(-6);

for c = 1:height(concatenateddatainv)
    for f = 1:length(freq)
        if conversionMatrix(c, 1) == freqMHz(f)
            dataPressure(:,f,:) = data2(:,f,:).* conversionMatrix(c,2);
        end
    end
end

peakPressure = zeros(length(freq), length(V));
for kv = 1:length(V) 
    for kf = 1:length(freq)
        peakPressure(kf, kv) = max(dataPressure(:,kf,kv))- min(dataPressure(:,kf,kv)); 
    end 
end


figure; surf(V, freqMHz, peakPressure)
hold on
ylabel('Frequency [MHz]')
xlabel('Voltage [Vpp]')
zlabel('Pressure [Pa]')
title('Conversion')
colorbar
%% Signal processing and FFT analysis for single trace
Fs = 1e9;                      
N  = 10000;
dt = 1/Fs;
t  = (0:N-1)*dt;                

sig = data2(:, 50);
sig = sig(:);
sig = sig - mean(sig);          % Remove DC offset just in case but here the offset zero always

% Selecting time gate 
tStart = 2.2e-6;                  
tStop  = 2.4e-6;
gate   = (t >= tStart) & (t <= tStop);
gate   = gate(:);
M      = nnz(gate);

% Hamming window, zero outside 
w = zeros(N,1);                 % full-length signal we knew it 10000, zero everywhere
w(gate) = hamming(M);           % Hamming only inside the gate

sigw = sig .* w;                % everything outside the gate is now 0

%  FFT over the full record 
Y = fft(sigw);
Y = Y(1:N/2+1);                 % single-sided
f = (0:N/2)' * Fs/N;            % 100 kHz bins

amp = abs(Y) * 2 / sum(w);      % amplitude-corrected

% Plot
figure;
subplot(2,1,1)
plot(t*1e6, sig, 'Color', [0.7 0.7 0.7]); hold on
plot(t*1e6, sigw, 'r', 'LineWidth', 1.2)
xlabel('Time [\mus]'); ylabel('Voltage [V]')
legend('Raw trace', 'After Hamming + zeroing'); grid on

subplot(2,1,2)
plot(f*1e-6, amp, 'LineWidth', 1.2)
xlabel('Frequency [MHz]'); ylabel('Amplitude [V]')
xlim([0 100]); grid on

%%  Pre-amplifier gain compensation


% Data from the figure
FreqMHz = [ 0    5    10   15   20   25   30   35   40 ...
              45   50   55   60   65   70   75   80];
ampGainDB  = [19.9 19.6 19.2 18.5 17.9 17.3 16.8 16.3 15.8 ...
              15.4 15.0 14.6 14.2 13.8 13.3 12.6 11.8];

% Interpolate the gain at every measurement frequency 
fMHz = freq(:) * 1e-6;              % the frequency from the measurement 

gainDB  = interp1(FreqMHz, ampGainDB, fMHz, 'pchip', 'extrap'); %'pchip' keeps the curve monotone and avoids the overshoot spline can give
gainLin = 10.^(gainDB / 20);        % voltage gain (20*log10 convention)

% Refer the measurement back to the amplifier INPUT 
vpp2_in = vpp2(:) ./ gainLin; %% without any gain


% Compensates only the *deviation* from a chosen reference gain, so the
% numbers stay in the same ballpark as the raw measurement.
Gref_dB = ampGainDB(1);             % e.g. the low-frequency plateau, ~19.9 dB 
corrLin = 10.^((Gref_dB - gainDB) / 20); % The correction of the gain wiht the gainDb
vpp2_c  = vpp2(:) .* corrLin;
meanVpp2_c = mean(vpp2_c, 'omitnan');

%% --- 4. Plot raw vs corrected -----------------------------------------
figure;

subplot(2,1,1);
plot(FreqMHz, ampGainDB, 'k--', 'DisplayName', 'Datasheet');
hold on;
plot(fMHz, gainDB, 'r.', 'MarkerSize', 10, 'DisplayName', 'Interpolated');
xlabel('Frequency (MHz)'); ylabel('Gain (dB)');
title('Pre-amplifier gain'); legend('Location','southwest'); grid on; hold off;

subplot(2,1,2);
plot(fMHz, vpp2, '-x', 'DisplayName', 'Raw');
hold on;
plot(fMHz, vpp2_c, '-s', 'DisplayName', 'Gain-compensated');
yline(meanVpp2_c, '--b', 'Mean (corrected)');
xlabel('Frequency (MHz)'); ylabel('Vpp (V)');
title('Channel 2'); legend; grid on; hold off;