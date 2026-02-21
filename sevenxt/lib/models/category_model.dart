import 'package:flutter/material.dart';
import '../../route/route_constants.dart';

class CategoryModel {
  final String name;
  final String? svgSrc, route, image;
  final List<CategoryModel>? subCategories;

  CategoryModel({
    required this.name,
    this.svgSrc,
    this.route,
    this.image,
    this.subCategories = const [],
  });

  // Getter for backward compatibility
  String get displayName => name;
}

// Update demoCategories with correct route and images
List<CategoryModel> demoCategories = [
  CategoryModel(
    name: "All Gadgets",
    svgSrc: "assets/icons/Product.svg",
    route: gadgetsScreenRoute,
  ),
  CategoryModel(
    name: "Mobile & Devices",
    svgSrc: "assets/icons/Phone.svg",
     route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "Laptops & PCs",
    svgSrc: "assets/icons/Pc.svg",
    route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "Cameras & Photography",
    svgSrc: "assets/icons/Camera.svg",
    route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "Wearables",
    svgSrc: "assets/icons/Accessories.svg",
     route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "TV & Entertainment",
    svgSrc: "assets/icons/tv.svg",
    route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "Networking",
    svgSrc: "assets/icons/network.svg",
    route: categoryProductsScreen,
  ),
  CategoryModel(
    name: "Peripherals",
    svgSrc: "assets/icons/Child.svg",
    route: categoryProductsScreen,
  ),
];
