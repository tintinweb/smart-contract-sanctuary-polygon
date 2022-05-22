/**
 *Submitted for verification at polygonscan.com on 2022-05-21
*/

// SPDX-License-Identifier: Apache License 2.0
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/******************************************************************************
* File:     ICommonStructs.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: IERC20.sol
* License:  Apache 2.0
******************************************************************************/

/// @title Common data structures for the SW DAO Balancer pool
/// @author Peter T. Flynn
/// @notice Maintains a common interface between [CustomBalancerPool], and [ExtraStorage]
interface ICommonStructs {
	// Enumerates the different categories which pool-managed tokens can be assigned to:
	// NULL) Reserved as the default state, which indicates that the token is un-managed.
	// PRODUCT) Indicates that the token is an SW DAO product.
	// COMMON) Indicates that the token is "common", such as WETH, WMATIC, LINK, etc., but that it
	//		   is not USD-related like USDC, USDT, etc.
	// USD) Indicates that the token is related national currencies, such as USDC, USDT, etc.
	// BASE) Indicates that the token is either the BPT, or SWD. Other tokens are not assignable to
	//		 this category, and the tokens of this category cannot be re-weighted, or removed.
	// These categories are more useful as "guidelines" than hard-and-fast separations, and they
	// exist for the benefit of the pool's manager.
	// Since the three, primary categories appear in binary as 0001, 0010, and 0011, we can use a
	// binary trick to detect valid categories. [TokenCategory & 0x3 == 0] only returns true
	// for [NULL], and [BASE], as [NULL] is 0000, [BASE] is 0100, and [0x3] is 0011.
	enum TokenCategory{ NULL, PRODUCT, COMMON, USD, BASE }

	// Saves gas by packing small, often-used variables into a single 32-byte slot
	struct Slot6 {
		// The contract's owner
		address owner;
		// The number of tokens managed by the pool, including the BPT, and SWD
		uint8 tokensLength;
		// The current, flat fee used to maintain the token balances according to the configured
		// weights, expressed in tenths of a percent (ex. 10 = 1%). Can also be set to
		// 255 (type(uint8).max) to indicate that the "swap lock" is engaged, in which case the
		// balance fee can be found in [balanceFeeCache].
		uint8 balanceFee;
		// The weights of the three, primary categories
		// (DAO Products, Common Tokens, and USD-related tokens) relative to one another
		// (ex. [1, 1, 1] would grant 1/3 of the pool to each category).
		// See [enum TokenCategory] above for details on categories.
		// Stored as bytes3, but utilized as if it were uint8[3], in order to pack tightly.
		bytes3 categoryWeights;
		// The sum of all [categoryWeights]
		uint8 categoryWeightsTotal;
		// The sum of all individual, token wights within a given category.
		// Stored as bytes6, but utilized as if it were uint16[3], in order to pack tightly.
		// Helper functions bytes6ToUint16Arr(), and uint16ArrToBytes6() exist within
		// [ExtraStorage] to help with conversion.
		bytes6 inCategoryTotals;
	}

	// Used by various functions to store information about token pricing
	struct TokenValuation {
		// The price of the token in USD, with 18-decimals of precision
		uint price;
		// The total USD value of all such tokens managed by the pool
		uint total;
	}

	// Useful only for avoiding "stack too deep" errors
	struct GetValue {
		uint totalMinusSWD;
		uint bpt;
		TokenValuation indexIn;
		TokenValuation indexOut;
	}

	// Contains data about a "tier" of pricing, usually contained in a fixed-size array of length 3.
	// Each tier represents a balance state, as described in ExtraStorage.onSwapGetComplexPricing().
	// A [price] of 0, combined with an [amount] of 0 indicates that no such tier is reachable;
	// as, depending on the type of trade, the trade may only reach one, or two tiers.
	struct ComplexPricing {
		// The price per token, offered within this tier
		uint price;
		// The amount of tokens available within this tier, where 0 represents infinity
		uint amount;
	}

	// Utilized in an [IERC20 => TokenInfo] mapping for quickly retrieving category, and weight
	// information about a given token
	struct TokenInfo {
		TokenCategory category;
		uint8 inCategoryWeight;
	}

	// Useful only for avoiding "stack too deep" errors
	struct TokenData {
		uint indexIn;
		uint indexOut;
		TokenInfo inInfo;
		TokenInfo outInfo;
	}

	// Useful for passing pricing data between the various onSwap() child functions
	struct IndexPricing {
		ComplexPricing[3] indexIn;
		ComplexPricing[3] indexOut;
	}
}

/*****************************************************************************/




/******************************************************************************
* File:     ExtraStorage.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: ERC20.sol, ITokenPriceControllerDefault.sol, ITokenPriceManagerMinimal.sol,
*           IPoolSwapStructs.sol, IVault.sol, BalancerErrors.sol, ICommonStructs.sol
* License:  Apache 2.0
******************************************************************************/

