/**
 *Submitted for verification at polygonscan.com on 2023-07-16
*/

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts\interfaces\IKeys.sol

pragma solidity ^0.8.18;

interface IKeys {


    function uri(uint256 tokenId) external view returns (string memory);

    // @dev mints any quantity of a single token type
    // @param - keyID - ID of desired key type
    // @param - amt - how many to mint
    function mintKey(address user, uint256 keyID, uint256 amt) external;

    // @dev mints multiple types of keys in multiple quantities
    function mintManyKeys(address user, uint256[] calldata keyIDs, uint256[] calldata amounts) external;

    // @dev - can burn multiple gem types at once
    // @param - keyIDs - list of different gem types
    // @param - amounts - how many of each gem to burn
    // @notice - indices of array params are complementary (i.e. amounts[0] refers to quantity of gemIDs[0])
    // @notice - length of arrays must be equal
    function burnManyKeys(uint256[] calldata keyIDs, uint256[] calldata amounts, address player) external;
    //
    // @dev - burn single gem type
    // @dev - can burn any amount of single gem type
    function burnSingleKey(address player, uint256 keyID, uint256 amount) external;

    // owner functions
    function addOperator(address _op) external;

    function removeOperator(address _op) external;

    function setTokenURI(uint256 keyID, string calldata _uri) external;

}

// File: contracts\operators\discoveryMinter.sol

pragma solidity ^0.8.18;
contract DiscoveryKeyMinter is Ownable {
    IKeys immutable keys;

    event KeyPurchased(address indexed user, uint256 amt);

    uint256 public maximum = 1000;
    uint256 public fullMaximum = 1800;
    uint256 public count = 0;
    uint256 constant coolDown = 1800; // 30 minutes per token
    uint256 public cost = 0.01 ether;

    mapping(address => uint256) public timers;

    constructor(address _keys) public Ownable() {
        keys = IKeys(_keys);
    }

    // mint functions
    function buyKey(uint256 amt) external payable {
        require(count + amt <= maximum, "Sold out!");
        require(amt > 0 && amt <= 5, "Invalid");
        require(msg.value == cost * amt, "Invalid payment");
        require(block.timestamp >= timers[msg.sender], "Cooldown in effect");
        timers[msg.sender] = block.timestamp + coolDown * amt;
        count += amt;
        keys.mintKey(msg.sender, 0, amt);
        emit KeyPurchased(msg.sender, amt);
    }

    // Owner Functions
    function unlockWave(uint256 amt, uint256 newPrice) external onlyOwner {
        require(amt > 0, "Invalid");
        require(newPrice > 0, "Invalid Price");
        require(maximum + amt <= fullMaximum, "maximum reached");
        maximum += amt;
        cost = newPrice;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        (bool sent, ) = payable(msg.sender).call{value: address(this).balance}("");
    }

    // Modifiers
    modifier isZeroAddress(address addr) {
        require(addr != address(0), "Burner: 0x0 address");
        _;
    }

}