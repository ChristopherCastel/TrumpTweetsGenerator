functor
import
    System
    Browser
    Reader
    GUI
define
    Show = System.show % macro definition
    GUIPort = {GUI.startWindow}
in
    for Filenumber in 1..208 do Stream in
        Stream = {Reader.readfile 'tweets/part_'#Filenumber#'.txt'}
        {Parser.parseStream Stream}
    end
end

% ThreadedReadFile
