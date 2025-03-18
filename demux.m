function [time_data, demuxed_data] = demux(time_mux, muxed_signal, n_channels, sample_rate, mux_rate)
    % Inputs
    %   time_mux = raw time value
    %   muxed_signal = raw single output of muxed channels
    %   n_channels = how many channels are within the muxed signal (32)
    %   sample_rate = analog sample rate used to acquire the raw signal
    %   mux_rate = clock rate used to change channels (often same as sample
    %   rate if recording one analog point per digital change). 
    % Outputs 
    %   time_data = n_channels x demuxed time data vec of demuxed channels
    %   demuxed_data = n_channels x demuxed data vector of demuxed channels

    % find total time duration
    time_duration = round((time_mux(end) - time_mux(1)),2);

    % calculate total 
    n_samples = length(muxed_signal);
    n_samples_per_mux = n_samples/(mux_rate*time_duration);
    sample_gap = round((n_channels*n_samples_per_mux),2);          % number of samples between samples within a channel 
    remainder_samples = rem(n_samples, sample_gap); %cutoff non-integer multiples
    fs_per_ch = (n_samples-remainder_samples)/sample_gap;

    % init outputs
    demuxed_data = zeros(n_channels,fs_per_ch);
    time_data = zeros(n_channels,fs_per_ch);
    
    % extract time and data of channels
    for i = 1:n_channels
        demuxed_ch = zeros(1,fs_per_ch);
        demuxed_time =  zeros(1,fs_per_ch);
        k = 1;

        % Extract the i th channel
        for j = i*n_samples_per_mux:sample_gap:n_samples-remainder_samples
            j = round(j);
            demuxed_samp = muxed_signal(j);
            demuxed_ch(1,k) = demuxed_samp;

            time_samp = time_mux(j);
            demuxed_time(1,k) = time_samp;
            k = k + 1;  
        end

        % add to output data
        demuxed_data(i,:) = demuxed_ch;
        time_data(i,:) = demuxed_time;
    end

end