/// @title Extra Storage for the SW DAO Balancer pool
/// @author Peter T. Flynn
/// @notice Useful for staying within the EVM's limit for contract bytecode
/// @dev Later versions of the [CustomBalancerPool] contract should do away with this library in
/// favor of having each function stored in their own contracts, with a local singleton for onSwap.
/// This current library-based implementation is not gas-efficient, and was done as a concession
/// for the time-sensitive nature of this project.
library ExtraStorage {
	ITokenPriceControllerDefault constant ORACLE =
		ITokenPriceControllerDefault(0x8A46Eb6d66100138A5111b803189B770F5E5dF9a);

	// Always known, set at the first run of initialize()
	uint constant INDEX_BPT = 0;
	// Always known, set at the first run of initialize()
	uint constant INDEX_SWD = 1;
	// Named for readability
	uint8 constant UINT8_MAX = type(uint8).max;
	// Useful in common, fixed-point math - named for readability
	uint constant EIGHTEEN_DECIMALS = 1e18;
	// Sets a hard cap on the number of tokens that the pool may manage.
	// Attempting to add more reverts with [Errors.MAX_TOKENS] (BAL#201).
	uint8 constant MAX_TOKENS = 50;

	// Must be incremented whenever a new library implementation is deployed
	uint16 constant CONTRACT_VERSION = 100; // Version 1.00;

	/// @notice Emitted when tokens are added to the pool
	/// @param sender The transactor
	/// @param token The token added
	/// @param category The token's category
	/// @param weight The token's weight within that category
	event TokenAdd(
		address indexed sender,
		address indexed token,
		ICommonStructs.TokenCategory indexed category,
		uint8 weight
	);

	// Adds tokens to be managed by the pool
	// Checks that each token:
	// 1) Doesn't already exist in the pool
	// 2) Doesn't put the pool over the [MAX_TOKENS] limit
	// 3) Has a price provider in [ORACLE]
	// 4) Is being added to a valid category
	function tokensAddIterate(
		ICommonStructs.Slot6 memory _slot6,
		mapping(IERC20 => ICommonStructs.TokenInfo) storage tokens,
		IERC20[] calldata _tokens,
		ICommonStructs.TokenCategory[] calldata categories,
		uint8[] calldata weights
	) public returns (ICommonStructs.Slot6 memory) {
		onlyOwner(_slot6.owner);
		_require(
			_slot6.tokensLength + _tokens.length <= MAX_TOKENS,
			Errors.MAX_TOKENS
		);
		_require(
			_tokens.length == categories.length &&
			_tokens.length == weights.length,
			Errors.INPUT_LENGTH_MISMATCH
		);
		uint16[3] memory categoryWeights;
		for (uint i; i < _tokens.length; i++) {
			_require(
				tokens[_tokens[i]].category == ICommonStructs.TokenCategory.NULL,
				Errors.TOKEN_ALREADY_REGISTERED
			);
			_require(isContract(_tokens[i]), Errors.INVALID_TOKEN);
			address oracleReportedAddress = ORACLE
				.getManager(
					ERC20(address(_tokens[i])).symbol()
				).getTokenPrimary();
			_require(
				address(_tokens[i]) == oracleReportedAddress,
				Errors.TOKEN_DOES_NOT_HAVE_RATE_PROVIDER
			);
			getValue(
				_tokens[i],
				ITokenPriceManagerMinimal.PriceType.RAW
			);
			uint8 category = uint8(categories[i]);
			// The [category & 0x3 != 0] below detects that the token is both added,
			// and not in the [TokenCategory.BASE] category, using a binary trick
			_require(category & 0x3 != 0, Errors.INVALID_TOKEN);
			categoryWeights[category - 1] += weights[i];
			tokens[_tokens[i]] = ICommonStructs.TokenInfo(categories[i], weights[i]);
			emit TokenAdd(_slot6.owner, address(_tokens[i]), categories[i], weights[i]);
		}
		uint16[3] memory _inCategoryTotals =
			bytes6ToUint16Arr(_slot6.inCategoryTotals);
		for (uint i; i < categoryWeights.length; i++)
			_inCategoryTotals[i] += categoryWeights[i];
		_slot6.inCategoryTotals = uint16ArrToBytes6(_inCategoryTotals);
		_slot6.tokensLength += uint8(_tokens.length);
		return _slot6;
	}

	// Sets the weights for the three, primary categories, as explained above the parent function
	function setCategoryWeightsIterate(
		ICommonStructs.Slot6 memory _slot6,
		uint8[3] calldata weights
	) public view returns (ICommonStructs.Slot6 memory) {
		onlyOwner(_slot6.owner);
		uint16 total = uint16(weights[0]) + uint16(weights[1]) + uint16(weights[2]);
		_slot6.categoryWeights = bytes3(
			bytes1(weights[0]) |
			bytes2(bytes1(weights[1])) >> 8 |
			bytes3(bytes1(weights[2])) >> 16
		);
		_require(total <= UINT8_MAX, Errors.ADD_OVERFLOW);
		_slot6.categoryWeightsTotal = uint8(total);
		return _slot6;
	}

	// Sets the weights of the requested tokens, as explained above the parent function.
	// Checks that each token:
	// 1) Exists in the pool
	// 2) Is in a category where weight changes are allowed
	function setTokenWeightsIterate(
		ICommonStructs.Slot6 memory _slot6,
		IERC20[] calldata _tokens,
		uint8[] calldata weights,
		mapping(IERC20 => ICommonStructs.TokenInfo) storage tokens
	) public returns (ICommonStructs.Slot6 memory) {
		onlyOwner(_slot6.owner);
		for (uint i; i < _tokens.length; i++) {
			ICommonStructs.TokenInfo memory tokenInfo = tokens[_tokens[i]];
			uint8 categoryIndex = uint8(tokenInfo.category) - 1;
			// The [uint8(tokenInfo.category) & 0x3 != 0] below detects that the token is both
			// added, and not in the [TokenCategory.BASE] category, using a binary trick
			_require(uint8(tokenInfo.category) & 0x3 != 0, Errors.INVALID_TOKEN);
			uint16[3] memory _inCategoryTotals =
				bytes6ToUint16Arr(_slot6.inCategoryTotals);
			_inCategoryTotals[categoryIndex] = 
				_inCategoryTotals[categoryIndex] - tokenInfo.inCategoryWeight + weights[i];
			_slot6.inCategoryTotals = uint16ArrToBytes6(_inCategoryTotals);
			tokenInfo.inCategoryWeight = weights[i];
			tokens[_tokens[i]] = tokenInfo;
		}
		return _slot6;
	}

	// Checks to ensure that the pool can be unlocked, as explained above the parent function
	function toggleSwapLockCheckState(
		IERC20[] calldata _tokens,
		uint[] calldata balances,
		mapping(IERC20 => ICommonStructs.TokenInfo) storage tokens,
		uint totalSupply,
		uint dueProtocolFees
	) public view {
		_require(
			(totalSupply - balances[INDEX_BPT] + dueProtocolFees) > 0,
			Errors.UNINITIALIZED
		);
		_require(_tokens.length > 2, Errors.UNINITIALIZED);
		bool someBalance;
		for (uint i; i < _tokens.length; i++) {
			if (i == INDEX_BPT)
				continue;
			ICommonStructs.TokenInfo memory tokenInfo = tokens[_tokens[i]];
			if (tokenInfo.inCategoryWeight > 0 && balances[i] > 0) {
				if (i != INDEX_SWD)
					someBalance = true;
			} else if (i == INDEX_SWD) {
				_revert(Errors.UNINITIALIZED);
			}
		}
		_require(someBalance, Errors.UNINITIALIZED);
	}

	// Returns token amounts in proportion to the total BPT in circulation, as explained above the
	// parent function
	function onExitPoolAmountsOut(
		uint[] calldata balances,
		uint bptSupply,
		uint bptAmountIn
	) public pure returns (uint[] memory amountsOut) {
		amountsOut = new uint[](balances.length);
		if (bptAmountIn == 0)
			return amountsOut;
		for (uint i = 1; i < balances.length; i++) {
			if	(balances[i] == 0)
				continue;
			amountsOut[i] = safeMul(
				balances[i],
				bptAmountIn
			) / bptSupply;
		}
	}

	// Gathers pricing information for the case in which the user is trading either the BPT, or SWD
	// for some other token. See [ICommonStructs.sol -> struct ComplexPricing] for details.
	// Implements a constant-product pricing style for SWD.
	function onSwapGetIndexInPricing(
		IPoolSwapStructs.SwapRequest calldata swapRequest,
		uint[] calldata balances,
		ICommonStructs.GetValue calldata _getValue,
		ICommonStructs.TokenData calldata _tokenData
	) public pure returns (ICommonStructs.ComplexPricing[3] memory indexInPricing) {
		if (_tokenData.indexIn == INDEX_BPT) {
			indexInPricing[0].price = _getValue.bpt;
		} else if (_tokenData.indexIn == INDEX_SWD) {
			if (swapRequest.kind == IVault.SwapKind.GIVEN_IN) {
				uint workingValue = safeMul(
					_getValue.totalMinusSWD,
					swapRequest.amount
				) / (balances[INDEX_SWD] + swapRequest.amount);
				indexInPricing[0].price = safeMul(
					workingValue,
					EIGHTEEN_DECIMALS
				) / swapRequest.amount;
			} else {
				uint buyValue = safeMul(
					_getValue.indexOut.price,
					swapRequest.amount
				) / EIGHTEEN_DECIMALS;
				uint workingValue = safeMul(
					balances[INDEX_SWD],
					buyValue
				) / (_getValue.totalMinusSWD - buyValue);
				indexInPricing[0].price = safeMul(
					buyValue,
					EIGHTEEN_DECIMALS
				) / workingValue;
			}
		}
	}

	// Gathers pricing information for the case in which the user is trading some token for either
	// the BPT, or SWD. See [ICommonStructs.sol -> struct ComplexPricing] for details.
	// Implements a constant-product pricing style for SWD.
	function onSwapGetIndexOutPricing(
		IPoolSwapStructs.SwapRequest calldata swapRequest,
		uint[] calldata balances,
		ICommonStructs.GetValue calldata _getValue,
		ICommonStructs.TokenData calldata _tokenData
	) public pure returns (ICommonStructs.ComplexPricing[3] memory indexOutPricing) {
		if (_tokenData.indexOut == INDEX_BPT) {
			indexOutPricing[0].price = _getValue.bpt;
		} else if (_tokenData.indexOut == INDEX_SWD) {
			if (swapRequest.kind == IVault.SwapKind.GIVEN_IN) {
				uint workingValue = (_tokenData.indexIn == INDEX_BPT) ?
					_getValue.bpt :
					_getValue.indexIn.price;
				uint buyValue = safeMul(
					workingValue,
					swapRequest.amount
				) / EIGHTEEN_DECIMALS;
				workingValue = safeMul(
					balances[INDEX_SWD],
					buyValue
				) / (_getValue.totalMinusSWD + buyValue);
				indexOutPricing[0].price = safeMul(
					buyValue,
					EIGHTEEN_DECIMALS
				) / workingValue;
			} else {
				uint workingValue = safeMul(
					_getValue.totalMinusSWD,
					swapRequest.amount
				) / (balances[INDEX_SWD] - swapRequest.amount);
				indexOutPricing[0].price = safeMul(
					workingValue,
					EIGHTEEN_DECIMALS
				) / swapRequest.amount;
			}
		}
	}

	// Gathers pricing information for the case in which the user is trading a token besides the
	// BPT, or SWD (irrespective of whether BPT/SWD is on the opposite side of the trade).
	// Pricing is handled in three tiers according to its balance within the pool:
	// 1) The token is below its configured weight (incentive for user to buy).
	// 2) The token is above its configured weight (incentive for user to sell).
	// 3) The token is within 2% of its configured weight (no incentive).
	// A user may pass through multiple tiers during a single trade.
	// See [ICommonStructs.sol -> struct ComplexPricing] for further details.
	function onSwapGetComplexPricing(
		uint totalMinusSWDValue,
		IERC20 token,
		ICommonStructs.TokenInfo calldata tokenInfo,
		ICommonStructs.TokenValuation memory tokenValue,
		ICommonStructs.Slot6 calldata _slot6,
		bool buySell
	) public view returns (ICommonStructs.ComplexPricing[3] memory pricing) {
		uint16[3] memory inCategoryTotals = bytes6ToUint16Arr(_slot6.inCategoryTotals);
		uint totalTarget = safeMul(
			(	safeMul(
					totalMinusSWDValue,
					uint8(_slot6.categoryWeights[uint8(tokenInfo.category) - 1])
				) / _slot6.categoryWeightsTotal
			),
			tokenInfo.inCategoryWeight
		) / inCategoryTotals[uint8(tokenInfo.category) - 1];
		uint totalMargin = (safeMul(totalTarget, 51) / 50) - totalTarget;
		if (tokenValue.total == 0) tokenValue.total++;
		for (uint i; tokenValue.total > 0; i++) {
			if (tokenValue.total > totalTarget + totalMargin) {
				if (buySell) {
					pricing[i].price = safeMul(
						getValue(
							token,
							ITokenPriceManagerMinimal.PriceType.SELL
						),
						1000 - _slot6.balanceFee
					) / 1000;
					tokenValue.total = 0;
				} else {
					pricing[i].price = safeMul(
						tokenValue.price,
						1000 - _slot6.balanceFee
					) / 1000;
					pricing[i].amount = safeMul(
						tokenValue.total - totalTarget - totalMargin,
						EIGHTEEN_DECIMALS
					) / tokenValue.price;
					tokenValue.total = totalTarget + totalMargin;
				}
			} else if (tokenValue.total < totalTarget - totalMargin) {
				if (buySell) {
					pricing[i].price = safeMul(
						tokenValue.price,
						1000 + _slot6.balanceFee
					) / 1000;
					pricing[i].amount = safeMul(
						totalTarget - totalMargin - tokenValue.total,
						EIGHTEEN_DECIMALS
					) / tokenValue.price;
					tokenValue.total = totalTarget - totalMargin;
				} else {
					pricing[i].price = safeMul(
						getValue(
							token,
							ITokenPriceManagerMinimal.PriceType.BUY
						),
						1000 + _slot6.balanceFee
					) / 1000;
					tokenValue.total = 0;
				}
			} else {
				if (buySell) {
					pricing[i].price = getValue(
						token,
						ITokenPriceManagerMinimal.PriceType.SELL
					);
					pricing[i].amount = safeMul(
						totalTarget + totalMargin - tokenValue.total + 1,
						EIGHTEEN_DECIMALS
					) / tokenValue.price;
					tokenValue.total = totalTarget + totalMargin + 1;
				} else {
					pricing[i].price = getValue(
						token,
						ITokenPriceManagerMinimal.PriceType.BUY
					);
					pricing[i].amount = safeMul(
						tokenValue.total - totalTarget + totalMargin - 1,
						EIGHTEEN_DECIMALS
					) / tokenValue.price;
					tokenValue.total = totalTarget - totalMargin - 1;
				}
			}
		}
	}

	// Utilized in onSwapGetAmount() to convert two sets of [ComplexPricing] data into an
	// [outAmount] that onSwapGetAmount() can further process.
	// See [ICommonStructs.sol -> struct ComplexPricing] for further details.
	function onSwapCalculateTrade(
		ICommonStructs.ComplexPricing[3] calldata inPricing,
		ICommonStructs.ComplexPricing[3] calldata outPricing,
		uint inAmount
	) public pure returns (uint outAmount) {
		uint inValueTotal;
		for (uint i; inAmount > 0; i++) {
			if (inAmount < inPricing[i].amount || inPricing[i].amount == 0) {
				inValueTotal += safeMul(
					inAmount,
					inPricing[i].price
				) / EIGHTEEN_DECIMALS;
				inAmount = 0;
			} else {
				inValueTotal += safeMul(
					inPricing[i].amount,
					inPricing[i].price
				) / EIGHTEEN_DECIMALS;
				inAmount -= inPricing[i].amount;
			} 
		}
		for (uint i; inValueTotal > 0; i++) {
			uint stepTotal = (outPricing[i].amount == 0) ?
				0 :
				safeMul(
					outPricing[i].amount,
					outPricing[i].price
				) / EIGHTEEN_DECIMALS;
			if (inValueTotal < stepTotal || outPricing[i].amount == 0) {
				outAmount += safeMul(
					inValueTotal,
					EIGHTEEN_DECIMALS
				) / outPricing[i].price;
				inValueTotal = 0;
			} else {
				inValueTotal -= stepTotal;
				outAmount += outPricing[i].amount;
			}
		}
	}

	// Constructs a final amount for onSwap() to return to the [VAULT], utilizing
	// onSwapCalculateTrade() above. Checks to ensure the pool has enough balance in the requested
	// token to settle the trade. Handles the differences between Balancer's
	// [IVault.SwapKind.GIVEN_IN] versus [IVault.SwapKind.GIVEN_OUT].
	function onSwapGetAmount(
		IPoolSwapStructs.SwapRequest calldata swapRequest,
		uint[] calldata balances,
		ICommonStructs.TokenData calldata _tokenData,
		ICommonStructs.IndexPricing calldata _pricing
	) public view returns (uint amount) {
		if (swapRequest.kind == IVault.SwapKind.GIVEN_IN) {
			amount = onSwapCalculateTrade(
				_pricing.indexIn,
				_pricing.indexOut,
				safeMul(
					swapRequest.amount, 
					10 ** (18 - ERC20(address(swapRequest.tokenIn)).decimals())
				)
			) / 10 ** (18 - ERC20(address(swapRequest.tokenOut)).decimals());
			if (amount > balances[_tokenData.indexOut])
				amount = balances[_tokenData.indexOut];
		} else {
			_require(
				swapRequest.amount <= balances[_tokenData.indexOut],
				Errors.INSUFFICIENT_BALANCE
			);
			amount = onSwapCalculateTrade(
				_pricing.indexOut,
				_pricing.indexIn,
				safeMul(
					swapRequest.amount, 
					10 ** (18 - ERC20(address(swapRequest.tokenOut)).decimals())
				)
			) / 10 ** (18 - ERC20(address(swapRequest.tokenIn)).decimals());
		}
	}

	// Constructs a hypothetical, feeless transaction to which the amount returned by
	// onSwapGetAmount() is compared. If the feeless transaction results in a better trade for the
	// user, the difference between the two amounts is taken, and that difference is used to
	// calculate the "swap fee". That "swap fee" allows us to calculate fees due to the Balancer
	// protocol, according to Balancer governance' requested fee percent. Fees are paid in the BPT.
	// Note: trades that involve the BPT are excluded from fee calculations (sorry Balancer), this	
	// is due to the fact that this contract currently can't deal with negative fees. This may
	// change in future versions.
	function onSwapCalculateFees(
		IPoolSwapStructs.SwapRequest calldata swapRequest,
		ICommonStructs.GetValue memory _getValue,
		ICommonStructs.TokenData calldata _tokenData,
		ICommonStructs.IndexPricing calldata _pricing,
		uint amount,
		uint cachedProtocolSwapFeePercentage
	) public view returns (uint) {
		if (
			!(
				_tokenData.indexIn == INDEX_BPT ||
				_tokenData.indexOut == INDEX_BPT
			)
		) {
			if (_tokenData.indexIn == INDEX_SWD)
				_getValue.indexIn.price = _pricing.indexIn[0].price;
			if (_tokenData.indexOut == INDEX_SWD)
				_getValue.indexOut.price = _pricing.indexOut[0].price;
			if (swapRequest.kind == IVault.SwapKind.GIVEN_IN) {
				uint rawAmount = safeMul(
					_getValue.indexIn.price,
					safeMul(
						swapRequest.amount,
						10 ** (18 - ERC20(address(swapRequest.tokenIn)).decimals())
					)
				) / _getValue.indexOut.price;
				amount = safeMul(
					amount,
					10 ** (18 - ERC20(address(swapRequest.tokenOut)).decimals())
				);
				if (rawAmount > amount) {
					return safeMul(
						(	safeMul(
								rawAmount - amount,
								_getValue.indexOut.price
							) / EIGHTEEN_DECIMALS
						),
						cachedProtocolSwapFeePercentage
					) / (_getValue.bpt * 100);
				}
			} else {
				uint rawAmount = safeMul(
					_getValue.indexOut.price,
					safeMul(
						swapRequest.amount,
						10 ** (18 - ERC20(address(swapRequest.tokenOut)).decimals())
					)
				) / _getValue.indexIn.price;
				amount = safeMul(
					amount,
					10 ** (18 - ERC20(address(swapRequest.tokenIn)).decimals())
				);
				if (rawAmount < amount) {
					return safeMul(
						(	safeMul(
								amount - rawAmount,
								_getValue.indexIn.price
							) / EIGHTEEN_DECIMALS
						),
						cachedProtocolSwapFeePercentage
					) / (_getValue.bpt * 100);
				}
			}
		}
		return 0;
	}

	// Gets the price of a token, with the requested [ITokenPriceManagerMinimal.PriceType],
	// from the [ORACLE] (in USD, with 18-decimals of precision)
	function getValue(
		IERC20 token,
		ITokenPriceManagerMinimal.PriceType priceType
	) public view returns (uint usdValue) {
		address denominator;
		(usdValue, denominator) = ORACLE
			.getManager(
				ERC20(address(token)).symbol()
			).getPrice(priceType);
		if (denominator != address(0))
			usdValue = ExtraStorage.safeMul(
				usdValue,
				getValue(IERC20(denominator), ITokenPriceManagerMinimal.PriceType.RAW)
			) / EIGHTEEN_DECIMALS;
		_require(usdValue != 0, Errors.TOKEN_DOES_NOT_HAVE_RATE_PROVIDER);
	}

	// Given an [indexIn]/[indexOut], among other information, this function returns returns five
	// points of data:
	// 1) The total USD value of all assets managed by the pool, excluding the BPT, and SWD.
	// 2) The price of an [indexIn] token in USD.
	// 3) The USD value of all [indexIn] tokens managed by the pool.
	// 2) The price of an [indexOut] token in USD.
	// 3) The USD value of all [indexOut] tokens managed by the pool.
	function getValue(
		IERC20[] calldata _tokens,
		uint[] calldata balances,
		uint indexIn,
		uint indexOut,
		uint totalSupply,
		uint dueProtocolFees
	) public view returns (
		uint totalMinusSWDValue,
		ICommonStructs.TokenValuation memory indexInValue,
		ICommonStructs.TokenValuation memory indexOutValue
	) {
		_require(
			_tokens.length == balances.length,
			Errors.INPUT_LENGTH_MISMATCH
		);
		for (uint i; i < _tokens.length; i++) {
			if (i == INDEX_BPT || i == INDEX_SWD)
				continue;
			uint value = getValue(_tokens[i], ITokenPriceManagerMinimal.PriceType.RAW);
			uint totalValue = ExtraStorage.safeMul(value, balances[i]) /
				(10 ** ERC20(address(_tokens[i])).decimals());
			totalMinusSWDValue += totalValue;
			if (i == indexIn) {
				indexInValue.total = totalValue;
				indexInValue.price = value;
			} else if (i == indexOut) {
				indexOutValue.total = totalValue;
				indexOutValue.price = value;
			}
		}
		if (indexIn == INDEX_BPT) {
			indexInValue.total = totalMinusSWDValue;
			indexInValue.price = ExtraStorage.safeMul(
				indexInValue.total,
				EIGHTEEN_DECIMALS
			) / (totalSupply - balances[INDEX_BPT] + dueProtocolFees);
		} else if (indexIn == INDEX_SWD) {
			indexInValue.total = totalMinusSWDValue;
			indexInValue.price = ExtraStorage.safeMul(
				indexInValue.total,
				EIGHTEEN_DECIMALS
			) / balances[INDEX_SWD];
		}
		if (indexOut == INDEX_BPT) {
			indexOutValue.total = totalMinusSWDValue;
			indexOutValue.price = ExtraStorage.safeMul(
				indexOutValue.total,
				EIGHTEEN_DECIMALS
			) / (totalSupply - balances[INDEX_BPT] + dueProtocolFees);
		} else if (indexOut == INDEX_SWD) {
			indexOutValue.total = totalMinusSWDValue;
			indexOutValue.price = ExtraStorage.safeMul(
				indexOutValue.total,
				EIGHTEEN_DECIMALS
			) / balances[INDEX_SWD];
		}
	}

	// Reverts if [msg.sender] is not the specified owner. Not made a modifier in order to work well
	// with the gas-saving [slot6].
	function onlyOwner(address _owner) internal view {
		_require(msg.sender == _owner, Errors.CALLER_IS_NOT_OWNER);
	}

	// Reverts if the "swap lock" is not engaged. Not made a modifier in order to work well with
	// the gas-saving [slot6].
	function onlyLocked(uint8 locked) internal pure {
		_require(locked == UINT8_MAX, Errors.NOT_PAUSED);
	}

	// Reverts if the "swap lock" is engaged. Not made a modifier in order to work well with the
	// gas-saving [slot6].
	function notLocked(uint8 locked) internal pure {
		if (locked == UINT8_MAX) _revert(Errors.PAUSED);
	}

	// Checks if a given address is a contract, but always returns true
	// if [contr] is [address(this)]
	function isContract(IERC20 contr) internal view returns (bool) {
		if (address(contr) == address(this)) return true;
		uint size;
		assembly {
			size := extcodesize(contr)
		}
		return (size > 0);
	}

	// Multiplication technique by Remco Bloemen - MIT license
	// https://medium.com/wicketh/mathemagic-full-multiply-27650fec525d
	function safeMul(uint256 x, uint256 y) internal pure returns (uint256 r0) {
		uint256 r1;
		assembly {
			let mm := mulmod(x, y, not(0))
			r0 := mul(x, y)
			r1 := sub(sub(mm, r0), lt(mm, r0))
		}
		_require(r1 == 0, Errors.MUL_OVERFLOW);
	}

	// Necessary for working with [slot6.inCategoryTotals]. See ICommonStructs.sol for details.
	function bytes6ToUint16Arr(bytes6 _bytes) internal pure returns (uint16[3] memory num) {
		num[0] = uint16(bytes2(_bytes[0]) | (bytes2(_bytes[1]) >> 8));
		num[1] = uint16(bytes2(_bytes[2]) | (bytes2(_bytes[3]) >> 8));
		num[2] = uint16(bytes2(_bytes[4]) | (bytes2(_bytes[5]) >> 8));
	}

	// Necessary for working with [slot6.inCategoryTotals]. See ICommonStructs.sol for details.
	function uint16ArrToBytes6(uint16[3] memory num) internal pure returns (bytes6 _bytes) {
		_bytes = 
			bytes6(bytes2(num[0])) |
			(bytes6(bytes2(num[1])) >> 16) |
			(bytes6(bytes2(num[2])) >> 32);
	}
}

