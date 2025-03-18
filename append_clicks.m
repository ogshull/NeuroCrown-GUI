function speaker_out = append_clicks(click_period, n_copies_repeat)
    % click_period = output of generate_clicks
    % n_copies_repeat = how many times to repeat the clicks
    % speaker_out = time signal for clicks 

    n_samps_per_click_period = length(click_period);
    n_samps_speaker_out_tot = n_copies_repeat*n_samps_per_click_period;
    speaker_out = zeros(1,n_samps_speaker_out_tot);

    ind_speaker_out = 0;
    for i = 1:n_copies_repeat
        ind_speaker_out = ind_speaker_out + 1;
        speaker_out(n_samps_per_click_period*(ind_speaker_out-1)+1:n_samps_per_click_period*(ind_speaker_out)) = click_period;            
    end

end