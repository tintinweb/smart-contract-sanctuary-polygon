/**
 *Submitted for verification at polygonscan.com on 2022-11-26
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: oburnpresale.sol

/**
 *  SPDX-License-Identifier: MIT
 *
 *
 *  OnlyBurns (Oburn) Token Presale
 *
 *  Website -------- https://onlyburns.com
 *  Twitter -------- https://twitter.com/onlyburnsdefi
 **/

pragma solidity 0.8.13;






/**
 * @title Token presale contract for $Oburn
 * @author Parrotly Finance, Inc.
 */
contract OburnTokenPresale is ReentrancyGuard, Context, Ownable {
    // The token being sold
    IERC20 private _token;

    // USDC reference since the presale is in USDC
    IERC20 private _usdc;

    // Address where funds are collected
    address payable private _wallet;

    // Amount of USDC raised
    uint256 private _usdcRaised;

    mapping(address => bool) private _whitelistedAddresses;
    mapping(address => uint256) private _whitelistAddressSpend;
    mapping(address => uint256) private _OburnPurchased;
    bool private _saleParametersLocked = false;
    bool private _whitelistSaleActive = false;
    bool private _publicSaleActive = false;
    bool private _whitelistSaleStarted = false;
    bool private _whitelistSaleEnded = false;
    uint256 private _whitelistSaleOburnSold;
    uint256 private _publicSaleOburnSold;
    uint256 private _whitelistSaleOburnCap = 25000000000 ether; // max Oburn available (WL)
    uint256 private _whitelistSaleRate = 500000 * (10 ** 12); // Oburn per the smallest amount of USDC ($0.000001) (WL)
    uint256 private _publicSaleOburnCap = 130000000000 ether; // max Oburn available (public)
    uint256 private _publicSaleRate = 250000 * (10 ** 12); // Oburn per the smallest amount of USDC ($0.000001) (public)
    uint256 private _maxOburnPerAddress = 250000000 ether; // max Oburn spend per adddress

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value usdc paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
     * @param preSaleWallet Address where collected funds will be forwarded to
     * @param preSaleToken Address of the token being sold
     * @param usdc Address of the USDC token which will be used to purchase OBurn in the presale
     */
    constructor(
        address payable preSaleWallet,
        IERC20 preSaleToken,
        IERC20 usdc
    ) {
        require(preSaleWallet != address(0), "Wallet is the zero address");
        require(address(preSaleToken) != address(0), "Token is the zero address");
        _wallet = preSaleWallet;
        _token = preSaleToken;
        _usdc = usdc;
    }

    /**
     * @dev Throws if sale parameters are locked
     */
    modifier onlyWhenUnlocked() {
        require(_saleParametersLocked == false, "Sale parameters are locked");
        _;
    }

    /**
     @dev Internal function to validate the presale purchase.
     @param beneficiary the address of the user receiving tokens from the presale purchase
     @param usdcAmount the amount of USDC sent in for the presale purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 usdcAmount) internal view {
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(usdcAmount != 0, "usdcAmount is 0");
        require(_usdc.allowance(_msgSender(), address(this)) >= usdcAmount, "Sender hasn't allowed this contract to spend enough USDC for this presale purchase.");
        require(_saleParametersLocked, "Sale parameters are not locked");
        require(_whitelistSaleActive || _publicSaleActive, "Whitelist sale and public sale are both not active");
        require(_msgSender() == beneficiary, "Sender address must also be the beneficiary address");

        if (_whitelistSaleActive) {
            _validateWhitelistSale(beneficiary, usdcAmount);
        } else {
            _validatePublicSale(beneficiary, usdcAmount);
        }
    }

    /**
     * @dev Validation specific to the whitelist portion of the sale
     * @param beneficiary address receiving the OBURN
     * @param usdcAmount Value in USDC involved in the purchase
     */
    function _validateWhitelistSale(address beneficiary, uint256 usdcAmount) internal view {
        require(checkAddressWhitelisted(beneficiary), "Beneficiary address is not whitelisted");

        uint256 tokens = _getTokenAmount(usdcAmount);

        require(_whitelistSaleOburnSold + tokens <= _whitelistSaleOburnCap, "Exceeds whitelist sale cap");
        require(_OburnPurchased[beneficiary] + tokens <= _maxOburnPerAddress, "Exceeds maximum tokens per address");
    }

    /**
     * @dev Validation specific to the public portion of the sale
     * @param beneficiary address receiving the OBURN
     * @param usdcAmount Value in USDC involved in the purchase
     */
    function _validatePublicSale(address beneficiary, uint256 usdcAmount) internal view {
        uint256 tokens = _getTokenAmount(usdcAmount);

        require(_publicSaleOburnSold + tokens <= _publicSaleOburnCap, "Exceeds public sale cap");
        require(_OburnPurchased[beneficiary] + tokens <= _maxOburnPerAddress, "Exceeds maximum tokens per address");
    }

    /**
    @dev Internal function to compute the amount of OBURN the beneficiary will receive based on the amount of USDC sent in.
    @param usdcAmount the amount of USDC sent in for the presale purchase.
     */
    function _getTokenAmount(uint256 usdcAmount) internal view returns (uint256) {
        if (_whitelistSaleActive) {
            return usdcAmount * _whitelistSaleRate;
        }

        return usdcAmount * _publicSaleRate;
    }

    /**
    @dev External function to compute how many tokens someone would get if they sent in usdcAmount USDC.
    @param usdcAmount the amount of USDC to use when computing the OBURN amount
     */
    function getTokenAmount(uint256 usdcAmount) external view returns (uint256) {
        return _getTokenAmount(usdcAmount);
    }

    /**
    @dev Internal function to update the presale state (OBURN purchased, public ORBURN sold, whitelist OBURN sold, etc.)
    @param beneficiary the address of the user receiving OBURN for the presale purchase
    @param usdcAmount the amount of USDC sent in for the presale purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 usdcAmount) internal {
        uint256 tokens = _getTokenAmount(usdcAmount);
        if (_whitelistSaleActive) {
            _OburnPurchased[beneficiary] += tokens;
            _whitelistSaleOburnSold += tokens;
        } else {
            _OburnPurchased[beneficiary] += tokens;
            _publicSaleOburnSold += tokens;
        }
    }

    /**
     * @dev Function for purchasing tokens in the presale.
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary, uint256 usdcAmount) external nonReentrant {
        _preValidatePurchase(beneficiary, usdcAmount);

        // calculate token amount to be sent
        uint256 tokens = _getTokenAmount(usdcAmount);

        // update state
        _usdcRaised = _usdcRaised + usdcAmount;

        _processPurchase(beneficiary, tokens, usdcAmount);

        emit TokensPurchased(_msgSender(), beneficiary, usdcAmount, tokens);

        _updatePurchasingState(beneficiary, usdcAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     * @param usdcAmount the amount of USDC spent on the presale purchase
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount, uint256 usdcAmount) internal {
        _usdc.transferFrom(_msgSender(), _wallet, usdcAmount);
        _token.transfer(beneficiary, tokenAmount);
    }     

    /**
     * @dev onlyOwner
     * Send remaining Oburn back to the owner
     */
    function endSale() external onlyOwner {
        require(_publicSaleActive, "Public sale has not started");
        _publicSaleActive = false;
        uint256 balance = _token.balanceOf(address(this));
        _token.transfer(owner(), balance);
    }

    /**
     * Getters & Setters
     */
    function getWhitelistSaleOburnSold() external view returns (uint256) {
        return _whitelistSaleOburnSold;
    }

    function getPublicSaleOburnSold() external view returns (uint256) {
        return _publicSaleOburnSold;
    }

    function getWhitelistSaleOburnCap() external view returns (uint256) {
        return _whitelistSaleOburnCap;
    }

    /**
     * @return the token being sold.
     */
    function token() external view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() external view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the amount of USDC raised.
     */
    function usdcRaised() external view returns (uint256) {
        return _usdcRaised;
    }

    /**
     * @dev onlyOwner and onlyWhenUnlocked
     */
    function setWhitelistSaleOburnCap(uint256 cap) external onlyOwner onlyWhenUnlocked {
        _whitelistSaleOburnCap = cap;
    }

    function getPublicSaleOburnCap() external view returns (uint256) {
        return _publicSaleOburnCap;
    }

    /**
     * @dev onlyOwner and onlyWhenUnlocked
     */
    function setPublicSaleOburnCap(uint256 cap) external onlyOwner onlyWhenUnlocked {
        _publicSaleOburnCap = cap;
    }

    function getWhitelistSaleRate() external view returns (uint256) {
        return _whitelistSaleRate;
    }

    /**
     * @dev onlyOwner and onlyWhenUnlocked
     */
    function setWhitelistSaleRate(uint256 rate) external onlyOwner onlyWhenUnlocked {
        _whitelistSaleRate = rate;
    }

    function getPublicSaleRate() external view returns (uint256) {
        return _publicSaleRate;
    }

    /**
     * @dev onlyOwner and onlyWhenUnlocked
     */
    function setPublicSaleRate(uint256 rate) external onlyOwner onlyWhenUnlocked {
        _publicSaleRate = rate;
    }

    function getMaxOburnPerAddress() external view returns (uint256) {
        return _maxOburnPerAddress;
    }

    /**
     * @dev onlyOwner and onlyWhenUnlocked
     */
    function setMaxOburnPerAddress(uint256 amount) external onlyOwner onlyWhenUnlocked {
        _maxOburnPerAddress = amount;
    }

    function getSaleParametersLocked() external view returns (bool) {
        return _saleParametersLocked;
    }

    /**
     * @dev onlyOwner
     * Parameters cannot be unlocked
     */
    function lockSaleParameters() external onlyOwner {
        _saleParametersLocked = true;
    }

    function getWhitelistSaleActive() external view returns (bool) {
        return _whitelistSaleActive;
    }

    /**
     * @dev onlyOwner
     */
    function setWhitelistSaleActive(bool active) external onlyOwner {
        require(_saleParametersLocked, "Sale parameters are not locked");
        require(!_whitelistSaleEnded, "Whitelist sale has ended");

        _whitelistSaleActive = active;
        if (_whitelistSaleActive && !_whitelistSaleStarted) {
            _whitelistSaleStarted = true;
        }
    }

    function getPublicSaleActive() external view returns (bool) {
        return _publicSaleActive;
    }

    /**
     * @dev onlyOwner
     */
    function setPublicSaleActive(bool active) external onlyOwner {
        require(_saleParametersLocked, "Sale parameters are not locked");
        require(_whitelistSaleStarted, "Whitelist sale has not started");

        _publicSaleActive = active;
        if (_publicSaleActive && !_whitelistSaleEnded) {
            endWhitelistSale();
            transferWhitelistSaleTokensToPublicSaleCap();
            adjustMaxOburnPerAddress();
        }
    }

    /**
     * @dev Set whitelist sale state according to the end of the whitelist sale
     */
    function endWhitelistSale() private {
        _whitelistSaleActive = false;
        _whitelistSaleEnded = true;
    }

    /**
     * @dev Any unsold whitelist sale tokens will be made available in the public sale
     */
    function transferWhitelistSaleTokensToPublicSaleCap() private {
        _publicSaleOburnCap += (_whitelistSaleOburnCap - _whitelistSaleOburnSold);
    }

    /**
     * @dev Adjust the max Oburn per address to play nice with the rounded rate
     */
    function adjustMaxOburnPerAddress() private {
        _maxOburnPerAddress = 250000000 ether;
    }

    /**
     * @dev onlyOwner
     */
    function addAddressToWhitelist(address user) external onlyOwner {
        _whitelistedAddresses[user] = true;
    }

    /**
     * @dev onlyOwner
     */
    function addAddressesToWhitelist(address[] calldata users) external onlyOwner {
        for (uint256 i; i < users.length; i++) {
            _whitelistedAddresses[users[i]] = true;
        }
    }

    /**
     * @dev onlyOwner
     */
    function removeAddressFromWhitelist(address user) external onlyOwner {
        _whitelistedAddresses[user] = false;
    }

    /**
    @dev Only owner function to change the token being sold.
    @param newTokenAddress reference to the new token being sold
    */
    function updateTokenReference(IERC20 newTokenAddress) external onlyOwner {
        _token = newTokenAddress;
    }

    /**
    @dev Only owner function to change the reference to the USDC token.
    @param newUSDCReference reference to the new USDC token
    */
    function updateUSDCReference(IERC20 newUSDCReference) external onlyOwner {
        _usdc = newUSDCReference;
    }

    /**
     * @dev onlyOwner
     */
    function isAddressWhitelisted(address user) external view onlyOwner returns (bool) {
        return checkAddressWhitelisted(user);
    }

    function singleAddressCheckWhitelist() external view returns (bool) {
        return _whitelistedAddresses[_msgSender()];
    }

    function singleAddressCheckOburnAmountPurchased() external view returns (uint256) {
        return _OburnPurchased[_msgSender()];
    }

    function singleAddressCheckOburnAmountAvailable() external view returns (uint256) {
        return _maxOburnPerAddress - _OburnPurchased[_msgSender()];
    }

    function checkAddressWhitelisted(address user) private view returns (bool) {
        return _whitelistedAddresses[user];
    }
}