/*****************************************************************************/




/******************************************************************************
* File:     IPoolSwapStructs.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IPoolSwapStructs.sol
* Requires: IERC20.sol, IVault.sol
* License:  GPL-3.0-or-later
******************************************************************************/

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     IBasePool.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IBasePool.sol
* Requires: IVault.sol, IPoolSwapStructs.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev Interface for adding and removing liquidity that all Pool contracts should implement. Note that this is not
 * the complete Pool contract interface, as it is missing the swap hooks. Pool contracts should also inherit from
 * either IGeneralPool or IMinimalSwapInfoPool
 */
interface IBasePool is IPoolSwapStructs {
    /**
     * @dev Called by the Vault when a user calls `IVault.joinPool` to add liquidity to this Pool. Returns how many of
     * each registered token the user should provide, as well as the amount of protocol fees the Pool owes to the Vault.
     * The Vault will then take tokens from `sender` and add them to the Pool's balances, as well as collect
     * the reported amount in protocol fees, which the pool should calculate based on `protocolSwapFeePercentage`.
     *
     * Protocol fees are reported and charged on join events so that the Pool is free of debt whenever new users join.
     *
     * `sender` is the account performing the join (from which tokens will be withdrawn), and `recipient` is the account
     * designated to receive any benefits (typically pool shares). `balances` contains the total balances
     * for each token the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * join (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as minting pool shares.
     */
    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsIn, uint256[] memory dueProtocolFeeAmounts);

    /**
     * @dev Called by the Vault when a user calls `IVault.exitPool` to remove liquidity from this Pool. Returns how many
     * tokens the Vault should deduct from the Pool's balances, as well as the amount of protocol fees the Pool owes
     * to the Vault. The Vault will then take tokens from the Pool's balances and send them to `recipient`,
     * as well as collect the reported amount in protocol fees, which the Pool should calculate based on
     * `protocolSwapFeePercentage`.
     *
     * Protocol fees are charged on exit events to guarantee that users exiting the Pool have paid their share.
     *
     * `sender` is the account performing the exit (typically the pool shareholder), and `recipient` is the account
     * to which the Vault will send the proceeds. `balances` contains the total token balances for each token
     * the Pool registered in the Vault, in the same order that `IVault.getPoolTokens` would return.
     *
     * `lastChangeBlock` is the last block in which *any* of the Pool's registered tokens last changed its total
     * balance.
     *
     * `userData` contains any pool-specific instructions needed to perform the calculations, such as the type of
     * exit (e.g., proportional given an amount of pool shares, single-asset, multi-asset, etc.)
     *
     * Contracts implementing this function should check that the caller is indeed the Vault before performing any
     * state-changing operations, such as burning pool shares.
     */
    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut, uint256[] memory dueProtocolFeeAmounts);

    function getPoolId() external view returns (bytes32);
}

