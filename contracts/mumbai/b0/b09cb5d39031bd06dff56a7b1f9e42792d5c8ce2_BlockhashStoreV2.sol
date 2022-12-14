/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File contracts/interfaces/OwnableInterface.sol

// SPDX-License-Identifier: MIT


interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}


// File contracts/ConfirmedOwnerWithProposal.sol




/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}


// File contracts/ConfirmedOwner.sol




/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}


// File contracts/BlockhashStoreV2.sol


pragma solidity 0.8.6;

/**
 * @title BlockhashStoreV2
 * @notice This contract provides a way to access blockhashes older than
 *   the 256 block limit imposed by the BLOCKHASH opcode.
 *   You may assume that any blockhash stored by the contract is correct.
 *   Note that the contract depends on the format of serialized Ethereum
 *   blocks. If a future hardfork of Ethereum changes that format, the
 *   logic in this contract may become incorrect and an updated version
 *   would have to be deployed.
 */
contract BlockhashStoreV2 is ConfirmedOwner {
  mapping(uint => bytes32) internal s_blockhashes;
  event Blockhashfilled(uint256 indexed blockNumber, bytes32 indexed blockHash);
  event BlockhashfilledByOwner(uint256 indexed blockNumber, bytes32 indexed blockHash);

  constructor(address owner) ConfirmedOwner(owner) {}

  /**
   * @notice stores blockhash of a given block, assuming it is available through BLOCKHASH
   * @param n the number of the block whose blockhash should be stored
   * @param blockHash blockhash
   */
  function store(uint256 n, bytes32 blockHash) public onlyOwner {
    require(blockHash != 0x0, "blockhash error");
    s_blockhashes[n] = blockHash;
    emit BlockhashfilledByOwner(n, blockHash);
  }

  /**
   * @notice stores blockhash of a given block, assuming it is available through BLOCKHASH
   * @param n the number of the block whose blockhash should be stored
   */
  function store(uint256 n) public {
    bytes32 h = blockhash(n);
    require(h != 0x0, "blockhash(n) failed");
    s_blockhashes[n] = h;
    emit Blockhashfilled(n, h);
  }

  /**
   * @notice stores blockhash of the earliest block still available through BLOCKHASH.
   */
  function storeEarliest() external {
    store(block.number - 256);
  }

  /**
   * @notice stores blockhash after verifying blockheader of child/subsequent block
   * @param n the number of the block whose blockhash should be stored
   * @param header the rlp-encoded blockheader of block n+1. We verify its correctness by checking
   *   that it hashes to a stored blockhash, and then extract parentHash to get the n-th blockhash.
   */
  function storeVerifyHeader(uint256 n, bytes memory header) public {
    require(keccak256(header) == s_blockhashes[n + 1], "header has unknown blockhash");

    // At this point, we know that header is the correct blockheader for block n+1.

    // The header is an rlp-encoded list. The head item of that list is the 32-byte blockhash of the parent block.
    // Based on how rlp works, we know that blockheaders always have the following form:
    // 0xf9____a0PARENTHASH...
    //   ^ ^   ^
    //   | |   |
    //   | |   +--- PARENTHASH is 32 bytes. rlpenc(PARENTHASH) is 0xa || PARENTHASH.
    //   | |
    //   | +--- 2 bytes containing the sum of the lengths of the encoded list items
    //   |
    //   +--- 0xf9 because we have a list and (sum of lengths of encoded list items) fits exactly into two bytes.
    //
    // As a consequence, the PARENTHASH is always at offset 4 of the rlp-encoded block header.

    bytes32 parentHash;
    assembly {
      parentHash := mload(add(header, 36)) // 36 = 32 byte offset for length prefix of ABI-encoded array
      //    +  4 byte offset of PARENTHASH (see above)
    }

    s_blockhashes[n] = parentHash;
    emit Blockhashfilled(n, parentHash);
  }

  /**
   * @notice gets a blockhash from the store. If no hash is known, this function reverts.
   * @param n the number of the block whose blockhash should be returned
   */
  function getBlockhash(uint256 n) external view returns (bytes32) {
    bytes32 h = s_blockhashes[n];
    require(h != 0x0, "blockhash not found in store");
    return h;
  }
}