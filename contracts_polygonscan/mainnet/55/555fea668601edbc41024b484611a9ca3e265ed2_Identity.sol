/**
 *Submitted for verification at polygonscan.com on 2021-09-22
*/

pragma solidity ^0.8.7;

// @TODO: Formatting
library LibBytes {
  using LibBytes for bytes;

  // @TODO: see if we can just set .length = 
  function trimToSize(bytes memory b, uint newLen)
    internal
    pure
  {
    require(b.length > newLen, "BytesLib: only shrinking");
    assembly {
      mstore(b, newLen)
    }
  }


  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    require(b.length >= index + 32, "BytesLib: length");

    // Arrays are prefixed by a 256 bit length parameter
    index += 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, index))
    }
    return result;
  }
}



interface IERC1271Wallet {
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

library SignatureValidator {
	using LibBytes for bytes;

	enum SignatureMode {
		NoSig,
		EIP712,
		EthSign,
		SmartWallet,
		Spoof,
		// must be at the end
		Unsupported
	}

	// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
	bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

	function recoverAddr(bytes32 hash, bytes memory sig) internal view returns (address) {
		require(sig.length >= 1, "SignatureValidator: basic sig len");
		uint8 modeRaw = uint8(sig[sig.length - 1]);
		require(modeRaw < uint8(SignatureMode.Unsupported), "SignatureValidator: unsupported sig mode");
		SignatureMode mode = SignatureMode(modeRaw);

		if (mode == SignatureMode.NoSig) {
			return address(0x0);
		}

		// {r}{s}{v}{mode}
		if (mode == SignatureMode.EIP712 || mode == SignatureMode.EthSign) {
			// @TODO sig len check
			require(sig.length == 66, "SignatureValidator: sig len");
			bytes32 r = sig.readBytes32(0);
			bytes32 s = sig.readBytes32(32);
			// @TODO: is there a gas saving to be had here by using assembly?
			uint8 v = uint8(sig[64]);
			// Hesitant about this check: seems like this is something that has no business being checked on-chain
			require(v == 27 || v == 28, "invalid v");
			if (mode == SignatureMode.EthSign) hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
			return ecrecover(hash, v, r, s);
		}
		// {sig}{verifier}{mode}
		if (mode == SignatureMode.SmartWallet) {
			// @TODO: sig len check
			// 32 bytes for the addr, 1 byte for the type = 33
			require(sig.length > 33, "SignatureValidator: wallet sig len");
			// @TODO: can we pack the addr tigher into 20 bytes? should we?
			IERC1271Wallet wallet = IERC1271Wallet(address(uint160(uint256(sig.readBytes32(sig.length - 33)))));
			sig.trimToSize(sig.length - 33);
			require(ERC1271_MAGICVALUE_BYTES32 == wallet.isValidSignature(hash, sig), "SignatureValidator: invalid wallet sig");
			return address(wallet);
		}
		// {address}{mode}; the spoof mode is used when simulating calls
		if (mode == SignatureMode.Spoof) {
			require(tx.origin == address(0), "SignatureValidator: spoof must be used with zero");
			require(sig.length == 33, "SignatureValidator: spoof sig len");
			sig.trimToSize(32);
			return abi.decode(sig, (address));
		}
		return address(0x00);
	}
}


contract Identity {
	mapping (address => bytes32) public privileges;
	// The next allowed nonce
	uint public nonce = 0;

	// Events
	event LogPrivilegeChanged(address indexed addr, bytes32 priv);

	// Transaction structure
	// we handle replay protection separately by requiring (address(this), chainID, nonce) as part of the sig
	struct Transaction {
		address to;
		uint value;
		bytes data;
	}

	constructor(address[] memory addrs) {
		uint len = addrs.length;
		for (uint i=0; i<len; i++) {
			// @TODO should we allow setting to any arb value here?
			privileges[addrs[i]] = bytes32(uint(1));
			emit LogPrivilegeChanged(addrs[i], bytes32(uint(1)));
		}
	}

	// This contract can accept ETH without calldata
	receive() external payable {}

	// This contract can accept ETH with calldata
	// However, to support EIP 721 and EIP 1155, we need to respond to those methods with their own method signature
	fallback() external payable {
		if (msg.data.length >= 4) {
			bytes4 method;
			// solium-disable-next-line security/no-inline-assembly
			assembly {
				// can also do shl(224, shr(224, calldataload(0)))
				method := and(calldataload(0), 0xffffffff00000000000000000000000000000000000000000000000000000000)
			}
			if (
				method == 0x150b7a02 // bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
					|| method == 0xf23a6e61 // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
					|| method == 0xbc197c81 // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
			) {
				// Copy back the method
				// solhint-disable-next-line no-inline-assembly
				assembly {
					calldatacopy(0, 0, 0x04)
					return (0, 0x20)
				}
			}
		}
	}

	function setAddrPrivilege(address addr, bytes32 priv)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		// Anti-bricking measure: if the privileges slot is used for special data (not 0x01),
		// don't allow to set it to true
		if (privileges[addr] != bytes32(0) && privileges[addr] != bytes32(uint(1)))
			require(priv != bytes32(uint(1)), 'UNSETTING_SPECIAL_DATA');
		privileges[addr] = priv;
		emit LogPrivilegeChanged(addr, priv);
	}

