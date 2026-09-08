
PROCEDURE next_active_land_item(VAR current_x,current_y:integer);
  BEGIN
    REPEAT
      next_land_item(current_x,current_y);
    UNTIL human_resources_at(current_x,current_y);
  END;

PROCEDURE prev_active_land_item(VAR current_x,current_y:integer);
  BEGIN
    REPEAT
      prev_land_item(current_x,current_y);
    UNTIL human_resources_at(current_x,current_y);
  END;
