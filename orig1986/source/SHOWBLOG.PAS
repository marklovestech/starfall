
OVERLAY PROCEDURE Show_block_log_list;
BEGIN
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('LOG LIST      ');
  activate_block_log_window;
  edit_block_log_window;
  deactivate_block_log_window;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;
