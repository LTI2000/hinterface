{-# LANGUAGE Strict #-}
module Language.Erlang.Mailbox ( Mailbox(..) ) where

import           Language.Erlang.Term

data Mailbox = Mailbox { getPid             :: Pid
                       , deliverLink        :: Pid -> IO ()
                       , deliverSend        :: Term -> IO ()
                       , deliverExit        :: Pid -> Term -> IO ()
                       , deliverUnlink      :: Pid -> IO ()
                       , deliverRegSend     :: Pid -> Term -> IO ()
                       , deliverGroupLeader :: Pid -> IO ()
                       , deliverExit2       :: Pid -> Term -> IO ()
                       , send               :: Pid -> Term -> IO ()
                       , sendReg            :: Term -> Term -> Term -> IO ()
                       , receive            :: IO Term
                       }
