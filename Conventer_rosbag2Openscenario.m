clear;clc;
%% This section is user defined section. User can change the parameters here.
%  There are some example of user defined input here. If there is no user
%  defined input, keep init={}, sim={}, delete_object=[]. 

bag_name = "2020-12-06-21-45-11.bag";  %the path and name of rosbag
path_vehicleCatalog = "../xosc/Catalogs/Vehicles";  %the path of vehicle calalog
path_map = "../xodr/A5_final_RFoffset.xodr";  %the path of OpenDRIVE map
file_name = 'defaultscenario.xosc';  %the converted OpenSCENARIO file name
%this filter defined, the minimum number of timestamps, that the objects in this scenario.
%If the exist timestamp smaller than this value, it will be delete. 
%Use 0, if all the object will be hold.
filter = 5; 

% These two parameter means start time and end time of the scenario in Rosbag. 
% Unit is second. 0 means the begin of Rosbag. For example: start_time = 1; end_time = 5;
% means the scenario begins at the simulation time of 1s in Rosbag, and
% ends at the simulation time of 5s in Rosbag.
start_time = 4; 
end_time = 7;

% the matrix delete_object=[] used for deletiong objects in scenario.
% These objects won't be converted into OpenSCENARIO.
% If you want to delete S1, just input 1 in this matrix.
% Example: delete_object = [2, 3];
delete_object = [];

% The cell init={} used for adding objects in this scenario. There are three method
% to locate the object, 'WorldPosition', 'RelativeLanePosition' and 'LanePosition'.
% If you want to add more objects, add new row in cell init={}, that means
% use ; to seperate

% If you use "WorldPosition", the parameters means:
% first: the locate method. here 'WorldPosition'
% second: the name of the object
% third: the type of the object
% fourth: the initial x-coordinate of the object. unit is meter
% fifth: the initial y-coordinate of the object. unit is meter
% sixth: the initial z-coordinate of the object, if 2D, use 0. unit is meter
% seventh: the initial velocity of the object. unit is meter pro second

% If you use "RelativeLanePosition", the parameters means:
% first: the locate method. here 'RelativeLanePosition'
% second: the name of the object
% third: the type of the object
% fourth: the relative object, if relative to ego use "Ego"
% fifth: the relative lane number of the object, same lane number use 0.
% sixth: the relative s-coordinate of the object. unit is meter.
% seventh: the initial velocity of the object. unit is meter pro second.

% If you use "LanePosition", the parameters means:
% first: the locate method. here 'LanePosition'
% second: the name of the object
% third: the type of the object
% fourth: the initial road number of the object
% fifth: the initial lane number of the object
% sixth: the initial s-coordinate of the object. unit is meter.
% seventh: the initial velocity of the object. unit is meter pro second

% Here is an example for init{}:
% init = {'RelativeLanePosition','A1', 'car_red', 'Ego', 1, -50, 35.5112; 
%         'WorldPosition', 'A2', 'car_red', 988.1839, 4.5803e+03, 0, 38.0113; 
%         'LanePosition', 'A3', 'truck_yellow', 1, -2, 700, 23};
init = {}; 


% The cell sim={} used for change the action of objects in this scenario.
% There are two actions, 'laneChange' and 'velocityChange'
% If you want to define more than one actions, please use ; to seperate
% these actions

% If you use "laneChange", the parameters means:
% first: action, here use 'laneChange'
% second: the actor of the action, ego-car use 'Ego', 
%         the object in Rosbag use 'OS+number', user added object use its name
% third: the start trigger of the action. Value 1 means time trigger. Value
%        0 means distance trigger.
% fourth: the parameter of the trigger. For time trigger, the action will
%         be activated, when the simulation time reach this value. 
%         Unit is Second. For distance trigger, there are two rules, positive 
%         value means greater than and negative value means less than.
%         The action will be activated, if the distance between object and 
%         ego greater than or less than this value. The unit is meter.
% fifth: the target lane to change. -1 means change lane to the right, 1
%        means change lane to the left. The value bigger than 1 means change mor than 1 lane. 
% sixth: how long will the target get. The unit here is second.

% If you use "offsetChange", the parameters means:
% first: action, here use 'offsetChange'
% second: the actor of the action, ego-car use 'Ego', 
%         the object in Rosbag use 'OS+number', user added object use its name
% third: the start trigger of the action. Value 1 means time trigger. Value
%        0 means distance trigger.
% fourth: the parameter of the trigger. For time trigger, the action will
%         be activated, when the simulation time reach this value. 
%         Unit is Second. For distance trigger, there are two rules, positive 
%         value means greater than and negative value means less than.
%         The action will be activated, if the distance between object and 
%         ego greater than or less than this value. The unit is meter.
% fifth: the target offset to reach. Positive offset means go left,
%        negative offset means go right, the unit is meter.
% sixth: how long will the target get. The unit here is second.

% If you use "velocityChange", the parameters means:
% first: action, here use 'velocityChange'
% second: the actor of the action, ego-car use 'Ego', 
%         the object in Rosbag use 'OS+number', user added object use its name
% third: the start trigger of the action. Value 1 means time trigger. Value
%        0 means distance trigger.
% fourth: the parameter of the trigger. For time trigger, the action will
%         be activated, when the simulation time reach this value. 
%         Unit is Second. For distance trigger, there are two rules, positive 
%         value means greater than and negative value means less than.
%         The action will be activated, if the distance between object and 
%         ego greater than or less than this value. The unit is meter.
% fifth: the target speed to reach
% sixth: how long will the target get. The unit here is second.

% Here is an example for sim{}:
% sim = {'laneChange', 'A1',0 ,-10, 1, 1;
%        'laneChange', 'A2',1 ,3.5, -1, 5; 
%        'velocityChange', 'S4', 1, 5, 40, 2; 
%        'offsetChange', 'Ego', 1, 2, 1, 2};
sim = {};


%% read the data in Rosbag
bag = rosbag(bag_name);
bagInfo = rosbag('info',"2020-12-06-21-45-11.bag");
TopicsA = bag.AvailableTopics;
ego_raw  = select(bag, 'Topic','/VechInfo');
Obj      = select(bag, 'Topic','/finalObjList/map/objects');
clear bag;
vechInfo      = readMessages(ego_raw,'DataFormat','struct');
map_objects         = readMessages(Obj,'DataFormat','struct');

