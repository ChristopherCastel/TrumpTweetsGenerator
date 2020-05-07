functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
export
    startWindow:StartWindow
define
    StartWindow
    BuildWindow
    HandleCommands

    OnPress

    PredictionRange = 3
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
                text(handle:HandleInputText width:28 height:5 background:white foreground:black wrap:word)
                button(text:"Predict next" action:OnPress)
            )
            text(handle:HandleOutputText width:28 height:5 background:black foreground:white glue:w wrap:word)
            lr(
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
        )
    end

    % events
    proc {OnPress}
        Inserted
        TrimmedInserted
        PredictedWords
    in
        Inserted = {Handlers.input getText(p(1 0) 'end' $)}
        {String.token Inserted &\n TrimmedInserted _}
        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom TrimmedInserted} predictedWords:PredictedWords)}
        {Handlers.output set(1:PredictedWords.1)} % TODO: upgrade to buttons
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