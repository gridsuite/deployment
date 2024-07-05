begin transaction isolation level serializable;
select *, gen_random_uuid() as new_id into MODIFICATION_ELEMENTS from directory.element where type = 'MODIFICATION';

update directory.element e set id = (select modifs.new_id from MODIFICATION_ELEMENTS modifs where modifs.id=e.id) where type = 'MODIFICATION';

insert into networkmodifications.modification (id, date, group_id, modifications_order, stashed, message_type, message_values, type)
select new_id, NULL, NULL, NULL, false, NULL, NULL, 'COMPOSITE_MODIFICATION' from MODIFICATION_ELEMENTS;

insert into networkmodifications.composite_modification (id) (select new_id from MODIFICATION_ELEMENTS);

insert into networkmodifications.composite_modification_sub_modifications(id, modification_id, modifications_order)
    (select new_id, id, 0 from MODIFICATION_ELEMENTS);
commit;