%% track the objects in Rosbag.
% the matrix is trajectory. The index of object in cell will be found with trajectory(index of cell, ID of object) 
for i = 1 : length(map_objects)
    if start_time < double(map_objects{i , 1}.Header.Stamp.Sec - map_objects{1, 1}.Header.Stamp.Sec) + double(map_objects{i, 1}.Header.Stamp.Nsec - map_objects{1, 1}.Header.Stamp.Nsec) * 0.000000001
        sc_start = i - 1;
        break;
    end
end
for i = 1 : length(map_objects)
    if end_time < double(map_objects{i , 1}.Header.Stamp.Sec - map_objects{1, 1}.Header.Stamp.Sec) + double(map_objects{i, 1}.Header.Stamp.Nsec - map_objects{1, 1}.Header.Stamp.Nsec) * 0.000000001
        sc_end = i;
        break;
    end
end
index_tr = 1;
for i = 1 : length(map_objects)
    for j = 1 : length(map_objects{i, 1}.Objects)
        map_objects{i, 1}.Objects(j).search = 0;
    end
end
for i = 1 : length(map_objects)
    for j = 1 : length(map_objects{i, 1}.Objects)
        if map_objects{i, 1}.Objects(j).search == 0
            map_objects{i, 1}.Objects(j).search = 1;
            traj_temp = zeros(1, length(map_objects));
            id_thisob = map_objects{i, 1}.Objects(j).Id;
            index_trajt = 1;
            a = i + 1;
            b = j;
            traj_temp(1) = b;
            continious = 1;
            while continious && a <= length(map_objects)
                continious = 0;
                for k = 1 : length(map_objects{a, 1}.Objects)
                    if map_objects{a, 1}.Objects(k).Id == id_thisob
                        index_trajt = index_trajt + 1;
                        map_objects{a, 1}.Objects(k).search = 1;
                        b = k;
                        a = a + 1;
                        traj_temp(index_trajt) = b;
                        continious = 1;
                        break;
                    end
                end
            end
            count = 0;
            for k = 1 : length(traj_temp)
                if traj_temp(k) ~= 0
                    count = count + 1;
                end
            end
            if count >= filter
                m = 1;
                for k = i : length(map_objects)
                    trajectory(index_tr, k) = traj_temp(m);
                    m = m + 1;
                end
                index_tr = index_tr + 1;
            end
        end
    end
end
%find the number of trajectory, length will be hold in "count", the A(count) is the row of the trajectory. 
[m, n]=size(trajectory);
count = 0;
count2 = 0;
A = [];
for i = 1 : m
    if trajectory(i, sc_start) ~= 0
        if trajectory(i, sc_start + 1 + filter) ~= 0
            count = count + 1;
            A(count) = i;
        end
    end
end

