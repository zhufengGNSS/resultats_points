function [PosSat, Dobs, ElevSat, sat_index, result_LS_code_base]=interf_calc_preprocessing_DGNSS(RNX_header_base, RNX_data_base, RNX_header_rover, RNX_data_rover, NAV_header, NAV_data, X0_base, epoch, options)
%% function [PosSat, Dobs, ElevSat, sat_index, result_LS_code_base]=interf_calc_preprocessing_DGNSS(RNX_header_base, RNX_data_base, RNX_header_rover, RNX_data_rover, NAV_header, NAV_data, X0_base, epoch, options)
%% Data organization and preparation before DGNSS processing - interface function
%%
%% Clement Fontaine - 2014-01-09
%%
%% Input
%%	- RNX_header_base, RNX_data_base : obs rinex data for base station generated by function load_rinex_o
%%	- RNX_header_rover, RNX_data_rover : obs rinex data for rover station generated by function load_rinex_o
%%  - NAV_header,NAV_data : nav data (rinex_n or sp3) generated by load_rinex_n (for broadcasted ephemeris) or load_sp3 (for precise orbits)
%% 		- broadcasted ephemeris : NAV_header,NAV_data generated from broadcasted ephemeris .n or .p
%% 		- precise orbits : replace NAV_header,NAV_data by sp3_header,sp3_data, and set options.nav to 'sp3'
%%  - X0_base : base station coordinates
%%	- epoch : computation epoch
%%	- options : structure containing processing options ( optional )
%% {
%%   X0 : approximated coordinates (column vector of 6 elements [X;Y;Y;cdtr;cGGTO;cGPGL]) 
%%        default : X0 = [0 ;0; 0; 0; 0; 0];
%%   const : constellations used ('G' = GPS, 'R' = Glonass, 'E' = Galileo, for multi-constellation concatenate chars)
%%        default : 'G'
%%   freq : type of used data [F1,F2,iono_free] 
%%        default : iono_free
%%         - 'F1' : use F1 frequency obs
%%         - 'F2' : use F2 frequency obs (or F5 for Galileo)
%%         - 'iono_free' : ionosphere-free combination
%%		   default : 'iono_free'
%%   iono : type of correction :
%%		   - 'klobuchar' : klobuchar modelization -> if  nav = 'brdc'
%%		   - 'none' : no correction (if freq = 'iono_free', iono set to 'none')
%%         default : 'none' 
%%   nav : type of orbits
%%		   - 'brdc' : broadcasted ephemeris
%%         - 'sp3' : precise orbits
%%         default : 'brdc'    
%%   cut_off : elevation cut off in degree
%%         default : 3 degrees
%% }
%%
%% Output : 
%% - PosSat : matrix containing satellite position [Xs_rover, Ys_rover, Zs_rover] (m)
%% - Dobs : vector containing corrected observations (from rover station) (m)
%% - elev_Sat : vector of satellite elevation (from rover station) (rad)
%% - sat_index : vector containing constellation type (1 = GPS, 2 = Galileo, 3 = Glonass)
%% - result_LS_code_base : structure containing results of base dtr estimation
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
c = 299792458.0;

if nargin == 9
	if isfield(options,'X0')
		X0 = options.X0;
		if length(X0)<6
			X0 = [X0(:);zeros(6-length(X0),1)];
		end
		options.X0 = X0;
	else
		options.X0 = [0;0;0;0;0;0];
	end
else
	options.X0 = [0;0;0;0;0;0];
end


X0_base = [X0_base(1:3);0]; %cdtr

% initial cGGTO and cGPGL

if isfield(NAV_header,'GPGA')
	cGGTO = c * NAV_header.GPGA(1);  % Approx GGTO, not the real formula which need mjd (cf official doc Galileo)
	X0_base = [X0_base;cGGTO];  
else
	X0_base = [X0_base;0];  
end

if isfield(NAV_header,'GLGP')
	cGPGL = c * NAV_header.GLGP(1); % in rinex, GPGL is not defined, but  - GLGP is present
	X0_base = [X0_base;cGPGL];  
else
	X0_base = [X0_base;0];  
end
	

[G1,G2,result,result_LS_code_base]=calc_preprocessing_DGNSS(RNX_header_base, RNX_data_base, RNX_header_rover, RNX_data_rover, NAV_header, NAV_data, X0_base, epoch, options);

% output
PosSat = result.PosSat(:,4:6);
Dobs = result.Dobs(:,2);
ElevSat = result.ElevSat(:,2);

sat_index_temp = zeros(size(Dobs,1),1);
for i = 1:size(result.sat_index,1)
	id = result.sat_index{i,1};
	if (id(1) == 'G')
		sat_index_temp(i) = 1;
	elseif (id(1) == 'E')
		sat_index_temp(i) = 2;
	elseif (id(1) == 'R')
		sat_index_temp(i) = 3;
	end
end

sat_index = sat_index_temp;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

