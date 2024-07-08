begin transaction isolation level serializable;
update networkmodifications.modification e
set date = (select creation_date from modification_elements where id = e.id),
    modifications_order = 0,
    message_type = 'COMPOSITE_MODIFICATION',
    message_values = '{}'
where type = 'COMPOSITE_MODIFICATION'
  AND date IS NULL
  AND modifications_order IS NULL
  AND message_type IS NULL
  AND message_values IS NULL;

drop table modification_elements;
commit;
