(require [src.utils.macros [*]])
(require [hy.extra.anaphoric [*]])
(require [tests.hytest [*]])
(import [tests.hytest [*]])

(import
  [src.inspection [Parameter
                   Signature
                   Inspect
                   builtin-docs-to-lispy-docs]])

;; * Argspec Extraction
;; ** Maximal Cases

(defn test-maximal-argspec []
  (defn func [a b
           &optional c [d 0]
           &kwonly e [f 1]
           &rest args
           &kwargs kwargs])

  (assert= "a b &optional c [d 0] #* args #** kwargs &kwonly e [f 1]"
           (-> func Signature str)))


(defn test-maximal-argspec-minus-kwonly []
  (defn func [a b
           &optional c [d 0]
           &rest args
           &kwargs kwargs])

  (assert= "a b &optional c [d 0] #* args #** kwargs"
           (-> func Signature str)))


(defn test-maximal-argspec-minus-kwargs []
  (defn func [a b
           &optional c [d 0]
           &kwonly e [f 1]
           &rest args])

  (assert= "a b &optional c [d 0] #* args &kwonly e [f 1]"
           (-> func Signature str)))


(defn test-maximal-argspec-minus-normal-args []
  (defn func [&optional c [d 0]
           &kwonly e [f 1]
           &rest args
           &kwargs kwargs])

  (assert= "&optional c [d 0] #* args #** kwargs &kwonly e [f 1]"
           (-> func Signature str)))

;; ** Optional/Kwonly with/without defaults

(defn test-optional-without-defaults []
  (defn func [&optional c
           &kwonly e [f 1]])

  (assert= "&optional c &kwonly e [f 1]"
           (-> func Signature str)))


(defn test-optional-with-only-defaults []
  (defn func [&optional [c 0] [d 0]
           &kwonly e [f 1]])

  (assert= "&optional [c 0] [d 0] &kwonly e [f 1]"
           (-> func Signature str)))


(defn test-kwonly-without-defaults []
  (defn func [&kwonly f g])

  (assert= "&kwonly f g"
           (-> func Signature str)))


(defn test-kwonly-with-only-defaults []
  (defn func [&kwonly [f 1] [g 1]])

  (assert= "&kwonly [f 1] [g 1]"
           (-> func Signature str)))

;; ** Trivial cases

(defn test-no-sig []
  (defn func [])

  (assert= ""
           (-> func Signature str)))


(defn test-simplest-sig []
  (defn func [a])

  (assert= "a"
           (-> func Signature str)))

;; * Convert Builtin Docs to Lispy

(defn test-builtin-docstring-conversion-maximal-case []
  (assert=
    "print: (value #* args &optional [sep ' '] [end 'newline'] [file sys.stdout] [flush False])"
    (builtin-docs-to-lispy-docs
      "print(value, ..., sep=' ', end='\n', file=sys.stdout, flush=False)")))

(defn test-builtin-docstring-conversion-optional-only-with-defaults []
  (assert=
    "tee: (iterable &optional [n 2]) return tuple of n independent iterators."
    (builtin-docs-to-lispy-docs
      "tee(iterable, n=2) --> tuple of n independent iterators.")))

(defn test-builtin-docstring-conversion-optional-only-without-defaults []
  (assert=
    "x: (foo &optional bar) - x"
    (builtin-docs-to-lispy-docs
      "x(foo, bar=None) - x")))

(defn test-builtin-docstring-conversion-no-docs []
  (assert=
    "x: (foo &optional bar)"
    (builtin-docs-to-lispy-docs
      "x(foo, bar=None)")))

(defn test-builtin-docstring-conversion-no-optionals []
  (assert=
    "combinations: (iterable r) return combinations object"
    (builtin-docs-to-lispy-docs
      "combinations(iterable, r) --> combinations object")))
