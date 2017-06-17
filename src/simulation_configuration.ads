package Simulation_Configuration is
   type Measurable is digits 8;

   Wall_Stiffness : constant Measurable := 50.0;
   Gravity : constant Measurable := 0.0;
   Width : constant Measurable := 20.0;
   Height : constant Measurable := 20.0;
   Depth : constant Measurable := 20.0;

   type Particle_Group_Ix is mod 4;
   type Particles_Per_Task is range 1 .. 1000;

end Simulation_Configuration;
