function gout=warpedblfilter(winname,fsupp,fc,fs,freqtoscale,scaletofreq,varargin)
%-*- texinfo -*-
%@deftypefn {Function} warpedblfilter
%@verbatim
%WARPEDBLFILTER  Construct a warped band-limited filter
%   Usage:  g=warpedblfilter(winname,fsupp,fc,fs,freqtoscale,scaletofreq);
%
%   Input parameters:
%      winname     : Name of prototype.
%      fsupp       : Support length of the prototype (in scale units).
%      fc          : Centre frequency (in Hz).
%      fs          : Sampling rate
%      freqtoscale : Function handle to convert Hz to scale units
%      scaletofreq : Function to convert scale units into Hz.
%
%   Output parameters:
%      g           : Filter definition, see BLFILTER.
%
%   WARPEDBLFILTER(winname,fsupp,fc,fs,freqtoscale,scaletofreq) constructs
%   a band-limited filter that is warped on a given frequency scale. The 
%   parameter winname specifies the basic shape of the frequency response.
%   The name must be one of the shapes accepted by FIRWIN. The support of
%   the frequency response measured on the selected frequency scale is 
%   specified by fsupp, the centre frequency by fc and the scale by the
%   function handle freqtoscale of a function that converts Hz into the 
%   choosen scale and scaletofreq doing the inverse.
%
%   If one of the inputs is a vector, the output will be a cell array
%   with one entry in the cell array for each element in the vector. If
%   more input are vectors, they must have the same size and shape and the
%   the filters will be generated by stepping through the vectors. This
%   is a quick way to create filters for FILTERBANK and UFILTERBANK.
%
%   WARPEDBLFILTER accepts the following optional parameters:
%
%     'complex'      Make the filter complex valued if the centre frequency
%                    is non-zero. This is the default.
%
%     'real'         Make the filter real-valued if the centre frequency
%                    is non-zero.
%
%     'symmetric'    The filters with fc<0 (or fc>fs/2) will be created
%                    on the positive frequencies and mirrored. This allows
%                    using freqtoscale defined only for the positive 
%                    numbers.
%
%     'delay',d      Set the delay of the filter. Default value is zero.
%
%     'scal',s       Scale the filter by the constant s. This can be
%                    useful to equalize channels in a filterbank.
%
%   It is possible to normalize the transfer function of the filter by
%   passing any of the flags from the NORMALIZE function. The default
%   normalization is 'energy'.
%
%   The filter can be used in the PFILT routine to filter a signal, or
%   in can be placed in a cell-array for use with FILTERBANK or
%   UFILTERBANK.
%
%   The output format is the same as that of BLFILTER. 
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/warpedblfilter.html}
%@seealso{blfilter, firwin, pfilt, filterbank}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

capmname = upper(mfilename);
complainif_notenoughargs(nargin,6,capmname);
complainif_notposint(fs,'fs',capmname);

if isempty(freqtoscale) || ~isa(freqtoscale,'function_handle')
    error('%s: freqtoscale must be a function handle',capmname);
end

if isempty(scaletofreq) || ~isa(scaletofreq,'function_handle')
    error('%s: scaletofreq must be a function handle',capmname);
end

if isempty(fc) || ~isnumeric(fc)
   error('%s: fc must be numeric',capmname);
end

if isempty(fsupp) || ~isnumeric(fsupp)
   error('%s: fc must be numeric',capmname);
end

% Define initial value for flags and key/value pairs.
definput.import={'normalize'};
definput.importdefaults={'energy'};
definput.keyvals.delay=0;
definput.keyvals.scal=1;
definput.flags.real={'complex','real'};
definput.flags.symmetry = {'nonsymmetric','symmetric'};

[flags,kv]=ltfatarghelper({},definput,varargin);

if ~isscalar(kv.scal)
    error('%s: scal must be a scalar',capmname);
end

if ~isscalar(kv.delay)
    error('%s: delay must be a scalar',capmname);
end

[fsupp,fc,kv.delay,kv.scal]=scalardistribute(fsupp,fc,kv.delay,kv.scal);

Nfilt=numel(fsupp);
gout=cell(1,Nfilt);

if ischar(winname)
    wn = {winname};
elseif iscell(winname)
    wn = winname;
else
    error('%s: Incorrect format of winname.',upper(mfilename));
end

for ii=1:Nfilt
    g=struct();
    
    
    if flags.do_1 || flags.do_area 
        g.H=@(L)    comp_warpedfreqresponse( wn{1},fc(ii), ...
                                             fsupp(ii),fs,L,freqtoscale, ...
                                             scaletofreq, flags.norm,...
                                             flags.symmetry)*kv.scal(ii)*L;
    end;
    
    if  flags.do_2 || flags.do_energy
        g.H=@(L)    comp_warpedfreqresponse(wn{1},fc(ii), ...
                                            fsupp(ii),fs,L,freqtoscale,scaletofreq, ...
                                            flags.norm,flags.symmetry)*kv.scal(ii)*sqrt(L);
    end;
        
    if flags.do_inf || flags.do_peak
        g.H=@(L)    comp_warpedfreqresponse(wn{1},fc(ii), ...
                                            fsupp(ii),fs,L,freqtoscale,scaletofreq, ...
                                            flags.norm,flags.symmetry)*kv.scal(ii);
    end;
        
    g.foff=@(L) comp_warpedfoff(fc(ii),fsupp(ii),fs,L,freqtoscale,...
                                scaletofreq,flags.do_symmetric);
    g.realonly=flags.do_real;
    if kv.delay~=0
       g.delay=kv.delay(ii);
    end
    g.fs=fs;
    gout{ii}=g;
end;

if Nfilt==1
    gout=g;
end;

