-- M-x intero-targets
-- hinterface:lib hinterface:hinterface-test
--
module Main ( main ) where

import           Prelude                   hiding (length)

import           Control.Monad.IO.Class    (liftIO)

import           Data.IOx

import           Language.Erlang.Epmd
import           Language.Erlang.LocalNode
import           Language.Erlang.Mailbox
import           Language.Erlang.Term

import           Person

main :: IO ()
main = fromIOx $ do
    mainX

mainX :: IOx ()
mainX = do
    epmdNames "localhost.localdomain" >>= (liftIO . print)

    localNode <- newLocalNode "hay@localhost.localdomain" "cookie" >>= registerLocalNode

    epmdNames "localhost.localdomain" >>= (liftIO . print)

    mailbox <- make_mailbox localNode
    let self = getPid mailbox

    myPort <- make_port localNode
    myRef <- make_ref localNode
    let message = ( self
                  , myRef
                  , myPort
                  , (float 2.18, (), list [], list [ atom "a", atom "b", atom "c" ])
                  , string "hello!"
                  )
    liftIO $ putStr "Message: "
    liftIO $ print message
    liftIO $ putStrLn ""

    sendReg mailbox "echo" "erl@localhost.localdomain" (toTerm message)


    reply <- receive mailbox
    liftIO $ putStr "Reply: "
    liftIO $ print reply
    liftIO $ putStrLn ""

    sendReg mailbox "echo" "erl@localhost.localdomain" (toTerm (self, Person "Timo" 46))
    person <- receive mailbox
    liftIO $ print person
    case fromTerm person :: Maybe Person of
        Just p -> liftIO $ print p
        Nothing -> liftIO $ putStrLn "NOPE!"

    liftIO $ putStrLn "BYE"

    register localNode "hay" self
    loopX mailbox

    closeLocalNode localNode

    epmdNames "localhost.localdomain" >>= (liftIO . print)

loopX :: Mailbox -> IOx ()
loopX mailbox = do
    msg <- receive mailbox
    case fromTerm msg of
        Just (remotePid, i) ->
          do send mailbox remotePid (toTerm (integer (i + 1)))
             loopX mailbox
        _ -> do
            return ()
