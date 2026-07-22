; Aerial symbol outline for Dockerfiles.
; Shows build stages (FROM) and major instructions (RUN, COPY, ENV, etc.).

; Build stages: FROM <image> [AS <alias>]
(from_instruction
  (image_spec
    name: (image_name) @name)
  (#set! "kind" "Module")) @symbol

; RUN -- first shell fragment as name
(run_instruction
  (shell_command
    (shell_fragment) @name)
  (#set! "kind" "Method")) @symbol

; COPY / ADD -- first path as name
(copy_instruction
  (path) @name
  (#set! "kind" "Method")) @symbol

(add_instruction
  (path) @name
  (#set! "kind" "Method")) @symbol

; WORKDIR -- path as name
(workdir_instruction
  (path) @name
  (#set! "kind" "Method")) @symbol

; ENV -- first pair key as name
(env_instruction
  (env_pair
    name: (unquoted_string) @name)
  (#set! "kind" "Method")) @symbol

; ARG -- name field
(arg_instruction
  name: (unquoted_string) @name
  (#set! "kind" "Method")) @symbol

; LABEL -- key field
(label_instruction
  (label_pair
    key: [(double_quoted_string) (single_quoted_string) (unquoted_string)] @name)
  (#set! "kind" "Method")) @symbol
