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

    FilesNumber = 1
    PredictionDictionaryPort = {PredictionDictionary.createDictionary}
in
    % Parses all files and blocks main thread execution until finished
    proc {LaunchParsing N}
        proc {Barrier Ps}
            Xs = {Map Ps fun {$ P} X in thread {P} X = unit end X end}
        in
            for X in Xs do
                {Wait X}
            end
        end
        fun {GenerateParsers Statements FileNumber} % one parsed per file
            if FileNumber > N then
                Statements
            else Statement in
                Statement = proc {$} Stream in
                            Stream = {Reader.readfile 'tweets/part_'#FileNumber#'.txt'}
                            {Parser.parseStream Stream PredictionDictionaryPort} end
                {GenerateParsers Statement|Statements FileNumber+1}
            end
        end
        Parsers
    in
        {System.show 'Parsing...'}
        Parsers = {GenerateParsers nil 1}
        {Barrier Parsers}
        {System.show 'Parsing finished'}
    end

    {LaunchParsing FilesNumber}
    {GUI.startWindow PredictionDictionaryPort}
end