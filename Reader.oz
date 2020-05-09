functor
import
    Open
export
    readfile:ReadFile
define
    class TextFile from Open.file Open.text end
    ReadFile
in
    % Reads the whole file and returns a stream of lines
    fun {ReadFile Filename}
        Filereader = {New TextFile init(name:Filename)}
        fun {BuildStream}
            Line = {Filereader getS($)}
        in
            if Line == false then
                {Filereader close}
                nil
            else
                Line|{BuildStream}
            end
        end
    in
        {BuildStream}
    end
end