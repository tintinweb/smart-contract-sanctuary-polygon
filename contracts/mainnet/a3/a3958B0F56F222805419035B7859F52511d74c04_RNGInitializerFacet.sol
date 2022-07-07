// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LibRNG} from "LibRNG.sol";

contract RNGInitializerFacet {
    struct InitParams {
        uint256 vrfBlocksToRespond;
        bytes32 chainlinkVRFKeyhash;
        uint256 chainlinkVRFFee;
        address vrfCoordinator;
        address linkTokenAddress;
    }
    function init(InitParams memory params) external {
        LibRNG.RNGStorage storage rs = LibRNG.rngStorage();
        rs.vrfBlocksToRespond = params.vrfBlocksToRespond;
        rs.chainlinkVRFKeyhash = params.chainlinkVRFKeyhash;
        rs.chainlinkVRFFee = params.chainlinkVRFFee;
        rs.vrfCoordinator = params.vrfCoordinator;
        rs.linkTokenAddress = params.linkTokenAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LinkTokenInterface} from "LinkTokenInterface.sol";

library LibRNG {
    bytes32 private constant RNG_STORAGE_POSITION =
        keccak256("CryptoUnicorns.RNG.storage");

    uint256 internal constant RNG_HATCHING = 1;

    struct RNGStorage {
        // blocks we give Chainlink to respond before we fail.
        uint256 vrfBlocksToRespond;
        bytes32 chainlinkVRFKeyhash;
        uint256 chainlinkVRFFee;
        address vrfCoordinator;
        mapping(bytes32 => uint256) mechanicIdByVRFRequestId;
        // requestId => randomness provided by ChainLink
        mapping(bytes32 => uint256) randomness;
        // Nonce used to create randomness.
        uint256 rngNonce;
        // Nonces for each VRF key from which randomness has been requested.
        // Must stay in sync with VRFCoordinator[_keyHash][this]
        // keyHash => nonce
        mapping(bytes32 => uint256) vrfNonces;

        address linkTokenAddress;
    }

    function rngStorage() internal pure returns (RNGStorage storage rs) {
        bytes32 position = RNG_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function requestRandomnessFor(uint256 mechanicId) internal returns(bytes32) {
		RNGStorage storage ds = rngStorage();
		bytes32 requestId = requestRandomness(
			ds.chainlinkVRFKeyhash,
			ds.chainlinkVRFFee
		);
		ds.mechanicIdByVRFRequestId[requestId] = mechanicId;
		return requestId;
	}

	function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
	function makeVRFInputSeed(
        bytes32 _keyHash,
        uint256 _userSeed,
        address _requester,
        uint256 _nonce
    ) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

	function requestRandomness(
        bytes32 _keyHash,
        uint256 _fee
    ) internal returns (bytes32 requestId) {
        RNGStorage storage ds = rngStorage();
		LinkTokenInterface(ds.linkTokenAddress).transferAndCall(ds.vrfCoordinator, _fee, abi.encode(_keyHash, 0));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        // So the seed doesn't actually do anything and is left over from an old API.
        uint256 vrfSeed = makeVRFInputSeed(_keyHash, 0, address(this), ds.vrfNonces[_keyHash]);
        // vrfNonces[_keyHash] must stay in sync with
        // VRFCoordinator.vrfNonces[_keyHash][this], which was incremented by the above
        // successful Link.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input
        // seed, which would result in a predictable/duplicate output.
        ds.vrfNonces[_keyHash]++;
        return makeRequestId(_keyHash, vrfSeed);
    }

    function expand(uint256 _modulus, uint256 _seed, uint256 _salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encode(_seed, _salt))) % _modulus;
    }

    function getRuntimeRNG() internal returns (uint256) {
        return getRuntimeRNG(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    function getRuntimeRNG(uint _modulus) internal returns (uint256) {
        require(msg.sender != block.coinbase, "RNG: Validators are not allowed to generate their own RNG");
        RNGStorage storage ds = rngStorage();
        return uint256(keccak256(abi.encodePacked(block.coinbase, gasleft(), block.number, ++ds.rngNonce))) % _modulus;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}