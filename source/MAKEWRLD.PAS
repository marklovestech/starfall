{&H MAKEWRLD - Program to create worlds for STARFALL }
{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : MAKEWRLD.COM                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This is the program that creates the worlds that the ***)
(***                 user plays with.  It has no prompting to start, and  ***)
(***                 all of its constants come out of CTVSEC.             ***)
(***                 It starts out by defining the continents, and then   ***)
(***                 goes on to make a base hydrograph and temperature    ***)
(***                 chart for the whole world.  After that, it starts to ***)
(***                 lay out the altitudes for the land items.  As it     ***)
(***                 does this, it also finalizes the temperature for the ***)
(***                 block and the moisture (hydrograph) for the block.   ***)
(***                 The last thing it does is lay out the subsurface     ***)
(***                 minerals that are present on the planet.             ***)
(***                      After all of the creation has been done, the    ***)
(***                 user is prompted to enter a text name and a file     ***)
(***                 name for the world.  Then, after the world has been  ***)
(***                 saved, the user is returned to the STARFALL main     ***)
(***                 menu.                                                ***)
(*** Input         : None.                                                ***)
(*** Output        : World File on disk.                                  ***)
(*** Special Notes : none                                                 ***)
(****************************************************************************)

PROGRAM make_world;

{$I CTVSEC.PAS}

CONST
  world_temperature_gradient_factor    = 10;     (* This defines how fast the temperature changes *)
  Base_land_percentage                 = 10;     (* These other constants all define various      *)
  Modifier_land_percentage             = 10;     (* parameters about the making of a world.       *)
  Base_continent_percentage            = 25;     (*       "                             "         *)
  Modifier_continent_percentage        = 10;     (*       "                             "         *)
  Base_mineral_percentage              = 35;     (*       "                             "         *)
  Modifier_mineral_percentage          = 20;     (*       "                             "         *)

TYPE
  {--------------------------------------------------------------------------}
  { The following two TYPE definitions define the 'land list' that MAKEWRLD  }
  { uses.  This land list is a linked list of all the land items that are    }
  { present on the world.  It is only used here, in MAKEWRLD.  Among other   }
  { things, it is used to lay out the altitudes in a meaningful, TRULY       }
  { random way.                                                              }
  {--------------------------------------------------------------------------}

  land_list_ptr                        = ^land_list_item;
  land_list_item                       = RECORD
                                           next         : land_list_ptr;
                                           x            : integer;
                                           y            : byte;
                                           climate      : byte;
                                           altitude     : byte;
                                           resources    : resource_ptr;
                                         END;

  {--------------------------------------------------------------------------}
  { The world is arranged as a list (288 long) of pointers, which point down }
  { at lists (144 long) of more pointers.  These in turn point at the data   }
  { (if any) for the world space in question.  An entry of NIL in the        }
  { double-referenced table indicates that that land item has water there.   }
  {--------------------------------------------------------------------------}
  world_mat_column_ptr                 = ^world_matrix_column;

  world_matrix_column                  = ARRAY[1..world_height]
                                         of land_list_ptr;

  world_mat_type                       = ARRAY[1..world_width]
                                         of world_mat_column_ptr;
VAR
  {--------------------------------------------------------------------------}
  { The following variable is the first reference level of the world matrix, }
  { as described above.  Note that this is kept in main memory, to make      }
  { access just a tiny bit quicker.                                          }
  {--------------------------------------------------------------------------}
  world_matrix                         : world_mat_type;

  {--------------------------------------------------------------------------}
  { This variable points at the beginning of the land list for MAKEWRLD.     }
  { If it is NIL, then there is no land allocated as yet.                    }
  {--------------------------------------------------------------------------}
  land_list_root                       : land_list_ptr;

