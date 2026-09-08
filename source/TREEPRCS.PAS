{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TREEPRCS.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : All of the following routines have to do with        ***)
(***                 resource trees, in one way or another.
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

FUNCTION create_a_new_resource:resource_ptr;
VAR
  temp_ptr : resource_ptr;
BEGIN
  new(temp_ptr);
  WITH temp_ptr^ DO
    BEGIN
      next:=NIL;
      prev:=NIL;
      parent:=NIL;
      child:=NIL;
      resource_num:=0;
      quantity:=0.0;
      flags:=0;
      set_resource_flag_found(flags,false);
      set_resource_flag_extracted(flags,true);
      set_resource_flag_selected(flags,false);
    END;
  create_a_new_resource:=temp_ptr;
END;

FUNCTION ptr_at_end_of_tree(resource : resource_ptr):boolean;
VAR
  temp_ptr : resource_ptr;
BEGIN
  ptr_at_end_of_tree:=true;
  temp_ptr:=resource;
  WHILE temp_ptr^.parent<>NIL DO
    BEGIN
      temp_ptr:=temp_ptr^.parent;
      IF temp_ptr^.next<>NIL
        THEN
          ptr_at_end_of_tree:=false;
    END;
END;

PROCEDURE step_resource_ptr(VAR resource:resource_ptr);
VAR
  exit_flag : boolean;
BEGIN
  IF resource^.child<>NIL
    THEN
      resource:=resource^.child
    ELSE
      IF resource^.next<>NIL
        THEN
          resource:=resource^.next
        ELSE
          BEGIN
            IF NOT ptr_at_end_of_tree(resource)
              THEN
                BEGIN
                  exit_flag:=false;
                  WHILE (resource^.parent<>NIL)
                        AND (NOT exit_flag) DO
                    BEGIN
                      IF resource^.parent^.next<>NIL
                        THEN
                          BEGIN
                            exit_flag:=true;
                            resource:=resource^.parent^.next;
                          END
                        ELSE
                          resource:=resource^.parent;
                END;
            END;
          END;
END;

PROCEDURE incr_window_ptr(VAR resource    : resource_ptr;
                          VAR window      : resource_ptr;
                          VAR window_line : integer;
                          min_y,max_y     : integer);

VAR
  temp_ptr:resource_ptr;
BEGIN
  temp_ptr:=resource;
  step_resource_ptr(resource);
  IF temp_ptr<>resource
    THEN
      IF window_line>(max_y-min_y)
        THEN
          step_resource_ptr(window);
END;

PROCEDURE unstep_resource_ptr(VAR resource : resource_ptr);
VAR
  temp_ptr : resource_ptr;
  save_ptr : resource_ptr;
BEGIN
  IF resource^.prev<>NIL
    THEN
      BEGIN
        resource:=resource^.prev;
        IF resource^.child<>NIL
          THEN
            BEGIN
              temp_ptr:=resource^.child;
              REPEAT
                save_ptr:=temp_ptr;
                step_resource_ptr(temp_ptr);
              UNTIL temp_ptr=resource^.next;
              resource:=save_ptr;
            END;
      END
    ELSE
      IF resource^.parent<>NIL
        THEN
          resource:=resource^.parent;
END;

PROCEDURE decr_window_ptr(VAR resource    : resource_ptr;
                          VAR window      : resource_ptr;
                          VAR window_line : integer);
VAR
  temp_resource_ptr: resource_ptr;
BEGIN
  temp_resource_ptr:=resource;
  unstep_resource_ptr(resource);
  IF (temp_resource_ptr<>resource)
    THEN
      IF window_line<=1
        THEN
          unstep_resource_ptr(window);
END;

FUNCTION level_of_resource(resource:resource_ptr):integer;
VAR
  temp:integer;
BEGIN
  temp:=1;
  WHILE resource^.parent<>NIL DO
    BEGIN
      resource:=resource^.parent;
      temp:=succ(temp);
    END;
  level_of_resource:=temp;
END;

PROCEDURE update_resource_window_aux(window_ptr    : resource_ptr);
VAR
  loop : integer;
  inner_loop : integer;
  current_y : integer;
  save_ptr : resource_ptr;
BEGIN
  current_resource_window_line:=-1; (* signal that, as of now, it is not on the current window *)
  current_y:=1;
  save_ptr:=NIL;
  WHILE ((current_y<=(max_resource_window_y-min_resource_window_y+1))
     AND (window_ptr<>save_ptr)) DO
    BEGIN
      save_ptr:=window_ptr;
      WITH window_ptr^ DO
        BEGIN
          IF window_ptr=current_resource_window_item
            THEN
              BEGIN
                TextColor(resource_window_cursor_color);
                gotoxy(1,current_y);
                write('->');
                gotoxy(50,current_y);
                write('<-');
                current_resource_window_line:=current_y;
              END;

          IF value_of_resource_flag_selected(flags)
            THEN
              TextColor(resource_window_data_selected_color)
            ELSE
              TextColor(resource_window_data_normal_color);

          gotoxy(1+level_of_resource(window_ptr)*2,current_y);
          write(resources[resource_num].resource_name);

          gotoxy(54,current_y);
          write(quantity:11:2,' ',resources[resource_num].resource_units);

          IF NOT (value_of_resource_flag_extracted(flags))
            THEN
              BEGIN
                gotoxy(75,current_y);
                write('U');
              END;

          IF NOT (value_of_resource_flag_found(flags))
            THEN
              BEGIN
                gotoxy(76,current_y);
                write('N');
              END;

          current_y:=succ(current_y);
          step_resource_ptr(window_ptr);
        END;
    END;
END;

PROCEDURE update_resource_window;
BEGIN
  TextColor(resource_window_data_normal_color);
  Window(2,min_resource_window_y,
         78,max_resource_window_y);
  ClrScr;
  update_resource_window_aux(current_resource_window_ptr);
  Window(1,1,80,25);
END;

FUNCTION amount_of_resource_in_tree(resource_num : byte;
                                    root         : resource_ptr):real;
VAR
  root_amount : real;
BEGIN
  IF root=NIL
    THEN
      amount_of_resource_in_tree:=0.0
    ELSE
      BEGIN
        root_amount:=0.0;
        IF resource_num=root^.resource_num
          THEN
            IF (value_of_resource_flag_found(root^.flags)=true) AND
               (value_of_resource_flag_extracted(root^.flags)=true)
              THEN
                root_amount:=root^.quantity;
        amount_of_resource_in_tree:=
          root_amount
          + amount_of_resource_in_tree(resource_num,root^.child)
          + amount_of_resource_in_tree(resource_num,root^.next);
      END;
END;

FUNCTION amount_of_resource_in_top_level_of_tree(resource_num : byte;
                                                 first        : resource_ptr):real;
VAR
  temp_amount:real;
BEGIN
  temp_amount:=0.0;
  WHILE first<>NIL DO
    BEGIN
      IF first^.resource_num=resource_num
        THEN
          IF (value_of_resource_flag_found(first^.flags)=true) AND
             (value_of_resource_flag_extracted(first^.flags)=true)
            THEN
              temp_amount:=temp_amount+first^.quantity;
      first:=first^.next;
    END;
  amount_of_resource_in_top_level_of_tree:=temp_amount;
END;

FUNCTION amount_of_unlinked_resource_in_top_level_of_tree(resource_num : byte;
                                                          first        : resource_ptr):real;
VAR
  temp_amount:real;
BEGIN
  temp_amount:=0.0;
  WHILE first<>NIL DO
    BEGIN
      IF first^.resource_num=resource_num
        THEN
          IF (value_of_resource_flag_found(first^.flags)=true) AND
             (value_of_resource_flag_extracted(first^.flags)=true) AND
             (first^.child=NIL)
            THEN
              temp_amount:=temp_amount+first^.quantity;
      first:=first^.next;
    END;
  amount_of_unlinked_resource_in_top_level_of_tree:=temp_amount;
END;

FUNCTION Human_resources_in_tree(root : resource_ptr):boolean;
BEGIN
  IF root=NIL
    THEN
      Human_resources_in_tree:=false
    ELSE
      IF (NOT resources[root^.resource_num].naturally_occuring) OR
         ((resources[root^.resource_num].extractable) AND
          ((Value_of_resource_flag_found(root^.flags)=true) OR
           (Value_of_resource_flag_extracted(root^.flags)=true)))
        THEN
          Human_resources_in_tree:=true
        ELSE
          Human_resources_in_tree:=Human_resources_in_tree(root^.child)
                                OR Human_resources_in_tree(root^.next);
END;

FUNCTION nonmoving_item_in_pending_list(x,y:integer):boolean;
VAR
  temp_ptr : pending_ptr;
  temp_val : boolean;
BEGIN
  temp_val:=false;
  temp_ptr:=world_pending_list_root;
  WHILE (temp_ptr<>NIL) AND (NOT temp_val) DO
    BEGIN
      IF (temp_ptr^.action_type<>transportation_action)
        THEN
          IF (temp_ptr^.x=x) AND
             (temp_ptr^.y=y)
            THEN
              temp_val:=true;
      temp_ptr:=temp_ptr^.next;
    END;
  nonmoving_item_in_pending_list:=temp_val;
END;

FUNCTION human_resources_at(x,y:integer):boolean;
BEGIN
  human_resources_at:=human_resources_in_tree(world_matrix[x]^[y]^.resources) OR
                      nonmoving_item_in_pending_list(x,y);
END;

FUNCTION surface_resources_in_tree(root : resource_ptr):boolean;
BEGIN
  IF root=NIL
    THEN
      surface_resources_in_tree:=false
    ELSE
      IF (NOT resources[root^.resource_num].subsurface_resource) AND
         (resources[root^.resource_num].naturally_occuring)
        THEN
          surface_resources_in_tree:=true
        ELSE
          surface_resources_in_tree:=surface_resources_in_tree(root^.child)
                                  OR surface_resources_in_tree(root^.next);
END;

FUNCTION surface_resources_at(x,y:integer):boolean;
BEGIN
  surface_resources_at:=surface_resources_in_tree(world_matrix[x]^[y]^.resources);
END;

PROCEDURE decompose_resource( source           : resource_ptr;
                              num_to_decompose : real);
VAR
  temp_ptr:resource_ptr;
BEGIN
  IF num_to_decompose<source^.quantity
    THEN
      BEGIN
        temp_ptr:=create_a_new_resource;
        temp_ptr^.resource_num:=source^.resource_num;
        temp_ptr^.quantity:=num_to_decompose;
        source^.quantity:=source^.quantity-num_to_decompose;
        temp_ptr^.flags:=source^.flags;
        temp_ptr^.prev:=source;
        temp_ptr^.next:=source^.next;
        temp_ptr^.parent:=source^.parent;
        IF source^.next<>NIL
          THEN
            source^.next^.prev:=temp_ptr;
        source^.next:=temp_ptr;
      END;
END;

PROCEDURE swap_resources(first  : resource_ptr;
                         second : resource_ptr);
BEGIN
  IF (first<>NIL) AND (second<>NIL)
    THEN
      BEGIN
        IF first^.prev=NIL
          THEN
            first^.parent^.child:=second;
        IF second^.prev=NIL
          THEN
            second^.parent^.child:=first;
        second^.prev:=first^.prev;
        first^.next:=second^.next;
        IF first^.prev<>NIL
          THEN
            first^.prev^.next:=second;
        IF second^.next<>NIL
          THEN
            second^.next^.prev:=first;
        second^.next:=first;
        first^.prev:=second;
      END;
END;

PROCEDURE unlink_from_siblings(resource : resource_ptr);
BEGIN
  IF resource<>NIL
    THEN
      BEGIN
        IF resource^.next<>NIL
          THEN
            resource^.next^.prev:=resource^.prev;
        IF resource^.prev<>NIL
          THEN
            resource^.prev^.next:=resource^.next
          ELSE
            BEGIN
              IF resource^.parent=NIL
                THEN
                  world_matrix[current_block_x]^[current_block_y]^.resources:=
                    resource^.next
                ELSE
                  resource^.parent^.child:=resource^.next;
            END;
      END;
END;

PROCEDURE add_resource_to_tree(VAR tree     : resource_ptr;
                               resource     : resource_ptr);
VAR
  save_ptr:resource_ptr;
BEGIN
  IF tree=NIL  (* this means we are just starting a tree *)
    THEN
      BEGIN
        tree:=resource;
        resource^.next:=NIL;
        resource^.prev:=NIL;
        resource^.parent:=NIL;
      END
    ELSE
      BEGIN
        resource^.parent:=tree;
        resource^.next:=NIL;
        IF tree^.child=NIL
          THEN
            BEGIN
              tree^.child:=resource;
              resource^.prev:=NIL;
            END
          ELSE
            BEGIN
              save_ptr:=tree^.child;
              WHILE save_ptr^.next<>NIL DO
                save_ptr:=save_ptr^.next;
              (* Now that we have stepped to far right, add resource *)
              resource^.prev:=save_ptr;
              save_ptr^.next:=resource;
            END;
      END;
END;

PROCEDURE add_resource_to_top_level_of_tree(VAR tree   : resource_ptr;
                                            resource   : resource_ptr);
VAR
  temp_ptr:resource_ptr;
BEGIN
  IF tree=NIL  (* this means we are just starting a tree *)
    THEN
      BEGIN
        tree:=resource;
        resource^.next:=NIL;
        resource^.prev:=NIL;
        resource^.parent:=NIL;
      END
    ELSE
      BEGIN
        resource^.prev:=NIL;
        resource^.next:=tree;
        tree^.prev:=resource;
        resource^.parent:=tree^.parent;
        tree:=resource;
      END;
END;

PROCEDURE merge_list_into_tree(VAR list      : resource_ptr;
                               VAR tree      : resource_ptr;
                               x,y           : integer);
VAR
  save_ptr  : resource_ptr;
  change_it : boolean;
BEGIN
  change_it:=false;
  IF (current_resource_window_ptr=tree) AND
     (mode=block_text) AND
     (block_text_mode<>block_resource_window_mode)
    THEN
      change_it:=true;
  WHILE list<>NIL DO
    BEGIN
      save_ptr:=list^.next;
      add_resource_to_top_level_of_tree(tree,list);
      list:=save_ptr;
    END;
  IF change_it
    THEN
      BEGIN
        current_resource_window_ptr:=tree;
        current_resource_window_item:=tree;
      END;
END;

PROCEDURE demote_sibling_to_child(VAR new_parent : resource_ptr;
                                  VAR new_child  : resource_ptr);
BEGIN
  unlink_from_siblings(new_child);
  add_resource_to_tree(new_parent,new_child);
END;

PROCEDURE advance_child_to_sibling(VAR parent,child:resource_ptr);
BEGIN
  IF parent^.child=child
    THEN
      parent^.child:=child^.next;
  unlink_from_siblings(child);
  child^.prev:=parent;
  child^.next:=parent^.next;
  IF parent^.next<>NIL
    THEN
      parent^.next^.prev:=child;
  parent^.next:=child;
  child^.parent:=parent^.parent;
END;

PROCEDURE delete_resource(resource:resource_ptr);
BEGIN
  WHILE resource^.child<>NIL DO
    BEGIN
      advance_child_to_sibling(resource,resource^.child);
    END;

  unlink_from_siblings(resource);
  dispose(resource);
END;

PROCEDURE compress_resources(VAR primary, secondary : resource_ptr);
BEGIN
  IF (primary^.resource_num=secondary^.resource_num)  AND
     (value_of_resource_flag_found(primary^.flags)=
      value_of_resource_flag_found(secondary^.flags)) AND
     (value_of_resource_flag_extracted(primary^.flags)=
      value_of_resource_flag_extracted(secondary^.flags))
    THEN
      BEGIN
        primary^.quantity:=primary^.quantity+secondary^.quantity;
        secondary^.quantity:=0;
        delete_resource(secondary);
      END;
END;

PROCEDURE delete_resource_tree(root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        delete_resource_tree(root^.child);
        delete_resource_tree(root^.next);
        delete_resource(root);
      END;
END;

PROCEDURE delete_resource_tree_plus_root(VAR root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        delete_resource_tree(root^.child);
        delete_resource(root);
        root:=NIL;
      END;
END;

FUNCTION delete_some_resource_from_top_level_of_tree(resource_num : byte;
                                                     amount       : real;
                                                     first        : resource_ptr):real;
VAR
  save_ptr : resource_ptr;
BEGIN
  WHILE (amount>0.0) AND (first<>NIL) DO
    BEGIN
      save_ptr:=first^.next;
      IF first^.resource_num=resource_num
        THEN
          BEGIN
            IF amount>=first^.quantity
              THEN
                BEGIN
                  amount:=amount-first^.quantity;
                  delete_resource(first);
                END
              ELSE
                BEGIN
                  first^.quantity:=first^.quantity-amount;
                  amount:=0.0;
                END;
          END;
      first:=save_ptr;
    END;
  delete_some_resource_from_top_level_of_tree:=amount;
END;

PROCEDURE use_some_resource_from_top_level_of_tree(resource_num : byte;
                                                   amount       : real;
                                                   first        : resource_ptr);
VAR
  killed_amount : real;
BEGIN
  IF resources[resource_num].expendable
    THEN
      killed_amount:=delete_some_resource_from_top_level_of_tree(resource_num,
                                                                 amount,
                                                                 first);
END;

FUNCTION delete_some_resource_aux(VAR resource_num : byte;
                                  amount           : real;
                                  tree             : resource_ptr):real;
BEGIN
  IF (tree<>NIL) AND (amount>0.0)
    THEN
      BEGIN
        IF tree^.resource_num=resource_num
          THEN
            BEGIN
              IF amount>=tree^.quantity
                THEN
                  BEGIN
                    amount:=amount-tree^.quantity;
                    delete_resource(tree);
                  END
                ELSE
                  BEGIN
                    tree^.quantity:=tree^.quantity-amount;
                    amount:=0.0;
                  END;
            END;
        IF amount>0.0
          THEN
            amount:=amount-
              delete_some_resource_aux(resource_num,amount,tree^.next);
        IF amount>0.0
          THEN
            amount:=amount-
              delete_some_resource_aux(resource_num,amount,tree^.child);
      END;
  delete_some_resource_aux:=amount;
END;

PROCEDURE delete_some_resource_from_tree(resource_num   : byte;
                                         amount         : real;
                                         tree           : resource_ptr);
VAR
  trash_result:real;
BEGIN
  trash_result:=delete_some_resource_aux(resource_num,amount,tree);
  IF trash_result<>0.0
    THEN
      BEGIN
        writeln('We couldnt find enough of those things at the base to delete');
        writeln('them all.  You should tell Mark to fix that, OK?');
        REPEAT
        UNTIL KeyPressed;
      END;
END;

PROCEDURE select_tree(root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        set_resource_flag_selected(root^.flags,true);
        select_tree(root^.child);
        select_tree(root^.next);
      END;
END;

PROCEDURE select_tree_plus_root(root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        set_resource_flag_selected(root^.flags,true);
        select_tree(root^.child);
      END;
END;

PROCEDURE unselect_tree(root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        set_resource_flag_selected(root^.flags,false);
        unselect_tree(root^.child);
        unselect_tree(root^.next);
      END;
END;

PROCEDURE unselect_tree_plus_root(root:resource_ptr);
BEGIN
  IF root<>NIL
    THEN
      BEGIN
        set_resource_flag_selected(root^.flags,false);
        unselect_tree(root^.child);
      END;
END;

FUNCTION make_selection_tree_from(first : resource_ptr):resource_ptr;
(* This procedure only takes out selected items on the top level *)
VAR
  temp_ptr : resource_ptr;
  save_ptr : resource_ptr;
BEGIN
  temp_ptr:=NIL;
  WHILE first<>NIL DO
    BEGIN
      save_ptr:=first^.next;
      IF value_of_resource_flag_selected(first^.flags)=true
        THEN
          BEGIN
            unlink_from_siblings(first);
            add_resource_to_top_level_of_tree(temp_ptr,first);
          END;
      first:=save_ptr;
    END;
  make_selection_tree_from:=temp_ptr;
END;