(local fennel (require :fennel))

(fn make-rooted-path [loader]
  (fn [root path]
    {:root root :path path :loader loader}))

(local config-filename ".root-path")
(local config-env
  (doto (collect [name value (pairs _ENV)]
          name value)
    (tset :/f (make-rooted-path :fnl))
    (tset :/l (make-rooted-path :lua))
    (tset :/c (make-rooted-path :c))
    (tset :/m (make-rooted-path :macro))))
(local config (fennel.dofile config-filename {:env config-env}))

(local loader-makers
  {:fnl (fn [filename]
          (partial fennel.dofile filename nil))
   :lua (fn [filename]
          (partial loadfile filename))
   :c (fn [filename modname]
        (let [func-modname (-> modname
                               (: :match "^([^-]+)%-?.*") ; get module up to first hyphen (excluding)
                               (: :gsub "%." "_")) ; replace dots with underscores
              funcname (.. "luaopen_" func-modname)]
          (package.loadlib filename funcname)))
   :macro (fn [filename]
            (partial fennel.dofile filename {:env :_COMPILER}))})

(each [package-name config (pairs config)]
  (assert (< 0 (length config)) (: "root-path configuration for %s empty" :format package-name))
  (each [_ path-config (ipairs config)]
    (fn make-message [format-str]
      (format-str:format (fennel.view path-config) package-name))
    (let [{: root : path : loader} path-config]
      (assert (= :string (type root)) (make-message "invalid root of %s for %s"))
      (assert (= :string (type path)) (make-message "invalid path of %s for %s"))
      (assert (. loader-makers loader) (make-message "invalid loader type of %s for %s")))))

(local runtime-config [])
(local macro-config [])
(fn into-config [config-table package-name path-config]
  (when (not (. config-table package-name))
    (tset config-table package-name []))
  (table.insert (. config-table package-name) path-config))
(each [package-name config (pairs config)]
  (each [_ {: loader &as path-config} (ipairs config)]
    (if (= loader :macro)
      (into-config macro-config package-name path-config)
      (into-config runtime-config package-name path-config))))

(local [dirsep pathsep substpat]
  (icollect [line (package.config:gmatch "([^\n]+)")]
    line))

(fn escape [pattern]
  (pattern:gsub "%W" "%%%1"))

(local trimming-pattern (escape (.. substpat ":")))
(local no-package-pattern "^[^.]+%.?(.*)") ; remove first module component (up to and including first dot)

(fn handle-special-patterns [path modname]
  (if (path:match trimming-pattern)
    (values
      (path:gsub trimming-pattern substpat)
      (modname:match no-package-pattern))
    (values path modname)))

(local path-pattern (: "[^%s]+" :format (escape pathsep)))

(fn find-in-path [root path modname tried-files]
  (accumulate [filename nil
               path (path:gmatch path-pattern)
               &until filename]
    (let [(path modname) (handle-special-patterns path modname)
          full-path (.. root dirsep path)
          (?filename ?error-message) (fennel.search-module modname full-path)]
      (table.insert tried-files ?error-message)
      ?filename)))

(local package-pattern "^([^.]+)") ; get first module component (up to and excluding first dot)

(fn make-searcher [config-table]
  (fn [modname]
    (let [module-config (. config-table (modname:match package-pattern))]
      (when module-config
        (let [tried-files []
              (filename make-loader) (accumulate [(filename make-loader) (values nil nil)
                                                  _ {: root : path : loader} (ipairs module-config)
                                                  &until filename]
                                        (let [make-loader (. loader-makers loader)
                                              ?filename (find-in-path root path modname tried-files)]
                                          (values ?filename make-loader)))]
          (if filename
            (values
              (make-loader filename modname)
              filename)
            (when (< 0 (length tried-files))
              (let [tried-files (table.concat tried-files "\n\t")]
                (if (< _VERSION "Lua 5.4")
                  (.. "\n\t" tried-files)
                  tried-files)))))))))

(table.insert (or package.loaders package.searchers) (make-searcher runtime-config))
(table.insert fennel.macro-searchers (make-searcher macro-config))

;; TODO tests
