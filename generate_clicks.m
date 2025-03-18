function click_period = generate_clicks(click_duration, inter_click_period, Fs, rampstyle)

    % This function generates the clicks
    % https://iopscience.iop.org/article/10.1088/1741-2560/13/2/026030/meta
    
    % Inputs
    % click_duration = how long clicks are on (usually 50 ms long)
    % inter_click_period = time between clicks on (usually 950 ms)
    % Fs = sampling rate of analog input
    %rampstyle = linear or tukey (describes ramp shape)

    % Output
    % total_click_period = one vector of 1 s of click    


    time_inter_tone = inter_click_period;    % time between tones is 0.8 s
    total_time_per_tonestim = click_duration + time_inter_tone;  % 0.85 s
    
    %%Time specifications:
    dt = 1/Fs;                                  % seconds per sample
    t_click = (0:dt:click_duration-dt)';          % seconds
    t_tot = (0:dt:total_time_per_tonestim-dt)'; 
    n_samps_click = length(t_click);
    ramp_window = zeros(1,length(t_tot));

    if strcmp(rampstyle,'tukey') == true        
        tukey_win = tukeywin(n_samps_click,0.75);          
        ramp_window(1:n_samps_click) = tukey_win;

    elseif strcmp(rampstyle,'linear') == true 
        % Add ramps to on by making a window
        ramp_time = click_duration/10;                       % ramp on/off duration = 2 ms
        ind_ramp_start = 1;
        ind_ramp_end = floor(ramp_time/dt);
        ramp_ind_tot = ind_ramp_end - ind_ramp_start;
        ramp_vec = linspace(0,1,ramp_ind_tot);
        ramp_window(ind_ramp_start:ind_ramp_end-1) = ramp_vec;

        % add ones in ramp window during sine     
        n_samps_sine_ones = n_samps_click - 2*ramp_ind_tot; % n samples full amp outside of ramp
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
    click_period = zeros(1, length(t_tot));

    figure(21)
    click_sig = 2*(rand(1,n_samps_click)-0.5); %(wgn(1,n_samps_click,0)/5);    
    click_period(1,1:length(click_sig)) = click_sig;
    click_period(1,:) = ramp_window.*click_period(1,:);

    subplot(2,1,1)
    plot(t_tot,click_period(1,:),'r')
    xlim([0 1.05*click_duration])
    title('Click Period - zoomed in')
    xlabel('Time (s)')
    ylabel('Voltage (V)')

    subplot(2,1,2)
    plot(t_tot,click_period(1,:),'r')
    title('Click Period - zoomed out')
    xlabel('Time (s)')
    ylabel('Voltage (V)')

end