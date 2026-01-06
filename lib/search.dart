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
                filteredNotes = getFilteredNotes(widget.allNotes!, q.toLowerCase());
              })
            ), Expanded(
              child: ListView.builder(
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                return _confirmDelete(note);
              },
              child: Icon(Icons.delete),
            ),
            GestureDetector(
              onTap: () {
                return _openNoteSheet(note);
              },
              child: Icon(Icons.edit, color: Colors.blue,),
            ),
          ],
        ),
      ),
    );
  }

  // edit note call to firestore
  Future<void> _editNote(QueryDocumentSnapshot note) async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await note.reference.update({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  // add note UI
  void _openNoteSheet(QueryDocumentSnapshot note) {
      _titleCtrl.text = note['title'];
      _contentCtrl.text = note['content'];

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                textAlign: TextAlign.center,
                "Edit Note",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              AppTextField(controller: _titleCtrl, hintText: "Add Task Title"),
              const SizedBox(height: 12),
              AppTextField(
                controller: _contentCtrl,
                maxLines: 4,
                hintText: "Add Task Title",
              ),
              const SizedBox(height: 16),
              AppButton(
                onPressed: () {_editNote(note);},
                text: "Edit Note",
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // delete call to firestore with ui
  void _confirmDelete(QueryDocumentSnapshot note) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () async {
              await note.reference.delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
