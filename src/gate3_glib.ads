-----------------------------------------------------------------------
--
-- simple XML Parser using glib & utilities
--
-----------------------------------------------------------------------

with Glib.Xml_Int; use Glib.Xml_Int;
pragma Elaborate_All (Glib.Xml_Int);

package Gate3_Glib is

   -- utility functions

   function To_Ada (S : String; Separator : Character := '_') return String;
   --  Convert S by adding a separator before each upper case character.
   --  Also put in upper case each character following a separator.

   function Find_Top_Object (N : Node_Ptr) return Node_Ptr;
   --  Find a node in the ancestors of N that represents a root object.

end Gate3_Glib;
