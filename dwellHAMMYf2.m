function [transcell, dwellstruct, ntr, conm] = dwellHAMMYf2
n = 0;
tcs.tpath = [];
tcs.states = [];
tcs.dwell = {};
tcs.len = 0;
tcs.numtrans = 0;
tcs.numstate = 0;
tcs.fname = '';
tcs.tmat = [];
tcs.sig = 0;
tcs.ppath = [];
flst = input('Enter name of list file: ','s');
fid = fopen(flst);
if fid ~= -1
    while ~feof(fid)
        n = n + 1;
        fname = fgetl(fid);
        if ~isempty(fname)
            tcs(n) = TraceLoad(fname);
            if tcs(n).len == 0
                n = n - 1;
                tcs = tcs(1:n);
            end
        end
    end
    closerror = fclose(fid);
    if closerror == 0
        fprintf('List file closed succesfully\n')
    else
        fprintf('Error closing list file\n')
    end
    f = figure;
    cmt = plotDwell(f,tcs);
    states = [];
    lnts = [];
    tlnts = 0;
    for m = 1:n
        if cmt(m)
            states = [states, tcs(m).states];
            lnts = [lnts, tcs(m).len];
            tlnts = tlnts + tcs(m).len;
        end
    end
    thmat = zeros(100);
    for m = 1:n
        thmat = thmat + tcs(m).len/tlnts*heatmat(tcs(m).tmat,tcs(m).sig,100);
    end
    figure;
    imagesc(thmat)
    fstat = figure('Position',[160 378 1120 420],'Visible','off');
    subplot(1,2,1)
    histogram(lnts,20)
    title('Trace Lengths')
    xlabel('Trace length (ms)')
    ylabel('Occurences')
    subplot(1,2,2)
    histogram(states,0:1/20:1)
    fstat.Visible = 'on';
    title('FRET States')
    xlabel('FRET')
    ylabel('Occurences')
    mlnt = input('Enter minimun trace length to include in final dwell report:\n');
    statest = [];
    for m = 1:n
        if (tcs(m).len > mlnt) && cmt(m)
            statest = [statest, tcs(m).states];
        end
    end
    histogram(statest,0:1/20:1)
    title('Trimmed FRET States')
    xlabel('FRET')
    ylabel('Occurences')
    rnfret = FRETrange;
    dwellstruct = tcs;
    [transcell, ntr] = dwellorg(tcs,rnfret,mlnt,cmt);
    conm = cmt;
else
    fprintf('ERROR could not open list file\n')
    dwellstruct = struct('tpath',[],'states',[],'dwell',[],'numtrans',0,'len',0,'numstate',0);
    transcell = cell(1,1);
    ntr = 0;
end
end