/*****************************************************************************/




/******************************************************************************
* File:     IGeneralPool.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IGeneralPool.sol
* Requires: IBasePool.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev IPools with the General specialization setting should implement this interface.
 *
 * This is called by the Vault when a user calls `IVault.swap` or `IVault.batchSwap` to swap with this Pool.
 * Returns the number of tokens the Pool will grant to the user in a 'given in' swap, or that the user will
 * grant to the pool in a 'given out' swap.
 *
 * This can often be implemented by a `view` function, since many pricing algorithms don't need to track state
 * changes in swaps. However, contracts implementing this in non-view functions should check that the caller is
 * indeed the Vault.
 */
interface IGeneralPool is IBasePool {
    function onSwap(
        SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256 amount);
}

/*****************************************************************************/




/******************************************************************************
* File:     IERC20.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/IERC20.sol
* License:  MIT
******************************************************************************/

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

/*****************************************************************************/




/******************************************************************************
* File:     ERC20.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/ERC20.sol
* Requires: BalancerErrors.sol, IERC20.sol, SafeMath.sol
* License:  MIT
* Modified: -- string private _name;
*           -- string private _symbol;
*           -- uint8 private _decimals;
*           ++ string internal _name;
*           ++ string internal _symbol;
*           ++ uint8 private immutable _decimals;
******************************************************************************/

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 private immutable _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE)
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _require(sender != address(0), Errors.ERC20_TRANSFER_FROM_ZERO_ADDRESS);
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        _require(account != address(0), Errors.ERC20_BURN_FROM_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, Errors.ERC20_BURN_EXCEEDS_BALANCE);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

/*****************************************************************************/




/******************************************************************************
* File:     IERC20Permit.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/IERC20Permit.sol
* License:  MIT
******************************************************************************/

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/*****************************************************************************/




/******************************************************************************
* File:     EIP712.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/EIP712.sol
* License:  MIT
******************************************************************************/

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _HASHED_NAME = keccak256(bytes(name));
        _HASHED_VERSION = keccak256(bytes(version));
        _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, _getChainId(), address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        // Silence state mutability warning without generating bytecode.
        // See https://github.com/ethereum/solidity/issues/10090#issuecomment-741789128 and
        // https://github.com/ethereum/solidity/issues/2691
        this;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     ERC20Permit.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/ERC20Permit.sol
* Requires: ERC20.sol, IERC20Permit.sol, EIP712.sol
* License:  MIT
******************************************************************************/

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    mapping(address => uint256) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        // solhint-disable-next-line not-rely-on-time
        _require(block.timestamp <= deadline, Errors.EXPIRED_PERMIT);

        uint256 nonce = _nonces[owner];
        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ecrecover(hash, v, r, s);
        _require((signer != address(0)) && (signer == owner), Errors.INVALID_SIGNATURE);

        _nonces[owner] = nonce + 1;
        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner];
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     BalancerPoolToken.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/pool-utils/contracts/BalancerPoolToken.sol
* Requires: ERC20Permit.sol, IVault.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @title Highly opinionated token implementation
 * @author Balancer Labs
 * @dev
 * - Includes functions to increase and decrease allowance as a workaround
 *   for the well-known issue with `approve`:
 *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
 * - Allows for 'infinite allowance', where an allowance of 0xff..ff is not
 *   decreased by calls to transferFrom
 * - Lets a token holder use `transferFrom` to send their own tokens,
 *   without first setting allowance
 * - Emits 'Approval' events whenever allowance is changed by `transferFrom`
 * - Assigns infinite allowance for all token holders to the Vault
 */
