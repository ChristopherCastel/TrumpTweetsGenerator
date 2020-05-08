functor
import
    System
    Browser
    PredictionDictionary
    % Regex at 'x-oz://contrib/regex'
export
    parseStream:ThreadedParseStream
define
    % Functions
    ThreadedParseStream
    SanitizeLine
    ConvertAtomsToStrings
    BuildWordList
    BuildSentenceList
    SentenceToDictionary

    % Global variables
    ToReplace
    ToRemove
    BreakList
    BreakListNumber
in

% ---------------------------------- UTILS ----------------------------------

    % Converts a list of Atoms to a list of Strings
    % flips order
    % ['a', 'b', 'cde'] -> []
    fun {ConvertAtomsToStrings AtomsList}
        fun {Loop AtomsList StringsList}
            case AtomsList
                of AtomTuple|AtomsTail then
                    {Loop AtomsTail {Atom.toString AtomTuple}|StringsList}
                [] nil then StringsList
            end
        end
    in
        {Loop AtomsList nil}
    end

% ---------------------------------- INIT ----------------------------------

    % ToReplace = {ConvertAtomsToStrings [t('&amp;' '&')]}
    ToRemove = {ConvertAtomsToStrings ['']}
    BreakList = ['.' ':' '-' '(' ')' '[' ']' '{' '}' ',' '\'' '!' '?'] % TODO should handle parentheses handling with subfunctions
    BreakListNumber = {List.map BreakList fun {$ X} {Atom.toString X}.1 end}

