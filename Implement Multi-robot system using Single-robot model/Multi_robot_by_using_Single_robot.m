N = maxNumCompThreads(1);

%% create map
map = binaryOccupancyMap(140, 200, 1);
occ = zeros(200, 140);

% shelves location
shelves = {};
for j = 25:18:117
    for i = 42:15:148
        occ(i:i + 1,j:j + 1) = 1;        
        shelves{end + 1} = [j (i + 8)];
    end
end

% ports location
objects = [rand(36,3)]; 
ports = {};
for i = 1:6
    ports{end + 1} = [(25 + (i - 1)*18) 192];
    objects(i,1:3) = [(25 + (i - 1)*18) 195 1];
end

setOccupancy(map, occ);

%% create numRobots robots
numRobots = 30;
robots = Single_robot.empty;
poses = 10*rand(3,numRobots);
for i = 1:30
    if i <= 10
        poses(1:3,i) = [(26 + mod(i - 1,5)*4) (15 - 10*(floor((i - 1)/5))) pi/2];
        objects(i + 6,1:3) = [(26 + mod(i,5)*4) (15 - 10*(floor((i - 1)/5))) 2];
    elseif i <= 20
        poses(1:3,i) = [(62 + mod(i - 11,5)*4) (15 - 10*(floor((i - 11)/5))) pi/2];
        objects(i + 6,1:3) = [(62 + mod(i - 10,5)*4) (15 - 10*(floor((i - 11)/5))) 2];
    else
        poses(1:3,i) = [(98 + mod(i - 21,5)*4) (15 - 10*(floor((i - 21)/5))) pi/2];
        objects(i + 6,1:3) = [(98 + mod(i - 20,5)*4) (15 - 10*(floor((i - 21)/5))) 2];
    end
    robots(end + 1) = Single_robot(i,poses(1:3,i), 1);
end

%% create enviroment
env = MultiRobotEnv(numRobots);
env.robotRadius = 1;
env.mapName = 'map';
env.showTrajectory = false;
env.showRobotIds = false;
env.objectColors = [1 0 0;0 1 0;0 0 1];
env.objectMarkers = 'so^';

%% create object detector
objectDetector = ObjectDetector;
objectDetector.fieldOfView = pi/4;
attachObjectDetector(env,1,objectDetector);
env.plotSensorLines = false;

checkMap(1:140,1:200) = 0;
for i = 1:numRobots
    checkMap(robots(i).pos(1),robots(i).pos(2)) = 1;
end

while 1 == 1    
    
    for i = 1:numRobots

        if (robots(i).status(3) == 1 || robots(i).package(1) == 0) && robots(i).battery > 0 && robots(i).status(5) ~= 1
            rI = randi([1 10],1);         
            disp(rI);
            if rI <= 6                            
               setInfo(robots(i),ports{rI},shelves{randi([1 48],1)});
            else 
                robots(i).status(5) = 1;
            end        
        end
        
        r = copy(robots(i));
        selfMove(r);
        if checkCorrupt(checkMap, r.pos(1), r.pos(2), robots(i).pos(1), robots(i).pos(2)) == 1
            checkMap(robots(i).pos(1), robots(i).pos(2)) = 0;        
            selfMove(robots(i));
            checkMap(robots(i).pos(1), robots(i).pos(2)) = 1;
            poses(1:3,i) = robots(i).pos;
        end    
    
    end     
    env(1:numRobots, poses,objects);
    
end

%% function
function c = checkCorrupt(map, x, y, a, b)
    c = 1;
    for i = x-2:x+2
        for j = y-2:y+2
            if (i == x && j == y) || (i == a && j == b)
                continue;
            end
            if map(i,j) == 1                
                c = 0;
                return;
            end
        end
    end
end