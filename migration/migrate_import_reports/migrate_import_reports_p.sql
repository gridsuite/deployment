CREATE TABLE prod_report.severity_temp
(
    LIKE prod_report.severity INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from prod_study.root_node_info),
               included_nodes(id) AS (SELECT id
                                      FROM prod_report.report_node r
                                      WHERE r.id IN (SELECT id from root)

                                      UNION ALL

                                      SELECT r.id
                                      FROM included_nodes incn
                                               INNER JOIN prod_report.report_node r
                                                          ON r.parent_id = incn.id)
INSERT
INTO prod_report.severity_temp
SELECT *
FROM prod_report.severity
WHERE report_node_id IN (SELECT id FROM included_nodes);

CREATE TABLE prod_report.report_node_temp
(
    LIKE prod_report.report_node INCLUDING ALL
);
WITH RECURSIVE root(id) AS (select report_uuid from prod_study.root_node_info),
               included_nodes(id) AS (SELECT id
                                      FROM prod_report.report_node r
                                      WHERE r.id IN (SELECT id from root)

                                      UNION ALL

                                      SELECT r.id
                                      FROM included_nodes incn
                                               INNER JOIN prod_report.report_node r
                                                          ON r.parent_id = incn.id)
INSERT
INTO prod_report.report_node_temp
SELECT *
FROM prod_report.report_node
WHERE id IN (SELECT id FROM included_nodes);

ALTER TABLE prod_report.report_node_temp
    ADD CONSTRAINT parent_fk FOREIGN KEY (parent_id) REFERENCES prod_report.report_node_temp (id);
ALTER TABLE prod_report.severity_temp
    ADD CONSTRAINT report_node_severity_fk FOREIGN KEY (report_node_id) REFERENCES prod_report.report_node_temp (id);

DROP TABLE prod_report.severity;
DROP TABLE prod_report.report_node;
ALTER TABLE prod_report.severity_temp
    RENAME TO severity;
ALTER TABLE prod_report.report_node_temp
    RENAME TO report_node;
