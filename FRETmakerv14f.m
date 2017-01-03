function FRETanswer = FRETmakerv14f()
rstr = input('Select action:\n[1]Load new files from symphotime export to ascii .dat files\n[2]Load session from .mat saved file\n[3]Load old format session from .mat file\n[4]Quit Program\n','s');
r = str2double(rstr);
fcon = 0;
switch r % select which file load option
% switch statement for initial loading of data- options are 
% [1] Load new file 
% [2] load a .mat file saved from a previous session, which must have been using the v9 (current version) of the script) 
% [3] load data from a .mat file produced with an older version of the script, this will require the user to then go through each trace and mark regions etc. 
% [4] exit the program, the script is set up to automatically terminate if one of the opotions is not selected
    case 1 % load unprocessed files generated from Symphotime
        [filenames, dtarray, binsize, fcon] = FmakerFileLoader(); % Call function that loads files, outputs filenames, data in the files, as well as binsizes and a count of files generated, if no files entered, returns 0 
        if fcon == 0
            fprintf('ERROR inputing files\nExiting program\n')
            r = 8;
        else % proceed to generate time traces and FRET histograms
            histbinstr = input('Enter desired number of FRET bins, if you want to use the default of 50, hit ENTER without entering anything else\n','s'); % prompt for size of FRET histogram bins
            histbin = str2double(histbinstr);
            if isnan(histbin) % if a number is not entered, bin size defualt set to 50
                histbin = 50;
            end
            intensityminstr = input('Enter desired intensity minnimum, if you want to set each minimum individually, hit ENTER without enterying anything else\n','s'); % prompt for minimum intensity (sum of donor and acceptor) for which a FRET point will be considered for histogramming
            imin = str2double(intensityminstr);
            if isnan(imin) % if a number is not entered, default bin size set to 0, FmakerHistogram function will receive this 0 and interpret it as a desire to select a particular minimum for that time trace
                intensitymin = zeros(1,fcon);
            else % if a number is entered, a row vector of that number is made
                intensitymin = ones(1,fcon)*imin;
            end
            region = cell(fcon); % each cell in region is a matrix of start and end indexes (1st row, 2nd row respectively) of the regions to be histogrammed (note this is the index in the matrix, not the actual time, converting once saves procesing power) the number of columns in each regions cell differes, depending on the number of regions being used
            tracecon = zeros(1,fcon); % a bolean vector identifying which files the user wants to skip (correponding element set to 0) and which to use (element set to 1) in the summed histogram, it also indicates which files will be saved into the results file
            FRETmat = zeros(histbin,(fcon + 2)); % this floating point matrix stores the time-adjusted histograms of all traces in succesive columns, the first and last rows are not from individual time traces, rather the first row corresponds to the FRET efficency, and the last is the summed histogram of all individual file histograms
            FREThist =  zeros(histbin,fcon); % stores raw histogram results, not adjusted for bin size
            belowmin = zeros(1,fcon); % stores number of data points below minimum intensity in each file that are within the histogrammed region
            zerocount = zeros(1,fcon); % number of points within the histogrammed reginon that have no photons for each file
            FRETmat(:,1) = ((1/histbin):(1/histbin):1)'; % initialize first column of FRETmat which stores the label for each FRET bin
            ttl = input('Enter title for this calculation\n','s');
            sumfig = figure('Visible','off');
            fig = figure('Visible','off');
            for fl = 1:size(dtarray,1) % for loop sequentially plots all each file, using FmakerTimeTraceGenerator and FmakerHistogram functions, which prompt for ranges and if no minimum count already set, a minimum intensity to consider a data point for histogramming
                fprintf('File identifier: [%d] ',fl) % print which file identifier will be used later when manipulating the data
                [region{fl}, tracecon(fl)]= FmakerTimeTraceGenerator(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl}); % calling FmakerTimeTraceGenerator generates plots and asks for regions to be histograms, it returns to the scipt a regions matrix which contains the intexes for begin and end points in each row for each region
                if tracecon(fl) % if user did not skip file, execute the histogram making function
                    [FREThist(:,fl), intensitymin(fl), belowmin(fl), zerocount(fl)] = FmakerHistogram(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl},region{fl},histbin,intensitymin(fl)); % this function take data, region from time trace, histogram bin size and intensity minimum to generate histogram plot of the given file
                    FRETmat(:,(fl+1)) = FREThist(:,fl)*binsize(fl); % scales the results of FmakerHistogram and saves to FRETmat
                    FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % fill total histogram from histograms of each file
                    figure(sumfig)
                    bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                    xlabel('FRET efficeincy')
                    ylabel('Dwell time (s)')
                    title(ttl)
                    ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                    axis(ax)
                    set(sumfig,'Visible','on')
                    dummy = input('Press any key to continue\n','s'); % arrest program processing until user hits enter, allows viewing of Histogram
                end
            end
            % identify that all traces have been assigned and move on
            fprintf('Finihsed assigning regions to traces\n')
            r = 0;
        end
    case 2 % option for viewing/modifying saved results file that was generated with a script v9 or later
        flname = input('Enter name of file (include .mat extention)\n','s'); % prompt to enter file name    load(flname)
        load(flname)
        % following lines are used to assign variables from saved file into
        % program variables
        filenames = flarray;
        clear('flarray')
        dtarray = dataarray;
        clear('dataaray')
        region = htmregion;
        clear('htmregion');
        FRETmat = FREThst;
        clear('FREThst')
        ttl = ttle;
        clear('ttle')
        intensitymin = intensmin;
        clear('intensmin')
        % following lines initialize variable needed in the script but do
        % not require saving, as they are either constant for all saved
        % files or can be derived from information within the save file
        fcon = size(dtarray,1); % fcon is output of FmakerFileLoader, identifying the number of files loaded, but as FmakerFileSave trims all files excluded from histogramming, fcon is simply the size of the dtaray cell array
        belowmin = zeros(1,fcon);
        zerocount = zeros(1,fcon);
        tracecon = ones(1,fcon); % since all files saved are ones used, it can be assume tracecon, which tells which file to histogram is all true
        FREThist = zeros(size(FRETmat,1),fcon);
        histbin = size(FREThist,1); % histbin indicates number of bins FRET data is histogramed into, since this is just the number of rows in the FRETmat matrix, it is not saved, but rather assigned in this line
        binsize = zeros(fcon,1);
        for tbin = 1:fcon % for loop to identify bin size of each file, and store in binsize variable
            binsize(tbin) = dtarray{tbin}(1,2) - dtarray{tbin}(1,1);
        end
        for fl = 1:fcon
            for rl = 1:size(region{fl},2)
                belowmin(fl) = sum(dtarray{fl}(4,region{fl}(1,rl):region{fl}(2,rl)) <= intensitymin(fl));
                zerocount(fl) = sum(dtarray{fl}(4,region{fl}(1,rl):region{fl}(2,rl)) <= intensitymin(fl));
            end
        end
        % this prints the summed FRET histogram generated from the last session
        sumfig = figure('Visible','off');
        bar(FRETmat(:,1),FRETmat(:,fcon+2))
        ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
        axis(ax)
        title(ttl)
        xlabel('FRET efficency')
        ylabel('Dwell time (s)')
        sumfig.Visible = 'on';
        fig = figure('Visible','off');
    case 3 % option for loading file made using older FRETmaker version
        % this is for loading a saved session from a previous version,
        % since previous versions did not save the regions used in
        % histogramming, it will print the old histogram, but prompts the
        % user to identify all regions of all traces afterwards, and before
        % proceeding on the data manipulation and viewing stages
        flname = input('Enter name of file (inlcude .mat extension)\n','s'); % prompts for name of file, must inlcude .mat in the filename entered
        load(flname) % load filename
        % the following section assigns saved variables to script variables
        % and then clears the loaded variables
        filenames = filearray;
        clear('filearray');
        dtarray = dtray;
        clear('dtray')
        % this section initializes what necessary script variables can be
        % initialized from the data provided in the saved file
        fcon = size(dtarray,1); % fcon counts number of traces, identified from size of dtarray cell array
        histbin = size(FRETmat,1); % histbin stores the histogram binning identified by # of columns of FRETmat variable
        % this section prints the histogram developed from the previous
        % section
        ttl = input('Enter title for this calculation\n','s'); % prompt for title, since title is also not saved in older versions
        sumfig = figure('Visible','off');
        bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
        title(ttl)
        xlabel('FRET efficency')
        ylabel('Dwell time (s)')
        ax = [0 1 0 max(FRETmat(:,(fcon + 2)))];
        axis(ax)
        sumfig.Visible = 'on';
        binsize = zeros(fcon,1);
        for tbin = 1:fcon % for loop to identify bin size of each file, and store in binsize variable
            binsize(tbin) = dtarray{tbin}(1,2) - dtarray{tbin}(1,1);
        end
        % this section makes figures of all traces so user can enter
        % regions for histogramming, this is necessary since the regions
        % used in the loaded session were not saved, and thus must be
        % reentered (will cause some uncertainty, as new regions may be
        % different from previous ones)
        % first some variables must be initialized
        region = cell(fcon);
        tracecon = zeros(1,fcon);
        FRETmat = zeros(histbin,(fcon + 1));
        FREThist =  zeros(histbin,fcon);
        belowmin = zeros(1,fcon);
        zerocount = zeros(1,fcon);
        FRETmat(:,1) = ((1/histbin):(1/histbin):1)';
        intensityminstr = input('Enter desired intensity minnimum, if you want to set each minimum individually, hit ENTER without enterying anything else\n','s'); % prompt for intensity minumum to be used on all files
        imin = str2double(intensityminstr);
        if isnan(imin) % assignment of 0 if user does not enter a number
            intensitymin = zeros(1,fcon);
        else % generate intensitymin row vector of all the entered intensity min
            intensitymin = ones(1,fcon)*imin;
        end
        % begin generating time trace figures
        fig = figure('Visible','off');
        for fl = 1:size(dtarray,1) % for loop cycles through all loaded traces
            [region{fl}, tracecon(fl)]= FmakerTimeTraceGenerator(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl}); % FmakerTimeTraceGenerator takes data from dtarray, plots and promts for regions, which it returns in a matrix, function also can be used to indicate the trace should be excluded, where instead of inputing the regions the user types 's'
            if tracecon(fl)
                [FREThist(:,fl), intensitymin(fl), belowmin(fl), zerocount(fl)] = FmakerHistogram(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl},region{fl},histbin,intensitymin(fl)); % FRETmakerHistogram takes data and regions from FmakerTimeTraceGenerator and plots the histogram, and outputs histogramed data
                FRETmat(:,(fl+1)) = FREThist(:,fl)*binsize(fl); % weights the histogram data by time (binsize) and stores in FRETmat 
                dummy = input('Press any key to continue\n','s'); % used to stop program from continuing so that user can view resultant histogram
            end
        end
        % plot newly generated histogram
        FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % generate the information for the final histogram, summing time weighted data for each trace
        figure(sumfig)
        sumfig.Visible = 'off';
        bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
        xlabel('FRET efficeincy')
        ylabel('Dwell time (s)')
        title(ttl)
        ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
        axis(ax)
        sumfig.Visible = 'on';
    case 4 % exit commmand
        r = 5;
    otherwise % in case the user didn't enter one of the correct options
        fprintf('Incomprehensible input\nExitting Program\n')
        r = 5;
