functor
import
    System
    Browser
    Reader
    Parser
    GUI
define
    Show = System.show % macro definition
    GUIPort = {GUI.startWindow}
    Stream
in
    % for Filenumber in 1..208 do Stream in
        % Stream = {Reader.readfile 'tweets/part_'#Filenumber#'.txt'}
        Stream = {Reader.readfile 'tweets/part_1.txt'}
        {Parser.parseStream Stream}
    % end
end

% ThreadedReadFile
