OVERLAY PROCEDURE Show_block_pending_list;
BEGIN
  TextColor(Block_mode_explanation_color);
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  writeln('PENDING LIST  ');
  activate_block_pending_window;
  edit_block_pending_window;
  deactivate_block_pending_window;
  gotoxy(block_mode_explanation_x,block_mode_explanation_y);
  write('             ');
END;
