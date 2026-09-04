import 'package:flutter/material.dart';

import '../../../models/entities/listing_type.dart';
import '../../../services/index.dart';

class SelectListingType extends StatefulWidget {
  const SelectListingType({super.key, this.value, required this.onChanged});
  final ListingType? value;
  final Function(ListingType?) onChanged;
  @override
  State<SelectListingType> createState() => _SelectListingTypeState();
}

class _SelectListingTypeState extends State<SelectListingType> {
  List<ListingType> _types = [];

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      Services().api.getListingTypes().then((types) {
        if (types.isNotEmpty) {
          setState(() {
            _types = types;
          });
          widget.onChanged(types[0]);
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_types.isEmpty || widget.value == null) return const SizedBox();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: DropdownButton<ListingType>(
        underline: const SizedBox(),
        isExpanded: true,
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
        value: widget.value,
        onChanged: (ListingType? value) {
          widget.onChanged(value);
        },
        items: _types.map<DropdownMenuItem<ListingType>>((ListingType item) {
          return DropdownMenuItem<ListingType>(
            value: item,
            child: Text(item.title ?? ''),
          );
        }).toList(),
      ),
    );
  }
}
