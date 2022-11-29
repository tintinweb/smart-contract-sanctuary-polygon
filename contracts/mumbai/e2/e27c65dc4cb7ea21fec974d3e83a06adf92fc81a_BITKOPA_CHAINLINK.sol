/**
 *Submitted for verification at polygonscan.com on 2022-11-29
*/

// SPDX-License-Identifier: MIT

// File: @uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol


pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// File: @uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol


pragma solidity >=0.7.5;
pragma abicoder v2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
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

// File: @uniswap/v3-periphery/contracts/libraries/TransferHelper.sol


pragma solidity >=0.6.0;


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
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

// File: contracts/BITKOPA_CHAINLINK.sol



pragma solidity ^0.8.0;






interface Iverification {
       function checkVerificationStatus(address _addr) external view returns(bool);
}

contract BITKOPA_CHAINLINK is ReentrancyGuard{

    // interfaces
    //Bitkopa Verification
    Iverification VerificationInterface;

    //IERC20
    IERC20 ERC20Interface;

    //Uniswap Router - Required to liquidate collateral
    // Collateral is swapped to USDC on Uniswap V3
    ISwapRouter public immutable swapRouter;

    address  constant COLLATERAL_ADDRESS = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //chainlink mumbai
    uint256 constant COLLATERAL_DECIMALS = 18; //
    address  STABLECOIN = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; //mainnet for USDC

    // set the pool fee to 0.05%. => 500/10,000
    uint24   poolFee = 500;


    //USD PriceFeed 
    AggregatorV3Interface internal PriceFeedInterface;

    //events
    event LoanRequest(address indexed borrower, address refBorrower, uint256 loanId, uint256 duration, uint256 collateralAmount);
    event CollateralTopUp(address indexed borrower, address refBorrower, uint256 loanId, uint256 topUpAmount);
    event LoanRepayment(address indexed borrower, Loan activeLoan);
    event LoanProcessed(address indexed borrower, Loan processedLoan);
    event CollateralRecovery(address indexed borrower, Loan liquidatedLoan);
    event DirectDepositRecovery(address indexed owner, uint256 amount);
    event WithdrawExcessCollateral(address indexed borrower,uint256 amount, Loan targetLoan);
    event CollateralLiquidation(address indexed borrower, uint256 amountOut, Loan liquidatedLoan);

    //storage
    address private s_owner;
    uint256 public s_minCollateral; // minimum allowed collateral
    uint256 public s_maxLTV; // maximum loan amount you can receive
    uint256  s_priceDecimals = 8; //no. of decimals from price feed oracle
    uint256  s_FXDecimals = 8; //no. of decimals for the FX Rate
    uint256  s_interestRateDecimals = 8; //no. of decimals for the hourly interest rate
    uint256 public s_liquidationThreshold; // when LTV raises to this threshold, you get liquidated
    mapping(uint256 => LoanExtension) public s_loanDuration; //loan durations allowed (in days) e.g 7, 14, 30, their extension period and penalty
    uint256[] public s_loanIds; //to store loan ids
    uint256 public s_directDeposit; // holds MATIC that is sent directly to the contract. To allow recovery

    struct Loan{
       uint256 loanId;
       uint256 collateralAmount;
       uint256 loanAmount;
       uint256 paymentMethodId;
       uint256 duration;
       uint256 processedTimestamp;
       uint256 interestRate;
       uint256 FXRate;
       address borrower;
       LoanStatus status;
       uint256[] repayments;
    }
    struct LoanExtension{
        uint256 extendedDuration;
        uint256 interestRateMultiplier;
    }

    enum LoanStatus{
       Active,
       Completed,
       Liquidated,
       Requested
    }

    // to track loanIds beginning with 2540 - incremented before usage
    uint256 private s_loanId = 2539;

    //mapping for active loans
    mapping(uint256 => Loan) public s_Loans;

    constructor(address _verification, address _priceFeedContract, uint256 _maxLTV, uint256 _minCollateral, uint256 _liquidationThreshold, uint256[] memory _duration, uint256[] memory _extendedDuration, uint256[] memory _interestRateMultiplier,  ISwapRouter _swapRouter){
        VerificationInterface = Iverification(_verification);
        PriceFeedInterface = AggregatorV3Interface(_priceFeedContract);
        ERC20Interface = IERC20(COLLATERAL_ADDRESS);
        s_maxLTV = _maxLTV;
        s_minCollateral = _minCollateral;
        s_liquidationThreshold = _liquidationThreshold;
        swapRouter = _swapRouter;
        s_owner = msg.sender;
        require(_duration.length == _extendedDuration.length && _duration.length == _interestRateMultiplier.length, "Error in Loan Duration");
        for(uint8 i = 0; i< _duration.length; i++){
            s_loanDuration[_duration[i]] = LoanExtension({extendedDuration:_extendedDuration[i],interestRateMultiplier:_interestRateMultiplier[i]});
        }

      
    }

    // called by borrower to request for loan
    function loanRequest( uint256 _loanAmount, uint256 _duration, uint256 _collateralAmount, uint256 _paymentMethodId) external  returns (uint256 _loanId){
        // check if msg.sender is whiteListed
        require(VerificationInterface.checkVerificationStatus(msg.sender), "Not Authorised To Use Bitkopa.com services");

        //check if collateralAmount >= minCollateral
        require( _collateralAmount >= s_minCollateral, "Collateral Amount Is Below minimum");

        //LoanAmount will be validated by backend
        // If requested loan amount is 0, or > maxLTV, backend will disburse max LoanAmount depending on
        // collateralAmount otherwise requested loan amount will be disbursed

        //check if duration is supported  - 7days, 14 days, 30 days etc
        require(s_loanDuration[_duration].extendedDuration > 0, "Invalid Loan Duration");

        //transfer collateral from borrower to contract - frontend will handle approvals
        ERC20Interface.transferFrom(msg.sender, address(this), _collateralAmount);

        //create new loan 
        Loan memory newLoanRequest = Loan({loanId: ++s_loanId, 
        collateralAmount: _collateralAmount,
        loanAmount: _loanAmount,
        paymentMethodId: _paymentMethodId,
        duration: _duration,
        processedTimestamp: 0,
        interestRate: 0,
        FXRate:0,
        borrower: msg.sender,
        status: LoanStatus.Requested,
        repayments: new uint256[](0)});

        //make sure loanId hasnt been used yet
        //to avoid overwritting an existing loan request
        //the default collateralAmount is 0 for unused loanId
        require(s_Loans[newLoanRequest.loanId].collateralAmount == 0, "Loan Request Failed, Try Again Please");
        
        //map loan request with loanId
        s_Loans[newLoanRequest.loanId] = newLoanRequest;

        //add loanId to loanIds
        s_loanIds.push(newLoanRequest.loanId);
        // emit event
        emit LoanRequest(msg.sender, msg.sender, newLoanRequest.loanId, _duration, _collateralAmount);

        return newLoanRequest.loanId;
    }

    //called by owner to process loan request
    // means that FIAT has been sent to the user
    function processLoanRequest(uint256 _loanId, uint256 _loanAmount, uint256 _interestRate, uint256 _FXRate) external onlyOwner {

       //for non-existing loan request, collateralAmount = 0
       require(s_Loans[_loanId].collateralAmount >= s_minCollateral, "Invalid Loan ID"); 

       //assert the loan status is currently requested
       require(s_Loans[_loanId].status == LoanStatus.Requested, "Invalid Loan Status");

       //retrieve the loanRequest
        Loan memory pendingLoan = s_Loans[_loanId];

        pendingLoan.interestRate = _interestRate;
        pendingLoan.FXRate = _FXRate;
        pendingLoan.loanAmount = _loanAmount;
        pendingLoan.processedTimestamp = block.timestamp;
        pendingLoan.status = LoanStatus.Active;

        //update in storage
        s_Loans[_loanId] = pendingLoan;
        //emit event
        emit LoanProcessed(pendingLoan.borrower, pendingLoan);
    }

    // called by admin to reduce the loanAmount
    function Repayment(uint256 _loanId, uint256 _payment) external onlyOwner{
        //assert loan is active
        require(s_Loans[_loanId].status == LoanStatus.Active, "Invalid Loan Id");

        //No need for safe math - solidity 0.8+ handles overflows
        //push payment into repayments
        s_Loans[_loanId].repayments.push(_payment);

        uint256 loanBalance = getLoanBalance(s_Loans[_loanId]);

        //check if fully repaid
        if(loanBalance == 0){
            s_Loans[_loanId].status = LoanStatus.Completed;
            //send collateral back to borrower
            ERC20Interface.transfer(s_Loans[_loanId].borrower, s_Loans[_loanId].collateralAmount);
        }
        //event
        emit LoanRepayment(s_Loans[_loanId].borrower, s_Loans[_loanId]);

    }

    // called by borrower to increase collateralAmount
    function topUpCollateral(uint256 _loanId, uint256 _collateralAmount) external  {
        //assert msg.sender is the borrower
        require(s_Loans[_loanId].borrower == msg.sender, "Invalid Loan Id");

        //assert loan is still active -not completed/liquidated
        require(s_Loans[_loanId].status == LoanStatus.Active, "Loan Not Active, Already Completed or liquidated");

        //assert collateral > 0
        require(_collateralAmount> 0, "Invalid Amount");

        //Increment collateralAmount for the loan
        ERC20Interface.transferFrom(msg.sender, address(this), _collateralAmount);
        s_Loans[_loanId].collateralAmount += _collateralAmount;

        //emit event
        emit CollateralTopUp(msg.sender, msg.sender, _loanId, _collateralAmount);
    }

 
    //In the event a borrower tops up a liquidated loan during the liquidation block
    function recoverCollateral(uint256 _loanId) external {
        Loan memory liquidatedLoan = s_Loans[_loanId];
        //for non-existing loan collateralAmount = 0
        require(liquidatedLoan.collateralAmount > 0, "Invalid Loan ID"); 
        //assert loan is liquidated
        require(liquidatedLoan.status == LoanStatus.Liquidated, "Loan Not liquidated");

        //assert msg.sender is borrower
        require(liquidatedLoan.borrower == msg.sender, "Invalid Loan ID"); 
        
        //set collateralAmount to 0
        s_Loans[_loanId].collateralAmount = 0;

        // send the collateral to user
        ERC20Interface.transfer(liquidatedLoan.borrower, liquidatedLoan.collateralAmount);
        
        //emit event
        emit CollateralRecovery(liquidatedLoan.borrower, liquidatedLoan);
    }

     //allow owner to withdraw funds sent directly to the smart contract
    function recoverDirectDeposit() external  payable onlyOwner{
        require(s_directDeposit > 0, "No Direct Deposits");
        uint256 amount = s_directDeposit;
        s_directDeposit = 0; // reset to zero to avoid multiple withdrawals
        payable(s_owner).transfer(amount);

        //emit event
        emit DirectDepositRecovery(s_owner, amount);
    }

    
    // called by borrower to reduce collateral amount
    // collateral remaining cannot be < maxLTV
    // can only withdraw from an ongoing loan
    //reentrancy guard needed
    function withdrawExcessCollateral(uint256 _loanId, uint256 _withdrawAmount) external nonReentrant{
        Loan memory targetLoan = s_Loans[_loanId];
        //assert msg.sender is borrower
        require(targetLoan.borrower == msg.sender, "Invalid Loan Id");

        //assert loan is still active -not completed/liquidated
        require(targetLoan.status == LoanStatus.Active, "Loan Not Active, Already Completed or liquidated");

        uint256 collateralInLocalFiat = uint256((getCurrentprice() * targetLoan.collateralAmount * targetLoan.FXRate) / (10**s_priceDecimals*10**s_FXDecimals*10**COLLATERAL_DECIMALS));
        uint256 requiredCollateralLocalFiat = uint256(targetLoan.loanAmount * 100/s_maxLTV);
        uint256 excessCollateralLocalFiat = uint256(collateralInLocalFiat - requiredCollateralLocalFiat);
        uint256 excessCollateralCrypto = (excessCollateralLocalFiat * 10**COLLATERAL_DECIMALS * 10**s_priceDecimals * 10**s_FXDecimals) / (getCurrentprice() * targetLoan.FXRate);
        uint amount = 0;

        // check if withdrawAmount < excessCollateralCrypto
        if (_withdrawAmount < excessCollateralCrypto){
              amount = _withdrawAmount;
        }
        else{
            amount = excessCollateralCrypto;
        }
        //update collateralAmount first
        s_Loans[_loanId].collateralAmount -= amount;

        //send requested amount to borrower
        //assert amount > 0
        require(amount > 0, "Not Enough Excess Collateral");
        ERC20Interface.transfer(msg.sender, amount);
        
        //emit event
        emit WithdrawExcessCollateral(msg.sender, amount, targetLoan);
    }

    // called by chainlink keepers
    // checks for pending loans in the risk of liquidation
    // uses chainlink data feeds for checking collateral price
    // returns loanId for loan to liquidate
    // can be optimized to return array of loan Ids if need be
    function checkUpkeep(bytes calldata /* checkData */ ) external view  returns (bool upkeepNeeded, bytes memory performData) {
        //upkeepNeeded when there is a loan to liquidate
        uint256[] memory loanIds = s_loanIds;
        uint256  length = loanIds.length;
        for(uint i = 1; i < length +1; i++){
            //accessing active loans from end of array
            if(s_Loans[loanIds[length - i]].status == LoanStatus.Active){
            //check loan expiry or liquidation threshold
                if(checkLoanExpiry(s_Loans[loanIds[length - i]]) ||checkLiquidationThreshold(s_Loans[loanIds[length - i]]) ){
                    performData = abi.encode(s_Loans[loanIds[length - i]].loanId);
                    upkeepNeeded = true;
                    return(upkeepNeeded, performData);
                }      
            }
        }
        
}

    // checks for loans to liquidate
    // liquidate through uniswap in mainnet
    // for testnet, send collateral to admin 
    // for manual liquidation
    // all the USDC is sent to admin
    // update loan to liquidated
    function performUpkeep(bytes calldata performData ) external  {
        //decode performData
        uint256 loanId = abi.decode(performData, (uint256));
        //retrieve the loan
        Loan memory targetLoan = s_Loans[loanId];
        //check if loan is active
        require(targetLoan.status == LoanStatus.Active, "Loan Not Active");
        //check if loan expired
        if(checkLoanExpiry(targetLoan) || checkLiquidationThreshold(targetLoan)){
              uint256 amount = targetLoan.collateralAmount;
              //subtract amount from collateral
              s_Loans[loanId].collateralAmount -= amount;
              //change status to liquidated
              s_Loans[loanId].status = LoanStatus.Liquidated;
              
              // on mainnet - Liquidation through Uniswap V3
              //uint256 amountOut = liquidateCollateral(amount, getCurrentprice());
              //emit event
              //emit CollateralLiquidation(targetLoan.borrower, amountOut, targetLoan);

              //on testnet - send collateral to admin for manual liquidation
              ERC20Interface.transfer(s_owner, amount);
              
               emit CollateralLiquidation(targetLoan.borrower, amount, targetLoan);
            }
        
    }
    
    //UTILITY functions

     // Function to receive Ether. msg.data must be empty
    receive() external payable{
        s_directDeposit += msg.value;
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
         s_directDeposit += msg.value;
    }

    // gets the current price of MATIC from chainlink oracles in USD
    function getCurrentprice() internal view returns(uint256 _currentPrice){
        //get current price of collateral in usd
         (
            ,
            /*uint80 roundID*/ int256 currentPrice /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = PriceFeedInterface.latestRoundData();

        //get current Price in usd
        _currentPrice = uint256(currentPrice);
        return _currentPrice;

    }

    //returns the loan balance
    //if repayments > loanAmount, return 0
    function getLoanBalance(Loan memory _loan) internal view returns(uint256){
        uint8 i = 0;
        uint256 totalRepayments = 0;
        uint256 interest = calculateInterest(_loan);
        for(i; i < _loan.repayments.length; i++){
            totalRepayments += _loan.repayments[i];
        }
        if (totalRepayments > _loan.loanAmount + interest){
            return 0;
        }
        else{
            return _loan.loanAmount + interest - totalRepayments;
        }
    }

    //used to calculate the interest 
    //returns loanAmount - repayments
    function reducingLoanBalance(Loan memory _loan) internal pure returns(uint256){
        uint8 i = 0;
        uint256 totalRepayments = 0;
        for(i; i < _loan.repayments.length; i++){
            totalRepayments += _loan.repayments[i];
        }
        if (totalRepayments > _loan.loanAmount ){
            return 0;
        }
        else{
            return _loan.loanAmount  - totalRepayments;
        }
    }

    //returns the interest accrued by a loan
    function calculateInterest(Loan memory _loan) internal view returns (uint256){
        uint256 duration = block.timestamp - _loan.processedTimestamp;
        if(uint256(duration/ 1 hours) < 1){
            duration = 1;
        }
        else{
            duration = uint256(duration/ 1 hours);
        }
        uint256 interest = uint256((reducingLoanBalance(_loan) * _loan.interestRate * duration) / (10**s_interestRateDecimals * 100));

        //interest rate is increased if loan duration is exceeded
        if (block.timestamp > (_loan.processedTimestamp + _loan.duration * 1 days)){
            return interest * s_loanDuration[_loan.duration].interestRateMultiplier;
        }
        else{
            return interest;
        }
        

    }

    // checks if a loan has exceeded the loan duration + extendedDuration
    function checkLoanExpiry(Loan memory _loan) internal view returns(bool){
        if(block.timestamp > (_loan.processedTimestamp + _loan.duration * 1 days) + (s_loanDuration[_loan.duration].extendedDuration * 1 days)){
            return true;
        }
        else{
            return false;
        }
    }

    // checks if loan Amount has exceeded the liquidation threshold
    // as value of collateral drops, LTV increases
    function checkLiquidationThreshold(Loan memory _loan) internal view returns(bool){

        uint256 collateralInLocalFiat = uint256((getCurrentprice() * _loan.collateralAmount * _loan.FXRate) / (10**s_priceDecimals*10**s_FXDecimals*10**COLLATERAL_DECIMALS));
        if(getLoanBalance(_loan) >= uint256((s_liquidationThreshold*collateralInLocalFiat)/100)){
          
            return true;
        }
        else{
            return false;
        }
    }


    // swaps Collateral for USDC on Uniswap V3
    function liquidateCollateral(uint256 _collateralAmount, uint256 _currentPrice) internal returns(uint256 amountOut) {
       
        //second step approve SwapRouter to spend WMATIC
        TransferHelper.safeApprove(COLLATERAL_ADDRESS, address(swapRouter), _collateralAmount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: COLLATERAL_ADDRESS,
            tokenOut: STABLECOIN,
            fee: poolFee,
            recipient:s_owner,
            deadline:block.timestamp + 30 minutes,
            amountIn:_collateralAmount,
            amountOutMinimum:uint256((s_liquidationThreshold *_collateralAmount*_currentPrice) / (100 * 10**COLLATERAL_DECIMALS * 10**s_priceDecimals)), //atleast 80% at current prices
            sqrtPriceLimitX96: 0  //to ensure we swap the exact input amount
        });

        amountOut = swapRouter.exactInputSingle(params);


    }
  
    //GETTERS

    //returns balance of the contract
    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    //returns balance of funds sent directly to the contract
    function getDirectDepositBalance() public view returns (uint256){
        return s_directDeposit;
    }

    //returns a Loan
    function getLoan(uint256 _loanId) public view returns(Loan memory){
        return s_Loans[_loanId];
    }

    //returns the Loan balance for a particular loan
    function LoanBalance(uint256 _loanId) public view returns(uint256){
        return getLoanBalance(s_Loans[_loanId]);
    }

    //returns the interest owed by borrower
    function getLoanInterest(uint256 _loanId) public view returns(uint256){
        return calculateInterest(s_Loans[_loanId]);
    }
    //returns array of repayments
    function getLoanRepayments(uint256 _loanId) public view returns(uint256[] memory){
        return s_Loans[_loanId].repayments;
    }
    //returns all the loan Ids, will be useful in the frontend
    function getLoanIds() public view returns(uint256[] memory){
        return s_loanIds;
    }

    //Loan config function
    function loanConfig(uint256 _minCollateral, uint256 _maxLTV, uint256 _liquidationThreshold, uint256[] memory _duration, uint256[] memory _extendedDuration, uint256[] memory _interestRateMultiplier, uint256 _priceDecimals, uint256 _FXDecimals, uint256 _interestRateDecimals ) external onlyOwner{
        s_minCollateral = _minCollateral;
        s_maxLTV = _maxLTV;
        s_liquidationThreshold = _liquidationThreshold;
        s_priceDecimals = _priceDecimals;
        s_FXDecimals = _FXDecimals;
        s_interestRateDecimals = _interestRateDecimals;
        require(_duration.length == _extendedDuration.length && _duration.length == _interestRateMultiplier.length, "Error in Loan Duration");
        for(uint8 i = 0; i< _duration.length; i++){
            s_loanDuration[_duration[i]] = LoanExtension({extendedDuration:_extendedDuration[i],interestRateMultiplier:_interestRateMultiplier[i]});
        }

    }
    function uniswapConfig(uint24 _poolFee, address _stablecoin) external onlyOwner{
        poolFee = _poolFee;
        STABLECOIN = _stablecoin;
    }

    modifier onlyOwner(){
        require(msg.sender == s_owner);
        _;
    }

}