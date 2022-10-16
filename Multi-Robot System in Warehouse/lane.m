classdef lane < handle
    
    properties
        entrance
        exit
        dir
    end

    methods
        function obj = lane(entrance, exit, dir)            
            obj = obj@handle();            
            obj.entrance = entrance;
            obj.exit = exit;
            obj.dir = dir;
        end        

        function i = inLane(l, r)
            i = 0;
            if r.pos(1) >= l.entrance(1) && r.pos(1) <= l.exit(1) && r.pos(2) >= l.entrance(2) && r.pos(2) <= l.exit(2) 
               i = 1; 
            end            
        end

    end
end