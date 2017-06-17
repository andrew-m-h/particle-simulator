with Simulation_Configuration; use Simulation_Configuration;
with Particle;

with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
   package Particle_Sim is new Particle (Particles_Per_Task);
   use Particle_Sim;

   Particle_Positions : Global_Positions;
begin
   for I in Particle_Tasks'Range loop
      Particle_Tasks (I).Initialise (I, 0.02);
   end loop;

   for I in 0 .. 300 loop
      for P in Particle_Tasks'Range loop
         Particle_Tasks (P).Begin_Update;
      end loop;
   end loop;

   for I in Particle_Tasks'Range loop
      Particle_Tasks (I).Report_Position (Particle_Positions (I));
   end loop;

   for I in Particle_Positions'Range loop
      for J in Particles_Per_Task loop
         Put_Line (Vectors_3D_Mi.Image (Particle_Positions (I)(J)));
      end loop;
   end loop;

   for I in Particle_Tasks'Range loop
      Particle_Tasks (I).Finalise;
   end loop;

end Main;
