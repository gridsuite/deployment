begin isolation level repeatable read;
with
    new_modification as (insert into networkmodifications.modification(id, date, group_id, modifications_order, stashed, message_type, message_values, type)
        values (gen_random_uuid(), NULL, NULL, NULL, false, NULL, NULL, 'COMPOSITE_MODIFICATION') returning id),
    new_composite as (insert into networkmodifications.composite_modification(id) (select id from new_modification) returning id),
    modifications_ids as (select id from directory.element where type = 'MODIFICATION')
insert into networkmodifications.composite_modification_sub_modifications(id, modification_id, modifications_order)
select n.id as id, m.id as modification_id, row_number() over () from modifications_ids m full join new_composite n on true=true;
delete from directory.element where type = 'MODIFICATION';
insert into directory.element(id, name, owner, parent_id, type, description, creation_date, last_modification_date, last_modified_by, stash_date, stashed)
values ((select id from networkmodifications.composite_modification), 'Generated-modification-composite', 'admin',
        '054e7336-c9cc-4dd9-9817-7a8b38d2a667', 'MODIFICATION', null, '2024-07-02 14:24:50.296498 +00:00',
        '2024-07-01 21:14:15.517000 +00:00', 'admin', null, false);
commit;