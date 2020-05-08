functor
import
    System
    Browser
    Reader
    Parser
    PredictionDictionary
    GUI
define
    Show = System.show % macro definition
    LaunchParsing

    FilesNumber = 208
    ThreadsNumber = 16

    PredictionDictionaryPort = {PredictionDictionary.createDictionary}
    Test
in
    % Parses all files and blocks main thread execution until finished
    proc {LaunchParsing MaxFilesNumber MaxThreadsNumber}
        proc {Barrier Ps}
            Xs = {Map Ps fun {$ P} X in thread {P} X = unit end X end}
        in
            for X in Xs do
                {Wait X}
            end
        end
        fun {GenerateParsers Statements LastFile ThreadIndex} % one parser per file
            if LastFile >= MaxFilesNumber then
                Statements
            else
                Statement
                NFiles = (MaxFilesNumber + ThreadIndex) div MaxThreadsNumber
                End = LastFile + NFiles
            in
                Statement = proc {$} Stream X in
                                Stream = thread {Reader.readFiles (LastFile + 1) End} end
                                thread {Parser.parseStream Stream PredictionDictionaryPort} X = unit end {Wait X}
                            end
                {GenerateParsers Statement|Statements End (ThreadIndex + 1)}
            end
        end
        Parsers
    in
        local TimeStart
            TimeStart = {Time.time}
        in
            {System.show 'Parsing...'}
            Parsers = {GenerateParsers nil 0 0}
            {Barrier Parsers}
            {System.show 'Parsing finished'}
            {System.show time('Time' ({Time.time} - TimeStart) seconds)}
        end
    end

    {LaunchParsing FilesNumber ThreadsNumber}
    {GUI.startWindow PredictionDictionaryPort}
end