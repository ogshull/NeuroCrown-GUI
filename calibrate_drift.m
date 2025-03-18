function [time_data_DCcor, avg_reset_shape, corrected_demuxed_data, avg_env_inv_shape] = calibrate_drift(time_data_demux, demuxed_data, samps_to_cut_st, samps_to_cut_end, plot_view)
    % Inputs 
    %   time_data = n_channels x demuxed time data vec of demuxed channels
    %   demuxed_data = n_channels x demuxed data vector of demuxed channels
    %   samps_to_cut_st = n samples to ignore at start of reset (usually 50)
    %   samps_to_cut_end = n samples to ignore at end of reset (usually 1)
    %   plot_view = 0 to supress figs, 1 to see figs
    % Outputs
    %   time_data_DCcor = 
    %   avg_reset_shape = n_channels x reset time length data
    %   corrected_demuxed_data = same as demuxed_data but avg drift 

    % constants
    envelope_width = 150;

    % for first channel, calculate abs val of derivative & std to find peaks
    ch = demuxed_data(1,:);
    time_vals = time_data_demux(1,:);
    time_vals_diff = time_vals(1:end-1);
    abs_diff_ch = -(diff(ch));
    std_ch = std(abs_diff_ch);
    diff_threshold = 10*std_ch;     %15x std_dev = peak
    
    % find peaks
    [diff_peaks_mag, hpfreset_ind] = findpeaks(abs_diff_ch,'MinPeakHeight',diff_threshold,'MinPeakDistance',20);

    %first = hpfreset_ind(2)-hpfreset_ind(1)
    %second = hpfreset_ind(20)-hpfreset_ind(19)
    
    % calculate n samples between resets
    fs = length(ch)/(time_vals(end)-time_vals(1));
    reset_period = 125e-3;
    n_sample_reset = floor(fs * reset_period)
    n_ch = length(demuxed_data(:,1));
    
    if plot_view == 1
        figure(25)
        subplot(2,1,1)
        hold on
        plot(time_vals,ch)
        plot(time_vals_diff(hpfreset_ind), ch(hpfreset_ind),'ro')
    end
    
    % make vector of hpfreset times
    hpfreset_ind = hpfreset_ind(2):n_sample_reset:length(time_vals);
    n_resets = length(hpfreset_ind)-1;
    hpf_diff_out= zeros(1,n_resets-1);


    first = hpfreset_ind(2)-hpfreset_ind(1);
    second = hpfreset_ind(20)-hpfreset_ind(19);
    
    if plot_view == 1
        subplot(2,1,2)
        hold on
        plot(time_vals_diff(hpfreset_ind), ch(hpfreset_ind), 'ro')
        plot(time_vals_diff(hpfreset_ind(1)), ch(hpfreset_ind(1)), 'go')

        plot(time_vals, ch, 'b')
        figure(26)
    end
    
    % now we can find reset points for every channel
    hpfreset_ind_total = zeros(n_ch, n_resets);    % ind of reset 
    
    % initialize outputs
    length_hpfreset_clip = n_sample_reset-samps_to_cut_st-samps_to_cut_end
    hpf_clip_appended = zeros(n_ch, (n_resets-1)*length_hpfreset_clip);
    hpf_clip_per_ch = zeros((n_resets-1), length_hpfreset_clip+1);
    hpf_clip_total = zeros(n_ch, n_resets-1, length_hpfreset_clip+1);
    hpf_clip_time_total = zeros(n_ch, n_resets-1, length_hpfreset_clip+1);
    env_diff_per_ch = zeros((n_resets-1), length_hpfreset_clip+1);
    
    % final outputs
    avg_reset_shape_tot = zeros(n_ch, length_hpfreset_clip+1);
    avg_env_diff_inv_tot = zeros(n_ch, length_hpfreset_clip+1);
    corrected_demuxed_data = zeros(n_ch, (n_resets-1)*length_hpfreset_clip);
    time_data_DCcor = zeros(n_ch, (n_resets-1)*length_hpfreset_clip);

    for i = 1:n_ch
        i
        % for ith channel, calculate abs val of derivative & std to find peaks
        ch = demuxed_data(i,:);
        time_vals = time_data_demux(i,:);
        time_vals_diff = time_vals(1:end-1);
        abs_diff_ch = -(diff(ch));
        std_ch = std(abs_diff_ch);
        diff_threshold = 15*std_ch;     %anything above 15x std_dev = peak

        % find peaks
        [diff_peaks_mag, hpfreset_ind] = findpeaks(abs_diff_ch,'MinPeakHeight',diff_threshold,'MinPeakDistance',20);  

        % make vector of hpfreset times
        if i < 5 
            hpfreset_ind_clip = hpfreset_ind(2):n_sample_reset:length(time_vals_diff);
        else
            hpfreset_ind_clip = hpfreset_ind(1):n_sample_reset:length(time_vals_diff);
        end
        hpfreset_ind_clip = hpfreset_ind_clip(1:n_resets);        
        %n_resets
        %length(hpfreset_ind_clip)
        hpfreset_ind_total(i,:) = hpfreset_ind_clip;
    
        if plot_view == 1
            subplot(8,4,i)
            hold on
            plot(time_vals_diff(hpfreset_ind_clip), ch(hpfreset_ind_clip), 'ro')
            plot(time_vals, ch, 'b')
            xlabel('time)')
            ylabel('Voltage')
            title(append('Ch = ',num2str(i)))
            xlim([0 1.5])
        end
    
        % for each reset, find indicies of clip, then export the clipped
        for j = 1:n_resets-1
            % find start and end indicies 
            hpf_reset_ind_ch = hpfreset_ind_total(i,j);
            hpf_reset_ind_next = hpfreset_ind_total(i,j+1);
            hpf_reset_ind_ch_st = hpf_reset_ind_ch + samps_to_cut_st;
            hpf_reset_ind_ch_end = (hpf_reset_ind_ch + n_sample_reset) - samps_to_cut_end;
    
            % extract reset clip 
            reset_clip = ch(hpf_reset_ind_ch_st:hpf_reset_ind_ch_end);
            reset_clip_time = time_vals(hpf_reset_ind_ch_st:hpf_reset_ind_ch_end);
            start_ind_output = (j-1)*length_hpfreset_clip+1;
            end_ind_output = start_ind_output+length_hpfreset_clip;
            hpf_clip_appended(i,start_ind_output:end_ind_output) = reset_clip;
            hpf_clip_per_ch(j, :) = reset_clip;
            hpf_clip_total(i,j,:) = reset_clip;
            hpf_clip_time_total(i,j,:) = reset_clip_time;

            % calculate top and bottom envelope 
            [env_top,env_bot] = envelope(reset_clip,envelope_width,'peak');
            env_diff = (env_top - env_bot);
            env_diff_per_ch(j,:) = env_diff;

        end
    
        % calculate the average shape of the hpf reset
        avg_reset_shape_ch = mean(hpf_clip_per_ch);
        avg_env_diff_ch = mean(env_diff_per_ch) - avg_reset_shape_ch;
        avg_env_diff_ch_inv = 1./avg_env_diff_ch;

        avg_reset_shape_tot(i, :) =  avg_reset_shape_ch;
        avg_env_diff_inv_tot(i,:) = avg_env_diff_ch_inv/min(avg_env_diff_ch_inv);
    
    end

    if plot_view == 1
        % visualize hpf resets average and raw data
        figure(27)
        for i = 1:32
            subplot(4,8,i)
            hold on
            for j = 1:n_resets -1
                plot_reset = squeeze(hpf_clip_total(i,j,:));
                plot(plot_reset,'b')
            end
            plot(avg_reset_shape_tot(i,:),'r')
        end
    end
    
    % subtract the hpf reset average from each reset
    for i = 1:n_ch
        % get channel's hpf reset average
        hpf_reset_avg_ch = avg_reset_shape_tot(i, :);
        avg_env_inv_ch =  avg_env_diff_inv_tot(i, :);
    
        
        for j = 1:n_resets-1
            % subtract the average from each channel 
            hpf_clip_ch = squeeze(hpf_clip_total(i,j,:));
            hpf_clip_ch_time = squeeze(hpf_clip_time_total(i,j,:));
            hpf_clip_ch_hpf_cor = hpf_clip_ch' - hpf_reset_avg_ch;

            % get outputs indicies
            start_ind_output = (j-1)*length_hpfreset_clip+1;
            end_ind_output = start_ind_output+length_hpfreset_clip;
            corrected_demuxed_data(i,start_ind_output:end_ind_output) = (hpf_clip_ch_hpf_cor.*avg_env_inv_ch)-min(hpf_clip_ch_hpf_cor.*avg_env_inv_ch);
            time_data_DCcor(i,start_ind_output:end_ind_output) = hpf_clip_ch_time;

        end
    end
    
    % plot corrected data
    if plot_view == 1
        figure(28)
        for i = 1:n_ch
            subplot(8,4,i)
            plot(time_data_DCcor(i,:),corrected_demuxed_data(i,:))
        end
    end

    % assign outputs
    avg_reset_shape = avg_reset_shape_tot;
    avg_env_inv_shape = avg_env_diff_inv_tot;

end