	// @TODO: should this stay? is this the right place for it?
	function tipMiner(uint amount)
		external
	{
		require(msg.sender == address(this), 'ONLY_IDENTITY_CAN_CALL');
		// See https://docs.flashbots.net/flashbots-auction/searchers/advanced/coinbase-payment/#managing-payments-to-coinbaseaddress-when-it-is-a-contract
		// generally this contract is reentrancy proof cause of the nonce
		executeCall(block.coinbase, amount, new bytes(0));
	}

	function execute(Transaction[] calldata txns, bytes calldata signature)
		external
	{
		require(txns.length > 0, 'MUST_PASS_TX');
		// If we use the naive abi.encode(txn) and have a field of type `bytes`,
		// there is a discrepancy between ethereumjs-abi and solidity
		// @TODO check if this is resolved
		uint currentNonce = nonce;
		// NOTE: abi.encode is safer than abi.encodePacked in terms of collision safety
		bytes32 hash = keccak256(abi.encode(address(this), block.chainid, currentNonce, txns));
		// We have to increment before execution cause it protects from reentrancies
		nonce = currentNonce + 1;

		address signer = SignatureValidator.recoverAddr(hash, signature);
		require(privileges[signer] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			executeCall(txn.to, txn.value, txn.data);
		}
		// The actual anti-bricking mechanism - do not allow a signer to drop their own priviledges
		require(privileges[signer] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	// no need for nonce management here cause we're not dealing with sigs
	function executeBySender(Transaction[] calldata txns) external {
		require(txns.length > 0, 'MUST_PASS_TX');
		require(privileges[msg.sender] != bytes32(0), 'INSUFFICIENT_PRIVILEGE');
		uint len = txns.length;
		for (uint i=0; i<len; i++) {
			Transaction memory txn = txns[i];
			executeCall(txn.to, txn.value, txn.data);
		}
		// again, anti-bricking
		require(privileges[msg.sender] != bytes32(0), 'PRIVILEGE_NOT_DOWNGRADED');
	}

	// we shouldn't use address.call(), cause: https://github.com/ethereum/solidity/issues/2884
	// copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
	// there's also
	// https://github.com/gnosis/MultiSigWallet/commit/e1b25e8632ca28e9e9e09c81bd20bf33fdb405ce
	// https://github.com/austintgriffith/bouncer-proxy/blob/master/BouncerProxy/BouncerProxy.sol
	// https://github.com/gnosis/safe-contracts/blob/7e2eeb3328bb2ae85c36bc11ea6afc14baeb663c/contracts/base/Executor.sol
	function executeCall(address to, uint256 value, bytes memory data)
		internal
	{
		assembly {
			let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)

			switch result case 0 {
				let size := returndatasize()
				let ptr := mload(0x40)
				returndatacopy(ptr, 0, size)
				revert(ptr, size)
			}
			default {}
		}
		// A single call consumes around 477 more gas with the pure solidity version, for whatever reason
		//(bool success, bytes memory returnData) = to.call{value: value, gas: gasleft()}(data);
		//if (!success) revert(string(data));
	}

	// EIP 1271 implementation
	// see https://eips.ethereum.org/EIPS/eip-1271
	function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4) {
		if (privileges[SignatureValidator.recoverAddr(hash, signature)] != bytes32(0)) {
			// bytes4(keccak256("isValidSignature(bytes32,bytes)")
			return 0x1626ba7e;
		} else {
			return 0xffffffff;
		}
	}

	// EIP 1155 implementation
	// we pretty much only need to signal that we support the interface for 165, but for 1155 we also need the fallback function
	function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
		return
			interfaceID == 0x01ffc9a7 ||    // ERC-165 support (i.e. `bytes4(keccak256('supportsInterface(bytes4)'))`).
			interfaceID == 0x4e2312e0;      // ERC-1155 `ERC1155TokenReceiver` support (i.e. `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")) ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`).
	}
}