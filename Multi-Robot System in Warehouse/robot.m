classdef robot < matlab.mixin.Copyable
    properties 
        index
        pos
        spawn
        package
        shelf
        speed
        battery
        status % leftCStation gotPackage delivered return switch delay
        tempDest                
        delayTime
        outLanes
        shelfLanes
        adjustLanes
        portLanes
        route % shelf port shelf
        curLane% out shelf adjust port
    end

    methods
        function obj = robot(index, pos, speed, outLanes, shelfLanes, adjustLanes, portLanes)
            obj = obj@matlab.mixin.Copyable();            
            obj.index = index;
            obj.spawn = pos;
            obj.pos = pos;
            obj.speed = speed;
            obj.battery = 5;            
            obj.delayTime = 0;
            obj.outLanes = outLanes;
            obj.shelfLanes = shelfLanes;
            obj.adjustLanes = adjustLanes;
            obj.portLanes = portLanes;
            obj.route = [0 0 0];
            obj.curLane = [0 0 0 0];            
            resetStatus(obj);
        end        

        function setRoute(obj, package, shelf)
            resetStatus(obj);
            obj.package = package;
            obj.shelf = shelf;
            if obj.route == [0 0 0]
                obj.route = [(1 + 4*((package(1) - 25)/18)) ((package(1) - 25)/18 + 1) (3 + ((shelf(1) - 25)/18)*4)];
            else
                obj.route = [(obj.curLane(2) - 1) ((package(1) - 25)/18 + 1) (3 + ((shelf(1) - 25)/18)*4)];
                obj.status(1) = 1;
                setSwitchDir(obj,pi,3);
                obj.curLane = obj.curLane - [0 1 0 0];
            end            
        end
        
        function leftCStation(obj)          

            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif obj.pos(2) < (obj.spawn(2) + 3)
                obj.pos = obj.pos + obj.speed*[0;1;0];
                obj.pos(3) = pi/2;
            elseif obj.pos(1) > (18 + floor((obj.index - 1)/10)*36)
                obj.pos = obj.pos - obj.speed*[1;0;0];
                obj.pos(3) = pi;
            elseif (obj.pos(2) < obj.outLanes(1).entrance(2))
                obj.pos = obj.pos + obj.speed*[0;1;0];
                obj.pos(3) = pi/2;
            end
            
            if obj.pos(1) == (18 + floor((obj.index - 1)/10)*36) && obj.pos(2) == obj.outLanes(1).entrance(2)
                obj.status(1) = 1;
                obj.curLane = [1 0 0 0];
            end
        end
        
        function goOutByOutLanes(obj)
            
            curDir = 0;            
            if obj.pos(1) > obj.shelfLanes(obj.route(1)).entrance(1)
                curDir = pi;
            end            

            if curDir ~= obj.outLanes(obj.curLane(1)).dir && obj.status(5) == 0                
                setSwitchDir(obj,pi/2,3);
                obj.curLane = obj.curLane + [1 0 0 0];                
            end
            
            if obj.status(5) == 1
                switchLane(obj);                
            elseif obj.pos(1) ~= obj.shelfLanes(obj.route(1)).entrance(1)
                s = (obj.pos(1) - obj.shelfLanes(obj.route(1)).entrance(1))/abs(obj.pos(1) - obj.shelfLanes(obj.route(1)).entrance(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);                
            elseif obj.shelfLanes(obj.route(1)).entrance(2) - obj.pos(2) >= 3 && obj.status(5) == 0
                setSwitchDir(obj, pi/2, 3)            
                obj.curLane = obj.curLane + [1 0 0 0];
            end
            
            if inLane(obj.shelfLanes(obj.route(1)), obj) == 1
                obj.curLane = [0 obj.route(1) 0 0];
            end

        end

        function goOutByShelfLane(obj)       

            if obj.status(5) == 1
                switchLane(obj)
            else
                obj.pos = obj.pos + obj.speed*[0;1;0];
                obj.pos(3) = pi/2;                                        
            end
            
            if inLane(obj.adjustLanes(1),obj) == 1
                obj.curLane = [0 0 1 0];
            end           

        end

        function goOutByAdjustLane(obj)
            
            curDir = 0;            
            if obj.pos(1) > obj.portLanes(obj.route(2)).entrance(1)
                curDir = pi;
            end            
                     
            if curDir ~= obj.adjustLanes(obj.curLane(3)).dir && obj.status(5) == 0                
                setSwitchDir(obj,pi/2,3);                
                obj.curLane = obj.curLane + [0 0 1 0];
            end

            if obj.status(5) == 1
                switchLane(obj);
            elseif obj.pos(1) ~= obj.portLanes(obj.route(2)).entrance(1)
                s = (obj.pos(1) - obj.portLanes(obj.route(2)).entrance(1))/abs(obj.pos(1) - obj.portLanes(obj.route(2)).entrance(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);
            elseif obj.portLanes(obj.route(2)).entrance(2) - obj.pos(2) >= 3                
                setSwitchDir(obj,pi/2,3);            
                obj.curLane = obj.curLane + [0 0 1 0];
            end
            
            if enteredPort(obj.portLanes(obj.route(2)),obj)
                obj.curLane = [0 0 0 obj.route(2)];
            end

        end

        function moveOnPort(obj)
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;                
            else
                dir = getDir(obj.portLanes(obj.route(2)), obj);
                if dir == pi/2
                    obj.pos = obj.pos + obj.speed*[0;1;0];                
                elseif dir == 0
                    obj.pos = obj.pos + obj.speed*[1;0;0];                
                elseif dir == -pi/2
                    obj.pos = obj.pos - obj.speed*[0;1;0];
                end
                obj.pos(3) = dir;
            end
            if obj.pos(1) == obj.package(1) && obj.pos(2) == obj.package(2) && obj.status(6) == 0
                obj.delayTime = 30;
                obj.status(6) = 1;
            end
            if wentOut(obj.portLanes(obj.route(2)), obj)
                obj.curLane = [0 0 3 0];
                obj.status(2) = 1;
                obj.status(6) = 0;
            end
        end              

        function takePackage(obj)            
            if obj.status(1) == 0
                leftCStation(obj)
            elseif obj.curLane(1) ~= 0                 
                goOutByOutLanes(obj);       
            elseif obj.curLane(2) ~= 0
                goOutByShelfLane(obj);
            elseif obj.curLane(3) ~= 0
                goOutByAdjustLane(obj);
            elseif obj.curLane(4) ~= 0                
                moveOnPort(obj)
            end
        end

        function goThroughAdjustLane(obj)
            
            curDir = 0;            
            if obj.pos(1) > obj.shelfLanes(obj.route(3)).exit(1)
                curDir = pi;
            end            
                     
            if curDir ~= obj.adjustLanes(obj.curLane(3)).dir && obj.status(5) == 0                
                setSwitchDir(obj,-pi/2,3);
                obj.curLane = obj.curLane - [0 0 1 0];                
            end

            if obj.status(5) == 1
                switchLane(obj)
            elseif abs(obj.pos(1) - obj.shelfLanes(obj.route(3)).exit(1)) > 0.0001
                s = (obj.pos(1) - obj.shelfLanes(obj.route(3)).exit(1))/abs(obj.pos(1) - obj.shelfLanes(obj.route(3)).exit(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);
            elseif abs(obj.pos(2) - obj.shelfLanes(obj.route(3)).exit(1)) >= 3                
                setSwitchDir(obj,-pi/2,3);        
                obj.curLane = obj.curLane - [0 0 1 0];
            end
            
            if inLane(obj.shelfLanes(obj.route(3)), obj) == 1
                obj.curLane = [0 obj.route(3) 0 0];
            end

        end

        function putPackageOnShelf(obj)
            
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif obj.status(5) == 1
                switchLane(obj);
            elseif obj.pos(2) > obj.shelf(2)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            elseif obj.pos(1) > obj.shelf(1)
                obj.pos = obj.pos - obj.speed*[1;0;0];
                obj.pos(3) = pi;            
            end

            if obj.pos(1) == obj.shelf(1) && obj.pos(2) == obj.shelf(2) && obj.status(6) == 0
                setSwitchDir(obj,pi,3);                
                obj.delayTime = 30;
                obj.status(6) = 1;                
            end

            if obj.delayTime == 0 && obj.status(6) == 1 && obj.status(5) == 0
                obj.status(6) = 0;
                obj.status(3) = 1;                                
                obj.curLane = obj.curLane - [0 1 0 0];
                obj.battery = obj.battery - 1;
            end

        end

        function deliveryPackage(obj)
            if obj.curLane(3) ~= 0
                goThroughAdjustLane(obj);
            elseif obj.curLane(2) ~= (obj.route(3) - 1)
                putPackageOnShelf(obj);
            end
        end
        
        function goBackOutLane(obj)
            if obj.pos(2) > obj.outLanes(4).entrance(2)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            end
            if inLane(obj.outLanes(4), obj) == 1
                obj.curLane = [4 0 0 0];                
            end
        end

        function goThroughOutLane(obj)
            curDir = 0;                 
            if obj.pos(1) > (50 + floor((obj.index - 1)/10)*36)
                curDir = pi;
            end            

            if curDir ~= obj.outLanes(obj.curLane(1)).dir && obj.status(5) == 0                
                setSwitchDir(obj,-pi/2,3);                
                obj.curLane = obj.curLane - [1 0 0 0];
            end

            if obj.status(5) == 1
                switchLane(obj);                
            elseif obj.pos(1) ~= (50 + floor((obj.index - 1)/10)*36)
                s = (obj.pos(1) - (50 + floor((obj.index - 1)/10)*36))/abs(obj.pos(1) - (50 + floor((obj.index - 1)/10)*36));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);                
            elseif obj.pos(2) >= obj.outLanes(1).entrance(2)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            end
            
            if obj.pos(2) < obj.outLanes(1).entrance(2)
                obj.curLane = [0 0 0 0];
            end

        end
        
        function toSpawn(obj)
            if obj.pos(2) > (obj.spawn(2) + 3)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            elseif obj.pos(1) > obj.spawn(1)
                obj.pos = obj.pos - obj.speed*[1;0;0];
                obj.pos(3) = pi;
            elseif obj.pos(2) > obj.spawn(2)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            end
            
            if obj.pos(1) == obj.spawn(1) && obj.pos(2) == obj.spawn(2)
                obj.status(4) = 0;
                obj.delayTime = (5 - obj.battery)*10;
                obj.battery = 5;
                obj.pos(3) = pi/2;
                obj.route = [0 0 0];
                resetStatus(obj);
            end

        end

        function returnCStation(obj)
            if obj.curLane(2) ~= 0
                goBackOutLane(obj);
            elseif obj.curLane(1) ~= 0
                goThroughOutLane(obj);            
            elseif obj.status(4) == 1 || obj.battery == 0
                toSpawn(obj);
            end
        end
        
        function selfControl(obj)
            if obj.status(4) == 1 || obj.battery == 0
                returnCStation(obj);
            elseif obj.status(2) == 0 && obj.route(1) ~= 0
                takePackage(obj);
            elseif obj.status(3) == 0 && obj.route(1) ~= 0
                deliveryPackage(obj);                                    
            end                        
        end
           
        function switchLane(obj)
            if abs(obj.pos(1) - obj.tempDest(1)) > 0.0001
                s = (obj.pos(1) - obj.tempDest(1))/abs(obj.pos(1) - obj.tempDest(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);
            elseif abs(obj.pos(2) - obj.tempDest(2)) > 0.0001
                s = (obj.pos(2) - obj.tempDest(2))/abs(obj.pos(2) - obj.tempDest(2));
                obj.pos = obj.pos - obj.speed*s*[0;1;0];
                obj.pos(3) = -s*pi/2;
            end
            if abs(obj.pos(1) - obj.tempDest(1)) < 0.0001 && abs(obj.pos(2) - obj.tempDest(2)) < 0.0001
                obj.status(5) = 0;
            end
        end
            
        function setSwitchDir(obj, dir, dis)            
            if dir == 0
                obj.tempDest = obj.pos + [dis;0;0];
            elseif dir == pi
                obj.tempDest = obj.pos + [-dis;0;0];
            elseif dir == pi/2
                obj.tempDest = obj.pos + [0;dis;0];
            elseif dir == -pi/2
                obj.tempDest = obj.pos + [0;-dis;0];
            end
            obj.status(5) = 1;
        end
                   
        function resetStatus(obj)
            obj.status = [0 0 0 0 0 0];
        end           

    end
end