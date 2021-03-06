--
--   Jan & Uwe R. Zimmer, Australia, July 2011
--

--  with Arrow_P, Cube_P, Duck_P, Plane_P, Spaceship_P, Sphere_P;
with Sphere_P;

with Float_Type;    use Float_Type;
with Vectors_4D;    use Vectors_4D;

with GL;
with GL.Materials;  use GL.Materials;

package body Models is

   --

   procedure Assign_Material (Model : GLOBE_3D.p_Object_3D; Material : Material_type) is

   begin
      for Faces in Model.face'Range loop
         Model.face (Faces).material := Material;
      end loop;
   end Assign_Material;

   --

   function To_Vector_4D (V : GL.Material_Float_vector) return Vector_4D is

   begin
      return (x => Real (V (0)), y => Real (V (1)), z => Real (V (2)), t => Real (V (3)));
   end To_Vector_4D;

   --

   function To_GL (V : Vector_4D) return GL.Material_Float_vector is

   begin
      return (0 => GL.Float (V (x)), 1 => GL.Float (V (y)), 2 => GL.Float (V (z)), 3 => GL.Float (V (t)));
   end To_GL;

   --

   subtype Ratio_T is Float range 0.0 .. 1.0;

   function Blend_Material (Material_1, Material_2 : Material_type; Ratio : Ratio_T) return Material_type is

      Blended_Material : constant Material_type :=
        (ambient   => To_GL (Ratio * To_Vector_4D (Material_1.ambient)  + (1.0 - Ratio) *  To_Vector_4D (Material_2.ambient)),
         diffuse   => To_GL (Ratio * To_Vector_4D (Material_1.diffuse)  + (1.0 - Ratio) *  To_Vector_4D (Material_2.diffuse)),
         specular  => To_GL (Ratio * To_Vector_4D (Material_1.specular) + (1.0 - Ratio) *  To_Vector_4D (Material_2.specular)),
         emission  => To_GL (Ratio * To_Vector_4D (Material_1.emission) + (1.0 - Ratio) *  To_Vector_4D (Material_2.emission)),
         shininess => GL.Float (Ratio * Float (Material_1.shininess) + (1.0 - Ratio) * Float (Material_2.shininess)));

   begin
      return Blended_Material;
   end Blend_Material;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is

   begin
      for Model in Model_Name loop
         case Model is
--              when Arrow     => Arrow_P.Create (object => Model_Set (Model), scale  => 0.003, centre => (0.0, 0.0, 0.0));
--              when Cube      => Cube_P.Create  (object => Model_Set (Model), scale  => 0.015, centre => (0.0, 0.0, 0.0));
--              when Duck      => Duck_P.Create  (object => Model_Set (Model), scale  => 0.003, centre => (0.0, 0.0, 0.0));
--              when Plane     => Plane_P.Create (object => Model_Set (Model), scale  => 0.003, centre => (0.0, 0.0, 0.0));
--            when Spaceship      => Spaceship_P.Create (object => Model_Set (Model), scale  => 0.003, centre => (0.0, 0.0, 0.0)); Assign_Material (Model_Set (Model), Pearl);
--              when Spaceship_Ruby => Spaceship_P.Create (object => Model_Set (Model), scale  => 0.003, centre => (0.0, 0.0, 0.0)); Assign_Material (Model_Set (Model), Ruby);
            when Sphere    => Sphere_P.Create (object => Model_Set (Model), scale  => 0.015, centre => (0.0, 0.0, 0.0)); Assign_Material (Model_Set (Model), Ruby);
         end case;
      end loop;

--      for M in Spaceship_Gradient'Range (1) loop
--         for i in Spaceship_Gradient'Range (2) loop
--            Spaceship_P.Create (object => Spaceship_Gradient (M, i), scale  => 0.003, centre => (0.0, 0.0, 0.0));
--            declare
--               Ratio : constant Ratio_T :=
--                 ((Float (i) - Float (Spaceship_Gradient'First (2)))
--                  / Float (Spaceship_Gradient'Last (2) - Spaceship_Gradient'First (2)))
--                 + Ratio_T'First;
--            begin
--               case M is
--               when G_Ruby      => Assign_Material (Spaceship_Gradient (M, i), Blend_Material (Ruby,      Pearl, Ratio));
--               when G_Turquoise => Assign_Material (Spaceship_Gradient (M, i), Blend_Material (Turquoise, Pearl, Ratio));
--               end case;
--            end;
--         end loop;
--      end loop;

   end Initialize;

begin
   Initialize;
end Models;
