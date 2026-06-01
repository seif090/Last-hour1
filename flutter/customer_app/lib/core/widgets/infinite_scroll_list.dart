import 'package:flutter/material.dart';

class InfiniteScrollList extends StatefulWidget {
  final bool isLoading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final Widget Function(int index) itemBuilder;
  final int itemCount;
  final EdgeInsets? padding;

  const InfiniteScrollList({
    super.key,
    required this.isLoading,
    required this.hasMore,
    required this.onLoadMore,
    required this.itemBuilder,
    required this.itemCount,
    this.padding,
  });

  @override
  State<InfiniteScrollList> createState() => _InfiniteScrollListState();
}

class _InfiniteScrollListState extends State<InfiniteScrollList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoading && widget.hasMore) {
        widget.onLoadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.only(bottom: 80),
      itemCount: widget.itemCount + (widget.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.itemCount) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.itemBuilder(index);
      },
    );
  }
}
