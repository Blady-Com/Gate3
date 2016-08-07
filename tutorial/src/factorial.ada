------------------------------------------------------------------------------
--                                                                          --
--  File generated by gate3                                                 --
--  Glade3 original file : factorial.glade
--  Generation date  : 2012-12-25 15:48:41                                  --
--                                                                          --
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Legal licensing note:
--
--  Copyright (c) surname name
--  FRANCE
--  Send bug reports to captain.nemo@jules-verne.fr
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--  DEALINGS IN THE SOFTWARE.
--  NB: this is the MIT License, as found 12-Sep-2007 on the site
--  http://www.opensource.org/licenses/mit-license.php

------------------------------------------------------------------------------
-- units from Gtk
with Gtk;            use Gtk;
with Gtk.Main;
with Glib.Error;     use Glib.Error;
with Gtk.Widget;     use Gtk.Widget;
with Gtkada.Builder; use Gtkada.Builder;

-- Ada predefined units
with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;

-- Application specific units
with Window1_Callbacks; use Window1_Callbacks;

procedure Factorial is

   Builder       : Gtkada_Builder;
   Error         : Glib.Error.GError;
   GladeFileName : constant String := "factorial.glade";

begin

   Gtk.Main.Init;

   -- Step 1: create a Builder and add the XML data

   Gtk_New (Builder);
   Error := Add_From_File (Builder, GladeFileName);
   if Error /= null then
      Put_Line ("Error : " & Get_Message (Error));
      Error_Free (Error);
      return;
   end if;

   --  Step 2: add calls to "Register_Handler" to associate your
   --  handlers with your callbacks.

   Register_Handler (Builder, "on_window1_delete_event", On_Window1_Delete_Event'Access);
   Register_Handler (Builder, "gtk_main_quit", Gtk_Main_Quit'Access);
   Register_Handler (Builder, "on_button2_clicked", On_Button2_Clicked'Access);

   -- Step 3: call Do_Connect. Once to connect all registered handlers

   Do_Connect (Builder);

   Put_Line ("Factorial : loading and connexion of builder OK ");

   -- Step 3.5 : display the windows and all of their children.
   --            Remove objects than are not windows as necessary.

   Show_All (Get_Widget (Builder, "window1"));
   Gtk.Main.Main;

   --  Step 4: when the application terminates
   --          call Unref to free memory associated with the Builder.
   Unref (Builder);
   Put_Line ("Program Factorial is finished !");

exception
   when Error : others =>
      Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (Error));

end Factorial;
-----------------------------------------------------------------------------

with Gtkada.Builder; use Gtkada.Builder;

package Window1_Callbacks  is

   function On_Window1_Delete_Event  (Builder : access Gtkada_Builder_Record'Class)
      return Boolean;

   procedure Gtk_Main_Quit (Builder : access Gtkada_Builder_Record'Class);

   procedure On_Button2_Clicked (Builder : access Gtkada_Builder_Record'Class);


end Window1_Callbacks;
-----------------------------------------------------------------------------

-- units from Gtk
with Gtk.Main;       use Gtk.Main;

-- Ada predefined units
with Ada.Text_IO;    use Ada.Text_IO;

-- Application specific units

package body Window1_Callbacks  is

   -----------------------------------------------
   -- On_Window1_Delete_Event
   -----------------------------------------------

   function On_Window1_Delete_Event  (Builder : access Gtkada_Builder_Record'Class)
      return Boolean is
      pragma Unreferenced (Builder);
   begin
      Put_Line ("Within handler On_Window1_Delete_Event");
      Gtk.Main.Main_Quit;
      return False;
   end On_Window1_Delete_Event;

   -----------------------------------------------
   -- Gtk_Main_Quit
   -----------------------------------------------

   procedure Gtk_Main_Quit (Builder : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Builder);
   begin
      Put_Line ("Within handler Gtk_Main_Quit");
      Gtk.Main.Main_Quit;
   end Gtk_Main_Quit;

   -----------------------------------------------
   -- On_Button2_Clicked
   -----------------------------------------------

   procedure On_Button2_Clicked (Builder : access Gtkada_Builder_Record'Class) is
      pragma Unreferenced (Builder);
   begin
      Put_Line ("Within handler On_Button2_Clicked");
   end On_Button2_Clicked;


end Window1_Callbacks;

