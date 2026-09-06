# google_mobile_ads pulls play-services-ads-api, which pulls
# androidx.work:work-runtime:2.7.0, which pulls androidx.room:room-runtime:2.2.5.
# Room 2.2.5 ships this consumer rule, with no member spec:
#
#     -keep class * extends androidx.room.RoomDatabase
#
# Under R8 full mode that keeps WorkDatabase_Impl but removes its default
# constructor -- dexdump on the 1.5.26+73 bundle showed "Direct methods -" for
# androidx.work.impl.WorkDatabase_Impl. Room instantiates the class through
# Class.newInstance(), which then throws InstantiationException, so every
# release build dies before the first frame:
#
#     FATAL EXCEPTION: main
#     Unable to get provider androidx.startup.InitializationProvider:
#       Failed to create an instance of androidx.work.impl.WorkDatabase
#
-keep class * extends androidx.room.RoomDatabase { <init>(); }
