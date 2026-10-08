# Configura el proyecto de Xcode de la app para live_island:
#   - agrega el target "LiveIslandExtension" (Widget Extension) y lo incrusta en la app,
#   - copia el renderer SwiftUI (plantilla de ios/LiveIslandExtension del paquete),
#   - crea el App Group y los entitlements de la app y de la extensión,
#   - activa NSSupportsLiveActivities en la app.
# Es idempotente: se puede ejecutar de nuevo para actualizar el renderer.
#
# Uso: ruby setup_ios.rb <ios_dir> <plantilla> <app_group|-> <nombre_extension>
require 'fileutils'
require 'xcodeproj'

ios_dir, template_dir, group_arg, ext_name = ARGV
abort 'Uso: setup_ios.rb <ios_dir> <plantilla> <app_group|-> <extension>' unless ios_dir && template_dir && ext_name

proj_path = File.join(ios_dir, 'Runner.xcodeproj')
abort "No existe #{proj_path}" unless File.directory?(proj_path)
project = Xcodeproj::Project.open(proj_path)
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'No se encontró el target Runner.'

def setting(target, key)
  target.build_configurations.map { |c| c.build_settings[key] }.compact.first
end

bundle_id = setting(runner, 'PRODUCT_BUNDLE_IDENTIFIER') or abort 'Runner no tiene PRODUCT_BUNDLE_IDENTIFIER.'
app_group = (group_arg && group_arg != '-') ? group_arg : "group.#{bundle_id}.liveisland"
ext_bundle_id = "#{bundle_id}.#{ext_name}"
ext_dir = File.join(ios_dir, ext_name)

# --- 1. Archivos de la extensión -------------------------------------------
swift_sources = %w[Shared Renderer Widget].flat_map do |sub|
  src = File.join(template_dir, sub)
  dst = File.join(ext_dir, sub)
  FileUtils.mkdir_p(dst)
  Dir[File.join(src, '*.swift')].sort.map do |f|
    FileUtils.cp(f, File.join(dst, File.basename(f)))
    File.join(sub, File.basename(f))
  end
end

File.write(File.join(ext_dir, 'LEEME.md'), <<~MD)
  # #{ext_name}

  Generado por `dart run live_island:setup`. No lo edites: el diseño de las
  actividades se define en Dart y estos archivos se reemplazan al volver a
  ejecutar el comando (por ejemplo, tras actualizar el paquete).
MD

File.write(File.join(ext_dir, "#{ext_name}.xcconfig"), <<~XC)
  // Toma la versión de la app (Flutter) para que la extensión coincida.
  #include? "../Flutter/Generated.xcconfig"
  MARKETING_VERSION = $(FLUTTER_BUILD_NAME)
  CURRENT_PROJECT_VERSION = $(FLUTTER_BUILD_NUMBER)
XC

ext_info = {
  'CFBundleDevelopmentRegion' => '$(DEVELOPMENT_LANGUAGE)',
  'CFBundleDisplayName' => ext_name,
  'CFBundleExecutable' => '$(EXECUTABLE_NAME)',
  'CFBundleIdentifier' => '$(PRODUCT_BUNDLE_IDENTIFIER)',
  'CFBundleInfoDictionaryVersion' => '6.0',
  'CFBundleName' => '$(PRODUCT_NAME)',
  'CFBundlePackageType' => '$(PRODUCT_BUNDLE_PACKAGE_TYPE)',
  'CFBundleShortVersionString' => '$(MARKETING_VERSION)',
  'CFBundleVersion' => '$(CURRENT_PROJECT_VERSION)',
  'NSExtension' => { 'NSExtensionPointIdentifier' => 'com.apple.widgetkit-extension' },
  'NSSupportsLiveActivities' => true,
  'LiveIslandAppGroup' => app_group
}
Xcodeproj::Plist.write_to_path(ext_info, File.join(ext_dir, 'Info.plist'))

def write_entitlements(path, group)
  data = File.exist?(path) ? (Xcodeproj::Plist.read_from_path(path) || {}) : {}
  groups = Array(data['com.apple.security.application-groups'])
  groups << group unless groups.include?(group)
  data['com.apple.security.application-groups'] = groups
  FileUtils.mkdir_p(File.dirname(path))
  Xcodeproj::Plist.write_to_path(data, path)
