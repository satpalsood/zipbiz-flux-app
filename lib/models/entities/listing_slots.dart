import 'dart:convert';

class ListingSlots {
  List<List<dynamic>> timeSlots = [];

  ListingSlots.fromJson(slot) {
    if (slot != null) {
      try {
        var json = slot is String && slot.isNotEmpty ? jsonDecode(slot) : slot;
        if (json is Map) {
          for (var entry in json.values) {
            var list = <dynamic>[];
            if (entry is Iterable) {
              for (var timeSlot in entry) {
                if (timeSlot != null) {
                  list.add(timeSlot.toString().split('|')[0].trim());
                }
              }
            } else if (entry != null && entry.toString().isNotEmpty) {
              list.add(entry.toString().split('|')[0].trim());
            }
            if (list.isNotEmpty) timeSlots.add(list);
          }
        } else if (json is Iterable) {
          for (var item in json) {
            var list = <dynamic>[];
            if (item is Iterable) {
              for (var timeSlot in item) {
                if (timeSlot != null) {
                  list.add(timeSlot.toString().split('|')[0].trim());
                }
              }
            } else if (item != null && item.toString().isNotEmpty) {
              list.add(item.toString().split('|')[0].trim());
            }
            if (list.isNotEmpty) timeSlots.add(list);
          }
        }
      } catch (e) {
        return;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {'timeSlots': timeSlots};
  }
}
