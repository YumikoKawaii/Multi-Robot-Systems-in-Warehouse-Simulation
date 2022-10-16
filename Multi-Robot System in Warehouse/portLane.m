classdef portLane < handle

    properties
        entrance
        turnIn
        turnOut
        exit
    end

    methods
        function obj = portLane(entrance, turnIn, turnOut, exit)
            obj = obj@handle();
            obj.entrance = entrance;
            obj.turnIn = turnIn;
            obj.turnOut = turnOut;
            obj.exit = exit;
        end
        
        function e = enteredPort(l,r)
            e = 0;
            if (r.pos(1) == l.entrance(1) && r.pos(2) >= l.entrance(2))
                e = 1;
            end
        end
        
        function w = wentOut(l, r)
            w = 0;
            if r.pos(1) == l.exit(1) && r.pos(2) <= l.exit(2)
                w = 1;
            end
        end

        function dir = getDir(l, r)
            dir = pi/2;
            if r.pos(2) == l.turnIn(2) && r.pos(1) >= l.turnIn(1) && r.pos(1) < l.turnOut(1)
                dir = 0;
            elseif r.pos(1) == l.exit(1) && r.pos(2) > l.exit(2)
                dir = -pi/2;
            end
        end
    end

end