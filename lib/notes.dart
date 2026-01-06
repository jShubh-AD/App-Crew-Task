import 'dart:developer';

import 'package:appcrew_task/search.dart';
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
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool isAddingTask = false;

  List<QueryDocumentSnapshot<Object?>>? allNotes;

  @override
  void dispose(){
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Notes'),
        backgroundColor: Colors.grey.shade100,
        surfaceTintColor: Colors.transparent,
        actions: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchNotes(allNotes: allNotes),
                    ),
                  );
                },
              ),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openNoteSheet(false, null);
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

          allNotes = snapshot.data!.docs;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: allNotes == null || allNotes!.isEmpty
                ? const Center(child: Text('No Notes available'))
                : ListView.builder(
                    itemCount: allNotes!.length,
                    itemBuilder: (context, index) {
                      final note = allNotes![index];
                      return _noteTile(note);
                    },
                  ),
          );
        },
      ),
    );
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
                return _openNoteSheet(true,note);
              },
              child: Icon(Icons.edit, color: Colors.blue,),
            ),
          ],
        ),
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
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () async {
              await note.reference.delete();
              setState(() {});
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // add note UI
  void _openNoteSheet(bool isEdit, QueryDocumentSnapshot? note) {

    if(isEdit && note != null){
      _titleCtrl.text = note['title'];
      _contentCtrl.text = note['content'];
    }
    else{
      _titleCtrl.clear();
      _contentCtrl.clear();
    }

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
                isEdit? "Edit Note" :"Add Note",
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
                loading: isAddingTask,
                onPressed: () {
                  if(isEdit && note != null){
                    _editNote(note);
                  }else{
                    _addNote();
                  }},
                text: isEdit ? "Edit Note" :'Add Note',
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
    setState(() {});
    if (mounted) Navigator.pop(context);
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
    setState(() {});
    if (mounted) Navigator.pop(context);
  }

  String formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}
