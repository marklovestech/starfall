{&P}
(****************************************************************************)
(***                       STARFALL VERSION 1.0            April 21, 1986 ***)
(***----------------------------------------------------------------------***)
(*** Module Name   : TRNSPRIM.PAS                                         ***)
(*** Author        : Mark Porter                                          ***)
(*** Original Rel. : April 21, 1986 (Version 1.0)                         ***)
(*** Updates       :                                                      ***)
(*** Module Desc   : These are the primitive routines for transportation  ***)
(*** Input         : See particular subprogram                            ***)
(*** Output        : See particular subprogram                            ***)
(*** Special Notes :                                                      ***)
(****************************************************************************)

(****************************************************************************)
(*** AMOUNT OF WEIGHT IN TREE : Just like it sounds, this function goes   ***)
(*** down a tree and adds up all of the weight that is found there.       ***)
(****************************************************************************)

OVERLAY FUNCTION amount_of_weight_in_tree(root        : resource_ptr):real;

  FUNCTION amount_of_weight_in_tree_aux(root : resource_ptr):real;
  BEGIN
    IF root=NIL
      THEN
        amount_of_weight_in_tree_aux:=0.0
      ELSE
        amount_of_weight_in_tree_aux:=resources[root^.resource_num].empty_weight*
                                      root^.quantity+
                                      amount_of_weight_in_tree_aux(root^.child)+
                                      amount_of_weight_in_tree_aux(root^.next);
  END;

BEGIN
  amount_of_weight_in_tree:=amount_of_weight_in_tree_aux(root^.child);
END;

(****************************************************************************)
(*** ADD ITEM TO TRANSPORTATION LIST : When entering a transportation     ***)
(*** path, every time a key is pressed, that square is added to the       ***)
(*** current transportation list.  That is what this procedure does.      ***)
(****************************************************************************)

OVERLAY PROCEDURE add_item_to_transportation_list(old_x,old_y,new_x,new_y:integer);

VAR
  new_one : transportation_list_ptr;
  done    : boolean;

BEGIN
  done:=false;
  IF current_transportation_pending^.transportation_list<>NIL
    THEN
      IF (current_transportation_ptr=
          current_transportation_pending^.transportation_list^.next)
    THEN
      IF (new_x=current_transportation_pending^.x) AND
         (new_y=current_transportation_pending^.y)
        THEN
          BEGIN
            current_transportation_blocks:=0;
            current_transportation_pending^.distance:=0.0;
            dispose(current_transportation_ptr);
            current_transportation_pending^.transportation_list^.next:=NIL;
            current_transportation_ptr:=current_transportation_pending^.transportation_list;
            done:=true;
          END;

  IF NOT done
     THEN
      IF (current_transportation_ptr<>NIL)
        THEN
          IF (current_transportation_ptr^.prev<>NIL)
            THEN
              IF (new_x=current_transportation_ptr^.prev^.x) AND
                 (new_y=current_transportation_ptr^.prev^.y)
                THEN   (* they are doing a retrace to last position *)
                  BEGIN
                    current_transportation_blocks:=pred(current_transportation_blocks);
                    current_transportation_pending^.distance:=current_transportation_pending^.distance-
                       distance_between(old_x,old_y,new_x,new_y);
                    current_transportation_ptr:=current_transportation_ptr^.prev;
                    dispose(current_transportation_ptr^.next);
                    current_transportation_ptr^.next:=NIL;
                    done:=true;
                  END;

  IF NOT done
    THEN
      BEGIN
        new_one:=create_a_new_transportation_list_item;
        new_one^.x:=new_x;
        new_one^.y:=new_y;
        new_one^.prev:=current_transportation_ptr;
        current_transportation_blocks:=succ(current_transportation_blocks);
        new_one^.distance:=distance_between(old_x,old_y,new_x,new_y);
        current_transportation_pending^.distance:=current_transportation_pending^.distance
                                                 +new_one^.distance;
        new_one^.prev^.next:=new_one;
        current_transportation_ptr:=new_one;
      END;

  IF mode=transportation_zoom_map
    THEN
      draw_transportation_zoom_map_info;
END;

(****************************************************************************)
(*** MOVABLE TREE : This is a recursive function (aren't they all?) which ***)
(*** seeks out any non-mobile items in a tree and will not let you select ***)
(*** this tree for transportation if this is true.                        ***)
(****************************************************************************)

OVERLAY FUNCTION movable_tree(root : resource_ptr):boolean;

  FUNCTION movable_tree_aux(root : resource_ptr):boolean;
  BEGIN
    IF root=NIL
      THEN
        movable_tree_aux:=true
      ELSE
        movable_tree_aux:=resources[root^.resource_num].movable AND
                          movable_tree_aux(root^.child) AND
                          movable_tree_aux(root^.next);
  END;

BEGIN
  movable_tree:=resources[root^.resource_num].movable AND movable_tree_aux(root^.child);
END;

