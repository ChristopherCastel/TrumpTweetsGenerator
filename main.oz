functor
import
    System
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
    MaxParsingThreads = 1
    FilesNumber = 208
    PredictionDictionaryPort = {PredictionDictionary.createDictionary}
in
    proc {LaunchBoundedParsing N}

        proc {BuildThreadPool ?ThreadPool ?ThreadPoolTail Current Boundary}
            if Current > Boundary then
                ThreadPoolTail = ThreadPool
            else Tail in
                ThreadPool = {DedicatedThread}|Tail
                {BuildThreadPool Tail ThreadPoolTail Current+1 Boundary}
            end
        end

        proc {BoundedBarrier ThreadPool ThreadPoolTail Jobs}
            proc {Loop ThreadPool ThreadPoolTail Jobs JobsUnits JobsUnitsTail}
                case ThreadPool
                    of Thread|OtherThreads then
                        case Jobs
                            of Job|JobsTail then NewThreadPoolTail NewJobsUnitsTail in
                                thread CurrJobUnit in
                                    {Send Thread start(Job CurrJobUnit)}
                                    if JobsTail \= nil then
                                        JobsUnitsTail = CurrJobUnit|NewJobsUnitsTail
                                    else
                                        JobsUnitsTail = CurrJobUnit|nil
                                    end
                                    {Wait CurrJobUnit}
                                    ThreadPoolTail = Thread|NewThreadPoolTail
                                end
                                {Loop OtherThreads NewThreadPoolTail JobsTail JobsUnits NewJobsUnitsTail}
                            [] nil then
                                {Show barrier(ended 'waiting for all threads to end')}
                                for U in JobsUnits do
                                    {Wait U}
                                end
                                {Show barrier(ended 'all threads ended')}
                        end
                end
            end
        in
            local JobsUnits in
                {Loop ThreadPool ThreadPoolTail Jobs JobsUnits JobsUnits}
            end
        end

        fun {DedicatedThread}
            Stream
            Port = {NewPort Stream}
            proc {Loop Msg}
                case Msg
                    of start(Job Unit)|Tail then
                        thread
                            {Job}
                            Unit = unit
                        end
                        {Loop Tail}
                end
            end
        in
            thread {Loop Stream} end
            Port
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
                Parsers ThreadPool ThreadPoolTail
            in
                {BuildThreadPool ThreadPool ThreadPoolTail 1 MaxParsingThreads}
                Parsers = {GenerateParsers nil 1}
                {BoundedBarrier ThreadPool ThreadPoolTail Parsers}
            end

            {Show 'Parsing finished'}
            {Show time('Time' ({Time.time} - TimeStart) seconds)}
        end
    end

    {LaunchBoundedParsing FilesNumber}
    {GUI.startWindow PredictionDictionaryPort}
end