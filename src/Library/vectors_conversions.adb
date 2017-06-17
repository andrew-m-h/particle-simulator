with Float_Type; use Float_Type;

package body Vectors_Conversions is

   ------------------
   -- To_Vector_3D --
   ------------------

   function To_Vector_3D (V : Vector_3D_LF) return Vector_3D is

      Convert : Vector_3D;

   begin
      Convert (x) := Real (V (x));
      Convert (y) := Real (V (y));
      Convert (z) := Real (V (z));
      return Convert;
   end To_Vector_3D;

   ---------------------
   -- To_Vector_3D_LF --
   ---------------------

   function To_Vector_3D_LF (V : Vector_3D) return Vector_3D_LF is

      Convert : Vector_3D_LF;

   begin
      Convert (x) := Long_Float (V (x));
      Convert (y) := Long_Float (V (y));
      Convert (z) := Long_Float (V (z));
      return Convert;
   end To_Vector_3D_LF;

   ------------------
   -- To_Vector_2D --
   ------------------

   function To_Vector_2D (V : Vector_2D_I) return Vector_2D is

      Convert : Vector_2D;

   begin
      Convert (x) := Real (V (x));
      Convert (y) := Real (V (y));
      return Convert;
   end To_Vector_2D;

   ------------------
   -- To_Vector_2D --
   ------------------

   function To_Vector_2D (V : Vector_2D_N) return Vector_2D is

      Convert : Vector_2D;

   begin
      Convert (x) := Real (V (x));
      Convert (y) := Real (V (y));
      return Convert;
   end To_Vector_2D;

   ------------------
   -- To_Vector_2D --
   ------------------

   function To_Vector_2D (V : Vector_2D_P) return Vector_2D is

      Convert : Vector_2D;

   begin
      Convert (x) := Real (V (x));
      Convert (y) := Real (V (y));
      return Convert;
   end To_Vector_2D;

end Vectors_Conversions;