%% make the head file of OpenScenario
docNode=com.mathworks.xml.XMLUtils.createDocument('OpenSCENARIO');
OpenSCENARIO=docNode.getDocumentElement;
OpenSCENARIO.setAttribute('xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
OpenSCENARIO.setAttribute('xsi:noNamespaceSchemaLocation','OpenSCENARIO.xsd')
fileheadernode=docNode.createElement('FileHeader');
fileheadernode.setAttribute('revMajor',num2str(1));
fileheadernode.setAttribute('revMinor',num2str(0));
fileheadernode.setAttribute('name','test');
fileheadernode.setAttribute('date','Mon Oct 26 11:34:32 2020');
fileheadernode.setAttribute('description','OpenSCENARIO Template');
OpenSCENARIO.appendChild(fileheadernode);
parameterdeclarationsnode=docNode.createElement('ParameterDeclarations');
OpenSCENARIO.appendChild(parameterdeclarationsnode);
catalogLocationsnode=docNode.createElement('CatalogLocations');
VehicleCatalognode=docNode.createElement('VehicleCatalog');  
Directorynode=docNode.createElement('Directory');                                      
Directorynode.setAttribute('path', path_vehicleCatalog);      
VehicleCatalognode.appendChild(Directorynode);                                     
catalogLocationsnode.appendChild(VehicleCatalognode);               
OpenSCENARIO.appendChild(catalogLocationsnode);
roadnetworknode=docNode.createElement('RoadNetwork');
logicfilenode=docNode.createElement('LogicFile');
logicfilenode.setAttribute('filepath',path_map);  
roadnetworknode.appendChild(logicfilenode);
OpenSCENARIO.appendChild(roadnetworknode);

%establish of entities from user
entitiesnode=docNode.createElement('Entities');
OpenSCENARIO.appendChild(entitiesnode);
scenarioobjectnode=docNode.createElement('ScenarioObject');
scenarioobjectnode.setAttribute('name', 'Ego');
entitiesnode.appendChild(scenarioobjectnode);
CatalogReferencenode=docNode.createElement('CatalogReference');
CatalogReferencenode.setAttribute('catalogName', 'VehicleCatalog');
CatalogReferencenode.setAttribute('entryName', 'car_white');  
scenarioobjectnode.appendChild(CatalogReferencenode);
for i = 1 : count
    bool_obj = 0;
    for j = 1 : length(delete_object)
        if delete_object(j) == i
            bool_obj = 1;
            break;
        end
    end
    if bool_obj == 1
        continue;
    end
    scenarioobjectnode=docNode.createElement('ScenarioObject');
    scenarioobjectnode.setAttribute('name',strcat('S',string(i)));
    entitiesnode.appendChild(scenarioobjectnode);
    CatalogReferencenode=docNode.createElement('CatalogReference');
    CatalogReferencenode.setAttribute('catalogName', 'VehicleCatalog');
    CatalogReferencenode.setAttribute('entryName', 'car_red');  
    scenarioobjectnode.appendChild(CatalogReferencenode);
end
[m, ~] = size(init);
for i = 1 : m
    scenarioobjectnode=docNode.createElement('ScenarioObject');
    scenarioobjectnode.setAttribute('name',string(init{i, 2}));
    entitiesnode.appendChild(scenarioobjectnode);
    CatalogReferencenode=docNode.createElement('CatalogReference');
    CatalogReferencenode.setAttribute('catalogName', 'VehicleCatalog');
    CatalogReferencenode.setAttribute('entryName', string(init{i, 3}));  
    scenarioobjectnode.appendChild(CatalogReferencenode);
end

%% initialize the scenario
%------------------------------Storyboard--------------------------------------%
storyboardnode=docNode.createElement('Storyboard');
OpenSCENARIO.appendChild(storyboardnode);
%-------------initialize-------------%
initnode=docNode.createElement('Init');
storyboardnode.appendChild(initnode);
actionsnode=docNode.createElement('Actions');
initnode.appendChild(actionsnode);
%----environment----%
globalactionnode=docNode.createElement('GlobalAction');
actionsnode.appendChild(globalactionnode);
environmentactionnode=docNode.createElement('EnvironmentAction');
globalactionnode.appendChild(environmentactionnode);
environmentnode=docNode.createElement('Environment');
environmentactionnode.appendChild(environmentnode);
timeofdaynode=docNode.createElement('TimeOfDay');
timeofdaynode.setAttribute('animation','false');
timeofdaynode.setAttribute('dateTime','2020-02-21T12:00:00');
environmentnode.appendChild(timeofdaynode);
weathernode=docNode.createElement('Weather');
weathernode.setAttribute('cloudState','free');
environmentnode.appendChild(weathernode);
sunnode=docNode.createElement('Sun');
sunnode.setAttribute('intensity','1.0');
sunnode.setAttribute('azimuth','0.0');
sunnode.setAttribute('elevation','1.571');
weathernode.appendChild(sunnode);
fognode=docNode.createElement('Fog');
fognode.setAttribute('visualRange','100000.0');
weathernode.appendChild(fognode);
precipitationnode=docNode.createElement('Precipitation');
precipitationnode.setAttribute('precipitationType','dry');
precipitationnode.setAttribute('intensity','0.0');
weathernode.appendChild(precipitationnode);
roadconditionnode=docNode.createElement('RoadCondition');
roadconditionnode.setAttribute('frictionScaleFactor','1.0');
environmentnode.appendChild(roadconditionnode);
%----entity velocity----%
%the entities from bag
%ego
privatenode=docNode.createElement('Private');
privatenode.setAttribute('entityRef','Ego'); 
actionsnode.appendChild(privatenode);
%calculate the association between ego and objects:
%sc_start->ego_start, sc_end->ego_end
i = 1;
while map_objects{sc_start, 1}.Header.Stamp.Sec > vechInfo{i, 1}.Header.Stamp.Sec
    i = i + 1;
end
while map_objects{sc_start, 1}.Header.Stamp.Nsec > vechInfo{i, 1}.Header.Stamp.Nsec
    i = i + 1;
end
ego_start = i;
i = 1;
while map_objects{sc_end, 1}.Header.Stamp.Sec > vechInfo{i, 1}.Header.Stamp.Sec
    i = i + 1;
end
while map_objects{sc_end, 1}.Header.Stamp.Nsec > vechInfo{i, 1}.Header.Stamp.Nsec
    i = i + 1;
end
ego_end = i;
%the position of ego 
privateactionnode=docNode.createElement('PrivateAction');
privatenode.appendChild(privateactionnode);
teleportactionnode=docNode.createElement('TeleportAction');
privateactionnode.appendChild(teleportactionnode);
positionnode=docNode.createElement('Position');
worldpositionnode=docNode.createElement('WorldPosition'); 
worldpositionnode.setAttribute('x',string(vechInfo{ego_start, 1}.Pose.Position.X));
worldpositionnode.setAttribute('y',string(vechInfo{ego_start, 1}.Pose.Position.Y));
worldpositionnode.setAttribute('z','0');
positionnode.appendChild(worldpositionnode);
teleportactionnode.appendChild(positionnode);
%the position of others
for i = 1 : count
    bool_obj = 0;
    for j = 1 : length(delete_object)
        if delete_object(j) == i
            bool_obj = 1;
            break;
        end
    end
    if bool_obj == 1
        continue;
    end
    max = sc_end;
    for j = sc_start : sc_end
        if trajectory(A(i), j) == 0
            max = j - 1;
            break;
        end
    end
    privatenode=docNode.createElement('Private');
    privatenode.setAttribute('entityRef',strcat('S',string(i)));
    actionsnode.appendChild(privatenode);
    privateactionnode=docNode.createElement('PrivateAction');
    privatenode.appendChild(privateactionnode);
    teleportactionnode=docNode.createElement('TeleportAction');
    privateactionnode.appendChild(teleportactionnode);
    positionnode=docNode.createElement('Position');
    worldpositionnode=docNode.createElement('WorldPosition'); 
    worldpositionnode.setAttribute('x',string(map_objects{sc_start, 1}.Objects(trajectory(A(i), sc_start)).Pose.Position.X));
    worldpositionnode.setAttribute('y',string(map_objects{sc_start, 1}.Objects(trajectory(A(i), sc_start)).Pose.Position.Y));
    worldpositionnode.setAttribute('z','0');
    positionnode.appendChild(worldpositionnode);
    teleportactionnode.appendChild(positionnode);
end


% init that user defined
[m, ~] = size(init);
for i = 1: m
    privatenode=docNode.createElement('Private');
    privatenode.setAttribute('entityRef',string(init{i, 2}));
    actionsnode.appendChild(privatenode);
    privateactionnode=docNode.createElement('PrivateAction');
    privatenode.appendChild(privateactionnode);
    longitudinalactionnode=docNode.createElement('LongitudinalAction');
    privateactionnode.appendChild(longitudinalactionnode);
    speedactionnode=docNode.createElement('SpeedAction');
    longitudinalactionnode.appendChild(speedactionnode);
    speedactiondynamicsnode=docNode.createElement('SpeedActionDynamics');
    speedactiondynamicsnode.setAttribute('dynamicsShape','step');
    speedactiondynamicsnode.setAttribute('value','0');
    speedactiondynamicsnode.setAttribute('dynamicsDimension','time');
    speedactionnode.appendChild(speedactiondynamicsnode);
    speedactiontargetnode=docNode.createElement('SpeedActionTarget');
    absolutetragetspeednode=docNode.createElement('AbsoluteTargetSpeed');
    absolutetragetspeednode.setAttribute('value',string(init{i, 7}));
    speedactiontargetnode.appendChild(absolutetragetspeednode);
    speedactionnode.appendChild(speedactiontargetnode);
    %----entity position----%
    privateactionnode=docNode.createElement('PrivateAction');
    privatenode.appendChild(privateactionnode);
    teleportactionnode=docNode.createElement('TeleportAction');
    privateactionnode.appendChild(teleportactionnode);
    positionnode=docNode.createElement('Position');
    if init{i, 1} == "LanePosition"
        LanePositionnode=docNode.createElement('LanePosition');
        LanePositionnode.setAttribute('roadId',string(init{i, 4}));
        LanePositionnode.setAttribute('laneId',string(init{i, 5}));
        LanePositionnode.setAttribute('s',string(init{i, 6}));
        positionnode.appendChild(LanePositionnode);
        teleportactionnode.appendChild(positionnode);
    elseif init{i, 1} == "RelativeLanePosition"
        RelativeLanePositionnode=docNode.createElement('RelativeLanePosition');
        RelativeLanePositionnode.setAttribute('entityRef',string(init{i, 4}));
        RelativeLanePositionnode.setAttribute('ds',string(init{i, 6}));
        RelativeLanePositionnode.setAttribute('dLane',string(init{i, 5}));
        positionnode.appendChild(RelativeLanePositionnode);
        teleportactionnode.appendChild(positionnode);
    else
        worldpositionnode=docNode.createElement('WorldPosition');
        worldpositionnode.setAttribute('x',string(init{i, 4}));
        worldpositionnode.setAttribute('y',string(init{i, 5}));
        worldpositionnode.setAttribute('z',string(init{i, 6}));
        positionnode.appendChild(worldpositionnode);
        teleportactionnode.appendChild(positionnode);
    end
end
actnode_user = {};
[m, ~] = size(sim);
Bsim = [];
for i = 1 : m
    Bsim(i) = 0; 
end

%% establish the trajectories of objects in this scenario
%-------------Story-------------%
storynode=docNode.createElement('Story');
storynode.setAttribute('name','Mystory');
storyboardnode.appendChild(storynode);

%----Act from rosbag----%
%--ego car--%
%%%%%Act
event_ego = {};
actnode=docNode.createElement('Act');
actnode.setAttribute('name','Act0');
storynode.appendChild(actnode);
%%%%Act - ManeuverGroup
maneuvergroupnode=docNode.createElement('ManeuverGroup');
maneuvergroupnode.setAttribute('maximumExecutionCount','1');
maneuvergroupnode.setAttribute('name','Sequence0');
actnode.appendChild(maneuvergroupnode);
actorsnode=docNode.createElement('Actors'); 
actorsnode.setAttribute('selectTriggeringEntities','false');
maneuvergroupnode.appendChild(actorsnode);
entityrefnode=docNode.createElement('EntityRef');
entityrefnode.setAttribute('entityRef','Ego');  
actorsnode.appendChild(entityrefnode);
%%%Act - ManeuverGroup - Maneuver
maneuvernode=docNode.createElement('Maneuver');
maneuvernode.setAttribute('name','Maneuver0');
maneuvergroupnode.appendChild(maneuvernode);
%%Act - ManeuverGroup - Maneuver - Event
k = 1;
for j = 1 : length(Bsim)
    if sim{j, 2} == "Ego"
        eventnode=docNode.createElement('Event');
        eventnode.setAttribute('name',strcat('EventEgo',j));
        eventnode.setAttribute('priority','overwrite');
        if sim{j, 1} == "laneChange"
            event_ego{k} = laneChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
            k = k + 1;
        end
        if sim{j, 1} == "velocityChange"
            event_ego{k} = velocityChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
            k = k + 1;
        end
        if sim{j, 1} == "offsetChange"
            event_ego{k} = offsetChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
            k = k + 1;
        end
        Bsim(j) = 1;
    end
end
for j = 1 : length(event_ego)
    eventnode = event_ego{j};
    maneuvernode.appendChild(eventnode)
end
eventnode=docNode.createElement('Event');
eventnode.setAttribute('name','Event0');
eventnode.setAttribute('priority','overwrite');
maneuvernode.appendChild(eventnode)
%Act - ManeuverGroup - Maneuver - Event - Action
actionnode=docNode.createElement('Action');
actionnode.setAttribute('name','Action0');
eventnode.appendChild(actionnode);
privateactionnode=docNode.createElement('PrivateAction');
actionnode.appendChild(privateactionnode);
routingactionnode=docNode.createElement('RoutingAction');
privateactionnode.appendChild(routingactionnode);
followtrajectoryactionnode=docNode.createElement('FollowTrajectoryAction');
routingactionnode.appendChild(followtrajectoryactionnode);
%give the trajectory
trajectorynode=docNode.createElement('Trajectory');
trajectorynode.setAttribute('name','Trajectory0');
trajectorynode.setAttribute('closed','false');
followtrajectoryactionnode.appendChild(trajectorynode);
shapenode=docNode.createElement('Shape');
trajectorynode.appendChild(shapenode);
%Polyline
polylinenode=docNode.createElement('Polyline');
shapenode.appendChild(polylinenode);
for i = ego_start + 20 : 20 : ego_end
    vertexnode=docNode.createElement('Vertex');
    vertexnode.setAttribute('time',string((double(vechInfo{i , 1}.Header.Stamp.Sec - vechInfo{ego_start, 1}.Header.Stamp.Sec) + double(vechInfo{i, 1}.Header.Stamp.Nsec) * 0.000000001 - double(vechInfo{ego_start, 1}.Header.Stamp.Nsec) * 0.000000001)));
    polylinenode.appendChild(vertexnode);
    positionnode=docNode.createElement('Position');
    vertexnode.appendChild(positionnode);
    worldpositionnode=docNode.createElement('WorldPosition');
    worldpositionnode.setAttribute('x',string(vechInfo{i, 1}.Pose.Position.X));
    worldpositionnode.setAttribute('y',string(vechInfo{i, 1}.Pose.Position.Y));
    worldpositionnode.setAttribute('z','0');
    worldpositionnode.setAttribute('h', string(atan2(vechInfo{i, 1}.Pose.Position.Y - vechInfo{i - 20, 1}.Pose.Position.Y, vechInfo{i, 1}.Pose.Position.X - vechInfo{i - 20, 1}.Pose.Position.X)));
    positionnode.appendChild(worldpositionnode);
end
timereferencenode=docNode.createElement('TimeReference');
followtrajectoryactionnode.appendChild(timereferencenode);
timingnode=docNode.createElement('Timing');
timingnode.setAttribute('domainAbsoluteRelative','relative');
timingnode.setAttribute('scale','1.0');
timingnode.setAttribute('offset','0.0');
timereferencenode.appendChild(timingnode);
trajectoryfollowingmodenode=docNode.createElement('TrajectoryFollowingMode');
trajectoryfollowingmodenode.setAttribute('FollowingMode','follow');
followtrajectoryactionnode.appendChild(trajectoryfollowingmodenode);
%starttrigger-action
starttriggernode=docNode.createElement('StartTrigger');
eventnode.appendChild(starttriggernode);
conditiongroupnode=docNode.createElement('ConditionGroup');
starttriggernode.appendChild(conditiongroupnode);
conditionnode=docNode.createElement('Condition');
conditionnode.setAttribute('name','');
conditionnode.setAttribute('delay','0');
conditionnode.setAttribute('conditionEdge','none');
conditiongroupnode.appendChild(conditionnode);
byvalueconditionnode=docNode.createElement('ByValueCondition');
conditionnode.appendChild(byvalueconditionnode);
StoryboardElementStateConditionnode=docNode.createElement('StoryboardElementStateCondition');
StoryboardElementStateConditionnode.setAttribute('storyboardElementType','act');
StoryboardElementStateConditionnode.setAttribute('storyboardElementRef','Act0');
StoryboardElementStateConditionnode.setAttribute('state','startTransition');
byvalueconditionnode.appendChild(StoryboardElementStateConditionnode);
%starttrigger-manuegroup
starttriggernode=docNode.createElement('StartTrigger');
actnode.appendChild(starttriggernode);
conditiongroupnode=docNode.createElement('ConditionGroup');
starttriggernode.appendChild(conditiongroupnode);
conditionnode=docNode.createElement('Condition');
conditionnode.setAttribute('name','StartCondition1');
conditionnode.setAttribute('delay','0');
conditionnode.setAttribute('conditionEdge','rising');
conditiongroupnode.appendChild(conditionnode);
byvalueconditionnode=docNode.createElement('ByValueCondition');
conditionnode.appendChild(byvalueconditionnode);
simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
simulationtimeconditionnode.setAttribute('value','0');
simulationtimeconditionnode.setAttribute('rule','greaterThan');
byvalueconditionnode.appendChild(simulationtimeconditionnode);

%--other car--%
for i = 1 : count
    bool_obj = 0;
    for j = 1 : length(delete_object)
        if delete_object(j) == i
            bool_obj = 1;
            break;
        end
    end
    if bool_obj == 1
        continue;
    end
    %%%%%Act
    actnode=docNode.createElement('Act');
    actnode.setAttribute('name',strcat('Act', string(i)));
    storynode.appendChild(actnode);
    %%%%Act - ManeuverGroup
    maneuvergroupnode=docNode.createElement('ManeuverGroup');
    maneuvergroupnode.setAttribute('maximumExecutionCount','1');
    maneuvergroupnode.setAttribute('name',strcat('Sequence', string(i)));
    actnode.appendChild(maneuvergroupnode);
    actorsnode=docNode.createElement('Actors'); 
    actorsnode.setAttribute('selectTriggeringEntities','false');
    maneuvergroupnode.appendChild(actorsnode);
    entityrefnode=docNode.createElement('EntityRef');
    entityrefnode.setAttribute('entityRef',strcat('S', string(i))); 
    actorsnode.appendChild(entityrefnode);
    %%%Act - ManeuverGroup - Maneuver
    maneuvernode=docNode.createElement('Maneuver');
    maneuvernode.setAttribute('name',strcat('Maneuver', string(i)));
    maneuvergroupnode.appendChild(maneuvernode);
    %%Act - ManeuverGroup- Maneuver - Event
    event_obj = {};
    j = 1;
    for k = 1 : length(Bsim)
        if Bsim(k) == 1
            continue;
        end
        if sim{k, 2} == strcat('S', string(i))
            eventnode=docNode.createElement('Event');
            eventnode.setAttribute('name',strcat('Event',string(i), string(k)));
            eventnode.setAttribute('priority','overwrite');
            if sim{k, 1} == "laneChange"
                event_obj{j} = laneChange(sim{k, 2}, sim{k, 3}, sim{k, 4}, sim{k, 5}, sim{k, 6}, docNode, k);
                j = j + 1;
            end
            if sim{k, 1} == "velocityChange"
                event_obj{j} = velocityChange(sim{k, 2}, sim{k, 3}, sim{k, 4}, sim{k, 5}, sim{k, 6}, docNode, k);
                j = j + 1;
            end
            if sim{k, 1} == "offsetChange"
                event_obj{j} = offsetChange(sim{k, 2}, sim{k, 3}, sim{k, 4}, sim{k, 5}, sim{k, 6}, docNode, k);
                j = j + 1;
            end
            Bsim(k) = 1;
        end
    end
    for k = 1 : length(event_obj)
        eventnode = event_obj{k};
        maneuvernode.appendChild(eventnode)
    end
    eventnode=docNode.createElement('Event');
    eventnode.setAttribute('name',strcat('Event', string(i)));
    eventnode.setAttribute('priority','overwrite');
    maneuvernode.appendChild(eventnode)
    %Act - ManeuverGroup - Maneuver - Event - Action
    actionnode=docNode.createElement('Action');
    actionnode.setAttribute('name',strcat('Action', string(i)));
    eventnode.appendChild(actionnode);
    privateactionnode=docNode.createElement('PrivateAction');
    actionnode.appendChild(privateactionnode);
    routingactionnode=docNode.createElement('RoutingAction');
    privateactionnode.appendChild(routingactionnode);
    followtrajectoryactionnode=docNode.createElement('FollowTrajectoryAction');
    routingactionnode.appendChild(followtrajectoryactionnode);
    %trajectory
    trajectorynode=docNode.createElement('Trajectory');
    trajectorynode.setAttribute('name',strcat('Trajectory',string(i)));
    trajectorynode.setAttribute('closed','false');
    followtrajectoryactionnode.appendChild(trajectorynode);
    shapenode=docNode.createElement('Shape');
    trajectorynode.appendChild(shapenode);
    %Polyline
    polylinenode=docNode.createElement('Polyline');
    shapenode.appendChild(polylinenode);
    %j
    max = sc_end;
    for j = sc_start : sc_end
        if trajectory(A(i), j) == 0
            max = j - 1;
            break;
        end
    end
    for j = sc_start + 1 : max
        vertexnode=docNode.createElement('Vertex');
        vertexnode.setAttribute('time',string((double(map_objects{j, 1}.Header.Stamp.Sec - map_objects{sc_start, 1}.Header.Stamp.Sec) + double(map_objects{j, 1}.Header.Stamp.Nsec) * 0.000000001 - double(map_objects{sc_start, 1}.Header.Stamp.Nsec) * 0.000000001)));
        polylinenode.appendChild(vertexnode);
        positionnode=docNode.createElement('Position');
        vertexnode.appendChild(positionnode);
        worldpositionnode=docNode.createElement('WorldPosition');
        worldpositionnode.setAttribute('x',string(map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Position.X));
        worldpositionnode.setAttribute('y',string(map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Position.Y));
        worldpositionnode.setAttribute('z','0');
        %[yaw_o, pitch_o, roll_o] = quat2angle([map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Orientation.X, map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Orientation.Y, map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Orientation.Z, map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Orientation.W]);
        worldpositionnode.setAttribute('h', string(string(atan2(map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Position.Y - map_objects{j - 1, 1}.Objects(trajectory(A(i), j - 1)).Pose.Position.Y, map_objects{j, 1}.Objects(trajectory(A(i), j)).Pose.Position.X - map_objects{j - 1, 1}.Objects(trajectory(A(i), j - 1)).Pose.Position.X))));
        positionnode.appendChild(worldpositionnode);
    end

    timereferencenode=docNode.createElement('TimeReference');
    followtrajectoryactionnode.appendChild(timereferencenode);
    timingnode=docNode.createElement('Timing');
    timingnode.setAttribute('domainAbsoluteRelative','relative');
    timingnode.setAttribute('scale','1.0');
    timingnode.setAttribute('offset','0.0');
    timereferencenode.appendChild(timingnode);
    trajectoryfollowingmodenode=docNode.createElement('TrajectoryFollowingMode');
    trajectoryfollowingmodenode.setAttribute('FollowingMode','follow');
    followtrajectoryactionnode.appendChild(trajectoryfollowingmodenode);
    %starttrigger of Action
    starttriggernode=docNode.createElement('StartTrigger');
    eventnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','none');
    conditiongroupnode.appendChild(conditionnode);
    byvalueconditionnode=docNode.createElement('ByValueCondition');
    conditionnode.appendChild(byvalueconditionnode);
    StoryboardElementStateConditionnode=docNode.createElement('StoryboardElementStateCondition');
    StoryboardElementStateConditionnode.setAttribute('storyboardElementType','act');
    StoryboardElementStateConditionnode.setAttribute('storyboardElementRef',strcat('Act',string(i)));
    StoryboardElementStateConditionnode.setAttribute('state','startTransition');
    byvalueconditionnode.appendChild(StoryboardElementStateConditionnode);

    %starttrigger of manuver
    starttriggernode=docNode.createElement('StartTrigger');
    actnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','StartCondition1');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','rising');
    conditiongroupnode.appendChild(conditionnode);
    byvalueconditionnode=docNode.createElement('ByValueCondition');
    conditionnode.appendChild(byvalueconditionnode);
    simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
    simulationtimeconditionnode.setAttribute('value','0');
    simulationtimeconditionnode.setAttribute('rule','greaterThan');
    byvalueconditionnode.appendChild(simulationtimeconditionnode);
