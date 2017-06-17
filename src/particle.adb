package body Particle is
   procedure Update_Position (Dt : in Measurable; P : in out Particle) is
   begin
      P.Pos := P.Pos + P.Vel * Dt + (0.5 * Dt * Dt * P.Acc);
   end Update_Position;

   procedure Update_Velocity (Dt : in Measurable; P : in out Particle) is
   begin
      P.Vel := P.Vel + P.Acc * (Dt * 0.5);
   end Update_Velocity;

   procedure Update_Acceleration (Pos : access constant Global_Positions;
                                  P : in out Particle) is
   begin
      if P.Pos (x) < 0.5 then
         P.Acc (x) := Wall_Stiffness * (0.5 - P.Pos (x));
      elsif P.Pos (x) > (Width - 0.5) then
         P.Acc (x) := Wall_Stiffness * (Width - 0.5 - P.Pos (x));
      else
         P.Acc (x) := 0.0;
      end if;

      if P.Pos (y) < 0.5 then
         P.Acc (y) := Wall_Stiffness * (0.5 - P.Pos (y));
      elsif P.Pos (y) > (Height - 0.5) then
         P.Acc (y) := Wall_Stiffness * (Height - 0.5 - P.Pos (y));
      else
         P.Acc (y) := 0.0;
      end if;

      if P.Pos (z) < 0.5 then
         P.Acc (z) := Wall_Stiffness * (0.5 - P.Pos (z));
      elsif P.Pos (z) > (Depth - 0.5) then
         P.Acc (z) := Wall_Stiffness * (Depth - 0.5 - P.Pos (z));
      else
         P.Acc (z) := 0.0;
      end if;

      for T in Pos'Range loop
         for N in Particles_Ix loop
            declare
               R : constant Position := P.Pos - Pos (T)(N);
               Inv_R_Squared : Measurable;

               F : Acceleration;
               Attract, Repel : Measurable;
            begin
               if abs R > 1.0 then
                  Inv_R_Squared := 1.0 / (R * R);
                  Attract := Inv_R_Squared * Inv_R_Squared * Inv_R_Squared;
                  Repel := Attract * Attract;
                  F := (24.0 * ((2.0 * Repel) - Attract) * Inv_R_Squared) * R;
                  P.Acc := P.Acc + F;
               end if;
            end;
         end loop;
      end loop;

      P.Acc (y) := P.Acc (y) - Gravity;
   end Update_Acceleration;

   task body Particle_Group is
      Particles : array (Particles_Ix) of Particle;
      Dt : Measurable := Measurable'Invalid_Value;
      Id : Particle_Group_Ix := Particle_Group_Ix'Invalid_Value;

      Particle_Positions : aliased Global_Positions;
      Local_Positions : Positions;

   begin
      accept Initialise (
                        Task_Id : in Particle_Group_Ix;
                        Time : in Measurable
                       ) do
         Id := Task_Id;
         Dt := Time;
      end Initialise;

      for I in Particles'Range loop
         declare
            Pid : constant Integer := Integer (Id)
              * Integer (Particles_Ix'Last) + Integer (I);
            W : constant Integer := Integer (Width);
            H : constant Integer := Integer (Height);
            D : constant Integer := Integer (Depth);
         begin
            Particles (I).Pos := (
                                 Measurable (Pid mod W),
                                 Measurable ((Pid / W) mod H),
                                 Measurable ((Pid / W / H) mod D)
                                 );
         end;
      end loop;

      Outer : loop
         declare
         begin
            select
               accept Begin_Update;

               for P in Particles'Range loop
                  Update_Position (Dt, Particles (P));
                  Update_Velocity (Dt, Particles (P));
                  Local_Positions (P) := Particles (P).Pos;
               end loop;
               Particle_Positions (Id) := Local_Positions;

               for I in Particle_Tasks'Range loop
                  declare
                     Incoming_Id : Particle_Group_Ix :=
                       Particle_Group_Ix'Invalid_Value;
                     Incoming_Pos : Positions;
                  begin

                     if I = Id then
                        Particle_Tasks (Id + 1)
                          .Neighbour_Positions (Id, Local_Positions);
                     end if;

                     accept
                       Neighbour_Positions (
                                            From_Id : in Particle_Group_Ix;
                                            Pos : in Positions) do
                        Incoming_Id := From_Id;
                        Incoming_Pos := Pos;
                     end Neighbour_Positions;

                     if Incoming_Id /= Id then
                        Particle_Tasks (Id + 1)
                          .Neighbour_Positions (Incoming_Id, Incoming_Pos);
                        Particle_Positions (Incoming_Id) := Incoming_Pos;
                     end if;
                  end;
               end loop;

               for I in Particles'Range loop
                  Update_Acceleration (Particle_Positions'Access,
                                       Particles (I));
                  Update_Velocity (Dt, Particles (I));
               end loop;
            or
               accept Finalise;
               exit Outer;
            or
               accept Report_Position (Pos : out Positions) do
                  Pos := Local_Positions;
               end Report_Position;
            or
               accept Report_Velocity (Vel : out Positions) do
                  for I in Particles'Range loop
                     Vel (I) := Particles (I).Vel;
                  end loop;
               end Report_Velocity;
            end select;
         end;
      end loop Outer;

   end Particle_Group;
end Particle;
