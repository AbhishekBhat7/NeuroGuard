class UserProfile {
  final int id;
  final String patientName;
  final String patientAge;
  final String patientLocation;
  final String patientGender;
  final String patientPhone;
  final String caretakerEmail;
  final String caretakerName;
  final String caretakerPhone;
  final String caretakerGender;

  const UserProfile({
    this.id = 1,
    required this.patientName,
    required this.patientAge,
    required this.patientLocation,
    required this.patientGender,
    required this.patientPhone,
    required this.caretakerEmail,
    required this.caretakerName,
    required this.caretakerPhone,
    required this.caretakerGender,
  });

  factory UserProfile.defaultProfile() {
    return const UserProfile(
      id: 1,
      patientName: 'Rahul',
      patientAge: '24',
      patientLocation: '#24, Room 1, Manipal',
      patientGender: 'Male',
      patientPhone: '9876543210',
      caretakerEmail: 'caretaker@gmail.com',
      caretakerName: 'Dr. Anita Sharma',
      caretakerPhone: '9123456780',
      caretakerGender: 'Female',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientLocation': patientLocation,
      'patientGender': patientGender,
      'patientPhone': patientPhone,
      'caretakerEmail': caretakerEmail,
      'caretakerName': caretakerName,
      'caretakerPhone': caretakerPhone,
      'caretakerGender': caretakerGender,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int? ?? 1,
      patientName: map['patientName'] as String? ?? 'Rahul',
      patientAge: map['patientAge'] as String? ?? '24',
      patientLocation: map['patientLocation'] as String? ?? '#24, Room 1, Manipal',
      patientGender: map['patientGender'] as String? ?? 'Male',
      patientPhone: map['patientPhone'] as String? ?? '9876543210',
      caretakerEmail: map['caretakerEmail'] as String? ?? 'caretaker@gmail.com',
      caretakerName: map['caretakerName'] as String? ?? 'Caretaker',
      caretakerPhone: map['caretakerPhone'] as String? ?? '9123456780',
      caretakerGender: map['caretakerGender'] as String? ?? 'Female',
    );
  }

  UserProfile copyWith({
    int? id,
    String? patientName,
    String? patientAge,
    String? patientLocation,
    String? patientGender,
    String? patientPhone,
    String? caretakerEmail,
    String? caretakerName,
    String? caretakerPhone,
    String? caretakerGender,
  }) {
    return UserProfile(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientAge: patientAge ?? this.patientAge,
      patientLocation: patientLocation ?? this.patientLocation,
      patientGender: patientGender ?? this.patientGender,
      patientPhone: patientPhone ?? this.patientPhone,
      caretakerEmail: caretakerEmail ?? this.caretakerEmail,
      caretakerName: caretakerName ?? this.caretakerName,
      caretakerPhone: caretakerPhone ?? this.caretakerPhone,
      caretakerGender: caretakerGender ?? this.caretakerGender,
    );
  }
}

