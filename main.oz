functor
import
    System
    Reader
    GUI
define
    Show = System.show % macro definition

    GUIPort = {GUI.startWindow}
    {Show GUIPort}
    {Send GUIPort 'buildWindow'}
end
