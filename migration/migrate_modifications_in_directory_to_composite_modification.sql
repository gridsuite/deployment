begin transaction isolation level serializable;

with

    dir_element_with_m_id as (select *, gen_random_uuid() as new_id from directory.element where type = 'MODIFICATION'),

    new_modification as (

        insert into networkmodifications.modification(id, date, group_id, modifications_order, stashed, message_type, message_values, type)

            select m.new_id, NULL, NULL, NULL, false, NULL, NULL, 'COMPOSITE_MODIFICATION' from dir_element_with_m_id m

            returning id
    ),

    new_composite as (insert into networkmodifications.composite_modification(id) select id from new_modification returning id),

    new_element_modification as (

        insert into networkmodifications.composite_modification_sub_modifications(id, modification_id, modifications_order)

            select m.new_id, m.id, row_number() over () as modifications_order from dir_element_with_m_id m

            left join new_composite nc on m.new_id=nc.id

            returning id, modification_id
    )

update directory.element e set id = (select n.id from new_element_modification n where n.modification_id=e.id) where type = 'MODIFICATION';

commit;
