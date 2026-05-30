import '../dummy_data/dummy_data.dart';
import '../models/user_profile.dart';

class UserProfileService {
  Future<UserProfile> getCurrentUserProfile() async {
    return DummyData.userProfile;
  }
}
