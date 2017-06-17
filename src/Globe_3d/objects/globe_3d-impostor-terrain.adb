with GLOBE_3D.Textures,
     GLOBE_3D.Math;

with glut.Windows; use glut.Windows;
with gl.Errors;
with GLU;

with ada.text_io;



package body GLOBE_3D.Impostor.Terrain is


   package G3DT renames GLOBE_3D.Textures;
   package G3DM renames GLOBE_3D.Math;



   procedure pre_Calculate (o : in out Impostor)
   is
   begin
      null;
   end;




   procedure set_Target        (o : in out Impostor;   Target : in p_Visual)
   is
   begin
      set_Target (globe_3d.impostor.Impostor (o),  Target);
      o.expand_X := 0.02;
      o.expand_Y := 0.02;            -- tbd: 0.02 is good for full screen and not extremely distant, otherwise increase to 0.04
--        o.expand_X := 0.04;        --      do this algorithmically.
--        o.expand_Y := 0.04;
   end;




   procedure free (o : in out p_Impostor)
   is
      procedure deallocate is new ada.unchecked_Deallocation (Impostor'Class, p_Impostor);
   begin
      destroy    (o.all);
      deallocate (o);
   end;




   function update_Required (o : access Impostor;      the_Camera           : in     globe_3d.p_Camera) return Boolean
   is
   begin
      o.current_pixel_Region := o.get_pixel_Region (the_Camera);

      declare
         use GL;
         use gl.Textures, globe_3d.Math;
         use type gl.Double;

         update_Required : Boolean      := o.general_Update_required (the_Camera, o.current_pixel_Region);

         copy_x_Offset   : gl.Int       := 0;
         copy_y_Offset   : gl.Int       := 0;
         copy_X          : gl.Int       := o.current_pixel_Region.X;
         copy_Y          : gl.Int       := o.current_pixel_Region.Y;
         copy_Width      : gl.SizeI     := o.current_pixel_Region.Width;
         copy_Height     : gl.SizeI     := o.current_pixel_Region.Height;

         viewport_Width  : Integer      := the_Camera.clipper.main_Clipping.x2 - the_Camera.clipper.main_Clipping.x1 + 1;
         viewport_Height : Integer      := the_Camera.clipper.main_Clipping.y2 - the_Camera.clipper.main_Clipping.y1 + 1;
                                           -- tbd: make above calculations attributes of camera class !
         Complete_left   : Boolean;
         Complete_right  : Boolean;
         Complete_top    : Boolean;
         Complete_bottom : Boolean;
         now_Complete    : Boolean;
      begin

         if copy_X < 0 then
            copy_x_Offset := -copy_X;
            copy_X        := 0;
            copy_Width    := copy_Width - SizeI (copy_x_Offset);

            Complete_left  := False;
            Complete_right := True;

            if copy_Width < 1 then
               o.is_Valid := False;
               return False;                                     -- nb: short circuit return !
            end if;
            -- tbd: check what causes negative widths and heights !

         elsif copy_X + Int (copy_Width) >  Int (Viewport_Width) then
            copy_Width := SizeI (viewport_Width) - SizeI (copy_X);

            Complete_left  := True;
            Complete_right := False;

            if copy_Width < 1 then
               o.is_Valid := False;
               return False;                                     -- nb: short circuit return !
            end if;

         else
            Complete_left  := True;
            Complete_right := True;
         end if;


         if copy_Y < 0 then
            copy_y_Offset := -copy_Y;
            copy_Y        := 0;
            copy_Height   := copy_Height - SizeI (copy_y_Offset);

            Complete_top    := True;
            Complete_bottom := False;

            if copy_Height < 1 then
               o.is_Valid := False;
               return False;                                     -- nb: short circuit return !
            end if;

         elsif copy_Y + Int (copy_Height)  >  Int (Viewport_Height) then
            copy_Height := SizeI (viewport_Height) - SizeI (copy_Y);

            Complete_top    := False;
            Complete_bottom := True;

            if copy_Height < 1 then
               o.is_Valid := False;
               return False;                                     -- nb: short circuit return !
            end if;

         else
            Complete_top    := True;
            Complete_bottom := True;
         end if;

         now_Complete := Complete_left and then Complete_right and then Complete_top and then Complete_bottom;


         if not update_Required then   -- only do further tests if update not already required.

            if o.prior_Complete then

               if         now_Complete
                 and then o.size_Update_required (o.current_pixel_Region)
               then
                  update_Required := True;
               end if;

            else

               if copy_Width > o.prior_copy_Width then
                  update_Required := True;
               end if;

               if copy_Height > o.prior_copy_Height then
                  update_Required := True;
               end if;

            end if;

         end if;

         if update_Required then
            o.current_Width_pixels  := o.current_pixel_Region.Width;       -- cache current state.
            o.current_Height_pixels := o.current_pixel_Region.Height;

            o.current_copy_X_Offset := copy_X_Offset;
            o.current_copy_Y_Offset := copy_Y_Offset;

            o.current_copy_X := copy_X;
            o.current_copy_Y := copy_Y;

            o.current_copy_Width  := copy_Width;
            o.current_copy_Height := copy_Height;

            o.current_Complete := now_Complete;
         end if;

         o.is_Valid := True;
         return update_Required;
      end;
   end update_Required;





   procedure update (o : in out Impostor;   the_Camera   : in     p_Camera;
                                            texture_Pool : in     gl.textures.p_Pool)
   is
      use globe_3d.Math;
      maximum_Expansion : constant := 0.05;
      Distance          : Real     := Norm (o.centre - the_camera.clipper.eye_Position);
      Expansion         : Real     := real'Max (0.02,
                                                0.015  +  maximum_Expansion * real'Min (Distance, 5_000.0) / 5_000.0 );
   begin
      o.expand_X := Expansion;   -- tbd: expansion formula needs tuning !
      o.expand_Y := Expansion;

      globe_3d.impostor.Impostor (o).update (the_Camera, texture_Pool);   -- base class 'update'

      o.prior_copy_Width  := o.current_copy_Width;                        -- set prior state.
      o.prior_copy_Height := o.current_copy_Height;
      o.prior_Complete    := o.current_Complete;
   end;

end GLOBE_3D.Impostor.Terrain;

