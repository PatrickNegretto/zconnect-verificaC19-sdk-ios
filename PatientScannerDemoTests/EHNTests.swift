//
//  EHNTests.swift
//  EHNTests
//
//  Created by Dirk-Willem van Gulik on 01/04/2021.
//

@testable import PatientScannerDemo
import XCTest
import CryptoKit
import SwiftCBOR

var barcode = "HC1NCFY70R30FFWTWGSLKC 4O992$V M63TMF2V*D9LPC.3EHPCGEC27B72VF/347O4-M6Y9M6FOYG4ILDEI8GR3ZI$15MABL:E9CVBGEEWRMLE C39S0/ANZ52T82Z-73D63P1U 1$PKC 72H2XX09WDH889V5"

let trustJson = """
[
  {
    \"kid\" : \"DEFBBA3378B322F5\",
    \"coord\" : [
      \"230ca0433313f4ef14ec0ab0477b241781d135ee09369507fcf44ca988ed09d6\",
      \"bf1bfe3d2bda606c841242b59c568d00e5c8dd114d223b2f5036d8c5bc68bf5d\"
    ]
  },
  {
    \"kid\" : \"FFFBBA3378B322F5\",
    \"coord\" : [
      \"9999a0433313f4ef14ec0ab0477b241781d135ee09369507fcf44ca988ed09d6\",
      \"9999fe3d2bda606c841242b59c568d00e5c8dd114d223b2f5036d8c5bc68bf5d\"
    ]
  }
]
"""


class EHNTests: XCTestCase {
  func test_cose() throws {
    let COSE_TAG = UInt64(18)
    let COSE_PHDR_KID = CBOR.unsignedInt(4)

    // Remove HC1 header if any
    if (barcode.hasPrefix("HC1")) {
      barcode = String(barcode.suffix(barcode.count-3))
    }

    guard
      let compressed = try? barcode.fromBase45()
    else {
      XCTAssert(false)
      return
    }

    let data = decompress(compressed)
    let decoder = SwiftCBOR.CBORDecoder(input: data.uint)

    guard
      let cbor = try? decoder.decodeItem(),
      case let CBOR.tagged(tag, cborElement) = cbor,
      tag.rawValue == COSE_TAG, // SIGN1
      case let CBOR.array(array) = cborElement,
      case let CBOR.byteString(protectedBytes) = array[0],
      case let CBOR.byteString(payloadBytes) = array[2],
      let protected = try? CBOR.decode(protectedBytes),
      let payload = try? CBOR.decode(payloadBytes),
      case let CBOR.map(protectedMap) = protected
    else {
      XCTAssert(false)
      return
    }
    guard case let CBOR.byteString(kid) = protectedMap[COSE_PHDR_KID] ?? .null else {
      XCTAssert(false)
      return
    }

    guard
      let trustData = trustJson.data(using: .utf8),
      let trustSerialization = try? JSONSerialization.jsonObject(with: trustData, options: []),
      let trust = trustSerialization as? [[String: Any]]
    else {
      XCTAssert(false)
      return
    }
    for case let elem: Dictionary in trust {
      if
        kid == Data(hexString: elem["kid"] as! String)?.uint,
        let x = (elem["coord"] as? Array<Any>)?[0] as? String,
        let y = (elem["coord"] as? Array<Any>)?[1] as? String
      {
        print("We know this KID - check if this sig works...")
        if COSE.verify(cbor, with: x, and: y) {
          print("All is well! Payload: ", payload)
          return
        }
        print("- sig failed - which is OK - we may have more matching KIDS --")
      }
    }
    print("Nope - all failed - sadness all around")
    XCTAssert(false)
  }
}

/**

 Produces:

 All is well! Payload:  map([SwiftCBOR.CBOR.utf8String("foo"): SwiftCBOR.CBOR.utf8String("bar")])

 */
