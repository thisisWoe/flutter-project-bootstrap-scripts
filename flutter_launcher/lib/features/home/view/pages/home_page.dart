import 'package:flutter/material.dart';
import 'package:flutter_launcher/core/styles/app_colors.dart';
import 'package:flutter_launcher/core/styles/app_paddings.dart';
import 'package:flutter_launcher/core/styles/app_text_styles.dart';
import 'package:get/get.dart';

import 'package:flutter_launcher/features/home/view/controllers/home_controller.dart';
import 'package:flutter_launcher/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _accordionSurfaceColor = AppColors.darkOnSurfaceVariant;
  static const _accordionTextColor = AppColors.onPrimaryFixedVariant;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: LayoutBuilder(
          builder: (context, constraints) {
            final showTitle = constraints.maxWidth >= 220;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FlutterLogo(size: 28),
                if (showTitle) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      l10n.homeTitle,
                      style: AppTextStyles.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        backgroundColor: AppColors.flutterSky,
      ),
      backgroundColor: AppColors.surfaceTint,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppPaddings.xxl),
          child: Obx(() {
            final steps = <_HomeStepData>[
              _HomeStepData(
                title: l10n.homeStepProjectTitle,
                subtitle: l10n.homeStepProjectSubtitle,
                state: _stepState(
                  currentStep: controller.currentStep.value,
                  stepIndex: 0,
                  isValid:
                      controller.targetRootError.value == null &&
                      controller.targetRoot.isNotEmpty &&
                      controller.projectNameError.value == null &&
                      controller.appDisplayNameError.value == null &&
                      controller.organizationIdError.value == null &&
                      controller.projectName.isNotEmpty &&
                      controller.appDisplayName.isNotEmpty &&
                      controller.organizationId.isNotEmpty,
                  hasError:
                      controller.targetRootError.value != null ||
                      controller.projectNameError.value != null ||
                      controller.appDisplayNameError.value != null ||
                      controller.organizationIdError.value != null,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: controller.targetRootController,
                      onChanged: (_) => controller.targetRootError.value = null,
                      decoration: InputDecoration(
                        labelText: l10n.homeTargetRootLabel,
                        hintText: '/path/project',
                        helperText: l10n.homeTargetRootHelper,
                        errorText: _targetRootErrorText(
                          l10n,
                          controller.targetRootError.value,
                        ),
                        suffixIcon: IconButton(
                          onPressed: controller.pickTargetRoot,
                          icon: const Icon(
                            Icons.folder_open_outlined,
                            color: _accordionTextColor,
                          ),
                          tooltip: l10n.homeChooseFolderTooltip,
                        ),
                      ),
                      style: const TextStyle(color: _accordionTextColor),
                    ),
                    const SizedBox(height: AppPaddings.l),
                    TextField(
                      controller: controller.projectNameController,
                      onChanged: (_) =>
                          controller.projectNameError.value = null,
                      decoration: InputDecoration(
                        labelText: l10n.homeProjectNameLabel,
                        hintText: 'my_project',
                        helperText: l10n.homeProjectNameHelper,
                        errorText: _projectNameErrorText(
                          l10n,
                          controller.projectNameError.value,
                        ),
                      ),
                      style: const TextStyle(color: _accordionTextColor),
                    ),
                    const SizedBox(height: AppPaddings.l),
                    TextField(
                      controller: controller.appDisplayNameController,
                      onChanged: (_) =>
                          controller.appDisplayNameError.value = null,
                      decoration: InputDecoration(
                        labelText: l10n.homeAppDisplayNameLabel,
                        hintText: l10n.homeAppDisplayNameHint,
                        helperText: l10n.homeAppDisplayNameHelper,
                        errorText: _appDisplayNameErrorText(
                          l10n,
                          controller.appDisplayNameError.value,
                        ),
                      ),
                      style: const TextStyle(color: _accordionTextColor),
                    ),
                    const SizedBox(height: AppPaddings.l),
                    TextField(
                      controller: controller.organizationIdController,
                      onChanged: (_) =>
                          controller.organizationIdError.value = null,
                      decoration: InputDecoration(
                        labelText: l10n.homeOrganizationIdLabel,
                        hintText: l10n.homeOrganizationIdHint,
                        helperText: l10n.homeOrganizationIdHelper,
                        errorText: _organizationIdErrorText(
                          l10n,
                          controller.organizationIdError.value,
                        ),
                      ),
                      style: const TextStyle(color: _accordionTextColor),
                    ),
                  ],
                ),
              ),
              _HomeStepData(
                title: l10n.homeStepPlatformsTitle,
                subtitle: l10n.homeStepPlatformsSubtitle,
                state: _stepState(
                  currentStep: controller.currentStep.value,
                  stepIndex: 1,
                  isValid: controller.selectedPlatforms.isNotEmpty,
                  hasError: controller.platformsHasError.value,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppPaddings.s,
                      runSpacing: AppPaddings.s,
                      children: [
                        for (final platform
                            in HomeController.supportedPlatforms)
                          FilterChip(
                            label: Text(
                              platform,
                              style: TextStyle(
                                color:
                                    controller.selectedPlatforms.contains(
                                      platform,
                                    )
                                    ? AppColors.onPrimary
                                    : AppColors.surfaceTint,
                              ),
                            ),
                            selected: controller.selectedPlatforms.contains(
                              platform,
                            ),
                            onSelected: (selected) =>
                                controller.togglePlatform(platform, selected),
                            backgroundColor: AppColors.teal100,
                            selectedColor: AppColors.teal,
                            checkmarkColor: AppColors.onPrimary,
                            side: BorderSide(color: AppColors.teal100),
                          ),
                      ],
                    ),
                    if (controller.platformsHasError.value) ...[
                      const SizedBox(height: AppPaddings.s),
                      Text(
                        l10n.homePlatformsRequiredError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _HomeStepData(
                title: l10n.homeStepEnvironmentsTitle,
                subtitle: l10n.homeStepEnvironmentsSubtitle,
                state: _stepState(
                  currentStep: controller.currentStep.value,
                  stepIndex: 2,
                  isValid: controller.selectedEnvironments.length >= 2,
                  hasError: controller.environmentsHasError.value,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppPaddings.s,
                      runSpacing: AppPaddings.s,
                      children: [
                        for (final environment
                            in HomeController.defaultEnvironments)
                          FilterChip(
                            label: Text(
                              environment,
                              style: TextStyle(
                                color:
                                    controller.selectedEnvironments.contains(
                                      environment,
                                    )
                                    ? AppColors.onPrimary
                                    : AppColors.surfaceTint,
                              ),
                            ),
                            backgroundColor: AppColors.teal100,
                            disabledColor: AppColors.teal100,
                            selected: controller.selectedEnvironments.contains(
                              environment,
                            ),
                            onSelected: (selected) => controller
                                .toggleEnvironment(environment, selected),
                            selectedColor: AppColors.teal,
                            checkmarkColor: AppColors.onPrimary,
                            side: BorderSide(color: AppColors.teal100),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppPaddings.l),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller.customEnvironmentController,
                            decoration: InputDecoration(
                              labelText: l10n.homeCustomEnvironmentLabel,
                              hintText: l10n.homeCustomEnvironmentHint,
                            ),
                            onSubmitted: (_) =>
                                controller.addCustomEnvironment(),
                            style: const TextStyle(color: _accordionTextColor),
                          ),
                        ),
                        const SizedBox(width: AppPaddings.s),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.flutterSky,
                            foregroundColor: AppColors.onPrimary,
                          ),
                          onPressed: controller.addCustomEnvironment,
                          child: Text(l10n.homeAddEnvironment),
                        ),
                      ],
                    ),
                    if (controller.selectedEnvironments.isNotEmpty) ...[
                      const SizedBox(height: AppPaddings.l),
                      Wrap(
                        spacing: AppPaddings.s,
                        runSpacing: AppPaddings.s,
                        children: [
                          for (final environment
                              in controller.selectedEnvironments)
                            InputChip(
                              label: Text(
                                environment,
                                style: const TextStyle(
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              backgroundColor: AppColors.teal,
                              selectedColor: AppColors.teal,
                              onDeleted: () =>
                                  controller.removeEnvironment(environment),
                              deleteIconColor: AppColors.onPrimary,
                              side: BorderSide(color: AppColors.teal),
                            ),
                        ],
                      ),
                    ],
                    if (controller.environmentsHasError.value) ...[
                      const SizedBox(height: AppPaddings.s),
                      Text(
                        l10n.homeEnvironmentsRequiredError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _HomeStepData(
                title: l10n.homeStepRouterTitle,
                subtitle: l10n.homeStepRouterSubtitle,
                state: _stepState(
                  currentStep: controller.currentStep.value,
                  stepIndex: 3,
                  isValid: HomeController.routerShapes.contains(
                    controller.routerShape.value,
                  ),
                  hasError: controller.routerShapeHasError.value,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppPaddings.s,
                      children: [
                        for (final shape in HomeController.routerShapes)
                          ChoiceChip(
                            label: Text(
                              shape,
                              style: TextStyle(
                                color: controller.routerShape.value == shape
                                    ? AppColors.onPrimary
                                    : AppColors.surfaceTint,
                              ),
                            ),
                            backgroundColor: AppColors.teal100,
                            selected: controller.routerShape.value == shape,
                            onSelected: (_) => controller.setRouterShape(shape),
                            selectedColor: AppColors.teal,
                            side: BorderSide(color: AppColors.teal100),
                          ),
                      ],
                    ),
                    if (controller.routerShapeHasError.value) ...[
                      const SizedBox(height: AppPaddings.s),
                      Text(
                        l10n.homeRouterShapeRequiredError,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppPaddings.xxl),
                    Card(
                      color: _accordionSurfaceColor,
                      surfaceTintColor: _accordionSurfaceColor,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(AppPaddings.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.homeCollectedValuesTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: _accordionTextColor),
                            ),
                            const SizedBox(height: AppPaddings.s),
                            _SummaryRow(
                              label: 'target_root',
                              value:
                                  controller.collectedValues['target_root']
                                      as String? ??
                                  '',
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'project_name',
                              value:
                                  controller.collectedValues['project_name']
                                      as String? ??
                                  '',
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'app_display_name',
                              value:
                                  controller.collectedValues['app_display_name']
                                      as String? ??
                                  '',
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'organization_id',
                              value:
                                  controller.collectedValues['organization_id']
                                      as String? ??
                                  '',
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'target_platforms',
                              value:
                                  (controller.collectedValues['target_platforms']
                                          as List<String>)
                                      .join(', '),
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'environment_names',
                              value:
                                  (controller.collectedValues['environment_names']
                                          as List<String>)
                                      .join(', '),
                              color: _accordionTextColor,
                            ),
                            _SummaryRow(
                              label: 'router_shape',
                              value:
                                  controller.collectedValues['router_shape']
                                      as String? ??
                                  '',
                              color: _accordionTextColor,
                            ),
                            if (controller.isRunningBootstrap.value ||
                                controller.bootstrapSuccess.value != null ||
                                controller.bootstrapError.value != null ||
                                controller.bootstrapLogs.isNotEmpty) ...[
                              const SizedBox(height: AppPaddings.l),
                              if (controller.isRunningBootstrap.value)
                                const LinearProgressIndicator(
                                  color: AppColors.flutterSky,
                                ),
                              if (controller.bootstrapSuccess.value !=
                                  null) ...[
                                const SizedBox(height: AppPaddings.s),
                                Text(
                                  controller.bootstrapSuccess.value!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.teal100),
                                ),
                              ],
                              if (controller.bootstrapError.value != null) ...[
                                const SizedBox(height: AppPaddings.s),
                                Text(
                                  controller.bootstrapError.value!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppColors.tertiary),
                                ),
                              ],
                              if (controller.bootstrapLogs.isNotEmpty) ...[
                                const SizedBox(height: AppPaddings.l),
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    minHeight: 120,
                                    maxHeight: 260,
                                  ),
                                  padding: const EdgeInsets.all(AppPaddings.s),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceTint.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.onPrimaryFixedVariant
                                          .withValues(alpha: 0.24),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: SelectableText(
                                      controller.bootstrapLogs.join('\n'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: _accordionTextColor,
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];

            return ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                final isCurrent = controller.currentStep.value == index;

                return _VerticalStepItem(
                  index: index,
                  title: step.title,
                  subtitle: step.subtitle,
                  state: step.state,
                  isCurrent: isCurrent,
                  isFirst: index == 0,
                  isLast: index == steps.length - 1,
                  onTap: () => controller.goToStep(index),
                  content: isCurrent
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            step.content,
                            const SizedBox(height: AppPaddings.l),
                            _StepControls(
                              isLastStep: index == steps.length - 1,
                              canGoBack: index > 0,
                              isBusy: controller.isRunningBootstrap.value,
                              onContinue: index == steps.length - 1
                                  ? () {
                                      controller.submit();
                                    }
                                  : controller.continueStep,
                              onBack: controller.cancelStep,
                              continueLabel: l10n.homeContinue,
                              finishLabel: l10n.homeFinish,
                              backLabel: l10n.homeBack,
                            ),
                          ],
                        )
                      : null,
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

String? _targetRootErrorText(
  AppLocalizations l10n,
  TargetRootValidationError? error,
) {
  return switch (error) {
    null => null,
    TargetRootValidationError.notFound => l10n.homeTargetRootNotFoundError,
    TargetRootValidationError.notDirectory =>
      l10n.homeTargetRootNotDirectoryError,
    TargetRootValidationError.notResolvable =>
      l10n.homeTargetRootNotResolvableError,
    TargetRootValidationError.notAccessible =>
      l10n.homeTargetRootNotAccessibleError,
    TargetRootValidationError.unsafeFilesystemRoot =>
      l10n.homeTargetRootUnsafeFilesystemRootError,
    TargetRootValidationError.unsafeUserHome =>
      l10n.homeTargetRootUnsafeUserHomeError,
    TargetRootValidationError.unsafeHighLevelDirectory =>
      l10n.homeTargetRootUnsafeHighLevelDirectoryError,
    TargetRootValidationError.sameAsBootstrapRepository =>
      l10n.homeTargetRootSameAsBootstrapRepositoryError,
    TargetRootValidationError.existingFlutterProject =>
      l10n.homeTargetRootExistingFlutterProjectError,
    TargetRootValidationError.partialFlutterProject =>
      l10n.homeTargetRootPartialFlutterProjectError,
    TargetRootValidationError.unsupportedContents =>
      l10n.homeTargetRootUnsupportedContentsError,
    TargetRootValidationError.internalTemporaryDirectory =>
      l10n.homeTargetRootInternalTemporaryDirectoryError,
  };
}

String? _projectNameErrorText(
  AppLocalizations l10n,
  ProjectNameValidationError? error,
) {
  return switch (error) {
    null => null,
    ProjectNameValidationError.required => l10n.homeProjectNameRequiredError,
    ProjectNameValidationError.tooLong => l10n.homeProjectNameTooLongError,
    ProjectNameValidationError.invalidCharacters =>
      l10n.homeProjectNameInvalidCharactersError,
    ProjectNameValidationError.invalidDerivedFlutterName =>
      l10n.homeProjectNameInvalidDerivedFlutterNameError,
    ProjectNameValidationError.derivedStartsWithDigit =>
      l10n.homeProjectNameDerivedStartsWithDigitError,
    ProjectNameValidationError.invalidDerivedPlatformIdentifier =>
      l10n.homeProjectNameInvalidDerivedPlatformIdentifierError,
    ProjectNameValidationError.derivedTooWeak =>
      l10n.homeProjectNameDerivedTooWeakError,
    ProjectNameValidationError.derivedTooLong =>
      l10n.homeProjectNameDerivedTooLongError,
  };
}

String? _appDisplayNameErrorText(
  AppLocalizations l10n,
  AppDisplayNameValidationError? error,
) {
  return switch (error) {
    null => null,
    AppDisplayNameValidationError.required =>
      l10n.homeAppDisplayNameRequiredError,
    AppDisplayNameValidationError.tooLong =>
      l10n.homeAppDisplayNameTooLongError,
    AppDisplayNameValidationError.leadingOrTrailingWhitespace =>
      l10n.homeAppDisplayNameLeadingOrTrailingWhitespaceError,
    AppDisplayNameValidationError.containsNewline =>
      l10n.homeAppDisplayNameContainsNewlineError,
    AppDisplayNameValidationError.containsControlCharacter =>
      l10n.homeAppDisplayNameContainsControlCharacterError,
    AppDisplayNameValidationError.containsSingleQuote =>
      l10n.homeAppDisplayNameContainsSingleQuoteError,
    AppDisplayNameValidationError.containsBackslash =>
      l10n.homeAppDisplayNameContainsBackslashError,
    AppDisplayNameValidationError.noVisibleCharacter =>
      l10n.homeAppDisplayNameNoVisibleCharacterError,
  };
}

String? _organizationIdErrorText(
  AppLocalizations l10n,
  OrganizationIdValidationError? error,
) {
  return switch (error) {
    null => null,
    OrganizationIdValidationError.required =>
      l10n.homeOrganizationIdRequiredError,
    OrganizationIdValidationError.tooLong =>
      l10n.homeOrganizationIdTooLongError,
    OrganizationIdValidationError.leadingOrTrailingWhitespace =>
      l10n.homeOrganizationIdLeadingOrTrailingWhitespaceError,
    OrganizationIdValidationError.invalidFormat =>
      l10n.homeOrganizationIdInvalidFormatError,
  };
}

StepState _stepState({
  required int currentStep,
  required int stepIndex,
  required bool isValid,
  required bool hasError,
}) {
  if (hasError) {
    return StepState.error;
  }

  if (stepIndex < currentStep && isValid) {
    return StepState.complete;
  }

  return StepState.indexed;
}

class _HomeStepData {
  const _HomeStepData({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.content,
  });

  final String title;
  final String subtitle;
  final StepState state;
  final Widget content;
}

class _VerticalStepItem extends StatelessWidget {
  const _VerticalStepItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.isCurrent,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
    this.content,
  });

  final int index;
  final String title;
  final String subtitle;
  final StepState state;
  final bool isCurrent;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;
  final Widget? content;

  static const _railWidth = 32.0;
  static const _iconSize = 24.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isComplete = state == StepState.complete;
    final isActive = isCurrent || isComplete;
    final lineColor = isActive
        ? AppColors.flutterSky.withValues(alpha: 0.7)
        : colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppPaddings.xxl),
      child: Stack(
        children: [
          Positioned(
            left: (_railWidth - 1) / 2,
            top: isFirst ? _iconSize / 2 : 0,
            bottom: isLast ? null : 0,
            child: Container(
              width: 1,
              height: isLast ? _iconSize / 2 : null,
              color: lineColor,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _railWidth,
                child: Center(
                  child: _StepIcon(
                    index: index,
                    state: state,
                    isCurrent: isCurrent,
                  ),
                ),
              ),
              const SizedBox(width: AppPaddings.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppPaddings.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: content == null
                          ? const SizedBox.shrink()
                          : Card(
                              margin: const EdgeInsets.only(
                                top: AppPaddings.l,
                              ),
                              color: AppColors.darkOnSurfaceVariant,
                              surfaceTintColor: AppColors.darkOnSurfaceVariant,
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: InputDecorationTheme(
                                    labelStyle: const TextStyle(
                                      color: AppColors.onPrimaryFixedVariant,
                                    ),
                                    floatingLabelStyle: const TextStyle(
                                      color: AppColors.onPrimaryFixedVariant,
                                    ),
                                    hintStyle: TextStyle(
                                      color: AppColors.onPrimaryFixedVariant
                                          .withValues(alpha: 0.72),
                                    ),
                                    helperStyle: TextStyle(
                                      color: AppColors.onPrimaryFixedVariant
                                          .withValues(alpha: 0.72),
                                    ),
                                    errorStyle: const TextStyle(
                                      color: AppColors.tertiary,
                                    ),
                                    enabledBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.onPrimaryFixedVariant,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.flutterSky,
                                      ),
                                    ),
                                    errorBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                    focusedErrorBorder:
                                        const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: AppColors.tertiary,
                                          ),
                                        ),
                                  ),
                                  iconTheme: const IconThemeData(
                                    color: AppColors.onPrimaryFixedVariant,
                                  ),
                                ),
                                child: DefaultTextStyle.merge(
                                  style: const TextStyle(
                                    color: AppColors.onPrimaryFixedVariant,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      AppPaddings.l,
                                    ),
                                    child: content,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  const _StepIcon({
    required this.index,
    required this.state,
    required this.isCurrent,
  });

  final int index;
  final StepState state;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isComplete = state == StepState.complete;
    final isError = state == StepState.error;
    final backgroundColor = isError
        ? AppColors.tertiary
        : (isComplete || isCurrent
              ? AppColors.flutterSky
              : colorScheme.surfaceContainerHighest);
    final foregroundColor = isError || isComplete || isCurrent
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCurrent ? AppColors.flutterSky : colorScheme.outlineVariant,
        ),
      ),
      alignment: Alignment.center,
      child: switch (state) {
        StepState.complete => Icon(
          Icons.check,
          size: 16,
          color: foregroundColor,
        ),
        StepState.error => Icon(Icons.close, size: 16, color: foregroundColor),
        _ => Text(
          '${index + 1}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      },
    );
  }
}

class _StepControls extends StatelessWidget {
  const _StepControls({
    required this.isLastStep,
    required this.canGoBack,
    required this.isBusy,
    required this.onContinue,
    required this.onBack,
    required this.continueLabel,
    required this.finishLabel,
    required this.backLabel,
  });

  final bool isLastStep;
  final bool canGoBack;
  final bool isBusy;
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final String continueLabel;
  final String finishLabel;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppPaddings.s,
      runSpacing: AppPaddings.s,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.flutterSky,
            foregroundColor: AppColors.onPrimary,
          ),
          onPressed: isBusy ? null : onContinue,
          child: Text(isLastStep ? finishLabel : continueLabel),
        ),
        if (canGoBack)
          OutlinedButton(
            onPressed: isBusy ? null : onBack,
            child: Text(
              backLabel,
              style: TextStyle(color: AppColors.flutterSky),
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppPaddings.xs),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(fontWeight: FontWeight.w700, color: color),
            ),
            TextSpan(text: value.isEmpty ? '-' : value),
          ],
        ),
      ),
    );
  }
}