{$I GRAPH306.P  }  { TURBO graphics routines.                                }
{$I NOISE.PAS   }  { Various routines to make the noises we like             }
{$I GETWRLDN.PAS}  { Procedure to read a world name from the user            }
{$I CLRTIME.PAS }  { Procedure to clear a time variable.                     }
{$I INITSRMT.PAS}  { Procedure to initialize the surface resource matrix.    }
{$I RDRSRCFL.PAS}  { Procedure to read resource file.                        }
{$I DRAWBOX.PAS }  { Procedure to draw a box.                                }
{$I LANDPRIM.PAS}  { Various primitive routines for handling land/water, etc.}
{$I RSRCFLAG.PAS}  { Routines to deal with the FLAGS byte in a resource.     }
{$I SETWRLDM.PAS}  { Procedure to set up the graphics params for world map   }
{$I MAPPRIMS.PAS}  { Primitive routines to draw on the maps, etc.            }
{$I HRLLPRCS.PAS}  { Procedures to deal with the human resource list.        }

{&P}
(****************************************************************************)
(*** PAINT LAND CHUNK : This takes in a land list pointer and draw its    ***)
(*** data on the screen.                                                  ***)
(****************************************************************************)

PROCEDURE paint_land_chunk(land_loc  : land_list_ptr;
                           color     : integer);
BEGIN
  draw_on_world_map(land_loc^.x,land_loc^.y,color);
END;

(****************************************************************************)
(*** SHOW WORLD MAP GRID : This procedure out onto the screen and draws   ***)
(*** up the pretty grid around the world map, with all of its ticks, etc. ***)
(****************************************************************************)

PROCEDURE show_world_map_grid;
VAR
  loop:integer;
BEGIN
  GraphWindow(wm_x_coord,wm_y_coord,screen_width,screen_height);
  FOR loop:=1 to 37 DO
    BEGIN
      draw(loop*wm_sector_width-2,
           0,
           loop*wm_sector_width+-2,
           wm_tick_length,
           wm_white);
      draw(loop*wm_sector_width+-2,
           world_height+2+wm_tick_length,

           loop*wm_sector_width-2,
           world_height+2+2*wm_tick_length,
           wm_white);
    END;

  FOR loop:=1 to 19 DO
    BEGIN
      draw(0,
           loop*wm_sector_height-2,
           wm_tick_length,
           loop*wm_sector_height-2,
           wm_white);
      draw(world_width+2+wm_tick_length,
           loop*wm_sector_height-2,
           world_width+2+2*wm_tick_length,
           loop*wm_sector_height-2,
           wm_white);
    END;

  draw_box(wm_tick_length+1,
           wm_tick_length+1,
           wm_tick_length+2+world_width,
           wm_tick_length+2+world_height,
           wm_white);

  GraphWindow(wm_x_coord+wm_tick_length+2,
              wm_y_coord+wm_tick_length+2,
              wm_x_coord+wm_tick_length+1+world_width,
              wm_y_coord+wm_tick_length+1+world_height);
  FillScreen(wm_blue);
  GraphWindow(0,0,screen_width,screen_height);
END;

(****************************************************************************)
(*** ADD TO LAND LIST : As mentioned above, in the VAR section, MAKEWRLD  ***)
(*** uses a linked list of land items to do a lot of the randomization    ***)
(*** necessary.  This is the procedure that adds in an item to this list. ***)
(****************************************************************************)

PROCEDURE add_to_land_list(x_coord,y_coord:integer);
VAR
  new_one   : land_list_ptr;
BEGIN
  (* Make new item *)
  new(new_one);
  world_matrix[x_coord]^[y_coord]:=new_one;

  (* Link into land list *)
  new_one^.next:=land_list_root;
  land_list_root:=new_one;

  (* initialize all fields *)
  new_one^.climate:=0;
  new_one^.altitude:=0;
  new_one^.x:=x_coord;
  new_one^.y:=y_coord;
  new_one^.resources:=NIL;
END;

(****************************************************************************)
(*** COLOR ADJACENCY : Given a color to look for and a block to look      ***)
(*** around, this function returns the number of blocks around the given  ***)
(*** one that are that color.                                             ***)
(****************************************************************************)

FUNCTION color_adjacency(x,y,color:integer):integer;
VAR
  temp:integer;