end
% Data loading is finished, now script deals with data manipulations
if ~isnan(str2double(rstr)) && fcon > 0  % if statement used because if the user did not enter valid data, the following operation will generate an error message
    trcon = tracecon; % since the user may want to exclude more traces, the current set of exclusions is given to a new variable, that will not be changed in the rest of the script, trcon, while in the rest of the script tracecon will store the current set of exclusions
    mod = boolean(1);
end
statfig = figure('Visible','off');
while r ~= 9 % while loop repeats choices so user can do many maniputlations, and only when he gives the stop signal will the script be terminated
    FmakerUnistats(statfig,region,binsize,tracecon)
    fprintf('Select which action you want to take:\n[1] View Traces (with option of excluding from Histogramming)\n[2] View/modify regions and minimums\n[3] Change FRET bin size\n[4] Change Time Bin size \n[5] Add traces from Symphotime export to ascii .dat files\n[6] Add traces from .mat saved file\n[7] Change title\n[8] Save results\n[9]Exit program\n') % prompt gives user options for data manipulation and saving
    rstr = input('','s'); % user input
    r = str2double(rstr);
    switch r % select with data manipulation/save you want to perform
        % [1] View individual traces
        % [2] Modify regions and minimums of individual traces
        % [3] Change FRET bin size
        % [4] Change time bin size
        % [5] Add traces from symphotime .dat saves
        % [6] Add traces from saved .mat file
        % [7] Change title
        % [8] Save
        % [9] Exit
        case 1 % view individual trace, also allows user to exclude from histogram
            sel = 1;
            while ~isnan(sel) && sel <= fcon && sel >= 1 && (rem(sel,1) == 0) % while loop continues until user does not enter a number
                % this section prints the list of files currently
                % loaded and then displays whichever trace is selected
                % in a NEW figure. If the user does not enter a number,
                % the program will automatically return to the root
                % data modification menu it then prompts the user if he
                % would like to exclude it from the trace, typing 'Y'
                % will exclude the trace from the summed histogram, 'N'
                % will include the trace, and any other response will
                % leave the status if the trace unchanged, ie if it was
                % excluded before, it will continue to be excluded,
                % and if it was included before, it will continue to be
                % included
                % this first part prints the file selction options
                fprintf('Files:\n')
                for fcnt = 1:fcon % for loop loops to print all file names
                    if trcon(fcnt)
                        fprintf('[%d]',fcnt)
                        if ~tracecon(fcnt)
                            fprintf('<EXCLUDED>')
                        end
                        fprintf(' %s %s\n', filenames{fcnt,1},filenames{fcnt,2})
                    end
                end
                fprintf('Select which files you want to view/modify, or hit ENTER without making a selection to exit view/modify mode\n') % prompt to select which trace to view
                selstr = input('','s');
                sel = str2double(selstr);
                if ~isnan(sel) && sel <= fcon && (rem(sel,1) == 0) % if statment determines if file is printed or program returns to data modification menu
                    % this is executed if the user entered a valid
                    % number for a time trace
                    % displays histogram of the selected time trace
                    fig = figure('Visible','off');
                    [FREThist(:,sel), intensitymin(sel), belowmin(sel), zerocount(sel)] = FmakerHistogram(fig,{filenames{sel,1}, filenames{sel,2}},dtarray{sel},region{sel},histbin,intensitymin(sel)); % FRETmakerHistogram is loaded with all previous data, as regions and minimums and histogram bin size are all the same, this will only display the end result, not change anything
                    exclustr = input('Do you want to exclude this trace?(Y/N)\n','s'); % prompt asking if the user wants to exclude the currently displayed time trace
                    if strcmpi(exclustr,'y')
                        % executes if the user wants to exclude the
                        % trace from the histogram
                        tracecon(sel) = 0;
                        FREThist(:,sel) = zeros(histbin,1);
                        FRETmat(:,(sel+1)) = zeros(histbin,1);
                    elseif strcmpi(exclustr,'n')
                        % executes if the user wants to incldue the
                        % trace in the histogram
                        tracecon(sel) = 1;
                        FRETmat(:,(sel+1)) = FREThist(:,sel)*binsize(sel);
                        % no final else statement, as if the user does
                        % not enter 'Y' or 'N' the assumption is that
                        % he doesn't want any changes to be made to the
                        % histogram
                    end
                    % This part prints the new summed histogram
                    set(sumfig,'Visible','off')
                    figure(sumfig)
                    FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % update the summed (final) column of the FRETmat matrix
                    bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                    ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                    axis(ax)
                    title(ttl);
                    xlabel('FRET efficency')
                    ylabel('Dwell time (s)')
                    set(sumfig,'Visible','on')
                end
            end
        case 2
            % this is executed if the user wants to adjust the regions
            % histogrammed and give the option of also adjusting
            % minimums
            sel = 1;
            modstr = input('Do you want to modify minimums?(Y/N)\n','s'); % one time question, allows user to choose to modify intensity minimums or keep them as they were or be allowed to change them
            if strcmpi(modstr,'y') % if statement sets mod variable to true if the user entered 'Y' to wanting to change minimums (string stored in modstr in line above) or to false if the user entered anything else
                mod = 1;
            else
                mod = 0;
            end
            % while loop cycles until user does not enter a valid
            % number for a time trace, it first generates FRET time
            % traces asking for the user to enter in new regions, then
            % plots the histogram, if the user said they wanted to
            % modify the minimums, it then
            while ~isnan(sel) && sel <= fcon && sel >= 1 && (rem(sel,1) == 0) % while loop continues until user enters something that is either not a number or a number not corresponding to one of the files
                % this section of the while loop is dedicated to
                % printing out the files available for viewing
                fprintf('Files:\n')
                for fcnt = 1:fcon % for loop prints each file succesively
                    if trcon(fcnt)
                        fprintf('[%d]',fcnt) % prints handle the user should use to specify this file in selecting which file to view
                        if ~tracecon(fcnt) % is statement used to print <EXCLUDED> when the file has been excluded from the current histogram
                            fprintf('<EXCLUDED>')
                        end
                        fprintf(' %s %s\n', filenames{fcnt,1},filenames{fcnt,2}) % prints file names
                    end
                end
                if mod
                    fprintf('You will be asked to modify intensity minimums\n')
                else
                    fprintf('You will not be asked to modify intensity minimums\n')
                end
                fprintf('Select which files you want to view/modify/exclude, or hit ENTER without making a selection to exit view/modify mode\n')
                selstr = input('','s'); % input for selecting file to view, any input not corresponding to a possible file will cause
                sel = str2double(selstr);
                % this section is used for generating the figures so
                % user can enter new regions and minimums
                if ~isnan(sel) && sel <= fcon && (rem(sel,1) == 0) % if statement prevents anything from being executed if the user entered anything not corresponding to a trace not available for modification
                    fig = figure('Visible','off');
                    fprintf('Previous regions were: ') % printing out old regions so user can keep them if he does not wish to change them
                    for recnt = 1:size(region{sel},2) % for loop loops through all regions used
                        fprintf('%g %g', binsize(sel)*double((region{sel}(1,recnt) - 1)), binsize(sel)*double((region{sel}(2,recnt) - 1))) % prints each succesive region in trace
                    end
                    fprintf('\n')
                    [region{sel}, tracecon(sel)]= FmakerTimeTraceGenerator(fig,{filenames{sel,1}, filenames{sel,2}},dtarray{sel}); % function generates time trace and prompts for new regions
                    if tracecon(sel) % if statement only executes if the user entered a valid region, does not execute if user indicated he wants to exclude the trace from histogramming
                        fprintf('Current Intensity Minimum: %d\n', intensitymin(sel))
                        if mod % if statement will set the appropriate element of intensitymin to 0 so that FmakerHistogram will prompt user for a new minimum
                            intensitymin(sel) = 0; % set appropriate element of intensitymin to 0
                        end
                        [FREThist(:,sel), intensitymin(sel), belowmin(sel), zerocount(sel)] = FmakerHistogram(fig,{filenames{sel,1}, filenames{sel,2}},dtarray{sel},region{sel},histbin,intensitymin(sel));
                        exclustr = input('Do you want to exclude this trace?(Y/N)\n','s'); % input giving user a second chance to exclude the trace for the histogram
                        if strcmpi(exclustr,'y') % set the appropriate variable for exclusion
                            tracecon(sel) = 0; % set boolean tracecon to 0 so program know to keep it excluded in the future
                            FREThist(:,sel) = zeros(histbin,1); % set column of FREThist to 0 so will not contribute to histogram sum
                            FRETmat(:,(sel+1)) = zeros(histbin,1); % again set FRETmat column to 0 so will not contribute to histogram sum
                        elseif strcmpi(exclustr,'n') % executed if user indicated he wants to include trace in histogramming
                            tracecon(sel) = 1;
                            FRETmat(:,(sel+1)) = FREThist(:,sel)*binsize(sel);
                        elseif tracecon(sel) % executes if the user did not enter 'y' or 'n' so program checks previous status of the inclusion of this trace, and updates FRETmat if trace included
                            FRETmat(:,(sel+1)) = FREThist(:,sel)*binsize(sel);
                        elseif ~tracecon(sel) % executes if the user did not entery 'y' or 'n' and trace was excluded, the appropriate column FRETmat and FREThist variables are set to 0 so they do not contribute to the sum
                            FREThist(:,sel) = zeros(histbin,1); % set column of FREThist to 0 so will not contribute to histogram sum
                            FRETmat(:,(sel+1)) = zeros(histbin,1); % again set FRETmat column to 0 so will not contribute to histogram sum
                        end
                    end
                end
                % now that new regions and minimums have been set, the
                % script generates the new summed histogram
                set(sumfig,'Visible','off')
                figure(sumfig)
                FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2);
                bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                axis(ax)
                title(ttl);
                xlabel('FRET efficency')
                ylabel('Dwell time (s)')
                set(sumfig,'Visible','on')
            end
        case 3 % for setting new histogram bin size
            % this case first prompts user for new histogram bin size
            % and then loops through each trace executing the
            % FmakerHistogram fucntion with the new bin size so
            % that each histogram is updated
            % the first part of this scipt prompts for new bin size
            histbinstr = input('Enter new FRET bin size\n','s'); % prompt and input for new histogram bin size
            histbinr = str2double(histbinstr); % temporary storage of new histbin size, if statement checks if it is valid, and only then sets the master histbin variable
            % this section resets all histogram related varaible to new
            % values
            if ~isnan(histbinr) && rem(histbinr,1) == 0 % if statement check if input is valid, if it is not, the user returned to data manipulation menu
                histbin = histbinr; % set mast histbin variable to new histbin size
                FREThist = zeros(histbin,fcon); % set FREThist variable for new histogram size
                FRETmat = zeros(histbin,(fcon + 2)); % set FRETmat variable for new histogram size
                FRETmat(:,1) = ((1/histbin):(1/histbin):1)'; % intitialize the FRET efficency column of the FRETmat variable
                fig = figure('Visible','off');
                % this section updates histogram values
                for n = 1:fcon % loops through all traces, setting new histogram size
                    if tracecon(n) % only execute if trace included in histogram
                        [FREThist(:,n), intensitymin(n), belowmin(n), zerocount(n)] = FmakerHistogram(fig,{filenames{n,1}, filenames{n,2}},dtarray{n},region{n},histbin,intensitymin(n)); % call FmakerHistogram to update histograms
                        FRETmat(:,(n+1)) = FREThist(:,n)*binsize(n); % update FRETmat variable
                    end
                end
                % this section generates figure for new histogram size
                FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % update FRETmat final column
                figure(sumfig)
                set(sumfig,'Visible','off')
                bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                axis(ax)
                title(ttl)
                xlabel('FRET efficency')
                ylabel('Dwell time (s)')
                set(sumfig,'Visible','on')
            end
        case 4 % case for adjusting bin size
            % this option allows the user to set a new bin size, the
            % resizeing is limited to multiple of the bin size of each
            % trace, there are 2 options, universally setting the bin
            % size, or setting new bins sizes for individual traces,
            % for the former, either entering the new bin size
            % directly, or typing 'G' will start this process, typing I
            % will allow the user to individually adjust the bin size
            % of each trace
            fprintf('WARNING: Rebinning cannot be undone!\n[G]lobally modify binsize or\n[I]ndividually modify bin size?\n')
            newbinstr = input('','s');
            newbin = str2double(newbinstr);
            if ~isnan(newbin)
                bsizechk = rem(newbin,binsize);
                if sum(bsizechk) == 0
                    intensitymin = newbin*(intensitymin./binsize);
                    fig = figure('Visible','off');
                    for n = 1:fcon
                        if trcon(n)
                            [dstor, c] = FmakerReBin(dtarray{n},newbin);
                            if c
                                dtarray{n} = dstor;
                                region{n}(1,:) = ceil(double(region{n}(1,:))*(binsize(n)/newbin));
                                region{n}(2,:) = floor(double(region{n}(2,:))*(binsize(n)/newbin));
                                binsize(n) = newbin;
                                [FREThist(:,n), intensitymin(n), belowmin(n), zerocount(n)] = FmakerHistogram(fig,{filenames{n,1}, filenames{n,2}},dtarray{n},region{n},histbin,intensitymin(n)); % call FmakerHistogram to update histograms
                                FRETmat(:,(n+1)) = FREThist(:,n)*binsize(n); % update FRETmat variable
                            end
                        end
                    end
                    FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % update FRETmat final column
                    figure(sumfig)
                    set(sumfig,'Visible','off')
                    bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                    ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                    axis(ax)
                    title(ttl)
                    xlabel('FRET efficency')
                    ylabel('Dwell time (s)')
                    set(sumfig,'Visible','on')
                else
                    fprintf('One or more of your files cannot be re-binned to this value, please make a new selection\n')
                end
            elseif strcmpi(newbinstr,'g')
                while isnan(newbin)
                    newbinstr = input('Input new bin size: press [s] to leave bin adjustment\n','s');
                    newbin = str2double(newbinstr);
                    if ~isnan(newbin)
                        bsizechk = rem(newbin,binsize);
                        if sum(bsizechk) == 0
                            intensitymin = newbin*(intensitymin./binsize);
                            fig = figure('Visible','off');
                            for n = 1:fcon
                                if trcon(n)
                                    [dstor, c] = FmakerReBin(dtarray{n},newbin);
                                    if c
                                        dtarray{n} = dstor;
                                        region{n}(1,:) = ceil(double(region{n}(1,:))*(binsize(n)/newbin));
                                        region{n}(2,:) = floor(double(region{n}(2,:))*(binsize(n)/newbin));
                                        binsize(n) = newbin;
                                        [FREThist(:,n), intensitymin(n), belowmin(n), zerocount(n)] = FmakerHistogram(fig,{filenames{n,1}, filenames{n,2}},dtarray{n},region{n},histbin,intensitymin(n)); % call FmakerHistogram to update histograms
                                        FRETmat(:,(n+1)) = FREThist(:,n)*binsize(n); % update FRETmat variable
                                    end
                                end
                            end
                            FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % update FRETmat final column
                            figure(sumfig)
                            set(sumfig,'Visible','off')
                            bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                            ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                            axis(ax)
                            title(ttl)
                            xlabel('FRET efficency')
                            ylabel('Dwell time (s)')
                            set(sumfig,'Visible','on')
                        elseif strcmpi(newbinstr,'s')
                            newbin = 1;
                        else
                            fprintf('One or more of you files cannot be rebinned to this value, please make a new selection\n')
                            newbin = NaN;
                        end
                    else
                        fprintf('You did not enter a number, please make a new selection\n')
                    end
                end
            elseif strcmpi(newbinstr,'i')
                selt = 1;
                while ~isnan(selt) && selt <= fcon && selt >= 1 && rem(selt,1) == 0
                    fprintf('Files:\n')
                    for fcnt = 1:fcon % for loop prints each file succesively
                        if trcon(fcnt)
                            fprintf('[%d]',fcnt) % prints handle the user should use to specify this file in selecting which file to view
                            if ~tracecon(fcnt) % is statement used to print <EXCLUDED> when the file has been excluded from the current histogram
                                fprintf('<EXCLUDED>')
                            end
                            fprintf(' %s %s\n', filenames{fcnt,1},filenames{fcnt,2}) % prints file names
                        end
                    end
                    seltstr = input('Select file to change its bin size:\n','s');
                    selt = str2double(seltstr);
                    if ~isnan(selt) && selt >= 0 && selt <= fcon && rem(selt,1) == 0
                        fprintf('Current binsize %f\nEnter a muliple of this bin size for file %s',binsize(selt),filenames{selt,1})
                        newbinstr = input('','s');
                        newbin = str2double(newbinstr);
                        if ~isnan(newbin)
                            if rem(newbin,binsize(selt)) == 0
                                intensitymin(selt) = newbin*intensitymin(selt)*binsize(selt);
                                [dstor, c] = FmakerReBin(dtarray{selt},newbin);
                                if c
                                    dtarray{selt} = dstor;
                                    region{selt}(:,1) = ceil(double(region{selt}(:,1))*binsize(selt)/newbin);
                                    region{selt}(:,2) = floor(double(region{selt}(:,2))*binsize(selt)/newbin);
                                    binsize(selt) = newbin;
                                    [FREThist(:,selt), intensitymin(selt), belowmin(selt), zerocount(selt)] = FmakerHistogram(fig,{filenames{selt,1}, filenames{selt,2}},dtarray{selt},region{selt},histbin,intensitymin(selt)); % call FmakerHistogram to update histograms
                                    FRETmat(:,(selt+1)) = FREThist(:,selt)*binsize(selt); % update FRETmat variable
                                end
                                FRETmat(:,(fcon+2)) = sum(FRETmat(:,2:(fcon + 1)),2); % update FRETmat final column
                                figure(sumfig)
                                set(sumfig,'Visible','off')
                                bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                                ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                                axis(ax)
                                title(ttl)
                                xlabel('FRET efficency')
                                ylabel('Dwell time (s)')
                                set(sumfig,'Visible','on')
                            else
                                fprintf('You did not enter a multiple of the previous bin size, returning to file selection for bin size adjustment\n')
                            end
                        else
                            fprintf('You did not enter a number, returning to file selection for bin size adjustment\n')
                        end
                    end
                end
            end
        case 5 % this case is used to add new traces to the current session
            [filenames1, dtarray1, binsize1, fcon1] = FmakerFileLoader();
            if fcon1 == 0;
                fprintf('ERROR INPUTTING FILES: no traces added')
            else
                % update various storage varaibles with new data
                fcon = fcon1 + fcon;
                filenames = [filenames; filenames1];
                clear('filenames1')
                dtarray = [dtarray; dtarray1];
                clear('dtarray1')
                binsize = [binsize; binsize1];
                clear('binsize1')
                region = [region; cell(fcon1,1)];
                FRETmat = [FRETmat, zeros(histbin, fcon1)];
                FRETmat(:, fcon + 2) = FRETmat(:, fcon - fcon1 + 2);
                FRETmat(:, fcon - fcon1 + 2) = zeros(histbin,1);
                FREThist = [FREThist, zeros(histbin, fcon1)];
                tracecon = [tracecon, zeros(1, fcon1)];
                belowmin = [belowmin, zeros(1, fcon1)];
                zerocount = [zerocount, zeros(1, fcon1)];
                % prompt for intensity mininum set point, if the user
                % enters a non-number input, program automatically
                % assigns the mode of the previous
                intensitymin1str = input('Set intensity minimum for new traces\nIf you want to use previous intenity minimum, hit enter, if you want to set them individually, type 0\n','s');
                intensitymin1 = str2double(intensitymin1str);
                if isnan(intensitymin1)
                    intensitymin1 = mode(intensitymin);
                    intenmin1 = ones(fcon1,1)*intensitymin1;
                else
                    intenmin1 = ones(fcon1,1)*intensitymin1;
                end
                intensitymin = [intensitymin; intenmin1];
                % loop through all the new files asking user to input
                % regions to histogram and generate individual
                % histograms
                for fl = (fcon - fcon1 + 1):fcon
                    fprintf('File identifier: [%d] ',fl) % print which file identifier will be used later when manipulating the data
                    [region{fl}, tracecon(fl)]= FmakerTimeTraceGenerator(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl}); % calling FmakerTimeTraceGenerator generates plots and asks for regions to be histograms, it returns to the scipt a regions matrix which contains the intexes for begin and end points in each row for each region
                    if tracecon(fl) % if user did not skip file, execute the histogram making function
                        [FREThist(:,fl), intensitymin(fl), belowmin(fl), zerocount(fl)] = FmakerHistogram(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl},region{fl},histbin,intensitymin(fl)); % this function take data, region from time trace, histogram bin size and intensity minimum to generate histogram plot of the given file
                        FRETmat(:,(fl+1)) = FREThist(:,fl)*binsize(fl); % scales the results of FmakerHistogram and saves to FRETmat
                        FRETmat(:,(fcon + 2)) = sum(FRETmat(:,2:(fcon + 1)),2); % fill total histogram from histograms of each file
                        figure(sumfig)
                        set(sumfig,'Visible','off')
                        bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
                        xlabel('FRET efficeincy')
                        ylabel('Dwell time (s)')
                        title(ttl)
                        ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
                        axis(ax)
                        set(sumfig,'Visible','on')
                        dummy = input('Press any key to continue\n','s'); % arrest program processing until user hits enter, allows viewing of Histogram
                    end
                end
                fprintf('Finished assigning regions to all new traces\n')
                trcon = [trcon, tracecon((fcon - fcon1 + 1):fcon)];
            end
        case 6 % this case is used for combining sessions, adding files from a previously saved session
            flname = input('Enter filename:\n','s');
            load(flname)
            fcon1 = size(dataarray,1);
            filenames = [filenames; flarray];
            clear('flarray')
            dtarray = [dtarray; dataarray];
            clear('dataaray')
            region = [region; htmregion];
            clear('htmregion');
            clear('FREThst')
            intensitymin = [intensitymin; intensmin];
            clear('intensmin')
            fcon = fcon + fcon1;
            tracecon = [tracecon, ones(1,fcon1)];
            binsize = [binsize; zeros(fcon1, 1)];
            zerocount = [zerocount, zeros(1, fcon1)];
            belowmin = [belowmin, zeros(1, fcon1)];
            selstr = input('Which title to you want to use?\n[1] Current chart title\n[2] Chart title from file\n[3] Enter new chart title\n','s');
            sel = str2double(selstr);
            if isnan(sel)
                ttl = selstr;
            elseif sel == 2
                ttl = ttle;
            elseif sel == 3
                ttl = input('Enter new chart title:\n','s');
            elseif sel ~= 1
                fprintf('You entered an incomprehensible input, using old title\n')
            end
            clear('ttle')
            for fl = (fcon - fcon1 +1):fcon
                binsize(fl) = dtarray{fl}(1,2) - dtarray{fl}(1,1);
                [FREThist(:,fl), intensitymin(fl), belowmin(fl), zerocount(fl)] = FmakerHistogram(fig,{filenames{fl,1}, filenames{fl,2}},dtarray{fl},region{fl},histbin,intensitymin(fl));
                FRETmat(:, (fl + 1)) = FREThist(:,fl)*binsize(fl);
            end
            FRETmat(:,(fcon+2)) = sum(FRETmat(:,2:(fcon + 1)),2);
            figure(sumfig)
            set(sumfig,'Visible','off')
            bar(FRETmat(:,1),FRETmat(:,(fcon + 2)))
            xlabel('FRET efficeincy')
            ylabel('Dwell time (s)')
            title(ttl)
            ax = [0, 1, 0, max(FRETmat(:,(fcon + 2)))];
            axis(ax)
            set(sumfig,'Visible','on')
            trcon = [trcon, tracecon((fcon - fcon1 + 1):fcon)];
        case 7 % changes the title of the summed histogram
            ttl = input('Enter new title:\n','s');
            figure(sumfig)
            title(ttl)
        case 8 % saves data as currently processed in program
            % since this is simple execution of the FmakerFileSave
            % function, most of the details shoudl be refered to from
            % said function. Basically, it takes the important data,
            % and trims out all excluded traces, and then saves in
            % several ways (user is promted each time) the first is to
            % an ascii .dat file, usefull for sharing data in human
            % readable way, then it offers to save the traces as HAMMY
            % traces, which it trims to only include the regions the
            % user selected, generating as many files as traces used,
            % and finally it asks to save a .mat file, which is what
            % this program can accept
            % future versions may add in the file loading menu a way to
            % load files from the .dat format, but that may be a long
            % way out, as parsing such a long file may be difficult
            FmakerFileSave(filenames,dtarray,FRETmat,region,intensitymin, tracecon,fcon,ttl)
        case 9 % since while loop exits when r = f the purpose of this case is  simply to print the exit line then while loop and whole script terminates
            fprintf('Exiting program\n')
        otherwise % this recognizes all other inputs, and acts just like the previouse case, except it also notes the incorrect input, and then sets r = 5 so that the script terminates
            fprintf('Incomprehensible input\nExiting program\n')
            r = 9;
    end
