import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';
import 'package:rnd_mobile/firebase/firestore.dart';
import 'package:rnd_mobile/widgets/toast.dart';

class WebAdmin extends StatefulWidget {
  const WebAdmin({super.key});

  @override
  State<WebAdmin> createState() => _WebAdminState();
}

class _WebAdminState extends State<WebAdmin> {
  final TextEditingController _addUsernameController = TextEditingController();
  final TextEditingController _addGroupController = TextEditingController();
  final TextEditingController _removeUsernameController =
      TextEditingController();
  final TextEditingController _removeGroupController = TextEditingController();
  final TextEditingController _searchGroupController = TextEditingController();
  final TextEditingController _searchUsernameController =
      TextEditingController();
  String? _addUsernameErrorText;
  String? _addGroupErrorText;
  String? _removeUsernameErrorText;
  String? _removeGroupErrorText;
  bool isAdding = false;
  bool isRemoving = false;
  late Future<dynamic> future;
  Map<String, List<String>> groupToUsernames = {};
  Map<String, List<String>> usernameToGroups = {};

  @override
  void initState() {
    super.initState();
    future = FirestoreService().read(collection: 'groups');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: maxHeight / 3,
                child: Column(
                  children: [
                    //2 input, 1 for username, 1 for group
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: maxHeight / 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'ADD USERNAME TO A GROUP',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: TextField(
                                            controller: _addUsernameController,
                                            decoration: InputDecoration(
                                              labelText: 'Username',
                                              labelStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.red),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorText: _addUsernameErrorText,
                                              suffixIcon: Visibility(
                                                visible: _addUsernameController
                                                    .text.isNotEmpty,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 25),
                                                  onPressed: () {
                                                    setState(() {
                                                      _addUsernameController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_addUsernameErrorText !=
                                                  null) {
                                                setState(() {
                                                  _addUsernameErrorText = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: TextField(
                                            controller: _addGroupController,
                                            decoration: InputDecoration(
                                              labelText: 'Group',
                                              labelStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.red),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorText: _addGroupErrorText,
                                              suffixIcon: Visibility(
                                                visible: _addGroupController
                                                    .text.isNotEmpty,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 25),
                                                  onPressed: () {
                                                    setState(() {
                                                      _addGroupController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_addGroupErrorText != null) {
                                                setState(() {
                                                  _addGroupErrorText = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor: const Color(0xFF795FCD),
                                      backgroundColor: Colors.blueGrey,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        isAdding = false;
                                      });
                                      bool proceed = true;

                                      String group = _addGroupController.text;
                                      String username =
                                          _addUsernameController.text;
                                      if (group == '') {
                                        _addGroupErrorText = 'Group is empty';
                                        proceed = false;
                                      }
                                      if (username == '') {
                                        _addUsernameErrorText =
                                            'Username is empty';
                                        proceed = false;
                                      }
                                      if (groupToUsernames[group] != null) {
                                        if (groupToUsernames[group]!
                                            .contains(username)) {
                                          // The key and value already exist, do not add the value again
                                          showToastMessage(
                                              'Username $username is already in $group group');
                                          proceed = false;
                                        }
                                      }

                                      if (proceed) {
                                        _addGroupErrorText = null;
                                        _addUsernameErrorText = null;
                                        bool createFlag =
                                            await FirestoreService().create(
                                                collection: 'groups',
                                                documentId: group,
                                                data: {username: true});
                                        if (createFlag) {
                                          if (!groupToUsernames
                                              .containsKey(group)) {
                                            groupToUsernames[group] = [];
                                          }
                                          if (!usernameToGroups
                                              .containsKey(username)) {
                                            usernameToGroups[username] = [];
                                          }
                                          groupToUsernames[group]!
                                              .add(username);
                                          usernameToGroups[username]!
                                              .add(group);
                                          showToastMessage(
                                              'Username $username added to $group group');
                                        } else {
                                          showToastMessage(
                                              'Something went wrong with writing to database');
                                        }

                                        _addGroupController.clear();
                                        _addUsernameController.clear();
                                      }

                                      setState(() {
                                        isAdding = false;
                                      });
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      width: 100,
                                      child: Center(
                                        child: isAdding
                                            ? const CircularProgressIndicator()
                                            : const Text('ADD',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 50),
                            child: VerticalDivider(),
                          ),
                          Expanded(
                            child: SizedBox(
                              height: maxHeight / 3,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'REMOVE USERNAME FROM A GROUP',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: TextField(
                                            controller:
                                                _removeUsernameController,
                                            decoration: InputDecoration(
                                              labelText: 'Username',
                                              labelStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.red),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorText:
                                                  _removeUsernameErrorText,
                                              suffixIcon: Visibility(
                                                visible:
                                                    _removeUsernameController
                                                        .text.isNotEmpty,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 25),
                                                  onPressed: () {
                                                    setState(() {
                                                      _removeUsernameController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_removeUsernameErrorText !=
                                                  null) {
                                                setState(() {
                                                  _removeUsernameErrorText =
                                                      null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 15),
                                          child: TextField(
                                            controller: _removeGroupController,
                                            decoration: InputDecoration(
                                              labelText: 'Group',
                                              labelStyle: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.red),
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              errorText: _removeGroupErrorText,
                                              suffixIcon: Visibility(
                                                visible: _removeGroupController
                                                    .text.isNotEmpty,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      size: 25),
                                                  onPressed: () {
                                                    setState(() {
                                                      _removeGroupController
                                                          .clear();
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {});
                                            },
                                            onTap: () {
                                              if (_removeGroupErrorText !=
                                                  null) {
                                                setState(() {
                                                  _removeGroupErrorText = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      // backgroundColor: const Color(0xFF795FCD),
                                      backgroundColor: Colors.blueGrey,
                                      shape: RoundedRectangleBorder(
                                        side: const BorderSide(
                                            color: Colors.grey),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () async {
                                      setState(() {
                                        isRemoving = true;
                                      });

                                      bool proceed = true;
                                      String group =
                                          _removeGroupController.text;
                                      String username =
                                          _removeUsernameController.text;
                                      if (group.isEmpty) {
                                        _removeGroupErrorText =
                                            'Group is empty';
                                        proceed = false;
                                      }
                                      if (username.isEmpty) {
                                        _removeUsernameErrorText =
                                            'Username is empty';
                                        proceed = false;
                                      }
                                      if (proceed) {
                                        _removeGroupErrorText = null;
                                        _removeUsernameErrorText = null;
                                        if (!groupToUsernames
                                            .containsKey(group)) {
                                          showToastMessage(
                                              '$group group does not exist');
                                          return;
                                        }

                                        if (!usernameToGroups
                                            .containsKey(username)) {
                                          showToastMessage(
                                              '$username username does not exist');
                                          return;
                                        }
                                        if (!usernameToGroups[username]!
                                            .contains(group)) {
                                          showToastMessage(
                                              'Username $username is not in $group group');
                                          return;
                                        }
                                        usernameToGroups[username]!
                                            .remove(group);
                                        groupToUsernames[group]!
                                            .remove(username);
                                        if (usernameToGroups[username]!
                                            .isEmpty) {
                                          usernameToGroups.remove(username);
                                        }
                                        await FirestoreService().deleteField(
                                            collection: 'groups',
                                            documentId: group,
                                            field: username);
                                        showToastMessage(
                                            'Username $username removed from $group group');

                                        _removeGroupController.clear();
                                        _removeUsernameController.clear();
                                      }
                                      setState(() {
                                        isRemoving = false;
                                      });
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      width: 100,
                                      child: Center(
                                        child: isRemoving
                                            ? const CircularProgressIndicator()
                                            : const Text('REMOVE',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    //add button
                  ],
                ),
              ),
              // const Divider(),
              Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey,
                        width: 0.5,
                      ),
                    ),
                  ),
                  height: maxHeight * 2 / 3,
                  child: FutureBuilder(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(child: Text('An error occurred'));
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        // Data is not yet available, display a loading indicator
                        return const Center(child: CircularProgressIndicator());
                      } else {
                        if (groupToUsernames.isEmpty &&
                            usernameToGroups.isEmpty) {
                          Map<String, Map<String, dynamic>> documentData = {};
                          List<DocumentSnapshot> documents = snapshot.data.docs;
                          for (DocumentSnapshot document in documents) {
                            String documentId = document.id;
                            Map<String, dynamic> data =
                                document.data() as Map<String, dynamic>;
                            documentData[documentId] = data;
                          }

                          documentData.forEach((group, users) {
                            groupToUsernames[group] = [];
                            users.forEach((username, value) {
                              if (groupToUsernames[group] != null) {
                                groupToUsernames[group]?.add(username);
                              }
                              if (!usernameToGroups.containsKey(username)) {
                                usernameToGroups[username] = [];
                              }
                              if (usernameToGroups[username] != null) {
                                usernameToGroups[username]?.add(group);
                              }
                            });
                          });
                        }
                        return SizedBox(
                          height: maxHeight * 2 / 3,
                          child: IntrinsicHeight(
                            child: Row(children: [
                              //groups
                              Expanded(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 35),
                                    const Text(
                                      'GROUPS',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 30),
                                    ),
                                    const SizedBox(
                                      height: 15,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 150),
                                      child: TextField(
                                        controller: _searchGroupController,
                                        style: const TextStyle(fontSize: 12),
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.zero,
                                          hintText: 'Search',
                                          hintStyle:
                                              const TextStyle(fontSize: 12),
                                          prefixIcon: const Icon(Icons.search),
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(30.0)),
                                          ),
                                          suffixIcon: Visibility(
                                            visible: _searchGroupController
                                                .text.isNotEmpty,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 25),
                                              onPressed: () {
                                                setState(() {
                                                  _searchGroupController
                                                      .clear();
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        onChanged: (value) {
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          50, 10, 50, 0),
                                      child: SizedBox(
                                        height: (maxHeight * 2 / 3) - 150,
                                        child: ListView.builder(
                                          itemCount: groupToUsernames.keys
                                              .where((group) => group
                                                  .toLowerCase()
                                                  .contains(
                                                      _searchGroupController
                                                          .text
                                                          .toLowerCase()))
                                              .length,
                                          itemBuilder: (context, index) {
                                            String group = groupToUsernames.keys
                                                .where((group) => group
                                                    .toLowerCase()
                                                    .contains(
                                                        _searchGroupController
                                                            .text
                                                            .toLowerCase()))
                                                .elementAt(index);
                                            final groupLength =
                                                groupToUsernames[group]!.length;
                                            final peopleText = groupLength > 1
                                                ? 'people'
                                                : 'person';
                                            return ExpansionTile(
                                              textColor: Colors.white,
                                              iconColor: Colors.white,
                                              collapsedTextColor: Colors.grey,
                                              collapsedIconColor: Colors.grey,
                                              leading: const Icon(Icons.group),
                                              title: Text(group),
                                              subtitle: Text(
                                                  '$groupLength $peopleText'),
                                              children: [
                                                SizedBox(
                                                  height: 120,
                                                  child: ListView.builder(
                                                    itemCount:
                                                        groupToUsernames[group]!
                                                            .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      return ListTile(
                                                        leading: const Icon(Icons
                                                            .person_outline),
                                                        title: Text(
                                                            groupToUsernames[
                                                                group]![index]),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 50),
                                child: VerticalDivider(),
                              ),
                              //users
                              Expanded(
                                child: Column(children: [
                                  const SizedBox(height: 35),
                                  const Text(
                                    'USERNAMES',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 30),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 150),
                                    child: TextField(
                                      controller: _searchUsernameController,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.zero,
                                        hintText: 'Search',
                                        hintStyle:
                                            const TextStyle(fontSize: 12),
                                        prefixIcon: const Icon(Icons.search),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(30.0)),
                                        ),
                                        suffixIcon: Visibility(
                                          visible: _searchUsernameController
                                              .text.isNotEmpty,
                                          child: IconButton(
                                            icon: const Icon(Icons.close,
                                                size: 25),
                                            onPressed: () {
                                              setState(() {
                                                _searchUsernameController
                                                    .clear();
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        50, 10, 50, 0),
                                    child: SizedBox(
                                      height: (maxHeight * 2 / 3) - 150,
                                      child: ListView.builder(
                                        itemCount: usernameToGroups.keys
                                            .where((username) => username
                                                .toLowerCase()
                                                .contains(
                                                    _searchUsernameController
                                                        .text
                                                        .toLowerCase()))
                                            .length,
                                        itemBuilder: (context, index) {
                                          String username = usernameToGroups
                                              .keys
                                              .where((username) => username
                                                  .toLowerCase()
                                                  .contains(
                                                      _searchUsernameController
                                                          .text
                                                          .toLowerCase()))
                                              .elementAt(index);
                                          final usernameGroupsLength =
                                              usernameToGroups[username]!
                                                  .length;
                                          final groupText =
                                              usernameGroupsLength > 1
                                                  ? 'groups'
                                                  : 'group';
                                          return ExpansionTile(
                                            textColor: Colors.white,
                                            iconColor: Colors.white,
                                            collapsedTextColor: Colors.grey,
                                            collapsedIconColor: Colors.grey,
                                            leading: const Icon(Icons.person),
                                            title: Text(username),
                                            subtitle: Text(
                                                '$usernameGroupsLength $groupText'),
                                            children: [
                                              SizedBox(
                                                height: 120,
                                                child: ListView.builder(
                                                  itemCount: usernameToGroups[
                                                          username]!
                                                      .length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    return ListTile(
                                                      leading: const Icon(
                                                          Icons.group_outlined),
                                                      title: Text(
                                                          usernameToGroups[
                                                                  username]![
                                                              index]),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ]),
                              ),
                            ]),
                          ),
                        );
                      }
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