BEGIN
  temp:=0;
  IF x>1
    THEN
      IF get_map_value(x-1,y)=color
        THEN
          temp:=succ(temp);
  IF x<world_width
    THEN
      IF get_map_value(x+1,y)=color
        THEN
          temp:=succ(temp);
  IF y>1
    THEN
      IF get_map_value(x,y-1)=color
        THEN
          temp:=succ(temp);
  IF y<world_height
    THEN
      IF get_map_value(x,y+1)=color
        THEN
          temp:=succ(temp);
  color_adjacency:=temp;
END;

(****************************************************************************)
(*** LATITUDE OF : Given a y coordinate, this returns its latitude.       ***)
(****************************************************************************)

FUNCTION latitude_of(y_coord:integer):integer;
BEGIN
  latitude_of:=trunc(abs(y_coord-(world_height DIV 2))/(world_height DIV 2)*90);
END;

(****************************************************************************)
(*** MAKE BASE HYDRO AND TEMP : This is the part of the program that runs ***)
(*** that crazy little red dot around the world map.  Along the way, it   ***)
(*** takes percentage readings of land vs. water readings, and also takes ***)
(*** latitude readings for temperature.  It stores these out in memory,   ***)
(*** and later, when we do altitudes, we refine these down a lot.         ***)
(****************************************************************************)

PROCEDURE make_base_hydro_and_temp;
VAR
  sector_x_loop : integer;
  sector_y_loop : integer;
  sector_result : integer;
  temp          : integer;
  block_x_loop  : integer;
  block_y_loop  : integer;
  temp_temp     : integer;
  temp_moist    : integer;

(****************************************************************************)
(*** SECTOR BASE HYDROGRAPH : This generates a percentage reading of      ***)
(*** moisture for the sector given.                                       ***)
(****************************************************************************)

  FUNCTION sector_base_hydrograph(sector_x,sector_y:integer):integer;
  VAR
    block_loop_x   : integer;
    block_loop_y   : integer;
    number_water   : integer;
  BEGIN
    number_water:=0;
    FOR block_loop_x:=1 to 8 DO
      FOR block_loop_y:=1 to 8 DO
        BEGIN
          IF water_at(sector_x*wm_sector_width+block_loop_x,
                      sector_y*wm_sector_width+block_loop_y)
            THEN
              number_water:=succ(number_water);
        END;
    sector_base_hydrograph:=trunc(100*(number_water/64));
  END;

BEGIN
  FOR sector_x_loop:=0 to 35 DO
    FOR sector_y_loop:=0 to 17 DO
      BEGIN
        temp:=get_map_value(sector_x_loop*wm_sector_width+4,
                            sector_y_loop*wm_sector_height+4);
        draw_on_world_map(sector_x_loop*wm_sector_width+4,
                          sector_y_loop*wm_sector_height+4,
                          wm_red);
        sector_result:=sector_base_hydrograph(sector_x_loop,sector_y_loop);
        IF sector_result<>100
          THEN
            FOR block_x_loop:=1 to 8 DO
              FOR block_y_loop:=1 to 8 DO
                BEGIN
                  IF land_at(sector_x_loop*wm_sector_width+block_x_loop,
                             sector_y_loop*wm_sector_height+block_y_loop)
                    THEN
                      BEGIN
                        temp_moist:=trunc((sector_result / 100.0) * 16.0)+4;
                        IF temp_moist>15
                           THEN
                             temp_moist:=15
                           ELSE
                             IF temp_moist<0
                               THEN
                                 temp_moist:=0;
                        set_moisture(sector_x_loop*wm_sector_width+block_x_loop,
                                     sector_y_loop*wm_sector_height+block_y_loop,
                                     temp_moist);
                        temp_temp:=8+((temperate_latitude-
                                       abs(latitude_of(sector_y_loop*wm_sector_height+block_y_loop)))
                                      DIV world_temperature_gradient_factor);
                        IF temp_temp<0
                          THEN
                            temp_temp:=0
                          ELSE
                            IF temp_temp>15
                              THEN
                                temp_temp:=15;
                        set_temperature(sector_x_loop*wm_sector_width+block_x_loop,
                                        sector_y_loop*wm_sector_height+block_y_loop,
                                       temp_temp);
                      END;
                END;
        draw_on_world_map(sector_x_loop*wm_sector_width+4,
                          sector_y_loop*wm_sector_height+4,
                          temp);
      END;
