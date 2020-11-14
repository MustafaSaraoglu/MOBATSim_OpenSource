classdef GridMap < Map
    %A MOBATSim map object with a XML-graph and a binary occupancy grid object
    %   Detailed explanation goes here
    
    properties
        bogMap;                        % Binary occupancy grid object
        gridResolution = 0.25;         % Number of cells per 1 length unit on the map
        gridLocationMap;               % Container object to store and load all GridLocation objects
        xOffset;                       % Offset to transform visualization into bog coordinates if necessary
        yOffset;
        colourMatrix;
    end
    
    methods
        %% constructor and visualization creation
        function obj = GridMap(mapName,waypoints, connections_circle,connections_translation, startingNodes, breakingNodes, stoppingNodes, leavingNodes)
            obj = obj@Map(mapName,waypoints, connections_circle,connections_translation, startingNodes, breakingNodes, stoppingNodes, leavingNodes);
            
            obj.colourMatrix = [1 0 0;      %1  red
                1 1 0 ;                     %2	yellow
                0 1 1 ;                     %3  light blue
                0 0.2470 0.5410;            %4  dark blue
                0.8500 0.3250 0.0980;       %5  orange
                1 0 1;                      %6  magenta
                0 0.4470 0.7410;            %7  blue
                0.6350 0.0780 0.1840;       %8  dark red
                0.3 0.3 0.3;                %9  grey
                0.4940 0.1840 0.5560;       %10 violet
                ];
            
            
            % Plot the map on the figure
            generateMapVisual(obj,false);
            % BOG will be created in the prepare_simulator script, to include all vehicle data
            
            %create bog container map object
            obj.gridLocationMap = containers.Map();
            
            obj.PlotMap();
            
        end %Constructor
        
        function generateMapVisual(obj,displayInGridCoordinates)
            %This function plots any XML Map of MOBATSim. Keep in mind that you have to
            %do a coordinate transformation between normal coordinates and grid / mobatsim
            %Input: XML Map object of MOBATSim, boolean wether to plot mobatsim or grid coordinates
            
            %% prepare everything
            hold off
            waypoints = obj.waypoints;
            circ = obj.connections.circle; %curves
            trans = obj.connections.translation; %straight roads
            %coordinate transformation
            waypoints(:,3) = -1.*waypoints(:,3);    %MOBATSim stores the negative y, so we have to transform it
            circ(:,6) = -1.*circ(:,6);
            %maybe it is necessary to display everything in the coordinate system of the binary occupancy grid object
            %if so, we have to shift everything here and set the input true
            if displayInGridCoordinates
                xOff = min(waypoints(:,1))-50;
                yOff = min(waypoints(:,3))-50;
                
                waypoints(:,3) = waypoints(:,3)-yOff;
                waypoints(:,1) = waypoints(:,1)-xOff;
                
                circ(:,4) = circ(:,4)-xOff;
                circ(:,6) = circ(:,6)-yOff;
            end
            %% Generate a usable plot
            %% generate curves
            for c = 1 : length(circ)
                cPart = circ(c,:); %load information on the current curve
                %starting point
                x1 = waypoints(cPart(1),1);
                y1 = waypoints(cPart(1),3);
                %goal point
                x2 = waypoints(cPart(2),1);
                y2 = waypoints(cPart(2),3);
                %central point
                x0W = cPart(4);
                y0W = cPart(6);
                %radius
                radius = norm( [x2,y2]-[x0W,y0W] );
                %angles of start and goal
                phiStart = angle(complex((x1-x0W) , (y1-y0W)));
                phiGoal = angle(complex((x2-x0W) , (y2-y0W)));
                %direction
                direction = sign(cPart(3));
                %% make angle allways usable
                %we have to make every angle positive and also big eneough,
                %that an angle of a point is allways between start and goal
                if phiStart <0
                    phiStart = phiStart + 2*3.1415;
                end
                if phiGoal <0
                    phiGoal = phiGoal + 2*3.1415;
                end
                %make turns through 0° possible
                if (direction == -1 && phiStart < phiGoal)
                    phiStart = phiStart + 2*3.1415;
                end
                if (direction == 1 && phiStart > phiGoal)
                    phiGoal = phiGoal + 2*3.1415;
                end
                %create an array with all angles between start and goal
                phi1 = phiStart : direction*0.01 : phiGoal;
                %set first and last, to make shure there are no gaps in the
                %plot because of rounding errors
                phi1(1) = phiStart;
                phi1(end) = phiGoal;
                %create the points to plot from angle and radius
                points = [(radius .* cos(phi1)+x0W)',(radius .* sin(phi1))'+y0W];
                
                if c ==1
                    hold off
                else
                    hold on
                end
                %plot it
                plot(points(:,1),points(:,2),'color',[0 1 0],'LineWidth',2);
                %plot number next to edge
                textPos = points(round(length(points)/2,0),:);
                description = text(textPos(1)-10,textPos(2)-15,num2str(c),'color',[0 0.5 0]);
            end
            %% generate straight lines
            for t = 1 : length(trans)
                position = zeros(2,2); %preallocate start and goal point
                %get both points and plot a line in between
                position(1,:) = [waypoints(trans(t,1),1) ,waypoints(trans(t,1),3)];
                position(2,:) = [waypoints(trans(t,2),1) ,waypoints(trans(t,2),3)];
                plot(position(:,1),position(:,2),'color',[0 1 0],'LineWidth',2);
                %plot number next to edge
                textPos = (position(2,:) + position(1,:))/2;
                text(textPos(1)+5,textPos(2)-15,num2str(t+c),'color',[0 0.5 0]);
            end
            %% plot nodes with numbers
            for n = 1 : length(waypoints)
                %get position
                pos = [waypoints(n,1),waypoints(n,3)];
                %plot dot and number in a dark blue
                plot(pos(1),pos(2),'Marker','o','MarkerFaceColor',[0 0.2 0.5],'color',[0 0.2 0.5]);
                text(pos(1)-5,pos(2)-15,num2str(n),'color',[0 0.2 0.5]);%TODO make it appear automatically under dot
                %maybe there is a way to let it not collide with other text?
            end
            hold off
        end
        
        function dynamicRouteHighlighting(obj)
            try
                delete(obj.plots.trajectories)
            catch ME
                disp('Problem deleting trajectories.'); % TODO: remove try-catch after making sure it works fine
            end
            
            hold on
            for vehicle = obj.Vehicles % Changing sizes of BOGPath makes it hard to vectorize
                try
                    obj.plots.trajectories(vehicle.id) = plot(vehicle.pathInfo.BOGPath(:,1),vehicle.pathInfo.BOGPath(:,2),'color',obj.colourMatrix(vehicle.id,:),'LineWidth',2);
                catch ME
                    disp('Problem creating trajectories'); % TODO: remove try-catch after making sure it works fine
                end
            end
            hold off
            
        end
        
        
    end
    
    methods(Static)
        function [bogMap,xOff,yOff] = generateBOGrid(map)
            %create binary occupancy grid object and grid location objects
            %all cells are drawn like pixel and connect to each other
            %Input: XML map object
            %Output: binary occupancy map object, x-offset, y-offset
            
            %% prepare for drawing
            %get the number of cars to set up the vectors inside GridLocation
            nrOfCars = length([map.Vehicles.id]);
            %get the gridsize (the number of cells for 1 unit on the map)
            gRes = map.gridResolution;
            %first we need map size
            %we can get it from waypoints with some space for better
            %display
            distances = map.connections.distances;
            waypoints = map.waypoints;  %[x z y]
            waypoints(:,3) = -1.*waypoints(:,3);%transform to mobatsim coordinates
            xSize = max(waypoints(:,1))-min(waypoints(:,1))+100;
            xOff = min(waypoints(:,1))-50;
            ySize = max(waypoints(:,3))-min(waypoints(:,3))+100;
            yOff = min(waypoints(:,3))-50;
            %calculate speedLimit [carID,edgeNR]
            maxEdgeSpeed = [map.connections.circle(:,end);
                map.connections.translation(:,end)];
            %set speed limit to equal or less than max vehicle speed
            speedLimit = zeros(nrOfCars,length(maxEdgeSpeed));
            for car = 1 : nrOfCars
                maxSpeed = map.Vehicles(car).dynamics.maxSpeed ;
                maxEdgeSpeed(maxEdgeSpeed>maxSpeed)= maxSpeed;
                speedLimit(car,:) = maxEdgeSpeed;
            end
            %create binary occupancy map object
            bogMap = binaryOccupancyMap(xSize,ySize,gRes);
            %mark everything as blocked
            occ = ones(round(ySize*gRes,0),round(xSize*gRes,0));
            setOccupancy(bogMap,[0,0],occ);%lower left corner to set values
            
            %import map details
            trans = map.connections.translation; %[from, to, speed]
            circ = map.connections.circle; %[from, to, angle, x,z,yCenter, speed]
            circ(:,6) = -1.*circ(:,6);     %transform to mobatsim coordinates
            
            %we iterate backwards in case we want to preallocate something
            
            %% bresenham algorithm
            for j = size(map.connections.all,1) :-1: (size(circ,1)+1)
                %% for each straight edge
                %conncetions.all stores first all circles, then all translations
                %   j = nr of edge globally inside conncetions.all
                %   t = nr inside the vector trans
                t= j - size(circ,1);
                dist = distances(j);
                %start node coordinates in grid
                p1 = bogMap.world2grid([waypoints(trans(t,1),1)-xOff,waypoints(trans(t,1),3)-yOff]);
                %end node coordinates in grid
                p2 = bogMap.world2grid([waypoints(trans(t,2),1)-xOff,waypoints(trans(t,2),3)-yOff]);
                %get difference
                deltaX = p2(1)-p1(1);
                delatY = p2(2)-p1(2);
                %get distance and direction
                absDx = abs(deltaX);
                absDy = abs(delatY); % distance
                signDx = sign(deltaX);
                signDy = sign(delatY); % direction
                %determine which direction to go
                if absDx > absDy
                    % y is shorter
                    pdx = signDx;   %what to add for a parallel step
                    pdy = 0;        %p is parallel
                    ddx = signDx;   %what to add for a diagonal step
                    ddy = signDy;   % d is diagonal
                    deltaShortDirection  = absDy;
                    deltaLongDirection  = absDx;
                else
                    % x is shorter
                    pdx = 0;        %what to add for a parallel step
                    pdy = signDy;   % p is parallel
                    ddx = signDx;   %what to add for a diagonal step
                    ddy = signDy;   % d is diagonal
                    deltaShortDirection  = absDx;
                    deltaLongDirection  = absDy;
                end
                %start at node 1
                x = p1(1);
                y = p1(2);
                pixelArray = append(num2str(x), ",", num2str(y));
                error = deltaLongDirection/2;
                %% now set the pixel
                for i= 1:deltaLongDirection
                    %% for each pixel
                    % update error
                    error = error - deltaShortDirection;
                    if error < 0
                        error = error + deltaLongDirection; % error is never < 0
                        % go in long and short  direction
                        x = x + ddx;
                        y = y + ddy; % diagonal
                    else
                        % go in long direction
                        x = x + pdx;
                        y = y + pdy; % parallel
                    end
                    curKey = append(num2str(x), ",", num2str(y));
                    pixelArray = [pixelArray,curKey];
                end
                %% now assign properties
                bogMap = map.setPixelFromArray(map,bogMap,dist,pixelArray,speedLimit(:,j),map.connections.all(j,1),map.connections.all(j,2),nrOfCars,j);
            end
            
            %% draw a circle pixel by pixel
            for t = size(circ,1):-1:1
                % t = nr of edge
                %% load information
                dist = distances(t);
                %starting point
                pStart = bogMap.world2grid([waypoints(circ(t,1),1)-xOff,waypoints(circ(t,1),3)-yOff]);
                %goal point
                pGoal = bogMap.world2grid([waypoints(circ(t,2),1)-xOff,waypoints(circ(t,2),3)-yOff]);
                %central point
                pCenter = bogMap.world2grid([circ(t,4)-xOff,circ(t,6)-yOff]);
                
                radius = round(norm( pGoal-pCenter  ),0);
                phiStart = angle(complex((pStart(1)-pCenter(1)) , (pStart(2)-pCenter(2))));
                phiGoal = angle(complex((pGoal(1)-pCenter(1)) , (pGoal(2)-pCenter(2))));
                direction = sign(circ(t,3));
                % make angle allways usable
                if phiStart <0
                    phiStart = phiStart + 2*3.1415;
                end
                if phiGoal <0
                    phiGoal = phiGoal + 2*3.1415;
                end
                offset = 0;
                %make turns through 0° possible
                if (direction == -1 && phiStart < phiGoal)
                    offset = 2*3.1415;
                    phiStart = phiStart + offset;
                end
                if (direction == 1 && phiStart > phiGoal)
                    offset = 2*3.1415;
                    phiGoal = phiGoal + offset;
                end
                %% calculate all pixel
                pixelArray = map.calculateCircle(pStart,phiStart,pGoal,phiGoal,pCenter,direction,radius,offset);
                %% now draw pixel and assign to map
                bogMap = map.setPixelFromArray(map,bogMap,dist,pixelArray,speedLimit(:,t),map.connections.all(t,1),map.connections.all(t,2),nrOfCars,t);
            end
        end
        
        %% Helper functions
        function bogMap = setPixelFromArray(map,bogMap,dist,pixelArray,speedLimit,startNodeNR,endNodeNR,nrOfCars,edgeNumber)
            %get number of starting node and end node, to set unique
            %successors and predecessors per different edge
            %% set first GridLocation
            curKey = pixelArray(1);
            %calculate distance of every cell
            dist = dist/size(pixelArray,2);
            %load or create GridLocation for starting node
            pStart = str2num(pixelArray(1));
            if ~map.gridLocationMap.isKey(curKey)
                curGL = Grid(pStart,nrOfCars,startNodeNR,0);
            else
                curGL = map.gridLocationMap(curKey);
            end
            %assign property
            curGL = curGL.assignDistance(dist);
            curGL.speedLimit = speedLimit;
            p = str2num(pixelArray(1));
            %set pixel
            setOccupancy(bogMap,p,0,"grid");
            %% set all GridLocation objects on the road and connect them
            for s = 2 : (length(pixelArray)-1)
                %% start connecting
                % create new key
                newKey = pixelArray(s);
                % set pixel at location p
                p = str2num(newKey);
                setOccupancy(bogMap,p,0,"grid");
                %create new GL
                if ~map.gridLocationMap.isKey(newKey)
                    newGL = Grid(p,nrOfCars,0,edgeNumber);
                else
                    %or load old one
                    newGL = map.gridLocationMap(newKey);
                end
                %% assign properties
                newGL = newGL.assignDistance(dist);
                curGL.speedLimit = speedLimit;
                %% assign successor and predecessor
                curGL = curGL.addTransSucc(newKey,startNodeNR);
                newGL = newGL.addTransPred(curKey,endNodeNR);
                %store in map
                map.gridLocationMap(curKey)=curGL;
                %% move to next GL
                curGL = newGL;
                oldKey = curKey;
                curKey = newKey;
            end
            %% set the last GL
            %get key
            newKey = pixelArray(end);
            if ~map.gridLocationMap.isKey(newKey)
                %create new
                p = str2num(newKey);
                newGL = Grid(p,nrOfCars,endNodeNR,0);
            else
                %load from map
                newGL = map.gridLocationMap(newKey);
            end
            %set inside bog
            setOccupancy(bogMap,p,0,"grid");
            p = str2num(oldKey);
            setOccupancy(bogMap,p,0,"grid");
            %assign properties
            newGL = newGL.assignDistance(dist);
            newGL.speedLimit = speedLimit;
            curGL.speedLimit = speedLimit;
            %assign succ and pred
            curGL = curGL.addTransSucc(newKey,startNodeNR);
            newGL = newGL.addTransPred(curKey,endNodeNR);
            %store inside map
            map.gridLocationMap(curKey)=curGL;
            map.gridLocationMap(newKey)=newGL;
        end
        
        
        function pixelArray = calculateCircle(pStart,phiStart,pGoal,phiGoal,pCenter,direction,radius,offset)
            
            %start with the first one
            curPix = pStart;
            %assign it to an array
            pixelArray = [];%store points here
            pixelArray = [pixelArray,append(num2str(curPix(1)), ",", num2str(curPix(2)))];
            curPhi = phiStart;
            while curPix(1) ~= pGoal(1) || curPix(2) ~= pGoal(2)
                %while the goal pixel is not reached, go to the next
                %pixel, that is between the last one and the goal and
                %is closest to the radius
                nextPix = [];   %the next pixel to draw in grid
                nextPhi = 0;
                deltaR = 200000;     %set up distance to the radius point with angle phi to be allways higher first try
                %for every neighbour
                for x = -1 : 1
                    for y = -1 : 1
                        if x ~= 0 || y ~= 0
                            %compare pixel to get the closest one to the original
                            %point
                            %calculate the distance between the pixel and the
                            %reference and use the closest
                            neighbourPix = [curPix(1)+x,curPix(2)+y];%new pixel in grid
                            phi = angle(complex((neighbourPix(1)-pCenter(1)) , (neighbourPix(2)-pCenter(2))));%angle in world
                            if phi < 0
                                phi = phi + 2*3.1415;
                            else
                                phi = phi + offset;
                            end
                            %test, if the angle is relevant (between last and goal)
                            if (direction == 1 && curPhi <= phi && phiGoal >= phi)|| (direction ==-1 && curPhi >= phi && phiGoal <= phi)
                                %get point with same angle on the radius
                                referencePoint = [radius * cos(phi)+pCenter(1),radius*sin(phi)+pCenter(2)];
                                %calculate distance between reference and current neighbour pixel
                                refDeltaR = norm(neighbourPix - referencePoint);
                                if refDeltaR < deltaR
                                    %if the distance is less then
                                    %previously, we found a better next
                                    %pixel
                                    deltaR = refDeltaR;
                                    nextPix = neighbourPix;
                                    nextPhi = phi;
                                end
                            end
                        end
                    end
                end
                %move to the best pixel
                curPix = nextPix;
                curPhi = nextPhi;
                %now curPix is the next pixel to draw
                pixelArray = [pixelArray, append(num2str(curPix(1)), ",", num2str(curPix(2)))];
            end
        end
        
        
    end
    
end

