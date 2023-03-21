(local fennel (require :fennel))

(local loader-makers
  {:fnl (fn [filename]
         (partial fennel.dofile filename nil))})

(local [dirsep pathsep substpat]
  (icollect [line (package.config:gmatch "([^\n]+)")]
    line))

(fn escape [pattern]
  (pattern:gsub "%W" "%%%1"))

(local trimming-pattern (escape (.. substpat ":")))

(fn handle-special-patterns [path modname]
  (if (path:match trimming-pattern)
    (values
      (path:gsub trimming-pattern substpat)
      (modname:match "^[^.]+%.?(.*)"))
    (values path modname)))

(fn find-in-path [root path modname tried-files]
  (accumulate [filename nil
               path (path:gmatch (: "[^%s]+" :format (escape pathsep)))
               &until filename]
    (let [(path modname) (handle-special-patterns path modname)
          full-path (.. root dirsep path)
          (?filename ?error-message) (fennel.search-module modname full-path)]
      (table.insert tried-files ?error-message)
      ?filename)))

;; helpers
(fn make-rooted-path [root path loader]
  {:root root :path path :loader loader})
(fn make-fennel-rooted-path [root path]
  (make-rooted-path root path :fnl))
(tset package.preload :searcher #{: make-fennel-rooted-path})

(local config-filename ".package-root-paths")
(local searcher-config (fennel.dofile config-filename))

;; TODO validate config
;; TODO add macro searchers (split config, install new macro-searcher: (fennel.dofile filename {:env :_COMPILER}))
;; TODO tests

(fn searcher [modname]
  (let [module-config (. searcher-config (modname:match "^([^.]+)"))]
    (when module-config
      (let [tried-files []
            (filename make-loader) (accumulate [(filename make-loader) (values nil nil)
                                                _ {: root : path : loader} (ipairs module-config)
                                                &until filename]
                                      (let [make-loader (. loader-makers loader)
                                            filename (find-in-path root path modname tried-files)]
                                        (values filename make-loader)))]
        (if filename
          (values
            (make-loader filename modname)
            filename)
          (when (< 0 (length tried-files))
            (let [tried-files (table.concat tried-files "\n\t")]
              (if (< _VERSION "Lua 5.4")
                (.. "\n\t" tried-files)
                tried-files))))))))

(table.insert (or package.loaders package.searchers) searcher)
