;;;==============
;;;  JazzScheme
;;;==============
;;;
;;;; Libgit2 Bindings
;;;


(include "syntax.scm")
(include "foreign.scm")


(c-declare "#include <git2.h>")


;;;
;;;; Enumerations
;;;


(c-enumerant GIT_DIRECTION_FETCH)
(c-enumerant GIT_DIRECTION_PUSH)

(c-enumerant GIT_OBJ_COMMIT)
(c-enumerant GIT_OBJ_TREE)
(c-enumerant GIT_OBJ_BLOB)
(c-enumerant GIT_OBJ_TAG)

(c-enumerant GIT_RESET_SOFT)
(c-enumerant GIT_RESET_MIXED)
(c-enumerant GIT_RESET_HARD)


;;;
;;;; Types
;;;


(c-type git_otype int)
(c-type git_reset_t int)
(c-type git_error "git_error")
(c-type git_error* (pointer git_error))
(c-type git_commit "git_commit")
(c-type git_commit* (pointer git_commit))
(c-type git_cred "git_cred")
(c-type git_cred* (pointer git_cred))
(c-type git_index "git_index")
(c-type git_index* (pointer git_index))
(c-type git_object "git_object")
(c-type git_object* (pointer git_object))
(c-type git_oid "git_oid")
(c-type git_oid* (pointer git_oid))
(c-type git_reference "git_reference")
(c-type git_reference* (pointer git_reference))
(c-type git_remote "git_remote")
(c-type git_remote* (pointer git_remote))
(c-type git_repository "git_repository")
(c-type git_repository* (pointer git_repository))
(c-type git_tree "git_tree")
(c-type git_tree* (pointer git_tree))

(c-type HANDLE (pointer void handle))
(c-type HWND (pointer (struct "HWND__") handle))


;;;
;;;; Error
;;;


(c-define (git-check-error code) (int) void "git_check_error" ""
  (when (not (= code 0))
    (error "Libgit2 error:"
           (let ((err (giterr-last)))
             (if err
                 (git-error-message err)
               code)))))

(define giterr-last
  (c-lambda () git_error*
    "___result_voidstar = (void*) giterr_last();"))

(define git-error-message
  (c-lambda (git_error*) char-string
    "___result = ___arg1->message;"))


;;;
;;;; Thread
;;;


(c-declare #<<end-of-c-declare
    HANDLE ghMutex = NULL;
    HWND remoteHwnd = NULL;
    
    #define DOWNLOAD_PROGRESS 0
    #define DOWNLOAD_DONE     1
    #define CHECKOUT_PROGRESS 2
    #define CHECKOUT_DONE     3
end-of-c-declare
)


(c-enumerant DOWNLOAD_PROGRESS)
(c-enumerant DOWNLOAD_DONE)
(c-enumerant CHECKOUT_PROGRESS)
(c-enumerant CHECKOUT_DONE)


;;;
;;;; Checkout
;;;


(define git-checkout-head
  (c-lambda (git_repository*) void
    #<<end-of-c-code
    git_checkout_opts options = GIT_CHECKOUT_OPTS_INIT;
    git_check_error(git_checkout_head(___arg1, &options));
end-of-c-code
))

(define git-checkout-tree-force
  (c-lambda (git_repository* git_tree*) void
    #<<end-of-c-code
    git_checkout_opts options = GIT_CHECKOUT_OPTS_INIT;
    options.checkout_strategy = GIT_CHECKOUT_FORCE;
    git_check_error(git_checkout_tree(___arg1, (git_object*) ___arg2, &options));
end-of-c-code
))

(c-declare #<<end-of-c-declare
    git_repository* checkout_repository = NULL;
    git_tree* checkout_tree = NULL;
    
    char* checkout_path = NULL;
    size_t checkout_completed_steps = 0;
    size_t checkout_total_steps = 0;
end-of-c-declare
)

