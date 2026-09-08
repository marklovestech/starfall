{$U+}

PROGRAM Genesis(input,output,diskfile,helpfile,scorefile,
                chain_file);

(*****************************************************************************)
(***** CONSTANT, TYPE, AND VARIABLE SECTION - INCLUSION FILE CTVSEC.PAS  *****)
(*****************************************************************************)

{$I CTVSEC.PAS}

VAR
  chain_file                           : file;

(******** START OF REAL PROCEDURES ******)

(* Include routine to read the keyboard, including function keys. *)
{$I TIMER.PAS}
{$I GETKEY.PAS}

(****************************************************************************)

PROCEDURE title_page;
VAR
  loop  : integer;
BEGIN
  ClrScr;
  writeln;
  writeln('****************************************************************************');
  writeln('**                                                                        **');
  writeln('**                         GENESIS - A second try                         **');
  writeln('**                                                                        **');
  writeln('**      Written for Math 306 - Program Design during the                  **');
  writeln('**                  Spring Semester, 1986 at the Colorado                 **');
  writeln('**                  School of Mines.                                      **');
  writeln('**                                                                        **');
  writeln('**      Production team:                                                  **');
  writeln('**           Designer   : John Stevens                                    **');
  writeln('**           Programmer : Mark Porter                                     **');
  writeln('**           Documenter : Jeanne Barnett                                  **');
  writeln('**           Debugger   : Susan Gager                                     **');
  writeln('**                                                                        **');
  writeln('**                                                                        **');
  writeln('**                                                                        **');
  writeln('**      Press any key to begin                                            **');
  writeln('**                                                                        **');
  writeln('****************************************************************************');
  choice:=get_key(fkey);
END;

{$U+}

PROCEDURE instructions;
BEGIN
END;

BEGIN
  title_page;
  REPEAT
    REPEAT
      ClrScr;
      writeln('Choose from the following:');
      writeln;
      writeln('  I)nstructions');
      writeln('  S)tart game with world on disk');
      writeln('  C)reate new world and write to disk');
      writeln('  M)odify world resource file');
      writeln('  E)xamine score file');
      writeln('  Q)uit');
      writeln;
      write('Choice: ');
      choice:=get_key_with_clock(fkey);
    UNTIL choice IN ['i','I','s','S','c','C','m','M','e','E','q','Q'];

    CASE choice OF
      'i','I'     : instructions;
      's','S'     : BEGIN
                      ASSIGN(chain_file,'PLAYGAME.COM');
                      EXECUTE(chain_file);
                    END;
      'c','C'     : BEGIN
                      ASSIGN(chain_file,'MAKEWRLD.COM');
                      EXECUTE(chain_file);
                    END;
      'm','M'     : BEGIN
                      ASSIGN(chain_file,'WRLDSHAK.COM');
                      EXECUTE(chain_file);
                    END;
      'e','E'     : BEGIN
                      ASSIGN(chain_file,'SHOSCORE.COM');
                      EXECUTE(chain_file);
                    END;
      'q','Q'     : ;
    END; (* case *)
  UNTIL choice IN ['q','Q'];
END.