end

%----Act from user----%
for i = 1 : length(Bsim)
    if Bsim(i) == 1
        continue;
    end
    event_obju = {};
    k = 1;
    %%%%%Act
    actnode=docNode.createElement('Act');
    actnode.setAttribute('name',strcat('Act', sim{i, 2}));
    storynode.appendChild(actnode);
    %%%%Act - ManeuverGroup
    maneuvergroupnode=docNode.createElement('ManeuverGroup');
    maneuvergroupnode.setAttribute('maximumExecutionCount','1');
    maneuvergroupnode.setAttribute('name',strcat('Sequence', sim{i, 2}));
    actnode.appendChild(maneuvergroupnode);
    actorsnode=docNode.createElement('Actors'); 
    actorsnode.setAttribute('selectTriggeringEntities','false');
    maneuvergroupnode.appendChild(actorsnode);
    entityrefnode=docNode.createElement('EntityRef');
    entityrefnode.setAttribute('entityRef',sim{i, 2}); 
    actorsnode.appendChild(entityrefnode);
    %%%Act - ManeuverGroup - Maneuver
    maneuvernode=docNode.createElement('Maneuver');
    maneuvernode.setAttribute('name',strcat('Maneuver', sim{i, 2}));
    maneuvergroupnode.appendChild(maneuvernode);
    %%Act - ManeuverGroup- Maneuver - Event
    for j = i : length(Bsim)
        if Bsim(j) == 1
            continue;
        end
        if string(sim{j, 2}) == string(sim{i, 2})
            eventnode=docNode.createElement('Event');
            eventnode.setAttribute('name',strcat('Event',string(i), string(j)));
            eventnode.setAttribute('priority','overwrite');
            if sim{j, 1} == "laneChange"
                event_obju{k} = laneChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
                k = k + 1;
            end
            if sim{j, 1} == "velocityChange"
                event_obju{k} = velocityChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
                k = k + 1;
            end
            if sim{j, 1} == "offsetChange"
                event_obju{k} = offsetChange(sim{j, 2}, sim{j, 3}, sim{j, 4}, sim{j, 5}, sim{j, 6}, docNode, j);
                k = k + 1;
            end
            Bsim(j) = 1;
        end
    end
    for j = 1 : length(event_obju)
        eventnode = event_obju{j};
        maneuvernode.appendChild(eventnode)
    end
    %starttrigger of manuver
    starttriggernode=docNode.createElement('StartTrigger');
    actnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','StartCondition1');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','rising');
    conditiongroupnode.appendChild(conditionnode);
    byvalueconditionnode=docNode.createElement('ByValueCondition');
    conditionnode.appendChild(byvalueconditionnode);
    simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
    simulationtimeconditionnode.setAttribute('value','0');
    simulationtimeconditionnode.setAttribute('rule','greaterThan');
    byvalueconditionnode.appendChild(simulationtimeconditionnode);
