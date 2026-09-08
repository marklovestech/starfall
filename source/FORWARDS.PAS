{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : FORWARDS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the necessary FORWARD declarations for     ***)
(***                 PLAYGAME.  Much as I hate them, there is sometimes   ***)
(***                 no choice in this matter, especially when working    ***)
(***                 with overlays.                                       ***)
(*** Input         : N/A                                                  ***)
(*** Output        : N/A                                                  ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE update_human_resource_list(x,y:integer);                      FORWARD;

PROCEDURE trader_arrives;                                               FORWARD;

PROCEDURE trader_departs;                                               FORWARD;

PROCEDURE display_help_screen(screen_name : string50);                  FORWARD;

PROCEDURE display_function_key_help_screen(key : char);                 FORWARD;

PROCEDURE process_realtime_events;                                      FORWARD;

PROCEDURE refresh_screen;                                               FORWARD;

PROCEDURE finish_pending_item(item        : pending_ptr;
                              amount_done : real);                      FORWARD;

PROCEDURE draw_base_block_on_zoom_map;                                  FORWARD;

PROCEDURE update_resource_window;                                       FORWARD;

PROCEDURE update_block_log_window;                                      FORWARD;

PROCEDURE update_block_pending_window;                                  FORWARD;

PROCEDURE update_world_inventory_window;                                FORWARD;

PROCEDURE update_world_pending_window;                                  FORWARD;

PROCEDURE update_world_log_window;                                      FORWARD;

PROCEDURE draw_resource_window_mode_header;                             FORWARD;

PROCEDURE draw_transportation_zoom_map_info;                            FORWARD;

FUNCTION create_a_new_transportation_list_item:transportation_list_ptr; FORWARD;