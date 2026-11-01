import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/invoice_list_viewmodel.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var vm = context.watch<InvoiceListViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('TM ', style: TextStyle(color: Colors.white, fontSize: 20)),
            Text('Visuals',
                style: TextStyle(color: Colors.amber, fontSize: 20)),
            SizedBox(width: 8),
            Icon(Icons.stars, color: Colors.amber),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.amber),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Invoices',
              style: TextStyle(color: Colors.white, fontSize: 22)),
          SizedBox(height: 16),
          Container(
            height: 420,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber, width: 0.5),
            ),
            child: Column(
              children: [
                TextField(
                  style: TextStyle(color: Colors.white),
                  onChanged: (text) {
                    vm.search(text);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.amber),
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: vm.invoices.length,
                  itemBuilder: (context, index) {
                    var invoice = vm.invoices[index];
                    return GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(invoice.reference,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                SizedBox(height: 8),
                                Text('Date Created: ${invoice.dateCreated}',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 11)),
                              ],
                            ),
                            Text('Click to View',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 9)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('ADD',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}