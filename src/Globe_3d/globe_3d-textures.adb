with GL, GL.IO, Unzip.Streams;

with Ada.Characters.Handling;           use Ada.Characters.Handling;
with Ada.Exceptions;                    use Ada.Exceptions;
with Ada.Strings.Fixed;                 use Ada.Strings, Ada.Strings.Fixed;
with Ada.Strings.Unbounded;             use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;
with Ada.Containers.Hashed_Maps;
with Ada.Strings.Unbounded.Hash;

package body GLOBE_3D.Textures is

  ------------------------------------------------------------------
  -- 1) Fast access though the number (Image_ID -> Texture_info): --
  ------------------------------------------------------------------
  type Texture_info is record
    loaded       : Boolean:= False;
    blending_hint: Boolean:= False;
    name         : Ident:= empty;
  end record;

  type Texture_info_array is array( Image_id range <>) of Texture_info;
  type p_Texture_info_array is access Texture_info_array;

  procedure Dispose is new Ada.Unchecked_Deallocation(Texture_info_array, p_Texture_info_array);

  -----------------------------------
  -- 2) Fast access through a name --
  -----------------------------------

  package Texture_Name_Mapping is new Ada.Containers.Hashed_Maps
     (Key_Type        => Ada.Strings.Unbounded.Unbounded_String,
      Element_Type    => Image_id,
      Hash            => Ada.Strings.Unbounded.Hash,
      Equivalent_Keys => Ada.Strings.Unbounded."=");

  type Texture_2d_infos_type is record
    tex              : p_Texture_info_array;
    map              : Texture_Name_Mapping.Map;
    last_entry_in_use: Image_ID;
  end record;

  empty_texture_2d_infos: constant Texture_2d_infos_type:=
    ( null,
      Texture_Name_Mapping.Empty_Map,
      null_image
    );

  texture_2d_infos: Texture_2d_infos_type:= empty_texture_2d_infos;

  -----------------------------
  -- Load_texture (internal) --
  -----------------------------

  procedure Load_texture_2D (id: Image_id; blending_hint: out Boolean) is
    tex_name: constant String:= Trim(texture_2D_infos.tex(id).name,Right);

    procedure Try( zif: in out Zip.Zip_info; name: String ) is
      use Unzip.Streams;
      ftex: Zipped_File_Type;
      procedure Try_a_type(tex_name_ext: String; format: GL.IO.Supported_format) is
      begin
        Open( ftex, zif, tex_name_ext );
        GL.IO.Load( Stream(ftex), format, Image_id'Pos(id)+1, blending_hint );
        Close( ftex );
      exception
        when Zip.File_name_not_found =>
          raise;
        when e:others =>
          raise_exception(
            Exception_Identity(e),
            Exception_Message(e) & " on texture: " & tex_name_ext
          );
      end Try_a_type;
    begin -- Try
      Load_if_needed( zif, name );
      Try_a_type(tex_name & ".TGA", GL.IO.TGA);
    exception
      when Zip.File_name_not_found =>
        Try_a_type(tex_name & ".BMP", GL.IO.BMP);
    end Try;
  begin
    begin
      Try( zif_level, To_String(level_data_name) );
    exception
      when Zip.File_name_not_found |
           Zip.Zip_file_open_error =>
        -- Not found in level-specific pack
        Try( zif_global, To_String(global_data_name) );
    end;
  exception
    when Zip.File_name_not_found |
         Zip.Zip_file_open_error =>
      -- Never found - neither in level, nor in global pack
      raise_exception(Missing_texture'Identity, "texture: " & tex_name);
  end Load_texture_2D;

  function Valid_texture_ID(id: Image_id) return Boolean is
  begin
    return id in null_image+1 .. texture_2d_infos.last_entry_in_use;
  end Valid_texture_ID;

  procedure Check_2D_texture(id: Image_id; blending_hint: out Boolean) is
  begin
    if not Valid_texture_ID(id) then
      raise Undefined_texture_ID;
    end if;
    if texture_2D_infos.tex(id).loaded then
      blending_hint:= texture_2D_infos.tex(id).blending_hint;
    else
      Load_texture_2D(id, blending_hint);
      texture_2D_infos.tex(id).loaded:= True;
      texture_2D_infos.tex(id).blending_hint:= blending_hint;
    end if;
  end Check_2D_texture;

  procedure Check_2D_texture(id: Image_id) is
    junk: Boolean;
  begin
    Check_2D_texture(id,junk);
  end Check_2D_texture;

  procedure Check_all_textures is
  begin
    for i in null_image+1 .. texture_2d_infos.last_entry_in_use loop
      Check_2D_texture(i);
    end loop;
  end Check_all_textures;

  --  procedure Bind_2D_texture (id: Image_id; blending_hint: out Boolean) is
  --  begin
  --    Check_2D_texture(id, blending_hint);
  --    GL.BindTexture( GL.TEXTURE_2D, GL.Uint(Image_id'Pos(id)+1) );
  --  end Bind_2D_texture;

  procedure Reset_textures is
  begin
    if texture_2d_infos.tex /= null then
      Dispose(texture_2d_infos.tex);
    end if;
    texture_2d_infos:= empty_texture_2d_infos;
  end Reset_textures;

  procedure Add_texture_name( name: String; id: out Image_id ) is
    new_tab: p_Texture_info_array;
    n_id: Ident:= empty;
    pos: Texture_Name_Mapping.Cursor;
    success: Boolean;
  begin
    if texture_2d_infos.tex = null then
      texture_2d_infos.tex:= new Texture_info_array(0..100);
    end if;
    if texture_2d_infos.last_entry_in_use >= texture_2d_infos.tex'Last then
      -- We need to enlarge the table: we double it...
      new_tab:= new Texture_info_array(0..texture_2d_infos.tex'Last * 2);
      new_tab(texture_2d_infos.tex'Range):= texture_2d_infos.tex.all;
      Dispose(texture_2d_infos.tex);
      texture_2d_infos.tex:= new_tab;
    end if;
    id:= texture_2d_infos.last_entry_in_use + 1;
    for i in name'Range loop
      n_id(n_id'First + i - name'First):= name(i);
    end loop;
    n_id:= To_Upper(n_id);
    texture_2d_infos.tex(id).name:= n_id;
    texture_2d_infos.last_entry_in_use:=
    Image_ID'Max(texture_2d_infos.last_entry_in_use, id);
    -- Feed the name dictionary with the new name:
    Texture_Name_Mapping.Insert(
      texture_2d_infos.map,
      Ada.Strings.Unbounded.To_Unbounded_String(name),
      id,
      pos,
      success
    );
    if not success then -- A.18.4. 45/2
      raise Duplicate_name with name;
    end if;
  end Add_texture_name;

  procedure Register_textures_from_resources is

      procedure Register( zif: in out Zip.Zip_info; name: String ) is
         procedure Action( name: String ) is
            dummy: Image_id;
            ext: constant String:= name(name'Last-3..name'Last);
         begin
            if ext = ".BMP" or ext = ".TGA" then
               Add_texture_name(name(name'First..name'Last-4), dummy);
            end if;
         end Action;
         procedure Traverse is new Zip.Traverse(Action);
      begin
         Load_if_needed( zif, name );
         Traverse(zif);
         -- That's it!
      exception
         when Zip.Zip_file_open_error =>
            null;
      end Register;

  begin
    Register( zif_level,  To_String(level_data_name) );
    Register( zif_global, To_String(global_data_name) );
  end Register_textures_from_resources;

  procedure Associate_textures is
    dummy: Image_id;
  begin
    Reset_textures;
    for t in Texture_enum loop
      Add_texture_name( Texture_enum'Image(t), dummy );
    end loop;
  end Associate_textures;

  function Texture_name( id: Image_id; trim: Boolean ) return Ident is
    tn: Ident;
  begin
    if not Valid_texture_ID(id) then
      raise Undefined_texture_ID;
    end if;
    tn:= texture_2d_infos.tex(id).name;
    if trim then
      return Ada.Strings.Fixed.Trim(tn,Right);
    else
      return tn;
    end if;
  end Texture_name;

  function Texture_ID( name: String ) return Image_ID is
    up_name: constant String:= To_Upper(name);
  begin
    return Texture_Name_Mapping.Element(
            texture_2d_infos.map,
            Ada.Strings.Unbounded.To_Unbounded_String(Trim(up_name,both)));
  exception
    when Constraint_Error =>
      raise Undefined_texture_name with " Texture: [" & Trim(name,both) & ']';
  end Texture_ID;

end GLOBE_3D.Textures;

