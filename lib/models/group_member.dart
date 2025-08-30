class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final String role; // admin, member, viewer
  final DateTime joinedAt;
  final String? invitedBy;
  final String status; // active, pending, inactive
  final String? userEmail; // Para exibição na UI
  final String? userName; // Para exibição na UI

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
    required this.status,
    this.userEmail,
    this.userName,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupId: json['group_id'],
      userId: json['user_id'],
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      invitedBy: json['invited_by'],
      status: json['status'] ?? 'active',
      userEmail: json['user_email'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'invited_by': invitedBy,
      'status': status,
      'user_email': userEmail,
      'user_name': userName,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';
  bool get isViewer => role == 'viewer';
  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  GroupMember copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? invitedBy,
    String? status,
    String? userEmail,
    String? userName,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
    );
  }
}
