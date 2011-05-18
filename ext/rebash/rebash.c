#include <readline/readline.h>
#include <stdio.h>
#include <ruby.h>

VALUE rebash_call_ruby_redisplay(VALUE arg)
{
  VALUE prompt = rb_str_new2(rl_display_prompt);
  VALUE line = rb_str_new(rl_line_buffer, rl_end);
  VALUE args[] = { prompt, line };

  /* TODO: there appear to be some control characters in the prompt */
  /* rl_expand_prompt(rl_display_prompt); */

  rb_funcall2(rb_cObject, rb_intern("redisplay"), 2, args);
}

void rebash_display(void)
{
  RUBY_INIT_STACK;
  int state = 0;

  rb_protect(rebash_call_ruby_redisplay, Qnil, &state);

  if (state == 6)
  {
    VALUE str = rb_funcall(ruby_errinfo, rb_intern("to_s"), 0);
    char * p = StringValueCStr(str);
    FILE * fp = rl_outstream ? rl_outstream : stdout;
    fprintf(fp, "\r%s\n%s%s", p, rl_display_prompt, rl_line_buffer);
  }
}

VALUE load_rebash(VALUE arg)
{
  rb_require("rebash/rebash");
}

void __attribute__ ((constructor)) rebash_init(void)
{
  RUBY_INIT_STACK;
  char * argv[] = { "argv0", "-e", "" };
  int state = 0;

  ruby_init();
  ruby_options(2, argv);

  rb_protect(load_rebash, Qnil, &state);

  if (state != 0)
  {
    ruby_stop(state);
  }

  rl_redisplay_function = rebash_display;
}