end
FRETanswer.filenames = filenames;
FRETanswer.dtarray = dtarray;
FRETanswer.FRETmat = FRETmat;
FRETanswer.region = region;
FRETanswer.intensitymin = intensitymin;
FRETanswer.tracecon = tracecon;
FRETanswer.fcon = fcon;
FRETanswer.ttl = ttl;
end

function [farray, datarray, bins, cont] = FmakerFileLoader()
filearray = {}; % initialize an empty array for containing all the file names
filefin = 0; % initialize variable for a while loop which repeatedly prompts user for more filenames
proceed = 1; % error check, if user indicates
files = 'dummy';
fileload = 0; % initialize variable for inner while loop which asks for files to be entered and terminates on user indicating no more files are to be entered
filecount = 0; % universal variable identifying the total number of fret timetraces untilized. this is actually 1/2 the total number of files loaded
while filefin == 0 % While loop for entering filenames this is the outer loop and also contains if statements for confirming correct file entry
    while fileload == 0  % inner while loop repeatedly asking for more files to be entered
        files = input('Input Donor time trace then Acceptor time trace file names separated by a space. When you are finished type Y\n' , 's'); % prompt asking for more files
        if ~strcmpi(files, 'y') % user has not entered 'Y' or 'y' so program assumes enteries are filenames in the format of donortrace.dat acceptortrace.dat
            [donorfile, acceptorfile] = strtok(files); % separates string of donor file from acceptor file
            acceptorfile = strtrim(acceptorfile); % strtok leaves the whitespace character on the front of the second string, this function removes that whitespace character
            if filecount == 0 % this is required so that filearray can be initialized
                filearray = {donorfile, acceptorfile}; % file array intitialized, column 1 is donor file, column 2 is accpetor file
            else % for all but first entry of files, this is used, extending the size of filearray
                filearray = [filearray; {donorfile, acceptorfile}]; % extending file array one row at a time
            end
            filecount = filecount + 1; % as long as the user did not enter 'Y' or 'y' the total nubmer of timetraces increases by one, thus this variable should increase by one
        else % else lower(files) == 'y' therefore the user has indicated they are finished entering files, fileload variable set to true so inner while loop is terminated
            fileload = 1;
        end
    end
    for filenum = 1:filecount % for loop prints all files entered
        fprintf('Donor timetrace %d is %s and acceptor timetrace %d is %s\n' , filenum, filearray{filenum, 1}, filenum, filearray{filenum, 2})
    end
    filedec = input('Are these files correct?(Y/N)\n', 's'); % prompt asking if files entered are correct
    if strcmpi(filedec,'n') % user indicates that the files are incorrectly entered
        filefin = 1; % user has entered incorrect files, so outer while loop terminated
        proceed = 0; % user has entered incorrect files so proceed set to 0 indicating script should be terminated
    elseif strcmpi(filedec, 'y') % user indicates files correclty entered
        filedec = input('Do you want to add more files?(Y/N)\n' , 's'); % prompt asking if the user wants to add more files, i.e. some files have been forgotten
        if strcmpi(filedec, 'y') % user indicates wanting to add more files
            filefin = 0; % stay in outer while loop
        elseif strcmpi(filedec, 'n') % user indicates they do not want to add more files
            filefin = 1; % terminates for loop
            proceed = 1; % allows next step to proceed
        else % user did not enter Y or N to the prompt "Do you want to add more files?" since the user indicated that the files entered were correct, we assume completion of file entry anyway and that all files are entered and the script shoudl proceed to calculating FRET
            fprintf('We will assume you do not want to add any more files\nNext time please enter Y or N, please do not enter some bogus string\n')
            filefin = 1; % terminates outer while loop
            proceed = 1; % allows next step to proceed
        end
    else % user did not enter an upper or lower case Y or N for the original prompt of "Are these files correct?" and thus we assume that the file are incorrect
        fprintf('We will assume you entered you files incorrectly\nNext time please indicated Y or N, please do not enter some bogus string\n')
        filefin = 1; % terminates outer while loop
        proceed = 0; % prevents script from proceeding
    end
