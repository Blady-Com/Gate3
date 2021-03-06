------------------------------------------------------------------------------
--                                                                          --
--  File generated by gate3                                                 --
--  Glade3 original file : /usr/local/src-2019/gate3_05/tutorial/factorial.glade
--  Generation date  : 2019-08-24 04:42:08                                  --
--
--  Gate3 web site : https://sourceforge.net/projects/lorenz/                                                                   --
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--  Legal licensing note : !!! Edit the file gate3_license.txt !!!
--
--  Copyright (c) F. J. FABIEN - 2013
--  Berry
--  FRANCE
--  Send bug reports or feedback to : francois_fabien@hotmail.com
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
with Glib;           use Glib;
with Glib.Object;
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
   Error         : aliased Glib.Error.GError;
   GladeFileName : constant String := "factorial.glade";

begin

   Gtk.Main.Init;

   -- Step 1: create a Builder and add the XML data

   Gtk_New (Builder);
   if Add_From_File (Builder, GladeFileName, Error'Access) = 0 then
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

   Show_All (Gtk.Widget.Gtk_Widget (Get_Object (Builder, "window1")));
   Gtk.Main.Main;

   --  Step 4: when the application terminates
   --          call Unref to free memory associated with the Builder.
   Unref (Builder);
   Put_Line ("Program Factorial is finished !");

exception
   when Error : others =>
      Ada.Text_IO.Put_Line (Ada.Exceptions.Exception_Information (Error));

end Factorial;
