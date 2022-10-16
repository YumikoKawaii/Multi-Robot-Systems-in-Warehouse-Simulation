classdef robot_Single < handle
    properties        
        spawn
        package % [x y]
        pose
        dest
        status %left gotPackage delivered leftShelf returned corrputed
        speed
        delayTime
        delivered
        battery
    end

    methods
        
        function initial(obj, spn, pos, sp)
            obj.spawn = spn;
            obj.pose = pos;
            obj.speed = sp;
            obj.delivered = 0;
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
            elseif obj.pose(2) <= 12
                obj.pose = obj.pose + obj.speed*[0 1 0];
                obj.pose(3) = pi/2;
                s = 1;                       
            end
            if s == 0
                obj.status(1) = 1;
            end
        end        

        function getPackage(obj)               
            if abs(obj.pose(2) - obj.package(2)) > 5
                s = (obj.pose(2) - obj.package(2))/abs(obj.pose(2) - obj.package(2));
                obj.pose = obj.pose - obj.speed*s*[0 1 0];
                obj.pose(3) = -s*(pi/2);                
            elseif abs(obj.pose(1) - obj.package(1)) >= 0.0001
                s = (obj.pose(1) - obj.package(1))/abs(obj.pose(1) - obj.package(1));                                
                obj.pose = obj.pose - obj.speed*s*[1 0 0];
                obj.pose(3) = (pi/2)*(1 + s);                               
            elseif abs(obj.pose(2) - obj.package(2)) <= 5
                s = (obj.pose(2) - obj.package(2))/abs(obj.pose(2) - obj.package(2));
                obj.pose = obj.pose - obj.speed*s*[0 1 0];
                obj.pose(3) = -s*(pi/2);                
            end            
           if abs(obj.pose(1) - obj.package(1)) <= 0.0001 && abs(obj.pose(2) - obj.package(2)) <= 0.0001
                obj.status(2) = 1;
                obj.delayTime = 500;
            end
        end

        function deliveryPackage(obj)          
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;              
            elseif abs(obj.pose(1) - obj.dest(1)) > 3
                s = (obj.pose(1) - obj.dest(1))/abs(obj.pose(1) - obj.dest(1));
                obj.pose = obj.pose - obj.speed*s*[1 0 0];
                obj.pose(3) = (pi/2)*(1 + s);                            
            elseif abs(obj.pose(2) - obj.dest(2)) >= 0.0001 
                s = (obj.pose(2) - obj.dest(2))/abs(obj.pose(2) - obj.dest(2));
                obj.pose = obj.pose - obj.speed*s*[0 1 0];
                obj.pose(3) = (pi/2)*(-s);                                        
            elseif abs(obj.pose(1) - obj.dest(1)) <= 3
                s = (obj.pose(1) - obj.dest(1))/abs(obj.pose(1) - obj.dest(1));
                obj.pose = obj.pose - obj.speed*s*[1 0 0];
                obj.pose(3) = (pi/2)*(1 + s);                
            end
            if abs(obj.pose(1) - obj.dest(1)) <= 0.0001 && abs(obj.pose(2) - obj.dest(2)) <= 0.0001
                obj.status(3) = 1;
                obj.delayTime = 500;
                obj.delivered = obj.delivered + 1;    
                obj.battery = obj.battery - 1;
            end
        end
        
        function leaveShelf(obj)
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif abs(obj.pose(1) - obj.dest(1)) <= 3
                obj.pose = obj.pose + obj.speed*[1 0 0];
                obj.pose(3) = 0;
            else
                obj.status(4) = 1; 
            end
        end
        
        function avoidCorrupt(obj)
            if obj.delayTime > 0
                obj.delayTime = obj.delayTime - 1;
            elseif abs(obj.pose(1) - obj.dest(1)) <= 3
                obj.pose = obj.pose + obj.speed*[1 0 0];
                obj.pose(3) = 0;
            else
                obj.status(6) = 0; 
            end
        end

        function returnChargingStation(obj)            
            if abs(obj.pose(1) - obj.spawn(1)) > 3
                s = (obj.pose(1) - obj.spawn(1))/abs(obj.pose(1) - obj.spawn(1));
                obj.pose = obj.pose - obj.speed*s*[1 0 0];
                obj.pose(3) = (pi/2)*(1 + s);                            
            elseif abs(obj.pose(2) - obj.spawn(2)) >= 0.0001 
                s = (obj.pose(2) - obj.spawn(2))/abs(obj.pose(2) - obj.spawn(2));
                obj.pose = obj.pose - obj.speed*s*[0 1 0];
                obj.pose(3) = (pi/2)*(-s);                                        
            elseif abs(obj.pose(1) - obj.spawn(1)) <= 3
                s = (obj.pose(1) - obj.spawn(1))/abs(obj.pose(1) - obj.spawn(1));
                obj.pose = obj.pose - obj.speed*s*[1 0 0];
                obj.pose(3) = (pi/2)*(1 + s); 
            end
            if abs(obj.pose(1) - obj.spawn(1)) <= 0.0001 && abs(obj.pose(2) - obj.spawn(2)) <= 0.0001
                obj.status(5) = 1;
                obj.delayTime = 2000;
                obj.battery = 5;
            end
        end
        
        function active(obj, viz, objects)
            if obj.status(1) == 0
                leaveChargingStation(obj)
            elseif obj.status(2) == 0
                 getPackage(obj)
            elseif obj.status(6) == 1
                 avoidCorrupt(obj);
            elseif obj.status(3) == 0
                 deliveryPackage(obj)
            elseif obj.status(4) == 0
                 leaveShelf(obj);
            end                   
            viz(obj.pose, objects);
        end

        function selfControl(obj, viz, shelves, ports, objects)
           posPackage = randi([1 10],1);
           if posPackage <= 6
               setInfo(obj,ports{posPackage},shelves{randi([1 48],1)});
               while obj.status(4) == 0
                   active(obj, viz, objects)                   
               end               
               resetStatus(obj);                              
               if randi([1 5],1) == 1
                   while obj.status(5) == 0 
                       returnChargingStation(obj);
                       viz(obj.pose, objects);                       
                   end               
               elseif obj.battery == 5
                   while obj.status(5) == 0 
                       returnChargingStation(obj);
                       viz(obj.pose, objects);                       
                   end
               elseif obj.delivered == 10
                   while obj.status(5) == 0 
                       returnChargingStation(obj);
                       viz(obj.pose, objects);                       
                   end
               end       
           end
        end                

        function resetStatus(obj)
            obj.status = [0 0 0 0 0 0];
        end             

    end
end