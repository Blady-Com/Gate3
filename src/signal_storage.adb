with GNAT.Regpat;           use GNAT.Regpat;
with Ada.Exceptions;        use Ada.Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Gate3_Glib;            use Gate3_Glib;

pragma Elaborate_All (GNAT.Regpat);

package body Signal_Storage is

   package US renames Ada.Strings.Unbounded;

   Object_Nbr : Object_Index := 0;
   -- the number of windows/objects in the project

   Store_Size : constant := 1024;

   Store : array (1 .. Store_Size) of Signal_Rec;
   -- register the different handlers within a project
   -- several signals may use to the same handler
   -- Store will register only one handler for the different signals.

   First_Available_Item : Natural := 1;
   -- signal number

   Event_Pattern : Pattern_Matcher (100);
   -- signal is of type event$
   Ada_Identifier : Pattern_Matcher (200);
   -- pattern for a valid Ada identifier
   Quit_Pattern : Pattern_Matcher (100);
   -- detects the <quit> string in a handler

   -----------------------
   -- Check_Cb_Type     --
   -----------------------
   function Check_Cb_Type (Handler : String) return Cb_Type is
   begin
      if GNAT.Regpat.Match (Event_Pattern, Handler, Handler'First, Handler'Last) > 0 then
         return Func;
      end if;

      return Proc;
   end Check_Cb_Type;

   -----------------------
   -- Inc_Object_Number --
   -----------------------

   procedure Inc_Object_Number is
   begin
      Object_Nbr := Object_Nbr + 1;
   end Inc_Object_Number;

   -----------------------
   -- Get_Object_Number --
   -----------------------

   function Get_Object_Number return Object_Index is
   begin
      return Object_Nbr;
   end Get_Object_Number;

   ------------------------------
   -- Initialize_Signals_Store --
   ------------------------------

   procedure Initialize_Signals_Store is
   begin
      First_Available_Item := 1;
      Object_Nbr           := 0;
   end Initialize_Signals_Store;

   -----------------------
   -- Store_Signal_Node --
   -----------------------

   procedure Store_Signal_Node (Signal : in Node_Ptr; Top_Object : in Object_Index) is

      Handler     : constant String := Get_Attribute (Signal, "handler");
      Ada_Handler : constant String := Gate3_Glib.To_Ada (Handler);
      Sig_Name    : constant String := Get_Attribute (Signal, "name");
      -- determine whether a function or procedure
      Callback : constant Cb_Type := Check_Cb_Type (Sig_Name);

      Signal_Data : Signal_Rec := (Signal, Top_Object, Callback, False);

   begin
      -- check if Signal handler is already registered
      for I in 1 .. First_Available_Item - 1 loop
         if Get_Attribute (Store (I).Signal, "handler") = Handler then
            -- already registrered. do nothing
            return;
         end if;
      end loop;

      -- check if handler string gives a valid Ada identifier
      if GNAT.Regpat.Match (Ada_Identifier, Ada_Handler, Ada_Handler'First, Ada_Handler'Last) =
        0
      then
         -- Invalid identifier => Emit a warning with location
         declare
            Node_Chain : US.Unbounded_String :=
              US.To_Unbounded_String (Get_Attribute (Signal, "name"));
            A_Node : Node_Ptr := Signal;
         begin
            loop
               if (A_Node.Tag.all = "object") then
                  Node_Chain := Get_Attribute (A_Node, "id") & ":" & Node_Chain;
               end if;
               exit when A_Node = Object_Store (Top_Object).Node;
               A_Node := A_Node.Parent;
            end loop;
            Raise_Exception
              (Bad_Identifier'Identity,
               "Gate3 Error : Signal Identifier <" &
               Handler &
               "> in object [" &
               US.To_String (Node_Chain) &
               "] is an invalid Ada Identifier.");
         end;
      end if;

      -- check if signal name is destroy or delete-event
      if (Sig_Name = "destroy") or (Sig_Name = "delete-event") then
         Signal_Data.Has_Quit := True;
      elsif
         -- check if handler string contains the string <quit>
        GNAT.Regpat.Match (Quit_Pattern, Handler, Handler'First, Handler'Last) > 0
      then
         Signal_Data.Has_Quit := True;
      else
         null;
      end if;

      -- register the new signal
      Store (First_Available_Item) := Signal_Data;
      First_Available_Item         := First_Available_Item + 1;

      -- increment top window signal number
      Object_Store (Top_Object).Signumber := Object_Store (Top_Object).Signumber + 1;
   end Store_Signal_Node;

   -----------------------
   -- Get_Signal_Number --
   -----------------------

   function Get_Signal_Number return Natural is
   begin
      return First_Available_Item - 1;
   end Get_Signal_Number;

   --------------------------
   -- Retrieve_Signal_Node --
   --------------------------

   function Retrieve_Signal_Node (Item : Natural) return Signal_Rec is
   begin
      return Store (Item);
   end Retrieve_Signal_Node;

begin

   Compile (Matcher => Event_Pattern, Expression => ".*event$", Flags => Case_Insensitive);
   Compile (Matcher => Ada_Identifier, Expression => "^[a-zA-Z](_?[a-zA-Z0-9])*$");
   Compile (Matcher => Quit_Pattern, Expression => "quit", Flags => Case_Insensitive);

end Signal_Storage;
