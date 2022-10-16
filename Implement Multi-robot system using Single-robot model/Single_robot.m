classdef Single_robot < matlab.mixin.Copyable
    properties
        index
        spawn
        pos
        package % [x y]        
        dest
        status %left gotPackage delivered leaveShelf returned corrputed
        speed
        delayTime        
        battery
    end

    methods
        
        function obj = Single_robot(i, spn, sp)
            obj = obj@matlab.mixin.Copyable();
            obj.index = i;
            obj.spawn = spn;
            obj.pos = spn;
            obj.package = [0 0];
            obj.speed = sp;            
            obj.battery = 5;
            resetStatus(obj);
        end
        
        function setInfo(obj, pck,dst)
            obj.package = pck;
            obj.dest = dst;
            if abs(pck(1) - dst(1)) < 2
                obj.status(6) = 1;
            end
        end

        function leaveChargingStation(obj)            
            s = 0;
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
                s = 1;
            elseif obj.pos(2) <= 31
                obj.pos = obj.pos + obj.speed*[0;1;0];
                obj.pos(3) = pi/2;
                s = 1;                    
            elseif obj.pos(1) > (18 + floor((obj.index - 1)/10)*36)
                obj.pos = obj.pos - obj.speed*[1;0;0];
                obj.pos(3) = pi;
                s = 1;
            end
            if s == 0
                obj.status(1) = 1;
            end
        end        

        function getPackage(obj)                           
            if abs(obj.pos(2) - obj.package(2)) > 5
                s = (obj.pos(2) - obj.package(2))/abs(obj.pos(2) - obj.package(2));
                obj.pos = obj.pos - obj.speed*s*[0;1;0];
                obj.pos(3) = -s*(pi/2);                
            elseif abs(obj.pos(1) - obj.package(1)) >= 0.0001
                s = (obj.pos(1) - obj.package(1))/abs(obj.pos(1) - obj.package(1));                                
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);                               
            elseif abs(obj.pos(2) - obj.package(2)) <= 5
                s = (obj.pos(2) - obj.package(2))/abs(obj.pos(2) - obj.package(2));
                obj.pos = obj.pos - obj.speed*s*[0;1;0];
                obj.pos(3) = -s*(pi/2);                
            end            
           if abs(obj.pos(1) - obj.package(1)) <= 0.0001 && abs(obj.pos(2) - obj.package(2)) <= 0.0001
                obj.status(2) = 1;
                obj.delayTime = 30;
            end
        end

        function deliveryPackage(obj)          
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;              
            elseif abs(obj.pos(1) - obj.dest(1)) > 3
                s = (obj.pos(1) - obj.dest(1))/abs(obj.pos(1) - obj.dest(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);                            
            elseif abs(obj.pos(2) - obj.dest(2)) >= 0.0001 
                s = (obj.pos(2) - obj.dest(2))/abs(obj.pos(2) - obj.dest(2));
                obj.pos = obj.pos - obj.speed*s*[0;1;0];
                obj.pos(3) = (pi/2)*(-s);                                        
            elseif abs(obj.pos(1) - obj.dest(1)) <= 3
                s = (obj.pos(1) - obj.dest(1))/abs(obj.pos(1) - obj.dest(1));
                obj.pos = obj.pos - obj.speed*s*[1;0;0];
                obj.pos(3) = (pi/2)*(1 + s);                
            end
            if obj.pos(1) == obj.dest(1) && obj.pos(2) == obj.dest(2)
                obj.status(3) = 1;         
                obj.status(4) = 1;
                disp("hehe");
                obj.delayTime = 30;                
                obj.battery = obj.battery - 1;
            end
        end
        
        function leaveShelf(obj)            
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif abs(obj.pos(1) - obj.dest(1)) <= 3
                obj.pos = obj.pos + obj.speed*[1;0;0];
                obj.pos(3) = 0;
            else
                disp("check");
                obj.status(4) = 0; 
            end
        end
        
        function avoidCorrupt(obj)
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif abs(obj.pos(1) - obj.dest(1)) <= 3
                obj.pos = obj.pos + obj.speed*[1;0;0];
                obj.pos(3) = 0;
            else
                obj.status(6) = 0; 
            end
        end

        function returnChargingStation(obj)    

            if obj.pos(2) > (obj.spawn(2) + 15)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            elseif obj.pos(1) > obj.spawn(1)
                obj.pos = obj.pos - obj.speed*[1;0;0];
                obj.pos(3) = pi;
            elseif obj.pos(2) > obj.spawn(2)
                obj.pos = obj.pos - obj.speed*[0;1;0];
                obj.pos(3) = -pi/2;
            end

            if abs(obj.pos(1) - obj.spawn(1)) <= 0.0001 && abs(obj.pos(2) - obj.spawn(2)) <= 0.0001
                obj.status(5) = 1;                                
                obj.delayTime = (5 - obj.battery)*10;
                obj.battery = 5;
                obj.pos(3) = pi/2;                
                resetStatus(obj);
            end
        end
        
        function active(obj)
            if obj.status(1) == 0
                leaveChargingStation(obj)
            elseif obj.status(2) == 0
                 getPackage(obj)
            elseif obj.status(6) == 1
                 avoidCorrupt(obj);
            elseif obj.status(3) == 0
                 deliveryPackage(obj)            
            end                               
        end

        function selfMove(obj)
            if obj.status(4) == 1
                disp(1);
                leaveShelf(obj);
            elseif obj.status(5) == 1 || obj.battery == 0
                returnChargingStation(obj);
            elseif obj.status(4) == 0
                active(obj);
            end
                                                
        end                

        function resetStatus(obj)
            obj.status = [0 0 0 0 0 0];
        end             

    end
end