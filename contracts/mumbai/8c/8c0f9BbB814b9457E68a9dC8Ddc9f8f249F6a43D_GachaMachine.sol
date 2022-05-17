/**
 *Submitted for verification at polygonscan.com on 2022-05-16
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

// File: contracts/LuxOn/IERC721LUXON.sol


pragma solidity ^0.8.13;

interface IERC721LUXON {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mintLuxOn(address mintUser, uint32 quantity) external;
}
// File: contracts/LuxOn/IERC20LUXON.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20LUXON {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    function approveFor(address owner, address spender, uint256 amount) external returns (bool success);

    function paybackByMint(address to, uint256 amount) external;
    function paybackByTransfer(address to, uint256 amount) external;
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

// File: contracts/LuxOn/SuperOperators.sol


pragma solidity ^0.8.13;


contract SuperOperators is Ownable {

    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    modifier onlySuperOperator() {
        require(_superOperators[msg.sender], "SuperOperators: not super operators");
        _;
    }

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external onlyOwner {
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}
// File: contracts/LuxOn/Payback.sol


pragma solidity ^0.8.13;



contract Payback is Ownable {
    address private _tokenAddress;
    uint256 private _percentageRate;
    uint256 private _percentage;

    event PaybackTokenAddressTransferred(address indexed previousTokenAddress, address indexed newTokenAddress);
    event PaybackPercentageRateTransferred(uint256 indexed previousPaybackPercentageRate, uint256 indexed newPaybackPercentageRate);
    event PaybackPercentageTransferred(uint256 indexed previousPaybackPercentage, uint256 indexed newPaybackPercentage);

    constructor (address tokenAddress, uint256 percentageRate, uint256 percentage) {
        _transferTokenAddress(tokenAddress);
        _transferPaybackPercentageRate(percentageRate);
        _transferPaybackPercentage(percentage);
    }

    modifier validPercentage() {
        require(getPaybackTokenAddress() != address(0), "Payback: token address is the zero address");
        require(getPaybackPercentageRate() >= 100, "Payback: percentage rate cannot be less than 100");
        require(getPaybackPercentage() >= 1, "Payback: percentage cannot be less than 1");
        _;
    }

    function getPaybackTokenAddress() public view virtual returns (address) {
        return _tokenAddress;
    }

    function getPaybackPercentageRate() public view virtual returns (uint256) {
        return _percentageRate;
    }

    function getPaybackPercentage() public view virtual returns (uint256) {
        return _percentage;
    }

    function transferTokenAddress(address newTokenAddress) external virtual onlyOwner {
        require(newTokenAddress != address(0), "Payback: token address is the zero address");
        _transferTokenAddress(newTokenAddress);
    }

    function _transferTokenAddress(address newTokenAddress) private {
        address oldTokenAddress = _tokenAddress;
        _tokenAddress = newTokenAddress;

        emit PaybackTokenAddressTransferred(oldTokenAddress, newTokenAddress);
    }

    function transferPaybackPercentageRate(uint256 newPercentageRate) external virtual onlyOwner {
        require(newPercentageRate <= 100, "Payback: percentage rate cannot be less than 100");
        _transferPaybackPercentageRate(newPercentageRate);
    }

    function _transferPaybackPercentageRate(uint256 newPercentageRate) private {
        uint256 oldPercentageRate = _percentageRate;
        _percentageRate = newPercentageRate;

        emit PaybackPercentageRateTransferred(oldPercentageRate, newPercentageRate);
    }

    function transferPaybackPercentage(uint256 newPercentage) external virtual onlyOwner {
        require(newPercentage <= 1, "Payback: percentage cannot be less than 1");
        _transferPaybackPercentage(newPercentage);
    }

    function _transferPaybackPercentage(uint256 newPercentage) private {
        uint256 oldPercentage = _percentage;
        _percentage = newPercentage;

        emit PaybackPercentageTransferred(oldPercentage, newPercentage);
    }

    function paybackByMint(address to, uint256 amount) internal virtual validPercentage {
        IERC20LUXON(_tokenAddress).paybackByMint(to, amount * _percentage / _percentageRate);
    }

    function paybackByTransfer(address to, uint256 amount) internal virtual validPercentage {
        IERC20LUXON(_tokenAddress).paybackByTransfer(to, amount * _percentage / _percentageRate);
    }
}

// File: contracts/LuxOn/GachaMachine.sol


pragma solidity ^0.8.13;






contract GachaMachine is Payback, SuperOperators, ReentrancyGuard {
    address public mintAddress;
    address public mintGoodsAddress;

    uint256 public mintPrice;
    uint32 public onceMintCount;

    constructor(
        address _mintAddress,
        address _mintGoodsAddress,
        uint256 _mintPrice,
        uint32 _onceMintCount,
        address paybackAddress,
        uint256 paybackPercentageRate,
        uint256 paybackPercentage
    ) Payback(address(paybackAddress), paybackPercentageRate, paybackPercentage) {
        mintPrice = _mintPrice;
        onceMintCount = _onceMintCount;
        mintGoodsAddress = _mintGoodsAddress;
        mintAddress = _mintAddress;
    }

    //------------------ get ------------------//

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function getOnceMintCount() public view returns (uint32) {
        return onceMintCount;
    }

    function getMintGoodsAddress() public view returns (address) {
        return mintGoodsAddress;
    }

    function getMintAddress() public view returns (address) {
        return mintAddress;
    }

    //------------------ set ------------------//

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setOnceMintCount(uint32 _onceMintCount) external onlyOwner {
        onceMintCount = _onceMintCount;
    }

    function setMintGoodsAddress(address _mintGoodsAddress) external onlyOwner {
        mintGoodsAddress = _mintGoodsAddress;
    }

    function setMintAddress(address _mintAddress) external onlyOwner {
        mintAddress = _mintAddress;
    }

    //------------------ gacha ------------------//

    function gacha(address mintUser, uint32 quantity) external payable onlySuperOperator {
        require(quantity <= onceMintCount, "Once Exceeded the limit");
        mintPay(mintUser, quantity);
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success) = IERC20LUXON(mintGoodsAddress).transferFrom(address(this), msg.sender, IERC20LUXON(mintGoodsAddress).balanceOf(address(this)));
        require(success, "Transfer failed.");
    }

    //------------------ private ------------------//

    function mintPay(address mintUser, uint32 quantity) private {
        uint256 price = getMintPrice() * quantity;

        require(IERC20LUXON(mintGoodsAddress).balanceOf(mintUser) >= price, "Need to send more mint goods.");
        IERC20LUXON(mintGoodsAddress).transferFrom(mintUser, address(this), price);
        mintPayback(price);
        IERC721LUXON(mintAddress).mintLuxOn(mintUser, quantity);
    }

    function mintPayback(uint256 price) private {
        paybackByMint(msg.sender, price);
    }
}