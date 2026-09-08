;; extends

; xdg.configFile."*.xml".text / xdg.dataFile."*.xml".text / home.file."*.xml".text
(binding
  attrpath: (attrpath
    (string_expression
      (string_fragment) @_path)
    .
    (identifier) @_attr)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "xml")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "xml")))
  ]
  (#eq? @_attr "text")
  (#lua-match? @_path "%.xml$")
  (#set! injection.combined))

; xdg.configFile."*.service".text (systemd units)
(binding
  attrpath: (attrpath
    (string_expression
      (string_fragment) @_path)
    .
    (identifier) @_attr)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "ini")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "ini")))
  ]
  (#eq? @_attr "text")
  (#lua-match? @_path "%.service$")
  (#set! injection.combined))

; home.file."*.reg".text (Windows registry exports; ini is the closest
; available grammar, not a perfect match)
(binding
  attrpath: (attrpath
    (string_expression
      (string_fragment) @_path)
    .
    (identifier) @_attr)
  expression: [
    (string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "ini")))
    (indented_string_expression
      ((string_fragment) @injection.content
        (#set! injection.language "ini")))
  ]
  (#eq? @_attr "text")
  (#lua-match? @_path "%.reg$")
  (#set! injection.combined))
