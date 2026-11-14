import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reservation_chat_univercity_project/core/utils/app_error.dart';
import 'package:reservation_chat_univercity_project/features/appointments/service/model/appointment_models.dart';
import 'package:reservation_chat_univercity_project/features/home/services/model/home_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/bloc/provider_services_bloc.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/screens/my_services_screen.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/model/provider_services_models.dart';
import 'package:reservation_chat_univercity_project/features/provider_services/service/provider_services_service.dart';

ProviderProfileModel _makeProfile({
  required String id,
  required String orgId,
  required String orgName,
  int slotDuration = 30,
  String title = 'متخصص قلب',
}) {
  return ProviderProfileModel.fromJson({
    'id': id,
    'user': {'id': 'u1', 'first_name': 'سارا', 'last_name': 'محمدی'},
    'organization': {'id': orgId, 'name': orgName, 'slug': 'clinic'},
    'title': title,
    'specialties': [
      {'id': 'cat-1', 'name': 'قلب و عروق', 'slug': 'cardiology'},
    ],
    'bio': 'بورد تخصصی',
    'default_slot_duration_minutes': slotDuration,
    'is_active': true,
  });
}

class _FakeProviderServicesService extends ProviderServicesService {
  List<ProviderProfileModel> profiles;
  List<MyOrganizationModel> ownedOrganizations;
  List<CategoryModel> categories;
  Map<String, List<ProviderOfferingModel>> offeringsByProvider;
  Map<String, List<WorkingHourModel>> workingHoursByProvider;
  Map<String, List<TimeOffModel>> timeOffsByProvider;
  Object? nextMutationError;

  _FakeProviderServicesService({
    required this.profiles,
    required this.ownedOrganizations,
    this.categories = const [],
    Map<String, List<ProviderOfferingModel>>? offeringsByProvider,
    Map<String, List<WorkingHourModel>>? workingHoursByProvider,
    Map<String, List<TimeOffModel>>? timeOffsByProvider,
  }) : offeringsByProvider = offeringsByProvider ?? {},
       workingHoursByProvider = workingHoursByProvider ?? {},
       timeOffsByProvider = timeOffsByProvider ?? {};

  @override
  Future<List<ProviderProfileModel>> getMyProviderProfiles() async => profiles;

  @override
  Future<List<MyOrganizationModel>> getMyOrganizations() async =>
      ownedOrganizations;

  @override
  Future<List<CategoryModel>> getCategories() async => categories;

  @override
  Future<List<ProviderOfferingModel>> getProviderOfferings(
    String providerId,
  ) async {
    return List.from(offeringsByProvider[providerId] ?? const []);
  }

  @override
  Future<List<WorkingHourModel>> getProviderWorkingHours(
    String providerId,
  ) async {
    final list = List<WorkingHourModel>.from(
      workingHoursByProvider[providerId] ?? const [],
    )..sort(WorkingHourModel.compareForSchedule);
    return list;
  }

  @override
  Future<List<TimeOffModel>> getProviderTimeOffs(String providerId) async {
    return List.from(timeOffsByProvider[providerId] ?? const []);
  }

