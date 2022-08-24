// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './RegistryHelper.sol';

import './interfaces/IVersionedContract.sol';
import './interfaces/IExecutor.sol';
import './interfaces/IBEP20.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IPullPaymentRegistry.sol';
import './interfaces/ITokenConverter.sol';
import '../pullPayments/interfaces/IPullPayment.sol';

/**
 * @title Executor
 * @author The Pumapay Team
 * @notice This contract executes the pullpayment for customer.
 *	This retrieves the payment tokens from user and transfers them to merchant.
 * @dev swap protocol is used to convert the user`s payment token to settlement token.
 * Execution fee is charged from the customer`s payment token and remaining tokens are sent to the merchant.
 * A typical example of execution is payment of 10PMA to merchant.
 * In this, if 10% is execution fee then execution fee receiver gets 1PMA and merchant receives 9PMA.
 */
contract Executor is ReentrancyGuard, RegistryHelper, IExecutor, IVersionedContract {
	/*
   	=======================================================================
   	======================== Constants ====================================
   	=======================================================================
 	*/
	uint256 constant deadline = 10 days;
	uint256 constant MAX_INT = type(uint256).max;

	/*
   	=======================================================================
   	======================== Public Variables ============================
   	=======================================================================
 	*/
	/// @dev PullPayment registry contract
	IPullPaymentRegistry public pullPaymentRegistry;
	/// @dev PMA token contract
	IBEP20 public PMAToken;
	/// @dev swap protocol router (Pancakeswap router)
	IUniswapV2Router02 public uniswapRouterV2;
	/// @dev swap protocol factory (Pancakeswap factory)
	IUniswapV2Factory public uniswapFactory;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @dev This method initializes registry helper to be able to access method of core registry.
	 * Also initializes the uniswpa factory, router, ppRegistry and pma token contracts
	 */
	constructor(address registryAddress) RegistryHelper(registryAddress) {
		pullPaymentRegistry = IPullPaymentRegistry(registry.getPullPaymentRegistry());
		PMAToken = IBEP20(registry.getPMAToken());
		uniswapRouterV2 = IUniswapV2Router02(registry.getUniswapRouter());
		uniswapFactory = IUniswapV2Factory(registry.getUniswapFactory());
	}

	/*
   	=======================================================================
   	======================== Modifiers ====================================
 		=======================================================================
 	*/

	/// @notice This modifier checks only granted executors are calling the execute method
	modifier onlyGrantedExecutors(address _executor) {
		require(
			pullPaymentRegistry.isExecutorGranted(_executor) == true,
			'Executor: PERMISSION_DENIED'
		);
		_;
	}

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 *  @notice This function executes the pullpayment of given billing model for given subscription id
	 *  @dev This function calls the executePullpayment method of pullpayment contract
	 *  @param _bmType indicates the pullPayment contracts name.
	 *  @param _subscriptionId indicates the subscription id of customer
	 *	@return pullPaymentID - id of executed pullpayment
	 */
	function execute(string calldata _bmType, uint256 _subscriptionId)
		external
		virtual
		override
		returns (uint256 pullPaymentID)
	{
		bytes32 identifierHash = keccak256(abi.encodePacked(_bmType));
		address pullPaymentAddress = pullPaymentRegistry.getPPAddressForOrDie(identifierHash);

		//get the pullPayment contract interface
		IPullPayment pullPayment = IPullPayment(pullPaymentAddress);

		//Execute the pullPayment for given subscriptionId for given BillingModel type
		//Current Flow for pullPayment execution
		//backend-> Executor(public execute()) -> RecurringPullPayment(executePullPayment()) -> Executor(internal execute())
		return pullPayment.executePullPayment(_subscriptionId);
	}

	function execute(
		address settlementToken,
		address paymentToken,
		address from,
		address to,
		uint256 amount
	) external virtual override onlyGrantedExecutors(msg.sender) returns (bool) {
		IBEP20 _paymentToken = IBEP20(paymentToken);
		require(registry.isSupportedToken(paymentToken), 'Executor: PAYMENT_TOKEN_NOT_SUPPORTED');

		// For all the cases below we have the following convention
		// <payment token> ---> <settlement token>
		// ========================================
		// Case 1: PMA ---> PMA payment,
		// 1. Get PMA tokens from user
		// 1. Transfer execution fee in PMA
		// 2. Then simple transfer same tokens to merchant - No need to SWAP
		if (paymentToken == settlementToken && paymentToken == address(PMAToken)) {
			// get tokens from the user
			require(_paymentToken.transferFrom(from, address(this), amount));

			uint256 executionFee = _transferExecutionFee(_paymentToken, amount);

			require(_paymentToken.transfer(to, amount - executionFee), 'Executor: TRANSFER_FAILED');

			return true;
		} else {
			_execute(settlementToken, IBEP20(paymentToken), from, to, amount);
			return true;
		}
	}

	/**
	 * @notice This method returns merchant` receiving amount, user`s payable amount and execution fee charges when given payment token and settlement tokens
	 * @dev
	 *	``` Execution fee = user payable amount * execution fee / 10000 ```
	 *	``` Receiving Amount = user payable amount - execution fee ```
	 * @param _paymentToken 			- indicates the payment token address
	 * @param _settlementToken 		- indicates the settlement token address
	 * @param _amount 						- indicates the amount of tokens to swap
	 * @return receivingAmount 		- indicates merchant` receiving amount after cutting the execution fees
	 * userPayableAmount 					- indicates customer` payble amount
	 * executionFee 							- indicates amount of execution fee charged from payment token
	 */
	function getReceivingAmount(
		address _paymentToken,
		address _settlementToken,
		uint256 _amount
	)
		public
		view
		virtual
		returns (
			uint256 receivingAmount,
			uint256 userPayableAmount,
			uint256 executionFee
		)
	{
		uint256 executionFeePercent = registry.executionFee();

		if (_paymentToken == _settlementToken && _paymentToken == address(PMAToken)) {
			// Case 1: token0 --> token0
			// In this case, we need directly transfers the tokens
			executionFee = (_amount * executionFeePercent) / 10000;

			userPayableAmount = _amount;
			receivingAmount = _amount - executionFee;
		} else {
			(
				bool canSwap,
				bool isTwoPaths,
				address[] memory path1,
				address[] memory path2
			) = canSwapFromV2(_paymentToken, _settlementToken);

			require(canSwap, 'Executor: NO_SWAP_PATH_EXISTS');

			// This flow is executed when neither of the token is PMA token
			if (isTwoPaths) {
				// get required PMA tokens for non-pma tokens
				uint256[] memory path2Amount = uniswapRouterV2.getAmountsIn(_amount, path2);
				// get required non-PMA tokens for PMA tokens
				uint256[] memory path1Amount = uniswapRouterV2.getAmountsIn(path2Amount[0], path1);

				userPayableAmount = path1Amount[0];
				executionFee = path1Amount[path1Amount.length - 1] * executionFeePercent / 10000;

				uint256 finalAmount = path1Amount[path1Amount.length - 1] - executionFee;

				uint256[] memory amountsOut = uniswapRouterV2.getAmountsOut(finalAmount, path2);

				receivingAmount = amountsOut[amountsOut.length - 1];
			} else {
				uint256[] memory amountInMax = uniswapRouterV2.getAmountsIn(_amount, path1);

				userPayableAmount = amountInMax[0];

				// transfer execution fee
				if (_paymentToken == address(PMAToken)) {
					// get execution fees in PMA
					executionFee = amountInMax[0] * executionFeePercent / 10000;
					uint256 finalAmount = amountInMax[0] - executionFee;

					uint256[] memory amountsOut = uniswapRouterV2.getAmountsOut(finalAmount, path1);
					receivingAmount = amountsOut[amountsOut.length - 1];
				} else if (_settlementToken == address(PMAToken)) {
					uint256[] memory amountsOut = uniswapRouterV2.getAmountsOut(amountInMax[0], path1);
					executionFee = amountsOut[amountsOut.length - 1] * executionFeePercent / 10000;

					receivingAmount = amountsOut[amountsOut.length - 1] - executionFee;
				}
			}
		}
	}

	/**
	 * @notice This method checks whether from token can be converted to toToken or not. returns true and swap path is there otherwise returns false.
	 * @param _fromToken 	- indicates the Payment Token
	 * @param _toToken	  - indicates settlement token
	 * @return canSWap 		- indicates whether thers is path for swap or not. 	 
	 					 path 			- indicates swap path
	 */
	function canSwapFromV2(address _fromToken, address _toToken)
		public
		view
		virtual
		returns (
			bool canSWap,
			bool isTwoPaths,
			address[] memory path1,
			address[] memory path2
		)
	{
		address pma = address(PMAToken);

		if (_fromToken == pma && _toToken == pma) {
			canSWap = true;
			return (canSWap, isTwoPaths, path1, path2);
		}

		address wbnb = registry.getWBNBToken();

		// CASE: PMA -> non-PMA || non-PMA -> PMA
		if (_fromToken == pma || _toToken == pma) {
			// check direct path for PMA
			if (_haveReserve(IUniswapV2Pair(uniswapFactory.getPair(_fromToken, _toToken)))) {
				canSWap = true;

				path1 = new address[](2);
				path1[0] = _fromToken;
				path1[1] = _toToken;
			} else {
				IUniswapV2Pair pair1 = IUniswapV2Pair(uniswapFactory.getPair(_fromToken, wbnb));
				IUniswapV2Pair pair2 = IUniswapV2Pair(uniswapFactory.getPair(wbnb, _toToken));

				if (_haveReserve(pair1) && _haveReserve(pair2)) {
					canSWap = true;

					path1 = new address[](3);
					path1[0] = _fromToken;
					path1[1] = wbnb;
					path1[2] = _toToken;
				}
			}
		} else {
			// CASE: non-PMA token0 -> non-PMA token1
			// 1. convert non-PMA token0 to PMA
			// 2. convert PMA to non-PMA token1

			// check path through the PMA
			IUniswapV2Pair pair1 = IUniswapV2Pair(uniswapFactory.getPair(_fromToken, pma));
			IUniswapV2Pair pair2 = IUniswapV2Pair(uniswapFactory.getPair(pma, _toToken));

			if (_haveReserve(pair1) && _haveReserve(pair2)) {
				canSWap = true;
				isTwoPaths = true;

				path1 = new address[](2);
				path1[0] = _fromToken;
				path1[1] = pma;

				path2 = new address[](2);
				path2[0] = pma;
				path2[1] = _toToken;
			} else if (!_haveReserve(pair1) && _haveReserve(pair2)) {
				// check path through the WBNB i.e token0 -> WBNB -> PMA
				IUniswapV2Pair pair3 = IUniswapV2Pair(uniswapFactory.getPair(_fromToken, wbnb));
				IUniswapV2Pair pair4 = IUniswapV2Pair(uniswapFactory.getPair(wbnb, _toToken));

				if (_haveReserve(pair3) && _haveReserve(pair4)) {
					canSWap = true;
					isTwoPaths = true;

					path1 = new address[](3);
					path1[0] = _fromToken;
					path1[1] = wbnb;
					path1[2] = pma;

					path2 = new address[](2);
					path2[0] = pma;
					path2[1] = _toToken;
				}
			} else if (_haveReserve(pair1) && !_haveReserve(pair2)) {
				// check path through the WBNB i.e PMA -> WBNB -> token1
				IUniswapV2Pair pair3 = IUniswapV2Pair(uniswapFactory.getPair(pma, wbnb));
				IUniswapV2Pair pair4 = IUniswapV2Pair(uniswapFactory.getPair(wbnb, _toToken));

				if (_haveReserve(pair3) && _haveReserve(pair4)) {
					canSWap = true;
					isTwoPaths = true;

					path1 = new address[](2);
					path1[0] = _fromToken;
					path1[1] = pma;

					path2 = new address[](3);
					path2[0] = pma;
					path2[1] = wbnb;
					path2[2] = _toToken;
				}
			}
		}
		return (canSWap, isTwoPaths, path1, path2);
	}

	/*
   	=======================================================================
   	======================== Internal Methods ===============================
   	=======================================================================
 	*/

	function _execute(
		address settlementToken,
		IBEP20 paymentToken,
		address from,
		address to,
		uint256 amount
	) internal {
		(bool canSwap, bool isTwoPaths, address[] memory path1, address[] memory path2) = canSwapFromV2(
			address(paymentToken),
			settlementToken
		);

		require(canSwap, 'Executor: NO_SWAP_PATH_EXISTS');

		uint256 executionFee;
		uint256[] memory amounts;
		uint256 finalAmount;

		// This flow is executed when neither of the token is PMA token
		if (isTwoPaths) {
			// Case 2: non-PMA token0 ---> non-PMA token1 payment,
			// 1. Get two paths for token conversion i.e non-PMA token0 ---> PMA && PMA ---> non-PMA token1
			// 2. Get required amount of tokens from user
			// 3. Swap token0 tokens to PMA tokens
			// 4. Transfer execution fee in PMA
			// 5. Swap remaining PMA to token1

			uint256[] memory path2Amount = uniswapRouterV2.getAmountsIn(amount, path2);
			uint256[] memory path1Amount = uniswapRouterV2.getAmountsIn(path2Amount[0], path1);

			require(paymentToken.transferFrom(from, address(this), path1Amount[0]));

			// Then we need to approve the payment token to be used by the Router
			paymentToken.approve(address(uniswapRouterV2), path1Amount[0]);

			amounts = uniswapRouterV2.swapExactTokensForTokens(
				path1Amount[0], // amount in
				1, // minimum out
				path1, // swap path i.e non-PMA -> PMA|| mpm-PMA -> WBNB -> PMA
				address(this), // token receiver
				block.timestamp + deadline
			);

			// get execution fees in PMA
			executionFee = _transferExecutionFee(IBEP20(address(PMAToken)), amounts[amounts.length - 1]);

			finalAmount = amounts[amounts.length - 1] - executionFee;

			// Then we need to approve the payment token to be used by the Router
			paymentToken.approve(address(uniswapRouterV2), finalAmount);

			uniswapRouterV2.swapExactTokensForTokens(
				finalAmount, // amount in
				1, // minimum out
				path2, // swap path i.e non-PMA -> PMA|| mpm-PMA -> WBNB -> PMA
				to, // token receiver
				block.timestamp + deadline
			);
		} else {
			// CASE 3: PMA -> non-PMA or non-PMA -> PMA
			// 1. Get required amount of tokens from user
			// 2. There are two cases
			//  	a. payment token is PMA token
			//			i. Transfer execution fee in PMA
			//		 ii. Swap remaining PMA tokens to non-PMA tokens and transfer to merchant
			//		b. settlement token is PMA token
			//			i. Swap non-PMA tokens to PMA tokens
			//		 ii. Transfer execution fee in PMA
			//		iii. Transfer remaining PMA tokens to merchant

			uint256[] memory amountInMax = uniswapRouterV2.getAmountsIn(amount, path1);

			require(paymentToken.transferFrom(from, address(this), amountInMax[0]));

			// transfer execution fee
			if (address(paymentToken) == address(PMAToken)) {
				// get execution fees in PMA
				executionFee = _transferExecutionFee(paymentToken, amountInMax[0]);
				finalAmount = amountInMax[0] - executionFee;

				// Then we need to approve the payment token to be used by the Router
				paymentToken.approve(address(uniswapRouterV2), finalAmount);

				uniswapRouterV2.swapExactTokensForTokens(
					finalAmount, // amount in
					1, // minimum out
					path1, // swap path i.e PMA->non-PMA || PMA -> WBNB -> non-PMA
					to, // token receiver
					block.timestamp + deadline
				);
			} else if (settlementToken == address(PMAToken)) {
				// Then we need to approve the payment token to be used by the Router
				paymentToken.approve(address(uniswapRouterV2), amountInMax[0]);

				amounts = uniswapRouterV2.swapExactTokensForTokens(
					amountInMax[0], // amount in
					1, // minimum out
					path1, // swap path i.e non-PMA -> PMA || non-PMA -> WBNB -> PMA
					address(this), // token receiver
					block.timestamp + deadline
				);

				// get execution fees in PMA
				executionFee = _transferExecutionFee(IBEP20(settlementToken), amounts[amounts.length - 1]);

				require(
					paymentToken.transfer(to, amounts[amounts.length - 1] - executionFee),
					'Executor: TRANSFER_FAILED'
				);
			}
		}
	}

	/**
	 * @notice This method calculates the execution fee and transfers it to the executionFee receiver
	 * @param _paymentToken 	- payment token address
	 * @param _amount					- amount of payment tokens
	 */
	function _transferExecutionFee(IBEP20 _paymentToken, uint256 _amount)
		internal
		virtual
		returns (uint256 executionFee)
	{
		require(address(_paymentToken) == address(PMAToken), 'Executor: INVALID_FEE_TOKEN');
		// calculate exection fee
		executionFee = (_amount * registry.executionFee()) / 10000;

		// transfer execution Fee in PMA to executionFee receiver
		if (executionFee > 0) {
			require(
				_paymentToken.transfer(registry.executionFeeReceiver(), executionFee),
				'Executor: TRANSFER_FAILED'
			);
		}

		uint256 upKeepId = pullPaymentRegistry.upkeepIds(msg.sender);

		require(upKeepId > 0, 'EXECUTOR:INVALID_UPKEEP_ID');

		ITokenConverter(registry.getTokenConverter()).topupUpkeep(upKeepId);
	}

	/**
	 * @notice checks if the UNI v2 contract have reserves to swap tokens
	 * @param pair 	- pair contract address ex. PMA-WBNB Pair
	 */
	function _haveReserve(IUniswapV2Pair pair) internal view returns (bool hasReserve) {
		if (address(pair) != address(0)) {
			(uint256 res0, uint256 res1, ) = pair.getReserves();
			if (res0 > 0 && res1 > 0) {
				return true;
			}
		}
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		virtual
		override
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0, 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPayment {
	struct BillingModelData {
		address payee;
		string name;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256 amount;
		address settlementToken;
		uint256 frequency;
		uint256 numberOfPayments;
		uint256[] subscriptionIDs;
		uint256 creationTime;
	}

	struct SwappableBillingModel {
		address payee;
		string name;
		string merchantName;
		string uniqueReference;
		string merchantURL;
		uint256 settlementAmount;
		address settlementToken;
		uint256 paymentAmount;
		address paymentToken;
		uint256 frequency;
		uint256 numberOfPayments;
		uint256 creationTime;
	}
	struct SubscriptionData {
		address subscriber;
		uint256 amount;
		address settlementToken;
		address paymentToken;
		uint256 numberOfPayments;
		uint256 startTimestamp;
		uint256 cancelTimestamp;
		uint256 nextPaymentTimestamp;
		uint256 lastPaymentTimestamp;
		uint256[] pullPaymentIDs;
		uint256 billingModelID;
		string uniqueReference;
		address cancelledBy;
	}

	function createBillingModel(
		address _payee,
		string memory _name,
		string memory _merchantName,
		string memory _reference,
		string memory _merchantURL,
		uint256 _amount,
		address _token,
		uint256 _frequency,
		uint256 _numberOfPayments
	) external returns (uint256 billingModelID);

	function subscribeToBillingModel(
		uint256 _billingModelID,
		address _paymentToken,
		string memory _reference
	) external returns (uint256 subscriptionID);

	function executePullPayment(uint256 _subscriptionID) external returns (uint256);

	function cancelSubscription(uint256 _subscriptionID) external returns (uint256);

	function editBillingModel(
		uint256 _billingModelID,
		address _newPayee,
		string memory _newName,
		string memory _newMerchantName,
		string memory _newMerchantURL
	) external returns (uint256);

	function getBillingModel(uint256 _billingModelID) external view returns (BillingModelData memory);

	function getSubscription(uint256 _subscriptionID) external view returns (SubscriptionData memory);

	function getBillingModel(uint256 _billingModelID, address _token)
		external
		view
		returns (SwappableBillingModel memory bm);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
	function removeLiquidityETHSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountETH);

	function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountETH);

	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;

	function swapExactETHForTokensSupportingFeeOnTransferTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable;

	function swapExactTokensForETHSupportingFeeOnTransferTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenConverter {
	function isLowBalance(uint256 _upkeepId) external view returns (bool isLow);

	function topupUpkeep(uint256 _upkeepId) external returns (bool topupPerform);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICoreRegistry.sol';
import './IPullPaymentConfig.sol';

interface IRegistry is ICoreRegistry, IPullPaymentConfig {
	function getPMAToken() external view returns (address);

	function getWBNBToken() external view returns (address);

	function getFreezer() external view returns (address);

	function getExecutor() external view returns (address);

	function getUniswapFactory() external view returns (address);

	function getUniswapPair() external view returns (address);

	function getUniswapRouter() external view returns (address);

	function getPullPaymentRegistry() external view returns (address);

	function getKeeperRegistry() external view returns (address);

	function getTokenConverter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentRegistry {
	function grantExecutor(address _executor) external;

	function revokeExecutor(address _executor) external;

	function addPullPaymentContract(string calldata _identifier, address _addr) external;

	function getPPAddressForOrDie(bytes32 _identifierHash) external view returns (address);

	function getPPAddressFor(bytes32 _identifierHash) external view returns (address);

	function getPPAddressForStringOrDie(string calldata _identifier) external view returns (address);

	function getPPAddressForString(string calldata _identifier) external view returns (address);

	function isExecutorGranted(address _executor) external view returns (bool);

	function BATCH_SIZE() external view returns (uint256);

	function setUpkeepId(address upkeepAddress, uint256 upkeepId) external;

	function upkeepIds(address upkeepAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPullPaymentConfig {
	function getSupportedTokens() external view returns (address[] memory);

	function isSupportedToken(address _tokenAddress) external view returns (bool isExists);

	function executionFeeReceiver() external view returns (address);

	function executionFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutor {
	function execute(
		address,
		address,
		address,
		address,
		uint256
	) external returns (bool);

	function execute(string calldata _bmType, uint256 _subscriptionId) external returns (uint256);
	//    function executePullPayment(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoreRegistry {
	function setAddressFor(string calldata, address) external;

	function getAddressForOrDie(bytes32) external view returns (address);

	function getAddressFor(bytes32) external view returns (address);

	function isOneOf(bytes32[] calldata, address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
	/**
	 * @dev Returns the amount of tokens in existence.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token decimals.
	 */
	function decimals() external view returns (uint8);

	/**
	 * @dev Returns the token symbol.
	 */
	function symbol() external view returns (string memory);

	/**
	 * @dev Returns the token name.
	 */
	function name() external view returns (string memory);

	/**
	 * @dev Returns the bep token owner.
	 */
	function getOwner() external view returns (address);

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
	function allowance(address _owner, address spender) external view returns (uint256);

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
	function transferFrom(
		address sender,
		address recipient,
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

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IRegistry.sol';

/**
 * @title RegistryHelper - initializer for core registry
 * @author The Pumapay Team
 * @notice This contract helps to initialize the core registry contract in parent contracts.
 */
contract RegistryHelper is Ownable {
	/*
   	=======================================================================
   	======================== Public variatibles ===========================
   	=======================================================================
 	*/
	/// @notice The core registry contract
	IRegistry public registry;

	/*
   	=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 * @dev initializes the core registry with registry address
	 */
	constructor(address _registryAddress) {
		setRegistry(_registryAddress);
	}

	/*
   	=======================================================================
   	======================== Events =======================================
 	=======================================================================
 	*/
	event RegistrySet(address indexed registryAddress);

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice Updates the address pointing to a Registry contract.
	 * @dev only owner can set the registry address.
	 * @param registryAddress - The address of a registry contract for routing to other contracts.
	 */
	function setRegistry(address registryAddress) public virtual onlyOwner {
		require(registryAddress != address(0), 'RegistryHelper: CANNOT_REGISTER_ZERO_ADDRESS');
		registry = IRegistry(registryAddress);
		emit RegistrySet(registryAddress);
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