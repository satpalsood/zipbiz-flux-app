import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:inspireui/extensions/color_extension.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../../common/theme/colors.dart';
import '../../../../../models/entities/product.dart';
import '../listing_booking_model.dart';

class PickDateTimeWidget extends StatelessWidget {
  final Product? product;

  const PickDateTimeWidget({this.product});

  int getListeoTimeSlotDate(DateTime date) => date.weekday - 1;

  Future<void> setDate(BuildContext context, ListingBookingModel model) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: model.date,
        firstDate: DateTime(2019, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != model.date) {
      await model.setDate(picked);
    }
  }

  Future<void> setTime(BuildContext context, ListingBookingModel model) async {
    final picked =
        await showTimePicker(context: context, initialTime: model.time);
    if (picked != null && picked != model.time) {
      await model.setTime(picked);
    }
  }

  Future<void> setDateStart(
      BuildContext context, ListingBookingModel model) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: model.dateStart,
        firstDate: DateTime.now(),
        lastDate: DateTime(2101));
    if (picked != null && picked != model.dateStart) {
      await model.setDateStart(picked);
    }
  }

  Future<void> setDateEnd(
      BuildContext context, ListingBookingModel model) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: model.dateEnd,
        firstDate: model.dateStart,
        lastDate: DateTime(2101));
    if (picked != null && picked != model.dateEnd) {
      await model.setDateEnd(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final listingBookingModel =
        Provider.of<ListingBookingModel>(context, listen: false);

    var weekday = getListeoTimeSlotDate(listingBookingModel.date);
    final slots = product?.slots;
    final isNotFoundSlots = slots == null || slots.timeSlots.isEmpty;
    final timeSlotsForDay = slots != null &&
            slots.timeSlots.isNotEmpty &&
            weekday >= 0 &&
            weekday < slots.timeSlots.length
        ? slots.timeSlots[weekday]
        : null;
    final theme = Theme.of(context);

    if (product?.type == 'service') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).pickADate,
            style: theme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setDate(context, listingBookingModel),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                        color: theme.primaryColorLight,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(3)),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color:
                              theme.colorScheme.secondary.withValueOpacity(0.7),
                        ),
                        const SizedBox(width: 10),
                        Center(
                          child: Text(
                            DateFormat('yyyy-MM-dd')
                                .format(listingBookingModel.date),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isNotFoundSlots) ...[
                const SizedBox(width: 20),
                Expanded(
                  child: InkWell(
                    onTap: () => setTime(context, listingBookingModel),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColorLight,
                        border: Border.all(color: Colors.grey, width: 1.0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 18,
                            color: theme.colorScheme.secondary
                                .withValueOpacity(0.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            listingBookingModel.time.format(context),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (timeSlotsForDay?.isEmpty ?? false)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(3.0)),
              child: Text(S.of(context).noSlotAvailable),
            ),
          Wrap(
            children: List.generate(
              timeSlotsForDay?.length ?? 0,
              (index) {
                final timeSlot = timeSlotsForDay?[index];
                final isSelected =
                    listingBookingModel.listTimeSlot.contains(timeSlot);
                return InkWell(
                  onTap: () {
                    listingBookingModel.updateListTimeSlot(
                        timeSlot, weekday, index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    margin: const EdgeInsets.all(5.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red, width: 1),
                      borderRadius: BorderRadius.circular(10.0),
                      color: isSelected ? kColorRed : null,
                    ),
                    child: Text(
                      timeSlot,
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }
    if (product?.type == 'rental') {
      return Column(
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      S.of(context).dateStart,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => setDateStart(context, listingBookingModel),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: theme.primaryColorLight,
                            border: Border.all(color: Colors.grey, width: 1.0),
                            borderRadius: BorderRadius.circular(3)),
                        child: Center(
                          child: Text(
                              DateFormat('yyyy-MM-dd')
                                  .format(listingBookingModel.dateStart),
                              style: theme.textTheme.titleMedium),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      S.of(context).dateEnd,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => setDateEnd(context, listingBookingModel),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColorLight,
                          border: Border.all(color: Colors.grey, width: 1.0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                              DateFormat('yyyy-MM-dd')
                                  .format(listingBookingModel.dateEnd),
                              style: theme.textTheme.titleMedium),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      );
    }
    return const SizedBox();
  }
}