END;

(****************************************************************************)
(*** MAKE HYDROGRAPH : This procedure, once we know the altitude, refines ***)
(*** down the hydrograph to a precise number for each block.              ***)
(****************************************************************************)

PROCEDURE make_hydrograph(x,y:integer);
VAR
  moisture:integer;
BEGIN
  moisture:=moisture_from_climate(world_matrix[x]^[y]^.climate)
          + ((color_adjacency(x,y,wm_blue)-1) + (random(3)-1));
  IF moisture>15
    THEN
      moisture:=15
    ELSE
      IF moisture<0
        THEN
          moisture:=0;
  set_moisture(x,y,moisture);
END;

(****************************************************************************)
(*** MAKE TEMPERATURE : This procedure, once we know the altitude,        ***)
(*** down the temperature to a precise number for each block.             ***)
(****************************************************************************)

PROCEDURE make_temperature(x,y:integer);
VAR
  temp : integer;
BEGIN
  temp:=temperature_from_climate(world_matrix[x]^[y]^.climate)
      -((world_matrix[x]^[y]^.altitude-1) DIV 30)
      + random(2);
  IF temp>15
    THEN
      temp:=15
    ELSE
      IF temp<0
        THEN
          temp:=0;
  set_temperature(x,y,temp);
END;

(****************************************************************************)
(*** MAKE ALTITUDES : This routine takes the world right after the base   ***)
(*** hydrograph and temperature have been generated, and, using a strange ***)
(*** algorithm, we decide how the altitudes of each block are going to be ***)
(*** laid out and then we refine down the hydrograph and temperature.     ***)
(****************************************************************************)

PROCEDURE make_altitudes;
VAR
  x_loop:integer;
  y_loop:integer;
  current_land_chunk : land_list_ptr;
  nothing_changed:boolean;
  temporary_altitude:integer;


(****************************************************************************)
(*** AVERAGE ALTITUDE AROUND : given a block, this function returns the   ***)
(*** the average altitude in the blocks around that block.                ***)
(****************************************************************************)

  FUNCTION average_altitude_around(x,y:integer):byte;
  VAR
    number_initialized : integer;
    total_altitudes    : integer;
    temp_x             : integer;

  BEGIN
    number_initialized:=0;
    total_altitudes:=0;
    IF x<=1 THEN temp_x:=world_width
            ELSE temp_x:=x-1;

    IF world_matrix[temp_x]^[y]^.altitude>0
      THEN
        BEGIN
          number_initialized:=succ(number_initialized);
          total_altitudes:=total_altitudes+world_matrix[temp_x]^[y]^.altitude;
        END;

    IF x>=world_width THEN temp_x:=1
                      ELSE temp_x:=x+1;

    IF world_matrix[temp_x]^[y]^.altitude>0
      THEN
        BEGIN
          number_initialized:=succ(number_initialized);
          total_altitudes:=total_altitudes+world_matrix[temp_x]^[y]^.altitude;
        END;

    IF y>1
      THEN
        IF world_matrix[x]^[y-1]^.altitude>0
          THEN
            BEGIN
              number_initialized:=succ(number_initialized);
              total_altitudes:=total_altitudes+world_matrix[x]^[y-1]^.altitude;
            END;

    IF y<world_height
      THEN
        IF world_matrix[x]^[y+1]^.altitude>0
          THEN
            BEGIN
              number_initialized:=succ(number_initialized);
              total_altitudes:=total_altitudes+world_matrix[x]^[y]^.altitude;
            END;

    average_altitude_around:=trunc(total_altitudes/number_initialized);
  END;

(****************************************************************************)
(*** MAKE ALTITUDES - MAINLINE CODE                                       ***)
(****************************************************************************)

