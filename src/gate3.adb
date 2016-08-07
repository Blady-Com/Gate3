------------------------------------------------------------------------------
--
--  Gate3 code sketcher :
--
--  Parse a Glade3's XML project file and generate the Ada code
--  to test User Interface.
--
--  Gate3 is limited in scope and does not generate User_Handler
--  callbacks. It is just a simple tool to avoid tedious typing.
--
--  Error messages are output on Standard_Output
--  Resulting Ada code is put in [glade-file-name].ada
--  Use gnatchop to generate *.ads and *.adb
------------------------------------------------------------------------------
--
--  Requires Ada libraries :
--       GtkAda : only for Glib
--       templates_parser
------------------------------------------------------------------------------
--  Legal licensing note:
--
--  Copyright (c) Francois Fabien 2012/2013
--  FRANCE
--
--  Gate3 web site : https://sourceforge.net/projects/lorenz/
--
--  Permission is hereby granted, free of charge, to any person obtaining a
--  copy of this software and associated documentation files (the "Software"),
--  to deal in the Software without restriction, including without limitation
--  the rights
--  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--  copies of the Software, and to permit persons to whom the Software is
--  furnished to do so, subject to the following conditions:
--
--  The above copyright notice and this permission notice shall be included in
--  all copies or substantial portions of the Software.
--
--  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
--  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
--  DEALINGS IN THE SOFTWARE.
--
-- NB: this is the MIT License, as found 12-Sep-2007 on the site
-- http://www.opensource.org/licenses/mit-license.php
------------------------------------------------------------------------------

with Ada.Command_Line;      use Ada.Command_Line;
with Ada.Directories;       use Ada.Directories;
with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Exceptions;        use Ada.Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with Ada.Characters.Handling; use Ada.Characters.Handling;

with GNAT.Command_Line; use GNAT.Command_Line;
with GNAT.OS_Lib;       use GNAT.OS_Lib;
with System.Assertions;

with Glade3_Generate; use Glade3_Generate;

procedure Gate3 is

   package UBS renames Ada.Strings.Unbounded;

   Version : constant String := "0.4 (4-Jan-2013)";
   -- gate3 version and release date

   Cmd : constant String := Ada.Command_Line.Command_Name;
   -- command typed to launch gate3

   InputFileName : UBS.String_Access := null;
   -- file name passed at input

   GladeFileName : UBS.String_Access := null;
   -- complete input file name with optional input directory

   Main_Proc_Name : UBS.String_Access := null;
   -- The name of the main Ada procedure
   -- By default will take the prefix of the glade file.

   Input_Dir : UBS.String_Access := null;
   -- optional input directory

   Output_Dir : UBS.String_Access := null;
   -- The directory where the resulting Ada file will be written
   -- By default will be the directory of the input glade file

   Template_Dir : UBS.String_Access := null;
   -- The directory where the templates are read (default is current exec directory)

   Create_Output_Dir : Boolean := False;

   Option : Character;

   procedure Clean_All is
      -- garbage collection
      procedure Clean (SA : in out UBS.String_Access) is
      begin
         if SA /= null then
            Free (SA);
         end if;
      end Clean;
   begin
      Clean (InputFileName);
      Clean (GladeFileName);
      Clean (Main_Proc_Name);
      Clean (Input_Dir);
      Clean (Output_Dir);
   end Clean_All;

   procedure Print_Help is
   begin
      Put_Line ("Usage: gate3 [options] glade3-file");
      Put_Line ("Options:");
      Put_Line ("    -h --help                 show this message");
      Put_Line ("    --version                 show version");
      Put_Line ("    -m proc_name              Proc_Name : Ada main procedure name");
      Put_Line ("    -d some/dir               search some/dir for input files");
      Put_Line ("    -o some/dir               some/dir : directory for output");
      Put_Line ("    -t some/dir               some/dir : directory for templates");
      Put_Line ("    -p                        create output directory");
      New_Line;
   end Print_Help;

   procedure Usage is
   begin
      Put_Line ("Usage: " & Command_Name & " [options] glade3-file");
      Put_Line ("Help: " & Command_Name & " --help");
      New_Line;
   end Usage;

