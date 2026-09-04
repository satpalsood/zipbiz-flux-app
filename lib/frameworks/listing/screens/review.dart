import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../models/index.dart';
import '../../../services/index.dart';
import '../../../widgets/common/star_rating.dart';

class Reviews extends StatefulWidget {
  final String productId;

  const Reviews(this.productId);

  @override
  State<Reviews> createState() => _StateReviews();
}

class _StateReviews extends State<Reviews> {
  User? get user => context.read<UserModel>().user;

  final services = Services();
  double rating = 0.0;
  final comment = TextEditingController();
  final title = TextEditingController();
  List<Review>? reviews;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    getListReviews();
  }

  @override
  void dispose() {
    comment.dispose();
    title.dispose();
    super.dispose();
  }

  void updateRating(double index) {
    if (mounted) {
      setState(() {
        rating = index;
      });
    }
  }

  void _showMessage(String message) {
    Tools.showSnackBar(ScaffoldMessenger.of(context), message);
  }

  Future<void> sendReview() async {
    if (rating == 0.0) {
      _showMessage(S.of(context).ratingFirst);
      return;
    }
    if (comment.text.isEmpty) {
      _showMessage(S.of(context).commentFirst);

      return;
    }

    if (title.text.isEmpty && ServerConfig().isListProType) {
      _showMessage(S.of(context).titleFirst);
      return;
    }
    final user = Provider.of<UserModel>(context, listen: false).user!;

    final reviewPayload = ReviewPayload(
      productId: widget.productId,
      rating: rating.toInt(),
      review: comment.text,
      reviewerName: user.fullName,
      reviewerEmail: user.email,
      token: user.cookie,
      reviewerId: user.id,
      title: title.text,
    );
    try {
      setState(() {
        _isSubmitting = true;
      });
      await services.api.createReview(reviewPayload);
      if (mounted) {
        setState(getListReviews);
      }
      setState(() {
        _isSubmitting = false;
        rating = 0.0;
        comment.text = '';
        title.text = '';
      });

      final message = (ServerConfig().isListProType ||
              (ServerConfig().isListeoType &&
                  kAdvanceConfig.enableApprovedReview))
          ? S.of(context).reviewSent
          : S.of(context).reviewPendingApproval;

      _showMessage(message);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showMessage(e.toString());
    }
  }

  void getListReviews() {
    services.api.getReviews(widget.productId).then((onValue) {
      if (mounted) {
        setState(() {
          reviews = onValue.data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (user != null)
            _SubmitReviewSection(
              isSubmitting: _isSubmitting,
              sendReview: sendReview,
              updateRating: updateRating,
              rating: rating,
              textControllerComment: comment,
              textControllerTitle: title,
            )
          else
            const _RequiredLoginButton(),
          reviews == null
              ? kLoadingWidget(context)
              : (reviews!.isEmpty
                  ? SizedBox(
                      height: 30,
                      child: Center(
                        child: Text(S.of(context).noReviews),
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        for (var i = 0; i < reviews!.length; i++)
                          _ReviewItemWidget(review: reviews![i])
                      ],
                    )),
        ],
      ),
    );
  }
}

class _ReviewItemWidget extends StatelessWidget {
  const _ReviewItemWidget({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      spacing: 5,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            if (review.avatar?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: FluxImage(
                    imageUrl: review.avatar!,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(review.name!.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.primaryColorLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SmoothStarRating(
                allowHalfRating: true,
                starCount: 5,
                rating: review.rating,
                size: 12.0,
                color: theme.primaryColor,
                borderColor: theme.primaryColor,
                spacing: 0.0,
                label: Container(),
              ),
            ),
          ],
        ),
        if (ServerConfig().isListProType) ...[
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: HtmlWidget(
              review.title ?? '',
              textStyle: const TextStyle(
                  color: kGrey600, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(timeago.format(review.createdAt),
              style: const TextStyle(color: kGrey400, fontSize: 10)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: HtmlWidget(
            review.review ?? '',
            textStyle: const TextStyle(color: kGrey600, fontSize: 14),
          ),
        ),
        if (review.images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: review.images
                  .map((imageUrl) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FluxImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ))
                  .toList(),
            ),
          ),
        const Divider(),
      ],
    );
  }
}

class _RequiredLoginButton extends StatelessWidget {
  const _RequiredLoginButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(
        minHeight: 32,
        maxHeight: 64,
      ),
      height: 50.0,
      child: RawMaterialButton(
        onPressed: () => Navigator.of(context).pushNamed(RouteList.login),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
        fillColor: theme.primaryColorLight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              S.of(context).loginToReview,
              style: TextStyle(
                color: theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SubmitReviewSection extends StatelessWidget {
  const _SubmitReviewSection({
    required this.isSubmitting,
    required this.sendReview,
    required this.updateRating,
    this.rating,
    this.textControllerComment,
    this.textControllerTitle,
  });

  final bool isSubmitting;
  final void Function() sendReview;
  final void Function(double index) updateRating;
  final double? rating;
  final TextEditingController? textControllerComment;
  final TextEditingController? textControllerTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                S.of(context).productRating.toUpperCase(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.secondary.withValueOpacity(0.5)),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  decoration: BoxDecoration(
                    color: theme.primaryColorLight,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: SmoothStarRating(
                    allowHalfRating: false,
                    onRatingChanged: updateRating,
                    starCount: 5,
                    rating: rating,
                    size: 25.0,
                    color: theme.primaryColor,
                    borderColor: theme.primaryColor,
                    spacing: 10.0,
                    label: Container(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 30),
          padding: const EdgeInsets.only(left: 5.0, bottom: 5.0, top: 5.0),
          child: Column(
            children: [
              /// Only listpro theme has title review
              if (ServerConfig().isListProType)
                TextField(
                  controller: textControllerTitle,
                  maxLines: 3,
                  minLines: 1,
                  decoration:
                      InputDecoration(labelText: S.of(context).writeTitle),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textControllerComment,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                          labelText: S.of(context).writeComment),
                    ),
                  ),
                  IconButton(
                    icon: isSubmitting
                        ? const CircularProgressIndicator()
                        : Icon(
                            Icons.send,
                            color: theme.primaryColor,
                          ),
                    onPressed: isSubmitting ? null : sendReview,
                  )
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
