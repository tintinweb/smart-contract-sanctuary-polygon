/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org

// File contracts/metatx/ManagedIdentity.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}


// File contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}


// File contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <0.8.0;


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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}


// File contracts/interfaces/IGBotInventory.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotInventory {
    function mintGBot(address to, uint256 nftId, uint256 metadata, bytes memory data) external;
    function getMetadata(uint256 tokenId) external view returns (uint256 metadata);
    function upgradeGBot(uint256 tokenId, uint256 newMetadata) external;

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

        /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File contracts/game/GBotStarterMinter/GBotStarterminter.sol



pragma solidity >=0.7.6 <0.8.0;


contract GBotStarterMinter is Ownable {
    
    IGBotInventory private GBotContract;
    // Bitwise operations
    uint constant internal ONE = uint(1);
    uint constant internal ONES = uint(~0);
    uint256 internal constant TYPE_ID_BITS = 247;
    uint internal constant GBOT_TYPE_STARTER = 1;


    constructor(address GBotInventory_)
    Ownable(msg.sender)
    {
        GBotContract = IGBotInventory(GBotInventory_);
    }
    
    
    function mintStarterGBots(uint256[] memory tokenIds, address[] memory owners) public onlyOwner {
        require(tokenIds.length == owners.length, "GBotStarters: GBots and owners don't match");
        isStarterBot(tokenIds);
        bytes memory data = "";
        for (uint256 i = 0; i < owners.length; i++) {
          GBotContract.mintGBot(owners[i], tokenIds[i], tokenIds[i], data);
        }
    }

        function isStarterBot(uint256[] memory tokenIds) public pure {
        for (uint256 i = 0; i < tokenIds.length; i++) {
          uint bits = 8;
          require(0 < bits && TYPE_ID_BITS < 256 && TYPE_ID_BITS + bits <= 256, "GetMetadata: Incorrect number of bits in metadata");
          uint256 botType = tokenIds[i] >> TYPE_ID_BITS & ONES >> 256 - bits;
          require(botType == GBOT_TYPE_STARTER, "StarterGbots Minter: GBot is not starter");
        }
    }
    
}