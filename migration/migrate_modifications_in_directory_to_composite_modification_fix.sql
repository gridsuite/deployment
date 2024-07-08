begin transaction isolation level serializable;
update networkmodifications.public.modification e
set date = CURRENT_DATE,
    modifications_order = 0,
    message_type = 'COMPOSITE_MODIFICATION',
    message_values = '{}'
where type = 'COMPOSITE_MODIFICATION'
  AND date IS NULL
  AND modifications_order IS NULL
  AND message_type IS NULL
  AND message_values IS NULL;
commit;
