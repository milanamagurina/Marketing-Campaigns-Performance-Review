{% macro nullif_blank(expr) -%}
nullif(trim({{ expr }}), '')
{%- endmacro %}
