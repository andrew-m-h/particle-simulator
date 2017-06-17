--
-- Jan & Uwe R. Zimmer, Australia, July 2011
--

with Ada.Numerics.Generic_Elementary_Functions;

package body Quaternions is

   package Elementary_Functions is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elementary_Functions;

   --

   function "abs" (Quad : Quaternion_Real) return Real is

   begin
      return Sqrt (Quad.w**2 + Quad.x**2 + Quad.y**2 + Quad.z**2);
   end "abs";

   --

   function Unit (Quad : Quaternion_Real) return Quaternion_Real is

   begin
      return Quad / abs (Quad);
   end Unit;

   --

   function Conj (Quad : Quaternion_Real) return Quaternion_Real is

   begin
      return (w => Quad.w, x => -Quad.x, y => -Quad.y, z => -Quad.z);
   end Conj;

   --

   function "-" (Quad : Quaternion_Real) return Quaternion_Real is

   begin
      return (w => -Quad.w, x => -Quad.x, y => -Quad.y, z => -Quad.z);
   end "-";

   --

   function "+" (Left, Right : Quaternion_Real) return Quaternion_Real is

   begin
      return
      (w => Left.w + Right.w, x => Left.x + Right.x,
       y => Left.y + Right.y, z => Left.z + Right.z);
   end "+";

   --

   function "-" (Left, Right : Quaternion_Real) return Quaternion_Real is

   begin
      return
      (w => Left.w - Right.w, x => Left.x - Right.x,
       y => Left.y - Right.y, z => Left.z - Right.z);
   end "-";

   --

   function "*" (Left : Quaternion_Real; Right : Real) return Quaternion_Real is

   begin
      return
      (w => Left.w * Right, x => Left.x * Right,
       y => Left.y * Right, z => Left.z * Right);
   end "*";

   --

   function "*" (Left : Real; Right : Quaternion_Real) return Quaternion_Real is

   begin
      return Right * Left;
   end "*";

   --

   function "/" (Left : Quaternion_Real; Right : Real) return Quaternion_Real is

   begin
      return
      (w => Left.w / Right, x => Left.x / Right,
       y => Left.y / Right, z => Left.z / Right);
   end "/";

   --

   function "/" (Left : Real; Right : Quaternion_Real) return Quaternion_Real is

   begin
      return Right / Left;
   end "/";

   --

   function "*" (Left, Right : Quaternion_Real) return Quaternion_Real is

   begin
      return
      (w => Left.w * Right.w - Left.x * Right.x - Left.y * Right.y - Left.z * Right.z,
       x => Left.w * Right.x + Left.x * Right.w + Left.y * Right.z - Left.z * Right.y,
       y => Left.w * Right.y - Left.x * Right.z + Left.y * Right.w + Left.z * Right.x,
       z => Left.w * Right.z + Left.x * Right.y - Left.y * Right.x + Left.z * Right.w);
   end "*";

   --

   function "/" (Left, Right : Quaternion_Real) return Quaternion_Real is

   begin
      return
      (w => Left.w * Right.w + Left.x * Right.x + Left.y * Right.y + Left.z * Right.z,
       x => Left.w * Right.x - Left.x * Right.w - Left.y * Right.z + Left.z * Right.y,
       y => Left.w * Right.y + Left.x * Right.z - Left.y * Right.w - Left.z * Right.x,
       z => Left.w * Right.z - Left.x * Right.y + Left.y * Right.x - Left.z * Right.w);
   end "/";

   --

   function Image (Quad : Quaternion_Real) return String is

   begin
      return Real'Image (Quad.w) & " +"  &
             Real'Image (Quad.x) & "i +" &
             Real'Image (Quad.y) & "j +" &
             Real'Image (Quad.z) & "k";
   end Image;

   --

end Quaternions;
