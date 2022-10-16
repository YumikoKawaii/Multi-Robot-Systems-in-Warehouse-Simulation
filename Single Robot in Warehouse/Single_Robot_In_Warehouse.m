%create map
map = binaryOccupancyMap(120, 150, 1);
occ = zeros(150, 120);

shelves = location.empty;

for i = 22:15:128
    for j = 15:18:107
        occ(i:i + 1,j:j + 1) = 1;
        shelves(end + 1).pos = [j (i - 2)];
    end
end
ports = location.empty;
for i = 1:6
    ports(end + 1).pos = [(15 + (i - 1)*18) 145];
end

setOccupancy(map, occ);

% create visualizer
viz = Visualizer2D;
viz.robotRadius = 1;
viz.showTrajectory = false;
viz.mapName = 'map';

% create robot
r = robot_Single;
initial(r,[60 5],[60 5 pi/2],0.2);
viz(r.pose);

while r.delivered < 10
   selfControl(r, viz, shelves, ports);     
end