end
if proceed == 1
    % initialize some variables
    readerror = int8(ones(filecount, 1));
    dataarray = cell(filecount, 2); % array will be used to store raw data from files
    linecount = zeros(filecount, 1); % array used primarily as a consistency check, will be used to store the total number of time points for each trace pair 
    for fcount = 1:filecount % for loop iterates through files and loads them into dataarray
        fid = fopen(filearray{fcount, 1}, 'r'); % open donor file
        if fid ~= -1
            filestor = fgetl(fid);
            filestor = strtrim(filestor);
            if strcmp(filestor,'D{_Em}') % check that file user specified as a Donor file is labeled as such in the file
                filestor = fgetl(fid);
                if strcmp(filestor,'Time[s]	D{_Em}[Cnts]')
                    dataarray{fcount, 1} = fscanf(fid, '%f %d\n', [2, inf]); % fscanf function loads rest of file into matirx in dataarray
                    linecount(fcount) = size(dataarray{fcount, 1}, 2); % load file size into matrix so that it can be compared to acceptor file
                else
                    fprintf('File skipped: file %s is not labeled properly\n', filearray{fcount, 1})
                    readerror(fcount) = 0;
                end
            else
                fprintf('File skipped: %s is not a donor file\n', filearray{fcount, 1})
                readerror(fcount) = 0;
            end
            closeerror = fclose(fid);
            if closeerror ~= 0
                fprintf('ERROR closing file %s\n', filearray{fcount, 1})
                readerror(fcount) = 0;
            end
            fid = fopen(filearray{fcount, 2}, 'r'); % open acceptor file
            if fid ~= -1
                filestor = fgetl(fid);
                filestor = strtrim(filestor);
                if strcmp(filestor, 'A{_Em}') % check that file user specified as Acceptor file is labeled as an acceptor file
                    filestor = fgetl(fid);
                    if strcmpi(filestor, 'Time[s]	A{_Em}[Cnts]')
                        dataarray{fcount, 2} = fscanf(fid, '%f %d\n', [2, inf]); % fscanf loads rest of file into matrix
                        if size(dataarray{fcount, 2}, 2) == linecount(fcount) % check that pair of files entered are appropriate
                            if dataarray{fcount, 1}(1,2) == dataarray{fcount, 2}(1,2)
                                fprintf('Files %s and %s are a match!\n', filearray{fcount, 1}, filearray{fcount, 2})
                            else
                                readerror(fcount) = 0;
                                fprintf('Files %s and %s have different time scales, and will be skipped in analysis\n', filearray{fcount, 1}, filearray{fcount, 2})
                            end
                        else
                            readerror(fcount) = 0;
                            fprintf('Files %s and %s are not the same length and will be skipped in analysis\n', filearray{fcount, 1}, filearray{fcount, 2})
                        end
                    else
                        fprintf('File skipped: file %s is not labeled properly\n', filearray{fcount, 2})
                        readerror(fcount) = 0;
                    end
                else
                    fprintf('File skipped: file %s is not a donor file\n', filearray{fcount, 2})
                    readerror(fcount) = 0;
                end
                closeerror = fclose(fid); % close acceptor file
                if closeerror ~= 0
                    fprintf('ERROR closing file %s\n', filearray{fcount, 2})
                    readerror(fcount) = 0;
                end
            else
                fprintf('ERROR opening file %s\n', filearray{fcount, 2})
                readerror(fcount) = 0;
            end
        else
            fprintf('ERROR opeinging file %s\n', filearray{fcount, 1})
            readerror(fcount) = 0;
        end
    end
    ftotal = sum(readerror);
    fray = cell(ftotal,2); % initialize fray to store strings of the filenames
    dtray = cell(ftotal, 1); % intialize dtray array to store FRET data from dataarray raw data
    n = 0;
    for fcount = 1:filecount % initializes each cell in the dtray cell array
        if readerror(fcount)
            n = n + 1;
            dtray{n} = zeros(5, linecount(fcount));
        end
    end
    n = 0;
    for fcount = 1:filecount  % for loop stores dtata and does FRET calculation into dtray cell array, the if statements are needed so that errors are not produced when there are times with no counts, this loop also uses the n variable to trim out all improperly labeled traces
        if readerror(fcount)
            n = n + 1;
            fray{n,1} = filearray{fcount,1}; % store string identifying the name of the donor file
            fray{n,2} = filearray{fcount,2}; % store string identifying the name of the acceptor file
            dtray{n}(1:2, :) = dataarray{fcount, 1}(1:2, :); % store the time and donor counts into the dtray variable
            dtray{n}(3, :) = dataarray{fcount, 2}(2, :); % store the acceptor counts into the dtray variable
            for tm = 1:linecount(fcount) % line by line calculation of total intensity and FRET efficiency, necesary because errors produced when there is 0 intensity, and thus the FRET calculation involves a divide by 0, if statements sort those out and assign FRET efficiency of -1
                dtray{n}(4, tm) = dtray{n}(2, tm) + dtray{n}(3, tm); % intensity caclulation
                if dtray{n}(4, tm) >= 1 % check if intensity is at least 1
                    dtray{n}(5, tm) = dtray{n}(3, tm)/ dtray{n}(4, tm); % calculate FRET efficiency
                else % 0 intensity
                    dtray{n}(5,tm) = -1; % assign FRET efficency to -1
                end
            end
        end
    end
    tbin = zeros(ftotal,1); % initialize the vector of bin sizes for each file
    for fcnt = 1:ftotal % for loop interates through each trace, and calculates bin size
        tbin(fcnt) = dtray{fcnt}(1,2) - dtray{fcnt}(1,1); % bin size calculations
    end
    if min(tbin) == max(tbin) % check if all bins are the same
        fprintf('Congratulations!!! all files have the same bin size, direct comparison possible!!!\n')
    else
        fprintf('Caution: Files have different bin sizes, histogramming will require scalling\n')
    end
    % final output of all variables if user did not indicate incorrect file
    % loading
    bins = tbin;
    farray = fray;
    datarray = dtray;
    cont = ftotal;
