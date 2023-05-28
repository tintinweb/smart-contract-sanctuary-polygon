/**
 *Submitted for verification at polygonscan.com on 2023-05-27
*/

// File: hardhat/console.sol


pragma solidity >= 0.4.22 <0.9.0;

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

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// File: contracts/contracts/breeding/IBreedingCenter.sol



pragma solidity ^0.8.0;

interface IBreedingCenter {
    /**
     * @dev this function is used to breed
     * @param _parentOneId uint256
     * @param _parentTwoId uint256
     */
    function breed(uint256 _parentOneId, uint256 _parentTwoId)
        external
        returns (uint256);

    /**
     * @dev admin will use this function to add metadata for the breeded NFT
     * @param _eggId uint256
     * @param _dna uint256
     * @param _uri string memory
     * @param _metadataUri string memory
     */
    function createBaby(
        uint256 _eggId,
        uint256 _dna,
        string memory _uri,
        string memory _metadataUri
    ) external;

    /**
     * @dev user will use this function to hatch the egg and obtain new NFT
     * @param _eggId uint256
     */
    function hatch(uint256 _eggId)
        external
        returns (
            uint256 eggId,
            uint256 _dna,
            uint256 _parentOne,
            uint256 _parentTwo,
            string memory _kind,
            string memory _uri,
            string memory _metadataUri
        );
}

// File: contracts/contracts/auction/IAuction.sol



pragma solidity ^0.8.0;

interface IAuction {
    /**
     * @dev this function is meant to initialize the auction
     * @param _tokenId uint256
     * @param _amount uint256
     * @param _minPrice uint256
     * @param _owner address
     * @param _startingTime uint256
     * @param _endingTime uint256
     * @param _isUserAllowedToCancel bool
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _minPrice,
        address _owner,
        uint256 _startingTime,
        uint256 _endingTime,
        bool _isUserAllowedToCancel
    ) external returns (uint256);

    /**
     * @dev this function is meant to cancel auction under certain conditions
     * @param auctionId uint256
     */
    function cancelAuction(uint256 auctionId) external returns (uint256);

    /**
     * @dev this function accepts bid in the auction
     * @param _auctionId uint256
     * @param _price uint256
     * @param _from address
     * @param _amount uint256
     */
    function bidInAuction(
        uint256 _auctionId,
        uint256 _price,
        address _from,
        uint256 _amount
    ) external returns (uint256);