  @override
  Future<ProviderOfferingModel> createOffering({
    required String organizationId,
    required String providerId,
    required OfferingFormPayload payload,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    return ProviderOfferingModel(
      id: 'off-new',
      organizationId: organizationId,
      organizationName: 'کلینیک مهر',
      providerId: providerId,
      title: payload.title,
      description: payload.description,
      visitMode: payload.visitMode,
      durationMinutes: payload.durationMinutes,
      bufferBeforeMinutes: payload.bufferBeforeMinutes,
      bufferAfterMinutes: payload.bufferAfterMinutes,
      priceValue: payload.price.toDouble(),
      priceFormatted: formatTomanPrice(payload.price),
      requiresApproval: payload.requiresApproval,
      isActive: payload.isActive,
    );
  }

  @override
  Future<ProviderOfferingModel> updateOffering({
    required String offeringId,
    required Map<String, dynamic> data,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    final all = offeringsByProvider.values.expand((x) => x);
    final existing = all.firstWhere((o) => o.id == offeringId);
    return ProviderOfferingModel(
      id: existing.id,
      organizationId: existing.organizationId,
      organizationName: existing.organizationName,
      providerId: existing.providerId,
      specialty: existing.specialty,
      title: (data['title'] as String?) ?? existing.title,
      description: (data['description'] as String?) ?? existing.description,
      visitMode: data['visit_mode'] != null
          ? VisitModeType.fromApi(data['visit_mode'].toString())
          : existing.visitMode,
      durationMinutes:
          (data['duration_minutes'] as int?) ?? existing.durationMinutes,
      bufferBeforeMinutes:
          (data['buffer_before_minutes'] as int?) ??
          existing.bufferBeforeMinutes,
      bufferAfterMinutes:
          (data['buffer_after_minutes'] as int?) ?? existing.bufferAfterMinutes,
      priceValue: data['price'] != null
          ? (data['price'] as num).toDouble()
          : existing.priceValue,
      priceFormatted: data['price'] != null
          ? formatTomanPrice(data['price'])
          : existing.priceFormatted,
      requiresApproval:
          (data['requires_approval'] as bool?) ?? existing.requiresApproval,
      isActive: (data['is_active'] as bool?) ?? existing.isActive,
    );
  }

  @override
  Future<WorkingHourModel> createWorkingHour({
    required String providerId,
    required int weekday,
    required String startTime,
    required String endTime,
    bool isActive = true,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    return WorkingHourModel(
      id: 'wh-new',
      providerId: providerId,
      weekday: weekday,
      weekdayDisplay: PersianWeekdays.nameOf(weekday),
      startTime: startTime,
      endTime: endTime,
      isActive: isActive,
    );
  }

  @override
  Future<WorkingHourModel> updateWorkingHour({
    required String workingHourId,
    required Map<String, dynamic> data,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    final existing = workingHoursByProvider.values
        .expand((x) => x)
        .firstWhere((w) => w.id == workingHourId);
    return WorkingHourModel(
      id: existing.id,
      providerId: existing.providerId,
      weekday: (data['weekday'] as int?) ?? existing.weekday,
      weekdayDisplay: existing.weekdayDisplay,
      startTime: (data['start_time'] as String?) ?? existing.startTime,
      endTime: (data['end_time'] as String?) ?? existing.endTime,
      isActive: (data['is_active'] as bool?) ?? existing.isActive,
    );
  }

  @override
  Future<TimeOffModel> createTimeOff({
    required String providerId,
    required DateTime startAt,
    required DateTime endAt,
    String reason = '',
    bool isActive = true,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    return TimeOffModel(
      id: 'to-new',
      providerId: providerId,
      startAt: startAt,
      endAt: endAt,
      reason: reason,
      isActive: isActive,
    );
  }

  @override
  Future<TimeOffModel> updateTimeOff({
    required String timeOffId,
    required Map<String, dynamic> data,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    final existing = timeOffsByProvider.values
        .expand((x) => x)
        .firstWhere((t) => t.id == timeOffId);
    return TimeOffModel(
      id: existing.id,
      providerId: existing.providerId,
      startAt: existing.startAt,
      endAt: existing.endAt,
      reason: (data['reason'] as String?) ?? existing.reason,
      isActive: (data['is_active'] as bool?) ?? existing.isActive,
    );
  }

  @override
  Future<ProviderProfileModel> updateProviderProfile({
    required String providerId,
    String? title,
    String? bio,
    int? defaultSlotDurationMinutes,
    List<String>? specialtyIds,
  }) async {
    if (nextMutationError != null) throw nextMutationError!;
    return _makeProfile(
      id: providerId,
      orgId: 'org-1',
      orgName: 'کلینیک مهر',
      slotDuration: defaultSlotDurationMinutes ?? 30,
      title: title ?? 'متخصص قلب',
    );
  }
}

void main() {
  group('ProviderServices models', () {
    test('parsePaginatedOrList handles both paginated maps and raw lists', () {
      final paginated = parsePaginatedOrList(
        {
          'count': 1,
          'results': [
            {'id': 'org-1', 'name': 'کلینیک شفا', 'slug': 'shafa'},
          ],
        },
        MyOrganizationModel.fromJson,
      );
      expect(paginated, hasLength(1));
      expect(paginated.first.name, 'کلینیک شفا');

      final raw = parsePaginatedOrList(
        [
          {'id': 'org-2', 'name': 'مطب نور', 'slug': 'noor'},
        ],
        MyOrganizationModel.fromJson,
      );
      expect(raw, hasLength(1));
      expect(raw.first.id, 'org-2');
    });

    test('flattenCategories deduplicates parent and nested child categories', () {
      final roots = [
        CategoryModel.fromJson({
          'id': 'c1',
          'name': 'داخلی',
          'slug': 'internal',
          'children': [
            {'id': 'c2', 'name': 'غدد', 'slug': 'endocrine'},
            {'id': 'c1', 'name': 'داخلی', 'slug': 'internal'},
          ],
        }),
      ];

      final flat = flattenCategories(roots);
      expect(flat.map((c) => c.id), ['c1', 'c2']);
    });

    test('OfferingFormPayload builds exact create and update JSON payloads', () {
      const payload = OfferingFormPayload(
        title: 'ویزیت تخصصی',
        description: 'معاینه کامل',
        visitMode: VisitModeType.onlineChat,
        specialtyId: 'cat-1',
        durationMinutes: 25,
        bufferBeforeMinutes: 5,
        bufferAfterMinutes: 5,
        price: 250000,
        requiresApproval: true,
        isActive: true,
      );

      final createJson = payload.toCreateJson(
        organizationId: 'org-1',
        providerId: 'prov-1',
      );
      expect(createJson['organization_id'], 'org-1');
      expect(createJson['provider_id'], 'prov-1');
      expect(createJson['visit_mode'], 'online_chat');
      expect(createJson['duration_minutes'], 25);
      expect(createJson['price'], 250000);

      final updateJson = payload.toUpdateJson();
      expect(updateJson.containsKey('organization_id'), isFalse);
      expect(updateJson.containsKey('provider_id'), isFalse);
      expect(updateJson['requires_approval'], isTrue);
    });

    test('WorkingHourModel orders Saturday..Friday and detects overlaps', () {
      final monday = WorkingHourModel.fromJson({
        'id': 'w1',
        'provider': {'id': 'p1'},
        'weekday': 0, // Monday (دوشنبه)
        'weekday_display': 'Monday',
        'start_time': '09:00:00',
        'end_time': '12:00:00',
        'is_active': true,
      });
      final saturday = WorkingHourModel.fromJson({
        'id': 'w2',
        'provider': {'id': 'p1'},
        'weekday': 5, // Saturday (شنبه)
        'weekday_display': 'Saturday',
        'start_time': '16:00:00',
        'end_time': '20:00:00',
        'is_active': true,
      });
      final inactiveSaturday = WorkingHourModel.fromJson({
        'id': 'w3',
        'provider': {'id': 'p1'},
        'weekday': 5,
        'weekday_display': 'Saturday',
        'start_time': '16:00:00',
        'end_time': '18:00:00',
        'is_active': false,
      });

      final sorted = [monday, saturday]..sort(WorkingHourModel.compareForSchedule);
      expect(sorted.map((w) => w.id), ['w2', 'w1']);
      expect(saturday.persianWeekdayName, 'شنبه');
      expect(monday.persianWeekdayName, 'دوشنبه');

      // Overlaps active Saturday 16:00-20:00
      expect(
        saturday.overlapsWith(
          candidateWeekday: 5,
          candidateStartMinutes: 19 * 60,
          candidateEndMinutes: 21 * 60,
        ),
        isTrue,
      );
      // Ignores self when editing
      expect(
        saturday.overlapsWith(
          candidateWeekday: 5,
          candidateStartMinutes: 16 * 60,
          candidateEndMinutes: 20 * 60,
          excludingId: 'w2',
        ),
        isFalse,
      );
      // Ignores inactive shifts
      expect(
        inactiveSaturday.overlapsWith(
          candidateWeekday: 5,
          candidateStartMinutes: 16 * 60,
          candidateEndMinutes: 18 * 60,
        ),
        isFalse,
      );
    });
  });

  group('ProviderServicesBloc', () {
    test('loads empty profile state when user has no provider profiles', () async {
      final fake = _FakeProviderServicesService(
        profiles: const [],
        ownedOrganizations: const [],
      );
      final bloc = ProviderServicesBloc(fake);
      addTearDown(bloc.close);

      bloc.add(LoadProviderServicesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProviderServicesLoading>(),
          isA<ProviderServicesEmptyProfile>(),
        ]),
      );
    });

    test('computes canManageOfferings per organization and supports switching clinics', () async {
      final profileOwned = _makeProfile(
        id: 'prov-1',
        orgId: 'org-owned',
        orgName: 'مطب شخصی',
      );
      final profileEmployee = _makeProfile(
        id: 'prov-2',
        orgId: 'org-other',
        orgName: 'بیمارستان مرکزی',
      );
      final fake = _FakeProviderServicesService(
        profiles: [profileOwned, profileEmployee],
        ownedOrganizations: const [
          MyOrganizationModel(id: 'org-owned', name: 'مطب شخصی', slug: 'own'),
        ],
        offeringsByProvider: {
          'prov-1': [
            const ProviderOfferingModel(
              id: 'off-1',
              organizationId: 'org-owned',
              organizationName: 'مطب شخصی',
              providerId: 'prov-1',
              title: 'ویزیت حضوری',
              description: '',
              visitMode: VisitModeType.inPerson,
              durationMinutes: 20,
              bufferBeforeMinutes: 0,
              bufferAfterMinutes: 0,
              priceValue: 180000,
              priceFormatted: '۱۸۰,۰۰۰',
              requiresApproval: false,
              isActive: true,
            ),
          ],
          'prov-2': const [],
        },
      );

      final bloc = ProviderServicesBloc(fake);
      addTearDown(bloc.close);

      bloc.add(LoadProviderServicesEvent());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProviderServicesLoading>(),
          isA<ProviderServicesLoaded>().having(
            (s) => s.data.canManageOfferings,
            'owned org canManageOfferings',
            isTrue,
          ),
        ]),
      );

      bloc.add(SelectProviderProfileEvent(providerId: 'prov-2'));
      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ProviderServiceActionLoading>(),
          isA<ProviderServicesLoaded>()
              .having((s) => s.data.selectedProfile.id, 'selectedId', 'prov-2')
              .having((s) => s.data.canManageOfferings, 'non-owned org', isFalse),
        ]),
      );
    });

