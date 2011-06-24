-----------------------------------------------------------------------
--                        G N A T C O L L                            --
--                                                                   --
--                  Copyright (C) 2011, AdaCore                      --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- As a special exception, if other files instantiate generics  from --
-- this unit, or you link this  unit with other files to produce  an --
-- executable, this unit does not by itself cause the resulting exe- --
-- cutable  to be covered by  the  GNU General  Public License. This --
-- exception does not however  invalidate any other reasons why  the --
-- executable  file  might  be  covered  by  the  GNU General Public --
-- License.                                                          --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Ada.Integer_Text_IO;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;       use Ada.Strings.Unbounded;
with Ada.Unchecked_Conversion;

with GNAT.Encode_UTF8_String;
with GNAT.Decode_UTF8_String;

package body GNATCOLL.JSON.Utility is

   --------------------------------
   -- Escape_Non_Print_Character --
   --------------------------------

   function Escape_Non_Print_Character (C : Wide_Character) return String
   is
      Int : constant Integer := Wide_Character'Pos (C);
      Str : String (1 .. 8);
      First, Last : Natural;

   begin
      Ada.Integer_Text_IO.Put (Str, Int, 16);
      First := Ada.Strings.Fixed.Index (Str, "16#") + 3;
      Last := Ada.Strings.Fixed.Index (Str, "#", Ada.Strings.Backward) - 1;

      --  Make sure we have 4 characters, prefixed with '0's
      Str (Last - 3 .. First - 1) := (others => '0');
      First := Last - 3;

      return "\u" & Str (First .. Last);
   end Escape_Non_Print_Character;

   -------------------
   -- Escape_String --
   -------------------

   function Escape_String (Text : UTF8_String) return String is
      Ret : Unbounded_String;
      WS  : constant Wide_String :=
              GNAT.Decode_UTF8_String.Decode_Wide_String (String (Text));

   begin
      Append (Ret, '"');

      for J in WS'Range loop
         case WS (J) is
            when '"' =>
               Append (Ret, "\""");
            when '\' =>
               Append (Ret, "\\");
            when Wide_Character'Val (Character'Pos (ASCII.BS)) =>
               Append (Ret, "\b");
            when Wide_Character'Val (Character'Pos (ASCII.FF)) =>
               Append (Ret, "\f");
            when Wide_Character'Val (Character'Pos (ASCII.LF)) =>
               Append (Ret, "\n");
            when Wide_Character'Val (Character'Pos (ASCII.CR)) =>
               Append (Ret, "\r");
            when Wide_Character'Val (Character'Pos (ASCII.HT)) =>
               Append (Ret, "\t");
            when others =>
               if Wide_Character'Pos (WS (J)) > 128 then
                  Append (Ret, Escape_Non_Print_Character (WS (J)));
               else
                  Append
                    (Ret, "" & Character'Val (Wide_Character'Pos (WS (J))));
               end if;
         end case;
      end loop;

      Append (Ret, '"');

      return To_String (Ret);
   end Escape_String;

   ----------------------
   -- Un_Escape_String --
   ----------------------

   function Un_Escape_String (Text : String) return UTF8_String is
      First : Integer;
      Last  : Integer;
      Unb   : Unbounded_String;
      Idx   : Natural;

   begin
      First := Text'First;
      Last  := Text'Last;

      --  Trim blancks and the double quotes

      while First <= Text'Last and then Text (First) = ' ' loop
         First := First + 1;
      end loop;
      if First <= Text'Last and then Text (First) = '"' then
         First := First + 1;
      end if;

      while Last >= Text'First and then Text (Last) = ' ' loop
         Last := Last - 1;
      end loop;
      if Last >= Text'First and then Text (Last) = '"' then
         Last := Last - 1;
      end if;

      Idx := First;
      while Idx <= Last loop
         if Text (Idx) = '\' then
            Idx := Idx + 1;

            if Idx > Text'Last then
               raise Invalid_JSON_Stream with
                 "Unexpected escape character at end of line";
            end if;

            case Text (Idx) is
               when 'u' | 'U' =>
                  declare
                     I : constant Short_Integer :=
                           Short_Integer'Value
                             ("16#" & Text (Idx + 1 .. Idx + 4) & "#");
                     function Unch is new Ada.Unchecked_Conversion
                       (Short_Integer, Wide_Character);
                  begin
                     Append
                       (Unb,
                        GNAT.Encode_UTF8_String.Encode_Wide_String
                          ("" & Unch (I)));
                     Idx := Idx + 4;
                  end;

               when '\' =>
                  Append (Unb, '\');
               when 'b' =>
                  Append (Unb, ASCII.BS);
               when 'f' =>
                  Append (Unb, ASCII.FF);
               when 'n' =>
                  Append (Unb, ASCII.LF);
               when 'r' =>
                  Append (Unb, ASCII.CR);
               when 't' =>
                  Append (Unb, ASCII.HT);
               when others =>
                  raise Invalid_JSON_Stream with
                    "Unexpected escape sequence '\" & Text (Idx) & "'";
            end case;

         else
            Append
              (Unb, Text (Idx));
         end if;

         Idx := Idx + 1;
      end loop;

      return UTF8_String (To_String (Unb));
   end Un_Escape_String;

end GNATCOLL.JSON.Utility;
