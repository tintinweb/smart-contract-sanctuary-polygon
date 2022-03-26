//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ShopContract is KeeperCompatibleInterface {

    uint256 private freePaymentEntryId;
    uint256 private freeSettledPaymentId;

    AggregatorV3Interface internal priceFeedMatic = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
    AggregatorV3Interface internal priceFeedDAI = AggregatorV3Interface(0x0FCAa9c899EC5A91eBc3D5Dd869De833b06fB046);

    uint256 private immutable interval;
    uint256 private immutable expireDuration;
    uint256 private lastTimeStamp;
    uint256 private lastTimeIndex;

    uint256 public slippageClient; //in x1000, so 5 -> 0.5% slippage
    uint256 public slippageExchange;
    uint256 public slippageDAI;

    uint256 private feeToTake;
    address payable shopchainAddress;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IUniswapV2Factory public immutable uniswapV2Factory;

    IERC20 DAI = IERC20(0xcB1e72786A6eb3b44C2a2429e317c8a2462CFeb1);

    enum Status{
        CANCELLED,
        PAID,
        UNLOCKED,
        EXPIRED
    }

    struct PaymentEntry {
        address seller;
        uint256 price; // Dollars cent
    }

    struct SettledPayment {
        uint256 paymentEntryId;
        Status status;
        address client;
        uint256 time;
        uint256 amountInDAI;
    }

    mapping(uint256 => PaymentEntry) private paymentsEntries;
    mapping(uint256 => SettledPayment) private settledPayments;

    event addedPaymentEntry(uint256 paymentEntryId);
    event paymentSettled(uint256 settledPaymentId);
    event statusChanged(uint256 settledPaymentId);

    modifier inBoundsPaymentEntryIndex(uint256 paymentEntryId) {
        require(paymentEntryId < freePaymentEntryId);
        _;
    }

    modifier inBoundsSettledPaymentIndex(uint256 settledPaymentId) {
        require(settledPaymentId < freeSettledPaymentId);
        _;
    }

    modifier onlyClient(uint256 settledPaymentId) {
        require(settledPayments[settledPaymentId].client == msg.sender);
        _;
    }

    modifier onlySeller(uint256 settledPaymentId) {
        require(paymentsEntries[settledPayments[settledPaymentId].paymentEntryId].seller == msg.sender);
        _;
    }

    modifier statusPaid(uint256 settledPaymentId) {
        require(settledPayments[settledPaymentId].status == Status.PAID);
        _;
    }

    modifier peggedDAI { //requires that the DAI value is pegged to USD (in the interval defined by slippageDAI), prevents catastrophic failure if DAI gets pwned
        (,int truncatedPriceDAI,,,) = priceFeedDAI.latestRoundData();
        uint256 priceDAI = uint256(truncatedPriceDAI) * 10**10; //8 decimals + 10 = 18 decimals
        require(priceDAI >= 10**18 - getSlippageAmount(10**18, slippageDAI) && priceDAI <= 10**18 + getSlippageAmount(10**18, slippageDAI));
        _;
    }

    modifier sufficientMatic(uint256 paymentEntryId) {
        (,int priceMatic,,,) = priceFeedMatic.latestRoundData(); //8 decimals
        uint256 priceInMatic = paymentsEntries[paymentEntryId].price * (10**24)/uint256(priceMatic);
        require(msg.value >= priceInMatic - getSlippageAmount(priceInMatic, slippageClient) && msg.value <= priceInMatic + getSlippageAmount(priceInMatic, slippageClient)); //client matic slippage check
        _;
    }

    /**
     * https://docs.chain.link/docs/matic-addresses/
     * Network: Mumbai Testnet
     * Aggregator: MATIC/USD Dec: 8
     * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     */
    constructor(uint256 _interval, uint256 _expireDuration, uint256 _slippageClient, uint256 _slippageExchange, uint256 _slippageDAI, uint256 _feeToTake, address payable _shopchainAddress){

        freePaymentEntryId = 0;
        freeSettledPaymentId = 0;

        lastTimeStamp = block.timestamp;
        lastTimeIndex = 0;

        interval = _interval;
        expireDuration = _expireDuration;

        slippageClient = _slippageClient;
        slippageExchange = _slippageExchange;
        slippageDAI = _slippageDAI;

        feeToTake = _feeToTake;
        shopchainAddress = _shopchainAddress;

        uniswapV2Router = IUniswapV2Router02(0x8954AfA98594b838bda56FE4C12a09D7739D179b);
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Router.factory());

    }

    function getSlippageAmount(uint256 number, uint256 slippage) internal pure returns(uint256){
        return (number * slippage)/1000;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {

        require((block.timestamp - lastTimeStamp) > interval);
        uint256 i = lastTimeIndex;

        while (i < freeSettledPaymentId && (block.timestamp - settledPayments[i].time) > expireDuration) {

            if (settledPayments[i].status == Status.PAID) {

                DAI.transfer(settledPayments[i].client, settledPayments[i].amountInDAI);
                settledPayments[i].status = Status.EXPIRED;
                emit statusChanged(i);

            }
            i++;
        }
        lastTimeIndex = i;
        lastTimeStamp = block.timestamp;
    }

    function addPaymentEntry(uint256 price) public {
        require(price > 0);
        paymentsEntries[freePaymentEntryId] = PaymentEntry(msg.sender, price);
        freePaymentEntryId = freePaymentEntryId + 1;
        emit addedPaymentEntry(freePaymentEntryId - 1);
    }

    function settlePayment(uint256 paymentEntryId) payable public inBoundsPaymentEntryIndex(paymentEntryId) sufficientMatic(paymentEntryId) peggedDAI{

        DAI.approve(address(uniswapV2Router), msg.value);

        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH(); //WMATIC canonic address
        path[1] = address(DAI);

        (,int truncatedPriceDAI,,,) = priceFeedDAI.latestRoundData();
        uint256 priceDAI = uint256(truncatedPriceDAI) * 10**10; //8 decimals + 10 = 18 decimals

        uint256 minAmountDAI = (paymentsEntries[paymentEntryId].price/priceDAI);
        minAmountDAI = minAmountDAI - getSlippageAmount(minAmountDAI, slippageExchange); //removes slippage %, slippageExchange is the slippage calculated on the real DAI price, value may vary according to slippageDAI

        uint[] memory amountsDAI = uniswapV2Router.swapExactETHForTokens{value: msg.value}(minAmountDAI, path, address(this), block.timestamp); //EXACT amount of DAI received

        settledPayments[freeSettledPaymentId] = SettledPayment(paymentEntryId, Status.PAID, msg.sender, block.timestamp, amountsDAI[amountsDAI.length - 1]);
        freeSettledPaymentId = freeSettledPaymentId + 1;

        emit paymentSettled(freeSettledPaymentId - 1);

    }

    function unlockFunds(uint256 settledPaymentId) public inBoundsSettledPaymentIndex(settledPaymentId) onlyClient(settledPaymentId) statusPaid(settledPaymentId){

        address payable sellerAddress = payable(paymentsEntries[settledPayments[settledPaymentId].paymentEntryId].seller);

        uint256 amountToTake = (settledPayments[settledPaymentId].amountInDAI * feeToTake)/1000;

        DAI.transferFrom(address(this), sellerAddress, settledPayments[settledPaymentId].amountInDAI - amountToTake);
        DAI.transferFrom(address(this), shopchainAddress, amountToTake);

        settledPayments[settledPaymentId].status = Status.UNLOCKED;

        emit statusChanged(settledPaymentId);
    }

    function cancelPayment(uint256 settledPaymentId) public inBoundsSettledPaymentIndex(settledPaymentId) onlySeller(settledPaymentId) statusPaid(settledPaymentId){

        address payable addr = payable(settledPayments[settledPaymentId].client);
        DAI.transfer(addr, settledPayments[settledPaymentId].amountInDAI);

        settledPayments[settledPaymentId].status = Status.CANCELLED;

        emit statusChanged(settledPaymentId);
    }

    function revertPayment(uint256 settledPaymentId) public inBoundsSettledPaymentIndex(settledPaymentId) onlyClient(settledPaymentId) statusPaid(settledPaymentId){
        require(block.timestamp - settledPayments[settledPaymentId].time > expireDuration); //txn expired

        DAI.transfer(settledPayments[settledPaymentId].client, settledPayments[settledPaymentId].amountInDAI);
        settledPayments[settledPaymentId].status = Status.EXPIRED;
        emit statusChanged(settledPaymentId);
    }

    function getPaymentEntry(uint256 paymentEntryId) public view inBoundsPaymentEntryIndex(paymentEntryId) returns(PaymentEntry memory){
        return paymentsEntries[paymentEntryId];
    }

    function getSettledPayment(uint256 settledPaymentId) public view inBoundsSettledPaymentIndex(settledPaymentId) returns(SettledPayment memory){
        return settledPayments[settledPaymentId];
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}