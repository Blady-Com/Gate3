with Ada.Characters.Handling; use Ada.Characters.Handling;
with Glib.Object;             use Glib.Object;

package body Gate3_Glib is

   ------------
   -- To_Ada --
   ------------

   function To_Ada (S : String; Separator : Character := '_') return String is
      First   : constant Positive := S'First;
      K       : Positive          := 2;
      Last    : Integer           := 0;
      R       : String (1 .. S'Length * 2);
      Has_Sep : Boolean;

      function Has_Separator (S : String) return Boolean is
      begin
         for J in S'Range loop
            if S (J) = Separator then
               return True;
            end if;
         end loop;

         return False;
      end Has_Separator;

   begin
      if S'Length = 0 then
         return S;
      end if;

      Has_Sep := Has_Separator (S);

      R (1) := To_Upper (S (First));

      for J in First + 1 .. S'Last loop
         --  Add a separator if the separator is not nul, if the current
         --  character is in upper case and if the string doesn't have any
         --  separator.

         if Separator /= ASCII.NUL
           and then Is_Upper (S (J))
           and then not Has_Sep
           and then J /= Last + 1
         then
            R (K) := Separator;
            K     := K + 1;
            Last  := J;
         end if;

         if S (J) = '-' then
            R (K) := Separator;
         else
            if R (K - 1) = Separator then
               R (K) := To_Upper (S (J));
            else
               R (K) := To_Lower (S (J));
            end if;
         end if;

         K := K + 1;
      end loop;

      return R (1 .. K - 1);
   end To_Ada;

   ---------------------
   -- Find_Top_Object --
   ---------------------

   function Find_Top_Object (N : Node_Ptr) return Node_Ptr is
      P, Q : Node_Ptr;
   begin
      Q := N;
      P := N.Parent;

      if P /= null then
         while P.Tag.all /= "interface" loop
            Q := P;
            P := P.Parent;
         end loop;
      end if;

      return Q;
   end Find_Top_Object;

end Gate3_Glib;
