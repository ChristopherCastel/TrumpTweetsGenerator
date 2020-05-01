functor
import
    % ...
export
    parseStream:ThreadedParseStream
define
    ThreadedParseStream
    Sanitize
in
    fun {ThreadedParseStream Stream}
        proc {ParseStream}
            for Line in Stream do SanitizedLine in
                SanitizedLine = {Sanitize Line}
            end
        end
    in
        thread {ParseStream} end
    end

    % unhandled cases:
    %   - the drain....\n....instead of giving -> parsed as two sentences
    %   - contractions (I'm, you're, don't, and so on) are counted as a single word
    %   - single and multiples hyphens are considered as end-of-sentence symbols

    % A word is (\w+|\w+%|\w+'\w+|@\w+|#\w+|\w+´\w+)(\W+)
    % End a of a sentence if $2 in {-+, .+, (?|!)+}
    fun {Sanitize Line}
        ToReplace = [('&amp;' '&')]
        ToRemove = ['#' ':' ',' ';']
        FinalMark = ['?' '!' '.' '-']
    in

    end
end