function [x, y, resolution, commentaire] = bomem(fich, aff, calib, fond, lim)
% function [x, y] = bomem(fich, aff, {calib, fond, lim})
% Pour fichiers .spc
% aff = 0 cm-1
% aff = 1 eV
% aff = 2 angstroems
% fond (optionnel): vecteur à soustraire;
% lim (optionnel): vecteur des indices à conserver;

disp(' ')
disp(['  fichier ' fich '.spc'])
[x, y, resolution, commentaire] = rbom(fich);
if (nargin == 2 | isempty(calib))
    calib = menu('RÉPONSE SPECTRALE', 'pas de calibration (0)', 'Si lame quartz (1)', 'InGaAs lame quartz (2)', ...
        'Ge lame CaF2 (3)', 'InSb lame quartz (4)', 'InSb lame CaF2 (5)') - 1;
end
if nargin>3
    y = y - fond;
end
if nargin>4
    x = x(lim);
    y = y(lim);
end
switch calib
    case 1,
        load fcrsi
        fact = ppval(fcrsi, x);
    case 2,
        load fcringavis
        fact = ppval(fcringavis, x);
    case 3,
        load fcrgecaf2
        fact = ppval(fcrgecaf2, x);
    case 4,
        load fcrinsbvis
        fact = ppval(fcrinsbvis, x);
    case 5,
        load fcrinsbcaf2
        fact = ppval(fcrinsbcaf2, x);
    otherwise,
        fact = ones(size(x));
end
y = y .* fact;
if aff == 1
    x = x / 8065.54;
elseif aff == 2
    y = y ./ (x / 11000) .^2;
    x = 1 ./ x * 1e8 / 1.00027;
end
unites = {'cm-1';'eV';'angstroems'};
disp(['  ' commentaire])
disp(['  résolution nominale : ' resolution ' cm-1'])
disp(['  nombre de points : ' num2str(length(x), 6)]);
disp(['  axe X : ' num2str(min(x), 6) ' à ' num2str(max(x), 6) ' ' unites{aff + 1}])
disp(['  axe Y : ' num2str(min(y), 5) ' à ' num2str(max(y), 5)])

function [x, y, res, comm] = rbom(fich)

fich = [fich '.spc'];
fid = fopen(fich);
if fid ~= -1
    [a, a, endian] = computer;
    switch endian
        case 'B'
            fseek(fid, 3, -1);
            exposant = fread(fid, 1, 'uint8');
            npts = double(swapbytes(fread(fid, 1, 'uint32=>uint32')));
            xx = swapbytes(fread(fid, 2, 'float64'));
            x = linspace(xx(1), xx(2), npts)';
            fseek(fid, 36, -1);
            res = char(fread(fid, 9, 'char')');
            fseek(fid, 88, -1);
            comm = char(fread(fid, 130, 'char')');
            fseek(fid, 544, -1);
            y = double(swapbytes(fread(fid, npts, 'int32=>int32'))) * 2 ^ (exposant - 32);
        case 'L'
            fseek(fid, 3, -1);
            exposant = fread(fid, 1, 'uint8');
            npts = fread(fid, 1, 'uint32');
            xx = fread(fid, 2, 'float64');
            x = linspace(xx(1), xx(2), npts)';
            fseek(fid, 36, -1);
            res = char(fread(fid, 9, 'char')');
            fseek(fid, 88, -1);
            comm = char(fread(fid, 130, 'char')');
            fseek(fid, 544, -1);
            y = fread(fid, npts, 'int32') * 2 ^ (exposant - 32);
    end
    fclose(fid);
else
    disp(['                       ';'     fichier pas trouve';'                       '])
    x = 0;
    y = 0;
end