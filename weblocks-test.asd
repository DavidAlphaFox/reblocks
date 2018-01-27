(defsystem "weblocks-test"
  :class :package-inferred-system
  :pathname "t"
  :depends-on (:weblocks
               "weblocks-test/dependencies"
               "weblocks-test/hooks"
               "weblocks-test/weblocks"
               "weblocks-test/request"
               "weblocks-test/response"
               "weblocks-test/request-handler"
               "weblocks-test/actions"
               "weblocks-test/commands")
  :perform (test-op (o c) (symbol-call :rove '#:run c)))


(register-system-packages "lack" '(#:lack.request))
(register-system-packages "lack-test" '(#:lack.test))