    test('creates offering, toggles working hour, and preserves state on error', () async {
      final profile = _makeProfile(
        id: 'prov-1',
        orgId: 'org-1',
        orgName: 'کلینیک مهر',
      );
      final fake = _FakeProviderServicesService(
        profiles: [profile],
        ownedOrganizations: const [
          MyOrganizationModel(id: 'org-1', name: 'کلینیک مهر', slug: 'mehr'),
        ],
        categories: [
          CategoryModel.fromJson({
            'id': 'cat-1',
            'name': 'قلب و عروق',
            'slug': 'cardiology',
          }),
        ],
        workingHoursByProvider: {
          'prov-1': [
            const WorkingHourModel(
              id: 'wh-1',
              providerId: 'prov-1',
              weekday: 5,
              weekdayDisplay: 'Saturday',
              startTime: '09:00',
              endTime: '13:00',
              isActive: true,
            ),
          ],
        },
      );

      final bloc = ProviderServicesBloc(fake);
      addTearDown(bloc.close);

      bloc.add(LoadProviderServicesEvent());
      await bloc.stream.firstWhere((s) => s is ProviderServicesLoaded);

      bloc.add(
        CreateOfferingEvent(
          payload: const OfferingFormPayload(
            title: 'مشاوره آنلاین',
            visitMode: VisitModeType.onlineChat,
            durationMinutes: 15,
            price: 120000,
          ),
        ),
      );
      final afterCreate = await bloc.stream.firstWhere(
        (s) => s is ProviderServiceActionSuccess,
      ) as ProviderServiceActionSuccess;
      expect(afterCreate.data.offerings, hasLength(1));
      expect(afterCreate.data.offerings.first.title, 'مشاوره آنلاین');

      bloc.add(
        ToggleWorkingHourStatusEvent(
          workingHour: afterCreate.data.workingHours.first,
          isActive: false,
        ),
      );
      final afterToggle = await bloc.stream.firstWhere(
        (s) => s is ProviderServiceActionSuccess,
      ) as ProviderServiceActionSuccess;
      expect(afterToggle.data.workingHours.first.isActive, isFalse);

      // Simulate server error during next mutation and verify data is preserved.
      fake.nextMutationError = AppException(
        AppErrorCode.badRequest,
        serverMessage: 'ساعت کاری هم‌پوشانی دارد',
      );
      bloc.add(
        CreateWorkingHourEvent(
          weekday: 5,
          startTime: '10:00',
          endTime: '12:00',
        ),
      );
      final errState = await bloc.stream.firstWhere(
        (s) => s is ProviderServiceActionError,
      ) as ProviderServiceActionError;
      expect(errState.message, 'ساعت کاری هم‌پوشانی دارد');
      expect(errState.data.offerings, hasLength(1));
      expect(errState.data.workingHours, hasLength(1));
    });
  });

  group('MyServicesScreen widget', () {
    testWidgets('renders tabs and switches cleanly between offerings, working hours, and time-offs', (tester) async {
      final profile = _makeProfile(
        id: 'prov-1',
        orgId: 'org-1',
        orgName: 'کلینیک مهر',
      );
      final fake = _FakeProviderServicesService(
        profiles: [profile],
        ownedOrganizations: const [
          MyOrganizationModel(id: 'org-1', name: 'کلینیک مهر', slug: 'mehr'),
        ],
        offeringsByProvider: {
          'prov-1': [
            const ProviderOfferingModel(
              id: 'off-1',
              organizationId: 'org-1',
              organizationName: 'کلینیک مهر',
              providerId: 'prov-1',
              title: 'ویزیت تخصصی قلب',
              description: 'نوار قلب و معاینه',
              visitMode: VisitModeType.inPerson,
              durationMinutes: 30,
              bufferBeforeMinutes: 5,
              bufferAfterMinutes: 5,
              priceValue: 350000,
              priceFormatted: '۳۵۰,۰۰۰',
              requiresApproval: false,
              isActive: true,
            ),
          ],
        },
        workingHoursByProvider: {
          'prov-1': [
            const WorkingHourModel(
              id: 'wh-1',
              providerId: 'prov-1',
              weekday: 5,
              weekdayDisplay: 'Saturday',
              startTime: '09:00',
              endTime: '13:00',
              isActive: true,
            ),
          ],
        },
        timeOffsByProvider: {
          'prov-1': [
            TimeOffModel(
              id: 'to-1',
              providerId: 'prov-1',
              startAt: DateTime(2030, 5, 10, 9, 0),
              endAt: DateTime(2030, 5, 10, 14, 0),
              reason: 'همایش تخصصی',
              isActive: true,
            ),
          ],
        },
      );

      final bloc = ProviderServicesBloc(fake);
      addTearDown(bloc.close);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: MyServicesScreen(bloc: bloc),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('خدمات من'), findsOneWidget);
      expect(find.text('کلینیک مهر'), findsOneWidget);
      expect(find.text('ویزیت تخصصی قلب'), findsOneWidget);
      expect(find.text('خدمت جدید'), findsOneWidget);

      await tester.tap(find.text('ساعات کاری'));
      await tester.pumpAndSettle();
      expect(find.text('ساعات کاری هفتگی'), findsOneWidget);
      expect(find.text('۰۹:۰۰ الی ۱۳:۰۰'), findsOneWidget);

      await tester.tap(find.text('مرخصی‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('مرخصی‌ها و عدم حضور'), findsOneWidget);
      expect(find.textContaining('همایش تخصصی'), findsOneWidget);
    });
  });
}

