import 'package:flutter/cupertino.dart';
import 'package:photo_view/photo_view.dart';
import 'package:podsquad/BackendDataclasses/IdentifiableImage.dart';

class MultiImagePageViewer extends StatefulWidget {
  const MultiImagePageViewer({Key? key, required this.imagesList, this.personName}) : super(key: key);
  final List<IdentifiableImage> imagesList;
  final String? personName;

  @override
  _MultiImagePageViewerState createState() =>
      _MultiImagePageViewerState(imagesList: imagesList, personName: personName);
}

class _MultiImagePageViewerState extends State<MultiImagePageViewer> {
  _MultiImagePageViewerState({required this.imagesList, this.personName});

  final List<IdentifiableImage> imagesList;
  final String? personName;

  final _controller = PageController();
  bool _showingCaption = true;

  /// Show of hide the image caption
  void toggleCaption() {
    setState(() {
      _showingCaption = !_showingCaption;
    });
  }

  @override
  void initState() {
    super.initState();
    imagesList.sort((a, b) => a.position.compareTo(b.position)); // put the images in order
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(personName != null ? "${personName ?? "User"}'s Photos" : "View Images"),
        ),
        child: PageView(
          controller: _controller,
          children: [
            if (imagesList.isNotEmpty)
              for (var identifiableImage in imagesList)
                SafeArea(
                    child: Stack(
                  children: [
                    // stack contains a loading indicator that will be covered by the image once it loads
                    Stack(
                      children: [
                        Center(
                          child: CupertinoActivityIndicator(),
                        ),
                        GestureDetector(
                          child: PhotoView(
                            imageProvider: NetworkImage(identifiableImage.imageURL),
                            minScale: 0.25,
                            maxScale: 2.0,
                          ),
                          onTap: toggleCaption,
                        )
                      ],
                    ),

                    // The image caption
                    if (identifiableImage.caption != null)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedSwitcher(
                            switchInCurve: Curves.ease,
                            switchOutCurve: Curves.ease,
                            duration: Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return SizeTransition(
                                sizeFactor: animation,
                                child: child,
                              );
                            },
                            child: _showingCaption
                                ? Padding(padding: EdgeInsets.all(10), child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: ClipRRect(
                                        child: Container(
                                          color: CupertinoColors.systemBackground.withOpacity(0.9),
                                          child: Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Text(identifiableImage.caption!),
                                          ),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),)
                                : Container()),
                      )
                  ],
                )),
            if (imagesList.isEmpty)
              Center(
                child: Text("${personName ?? "This user"} doesn't have any pictures yet!"),
              )
          ],
        ));
  }
}
