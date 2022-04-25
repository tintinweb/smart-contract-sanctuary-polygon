/**
 *Submitted for verification at polygonscan.com on 2022-04-24
*/

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

// File: chrisfund/IERC20.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}
// File: chrisfund/1inchproxy.sol


pragma solidity ^0.8.6;



contract TradingContract is Ownable {

    // variables to define our t&c for deposits and trading
    address public paymentToken; // this will initially be set to USDT on BSC
    address public depositContract;
    address public fundWallet;
    address public immutable AGGREGATION_ROUTER_V3;

    // SwapDescription that the 1inch calldata will decode into
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    // Struct and mapping to record our trading history
    struct FullSwap {
        uint256 usdIn;
        int profit;
        address assetTraded;
        uint256 amountPurchased;
    }
    mapping(uint => FullSwap) public trades;
    event TradeCompleted(
        FullSwap result);
    // variables to define our trading results
    int public profits;
    int public owingToFund;
    int public netDeposits;

    constructor(address router, address _paymentToken, address _depositContract, address _fundWallet) {
        AGGREGATION_ROUTER_V3 = router;
        depositContract = _depositContract;
        paymentToken=_paymentToken;
        fundWallet=_fundWallet;
    }

    function swap(uint tradeId, uint minOut, bytes calldata _data) external onlyOwner {
        // decode the calldata
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));
        // Approve the router to spend this contract's token
        IERC20(desc.srcToken).approve(AGGREGATION_ROUTER_V3, desc.amount);
        // make the router call to execute token swap
        (bool succ, bytes memory _data) = address(AGGREGATION_ROUTER_V3).call(_data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            // we record a successful trade or a new trade here
            if (trades[tradeId].usdIn==0){
                trades[tradeId].usdIn=desc.amount;
                trades[tradeId].assetTraded=address(desc.dstToken);
                trades[tradeId].amountPurchased=returnAmount;
            } else if (address(desc.dstToken)==paymentToken) {
                int profit=int(returnAmount - trades[tradeId].usdIn);
                trades[tradeId].profit=profit;
                profits+=profit;
                owingToFund+=profit/10000*2000; // 20% 0x1111111254fb6c44bAC0beD2854e76F90643097d
                emit TradeCompleted(trades[tradeId]);
            }
        } else {
            revert();
        }
    }

    // function to move funds back to the deposit contract so they can be paid out
    function moveFundsToDP(uint amount) external onlyOwner {
        netDeposits-=int(amount);
        IERC20(paymentToken).transfer(depositContract,amount);
    }
    // external function to be called by the deposit contract to allow for funds to be transferred to the trading contract for investments
    function depositToTradingContract(uint amount) external onlyOwner{
        netDeposits+=int(amount);
        require(IERC20(paymentToken).transferFrom(depositContract,address(this),amount),"Could not transfer token to contract. Ensure allowance has been given");
    }
    // Function to transfer the share of profits owed to the fund, to the fund
    function transferProfits() external onlyOwner {
        netDeposits-=owingToFund;
        IERC20(paymentToken).transfer(fundWallet,uint(owingToFund));
        owingToFund=0;
    }

    function getFundValue() public view returns (int fundvalue) {
        return int(IERC20(paymentToken).balanceOf(depositContract)) + netDeposits + profits - owingToFund;
    }
    // FOR TESTING PURPOSES ONLY, DO NOT INCLUDE THIS IS PRODUCTION
    function addProfits(int profit) external {
        profits+=profit;
        owingToFund+=profit/10000*2000; // 20% 
    }
}