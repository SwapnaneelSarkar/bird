import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class QuantityCounter extends StatefulWidget {
  final int initialValue;
  final Function(int) onChanged;
  
  const QuantityCounter({
    Key? key,
    this.initialValue = 0,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<QuantityCounter> createState() => _QuantityCounterState();
}

class _QuantityCounterState extends State<QuantityCounter> {
  late int value;
  
  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }
  
  @override
  Widget build(BuildContext context) {
    if (value == 0) {
      return _buildAddButton();
    } else {
      return _buildCounter();
    }
  }
  
  Widget _buildAddButton() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          value = 1;
        });
        widget.onChanged(value);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorManager.black,
        foregroundColor: ColorManager.textWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text('ADD'),
    );
  }
  
  Widget _buildCounter() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: ColorManager.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildControlButton(
            icon: Icons.remove,
            onPressed: () {
              setState(() {
                value = value - 1;
                if (value < 0) value = 0;
              });
              widget.onChanged(value);
            },
          ),
          SizedBox(
            width: 36,
            child: Center(
              child: Text(
                value.toString(),
                style: TextStyle(
                  fontFamily: FontFamily.Montserrat,
                  fontSize: FontSize.s16,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ),
          ),
          _buildControlButton(
            icon: Icons.add,
            onPressed: () {
              setState(() {
                value = value + 1;
                if (value > 99) value = 99;
              });
              widget.onChanged(value);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: ColorManager.black,
          borderRadius: icon == Icons.remove
              ? const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                )
              : const BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
        ),
        child: Icon(
          icon,
          color: ColorManager.textWhite,
          size: 16,
        ),
      ),
    );
  }
}