    /**
     * @dev this function is meant to withdraw bid which is not current placed
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function withdrawBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external returns (uint256);

    /**
     * @dev this function is meant to allow the owner to accept bids
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function acceptBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external;

    /**
     * @dev this function is meant to withdraw item and remaining money from the auction
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function claimReward(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external returns (uint256, uint256);

    /**
     * @dev this function returns remaining items which are left
     * @param _auctionId uint256
     * @param _from address
     */
    function returnRemains(uint256 _auctionId, address _from)
        external
        returns (uint256);
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: contracts/contracts/utils/AccessControl.sol



pragma solidity ^0.8.0;


contract AccessControl {
    /**
     * Access control
     */
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private adminSet;
    address internal owner;

    /**
     * @dev modifier for only admin access
     */
    modifier onlyAdmin() {
        require(
            adminSet.contains(msg.sender) || msg.sender == owner,
            "You are not authorized"
        );
        _;
    }

    /**
     *  @dev add new admin for managing this ERC1155 token
     *  @param _address address
     */
    function addAdmin(address _address) public virtual onlyAdmin {
        require(_address != address(0), "The address is 0");
        adminSet.add(_address);
    }

    /**
     *  @dev remove admin rights from an account
     *  @param _address address
     */
    function removeAdmin(address _address) public onlyAdmin {
        adminSet.remove(_address);
    }

    /**
     *  @dev remove admin rights from an account
     *  @param _address address
     */
    function isAdmin(address _address) public view onlyAdmin returns (bool) {
        return adminSet.contains(_address);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: contracts/contracts/auction/GigAuction.sol



pragma solidity ^0.8.0;




contract GigAuction is IAuction, AccessControl {
    using Counters for Counters.Counter;

    /**
     * Auction Market Address
     */
    address AUCTION_MARKET_ADDRESS;

    /**
     * Auctionmetadata Structure
     */
    struct AuctionMetadata {
        uint256 gigAuctionId;
        uint256 tokenId;
        uint256 amount;
        uint256 minPrice;
        address owner;
        uint256 startingTime;
        uint256 endingTime;
        bool isAuctionCancelled;
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool isWithdraw;
        bool isUserAllowedToCancel;
    }
    mapping(uint256 => AuctionMetadata) auctionRegistry;
    Counters.Counter private gigAuctionId;

    /**
     * Bidding Storage Structure
     */
    struct BiddingData {
        uint256 bidId;
        uint256 bid;
        address bidder;
        uint256 amount;
        bool active;
        bool accepted;
        bool claimed;
    }
    // Counters.Counter private bidIdCounter;
    mapping(uint256 => mapping(uint256 => BiddingData)) biddingRegistry;
    mapping(uint256 => Counters.Counter) biddingCounterRegistry;
    mapping(uint256 => BiddingData[]) bidsLUTs;

    /**
     * events
     */
    event AuctionCreated(
        uint256 gigAuctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 minPrice,
        address owner,
        uint256 startingTime,
        uint256 endingTime,
        bool isAuctionCancelled,
        bool isAuctionStarted,
        bool isAuctionEnded,
        bool isUserAllowedToCancel
    );
    event AuctionCancelled(
        uint256 gigAuctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 minPrice,
        address owner,
        uint256 startingTime,
        uint256 endingTime,
        bool isAuctionCancelled,
        bool isAuctionStarted,
        bool isAuctionEnded,
        bool isUserAllowedToCancel
    );
    event AuctionBid(
        uint256 gigAuctionId,
        uint256 bidId,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event AuctionBidWithdraw(
        uint256 gigAuctionId,
        uint256 bidId,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event AuctionBidAccept(
        uint256 gigAuctionId,
        uint256 bidId,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event AuctionReward(
        uint256 gigAuctionId,
        uint256 tokenId,
        uint256 bidId,
        uint256 price,
        uint256 amount,
        address bidder
    );
    event AuctionRemains(
        uint256 gigAuctionId,
        uint256 tokenId,
        uint256 amount,
        address owner
    );

    /**
     * @dev contructor setting admin account
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev set auction market address
     * @param _auctionMarket address
     */
    function setAuctionMarket(address _auctionMarket) public onlyAdmin {
        AUCTION_MARKET_ADDRESS = _auctionMarket;
    }

    /**
     * @dev this function is meant to initialize the auction
     * @param _tokenId uint256
     * @param _amount uint256
     * @param _minPrice uint256
     * @param _owner address
     * @param _startingTime uint256
     * @param _endingTime uint256
     * @param _isUserAllowedToCancel bool
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _minPrice,
        address _owner,
        uint256 _startingTime,
        uint256 _endingTime,
        bool _isUserAllowedToCancel
    ) external override returns (uint256) {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(_amount != 0, "token amount should not be 0");
        require(
            _startingTime < _endingTime,
            "end time is before the start time"
        );
        require(_owner != address(0), "owner can have 0x0 as address");
        gigAuctionId.increment();
        uint256 auctionId = gigAuctionId.current();

        auctionRegistry[auctionId] = AuctionMetadata(
            auctionId,
            _tokenId,
            _amount,
            _minPrice,
            _owner,
            _startingTime,
            _endingTime,
            false,
            false,
            false,
            false,
            _isUserAllowedToCancel
        );

        emit AuctionCreated(
            auctionId,
            _tokenId,
            _amount,
            _minPrice,
            _owner,
            _startingTime,
            _endingTime,
            false,
            false,
            false,
            _isUserAllowedToCancel
        );

        return auctionId;
    }

    /**
     * @dev this function is meant to cancel auction under certain conditions
     * @param _auctionId uint256
     */
    function cancelAuction(uint256 _auctionId)
        external
        override
        returns (uint256)
    {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction is already cancelled"
        );
        require(
            auctionRegistry[_auctionId].gigAuctionId != 0,
            "The auction does not exists"
        );
        require(
            auctionRegistry[_auctionId].amount != 0,
            "Auction is already completed"
        );
        auctionRegistry[_auctionId].isAuctionCancelled = true;

        emit AuctionCancelled(
            auctionRegistry[_auctionId].gigAuctionId,
            auctionRegistry[_auctionId].tokenId,
            auctionRegistry[_auctionId].amount,
            auctionRegistry[_auctionId].minPrice,
            auctionRegistry[_auctionId].owner,
            auctionRegistry[_auctionId].startingTime,
            auctionRegistry[_auctionId].endingTime,
            auctionRegistry[_auctionId].isAuctionCancelled,
            auctionRegistry[_auctionId].isAuctionStarted,
            auctionRegistry[_auctionId].isAuctionEnded,
            auctionRegistry[_auctionId].isUserAllowedToCancel
        );

        return (auctionRegistry[_auctionId].amount);
    }

    /**
     * @dev this function accepts bid in the auction
     * @param _auctionId uint256
     * @param _price uint256
     * @param _from address
     * @param _amount uint256
     */
    function bidInAuction(
        uint256 _auctionId,
        uint256 _price,
        address _from,
        uint256 _amount
    ) external override returns (uint256) {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction is cancelled"
        );
        require(
            block.timestamp >= auctionRegistry[_auctionId].startingTime,
            "Auction is not in progress"
        );
        require(
            block.timestamp < auctionRegistry[_auctionId].endingTime,
            "Auction Ended"
        );
        require(
            _amount <= auctionRegistry[_auctionId].amount,
            "Enough items not available"
        );
        biddingCounterRegistry[_auctionId].increment();
        uint256 bidIndex = biddingCounterRegistry[_auctionId].current();
        BiddingData memory bd = BiddingData(
            bidIndex,
            _price,
            _from,
            _amount,
            true,
            false,
            false
        );
        biddingRegistry[_auctionId][bidIndex] = bd;
        bidsLUTs[_auctionId].push(bd);

        emit AuctionBid(_auctionId, bidIndex, _from, _price, _amount);

        return bidIndex;
    }

    /**
     * @dev return the lookup table for bids
     * @param _auctionId uint256
     */
    function returnLUT(uint256 _auctionId)
        public
        view
        returns (BiddingData[] memory)
    {
        return bidsLUTs[_auctionId];
    }

    /**
     * @dev this function is meant to withdraw bid which is not current placed
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function withdrawBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external override returns (uint256) {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            biddingRegistry[_auctionId][_bidId].bidder == _from,
            "This is not your bid"
        );
        require(
            biddingRegistry[_auctionId][_bidId].accepted == false,
            "Bid has been already accepted"
        );
        require(
            biddingRegistry[_auctionId][_bidId].active != false,
            "Bid has been already withdrawn"
        );
        emit AuctionBidWithdraw(
            _auctionId,
            _bidId,
            _from,
            biddingRegistry[_auctionId][_bidId].bid,
            biddingRegistry[_auctionId][_bidId].amount
        );

        biddingRegistry[_auctionId][_bidId].active = false;
        bidsLUTs[_auctionId][_bidId - 1].active = false;

        return (biddingRegistry[_auctionId][_bidId].bid);
    }

    /**
     * @dev this function is meant to allow the owner to accept bids
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _owner address
     */
    function acceptBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _owner
    ) external override {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction is cancelled"
        );
        require(
            auctionRegistry[_auctionId].gigAuctionId == _auctionId,
            "Auction doesnot exists"
        );
        require(
            auctionRegistry[_auctionId].owner == _owner,
            "You are not the owner of the Auciton"
        );
        require(
            biddingRegistry[_auctionId][_bidId].active == true,
            "Bid has been withdrawn by the bidder"
        );
        require(
            biddingRegistry[_auctionId][_bidId].accepted == false,
            "Bid has been already accepted"
        );
        require(
            biddingRegistry[_auctionId][_bidId].amount <=
                auctionRegistry[_auctionId].amount,
            "Bid amount is greater than available amount"
        );
        emit AuctionBidAccept(
            _auctionId,
            _bidId,
            biddingRegistry[_auctionId][_bidId].bidder,
            biddingRegistry[_auctionId][_bidId].bid,
            biddingRegistry[_auctionId][_bidId].amount
        );
        bidsLUTs[_auctionId][_bidId - 1].active = false;
        bidsLUTs[_auctionId][_bidId - 1].accepted = true;
        biddingRegistry[_auctionId][_bidId].active = false;
        biddingRegistry[_auctionId][_bidId].accepted = true;

        auctionRegistry[_auctionId].amount =
            auctionRegistry[_auctionId].amount -
            biddingRegistry[_auctionId][_bidId].amount;
    }

    /**
     * @dev this function is used to claim item for accept bid
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function claimReward(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external override returns (uint256, uint256) {
        require(
            AUCTION_MARKET_ADDRESS != address(0),
            "market Auction is not set"
        );
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            biddingRegistry[_auctionId][_bidId].bidder == _from,
            "This is not your bid"
        );
        require(
            biddingRegistry[_auctionId][_bidId].accepted == true,
            "Bid is not yet accepted by the owner"
        );
        require(
            biddingRegistry[_auctionId][_bidId].claimed == false,
            "Reward has been claimed"
        );
        if (biddingRegistry[_auctionId][_bidId].accepted) {
            bidsLUTs[_auctionId][_bidId - 1].claimed = true;
            biddingRegistry[_auctionId][_bidId].claimed = true;
            emit AuctionReward(
                _auctionId,
                auctionRegistry[_auctionId].tokenId,
                _bidId,
                biddingRegistry[_auctionId][_bidId].bid,
                biddingRegistry[_auctionId][_bidId].amount,
                _from
            );
        }
        return (
            biddingRegistry[_auctionId][_bidId].bid,
            biddingRegistry[_auctionId][_bidId].amount
        );
    }

    function returnRemains(uint256 _auctionId, address _from)
        external
        override
        returns (uint256)
    {
        require(
            msg.sender == AUCTION_MARKET_ADDRESS,
            "function can only be called from auction market"
        );
        require(
            block.timestamp > auctionRegistry[_auctionId].endingTime,
            "Auction has not ended"
        );
        require(
            auctionRegistry[_auctionId].owner == _from,
            "You are not the owner"
        );
        auctionRegistry[_auctionId].isWithdraw = true;
        uint256 amountToReturn = auctionRegistry[_auctionId].amount;
        auctionRegistry[_auctionId].amount = 0;
        emit AuctionRemains(
            _auctionId,
            auctionRegistry[_auctionId].tokenId,
            amountToReturn,
            auctionRegistry[_auctionId].owner
        );
        return amountToReturn;
    }
}

// File: contracts/contracts/auction/SimpleAuction.sol



pragma solidity ^0.8.0;




contract SimpleAuction is IAuction, AccessControl {
    using Counters for Counters.Counter;

    /**
     * Auction Market Address
     */
    address AUCTION_MARKET;

    /**
     * Auctionmetadata Structure
     */
    struct AuctionMetadata {
        uint256 simpleAuctionId;
        uint256 tokenId;
        uint256 amount;
        uint256 minPrice;
        address owner;
        uint256 numOfBidsStored;
        uint256 startingTime;
        uint256 endingTime;
        bool isAuctionCancelled;
        bool isAuctionStarted;
        bool isAuctionEnded;
        bool isUserAllowedToCancel;
        bool isReturned;
    }
    mapping(uint256 => AuctionMetadata) auctionRegistry;
    Counters.Counter private simpleAuctionId;

    /**
     * Bidding Storage Structure
     */
    struct BiddingData {
        uint256 bid;
        address bidder;
        uint256 amount;
        bool active;
    }
    mapping(uint256 => mapping(address => BiddingData)) biddingRegistry;
    mapping(uint256 => address) highestBidder;

    /**
     * events
     */
    event SimpleAuctionCreated(
        uint256 simpleAuctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 minPrice,
        address owner,
        uint256 startingTime,
        uint256 endingTime,
        bool isAuctionCancelled,
        bool isAuctionStarted,
        bool isAuctionEnded,
        bool isUserAllowedToCancel
    );
    event SimpleAuctionCancelled(
        uint256 simpleAuctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 minPrice,
        address owner,
        uint256 startingTime,
        uint256 endingTime,
        bool isAuctionCancelled,
        bool isAuctionStarted,
        bool isAuctionEnded,
        bool isUserAllowedToCancel
    );
    event SimpleAuctionBid(
        uint256 simpleAuctionId,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event SimpleAuctionBidWithdraw(
        uint256 simpleAuctionId,
        address bidder,
        uint256 price,
        uint256 amount
    );
    event SimpleAuctionClaimReward(
        uint256 simpleAuctionId,
        uint256 tokenId,
        uint256 price,
        uint256 amount,
        address bidder
    );
    event SimpleAuctionRemains(
        uint256 simpleAuctionId,
        uint256 tokenId,
        uint256 amount,
        address owner
    );

    /**
     * @dev contructor setting admin account
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev this function sets auction market address
     * @param _auctionMarket address
     */
    function setAuctionMarket(address _auctionMarket) public onlyAdmin {
        AUCTION_MARKET = _auctionMarket;
    }

    /**
     * @dev this function is meant to initialize the auction
     * @param _tokenId uint256
     * @param _amount uint256
     * @param _minPrice uint256
     * @param _owner address
     * @param _startingTime uint256
     * @param _endingTime uint256
     * @param _isUserAllowedToCancel bool
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _minPrice,
        address _owner,
        uint256 _startingTime,
        uint256 _endingTime,
        bool _isUserAllowedToCancel
    ) external override returns (uint256) {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(_amount != 0, "token amount should not be 0");
        require(
            _startingTime < _endingTime,
            "end time is before the start time"
        );
        require(_owner != address(0), "owner can have 0x0 as address");
        simpleAuctionId.increment();
        uint256 auctionId = simpleAuctionId.current();

        auctionRegistry[auctionId] = AuctionMetadata(
            auctionId,
            _tokenId,
            _amount,
            _minPrice,
            _owner,
            0,
            _startingTime,
            _endingTime,
            false,
            false,
            false,
            _isUserAllowedToCancel,
            false
        );

        emit SimpleAuctionCreated(
            auctionId,
            _tokenId,
            _amount,
            _minPrice,
            _owner,
            _startingTime,
            _endingTime,
            false,
            false,
            false,
            _isUserAllowedToCancel
        );

        biddingRegistry[auctionId][address(0)] = BiddingData(
            _minPrice - 1,
            address(0),
            _amount,
            true
        );
        highestBidder[auctionId] = address(0);

        return auctionId;
    }

    /**
     * @dev this function is meant to cancel auction under certain conditions
     * @param auctionId uint256
     */
    function cancelAuction(uint256 auctionId)
        external
        override
        returns (uint256)
    {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            auctionRegistry[auctionId].isAuctionCancelled == false,
            "The auction is already cancelled"
        );
        require(
            auctionRegistry[auctionId].simpleAuctionId != 0,
            "The auction does not exists"
        );
        require(
            auctionRegistry[auctionId].isAuctionEnded == false,
            "The auction is already complete"
        );
        require(
            block.timestamp <= auctionRegistry[auctionId].endingTime,
            "Auction is already completed"
        );
        auctionRegistry[auctionId].isAuctionCancelled = true;
        emit SimpleAuctionCancelled(
            auctionRegistry[auctionId].simpleAuctionId,
            auctionRegistry[auctionId].tokenId,
            auctionRegistry[auctionId].amount,
            auctionRegistry[auctionId].minPrice,
            auctionRegistry[auctionId].owner,
            auctionRegistry[auctionId].startingTime,
            auctionRegistry[auctionId].endingTime,
            auctionRegistry[auctionId].isAuctionCancelled,
            auctionRegistry[auctionId].isAuctionStarted,
            auctionRegistry[auctionId].isAuctionEnded,
            auctionRegistry[auctionId].isUserAllowedToCancel
        );

        return (auctionRegistry[auctionId].amount);
    }

    /**
     * @dev this function accepts bid in the auction
     * @param _auctionId uint256
     * @param _price uint256
     * @param _from address
     * @param _amount uint256
     */
    function bidInAuction(
        uint256 _auctionId,
        uint256 _price,
        address _from,
        uint256 _amount
    ) external override returns (uint256) {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction has been cancelled"
        );
        require(
            block.timestamp >= auctionRegistry[_auctionId].startingTime,
            "Auction is not in progress"
        );
        require(
            block.timestamp < auctionRegistry[_auctionId].endingTime,
            "Auction Ended"
        );
        require(
            _price > biddingRegistry[_auctionId][highestBidder[_auctionId]].bid,
            "Lower bid that the current big"
        );
        require(
            _amount == auctionRegistry[_auctionId].amount,
            "You are not bidding for all the items on Auction"
        );
        if (highestBidder[_auctionId] == _from) {
            uint256 newPrice = _price + biddingRegistry[_auctionId][_from].bid;
            biddingRegistry[_auctionId][_from] = BiddingData(
                newPrice,
                _from,
                _amount,
                true
            );
            emit SimpleAuctionBid(_auctionId, _from, newPrice, _amount);
        } else {
            biddingRegistry[_auctionId][highestBidder[_auctionId]]
                .active = false;
            biddingRegistry[_auctionId][_from] = BiddingData(
                _price,
                _from,
                _amount,
                true
            );
            highestBidder[_auctionId] = _from;
            emit SimpleAuctionBid(_auctionId, _from, _price, _amount);
        }
        auctionRegistry[_auctionId].numOfBidsStored += 1;
        return (0);
    }

    /**
     * @dev this function is meant to withdraw bid which is not current placed
     * @param _auctionId uint256
     * @param _bidId uint256
     * @param _from address
     */
    function withdrawBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external override returns (uint256) {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            biddingRegistry[_auctionId][_from].active == false ||
                auctionRegistry[_auctionId].isAuctionCancelled == true,
            "Bid is active"
        );
        require(
            biddingRegistry[_auctionId][_from].bidder == _from,
            "You have not bid yet"
        );
        uint256 _bid = biddingRegistry[_auctionId][_from].bid;
        emit SimpleAuctionBidWithdraw(
            _auctionId,
            _from,
            biddingRegistry[_auctionId][_from].bid,
            biddingRegistry[_auctionId][_from].amount
        );
        delete biddingRegistry[_auctionId][_from];

        auctionRegistry[_auctionId].numOfBidsStored -= 1;

        return (_bid);
    }

