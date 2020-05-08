functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
    Browser
export
    startWindow:StartWindow
define
    StartWindow
    BuildWindow
    GenerateButtons

    OnPress

    PredictionRange = 10
    Handlers
    PredictionDictionaryPort
    PreviousWord = {NewCell null}
in
    proc {StartWindow DictionaryPort}
        PredictionDictionaryPort = DictionaryPort
        Handlers = {BuildWindow}
    end

    fun {BuildWindow}
        % components
        MainWindow
        Layout

        % handlers
        HandleInputText
        HandleOutputText
        Handle1GramButtons
        Handle2GramButtons
    in
        Layout = td(
            title:"Frequency count"
            lr(
                glue:nswe
                text(handle:HandleInputText width:28 height:5 background:white foreground:black glue:nswe wrap:word)
                button(text:"Predict next" action:OnPress glue:nswe)
            )
            text(
                handle:HandleOutputText width:28 height:5 background:black foreground:white glue:nswe wrap:word
            )
            placeholder(
                glue:nswe
                handle:Handle1GramButtons
            )
            placeholder(
                glue:nswe
                handle:Handle2GramButtons
            )
            action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
        )

        MainWindow = {QTk.build Layout}
        {MainWindow show}

        {HandleInputText bind(event:"<Control-s>" action:OnPress)} % You can also bind events

        handlers(
            input:HandleInputText
            output:HandleOutputText
            prediction1GramButtons:Handle1GramButtons
            prediction2GramButtons:Handle2GramButtons
        )
    end

    % add occurences next to word (button) ?
    proc {GenerateButtons PredictedWords Gram}
        Container
        fun {FillContainer Words CurrContainer}
            case Words
                of Word|OtherWords then
                    NewContainer
                    WordString = {Atom.toString Word}
                    proc {OnPress}
                        PredictedWords1Gram
                        PredictedWords2Gram
                        OutputBefore
                        OutputAfter
                    in
                        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom WordString} predictedWords:PredictedWords1Gram)}
                        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom {List.append {List.append @PreviousWord " "} WordString}} predictedWords:PredictedWords2Gram)}
                        {Handlers.output get(1:OutputBefore)}
                        OutputAfter = OutputBefore#" "#Word
                        {Handlers.output set(
                            1:OutputAfter
                        )}
                        PreviousWord := {List.last {String.tokens WordString " ".1}}
                        {GenerateButtons PredictedWords1Gram 1}
                        {GenerateButtons PredictedWords2Gram 2}
                    end
                in
                    NewContainer = {Tuple.append
                        CurrContainer
                        lr(button(text:WordString action:OnPress glue:nswe))
                    }
                    {FillContainer OtherWords NewContainer}
                [] nil then CurrContainer
            end
        end
    in
        if Gram == 1 then
            if PredictedWords \= null then
                Container = {FillContainer PredictedWords lr()}
                {Handlers.prediction1GramButtons set(
                    Container
                )}
            else
                {Handlers.prediction1GramButtons set(
                    label(init:"1G No prediction found :/")
                )}
            end
        else
            if PredictedWords \= null then
                Container = {FillContainer PredictedWords lr()}
                {Handlers.prediction2GramButtons set(
                    Container
                )}
            else
                {Handlers.prediction2GramButtons set(
                    label(init:"2G No prediction found :/")
                )}
            end
        end
    end

    % events
    proc {OnPress}
        Inserted
        TrimmedInserted
        PredictedWords
    in
        Inserted = {Handlers.input getText(p(1 0) 'end' $)}
        {String.token Inserted &\n TrimmedInserted _}
        {Handlers.output set(
            1:TrimmedInserted
        )}
        PreviousWord := {List.last {String.tokens TrimmedInserted " ".1}}
        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom TrimmedInserted} predictedWords:PredictedWords)}
        % {Handlers.output set(1:PredictedWords.1)} % TODO: upgrade to buttons
        {GenerateButtons PredictedWords 1}
        {GenerateButtons PredictedWords 2}
    end
end