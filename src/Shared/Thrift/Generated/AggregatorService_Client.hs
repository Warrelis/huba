{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE OverloadedStrings #-}
{-# OPTIONS_GHC -fno-warn-missing-fields #-}
{-# OPTIONS_GHC -fno-warn-missing-signatures #-}
{-# OPTIONS_GHC -fno-warn-name-shadowing #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}
{-# OPTIONS_GHC -fno-warn-unused-matches #-}

-----------------------------------------------------------------
-- Autogenerated by Thrift Compiler (0.9.1)                      --
--                                                             --
-- DO NOT EDIT UNLESS YOU ARE SURE YOU KNOW WHAT YOU ARE DOING --
-----------------------------------------------------------------

module AggregatorService_Client(query) where
import CommonService_Client
import Data.IORef
import Prelude ( Bool(..), Enum, Double, String, Maybe(..),
                 Eq, Show, Ord,
                 return, length, IO, fromIntegral, fromEnum, toEnum,
                 (.), (&&), (||), (==), (++), ($), (-) )

import Control.Exception
import Data.ByteString.Lazy
import Data.Hashable
import Data.Int
import Data.Text.Lazy ( Text )
import qualified Data.Text.Lazy as TL
import Data.Typeable ( Typeable )
import qualified Data.HashMap.Strict as Map
import qualified Data.HashSet as Set
import qualified Data.Vector as Vector

import Thrift
import Thrift.Types ()


import Huba_Types
import AggregatorService
seqid = newIORef 0
query (ip,op) arg_query = do
  send_query op arg_query
  recv_query ip
send_query op arg_query = do
  seq <- seqid
  seqn <- readIORef seq
  writeMessageBegin op ("query", M_CALL, seqn)
  write_Query_args op (Query_args{f_Query_args_query=Just arg_query})
  writeMessageEnd op
  tFlush (getTransport op)
recv_query ip = do
  (fname, mtype, rseqid) <- readMessageBegin ip
  if mtype == M_EXCEPTION then do
    x <- readAppExn ip
    readMessageEnd ip
    throw x
    else return ()
  res <- read_Query_result ip
  readMessageEnd ip
  case f_Query_result_success res of
    Just v -> return v
    Nothing -> do
      throw (AppExn AE_MISSING_RESULT "query failed: unknown result")
