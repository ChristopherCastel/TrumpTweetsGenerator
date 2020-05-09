functor
import
    System
    Browser
    Reader
    Parser
    PredictionDictionary
    GUI
define
    % macro definitions
    Show = System.show
    % functions
    LaunchBoundedParsing
    % variables
    MaxParsingThreads = 16
    FilesNumber = 208
    PredictionDictionaryPort = {PredictionDictionary.createDictionary}
    Test
in
    proc {LaunchBoundedParsing N}

        proc {BuildExecutionTokens ?ExecutionTokens ?ExecutionTokensTail Current Boundary}
            if Current > Boundary then Tail in
                ExecutionTokens = ExecutionTokensTail
            else Tail in
                ExecutionTokens = token|Tail
                {BuildExecutionTokens Tail ExecutionTokensTail Current+1 Boundary}
            end
        end

        proc {BoundedBarrier ExecutionTokens ExecutionTokensTail Jobs}
            case ExecutionTokens
                of ExecToken|TokenTail then
                    case Jobs
                        of Job|JobsTail then NewTail in
                            thread
                                {Job}
                                ExecutionTokensTail = token|NewTail
                            end
                            {BoundedBarrier TokenTail NewTail JobsTail}
                        [] nil then
                            skip
                    end
            end
        end

        fun {GenerateParsers Statements FileNumber} % one parsed per file
            if FileNumber > N then
                Statements
            else Statement in
                Statement = proc {$}
                        Stream
                        UnitReader
                        UnitParser
                    in
                        {Show job(FileNumber started)}
                        thread
                            Stream = {Reader.readfile 'tweets/part_'#FileNumber#'.txt'}
                            UnitReader = unit
                        end
                        thread
                            {Parser.parseStream Stream PredictionDictionaryPort}
                            UnitParser = unit
                        end
                        {Wait UnitReader}
                        {Wait UnitParser}
                        {Show job(FileNumber ended)}
                    end
                {GenerateParsers Statement|Statements FileNumber+1}
            end
        end

    in
        local TimeStart
            TimeStart = {Time.time}
        in
            {Show 'Parsing...'}
            local
                Parsers ExecutionTokens ExecutionTokensTail
            in
                {BuildExecutionTokens ExecutionTokens ExecutionTokensTail 1 MaxParsingThreads}
                Parsers = {GenerateParsers nil 1}
                {BoundedBarrier ExecutionTokens ExecutionTokensTail Parsers}
            end
            {Show 'Parsing finished'}
            {Show time('Time' ({Time.time} - TimeStart) seconds)}
        end
    end

    {LaunchBoundedParsing FilesNumber}
    % {GUI.startWindow PredictionDictionaryPort}
end