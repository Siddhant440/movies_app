import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movieApp/data/media_category.dart';
import 'package:movieApp/models/app_user_model.dart';
import 'package:movieApp/providers/sync_service_provider.dart';
import 'package:movieApp/providers/user_providers.dart';
import 'package:movieApp/screens/matches_page.dart';
import 'package:movieApp/screens/user/add_user_page.dart';
import 'package:movieApp/screens/media_list_screen.dart';
import 'package:movieApp/screens/user/user_details_screen.dart';
import 'package:movieApp/theme/app_colors.dart';
import 'package:movieApp/theme/app_fonts.dart';
import 'package:movieApp/utils/responsive.dart';
import 'package:movieApp/widgets/shimmer_loading.dart';

class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _scrollController = ScrollController();
  bool _syncListenerRegistered = false;

  @override
  void initState() {
    super.initState();
    ref.read(syncServiceProvider);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(usersProvider.notifier).fetchNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_syncListenerRegistered) {
      _syncListenerRegistered = true;
      ref.listen<AsyncValue<bool>>(isSyncingProvider, (previous, next) {
        final wasSyncing =
            previous?.maybeWhen(data: (value) => value, orElse: () => false) ??
                false;
        final isSyncing = next.maybeWhen(
          data: (value) => value,
          orElse: () => false,
        );

        if (wasSyncing && !isSyncing && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Sync complete'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(milliseconds: 1500),
              ),
            );
          });
        }
      });
    }

    final state = ref.watch(usersProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Who's watching?", style: AppFonts.title(context)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Matches icon button - top right corner
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: AppColors.textPrimary,
              size: h(context) * 0.028,
            ),
            tooltip: 'View Matches',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MatchesPage()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              Expanded(
                child: state.users.isEmpty && state.isLoading
                    ? const UsersListSkeleton()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            ref.read(usersProvider.notifier).fetchNextPage(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.fromLTRB(
                            w(context) * 0.032,
                            h(context) * 0.02,
                            w(context) * 0.032,
                            h(context) * 0.1, // extra padding at bottom for FAB
                          ),
                          itemCount: state.users.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.users.length) {
                              return const UserTileSkeleton();
                            }
                            final user = state.users[index];
                            return _UserTile(user: user);
                          },
                        ),
                      ),
              ),
            ],
          ),

          // Floating Action Button positioned with Stack
          Positioned(
            bottom: h(context) * 0.03,
            right: w(context) * 0.06,
            child: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddUserPage()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 8,
              shape: const CircleBorder(),
              child: Icon(
                Icons.person_add_rounded,
                size: h(context) * 0.028,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _UserTile remains unchanged
class _UserTile extends ConsumerWidget {
  final AppUser user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSyncing = ref
        .watch(isSyncingProvider)
        .maybeWhen(data: (syncing) => syncing, orElse: () => false);

    final showCloudAsync = ref.watch(showCloudIconProvider(user.localId));
    final showCloud = showCloudAsync.maybeWhen(
      data: (show) => show,
      orElse: () => false,
    );

    return Container(
      margin: EdgeInsets.only(bottom: h(context) * 0.012),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(w(context) * 0.032),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: w(context) * 0.04,
          vertical: h(context) * 0.012,
        ),
        leading: CircleAvatar(
          radius: h(context) * 0.03,
          backgroundColor: Colors.grey,
          backgroundImage: user.avatar.isNotEmpty
              ? CachedNetworkImageProvider(user.avatar)
              : null,
          child: user.avatar.isEmpty
              ? Icon(Icons.person, size: h(context) * 0.03, color: Colors.black)
              : null,
        ),
        title: Text(user.fullName, style: AppFonts.emphasis(context)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.movieTaste, style: AppFonts.caption(context)),
            SizedBox(height: h(context) * 0.004),
            Text(
              '${user.savedCount} movie${user.savedCount == 1 ? '' : 's'} saved'
              '${!user.isSynced ? ' · pending sync' : ''}',
              style: AppFonts.caption(context).copyWith(
                color: user.isSynced
                    ? AppColors.textSecondary
                    : AppColors.pendingSync,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSyncing)
              Padding(
                padding: EdgeInsets.only(right: w(context) * 0.016),
                child: const PulsingDotsIndicator(color: Colors.white70),
              )
            else if (showCloud)
              Padding(
                padding: EdgeInsets.only(right: w(context) * 0.016),
                child: Icon(
                  Icons.cloud_off,
                  size: h(context) * 0.022,
                  color: AppColors.pendingSync,
                ),
              ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserDetailsScreen(user: user),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(w(context) * 0.022),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_horiz,
                  size: h(context) * 0.025,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MediaListScreen(
              category: MediaCategory.trendingMovies,
              user: user,
            ),
          ),
        ),
      ),
    );
  }
}