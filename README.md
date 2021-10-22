1. This code is used for conversion of Rosbag into Openscenario.

2. Please play the file "Conventer_rosbag2Openscenario.m"

3. The file "bagdata.mat" is an example of Rosbag data in mat-format. You can use this example without Rosbag file. If you use this example, please delete line 1 and line 128-135 in the code.

4. The file "example_scenario.xosc" is an example of converted OpenScenario file.

5. The file "A5_final_RFoffset.xodr" is an example of OpenDRIVE map, that the example scenario uses.

6. You can change the parameters in this code. These parameters are declared in the code.

7. The name of ego-vehicle in this scenario is "Ego". The name of other objects are "S1", "S2", "S3"...

8. Parameter declaration:
  <1>"bag_name": the path includes name of Rosbag. 
  <2>"path_vehicleCatalog": the path of vehicle calalog. 
  <3>"path_map": the path of OpenDRIVE map. 
  <4>"file_name": the converted OpenSCENARIO file name. 
  <5>"filter": an integer, that filters the objects. The number of timestamps of these objects are smaller than this value. 
  <6>"start_time": the second in Rosbag, that this scenario begins. 
  <7>"end_time": the second in Rosbag, that this scenario ends. 
  <8>"delete_object": an array for deleting objects. If you want to delete "S2", just put 2 in this array.
  <9>"init": a table used for adding objects in this scenario. 
  <10>"sim": a table used for defining actions in this scenario. 

9. Explaination of parameters in "init". If you want to add more objects, put theirs parameters in different rows.
  <1>first parameter: (string) the method to locate the object. There are three methods, "RelativeLanePosition", "WorldPosition" and "LanePosition".
  <2>second parameter: (string) the name of the object.
  <3>third parameter: (string) the type of the object.
  <4, 5, 6>fourth fifth and sixth parameters: the position of object, more details see below.
  <7>seventh parameter : (double) the velocity of the object. Unit is meter pro second.

10. location method "WorldPosition":
  <4>forth parameter: (double) x-coordinate. Unit is meter.
  <5>fifth parameter: (double) y-coordinate. Unit is meter.
  <6>sixth parameter: (double) z-coordinate. Unit is meter.

11. location method "RelativeLanePosition":
  <4>forth parameter: (string) the name of relative object. 
  <5>fifth parameter: (int) the relative lane number. Left to the relative object use positive value. For example, -2 means on the lane, which in the right second lane to the relative object.
  <6>sixth parameter: (double) the s-coordinate of Frenet relative to the relative object. 0 means their s-coordinate is same.
12. location method "LanePosition":
  <4>forth parameter: (int) road number.
  <5>fifth parameter: (int) lane number.
  <6>sixth parameter: (double) s-coordinate of Frenet. Unit is meter.

13. Explaination of parameters in "sim". If you want to add more actions, put theirs parameters in different rows. An object can be defined more than 1 actions.
  <1>first parameter: (string) the name of action. There are three actions, "laneChange", "velocityChange" and "velocityChange".
  <2>second parameter: (string) actor name.
  <3, 4>third and fourth parameters: trigger of start of the action. There are two trigger, "timetrigger" and "distancetrigger". More details see below.
  <5, 6>fifth and sixth parameters: the parameters of the action, more details see below.

14. "timetrigger":
  <3>third parameter: (boolean) use 1 here. Indicate this is a "timetrigger".
  <4>fourth parameter: (double) scenario time, that the action will be activited.

15. "distancetrigger":
  <3>third parameter: (boolean) use 0 here. Indicate this is a "distancetrigger".
  <4>fourth parameter: (double) distance between ego-vehicle and the actor. Positive value means greater than. Negative value means less than. If the distance greater than or less than this value, the action will be activated.

16. action "laneChange":
  <5>fifth parameter: (int) the target lane will be reached. Positive means left. For example -2 means drive to the second lane in the right.
  <6>sixth parameter: (double) the time long between the start of action and end of action.

17. action "offsetChange":
  <5>fifth parameter: (double) the target offset will be reached. Positive means left.
  <6>sixth parameter: (double) the maximal lateral acceleration for reach the offset.

18. action "velocityChange":
  <5>fifth parameter: (double) the target velocity will be reached. Unit is meter pro second.
  <6>sixth parameter: (double) the time long between the start of action and end of action. Acceleration is (targetvelocity - currentvelocity)/time
