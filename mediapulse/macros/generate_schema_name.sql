{% macro generate_schema_name(custom_schema_name, node) -%}
    {#
        Override the default schema name generation so that:
        - Seeds with a custom schema (e.g. raw_news) land in exactly that schema,
          not the default target_schema + "_" + custom_schema pattern.
        - All other models use the target schema as normal.

        This keeps the raw seed tables in predictable schemas that match the
        source definitions, without needing a separate ingestion pipeline.
    #}
    {%- set default_schema = target.schema -%}

    {%- if custom_schema_name is none -%}
        {{ default_schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}