else
    % final output of all variables if the user indicates that there was a
    % problem in loading files
    cont = 0;
    farray = {};
    datarray = {};
    bins = [];
end
end

function FmakerFileSave(filearray, dtray, FRETmat, region, intenmin, exclu, filecount,ttle)
        sfile = input('Do you want to save the entire results of this calculation with anotations?(Y/N)\n','s'); % the last section of code creates a file storing the regions of the traces indicated by the user, and then at the end the histogram data
        if strcmpi(sfile, 'y') % execute if user wants to save file in .dat format
            fnamestr = input('Please give name of new file:\n','s'); % prompt to name new file
            fid = fopen(fnamestr, 'w'); 
            if fid ~= -1
                % print data from regions used in traces to file
                fprintf(fid,'%s\r\n',ttle); % adds title give to histogram to the beginning of the file
                for fcnt = 1:filecount % for loop itterates through all traces, so that they can be printed to the file
                    if exclu(fcnt) % traces only added if the user chose in include them in the histogram
                        fprintf(fid,'Donor file: %s Acceptor file: %s\r\n<time (s)>  <donor counts>  <acceptor counts> <FRET ratio>\r\n', filearray{fcnt, 1}, filearray{fcnt, 2}); % print format to beginning of file, including file names
                        for bcnt = 1:size(region{fcnt},2) % for loop iterates through all regions used in histogram, outer loop through each individual region, inner loop through each point in region
                            for lcnt = region{fcnt}(1, bcnt):region{fcnt}(2, bcnt) % inner for loop itereates through each point in region
                                fprintf(fid,'%f %d %d %f\r\n', dtray{fcnt}(1, lcnt), dtray{fcnt}(2, lcnt), dtray{fcnt}(3, lcnt), dtray{fcnt}(5, lcnt)); % print time, donor, acceptor, and FRET efficiency to file
                            end
                            fprintf(fid, '\r\n'); % adds extra line between separate regions from same file
                        end
                        fprintf(fid,'\r\n\r\n'); % adds two lines between separate files in data
                    end
                end
                % print histogram to file
                fprintf(fid,'Calculated FRET histogram\r\n');
                for lcnt = 1:size(FRETmat,1) % for loop itereates through each line of the histogram file printing each value to the output file
                    fprintf(fid, '%f', FRETmat(lcnt, 1)); % print FRET efficiency column of FRET histogram matrix
                    for tcnt = 1:filecount % for loop loops through each column of FRET histogram matrix
                        if exclu(tcnt) % check if column corresponds to exlcuded file, if not, print to file the dwell time
                            fprintf(fid, ' %f', FRETmat(lcnt, (tcnt + 1))); % print to file corresponting FRET dwell time
                        end
                    end
                    fprintf(fid, ' %f\r\n', FRETmat(lcnt, (filecount + 2))); % print summed dwell time to file for given FRET efficency
                end
                % file writing complet, close file next
                closeerror = fclose(fid);
                if closeerror == 0
                    fprintf('File saved succesfully\n')
                else
                    fprintf('ERROR closing file output data file\n')
                end
            else
                fprintf('Error creating file %s\n',fnamestr)
            end
        end
        % this section of the function generates traces for HAMMY
        sfile = input('Do you want to save these files for processing with HAMMY?(Y/N)\n', 's'); % input asking if you want to save as HAMMY
        if strcmpi(sfile, 'y') % if statement executes if user responds with 'y'
            cfidp = -1;
            while cfidp == -1
                rfname = input('Enter name of file to record names of exported traces:','s');
                fidp = fopen(rfname,'w');
                cfidp = fidp;
                if fidp == -1
                    fprintf('Bad file name\n')
                end
            end
            for fcnt = 1:filecount % for loop iterates through all traces
                if exclu(fcnt) % only execute for treaces user included in histogramming
                    sp = strfind(filearray{fcnt}, '.'); % used to generate name of new file
                    fnme = filearray{fcnt, 1}(1:(sp(end) - 2));
                    fnme = strrep(fnme,'.','-');
                    for fct = 1:size(region{fcnt},2)
                        fname = strcat(fnme, num2str(fct));
                        fname = strcat(fname, 'HAMMY.dat');
                        fid = fopen(fname, 'w');
                        fprintf(fidp,'%s\n',fname);
                        if fid ~= 0
                            for lcnt = region{fcnt}(1, fct):region{fcnt}(2, fct) % for loop prints to file all time points in region outer for loop is currently on
                                fprintf(fid,'%f %d %d\r\n', dtray{fcnt}(1, lcnt), dtray{fcnt}(2, lcnt), dtray{fcnt}(3, lcnt));
                            end
                            closeerror = fclose(fid);
                            if closeerror == 0
                                fprintf('File %s saved succesfully\n', fname)
                            else
                                fprintf('ERROR closing file %s\n', fname)
                            end
                        else
                            fprintf('Error opening file %s\n', fname)
                        end
                    end
                end
            end
            closeerror = fclose(fidp);
            if closeerror == 0
                fprintf('HAMMY list file saved correctly\n')
            else
                fprintf('ERROR closing HAMMY list file\n')
            end
        end
       % section for saving catenated HAMMY file
       sfile = input('Do you want to save a single catenated HAMMY file?(Y/N)\n','s');
       if strcmpi(sfile, 'y') % if statement executes if user responds with 'y'
           fname = input('WARNING: all files must have same bin size, global rebin recomended\nEnter name for catenated HAMMY file:\n','s');
           fid = fopen(fname, 'w');
           if fid ~= 0
               for fcnt = 1:filecount % for loop iterates through all traces
                   if exclu(fcnt) % only execute for treaces user included in histogramming
                       for bcnt = 1:size(region{fcnt},2) % for loop to loop through each region in file
                           for lcnt = region{fcnt}(1, bcnt):region{fcnt}(2, bcnt) % for loop prints to file all time points in region outer for loop is currently on
                               fprintf(fid,'%f %d %d\r\n', dtray{fcnt}(1, lcnt), dtray{fcnt}(2, lcnt), dtray{fcnt}(3, lcnt));
                           end
                       end
                   end
               end
               closeerror = fclose(fid);
               if closeerror == 0
                   fprintf('File %s saved succesfully\n', fname)
               else
                   fprintf('ERROR closing file %s\n', fname)
               end
           else
               fprintf('ERROR opening file\n')
           end
       end
        % final section saves a .mat file
        sfile = input('Do you want to save the data as a .mat file?(Y/N)\n', 's'); % prompts if file should be saved in .mat format
        if strcmpi(sfile, 'y')
            % first variables to be stored in file are initialized
            % so that there never is a problem with loading a file, all
            % variables are reassigned for saving
            t = abs(int32(sum(exclu)));
            s = size(FRETmat,1);
            dataarray = cell(t,1);
            flarray = cell(t,2);
            htmregion = cell(t,1);
            intensmin = zeros(t,1);
            FREThst = zeros(s,(t + 2));
            FREThst(:,[1, (t + 2)]) = FRETmat(:,[1, (filecount + 2)]);
            n = 0;
            for fcnt = 1:filecount % loop to create new variables, excluding the traces excluded from the histogram
                if exclu(fcnt) % this if statement selects only the traces included in the histogram
                    n = n + 1; % n counts how many times this loop has been executed with a used file, so indexes of new variable are properly assigned
                    dataarray{n} = dtray{fcnt};
                    flarray{n,1} = filearray{fcnt,1};
                    flarray{n,2} = filearray{fcnt,2};
                    FREThst(:,(n + 1)) = FRETmat(:,(fcnt + 1));
                    htmregion{n} = region{fcnt};
                    intensmin(n) = intenmin(fcnt);
                end
            end
            % final part prompts for name of .mat file, .mat should be
            % inlcuded, and save to said file
            fnamestr = input('Enter desired filename, do not include extension, as .mat will be added automatically\n', 's'); % prompt for filename
            save(fnamestr, 'dataarray','flarray' ,'FREThst','htmregion','intensmin','ttle') % save all relevant variable to that filename
        end
