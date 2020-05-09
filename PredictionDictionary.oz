functor
import
    System
export
    createDictionary:CreateDictionary
define
    CreateDictionary
    HandleCommands
    Save
    PredictNext

    DictionaryWords
in
    fun {CreateDictionary}
        Stream
        Port = {NewPort Stream}
    in
        {Dictionary.new DictionaryWords}
        thread {HandleCommands Stream} end
        Port
    end

    proc {Save Word Next}
        DictionaryCounts
    in
        if {Not {Dictionary.member DictionaryWords Word}} then NewDictionaryCounts in
            {Dictionary.new NewDictionaryCounts}
            {Dictionary.put DictionaryWords Word NewDictionaryCounts}
        end
        {Dictionary.get DictionaryWords Word DictionaryCounts}
        if {Not {Dictionary.member DictionaryCounts Next}} then
            {Dictionary.put DictionaryCounts Next 1}
        else OldCount in
            {Dictionary.get DictionaryCounts Next OldCount}
            {Dictionary.put DictionaryCounts Next OldCount+1}
        end
    end

    fun {PredictNext Word Range}
        % Returns N (or less) best words in the given dictionary
        % Iterates N times or until the initial entries list is fully depleted
        % When one best word is found, NextEntries holds the current entries without the best word
        proc {GetNBestWords Entries NextEntries NextEntriesTail ?BestWords BestWord N}
            case Entries
                of (Word#Count)|OtherEntries then
                    % found candidate best word
                    if (Count >= BestWord.2) then Tail in
                        % makes sure to omit the one best word from the NextEntries
                        if BestWord.1 \= null then
                            NextEntriesTail = BestWord|Tail
                            {GetNBestWords OtherEntries NextEntries Tail BestWords (Word#Count) N}
                        else
                            {GetNBestWords OtherEntries NextEntries NextEntriesTail BestWords (Word#Count) N}
                        end
                    else Tail in
                        NextEntriesTail = (Word#Count)|Tail
                        {GetNBestWords OtherEntries NextEntries Tail BestWords BestWord N}
                    end
                [] nil then
                    % no best word found (entries is empty) or found enough best-words
                    if BestWord.1 == null orelse N =< 0 then
                        BestWords = nil
                    else BestWordsTail FreshNextEntries in
                        NextEntriesTail = nil
                        BestWords = BestWord.1|BestWordsTail
                        {GetNBestWords NextEntries FreshNextEntries FreshNextEntries BestWordsTail (null#~1) (N-1)}
                    end
            end
        end
    in
        if {Not {Dictionary.member DictionaryWords Word}} then
            null
        else DictionaryCounts Entries NextEntries NBestWords in
            DictionaryCounts = {Dictionary.get DictionaryWords Word}
            Entries = {Dictionary.entries DictionaryCounts}
            {GetNBestWords Entries NextEntries NextEntries NBestWords (null#~1) Range}
            NBestWords
        end
    end

    proc {HandleCommands Stream}
        case Stream
            of save(word:Word next:Next)|T then
                % {System.show stdout_debug({String.toAtom Word} ' ' {String.toAtom Next})}
                {Save {String.toAtom Word} {String.toAtom Next}}
                {HandleCommands T}
            [] predict(range:Range word:Word predictedWords:Next)|T then
                Next = {PredictNext Word Range}
                {HandleCommands T}
            [] _|T then
                {System.show error('[Prediction dictionary]' 'Unknown command')}
                {HandleCommands T}
        end
    end
end