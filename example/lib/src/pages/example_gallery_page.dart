import 'package:flutter/material.dart';
import '../examples/example_case.dart';
import '../examples/example_catalog.dart';
import '../transport/hardware_printer_transport.dart';
import 'example_detail_page.dart';
import 'hardware_validation_page.dart';

/// Main Gallery Home Page displaying all Portakal use cases organized by category.
class ExampleGalleryPage extends StatefulWidget {
  final HardwarePrinterTransport? transport;

  const ExampleGalleryPage({super.key, this.transport});

  @override
  State<ExampleGalleryPage> createState() => _ExampleGalleryPageState();
}

class _ExampleGalleryPageState extends State<ExampleGalleryPage> {
  ExampleCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCases = ExampleCatalog.filterCases(
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portakal Example Gallery'),
        backgroundColor: Colors.deepOrange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('open_hardware_bench_button'),
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Hardware Validation Bench',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HardwareValidationPage(
                    transport: widget.transport ?? FlutterThermalPrinterTransport(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  key: const Key('gallery_search_field'),
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${ExampleCatalog.allCases.length} practical use cases...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Category Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        key: const Key('category_all'),
                        selected: _selectedCategory == null,
                        label: Text('All (${ExampleCatalog.allCases.length})'),
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ...ExampleCategory.values.map((cat) {
                        final count = ExampleCatalog.getByCategory(cat).length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            key: Key('category_${cat.name}'),
                            selected: _selectedCategory == cat,
                            label: Text('${cat.label} ($count)'),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? cat : null;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Use Case List
          Expanded(
            child: filteredCases.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No examples match your filter.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredCases.length,
                    itemBuilder: (context, index) {
                      final item = filteredCases[index];
                      return Card(
                        key: Key('example_card_${item.id}'),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExampleDetailPage(
                                  exampleCase: item,
                                  transport: widget.transport,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Chip(
                                      label: Text(
                                        item.category.label,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.deepOrange.shade50,
                                      side: BorderSide(color: Colors.deepOrange.shade200),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      avatar: const Icon(Icons.aspect_ratio, size: 12),
                                      label: Text(
                                        item.recommendedMedia,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.grey.shade100,
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${item.testedProtocols.length} protocols tested',
                                      style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