contract BalancerPoolToken is ERC20Permit {
    IVault private immutable _vault;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        IVault vault
    ) ERC20(tokenName, tokenSymbol) ERC20Permit(tokenName) {
        _vault = vault;
    }

    function getVault() public view returns (IVault) {
        return _vault;
    }

    // Overrides

    /**
     * @dev Override to grant the Vault infinite allowance, causing for Pool Tokens to not require approval.
     *
     * This is sound as the Vault already provides authorization mechanisms when initiation token transfers, which this
     * contract inherits.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (spender == address(getVault())) {
            return uint256(-1);
        } else {
            return super.allowance(owner, spender);
        }
    }

    /**
     * @dev Override to allow for 'infinite allowance' and let the token owner use `transferFrom` with no self-allowance
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 currentAllowance = allowance(sender, msg.sender);
        _require(msg.sender == sender || currentAllowance >= amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE);

        _transfer(sender, recipient, amount);

        if (msg.sender != sender && currentAllowance != uint256(-1)) {
            // Because of the previous require, we know that if msg.sender != sender then currentAllowance >= amount
            _approve(sender, msg.sender, currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Override to allow decreasing allowance by more than the current amount (setting it to zero)
     */
    function decreaseAllowance(address spender, uint256 amount) public override returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);

        if (amount >= currentAllowance) {
            _approve(msg.sender, spender, 0);
        } else {
            // No risk of underflow due to if condition
            _approve(msg.sender, spender, currentAllowance - amount);
        }

        return true;
    }

    // Internal functions

    function _mintPoolTokens(address recipient, uint256 amount) internal {
        _mint(recipient, amount);
    }

    function _burnPoolTokens(address sender, uint256 amount) internal {
        _burn(sender, amount);
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     CustomBalancerPool.sol
* Author:   Peter T. Flynn
* Location: Local
* Requires: ERC20.sol, IGeneralPool.sol, BalancerPoolToken.sol, ITokenPriceControllerDefault.sol,
*           ITokenPriceManagerMinimal.sol, IVault.sol, BalancerErrors.sol, ExtraStorage.sol,
*           ICommonStructs.sol
* License:  Apache 2.0
******************************************************************************/

/// @title SW DAO Balancer pool
/// @author Peter T. Flynn
/// @notice In order to allow swaps, the contract creator must call initialize(), tokensAdd(),
/// and setCategoryWeights(). Additionally, the owner must seed the pool by joining it with 
/// type [JoinKindPhantom.INIT], and finally calling toggleSwapLock().
/// @dev This contract is designed to operate behind a proxy, and must be initialized before use.
/// Constants require adjustment for deployment outside Polygon.
/// Concessions were made to comply with Solidity limitations, and time constraints
/// (ex. contract emits few events, is not gas efficient, and uses an external library).
/// Future versions of this contract should use separate contracts per function, with a local
/// singleton for onSwap(). [CONTRACT_VERSION] must be incremented every time a new contract
/// version necessitates a call to initialize().
contract CustomBalancerPool is IGeneralPool, BalancerPoolToken, ICommonStructs {
	IVault constant VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
	IERC20 constant SWD = IERC20(0xaeE24d5296444c007a532696aaDa9dE5cE6caFD0);
	ITokenPriceControllerDefault constant ORACLE =
		ITokenPriceControllerDefault(0x8A46Eb6d66100138A5111b803189B770F5E5dF9a);

	// 2^96 - 1 (~80 billion at 18-decimal precision)
	uint constant MAX_POOL_BPT = 0xffffffffffffffffffffffff;
	// 1e18 corresponds to 1.0, or a 100% fee
	// Set to the minimum for compatibility with Balancer interfaces. Actual fee is dynamic,
	// and changes on a per-token basis. [dueProtocolFees] are calculated at time of swap.
	uint256 constant SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
	// Always known, set at the first run of initialize()
	uint constant INDEX_BPT = 0;
	// Always known, set at the first run of initialize()
	uint constant INDEX_SWD = 1;
	// Named for readability
	uint8 constant UINT8_MAX = type(uint8).max;
	// Useful in common, fixed-point math - named for readability
	uint constant EIGHTEEN_DECIMALS = 1e18;

	// INIT, and COLLECT_PROTOCOL_FEES are standard, but TOP_UP_BPT has been added for the
	// highly-unlikely case in which the pool runs out of BPT for trading
	enum JoinKindPhantom { INIT, COLLECT_PROTOCOL_FEES, TOP_UP_BPT }
	// Balancer standard
	enum ExitKindPhantom { EXACT_BPT_IN_FOR_TOKENS_OUT }

	// Must be incremented whenever a new initialize() function is needed for an implementation
	uint16 constant CONTRACT_VERSION = 100; // Version 1.00;

	// SEE ICommonStructs.sol, AND ExtraStorage.sol FOR FURTHER DOCUMENTATION

	// Gas-saving storage slot
	Slot6 private slot6;
	// New owner for ownership transfer
	address private ownerNew;
	// Typically stored in [slot6.balanceFee], but said variable is also used for locking the
	// contract against swaps. In such an event, [balanceFeeCache] is used to store the original
	// value.
	uint8 private balanceFeeCache;
	// Timestamp for ownership transfer timeout
	uint private ownerTransferTimeout;
	// The Balancer-determined swap fee, paid to Balancer. Can be updated with
	// updateCachedProtocolSwapFeePercentage() by any caller.
	uint private cachedProtocolSwapFeePercentage;
	// The BPT balance owed to Balancer, which can be paid by any user joining the pool
	// with type [JoinKindPhantom.COLLECT_PROTOCOL_FEES]
	uint private dueProtocolFees;
	// The ID of the contract's Balancer pool, given to it when initialize() is called
	bytes32 private poolId;
	// Information for each token listed by the pool. Future versions of this contract should
	// consider storing more info here, as there is unused capacity in each 32-byte slot.
	// There is potential to store symbol, and decimal info in order to save gas.
	mapping(IERC20 => TokenInfo) private tokens;
	// Returns whether a given contract version has been initialized already
	mapping(uint16 => bool) private initialized;

	/// @notice Emitted when tokens are removed from the pool
	/// @param sender The transactor
	/// @param token The token removed
	event TokenRemove(address indexed sender, address indexed token);
	/// @notice Emitted when an ownership transfer is confirmed
	/// @param sender The transactor, and new owner
	/// @param oldOwner The old owner
	event OwnerConfirm(address indexed sender, address oldOwner);

	// This constructor is for compatibility's sake only, as the contract is designed to operate
	// behind a proxy, and the constructor will never be called in that environment
	constructor() BalancerPoolToken("UNSET", "UNSET", VAULT) {
		initialized[CONTRACT_VERSION] = true;
	}

	/// @notice Readies the contract for use, and registers it as a pool with Balancer.
	/// Must be called immediately after implementation in the proxy, as the contract's "owner"
	/// will be unset. Only needs to be called once per contract version.
	/// @param tokenName The name of the BPT, visible to users
	/// @param tokenSymbol The symbol (ticker) of the BPT, visible to users
	/// @dev This function must be entirely rewritten for subsequent contract versions, such that
	/// it only makes changes which are necessary for the new version to function. All variables
	/// will be retained between versions within the proxy contract.
	function initialize(
		string calldata tokenName,
		string calldata tokenSymbol
	) public {
		if (initialized[CONTRACT_VERSION]) _revert(Errors.INVALID_INITIALIZATION);
		Slot6 memory _slot6 = slot6;
		// Should never resolve to "true", but included for safety
		if (_slot6.owner != address(0))
			ExtraStorage.onlyOwner(_slot6.owner);
		_name = tokenName;
		_symbol = tokenSymbol;
		bytes32 _poolId = VAULT.registerPool(IVault.PoolSpecialization.GENERAL);
		poolId = _poolId;
		_slot6.owner = msg.sender;
		// Initiates the pool in its locked state
		_slot6.balanceFee = UINT8_MAX;
		balanceFeeCache = 10;
		tokens[this] = TokenInfo(TokenCategory.BASE, 1);
		tokens[SWD] = TokenInfo(TokenCategory.BASE, 1);
		_slot6.tokensLength += 2;
		IERC20[] memory _tokens = new IERC20[](2);
		_tokens[INDEX_BPT] = this;
		_tokens[INDEX_SWD] = SWD;
		VAULT.registerTokens(_poolId, _tokens, new address[](2));
		updateCachedProtocolSwapFeePercentage();
		slot6 = _slot6;
		initialized[CONTRACT_VERSION] = true;
	}

	/// @notice Adds tokens to the pool by address, but does not increase their balance.
	/// A token can only be added if it has a TokenPriceManager present in [ORACLE], which
	/// is a TokenPriceController. For details, see ITokenPriceManagerMinimal.sol, and
	/// ITokenPriceControllerDefault.sol. (Can only be called by the owner)
	/// @param _tokens A list of token addresses to add
	/// @param categories A list of [TokenCategory]s of the same length,
	/// and in the same order as [_tokens]
	/// @param weights A list of weights (uint8), of the same length and order as [_tokens], which
	/// dictates the respective token's weight within the chosen category
	function tokensAdd(
		IERC20[] calldata _tokens,
		TokenCategory[] calldata categories,
		uint8[] calldata weights
	) external {
		slot6 = ExtraStorage.tokensAddIterate(slot6, tokens, _tokens, categories, weights);
		VAULT.registerTokens(poolId, _tokens, new address[](_tokens.length));
	}

	/// @notice Removes tokens from the pool by address. Each token must have a zero balance within
	/// the pool before removal. One can achieve a zero balance by either buying all the tokens
	/// manually, or by incentivizing their sale by setting the token's weight to 0.
	/// (Can only be called by the owner)
	/// @param _tokens A list of token addresses to remove
	function tokensRemove(
		IERC20[] calldata _tokens
	) external {
		Slot6 memory _slot6 = slot6;
		ExtraStorage.onlyOwner(_slot6.owner);
		_require(_tokens.length < _slot6.tokensLength - 2, Errors.MIN_TOKENS);
		uint16[3] memory categoryWeights;
		for (uint i; i < _tokens.length; i++) {
			uint8 category = uint8(tokens[_tokens[i]].category);
			// The [category & 0x3 != 0] below detects that the token is both added,
			// and not in the [TokenCategory.BASE] category, using a binary trick
			_require(category & 0x3 != 0, Errors.INVALID_TOKEN);
			categoryWeights[category - 1] += tokens[_tokens[i]].inCategoryWeight;
			delete tokens[_tokens[i]];
			emit TokenRemove(_slot6.owner, address(_tokens[i]));
		}
		uint16[3] memory _inCategoryTotals =
			ExtraStorage.bytes6ToUint16Arr(_slot6.inCategoryTotals);
		for (uint i; i < categoryWeights.length; i++)
			_inCategoryTotals[i] -= categoryWeights[i];
		_slot6.inCategoryTotals = ExtraStorage.uint16ArrToBytes6(_inCategoryTotals);
		_slot6.tokensLength -= uint8(_tokens.length);
		VAULT.deregisterTokens(poolId, _tokens);
		slot6 = _slot6;
	}

	/// @notice Sets the balance fee to the requested value, which is used to incentivize traders
	/// into keeping the pool balanced according to the set weights.
	/// (Can only be called by the owner)
	/// @param fee The new fee (in tenths of a percent, ex. 10 = 1%)
	function setBalanceFee(uint8 fee) external {
		require(fee < UINT8_MAX, "NoMax");
		Slot6 memory _slot6 = slot6;
		ExtraStorage.onlyOwner(_slot6.owner);
		if (_slot6.balanceFee == UINT8_MAX)
			balanceFeeCache = fee;
		else
			_slot6.balanceFee = fee;
		slot6 = _slot6;
	}

	/// @notice Sets the weights for each category, relative to one-another:
	/// "products", "common", then "USD" (Can only be called by the owner).
	/// The sum of all three weights must be less than 256.
	/// See ICommonStructs.sol, or getSlot6() below for more details.
	/// @param weights Three weights (uint8) corresponding to each main category
	function setCategoryWeights(uint8[3] calldata weights) external {
		slot6 = ExtraStorage.setCategoryWeightsIterate(slot6, weights);
	}

	/// @notice Sets the weights for the requested tokens, relative to the other tokens
	/// in each token's category (Can only be called by the owner)
	/// @param _tokens A list of token addresses to modify (must already be added to the pool)
	/// @param weights A list of weights of the same length, and in the same order as [_tokens]
	function setTokenWeights(IERC20[] calldata _tokens, uint8[] calldata weights) external {
		_require(_tokens.length == weights.length, Errors.INPUT_LENGTH_MISMATCH);
		slot6 = ExtraStorage.setTokenWeightsIterate(slot6, _tokens, weights, tokens);
	}

	/// @notice Toggles the lock, which prevents swapping within the pool, and allows for exits.
	/// To unlock swaps, the pool must have some balance in a token besides the BPT, or SWD;
	/// and, by extension, the pool must have some BPT tokens circulating, outside the pool itself.
	/// Most useful for four things:
	/// 1) Locking the pool in case of an emergency/exploit.
	/// 2) Making 1-for-1 withdrawals by locking, exiting, and then unlocking the pool in one TX.
	///    This allows for the pool owner to withdraw without affecting the BPT, or SWD prices.
	/// 3) Decommissioning the pool.
	/// 4) Unlocking the pool after initialization.
	/// Call isLocked() to detect current lock state.
	/// (Can only be called by the owner)
	function toggleSwapLock() external {
		Slot6 memory _slot6 = slot6;
		ExtraStorage.onlyOwner(_slot6.owner);
		if (_slot6.balanceFee == UINT8_MAX) {
			(IERC20[] memory _tokens, uint[] memory balances,) =
				VAULT.getPoolTokens(poolId);
			ExtraStorage.toggleSwapLockCheckState(
				_tokens, balances,
				tokens, totalSupply(),
				dueProtocolFees
			);
			_slot6.balanceFee = balanceFeeCache;
			balanceFeeCache = 0;
		} else {
			balanceFeeCache = _slot6.balanceFee;
			_slot6.balanceFee = UINT8_MAX;
		}
		slot6 = _slot6;
	}

	/// @notice The standard "join" interface for Balancer pools, used in a nonstandard fashion.
	/// Cannot be called directly, but can be called through the vault's joinPool() function.
	/// Typical users do not call joinPool() to join, instead they should simply trade for the BPT
	/// token, as the BPTs are part of the (phantom) pool, like any other token.
	/// @dev Please see Balancer's IVault.sol for documentation on joinPool(), but do note:
	/// 1) The [JoinKindPhantom] is interpreted through the [userData] field, along with the
	///    requested [amountsIn].
	/// 2) maxAmountsIn[0] should always be type(uint).max, while the other values should match
	///    those passed in the userData field. This is to allow for mint/deposit combinations in
	///    certain join types, especially [JoinKindPhantom.INIT].
	function onJoinPool(
		bytes32 _poolId,
		address sender,
		address recipient,
		uint[] calldata balances,
		uint,
		uint,
		bytes calldata userData
	) external override returns (
		uint[] memory amountsIn,
		uint[] memory dueProtocolFeeAmounts
	) {
		onlyVault(_poolId);
		(JoinKindPhantom kind, uint[] memory amountsInRequested) = abi.decode(
			userData,
			(JoinKindPhantom, uint256[])
		);
		dueProtocolFeeAmounts = new uint[](balances.length);
		// Allows Balancer to collect fees due to their protocol
		if (kind == JoinKindPhantom.COLLECT_PROTOCOL_FEES) {
			amountsIn = new uint[](balances.length);
			dueProtocolFeeAmounts[INDEX_BPT] = dueProtocolFees;
			dueProtocolFees = 0;
		// Allows the pool owner to seed the pool with a balance after initialization
		} else if (kind == JoinKindPhantom.INIT && totalSupply() == 0) {
			_require(sender == recipient && recipient == slot6.owner, Errors.CALLER_IS_NOT_OWNER);
			amountsIn = amountsInRequested;
			uint initBPT;
			{
				(IERC20[] memory _tokens,,) = VAULT.getPoolTokens(poolId);
				(initBPT,,) = ExtraStorage.getValue(
					_tokens, amountsIn,
					INDEX_SWD, INDEX_SWD,
					totalSupply(), dueProtocolFees
				);
			}
			require(initBPT >= 10000 * EIGHTEEN_DECIMALS, "Min$20K");
			amountsIn[INDEX_BPT] = MAX_POOL_BPT;
			_mintPoolTokens(recipient, MAX_POOL_BPT + initBPT - (10 * EIGHTEEN_DECIMALS));
			_mintPoolTokens(address(0), (10 * EIGHTEEN_DECIMALS));
		// Allows anyone to "top-up" the BPT in the pool in case it runs low, and doing so has no
		// effect on the price of the BPT, or the value within the pool
		} else if (
			kind == JoinKindPhantom.TOP_UP_BPT &&
			balances[INDEX_BPT] < MAX_POOL_BPT
		) {
			amountsIn = new uint[](balances.length);
			uint amountBPT = MAX_POOL_BPT - balances[INDEX_BPT];
			amountsIn[INDEX_BPT] = amountBPT;
			_mintPoolTokens(recipient, amountBPT);
		} else {
			_revert(Errors.UNHANDLED_BY_PHANTOM_POOL);
		}
	}

	/// @notice The standard "exit" interface for Balancer pools, used in a nonstandard fashion.
	/// Cannot be called directly, but can be called through the vault's exitPool() function.
	/// Typical users do not call exitPool() to exit, instead they should simply trade the BPT for
	/// other tokens, as the BPTs are part of the (phantom) pool, like any other token.
	/// @dev Please see Balancer's IVault.sol for documentation on exitPool(), but do note:
	/// 1) The [ExitKindPhantom] is interpreted through the [userData] field, along with the
	///    requested [bptAmountIn].
	/// 2) minAmountsOut[0] should always be 0, as the zeroth token in the pool is always the BPT,
	///    and the pool will never return BPT upon exit. Other indexes can safely be set to 0 as
	///    well, given that the pool always returns in proportion to the BPT in circulation.
	function onExitPool(
		bytes32 _poolId,
		address sender,
		address,
		uint[] calldata balances,
		uint,
		uint,
		bytes calldata userData
	) external override returns (
		uint[] memory amountsOut,
		uint[] memory dueProtocolFeeAmounts
	) {
		onlyVault(_poolId);
		Slot6 memory _slot6 = slot6;
		ExtraStorage.onlyLocked(_slot6.balanceFee);
		(ExitKindPhantom kind, uint bptAmountIn) = abi.decode(
			userData,
			(ExitKindPhantom, uint256)
		);
		uint bptSupply = getCirculatingSupply(balances[INDEX_BPT]);
		_require(bptSupply >= bptAmountIn, Errors.ADDRESS_INSUFFICIENT_BALANCE);
		if (kind == ExitKindPhantom.EXACT_BPT_IN_FOR_TOKENS_OUT) {
			amountsOut = ExtraStorage.onExitPoolAmountsOut(balances, bptSupply, bptAmountIn);
			_burnPoolTokens(sender, bptAmountIn);
			dueProtocolFeeAmounts = new uint[](balances.length);
		} else {
			_revert(Errors.UNHANDLED_BY_PHANTOM_POOL);
		}
	}

	/// @notice The standard "swap" interface for Balancer pools. Cannot be called directly, but
	/// can be called through the vault's various swap functions. A "blocklock" is implemented to
	/// prevent flashloan attacks - although no attack vector is currently known.
	/// @dev Please see Balancer's IVault.sol for documentation on swaps.
	// Swap implementation is unique, and is composed internally using separate AMM methods:
	// 1) The first method applies to all tokens that are not the BPT, or SWD.
	//		• Tokens are bought and sold for the fair price dictated by the [ORACLE].
	//		• Buy versus sell price can be reported differently by the [ORACLE].
	//		• Tokens may run out entirely, and prices do not change according to balance
	//		  proportions (unlike Uniswap's constant-product method)
	//		• Tokens are maintained according to the set weights using a flat fee/bonus dictated by
	//		  the [slo6.balanceFee]. A user bringing the pool back into balance will receive a
	//		  bonus (reducing the BPT value), whereas a user bringing it out of balance will pay a
	//		  fee (increasing the BPT value). Balance is incentivized by offering rates different
	//		  from those in the wider market.
	//		• Fees due to the Balancer protocol are calculated by comparing the final output to a
	//		  hypothetical, feeless transaction.
	// 2) The second method applies to SWD.
	//		• SWD's price is calculated using the constant-product method (like Uniswap).
	//		• Rather than calculating against a single token (ex. WETH, USDC, etc.), SWD is 
	//		  compared to the entire sum of all other tokens in the pool (in USD).
	//		  With the BPT being "Token_0", and SWD being "Token_1":
	//
	//			Balance:		USD Sum:		Constant:
	//
	//							Token_2
	//			SWD		X		...			=	K
	//							Token_N
	//
	//		  Alternatively:
	//
	//			(SWD Price)×(SWD Balance) =
	//				(Token_2 Price)×(Token_2 Balance) + ... + (Token_N Price)×(Token_N Balance)
	//
	//		• Summing the USD value of all tokens can be gas-expensive, therefore future versions
	//		  of this contract should seek to make this process as efficient as possible, and care
	//		  should be taken when adding more tokens to the pool. A hard cap of 50 tokens has been
	//		  set within [ExtraStorage.MAX_TOKENS].
	// 3) The final method applies to the BPT.
	//		• Like SWD, the BPT's price is found through the summation of all value within the
	//		  pool, but rather than changing with balance proportions, the total pool value is
	//		  simply divided by the BPT's circulating supply.
	//
	//			USD Sum:		Balance:					USD Price:
	//
	//			Token_2
	//			...			/	(Circulating Supply)	=	BPT
	//			Token_N
	//
	//		• The BPT's circulating supply is found by subtracting the pool's balance from the
	//		  total supply, and then adding those tokens due as fees to the Balancer protocol, but
	//		  not yet issued.
	//
	//		  (Circulating Supply) = (Total Supply) - (Pool Balance) + (Due Protocol Fees)
	//
	//		• The process of the pool owner joining the pool with [JoinKindPhantom.INIT] mints the
	//		  initial supply of BPT, and deposits the initial balance within the pool. The total
	//		  balance remaining in the pool owner's wallet will equate 1-to-1 with every USD
	//		  (in value) deposited to the pool, excluding the value of the SWD. This gives the BPT
	//		  an initial value of $1.
	//		• As BPT are accounted for as they enter/leave the pool, the price of BPT will remain
	//		  constant for such transactions. The price of the BPT only changes if:
	//			1) The underlying tokens change in value.
	//			2) Trades are made with the SWD balance (thus changing SWD's value).
	//			3) The pool accumulates fees, or grants trade bonuses.
	//		  This makes the BPT's performance as an asset easy to understand for the end user.
	//		• Intuitively, one might expect that the BPT should be valued using double the pool's
	//		  total value, in order to account for the value of the pool's SWD. However, this would
	//		  be an error, as shown in the following scenario.
	//		  	1) A user owns all circulating BPT.
	//			2) That user sells half their BPT to purchase all tokens except the SWD.
	//			3) The user then sells zero BPT to purchase all the SWD which are now worth nothing.
	//			4) The user retains half their original BPT, while the pool is now empty.
	//		  Accounting for the BPT's price properly avoids such a possibility.
	// All complexity is abstracted away from the end user, and these solutions are compatible with
	// DEx aggregators. Trades from SWD to the BPT are not allowed directly, acting as an
	// artificial bias towards SWD's positive price-action.
	function onSwap(
		SwapRequest calldata swapRequest,
		uint[] calldata balances,
		uint indexIn,
		uint indexOut
	) external override returns (uint amount) {
		_require(balances[indexOut] != 0, Errors.INSUFFICIENT_BALANCE);
		if (
			indexIn == INDEX_SWD &&
			indexOut == INDEX_BPT
		) {
			_revert(Errors.UNHANDLED_JOIN_KIND);
		}
		onlyVault(swapRequest.poolId);
		require(swapRequest.lastChangeBlock != block.number, "BlockLock");
		Slot6 memory _slot6 = slot6;
		ExtraStorage.notLocked(_slot6.balanceFee);
		GetValue memory _getValue;
		TokenData memory _tokenData;
		{
			(IERC20[] memory _tokens,,) = VAULT.getPoolTokens(poolId);
			(_getValue.totalMinusSWD, _getValue.indexIn,
			_getValue.indexOut) = ExtraStorage.getValue(
				_tokens, balances,
				indexIn, indexOut,
				totalSupply(), dueProtocolFees
			);
			_getValue.bpt = ExtraStorage.safeMul(
				_getValue.totalMinusSWD,
				EIGHTEEN_DECIMALS
			) / getCirculatingSupply(balances[INDEX_BPT]);
			_tokenData.indexIn = indexIn;
			_tokenData.indexOut = indexOut;
			_tokenData.inInfo = tokens[swapRequest.tokenIn];
			_tokenData.outInfo = tokens[swapRequest.tokenOut];
		}
		IndexPricing memory _pricing;
		_pricing.indexIn = (_tokenData.inInfo.category == TokenCategory.BASE) ?
			ExtraStorage.onSwapGetIndexInPricing(
				swapRequest, balances,
				_getValue, _tokenData
			) :
			ExtraStorage.onSwapGetComplexPricing(
				_getValue.totalMinusSWD,
				swapRequest.tokenIn,
				_tokenData.inInfo,
				_getValue.indexIn,
				_slot6,
				true
			);
		_pricing.indexOut = (_tokenData.outInfo.category == TokenCategory.BASE) ?
			ExtraStorage.onSwapGetIndexOutPricing(
				swapRequest, balances,
				_getValue, _tokenData
			) :
			ExtraStorage.onSwapGetComplexPricing(
				_getValue.totalMinusSWD,
				swapRequest.tokenOut,
				_tokenData.outInfo,
				_getValue.indexOut,
				_slot6,
				false
			);
		amount = ExtraStorage.onSwapGetAmount(swapRequest, balances, _tokenData, _pricing);
		dueProtocolFees += ExtraStorage.onSwapCalculateFees(
			swapRequest, _getValue, _tokenData, _pricing,
			amount, cachedProtocolSwapFeePercentage
		);
	}

	/// @notice Initiates an ownership transfer, but the new owner must call ownerConfirm()
	/// within 36 hours to finalize (Can only be called by the owner)
	/// @param _ownerNew The new owner's address
	function ownerTransfer(address _ownerNew) external {
		ExtraStorage.onlyOwner(slot6.owner);
		ownerNew = _ownerNew;
		ownerTransferTimeout = block.timestamp + 36 hours;
	}

	/// @notice Finalizes an ownership transfer (Can only be called by the new owner)
	function ownerConfirm() external {
		ExtraStorage.onlyOwner(ownerNew);
		if (block.timestamp > ownerTransferTimeout) _revert(Errors.EXPIRED_PERMIT);
		address _ownerOld = slot6.owner;
		slot6.owner = ownerNew;
		ownerNew = address(0);
		ownerTransferTimeout = 0;
		emit OwnerConfirm(msg.sender, _ownerOld);
	}

	/// @notice Used to rescue mis-sent tokens from the contract address
	/// (Can only be called by the contract owner)
	/// @param _token The address of the token to be rescued
	function withdrawToken(address _token) external {
		address _owner = slot6.owner;
		ExtraStorage.onlyOwner(_owner);
		_require(IERC20(_token).transfer(
				_owner,
				IERC20(_token).balanceOf(address(this))
			),
			Errors.SAFE_ERC20_CALL_FAILED
		);
	}

	/// @notice Used to burn BPT from the caller's wallet. (Can be called by anyone)
	/// Only call this function if you really know what you're doing.
	/// @param amount The amount of BPT to burn (18-decimals of precision)
	function burnPoolTokens(uint amount) external {
		_burnPoolTokens(msg.sender, amount);
	}

	/// @notice Updates the Balancer protocol's swap fee (Can be called by anyone)
	function updateCachedProtocolSwapFeePercentage() public {
		cachedProtocolSwapFeePercentage = VAULT.getProtocolFeesCollector().getSwapFeePercentage();
	}

	/// @notice Gets pricing information for both the BPT, and SWD
	/// @return bptValue The BPT's current price (in USD with 18-decimals of precision)
	/// @return swdValue SWD's current price (in USD with 18-decimals of precision)
	function getValue() external view returns (uint bptValue, uint swdValue) {
		TokenValuation memory bptTotal;
		TokenValuation memory swdTotal;
		{
			(IERC20[] memory _tokens, uint[] memory balances,) =
				VAULT.getPoolTokens(poolId);
			(,bptTotal,swdTotal) = ExtraStorage.getValue(
				_tokens, balances,
				INDEX_BPT, INDEX_SWD,
				totalSupply(), dueProtocolFees
			);
		}
		return (bptTotal.price, swdTotal.price);
	}

	/// @notice Gets the current state of the "swap lock" which prevents swaps within the pool
	/// @return bool "True" indicates that the pool is locked, "false" indicates that it's unlocked.
	function isLocked() external view returns (bool) {
		return (slot6.balanceFee == UINT8_MAX);
	}

	/// @notice Gets the BPT's current circulating supply
	/// @return uint The BPT's circulating supply
	function getCirculatingSupply() external view returns (uint) {
		(,uint[] memory balances,) = VAULT.getPoolTokens(poolId);
		return getCirculatingSupply(balances[INDEX_BPT]);
	}

	/// @notice Standard Balancer interface for getting the pool's internal ID
	///	@return bytes32 The pool's ID, given to it by Balancer upon registration
	function getPoolId() external view override returns (bytes32) { return poolId; }

	/// @notice Helper function for reading the [slot6] struct
	/// @dev [slot6] uses fixed-size byte arrays for [categoryWeights], and [inCategoryTotals] in
	/// order to achieve tighter packing, and to stay within a single 32-byte slot; however, these
	/// variables are used internally as fixed-size uint8/uint16 arrays. This function grants the
	/// end user an easier method for reading these values on/off-chain.
	/// Please see ICommonStructs.sol for further documentation.
	/// @return owner The current contract owner
	/// @return tokensLength The number of tokens managed by the pool, including the BPT, and SWD
	/// @return balanceFee The current, flat fee used to maintain the token balances according to
	/// the configured weights, expressed in tenths of a percent (ex. 10 = 1%). Can also be set to
	/// 255 (type(uint8).max) to indicate that the "swap lock" is engaged, in which case the
	/// balance fee can be found in [balanceFeeCache].
	/// @return categoryWeights The weights of the three, primary categories (DAO Products, Common
	/// Tokens, and USD-related tokens) relative to one another (ex. [1, 1, 1] would grant 1/3 of
	/// the pool to each category)
	/// @return categoryWeightsTotal The sum of all [categoryWeights]
	/// @return inCategoryTotals The sum of all individual, token wights within a given category
	function getSlot6() external view returns (
		address owner, uint8 tokensLength, uint8 balanceFee,
		uint8[3] memory categoryWeights, uint8 categoryWeightsTotal,
		uint16[3] memory inCategoryTotals
	) {
		Slot6 memory _slot6 = slot6;
		categoryWeights[0] = uint8(_slot6.categoryWeights[0]);
		categoryWeights[1] = uint8(_slot6.categoryWeights[1]);
		categoryWeights[2] = uint8(_slot6.categoryWeights[2]);
		return (
			_slot6.owner, _slot6.tokensLength, _slot6.balanceFee,
			categoryWeights, _slot6.categoryWeightsTotal,
			ExtraStorage.bytes6ToUint16Arr(_slot6.inCategoryTotals)
		);
	}

	/// @notice Returns a fake "swap fee" for compliance with standard Balancer interfaces
	/// @return uint256 A falsified "swap fee", set to the minimum allowed by Balancer. Actual swap
	/// fee varies depending on the tokens traded. Due protocol fees are properly accounted for
	/// during swaps, are stored in [dueProtocolFees], and can be claimed through a joinPool()
	/// using [JoinKindPhantom.COLLECT_PROTOCOL_FEES].
	function getSwapFeePercentage() external pure returns (uint256) {
		return SWAP_FEE_PERCENTAGE;
	}

	/// @notice Returns the internal version of this contract, which is mainly used to maintain
	/// consistency within the proxy.
	/// @return uint16 The version number, with 2-decimals of precision (ex. 100 = 1.00).
	function getVersion() external pure returns (uint16) {
		return CONTRACT_VERSION;
	}

	/// @notice Returns the internal version of the [ExtraStorage] library, along with its address
	/// @return uint16 The version number, with 2-decimals of precision (ex. 100 = 1.00).
	/// @return address The address of the [ExtraStorage] library.
	function getVersionStorage() external pure returns (uint16, address) {
		return (ExtraStorage.CONTRACT_VERSION, address(ExtraStorage));
	}

	// Internal version of getCirculatingSupply() useful for memory management
	function getCirculatingSupply(uint bptBalance) private view returns (uint bptAmount) {
		return totalSupply() - bptBalance + dueProtocolFees;
	}

	// Reverts if the [msg.sender] is not the [VAULT]
	function onlyVault(bytes32 _poolId) private view {
		_require(
			msg.sender == address(VAULT) &&
			_poolId == poolId, Errors.CALLER_NOT_VAULT
		);
	}
}

/*****************************************************************************/




/******************************************************************************
* File:     ITokenPriceControllerDefault.sol
* Author:   Peter T. Flynn
* Location: https://github.com/Peter-Flynn/SWDAO_TokenPriceManager-Controller/blob/master/
*           contracts/interfaces/ITokenPriceControllerDefault.sol
* Requires: ITokenPriceManagerMinimal.sol
* License:  Apache 2.0
******************************************************************************/

/// @title Address database for TokenPriceManagers
/// @author Peter T. Flynn
/// @notice Allows for access to TokenPriceManagers by their primary token's symbol, with
/// easy upgradeability in mind.
interface ITokenPriceControllerDefault {
    /// @notice Gets the address of a TokenPriceManager, given the primary token's symbol
    /// @param symbol The primary token's symbol, formatted identically to its contract variable
    function getManager(string calldata symbol)
        external
        view
        returns 
        (ITokenPriceManagerMinimal);
}

/*****************************************************************************/




/******************************************************************************
* File:     ITokenPriceManagerMinimal.sol
* Author:   Peter T. Flynn
* Location: https://github.com/Peter-Flynn/SWDAO_TokenPriceManager-Controller/blob/master/
*           contracts/interfaces/ITokenPriceManagerMinimal.sol
* License:  Apache 2.0
******************************************************************************/

/// @title Price maintainer for arbitrary tokens
/// @author Peter T. Flynn
/// @notice Maintains a common interface for requesting the price of the given token, with
/// special functionality for TokenSets.
/// @dev Contract must be initialized before use. Price should always be requested using 
/// getPrice(PriceType), rather than viewing the [price] variable. Price returned is dependent
/// on the transactor's SWD balance. Constants require adjustment for deployment outside Polygon. 
interface ITokenPriceManagerMinimal {
    // @notice Affects the application of the "spread fee" when requesting token price
    enum PriceType { BUY, SELL, RAW }
    
    /// @notice Gets the current price of the primary token, denominated in [tokenDenominator]
    /// @dev Returns a different value, depending on the SWD balance of tx.origin's wallet.
    /// If the balance is over the threshold, getPrice() will return the price unmodified,
    /// otherwise it adds the dictated fee. Tx.origin is purposefully used over msg.sender,
    /// so as to be compatible with DEx aggregators. As a side effect, this makes it incompatible
    /// with relays. Price is always returned with 18 decimals of precision, regardless of token
    /// decimals. Manual adjustment of precision must be done later for [tokenDenominator]s
    /// with less precision.
    /// @param priceType "BUY" for buying, "SELL" for selling,
    /// and "RAW" for a direct price request
    /// @return uint256 Current price in [tokenDenominator], per primary token
    /// @return address Current [tokenDenominator], may be address(0) to indicate USD
    function getPrice(PriceType priceType) external view returns (uint256, address);

    /// @return address Current [tokenPrimary]
    function getTokenPrimary() external view returns (address);

    /// @return address Current [tokenDenominator], may be address(0) to indicate USD
    function getTokenDenominator() external view returns (address);
}

/*****************************************************************************/




/******************************************************************************
* File:     ISignaturesValidator.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/helpers/ISignaturesValidator.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

/*****************************************************************************/




/******************************************************************************
* File:     ITemporarilyPausable.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/helpers/ITemporarilyPausable.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

/*****************************************************************************/




/******************************************************************************
* File:     IAuthentication.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/helpers/IAuthentication.sol
* License:  GPL-3.0-or-later
******************************************************************************/

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

/*****************************************************************************/




/******************************************************************************
* File:     BalancerErrors.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/helpers/BalancerErrors.sol
* License:  GPL-3.0-or-later
******************************************************************************/

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAL#" part is a known constant
        // (0x42414c23): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414c23000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant UNAUTHORIZED_OPERATION = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;
}

