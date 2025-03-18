function [total_tone_period, out_frequencies] = generate_tones(min_freq, max_freq, n_half_octaves, tone_duration, inter_tone_period, Fs, rampstyle)

    % This function generates the tone frequencies described in
    % https://iopscience.iop.org/article/10.1088/1741-2560/13/2/026030/meta
    
    % Inputs
    % min_freq = lower bound for frequencies generated
    % max_freq = upper bound for frequencies generated
    % n_half_octaves = 
    % 
    % how many steps in frequencies 
    % tone_duration = how long tones are on (usually 50 ms long)
    % inter_tone_period = time between tones on (usually 950 ms)
    % Fs = sampling rate of analog input

    % Output
    % total_tone_period = (M x N) vector where M = number of different
    % tones, and N = total time in tone 


    time_inter_tone = inter_tone_period;    % time between tones is 950 ms
    total_time_per_tonestim = tone_duration + time_inter_tone;  % 1 s
    
    %%Time specifications:
    dt = 1/Fs;                              % seconds per sample
    t_sin = (0:dt:tone_duration-dt)';       % seconds
    t_tot = (0:dt:total_time_per_tonestim-dt)'; 
    n_samps_sine = length(t_sin);
    ramp_window = zeros(1,length(t_tot));

    if strcmp(rampstyle,'tukey') == true        
        tukey_win = tukeywin(n_samps_sine,0.75);          
        ramp_window(1:n_samps_sine) = tukey_win;

    elseif strcmp(rampstyle,'linear') == true 
        % Add ramps to on by making a window
        ramp_time = 2e-3;                       % ramp on/off duration = 2 ms
        
        ind_ramp_start = 1;
        ind_ramp_end = ramp_time/dt;
        ramp_ind_tot = ind_ramp_end - ind_ramp_start;
        ramp_vec = linspace(0,1,ramp_ind_tot);
        ramp_window(ind_ramp_start:ind_ramp_end-1) = ramp_vec;

        % add ones in ramp window during sine     
        n_samps_sine_ones = n_samps_sine - 2*ramp_ind_tot; % n samples full amp outside of ramp
        ones_sine_window = ones(1,n_samps_sine_ones);
        ramp_window(ind_ramp_end:n_samps_sine_ones+ind_ramp_end-1) = ones_sine_window;

        % add off ramp at end of sine
        ind_rampoff_start = n_samps_sine_ones+ind_ramp_end;
        ind_rampoff_end = n_samps_sine_ones+ind_ramp_end + ramp_time/dt;
        ramp_ind_tot = ind_rampoff_end - ind_rampoff_start;
        rampoff_vec = linspace(1,0,ramp_ind_tot);
        ramp_window(ind_rampoff_start:ind_rampoff_end-1) = rampoff_vec;
    end
    
    format short g    
    out_frequencies = zeros(1, n_half_octaves);
    out_frequencies(1,1) = min_freq;
    out_frequencies(1,2) = 1.5*min_freq;
    tone_sines = zeros(n_half_octaves,length(t_sin));
    total_tone_period = zeros(n_half_octaves, length(t_tot));

    figure(21)
    hold on
    
    % Generate single periods for each tone frequency
    for i = 1:n_half_octaves
        if i>2
            if  ~mod(i,2) 
                freq_before = out_frequencies(1,i-2);
                out_frequencies(1,i) = 2*freq_before;
            elseif  mod(i,2) 
                freq_before = out_frequencies(1,i-2);
                out_frequencies(1,i) = 2*freq_before;
            end
        end
    
        tone_sig = sin(2*pi*out_frequencies(1,i)*t_sin);
        tone_sig = tone_sig/2;
        tone_sines(i,:) = tone_sig;
        total_tone_period(i,1:length(tone_sig)) = tone_sig;
        total_tone_period(i,:) = ramp_window.*total_tone_period(i,:);        
    end

    subplot(2,1,1)
    plot(t_tot,total_tone_period(4,:),'r')
    xlim([0 51e-3])
    title('Tone Period - zoomed in')
    xlabel('Time (s)')
    ylabel('Voltage (V)')

    subplot(2,1,2)
    plot(t_tot,total_tone_period(4,:),'r')
    title('Tone Period - zoomed out')
    xlabel('Time (s)')
    ylabel('Voltage (V)')
    
end