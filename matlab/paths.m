function P = paths()
P.BASE_DIR = 'E:\AI\AI project\code';
P.MATLAB_DIR = fullfile(P.BASE_DIR, 'matlab');
P.PYTHON_DIR = fullfile(P.BASE_DIR, 'python');
P.DATA_DIR = fullfile(P.BASE_DIR, 'data');
P.OUTPUTS_DIR = fullfile(P.BASE_DIR, 'outputs');
P.PLOTS_DIR = fullfile(P.OUTPUTS_DIR, 'plots');
P.EXCEL_DIR = fullfile(P.OUTPUTS_DIR, 'excel');
P.ARCHIVE_DIR = fullfile(P.BASE_DIR, 'archive');
P.TEMP_DIR = fullfile(P.ARCHIVE_DIR, 'temp');
if ~exist(P.TEMP_DIR, 'dir'), mkdir(P.TEMP_DIR); end
end