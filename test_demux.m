% File to test function "demux.m"

cd("C:\Users\dropb\Documents\Gabi\quantify chip")
%load('demux.m')

% load sample data
time_vals = load('time_data_vals.mat',"-mat");
time_vals = time_vals.time_vec;
ai_config_data = load('ai_config_data.mat',"-mat");
analog_data = ai_config_data.ai_config.Data;

% define constants
num_ch = 32;        % number of channels in mux (32 for 32:1)
fs = 25e3;          % analog sampling rate
muxrate = 25e3;     % how quickly each channel is being switched between

% figure()
% plot(time_vals,analog_data)
% title(' Analog Data Raw')      
% xlabel('Time [s]');
% ylabel('Measurement [V]');

[time_vals_demuxed, sorted_data] = demux(time_vals, analog_data, num_ch, fs, muxrate);

figure()
hold on
for i = 1:num_ch
    subplot(4,8,i)
    plot(time_vals_demuxed(i,:), sorted_data(i,:),'o')
    title(append(' DeMUXed, ch ',num2str(i)))      
    xlabel('Time [s]');
    ylabel('Measurement [V]');
end