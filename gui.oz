functor
import
    QTk at 'x-oz://system/wp/QTk.ozf'
    System
    Application
    OS
export
    startWindow:StartWindow
define
    fun {StartWindow}
        Stream
        Port = {NewPort Stream}
    in
        thread {HandleCommands Stream} end
        Port
    end

    proc {BuildWindow}
        % components
        MainWindow
        Layout

        % handlers
        HandleInputText
        HandleOutputText

        % events
        proc {OnPress}
            Inserted
        in
            Inserted = {HandleInputText getText(p(1 0) 'end' $)} % example using coordinates to get text
            {HandleOutputText set(1:Inserted)} % you can get/set text this way too
        end
    in
        Layout = td(
            title: "Frequency count"
            lr(
                text(handle:HandleInputText width:28 height:5 background:white foreground:black wrap:word)
                button(text:"Change" action:OnPress)
            )
            text(handle:HandleOutputText width:28 height:5 background:black foreground:white glue:w wrap:word)
            action: proc{$}{Application.exit 0} end % quit app gracefully on window closing
        )

        MainWindow = {QTk.build Layout}
        {MainWindow show}

        {HandleInputText tk(insert 'end' 'xd')}
        {HandleInputText bind(event:"<Control-s>" action:OnPress)} % You can also bind events
    end

    proc {HandleCommands Stream}
        case Stream
            of buildWindow|T then
                {BuildWindow}
                {HandleCommands T}
            [] _|T then
                {System.show error('[GUI]' 'Unknown command')}
                {HandleCommands T}
        end
    end
end