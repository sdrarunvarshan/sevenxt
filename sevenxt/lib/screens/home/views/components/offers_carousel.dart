import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sevenxt/components/Banner/M/banner_m_style_1.dart';
import 'package:sevenxt/components/Banner/M/banner_m_style_2.dart';
import 'package:sevenxt/components/Banner/M/banner_m_style_3.dart';
import 'package:sevenxt/components/Banner/M/banner_m_style_4.dart';
import 'package:sevenxt/components/dot_indicators.dart';
import 'package:sevenxt/components/skleton/others/offers_skelton.dart';
import 'package:sevenxt/route/api_service.dart';

import '../../../../constants.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key});

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late Timer _timer;

  List<String> _bannerImages = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadBanners();

    // Auto-play timer (will start after banners load)
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted || _bannerImages.isEmpty) return;

      setState(() {
        _selectedIndex =
            _selectedIndex < _bannerImages.length - 1 ? _selectedIndex + 1 : 0;
      });

      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageUrls = await ApiService.getHeroBannerImageUrls();

      if (!mounted) return;

      setState(() {
        _bannerImages = imageUrls;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  // Rotate through the 4 styles
  Widget _buildBannerWidget(String imageUrl, int index) {
    final int styleIndex = index % 4;
    void press() {
      // TODO: Handle banner tap (e.g., navigate to offer page)
      debugPrint('Banner tapped: $imageUrl');
    }

    switch (styleIndex) {
      case 0:
        return BannerMStyle1(press: press, image: imageUrl);
      case 1:
        return BannerMStyle2(press: press, image: imageUrl);
      case 2:
        return BannerMStyle3(press: press, image: imageUrl);
      case 3:
        return BannerMStyle4(press: press, image: imageUrl);
      default:
        return BannerMStyle1(press: press, image: imageUrl);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
            maxHeight: 500,
          ),
          child: const AspectRatio(
            aspectRatio: 1.87,
            child: OffersSkelton(),
          ),
        ),
      );
    }
    if (_hasError || _bannerImages.isEmpty) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1200,
            maxHeight: 500, // SAME as success state
          ),
          child: AspectRatio(
            aspectRatio: 1.87,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No offers available',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton.icon(
                      onPressed: _loadBanners,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 500, // prevents banner from stretching on desktop
        ),
        child: AspectRatio(
          aspectRatio: 1.87,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _bannerImages.length,
                onPageChanged: (int index) {
                  if (mounted) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  }
                },
                itemBuilder: (context, index) =>
                    _buildBannerWidget(_bannerImages[index], index),
              ),
              Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: SizedBox(
                  height: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _bannerImages.length,
                      (index) => Padding(
                        padding:
                            const EdgeInsets.only(left: defaultPadding / 4),
                        child: DotIndicator(
                          isActive: index == _selectedIndex,
                          activeColor: whiteColor,
                          inActiveColor: whiteColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
