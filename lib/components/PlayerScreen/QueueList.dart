import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import '../AlbumImage.dart';
import '../../services/connectIfDisconnected.dart';
import '../../services/processArtist.dart';

class _QueueListStreamState {
  _QueueListStreamState({
    required this.queue,
    required this.shuffleIndicies,
  });

  final List<MediaItem>? queue;
  final dynamic shuffleIndicies;
}

class QueueList extends StatefulWidget {
  const QueueList({Key? key, required this.scrollController}) : super(key: key);

  final ScrollController scrollController;

  @override
  _QueueListState createState() => _QueueListState();
}

class _QueueListState extends State<QueueList> {
  Stream<_QueueListStreamState> _queueListStream =
      Rx.combineLatest2<List<MediaItem>?, dynamic, _QueueListStreamState>(
          AudioService.queueStream,
          // We turn this future into a stream because using rxdart is
          // easier than having nested StreamBuilders/FutureBuilders
          AudioService.customAction("getShuffleIndices").asStream(),
          (a, b) => _QueueListStreamState(queue: a, shuffleIndicies: b));

  List<MediaItem>? _queue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<_QueueListStreamState>(
      // stream: AudioService.queueStream,
      stream: _queueListStream,
      builder: (context, snapshot) {
        connectIfDisconnected();
        if (snapshot.hasData) {
          if (_queue == null) {
            _queue = snapshot.data!.queue;
          }
          return PrimaryScrollController(
            controller: widget.scrollController,
            child: ReorderableListView.builder(
              itemCount: snapshot.data!.queue?.length ?? 0,
              onReorder: (oldIndex, newIndex) async {
                setState(() {
                  // _queue?.insert(newIndex, _queue![oldIndex]);
                  // _queue?.removeAt(oldIndex);
                  int? smallerThanNewIndex;
                  if (oldIndex < newIndex) {
                    // When we're moving an item backwards, we need to reduce
                    // newIndex by 1 to account for there being a new item added
                    // before newIndex.
                    smallerThanNewIndex = newIndex - 1;
                  }
                  final item = _queue?.removeAt(oldIndex);
                  _queue?.insert(smallerThanNewIndex ?? newIndex, item!);
                });
                await AudioService.customAction("reorderQueue", {
                  "oldIndex": oldIndex,
                  "newIndex": newIndex,
                });
              },
              itemBuilder: (context, index) {
                final actualIndex = AudioService.playbackState.shuffleMode ==
                        AudioServiceShuffleMode.all
                    ? snapshot.data!.shuffleIndicies![index]
                    : index;
                return Dismissible(
                  key: ValueKey(snapshot.data!.queue![actualIndex].id),
                  onDismissed: (direction) async {
                    setState(() {
                      _queue?.removeAt(actualIndex);
                    });
                    await AudioService.customAction(
                        "removeQueueItem", actualIndex);
                  },
                  child: ListTile(
                    leading: AlbumImage(
                      itemId: _queue?[actualIndex].extras?["parentId"],
                    ),
                    title: Text(
                        snapshot.data!.queue?[actualIndex].title ??
                            "Unknown Name",
                        style: AudioService.currentMediaItem ==
                                snapshot.data!.queue?[actualIndex]
                            ? TextStyle(color: Theme.of(context).accentColor)
                            : null),
                    subtitle: Text(processArtist(
                        snapshot.data!.queue?[actualIndex].artist)),
                  ),
                );
              },
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
