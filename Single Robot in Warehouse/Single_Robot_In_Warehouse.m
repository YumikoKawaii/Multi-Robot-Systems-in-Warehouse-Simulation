%create map

map = binaryOccupancyMap(120, 150, 1);
occ = zeros(150, 120);



shelves = {};
for i = 22:15:128
    for j = 15:18:107
        occ(i:i + 1,j:j + 1) = 1;
        shelves{end + 1} = [j (i - 2)];        
    end
end

ports = {};
objects = [rand(7,3)];
for i = 1:6
    ports{end + 1} = [(15 + (i - 1)*18) 142];
    objects(i,1:3) = [(15 + (i - 1)*18) 145 1];
end
setOccupancy(map, occ);

% create robot
r = robot_Single;
initial(r,[60 5],[60 5 pi/2],0.2);
objects(7,1:3) = [60 5 2];

% create visualizer
viz = Visualizer2D;
viz.robotRadius = 1;
viz.showTrajectory = false;
detector = ObjectDetector;
attachObjectDetector(viz,detector);
%objects = [1, 1, 1; 0, 1, 2; 1, 0, 3]; 
viz.objectColors = [1, 0, 0; 0, 1, 0; 0, 0, 1]; % Red, Green, Blue
viz.mapName = 'map';
viz(r.pose, objects);
while r.delivered < 10
   selfControl(r, viz, shelves, ports, objects);     
end