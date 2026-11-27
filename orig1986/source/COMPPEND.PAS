{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : COMPPEND.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These procedures are called whenever a pending item  ***)
(***                 finishes and things need to be done to it.           ***)
(*** Input         : pending item and the amount done on it.              ***)
(*** Output        : None, but many side effects around system lists.     ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

OVERLAY PROCEDURE finish_exploration_pending_item(item         : pending_ptr;
                                                  amount_done  : real);
VAR
  current_equipment    : resource_ptr;
  current_resource     : resource_ptr;
  test_loop            : integer;
  chance               : integer;
BEGIN
  current_equipment:=item^.resources_involved;
  WHILE current_equipment<>NIL DO
    BEGIN
      current_resource:=world_matrix[item^.x]^[item^.y]^.resources;
      (* note that, although we are actually searching a binary tree, *)
      (* it is a given that any items that are not found yet by the   *)
      (* user will be on the top level of the tree.  Because of this  *)
      (* unique realization, we may process the block resource tree   *)
      (* as if it were a simple linear linked list.                   *)
      WHILE current_resource<>NIL DO
        BEGIN
          IF (value_of_resource_flag_extracted(current_resource^.flags)=false) AND
             (value_of_resource_flag_found(current_resource^.flags)=false)
            THEN
              FOR test_loop:=1 to 4 DO
                BEGIN
                  chance:=trunc((amount_done/100)
                    *(resources[current_resource^.resource_num].exploratory_test_effectiveness[test_loop]/100)
                    *resources[current_equipment^.resource_num].exploratory_test_effectiveness[test_loop]);
                  IF random(100)<=chance
                    THEN
                      set_resource_flag_found(current_resource^.flags,true);
                END;
          current_resource:=current_resource^.next;
        END;
      current_equipment:=current_equipment^.next;
    END;

  merge_list_into_tree(item^.resources_involved,world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);
  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_extraction_pending_item(item          : pending_ptr;
                                                 amount_done   : real);
VAR
  current_mineral   : resource_ptr;
  new_mineral       : resource_ptr;
  save_ptr          : resource_ptr;
  current_equipment : resource_ptr;
BEGIN
  current_mineral:=item^.objects_involved;
  WHILE current_mineral<>NIL DO
    BEGIN
      save_ptr:=current_mineral^.next;
      IF amount_done=100.0
        THEN
          BEGIN
            set_resource_flag_extracted(current_mineral^.flags,true);
          END
        ELSE
          BEGIN
            IF NOT value_of_resource_flag_extracted(current_mineral^.flags)
              THEN
                BEGIN
                  new_mineral:=create_a_new_resource;
                  set_resource_flag_extracted(new_mineral^.flags,true);
                  set_resource_flag_found(new_mineral^.flags,true);
                  new_mineral^.resource_num:=current_mineral^.resource_num;
                  new_mineral^.quantity:=(amount_done/100.0)*(current_mineral^.quantity);
                  current_mineral^.quantity:=current_mineral^.quantity-new_mineral^.quantity;
                  add_resource_to_top_level_of_tree(new_mineral,item^.objects_involved);
                END;
          END;
      current_mineral:=save_ptr;
    END;


  merge_list_into_tree(item^.resources_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  merge_list_into_tree(item^.objects_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_development_pending_item(item         : pending_ptr;
                                                  amount_done  : real);
VAR
  surface_resources : resource_ptr;
  new_resource      : resource_ptr;
  save_ptr          : resource_ptr;
  current_equipment : resource_ptr;
BEGIN
  surface_resources:=item^.objects_involved;
  WHILE surface_resources<>NIL DO
    BEGIN
      save_ptr:=surface_resources^.next;
      IF amount_done=100.0
        THEN
          BEGIN
            surface_resources^.quantity:=surface_resources^.quantity*
              (resources[surface_resources^.resource_num].typical_purity);
            surface_resources^.resource_num:=resources[surface_resources^.resource_num].development_result;
          END
        ELSE
          BEGIN
            IF resources[surface_resources^.resource_num].developable
              THEN
                BEGIN
                  new_resource:=create_a_new_resource;
                  set_resource_flag_extracted(new_resource^.flags,true);
                  set_resource_flag_found(new_resource^.flags,true);
                  new_resource^.resource_num:=resources[surface_resources^.resource_num].development_result;
                  new_resource^.quantity:=(amount_done/100.0)*(surface_resources^.quantity)
                    *(resources[surface_resources^.resource_num].typical_purity);
                  surface_resources^.quantity:=((100.0-amount_done)/100)*surface_resources^.quantity;
                  add_resource_to_top_level_of_tree(new_resource,item^.objects_involved);
                END;
          END;
      surface_resources:=save_ptr;
    END;

  merge_list_into_tree(item^.resources_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  merge_list_into_tree(item^.objects_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_refinement_pending_item(item          : pending_ptr;
                                                 amount_done   : real);
VAR
  current_mineral : resource_ptr;
  new_resource      : resource_ptr;
  save_ptr          : resource_ptr;
  current_equipment : resource_ptr;
  new_log_item      : log_ptr;
BEGIN
  current_mineral:=item^.objects_involved;
  WHILE current_mineral<>NIL DO
    BEGIN
      save_ptr:=current_mineral^.next;
      IF amount_done=100.0
        THEN
          BEGIN
            current_mineral^.quantity:=current_mineral^.quantity*
              (resources[current_mineral^.resource_num].typical_purity);
            current_mineral^.resource_num:=resources[current_mineral^.resource_num].refinement_result;
          END
        ELSE
          BEGIN
            IF resources[current_mineral^.resource_num].refineable
              THEN
                BEGIN
                  new_resource:=create_a_new_resource;
                  set_resource_flag_extracted(new_resource^.flags,true);
                  set_resource_flag_found(new_resource^.flags,true);
                  new_resource^.resource_num:=resources[current_mineral^.resource_num].refinement_result;
                  new_resource^.quantity:=(amount_done/100.0)*(current_mineral^.quantity)
                    *(resources[current_mineral^.resource_num].typical_purity);
                  current_mineral^.quantity:=((100.0-amount_done)/100)*current_mineral^.quantity;
                  add_resource_to_top_level_of_tree(new_resource,item^.objects_involved);
                END;
          END;
      current_mineral:=save_ptr;
    END;

  merge_list_into_tree(item^.resources_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  merge_list_into_tree(item^.objects_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);

  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_production_pending_item(item          : pending_ptr;
                                                 amount_done   : real);
VAR
  current_resource : resource_ptr;
  save_resource    : resource_ptr;
  number_made      : real;
  amount_used      : real;

FUNCTION amount_of_resource_needed(current : resource_ptr):real;
(* This function looks through the production requirements for the current *)
(* item, looking for the resource in question.  When it finds, it, it sees *)
(* if it's amount is less than or equal to the amount we have on hand.     *)
(* If this is true, then we now know just how much to delete from the stupid *)
(* resource, and we pass this back.  Note that if we do not find this resource, *)
(* we pass back a 0.0                                                           *)
VAR
  temp_needed  : real;
  current_level : ingredient_ptr;
  current_alternative : ingredient_ptr;
  done:boolean;
BEGIN
  temp_needed:=0.0;
  done:=false;
  current_level:=resources[item^.objects_involved^.resource_num].production_requirements;
  WHILE (current_level<>NIL) AND (NOT done) DO
    BEGIN
      current_alternative:=current_level;
      REPEAT
        IF (current_alternative^.resource_num=current^.resource_num) AND
           (current_alternative^.quantity<=current^.quantity)
          THEN
            BEGIN
              done:=true;
              temp_needed:=current_alternative^.quantity;
            END;
        IF NOT done
          THEN
            current_alternative:=current_alternative^.alternatives;
      UNTIL (done) OR (current_alternative=NIL);
      IF NOT done
        THEN
          current_level:=current_level^.next;
    END;

  amount_of_resource_needed:=temp_needed;
END;

BEGIN
  current_resource:=item^.resources_involved;
  WHILE current_resource<>NIL DO
    BEGIN
      save_resource:=current_resource^.next;
      amount_used:=amount_of_resource_needed(current_resource);
      IF amount_used<>0.0
        THEN
          use_some_resource_from_top_level_of_tree(current_resource^.resource_num,
                                               amount_used,
                                               current_resource);
      current_resource:=save_resource;
    END;

  number_made:=int(item^.objects_involved^.quantity*(amount_done/100.0));
  IF number_made>0
    THEN
      BEGIN
        item^.objects_involved^.quantity:=number_made;
        merge_list_into_tree(item^.objects_involved,
                             world_matrix[item^.x]^[item^.y]^.resources,
                             item^.x,item^.y);
      END;

  merge_list_into_tree(item^.resources_involved,
                       world_matrix[item^.x]^[item^.y]^.resources,
                       item^.x,item^.y);
  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_transportation_pending_item(item        : pending_ptr;
                                                     amount_done : real);
BEGIN
  merge_list_into_tree(item^.resources_involved,
                       world_matrix[item^.transportation_list^.x]^[item^.transportation_list^.y]^.resources,
                       item^.transportation_list^.x,
                       item^.transportation_list^.y);

  update_human_resource_list(item^.transportation_list^.x,
                             item^.transportation_list^.y);
  change_pending_item_to_log_item(item);
END;

OVERLAY PROCEDURE finish_trader_arriving_pending_item(item     : pending_ptr);
VAR
  temp_log                  : log_ptr;
  updates_until_depart      : integer;
  time_until_trader_departs : time_type;
  temp_time                 : time_type;
  temp_pending              : pending_ptr;
  loop                      : integer;

  FUNCTION normal_random_real(median : real):real;
  (* This function generates a random number distributed normally *)
  (* (approximately) around the 'median'. *)
  VAR
    loop            : integer;
    number_of_steps : integer;
    step_amount     : real;
    temp_val        : real;
  BEGIN
    temp_val:=0.0;
    step_amount:=median;
    number_of_steps:=2;

    REPEAT
      step_amount:=step_amount/2;
      number_of_steps:=succ(number_of_steps);
    UNTIL step_amount<32767.0;

    FOR loop:=1 to number_of_steps*2 DO
      temp_val:=temp_val+random(trunc(step_amount)+1);

    normal_random_real:=temp_val;
  END;

  FUNCTION generate_trader_resource_tree:resource_ptr;
  VAR
    loop                    : integer;
    tree                    : resource_ptr;
    current_item            : resource_ptr;
  BEGIN
    tree:=NIL;
    FOR loop:=1 TO max_resource DO
      BEGIN
        sound(50+loop);
        IF resources[loop].typical_trader_amount<>0
          THEN
            BEGIN
              current_item:=create_a_new_resource;
              set_resource_flag_extracted(current_item^.flags,true);
              set_resource_flag_found(current_item^.flags,true);
              current_item^.resource_num:=loop;
              current_item^.quantity:=0.0;
              IF resources[loop].typical_trader_amount>0.0
                THEN
                  BEGIN
                    current_item^.quantity
                      :=normal_random_real(resources[loop].typical_trader_amount);
                    IF (current_item^.quantity=0.0)
                       AND (random(3)<>0)
                      THEN
                        current_item^.quantity:=1.0;
                  END;
              add_resource_to_top_level_of_tree(tree,current_item);
            END;
      END;
    generate_trader_resource_tree:=tree;
    nosound;
  END;

BEGIN
  trader_arrives;

  updates_until_depart:=0;
  FOR loop:=1 to 10 DO
    updates_until_depart:=updates_until_depart+random(15)+3;

(* DEVELOPMENT CODE ONLY *)
   updates_until_depart:=updates_until_depart DIV 15;

  convert_updates_to_time(updates_until_depart,time_until_trader_departs);

  temp_pending:=create_a_new_pending_item;
  temp_pending^.x:=base_block_x;
  temp_pending^.y:=base_block_y;
  temp_pending^.action_type:=trader_leaving_action;

  temp_time:=game_time;
  add_times(temp_time,time_until_trader_departs);

  temp_pending^.estimated_completion_time:=temp_time;
  temp_pending^.updates_left:=updates_until_depart;

  add_to_pending_list(temp_pending);

  temp_log:=create_a_new_log_item;
  temp_log^.x:=base_block_x;
  temp_log^.y:=base_block_y;
  temp_log^.action_desc:='TRADER ARRIVED';
  temp_log^.completion_time:=game_time;

  add_to_log_list(temp_log);

  delete_from_pending_list(item);
  trader_resource_tree_root:=generate_trader_resource_tree;
END;

OVERLAY PROCEDURE finish_trader_leaving_pending_item(item      : pending_ptr);
VAR
  temp_log    : log_ptr;
  temp_ptr    : resource_ptr;
  save_ptr    : resource_ptr;
BEGIN
  trader_departs;
  temp_log:=create_a_new_log_item;
  temp_log^.x:=base_block_x;
  temp_log^.y:=base_block_y;
  temp_log^.action_desc:='TRADER LEFT';
  temp_log^.completion_time:=game_time;

  add_to_log_list(temp_log);
  delete_from_pending_list(item);

  temp_ptr:=trader_resource_tree_root;
  WHILE temp_ptr<>NIL DO
    BEGIN
      save_ptr:=temp_ptr^.next;
      dispose(temp_ptr);
      temp_ptr:=save_ptr;
    END;
  trader_resource_tree_root:=NIL;
END;