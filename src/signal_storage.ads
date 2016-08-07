with Glib.Xml_Int; use Glib.Xml_Int;

package Signal_Storage is

   --
   Bad_Identifier : exception;
   -- raised when any signal name gives a bad Ada identifier
   --

   type Window_Record is record
      Node      : Node_Ptr;
      Signumber : Natural := 0;
   end record;
   -- For each window, store the XML node and the number of signals in the
   -- widget

   Max_Object : constant := 50;
   type Object_Index is range 0 .. Max_Object;

   Object_Store : array (1 .. Object_Index'Last) of Window_Record;
   -- storage for top windows that have signals or shows.

   type Cb_Type is (Func, Proc);
   -- Callback type is a function or procedure
   -- function for event; procedure otherwise

   type Signal_Rec is record
      Signal     : Node_Ptr;
      Top_Window : Object_Index;
      Callback   : Cb_Type := Proc;
      Has_Quit   : Boolean := False;
   end record;
   -- description of infos required to process a signal

   procedure Inc_Object_Number;
   -- increment the number of top windows to show

   function Get_Object_Number return Object_Index;
   -- returns the number of top windows to show

   procedure Initialize_Signals_Store;

   procedure Store_Signal_Node
     (Signal     : in Node_Ptr;
      Top_Object : in Object_Index);

   function Get_Signal_Number return Natural;
   -- returns the total number of signals in the project

   function Retrieve_Signal_Node (Item : Natural) return Signal_Rec;

end Signal_Storage;
