functor
import
    Open
export
    readfile:ThreadedReadFile
define
    class TextFile from Open.file Open.text end
    ThreadedReadFile
in
    % Reads the whole file and returns a stream of lines
    fun {ThreadedReadFile Filename}
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
        thread {BuildStream} end
    end
end