/*****************************************************************************/




/******************************************************************************
* File:     IVault.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IVault.sol
* Requires: IERC20.sol, IAuthentication.sol, ISignaturesValidator.sol, ITemporarilyPausable.sol,
*           IWETH.sol, IAsset.sol, IAuthorizer.sol, IFlashLoanRecipient.sol,
*           IProtocolFeesCollector.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

/*****************************************************************************/




/******************************************************************************
* File:     SafeMath.sol
* Author:   OpenZeppelin
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/openzeppelin/SafeMath.sol
* Requires: BalancerErrors.sol
* License:  MIT
******************************************************************************/

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, Errors.SUB_OVERFLOW);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, uint256 errorCode) internal pure returns (uint256) {
        _require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
    }
}

/*****************************************************************************/




/******************************************************************************
* File:     IWETH.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/solidity-utils/contracts/misc/IWETH.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

/*****************************************************************************/




/******************************************************************************
* File:     IAsset.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IAsset.sol
* License:  GPL-3.0-or-later
******************************************************************************/

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

/*****************************************************************************/




/******************************************************************************
* File:     IAuthorizer.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IAuthorizer.sol
* License:  GPL-3.0-or-later
******************************************************************************/

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

/*****************************************************************************/




/******************************************************************************
* File:     IFlashLoanRecipient.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IFlashLoanRecipient.sol
* Requires: IERC20.sol
* License:  GPL-3.0-or-later
******************************************************************************/

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

/*****************************************************************************/




/******************************************************************************
* File:     IProtocolFeesCollector.sol
* Author:   Balancer Labs
* Location: https://github.com/balancer-labs/balancer-v2-monorepo/blob/master/
*           pkg/vault/contracts/interfaces/IProtocolFeesCollector.sol
* Requires: IERC20.sol, IVault.sol, IAuthorizer.sol
* License:  GPL-3.0-or-later
******************************************************************************/

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}

/*****************************************************************************/