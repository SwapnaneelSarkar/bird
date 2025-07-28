import 'package:flutter/material.dart';
import '../../models/order_details_model.dart';
import '../../models/menu_model.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../service/currency_service.dart';
import '../../utils/currency_utils.dart';

class OrderItemsFullListPage extends StatelessWidget {
  final List<OrderDetailsItem> items;
  final Map<String, MenuItem> menuItems;

  const OrderItemsFullListPage({Key? key, required this.items, required this.menuItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Order Items'),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: ColorManager.black),
        titleTextStyle: TextStyle(
          fontSize: screenWidth * 0.045,
          fontWeight: FontWeightManager.bold,
          fontFamily: FontFamily.Montserrat,
          color: ColorManager.black,
        ),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: ListView.separated(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(color: Colors.grey[200]),
        itemBuilder: (context, index) {
          final item = items[index];
          final menuItem = item.menuId != null ? menuItems[item.menuId!] : null;
          final itemName = menuItem?.name ?? item.itemName ?? 'Menu Item';
          return Row(
            children: [
              Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  image: item.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(item.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: item.imageUrl == null
                    ? Icon(
                        Icons.fastfood,
                        color: Colors.grey[500],
                        size: screenWidth * 0.06,
                      )
                    : null,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Text(
                          '${item.quantity}x',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.grey[600],
                          ),
                        ),
                        FutureBuilder<String>(
                          future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                          builder: (context, snapshot) {
                            final currencySymbol = snapshot.data ?? '₹';
                            return Text(
                              ' ${CurrencyUtils.formatPrice(item.itemPrice, currencySymbol)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontFamily: FontFamily.Montserrat,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    if (menuItem?.description != null && menuItem!.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.005),
                        child: Text(
                          menuItem.description!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              FutureBuilder<String>(
                future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                builder: (context, snapshot) {
                  final currencySymbol = snapshot.data ?? '₹';
                  return Text(
                    CurrencyUtils.formatPrice(item.totalPrice, currencySymbol),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeightManager.bold,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
} 