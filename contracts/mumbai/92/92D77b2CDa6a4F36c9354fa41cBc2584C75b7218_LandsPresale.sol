/**
 *Submitted for verification at polygonscan.com on 2022-05-31
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/LandsPresale.sol

pragma solidity ^0.8.7;




contract LandsPresale is Ownable, ReentrancyGuard {
    constructor(uint256 _priceModifier) {
        priceModifier = _priceModifier;
    }

    uint256 public landSalesCounter;
    uint256 public priceModifier;
    uint256 public presaleStartTimestamp;
    bool public amountControl;
    bool public isPresaleOpen;

    mapping(uint256 => LandSale) public landSales;
    mapping(string => Land) public lands;
    mapping(address => bool) public currencies;
    mapping(address => bool) public deactualizers;

    struct LandSale {
        address buyer;
        address currency;
        uint256 price;
        uint256 timestamp;
        string size;
        bool isActual;
    }

    struct Land {
        string name;
        uint256 amount;
        uint256 startPrice;
        bool isExist;
    }

    struct DeactualizeUnit {
        uint256 saleId;
        bool value;
    }

    function currencyUpdate(address currency, bool isAccepted)
        external
        onlyOwner
    {
        currencies[currency] = isAccepted;
    }

    function deactualizersUpdate(address deactualizer, bool isDeactualizer)
        external
        onlyOwner
    {
        deactualizers[deactualizer] = isDeactualizer;
    }

    function priceModifierUpdate(uint256 _modifier) external onlyOwner {
        // require(_modifier > 0, "Zero value is not allowed");
        priceModifier = _modifier;
    }

    function landsUpdate(bytes calldata data) external onlyOwner {
        Land[] memory landsData = abi.decode(data, (Land[]));
        uint256 lenght = landsData.length;
        require(lenght > 0, "Empty array");
        for (uint256 i = 0; i < lenght; i++) {
            lands[landsData[i].name].name = landsData[i].name;
            lands[landsData[i].name].amount = landsData[i].amount;
            lands[landsData[i].name].startPrice = landsData[i].startPrice;
            lands[landsData[i].name].isExist = landsData[i].isExist;
        }
    }

    function startSale() external onlyOwner {
        require(!isPresaleOpen, "Presale is already started");
        isPresaleOpen = true;
        presaleStartTimestamp = block.timestamp;
    }

    function stopPresale() external onlyOwner {
        require(isPresaleOpen, "Presale is already stopped");
        isPresaleOpen = false;
    }

    function amountControlUpdate(bool value) external onlyOwner {
        require(value != amountControl, "Value dublicate");
        amountControl = value;
    }

    function withdraw(
        address currency,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "Zero value is not allowed");
        IERC20 token = IERC20(currency);
        token.transfer(to, amount);
    }

    function deactualize(bytes calldata data) external {
        require(
            deactualizers[msg.sender],
            "This address doesn't have permission to deactualize"
        );
        DeactualizeUnit[] memory salesData = abi.decode(
            data,
            (DeactualizeUnit[])
        );
        uint256 lenght = salesData.length;
        require(lenght > 0, "Empty array");
        for (uint256 i = 0; i < lenght; i++) {
            landSales[salesData[i].saleId].isActual = salesData[i].value;
        }
    }

    function buy(string memory landType, address currency)
        external
        nonReentrant
    {
        require(isPresaleOpen, "Presale is not available");
        require(currencies[currency], "Wrong currency");
        require(lands[landType].isExist, "Wrong size type");
        if (amountControl) {
            require(
                lands[landType].amount > 0,
                "This size type is not available"
            );
        }

        landSalesCounter += 1;
        uint256 dayOfPresale = (block.timestamp - presaleStartTimestamp) /
            86400;
        uint256 sPrice = lands[landType].startPrice;
        uint256 price = sPrice +
            ((sPrice * dayOfPresale * priceModifier) / 10000);
        IERC20 token = IERC20(currency);
        require(
            token.transferFrom(msg.sender, address(this), price),
            "Transfer error"
        );
        if (lands[landType].amount > 0) {
            lands[landType].amount -= 1;
        }

        landSales[landSalesCounter].buyer = msg.sender;
        landSales[landSalesCounter].currency = currency;
        landSales[landSalesCounter].price = price;
        landSales[landSalesCounter].timestamp = block.timestamp;
        landSales[landSalesCounter].size = landType;
        landSales[landSalesCounter].isActual = true;
    }

    function getPriceAndAmount(string memory landType)
        external
        view
        returns (uint256 price, uint256 amount)
    {
        uint256 dayOfPresale = (block.timestamp - presaleStartTimestamp) /
            86400;
        uint256 sPrice = lands[landType].startPrice;
        price = sPrice + ((sPrice * dayOfPresale * priceModifier) / 10000);
        amount = lands[landType].amount;
    }
}