{% macro generate_schema_name(custom_schema_name, node) -%}
{%- set default_schema = target.schema -%}

{%- if node.resource_type == 'seed' and node.fqn[1] == '_seeds_setup' -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- elif node.resource_type == 'model' and node.fqn[1] == '_data_for_mediapulse_dbt' -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- else -%}
    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ default_schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endif -%}

{%- endmacro %}