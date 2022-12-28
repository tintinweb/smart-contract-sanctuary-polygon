/**
 *Submitted for verification at polygonscan.com on 2022-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library console {
  address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint256 payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
  }

  function logUint(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint256 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint256 p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
  }

  function log(uint256 p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
  }

  function log(uint256 p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
  }

  function log(uint256 p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
  }

  function log(string memory p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint256 p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    uint256 p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    uint256 p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    uint256 p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    uint256 p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    uint256 p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint256 p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
  }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if the sender is not the owner.
   */
  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// https://github.com/ensdomains/ens-contracts/blob/master/contracts/ethregistrar/StringUtils.sol
library StringUtils {
  /**
   * @dev Returns the length of a given string
   *
   * @param s The string to measure the length of
   * @return The length of the input string
   */
  function strlen(string memory s) internal pure returns (uint256) {
    uint256 len;
    uint256 i = 0;
    uint256 bytelength = bytes(s).length;
    for (len = 0; i < bytelength; len++) {
      bytes1 b = bytes(s)[i];
      if (b < 0x80) {
        i += 1;
      } else if (b < 0xE0) {
        i += 2;
      } else if (b < 0xF0) {
        i += 3;
      } else if (b < 0xF8) {
        i += 4;
      } else if (b < 0xFC) {
        i += 5;
      } else {
        i += 6;
      }
    }
    return len;
  }
}

