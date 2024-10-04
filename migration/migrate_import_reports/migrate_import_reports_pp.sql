CREATE TABLE preprod_report.severity_temp
(
    LIKE preprod_report.severity INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from preprod_study.root_node_info),
               included_nodes(id) AS (SELECT id
                                      FROM preprod_report.report_node r
                                      WHERE r.id IN (SELECT id from root)

                                      UNION ALL

                                      SELECT r.id
                                      FROM included_nodes incn
                                               INNER JOIN preprod_report.report_node r
                                                          ON r.parent_id = incn.id)
INSERT
INTO preprod_report.severity_temp
SELECT *
FROM preprod_report.severity
WHERE report_node_id IN (SELECT id FROM included_nodes);

CREATE TABLE preprod_report.report_node_temp
(
    LIKE preprod_report.report_node INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from preprod_study.root_node_info),
               included_nodes(id) AS (SELECT id
                                      FROM preprod_report.report_node r
                                      WHERE r.id IN (SELECT id from root)

                                      UNION ALL

                                      SELECT r.id
                                      FROM included_nodes incn
                                               INNER JOIN preprod_report.report_node r
                                                          ON r.parent_id = incn.id)
INSERT
INTO preprod_report.report_node_temp
SELECT *
FROM preprod_report.report_node
WHERE id IN (SELECT id FROM included_nodes);

ALTER TABLE preprod_report.report_node_temp
    ADD CONSTRAINT parent_fk FOREIGN KEY (parent_id) REFERENCES preprod_report.report_node_temp (id);
ALTER TABLE preprod_report.severity_temp
    ADD CONSTRAINT report_node_severity_fk FOREIGN KEY (report_node_id) REFERENCES preprod_report.report_node_temp (id);

DROP TABLE preprod_report.severity;
DROP TABLE preprod_report.report_node;
ALTER TABLE preprod_report.severity_temp
    RENAME TO severity;
ALTER TABLE preprod_report.report_node_temp
    RENAME TO report_node;
