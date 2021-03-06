{-# LANGUAGE OverloadedStrings, OverloadedLists #-}

module Common.TestData (makeSpec) where

import Test.Hspec

import Shared.Thrift.Types as T
import Shared.Thrift.Interface


{- This module contains some query tests that can be run at any layer of the system, i.e.
   against a LeafNode, Aggregator, or RootAggregator.

   Important: this only works if the queries below don't require any special transformations to be
   applied by the RootAggregator such as average or adding missing groupBy. Don't add such queries to
   this file!

   The module exports the function makeSpec, which requires you to specify a function for actually
   running queries and comparing the response. -}

makeSpec :: (LogBatch -> Query -> QueryResponse -> Expectation) -> Spec
makeSpec testQueryResponse = do
  describe "Basic ingesting" $
    it "stores a message in a LeafStore and lets you query it" $
       testQueryResponse [simpleMsg]
                         (basicTimeRangeQuery 0 50)
                         (successfulQueryResponse [[RStringValue "s1"]])

  describe "Time queries" $ do
    it "returns messages in the middle of a time range" $
       testQueryResponse allMessages
                         (basicTimeRangeQuery 15 25)
                         (successfulQueryResponse [[RStringValue "s2"]])

    it "returns all messages to the right" $
       testQueryResponse allMessages
                         (basicTimeRangeQuery 15 100)
                         (successfulQueryResponse [[RStringValue "s2"], [RStringValue "s3"], [RStringValue "s3"]])

  describe "Simple projection queries" $
    it "should project out columns" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" CONSTANT, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing Nothing Nothing 100)
                         (successfulQueryResponse [[RIntValue 42, RStringValue "s1"],
                                                  [RIntValue 100, RStringValue "s2"],
                                                  [RIntValue 3, RStringValue "s3"],
                                                  [RIntValue 15, RStringValue "s3"]])

  describe "Aggregations" $ do
    it "can do a count aggregation" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" COUNT, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing (Just []) Nothing 100)
                         (successfulQueryResponse [[RIntValue 4, RStringValue "s1"]])

    it "can do a min aggregation" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" MIN, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing (Just []) Nothing 100)
                         (successfulQueryResponse [[RIntValue 3, RStringValue "s1"]])

    it "can do a max aggregation" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" MAX, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing (Just []) Nothing 100)
                         (successfulQueryResponse [[RIntValue 100, RStringValue "s1"]])

    it "can do a sum aggregation" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" SUM, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing (Just []) Nothing 100)
                         (successfulQueryResponse [[RIntValue 160, RStringValue "s1"]])

  describe "GroupBys" $ do
    it "can group by a single string column" $
       testQueryResponse allMessages
                         (Query [ColumnExpression "int1" SUM, ColumnExpression "string1" CONSTANT] "some-table" 0 100 Nothing (Just ["string1"]) Nothing 100)
                         (successfulQueryResponse [[RIntValue 42, RStringValue "s1"],
                                                   [RIntValue 100, RStringValue "s2"],
                                                   [RIntValue 18, RStringValue "s3"]])

    it "can group by a string and int column together" $
       testQueryResponse groupByMessages
                         (Query [ColumnExpression "string1" CONSTANT, ColumnExpression "int1" CONSTANT] "some-table" 0 100 Nothing (Just ["int1"]) Nothing 100)
                         (successfulQueryResponse [[RStringValue "s1", RIntValue 20],
                                                   [RStringValue "s2", RIntValue 30],
                                                   [RStringValue "s2", RIntValue 50]])

  describe "Aggregations with GroupBys" $ do
    it "can group by a string while aggregating an int" $
       testQueryResponse groupByMessages
                         (Query [ColumnExpression "string1" CONSTANT, ColumnExpression "int1" SUM] "some-table" 0 100 Nothing (Just ["string1"]) Nothing 100)
                         (successfulQueryResponse [[RStringValue "s1", RIntValue 40],
                                                   [RStringValue "s2", RIntValue 110]])


-- Helper functions --

basicTimeRangeQuery :: Timestamp -> Timestamp -> Query
basicTimeRangeQuery t1 t2 = Query [ColumnExpression "string1" CONSTANT] "some-table" t1 t2 Nothing Nothing Nothing 100

successfulQueryResponse rows = QueryResponse 0 Nothing (Just rows)

-- Data --

simpleMsg = LogMessage 10 "some-table" [("string1", StringValue "s1"), ("int1", IntValue 42), ("vector1", StringVector ["a", "b", "c"])]

allMessages = [
  LogMessage 10 "some-table" [("string1", StringValue "s1"), ("int1", IntValue 42), ("vector1", StringVector ["a", "b", "c"])],
  LogMessage 20 "some-table" [("string1", StringValue "s2"), ("int1", IntValue 100), ("vector2", StringVector ["b", "c"])],
  LogMessage 30 "some-table" [("string1", StringValue "s3"), ("int1", IntValue 3), ("vector3", StringVector ["x", "y", "z"])],
  LogMessage 40 "some-table" [("string1", StringValue "s3"), ("int1", IntValue 15), ("vector3", StringVector ["p", "q", "r"])]
  ]

groupByMessages = [
 LogMessage 10 "some-table" [("string1", StringValue "s1"), ("int1", IntValue 20)],
 LogMessage 20 "some-table" [("string1", StringValue "s1"), ("int1", IntValue 20)],
 LogMessage 30 "some-table" [("string1", StringValue "s2"), ("int1", IntValue 30)],
 LogMessage 40 "some-table" [("string1", StringValue "s2"), ("int1", IntValue 30)],
 LogMessage 40 "some-table" [("string1", StringValue "s2"), ("int1", IntValue 50)]
 ]