contract NounsAmidakuji is Ownable {
  using StringUtils for string;

  event msgEvent(address indexed from, string msg);

  uint256 public currentGameId;
  uint256 public baseStartTime;
  uint256 public startTimeDuration = 1 days; // 86400s

  struct PrivateGame {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint8 atariPosition; // A->1 ~ F->6
    address[] players;
    uint8[] playerPositions; // playersと同じindexに格納
    string[] playerNames; // playersと同じindexに格納
    address[] linePlayers;
    uint8[] linesX; // linePlayersと同じindexに格納
    uint8[] linesY; // linePlayersと同じindexに格納
  }

  struct PublicGame {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    address[] players;
    string[] playerNames;
    uint8[] playerPositions;
    uint8[] myLinesX;
    uint8[] myLinesY;
  }

  struct ResultGame {
    uint256 id;
    uint256 startTime;
    uint256 endTime;
    uint8 atariPosition;
    address winner;
    address[] players;
    uint8[] playerPositions;
    string[] playerNames;
    uint8[] myLinesX;
    uint8[] myLinesY;
    bool[12][] amidaMap;
  }

  mapping(uint256 => PrivateGame) private _games;

  constructor() {
    currentGameId = 0;
    baseStartTime = 1672185600; // 2022-12-28 09:00:00 (JST)
  }

  function _randMod(uint256 _nonce, uint256 _modulus) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _nonce))) % _modulus;
  }

  // _setup (by first entry): ゲームの初期設定。あたりの場所をprivate変数に格納
  function _setup(uint256 _nonce) private returns (uint256) {
    uint256 beforeGameStartTime = _games[currentGameId].startTime;
    if (beforeGameStartTime == 0) {
      beforeGameStartTime = baseStartTime;
    }

    // 前回の開始日からの日付差分
    // 暫定で300年くらいプレイされなくても大丈夫
    uint256 beforeGameDiffDate;
    for (uint256 i = 1; i < 100000; i++) {
      if (beforeGameStartTime + (startTimeDuration * (i + 1)) > block.timestamp) {
        beforeGameDiffDate = i;
        break;
      }
    }

    currentGameId++;
    _games[currentGameId].id = currentGameId;
    // YYYY/MM/DD 09:00:00(JST)
    _games[currentGameId].startTime = beforeGameStartTime + (beforeGameDiffDate * startTimeDuration);
    _games[currentGameId].endTime = beforeGameStartTime + (beforeGameDiffDate * startTimeDuration) + startTimeDuration;
    _games[currentGameId].atariPosition = uint8(_randMod(_nonce, 6) + 1);

    return currentGameId;
  }

  function _myLines(uint256 _id) private view returns (uint8[] memory, uint8[] memory) {
    uint8[] memory myLinesX = new uint8[](2);
    uint8[] memory myLinesY = new uint8[](2);

    uint8 count = 0;
    for (uint256 i = 0; i < _games[_id].linePlayers.length; i++) {
      if (_games[_id].linePlayers[i] == msg.sender) {
        myLinesX[count] = _games[_id].linesX[i];
        myLinesY[count] = _games[_id].linesY[i];
        count++;
      }
    }

    return (myLinesX, myLinesY);
  }

  function _lineToMap(uint256 _id) private view returns (bool[12][] memory) {
    bool[12][] memory map = new bool[12][](6);

    // mapping
    for (uint256 i = 0; i < _games[_id].linePlayers.length; i++) {
      uint8 lineX = _games[_id].linesX[i];
      uint8 lineY = _games[_id].linesY[i];
      if (lineX != 0 && lineY != 0) {
        map[lineX - 1][lineY - 1] = true;
      }
    }

    return map;
  }

  function _calcWinner(uint256 _id) private view returns (address) {
    uint256 currentPos = _games[_id].atariPosition;
    address winner;
    // アクセスするときは添字が逆になるのに注意
    bool[12][] memory map = _lineToMap(_id);

    // // 配列の後ろから逆算していく
    for (uint256 i = 12; i > 0; i--) {
      if (map[currentPos - 1][i - 1] == true) {
        // 終点とマッチ
        currentPos = currentPos + 1;
      } else if (currentPos >= 2) {
        if (map[currentPos - 2][i - 1] == true) {
          // 始点とマッチ
          currentPos = currentPos - 1;
        }
      }
    }

    for (uint256 i = 0; i < _games[_id].playerPositions.length; i++) {
      if (_games[_id].playerPositions[i] == currentPos) {
        // playerPositionsとplayersの配列の添字は紐づいている
        winner = _games[_id].players[i];
      }
    }

    return winner;
  }

  // entry: ゲームへのエントリー（ゲームが開催されてなかったら作成される）
  function entry(string memory _name, uint8 _pos) public returns (bool) {
    uint256 gameId = currentGameId;

    if (_games[gameId].startTime + startTimeDuration < block.timestamp) {
      gameId = _setup(uint256(keccak256(abi.encodePacked(block.timestamp))));
    }

    // 重複参加のチェック
    for (uint256 i = 0; i < _games[gameId].players.length; i++) {
      require(_games[gameId].players[i] != msg.sender, "Already player exists");
    }

    // ポジションの重複チェック
    for (uint256 i = 0; i < _games[gameId].playerPositions.length; i++) {
      require(_games[gameId].playerPositions[i] != _pos, "Already pos exists");
    }

    // name check
    // Feature: 英数字チェック
    require(_name.strlen() >= 0 && _name.strlen() <= 3, "Name is invalid");
    require(_pos >= 1 && _pos <= 6, "Invalid x Position");

    _games[gameId].players.push(msg.sender);
    _games[gameId].playerPositions.push(_pos);
    _games[gameId].playerNames.push(_name);

    emit msgEvent(msg.sender, "DONE");
    return true; // succeed
  }

  // draw: 2本の線を引く。private領域へ情報を格納。1人２本引ける
  // xStartPosはA,C,Eが1~12の奇数, B,Dが2~12の偶数
  function draw(
    uint8 xStartPos1,
    uint8 y1,
    uint8 xStartPos2,
    uint8 y2
  ) public returns (bool) {
    uint256 gameId = currentGameId;
    require(_games[gameId].startTime + startTimeDuration > block.timestamp, "Game is not started");

    // 参加チェック
    bool canDraw = false;
    for (uint256 i = 0; i < _games[gameId].players.length; i++) {
      if (_games[gameId].players[i] == msg.sender) {
        canDraw = true;
      }
    }
    require(canDraw, "Does not entry");

    // A:1 ~ E:5
    require(xStartPos1 >= 1 && xStartPos1 <= 5, "Invalid x Position");
    require(y1 >= 1 && y1 <= 12, "Invalid y1 Position");
    require(xStartPos2 >= 1 && xStartPos2 <= 5, "Invalid x Position");
    require(y2 >= 1 && y2 <= 12, "Invalid y2 Position");

    // 奇数偶数チェック
    // A,C,E
    if (xStartPos1 == 1 || xStartPos1 == 3 || xStartPos1 == 5) {
      require(y1 % 2 == 1, "Invalid y1 position");
    } else {
      require(y1 % 2 == 0, "Invalid y1 position");
    }
    if (xStartPos2 == 1 || xStartPos2 == 3 || xStartPos2 == 5) {
      require(y2 % 2 == 1, "Invalid y2 position");
    } else {
      require(y2 % 2 == 0, "Invalid y2 position");
    }

    // 1人2本チェック
    uint8 count;
    for (uint256 i = 0; i < _games[gameId].linePlayers.length; i++) {
      if (_games[gameId].linePlayers[i] == msg.sender) {
        count++;
      }
    }
    require(count < 2, "Already drawing 2 positions");

    _games[gameId].linesX.push(xStartPos1);
    _games[gameId].linesY.push(y1);
    _games[gameId].linesX.push(xStartPos2);
    _games[gameId].linesY.push(y2);
    _games[gameId].linePlayers.push(msg.sender);
    _games[gameId].linePlayers.push(msg.sender);

    emit msgEvent(msg.sender, "DONE");
    return true;
  }

  // 勝った人が自分の意思でmintできる
  // result: ゲーム結果を得る
  function result(uint256 _id) public view returns (ResultGame memory) {
    require(_games[_id].startTime + startTimeDuration < block.timestamp, "Game is not ended");
    (uint8[] memory myLinesX, uint8[] memory myLinesY) = _myLines(_id);

    ResultGame memory _game = ResultGame({
      id: _games[_id].id,
      startTime: _games[_id].startTime,
      endTime: _games[_id].endTime,
      atariPosition: _games[_id].atariPosition,
      winner: _calcWinner(_id),
      players: _games[_id].players,
      playerPositions: _games[_id].playerPositions,
      playerNames: _games[_id].playerNames,
      myLinesX: myLinesX,
      myLinesY: myLinesY,
      amidaMap: _lineToMap(_id)
    });
    return _game;
  }

  // BeforeRevealGameのGameを返す
  function game(uint256 _id) public view returns (PublicGame memory) {
    (uint8[] memory myLinesX, uint8[] memory myLinesY) = _myLines(_id);

    PublicGame memory _game = PublicGame({
      id: _games[_id].id,
      startTime: _games[_id].startTime,
      endTime: _games[_id].endTime,
      players: _games[_id].players,
      playerNames: _games[_id].playerNames,
      playerPositions: _games[_id].playerPositions,
      myLinesX: myLinesX,
      myLinesY: myLinesY
    });
    return _game;
  }

  function isHeld() public view returns (bool) {
    uint256 gameId = currentGameId;
    return _games[gameId].startTime + startTimeDuration >= block.timestamp;
  }
}