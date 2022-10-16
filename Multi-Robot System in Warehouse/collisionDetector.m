classdef collisionDetector < handle
    properties
        map
    end

    methods
        function obj = collisionDetector(m, n, robots, num)
            obj = obj@handle();
            obj.map(1:m,1:n) = 0;
            for i = 1:num
                fill(obj,robots(i).pos(1),robots(i).pos(2),1);
            end
        end
        
        function fill(obj, x, y, value)
            for i = x-1:x+1
                for j = y-1:y+1
                    obj.map(i,j) = value;
                end
            end
        end        

        function c = checkCollision(obj, x, y)
            c = 1;
            for i = x-1:x+1
                for j = y-1:y+1
                    if obj.map(i,j) == 1
                        c = 0;
                        return;
                    end
                end
            end
        end

    end

end