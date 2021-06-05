- [Overview](#overview)
- [How to use this package ?](#how-to-use-this-package-)
- [Credits](#credits)
- [Future Enhancements](#future-enhancements)

# Overview
This dbt package contains macros that can be (re)used across dbt projects with snowflake. `dbt_snow_mask` will help to apply [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-use.html) using [dbt meta](https://docs.getdbt.com/reference/resource-properties/meta).

# How to use this package ?

- Add the package into your project

  **Example** : packages.yml

  ```bash
    - git: "https://github.com/entechlog/dbt-snow-mask.git"
    revision: 0.1.0
  ```

- Masking is controlled by [meta](https://docs.getdbt.com/reference/resource-properties/meta) in [dbt resource properties](https://docs.getdbt.com/reference/declaring-properties) for sources and models. 

- Decide you masking policy name and add the key `masking_policy` in the column which has to be masked.
  
  **Example** : src_sakila.yml

  ```bash
  sources:
  - name: sakila
    tables:
      - name: actor
        columns:
          - name: FIRST_NAME
            meta:
                masking_policy: temp
  ```
  
- Create a new `.sql` file with the name `create_masking_policy_<masking-policy-name-from-meta>.sql` and the sql for masking policy definition. Its important for macro to follow this naming standard.
  
  **Example** : create_masking_policy_temp.sql

  ```sql
  {% macro create_masking_policy_temp(node_database,node_schema) %}

  CREATE OR REPLACE MASKING POLICY {{node_database}}.{{node_schema}}.temp AS (val string) 
    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('ANALYST') THEN val 
             WHEN CURRENT_ROLE() IN ('DEVELOPER') THEN SHA2(val)
        ELSE '**********'
        END

  {% endmacro %}
  ```

> Its also good to keep the masking policy ddl organized into a directory say `\macros\snow-mask-ddl`

- Create the masking policies by running below command
  
  | Resource Type | Command                                              |
  | ------------- | ---------------------------------------------------- |
  | sources       | `dbt run-operation create_masking_policy --args '{"resource_type": "sources"}'` |
  | models        | `dbt run-operation create_masking_policy --args '{"resource_type": "models"}'`  |

- Apply the masking policy by running below commands

  | Resource Type | Command                         |
  | ------------- | ------------------------------- |
  | sources       | `dbt run-operation apply_masking_policy --args '{"resource_type": "sources"}'` |
  | models        | `dbt run -- model <model-name>` |

# Credits
This package was created using example macros from [Serge](https://getdbt.slack.com/archives/CJN7XRF1B/p1609177817234800)

# Future Enhancements
- Optimize the macros & reduce the number of lines in each macros
- `apply_masking_policy_list_for_sources` needs changes to find the `materialization` 