end

function [FREThist, IMIN, bcount, ncount]= FmakerHistogram(fighand, files, dataray, regionmat, histbin, INTENmin)
% Generates bar plots from time traces stored in a matrix, using the format
% of FRETmaker... functions, a requires input of 1: figure number to plot
% dtraces to, 2: a 1x2 cell array of strings, containing the names of the
% files, 3: the relavant data matrix, specifically with first row being
% times, second being donor counts, third acceptor coutns, fourth the sum
% of donor and acceptor counts, and fifth the FRET efficency, followed by a
% 2xN matrix of regions, each column being one region for histogramming, and
% the first row being start times of the regions, and the second row being
% the stop times, an integer specifying the number of bins the histogram
% should have, and finally a minimum intensity a time point must have to be
% added to the histogram, if this input is 0 then the script will prompt
% the user for a minimum intensity
if INTENmin == 0 % if statement runs if INTENmin is 0 in the function call, thus indicating the script should prompt for a minimum intensity
    INTENminstr = input('Input the minimum intensity for FRET to be considered:\n', 's'); % prompt for intensity minimum
    INTENmin = int32(abs(str2double(INTENminstr))); % convert string into a number
end
% initialize some variables
FRETmat = zeros(histbin, 1); % each element of FRETmat stores one bin of the histogram, it is a column vector
fighand.Visible = 'off';
belowmin = 0;
nocount = 0;
for rcnt = 1:size(regionmat,2) % for loop responsible for assigning values to histogram, it loops through every region specified by the region matrix
    for tcnt =  regionmat(1,rcnt):regionmat(2,rcnt) % inner for loop loops through each time point in the region specified by the outer for loop
        if dataray(4,tcnt) >= INTENmin % if statement used to discriminate points above and below the min, if above the min, the appropriate element of FRETmat is incremented
            fbin = round(dataray(5,tcnt)*histbin); % fbin stores the index of the bin to be incremented, the round function is used to convert a floating point to an integer
            if fbin >= 1 % since sometimes round will produce zero, an invalid index, this if statement must be used to prevent error messsages
                FRETmat(fbin) = FRETmat(fbin) + 1; % increment appropriate bin
            else % inrements approriate bin for 0 FRET efficency
                FRETmat(1) = FRETmat(1) + 1;
            end
        else % this else is executed if the time point has an intensity smaller than the intensity minimum
            belowmin = belowmin + 1; % increment a counter for number of points that are below the minimum
            if dataray(4,tcnt) == 0 % extra if statement to count number of points with 0 intensity
                nocount = nocount + 1; % increment 0 intensity counter
            end
        end
    end