% ------------------------------ MODULE LOGIC ------------------------------

    proc {ThreadedParseStream Stream PredictionDictionaryPort}
        for Line in Stream do SanitizedLine WordList SentenceList in
            % {System.show {String.toAtom SanitizedLine}}
            thread SanitizedLine = {SanitizeLine Line} end
            thread WordList = {BuildWordList SanitizedLine} end
            thread SentenceList = {BuildSentenceList WordList} end
            for Sentence in SentenceList do
                {SentenceToDictionary Sentence PredictionDictionaryPort}
            end
        end
    end

    proc {SentenceToDictionary Sentence PredictionDictionaryPort}
        proc {Loop Sentence PrevPrevWord PrevWord}
            case Sentence
                of CurrWord|OtherWords then
                    TailSentenceOut
                in
                    if PrevWord \= null then
                        {Send PredictionDictionaryPort save(word:PrevWord next:CurrWord)}
                        if PrevPrevWord \= null then
                            {Send PredictionDictionaryPort save(word:{List.append {List.append PrevPrevWord " "} PrevWord} next:CurrWord)}
                        end
                    end
                    {Loop OtherWords PrevWord CurrWord}
                [] nil then skip
            end
        end
    in
        {Loop Sentence null null}
    end

    fun {BuildWordList Line}
        proc {Loop Line Word WordTail LineOut}
            case Line
                of CurrChar|TailLine then TailLineOut in
                    if {Char.isSpace CurrChar} then
                        NextWord SanitizedWord
                    in
                        SanitizedWord = Word % {Sanitize Word}
                        if SanitizedWord \= null then
                            WordTail = nil
                            LineOut = SanitizedWord|TailLineOut
                        end
                        {Loop TailLine NextWord NextWord TailLineOut}
                    else X in
                        CurrChar|X = WordTail
                        {Loop TailLine Word X LineOut}
                    end
                [] nil then
                    WordTail = nil
                    LineOut = Word|nil
                [] _ then
                    {System.show error('[BuildWordList]' _)}
            end
        end
        Word
        LineOut
    in
        LineOut = {Loop Line Word Word}
    end

    fun {SanitizeLine Line}
        fun {IsISO8859Defined Character}
            (Character >= 32 andthen Character =< 126) orelse (Character >= 160 andthen Character =< 255)
        end
        fun {IsRestrictedISO8859Defined Character}
            (Character >= 32 andthen Character =< 126)
        end
        % "trimming" (2+) spaces between words
        fun {TrimMultiSpaces Line}
            proc {Loop Line PrevChar LineOut}
                case Line
                    of CurrChar|OtherChars then
                        TailLineOut
                    in
                        if {Char.isSpace CurrChar} andthen {Char.isSpace PrevChar} then
                            {Loop OtherChars CurrChar LineOut}
                        else
                            LineOut = CurrChar|TailLineOut
                            {Loop OtherChars CurrChar TailLineOut}
                        end
                    [] nil then
                        LineOut = nil
                end
            end
            LineOut
        in
            LineOut = {Loop Line " ".1}
        end
        RestrictedISO8859Line
    in
        RestrictedISO8859Line = {List.filter Line IsRestrictedISO8859Defined}
        {TrimMultiSpaces RestrictedISO8859Line}
    end

    fun {BuildSentenceList Line}
        % Checks if any character of a word is a 'SentenceBreakSymbol'
        fun {ContainsSentenceBreakSymbol Word}
            {List.some % tests for all BreakSymbols
                BreakListNumber
                fun {$ BreakWord} % a word is fully made of BreakWord
                    {List.some
                        Word
                        fun {$ Char}
                            Char == BreakWord
                        end
                    }
                end
            }
        end
        % Splits a "complex" word (containing 1+ 'SentenceBreakSymbol') into tokens
        % The resulting tokens are used for advanced sentence building
        proc {Split Word ?FirstToken ?TokensWithoutLast ?LastToken}
            proc {Loop Word Token TokenTail TokensWithoutLast}
                case Word
                    of CurrChar|OtherChars then TokensWithoutLastTail in
                        if {List.member CurrChar BreakListNumber} then NextToken in
                            % CurrChar is a sentenceBreakSymbol that "splits" the current token
                            if {IsDet Token} then
                                TokenTail = nil
                                TokensWithoutLast = Token|TokensWithoutLastTail
                                {Loop OtherChars NextToken NextToken TokensWithoutLastTail}
                            else % not currently building a token, skipping sentenceBreakSymbol
                                {Loop OtherChars Token TokenTail TokensWithoutLast}
                            end
                        else X in
                            CurrChar|X = TokenTail
                            {Loop OtherChars Token X TokensWithoutLast}
                        end
                    [] nil then
                        TokenTail = nil
                        TokensWithoutLast = nil
                        if Token \= nil then
                            LastToken = Token
                        else % Token == nil when the word ends with 1+ sentenceBreakSymbol
                            LastToken = nil
                        end
                    [] _ then
                        {System.show error('[BuildSentenceList][Loop]' _)}
                end
            end
        in
            local Token in
                {Loop Word Token Token TokensWithoutLast}
            end
            if {List.member Word.1 BreakListNumber} then
                FirstToken = nil
            else
                FirstToken = TokensWithoutLast.1
            end
        end

        % Receives the current sentence parsing context
        %   -> Sentence SentenceTail Sentences
        % And the new context
        %   -> NewSentence NewSentenceTail NewSentencesTail
        % Might modify the current context to end a sentence
        % Might modify the new context to start a new sentence
        % Is given a complex 'Word' that might:
        %              end the current sentence
        %    AND/OR    start a new sentence
        %    AND/OR    embed other word that are considered as whole sentences (not implemented yet)
        proc {HandleBreakSymbol Word Sentence SentenceTail Sentences NewSentence NewSentenceTail NewSentencesTail}
            FirstToken TokensWithoutLast LastToken
        in
            {Split Word FirstToken TokensWithoutLast LastToken}

            % Should deal with 'TokensWithoutLast' but that make it 2^3 branches..
            % Using a regex would make it easier to manipulate/read
            case FirstToken#LastToken
                of nil#nil then % no tokens -> '...' or '..word..'
                    if {IsDet Sentence} then
                        SentenceTail = nil
                        Sentences = Sentence|NewSentencesTail
                    else
                        Sentences = NewSentencesTail
                    end
                [] F#nil then
                    SentenceTail = FirstToken|nil
                    Sentences = Sentence|NewSentencesTail
                [] nil#L then
                    if {IsDet Sentence} then
                        SentenceTail = nil
                        NewSentence = LastToken|NewSentenceTail
                        Sentences = Sentence|NewSentencesTail
                    else
                        NewSentence = LastToken|NewSentenceTail
                        Sentences = NewSentencesTail
                    end
                [] F#L then
                    SentenceTail = FirstToken|nil
                    NewSentence = LastToken|NewSentenceTail
                    Sentences = Sentence|NewSentencesTail
            end
        end

        % builds the list of sentences
        proc {Loop Line Sentence SentenceTail Sentences}
            case Line
                of CurrWord|OtherWords then
                    % Must deal with words that look like -> "Hello...I..am..happy.."
                    if {ContainsSentenceBreakSymbol CurrWord} then
                        NewSentence NewSentenceTail NewSentencesTail
                    in
                        % might modify: Sentence SentenceTail Sentences
                        % might create: NewSentence NewSentenceTail NewSentencesTail
                        {HandleBreakSymbol
                            CurrWord Sentence SentenceTail Sentences % current
                            NewSentence NewSentenceTail NewSentencesTail} % new
                        if {IsDet NewSentence} then
                            {Loop OtherWords NewSentence NewSentenceTail NewSentencesTail}
                        else FreshSentence in
                            {Loop OtherWords FreshSentence FreshSentence NewSentencesTail}
                        end
                    else X in
                        CurrWord|X = SentenceTail
                        {Loop OtherWords Sentence X Sentences}
                    end
                [] nil then
                    SentenceTail = nil
                    if Sentence == nil then
                        Sentences = nil
                    else
                        Sentences = Sentence|nil
                    end
                [] _ then
                    {System.show error('[BuildSentenceList][Loop]' _)}
            end
        end
        SentencesOut
    in
        local Sentence in
            SentencesOut = {Loop Line Sentence Sentence}
        end
    end

    % unhandled cases:
    %   - the drain....\n....instead of giving -> parsed as two sentences
    %   - contractions (I'm, you're, don't, and so on) are counted as a single word
    %   - single and multiples hyphens are considered as end-of-sentence symbols

    % A word is (\w+|\w+%|\w+'\w+|@\w+|#\w+|\w+´\w+)(\W+)
    % End a of a sentence if $2 in {-+, .+, (?|!)+}
    % fun {ParseLine Line}
    %     ToReplace = [('&amp;' '&')]
    %     ToRemove = ['#' ':' ',' ';']
    %     FinalMark = ['?' '!' '.' '-']

    % {Regex.groups +MATCH +TXT ?GROUPS}
end