end
write_entitlements(File.join(ext_dir, "#{ext_name}.entitlements"), app_group)
runner_ent_rel = setting(runner, 'CODE_SIGN_ENTITLEMENTS') || 'Runner/Runner.entitlements'
write_entitlements(File.join(ios_dir, runner_ent_rel), app_group)

# --- 2. Info.plist de la app ------------------------------------------------
runner_info_rel = setting(runner, 'INFOPLIST_FILE') || 'Runner/Info.plist'
runner_info_path = File.join(ios_dir, runner_info_rel)
info = Xcodeproj::Plist.read_from_path(runner_info_path)
info['NSSupportsLiveActivities'] = true
info['LiveIslandAppGroup'] = app_group
Xcodeproj::Plist.write_to_path(info, runner_info_path)

# --- 3. Proyecto de Xcode ---------------------------------------------------
def group_for(project, name, path)
  g = project.main_group[name] || project.main_group.new_group(name, path)
  g.set_path(path)
  g
end

main_group = group_for(project, ext_name, ext_name)

def file_ref(group, rel)
  parts = rel.split('/')
  g = group
  parts[0..-2].each { |p| g = g[p] || g.new_group(p, p) }
  g.files.find { |f| f.path == parts.last } || g.new_file(parts.last)
end

ext_target = project.targets.find { |t| t.name == ext_name }
created = ext_target.nil?
if created
  ext_target = project.new_target(:app_extension, ext_name, :ios, '16.1', project.products_group, :swift)
end

# Archivos fuente
existing = ext_target.source_build_phase.files_references.map(&:path)
swift_sources.each do |rel|
  ref = file_ref(main_group, rel)
  ext_target.add_file_references([ref]) unless existing.include?(ref.path) || ext_target.source_build_phase.files_references.include?(ref)
end
plist_ref = file_ref(main_group, 'Info.plist')
ent_ref = file_ref(main_group, "#{ext_name}.entitlements")
xc_ref = file_ref(main_group, "#{ext_name}.xcconfig")
file_ref(main_group, 'LEEME.md')

%w[SwiftUI WidgetKit ActivityKit].each do |fw|
  next if ext_target.frameworks_build_phase.files_references.any? { |r| r.path.to_s.include?("#{fw}.framework") }
  ext_target.add_system_framework(fw)
end

team = setting(runner, 'DEVELOPMENT_TEAM')
ext_target.build_configurations.each do |config|
  s = config.build_settings
  config.base_configuration_reference = xc_ref
  s['PRODUCT_BUNDLE_IDENTIFIER'] = ext_bundle_id
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = "#{ext_name}/Info.plist"
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = "#{ext_name}/#{ext_name}.entitlements"
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
  s['SWIFT_VERSION'] = '5.0'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['CODE_SIGN_STYLE'] = setting(runner, 'CODE_SIGN_STYLE') || 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
end

# La app firma con los entitlements y puede ser incrustada la extensión.
runner.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] ||= runner_ent_rel
end
runner_group = project.main_group['Runner']
file_ref(runner_group, File.basename(runner_ent_rel)) if runner_group && runner_ent_rel.start_with?('Runner/')

unless runner.dependencies.any? { |d| d.target == ext_target }
  runner.add_dependency(ext_target)
end

embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' }
unless embed
  embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
  embed.symbol_dst_subfolder_spec = :plug_ins
end
unless embed.files_references.include?(ext_target.product_reference)
  bf = embed.add_file_reference(ext_target.product_reference, true)
  bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Evita el ciclo de dependencias "Cycle inside Runner": la fase que incrusta
# la extensión debe ir antes de "Thin Binary" y de "Run Script".
phases = runner.build_phases
embed_idx = phases.index(embed)
first_script = phases.index { |p| p.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) &&
                                  ['Run Script', 'Thin Binary'].include?(p.name) }
if first_script && embed_idx && embed_idx > first_script
  phases.delete(embed)
  phases.insert(first_script, embed)
end

project.save

puts "  Extensión:  #{ext_name} (#{ext_bundle_id})"
puts "  App Group:  #{app_group}"
puts "  Target #{created ? 'creado' : 'actualizado'}; renderer copiado en #{ext_dir}"