BEGIN
  current_land_chunk:=land_list_root;

  WHILE current_land_chunk<>NIL DO
    BEGIN
      WITH current_land_chunk^ DO
        BEGIN
          IF color_adjacency(x,y,wm_blue)>0 (* if by water *)
            THEN
              BEGIN
                altitude:=random(2)+1;
                make_hydrograph(x,y);
                make_temperature(x,y);
                draw_on_world_map(x,y,wm_red);
              END;
        END;
      current_land_chunk:=current_land_chunk^.next;
    END;

  REPEAT
    nothing_changed:=true;
    current_land_chunk:=land_list_root;
    WHILE current_land_chunk<>NIL DO
      BEGIN
        WITH current_land_chunk^ DO
          BEGIN
            IF altitude=0
              THEN
                BEGIN
                  nothing_changed:=false;
                  (* we do this because we want to continue until all *)
                  (* land has been laid out with a non-zero altitude. *)

                  IF color_adjacency(x,y,wm_red)>(random(5))
                    THEN
                      BEGIN
                        draw_on_world_map(x,y,wm_red);
                        temporary_altitude:=(random(6)-1)
                                           +average_altitude_around(x,y);
                        IF temporary_altitude<1
                          THEN
                            temporary_altitude:=random(2)+1;
                        IF temporary_altitude>max_altitude
                          THEN
                            temporary_altitude:=max_altitude;

                        (* There is a very good reason for using a *)
                        (* temporary variable here - the stupid system *)
                        (* wraps a BYTE type variable around - *)
                        (* 5-15 = 245, NOT -10! *)

                        altitude:=temporary_altitude;
                        make_hydrograph(x,y);
                        make_temperature(x,y);
                      END;
                END;
          END;
        current_land_chunk:=current_land_chunk^.next;
      END;
  UNTIL nothing_changed;
END;

{$I MAKETZON.PAS}
{$I TEMPZONE.PAS}
{$I WRLDPICS.PAS}

(****************************************************************************)
(*** DO LAND MASSES : This procedure is the part of the code that draws   ***)
(*** that schizo green dot all around the ocean.                          ***)
(****************************************************************************)

PROCEDURE do_land_masses;
VAR
  land_percentage      : real;
  land_area            : integer;
  total_land_area      : integer;
  continent_area       : integer;
  continent_area_used  : integer;
  continent_area_left  : integer;
  continent_radius     : integer;
  loop                 : integer;


(****************************************************************************)
(*** MAKE CONTINENT : Given a starting X,Y, this procedure goes and draws ***)
(*** a continent at that spot.  This is a recursive procedure, and it     ***)
(*** calls itself again and again until it feels bounded by the various   ***)
(*** tests embedded in the code.                                          ***)
(****************************************************************************)

  PROCEDURE make_continent(at_x,at_y,level:integer);
  VAR
    dir_used : ARRAY[0..3] of boolean;
    new_dir : 0..3;
  BEGIN
    dir_used[0]:=false;     (* north *)
    dir_used[1]:=false;     (* south *)
    dir_used[2]:=false;     (* east *)
    dir_used[3]:=false;     (* west *)
    IF at_x<1 THEN at_x:=world_width
              ELSE IF at_x>world_width THEN at_x:=1;
    IF  (at_y>0)
    AND (at_y<=world_height)
    AND (continent_area_left>0)
    AND (continent_radius*1.5>(level-random(15)))
      THEN
        BEGIN
          IF water_at(at_x,at_y)
            THEN
              BEGIN
                continent_area_left:=pred(continent_area_left);
                continent_area_used:=succ(continent_area_used);
                draw_on_world_map(at_x,at_y,wm_green);
                add_to_land_list(at_x,at_y);
                REPEAT
                  new_dir:=random(4);
                  IF NOT dir_used[new_dir]
                    THEN
                      BEGIN
                        dir_used[new_dir]:=true;
                        CASE new_dir OF
                          0 : make_continent(at_x,at_y-1,level+1);
                          1 : make_continent(at_x,at_y+1,level+1);
                          2 : make_continent(at_x+1,at_y,level+1);
                          3 : make_continent(at_x-1,at_y,level+1);
                        END; (* CASE *)
                      END;
                UNTIL (dir_used[0]
                   AND dir_used[1]
                   AND dir_used[2]
                   AND dir_used[3])
                   OR (continent_area_left<0);
              END;
        END;
  END;

(****************************************************************************)
(*** DO LAND MASSES - MAINLINE CODE                                       ***)
(****************************************************************************)

