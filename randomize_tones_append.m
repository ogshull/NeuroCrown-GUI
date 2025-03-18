function [speaker_out, freq_order_tot] = randomize_tones_append(tone_samples, freq_vals, n_copies_repeat)
    % tone_samples = output of generate_tones
    % n_copies_repeat = how many times to repeat the tones 

    [n_freqs,n_samples] = size(tone_samples);

    n_tot_tones = n_freqs*n_copies_repeat;
    freq_order_tot = [];
    speaker_out = zeros(1,n_tot_tones*n_samples);

    ind_speaker_out = 0;
    for i = 1:n_copies_repeat
        
        ind_vals = 1:1:n_freqs;
        ran_ind_vals = ind_vals(randperm(length(ind_vals)));
        freq_vals_shuffled = freq_vals(ran_ind_vals);
        freq_order_tot = [freq_order_tot, freq_vals_shuffled];
        
        for j = 1:n_freqs
            ind_speaker_out = ind_speaker_out + 1;
            out_freq_sample = tone_samples(ran_ind_vals(j),:);
            speaker_out(n_samples*(ind_speaker_out-1)+1:n_samples*(ind_speaker_out)) = out_freq_sample;            
        end
    end

end