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

    Handlers
in
    fun {StartWindow}
        Stream
        Port = {NewPort Stream}
    in
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
    in
        Layout = td(
            title:"Frequency count"
            lr(
                text(handle:HandleInputText width:28 height:5 background:white foreground:black wrap:word)
                button(text:"Change" action:OnPress)
            )
            text(handle:HandleOutputText width:28 height:5 background:black foreground:white glue:w wrap:word)
            action:proc{$}{Application.exit 0} end % quit app gracefully on window closing
        )

        MainWindow = {QTk.build Layout}
        {MainWindow show}

        {HandleInputText tk(insert 'end' 'xd')}
        {HandleInputText bind(event:"<Control-s>" action:OnPress)} % You can also bind events

        handles(input:HandleInputText output:HandleOutputText)
    end

    % events
    proc {OnPress}
        Inserted
    in
        Inserted = {Handlers.input getText(p(1 0) 'end' $)} % example using coordinates to get text
        {Handlers.output set(1:Inserted)} % you can get/set text this way too
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