import 'package:flutter/material.dart';

class RemarkPage extends StatefulWidget {
  const RemarkPage({super.key});

  @override
  State<RemarkPage> createState() => _RemarkPageState();
}

class _RemarkPageState extends State<RemarkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Remark Page'),
      ),

    );
  }
}
