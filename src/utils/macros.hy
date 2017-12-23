(import functools)

(require [hy.extra.anaphoric [*]])

;; * Tag Macros

(deftag t [form]
  "Cast evaluated form to a tuple. Useful via eg. #t(-> x f1 f2 ...)."
  `(tuple ~form))

(deftag $ [form]
  "Partially apply a form eg. (#$(map inc) [1 2 3])."
  `(functools.partial ~@form))

;; * Some-> and Some->> threads

(defmacro -opener-or-none-first [opener]
  `(fn [&rest x &kwargs y]
     (if (none? (first x))
         None
         (~opener #* x #** y))))

(defmacro -opener-or-none-last [opener]
  `(fn [&rest x &kwargs y]
     (if (none? (last x))
         None
         (~opener #* x #** y))))

(defmacro some-> [head &rest forms]
  (setv evaled `(~head))
  (setv ret `(if (none? ~@evaled) None ~@evaled))

  (unless (none? `(~ret))
    (for [node forms]
      (unless (isinstance node HyExpression)
        (setv node `(~node)))

      (.insert node 1 ret)

      (setv opener (first node))
      (setv fixed-node
            `((-opener-or-none-first ~opener) ~@(rest node)))

      (setv ret fixed-node)))
  ret)

(defmacro some->> [head &rest forms]
  (setv evaled `(~head))
  (setv ret `(if (none? ~@evaled)
                 None
                 ~@evaled))

  (unless (none? `(~ret))
    (for [node forms]
      (unless (isinstance node HyExpression)
        (setv node `(~node)))

      (.append node ret)

      (setv opener (first node))
      (setv fixed-node
            `((-opener-or-none-last ~opener) ~@(rest node)))

      (setv ret fixed-node)))
  ret)

;; Move to tests

(some-> 1 inc inc)
(some-> None inc inc inc)
(some-> 1 ((constantly None)) inc)

(some->> 1 (/ 2))
(some->> None inc inc)
(some->> 1 ((constantly None)) inc)

(defn assert= [x y]
  (assert (= x y)))

(defn fn-just-rest [&rest x]
  (- #* x))

(defn fn-args-plus-rest [a &rest x]
  (+ a (- #* x)))

(defn fn-args-plus-optional [a &optional b [c 10]]
  (+ a (- b c)))

(defn fn-kwonly [a b &kwonly [c 10]]
  (+ (- a b) c))

(assert= (-> 1 (fn-rest 2 3))
         (some-> 1 (fn-rest 2 3)))
(assert= (->> 1 (fn-rest 2 3))
         (some->> 1 (fn-rest 2 3)))

(assert= (-> 1 (fn-args-plus-rest 2 3))
         (some-> 1 (fn-args-plus-rest 2 3)))
(assert= (->> 1 (fn-args-plus-rest 2 3))
         (some->> 1 (fn-args-plus-rest 2 3)))

(assert= (-> 1 (fn-args-plus-optional 2))
         (some-> 1 (fn-args-plus-optional 2)))
(assert= (->> 1 (fn-args-plus-optional 2))
         (some->> 1 (fn-args-plus-optional 2)))

(assert= (-> 1 (fn-args-plus-optional 2 3))
         (some-> 1 (fn-args-plus-optional 2 3)))
(assert= (->> 1 (fn-args-plus-optional 2 3))
         (some->> 1 (fn-args-plus-optional 2 3)))

(assert= (-> 1 (fn-kwonly 2))
         (some-> 1 (fn-kwonly 2)))
(assert= (->> 1 (fn-kwonly 2))
         (some->> 1 (fn-kwonly 2)))

(assert= (-> 1 (fn-kwonly 2 :c 5))
         (some-> 1 (fn-kwonly 2 :c 5)))
(assert= (->> 1 (fn-kwonly 2 :c 5))
         (some->> 1 (fn-kwonly 2 :c 5)))

(assert (none? (some-> None inc inc)))
(assert (none? (some->> None inc inc)))

(assert (none? (some-> 1 ((constantly None)) inc)))
(assert (none? (some->> 1 ((constantly None)) inc)))

(assert= 1 (some-> 1 ((constantly 0)) inc))
(assert= 1 (some->> 1 ((constantly 0)) inc))

;; Open with form that evaluates to something
(assert= (-> (+ 1 2) inc)
         (some-> (+ 1 2) inc))

;; Open with form that evaluates to None
(assert (none? (some-> ((constantly None)) inc)))