end
% the next section is dedicated to plotting the new histogram with the FRET
% efficency and intensity traces above it in the same figure
clf(fighand)
figure(fighand)
subplot(2,2,[1,2]) % specify plot area for FRET efficency trace
plot(dataray(1,:),dataray(5,:),'b-') % plot complete FRET efficency trace in blue
title('FRET')
xlabel('Time(s)')
ylabel('FRET efficency')
ax = [0, dataray(1,end), 0, 1];
axis(ax)
hold on
for rcnt = 1:size(regionmat,2) % for loop plots each specified region in red
    plot(dataray(1,regionmat(1,rcnt):regionmat(2,rcnt)),dataray(5,regionmat(1,rcnt):regionmat(2,rcnt)),'r-')
end
hold off
subplot(2,2,3) % specify plot area for intensity trace
plot(dataray(1,:),dataray(4,:),'c-',dataray(1,:),dataray(2,:),'y-',dataray(1,:),dataray(3,:),'m-') % plot whole intensity trace in blue
title('Intensity')
xlabel('Time(s)')
ylabel('Counts')
ax(4) = max(dataray(4,:)) + 10;
axis(ax)
hold on
for rcnt = 1:size(regionmat,2) % for loop loops through each region and plots in red
    plot(dataray(1,regionmat(1,rcnt):regionmat(2,rcnt)),dataray(4,regionmat(1,rcnt):regionmat(2,rcnt)),'k-',dataray(1,regionmat(1,rcnt):regionmat(2,rcnt)),dataray(2,regionmat(1,rcnt):regionmat(2,rcnt)),'g-',dataray(1,regionmat(1,rcnt):regionmat(2,rcnt)),dataray(3,regionmat(1,rcnt):regionmat(2,rcnt)),'r-') % plot region specified by for loop in red
end
hold off
subplot(2,2,4) % speficy plot area for histogram
bar(1/histbin:1/histbin:1,FRETmat) % plot the histogram
ttl = sprintf('%s',files{1});
title(ttl)
xlabel('FRET efficeincy')
ylabel('Counts')
ax = [0, 1, 0, (max(FRETmat)+1)];
axis(ax)
fighand.Visible = 'on';
FREThist = FRETmat;
IMIN = INTENmin;
bcount = belowmin;
ncount = nocount;
end