function fstruct = TraceLoad(fname)
fstruct.tpath = [];
fstruct.states = [];
fstruct.dwell = {};
fstruct.len = 0;
fstruct.numtrans = 0;
fstruct.numstate = 0;
fstruct.fname = '';
fstruct.tmat = [];
fstruct.sig = 0;
fstruct.ppath = [];
fname = strtok(fname,'.');
dfname = strcat(fname,'dwell.dat');
rfname = strcat(fname,'report.dat');
pfname = strcat(fname,'path.dat');
fid = fopen(dfname);
bnsz = bnknow(fname);
if fid ~= -1 
    fprintf('Dwell file open succesful\n')
    tpath = fscanf(fid,'%f %f %f\n',[3,inf]);
    fc = fclose(fid);
    if fc == 0
        fprintf('Dwell file %s close succesful\n',dfname)
        if ~isempty(tpath)
            fid = fopen(rfname);
            if fid ~= -1
                strdump = fgetl(fid);
                strdump = fgetl(fid);
                sig = fscanf(fid,'FRET sigma: %f',[1,1]);
                strdump = fgetl(fid);
                strdump = fgetl(fid);
                if strcmp(strdump,'Transition probability matrix:  ')
                    tmat = fscanf(fid,'%f %f %f %f %f\n',[5,inf]);
                    fc = fclose(fid);
                    if fc == 0
                        fprintf('Report file %s close succesful\n',rfname)
                        fid = fopen(pfname);
                        if fid ~= -1
                            ppath = fscanf(fid,'%f %f %f %f %f\n',[5,inf]);
                            ppath(1,:) = ppath(1,:)*bnsz/1000;
                            fc = fclose(fid);
                            if fc == 0
                                fprintf('Path file %s closed succesfully\n',pfname)
                                tpath = blktrim(tpath);
                                tpath(3,:) = tpath(3,:)*bnsz;
                                states = unique(tpath(1,:));
                                numstate = numel(states);
                                len = sum(tpath(3,:));
                                numtrans = size(tpath,2);
                                dwell = cell(1,numstate);
                                for n = 1:numstate
                                    for m = 1:numtrans
                                        if tpath(1,m) == states(n)
                                            dwell{n} = [dwell{n}, tpath(3,m)];
                                        end
                                    end
                                end
                                fstruct.tpath = tpath;
                                fstruct.states = states;
                                fstruct.dwell = dwell;
                                fstruct.len = len;
                                fstruct.numtrans = numtrans;
                                fstruct.numstate = numstate;
                                fstruct.fname = fname;
                                fstruct.tmat = tmat;
                                fstruct.sig = sig;
                                fstruct.ppath = ppath;
                                
                            else
                                fprintf('ERROR: path file %s could not be closed\n',pfname)
                                fstruct.tpath = [];
                                fstruct.states = [];
                                fstruct.dwell = [];
                                fstruct.len = 0;
                                fstruct.numstate = 0;
                                fstruct.numtrans = 0;
                                fstruct.tmat = [];
                                fstruct.sig = 0;
                                fstruct.ppath = [];
                                fstruct.fname = '';
                            end
                        else
                            fprintf('ERROR: path file %s could not be opened\n',pfname);
                            fstruct.tpath = [];
                            fstruct.states = [];
                            fstruct.dwell = [];
                            fstruct.len = 0;
                            fstruct.numstate = 0;
                            fstruct.numtrans = 0;
                            fstruct.tmat = [];
                            fstruct.sig = 0;
                            fstruct.ppath = [];
                            fstruct.fname = '';
                        end
                    else
                        fprintf('ERROR:report file %s could not be closed\n',rfname)
                        fstruct.tpath = [];
                        fstruct.states = [];
                        fstruct.dwell = [];
                        fstruct.len = 0;
                        fstruct.numstate = 0;
                        fstruct.numtrans = 0;
                        fstruct.tmat = [];
                        fstruct.sig = 0;
                        fstruct.ppath = [];
                        fstruct.fname = '';
                    end
                else
                    fprintf('ERROR: report file %s is not a report file\n',rfname)
                    fstruct.tpath = [];
                    fstruct.states = [];
                    fstruct.dwell = [];
                    fstruct.len = 0;
                    fstruct.numstate = 0;
                    fstruct.numtrans = 0;
                    fstruct.tmat = [];
                    fstruct.sig = 0;
                    fstruct.ppath = [];
                    fstruct.fname = '';
                end
            else
                fprintf('ERROR: report fiel %s could not be opened\n',rfname)
                fstruct.tpath = [];
                fstruct.states = [];
                fstruct.dwell = [];
                fstruct.len = 0;
                fstruct.numstate = 0;
                fstruct.numtrans = 0;
                fstruct.tmat = [];
                fstruct.sig = 0;
                fstruct.ppath = [];
                fstruct.fname = '';
            end
        else
            fprintf('No transitions in file %s, file skipped\n',fname)
            fstruct.tpath = [];
            fstruct.states = [];
            fstruct.dwell = [];
            fstruct.len = 0;
            fstruct.numstate = 0;
            fstruct.numtrans = 0;
            fstruct.tmat = [];
            fstruct.sig = 0;
            fstruct.ppath = [];
            fstruct.fname = '';
        end
    else
        fprintf('ERROR: dwell file %s could not be closed\n',dfname)
        fstruct.tpath = [];
        fstruct.states = [];
        fstruct.dwell = [];
        fstruct.len = 0;
        fstruct.numstate = 0;
        fstruct.numtrans = 0;
        fstruct.tmat = [];
        fstruct.sig = 0;
        fstruct.ppath = [];
        fstruct.fname = '';
    end
else
    fprintf('ERROR: dwell file %s could not be opened\n',dfname)
    fstruct.tpath = [];
    fstruct.states = [];
    fstruct.dwell = [];
    fstruct.len = 0;
    fstruct.numstate = 0;
    fstruct.numtrans = 0;
    fstruct.tmat = [];
    fstruct.sig = 0;
    fstruct.ppath = [];
    fstruct.fname = '';
end
end

function frng = FRETrange
ord = {'first','second','third','fourth','fifth','sixth','seventh','eighth','ninth','tenth'};
istring = '0 0';
rng = {};
n = 0;
while ~isempty(istring)
    n = n + 1;
    pstr = sprintf('Input minimum and maximum values for %s FRET state:',ord{n});
    istring = input(pstr,'s');
    rng{n} = str2num(istring);
    [rng, p] = rngsort(rng);
    if ~p
        n = n - 1;
    end
end
frng = rng;
end

function [dhist, tcnt] = dwellorg(tstruct,rng,lmin,cmt)
sz = numel(tstruct);
rs = numel(rng);
dhst = cell(2,rs);
dhst(1,:) = rng;
cnt = 0;
for n = 1:sz
    if (tstruct(n).len > lmin) && (tstruct(n).numtrans > 2) && cmt(n)
        ns = numel(tstruct(n).states);
        cnt = cnt + 1;
        for m = 1:ns
            for o = 1:rs
                if ~isempty(rng{o})
                    if (tstruct(n).states(m) >= rng{o}(1,1)) && (tstruct(n).states(m) <= rng{o}(1,2))
                        dhst{2,o} = [dhst{2,o}, tstruct(n).dwell{m}];
                    end
                end
            end
        end
    end