begin
   loop
      begin
         Option := GNAT.Command_Line.Getopt ("h -help -version m: d: o: t: p", False);
         case Option is
            when 'h' =>
               Print_Help;
               return;
            when '-' =>
               if Full_Switch = "-version" then
                  Put_Line (Version);
                  return;
               elsif Full_Switch = "-help" then
                  Print_Help;
                  return;
               else
                  Usage;
                  return;
               end if;
            when 'm' =>
               Main_Proc_Name := new String'(To_Lower (Parameter));
            when 'o' =>
               Output_Dir := new String'(Parameter);
            when 'd' =>
               Input_Dir := new String'(Parameter);
            when 't' =>
               Template_Dir := new String'(Parameter);
            when 'p' =>
               Create_Output_Dir := True;
            when others =>
               null;
         end case;

         exit when Option = ASCII.NUL;
      exception
         when GNAT.Command_Line.Invalid_Switch =>
            Put_Line ("Unknown option [" & Full_Switch & "] ! Ignoring.");
      end;
   end loop;

   -- Find where the gate3 exec file is.
   -- Or find in Template_Dir if set.
   --
   --
   declare
      Gate3_Path : GNAT.OS_Lib.String_Access := GNAT.OS_Lib.Locate_Exec_On_Path (Cmd);
   begin
      if Template_Dir /= null then
         Set_Template_Dir (Template_Dir.all);
      -- setup the path where gate3 will find templates gate3_xxx.tmplt
      elsif Gate3_Path = null then
         Put_Line ("Could not locate gate3 on Path ! stopping.");
         raise Program_Error;
      else
         Set_Template_Dir (Ada.Directories.Containing_Directory (Gate3_Path.all));
         -- setup the path where gate3 will find templates gate3_xxx.tmplt
         GNAT.OS_Lib.Free (Gate3_Path);
      end if;
   end;

   InputFileName := new String'(Get_Argument);

   if InputFileName.all = "" then
      Put_Line ("Gate3 Error : Missing glade-file.");
      Usage;
      Clean_All;
      Set_Exit_Status (1);
      return;
   end if;

   if Input_Dir = null then
      Input_Dir     := new String'("");
      GladeFileName := new String'(InputFileName.all);
   elsif Input_Dir.all = "" then
      GladeFileName := new String'(InputFileName.all);

   elsif Ada.Directories.Exists (Input_Dir.all) then
      if (Ada.Directories.Kind (Input_Dir.all) = Directory) then
         GladeFileName :=
           new String'
             (Compose
                (Input_Dir.all,
                 Base_Name (InputFileName.all),
                 Extension (InputFileName.all)));
      else
         Put_Line ("Gate3 Error : input parameter [" & Input_Dir.all & "] is not a directory.");
         Clean_All;
         Set_Exit_Status (1);
         return;
      end if;

   else
      Put_Line ("Gate3 Error : input directory [" & Input_Dir.all & "] does not exist.");
      Clean_All;
      Set_Exit_Status (1);
      return;
   end if;

   if not Ada.Directories.Exists (GladeFileName.all) then
      Put_Line ("Gate3 Error : file [" & GladeFileName.all & "] does not exist.");
      Clean_All;
      Set_Exit_Status (1);
      return;
   end if;

   if Main_Proc_Name = null then
      Main_Proc_Name := new String'("");
   end if;

   -- checks on the output directory
   if Output_Dir = null then
      Output_Dir := new String'("");
   else
      if not Ada.Directories.Exists (Output_Dir.all) then
         if Create_Output_Dir then
            begin
               Ada.Directories.Create_Directory (Output_Dir.all);
            exception
               when E : others =>
                  Put_Line ("Exception = " & Exception_Name (E));
                  Put_Line ("Gate3 Error : Invalid directory name [" & Output_Dir.all & "].");
                  Clean_All;
                  Set_Exit_Status (2);
                  return;
            end;
         else
            Put_Line ("Gate3 Error : Output directory [" & Output_Dir.all & "] does not exist.");
            Clean_All;
            Set_Exit_Status (2);
            return;
         end if;
      else
         -- output dir exists, stops when it is not a dir
         if not (Ada.Directories.Kind (Output_Dir.all) = Directory) then
            Put_Line ("Gate3 Error : [" & Output_Dir.all & "] is not a directory.");
            Clean_All;
            Set_Exit_Status (2);
            return;
         end if;
      end if;
   end if;

   Generate (GladeFileName.all, Project_Name => Main_Proc_Name.all, Output_Dir => Output_Dir.all);

   Put_Line ("Gate3 v" & Version & " | Your file has been successfully processed.");
   Clean_All;
exception
   when System.Assertions.Assert_Failure =>
      Put_Line ("gate3 Error : the XML file seems corrupted.");
      Put_Line ("Please check it up manually, and try again");
      Clean_All;
      Set_Exit_Status (2);

   when E : Glade3_Generate.Old_Version =>
      Put_Line (Exception_Message (E));
      Put_Line ("Version of Glade file is too old");
      Put_Line ("Use Version 2.24 of GTK and Glade 3.8.");
      Clean_All;
      Set_Exit_Status (2);

   when E : Glade3_Generate.Bad_Xml =>
      Put_Line (Exception_Message (E));
      Put_Line ("Glade Xml file could not be processed");
      Clean_All;
      Set_Exit_Status (2);

   when E : others =>
      Put_Line ("Exception = " & Exception_Name (E));
      Put_Line ("Message   = " & Exception_Message (E));
      Put_Line ("gate3 : Internal error.");
      Put_Line
        ("Please send a bug report with the XML file " &
         " and the GtkAda version to francois_fabien@hotmail.com");
      Clean_All;
      Set_Exit_Status (2);
end Gate3;
