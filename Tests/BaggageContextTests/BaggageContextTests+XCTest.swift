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
// BaggageContextTests+XCTest.swift
//
import XCTest
///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

extension BaggageContextTests {

   @available(*, deprecated, message: "not actually deprecated. Just deprecated to allow deprecated tests (which test deprecated functionality) without warnings")
   static var allTests : [(String, (BaggageContextTests) -> () throws -> Void)] {
      return [
                ("test_ExampleFrameworkContext_dumpBaggage", test_ExampleFrameworkContext_dumpBaggage),
                ("test_ExampleMutableFrameworkContext_log_withBaggage", test_ExampleMutableFrameworkContext_log_withBaggage),
                ("test_ExampleMutableFrameworkContext_log_prefersBaggageContextOverExistingLoggerMetadata", test_ExampleMutableFrameworkContext_log_prefersBaggageContextOverExistingLoggerMetadata),
           ]
   }
}

