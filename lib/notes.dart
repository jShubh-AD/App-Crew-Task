import 'dart:developer';
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
  String searchQuery = '';

  final _searchCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();


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

          if(snapshot.hasError){
            log("Snapshot data: ${snapshot.data}", error: snapshot.error, stackTrace: snapshot.stackTrace);
            return const Center(child: Text('An error occurred'));
          }

          final allNotes = snapshot.data!.docs;
          log("Snapshot data: ${snapshot.data.toString()}", stackTrace: snapshot.stackTrace);

          final filteredNotes = allNotes.where((doc) {
            final title = (doc['title'] as String).toLowerCase();
            return title.contains(searchQuery);
          }).toList();

          if (filteredNotes.isEmpty) {
            return const Center(child: Text('No matching notes'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppTextField(
                    controller: _searchCtrl,
                    hintText: "Search",
                  onChanged: (q) {
                      setState(() {
                        searchQuery = _searchCtrl.text;
                      });
                  }
                ),
                Expanded(
                  child: ListView.builder(
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
        title: Text(note['title']),
        subtitle: Text(
          note['content'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.delete),
      ),
    );
  }

  void _openNoteSheet() {
    _titleCtrl.clear();
    _contentCtrl.clear();

    showModalBottomSheet(
      context: context,
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
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addNote,
                  child: const Text('Add Note'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addNote() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('notes').add({
      'title': _titleCtrl.text.trim(),
      'content': _contentCtrl.text.trim(),
      'user_id': uid,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }


}
