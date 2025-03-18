function [time_fixed, demuxed_fixed] = remove_drift(time_drift, demuxed_data_drift, avg_reset_tot, avg_env_tot, samps_to_cut_st, samps_to_cut_end, plot_view, output_mode)

    nresets = floor(length(demuxed_data_drift)/(length(avg_reset_tot)+samps_to_cut_st-samps_to_cut_end));
    nsamps_perclip = length(avg_reset_tot);
    nsamps_perclip_beforecut = nsamps_perclip + samps_to_cut_st + samps_to_cut_end - 1;
    length_after_corr = (nresets-2)*nsamps_perclip;
    n_ch = length(demuxed_data_drift(:,1));
    
    % init outputs
    demuxed_fixed = zeros(n_ch,length_after_corr);
    time_fixed = zeros(n_ch,length_after_corr);

    % subtract the hpf reset average from each reset
    for i = 1:n_ch
        % get channel's hpf reset average
        hpf_reset_avg_ch = avg_reset_tot(i, :);
        env_inv_scale_ch = avg_env_tot(i,:);
        demuxed_data_ch = demuxed_data_drift(i,:);
        demuxed_time_ch = time_drift(i,:);

        % Find the HPF resets by derivative of sig
        abs_diff_ch = -(diff(demuxed_data_ch));
        std_ch = std(abs_diff_ch);
        diff_threshold = 15*std_ch;     %10x std_dev = peak

        % find hpf resets
        [diff_peaks_mag, hpfreset_ind] = findpeaks(abs_diff_ch,'MinPeakHeight',diff_threshold,'MinPeakDistance',20);

        % make vector of regularly spaced points of hpf resets
        n_sample_reset = nsamps_perclip_beforecut;
        hpfreset_ind = hpfreset_ind(1):n_sample_reset:length(demuxed_data_ch);
        nresets = length(hpfreset_ind);
        %end

        
        % find each hpf reset, subtract average drift, and output
        for j = 1:nresets-1
            strt_reset = hpfreset_ind(j)+samps_to_cut_st;
            end_reset = (hpfreset_ind(j)+nsamps_perclip+samps_to_cut_st)-1; 
            hpf_clip = demuxed_data_ch(strt_reset:end_reset);
            hpf_clip_corr = hpf_clip - hpf_reset_avg_ch;
            hpf_clip_time = demuxed_time_ch(strt_reset:end_reset);

            % output
            strt_out_ind = (j-1)*nsamps_perclip+1;
            end_out_ind = strt_out_ind+nsamps_perclip-1;
            if output_mode == 1 % if output mode == 1, just output hpf subtracted
                demuxed_fixed(i,strt_out_ind:end_out_ind) = hpf_clip_corr;
            elseif output_mode == 2 %if output mode == 2 then also do gain correct
                demuxed_fixed(i,strt_out_ind:end_out_ind) = hpf_clip_corr.*env_inv_scale_ch;
            end

            time_fixed(i,strt_out_ind:end_out_ind) = hpf_clip_time;   

            if plot_view == 1 && i == 5 && j == 10
                figure(31)
                subplot(3,1,1)
                hold on
                plot(demuxed_time_ch, demuxed_data_ch,'bo')
                plot(demuxed_time_ch(hpfreset_ind), demuxed_data_ch(hpfreset_ind),'ro')
                subplot(3,1,2)
                hold on
                plot(hpf_reset_avg_ch,'r')
                plot(hpf_clip,'b')
                subplot(3,1,3)
                plot(hpf_clip_corr)

                hpfreset_ind(j+1)-hpfreset_ind(j);
            end
        end


    end

    if plot_view == 1
        figure(32)        
        for i = 1:n_ch
            subplot(8,4,i)
            plot(time_fixed(i,:), demuxed_fixed(i,:))
            
        end
    end

end