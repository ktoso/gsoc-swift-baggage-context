//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Baggage Context open source project
//
// Copyright (c) 2020 Moritz Lang and the Swift Baggage Context project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// BaggageTests+XCTest.swift
//
import XCTest
///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

extension BaggageTests {

   @available(*, deprecated, message: "not actually deprecated. Just deprecated to allow deprecated tests (which test deprecated functionality) without warnings")
   static var allTests : [(String, (BaggageTests) -> () throws -> Void)] {
      return [
                ("testSubscriptAccess", testSubscriptAccess),
                ("testRecommendedConvenienceExtension", testRecommendedConvenienceExtension),
                ("testEmptyBaggageDescription", testEmptyBaggageDescription),
                ("testSingleKeyBaggageDescription", testSingleKeyBaggageDescription),
                ("testMultiKeysBaggageDescription", testMultiKeysBaggageDescription),
                ("test_todo_context", test_todo_context),
                ("test_topLevel", test_topLevel),
           ]
   }
}

