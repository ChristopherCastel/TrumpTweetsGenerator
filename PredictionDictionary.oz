functor
import
    System
    OS
export
    createDictionary:CreateDictionary
define
    CreateDictionary
    HandleCommands
in
    fun {CreateDictionary}
        Stream
        Port = {NewPort Stream}
    in
        thread {HandleCommands Stream} end
        Port
    end

    proc {HandleCommands Stream}
        case Stream
            of save(word:Word next:Next)|T then
                % {System.show save(word:{String.toAtom Word} next:{String.toAtom Next})}
                {System.show save({String.toAtom Word} ' ' {String.toAtom Next})}
                {HandleCommands T}
            [] _|T then
                {System.show error('[Prediction dictionary]' 'Unknown command')}
                {HandleCommands T}
        end
    end
end