BEGIN
  land_percentage:=(base_land_percentage
    +(random(modifier_land_percentage)))/100;

  total_land_area:=trunc(land_percentage*world_width*world_height);
  land_area:=total_land_area;
  REPEAT
    continent_area:=trunc((base_continent_percentage+random(modifier_continent_percentage))
                  /100*total_land_area);
    continent_radius:=trunc(sqrt(continent_area));
    continent_area_used:=0;
    continent_area_left:=continent_area;
    make_continent(random(world_width)+1,random(world_height)+1,0);
    land_area:=land_area-continent_area_used;
  UNTIL land_area<=0;
END;

{$I ALLCRSRC.PAS}

(****************************************************************************)
(*** DO RESOURCE ALLOCATION : This calls the routines above in the include***)
(*** file.                                                                ***)
(****************************************************************************)

PROCEDURE do_resource_allocation;
BEGIN
  allocate_subsurface_resources;
END;

{$I SAVEWRLD.PAS}
{$I INITWMAT.PAS}

(****************************************************************************)
(*** INITIALIZE GAME TIME : This starts out the game time at some date    ***)
(*** in the 23rd century...                                               ***)
(****************************************************************************)

PROCEDURE initialize_game_time;
BEGIN
  game_time.date:=random(days_per_month)+1;
  game_time.month:=random(months_per_year)+1;
  game_time.year:=lowest_game_year+random(game_year_range);
  game_time.hour:=random(hours_per_day);
  game_time.minute:=random(minutes_per_hour);
  game_time.second:=random(seconds_per_minute);
END;

(****************************************************************************)
(*** INITIALIZE GAME TIME INCREMENT : This starts out the time at         ***)
(*** six minutes of game time to 1 second of real time.                   ***)
(****************************************************************************)

PROCEDURE initialize_game_time_increment;
BEGIN
  clear_time(game_time_increment);
  game_time_increment.minute:=trunc(minutes_per_hour/10);
END;

(****************************************************************************)
(*** INITIALIZE WORLD UPDATE INCREMENT : This initializes the maximum     ***)
(*** update increment to 8 hours.                                         ***)
(****************************************************************************)

PROCEDURE initialize_world_update_increment;
BEGIN
  clear_time(world_update_increment);
  world_update_increment.hour:=trunc(hours_per_day/3);
END;

(****************************************************************************)
(*** INITIALIZE BLOCK START : This procedure sets up where the cursor     ***)
(*** is when the game starts.                                             ***)
(****************************************************************************)

PROCEDURE initialize_block_start;
BEGIN
  current_block_x:=world_width DIV 2;
  current_block_y:=world_height DIV 2;
END;

(****************************************************************************)
(*** INITIALIZATION : This procedure calls all of the various             ***)
(*** initialization routines. See particular routines for details.        ***)
(****************************************************************************)

PROCEDURE initialization;
BEGIN
  initialize_game_time;
  world_file_name:='WORLD.DAT';
  world_name:='NEW EDEN';
  Randomize;
  new(world_picture);
  initialize_world_matrix;
  land_list_root:=NIL;
  initialize_surface_resource_matrix;
  initialize_game_time_increment;
  initialize_world_update_increment;
  initialize_block_start;
  initialize_human_resource_list;
  world_pending_list_root:=NIL;
  world_log_list_root:=NIL;
  clear_time(time_to_next_update);
  trader_in_orbit:=false;
  trader_called:=false;
  trader_resource_tree_root:=NIL;
  new_planet:=true;
  base_block_x:=-1;
  base_block_y:=-1;
  current_debt_limit:=initial_debt_limit;
  colony_financial_status:=0;
END;

(****************************************************************************)
(*** MAKEWRLD - MAINLINE CODE                                             ***)
(****************************************************************************)

BEGIN
  initialization;
  read_resource_file;

  setup_world_map_graphics;
  show_world_map_grid;
  determine_temperate_zone;
  do_land_masses;
  save_world_picture;
  Randomize;
  make_base_hydro_and_temp;
  make_altitudes;

  do_resource_allocation;
  save_world;

  ASSIGN(main_program,'STARFALL.COM');
  EXECUTE(main_program);
END.
