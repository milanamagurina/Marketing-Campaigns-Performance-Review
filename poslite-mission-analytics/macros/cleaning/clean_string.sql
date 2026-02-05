{% macro clean_string(col) %}


with base as (
    select lower(trim({{ col }})) as val
),


ws as (
    select regexp_replace(val, '\\s+', ' ') as val
    from base
),


fixed_terms as (
    select
        regexp_replace(
        regexp_replace(
        regexp_replace(
        regexp_replace(
        regexp_replace(
            val,
            'p\\s*r\\s*o\\s*s\\s*p\\s*e\\s*c\\s*t\\s*i\\s*n\\s*g', 'prospecting'
        ),
            's\\s*h\\s*o\\s*p\\s*p\\s*i\\s*n\\s*g', 'shopping'
        ),
            'l\\s*a\\s*n\\s*d\\s*i\\s*n\\s*g', 'landing'
        ),
            'd\\s*e\\s*m\\s*a\\s*n\\s*d\\s*[-_ ]*\\s*g\\s*e\\s*n', 'demandgen'
        ),
            'p\\s*o\\s*s\\s*[-_ ]*\\s*l\\s*i\\s*t\\s*e', 'pos-lite'
        ) as val
    from ws
),


separators as (
    select
        regexp_replace(
            regexp_replace(val, '\\s*-\\s*', '-'),
            '\\s*_\\s*', '_'
        ) as val
    from fixed_terms
),


underscores as (
    select replace(val, ' ', '_') as val
    from separators
),


prefix_fix as (
    select
        regexp_replace(
            regexp_replace(val, 'bing_search_+', 'bing-search_'),
            'search_shopping_+', 'search-shopping_'
        ) as val
    from underscores
),


final as (
    select
        trim(both '_' from regexp_replace(val, '_+', '_')) as val
    from prefix_fix
)

select val from final

{% endmacro %}