(define git-checkout-path
  (c-lambda () char-string
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_path;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-checkout-completed-steps
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_completed_steps;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-checkout-total-steps
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = checkout_total_steps;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(c-declare #<<end-of-c-declare
    void checkout_callback(const char *path, size_t completed_steps, size_t total_steps, void *payload)
    {
        WaitForSingleObject(ghMutex, INFINITE);
        checkout_path = (char*) path;
        checkout_completed_steps = completed_steps;
        checkout_total_steps = total_steps;
        ReleaseMutex(ghMutex);
        PostMessage(remoteHwnd, WM_USER, CHECKOUT_PROGRESS, 0);
    }

    DWORD WINAPI checkout_proc(LPVOID lpParam)
    {
        git_checkout_opts options = GIT_CHECKOUT_OPTS_INIT;
        options.checkout_strategy = GIT_CHECKOUT_FORCE;
        options.progress_cb = checkout_callback;
        int result = git_checkout_tree(checkout_repository, (git_object*) checkout_tree, &options);
        PostMessage(remoteHwnd, WM_USER, CHECKOUT_DONE, result);
        return 0;
    }
end-of-c-declare
)

(define git-checkout-tree-force-threaded
  (c-lambda (git_repository* git_tree* HWND) HANDLE
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    remoteHwnd = ___arg3;
    checkout_repository = ___arg1;
    checkout_tree = ___arg2;
    ___result = CreateThread(NULL, 0, &checkout_proc, 0, 0, NULL);
end-of-c-code
))


;;;
;;;; Commit
;;;


(define git-commit-tree
  (c-lambda (git_object*) git_tree*
    #<<end-of-c-code
    git_tree* tree;
    git_check_error(git_commit_tree(&tree, (git_commit*) ___arg1));
    ___result_voidstar = tree;
end-of-c-code
))


;;;
;;;; Cred
;;;


(define git-cred-userpass-plaintext-new
  (c-lambda (char-string char-string) git_cred*
    #<<end-of-c-code
    git_cred* cred;
    git_check_error(git_cred_userpass_plaintext_new(&cred, ___arg1, ___arg2));
    ___result_voidstar = cred;
end-of-c-code
))


;;;
;;;; Index
;;;


(define git-index-free
  (c-lambda (git_index*) void
    "git_index_free(___arg1);"))

(define git-index-read-tree
  (c-lambda (git_index* git_tree*) void
    #<<end-of-c-code
    git_check_error(git_index_read_tree(___arg1, ___arg2));
end-of-c-code
))

(define git-index-write
  (c-lambda (git_index*) void
    #<<end-of-c-code
    git_check_error(git_index_write(___arg1));
end-of-c-code
))


;;;
;;;; Object
;;;


(define git-object-lookup
  (c-lambda (git_repository* git_oid* git_otype) git_object*
    #<<end-of-c-code
    git_object* obj;
    git_check_error(git_object_lookup(&obj, ___arg1, ___arg2, ___arg3));
    ___result_voidstar = obj;
end-of-c-code
))

(define git-object-free
  (c-lambda (git_object*) void
    "git_object_free(___arg1);"))

(define git-object-peel
  (c-lambda (git_object* git_otype) git_object*
    #<<end-of-c-code
    git_object* obj;
    git_check_error(git_object_peel(&obj, ___arg1, ___arg2));
    ___result_voidstar = obj;
end-of-c-code
))

(define git-object-id
  (c-lambda (git_object*) git_oid*
    #<<end-of-c-code
    ___result_voidstar = (git_oid*) git_object_id(___arg1);
end-of-c-code
))


;;;
;;;; Reference
;;;


(define git-reference-create
  (c-lambda (git_repository* char-string git_oid* int) git_reference*
    #<<end-of-c-code
    git_reference* ref;
    git_check_error(git_reference_create(&ref, ___arg1, ___arg2, ___arg3, ___arg4));
    ___result_voidstar = ref;
end-of-c-code
))

(define git-reference-free
  (c-lambda (git_reference*) void
    #<<end-of-c-code
    git_reference_free(___arg1);
end-of-c-code
))

(define git-reference-lookup
  (c-lambda (git_repository* char-string) git_reference*
    #<<end-of-c-code
    git_reference* ref;
    git_check_error(git_reference_lookup(&ref, ___arg1, ___arg2));
    ___result_voidstar = ref;
end-of-c-code
))

(define git-reference-name
  (c-lambda (git_reference*) char-string
    #<<end-of-c-code
    ___result = (char*) git_reference_name(___arg1);
end-of-c-code
))

(define git-reference-name->id
  (c-lambda (git_repository* char-string) git_oid*
    #<<end-of-c-code
    git_oid* oid = calloc(1, sizeof(git_oid));
    git_check_error(git_reference_name_to_id(oid, ___arg1, ___arg2));
    ___result_voidstar = oid;
end-of-c-code
))

(define (git-reference->id repo ref)
  (git-reference-name->id repo (git-reference-name ref)))

(define git-reference__update_terminal
  (c-lambda (git_repository* char-string git_object*) void
    #<<end-of-c-code
    git_check_error(git_reference__update_terminal(___arg1, ___arg2, git_object_id(___arg3)));
end-of-c-code
))


;;;
;;;; Remote
;;;


(define git-remote-create
  (c-lambda (git_repository* char-string char-string) git_remote*
    #<<end-of-c-code
    git_remote* remote;
    git_check_error(git_remote_create(&remote, ___arg1, ___arg2, ___arg3));
    ___result_voidstar = remote;
end-of-c-code
))

(define git-remote-check-cert
  (c-lambda (git_remote* int) void
    #<<end-of-c-code
    git_remote_check_cert(___arg1, ___arg2);
end-of-c-code
))

(c-define (cred-acquire-procedure proc) (scheme-object) git_cred* "cred_acquire_procedure" ""
  (proc))

(c-declare #<<end-of-c-declare
    int cred_acquire_cb(git_cred **out, const char * url, const char * username_from_url, unsigned int allowed_types, void * payload)
    {
        *out = cred_acquire_procedure(___EXT(___data_rc)(payload));
        return 0;
    }
end-of-c-declare
)

(define git-remote-set-cred-acquire-cb
  (c-lambda (git_remote* scheme-object) void
    #<<end-of-c-code
    void* p = ___EXT(___alloc_rc)(0);
    ___EXT(___set_data_rc)(p, ___arg2);
    git_remote_set_cred_acquire_cb(___arg1, &cred_acquire_cb, p);
end-of-c-code
))

(define git-remote-connect
  (c-lambda (git_remote* int) void
    #<<end-of-c-code
    git_check_error(git_remote_connect(___arg1, ___arg2));
end-of-c-code
))

(c-define (remote-download-procedure proc total_objects indexed_objects received_objects received_bytes) (scheme-object unsigned-int unsigned-int unsigned-int unsigned-int) void "remote_download_procedure" ""
  (when proc
    (proc total_objects indexed_objects received_objects received_bytes)))

(c-declare #<<end-of-c-code
    int remote_download_cb(const git_transfer_progress *stats, void *payload)
    {
        remote_download_procedure(___EXT(___data_rc)(payload), stats->total_objects, stats->indexed_objects, stats->received_objects, stats->received_bytes);
        return 0;
    }
end-of-c-code
)

(define git-remote-download
  (c-lambda (git_remote* scheme-object) void
    #<<end-of-c-code
    void* p = ___EXT(___alloc_rc)(0);
    ___EXT(___set_data_rc)(p, ___arg2);
    git_check_error(git_remote_download(___arg1, &remote_download_cb, p));
    ___EXT(___release_rc)(p);
end-of-c-code
))

(c-declare #<<end-of-c-declare
    unsigned int total_objects = 0;
    unsigned int received_objects = 0;
    size_t received_bytes = 0;
end-of-c-declare
)

(define git-remote-download-total-objects
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = total_objects;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-remote-download-received-objects
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = received_objects;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(define git-remote-download-received-bytes
  (c-lambda () int
    #<<end-of-c-code
    WaitForSingleObject(ghMutex, INFINITE);
    ___result = received_bytes;
    ReleaseMutex(ghMutex);
end-of-c-code
))

(c-declare #<<end-of-c-declare
    int remote_download_callback(const git_transfer_progress *stats, void *payload)
    {
        WaitForSingleObject(ghMutex, INFINITE);
        total_objects = stats->total_objects;
        received_objects = stats->received_objects;
        received_bytes = stats->received_bytes;
        ReleaseMutex(ghMutex);
        PostMessage(remoteHwnd, WM_USER, DOWNLOAD_PROGRESS, 0);
        return 0;
    }

    DWORD WINAPI remote_download_proc(LPVOID lpParam)
    {
        int result = git_remote_download((git_remote*) lpParam, &remote_download_callback , NULL);
        PostMessage(remoteHwnd, WM_USER, DOWNLOAD_DONE, result);
        return 0;
    }
end-of-c-declare
)

(define git-remote-download-threaded
  (c-lambda (git_remote* HWND) HANDLE
    #<<end-of-c-code
    if (! ghMutex)
        ghMutex = CreateMutex(NULL, FALSE, NULL);
    remoteHwnd = ___arg2;
    ___result = CreateThread(NULL, 0, &remote_download_proc, ___arg1, 0, NULL);
end-of-c-code
))

(define git-remote-disconnect
  (c-lambda (git_remote*) void
    "git_remote_disconnect"))

(define git-remote-update-tips
  (c-lambda (git_remote*) void
    #<<end-of-c-code
    git_check_error(git_remote_update_tips(___arg1));
end-of-c-code
))

(define git-remote-free
  (c-lambda (git_remote*) void
    "git_remote_free"))


;;;
;;;; Repository
;;;


(define git-repository-init
  (c-lambda (char-string unsigned-int) git_repository*
    #<<end-of-c-code
    git_repository* repo;
    git_check_error(git_repository_init(&repo, ___arg1, ___arg2));
    ___result_voidstar = repo;
end-of-c-code
))

(define git-repository-free
  (c-lambda (git_repository*) void
    "git_repository_free"))

(define git-repository-index
  (c-lambda (git_repository*) git_index*
    #<<end-of-c-code
    git_index* index;
    git_check_error(git_repository_index(&index, ___arg1));
    ___result_voidstar = index;
end-of-c-code
))

(define git-repository-merge-cleanup
  (c-lambda (git_repository*) void
    #<<end-of-c-code
    git_check_error(git_repository_merge_cleanup(___arg1));
end-of-c-code
))

(define git-repository-set-head
  (c-lambda (git_repository* char-string) void
    #<<end-of-c-code
    git_check_error(git_repository_set_head(___arg1, ___arg2));
end-of-c-code
))


;;;
;;;; Reset
;;;


(define git-reset
  (c-lambda (git_repository* git_object* git_reset_t) void
    #<<end-of-c-code
    git_check_error(git_reset(___arg1, ___arg2, ___arg3));
end-of-c-code
))


;;;
;;;; Tree
;;;


(define git-tree-free
  (c-lambda (git_tree*) void
    "git_tree_free(___arg1);"))
