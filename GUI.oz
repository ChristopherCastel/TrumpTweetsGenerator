functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    Application
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
        HandlePred1gLabel
        HandlePred2gLabel
        Handle1GramButtons
        Handle2GramButtons
    in
        Layout = td(
            title:"Fake Trump tweet GEn3r4t0r"
            td(
                padx:1
                pady:1
                lr(
                    padx:10
                    pady:10
                    td(
                        label(text:"Start of sentence" glue:we)
                        text(handle:HandleInputText width:20 height:1 background:white foreground:black wrap:word glue:we)
                    )
                    button(text:"START" action:OnPress glue:ns padx:5)
                )
                td(
                    padx:10
                    pady:10
                    lr(
                        label(handle:HandlePred1gLabel glue:ns)
                        placeholder(
                            handle:Handle1GramButtons
                            glue:nswe
                        )
                        glue:nswe
                    )
                    lr(
                        label(handle:HandlePred2gLabel glue:ns)
                        placeholder(
                            handle:Handle2GramButtons
                            glue:nswe
                        )
                        glue:nswe
                    )
                    glue:nswe
                )
                text(
                    init:"Waiting for a prediction.." handle:HandleOutputText width:100 height:10 background:black foreground:white wrap:word glue:nswe
                )
                glue:nswe
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
            pred1gLabel:HandlePred1gLabel
            pred2gLabel:HandlePred2gLabel
        )
    end

    proc {GenerateButtons PredictedWords Gram}
        Container
        fun {FillContainer Words CurrContainer}
            case Words
                of Word|OtherWords then
                    NewContainer
                    WordString = {Atom.toString Word}
                    Input2gram = {List.append {List.append @PreviousWord " "} WordString}
                    proc {OnPress}
                        PredictedWords1Gram
                        PredictedWords2Gram
                        OutputBefore
                        OutputAfter
                    in
                        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom WordString} predictedWords:PredictedWords1Gram)}
                        {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom Input2gram} predictedWords:PredictedWords2Gram)}
                        {Handlers.output get(1:OutputBefore)}
                        OutputAfter = OutputBefore#" "#Word
                        {Handlers.output set(
                            1:OutputAfter
                        )}
                        PreviousWord := WordString
                        {GenerateButtons PredictedWords1Gram 1}
                        {GenerateButtons PredictedWords2Gram 2}
                    end
                in
                    NewContainer = {Tuple.append
                        CurrContainer
                        lr(button(text:WordString action:OnPress ipadx:5 ipady:5 glue:nswe))
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
                    label(init:"No prediction found :/")
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
                    label(init:"No prediction found :/")
                )}
            end
        end
    end

    % events
    proc {OnPress}
        InsertedString
        TrimmedInsertedString
    in
        InsertedString = {Handlers.input getText(p(1 0) 'end' $)}
        {String.token InsertedString &\n TrimmedInsertedString _}

        local
            Words = {String.tokens TrimmedInsertedString " ".1}
            Length = {List.length Words}
            IsInputValid
        in
            case Length
                of 1 then PredictedWords in
                    IsInputValid = true
                    {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom TrimmedInsertedString} predictedWords:PredictedWords)}
                    PreviousWord := TrimmedInsertedString
                    {Handlers.output set(
                        1:TrimmedInsertedString
                    )}
                    {GenerateButtons PredictedWords 1}
                    {GenerateButtons PredictedWords 2}
                [] 2 then OutputText PredictedWords1gram PredictedWords2gram in
                    IsInputValid = true
                    OutputText = {List.append {List.append Words.1 " "} Words.2.1}
                    {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom Words.1} predictedWords:PredictedWords1gram)}
                    {Send PredictionDictionaryPort predict(range:PredictionRange word:{String.toAtom OutputText} predictedWords:PredictedWords2gram)}
                    PreviousWord := Words.2.1
                    {Handlers.output set(
                        1:OutputText
                    )}
                    {GenerateButtons PredictedWords1gram 1}
                    {GenerateButtons PredictedWords2gram 2}
                else
                    IsInputValid = false
            end
            if IsInputValid then
                {Handlers.pred1gLabel set(1:"(1 gram)")}
                {Handlers.pred2gLabel set(1:"(2 gram)")}
            else
                {Handlers.output set(1:"Enter either 1 or 2 words please")}
            end
        end
    end
end