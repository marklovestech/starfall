{&H INSTALLATION OF STARFALL }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : INSTALL.PAS                                          ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This program allows the user to inform STARFALL      ***)
(***                 exactly where the overlay files are being kept.      ***)
(*** Input         : User types a drive designation key.                  ***)
(*** Output        : PARMS.DAT file on default drive                      ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROGRAM install_starfall;

TYPE
  string30      = string[30];

VAR
  param_file    : text;
  overlay_drive : string30;

(****************************************************************************)
(*** WRITE PARAMETER FILE : This opens up PARMS.DAT, shoves the data out  ***)
(*** to it, and then closes the file.                                     ***)
(****************************************************************************)

  PROCEDURE write_parameter_file;
  BEGIN
    ASSIGN(param_file,'PARMS.DAT');
    rewrite(param_file);
    write(param_file,overlay_drive);
    close(param_file);
  END;

(****************************************************************************)
(*** INSTALL - MAINLINE                                                   ***)
(****************************************************************************)

BEGIN
  ClrScr;
  writeln('Installing STARFALL : ');
  writeln;
  writeln;
  writeln('Param #1 : Overlay Drive');
  writeln;
  writeln('Because of the large amount of the STARFALL system that is stored');
  writeln('in overlays, it is strongly suggested that the overlay files for');
  writeln('PLAYGAME be put onto a RAMDISK on your system.  These files are the');
  writeln('following:');
  writeln;
  writeln('PLAYGAME.000     PLAYGAME.001     PLAYGAME.002  etc.');
  writeln;
  writeln('Because of this, STARFALL needs to know where to find the overlay ');
  writeln('files on your system.  Please type in the MSDOS pathname that will');
  writeln('access these overlay files.');
  writeln;
  write('PATHNAME OF OVERLAY FILES (Ex. D:, C:\OVERLAYS, etc) ?');
  readln(overlay_drive);
  IF length(overlay_drive)=1
    THEN
      overlay_drive:=concat(overlay_drive,':');
  write_parameter_file;
END.