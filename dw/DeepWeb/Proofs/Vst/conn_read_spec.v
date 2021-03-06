Require Import String.

From DeepWeb.Proofs.Vst
     Require Import VstInit VstLib SocketSpecs MonadExports AppLogic
     Connection Store.

Require Import DeepWeb.Spec.ITreeSpec.

Set Bullet Behavior "Strict Subproofs".

Import SockAPIPred.
Import TracePred.

(********************************* conn_read **********************************)

Definition conn_read_spec (T : Type) :=
  DECLARE _conn_read
  WITH k : (connection * string) -> SocketMonad T,
       st : SocketMap,
       conn : connection,
       fd : sockfd,
       last_msg : string,
       conn_ptr : val,
       msg_store_ptr : val 
  PRE [ _conn OF (tptr (Tstruct _connection noattr)),
        _last_msg_store OF (tptr (Tstruct _store noattr))
      ]
    PROP ( consistent_world st;
           conn_state conn = RECVING ;
           consistent_state st (conn, fd)
         )
    LOCAL ( temp _conn conn_ptr ; temp _last_msg_store msg_store_ptr )
    SEP ( SOCKAPI st ;
            TRACE (r <- conn_read conn last_msg ;; k r) ;
            list_cell LS Tsh (rep_connection conn fd) conn_ptr ;
            field_at Tsh (Tstruct _store noattr) []
                     (rep_store last_msg) msg_store_ptr
        )
  POST [ tint ]
    EX conn' : connection,
    EX last_msg' : string,
    EX st' : SocketMap,
    EX r : Z, 
    PROP ( r = YES ;
           recv_step (conn, fd, st, last_msg) (conn', fd, st', last_msg');
           consistent_world st'
         )
    LOCAL ( temp ret_temp (Vint (Int.repr r)) )
    SEP ( SOCKAPI st' ; TRACE (k (conn', last_msg')) ;
            list_cell LS Tsh (rep_connection conn' fd) conn_ptr ;
            field_at Tsh (Tstruct _store noattr) []
                     (rep_store last_msg') msg_store_ptr
        ).
