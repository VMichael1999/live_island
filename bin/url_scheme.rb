# Registra un esquema de URL en el Info.plist de la app (CFBundleURLTypes), para
# que tocar una actividad con `deepLink: 'miapp://pedido/42'` abra la app.
# Devuelve true si cambió algo.

def add_url_scheme!(info, scheme)
  types = (info['CFBundleURLTypes'] ||= [])
  return false if types.any? { |t| (t['CFBundleURLSchemes'] || []).include?(scheme) }
  types << { 'CFBundleURLName' => scheme, 'CFBundleURLSchemes' => [scheme] }
  true
end
