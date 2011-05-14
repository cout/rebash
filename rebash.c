#include <readline/readline.h>
#include <stdio.h>
#include <ruby.h>

void rebash_display(void)
{
  RUBY_INIT_STACK;

  VALUE prompt = rb_str_new2(rl_display_prompt);
  VALUE line = rb_str_new(rl_line_buffer, rl_end);
  VALUE args[] = { prompt, line };

  /* TODO: there appear to be some control characters in the prompt */
  /* rl_expand_prompt(rl_display_prompt); */

  /* TODO: catch exceptions */
  rb_funcall2(rb_cObject, rb_intern("redisplay"), 2, args);
}

void load_rebash(void)
{
  char buf[PATH_MAX];
  VALUE rebash_rb;

  getcwd(buf, sizeof(buf));
  rebash_rb = rb_str_new2(buf);
  rb_str_cat2(rebash_rb, "/rebash.rb");

  rb_load(rebash_rb, 0);
}

void __attribute__ ((constructor)) rebash_init(void)
{
  RUBY_INIT_STACK;

  ruby_init();

  load_rebash();

  rl_redisplay_function = rebash_display;
}

