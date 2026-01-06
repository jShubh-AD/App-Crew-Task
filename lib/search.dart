import 'package:appcrew_task/widgets/custom_button.dart';
import 'package:appcrew_task/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchNotes extends StatefulWidget {
  final List<QueryDocumentSnapshot<Object?>>? allNotes;
  const SearchNotes({super.key, required this.allNotes});

  @override
  State<SearchNotes> createState() => _SearchNotesState();
}

class _SearchNotesState extends State<SearchNotes> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  late List<QueryDocumentSnapshot>? filteredNotes;

  @override
  void initState(){
    super.initState();
    filteredNotes = widget.allNotes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Search Notes'),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppTextField(
              controller: _searchCtrl,
              hintText: "Search",
              onChanged: (q) => setState(() {
                if(widget.allNotes != null){
                  filteredNotes = getFilteredNotes(widget.allNotes!, q.toLowerCase());
                }
              })
            ), Expanded(
              child: filteredNotes == null || filteredNotes!.isEmpty
                  ? const Center(child: Text('No Notes available'))
                  : ListView.builder(
                itemCount: filteredNotes!.length,
                itemBuilder: (context, index) {
                  final note = filteredNotes![index];
                  return _noteTile(note);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // method for getting filter notes
  List<QueryDocumentSnapshot> getFilteredNotes(
      List<QueryDocumentSnapshot> allNotes,
      String searchQuery,
      ) {
    final query = searchQuery.toLowerCase().trim();

    if (query.isEmpty) return allNotes;

    return allNotes.where((doc) {
      final title = (doc['title'] as String).toLowerCase();
      return title.contains(query);
    }).toList();
  }

  Widget _noteTile(QueryDocumentSnapshot note) {
    Timestamp? createdTs = note['created_at'];
    Timestamp? updatedTs = note['updated_at'];

    DateTime createdAt = createdTs?.toDate() ?? DateTime.now();
    DateTime? updatedAt = updatedTs?.toDate();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: note['isCompleted'],
          onChanged: (v) async {
            await note.reference.update({
              'isCompleted': v,
              'updated_at': FieldValue.serverTimestamp(),
            });
          },
        ),
        title: Text(
          note['title'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: note['isCompleted'] ? Colors.grey : Colors.black,
            decoration: note['isCompleted']
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // txt for discription
            Text(
              note['content'],
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: note['isCompleted'] ? Colors.grey : Colors.black,
                decoration: note['isCompleted']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            // txt for time stamp
            Text(
              updatedAt == null
                  ? 'Created at: ${formatDate(createdAt)}'
                  : 'Updated at: ${formatDate(updatedAt)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: note['isCompleted'] ? Colors.grey : Colors.black,
                decoration: note['isCompleted']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ],
        ),

      ),
    );
  }
  String formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
