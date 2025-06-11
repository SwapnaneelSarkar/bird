// lib/ui_components/country_picker.dart

import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class CountryPicker extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onCountrySelected;
  final double? height;
  final double? width;

  const CountryPicker({
    Key? key,
    required this.selectedCountry,
    required this.onCountrySelected,
    this.height,
    this.width,
  }) : super(key: key);

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCountryPickerBottomSheet(context),
      child: Container(
        height: widget.height ?? 60.0,
        width: widget.width ?? 80.0,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.selectedCountry.flag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              widget.selectedCountry.dialCode,
              style: TextStyle(
                fontSize: FontSize.s14,
                fontFamily: FontFamily.Montserrat,
                fontWeight: FontWeightManager.medium,
                color: ColorManager.black,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _showCountryPickerBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerBottomSheet(
        selectedCountry: widget.selectedCountry,
        onCountrySelected: widget.onCountrySelected,
      ),
    );
  }
}

class CountryPickerBottomSheet extends StatefulWidget {
  final Country selectedCountry;
  final Function(Country) onCountrySelected;

  const CountryPickerBottomSheet({
    Key? key,
    required this.selectedCountry,
    required this.onCountrySelected,
  }) : super(key: key);

  @override
  State<CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filteredCountries = CountryData.countries;
  Country _selectedCountry = CountryData.defaultCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = widget.selectedCountry;
    _filteredCountries = CountryData.countries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = CountryData.searchCountries(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomSheetHeight = screenHeight * 0.75;

    return Container(
      height: bottomSheetHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Select Country',
                  style: TextStyle(
                    fontSize: FontSize.s18,
                    fontFamily: FontFamily.Montserrat,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterCountries,
                style: TextStyle(
                  fontSize: FontSize.s14,
                  fontFamily: FontFamily.Montserrat,
                ),
                decoration: InputDecoration(
                  hintText: 'Search country',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: FontSize.s14,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _filterCountries('');
                          },
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey.shade500,
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          
          // Countries list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country == _selectedCountry;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? ColorManager.primary.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? ColorManager.primary : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      widget.onCountrySelected(country);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    title: Text(
                      country.name,
                      style: TextStyle(
                        fontSize: FontSize.s16,
                        fontFamily: FontFamily.Montserrat,
                        fontWeight: isSelected 
                            ? FontWeightManager.semiBold 
                            : FontWeightManager.medium,
                        color: isSelected ? ColorManager.primary : ColorManager.black,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          country.dialCode,
                          style: TextStyle(
                            fontSize: FontSize.s14,
                            fontFamily: FontFamily.Montserrat,
                            fontWeight: FontWeightManager.medium,
                            color: isSelected 
                                ? ColorManager.primary 
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            color: ColorManager.primary,
                            size: 20,
                          ),
                        ],
                      ],
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