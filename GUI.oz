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
    HandleCommands

    OnPress

    PredictionRange = 10
    Handlers
    PredictionDictionaryPort
in
    fun {StartWindow DictionaryPort}
        Stream
        Port = {NewPort Stream}
    in
        PredictionDictionaryPort = DictionaryPort
        Handlers = {BuildWindow}
        thread {HandleCommands Stream} end
        Port
    end

    fun {BuildWindow}
        % components
        MainWindow
        Layout

        % handlers
        HandleInputText
        HandleOutputText
        HandlePredictionButtons
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
                handle:HandlePredictionButtons
            )
            action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
        )

        MainWindow = {QTk.build Layout}
        {MainWindow show}

        {HandleInputText bind(event:"<Control-s>" action:OnPress)} % You can also bind events

        handlers(
            input:HandleInputText
            output:HandleOutputText
            predictionButtons:HandlePredictionButtons
        )
    end

    % add occurences next to word (button) ?
    proc {GenerateButtons PredictedWords}
        Container
        fun {FillContainer Words CurrContainer}
            case Words
                of Word|OtherWords then
                    NewContainer
                    WordAtom = {Atom.toString Word}
                    proc {OnPress}
                        PredictedWords
                        OutputBefore
                        OutputAfter
                    in
                        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom WordAtom} predictedWords:PredictedWords)}
                        {Handlers.output get(1:OutputBefore)}
                        OutputAfter = OutputBefore#" "#Word
                        {Handlers.output set(
                            1:OutputAfter
                        )}
                        {GenerateButtons PredictedWords}
                    end
                in
                    NewContainer = {Tuple.append
                        CurrContainer
                        lr(button(text:WordAtom action:OnPress glue:nswe))
                    }
                    {FillContainer OtherWords NewContainer}
                [] nil then CurrContainer
            end
        end
    in
        if PredictedWords \= null then
            Container = {FillContainer PredictedWords lr()}
            {Handlers.predictionButtons set(
                Container
            )}
        else
            {Handlers.predictionButtons set(
                label(init:"No prediction found :/")
            )}
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
        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom TrimmedInserted} predictedWords:PredictedWords)}
        % {Handlers.output set(1:PredictedWords.1)} % TODO: upgrade to buttons
        {GenerateButtons PredictedWords}
    end

    proc {HandleCommands Stream}
        case Stream
            of lol|T then
                {HandleCommands T}
            [] _|T then
                {System.show error('[GUI]' 'Unknown command')}
                {HandleCommands T}
        end
    end
end