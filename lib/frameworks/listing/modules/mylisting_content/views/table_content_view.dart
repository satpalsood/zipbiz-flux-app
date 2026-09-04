import 'package:flutter/material.dart';
import 'package:inspireui/inspireui.dart';
import '../../../../../common/config.dart';
import '../../../../../widgets/common/expansion_info.dart';
import '../models/row_item.dart';
import '../models/table_content.dart';

class TableContentView extends StatelessWidget {
  const TableContentView({
    super.key,
    required this.content,
  });
  final TableContent content;
  @override
  Widget build(BuildContext context) {
    return ExpansionInfo(
      expand: kProductDetail.expandDescription,
      title: content.title ?? '',
      children: <Widget>[
        ...?content.rows?.map((item) => _renderItem(context, item))
      ],
    );
  }

  Widget _renderItem(BuildContext context, RowItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              width: 1.0,
              color: Theme.of(context).primaryColorLight.withValueOpacity(0.7)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.title ?? '',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            item.content ?? '',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
