------------------------------------------------------------------------------
--  File:            GLUT-Windows.adb
--  Description:     models a GLUT window
--  Copyright (c) Gautier de Montmollin/Rod Kay 2006..2007
------------------------------------------------------------------------------

--with opengl.glx;

with GL, GL.IO, GL.Frustums, GLU,  GLUT;

with GLOBE_3D,
     GLOBE_3D.IO,
     GLOBE_3D.Math,
     GLOBE_3D.Software_Anti_Aliasing;

with Actors;
with GLUT_2D;  --, GLUT_Exit;

-- with Ada.Text_IO;

with Ada.Numerics;                      use Ada.Numerics;
with Ada.unchecked_Conversion;

-- with Ada.Containers.Generic_Array_Sort;

with Ada.Calendar;

-- with System.Storage_Elements;




package body glut.Windows is


   package G3D  renames GLOBE_3D;
   package G3DM renames G3D.Math;

   use ada.Strings.unbounded;



   deg2rad      : constant := pi / 180.0;
   GLUT_Problem : exception;




   -- current_Window : - for accessing the current GLUT window
   --                  - used by GLUT callbacks to determine the Window to which a callback event relates.
   --
   function current_Window return Window_view
   is
      use GL;
      function to_Window is new ada.unchecked_Conversion (system.Address, globe_3d.p_Window);
   begin
      return glut.windows.Window_view (to_Window (getWindowData));
   end;






   procedure Name_is (Self : in out Window;   Now : in String)
   is
   begin
      self.Name := to_unbounded_String (Now);
   end;


   function  Name    (Self : in     Window) return String
   is
   begin
      return to_String (self.Name);
   end;



   function is_Closed (Self : in Window) return Boolean
   is
   begin
      return self.is_Closed;
   end;





   procedure Prepare_default_lighting (Self : in out Window;
                                       fact : in     GL.Float)
   is
      use GL, G3D;

      proto_light : Light_definition := (position => (0.0, 500.0,  0.0,  1.0),
                                         ambient  => (0.3,   0.3,  0.3,  fact),
                                         diffuse  => (0.9,   0.9,  0.9,  fact),
                                         specular => (0.05,  0.05, 0.01, fact));
   begin
      Enable( LIGHTING );

      G3D.Define (1, proto_light);
      self.frontal_light   := proto_light;

      proto_light.diffuse  := (0.5, 0.9, 0.5, fact);
      G3D.Define (2, proto_light);

      proto_light.diffuse  := (0.2, 0.0, 0.9, fact);
      proto_light.specular := (1.0, 1.0, 1.0, fact);
      G3D.Define (3, proto_light);

      proto_light.position := (-3.0, 4.0, 10.0, 1.0);
      G3D.Define (4, proto_light);

      proto_light.position := (3.0, -4.0, 10.0, 1.0);
      proto_light.ambient  := (0.6, 0.6, 0.6, 0.1);
      G3D.Define (5, proto_light);

      proto_light.ambient  := (0.6, 0.0, 0.0, 0.1);
      G3D.Define (6, proto_light);

      proto_light.ambient  := (0.0, 0.6, 0.0, 0.1);
      G3D.Define (7, proto_light);

      proto_light.ambient  := (0.0, 0.0, 0.6, 0.1);
      G3D.Define (8, proto_light);

      G3D.Switch_lights (True);

      G3D.Switch_light (2, False);
      G3D.Switch_light (3, False);
      G3D.Switch_light (4, False);
      G3D.Switch_light (5, False);
      G3D.Switch_light (6, False);
      G3D.Switch_light (7, False);
      G3D.Switch_light (8, False);

   end Prepare_default_lighting;






   procedure Clear_modes is
     use GL;
   begin
     Disable( BLEND );
     Disable( LIGHTING );
     Disable( AUTO_NORMAL );
     Disable( NORMALIZE );
     Disable( DEPTH_TEST );
   end Clear_modes;





   procedure Reset_for_3D (Self : in out Window'Class)
   is
      use GL, G3D, G3D.REF;
   begin
      MatrixMode (MODELVIEW);    -- (tbd: still needed ?) ... The matrix generated by GLU.Perspective is multipled by the current matrix
      ShadeModel (SMOOTH);       -- GL's default is SMOOTH, vs FLAT
      --ShadeModel (FLAT);       -- GL's default is SMOOTH, vs FLAT

      ClearColor (0.0, 0.0, 0.0, 0.0);    -- Specifies clear values for color buffer(s)
      ClearAccum (0.0, 0.0, 0.0, 0.0);    -- Specifies clear values for the accumulation buffer
   end Reset_for_3D;






   procedure enable_Viewport_and_Perspective (Self : in out Window'Class)  -- tbd: move projection matrix to 'window resize'.
   is
      use GL, G3D, G3D.REF;
   begin
      Viewport (0,  0,  sizei (Self.main_size_x),  sizei (Self.main_size_y));

      MatrixMode (PROJECTION);
      LoadIdentity;

      GLU.Perspective(fovy   => self.Camera.FOVy,                    -- field of view angle (deg) in the y direction
                      aspect => self.Camera.Aspect,                  -- x/y aspect ratio
                      zNear  => self.Camera.near_plane_Distance,     -- distance from the viewer to the near clipping plane
                      zFar   => self.Camera.far_plane_Distance);     -- distance from the viewer to the far clipping plane


      Get (GL.PROJECTION_MATRIX,  self.Camera.Projection_Matrix (1, 1)'unchecked_access);   -- Get the current PROJECTION matrix from OpenGL

      self.Camera.Projection_Matrix := g3d.math.transpose (self.Camera.Projection_Matrix);

      MatrixMode (MODELVIEW);    -- The matrix generated by GLU.Perspective is multipled by the current matrix
   end;





   procedure set_Size (Self : in out Window'Class;  width, height : Integer)
   is
      use globe_3d, GL;    use G3D.REF;

      half_fov_max_rads        : Real;
      Tan_of_half_fov_max_rads : Real;

   begin
      self.main_size_x  := GL.sizei (width);
      self.main_size_y  := GL.sizei (height);

      self.camera.clipper.main_clipping.x1 := 0;
      self.camera.clipper.main_clipping.y1 := 0;
      self.camera.clipper.main_clipping.x2 := width - 1;
      self.camera.clipper.main_clipping.y2 := height - 1;


      self.Camera.aspect := GL.Double (self.main_size_x) / GL.Double (self.main_size_y);
      half_fov_max_rads        := 0.5 * self.Camera.FOVy * deg2rad;


      Tan_of_half_fov_max_rads := Tan (half_fov_max_rads);

      self.camera.near_plane_Height := self.camera.near_plane_Distance * Tan_of_half_fov_max_rads;
      self.camera.near_plane_Width  := self.camera.near_plane_Height   * self.Camera.Aspect;

      self.camera.far_plane_Height  := self.camera.far_plane_Distance * Tan_of_half_fov_max_rads;
      self.camera.far_plane_Width   := self.camera.far_plane_Height   * self.Camera.Aspect;


      if self.Camera.aspect > 1.0 then -- x side angle broader than y side angle
         half_fov_max_rads := ArcTan (self.Camera.aspect * Tan_of_half_fov_max_rads);
      end if;

      self.camera.clipper.max_dot_product := Sin (half_fov_max_rads);

   end set_Size;




   -- Procedures passed to GLUT:
   --   Window_Resize, Keyboard, Motion, Menu, Mouse, Display


   procedure Window_Resize (width, height : Integer)
   is
      the_Window : constant glut.Windows.Window_view := current_Window;
   begin
      the_Window.forget_mouse := 5;
      set_Size     (the_Window.all,  width, height);
      Reset_for_3D (the_Window.all);
   end Window_Resize;







   procedure Menu (value : Integer)
   is
   begin
      case value is
         when 1 => -- GLUT.GameModeString (Full_Screen_Mode);
            glut.FullScreen;
            -- res := GLUT.EnterGameMode;
            glut.SetCursor (glut.CURSOR_NONE);
            current_Window.forget_mouse := 10;
            current_Window.full_screen  := True;
         when 2 => null; --GLUT_exit;
         when others => null;
      end case;
   end Menu;

   procedure Display_status (Self : in out Window;
                             sec  : globe_3d.Real)
   is
      use GL, G3D, G3D.REF, G3DM;
      light_info : String(1..8);
   begin
      PushMatrix;

      Disable( LIGHTING );
      Disable( TEXTURE_2D );

      Color( red   => 0.7,
             green => 0.7,
             blue  => 0.6);

      GLUT_2D.Text_output ((1.0, 0.0, 0.0),  "(x)",  GLUT_2D.Times_Roman_24 );
      GLUT_2D.Text_output ((0.0, 1.0, 0.0),  "(y)",  GLUT_2D.Times_Roman_24 );
      GLUT_2D.Text_output ((0.0, 0.0, 1.0),  "(z)",  GLUT_2D.Times_Roman_24 );


      GLUT_2D.Text_output (0,  50,  self.main_size_x,  self.main_size_y,
                           "Eye: " & Coords (self.Camera.Clipper.eye_Position),
                           GLUT_2D.Helvetica_10);

      GLUT_2D.Text_output (0,  60,  self.main_size_x,  self.main_size_y,
                           "View direction: " & Coords (self.Camera.Clipper.view_direction),
                           GLUT_2D.Helvetica_10);


      for i in light_info'Range loop

         if Is_light_switched(i) then
            light_info(i):= Character'Val(Character'Pos('0')+i);
         else
            light_info(i):= 'x';
         end if;
      end loop;


      GLUT_2D.Text_output (0, 70, self.main_size_x, self.main_size_y, "Lights: (" & light_info & ')', GLUT_2D.Helvetica_10);

      if sec > 0.0 then
         GLUT_2D.Text_output (0, 130, self.main_size_x, self.main_size_y, "FPS: " & Integer'Image(Integer(1.0/sec)), GLUT_2D.Helvetica_10);
      end if;


      if self.is_capturing_Video then
         GLUT_2D.Text_output (0, 150, self.main_size_x, self.main_size_y, "*recording*", GLUT_2D.Helvetica_10);
      end if;


      PopMatrix;

   end Display_status;






   function Frames_per_second (Self : in Window) return Float
   is
      use type gl.Double;
   begin
       return Float (1.0 / (self.Average * 0.001));
   end;





   procedure Graphic_display (Self   : in out Window'Class;
                              Extras : in     globe_3d.Visual_array := globe_3d.null_Visuals)
   is
      use GL, G3D;
   begin
      g3d.render (self.Objects (1 .. self.object_Count)  &  Extras,
                  self.Camera);

      if self.show_Status then
         Display_status (Self,  Self.average * 0.001);
      end if;

   end Graphic_display;





   procedure Fill_screen (Self   : in out Window'Class;
                          Extras : in     globe_3d.Visual_array := globe_3d.null_Visuals)
   is
      use GL;

      procedure Display
      is
      begin
         Graphic_display (Self, Extras);
      end Display;


      package SAA is new GLOBE_3D.Software_Anti_Aliasing (Display);
   begin

      case self.Smoothing is

      when software =>
        SAA.Set_Quality(SAA.Q3);
        for SAA_Phase in 1..SAA.Anti_Alias_phases loop
          SAA.Display_with_Anti_Aliasing(SAA_Phase);
        end loop;

      when hardware =>
        Enable( MULTISAMPLE_ARB ); -- (if not done yet)

        --ClearColor (0.0, 0.0, 0.0, 1.0);    -- Specifies clear values for color buffer(s)
        --ClearColor (0.15, 0.4, 0.15, 1.0);    -- Specifies clear values for color buffer(s)  -- tbd: make clear color user-settable
        ClearColor (0.0, 0.0, 0.0, 1.0);    -- Specifies clear values for color buffer(s)  -- tbd: make clear color user-settable
        ClearAccum (0.0,  0.0, 0.0,  0.0);    -- Specifies clear values for the accumulation buffer

        Graphic_display (Self, Extras);
        Flush;

      when none =>
        Graphic_display (Self, Extras);
        Flush;
    end case;

    glut.SwapBuffers;
  end Fill_screen;





   procedure Reset_eye  (Self : in out Window'Class) is
   begin
      self.Camera.Clipper.eye_Position := (0.0,  5.0,  4.0);
      self.Camera.world_rotation       := Globe_3D.Id_33;
   end Reset_eye;



   function Image(Date: Ada.Calendar.Time) return String;
   -- Proxy for Ada 2005 Ada.Calendar.Formatting.Image


   procedure Main_operations (Self      : access Window;
                              time_Step :        g3d.Real;
                              Extras    : in     globe_3d.Visual_array := globe_3d.null_Visuals)
   is
      use GL, G3D, G3DM, G3D.REF, Game_control;

      elaps, time_now    : Integer;
      gx,    gy          : GL.Double;   -- mouse movement since last call
      seconds            : GL.Double;   -- seconds since last image
      alpha_correct      : Boolean;
      attenu_t, attenu_r : Real;

   begin
      if        not self.is_Visible
        or else self.is_Closed
      then
         return;
      end if;


      enable_Viewport_and_Perspective (Self.all);   -- nb: must be done prior to setting frustum planes (when using gl.frustums.current_Planes)


      -- Control of lighting
      --
--        self.frontal_light.position := (GL.Float (self.Camera.Clipper.eye_Position (0)),
--                                              GL.Float (self.Camera.Clipper.eye_Position (1)),
--                                              GL.Float (self.Camera.Clipper.eye_Position (2)),
--                                              1.0);
--        G3D.Define (1, self.frontal_light);

      for c in n1..n8 loop
         if self.game_command (c) then
            Reverse_light_switch(1 + Command'Pos(c) - Command'Pos(n1));
         end if;
      end loop;


      -- Display screen
      --
      Fill_screen (self.all, Extras);


      -- Timer management
      --
      time_now := glut.Get( glut.ELAPSED_TIME );   -- Number of milliseconds since GLUT.Init

      if self.new_scene then
         self.new_scene := False;
         elaps          := 0;
      else
         elaps          := time_now - self.last_time;
      end if;

      self.last_time := time_now;
      self.average   := 0.0;


      for i in reverse self.sample'First+1 .. self.sample'Last loop
         self.sample (i) := self.sample (i-1);
         self.average    := self.average + Real (self.sample (i));
      end loop;


      self.sample (self.sample'First) := elaps;

      self.average := self.average + Real (elaps);
      self.average := self.average / Real (self.sample'Length);

      seconds  := Real (elaps) * 0.001;
      attenu_t := Real'Min (0.96, Real'Max (0.04,  1.0 - seconds*4.0));
      attenu_r := attenu_t ** 0.5;


      -- Game control management
      --
      self.game_command := no_command;

      game_control.append_Commands (size_x     => Integer (self.main_size_x),
                                    size_y     => Integer (self.main_size_y),
                                    warp_mouse => self.full_screen,
                                    c          => self.game_command,
                                    gx         => gx,
                                    gy         => gy,
                                    keyboard   => self.Keyboard'access,
                                    mouse      => self.Mouse'access);

      if self.forget_mouse > 0 then -- mouse coords disturbed by resize
         gx := 0.0;
         gy := 0.0;
         self.forget_mouse := self.forget_mouse - 1;
      end if;

      if self.game_command (interrupt_game) then
         null; -- GLUT_exit;                     -- tbd: how to handle this best ?
      end if;


      alpha_correct:= False;

      if self.game_command (special_plus)  then self.alpha := self.alpha + seconds;   alpha_correct := True; end if;
      if self.game_command (special_minus) then self.alpha := self.alpha - seconds;   alpha_correct := True; end if;

      if alpha_correct then
         if    self.alpha < 0.0 then self.alpha := 0.0;
         elsif self.alpha > 1.0 then self.alpha := 1.0; end if;

         for Each in 1 .. self.object_Count loop
            set_Alpha (self.Objects (Each).all,  self.Alpha);
         end loop;
      end if;


      -- Camera/Eye - nb: camera movement is done after rendering, so camera is in a state ready for the next frame.
      --            -     (important for Impostors)

      -- Rotating the eye

      Actors.Rotation ( self.Camera,
                        gc => self.game_command,
                        gx => gx,
                        gy => gy,
                        unitary_change => seconds,
                        deceleration   => attenu_r,
                        time_step      => time_Step);




      -- Moving the eye

      Actors.Translation( self.Camera,
                          gc => self.game_command,
                          gx => gx,
                          gy => gy,
                          unitary_change     => seconds,
                          deceleration       => attenu_t,
                          time_step          => time_Step);


      if self.game_command (n0) then
         Reset_eye (self.all);
      end if;


      self.Camera.Clipper.view_direction := Transpose (self.Camera.world_rotation) * (0.0, 0.0, -1.0);


      -- update camera frustum
      --
      MatrixMode    (MODELVIEW);
      Set_GL_Matrix (self.Camera.world_rotation);
      Translate     (-self.Camera.Clipper.eye_Position(0),  -self.Camera.Clipper.eye_Position(1),  -self.Camera.Clipper.eye_Position(2));

      self.camera.frustum_Planes := gl.frustums.current_Planes;  -- tbd: getting frustum planes from camera, might be quicker,
      --set_frustum_Planes (Self.Camera);                        --      but 'set_frustum_Planes' seems buggy :/.


      -- video management
      --
      if self.game_command (video) then
         if self.is_capturing_Video then
            gl.io.stop_Capture;
            self.is_capturing_Video := False;
         else
            gl.io.start_Capture (avi_name   => to_String (self.Name) & "." & Image (ada.calendar.Clock) & ".avi",
                                 frame_rate => 8); --Integer (self.Frames_per_second));
            self.is_capturing_Video := True;
         end if;
      end if;

      if self.is_capturing_Video then
         gl.io.capture_Frame;
      end if;


      -- photo management
      --
      if self.game_command (photo) then
         gl.io.screenshot (name => to_String (self.Name) & "." & Image (ada.calendar.Clock) & ".bmp");
      end if;

   end Main_Operations;




   procedure Close_Window
   is
   begin
      current_Window.is_Closed := True;
   end;





   procedure update_Visibility (State : Integer)
   is
   begin
      --      ada.text_io.put_line ("in update_Visibility callback state: " & integer'image( State));
      --
      -- tbd: this callback is not being called when a window is iconicised !!

      current_Window.is_Visible := not (        State = glut.HIDDEN
                                        or else State = glut.FULLY_COVERED);
   end;






   procedure Start_GLUTs (Self : in out Window)
   is
      use GL, GLUT;

      function to_Address is new ada.unchecked_Conversion (globe_3d.p_Window, system.Address);

      GLUT_options : glut.Unsigned := glut.DOUBLE  or  glut.RGBA or glut.ALPHA  or  glut.DEPTH;
   begin
      if self.Smoothing = hardware then
         GLUT_options := GLUT_options or glut.MULTISAMPLE;
      end if;

      InitDisplayMode (GLUT_options);

      set_Size (Self,  500, 400);

      InitWindowSize     (Integer (self.main_size_x),  Integer (self.main_size_y));
      InitWindowPosition (120, 120);

      self.glut_Window := CreateWindow ("GLOBE_3D/GLUT Window");

      if self.glut_Window = 0 then
         raise GLUT_Problem;
      end if;

      glut.CloseFunc        (close_Window'access);
      glut.ReshapeFunc      (Window_Resize'access);
      glut.WindowStatusFunc (update_Visibility'access);
      glut.setWindowData    (to_Address (globe_3d.window'Class (Self)'unchecked_access));

      glut.devices.Initialize;

--        if CreateMenu (Menu'access) = 0 then         -- tdb: deferred
--           raise GLUT_Problem;
--        end if;

--      AttachMenu( MIDDLE_BUTTON );

--      AddMenuEntry(" * Full Screen", 1);
--      AddMenuEntry("--> Exit (Esc)", 2);

   end Start_GLUTs;





   procedure Start_GLs (Self : in out Window)
   is
      use GL;
      fog_colour : GL.Light_Float_vector := (0.2,0.2,0.2,0.1);
   begin

      Clear_modes;
      Prepare_default_lighting (Self, 0.9);

      if Self.foggy then
         Enable (FOG);
         Fogfv  (FOG_COLOR,   fog_colour(0)'Unchecked_Access);
         Fogf   (FOG_DENSITY, 0.02);
      end if;

      Reset_for_3D (Self);

      if self.Smoothing = hardware then
         Enable( MULTISAMPLE_ARB );
         Enable( SAMPLE_COVERAGE_ARB ); -- Hope it helps switching on the AA...
      end if;

   end Start_GLs;






   procedure initialize
   is
   begin
      glut.Init;
      glut.setOption (glut.GLUT_RENDERING_CONTEXT, glut.GLUT_USE_CURRENT_CONTEXT);
      glut.setOption (glut.ACTION_ON_WINDOW_CLOSE, ACTION_CONTINUE_EXECUTION);
   end;




   procedure define (Self : in out Window)
   is
   begin
      Start_GLUTs (Self);    -- Initialize the GLUT things
      Start_GLs   (Self);    -- Initialize the (Open)GL things
      Reset_eye   (Self);

      freshen     (Self, 0.02);    -- do an initial freshen, to initialise Camera, etc.
   end define;






   procedure destroy (Self : in out Window)
   is
   begin
      destroyWindow (self.glut_Window);
   end;





   procedure enable (Self : in out Window)
   is
   begin
      glut.setWindow  (Self.glut_Window);
--      opengl.glx.glXMakeCurrent;

   end;




   procedure freshen (Self      : in out Window;
                      time_Step : in     g3d.Real;
                      Extras    : in     globe_3d.Visual_array := globe_3d.null_Visuals)
   is
   begin
      enable (self);  -- for multi-window operation.
      Main_operations (Self'access, time_Step, Extras);
   end;






   -- traits
   --

   function Smoothing (Self : in     Window) return Smoothing_method
   is
   begin
      return self.Smoothing;
   end;




   procedure Smoothing_is (Self : in out Window;
                           Now  : in Smoothing_method)
   is
   begin
      self.Smoothing := Now;
   end;




   procedure add (Self : in out Window;   the_Object : in globe_3d.p_Visual)
   is
   begin
      self.object_Count                := self.object_Count + 1;
      self.Objects (self.object_Count) := the_Object.all'access;
   end;




   procedure rid (Self : in out Window;   the_Object : in globe_3d.p_Visual)
   is
      use G3D;
   begin
      for Each in 1 .. self.object_Count loop

         if self.Objects (Each) = the_Object then

            if Each /= self.object_Count then
               self.Objects (Each .. self.object_Count - 1) := self.Objects (Each + 1 .. self.object_Count);
            end if;

            self.object_Count := self.object_Count - 1;
            return;
         end if;

      end loop;

      raise no_such_Object;
   end;




   function object_Count (Self : in Window) return Natural
   is
   begin
      return self.object_Count;
   end;





   -- status display
   --


   function  show_Status (Self : in     Window) return Boolean
   is
   begin
      return self.show_Status;
   end;




   procedure show_Status (Self : in out Window;
                          Show : in     Boolean := True)
   is
   begin
      self.show_Status := Show;
   end;




   -- Devices
   --

   function Keyboard (Self : access Window'Class) return devices.p_Keyboard
   is
   begin
      return self.Keyboard'access;
   end;





   function Mouse (Self : access Window'Class) return devices.p_Mouse
   is
   begin
      return self.Mouse'access;
   end;

  -- Proxy for Ada 2005 Ada.Calendar.Formatting.Image
  function Image(Date: Ada.Calendar.Time) return String
  is
    use Ada.Calendar;
    subtype Sec_int is Long_Integer; -- must contain 86_400
    m, s : Sec_int;
  begin
    s := Sec_int( Seconds(Date) );
    m := s / 60;

    declare
      -- + 100: trick for obtaining 0x
      sY : constant String:= Integer'Image( Year(Date));
      sM : constant String:= Integer'Image( Month(Date) + 100);
      sD : constant String:= Integer'Image(  Day(Date)  + 100);
      shr: constant String:= Sec_int'Image( m  /  60 + 100);
      smn: constant String:= Sec_int'Image( m mod 60 + 100);
      ssc: constant String:= Sec_int'Image( s mod 60 + 100);

    begin
      return
        sY( sY'Last-3 .. sY'Last ) & '-' &  -- not Year 10'000 compliant.
        sM( sM'Last-1 .. sM'Last ) & '-' &
        sD( sD'Last-1 .. sD'Last ) &
        " " &
        shr( shr'Last-1 .. shr'Last ) & '.' &
        smn( smn'Last-1 .. smn'Last ) & '.' &
        ssc( ssc'Last-1 .. ssc'Last );
    end;
  end Image;

end glut.Windows;
