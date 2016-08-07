with Ada.Directories;         use Ada.Directories;
with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Characters.Handling; use Ada.Characters.Handling;
with Ada.Strings.Unbounded;   use Ada.Strings.Unbounded;
with Ada.Exceptions;          use Ada.Exceptions;

with Glib.Xml_Int; use Glib.Xml_Int;

with Templates_Parser; use Templates_Parser;

with Signal_Storage; use Signal_Storage;
with Gate3_Glib;     use Gate3_Glib;

package body Glade3_Generate is

   package UBS renames Ada.Strings.Unbounded;

   Template_Dir : UBS.String_Access;

   -----------------------
   -- Set_Template_Dir     --
   -----------------------

   procedure Set_Template_Dir (Dir : in String) is
   begin
      if Template_Dir /= null then
         Free (Template_Dir);
      end if;
      Template_Dir := new String'(Dir);
   end Set_Template_Dir;

   procedure Scan_Project (Project : in Node_Ptr);
   -- Process the Xml tree Project to find windows and signal
   -- Results are stored in package Signal_Storage

   function Print_Header (File_Name : String) return String;
   --  Generates header using gate3_header.tmplt

   function Print_Main (Project_Name : String; Glade_Name : String) return String;
   --  Generates main Ada procedure using gate3_main.tmplt

   function Print_Spec (Window_Nbr : Object_Index) return String;
   --  Generates Ada specs for one callback package using gate3_spec.tmplt

   function Print_Body (Window_Nbr : Object_Index) return String;
   --  Generates Ada body for one callback package using gate3_body.tmplt

   --------------
   -- Generate --
   --------------

   -----------------------
   -- Generate a string --
   -----------------------

   function Process
     (File_Name    : String;
      Main_Name    : String := "";
      Project_Tree : Node_Ptr) return String is
      -- Scan the XML tree and outputs the text

      Result     : UBS.Unbounded_String;
      Window_Nbr : Object_Index := 0;

   begin
      -- Populate the object and signal store
      Scan_Project (Project_Tree);

      -- Do some checks for the validity
      Window_Nbr := Get_Object_Number;
      if Window_Nbr = 0 then
         -- something is wrong in the glade file
         Raise_Exception
           (Bad_Xml'Identity,
            "Gate3 Error : " & "Cannot find any window in your project.");
      end if;

      if Get_Signal_Number = 0 then
         -- there is no signal in project - program will hang.
         Raise_Exception
           (Bad_Xml'Identity,
            "Gate3 Error : " &
            "There is no signal in your project." &
            " You must have at least a destroy signal.");
      end if;

      -- The real processing is done here.
      Result := To_Unbounded_String (Print_Header (File_Name));
      Append (Result, Print_Main (Main_Name, File_Name));

      for I in 1 .. Window_Nbr loop
         if Object_Store (I).Signumber > 0 then
            Append (Result, Print_Spec (I));
            Append (Result, Print_Body (I));
         end if;
      end loop;

      return UBS.To_String (Result);

   exception
      when E : Signal_Storage.Bad_Identifier =>
         Raise_Exception (Bad_Xml'Identity, Exception_Message (E));

   end Process;

   ----------------------
   -- Generate a file  --
   ----------------------

   procedure Generate
     (Glade_File   : in String;
      Project_Name : in String := "";
      Output_Dir   : in String := "") is

      Project       : Node_Ptr;
      Output        : File_Type;
      Output_Name   : UBS.String_Access;
      Mainproc_Name : UBS.String_Access;
   begin

      if Project_Name = "" then
         Mainproc_Name := new String'(To_Ada (To_Lower (Base_Name (Glade_File))));
      else
         Mainproc_Name := new String'(Project_Name);
      end if;

      if Output_Dir = "" then
         Output_Name :=
           new String'
             (Compose
                (Containing_Directory (Glade_File),
                 To_Lower (Base_Name (Glade_File)),
                 "ada"));
      else
         begin
            if Exists (Output_Dir) and then Kind (Output_Dir) = Directory then
               Output_Name :=
                 new String'(Compose (Output_Dir, To_Lower (Base_Name (Glade_File)), "ada"));
            else
               Output_Name :=
                 new String'
                   (Compose
                      (Containing_Directory (Glade_File),
                       To_Lower (Base_Name (Glade_File)),
                       "ada"));
            end if;
         exception
            when Ada.Directories.Name_Error =>
               Output_Name := new String'(Compose ("", To_Lower (Base_Name (Glade_File)), "ada"));
         end;
      end if;

      -- Do the XML parsing.
      Project := Glib.Xml_Int.Parse (Glade_File);

      if Project = null then
         Raise_Exception
           (Bad_Xml'Identity,
            "Gate3 Error : XML parsing with glib failed." & "Check your glade file.");
      end if;

      if Ada.Directories.Exists (Output_Name.all) then
         Ada.Directories.Delete_File (Output_Name.all);
      end if;
      Create (Output, Out_File, Output_Name.all);

      Ada.Text_IO.Put (Output, Process (Glade_File, Mainproc_Name.all, Project));

      Close (Output);
      Put_Line ("Result file is : " & Output_Name.all);

      -- Garbage collection
      Free (Output_Name);
      Free (Mainproc_Name);
      Glib.Xml_Int.Free (Project);

   end Generate;

   ------------------
   -- Scan_Project --
   ------------------
   procedure Scan_Object (N : Node_Ptr; Top_Window : Object_Index);

   procedure Scan_Project (Project : Node_Ptr) is
      P              : Node_Ptr;
      Top_Widget_Nbr : Object_Index := 0;
   begin

      if Project.Tag.all /= "interface" then
         -- sanity check against old version of Glade
         Raise_Exception
           (Old_Version'Identity,
            "Gate3 Error : Old version. " & "The top tag must be [interface]");
      end if;

      Initialize_Signals_Store;

      P := Project.Child;

      while P /= null loop
         if P.Tag.all = "object" then
            if Debug then
               Put ("Scanning root object id [" & Get_Attribute (P, "id"));
               Put_Line ("] ; class [" & Get_Attribute (P, "class") & "].");
            end if;

            declare
               Class : constant String := Get_Attribute (P, "class");
            begin
               -- scan only objects that can contain signals or shows
               if Class = "GtkAction" or
                 Class = "GtkActionGroup" or
                 Class = "GtkAboutDialog" or
                 Class = "GtkDialog" or
                 Class = "GtkWindow"
               then
                  Top_Widget_Nbr                     := Top_Widget_Nbr + 1;
                  Object_Store (Top_Widget_Nbr).Node := P;
                  Inc_Object_Number;
                  Scan_Object (P, Top_Widget_Nbr);
               end if;
            end;

         elsif P.Tag.all = "widget" then
            -- sanity check against old version of Glade files
            Raise_Exception
              (Old_Version'Identity,
               "Gate3 Error : : Old version. " &
               "Tag [widget] is obsolete and replaced by [object]");
         else
            null;
         end if;

         P := P.Next;
      end loop;
   end Scan_Project;

   ------------------
   -- Scan_Object  --
   ------------------

   procedure Scan_Object (N : Node_Ptr; Top_Window : Object_Index) is
      P, Q : Node_Ptr;
   begin

      P := N.Child;

      while P /= null loop

         if P.Tag.all = "signal" then
            -- Looking for the root window
            Store_Signal_Node (P, Top_Window);

            if Debug then
               Put ("    Registering signal name [" & Get_Attribute (P, "name"));
               Put ("]; handler [" & Get_Attribute (P, "handler"));
               Put_Line ("]; widget [" & Get_Attribute (N, "id") & "]");
               Put_Line
                 ("    Top object is [" &
                  Get_Attribute (Object_Store (Top_Window).Node, "id") &
                  "].");
            end if;
         elsif P.Tag.all = "child" then
            Q := P.Child;

            while Q /= null loop
               if Q.Tag.all = "object" then
                  -- go into recursion
                  Scan_Object (Q, Top_Window);
               end if;

               Q := Q.Next;
            end loop;
         else
            null;
         end if;

         P := P.Next;
      end loop;

   end Scan_Object;

   ------------------
   -- Print_Header --
   ------------------

   function Print_Header (File_Name : String) return String is
      File_Tag     : constant Templates_Parser.Tag                      := +File_Name;
      Translations : constant Templates_Parser.Translate_Table (1 .. 1) :=
        (1 => Templates_Parser.Assoc ("FILE", File_Tag));

      Header_Template : constant String := Compose (Template_Dir.all, "gate3_header", "tmplt");

   begin
      return Templates_Parser.Parse (Header_Template, Translations);
   end Print_Header;

   ------------------
   -- Print_Main   --
   ------------------

   function Print_Main (Project_Name : String; Glade_Name : String) return String is
      Window_Nbr    : constant Object_Index := Get_Object_Number;
      Signal_Number : constant Natural      := Get_Signal_Number;

      Project_Tag : constant Templates_Parser.Tag := +Project_Name;
      Glade_Tag   : constant Templates_Parser.Tag := +Glade_Name;

      Objects     : Templates_Parser.Vector_Tag;
      Ada_Objects : Templates_Parser.Vector_Tag;
      Shows       : Templates_Parser.Vector_Tag;

      Signals     : Templates_Parser.Vector_Tag;
      Ada_Signals : Templates_Parser.Vector_Tag;

      Translations : Templates_Parser.Translate_Table (1 .. 7);

      Main_Template : constant String := Compose (Template_Dir.all, "gate3_main", "tmplt");
   -- the template file is <gate3_main.tmplt> located in
   -- directory of gate3

   begin

      for I in 1 .. Window_Nbr loop
         declare
            P     : constant String := Get_Attribute (Object_Store (I).Node, "id");
            Class : constant String := Get_Attribute (Object_Store (I).Node, "class");

         begin
            Append (Objects, P);
            if Object_Store (I).Signumber > 0 then
               Append (Ada_Objects, To_Ada (P));
            end if;
            if Class = "GtkAboutDialog" or Class = "GtkDialog" or Class = "GtkWindow" then
               Append (Shows, True);
            else
               Append (Shows, False);
            end if;
         end;
      end loop;

      for I in 1 .. Signal_Number loop
         declare
            Handler : constant String :=
              Get_Attribute (Retrieve_Signal_Node (I).Signal, "handler");
            Ada_Handler : constant String := To_Ada (Handler);
         begin
            Append (Signals, Handler);
            Append (Ada_Signals, Ada_Handler);
         end;
      end loop;

      Translations :=
        (1 => Templates_Parser.Assoc ("PROJECT", Project_Tag),
         2 => Templates_Parser.Assoc ("GLADE_NAME", Glade_Tag),
         3 => Templates_Parser.Assoc ("OBJECT", Objects),
         4 => Templates_Parser.Assoc ("ADA_OBJECT", Ada_Objects),
         5 => Templates_Parser.Assoc ("SHOW", Shows),
         6 => Templates_Parser.Assoc ("SIGNAL", Signals),
         7 => Templates_Parser.Assoc ("ADA_SIGNAL", Ada_Signals));

      return Templates_Parser.Parse (Main_Template, Translations);

   end Print_Main;

   ------------------
   -- Print_Spec   --
   ------------------

   function Print_Spec (Window_Nbr : Object_Index) return String is
      Window    : constant Node_Ptr := Object_Store (Window_Nbr).Node;
      Pack_Name : constant String   := To_Ada (Get_Attribute (Window, "id"));
      Signal    : Signal_Rec;

      Signal_Number : constant Natural := Get_Signal_Number;

      Package_Tag : constant Templates_Parser.Tag := +To_Ada (Pack_Name);

      Ada_Handlers  : Templates_Parser.Vector_Tag;
      Cb_Procedures : Templates_Parser.Vector_Tag;

      Translations : Templates_Parser.Translate_Table (1 .. 3);

      Spec_Template : constant String := Compose (Template_Dir.all, "gate3_spec", "tmplt");
   -- the template file is <gate3_spec.tmplt> located in
   -- directory of gate3

   begin

      -- Output signal handlers
      for I in 1 .. Signal_Number loop
         Signal := Retrieve_Signal_Node (I);

         if Signal.Top_Window = Window_Nbr then
            -- output only signals belonging to present window/object
            declare
               Ada_Handler : constant String := To_Ada (Get_Attribute (Signal.Signal, "handler"));
            begin
               Append (Ada_Handlers, Ada_Handler);
               if Signal.Callback = Proc then
                  Append (Cb_Procedures, True);
               else
                  Append (Cb_Procedures, False);
               end if;

            end;
         end if;
      end loop;

      Translations :=
        (1 => Templates_Parser.Assoc ("PACKAGE", Package_Tag),
         2 => Templates_Parser.Assoc ("ADA_HANDLER", Ada_Handlers),
         3 => Templates_Parser.Assoc ("CB_PROC", Cb_Procedures));

      return Templates_Parser.Parse (Spec_Template, Translations);

   end Print_Spec;

   ------------------
   -- Print_Body   --
   ------------------

   function Print_Body (Window_Nbr : Object_Index) return String is
      Window : constant Node_Ptr := Object_Store (Window_Nbr).Node;
      Signal : Signal_Rec;

      Signal_Number : constant Natural := Get_Signal_Number;

      Pack_Name : constant String := To_Ada (Get_Attribute (Window, "id"));

      Package_Tag : constant Templates_Parser.Tag := +To_Ada (Pack_Name);

      Ada_Handlers  : Templates_Parser.Vector_Tag;
      Cb_Procedures : Templates_Parser.Vector_Tag;
      Has_Quit      : Templates_Parser.Vector_Tag;

      Translations : Templates_Parser.Translate_Table (1 .. 4);

      Body_Template : constant String := Compose (Template_Dir.all, "gate3_body", "tmplt");
   -- the template file is <gate3_body.tmplt> located in directory of gate3

   begin
      -- Output signal handlers
      for I in 1 .. Signal_Number loop
         Signal := Retrieve_Signal_Node (I);

         if Signal.Top_Window = Window_Nbr then
            -- output only signals belonging to present window/object
            declare
               Ada_Handler : constant String := To_Ada (Get_Attribute (Signal.Signal, "handler"));
            begin
               Append (Ada_Handlers, Ada_Handler);
               if Signal.Callback = Proc then
                  Append (Cb_Procedures, True);
               else
                  Append (Cb_Procedures, False);
               end if;
               -- Add a call to Main.Main_Quit if handler name contains <quit>
               if Signal.Has_Quit then
                  Append (Has_Quit, True);
               else
                  Append (Has_Quit, False);
               end if;

            end;
         end if;
      end loop;

      Translations :=
        (1 => Templates_Parser.Assoc ("PACKAGE", Package_Tag),
         2 => Templates_Parser.Assoc ("ADA_HANDLER", Ada_Handlers),
         3 => Templates_Parser.Assoc ("CB_PROC", Cb_Procedures),
         4 => Templates_Parser.Assoc ("HAS_QUIT", Has_Quit));

      return Templates_Parser.Parse (Body_Template, Translations);

   end Print_Body;

end Glade3_Generate;
