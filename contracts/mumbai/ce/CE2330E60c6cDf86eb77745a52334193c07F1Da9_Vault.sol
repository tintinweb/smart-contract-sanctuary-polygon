// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Vault contract
/// @notice all operator raffle funds and platform fee saves on here.
/// referral system integrated to this contract
/// @dev users can withdraw referral reward in this contract with backend signatures
contract Vault is Ownable {
  // events
  /// @dev triggers when claimed referral reward
  event ReferralRewardClaimed(address indexed to, uint256 amount);

  /// @dev saved last claimed time
  mapping(address => uint256) public claimedDate;
  /// @dev signer address
  address public signer;

  // signature structure
  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  /// @param _signer signer address
  constructor(address _signer) {}

  // fallback function to accept eth
  receive() external payable {}

  fallback() external payable {}

  // external functions
  /// @param amount amount to claim
  /// @param sig sigature of signer
  function claimReferralReward(uint256 amount, Sig calldata sig) external {
    require(_validateClaimParams(amount, sig), "Invalid signature");

    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send Ether");

    emit ReferralRewardClaimed(msg.sender, amount);
  }

  /// @param _newAddress new address of the platform signer
  /// @dev Change the wallet of the platform signer
  function setSignerAddress(address payable _newAddress) external onlyOwner {
    signer = _newAddress;
  }

  /// @param amount amount to claim
  /// @dev claim funds
  function claimFund(uint256 amount) external onlyOwner {
    (bool sent, ) = msg.sender.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }

  // internal functions
  /// @param amount amount to claim
  /// @param sig signature of signer
  /// @dev validate claim amount of user
  function _validateClaimParams(uint256 amount, Sig calldata sig) internal view returns (bool) {
    bytes32 messageHash = keccak256(
      abi.encodePacked(_msgSender(), amount, claimedDate[_msgSender()])
    );

    bytes32 ethSignedMessageHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
    );

    return signer == ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s);
  }
}