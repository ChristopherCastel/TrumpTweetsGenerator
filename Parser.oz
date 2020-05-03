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
                % TODO : send to "save" thread

                thread SanitizedLine = {SanitizeLine Line} end
                thread WordList = {BuildWordList SanitizedLine} end
                thread SentenceList = {BuildSentenceList WordList} end
                for X in SentenceList do
                    {System.show X}
                end
                {System.show '---------------------------------------'}
                end
            end
    in
        thread {ParseStream} end
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
                    {System.show error([BuildWordList] _)}
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

        % builds the list of sentences
        proc {Loop Line Sentence SentenceTail Sentences}
            case Line
                of CurrWord|OtherWords then TailSentences in
                    if {IsEndOfSentence CurrWord} then NextSentence in
                        SentenceTail = nil
                        Sentences = Sentence|TailSentences
                        {Loop OtherWords NextSentence NextSentence TailSentences}
                    else X in
                        CurrWord|X = SentenceTail
                        {Loop OtherWords Sentence X Sentences}
                    end
                [] nil then
                    SentenceTail = nil
                    Sentences = Sentence|nil
                [] _ then
                    {System.show error([BuildSentenceList] _)}
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
    % in

    % end

    % {Regex.groups +MATCH +TXT ?GROUPS}
end