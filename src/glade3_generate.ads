-----------------------------------------------------------------------
--  This package generate Ada code from an XML definition file.
--  Top level package
--
-----------------------------------------------------------------------

package Glade3_Generate is

   Debug : Boolean := False;
   -- for internal use

   Old_Version : exception;
   -- raised when obsolete tags are found
   Bad_Xml : exception;
   -- raised when Xml parsing fails

   ---------------------
   -- Initialization  --
   ---------------------

   procedure Set_Template_Dir (Dir : in String);
   -- Set-up the directory where template files should be found.
   -- Dir must be a valid OS string
   -- Must be called at start-up

   ---------------------
   -- Code Generation --
   ---------------------

   procedure Generate
     (Glade_File   : in String;
      Project_Name : in String := "";
      Output_Dir   : in String := "");
   --  Parse xml-file Glade_File and generate the corresponding Ada code.
   --  Glade_File usually looks like /mydir/myapp.glade or rel/myapp.xml
   --  Note : File must be a valid file name and may be case-sensitive.
   --  by default, project_name will be the base name of file.
   --  output is send in a file named <output_dir><base_name(file).ada>
   --  Any existing output file will be overwrittten.

end Glade3_Generate;
