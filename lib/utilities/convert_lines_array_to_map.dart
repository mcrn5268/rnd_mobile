class ConvertLinesArrayToMap {
  List<Map<String, dynamic>> purchReq(List<dynamic> rowdata) {
    List<Map<String, dynamic>> listOfMaps = [];

    List<String> fieldNames = [
      'purchase_request_lne_id',
      'purchase_request_hdr_id',
      'ln_num',
      'item_id',
      'item_code',
      'item_desc',
      'item_desc2',
      'qty_requested',
      'trnx_unit',
      'conversion_factor',
      'pr_balance',
      'supplier_id',
      'supplier_name',
      'supplier_price',
      'whs_id',
      'inventory_account_id',
      'inventory_account_code',
      'cost_center_id',
      'cost_center_desc',
      'project_id',
      'project_desc'
    ];

    for (var row in rowdata) {
      Map<String, dynamic> map = {};
      for (var i = 0; i < row.length; i++) {
        var fieldName = fieldNames[i];
        var value = row[i];
        map[fieldName] = value;
      }
      listOfMaps.add(map);
    }

    return listOfMaps;
  }

  List<Map<String, dynamic>> purchOrder(List<dynamic> rowdata) {
    List<Map<String, dynamic>> listOfMaps = [];

    List<String> fieldNames = [
      'po_lne_id',
      'po_id',
      'purchase_request_lne_id',
      'ln_num',
      'item_id',
      'item_code',
      'item_desc',
      'item_desc2',
      'purchase_unit',
      'po_qty',
      'price_net_vat',
      'price',
      'ext_price',
      'vattable',
      'vat_perc',
      'vat_amount',
      'ext_vat_amount',
      'conversion_factor',
      'inventory_account_id',
      'inventory_account_code',
      'cost_center_id',
      'cost_center_desc',
      'project_id',
      'project_desc',
      'preq_num',
      'pr_ln_num'
          'subtotal'
    ];

    for (var row in rowdata) {
      Map<String, dynamic> map = {};
      for (var i = 0; i < row.length; i++) {
        var fieldName = fieldNames[i];
        var value = row[i];
        map[fieldName] = value;
      }

      // Calculate and assign the subtotal based on po_qty * price
      var poQty = map['po_qty'] as num? ?? 0;
      var price = map['price'] as num? ?? 0;
      map['subtotal'] = poQty * price;

      listOfMaps.add(map);
    }

    return listOfMaps;
  }

  List<Map<String, dynamic>> salesOrder(List<dynamic> rowdata) {
    List<Map<String, dynamic>> listOfMaps = [];

    List<String> fieldNames = [
      'so_lne_id',
      'so_hdr_id',
      'ln_num',
      'item_id',
      'item_code',
      'item_desc',
      'so_unit',
      'inventory_account_id',
      'inventory_account_code',
      'qty',
      'base_selling_price',
      'selling_price',
      'ln_amount',
      'conversion_factor',
      'remarks',
      'weight',
      'volume',
      'cost_center_id',
      'cost_center_desc',
      'subtotal' // Added 'subtotal' field
      // Add other field names here
    ];

    for (var row in rowdata) {
      Map<String, dynamic> map = {};
      for (var i = 0; i < row.length; i++) {
        var fieldName = fieldNames[i];
        var value = row[i];
        map[fieldName] = value;
      }

      // Calculate and assign the subtotal based on qty * selling_price
      var qty = map['qty'] as num? ?? 0;
      var sellingPrice = map['selling_price'] as num? ?? 0;
      map['subtotal'] = qty * sellingPrice;

      listOfMaps.add(map);
    }

    return listOfMaps;
  }
}
