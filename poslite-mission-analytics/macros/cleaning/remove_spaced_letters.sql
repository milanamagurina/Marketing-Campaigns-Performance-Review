{% macro remove_spaced_letters(expr) -%}
{{ return(adapter.dispatch('remove_spaced_letters', 'poslite_mission_analytics')(expr)) }}
{%- endmacro %}

{% macro poslite_mission_analytics__remove_spaced_letters(expr) -%}
regexp_replace(
  {{ expr }},
  '(?<=\\b\\p{L})\\s+(?=\\p{L}\\b)',
  ''
)
{%- endmacro %}



{% macro poslite_mission_analytics__remove_spaced_letters_redshift(expr) -%}
{%- set x = expr -%}
{%- for i in range(0, 12) -%}
  {%- set x -%}
  regexp_replace({{ x }}, '(\\m[[:alpha:]])\\s+([[:alpha:]]\\M)', '\\1\\2')
  {%- endset -%}
{%- endfor -%}
{{ x }}
{%- endmacro %}