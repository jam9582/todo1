#!/usr/bin/env ruby
# iOS WidgetKit Extension 타겟을 Xcode 프로젝트에 추가하는 스크립트.
# CocoaPods 내장 xcodeproj gem을 사용합니다.
# 사용법: GEM_HOME=... ruby add_widget_target.rb

require 'xcodeproj'
require 'fileutils'

PROJECT_PATH   = File.expand_path('../Runner.xcodeproj', __FILE__)
WIDGET_DIR     = File.expand_path('../TimerWidget', __FILE__)
BUNDLE_ID_APP  = 'com.studiovanilla.tinylog'
BUNDLE_ID_EXT  = 'com.studiovanilla.tinylog.TimerWidget'
TEAM_ID        = '5489HYLR4U'
DEPLOY_TARGET  = '14.0'
EXT_NAME       = 'TimerWidget'

project = Xcodeproj::Project.open(PROJECT_PATH)

# 이미 타겟이 존재하면 스킵
if project.targets.any? { |t| t.name == EXT_NAME }
  puts "✓ '#{EXT_NAME}' 타겟이 이미 존재합니다. 스킵."
  exit 0
end

# ─── 1. 위젯 Extension 타겟 생성 ──────────────────────────────────────────
ext_target = project.new_target(
  :app_extension,
  EXT_NAME,
  :ios,
  DEPLOY_TARGET,
  project.products_group
)
puts "✓ 타겟 '#{EXT_NAME}' 생성"

# ─── 2. 빌드 설정 구성 ────────────────────────────────────────────────────
ext_target.build_configurations.each do |config|
  s = config.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER']       = BUNDLE_ID_EXT
  s['DEVELOPMENT_TEAM']                = TEAM_ID
  s['SWIFT_VERSION']                   = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET']      = DEPLOY_TARGET
  s['INFOPLIST_FILE']                  = "#{EXT_NAME}/Info.plist"
  s['CODE_SIGN_ENTITLEMENTS']          = "#{EXT_NAME}/#{EXT_NAME}.entitlements"
  s['TARGETED_DEVICE_FAMILY']          = '1,2'
  s['SKIP_INSTALL']                    = 'YES'
  s['GENERATE_INFOPLIST_FILE']         = 'NO'
  s['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
  s['CLANG_ENABLE_MODULES']            = 'YES'
  s['SWIFT_EMIT_LOC_STRINGS']          = 'YES'
end
puts "✓ 빌드 설정 구성"

# ─── 3. Widget Extension 그룹 생성 및 소스 파일 추가 ──────────────────────
widget_group = project.main_group.new_group(EXT_NAME, "#{EXT_NAME}/")

swift_files = Dir.glob(File.join(WIDGET_DIR, '*.swift'))
source_files = []
swift_files.each do |path|
  fname = File.basename(path)
  file_ref = widget_group.new_file(fname)
  source_files << file_ref
  puts "  + #{fname}"
end

# Info.plist 파일 참조 (소스 컴파일 제외, 리소스로 추가)
plist_ref = widget_group.new_file('Info.plist')

# Entitlements
ent_ref = widget_group.new_file("#{EXT_NAME}.entitlements")

# Sources Build Phase
sources_phase = ext_target.source_build_phase
source_files.each { |f| sources_phase.add_file_reference(f) }
puts "✓ Swift 소스 파일 #{source_files.length}개 추가"

# Resources Build Phase (Info.plist 제외 — INFOPLIST_FILE로 처리)
# (Swift 파일 외 리소스가 있다면 여기에 추가)

# ─── 4. WidgetKit + SwiftUI 프레임워크 링크 ───────────────────────────────
frameworks_phase = ext_target.frameworks_build_phase
def find_or_create_framework(project, name)
  frameworks_group = project.main_group['Frameworks'] ||
                     project.main_group.new_group('Frameworks')
  existing = frameworks_group.files.find { |f| f.path&.include?(name) }
  return existing if existing

  ref = frameworks_group.new_file("System/Library/Frameworks/#{name}.framework")
  ref.last_known_file_type = 'wrapper.framework'
  ref.source_tree = 'SDKROOT'
  ref
end

['WidgetKit.framework', 'SwiftUI.framework', 'AppIntents.framework'].each do |fw|
  fw_ref = find_or_create_framework(project, fw.sub('.framework', ''))
  frameworks_phase.add_file_reference(fw_ref)
  puts "  + #{fw}"
end
puts "✓ 프레임워크 추가"

# ─── 5. Runner 타겟에 Embed App Extensions Build Phase 추가 ───────────────
runner_target = project.targets.find { |t| t.name == 'Runner' }
raise "Runner 타겟을 찾을 수 없습니다!" unless runner_target

# Embed App Extensions phase 찾기 또는 생성
embed_phase = runner_target.build_phases.find { |p|
  p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) &&
  p.name == 'Embed Foundation Extensions'
}
unless embed_phase
  embed_phase = runner_target.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.dst_subfolder_spec = '13' # PlugIns
  embed_phase.dst_path = ''
end

# 위젯 Extension 제품 참조 가져오기
ext_product = ext_target.product_reference
build_file = embed_phase.add_file_reference(ext_product)
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy', 'CodeSignOnCopy'] }
puts "✓ Runner에 Embed App Extensions 추가"

# ─── 6. Runner 타겟 의존성 추가 ───────────────────────────────────────────
runner_target.add_dependency(ext_target)
puts "✓ Runner → TimerWidget 의존성 추가"

# ─── 7. Runner 빌드 설정에 Entitlements 추가 ──────────────────────────────
runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= 'Runner/Runner.entitlements'
end
puts "✓ Runner entitlements 설정"

# ─── 8. 저장 ──────────────────────────────────────────────────────────────
project.save
puts "\n✅ project.pbxproj 저장 완료!"
puts "다음 단계: ios/ 에서 pod install 실행"
