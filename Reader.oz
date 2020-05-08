functor
import
    Open
    System
export
    readFiles:ReadFiles
define
    class TextFile from Open.file Open.text end
    ReadFiles
in
    % Reads the whole file and returns a stream of lines
    fun {ReadFiles CurrentFileIndex End} % reads whole file
        FileReader
        fun {ReadFileLoop} % read file line by line
            Line = {FileReader getS($)}
        in
            if Line == false then
                {FileReader close}
                {ReadFiles (CurrentFileIndex + 1) End}
            else
                Line|{ReadFileLoop}
            end
        end
    in
        if CurrentFileIndex > End then
            nil
        else
            FileReader = {New TextFile init(name:'tweets/part_'#CurrentFileIndex#'.txt')}
            {ReadFileLoop}
        end
    end
end