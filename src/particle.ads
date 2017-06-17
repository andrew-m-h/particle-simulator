with Simulation_Configuration; use Simulation_Configuration;
with Vectors_xD;

generic
   type Particles_Ix is range <>;

package Particle is

   type M_Coordinates is (x, y, z);
   package Vectors_3D_Mi is new Vectors_xD (Measurable, M_Coordinates);
   use Vectors_3D_Mi;

   subtype Vector_3D_M is Vectors_3D_Mi.Vector_xD;

   subtype Position is Vector_3D_M;
   subtype Velocity is Vector_3D_M;
   subtype Acceleration is Vector_3D_M;

   type Positions is array (Particles_Ix) of Position;
   type Global_Positions is array (Particle_Group_Ix) of Positions;

   subtype Velocities is Positions;
   subtype Global_Velocities is Global_Positions;

   task type Particle_Group is
      entry Initialise (
                       Task_Id : in Particle_Group_Ix;
                       Time : in Measurable
                      );
      entry Begin_Update;
      entry Neighbour_Positions (
                                 From_Id : in Particle_Group_Ix;
                                 Pos : in Positions);
      entry Finalise;
      entry Report_Position (Pos : out Positions);
      entry Report_Velocity (Vel : out Velocities);
   end Particle_Group;

   Particle_Tasks : array (Particle_Group_Ix) of Particle_Group;

   type Particle is
     record
        Pos : Position;
        Vel : Velocity := Vectors_3D_Mi.Zero_Vector_xD;
        Acc : Acceleration := Vectors_3D_Mi.Zero_Vector_xD;
     end record;

   procedure Update_Position (Dt : in Measurable; P : in out Particle);
   procedure Update_Velocity (Dt : in Measurable; P : in out Particle);
   procedure Update_Acceleration (Pos : access constant Global_Positions;
                                  P : in out Particle);
end Particle;
