import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/dropdown.dart';
import '../bloc/profile_bloc.dart';

class PetBreedRow extends StatelessWidget {
  const PetBreedRow({
    super.key,
    required this.selectedPet,
    required this.selectedBreeds,
    required this.onPetSelected,
    required this.onBreedSelected,
  });

  final String? selectedPet;
  final String? selectedBreeds;
  final ValueChanged<String> onPetSelected;
  final ValueChanged<String> onBreedSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "pet_type".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 9.h),
              BlocBuilder<ProfileBloc, ProfileState>(
                buildWhen: (previous, current) =>
                    current is GetPetsLoading ||
                    current is GetPetsSuccess ||
                    current is GetPetsError,
                builder: (context, state) {
                  final isLoading = state is GetPetsLoading;
                  final isError = state is GetPetsError;
                  final errorText = isError ? '' : null;

                  final List<FilterModel> petOptions = state is GetPetsSuccess
                      ? state.pets
                            .asMap()
                            .entries
                            .map((e) {
                              final idx = e.key;
                              final pet = e.value;
                              return FilterModel(
                                name: pet.name,
                                code: idx,
                                id: pet.id,
                              );
                            })
                            .toList(growable: false)
                      : const <FilterModel>[];

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 58.h),
                      child: DropdownWidget(
                        isEnabled:
                            state is GetPetsSuccess && petOptions.isNotEmpty,
                        isLoading: isLoading,
                        defaultTitle: selectedPet,
                        loadingText: 'in_loading'.tr(),
                        retryLabel: 'retry'.tr(),
                        errorText: errorText,
                        onRetry: isError
                            ? () => BlocProvider.of<ProfileBloc>(
                                context,
                              ).add(GetPetsEvent())
                            : null,
                        hintText: "sample_type_race".tr(),
                        dataList: petOptions,
                        validator: (int? value) =>
                            value == null ? 'required.pet_type'.tr() : null,
                        onChanged: (selected) {
                          if (selected == null) return;
                          onPetSelected(selected.name);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "pet_race".tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 9.h),
              BlocBuilder<ProfileBloc, ProfileState>(
                buildWhen: (previous, current) =>
                    current is GetBreedsLoading ||
                    current is GetBreedsSuccess ||
                    current is GetBreedsError,
                builder: (context, state) {
                  final isLoading = state is GetBreedsLoading;
                  final isError = state is GetBreedsError;
                  final errorText = isError ? '' : null;

                  final List<FilterModel> breedsOptions =
                      state is GetBreedsSuccess
                      ? state.pets
                            .asMap()
                            .entries
                            .map((e) {
                              final idx = e.key;
                              final pet = e.value;
                              return FilterModel(
                                name: pet.name,
                                code: idx,
                                id: pet.id,
                              );
                            })
                            .toList(growable: false)
                      : const <FilterModel>[];

                  return AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 58.h),
                      child: DropdownWidget(
                        isEnabled:
                            state is GetBreedsSuccess &&
                            breedsOptions.isNotEmpty,
                        isLoading: isLoading,
                        defaultTitle: selectedBreeds,
                        loadingText: 'in_loading'.tr(),
                        retryLabel: 'retry'.tr(),
                        errorText: errorText,
                        onRetry: isError
                            ? () => BlocProvider.of<ProfileBloc>(
                                context,
                              ).add(GetBreedsEvent(pet: selectedPet ?? ''))
                            : null,
                        hintText: "sample_pet_race".tr(),
                        dataList: breedsOptions,
                        validator: (int? value) =>
                            value == null ? 'required.pet_race'.tr() : null,
                        onChanged: (selected) {
                          if (selected == null) return;
                          onBreedSelected(selected.name);
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
