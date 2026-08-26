import 'asset/asset_tag.dart';
import 'example_case.dart';
import 'general/bitmap_logo_example.dart';
import 'general/invoice_example.dart';
import 'general/simple_text_example.dart';
import 'general/table_layout_example.dart';
import 'general/unicode_text_example.dart';
import 'logistics/shipping_label.dart';
import 'logistics/small_parcel_label.dart';
import 'pharmacy/expiry_stock_label.dart';
import 'pharmacy/medicine_price_label.dart';
import 'pharmacy/medicine_usage_label.dart';
import 'restaurant/customer_receipt.dart';
import 'restaurant/kitchen_ticket.dart';
import 'retail/retail_price_label.dart';
import 'retail/retail_promotion_label.dart';
import 'tickets/event_ticket.dart';
import 'tickets/queue_ticket.dart';
import 'tickets/visitor_badge.dart';
import 'warehouse/inventory_item_label.dart';
import 'warehouse/location_bin_label.dart';

/// Central catalog registry containing all 20 Portakal use cases.
class ExampleCatalog {
  /// All 20 executable Portakal use case definitions.
  static final List<ExampleCase> allCases = [
    // Getting Started
    simpleTextCase,

    // Retail
    retailPriceCase,
    retailPromotionCase,

    // Pharmacy
    medicinePriceCase,
    medicineUsageCase,
    expiryStockCase,

    // Restaurant
    kitchenTicketCase,
    customerReceiptCase,

    // Warehouse
    locationBinCase,
    inventoryItemCase,

    // Logistics
    shippingCase,
    smallParcelCase,

    // Tickets & Badges
    eventTicketCase,
    queueTicketCase,
    visitorBadgeCase,

    // Asset Management
    assetTagCase,

    // General & Advanced
    tableLayoutCase,
    invoiceCase,
    bitmapLogoCase,
    unicodeTextCase,
  ];

  /// Find an example case by its unique ID.
  static ExampleCase? getById(String id) {
    try {
      return allCases.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get cases belonging to a specific category.
  static List<ExampleCase> getByCategory(ExampleCategory category) {
    return allCases.where((c) => c.category == category).toList();
  }

  /// Filter cases by category and search query string.
  static List<ExampleCase> filterCases({
    ExampleCategory? category,
    String? searchQuery,
  }) {
    return allCases.where((c) {
      if (category != null && c.category != category) {
        return false;
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchTitle = c.title.toLowerCase().contains(query);
        final matchDesc = c.description.toLowerCase().contains(query);
        final matchId = c.id.toLowerCase().contains(query);
        return matchTitle || matchDesc || matchId;
      }
      return true;
    }).toList();
  }
}
