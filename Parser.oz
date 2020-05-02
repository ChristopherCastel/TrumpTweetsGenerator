functor
import
    System
    Browser
    % Regex at 'x-oz://contrib/regex'
export
    parseStream:ThreadedParseStream
define
    ThreadedParseStream
    Sanitize
    ConvertAtomsToStrings
    BuildWorldList
    ToReplace
    ToRemove
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

% ------------------------------ MODULE LOGIC ------------------------------

    proc {ThreadedParseStream Stream}
        proc {ParseStream}
            for Line in Stream do SanitizedLine in
                SanitizedLine = {Sanitize Line}
                % {System.show {String.toAtom SanitizedLine}}
                % TODO : send to "save" thread
            end
        end
    in
        thread {ParseStream} end
    end

    fun {BuildWorldList Line}
        proc {Loop Line Word WordTail LineOut}
            case Line
                of CurrChar|TailLine then TailLineOut in
                    if {Char.isSpace CurrChar} then
                        NewWord
                    in
                        WordTail = nil
                        LineOut = Word|TailLineOut
                        {Loop TailLine NewWord NewWord TailLineOut}
                    else X in
                        {Char.toLower CurrChar}|X = WordTail
                        {Loop TailLine Word X LineOut}
                    end
                [] nil then
                    WordTail = nil
                    LineOut = Word|nil
                [] _ then
                    {System.show error([BuildWorldList] _)}
            end
        end
        Word
        LineOut
    in
        LineOut = {Loop Line Word Word}
    end

    fun {Sanitize Line}
        proc {SpaceFilter Char}
            {Char.isSpace Char}
        end
        WordList = {List.partition Line Char.isSpace _}
    in
        WordList
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