end
dhist = dhst;
tcnt = cnt;
end

function [rn, k] = rngsort(ra)
n = numel(ra);
if ~sum(isnan(ra{n}))
    m = numel(ra{n});
    if m == 2
        if ra{n}(1,1) == ra{n}(1,2)
            rn = ra(1:n-1);
            k = false;
        elseif ra{n}(1,1) > ra{n}(1,2)
            ra{n} = [ra{n}(1,2), ra{n}(1,1)];
        end
        if n == 1;
            schk = false;
            rn = ra;
            k = true;
        else
            schk = true;
            chk = n - 1;
        end
        while schk
            if ra{n}(1,1) > ra{chk}(1,2)
                if (chk + 1) == n
                    rn = ra;
                    k = true;
                elseif n ~= 2
                    rn = [ra(1:chk), ra(n), ra(chk+1:n-1)];
                    k = true;
                else
                    rn = [ra(1), ra(n)];
                end
                schk = false;
            elseif ra{n}(1,2) < ra{chk}(1,1)
                if chk ~= 1
                    chk = chk - 1;
                else
                    rn = [ra(n), ra(1:n-1)];
                    k = true;
                    schk = false;
                end
            else
                rn = ra(1:n-1);
                k = false;
                schk = false;
            end
        end
    else
        rn = ra(1:n-1);
        k = false;
    end
else
    k = false;
    rn = {};
end
end

function bn = bnknow(fstring)
nu = strtok(fstring,'ms');
bn = str2double(nu);
end



function hm = heatmat(tpm,sigma,dim)
htmp = zeros(dim);
sz = size(tpm,2);
for m = 1:sz
    for o = 1:dim
        for p = 1:dim
            htmp(o,p) = htmp(o,p) + tpm(5,m)*(1/(sigma*(2*pi)^(1/2)))*exp(-((o/dim-tpm(1,m))^2)/(2*sigma^2)-((p/dim-tpm(2,m))^2)/(2*sigma^2));
        end
    end
end
hm = htmp;
end

function contmat = plotDwell(fig,dwellstruct)
figure(fig)
fig.Visible = 'off';
n = 0;
s = size(dwellstruct,2);
cmat = ones(1,s);
g1 = axes('Position',[0.12 0.2 0.775 0.745]);
plot(g1,dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(4,:),'b',dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(5,:),'r')
figb = uicontrol('Style','pushbutton','Position',[10,10,100,20],'String','Back','Callback',@backcallback);
fign = uicontrol('Style','pushbutton','Position',[120,10,100,20],'String','Next','Callback',@nextcallback);
grp = uibuttongroup('Parent',fig,'Position',[0.4, 0, 0.4, 0.1]);
figk = uicontrol('Parent',grp,'Style','radio','Position',[120,10,100,20],'String','Keep');
figr = uicontrol('Parent',grp,'Style','radio','Position',[10,10,100,20],'String','Remove');
figc = uicontrol('Style','pushbutton','Position',[450,10,100,20],'String','Close','Callback',@closecallback);
ttle = sprintf('%i/%i',n+1,s);
title(ttle)
fig.Visible = 'on';

    function backcallback(hObject,eventdata,handles)
        if figk == grp.SelectedObject
            cmat(n+1) = 1;
        elseif figr == grp.SelectedObject
            cmat(n+1) = 0;
        end
        n = n-1;
        n = mod(n,s);
        ttle = sprintf('%i/%i',n+1,s);
        plot(g1,dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(4,:),'b',dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(5,:),'r')
        title(g1,ttle)
    end
    function nextcallback(hObject,eventdata,handles)
        if figk == grp.SelectedObject
            cmat(n+1) = 1;
        elseif figr == grp.SelectedObject
            cmat(n+1) = 0;
        end
        n = n+1;
        n = mod(n,s);
        ttle = sprintf('%i/%i',n+1,s);
        plot(g1,dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(4,:),'b',dwellstruct(n+1).ppath(1,:),dwellstruct(n+1).ppath(5,:),'r');
        title(g1,ttle)
    end
    function closecallback(hObject,eventdata,handles)
        close(fig)
    end
uiwait
contmat = cmat;
end

function path = blktrim(pth)
n = 1;
if size(pth,2) >= 3
    m = size(pth,2);
    while n < m-1
        if (pth(3,n+1) == 1) && (pth(1,n) == pth(1,n+2))
            pth(3,n) = pth(3,n) + pth(3,n+1) +  pth(3,n+2);
            pth(:,n+1:n+2) = [];
            m = m - 2;
        else
            n = n + 1;
        end
    end
    path = pth;
else
    path = pth;
end
end
