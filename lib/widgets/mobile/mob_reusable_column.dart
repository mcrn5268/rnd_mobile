import 'package:flutter/material.dart';

class MobileReusableColumn extends StatelessWidget {
  final String firstRowFirstText;
  final String firstRowSecondText;
  final String secondRowFirstText;
  final String thirdRowFirstText;
  final String thirdRowSecondText;
  final String fourthRowFirstText;
  final String fourthRowSecondText;
  final Color? statusColor;
  final bool? clickable;
  final bool? confCanc;
  final void Function()? onDenyPressed;
  final void Function()? onApprovePressed;
  final void Function()? onCancelPressed;
  final void Function()? onConfirmPressed;
  final bool? fromItems;

  const MobileReusableColumn(
      {Key? key,
      required this.firstRowFirstText,
      required this.firstRowSecondText,
      required this.secondRowFirstText,
      required this.thirdRowFirstText,
      required this.thirdRowSecondText,
      required this.fourthRowFirstText,
      required this.fourthRowSecondText,
      required this.statusColor,
      this.clickable,
      this.confCanc,
      this.onDenyPressed,
      this.onApprovePressed,
      this.onCancelPressed,
      this.onConfirmPressed,
      this.fromItems})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Colors.grey),
              child: const Icon(Icons.numbers, color: Colors.white, size: 9),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(firstRowFirstText,
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Spacer(),
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: statusColor),
            ),
            const SizedBox(
              width: 5,
            ),
            Text(firstRowSecondText,
                style: TextStyle(fontSize: 12, color: statusColor)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              secondRowFirstText,
              textAlign: TextAlign.left,
            ),
            // const Spacer(),
            // if (clickable == false) ...[
            //   const SizedBox(width: 15),
            // ] else ...[
            //   const SizedBox(
            //       width: 15, child: Icon(Icons.arrow_right_outlined)),
            // ]
          ],
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        fromItems == true
                            ? 'Group: $thirdRowFirstText'
                            : 'Description: $thirdRowFirstText',
                        textAlign: TextAlign.left,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                        fromItems == true
                            ? 'Unit: $fourthRowFirstText'
                            : 'Request Date: $fourthRowFirstText',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ])),
              const VerticalDivider(),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        fromItems == true
                            ? 'Cost Method: $thirdRowSecondText'
                            : 'Reference: $thirdRowSecondText',
                        textAlign: TextAlign.left,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                        fromItems == true
                            ? 'Selling Price: $fourthRowSecondText'
                            : 'Needed Date: $fourthRowSecondText',
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey)),
                  ])),
            ],
          ),
        ),
        const SizedBox(
          height: 15,
        ),
        if (confCanc != null) ...[
          Stack(
            children: [
              Row(children: [
                Expanded(
                    child: Visibility(
                        visible: !confCanc!,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: onDenyPressed,
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close,
                                      color: Colors.red, size: 15),
                                  Text('Deny',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red))
                                ])))),
                const SizedBox(width: 5),
                Expanded(
                    child: Visibility(
                        visible: !confCanc!,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: onApprovePressed,
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check,
                                      color: Colors.green, size: 15),
                                  Text('Approve',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.green))
                                ])))),
              ]),
              Row(children: [
                Expanded(
                    child: Visibility(
                        visible: confCanc!,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: onCancelPressed,
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.close,
                                      color: Colors.red, size: 15),
                                  Text('Cancel',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.red))
                                ])))),
                const SizedBox(width: 5),
                Expanded(
                    child: Visibility(
                        visible: confCanc!,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: onConfirmPressed,
                            child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check,
                                      color: Colors.green, size: 15),
                                  Text('Confirm',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ))
                                ])))),
              ]),
            ],
          ),
        ]
      ],
    );
  }
}
