(defpackage #:qlot-tests/utils/asdf
  (:use #:cl
        #:rove)
  (:import-from #:qlot/utils/asdf
                #:with-directory))
(in-package #:qlot-tests/utils/asdf)

(deftest with-directory-tests
  (let ((system-hash (make-hash-table :test 'equal)))
    (with-directory (system-file system-name dependencies)
        (asdf:system-source-directory :qlot)
      (declare (ignore dependencies))
      (push system-name (gethash system-file system-hash)))
    (ok (null (set-difference (gethash (asdf:system-source-file :qlot) system-hash)
                              '("qlot" "qlot/subcommands" "qlot/command" "qlot/tests")
                              :test 'equal)))
    (ok (null (set-difference (gethash (asdf:system-source-file :qlot-tests) system-hash)
                              '("qlot-tests" "qlot-tests/patched")
                              :test 'equal)))))

(deftest feature-dependency-tests
  (let ((dir (uiop:ensure-directory-pathname
              (uiop:merge-pathnames*
               (format nil "qlot-feature-deps-~36R" (random (expt 36 8) (make-random-state t)))
               (uiop:temporary-directory))))
        (deps :unset))
    (ensure-directories-exist dir)
    (unwind-protect
         (progn
           (uiop:with-output-file (out (merge-pathnames "feature-deps.asd" dir))
             (write-string "(defsystem \"feature-deps\"
  :depends-on (\"alexandria\"
               (:feature :qlot-test-absent-feature \"absent-dep\")
               (:feature :qlot-test-absent-feature (:require \"absent-module\"))
               (:feature (:not :qlot-test-absent-feature) \"present-dep\")
               (:feature :common-lisp (:version \"versioned-dep\" \"1.0\"))))
" out))
           (with-directory (system-file system-name dependencies) dir
             (when (equal system-name "feature-deps")
               (setf deps dependencies))))
      (uiop:delete-directory-tree dir :validate t))
    (ok (equal deps '("alexandria" "present-dep" "versioned-dep")))))
