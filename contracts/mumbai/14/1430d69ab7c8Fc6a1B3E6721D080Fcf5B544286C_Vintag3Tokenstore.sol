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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vintag3Tokenstore is Ownable, ReentrancyGuard {

    /* Variables */

    uint256 public tokenBuyPrice = 0;
    uint256 public tokenSellPrice = 0;
    address private _token = 0x8dEE2d26c522601A5E93fBb7108EA16070F772dd;
    IERC20 private _tokenContract;
    bool private _buyOpen = false;
    bool private _sellOpen = false;

    /* Construction */

    constructor() { 
        setTokenContract(_token);
    }

    /* Config */

    /// @notice Gets all required config variables
    function config() external view returns(uint256, uint256, address, bool, bool) {
        return (tokenBuyPrice, tokenSellPrice, _token, _buyOpen, _sellOpen);
    }

    /// @notice Gets the smart contracts token balance
    function storeTokenBalance() public view returns(uint256) {
        return addressTokenBalance(address(this));
    }

    /// @notice Gets the current address native balance
    function storeBalance() public view returns(uint256) {
        return address(this).balance;
    }

    /* Getters */

    /// @dev Gets an addresses token balance
    function addressTokenBalance(address wallet) internal view returns(uint256) {
        return _tokenContract.balanceOf(wallet);
    }

    /* Buy/Sell */

    /// @notice Public buy function that accepts a quantity.
    /// @dev Buy function with price check
    function buy(uint256 quantity) external payable nonReentrant {
        require(_buyOpen == true, "Cannot buy while tokenstore is closed.");
        require(msg.value == quantity * tokenBuyPrice, "Must send exact amount as per [tokenBuyPrice * quantity]");
        _internalTransfer(msg.sender, quantity);
    }

    /// @notice Public sell function that accepts a quantity.
    /// @dev Buy function with price check
    function sell(uint256 quantity) external nonReentrant {
        require(_sellOpen == true, "Cannot sell while tokenstore is closed.");
        _internalTransferFrom(msg.sender, address(this), quantity);
        _internalSend(msg.sender, quantity * tokenSellPrice);
    }

    /// @dev Internal transfer/buy function that runs basic store balance checks.
    function _internalTransfer(address to, uint256 quantity) private {
        require(quantity <= storeTokenBalance(), "Store does not have enough to send");
        _tokenContract.transfer(to, quantity);
    }

    /// @dev Internal transferFrom/sell function that runs basic wallet balance checks.
    function _internalTransferFrom(address from, address to, uint256 quantity) private {
        require(addressTokenBalance(from) >= quantity, "From address must hold at least the quantity of tokens attempting to be transfered.");
        _tokenContract.transferFrom(from, to, quantity);
    }
    
    /// @dev Internal fund transfer function that runs basic store balance check.
    function _internalSend(address to, uint256 value) private {
        require(storeBalance() >= value, "Contract does not have enough funds to support the send of funds.");
        (bool sent,) = to.call{value: value}("");
        require(sent, "Failed to distribute funds.");
    }

    /* Ownership */

    /// @notice Prevents ownership renouncement
    function renounceOwnership() public override onlyOwner {}

    /* Fallbacks */

    receive() payable external {}
    fallback() payable external {}

    /* Owner Setters */

    /// @notice Sets the buy price per token in WEI
    function setTokenBuyPrice(uint256 price) external onlyOwner {
        tokenBuyPrice = price;
    }

    /// @notice Sets the price per token in WEI
    function setTokenSellPrice(uint256 price) external onlyOwner {
        tokenSellPrice = price;
    }

    /// @notice Sets the public buy to open or closed
    function setBuyOpen(bool open) external onlyOwner {
        _buyOpen = open;
    }
    
    /// @notice Sets the public sell to open or closed
    function setSellOpen(bool open) external onlyOwner {
        _sellOpen = open;
    }

    /// @notice Sets the primary token contract used for buying and selling
    function setTokenContract(address token) public onlyOwner {
        _token = token;
        _tokenContract = IERC20(_token);
    }

    /* Owner Functions */

    function airdrop(address to, uint256 quantity) external onlyOwner nonReentrant {
        _internalTransfer(to, quantity);
    }

    function airdropBatch(address[] memory wallets, uint[] calldata quantities) external onlyOwner nonReentrant {
        require(wallets.length == quantities.length, "Airdrop wallets must have assocaited token assignment.");
        uint256 w;
        for (w = 0; w < wallets.length; w++) {
            _internalTransfer(wallets[w], quantities[w]);
        }
    }

    /* Funds */

    /// @notice Fund distribution function.
    /// @dev Pays out to the owner
    function distributeFunds() external onlyOwner nonReentrant {
        if(address(this).balance > 0) {
            (bool sent,) = msg.sender.call{value: address(this).balance}("");
            require(sent, "Failed to distribute remaining funds.");
        }
    }

    /// @notice ERC20 fund distribution function.
    /// @dev Pays out to the owner
    function distributeERC20Funds(address tokenAddress) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(tokenAddress);

        if(tokenContract.balanceOf(address(this)) > 0) {
            tokenContract.transfer(msg.sender, tokenContract.balanceOf(address(this)));
        }
    }
}