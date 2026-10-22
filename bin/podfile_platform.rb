# Sube la plataforma del Podfile de la app a la que pide live_island_kit.
#
# La plantilla de Flutter deja `# platform :ios, '12.0'` comentado, y entonces
# CocoaPods asume iOS 12 y rechaza el plugin: «requires a higher minimum iOS
# deployment version». Devuelve :raised (se cambió), :ok (ya era suficiente) o
# :missing (no hay Podfile: por ejemplo, un proyecto solo con Swift Package Manager).

PLATFORM_LINE = /^[ \t]*(#[ \t]*)?platform[ \t]+:ios[ \t]*,[ \t]*['"]([\d.]+)['"].*$/

def version_at_least?(have, want)
  (Gem::Version.new(have) rescue Gem::Version.new('0')) >= Gem::Version.new(want)
end

def raise_podfile_platform(path, minimum = '15.0')
  return :missing unless File.exist?(path)
  text = File.read(path)
  line = "platform :ios, '#{minimum}'"
  m = text.match(PLATFORM_LINE)
  if m
    return :ok if m[1].nil? && version_at_least?(m[2], minimum)
    File.write(path, text.sub(PLATFORM_LINE, line))
  else
    File.write(path, "#{line}\n\n#{text}")
  end
  :raised
end