end


%+++++stoptrigger++++++
stoptriggernode=docNode.createElement('StopTrigger');
storyboardnode.appendChild(stoptriggernode);

xmlwrite(file_name, docNode);
type(file_name);

%% this function is used for user defined actions
function eventnode = laneChange(entityRef, isTime, relative, target, dynamicValue, docNode, Num)
    %%Act - ManeuverGroup- Maneuver- Event
    eventnode=docNode.createElement('Event');
    eventnode.setAttribute('name',strcat('Event', strcat(string(entityRef),string(Num))));
    eventnode.setAttribute('priority','overwrite');
    %Act - ManeuverGroup - Maneuver - Event - Action
    actionnode=docNode.createElement('Action');
    actionnode.setAttribute('name',strcat('Action', strcat(string(entityRef),string(Num))));
    eventnode.appendChild(actionnode);
    privateactionnode=docNode.createElement('PrivateAction');
    actionnode.appendChild(privateactionnode);
    LateralActionnode=docNode.createElement('LateralAction');
    privateactionnode.appendChild(LateralActionnode);
    LaneChangeActionactionnode=docNode.createElement('LaneChangeAction');
    LateralActionnode.appendChild(LaneChangeActionactionnode);

    LaneChangeActionDynamicsnode=docNode.createElement('LaneChangeActionDynamics');
    LaneChangeActionDynamicsnode.setAttribute('dynamicsShape', 'sinusoidal');
    LaneChangeActionDynamicsnode.setAttribute('value',string(dynamicValue));
    LaneChangeActionDynamicsnode.setAttribute('dynamicsDimension', 'time');
    LaneChangeActionactionnode.appendChild(LaneChangeActionDynamicsnode);
    LaneChangeTargetnode=docNode.createElement('LaneChangeTarget');
    LaneChangeActionactionnode.appendChild(LaneChangeTargetnode);
    RelativeTargetLanenode=docNode.createElement('RelativeTargetLane');
    RelativeTargetLanenode.setAttribute('entityRef',string(entityRef));
    RelativeTargetLanenode.setAttribute('value',string(target));
    LaneChangeTargetnode.appendChild(RelativeTargetLanenode);


    %+++++starttrigger-Action++++++
    starttriggernode=docNode.createElement('StartTrigger');
    eventnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','StartCondition1');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','rising');
    conditiongroupnode.appendChild(conditionnode);
    if isTime > 0
        byvalueconditionnode=docNode.createElement('ByValueCondition');
        conditionnode.appendChild(byvalueconditionnode);
        simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
        simulationtimeconditionnode.setAttribute('value',string(relative));
        simulationtimeconditionnode.setAttribute('rule','greaterThan');
        byvalueconditionnode.appendChild(simulationtimeconditionnode);
        conditionnode.appendChild(byvalueconditionnode);
    else
        byentityconditionnode=docNode.createElement('ByEntityCondition');
        triggeringentitiesnode=docNode.createElement('TriggeringEntities');
        triggeringentitiesnode.setAttribute('triggeringEntitiesRule','any');
        byentityconditionnode.appendChild(triggeringentitiesnode);
        entityrefnode=docNode.createElement('EntityRef');
        entityrefnode.setAttribute('entityRef',string(entityRef));
        triggeringentitiesnode.appendChild(entityrefnode);
        EntityConditionnode=docNode.createElement('EntityCondition');
        byentityconditionnode.appendChild(EntityConditionnode);
        distanceconditionnode=docNode.createElement('DistanceCondition');
        if relative > 0 
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','greaterThan');
        elseif relative < 0
            distanceconditionnode.setAttribute('value',string(-relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','lessThan');
        else
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','equalTo');
        end
        EntityConditionnode.appendChild(distanceconditionnode);
        positionnode=docNode.createElement('Position');
        distanceconditionnode.appendChild(positionnode);
        relativeobjectpositionnode=docNode.createElement('RelativeObjectPosition');
        relativeobjectpositionnode.setAttribute('entityRef','Ego');
        relativeobjectpositionnode.setAttribute('dx','0');
        relativeobjectpositionnode.setAttribute('dy','0');
        positionnode.appendChild(relativeobjectpositionnode);
        conditionnode.appendChild(byentityconditionnode);
    end
end

function eventnode = offsetChange(entityRef, isTime, relative, target, dynamicValue, docNode, Num)
    %%Act - ManeuverGroup- Maneuver- Event
    eventnode=docNode.createElement('Event');
    eventnode.setAttribute('name',strcat('Event', strcat(string(entityRef),string(Num))));
    eventnode.setAttribute('priority','overwrite');
    %Act - ManeuverGroup - Maneuver - Event - Action
    actionnode=docNode.createElement('Action');
    actionnode.setAttribute('name',strcat('Action', strcat(string(entityRef),string(Num))));
    eventnode.appendChild(actionnode);
    privateactionnode=docNode.createElement('PrivateAction');
    actionnode.appendChild(privateactionnode);
    LateralActionnode=docNode.createElement('LateralAction');
    privateactionnode.appendChild(LateralActionnode);
    LaneOffsetActionnode=docNode.createElement('LaneOffsetAction');
    LateralActionnode.appendChild(LaneOffsetActionnode);
    LaneOffsetActionnode.setAttribute('continuous', 'false');
    LaneOffsetActionDynamicsnode=docNode.createElement('LaneOffsetActionDynamics');
    LaneOffsetActionDynamicsnode.setAttribute('dynamicsShape', 'sinusoidal');
    LaneOffsetActionDynamicsnode.setAttribute('maxLateralAcc',string(dynamicValue));
    LaneOffsetActionnode.appendChild(LaneOffsetActionDynamicsnode);
    LaneOffsetTargetnode=docNode.createElement('LaneOffsetTarget');
    LaneOffsetActionnode.appendChild(LaneOffsetTargetnode);
    AbsoluteTargetLaneOffsetnode=docNode.createElement('AbsoluteTargetLaneOffset');
    AbsoluteTargetLaneOffsetnode.setAttribute('value',string(target));
    LaneOffsetTargetnode.appendChild(AbsoluteTargetLaneOffsetnode);


    %+++++starttrigger-Action++++++
    starttriggernode=docNode.createElement('StartTrigger');
    eventnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','StartCondition1');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','rising');
    conditiongroupnode.appendChild(conditionnode);
    if isTime > 0
        byvalueconditionnode=docNode.createElement('ByValueCondition');
        conditionnode.appendChild(byvalueconditionnode);
        simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
        simulationtimeconditionnode.setAttribute('value',string(relative));
        simulationtimeconditionnode.setAttribute('rule','greaterThan');
        byvalueconditionnode.appendChild(simulationtimeconditionnode);
        conditionnode.appendChild(byvalueconditionnode);
    else
        byentityconditionnode=docNode.createElement('ByEntityCondition');
        triggeringentitiesnode=docNode.createElement('TriggeringEntities');
        triggeringentitiesnode.setAttribute('triggeringEntitiesRule','any');
        byentityconditionnode.appendChild(triggeringentitiesnode);
        entityrefnode=docNode.createElement('EntityRef');
        entityrefnode.setAttribute('entityRef',string(entityRef));
        triggeringentitiesnode.appendChild(entityrefnode);
        EntityConditionnode=docNode.createElement('EntityCondition');
        byentityconditionnode.appendChild(EntityConditionnode);
        distanceconditionnode=docNode.createElement('DistanceCondition');
        if relative > 0 
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','greaterThan');
        elseif relative < 0
            distanceconditionnode.setAttribute('value',string(-relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','lessThan');
        else
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','equalTo');
        end
        EntityConditionnode.appendChild(distanceconditionnode);
        positionnode=docNode.createElement('Position');
        distanceconditionnode.appendChild(positionnode);
        relativeobjectpositionnode=docNode.createElement('RelativeObjectPosition');
        relativeobjectpositionnode.setAttribute('entityRef','Ego');
        relativeobjectpositionnode.setAttribute('dx','0');
        relativeobjectpositionnode.setAttribute('dy','0');
        positionnode.appendChild(relativeobjectpositionnode);
        conditionnode.appendChild(byentityconditionnode);
    end
end

function eventnode = velocityChange(entityRef, isTime, relative, target, dynamicValue, docNode, Num)
    %%Acti - ManeuverGroupi - Maneuver - Eventi
    eventnode=docNode.createElement('Event');
    eventnode.setAttribute('name',strcat('Event', strcat(string(entityRef),string(Num))));
    eventnode.setAttribute('priority','overwrite');
    %Act - ManeuverGroup - Maneuver - Event - Action
    actionnode=docNode.createElement('Action');
    actionnode.setAttribute('name',strcat('Action', strcat(string(entityRef),string(Num))));
    eventnode.appendChild(actionnode);
    privateactionnode=docNode.createElement('PrivateAction');
    actionnode.appendChild(privateactionnode);
    LongitudinalActionnode=docNode.createElement('LongitudinalAction');
    privateactionnode.appendChild(LongitudinalActionnode);
    SpeedActionnode=docNode.createElement('SpeedAction');
    LongitudinalActionnode.appendChild(SpeedActionnode);

    SpeedActionDynamicsnode=docNode.createElement('SpeedActionDynamics');
    SpeedActionDynamicsnode.setAttribute('dynamicsShape', 'linear');
    SpeedActionDynamicsnode.setAttribute('value',string(dynamicValue));
    SpeedActionDynamicsnode.setAttribute('dynamicsDimension', 'time');
    SpeedActionnode.appendChild(SpeedActionDynamicsnode);
    SpeedActionTargetnode=docNode.createElement('SpeedActionTarget');
    SpeedActionnode.appendChild(SpeedActionTargetnode);
    AbsoluteTargetSpeednode=docNode.createElement('AbsoluteTargetSpeed');
    AbsoluteTargetSpeednode.setAttribute('value',string(target));
    SpeedActionTargetnode.appendChild(AbsoluteTargetSpeednode);

    %+++++starttrigger-Action++++++
    starttriggernode=docNode.createElement('StartTrigger');
    eventnode.appendChild(starttriggernode);
    conditiongroupnode=docNode.createElement('ConditionGroup');
    starttriggernode.appendChild(conditiongroupnode);
    conditionnode=docNode.createElement('Condition');
    conditionnode.setAttribute('name','StartCondition1');
    conditionnode.setAttribute('delay','0');
    conditionnode.setAttribute('conditionEdge','rising');
    conditiongroupnode.appendChild(conditionnode);
    if isTime > 0
        byvalueconditionnode=docNode.createElement('ByValueCondition');
        conditionnode.appendChild(byvalueconditionnode);
        simulationtimeconditionnode=docNode.createElement('SimulationTimeCondition');
        simulationtimeconditionnode.setAttribute('value',string(relative));
        simulationtimeconditionnode.setAttribute('rule','greaterThan');
        byvalueconditionnode.appendChild(simulationtimeconditionnode);
        conditionnode.appendChild(byvalueconditionnode);
    else
        byentityconditionnode=docNode.createElement('ByEntityCondition');
        triggeringentitiesnode=docNode.createElement('TriggeringEntities');
        triggeringentitiesnode.setAttribute('triggeringEntitiesRule','any');
        byentityconditionnode.appendChild(triggeringentitiesnode);
        entityrefnode=docNode.createElement('EntityRef');
        entityrefnode.setAttribute('entityRef',string(entityRef));
        triggeringentitiesnode.appendChild(entityrefnode);
        EntityConditionnode=docNode.createElement('EntityCondition');
        byentityconditionnode.appendChild(EntityConditionnode);
        distanceconditionnode=docNode.createElement('DistanceCondition');
        if relative > 0 
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','greaterThan');
        elseif relative < 0
            distanceconditionnode.setAttribute('value',string(-relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','lessThan');
        else
            distanceconditionnode.setAttribute('value',string(relative));
            distanceconditionnode.setAttribute('freespace','false');
            distanceconditionnode.setAttribute('alongRoute','false');
            distanceconditionnode.setAttribute('rule','equalTo');
        end
        EntityConditionnode.appendChild(distanceconditionnode);
        positionnode=docNode.createElement('Position');
        distanceconditionnode.appendChild(positionnode);
        relativeobjectpositionnode=docNode.createElement('RelativeObjectPosition');
        relativeobjectpositionnode.setAttribute('entityRef','Ego');
        relativeobjectpositionnode.setAttribute('dx','0');
        relativeobjectpositionnode.setAttribute('dy','0');
        positionnode.appendChild(relativeobjectpositionnode);
        conditionnode.appendChild(byentityconditionnode);
    end
end

