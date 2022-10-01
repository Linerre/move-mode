;;; move-mode.el --- A major-mode for editing Move language -*- lexical-binding: t; -*-

;; Copyright (c) 2022 Ashok Menon

;; Author: Ashok Menon
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.1"))
;; Keywords: languages

;;; License:

;; This file is distributed under the terms of the Apache License
;; (version 2.0).

;;; Commentary:

;; This package implements a major-mode for editing smart contracts
;; written in Move.

;;; Code:



;;; Customization

(defgroup move-mode nil
  "Support for Move source code."
  :link '(url-link "https://github.com/move-language/move")
  :group 'languages)

(defcustom move-builtin-functions
  '("assert!" "borrow_global" "exists" "freeze" "move_from" "move_to" "old")
  "Functions to highlight as builtins (mutations require restarting font-lock)."
  :type '(list string)
  :group 'move-mode)

(defvar move-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; Operators
    (dolist (op '(?+ ?- ?* ?/ ?% ?& ?^ ?| ?< ?>))
      (modify-syntax-entry op "." table))

    ;; Parentheses
    (modify-syntax-entry ?(   "()" table)
    (modify-syntax-entry ?)   ")(" table)
    (modify-syntax-entry ?{   "(}" table)
    (modify-syntax-entry ?}   "){" table)
    (modify-syntax-entry ?[   "(]" table)
    (modify-syntax-entry ?]   ")[" table)

    ;; Comments
    (modify-syntax-entry ?/   ". 124b" table)
    (modify-syntax-entry ?*   ". 23n"  table)
    (modify-syntax-entry ?\n  "> b"    table)
    (modify-syntax-entry ?\^m "> b"    table)

    table))

;;;###autoload
(define-derived-mode move-mode prog-mode "Move"
  "Major mode for Move source code."
  :group 'move-mode
  :syntax-table move-mode-syntax-table

  (setq-local font-lock-defaults
              '(move-mode-font-lock-keywords
                nil ;; KEYWORDS-ONLY
                nil ;; CASE-FOLD
                nil ;; SYNTAX-ALIST
                ;;;;;; VARIABLES
                (font-lock-syntactic-face-function
                 . move-mode-distinguish-comments))))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.move\\'" . move-mode))

(defconst move-keywords
  '("abort" "acquires" "as" "break" "const" "continue" "copy" "else" "entry"
    "friend" "fun" "has" "if" "invariant" "let" "loop" "module" "move" "native"
    "public" "return" "script" "spec" "struct" "use" "while"))

(defconst move-integer-types
  '("u8" "u64" "u128"))

(defconst move-builtin-types
  (append move-integer-types '("address" "bool" "vector")))

(defconst move-integer-with-type-re
  (eval-when-compile
    (concat "\\_<"
            "\\(?:0x?\\|[1-9]\\)"
            "[[:digit:]a-fA-F]*"
            (regexp-opt move-integer-types t)
            "\\_>")))

(defconst move-ident-re
  "[a-zA-Z][a-zA-Z0-9_]*\\|_[a-zA-Z0-9_]+")

(defvar move-mode-font-lock-keywords
  `((,(regexp-opt move-keywords 'symbols)      . font-lock-keyword-face)
    (,(regexp-opt move-builtin-types 'symbols) . font-lock-type-face)
    ("\\(#\\[[^]]*\\]\\)"                      1 font-lock-preprocessor-face keep)
    (,move-integer-with-type-re                1 font-lock-type-face)

    ;; Module components
    (,(concat "\\(" move-ident-re "\\)::")     1 font-lock-constant-face)

    ;; Fields, function params, local variables with explicit types
    (,(concat "\\(" move-ident-re "\\)\\s-*:[^:]")
     1 font-lock-variable-name-face)

    ;; Let bindings with inferred type
    (,(concat "\\_<let\\s-+\\(" move-ident-re "\\)\\_>")
     1 font-lock-variable-name-face)

    (eval move--register-builtin-functions)))

(defun move-mode-distinguish-comments (state)
  "Distinguish between doc comments and normal comments in the given syntax
   STATE."
  (save-excursion
    (goto-char (nth 8 state))
    (cond ((looking-at "//[/!][^/!]")
           'font-lock-doc-face)
          ((looking-at "/[*][*!][^*!]")
           'font-lock-doc-face)
          ('font-lock-comment-face))))

(defun move--register-builtin-functions ()
  "Generate a font-lock MATCHER form for built-in functions, specified via the
   MOVE-BUILTIN-FUNCTIONS custom variable."
  `(,(regexp-opt move-builtin-functions 'symbols) . font-lock-builtin-face))

(provide 'move-mode)

;;; move-mode.el ends here
