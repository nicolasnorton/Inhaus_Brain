import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class InteractiveTableWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const InteractiveTableWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Data Table';
    final List<dynamic> columnsJson = data['columns'] ?? [];
    final List<dynamic> rowsJson = data['rows'] ?? [];

    final source = _JsonDataSource(rowsJson, columnsJson);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2128),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              IconButton(icon: const Icon(Icons.download, color: Colors.white54, size: 20), onPressed: () {}), // Placeholder
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 300, 
            child: SfDataGridTheme(
              data: SfDataGridThemeData(
                headerColor: const Color(0xFF2D333B),
                gridLineColor: Colors.white12,
                rowHoverColor: Colors.white10,
                selectionColor: Colors.blueAccent.withOpacity(0.3),
              ),
              child: SfDataGrid(
                source: source,
                columnWidthMode: ColumnWidthMode.fill,
                allowSorting: true,
                allowFiltering: true, // Requires extended setup, but keeping prop for now
                columns: columnsJson.map<GridColumn>((col) {
                  return GridColumn(
                    columnName: col['name'],
                    label: Container(
                      padding: const EdgeInsets.all(8.0),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        col['label'] ?? col['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonDataSource extends DataGridSource {
  final List<dynamic> rawRows;
  final List<dynamic> columns;
  List<DataGridRow> _dataGridRows = [];

  _JsonDataSource(this.rawRows, this.columns) {
    _dataGridRows = rawRows.map<DataGridRow>((row) {
      return DataGridRow(cells: columns.map<DataGridCell>((col) {
        final colName = col['name'];
        final val = row[colName];
        return DataGridCell(columnName: colName, value: val);
      }).toList());
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.all(8.0),
          child: Text(
            cell.value.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
