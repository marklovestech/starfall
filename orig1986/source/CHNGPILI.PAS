{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : CHNGPILI.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : This procedure brings in a pending item and does     ***)
(***                 the necessary machinations to make it into a log     ***)
(***                 item.                                                ***)
(*** Input         : pending_item comes in                                ***)
(*** Output        : None, but log item is added to log list              ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

PROCEDURE change_pending_item_to_log_item(pending_item : pending_ptr);
VAR
  new_log_item : log_ptr;
BEGIN
  IF pending_item<>NIL
    THEN
      BEGIN
        new_log_item:=create_a_new_log_item;
        new_log_item^.x:=pending_item^.x;
        new_log_item^.y:=pending_item^.y;
        new_log_item^.action_desc:=text_for_action_type(pending_item^.action_type);
        new_log_item^.completion_time:=game_time;

       add_to_log_list(new_log_item);
       delete_from_pending_list(pending_item);
     END;
END;
