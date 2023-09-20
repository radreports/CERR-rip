function gd=ref_tgabdual(ttype,g,L,a,M)
%REF_WIN   Compute appropriate dual window for transform
%
%
%   Url: http://ltfat.github.io/doc/reference/ref_tgabdual.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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

if nargin<5
  error('Too few input parameters.');
end;

info=ref_transforminfo(ttype,L,a,M);

gd=info.winscale*gabdual(g,info.a,info.M);


