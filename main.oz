functor
import
    System
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
            StdOut
        in
            {Show stdout_info({VirtualString.toAtom "parsing "#FilesNumber#" files with "#ThreadsNumber#" threads..."})}
            Parsers = {GenerateParsers nil 0 0}
            {Barrier Parsers}
            StdOut = stdout_info({VirtualString.toAtom "parsing finished in "#({Time.time} - TimeStart)#" seconds"})
            {Show StdOut}
        end
    end

    {LaunchParsing FilesNumber ThreadsNumber}
    {GUI.startWindow PredictionDictionaryPort}
end