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

/// @title VCOIN Transaction Tracker
/// @author MetaJuice
/// @notice Tracks VCOIN transactions on the IMVU Platform
contract IMVU_VCOIN_Activity is Ownable {

    /// @dev mapping of provider => baseUrl for looking up transactions of provider
    mapping(string => string) public providerBaseUrls;

    /// @dev mapping of provider => Url Suffix, if there is any
    mapping(string => string) public providerUrlSuffix;

    /// @dev Tracks when users convert VCOIN into IMVU Credits
    /// @param from The address VCOIN was sent from 
    /// @param provider The provider of the transaction
    /// @param txId The transaction id from the provider
    /// @param to The address VCOIN was sent to
    /// @param amount The amount of VCOIN transacted
    event Conversion(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users purchase an item in the IMVU store using VCOIN
    event SpentInStore(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users give VCOIN to another user 
    event CustomerGifting(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users purchase VCOIN with USD
    event Purchase(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users withdraw VCOIN off IMVU platform
    event Withdrawal(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users purchase an NFT using VCOIN
    event NFTPurchase(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when VCOIN is paid out as royalties for the sale of an NFT 
    event NFTRoyalty(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users are granted VCOIN from a Daily Spin 
    event DailySpinGrant(address indexed from, string indexed provider, string indexed txId, address to, string amount);

    /// @dev Tracks when users convert VCOIN into IMVU Credits
    function conversion(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit Conversion(from, provider, txId, to, amount);
    }

    /// @dev Tracks when users purchase an item in the IMVU store using VCOIN
    function spentInStore(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit SpentInStore(from, provider, txId, to, amount);
    }
    
    /// @dev Tracks when users give VCOIN to another user 
    function customerGifting(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit CustomerGifting(from, provider, txId, to, amount);
    }

    /// @dev Tracks when users purchase VCOIN with USD
    function purchase(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit Purchase(from, provider, txId, to, amount);
    }

    /// @dev Tracks when users withdraw VCOIN off IMVU platform
    function withdrawal(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner{
        emit Withdrawal(from, provider, txId, to, amount);
    }

    /// @dev Tracks when users purchase an NFT using VCOIN
    function nftPurchase(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit NFTPurchase(from, provider, txId, to, amount);
    }

    /// @dev Tracks when VCOIN is paid out as royalties for the sale of an NFT
    function nftRoyalty(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit NFTRoyalty(from, provider, txId, to, amount);
    }

    /// @dev Tracks when users are granted VCOIN from a Daily Spin
    function dailySpinGrant(address from, string calldata provider, string calldata txId, address to, string calldata amount) external onlyOwner {
        emit DailySpinGrant(from, provider, txId, to, amount);
    }

    /// @dev Adds OR Updates a URL to the provider => baseUrl mapping
    /// @param provider The provider of the transaction
    /// @param url The baseUrl of the provider
    /// @param suffix The Url suffix of the provider
    function addUrl(string calldata provider, string calldata url, string calldata suffix) external onlyOwner {
        providerBaseUrls[provider] = url;
        providerUrlSuffix[provider] = suffix;
    }

    /// @dev Removes a URL from the provider => baseUrl mapping
    /// @param provider The provider of the transaction
    function removeUrl(string calldata provider) external onlyOwner {
        providerBaseUrls[provider] = '';
        providerUrlSuffix[provider] = '';
    }

    /// @notice Users can retrieve a URL to the provider's original transaction
    /// @dev Gets a URL by concatenating the baseUrl of the provider with the txId
    /// @param provider The provider of the transaction
    /// @param txId The transaction id from the provider
    /// @return url The concatenated URL
    function getUrl(string calldata provider, string calldata txId) public view returns(string memory url){
        return string(abi.encodePacked(providerBaseUrls[provider], txId, providerUrlSuffix[provider]));
    }

}