    /**
     * @dev this function is meant to withdraw bid which is not current placed
     * @param _auctionId uint256
     * @param _from address
     */
    function claimReward(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external override returns (uint256, uint256) {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction has been cancelled"
        );
        require(
            block.timestamp > auctionRegistry[_auctionId].endingTime,
            "Auction has not Ended Yet"
        );
        require(
            biddingRegistry[_auctionId][_from].bidder == _from,
            "You have not bid yet"
        );
        uint256 _bid = biddingRegistry[_auctionId][_from].bid;

        uint256 amount;
        if (highestBidder[_auctionId] == _from) {
            amount = biddingRegistry[_auctionId][_from].amount;
        } else {
            amount = 0;
        }
        emit SimpleAuctionClaimReward(
            _auctionId,
            auctionRegistry[_auctionId].tokenId,
            biddingRegistry[_auctionId][_from].bid,
            amount,
            _from
        );
        delete biddingRegistry[_auctionId][_from];

        auctionRegistry[_auctionId].numOfBidsStored -= 1;

        return (_bid, amount);
    }

    function acceptBid(
        uint256 _auctionId,
        uint256 _bidId,
        address _from
    ) external override {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            false,
            "You cannot accept a particular bid in this Auction Type"
        );
    }

    /**
     * @dev this function returns remaining items which are left
     * @param _auctionId uint256
     * @param _from address
     */
    function returnRemains(uint256 _auctionId, address _from)
        external
        override
        returns (uint256)
    {
        require(AUCTION_MARKET != address(0), "auction market is not set");
        require(
            msg.sender == AUCTION_MARKET,
            "this function can only be called from auction market"
        );
        require(
            auctionRegistry[_auctionId].isAuctionCancelled == false,
            "Auction has been cancelled"
        );
        require(
            block.timestamp > auctionRegistry[_auctionId].endingTime,
            "Auction has not Ended Yet"
        );
        require(
            highestBidder[_auctionId] == address(0),
            "You have an auction winner"
        );
        require(
            _from == auctionRegistry[_auctionId].owner,
            "You are not the owner"
        );
        auctionRegistry[_auctionId].isAuctionCancelled = true;
        emit SimpleAuctionRemains(
            _auctionId,
            auctionRegistry[_auctionId].tokenId,
            auctionRegistry[_auctionId].amount,
            auctionRegistry[_auctionId].owner
        );
        return auctionRegistry[_auctionId].amount;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/contracts/GameAssets.sol



pragma solidity ^0.8.0;




contract GameAssets is ERC1155, AccessControl {
    /**
     * Storing the URI of a token
     * Storing the URI of the Metadata
     * Storing dna for token ID
     * Storing paraent token ID
     * Storing breeding option
     */
    struct Parents {
        uint256 parentOne;
        uint256 parentTwo;
    }
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => string) private _tokenMetadataURIs;
    mapping(uint256 => uint256) private _dnaRegistry;
    mapping(uint256 => string) private _tokenKind;
    mapping(uint256 => Parents) private _parentTokenIdRegistry;
    mapping(uint256 => bool) private _breedableRegistry;

    struct MetadataOutput {
        string uri;
        string metadataUri;
        string kind;
        uint256 dna;
        uint256 parentOne;
        uint256 parentTwo;
        bool breedable;
    }

    /**
     * TokenURI counter
     */
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;

    /**
     * Market Place address
     */
    address MarketPlace;

    /**
     * Events
     */
    event NFTMinted(
        uint256 tokenId,
        string uri,
        string metadataUri,
        uint256 amount,
        string tokenKind,
        uint256 dna,
        uint256 parentOneId,
        uint256 parentTwoId,
        bool isBreedable
    );

    /**
     * @dev deploy an instance of the contract and set the msg.sender as an admin
     */
    constructor() ERC1155("") {
        owner = msg.sender;
    }

    /**
     * @dev set uri directly from the market place
     * @param _tokenId uint256
     * @param _tokenURI string memort
     */
    function setURI(uint256 _tokenId, string memory _tokenURI) public {
        // minting rights restricted to Market Place
        require(
            msg.sender == MarketPlace,
            "Only market place can be used to mint tokens"
        );
        require(bytes(_tokenURI).length != 0, "URI link is empty");
        require(
            bytes(_tokenURIs[_tokenId]).length != 0,
            "Token does not exists"
        );
        _tokenURIs[_tokenId] = _tokenURI;
    }

    /**
     * @dev this function save the URI of the token Image
     * @param _tokenId uint256
     * @param tokenURI memory string
     */
    function _setTokenUri(uint256 _tokenId, string memory tokenURI) private {
        _tokenURIs[_tokenId] = tokenURI;
    }

    /**
     * @dev this function save the URI of the token metadata
     * @param _tokenId uint256
     * @param tokenmetadataURI memory string
     */
    function _setTokenMetadataUri(
        uint256 _tokenId,
        string memory tokenmetadataURI
    ) private {
        _tokenMetadataURIs[_tokenId] = tokenmetadataURI;
    }

    /**
     * @dev this function save the URI of the token metadata
     * @param _tokenId uint256
     * @param tokenKind memory string
     */
    function _setTokenKind(uint256 _tokenId, string memory tokenKind) private {
        _tokenKind[_tokenId] = tokenKind;
    }

    /**
     * @dev this function is used set dna for a token
     * @param _tokenId uint256
     * @param _dna uint256
     */
    function _setDna(uint256 _tokenId, uint256 _dna) private {
        _dnaRegistry[_tokenId] = _dna;
    }

    /**
     * @dev this function is used set the parent of the token
     * @param _tokenId uint256
     * @param _parentOneTokenId uint256
     * @param _parentTwoTokenId uint256
     */
    function _setParentToken(
        uint256 _tokenId,
        uint256 _parentOneTokenId,
        uint256 _parentTwoTokenId
    ) private {
        _parentTokenIdRegistry[_tokenId] = Parents(
            _parentOneTokenId,
            _parentTwoTokenId
        );
    }

    /**
     * @dev this function is used set the parent of the token
     * @param _tokenId uint256
     * @param _isBreedable uint256
     */
    function _setBreedableOption(uint256 _tokenId, bool _isBreedable) private {
        _breedableRegistry[_tokenId] = _isBreedable;
    }

    /**
     * @dev mint a new token x amount with image and metadata... It emits the event on NFT successful NFT creation
     * @param tokenURI string memory
     * @param tokenMetadataURI string memory
     * @param amount uint256
     */
    function mintToken(
        string memory tokenURI,
        string memory tokenMetadataURI,
        uint256 amount,
        address to,
        string memory tokenKind,
        uint256 _tokenDna,
        uint256 _tokenParentOneId,
        uint256 _tokenParentTwoId,
        bool _isTokenBreedable
    ) public returns (uint256) {
        // minting rights restricted to Market Place
        require(
            msg.sender == MarketPlace,
            "Only market place can be used to mint tokens"
        );
        require(bytes(tokenURI).length != 0, "URI link is empty");
        require(
            bytes(tokenMetadataURI).length != 0,
            "Metadata URI link is empty"
        );
        require(amount != 0, "Amount is 0");
        if (_isTokenBreedable) {
            require(amount == 1, "Breedable token cannot be greate than One");
        }
        tokenId.increment();
        uint256 newItemId = tokenId.current();
        _mint(to, newItemId, amount, "");

        _setTokenUri(newItemId, tokenURI);
        _setTokenMetadataUri(newItemId, tokenMetadataURI);

        _setApprovalForAll(to, MarketPlace, true);

        _setDna(newItemId, _tokenDna);
        _setTokenKind(newItemId, tokenKind);
        _setParentToken(newItemId, _tokenParentOneId, _tokenParentTwoId);

        _setBreedableOption(newItemId, _isTokenBreedable);

        emit NFTMinted(
            newItemId,
            tokenURI,
            tokenMetadataURI,
            amount,
            tokenKind,
            _tokenDna,
            _tokenParentOneId,
            _tokenParentTwoId,
            _isTokenBreedable
        );
        return newItemId;
    }

    /**
     * @dev return uri of the token
     * @param _tokenId uint256
     */
    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return (_tokenURIs[_tokenId]);
    }

    /**
     * @dev return uri of metadata of the token
     * @param _tokenId uint256
     */
    function metadataUri(uint256 _tokenId) public view returns (string memory) {
        return (_tokenMetadataURIs[_tokenId]);
    }

    /**
     * @dev return all metadata
     * @param _tokenId uint256
     */
    function metadata(uint256 _tokenId)
        public
        view
        returns (MetadataOutput memory)
    {
        MetadataOutput memory output;
        output.uri = uri(_tokenId);
        output.metadataUri = metadataUri(_tokenId);
        output.kind = kind(_tokenId);
        output.dna = dna(_tokenId);
        (uint256 parentOne, uint256 parentTwo) = parentId(_tokenId);
        output.parentOne = parentOne;
        output.parentTwo = parentTwo;
        output.breedable = isBreedable(_tokenId);
        return output;
    }

    /**
     * @dev return token kind
     * @param _tokenId uint256
     */
    function kind(uint256 _tokenId) public view returns (string memory) {
        return (_tokenKind[_tokenId]);
    }

    /**
     * @dev return dna of the token
     * @param _tokenId uint256
     */
    function dna(uint256 _tokenId) public view returns (uint256) {
        return (_dnaRegistry[_tokenId]);
    }

    /**
     * @dev return parent id
     * @param _tokenId uint256
     */
    function parentId(uint256 _tokenId) public view returns (uint256, uint256) {
        return (
            _parentTokenIdRegistry[_tokenId].parentOne,
            _parentTokenIdRegistry[_tokenId].parentTwo
        );
    }

    /**
     * @dev return parent id
     * @param _tokenId uint256
     */
    function isBreedable(uint256 _tokenId) public view returns (bool) {
        return (_breedableRegistry[_tokenId]);
    }

    // check this
    /**
     * @dev save the market place address for future references
     * @param _marketPlaceAddress address
     */
    function setMarketsAddress(address _marketPlaceAddress) public onlyAdmin {
        MarketPlace = _marketPlaceAddress;
    }

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        // Only Market Place can be used to transfer tokens
        require(
            msg.sender == MarketPlace,
            "Only market place can be used to transfer tokens"
        );
        super._safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev gives approval to the Market Place
     * @param operator address
     * @param from address
     * @param to address
     * @param ids uint256[]
     * @param data uint256[]
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(MarketPlace != address(0), "Marketplace address not set");
        if (to != MarketPlace) {
            _setApprovalForAll(to, MarketPlace, true);
        }
    }
}

