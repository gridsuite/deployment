CREATE TABLE report.severity_temp
(
    LIKE report.severity INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from study.root_node_info),
               included_nodes(id, level) AS (SELECT id, 0 as level
                                             FROM report.report_node r
                                             WHERE r.id IN (SELECT id from root)

                                             UNION ALL

                                             SELECT r.id, level + 1
                                             FROM included_nodes incn
                                                      INNER JOIN report.report_node r
                                                                 ON r.parent_id = incn.id)
INSERT
INTO report.severity_temp
SELECT *
FROM report.severity
WHERE report_node_id IN (SELECT id FROM included_nodes);

CREATE TABLE report.report_node_temp
(
    LIKE report.report_node INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from study.root_node_info),
               included_nodes(id, level) AS (SELECT id, 0 as level
                                             FROM report.report_node r
                                             WHERE r.id IN (SELECT id from root)

                                             UNION ALL

                                             SELECT r.id, level + 1
                                             FROM included_nodes incn
                                                      INNER JOIN report.report_node r
                                                                 ON r.parent_id = incn.id)
INSERT
INTO report.report_node_temp
SELECT *
FROM report.report_node
WHERE id IN (SELECT id FROM included_nodes);

ALTER TABLE report.report_node_temp
    ADD CONSTRAINT parent_fk FOREIGN KEY (parent_id) REFERENCES report.report_node_temp (id);
ALTER TABLE report.severity_temp
    ADD CONSTRAINT report_node_severity_fk FOREIGN KEY (report_node_id) REFERENCES report.report_node_temp (id);

DROP TABLE report.severity;
DROP TABLE report.report_node;
ALTER TABLE report.severity_temp
    RENAME TO severity;
ALTER TABLE report.report_node_temp
    RENAME TO report_node;
