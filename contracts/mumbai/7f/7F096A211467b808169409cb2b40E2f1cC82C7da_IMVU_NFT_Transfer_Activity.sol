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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title NFT Transfer Transaction Tracker
/// @author MetaJuice
/// @notice Tracks NFT Transfers on the IMVU Platform
contract IMVU_NFT_Transfer_Activity is Ownable {

    /// @dev Tracks when users receive an NFT for finishing a quest
    /// @param from The address the NFT was sent from 
    /// @param to The address the NFT was sent to
    /// @param contractAddress The smart contract address the NFT is associated with
    /// @param tokenId The tokenId of the NFT
    event QuestGrant(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT as part of the Loyalty Rewards Program
    event LoyaltyReward(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT for having VIP Tenure 
    event VIPTenure(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT for having an AP subscription 
    event APSubscription(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT for being part of an external community that comes into IMVU 
    event CommunityReward(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT for general purpose
    event GeneralReward(address indexed from, address indexed to, address indexed contractAddress, string tokenId);

    /// @dev Tracks when users receive an NFT for finishing a quest
    function questGrant(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit QuestGrant(from, to, contractAddress, tokenId);
    }

    /// @dev Tracks when users receive an NFT as part of the Loyalty Rewards Program
    function loyaltyReward(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit LoyaltyReward(from, to, contractAddress, tokenId);
    }
    
    /// @dev Tracks when users receive an NFT for having VIP Tenure 
    function vipTenure(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit VIPTenure(from, to, contractAddress, tokenId);
    }

    /// @dev Tracks when users receive an NFT for having an AP subscription 
    function apSubscription(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit APSubscription(from, to, contractAddress, tokenId);
    }

    /// @dev Tracks when users receive an NFT for being part of an external community that comes into IMVU 
    function communityReward(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit CommunityReward(from, to, contractAddress, tokenId);
    }

    /// @dev Tracks when users receive an NFT for general purpose
    function generalReward(address from, address to, address contractAddress, string calldata tokenId) external onlyOwner {
        emit GeneralReward(from, to, contractAddress, tokenId);
    }

}