function [datamat, cont] = FmakerReBin(dtmat, rebin)
% this function takes data from a time trace and re-bins it to a larger bin
% size, the function call asks for the data in the standard format of
% FRETmaker processed data files, 
bin = dtmat(1,2) - dtmat(1,1); % determine bin size of the data
tsize = size(dtmat,2);
if mod(rebin,bin) == 0 % determine if the new bin size is a multiple of old bin size
    bup = rebin/bin; % this calculates the number of bins that get combined into one bin when going from the old bin size to the new bin size. Since this value will be used several times, it is stored in its own variable
    trem = rem(tsize,bup); % how many of the end data points get trimmed off because the size of the new bins does not perfectly overlap
    ntsize = (tsize - trem)/bup; % number of time points in new file
    datmat = zeros(5,ntsize); % initialize new data variable
    datmat(1,:) = 0:rebin:(rebin*(ntsize-1)); % assign new time points
    for m = 1:ntsize % loop to fill in up-binned data
        datmat([2, 3],m) = sum(dtmat([2, 3],(((m-1)*bup)+1):(m*bup)),2); % fill in donor and acceptor rows
        datmat(4, m) = datmat(2,m) + datmat(3,m); % fill in intensity row
        if datmat(4,m) ~= 0 % if statement needed to prevent errors when intensity is 0 when calculating FRET efficency
            datmat(5,m) = datmat(3,m)/datmat(4,m); % fill in FRET efficency if intensity is not 0
        else % for those times when you saw no photons
            datmat(5,m) = -1; % fill in FRET for seeing no photons
        end
    end
    datamat = datmat; % output data variable
    cont = 1; % output binning succesful
else % in case new bin size is not a muliptle of old bin size
    cont = 0; % binning not succesful
    datamat = dtmat; % output old data
end
end

function [reg ,use]= FmakerTimeTraceGenerator(fighand, filearray, data)
limstor = [0; 0]; % initialize the variable for storing the regions, while the matirx can grow, most of the time only one region is selected, so initializing as a 1x2 matrix is reasonable
Ftracettl = sprintf('FRET efficiency\n%s', filearray{1, 1}); % make a string for the FRET efficiency plot title containing the filename
Itracettl = sprintf('Intensity\n%s', filearray{1, 2}); % make a string for the Intensity plot title containing the filename
set(fighand, 'Visible', 'off')
figure(fighand)
subplot(2,1,1)
plot(data(1, :), data(5, :)) % plot FRET efficency trace
xlabel('Time (s)')
ylabel('FRET efficiency')
title(Ftracettl)
ax = [0, data(1,end), 0, 1];
axis(ax)
subplot(2,1,2)
plot(data(1, :), data(4, :),'b',data(1,:),data(2,:),'g',data(1,:),data(3,:),'r') % plot intensity trace
title(Itracettl)
xlabel('Time')
ylabel('Counts')
set(fighand,'Visible','on')
% next section is for user input of regions
cont = 1;
str4inp = sprintf('Enter begin and end time for histogramming files %s %s\nIf you want to consider several times, please enter addition pairs in the same way:\nIf you want to remove this file from histogramming type "s"\n', filearray{1}, filearray{2}); % string used to prompt to input regions, is stored in variable what is used in the input command within the while loop on the while loops first iteration
while cont % while loop prevents any invalid inputs from causing errors in the output
    % first part of while loop prompts for input
    tinput = input(str4inp,'s');
    tinput = strtrim(tinput);
    cont = 0;
    if strcmpi(tinput, 's') % check if user indicated he wants to skip the current file in histogramming
        cont = 0; % setting cont = 0 terminates while loop an if statement at the end of the function checks if the inputed string is 's' and assigns outputs accordingly
    else % if user did not enter 's' function proceeds to process input as a series of numbers using textscan function
        % take user input and check that both the input is valid as a
        % series of regions and that the regions do not overlap
        lmstor = textscan(tinput, '%f '); % turn string input into a series of numbers
        if mod(length(lmstor{1}), 2) == 0 % check if the number of numbers inputed by user is even, if it is even then the user inputed a series of regions, if odd, then the user failed to enter either a begin or end value for the regions
            limstor = reshape(lmstor{1},2,[]); % take the awkward shape of the output of textscan and assigns it to a more easily understandable indexing convention, stored in limstor, each column is a begin/end pair, the first row is the begin time, the second (last) row is the end time in each pair
            regions = size(limstor, 2); % a counting variable used to store the number of regions (start stop points) in the inputed data
            for rcnt = 1:regions % loop make sure that the first row is all begin times and second row is all end times, it does this by interating through each column, and that all regions do not exceed the length of the time trace itself
                if limstor(1, rcnt) > limstor(2, rcnt) % if staement compares first and second row, if the second row is smaller than the first, the values are switched
                    bstor = limstor([2, 1],rcnt);
                    limstor(:,rcnt) = bstor;
                end
                if limstor(2, rcnt) > data(1,end) % check that the times entered are not larger than the largest time in the trace
                    str4inp = sprintf('One or more of the time ranges you entered exceed the largest time in this trace, please re-enter time ranges for files %s and %s\n', filearray{1, 1}, filearray{1, 2}); % error message to be used in next iteration of while loop's input
                    cont = 1; % cont set to 1 so while loop continues
                end
            end
            % this second secton operates only if the user entered more
            % than one region
            % it is used to make sure that none of the regions overlap so
            % that time points are never counted twice in a histogram
            if numel(limstor) > 2 % check that there are more than 1 region and thus this comparison is necessary
                cmpiterout = 1; % initialize outer variable, script works by comparing each region to all previous regions, thus it operates in two nested while loops (each while loop is somewhat of a for loop in that it terminates when the variable exceeds a certain value, and in each iteration that variable is incremented by 1)
                while cmpiterout <= size(limstor,1) % outer while loop for comparing each region to every other region
                    cmpiterin = 1;
                    while cmpiterin < cmpiterout % inner while loop
                        if xor((limstor(2, cmpiterout) > limstor(1, cmpiterin)), (limstor(2, cmpiterout) > limstor(1, cmpiterin))) % this long if statement identifies if the regions overlap by comparing the end time of each to the beginning time of each, if the regions overlap, then the script sends out an error message
                            str4inp = sprintf('One or more of the time ranges you entered overlap, please re-enter time ranges for files %s and %s\n', filearray{1, 1}, filearray{1, 2}); % set variable so that input regions command will display information that your regions overlapped and you should re enter the regions
                            cmpiterout = size(limstor, 2);
                            cmpiterin = cmpiterout; % used to terminate the while loops
                            cont = 1; % since there was mistake in the region entry, cont set to 1 so the region entry while loop will continue
                        end
                        cmpiterin = cmpiterin + 1; % increment inner variable in inner while loop
                    end
                    cmpiterout = cmpiterout + 1; % increment outer variable in outer while loop
                end
            end
        else % odd number of numbers entred, must enter a new number
            str4inp = sprintf('You are missing either a begin or end time, please re-enter time ranges for files %s and %s\n', filearray{1, 1}, filearray{1, 2}); % set string used in input command to indicate you entered an odd number of numbers and thus are missign a start or stop time
            cont = 1; % cont set to 1 so while loop will continue
        end
    end
end
if ~strcmpi(tinput, 's') % if statement check user input for region selection, if it is not 's', then the function returns use as (signals if user wants to include the trace in histogramming, is set to 1
    use = 1; % response indicating user wants to include trace in histogramming
else % user entered 's', so function returns use as 0 
    use = 0; % response indicating user does not want to use trace in histogramming
end
tbin = data(1,2) - data(1,1); % calculate bin size
reg = int32(limstor/tbin + 1); % turn limstor matrix of floating point times into integer matrix of corresponding indexes for the trace
end

function FmakerUnistats(fighand,reg,bsize,tcon)
regi = [];
for n = 1:size(bsize,1)
    if tcon(n)
        for m = 1:size(reg{n},2)
            regi = [regi (bsize(n)*(double(reg{n}(2,m)) - double(reg{n}(1,m))))];
        end
    end
end
tnum = sum(tcon);
rgnum = size(regi,2);
obtime = sum(regi);
fighand.Visible = 'off';
figure(fighand)
histogram(regi)
xlabel('Time (s)')
title('Trace lengths')
fighand.Visible = 'on';
fprintf('From %d traces there were %d regions with a total observed time of %.3fs\n',tnum,rgnum,obtime)
end
