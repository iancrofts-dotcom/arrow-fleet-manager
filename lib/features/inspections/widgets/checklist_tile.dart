import 'package:flutter/material.dart';

import '../models/inspection_item.dart';

class ChecklistTile extends StatefulWidget {

  final InspectionItem item;

  const ChecklistTile({
    super.key,
    required this.item,
  });

  @override
  State<ChecklistTile> createState() => _ChecklistTileState();
}

class _ChecklistTileState extends State<ChecklistTile> {

  @override
  Widget build(BuildContext context) {

    return Card(

      child: Padding(

        padding: const EdgeInsets.all(12),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Text(
              widget.item.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            Row(

              children: [

                Expanded(

                  child: RadioListTile(

                    title: const Text("Pass"),

                    value: InspectionStatus.pass,

                    groupValue: widget.item.status,

                    onChanged: (value) {

                      setState(() {

                        widget.item.status = value!;

                      });

                    },

                  ),

                ),

                Expanded(

                  child: RadioListTile(

                    title: const Text("Fail"),

                    value: InspectionStatus.fail,

                    groupValue: widget.item.status,

                    onChanged: (value) {

                      setState(() {

                        widget.item.status = value!;

                      });

                    },

                  ),

                ),

                Expanded(

                  child: RadioListTile(

                    title: const Text("N/A"),

                    value: InspectionStatus.na,

                    groupValue: widget.item.status,

                    onChanged: (value) {

                      setState(() {

                        widget.item.status = value!;

                      });

                    },

                  ),

                ),

              ],

            ),

            if (widget.item.status == InspectionStatus.fail)

              TextField(

                decoration: const InputDecoration(

                  labelText: "Defect Notes",

                ),

                onChanged: (value) {

                  widget.item.notes = value;

                },

              )

          ],

        ),

      ),

    );

  }

}