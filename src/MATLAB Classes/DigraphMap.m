classdef DigraphMap < Map
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        digraph_visualization
    end
    
    methods
        function obj = DigraphMap(mapName,waypoints, connections_circle,connections_translation, startingNodes, breakingNodes, stoppingNodes, leavingNodes)
            
            obj = obj@Map(mapName,waypoints, connections_circle,connections_translation, startingNodes, breakingNodes, stoppingNodes, leavingNodes);
            
            
            
            obj.digraph_visualization = digraph( [obj.connections.circle(:,1)' obj.connections.translation(:,1)'],[obj.connections.circle(:,2)' obj.connections.translation(:,2)'],[ obj.connections.distances']);
            
            for i=1:length(obj.connections.all)
                graphConnectionsLabel(i) = find(obj.connections.all(:,1) == obj.digraph_visualization.Edges.EndNodes(i,1)&obj.connections.all(:,2) == obj.digraph_visualization.Edges.EndNodes(i,2));
            end
            
            % Plot the map on the figure
            obj.plots.graph = plot(obj.digraph_visualization,'XData',obj.waypoints(:,1),'YData',-obj.waypoints(:,3),'EdgeLabel',graphConnectionsLabel');
            
            obj.PlotMap();
            obj.initialGraphHighlighting();
            obj.plots.graph.LineWidth = 2;
            
        end %Constructor

        function dynamicRouteHighlighting(obj)
            
            if(isempty(findobj('type','figure')))
                
            else
                obj.initialGraphHighlighting();
                for vehicle = obj.Vehicles
                    if length(vehicle.pathInfo.path) > 1
                        if vehicle.dynamics.speed < 27.7
                            routeColor = obj.getRouteColorFromSpeed(vehicle.dynamics.speed*3.6);
                            highlight(obj.plots.graph,vehicle.pathInfo.path(1),vehicle.pathInfo.path(2),'EdgeColor', routeColor)
                        end
                    end
                end
            end
            
        end
 
    end
    
end
