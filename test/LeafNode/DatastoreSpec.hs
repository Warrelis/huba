{-# LANGUAGE OverloadedStrings, OverloadedLists #-}

module LeafNode.DatastoreSpec (main, spec) where

import Test.Hspec
-- import Test.QuickCheck

import Shared.Thrift.Types as T
import Shared.Thrift.Interface

import LeafNode.Datastore



main :: IO ()
main = hspec spec


spec = do
  describe "Basic ingesting" $
    it "stores a message in a LeafStore" $
       testQueryResponse (ingestBatch [] [lm1])
                         (basicTimeRangeQuery 0 50)
                         (successfulQueryResponse [Row [RStringValue "s1"]])

  describe "Time queries" $ do
    it "returns messages in the middle of a time range" $
       testQueryResponse allMessagesStore
                         (basicTimeRangeQuery 15 25)
                         (successfulQueryResponse [Row [RStringValue "s2"]])

    it "returns all messages to the right" $
       testQueryResponse allMessagesStore
                         (basicTimeRangeQuery 15 100)
                         (successfulQueryResponse [Row [RStringValue "s2"], Row [RStringValue "s3"]])

  describe "Simple projection queries" $
    it "should project out columns" $
       testQueryResponse allMessagesStore
                         (Query [ColumnExpression "int1" CONSTANT, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing Nothing Nothing Nothing)
                         (successfulQueryResponse [Row [RIntValue 42, RStringValue "s1"],
                                                  Row [RIntValue 100, RStringValue "s2"],
                                                  Row [RIntValue 0, RStringValue "s3"]])


testQueryResponse :: LeafStore -> Query -> QueryResponse -> Expectation
testQueryResponse messageStore q queryResponse = query messageStore q `shouldBe` queryResponse

basicTimeRangeQuery :: Timestamp -> Timestamp -> Query
basicTimeRangeQuery t1 t2 = Query [ColumnExpression "string1" CONSTANT] "some-table" t1 t2 Nothing Nothing Nothing Nothing

successfulQueryResponse rows = QueryResponse 0 Nothing (Just rows)

lm1 = LogMessage 10 "some-table" [("string1", StringValue "s1"), ("int1", IntValue 42), ("vector1", StringVector ["a", "b", "c"])]
lm2 = LogMessage 20 "some-table" [("string1", StringValue "s2"), ("int1", IntValue 100), ("vector2", StringVector ["b", "c"])]
lm3 = LogMessage 30 "some-table" [("string1", StringValue "s3"), ("int1", IntValue 0), ("vector3", StringVector ["x", "y", "z"])]

allMessagesStore = ingestBatch [] [lm1, lm2, lm3]
