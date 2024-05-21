import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "main.dart";
import "backend.dart";

class DiscussionPage extends StatefulWidget {
    final int datapointId;

    const DiscussionPage(this.datapointId, {super.key});

    @override
    State<DiscussionPage> createState() => _DiscussionPageState(datapointId);
}

class _DiscussionPageState extends State<DiscussionPage> {
    int datapointId;

    _DiscussionPageState(this.datapointId);

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                if (snapshot.hasError) throw snapshot.error!;
                return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(value: null)
                ));
            }
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        Widget? bottomSheet = null;

        if (await Backend().isLoggedIn(ScaffoldMessenger.of(context))) {
            bottomSheet = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    const TextField(
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Write your comment..."
                        ),
                        maxLines: null
                    ),
                    ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom( 
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(2))),
                            minimumSize: const Size.fromHeight(60)
                        ),
                        child: const Text("Submit"),
                    )
                ]
            );
        }

        return Scaffold(
            body: DefaultTabController(
                length: 2,
                child: Scaffold(
                    appBar: AppBar(
                        title: const Text("Comments")
                    ),
                    body: Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Scrollbar(
                            child: SingleChildScrollView(
                                physics: const ScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                child: Column(
                                    children: [
                                        SingleChildScrollView(
                                            physics: const ScrollPhysics(),
                                            scrollDirection: Axis.vertical,
                                            child: CommentList(datapointId)
                                        )
                                    ]
                                )
                            )
                        )
                    ),
                    bottomSheet: bottomSheet
                ),
            ),
        );
    }
}

class CommentList extends StatefulWidget {
    final int datapointId;
    const CommentList(this.datapointId, {super.key});

    @override
    State<CommentList> createState() => _CommentListState(datapointId);
}

class _CommentListState extends State<CommentList> {
    int datapointId;

    _CommentListState(this.datapointId);
    
    @override
    Widget build(BuildContext context) {
        return FutureBuilder<Widget>(
            future: asyncBuild(context),
            builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                if (snapshot.hasData) return snapshot.data!;
                if (snapshot.hasError) throw snapshot.error!;
                return const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(child: CircularProgressIndicator(value: null)
                ));
            }
        );
    }

    Future<Widget> asyncBuild(BuildContext context) async {
        final commentElems = <Widget>[];

        final comments = await Backend().retrieveAllComments(ScaffoldMessenger.of(context), datapointId);
        if (comments == null) return const Text("Error: couldn't retrieve comments");
        for (final comment in comments) {
            String username = "[Deleted account]";
            final submitterData = await Backend().userData(ScaffoldMessenger.of(context), comment.submitterId);
            if (submitterData != null) {
                username = submitterData.username;
            }

            commentElems.add(ListTile(
                leading: const Icon(Icons.account_circle),
                title: Text(username),
                subtitle: Text(comment.content)
            ));
        }

        return Column(children: [
            ListView(physics: NeverScrollableScrollPhysics(), shrinkWrap: true, children: commentElems)
        ]);
    }
}
