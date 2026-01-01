;;; CL-REDIS package definition
;;; (c) Vsevolod Dyomkin, see LICENSE file for permissions

(in-package :cl-user)


(defpackage #:redis
  (:use #:common-lisp #:rutil)
  (:shadow #:quit #:sort #:set #:get #:substr #:eval #:type #:append
           #:watch #:unwatch #:shutdown #:time #:keys #:function)
  (:export #:redis-connection
           #:connect
           #:disconnect
           #:reconnect
           #:*connection*
           #:open-connection
           #:close-connection
           #:connected-p
           #:with-connection
           #:with-recursive-connection
           #:with-persistent-connection
           #:make-connection-pool
           #:with-pooled-connection

           #:*echo-p*
           #:*echo-stream*

           #:*cmd-prefix*

           #:def-cmd
           #:def-expect-method
           #:expect
           #:tell

           #:redis-error
           #:redis-error-message
           #:redis-bad-reply
           #:redis-error-reply
           #:redis-connection-error

           #:with-pipelining))

(defpackage #:red
  (:use #| nothing |# ))


;;; end
