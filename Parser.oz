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
    PredictionDictionaryPort
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
    PredictionDictionaryPort = {PredictionDictionary.createDictionary}
    BreakList = ['.' ':' '-' '(' ')' '[' ']' '{' '}' ',' '\'' '!' '?'] % TODO should handle parentheses handling with subfunctions
    BreakListNumber = {List.map BreakList fun {$ X} {Atom.toString X}.1 end}

% ------------------------------ MODULE LOGIC ------------------------------

    proc {ThreadedParseStream Stream }
        proc {ParseStream}
            for Line in Stream do SanitizedLine WordList SentenceList in
                % {System.show {String.toAtom SanitizedLine}}
                thread SanitizedLine = {SanitizeLine Line} end
                thread WordList = {BuildWordList SanitizedLine} end
                thread SentenceList = {BuildSentenceList WordList} end
                {Browser.browse SentenceList}
                for S in SentenceList do
                    {System.show debug('SentenceList' 'NewSentence')}
                    for W in S do
                        {System.show debug('SentenceList' {String.toAtom W})}
                    end
                end
                % for Sentence in SentenceList do
                %     {SentenceToDictionary Sentence}
                % end
            end
        end
    in
        thread {ParseStream} end
    end

    proc {SentenceToDictionary Sentence}
        proc {Loop Sentence PrevWord}
            case Sentence
                of CurrWord|OtherWords then
                    TailSentenceOut
                in
                    if PrevWord \= null then
                        {Send PredictionDictionaryPort save(word:PrevWord next:CurrWord)}
                    end
                    {Loop OtherWords CurrWord}
                [] nil then skip
            end
        end
    in
        {Loop Sentence null}
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
        % determines whether a word marks the end the sentence
        fun {IsEndOfSentence Word}
            {List.member {List.last Word} BreakListNumber}
        end
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
        fun {Split Word}
            proc {Loop Word Token TokenTail Tokens}
                case Word
                    of CurrChar|OtherChars then TailTokens in
                        if {List.member CurrChar BreakListNumber} then NextToken in
                            if {IsDet Token} then
                                TokenTail = nil
                                Tokens = Token|TailTokens
                                {Loop OtherChars NextToken NextToken TailTokens}
                            else
                                {Loop OtherChars Token TokenTail Tokens}
                            end
                        else X in
                            CurrChar|X = TokenTail
                            {Loop OtherChars Token X Tokens}
                        end
                    [] nil then
                        TokenTail = nil
                        if Token \= nil then % in the case "bon..." -> ["bon" nil]
                            Tokens = Token|nil
                        else
                            Tokens = nil
                        end
                    [] _ then
                        {System.show error('[BuildSentenceList][Loop]' _)}
                end
            end
            Tokens
        in
            local Token in
                Tokens = {Loop Word Token Token}
            end
        end
        % builds the list of sentences
        proc {Loop Line Sentence SentenceTail Sentences}
            case Line
                of CurrWord|OtherWords then TailSentences in
                    % Must deal with words that look like -> "Hello...I..am..happy.."
                    % "Hello" is the end of the current sentence
                    % Splitting the word -> [[Hello][I][am][happy]] (each token is a sentence)
                    if {ContainsSentenceBreakSymbol CurrWord} then Tokens NextSentence in
                        Tokens = {Split CurrWord}
                        {System.show d(word {String.toAtom CurrWord})}
                        for T in Tokens do
                            {System.show d(tokens {String.toAtom T})}
                        end
                        if Tokens \= nil then % no tokens -> split of "..."
                            SentenceTail = Tokens.1|nil
                            Sentences = {List.append Sentence Tokens.2}|TailSentences
                        else
                            {Loop OtherWords Sentence SentenceTail Sentences}
                        end
                        {Loop OtherWords NextSentence NextSentence TailSentences}
                    else X in
                        CurrWord|X = SentenceTail
                        {Loop OtherWords Sentence X Sentences}
                    end
                [] nil then
                    SentenceTail = nil
                    Sentences = Sentence|nil
                [] _ then
                    {System.show error('[BuildSentenceList][Loop]' _)}
            end
        end
        Sentence
        Sentences
    in
        Sentences = {Loop Line Sentence Sentence}
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