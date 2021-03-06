module Util.Socket
    ( connectSocket
    , serverSocket
    , acceptSocket
    , closeSock
    , Socket()
    ) where

import qualified Data.ByteString       as BS
import qualified Data.ByteString.Char8 as CS
import           Data.Word
import           Network.Socket        hiding (recv, recvFrom, send, sendTo)
import           Util.IOExtra

--------------------------------------------------------------------------------
connectSocket :: BS.ByteString -> Word16 -> IO Socket
connectSocket hostName portNumber = do
    (sock, sa) <- createSocket hostName (Just portNumber)
    handleAll (\e -> closeSock sock >> throwM e) $ do
        setSocketOption sock NoDelay 1
        connect sock sa
        return sock

serverSocket :: BS.ByteString -> IO (Socket, Word16)
serverSocket hostName = do
    (sock, sa) <- createSocket hostName Nothing
    handleAll (\e -> closeSock sock >> throwM e) $ do
        bind sock sa
        listen sock 5
        port <- socketPort sock
        return (sock, fromIntegral port)

acceptSocket :: Socket -> IO Socket
acceptSocket sock = do
    (sock', _sa) <- accept sock
    handleAll (\e -> closeSock sock' >> throwM e) $ do
      setSocketOption sock' NoDelay 1
      return sock'

closeSock :: Socket -> IO ()
closeSock = close

createSocket :: MonadIO m
             => BS.ByteString
             -> Maybe Word16
             -> m (Socket, SockAddr)
createSocket hostName portNumber =
    liftIO $ do
        ai <- addrInfo
        sock <- socket (addrFamily ai) (addrSocketType ai) (addrProtocol ai)
        return (sock, addrAddress ai)
  where
    addrInfo = do
        let hints = defaultHints { addrFlags = [ AI_CANONNAME
                                               , AI_NUMERICSERV
                                               , AI_ADDRCONFIG
                                               ]
                                 , addrFamily = AF_INET
                                 , addrSocketType = Stream
                                 }
        (ai : _) <- getAddrInfo (Just hints)
                                (Just (CS.unpack hostName))
                                (show <$> portNumber)
        return ai
