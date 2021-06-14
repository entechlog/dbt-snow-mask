- [Overview](#overview)
- [Installation Instructions](#installation-instructions)
- [How to apply masking policy ?](#how-to-apply-masking-policy-)
- [How to remove masking policy ?](#how-to-remove-masking-policy-)
- [How to validate masking policy ?](#how-to-validate-masking-policy-)
- [Future Enhancements](#future-enhancements)
- [Credits](#credits)
- [References](#references)

# Overview
This dbt package contains macros that can be (re)used across dbt projects with snowflake. `dbt_snow_mask` will help to apply [Dynamic Data Masking](https://docs.snowflake.com/en/user-guide/security-column-ddm-use.html) using [dbt meta](https://docs.getdbt.com/reference/resource-properties/meta).

# Installation Instructions

- Add the package into your project.

  **Example** : packages.yml

  ```bash
    - git: "https://github.com/entechlog/dbt-snow-mask.git"
    revision: 0.1.1
  ```

> Please refer to the release version of this repo/dbt hub for the latest revision

# How to apply masking policy ?

- Masking is controlled by [meta](https://docs.getdbt.com/reference/resource-properties/meta) in [dbt resource properties](https://docs.getdbt.com/reference/declaring-properties) for sources and models. 

- Decide you masking policy name and add the key `masking_policy` in the column which has to be masked.
  
  **Example** : source.yml

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
  
  **Example** : model.yml
  ```bash
  models:
  - name: stg_customer
    columns:
      - name: customer_email
        meta:
          masking_policy: temp
  ```

- Create a new `.sql` file with the name `create_masking_policy_<masking-policy-name-from-meta>.sql` and the sql for masking policy definition. Its important for macro to follow this naming standard.
  
  **Example** : create_masking_policy_temp.sql

  ```sql
  {% macro create_masking_policy_temp(node_database,node_schema) %}

  CREATE MASKING POLICY IF NOT EXISTS {{node_database}}.{{node_schema}}.temp AS (val string) 
    RETURNS string ->
        CASE WHEN CURRENT_ROLE() IN ('ANALYST') THEN val 
             WHEN CURRENT_ROLE() IN ('DEVELOPER') THEN SHA2(val)
        ELSE '**********'
        END

  {% endmacro %}
  ```

> Its good to keep the masking policy ddl organized in a directory say `\macros\snow-mask-ddl`

- Create the masking policies by running below command  

  
  | Resource Type | Command                                                                         |
  | ------------- | ------------------------------------------------------------------------------- |
  | sources       | `dbt run-operation create_masking_policy --args '{"resource_type": "sources"}'` |
  | models        | `dbt run-operation create_masking_policy --args '{"resource_type": "models"}'`  |

- Add post-hook to `dbt_project.yml`
  
  **Example** : dbt_project.yml

  ```bash
  models:
  post-hook: 
    - "{{ dbt_snow_mask.apply_masking_policy() }}"
  ```

- Apply the masking policy by running below commands  


  | Resource Type | Command                                                                        |
  | ------------- | ------------------------------------------------------------------------------ |
  | sources       | `dbt run-operation apply_masking_policy --args '{"resource_type": "sources"}'` |
  | models        | `dbt run -- model <model-name>`                                                |

# How to remove masking policy ?

- Remove the masking policy applied by this package by running below commands  


  | Resource Type | Command                                                                          |
  | ------------- | -------------------------------------------------------------------------------- |
  | sources       | `dbt run-operation unapply_masking_policy --args '{"resource_type": "sources"}'` |
  | models        | `dbt run-operation unapply_masking_policy --args '{"resource_type": "models"}'`  |

# How to validate masking policy ?

```sql
-- Show masking policy
SHOW MASKING POLICIES;

-- Describe masking policy
DESCRIBE MASKING POLICY <masking-policy-name>;

-- Show masking policy references
USE DATABASE <database-name>;

USE SCHEMA INFORMATION_SCHEMA;

SELECT *
  FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(POLICY_NAME => '<database-name>.<schema-name>.<masking-policy-name>'));
```

# Future Enhancements
- Optimize macros & reduce number of lines in macros
- `apply_masking_policy_list_for_sources` needs changes to find the `materialization` 
- Add support for `CREATE OR REPLACE MASKING POLICY`. This needs unset to happen before replacing the existing policy to avoid `SQL compilation error: Policy TEMP cannot be dropped/replaced as it is associated with one or more entities.` error

# Credits
This package was created using examples from [Serge](https://www.linkedin.com/in/serge-gekker-912b9928/) and [Matt](https://www.linkedin.com/in/matt-winkler-4024263a/)

# References
- https://docs.snowflake.com/en/user-guide/security-column-ddm-intro.html
- https://getdbt.slack.com/archives/CJN7XRF1B/p1609177817234800
