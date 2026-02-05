{% macro normalize_country(expr) -%}
upper(trim({{ expr }}))
{%- endmacro %}