// File: contracts/contracts/breeding/BreedingCenter.sol



pragma solidity ^0.8.0;






contract BreedingCenter is AccessControl {
    using Counters for Counters.Counter;

    /**
     * Game Asset address
     * Breeding Market Place
     */
    address private GAME_ASSET;

    /**
     * DNA information
     */
    uint256 COMPONENT_IN_DNA = 25;

    /**
     * Incubation duration
     */
    uint256 INCUBATION_PERIOD;

    /**
     * Egg ID counter
     * Egg metadata
     */

    struct eggMetadata {
        uint256 eggId;
        uint256 dna;
        uint256 parentOne;
        uint256 parentTwo;
        bool isConceived;
        string kind;
        string uri;
        string metadataUri;
        bool isHatched;
        uint256 hatchingTime;
    }
    Counters.Counter private eggId;
    mapping(uint256 => eggMetadata) eggRegistery;

    /**
     * events
     */
    event EggCreated(
        uint256 eggId,
        uint256 dna,
        uint256 parentOne,
        uint256 parentTwo,
        string kind,
        bool isConceived,
        bool isHatched,
        uint256 incubationPeriod
    );
    event CreateBaby(
        uint256 eggId,
        uint256 dna,
        string uri,
        string metadataUri
    );
    event HatchedEgg(
        uint256 eggId,
        uint256 dna,
        uint256 parentOne,
        uint256 parentTwo,
        string kind,
        string uri,
        string metadataUri
    );

    /**
     * @dev constructor sets the owner who can be used to set admin
     */
    constructor(address _owner) {
        owner = _owner;
        INCUBATION_PERIOD = 1 minutes;
    }

    /**
     * @dev set address of GameAsset contract
     * @param _gameAssetContract address
     */
    function setGameAssetContract(address _gameAssetContract) public onlyAdmin {
        GAME_ASSET = _gameAssetContract;
    }

    /**
     * @dev set incubation time
     * @param _timePeriod uint256
     */
    function setIncubationTime(uint256 _timePeriod) public onlyAdmin {
        INCUBATION_PERIOD = _timePeriod;
    }

    /**
     * @dev returns incubation time
     */
    function getIncubationTime() public view returns (uint256) {
        return (INCUBATION_PERIOD);
    }

    // /**
    //  *@dev this function calculate new DNA
    //  */
    // function calculateDNA(uint256 dnaOne, uint256 dnaTwo)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     uint256[] memory dnaOneComponents = new uint256[](25);
    //     uint256[] memory dnaTwoComponents = new uint256[](25);

    //     for (uint256 i = 0; i < COMPONENT_IN_DNA; i++) {
    //         uint256 tempComp = dnaOne % 1000;
    //         dnaOneComponents[i] = tempComp;
    //         dnaOne = dnaOne / 1000;
    //         tempComp = dnaTwo % 1000;
    //         dnaTwoComponents[i] = tempComp;
    //         dnaTwo = dnaTwo / 1000;
    //     }

    //     return 1;
    // }

    /**
     * @dev incest check
     * @param _parentOneId uint256
     * @param _parentTwoId uint256
     */
    function bloodRelationCheck(uint256 _parentOneId, uint256 _parentTwoId)
        private
        view
    {
        uint256 parent1;
        uint256 parent2;
        uint256 parent3;
        uint256 parent4;
        (parent1, parent2) = GameAssets(GAME_ASSET).parentId(_parentOneId);
        require(
            _parentTwoId != parent1 && _parentTwoId != parent2,
            "One if a parent of other"
        );
        (parent3, parent4) = GameAssets(GAME_ASSET).parentId(_parentTwoId);
        require(
            _parentOneId != parent3 && _parentOneId != parent4,
            "One if a parent of other"
        );
        require(
            (parent1 == 0 && parent2 == 0) ||
                (parent3 == 0 && parent4 == 0) ||
                (parent1 != parent3 &&
                    parent1 != parent4 &&
                    parent2 != parent3 &&
                    parent2 != parent4),
            "They are siblings"
        );
    }

    /**
     * @dev this function is used to breed
     * @param _parentOneId uint256
     * @param _parentTwoId uint256
     */
    function _breed(uint256 _parentOneId, uint256 _parentTwoId)
        internal
        returns (uint256)
    {
        require(GAME_ASSET != address(0), "Game Asset address not set");
        require(
            _parentOneId != 0 && _parentTwoId != 0,
            "You have forgotten to add parent id"
        );
        require(
            GameAssets(GAME_ASSET).isBreedable(_parentOneId),
            "Token One is not breedable"
        );
        require(
            GameAssets(GAME_ASSET).isBreedable(_parentTwoId),
            "Token Two is not breedable"
        );

        bloodRelationCheck(_parentOneId, _parentTwoId);

        eggId.increment();
        uint256 currentEggId = eggId.current();
        // uint256 _dna1 = GameAssets(GAME_ASSET).dna(_parentOneId);
        // uint256 _dna2 = GameAssets(GAME_ASSET).dna(_parentTwoId);
        // uint256 currentDna = calculateDNA(_dna1, _dna2);

        string memory _kind = GameAssets(GAME_ASSET).kind(_parentOneId);

        eggRegistery[currentEggId] = eggMetadata(
            currentEggId,
            0,
            _parentOneId,
            _parentTwoId,
            false,
            _kind,
            "",
            "",
            false,
            block.timestamp + INCUBATION_PERIOD
        );

        emit EggCreated(
            currentEggId,
            0,
            _parentOneId,
            _parentTwoId,
            _kind,
            false,
            false,
            block.timestamp + INCUBATION_PERIOD
        );

        return currentEggId;
    }

    /**
     * @dev admin will use this function to add metadata for the breeded NFT
     * @param _eggId uint256
     * @param _dna uint256
     * @param _uri string memory
     * @param _metadataUri string memory
     */
    function _createBaby(
        uint256 _eggId,
        uint256 _dna,
        string memory _uri,
        string memory _metadataUri
    ) internal {
        require(
            eggRegistery[_eggId].eggId == _eggId,
            "The egg does not exists"
        );
        require(eggRegistery[_eggId].dna == 0, "DNA has already been added");
        require(_dna != 0, "DNA is empty");
        require(bytes(_uri).length != 0, "URI is empty");
        require(bytes(_metadataUri).length != 0, "Metadata URI is empty");
        eggRegistery[_eggId].dna = _dna;
        eggRegistery[_eggId].uri = _uri;
        eggRegistery[_eggId].metadataUri = _metadataUri;
        eggRegistery[_eggId].isConceived = true;
        emit CreateBaby(_eggId, _dna, _uri, _metadataUri);
    }

    /**
     * @dev emit hatch event
     * @param _eggId uint256
     */
    function hatchEvent(uint256 _eggId) private {
        emit HatchedEgg(
            eggRegistery[_eggId].eggId,
            eggRegistery[_eggId].dna,
            eggRegistery[_eggId].parentOne,
            eggRegistery[_eggId].parentTwo,
            eggRegistery[_eggId].kind,
            eggRegistery[_eggId].uri,
            eggRegistery[_eggId].metadataUri
        );
    }

    /**
     * @dev user will use this function to hatch the egg and obtain new NFT
     * @param _eggId uint256
     */
    function _hatch(uint256 _eggId)
        internal
        returns (
            uint256 _eggTokenId,
            uint256 _dna,
            uint256 _parentOne,
            uint256 _parentTwo,
            string memory _kind,
            string memory _uri,
            string memory _metadataUri
        )
    {
        require(
            eggRegistery[_eggId].eggId == _eggId,
            "The egg does not exists"
        );
        require(!eggRegistery[_eggId].isHatched, "Egg is already hatch");
        require(
            eggRegistery[_eggId].hatchingTime <= block.timestamp,
            "Egg needs incubation"
        );
        require(
            eggRegistery[_eggId].isConceived,
            "Egg is waiting for a mericle"
        );

        eggRegistery[_eggId].isHatched = true;

        hatchEvent(_eggId);
        return (
            eggRegistery[_eggId].eggId,
            eggRegistery[_eggId].dna,
            eggRegistery[_eggId].parentOne,
            eggRegistery[_eggId].parentTwo,
            eggRegistery[_eggId].kind,
            eggRegistery[_eggId].uri,
            eggRegistery[_eggId].metadataUri
        );
    }
}

