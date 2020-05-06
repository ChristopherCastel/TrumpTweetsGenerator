functor
import
    System
    OS
    Browser
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

    fun {PredictNext Word}
        fun {MaxCount L BestWord BestCount}
            case L
                of (Word#Count)|Xr then
                    if Count > BestCount then
                        {MaxCount Xr Word Count}
                    else
                        {MaxCount Xr BestWord BestCount}
                    end
                [] nil then BestWord
            end
        end
    in
        if {Not {Dictionary.member DictionaryWords Word}} then
            null
        else DictionaryCounts Entries in
            {Dictionary.get DictionaryWords Word DictionaryCounts}
            {Dictionary.entries DictionaryCounts Entries}
            {MaxCount Entries null ~1}
        end
    end

    proc {HandleCommands Stream}
        case Stream
            of save(word:Word next:Next)|T then
                % {System.show save({String.toAtom Word} ' ' {String.toAtom Next})}
                {Save {String.toAtom Word} {String.toAtom Next}}
                {HandleCommands T}
            [] predict(word:Word next:Next)|T then
                Next = {PredictNext Word}
                {HandleCommands T}
            [] _|T then
                {System.show error('[Prediction dictionary]' 'Unknown command')}
                {HandleCommands T}
        end
    end
end