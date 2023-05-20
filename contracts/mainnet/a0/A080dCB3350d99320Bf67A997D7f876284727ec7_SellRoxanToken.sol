/**
 *Submitted for verification at polygonscan.com on 2023-05-20
*/

// SPDX-License-Identifier: MIT
// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

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

// File: contracts/RoxanSellContract.sol



pragma solidity ^0.8.8;





contract SellRoxanToken is Ownable, ReentrancyGuard{
    AggregatorV3Interface internal priceFeedMatic;
    AggregatorV3Interface internal priceFeedWeth;

    IERC20 public roxanToken;
    IERC20 public USDT;
    IERC20 public WETH;
    bool public isPaused;

    constructor(IERC20 _roxanToken, IERC20 _usdtToken, IERC20 _wethToken)
    {
        roxanToken=_roxanToken;
        USDT=_usdtToken;
        WETH=_wethToken;
        isPaused=true;
        priceFeedMatic = AggregatorV3Interface(
            0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
 
        );
         priceFeedWeth = AggregatorV3Interface(
             0xF9680D99D6C9589e2a93a78A04A279e509205945
        );


    }
    /// @notice 2 = 0.2 so, 1 ROX = 0.2 USDT
    uint256 public tokenPrice=2;
    
    // write the function for buying the token from usdt
    function buyWithUsdt(uint256 _amount) external nonReentrant  returns(bool){
        require(isPaused,"Contract is paused");
        require(roxanToken.balanceOf(address(this))>=_amount,"less pool bal.");
        uint256 usdtFee= estimateWithUsdt(_amount);
        require(USDT.balanceOf(msg.sender)>=usdtFee,"Less usdt balance");
        USDT.transferFrom(msg.sender,address(this),usdtFee);
        roxanToken.transfer(msg.sender,_amount);
        return true;
    }

    // write the function for buying the token from matic
    function buyWithMatic(uint256 _amount) external payable nonReentrant returns(bool){
        require(isPaused,"Contract is paused");
        require(roxanToken.balanceOf(address(this))>=_amount,"less pool bal.");
        uint256 maticFee= estimateWithMatic(_amount);
        require(msg.value>=maticFee,"less matic value");
        roxanToken.transfer(msg.sender,_amount);
        return true;
    }

    // write the function for buying the token from matic
    function buyWithWeth(uint256 _amount) external nonReentrant returns(bool){
        require(isPaused,"Contract is paused");
        require(roxanToken.balanceOf(address(this))>=_amount,"less pool bal.");
        uint256 wethFee= estimateWithWeth(_amount);
        require(WETH.balanceOf(msg.sender)>=wethFee,"Less weth balance");
        WETH.transferFrom(msg.sender,address(this),wethFee);
        roxanToken.transfer(msg.sender,_amount);
        return true;
    }

    // function for withdraw ROX from contract -  onlyOwner
      function withdrawRoxan(uint256 _amount) external onlyOwner returns(bool){
        require(roxanToken.balanceOf(address(this))>_amount,"less roxan bal.");
        roxanToken.transfer(owner(),_amount);
        return true;
    }

     // function for withdraw Matic from contract -  onlyOwner
      function withdrawMatic(uint256 _amount) external onlyOwner returns(bool){
        require(address(this).balance>=_amount,"less matic bal.");
        payable(owner()).transfer(_amount);
        return true;
    }

     // function for withdraw WETH and USDT if have on contract -  onlyOwner
    function withdrawTokenFromContract(address _tokenAddress, uint256 _amount) external onlyOwner returns(bool){
        IERC20 token= IERC20(_tokenAddress);
        require(token.balanceOf(address(this))>=_amount,"less pool token bal.");
        token.transfer(owner(),_amount);
        return true;
    }

    function updateRoxanToken(IERC20 _roxanToken) external onlyOwner returns(bool){
        roxanToken=_roxanToken;
        return true;
    }
    function updateUSDTAddress(IERC20 _usdtToken) external onlyOwner returns(bool){
        USDT=_usdtToken;
        return true;
    }
    function updateWETHAddress(IERC20 _wethToken) external onlyOwner returns(bool){
        WETH=_wethToken;
        return true;
    }
    
    // pass number in a digit
    function updateTokenPrice(uint256 _tokenPrice) external onlyOwner returns(bool){
        tokenPrice = _tokenPrice;
        return true;
    }
    // To secure the contract owner can on off the buy roxan contract.
    function togglePaused() external onlyOwner{
        isPaused = !isPaused;
    }

    function getLatestMaticPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedMatic.latestRoundData();
        return uint256(price/10**6);
    }
     function getLatestWethPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeedWeth.latestRoundData();
        return uint256(price/10**6);
    }

    // 1 token = 0.2 USDT * (1 Matic / 0.85 USDT) 
    function estimateWithMatic(uint256 _tokenBuyAmount) public view returns(uint256){
         uint256 liveMaticPrice= getLatestMaticPrice();
         uint256 calFee= (_tokenBuyAmount*tokenPrice*10)/(liveMaticPrice);
         return calFee;

    }
    function estimateWithWeth(uint256 _tokenBuyAmount) public view returns(uint256){
         uint256 liveWethPrice= getLatestWethPrice();
         uint256 calFee= (_tokenBuyAmount*tokenPrice*10)/(liveWethPrice);
         return calFee;

    }
    // write the function for estimate usdt price
    function estimateWithUsdt(uint256 _tokenBuyAmount) public view returns(uint256){
        uint256 calUsdt= (tokenPrice * _tokenBuyAmount)/(10*10**12);
        return calUsdt;
    }

    receive() external payable{}

}