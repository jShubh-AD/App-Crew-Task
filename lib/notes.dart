import 'dart:developer';
import 'package:appcrew_task/widgets/custom_button.dart';
import 'package:appcrew_task/widgets/custom_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'auth.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool isAddingTask = false;

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Auth()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openNoteSheet();
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('user_id', isEqualTo: uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            log("Snapshot data: ${snapshot.data} ");
            return const Center(child: Text('No notes yet'));
          }

          if (snapshot.hasError) {
            log(
              "Snapshot data: ${snapshot.data}",
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
            );
            return const Center(child: Text('An error occurred'));
          }

          final allNotes = snapshot.data!.docs;
          log(
            "Snapshot data: ${snapshot.data.toString()}",
            stackTrace: snapshot.stackTrace,
          );

          String searchQuery = _searchCtrl.text.toLowerCase();

          final filteredNotes = allNotes.where((doc) {
            final title = (doc['title'] as String).toLowerCase();
            return searchQuery.isEmpty || title.contains(searchQuery);
          }).toList();


          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                  controller: _searchCtrl,
                  hintText: "Search",
                  onChanged: (_){},
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: filteredNotes.isEmpty
                      ? const Center(child: Text('No matching notes'))
                      : ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      return _noteTile(note);
                    },
                  ),
                ),
              ],
            ),
          );

        },
      ),
    );
  }

  Widget _noteTile(QueryDocumentSnapshot note) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
            value: note['isCompleted'],
            onChanged: (v) async{
              await note.reference.update({
                'isCompleted': v,
                'updated_at': FieldValue.serverTimestamp(),
              });
            }
        ),
        title: Text(
            note['title'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: note['isCompleted'] ? Colors.grey : Colors.black,
              decoration: note['isCompleted'] ? TextDecoration.lineThrough : TextDecoration.none
          ),
        ),
        subtitle: Text(
          note['content'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: note['isCompleted'] ? Colors.grey : Colors.black,
              decoration: note['isCompleted'] ? TextDecoration.lineThrough : TextDecoration.none
          ),
        ),
        trailing: IconButton(icon :const Icon(Icons.delete), onPressed: (){ return _confirmDelete(note); },),
      ),
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
            child: const Text('Cancel',style: TextStyle(color: Colors.blue),),
          ),
          TextButton(
            onPressed: () async {
              await note.reference.delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete',),
          ),
        ],
      ),
    );
  }


  // add note UI
  void _openNoteSheet() {
    _titleCtrl.clear();
    _contentCtrl.clear();

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
              const SizedBox(height: 16,),
              Text(
                textAlign: TextAlign.center,
                "Add Task",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700
                ),
              ),
              const SizedBox(height: 16,),
              AppTextField(
                controller: _titleCtrl,
                hintText: "Add Task Title",
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _contentCtrl,
                hintText: "Add Task Title",
              ),
              const SizedBox(height: 16),
              AppButton(
                loading: isAddingTask,
                onPressed: _addNote,
                text: 'Add Note',
              ),
              const SizedBox(height: 16,)
            ],
          ),
        );
      },
    );
  }

  // add note call to firestore
  Future<void> _addNote() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('notes').add({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'isCompleted': false,
      'user_id': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': null,
    });

    if (mounted) Navigator.pop(context);
  }
}