// File: contracts/contracts/MarketPlace.sol



pragma solidity ^0.8.0;











contract MarketPlace is AccessControl, ERC1155Holder {
    /**
     * MARKET_PLACE_WALLET
     */
    address payable MARKET_PLACE_WALLET;

    /**
     * saves the information of all the token ownership for validation in Marketplace
     * token id => ( account => amount of token owned )
     */
    // mapping(uint256 => mapping(address => uint256)) tokenOwnershipRegistry;

    /**
     * Event
     */
    // add admin
    event MarketAdminAdded(address admin);
    // on successful minting of item/NFT
    event MarketNFTMinted(
        uint256 tokenId,
        string uri,
        string metadataUri,
        uint256 amount,
        address owner
    );
    // on changing uri
    event MarketUriChanged(uint256 tokenId, string uri);
    // on successful transfer of item/NFT
    event MarketTransfer(
        uint256 tokenId,
        address from,
        address to,
        uint256 amount
    );

    /**
     *   important address of the contracts
     */
    address private GameAssetsContract;
    address private BreedingMarketContract;

    constructor(address payable wallet) {
        owner = msg.sender;
        MARKET_PLACE_WALLET = wallet;
    }

    /**
     * @dev emits admin
     * @param _address address
     */
    function addAdmin(address _address) public override {
        super.addAdmin(_address);
        emit MarketAdminAdded(_address);
    }

    /**
     * @dev this function add the address of the GameAssetsContract to be referenced to
     * @param _gameAssetsContract address
     */
    function addGameAssetsContract(address _gameAssetsContract)
        public
        onlyAdmin
    {
        GameAssetsContract = _gameAssetsContract;
    }

    /**
     * @dev this function add the address of the BreedingMarketContract to be referenced to
     * @param _breedingMarketContract address
     */
    function addBreedingMarketContract(address _breedingMarketContract)
        public
        onlyAdmin
    {
        BreedingMarketContract = _breedingMarketContract;
    }

    /**
     * @dev this function returns the ownership of the tokens
     * @param _tokenId uint256
     * @param _from address
     */
    function returnOwnership(uint256 _tokenId, address _from)
        public
        view
        returns (uint256)
    {
        return GameAssets(GameAssetsContract).balanceOf(_from, _tokenId);
    }

    /**
     * @dev this function return the kind of the tokens which is required for a check in market breeding
     * @param _tokenId uint256
     */
    function kind(uint256 _tokenId) external view returns (string memory) {
        return GameAssets(GameAssetsContract).kind(_tokenId);
    }

    /**
     * @dev mints new tokens
     * @param _uri string memory
     * @param _metadataUri string memory
     * @param _amount uint256
     */
    function mintNewToken(
        string memory _uri,
        string memory _metadataUri,
        uint256 _amount,
        string memory _kind,
        uint256 _dna,
        uint256 _parentOneId,
        uint256 _parentTwoId,
        bool _isBreedable
    ) public onlyAdmin {
        require(
            GameAssetsContract != address(0),
            "Please initialize the GameAsset Contract"
        );

        require(bytes(_uri).length != 0, "URI is empty");
        require(
            bytes(_metadataUri).length != 0,
            "URI of the metadata is empty"
        );
        require(_amount != 0, "Amount cannot be 0");

        uint256 tokenId = GameAssets(GameAssetsContract).mintToken(
            _uri,
            _metadataUri,
            _amount,
            msg.sender,
            _kind,
            _dna,
            _parentOneId,
            _parentTwoId,
            _isBreedable
        );

        emit MarketNFTMinted(tokenId, _uri, _metadataUri, _amount, msg.sender);
    }

    /**
     * @dev mints new tokens
     * @param _uri string memory
     * @param _metadataUri string memory
     * @param _amount uint256
     */
    function breedNewToken(
        string memory _uri,
        string memory _metadataUri,
        uint256 _amount,
        address _breeder,
        string memory _kind,
        uint256 _dna,
        uint256 _parentOneId,
        uint256 _parentTwoId,
        bool _isBreedable
    ) public returns (uint256) {
        require(
            BreedingMarketContract != address(0),
            "Please set breeding market contract"
        );
        require(
            msg.sender == BreedingMarketContract,
            "Can only be called by breeding market"
        );
        require(
            GameAssetsContract != address(0),
            "Please initialize the GameAsset Contract"
        );

        require(bytes(_uri).length != 0, "URI is empty");
        require(
            bytes(_metadataUri).length != 0,
            "URI of the metadata is empty"
        );
        require(_amount != 0, "Amount cannot be 0");

        uint256 tokenId = GameAssets(GameAssetsContract).mintToken(
            _uri,
            _metadataUri,
            _amount,
            _breeder,
            _kind,
            _dna,
            _parentOneId,
            _parentTwoId,
            _isBreedable
        );

        emit MarketNFTMinted(tokenId, _uri, _metadataUri, _amount, _breeder);
        return (tokenId);
    }

    /**
     * @dev mints new tokens in batch
     * @param _uri string memory
     * @param _metadataUri string memory
     * @param _amount uint256
     */
    function mintNewTokenInBatch(
        string[] memory _uri,
        string[] memory _metadataUri,
        uint256[] memory _amount,
        string[] memory _kind,
        uint256[] memory _dna,
        uint256[] memory _parentOneId,
        uint256[] memory _parentTwoId,
        bool[] memory _isBreedable
    ) public onlyAdmin {
        require(
            (_uri.length == _metadataUri.length) &&
                (_uri.length == _amount.length),
            "Length of URI, MetadataUri and Amount is mismatched"
        );

        for (uint256 i = 0; i < _uri.length; i++) {
            mintNewToken(
                _uri[i],
                _metadataUri[i],
                _amount[i],
                _kind[i],
                _dna[i],
                _parentOneId[i],
                _parentTwoId[i],
                _isBreedable[i]
            );
        }
    }

    /**
     * @dev transfer token to the another address
     * @param _tokenId uint256
     * @param _from address
     * @param _to address
     * @param _amount uint256
     */
    function transferToken(
        uint256 _tokenId,
        address _from,
        address _to,
        uint256 _amount
    ) public onlyAdmin {
        require(
            GameAssets(GameAssetsContract).balanceOf(_from, _tokenId) >=
                _amount,
            "You do not own enough amount of tokens"
        );

        GameAssets(GameAssetsContract).safeTransferFrom(
            _from,
            _to,
            _tokenId,
            _amount,
            "0x0"
        );

        emit MarketTransfer(_tokenId, _from, _to, _amount);
    }

    /**
     * @dev for internal transfer of token
     * @param _tokenId uint256
     * @param _from address
     * @param _to address
     * @param _amount uint256
     */
    function internalTransferToken(
        uint256 _tokenId,
        address _from,
        address _to,
        uint256 _amount
    ) private {
        require(
            GameAssets(GameAssetsContract).balanceOf(_from, _tokenId) >=
                _amount,
            "You do not own enough amount of tokens"
        );

        GameAssets(GameAssetsContract).safeTransferFrom(
            _from,
            _to,
            _tokenId,
            _amount,
            "0x0"
        );

        emit MarketTransfer(_tokenId, _from, _to, _amount);
    }

    /**
     * @dev transfer token to the another address
     * @param _tokenId uint256
     * @param _to address
     * @param _amount uint256
     */
    function transferTokenDirect(
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) public {
        require(
            GameAssets(GameAssetsContract).balanceOf(msg.sender, _tokenId) >=
                _amount,
            "You do not own enough amount of tokens"
        );

        GameAssets(GameAssetsContract).safeTransferFrom(
            msg.sender,
            _to,
            _tokenId,
            _amount,
            "0x0"
        );

        emit MarketTransfer(_tokenId, msg.sender, _to, _amount);
    }

    /**
     * @dev reset token URI
     */
    function setTokenUri(uint256 _tokenId, string memory _tokenURI)
        public
        onlyAdmin
    {
        GameAssets(GameAssetsContract).setURI(_tokenId, _tokenURI);
        emit MarketUriChanged(_tokenId, _tokenURI);
    }

    /**
     * ====================================================================
     * ~~~~~~~~~~~~~~~~~~~~~~~~~ MARKET SELL ITEMS ~~~~~~~~~~~~~~~~~~~~~~~~
     * ====================================================================
     */

    // on maket item creation
    event MarketSellItem(
        uint256 sellItemId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        address owner,
        string status
    );

    /**
     * Sell Item System
     */
    using Counters for Counters.Counter;
    Counters.Counter private sellItemId;
    // for storing items for sale
    struct SellItem {
        uint256 sellItemId;
        uint256 tokenId;
        uint256 amount;
        uint256 price;
        address owner;
    }
    mapping(uint256 => SellItem) sellItemsRegistry;

    /**
     * market sell item fees
     */
    uint256 MARKET_COMMISSION = 0;

    /**
     * @dev set market auction fees
     * @param _amount uint256
     */
    function setMarketCommission(uint256 _amount) public onlyAdmin {
        MARKET_COMMISSION = _amount;
    }

    /**
     * @dev this function creates a sell item for fix price
     * @param _tokenId uint256
     * @param _amount uint256
     * @param _price uint256
     */
    function createFixPriceSellItem(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _price
    ) public {
        // validate if the user owns the token
        require(
            GameAssets(GameAssetsContract).balanceOf(msg.sender, _tokenId) >=
                _amount,
            "You do not own enough tokens"
        );

        require(_price != 0, "The price of the item cannot be 0");

        // take the ownership of the token
        internalTransferToken(_tokenId, msg.sender, address(this), _amount);

        // create the sell item
        sellItemId.increment();
        uint256 itemId = sellItemId.current();
        SellItem memory newSellItem = SellItem(
            itemId,
            _tokenId,
            _amount,
            _price,
            msg.sender
        );
        sellItemsRegistry[itemId] = newSellItem;

        emit MarketSellItem(
            itemId,
            _tokenId,
            _amount,
            _price,
            msg.sender,
            "CREATED"
        );
    }

    /**
     * @dev this function remove the item from sell and return that item to the owner
     * @param _sellItemId uint256
     */
    function removeFixPriceSellItem(uint256 _sellItemId) public {
        require(
            msg.sender == sellItemsRegistry[_sellItemId].owner,
            "You are not the owner of the Market Item"
        );
        uint256 tokenId = sellItemsRegistry[_sellItemId].tokenId;
        uint256 amount = sellItemsRegistry[_sellItemId].amount;
        uint256 price = sellItemsRegistry[_sellItemId].price;
        address owner = sellItemsRegistry[_sellItemId].owner;

        delete sellItemsRegistry[_sellItemId];
        emit MarketSellItem(
            _sellItemId,
            tokenId,
            amount,
            price,
            owner,
            "DELETED"
        );

        internalTransferToken(tokenId, address(this), msg.sender, amount);
    }

    /**
     * @dev buy fix price sell items
     * @param _sellItemId uint256
     */
    function buyFixPriceSellItem(uint256 _sellItemId, uint256 _amount)
        public
        payable
    {
        require(
            sellItemsRegistry[_sellItemId].sellItemId != 0,
            "Sell item does not exists"
        );
        require(msg.value != 0, "The money must be a multiple of the price");
        require(
            msg.sender != sellItemsRegistry[_sellItemId].owner,
            "You are the owner"
        );
        uint256 requireValue = _amount *
            sellItemsRegistry[_sellItemId].price +
            ((_amount * sellItemsRegistry[_sellItemId].price) / 100) *
            MARKET_COMMISSION;
        require(
            msg.value == requireValue,
            "The money must be a multiple of the price plus 1% commission"
        );
        require(
            sellItemsRegistry[_sellItemId].amount >= _amount,
            "Enough items not available for sell"
        );
        // transferring amount to commission
        (bool status, ) = payable(MARKET_PLACE_WALLET).call{
            value: ((_amount * sellItemsRegistry[_sellItemId].price) / 100) *
                MARKET_COMMISSION
        }("");
        require(status, "Money transfer failed");

        uint256 tokenId = sellItemsRegistry[_sellItemId].tokenId;
        uint256 amount = sellItemsRegistry[_sellItemId].amount;
        uint256 price = sellItemsRegistry[_sellItemId].price;
        address owner = sellItemsRegistry[_sellItemId].owner;

        uint256 amountBought = msg.value / price;

        // transferring amount to the owner
        (status, ) = payable(owner).call{
            value: _amount * sellItemsRegistry[_sellItemId].price
        }("");
        require(status, "Money transfer failed");

        if (amountBought == amount) {
            delete sellItemsRegistry[_sellItemId];
        } else {
            uint256 remainingAmount = amount - amountBought;
            sellItemsRegistry[_sellItemId].amount = remainingAmount;
        }
        emit MarketSellItem(
            _sellItemId,
            tokenId,
            amountBought,
            price,
            msg.sender,
            "SOLD"
        );

        internalTransferToken(tokenId, address(this), msg.sender, amountBought);
    }

    /**
     * @dev update the price of the fix items
     * @param _sellItemId uint256
     * @param _newPrice uint256
     */
    function updatePriceInFixPriceSellItem(
        uint256 _sellItemId,
        uint256 _newPrice
    ) public {
        require(
            msg.sender == sellItemsRegistry[_sellItemId].owner,
            "You are not the owner of the Market Item"
        );
        uint256 tokenId = sellItemsRegistry[_sellItemId].tokenId;
        uint256 amount = sellItemsRegistry[_sellItemId].amount;
        uint256 price = sellItemsRegistry[_sellItemId].price;
        address owner = sellItemsRegistry[_sellItemId].owner;

        require(price != _newPrice, "The price is already set");

        sellItemsRegistry[_sellItemId] = SellItem(
            _sellItemId,
            tokenId,
            amount,
            _newPrice,
            owner
        );

        emit MarketSellItem(
            _sellItemId,
            tokenId,
            amount,
            _newPrice,
            owner,
            "UPDATED"
        );
    }
}