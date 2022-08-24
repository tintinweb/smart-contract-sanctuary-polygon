// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicense

// MgvLib.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./IERC20.sol";
import "./preprocessed/MgvPack.post.sol" as P;

/* # Structs
The structs defined in `structs.js` have their counterpart as solidity structs that are easy to manipulate for outside contracts / callers of view functions. */

library MgvLib {
  /*
   Some miscellaneous data types useful to `Mangrove` and external contracts */
  //+clear+

  /* `SingleOrder` holds data about an order-offer match in a struct. Used by `marketOrder` and `internalSnipes` (and some of their nested functions) to avoid stack too deep errors. */
  struct SingleOrder {
    address outbound_tkn;
    address inbound_tkn;
    uint offerId;
    P.Offer.t offer;
    /* `wants`/`gives` mutate over execution. Initially the `wants`/`gives` from the taker's pov, then actual `wants`/`gives` adjusted by offer's price and volume. */
    uint wants;
    uint gives;
    /* `offerDetail` is only populated when necessary. */
    P.OfferDetail.t offerDetail;
    P.Global.t global;
    P.Local.t local;
  }

  /* <a id="MgvLib/OrderResult"></a> `OrderResult` holds additional data for the maker and is given to them _after_ they fulfilled an offer. It gives them their own returned data from the previous call, and an `mgvData` specifying whether the Mangrove encountered an error. */

  struct OrderResult {
    /* `makerdata` holds a message that was either returned by the maker or passed as revert message at the end of the trade execution*/
    bytes32 makerData;
    /* `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes) code. */
    bytes32 mgvData;
  }
}

/* # Events
The events emitted for use by bots are listed here: */
contract HasMgvEvents {
  /* * Emitted at the creation of the new Mangrove contract on the pair (`inbound_tkn`, `outbound_tkn`)*/
  event NewMgv();

  /* Mangrove adds or removes wei from `maker`'s account */
  /* * Credit event occurs when an offer is removed from the Mangrove or when the `fund` function is called*/
  event Credit(address indexed maker, uint amount);
  /* * Debit event occurs when an offer is posted or when the `withdraw` function is called */
  event Debit(address indexed maker, uint amount);

  /* * Mangrove reconfiguration */
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetVault(address value);
  event SetUseOracle(bool value);
  event SetNotify(bool value);
  event SetGasmax(uint value);
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasprice(uint value);

  /* Market order execution */
  event OrderStart();
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint feePaid
  );

  /* * Offer execution */
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives
  );

  /* Log information when a trade execution reverts or returns a non empty bytes32 word */
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    // `maker` is not logged because it can be retrieved from the state using `(outbound_tkn,inbound_tkn,id)`.
    address taker,
    uint takerWants,
    uint takerGives,
    // `mgvData` may only be `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"`
    bytes32 mgvData
  );

  /* Log information when a posthook reverts */
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId,
    bytes32 posthookData
  );

  /* * After `permit` and `approve` */
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );

  /* * Mangrove closure */
  event Kill();

  /* * An offer was created or updated.
  A few words about why we include a `prev` field, and why we don't include a
  `next` field: in theory clients should need neither `prev` nor a `next` field.
  They could just 1. Read the order book state at a given block `b`.  2. On
  every event, update a local copy of the orderbook.  But in practice, we do not
  want to force clients to keep a copy of the *entire* orderbook. There may be a
  long tail of spam. Now if they only start with the first $N$ offers and
  receive a new offer that goes to the end of the book, they cannot tell if
  there are missing offers between the new offer and the end of the local copy
  of the book.
  
  So we add a prev pointer so clients with only a prefix of the book can receive
  out-of-prefix offers and know what to do with them. The `next` pointer is an
  optimization useful in Solidity (we traverse fewer memory locations) but
  useless in client code.
  */
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );

  /* * `offerId` was present and is now removed from the book. */
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
}

/* # IMaker interface */
interface IMaker {
  /* Called upon offer execution. 
  - If the call fails, Mangrove will not try to transfer funds.
  - If the call succeeds but returndata's first 32 bytes are not 0, Mangrove will not try to transfer funds either.
  - If the call succeeds and returndata's first 32 bytes are 0, Mangrove will try to transfer funds.
  In other words, you may declare failure by reverting or by returning nonzero data. In both cases, those 32 first bytes will be passed back to you during the call to `makerPosthook` in the `result.mgvData` field.
     ```
     function tradeRevert(bytes32 data) internal pure {
       bytes memory revData = new bytes(32);
         assembly {
           mstore(add(revData, 32), data)
           revert(add(revData, 32), 32)
         }
     }
     ```
     */
  function makerExecute(MgvLib.SingleOrder calldata order)
    external
    returns (bytes32);

  /* Called after all offers of an order have been executed. Posthook of the last executed order is called first and full reentrancy into the Mangrove is enabled at this time. `order` recalls key arguments of the order that was processed and `result` recalls important information for updating the current offer. (see [above](#MgvLib/OrderResult))*/
  function makerPosthook(
    MgvLib.SingleOrder calldata order,
    MgvLib.OrderResult calldata result
  ) external;
}

/* # ITaker interface */
interface ITaker {
  /* Inverted mangrove only: call to taker after loans went through */
  function takerTrade(
    address outbound_tkn,
    address inbound_tkn,
    // total amount of outbound_tkn token that was flashloaned to the taker
    uint totalGot,
    // total amount of inbound_tkn token that should be made available
    uint totalGives
  ) external;
}

/* # Monitor interface
If enabled, the monitor receives notification after each offer execution and is read for each pair's `gasprice` and `density`. */
interface IMgvMonitor {
  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external;

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker) external;

  function read(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint gasprice, uint density);
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveModule.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import {AaveV3ModuleStorage as AMS} from "./AaveModuleStorage.sol";
import {AaveV3ModuleImplementation as AMI, IEIP20, IRewardsControllerIsh, IPoolAddressesProvider, ICreditDelegationToken, IPool, IPriceOracleGetter, DataTypes} from "./AaveModuleImplementation.sol";

contract AaveV3Module {
  address private immutable IMPLEMENTATION;
  IPool public immutable POOL;
  IPriceOracleGetter public immutable ORACLE;
  uint public immutable INTEREST_RATE_MODE;
  uint16 public immutable REFERRAL_CODE;

  constructor(
    address _addressesProvider,
    uint _referralCode,
    uint _interestRateMode
  ) {
    REFERRAL_CODE = uint16(_referralCode);
    INTEREST_RATE_MODE = _interestRateMode;

    address _priceOracle = IPoolAddressesProvider(_addressesProvider)
      .getAddress("PRICE_ORACLE");
    address _lendingPool = IPoolAddressesProvider(_addressesProvider).getPool();
    require(_priceOracle != address(0), "AaveModule/0xPriceOracle");
    require(_lendingPool != address(0), "AaveModule/0xPool");

    POOL = IPool(_lendingPool);
    ORACLE = IPriceOracleGetter(_priceOracle);
    IMPLEMENTATION = address(
      new AMI(IPool(_lendingPool), IPriceOracleGetter(_priceOracle))
    );
  }

  /**************************************************************************/
  ///@notice Required functions to let `this` contract interact with Aave
  /**************************************************************************/

  ///@notice approval of overlying contract by the underlying is necessary for minting and repaying borrow
  ///@notice user must use this function to do so.
  function _approveLender(IEIP20 token, uint amount) internal {
    token.approve(address(POOL), amount);
  }

  ///@notice exits markets
  function _exitMarket(IEIP20 underlying) internal {
    POOL.setUserUseReserveAsCollateral(address(underlying), false);
  }

  function _enterMarkets(IEIP20[] calldata underlyings) internal {
    for (uint i = 0; i < underlyings.length; i++) {
      POOL.setUserUseReserveAsCollateral(address(underlyings[i]), true);
    }
  }

  function overlying(IEIP20 asset) public view returns (IEIP20 aToken) {
    aToken = IEIP20(POOL.getReserveData(address(asset)).aTokenAddress);
  }

  function debtToken(IEIP20 asset)
    public
    view
    returns (ICreditDelegationToken debtTkn)
  {
    debtTkn = INTEREST_RATE_MODE == 1
      ? ICreditDelegationToken(
        POOL.getReserveData(address(asset)).stableDebtTokenAddress
      )
      : ICreditDelegationToken(
        POOL.getReserveData(address(asset)).variableDebtTokenAddress
      );
  }

  function _staticdelegatecall(bytes calldata data) external {
    require(msg.sender == address(this), "AaveModule/internalOnly");
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(data);
    if (!success) {
      AMS.revertWithData(retdata);
    }
    assembly {
      return(add(retdata, 32), returndatasize())
    }
  }

  /// @notice Computes maximal maximal redeem capacity (R) and max borrow capacity (B|R) after R has been redeemed
  /// returns (R, B|R)
  function maxGettableUnderlying(
    IEIP20 asset,
    bool tryBorrow,
    address onBehalf
  )
    public
    view
    returns (
      uint maxRedeemableUnderlying,
      uint maxBorrowAfterRedeemInUnderlying
    )
  {
    (bool success, bytes memory retdata) = address(this).staticcall(
      abi.encodeWithSelector(
        this._staticdelegatecall.selector,
        abi.encodeWithSelector(
          AMI.$maxGettableUnderlying.selector,
          asset,
          tryBorrow,
          onBehalf
        )
      )
    );
    if (!success) {
      AMS.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (uint, uint));
    }
  }

  function repayThenDeposit(
    IEIP20 token,
    address onBehalf,
    uint amount
  ) internal {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        AMI.$repayThenDeposit.selector,
        INTEREST_RATE_MODE,
        REFERRAL_CODE,
        token,
        onBehalf,
        amount
      )
    );
    if (!success) {
      AMS.revertWithData(retdata);
    }
  }

  ///@notice redeems liquidity on aave, if not enough liquidity is redeemed, tries to borrow what's missing.
  ///@param token the asset that needs to be redeemed
  ///@param onBehalf the account whose collateral is beeing redeemed and borrowed upon.
  ///@dev if `onBehalf != address(this)` then `this` needs to be approved by `onBehalf` using `ICreditDelegationToken.approveDelegation`
  ///@param amount the target amount of `token` one needs to redeem
  ///@param strict whether call allows contract to redeem more than amount (for gas optimization).
  ///@dev function will only try to borrow if less than `amount` was redeemed and will not try to borrow more than what is missing, even if `strict` is not required.
  ///@dev this is forced by aave v3 currently not allowing to repay a debt that was incurred on the same block (so no gas optim can be used). Repaying on the next block would be dangerous as `onBehalf` position could possibly be liquidated
  ///@param recipient the target address to which redeemed and borrowed tokens should be sent
  function redeemThenBorrow(
    IEIP20 token,
    address onBehalf,
    uint amount,
    bool strict,
    address recipient
  ) internal returns (uint got) {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        AMI.$redeemThenBorrow.selector,
        INTEREST_RATE_MODE,
        REFERRAL_CODE,
        token,
        onBehalf,
        amount,
        strict,
        recipient
      )
    );
    if (success) {
      got = abi.decode(retdata, (uint));
    } else {
      AMS.revertWithData(retdata);
    }
  }

  function _borrow(
    IEIP20 token,
    uint amount,
    address onBehalf
  ) internal {
    POOL.borrow(
      address(token),
      amount,
      INTEREST_RATE_MODE,
      REFERRAL_CODE,
      onBehalf
    );
  }

  function _redeem(
    IEIP20 token,
    uint amount,
    address to
  ) internal returns (uint redeemed) {
    redeemed = (amount == 0) ? 0 : POOL.withdraw(address(token), amount, to);
  }

  function _supply(
    IEIP20 token,
    uint amount,
    address onBehalf
  ) internal {
    if (amount == 0) {
      return;
    } else {
      POOL.supply(address(token), amount, onBehalf, REFERRAL_CODE);
    }
  }

  function _repay(
    IEIP20 token,
    uint amount,
    address onBehalf
  ) internal returns (uint repaid) {
    repaid = (amount == 0)
      ? 0
      : POOL.repay(address(token), amount, INTEREST_RATE_MODE, onBehalf);
  }

  // rewards claiming.
  // may use `SingleUser.withdrawToken` to move collected tokens afterwards
  function _claimRewards(
    IRewardsControllerIsh rewardsController,
    address[] calldata assets
  )
    internal
    returns (address[] memory rewardsList, uint[] memory claimedAmounts)
  {
    (rewardsList, claimedAmounts) = rewardsController.claimAllRewardsToSelf(
      assets
    );
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveModuleImplementation.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import {AaveV3ModuleStorage as AMS, IEIP20, IRewardsControllerIsh, IPoolAddressesProvider, ICreditDelegationToken, IPool, IPriceOracleGetter, DataTypes, RC} from "./AaveModuleStorage.sol";
import "contracts/Strategies/utils/TransferLib.sol";

contract AaveV3ModuleImplementation {
  IPool public immutable POOL;
  IPriceOracleGetter public immutable ORACLE;

  constructor(IPool pool, IPriceOracleGetter oracle) {
    POOL = pool;
    ORACLE = oracle;
  }

  // structs to avoir stack too deep in maxGettableUnderlying
  struct Underlying {
    uint ltv;
    uint liquidationThreshold;
    uint decimals;
    uint price;
  }

  struct Account {
    uint collateral;
    uint debt;
    uint borrowPower;
    uint redeemPower;
    uint ltv;
    uint liquidationThreshold;
    uint health;
    uint balanceOfUnderlying;
  }

  function $maxGettableUnderlying(
    address asset,
    bool tryBorrow,
    address onBehalf
  ) public view returns (uint, uint) {
    Underlying memory underlying; // asset parameters
    Account memory account; // accound parameters
    (
      account.collateral,
      account.debt,
      account.borrowPower, // avgLtv * sumCollateralEth - sumDebtEth
      account.liquidationThreshold,
      account.ltv,
      account.health // avgLiquidityThreshold * sumCollateralEth / sumDebtEth  -- should be less than 10**18
    ) = POOL.getUserAccountData(onBehalf);
    DataTypes.ReserveData memory reserveData = POOL.getReserveData(asset);
    (
      underlying.ltv, // collateral factor for lending
      underlying.liquidationThreshold, // collateral factor for borrowing
      ,
      /*liquidationBonus*/
      underlying.decimals,
      /*reserveFactor*/
      /*emode_category*/
      ,

    ) = RC.getParams(reserveData.configuration);
    account.balanceOfUnderlying = IEIP20(reserveData.aTokenAddress).balanceOf(
      onBehalf
    );

    underlying.price = ORACLE.getAssetPrice(asset); // divided by 10**underlying.decimals

    // account.redeemPower = account.liquidationThreshold * account.collateral - account.debt
    account.redeemPower =
      (account.liquidationThreshold * account.collateral) /
      10**4 -
      account.debt;
    // max redeem capacity = account.redeemPower/ underlying.liquidationThreshold * underlying.price
    // unless account doesn't have enough collateral in asset token (hence the min())

    uint maxRedeemableUnderlying = (account.redeemPower * // in 10**underlying.decimals
      10**(underlying.decimals) *
      10**4) / (underlying.liquidationThreshold * underlying.price);

    maxRedeemableUnderlying = (maxRedeemableUnderlying <
      account.balanceOfUnderlying)
      ? maxRedeemableUnderlying
      : account.balanceOfUnderlying;

    if (!tryBorrow) {
      //gas saver
      return (maxRedeemableUnderlying, 0);
    }
    // computing max borrow capacity on the premisses that maxRedeemableUnderlying has been redeemed.
    // max borrow capacity = (account.borrowPower - (ltv*redeemed)) / underlying.ltv * underlying.price

    uint borrowPowerImpactOfRedeemInUnderlying = (maxRedeemableUnderlying *
      underlying.ltv) / 10**4;

    uint borrowPowerInUnderlying = (account.borrowPower *
      10**underlying.decimals) / underlying.price;

    if (borrowPowerImpactOfRedeemInUnderlying > borrowPowerInUnderlying) {
      // no more borrowPower left after max redeem operation
      return (maxRedeemableUnderlying, 0);
    }

    // max borrow power in underlying after max redeem has been withdrawn
    uint maxBorrowAfterRedeemInUnderlying = borrowPowerInUnderlying -
      borrowPowerImpactOfRedeemInUnderlying;

    return (maxRedeemableUnderlying, maxBorrowAfterRedeemInUnderlying);
  }

  function $repayThenDeposit(
    uint interestRateMode,
    uint referralCode,
    IEIP20 token,
    address onBehalf,
    uint amount
  ) external {
    // AAVE repay/deposit throws if amount == 0
    if (amount == 0) {
      return;
    }
    uint debtOfUnderlying;
    DataTypes.ReserveData memory reserveData = POOL.getReserveData(
      address(token)
    );
    if (interestRateMode == 1) {
      debtOfUnderlying = IEIP20(reserveData.stableDebtTokenAddress).balanceOf(
        address(this)
      );
    } else {
      debtOfUnderlying = IEIP20(reserveData.variableDebtTokenAddress).balanceOf(
          address(this)
        );
    }
    uint toMint = amount;
    if (debtOfUnderlying == 0) {
      toMint = amount;
    } else {
      try
        POOL.repay(address(token), amount, interestRateMode, onBehalf)
      returns (uint repaid) {
        toMint -= repaid;
        if (toMint == 0) {
          return;
        }
      } catch {
        // this may happen in aave v3 (as of July 2022) when trying to repay debt in the block of the borrow
        // toMint == amount
      }
    }
    POOL.supply(address(token), toMint, onBehalf, uint16(referralCode));
  }

  function $redeemThenBorrow(
    uint interestRateMode,
    uint referralCode,
    IEIP20 token,
    address onBehalfOf,
    uint amount,
    bool strict,
    address recipient
  ) external returns (uint) {
    (uint redeemable, uint borrowable_after_redeem) = $maxGettableUnderlying(
      address(token),
      true, // compute borrow power after redeem
      onBehalfOf
    );
    if (strict) {
      redeemable = (redeemable < amount) ? redeemable : amount;
    }
    // `this` contract must have the aToken to withdraw on AAVE
    require(
      TransferLib.transferTokenFrom(
        IEIP20(POOL.getReserveData(address(token)).aTokenAddress),
        onBehalfOf,
        address(this),
        redeemable
      ),
      "AaveModule/redeemThenBorrow/aTknTransferFail"
    );
    // redeemed tokens are direclty transfered to `recipient`
    if (redeemable > 0) {
      POOL.withdraw(address(token), redeemable, recipient);
    }

    if (redeemable >= amount || borrowable_after_redeem == 0) {
      return redeemable;
    } else {
      amount -= redeemable;
      // still missing liquidity to reach target amount
      borrowable_after_redeem = borrowable_after_redeem > amount
        ? amount
        : borrowable_after_redeem;
      POOL.borrow(
        address(token),
        borrowable_after_redeem,
        interestRateMode,
        uint16(referralCode),
        onBehalfOf
      );
      // sending borrowed tokens to `recipient`
      require(
        TransferLib.transferToken(token, recipient, borrowable_after_redeem),
        "AaveModule/redeemThenBorrow/TknTransferFail"
      );
      return redeemable + borrowable_after_redeem;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveModuleStorage.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;
import "./IPool.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {IRewardsControllerIsh} from "./IRewardsControllerIsh.sol";
import {ICreditDelegationToken} from "./ICreditDelegationToken.sol";

import "./IPriceOracleGetter.sol";
import {ReserveConfiguration as RC} from "./ReserveConfiguration.sol";

import "../../../interfaces/IMangrove.sol";
import "../../../interfaces/IEIP20.sol";

library AaveV3ModuleStorage {
  // address of the lendingPool
  // struct Layout {
  // }

  // function get_storage() internal pure returns (Layout storage st) {
  //   bytes32 storagePosition = keccak256(
  //     "Mangrove.AaveV3ModuleStorageLib.Layout"
  //   );
  //   assembly {
  //     st.slot := storagePosition
  //   }
  // }

  function revertWithData(bytes memory retdata) internal pure {
    if (retdata.length == 0) {
      revert("AaveModuleStorage/revertNoReason");
    }
    assembly {
      revert(add(retdata, 32), mload(retdata))
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint data;
  }

  struct UserConfigurationMap {
    /**
     * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
     * The first bit indicates if an asset is used as collateral by the user, the second whether an
     * asset is borrowed by the user.
     */
    uint data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint currScaledVariableDebt;
    uint nextScaledVariableDebt;
    uint currPrincipalStableDebt;
    uint currAvgStableBorrowRate;
    uint currTotalStableDebt;
    uint nextAvgStableBorrowRate;
    uint nextTotalStableDebt;
    uint currLiquidityIndex;
    uint nextLiquidityIndex;
    uint currVariableBorrowIndex;
    uint nextVariableBorrowIndex;
    uint currLiquidityRate;
    uint currVariableBorrowRate;
    uint reserveFactor;
    ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint reservesCount;
    uint debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint amount;
    InterestRateMode interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint maxStableRateBorrowSizePercent;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint amount;
    InterestRateMode interestRateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint amount;
    address to;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint amount;
    uint balanceFromBefore;
    uint balanceToBefore;
    uint reservesCount;
    address oracle;
    uint8 fromEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint[] amounts;
    uint[] interestRateModes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint flashLoanPremiumToProtocol;
    uint flashLoanPremiumTotal;
    uint maxStableRateBorrowSizePercent;
    uint reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint amount;
    bytes params;
    uint16 referralCode;
    uint flashLoanPremiumToProtocol;
    uint flashLoanPremiumTotal;
  }

  struct FlashLoanRepaymentParams {
    uint amount;
    uint totalPremium;
    uint flashLoanPremiumToProtocol;
    address asset;
    address receiverAddress;
    uint16 referralCode;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    ReserveCache reserveCache;
    UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint amount;
    InterestRateMode interestRateMode;
    uint maxStableLoanPercent;
    uint reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    ReserveCache debtReserveCache;
    uint totalDebt;
    uint healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint unbacked;
    uint liquidityAdded;
    uint liquidityTaken;
    uint totalStableDebt;
    uint totalVariableDebt;
    uint averageStableBorrowRate;
    uint reserveFactor;
    address reserve;
    address aToken;
  }

  struct InitReserveParams {
    address asset;
    address aTokenAddress;
    address stableDebtAddress;
    address variableDebtAddress;
    address interestRateStrategyAddress;
    uint16 reservesCount;
    uint16 maxNumberReserves;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
  string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
  string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
  string public constant CALLER_NOT_BRIDGE = "6"; // 'The caller of the function is not a bridge'
  string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
  string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
  string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
  string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
  string public constant CALLER_NOT_ATOKEN = "11"; // 'The caller of the function is not an AToken'
  string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
  string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = "13"; // 'Invalid return value of the flashloan executor function'
  string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
  string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
  string public constant EMODE_CATEGORY_RESERVED = "16"; // 'Zero eMode category is reserved for volatile heterogeneous assets'
  string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT = "17"; // 'Invalid eMode category assignment to asset'
  string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
  string public constant FLASHLOAN_PREMIUM_INVALID = "19"; // 'Invalid flashloan premium'
  string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
  string public constant INVALID_EMODE_CATEGORY_PARAMS = "21"; // 'Invalid risk parameters for the eMode category'
  string public constant BRIDGE_PROTOCOL_FEE_INVALID = "22"; // 'Invalid bridge protocol fee'
  string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
  string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
  string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
  string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
  string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
  string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
  string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
  string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
  string public constant STABLE_BORROWING_NOT_ENABLED = "31"; // 'Stable borrowing is not enabled'
  string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
  string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
  string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
  string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "35"; // 'Health factor is lesser than the liquidation threshold'
  string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
  string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
  string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "38"; // 'The requested amount is greater than the max loan size in stable rate mode'
  string public constant NO_DEBT_OF_SELECTED_TYPE = "39"; // 'For repayment of a specific type of debt, the user needs to have debt that type'
  string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant NO_OUTSTANDING_STABLE_DEBT = "41"; // 'User does not have outstanding stable rate debt on this reserve'
  string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
  string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
  string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
  string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
  string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
  string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
  string public constant SAME_BLOCK_BORROW_REPAY = "48"; // 'Borrow and repay in same block is not allowed'
  string public constant INCONSISTENT_FLASHLOAN_PARAMS = "49"; // 'Inconsistent flashloan parameters'
  string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
  string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
  string public constant UNBACKED_MINT_CAP_EXCEEDED = "52"; // 'Unbacked mint cap is exceeded'
  string public constant DEBT_CEILING_EXCEEDED = "53"; // 'Debt ceiling is exceeded'
  string public constant ATOKEN_SUPPLY_NOT_ZERO = "54"; // 'AToken supply is not zero'
  string public constant STABLE_DEBT_NOT_ZERO = "55"; // 'Stable debt supply is not zero'
  string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
  string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
  string public constant INCONSISTENT_EMODE_CATEGORY = "58"; // 'Inconsistent eMode category'
  string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
  string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION = "60"; // 'Asset is not borrowable in isolation mode'
  string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
  string public constant USER_IN_ISOLATION_MODE = "62"; // 'User is in isolation mode'
  string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
  string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
  string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
  string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
  string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
  string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
  string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
  string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
  string public constant INVALID_EMODE_CATEGORY = "71"; // 'Invalid eMode category for the reserve'
  string public constant INVALID_UNBACKED_MINT_CAP = "72"; // 'Invalid unbacked mint cap for the reserve'
  string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
  string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
  string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
  string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
  string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
  string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
  string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
  string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
  string public constant DEBT_CEILING_NOT_ZERO = "81"; // 'Debt ceiling is not zero'
  string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
  string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
  string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = "84"; // 'Invalid optimal stable to total debt ratio'
  string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
  string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
  string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
  string public constant STABLE_BORROWING_ENABLED = "88"; // 'Stable borrowing is enabled'
  string public constant SILOED_BORROWING_VIOLATION = "89"; // 'User is trying to borrow multiple assets including a siloed one'
  string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title ICreditDelegationToken
 * @author Aave
 * @notice Defines the basic interface for a token supporting credit delegation.
 **/
interface ICreditDelegationToken {
  /**
   * @dev Emitted on `approveDelegation` and `borrowAllowance
   * @param fromUser The address of the delegator
   * @param toUser The address of the delegatee
   * @param asset The address of the delegated asset
   * @param amount The amount being delegated
   */
  event BorrowAllowanceDelegated(
    address indexed fromUser,
    address indexed toUser,
    address indexed asset,
    uint amount
  );

  /**
   * @notice Delegates borrowing power to a user on the specific debt token.
   * Delegation will still respect the liquidation constraints (even if delegated, a
   * delegatee cannot force a delegator HF to go below 1)
   * @param delegatee The address receiving the delegated borrowing power
   * @param amount The maximum amount being delegated.
   **/
  function approveDelegation(address delegatee, uint amount) external;

  /**
   * @notice Returns the borrow allowance of the user
   * @param fromUser The user to giving allowance
   * @param toUser The user to give allowance to
   * @return The current allowance of `toUser`
   **/
  function borrowAllowance(address fromUser, address toUser)
    external
    view
    returns (uint);

  /**
   * @notice Delegates borrowing power to a user on the specific debt token via ERC712 signature
   * @param delegator The delegator of the credit
   * @param delegatee The delegatee that can use the credit
   * @param value The amount to be delegated
   * @param deadline The deadline timestamp, type(uint256).max for max deadline
   * @param v The V signature param
   * @param s The S signature param
   * @param r The R signature param
   */
  function delegationWithSig(
    address delegator,
    address delegatee,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(
    address indexed reserve,
    address indexed backer,
    uint amount,
    uint fee
  );

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(
    address indexed reserve,
    address indexed user,
    address indexed to,
    uint amount
  );

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint amount,
    DataTypes.InterestRateMode interestRateMode,
    uint borrowRate,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  event SwapBorrowRateMode(
    address indexed reserve,
    address indexed user,
    DataTypes.InterestRateMode interestRateMode
  );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(
    address indexed reserve,
    address indexed user
  );

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address initiator,
    address indexed asset,
    uint amount,
    DataTypes.InterestRateMode interestRateMode,
    uint premium,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint debtToCover,
    uint liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint liquidityRate,
    uint stableBorrowRate,
    uint variableBorrowRate,
    uint liquidityIndex,
    uint variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint amount,
    uint fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode,
    uint deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint amount,
    address to
  ) external returns (uint);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint amount,
    uint interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint amount,
    uint interestRateMode,
    address onBehalfOf
  ) external returns (uint);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint amount,
    uint interestRateMode,
    address onBehalfOf,
    uint deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint amount,
    uint interestRateMode
  ) external returns (uint);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
    external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint[] calldata amounts,
    uint[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint totalCollateralBase,
      uint totalDebtBase,
      uint availableBorrowsBase,
      uint currentLiquidationThreshold,
      uint ltv,
      uint healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(
    address asset,
    address rateStrategyAddress
  ) external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(
    address asset,
    DataTypes.ReserveConfigurationMap calldata configuration
  ) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset)
    external
    view
    returns (uint);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset)
    external
    view
    returns (uint);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
  function getReserveData(address asset)
    external
    view
    returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint amount,
    uint balanceFromBefore,
    uint balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(
    uint8 id,
    DataTypes.EModeCategory memory config
  ) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id)
    external
    view
    returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  /**
   * @dev Emitted when the market identifier is updated.
   * @param oldMarketId The old id of the market
   * @param newMarketId The new id of the market
   */
  event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

  /**
   * @dev Emitted when the pool is updated.
   * @param oldAddress The old address of the Pool
   * @param newAddress The new address of the Pool
   */
  event PoolUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the pool configurator is updated.
   * @param oldAddress The old address of the PoolConfigurator
   * @param newAddress The new address of the PoolConfigurator
   */
  event PoolConfiguratorUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the price oracle is updated.
   * @param oldAddress The old address of the PriceOracle
   * @param newAddress The new address of the PriceOracle
   */
  event PriceOracleUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL manager is updated.
   * @param oldAddress The old address of the ACLManager
   * @param newAddress The new address of the ACLManager
   */
  event ACLManagerUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the ACL admin is updated.
   * @param oldAddress The old address of the ACLAdmin
   * @param newAddress The new address of the ACLAdmin
   */
  event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

  /**
   * @dev Emitted when the price oracle sentinel is updated.
   * @param oldAddress The old address of the PriceOracleSentinel
   * @param newAddress The new address of the PriceOracleSentinel
   */
  event PriceOracleSentinelUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the pool data provider is updated.
   * @param oldAddress The old address of the PoolDataProvider
   * @param newAddress The new address of the PoolDataProvider
   */
  event PoolDataProviderUpdated(
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when a new proxy is created.
   * @param id The identifier of the proxy
   * @param proxyAddress The address of the created proxy contract
   * @param implementationAddress The address of the implementation contract
   */
  event ProxyCreated(
    bytes32 indexed id,
    address indexed proxyAddress,
    address indexed implementationAddress
  );

  /**
   * @dev Emitted when a new non-proxied contract address is registered.
   * @param id The identifier of the contract
   * @param oldAddress The address of the old contract
   * @param newAddress The address of the new contract
   */
  event AddressSet(
    bytes32 indexed id,
    address indexed oldAddress,
    address indexed newAddress
  );

  /**
   * @dev Emitted when the implementation of the proxy registered with id is updated
   * @param id The identifier of the contract
   * @param proxyAddress The address of the proxy contract
   * @param oldImplementationAddress The address of the old implementation contract
   * @param newImplementationAddress The address of the new implementation contract
   */
  event AddressSetAsProxy(
    bytes32 indexed id,
    address indexed proxyAddress,
    address oldImplementationAddress,
    address indexed newImplementationAddress
  );

  /**
   * @notice Returns the id of the Aave market to which this contract points to.
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Associates an id with a specific PoolAddressesProvider.
   * @dev This can be used to create an onchain registry of PoolAddressesProviders to
   * identify and validate multiple Aave markets.
   * @param newMarketId The market id
   */
  function setMarketId(string calldata newMarketId) external;

  /**
   * @notice Returns an address by its identifier.
   * @dev The returned address might be an EOA or a contract, potentially proxied
   * @dev It returns ZERO if there is no registered address with the given id
   * @param id The id
   * @return The address of the registered for the specified id
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `newImplementationAddress`.
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param newImplementationAddress The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address newImplementationAddress)
    external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map.
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice Returns the address of the Pool proxy.
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates a proxy
   * setting the new `pool` implementation when the function is called for the first time.
   * @param newPoolImpl The new Pool implementation
   **/
  function setPoolImpl(address newPoolImpl) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy.
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
   * setting the new `PoolConfigurator` implementation when the function is called for the first time.
   * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

  /**
   * @notice Returns the address of the price oracle.
   * @return The address of the PriceOracle
   */
  function getPriceOracle() external view returns (address);

  /**
   * @notice Updates the address of the price oracle.
   * @param newPriceOracle The address of the new PriceOracle
   */
  function setPriceOracle(address newPriceOracle) external;

  /**
   * @notice Returns the address of the ACL manager.
   * @return The address of the ACLManager
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACL manager.
   * @param newAclManager The address of the new ACLManager
   **/
  function setACLManager(address newAclManager) external;

  /**
   * @notice Returns the address of the ACL admin.
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin.
   * @param newAclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address newAclAdmin) external;

  /**
   * @notice Returns the address of the price oracle sentinel.
   * @return The address of the PriceOracleSentinel
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the price oracle sentinel.
   * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address newPriceOracleSentinel) external;

  /**
   * @notice Returns the address of the data provider.
   * @return The address of the DataProvider
   */
  function getPoolDataProvider() external view returns (address);

  /**
   * @notice Updates the address of the data provider.
   * @param newDataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   **/
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   **/
  function BASE_CURRENCY_UNIT() external view returns (uint);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.10;

/**
 * @title adapted from IRewardsController (AAVE V3 periphery contracts)
 * @author Aave
 * @notice Defines the basic interface for a Rewards Controller.
 */
interface IRewardsControllerIsh {
  /**
   * @dev Claims reward for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets List of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint amount,
    address to,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims reward for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The
   * caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint amount,
    address user,
    address to,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param amount The amount of rewards to claim
   * @param reward The address of the reward token
   * @return The amount of rewards claimed
   **/
  function claimRewardsToSelf(
    address[] calldata assets,
    uint amount,
    address reward
  ) external returns (uint);

  /**
   * @dev Claims all rewards for a user to the desired address, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardList"
   **/
  function claimAllRewards(address[] calldata assets, address to)
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);

  /**
   * @dev Claims all rewards for a user on behalf, on all the assets of the pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsOnBehalf(
    address[] calldata assets,
    address user,
    address to
  )
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);

  /**
   * @dev Claims all reward for msg.sender, on all the assets of the pool, accumulating the pending rewards
   * @param assets The list of assets to check eligible distributions before claiming rewards
   * @return rewardsList List of addresses of the reward tokens
   * @return claimedAmounts List that contains the claimed amount per reward, following same order as "rewardsList"
   **/
  function claimAllRewardsToSelf(address[] calldata assets)
    external
    returns (address[] memory rewardsList, uint[] memory claimedAmounts);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 internal constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 internal constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 internal constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SILOED_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 internal constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint internal constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint internal constant IS_FROZEN_START_BIT_POSITION = 57;
  uint internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint internal constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint internal constant IS_PAUSED_START_BIT_POSITION = 60;
  uint internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  uint internal constant SILOED_BORROWING_START_BIT_POSITION = 62;
  /// @dev bit 63 reserved

  uint internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint internal constant BORROW_CAP_START_BIT_POSITION = 80;
  uint internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint internal constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint internal constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint internal constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint internal constant MAX_VALID_LTV = 65535;
  uint internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint internal constant MAX_VALID_DECIMALS = 255;
  uint internal constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint internal constant MAX_VALID_BORROW_CAP = 68719476735;
  uint internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
  uint internal constant MAX_VALID_EMODE_CATEGORY = 255;
  uint internal constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint public constant DEBT_CEILING_DECIMALS = 2;
  uint16 public constant MAX_RESERVES_COUNT = 128;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint ltv)
    internal
    pure
  {
    require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(
    DataTypes.ReserveConfigurationMap memory self,
    uint threshold
  ) internal pure {
    require(
      threshold <= MAX_VALID_LIQUIDATION_THRESHOLD,
      Errors.INVALID_LIQ_THRESHOLD
    );

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint) {
    return
      (self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
      LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(
    DataTypes.ReserveConfigurationMap memory self,
    uint bonus
  ) internal pure {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return
      (self.data & ~LIQUIDATION_BONUS_MASK) >>
      LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(
    DataTypes.ReserveConfigurationMap memory self,
    uint decimals
  ) internal pure {
    require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

    self.data =
      (self.data & DECIMALS_MASK) |
      (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active)
    internal
    pure
  {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen)
    internal
    pure
  {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   **/
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused)
    internal
    pure
  {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   **/
  function getPaused(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed
   * amount will be accumulated in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   **/
  function setBorrowableInIsolation(
    DataTypes.ReserveConfigurationMap memory self,
    bool borrowable
  ) internal pure {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev If the returned flag is true, the asset is borrowable against isolated collateral. Assets borrowed with
   * isolated collateral is accounted for in the isolated collateral's total debt exposure.
   * @dev Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep
   * consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   **/
  function getBorrowableInIsolation(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Sets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @param siloed True if the asset is siloed
   **/
  function setSiloedBorrowing(
    DataTypes.ReserveConfigurationMap memory self,
    bool siloed
  ) internal pure {
    self.data =
      (self.data & SILOED_BORROWING_MASK) |
      (uint(siloed ? 1 : 0) << SILOED_BORROWING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the siloed borrowing flag for the reserve.
   * @dev When this flag is set to true, users borrowing this asset will not be allowed to borrow any other asset.
   * @param self The reserve configuration
   * @return The siloed borrowing flag
   **/
  function getSiloedBorrowing(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~SILOED_BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (bool) {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(
    DataTypes.ReserveConfigurationMap memory self,
    uint reserveFactor
  ) internal pure {
    require(
      reserveFactor <= MAX_VALID_RESERVE_FACTOR,
      Errors.INVALID_RESERVE_FACTOR
    );

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return
      (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   **/
  function setBorrowCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint borrowCap
  ) internal pure {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

    self.data =
      (self.data & BORROW_CAP_MASK) |
      (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   **/
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   **/
  function setSupplyCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint supplyCap
  ) internal pure {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

    self.data =
      (self.data & SUPPLY_CAP_MASK) |
      (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   **/
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   **/
  function setDebtCeiling(
    DataTypes.ReserveConfigurationMap memory self,
    uint ceiling
  ) internal pure {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.INVALID_DEBT_CEILING);

    self.data =
      (self.data & DEBT_CEILING_MASK) |
      (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   **/
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   **/
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   **/
  function getLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self
  ) internal pure returns (uint) {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >>
      LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   **/
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint unbackedMintCap
  ) internal pure {
    require(
      unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP,
      Errors.INVALID_UNBACKED_MINT_CAP
    );

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   **/
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return
      (self.data & ~UNBACKED_MINT_CAP_MASK) >>
      UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   **/
  function setEModeCategory(
    DataTypes.ReserveConfigurationMap memory self,
    uint category
  ) internal pure {
    require(
      category <= MAX_VALID_EMODE_CATEGORY,
      Errors.INVALID_EMODE_CATEGORY
    );

    self.data =
      (self.data & EMODE_CATEGORY_MASK) |
      (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   **/
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint)
  {
    return
      (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing stableRateBorrowing enabled
   * @return The state flag representing paused
   **/
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    uint dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   **/
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint,
      uint,
      uint,
      uint,
      uint,
      uint
    )
  {
    uint dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >>
        LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >>
        LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps parameters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   **/
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint, uint)
  {
    uint dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../utils/AccessControlled.sol";
import {MangroveOfferStorage as MOS} from "./MangroveOfferStorage.sol";
import "../interfaces/IOfferLogic.sol";
import "../interfaces/IMangrove.sol";
import "../interfaces/IEIP20.sol";

// Naming scheme:
// `f() public`: can be used as is in all descendants of `this` contract
// `_f() internal`: descendant of this contract should provide a public wrapper of this function
// `__f__() virtual internal`: descendant of this contract may override this function to specialize the strat

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MangroveOffer is AccessControlled, IOfferLogic {
  // immutable does not impact storage layout
  IMangrove public immutable MGV;
  // `this` contract entypoint is `makerExecute` or `makerPosthook` if `msg.sender == address(MGV)`
  // `this` contract was called on an admin function iff `msg.sender = admin`

  modifier mgvOrAdmin() {
    require(
      msg.sender == admin() || msg.sender == address(MGV),
      "AccessControlled/Invalid"
    );
    _;
  }

  // necessary function to withdraw funds from Mangrove
  receive() external payable virtual {}

  constructor(IMangrove _mgv, uint strat_gasreq) AccessControlled(msg.sender) {
    require(
      strat_gasreq == uint24(strat_gasreq),
      "MangroveOffer/gasreqTooHigh"
    );
    MGV = _mgv;
    MOS.get_storage().ofr_gasreq = strat_gasreq;
  }

  function ofr_gasreq() public view returns (uint) {
    if (has_router()) {
      return MOS.get_storage().ofr_gasreq + router().gas_overhead();
    } else {
      return MOS.get_storage().ofr_gasreq;
    }
  }

  /////// Mandatory callback functions

  // `makerExecute` is the callback function to execute all offers that were posted on Mangrove by `this` contract.
  // it may not be overriden although it can be customized using `__lastLook__`, `__put__` and `__get__` hooks.
  // NB #1: When overriding the above hooks, the Offer Makers should make sure they do not revert in order if they wish to post logs in case of bad executions.
  // NB #2: if `makerExecute` does revert, the offer will be considered to be refusing the trade.
  // NB #3: `makerExecute` must return the empty bytes to signal to MGV it wishes to perform the trade. Any other returned byes will signal to MGV that `this` contract does not wish to proceed with the trade
  // NB #4: Reneging on trade by either reverting or returning non empty bytes will have the following effects:
  // * Offer is removed from the Order Book
  // * Offer bounty will be withdrawn from offer provision and sent to the offer taker. The remaining provision will be credited to the maker account on Mangrove
  function makerExecute(ML.SingleOrder calldata order)
    external
    override
    onlyCaller(address(MGV))
    returns (bytes32 ret)
  {
    if (!__lastLook__(order)) {
      // hook to check order details and decide whether `this` contract should renege on the offer.
      revert("mgvOffer/abort/reneged");
    }
    if (__put__(order.gives, order) > 0) {
      revert("mgvOffer/abort/putFailed");
    }
    if (__get__(order.wants, order) > 0) {
      revert("mgvOffer/abort/getFailed");
    }
    return ret;
  }

  // `makerPosthook` is the callback function that is called by Mangrove *after* the offer execution.
  // It may not be overriden although it can be customized via the post-hooks `__posthookSuccess__` and `__posthookFallback__` (see below).
  // Offer Maker SHOULD make sure the overriden posthooks do not revert in order to be able to post logs in case of bad executions.
  function makerPosthook(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) external override onlyCaller(address(MGV)) {
    if (result.mgvData == "mgv/tradeSuccess") {
      // toplevel posthook may ignore returned value which is only usefull for (vertical) compositionality
      __posthookSuccess__(order);
    } else {
      emit LogIncident(
        MGV,
        IEIP20(order.outbound_tkn),
        IEIP20(order.inbound_tkn),
        order.offerId,
        result.makerData
      );
      __posthookFallback__(order, result);
    }
  }

  // sets default gasreq for `new/updateOffer`
  function set_gasreq(uint gasreq) public override mgvOrAdmin {
    require(uint24(gasreq) == gasreq, "mgvOffer/gasreq/overflow");
    MOS.get_storage().ofr_gasreq = gasreq;
    emit SetGasreq(gasreq);
  }

  /** Sets the account from which base (resp. quote) tokens need to be fetched or put during trade execution*/
  /** */
  /** NB Router might need further approval to work as intended*/
  function set_router(AbstractRouter router_) public override mgvOrAdmin {
    require(address(router_) != address(0), "mgvOffer/set_router/0xRouter");
    MOS.get_storage().router = router_;
    router_.bind(address(this));
    emit SetRouter(router_);
  }

  // maker contract need to approve router for reserve push and pull
  function approveRouter(IEIP20 token) public {
    require(
      token.approve(address(router()), type(uint).max),
      "mgvOffer/approveRouter/Fail"
    );
  }

  function has_router() public view returns (bool) {
    return address(MOS.get_storage().router) != address(0);
  }

  function router() public view returns (AbstractRouter) {
    AbstractRouter router_ = MOS.get_storage().router;
    require(address(router_) != address(0), "mgvOffer/0xRouter");
    return router_;
  }

  /// `this` contract needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  /// NB if anyone can call this function someone could reset it to 0 for griefing
  function approveMangrove(IEIP20 outbound_tkn) public {
    require(
      outbound_tkn.approve(address(MGV), type(uint).max),
      "mgvOffer/approveMangrove/Fail"
    );
  }

  ///@notice withdraws ETH from the provision account on Mangrove and sends collected WEIs to `receiver`
  ///@dev for multi user strats, the contract provision account on Mangrove is pooled amongst offer owners so admin should only call this function to recover WEIs (e.g. that were erroneously transferred to Mangrove using `MGV.fund()`)
  /// This contract's balance on Mangrove may contain deprovisioned WEIs after an offer has failed (complement between provision and the bounty that was sent to taker)
  /// those free WEIs can be retrieved by offer owners by calling `retractOffer` with the `deprovsion` flag. Not by calling this function which is admin only.

  function withdrawFromMangrove(uint amount, address payable receiver)
    external
    onlyAdmin
  {
    if (amount == type(uint).max) {
      amount = MGV.balanceOf(address(this));
      if (amount == 0) {
        return; // optim
      }
    }
    require(MGV.withdraw(amount), "mgvOffer/withdrawFromMgv/withdrawFail");
    (bool noRevert, ) = receiver.call{value: amount}("");
    require(noRevert, "mgvOffer/withdrawFromMgv/payableCallFail");
  }

  ////// Default Customizable hooks for Taker Order'execution

  // Define this hook to describe where the inbound token, which are brought by the Offer Taker, should go during Taker Order's execution.
  // Usage of this hook is the following:
  // * `amount` is the amount of `inbound` tokens whose deposit location is to be defined when entering this function
  // * `order` is a recall of the taker order that is at the origin of the current trade.
  // * Function must return `missingPut` (<=`amount`), which is the amount of `inbound` tokens whose deposit location has not been decided (possibly because of a failure) during this function execution
  // NB in case of preceding executions of descendant specific `__put__` implementations, `amount` might be lower than `order.gives` (how much `inbound` tokens the taker gave)
  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint missingPut);

  // Define this hook to implement fetching `amount` of outbound tokens, possibly from another source than `this` contract during Taker Order's execution.
  // Usage of this hook is the following:
  // * `amount` is the amount of `outbound` tokens that still needs to be brought to the balance of `this` contract when entering this function
  // * `order` is a recall of the taker order that is at the origin of the current trade.
  // * Function must return `missingGet` (<=`amount`), which is the amount of `outbound` tokens still need to be fetched at the end of this function
  // NB in case of preceding executions of descendant specific `__get__` implementations, `amount` might be lower than `order.wants` (how much `outbound` tokens the taker wants)
  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint missingGet);

  // Override this hook to implement a last look check during Taker Order's execution.
  // Return value should be `true` if Taker Order is acceptable.
  // Returning `false` will cause `MakerExecute` to return the "RENEGED" bytes, which are interpreted by MGV as a signal that `this` contract wishes to cancel the trade
  function __lastLook__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (bool proceed)
  {
    order; //shh
    proceed = true;
  }

  //utils
  function $(IEIP20 token) internal pure returns (address) {
    return address(token);
  }

  // Override this post-hook to implement fallback behavior when Taker Order's execution failed unexpectedly. Information from Mangrove is accessible in `result.mgvData` for logging purpose.
  function __posthookFallback__(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) internal virtual returns (bool success) {
    order;
    result;
    return true;
  }

  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (bool)
  {
    order;
    return true;
  }

  // returns missing provision to repost `offerId` at given `gasreq` and `gasprice`
  // if `offerId` is not in the Order Book, will simply return how much is needed to post
  // NB in the case of a multi user contract, this function does not take into account a potential partition of the provision of `this` amongst offer owners
  function getMissingProvision(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint gasreq, // give > type(uint24).max to use `this.ofr_gasreq()`
    uint gasprice, // give 0 to use Mangrove's gasprice
    uint offerId // set this to 0 if one is not reposting an offer
  ) public view returns (uint) {
    (P.Global.t globalData, P.Local.t localData) = MGV.config(
      $(outbound_tkn),
      $(inbound_tkn)
    );
    P.OfferDetail.t offerDetailData = MGV.offerDetails(
      $(outbound_tkn),
      $(inbound_tkn),
      offerId
    );
    uint _gp;
    if (globalData.gasprice() > gasprice) {
      _gp = globalData.gasprice();
    } else {
      _gp = gasprice;
    }
    if (gasreq >= type(uint24).max) {
      gasreq = ofr_gasreq(); // this includes overhead of router if any
    }
    uint bounty = (gasreq + localData.offer_gasbase()) * _gp * 10**9; // in WEI
    // if `offerId` is not in the OfferList, all returned values will be 0
    uint currentProvisionLocked = (offerDetailData.gasreq() +
      offerDetailData.offer_gasbase()) *
      offerDetailData.gasprice() *
      10**9;
    uint currentProvision = currentProvisionLocked +
      MGV.balanceOf(address(this));
    return (currentProvision >= bounty ? 0 : bounty - currentProvision);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "contracts/Strategies/Routers/AbstractRouter.sol";

// Naming scheme:
// `f() public`: can be used as is in all descendants of `this` contract
// `_f() internal`: descendant of this contract should provide a public wrapper of this function
// `__f__() virtual internal`: descendant of this contract may override this function to specialize the strat

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
library MangroveOfferStorage {
  struct Layout {
    // default values
    uint ofr_gasreq;
    AbstractRouter router;
  }

  function get_storage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.MangroveOfferStorage");
    assembly {
      st.slot := storagePosition
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AdvancedCompoundRetail.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../Persistent.sol";
import "contracts/Strategies/Routers/AaveDeepRouter.sol";

contract OfferProxy is MultiUserPersistent {
  constructor(
    address _addressesProvider,
    IMangrove _MGV,
    address deployer
  )
    MultiUserPersistent(_MGV, new AaveDeepRouter(_addressesProvider, 0, 2), 50_000)
  {
    router().setAdmin(deployer);
    if (deployer != msg.sender) {
      setAdmin(deployer);
    }
  }

  function aaveRouter() internal view returns (AaveDeepRouter) {
    return AaveDeepRouter(address(router()));
  }

  function approveLender(IEIP20 token) external {
    aaveRouter().approveLender(token);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../MangroveOffer.sol";
import "../../../periphery/MgvReader.sol";
import "../../interfaces/IOfferLogicMulti.sol";

abstract contract MultiUser is IOfferLogicMulti, MangroveOffer {
  struct OfferData {
    // offer owner address
    address owner;
    // under approx of the portion of this contract's balance on mangrove
    // that can be returned to the user's reserve when this offer is deprovisioned
    uint96 wei_balance;
  }

  ///@dev outbound_tkn => inbound_tkn => offerId => OfferData
  mapping(IEIP20 => mapping(IEIP20 => mapping(uint => OfferData)))
    internal offerData;

  constructor(
    IMangrove _mgv,
    AbstractRouter _router,
    uint strat_gasreq
  ) MangroveOffer(_mgv, strat_gasreq) {
    require(address(_router) != address(0), "MultiUser/0xRouter");
    // define `_router` as the liquidity router for `this` and declare that `this` is allowed to call router.
    // NB router also needs to be approved for outbound/inbound token transfers by each user of this contract.
    set_router(_router);
  }

  /// @param offerIds an array of offer ids from the `outbound_tkn, inbound_tkn` offer list
  /// @return _offerOwners an array of the same length where the address at position i is the owner of `offerIds[i]`
  function offerOwners(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint[] calldata offerIds
  ) public view override returns (address[] memory _offerOwners) {
    _offerOwners = new address[](offerIds.length);
    for (uint i = 0; i < offerIds.length; i++) {
      _offerOwners[i] = ownerOf(outbound_tkn, inbound_tkn, offerIds[i]);
    }
  }

  /// @notice assigns an `owner` to `offerId`  on the `(outbound_tkn, inbound_tkn)` offer list
  function addOwner(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint offerId,
    address owner
  ) internal {
    offerData[outbound_tkn][inbound_tkn][offerId] = OfferData({
      owner: owner,
      wei_balance: uint96(0)
    });
    emit NewOwnedOffer(MGV, outbound_tkn, inbound_tkn, offerId, owner);
  }

  /// @param gasreq the gas required by the offer
  /// @param provision the amount of native token one is using to provision the offer
  /// @return gasprice that the `provision` can cover for
  /// @dev the returned gasprice is slightly lower than the real gasprice that the provision can cover because of the rouding error due to division
  function derive_gasprice(
    uint gasreq,
    uint provision,
    uint offer_gasbase
  ) internal pure returns (uint gasprice) {
    uint num = (offer_gasbase + gasreq) * 10**9;
    // pre-check to avoir underflow
    require(provision >= num, "MultiUser/derive_gasprice/NotEnoughProvision");
    unchecked {
      gasprice = provision / num;
    }
  }

  function ownerOf(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint offerId
  ) public view override returns (address owner) {
    owner = offerData[outbound_tkn][inbound_tkn][offerId].owner;
    require(owner != address(0), "multiUser/unkownOffer");
  }

  // splitting newOffer into external/internal in order to let internal calls specify who the owner of the newly created offer should be.
  // in case `newOffer` is being called during `makerExecute` or `posthook` calls.
  function newOffer(MakerOrder calldata mko)
    external
    payable
    override
    returns (uint offerId)
  {
    offerId = newOfferInternal(mko, msg.sender, msg.value);
  }

  function newOfferInternal(
    MakerOrder memory mko,
    address owner,
    uint provision
  ) internal returns (uint) {
    (P.Global.t global, P.Local.t local) = MGV.config(
      address(mko.outbound_tkn),
      address(mko.inbound_tkn)
    );
    // convention for default gasreq value
    mko.gasreq = (mko.gasreq > type(uint24).max) ? ofr_gasreq() : mko.gasreq;
    // computing gasprice implied by offer provision
    mko.gasprice = derive_gasprice(
      mko.gasreq,
      provision,
      local.offer_gasbase()
    );
    // mangrove will take max(`mko.gasprice`, `global.gasprice`)
    // if `mko.gapsrice < global.gasprice` Mangrove will use availble provision of this contract to provision the offer
    // this would potentially take native tokens that have been released after some offer managed by this contract have failed
    // so one needs to make sure here that only provision of this call will be used to provision the offer on mangrove
    require(
      mko.gasprice >= global.gasprice(),
      "MultiUser/newOffer/NotEnoughProvision"
    );

    // this call cannot revert for lack of provision (by design)
    mko.offerId = MGV.newOffer{value: provision}(
      $(mko.outbound_tkn),
      $(mko.inbound_tkn),
      mko.wants,
      mko.gives,
      mko.gasreq,
      mko.gasprice,
      mko.pivotId
    );
    //setting owner of offerId
    addOwner(mko.outbound_tkn, mko.inbound_tkn, mko.offerId, owner);
    return mko.offerId;
  }

  ///@notice update offer with parameters given in `mko`.
  ///@dev mko.gasreq == max_int indicates one wishes to use ofr_gasreq (default value)
  ///@dev mko.gasprice is overriden by the value computed by taking into account :
  /// * value transfered on current tx
  /// * if offer was deprovisioned after a fail, amount of wei (still on this contract balance on Mangrove) that should be counted as offer owner's
  /// * if offer is still live, its current locked provision
  function updateOffer(MakerOrder calldata mko) external payable {
    require(updateOfferInternal(mko, msg.value), "MultiUser/updateOfferFail");
  }

  // mko.gasprice is ignored (should be 0) because it needs to be derived from provision of the offer
  // not doing this would allow a user to submit an `new/updateOffer` underprovisioned for the announced gasprice
  // Mangrove would then erroneously take missing WEIs in `this` contract free balance (possibly coming from uncollected deprovisioned offers after a fail).
  // need to treat 2 cases:
  // * if offer is deprovisioned one needs to use msg.value and `offerData.wei_balance` to derive gasprice (deprovioning sets offer.gasprice to 0)
  // * if offer is still live one should compute its currenlty locked provision $P$ and derive gasprice based on msg.value + $P$ (note if msg.value = 0 offer can be reposted with offer.gasprice)

  struct UpdateData {
    P.Global.t global;
    P.Local.t local;
    P.OfferDetail.t offer_detail;
    uint provision;
  }

  function updateOfferInternal(MakerOrder memory mko, uint value)
    internal
    returns (bool)
  {
    OfferData memory od = offerData[mko.outbound_tkn][mko.inbound_tkn][
      mko.offerId
    ];
    UpdateData memory upd;
    require(
      msg.sender == od.owner || msg.sender == address(MGV),
      "Multi/updateOffer/unauthorized"
    );

    upd.offer_detail = MGV.offerDetails(
      $(mko.outbound_tkn),
      $(mko.inbound_tkn),
      mko.offerId
    );
    (upd.global, upd.local) = MGV.config(
      $(mko.outbound_tkn),
      $(mko.inbound_tkn)
    );
    upd.provision = value;
    // if `od.free_wei` > 0 then `this` contract has a free wei balance >= `od.free_wei`.
    // Gasprice must take this into account because Mangrove will pull into available WEIs if gasprice requires it.
    mko.gasreq = (mko.gasreq > type(uint24).max) ? ofr_gasreq() : mko.gasreq;
    mko.gasprice = upd.offer_detail.gasprice(); // 0 if offer is deprovisioned

    if (mko.gasprice == 0) {
      // offer was previously deprovisioned, we add the portion of this contract WEI pool on Mangrove that belongs to this offer (if any)
      if (od.wei_balance > 0) {
        upd.provision += od.wei_balance;
        offerData[mko.outbound_tkn][mko.inbound_tkn][mko.offerId] = OfferData({
          owner: od.owner,
          wei_balance: 0
        });
      }
      // gasprice for this offer will be computed using msg.value and available funds on Mangrove attributed to `offerId`'s owner
      mko.gasprice = derive_gasprice(
        mko.gasreq,
        upd.provision,
        upd.local.offer_gasbase()
      );
    } else {
      // offer is still provisioned as offer.gasprice requires
      if (value > 0) {
        // caller wishes to add provision to existing provision
        // we retrieve current offer provision based on upd.gasprice (which is current offer gasprice)
        upd.provision +=
          mko.gasprice *
          10**9 *
          (upd.offer_detail.gasreq() + upd.local.offer_gasbase());
        mko.gasprice = derive_gasprice(
          mko.gasreq,
          upd.provision,
          upd.local.offer_gasbase()
        );
      }
      // if value == 0  we keep upd.gasprice unchanged
    }
    require(
      mko.gasprice >= upd.global.gasprice(),
      "MultiUser/updateOffer/NotEnoughProvision"
    );
    try
      MGV.updateOffer{value: value}(
        $(mko.outbound_tkn),
        $(mko.inbound_tkn),
        mko.wants,
        mko.gives,
        mko.gasreq,
        mko.gasprice,
        mko.pivotId,
        mko.offerId
      )
    {
      return true;
    } catch {
      return false;
    }
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove. Function call will throw if `this` contract is not the owner of `offerId`.
  ///@param deprovision is true if offer owner wishes to have the offer's provision pushed to its reserve
  function retractOffer(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) public override returns (uint free_wei) {
    OfferData memory od = offerData[outbound_tkn][inbound_tkn][offerId];
    require(
      od.owner == msg.sender || address(MGV) == msg.sender,
      "Multi/retractOffer/unauthorized"
    );
    if (od.wei_balance > 0) {
      // offer was already retracted and deprovisioned by Mangrove after a trade failure
      // wei_balance is part of this contract's pooled free wei and can be redeemed by offer owner
      free_wei = deprovision ? od.wei_balance : 0;
    } else {
      free_wei = MGV.retractOffer(
        $(outbound_tkn),
        $(inbound_tkn),
        offerId,
        deprovision
      );
    }
    if (free_wei > 0) {
      // pulling free wei from Mangrove to `this`
      require(MGV.withdraw(free_wei), "MultiUser/withdrawFail");
      // resetting pending returned provision
      offerData[outbound_tkn][inbound_tkn][offerId] = OfferData({
        owner: od.owner,
        wei_balance: 0
      });
      // letting router decide what it should do with owner's free wei
       (bool noRevert, ) = msg.sender.call{value: free_wei}("");
       require(noRevert, "MultiUser/weiTransferFail");
    }
  }

  // NB anyone can call but msg.sender will only be able to withdraw from its reserve
  function withdrawToken(
    IEIP20 token,
    address receiver,
    uint amount
  ) external override returns (bool success) {
    require(receiver != address(0), "MultiUser/withdrawToken/0xReceiver");
    return router().withdrawToken(token, msg.sender, receiver, amount);
  }

  function tokenBalance(IEIP20 token) external view override returns (uint) {
    return router().reserveBalance(token, msg.sender);
  }

  // put received inbound tokens on offer owner reserve
  // if nothing is done at that stage then it could still be done in the posthook but it cannot be a flush
  // since `this` contract balance would have the accumulated takers inbound tokens
  // here we make sure nothing remains unassigned after a trade
  function __put__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    IEIP20 outTkn = IEIP20(order.outbound_tkn);
    IEIP20 inTkn = IEIP20(order.inbound_tkn);
    address owner = ownerOf(outTkn, inTkn, order.offerId);
    router().push(inTkn, owner, amount);
    return 0;
  }

  // get outbound tokens from offer owner reserve
  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    IEIP20 outTkn = IEIP20(order.outbound_tkn);
    IEIP20 inTkn = IEIP20(order.inbound_tkn);
    address owner = ownerOf(outTkn, inTkn, order.offerId);
    // telling router one is requiring `amount` of `outTkn` for `owner`.
    // because `pull` is strict, `pulled <= amount` (cannot be greater)
    // we do not check local balance here because multi user contracts do not keep more balance than what has been pulled
    uint pulled = router().pull(outTkn, owner, amount, true);
    return amount - pulled;
  }

  // if offer failed to execute or reneged Mangrove has deprovisioned it
  // the wei balance of `this` contract on Mangrove is now positive
  // this fallback returns an under approx of the provision that has been returned to this contract
  // being under approx implies `this` contract might accumulate a small amount of wei over time
  function __posthookFallback__(
    ML.SingleOrder calldata order,
    ML.OrderResult calldata result
  ) internal virtual override returns (bool success) {
    result; // ssh
    IEIP20 outTkn = IEIP20(order.outbound_tkn);
    IEIP20 inTkn = IEIP20(order.inbound_tkn);
    OfferData memory od = offerData[outTkn][inTkn][order.offerId];
    // NB if several offers of `this` contract have failed during the market order, the balance of this contract on Mangrove will contain cumulated free provision

    // computing an under approximation of returned provision because of this offer's failure
    (P.Global.t global, P.Local.t local) = MGV.config(
      order.outbound_tkn,
      order.inbound_tkn
    );
    uint gaspriceInWei = global.gasprice() * 10**9;
    uint provision = 10**9 *
      order.offerDetail.gasprice() *
      (order.offerDetail.gasreq() + order.offerDetail.offer_gasbase());

    // gas estimate to complete posthook ~ 1500, putting 3000 to be overapproximating
    uint approxBounty = (order.offerDetail.gasreq() -
      gasleft() +
      3000 +
      local.offer_gasbase()) * gaspriceInWei;

    uint approxReturnedProvision = approxBounty >= provision
      ? 0
      : provision - approxBounty;

    // storing the portion of this contract's balance on Mangrove that should be attributed back to the failing offer's owner
    // those free WEIs can be retrieved by offer owner, by calling `retractOffer` with the `deprovision` flag.
    offerData[outTkn][inTkn][order.offerId] = OfferData({
      owner: od.owner,
      wei_balance: uint96(approxReturnedProvision) // previous wei_balance is always 0 here: if offer failed in the past, `updateOffer` did reuse it
    });
    success = true;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MultiUser.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract MultiUserPersistent is MultiUser {
  constructor(
    IMangrove _mgv,
    AbstractRouter _router,
    uint gasreq
  ) MultiUser(_mgv, _router, gasreq) {}

  function __residualWants__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.wants() - order.gives;
  }

  function __residualGives__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.gives() - order.wants;
  }

  ///@dev posthook takes care of reposting offer residual
  ///@param order is a reminder of the taker order that was processed during `makerExecute`
  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    uint new_gives = __residualGives__(order);
    uint new_wants = __residualWants__(order);
    if (new_gives == 0) {
      // gas saving
      return true;
    }
    // if updateOffer fails offer will be retracted
    return
      updateOfferInternal(
        MakerOrder({
          outbound_tkn: IEIP20(order.outbound_tkn),
          inbound_tkn: IEIP20(order.inbound_tkn),
          wants: new_wants,
          gives: new_gives,
          gasreq: order.offerDetail.gasreq(), // keeping the same gasreq
          gasprice: order.offerDetail.gasprice(), // keeping the same gasprice
          pivotId: order.offer.next(), // best guess for pivotId
          offerId: order.offerId
        }),
        0 // no value
      );
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveDeepRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import "./AaveRouter.sol";

// Underlying on AAVE
// Overlying on reserve
// `this` must approve Lender for outbound token transfer (pull)
// `this` must approve Lender for inbound token transfer (flush)
// `this` must be approved by reserve for *overlying* of inbound token transfer
// `this` must be approved by maker contract for outbound token transfer

contract AaveDeepRouter is AaveRouter {
  constructor(
    address _addressesProvider,
    uint _referralCode,
    uint _interestRateMode
  ) AaveRouter(_addressesProvider, _referralCode, _interestRateMode) {
    gas_overhead += 350_000; // additional borrow
  }

  // 1. pulls aTokens from aToken reserve. Borrows if necessary
  // 2. redeems underlying on AAVE and forwards received tokens to maker contract
  function __pull__(
    IEIP20 token,
    address reserve,
    address maker,
    uint amount,
    bool strict
  ) internal virtual override returns (uint pulled) {
    return redeemThenBorrow(token, reserve, amount, strict, maker);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AaveRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import "contracts/Strategies/Modules/aave/v3/AaveModule.sol";
import "contracts/Strategies/utils/AccessControlled.sol";
import "contracts/Strategies/utils/TransferLib.sol";
import "./AbstractRouter.sol";

// Underlying on AAVE
// Overlying on reserve
// `this` must approve Lender for outbound token transfer (pull)
// `this` must approve Lender for inbound token transfer (flush)
// `this` must be approved by reserve for *overlying* of inbound token transfer
// `this` must be approved by maker contract for outbound token transfer

// gas overhead:
// - supply ~ 250K
// - borrow ~ 360K
contract AaveRouter is AbstractRouter, AaveV3Module {
  constructor(
    address _addressesProvider,
    uint _referralCode,
    uint _interestRateMode
  )
    AaveV3Module(_addressesProvider, _referralCode, _interestRateMode)
    AbstractRouter(700_000)
  {}

  // 1. pulls aTokens from reserve
  // 2. redeems underlying on AAVE to calling maker contract
  function __pull__(
    IEIP20 token,
    address reserve,
    address maker,
    uint amount,
    bool strict
  ) internal virtual override returns (uint pulled) {
    uint available = reserveBalance(token, reserve);
    // if strict enable one should pull at most `amount` from reserve
    if (strict) {
      amount = amount < available ? amount : available;
    } else {
      // one is pulling all availble funds from reserve
      amount = available;
    }
    // transfer below is a noop (almost 0 gas) if reserve == address(this)
    // needs to temporarily deposit tokens to `this` in order to be able to redeem to maker contract
    TransferLib.transferTokenFrom(
      overlying(token),
      reserve,
      address(this),
      amount
    );
    // redeem below is a noop if amount_ == 0
    return _redeem(token, amount, maker);
  }

  // Liquidity : MAKER --> `onBehalf`
  function __push__(
    IEIP20 token,
    address reserve,
    address maker,
    uint amount
  ) internal virtual override {
    require(
      TransferLib.transferTokenFrom(token, maker, address(this), amount),
      "AaveRouter/push/transferFail"
    );
    // repay and supply on behalf of `reserve`
    repayThenDeposit(token, reserve, amount);
  }

  // returns 0 if redeem failed (amount > balance).
  // Redeems user balance if amount == type(uint).max
  function __withdrawToken__(
    IEIP20 token,
    address reserve,
    address to,
    uint amount
  ) internal override returns (bool) {
    // note there is no possible redeem on behalf
    require(
      TransferLib.transferTokenFrom(
        overlying(token),
        reserve,
        address(this),
        amount
      ),
      "AaveRouter/supply/transferFromFail"
    );
    require(
      _redeem(token, amount, to) == amount,
      "AaveRouter/withdrawToken/Fail"
    );
    return true;
  }

  // Admin function to manage position on AAVE
  function borrow(
    IEIP20 token,
    address reserve,
    uint amount,
    address to
  ) external onlyAdmin {
    // NB if `reserve` != this, it must approve this router for increasing overlying debt token
    _borrow(token, amount, reserve);
    require(
      TransferLib.transferToken(token, to, amount),
      "AaveRouter/borrow/transferFail"
    );
  }

  function repay(
    IEIP20 token,
    address reserve,
    uint amount,
    address from
  ) external onlyAdmin {
    require(
      TransferLib.transferTokenFrom(token, from, reserve, amount),
      "AaveRouter/repay/transferFromFail"
    );
    _repay(token, amount, reserve);
  }

  function supply(
    IEIP20 token,
    address reserve,
    uint amount,
    address from
  ) external onlyAdmin {
    require(
      TransferLib.transferTokenFrom(token, from, reserve, amount),
      "AaveRouter/supply/transferFromFail"
    );
    _supply(token, amount, reserve);
  }

  function claimRewards(
    IRewardsControllerIsh rewardsController,
    address[] calldata assets
  )
    external
    onlyAdmin
    returns (address[] memory rewardsList, uint[] memory claimedAmounts)
  {
    return _claimRewards(rewardsController, assets);
  }

  function reserveBalance(IEIP20 token, address reserve)
    public
    view
    virtual
    override
    returns (uint available)
  {
    (available, ) = maxGettableUnderlying(token, false, reserve);
  }

  function approveLender(IEIP20 token) external {
    _approveLender(token, type(uint).max);
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//ITreasury.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import "contracts/Strategies/interfaces/IEIP20.sol";
import "contracts/Strategies/utils/AccessControlled.sol";

abstract contract AbstractRouter is AccessControlled {
  mapping(address => bool) public makers;
  uint public gas_overhead;

  modifier onlyMakers() {
    require(makers[msg.sender], "Router/unauthorized");
    _;
  }
  modifier makersOrAdmin() {
    require(msg.sender == admin() || makers[msg.sender], "Router/unauthorized");
    _;
  }

  constructor(uint overhead) AccessControlled(msg.sender) {
    require(uint24(overhead) == overhead, "AbstractRouter/overheadTooHigh");
    gas_overhead = overhead;
  }

  // pulls `amount` of `token`s from reserve to maker contract's balance if necessary
  // `reserve` is typically an EOA (for nice UX), the router contract itself (to minimize fragmentation when router is bound to several makers)
  // or the Maker contract (to minimize transfer costs)
  function pull(
    IEIP20 token,
    address reserve,
    uint amount,
    bool strict
  ) external onlyMakers returns (uint pulled) {
    uint buffer = token.balanceOf(msg.sender);
    if (buffer >= amount) {
      return 0;
    } else {
      pulled = __pull__({
        token: token,
        reserve: reserve,
        maker: msg.sender,
        amount: amount,
        strict: strict
      });
    }
  }

  function __pull__(
    IEIP20 token,
    address reserve,
    address maker,
    uint amount,
    bool strict
  ) internal virtual returns (uint);

  // pushes `amount` of `token`s from maker contract to reserve
  function push(
    IEIP20 token,
    address reserve,
    uint amount
  ) external onlyMakers {
    __push__({
      token: token,
      reserve: reserve,
      maker: msg.sender,
      amount: amount
    });
  }

  function __push__(
    IEIP20 token,
    address reserve,
    address maker,
    uint amount
  ) internal virtual;

  function flush(IEIP20[] calldata tokens, address reserve)
    external
    onlyMakers
  {
    for (uint i = 0; i < tokens.length; i++) {
      uint amount = tokens[i].balanceOf(msg.sender);
      if (amount > 0) {
        __push__(tokens[i], reserve, msg.sender, amount);
      }
    }
  }

  // checks amount of `token`s available in the liquidity source
  function reserveBalance(IEIP20 token, address reserve)
    external
    view
    virtual
    returns (uint);

  // withdraws `amount` of reserve tokens and sends them to `recipient`
  function withdrawToken(
    IEIP20 token,
    address reserve,
    address recipient,
    uint amount
  ) public onlyMakers returns (bool) {
    return __withdrawToken__(token, reserve, recipient, amount);
  }

  function __withdrawToken__(
    IEIP20 token,
    address reserve,
    address to,
    uint amount
  ) internal virtual returns (bool);

  // connect a maker contract to this router
  // if maker contract is `this` router's deployer, it will do so using admin privilege
  // if `this` router was deployed independently of maker contract, binding must be done by router's deployer
  function bind(address maker) public makersOrAdmin {
    makers[maker] = true;
  }

  function unbind(address maker) public makersOrAdmin {
    makers[maker] = false;
  }
}

// SPDX-License-Identifier: Unlicense

// IERC20.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* `MgvLib` contains data structures returned by external calls to Mangrove and the interfaces it uses for its own external calls. */

pragma solidity ^0.8.10;
pragma abicoder v2;

interface IEIP20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  function symbol() external view returns (string memory);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);

  /// for wETH contract
  function deposit() external payable;

  function withdraw(uint) external;

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.2. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import {MgvLib as ML, P, IMaker} from "../../MgvLib.sol";

interface IMangrove {
  event Approval(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address owner,
    address spender,
    uint value
  );
  event Credit(address indexed maker, uint amount);
  event Debit(address indexed maker, uint amount);
  event Kill();
  event NewMgv();
  event OfferFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives,
    bytes32 mgvData
  );
  event OfferRetract(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id
  );
  event OfferSuccess(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint id,
    address taker,
    uint takerWants,
    uint takerGives
  );
  event OfferWrite(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address maker,
    uint wants,
    uint gives,
    uint gasprice,
    uint gasreq,
    uint id,
    uint prev
  );
  event OrderComplete(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    address indexed taker,
    uint takerGot,
    uint takerGave,
    uint penalty
  );
  event OrderStart();
  event PosthookFail(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offerId
  );
  event SetActive(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    bool value
  );
  event SetDensity(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetFee(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint value
  );
  event SetGasbase(
    address indexed outbound_tkn,
    address indexed inbound_tkn,
    uint offer_gasbase
  );
  event SetGasmax(uint value);
  event SetGasprice(uint value);
  event SetGovernance(address value);
  event SetMonitor(address value);
  event SetNotify(bool value);
  event SetUseOracle(bool value);
  event SetVault(address value);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint offer_gasbase
  ) external;

  function allowances(
    address,
    address,
    address,
    address
  ) external view returns (uint);

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool);

  function balanceOf(address) external view returns (uint);

  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint);

  function config(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.Global.t, P.Local.t);

  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.GlobalStruct memory global, P.LocalStruct memory local);

  function deactivate(address outbound_tkn, address inbound_tkn) external;

  function flashloan(ML.SingleOrder memory sor, address taker)
    external
    returns (uint gasused);

  function fund(address maker) external payable;

  function fund() external payable;

  function governance() external view returns (address);

  function isLive(P.Offer.t offer) external pure returns (bool);

  function kill() external;

  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool);

  function marketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants
  )
    external
    returns (
      uint takerGot,
      uint takerGave,
      uint bounty,
      uint fee
    );

  function marketOrderFor(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint takerGot,
      uint takerGave,
      uint bounty,
      uint fee
    );

  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint);

  function nonces(address) external view returns (uint);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (P.OfferDetail.t);

  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  )
    external
    view
    returns (
      P.OfferStruct memory offer,
      P.OfferDetailStruct memory offerDetail
    );

  function offers(
    address,
    address,
    uint
  ) external view returns (P.Offer.t);

  function permit(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision);

  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) external;

  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) external;

  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
    uint offer_gasbase
  ) external;

  function setGasmax(uint gasmax) external;

  function setGasprice(uint gasprice) external;

  function setGovernance(address governanceAddress) external;

  function setMonitor(address monitor) external;

  function setNotify(bool notify) external;

  function setUseOracle(bool useOracle) external;

  function setVault(address vaultAddress) external;

  function snipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] memory targets,
    bool fillWants
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty,
      uint fee
    );

  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] memory targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty,
      uint fee
    );

  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable;

  function vault() external view returns (address);

  function withdraw(uint amount) external returns (bool noRevert);

  receive() external payable;
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"governance","type":"address"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"owner","type":"address"},{"indexed":false,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Credit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Debit","type":"event"},{"anonymous":false,"inputs":[],"name":"Kill","type":"event"},{"anonymous":false,"inputs":[],"name":"NewMgv","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"},{"indexed":false,"internalType":"bytes32","name":"mgvData","type":"bytes32"}],"name":"OfferFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"}],"name":"OfferRetract","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerWants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGives","type":"uint256"}],"name":"OfferSuccess","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"address","name":"maker","type":"address"},{"indexed":false,"internalType":"uint256","name":"wants","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gives","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasprice","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasreq","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"prev","type":"uint256"}],"name":"OfferWrite","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"taker","type":"address"},{"indexed":false,"internalType":"uint256","name":"takerGot","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"takerGave","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"penalty","type":"uint256"}],"name":"OrderComplete","type":"event"},{"anonymous":false,"inputs":[],"name":"OrderStart","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"PosthookFail","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetActive","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetDensity","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetFee","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"outbound_tkn","type":"address"},{"indexed":true,"internalType":"address","name":"inbound_tkn","type":"address"},{"indexed":false,"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"SetGasbase","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasmax","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"SetGasprice","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetGovernance","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetMonitor","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetNotify","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"value","type":"bool"}],"name":"SetUseOracle","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"value","type":"address"}],"name":"SetVault","type":"event"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"activate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"allowances","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"best","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"config","outputs":[{"internalType":"Global.t","name":"_global","type":"uint256"},{"internalType":"Local.t","name":"_local","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"configInfo","outputs":[{"components":[{"internalType":"address","name":"monitor","type":"address"},{"internalType":"bool","name":"useOracle","type":"bool"},{"internalType":"bool","name":"notify","type":"bool"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"gasmax","type":"uint256"},{"internalType":"bool","name":"dead","type":"bool"}],"internalType":"struct GlobalStruct","name":"global","type":"tuple"},{"components":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint256","name":"fee","type":"uint256"},{"internalType":"uint256","name":"density","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"bool","name":"lock","type":"bool"},{"internalType":"uint256","name":"best","type":"uint256"},{"internalType":"uint256","name":"last","type":"uint256"}],"internalType":"struct LocalStruct","name":"local","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"deactivate","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"Offer.t","name":"offer","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"OfferDetail.t","name":"offerDetail","type":"uint256"},{"internalType":"Global.t","name":"global","type":"uint256"},{"internalType":"Local.t","name":"local","type":"uint256"}],"internalType":"struct MgvLib.SingleOrder","name":"sor","type":"tuple"},{"internalType":"address","name":"taker","type":"address"}],"name":"flashloan","outputs":[{"internalType":"uint256","name":"gasused","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"maker","type":"address"}],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"fund","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"governance","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"Offer.t","name":"offer","type":"uint256"}],"name":"isLive","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"kill","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"}],"name":"locked","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"marketOrder","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"takerWants","type":"uint256"},{"internalType":"uint256","name":"takerGives","type":"uint256"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"marketOrderFor","outputs":[{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"}],"name":"newOffer","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offerDetails","outputs":[{"internalType":"OfferDetail.t","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"offerInfo","outputs":[{"components":[{"internalType":"uint256","name":"prev","type":"uint256"},{"internalType":"uint256","name":"next","type":"uint256"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"}],"internalType":"struct OfferStruct","name":"offer","type":"tuple"},{"components":[{"internalType":"address","name":"maker","type":"address"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"}],"internalType":"struct OfferDetailStruct","name":"offerDetail","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"offers","outputs":[{"internalType":"Offer.t","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offerId","type":"uint256"},{"internalType":"bool","name":"deprovision","type":"bool"}],"name":"retractOffer","outputs":[{"internalType":"uint256","name":"provision","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"density","type":"uint256"}],"name":"setDensity","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"fee","type":"uint256"}],"name":"setFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"offer_gasbase","type":"uint256"}],"name":"setGasbase","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasmax","type":"uint256"}],"name":"setGasmax","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"gasprice","type":"uint256"}],"name":"setGasprice","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"governanceAddress","type":"address"}],"name":"setGovernance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"monitor","type":"address"}],"name":"setMonitor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"notify","type":"bool"}],"name":"setNotify","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"useOracle","type":"bool"}],"name":"setUseOracle","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"vaultAddress","type":"address"}],"name":"setVault","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"}],"name":"snipes","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256[4][]","name":"targets","type":"uint256[4][]"},{"internalType":"bool","name":"fillWants","type":"bool"},{"internalType":"address","name":"taker","type":"address"}],"name":"snipesFor","outputs":[{"internalType":"uint256","name":"successes","type":"uint256"},{"internalType":"uint256","name":"takerGot","type":"uint256"},{"internalType":"uint256","name":"takerGave","type":"uint256"},{"internalType":"uint256","name":"bounty","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"outbound_tkn","type":"address"},{"internalType":"address","name":"inbound_tkn","type":"address"},{"internalType":"uint256","name":"wants","type":"uint256"},{"internalType":"uint256","name":"gives","type":"uint256"},{"internalType":"uint256","name":"gasreq","type":"uint256"},{"internalType":"uint256","name":"gasprice","type":"uint256"},{"internalType":"uint256","name":"pivotId","type":"uint256"},{"internalType":"uint256","name":"offerId","type":"uint256"}],"name":"updateOffer","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"vault","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"withdraw","outputs":[{"internalType":"bool","name":"noRevert","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"stateMutability":"payable","type":"receive"}]
*/

// SPDX-License-Identifier:	BSD-2-Clause

// SwingingMarketMaker.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;
pragma abicoder v2;
import "./IMangrove.sol";
import "./IEIP20.sol";
import "contracts/Strategies/Routers/AbstractRouter.sol";

interface IOfferLogic is IMaker {
  ///////////////////
  // MangroveOffer //
  ///////////////////

  /** @notice Events */

  // Log incident (during post trade execution)
  event LogIncident(
    IMangrove mangrove,
    IEIP20 indexed outbound_tkn,
    IEIP20 indexed inbound_tkn,
    uint indexed offerId,
    bytes32 reason
  );

  // Logging change of router address
  event SetRouter(AbstractRouter);
  // Logging change in default gasreq
  event SetGasreq(uint);

  // Offer logic default gas required --value is used in update and new offer if maxUint is given
  function ofr_gasreq() external returns (uint);

  // returns missing provision on Mangrove, should `offerId` be reposted using `gasreq` and `gasprice` parameters
  // if `offerId` is not in the `outbound_tkn,inbound_tkn` offer list, the totality of the necessary provision is returned
  function getMissingProvision(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) external view returns (uint);

  // Changing ofr_gasreq of the logic
  function set_gasreq(uint gasreq) external;

  // changing liqudity router of the logic
  function set_router(AbstractRouter router) external;

  // maker contract approves router for push and pull operations
  function approveRouter(IEIP20 token) external;

  // withdraw `amount` `token` form the contract's (owner) reserve and sends them to `receiver`'s balance
  function withdrawToken(
    IEIP20 token,
    address receiver,
    uint amount
  ) external returns (bool success);

  ///@return balance the  `token` amount that `msg.sender` has in the contract's reserve
  function tokenBalance(IEIP20 token) external returns (uint balance);

  // allow this contract to act as a LP for Mangrove on `outbound_tkn`
  function approveMangrove(IEIP20 outbound_tkn) external;

  // pulls available free wei from Mangrove balance to `this`
  function withdrawFromMangrove(uint amount, address payable receiver) external;

  struct MakerOrder {
    IEIP20 outbound_tkn; // address of the ERC20 contract managing outbound tokens
    IEIP20 inbound_tkn; // address of the ERC20 contract managing outbound tokens
    uint wants; // amount of `inbound_tkn` required for full delivery
    uint gives; // max amount of `outbound_tkn` promised by the offer
    uint gasreq; // max gas required by the offer when called. If maxUint256 is used here, default `ofr_gasreq` will be considered instead
    uint gasprice; // gasprice that should be consider to compute the bounty (Mangrove's gasprice will be used if this value is lower)
    uint pivotId;
    uint offerId; // 0 if new offer order
  }

  function newOffer(MakerOrder memory mko)
    external
    payable
    returns (uint offerId);

  //returns 0 if updateOffer failed (for instance if offer is underprovisioned) otherwise returns `offerId`
  function updateOffer(MakerOrder memory mko) external payable;

  function retractOffer(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external returns (uint received);
}

// SPDX-License-Identifier:	BSD-2-Clause

// IOfferLogicMulti.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.7.0;
pragma abicoder v2;

import "./IOfferLogic.sol";

interface IOfferLogicMulti is IOfferLogic {
  /** Multi offer specific Events */
  // Offer management
  event NewOwnedOffer(
    IMangrove mangrove,
    IEIP20 indexed outbound_tkn,
    IEIP20 indexed inbound_tkn,
    uint indexed offerId,
    address owner
  );

  // user provision on Mangrove has increased
  event CreditMgvUser(
    IMangrove indexed mangrove,
    address indexed user,
    uint amount
  );

  // user provision on Mangrove has decreased
  event DebitMgvUser(
    IMangrove indexed mangrove,
    address indexed user,
    uint amount
  );

  function offerOwners(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint[] calldata offerIds
  ) external view returns (address[] memory __offerOwners);

  function ownerOf(
    IEIP20 outbound_tkn,
    IEIP20 inbound_tkn,
    uint offerId
  ) external view returns (address owner);
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {AccessControlledStorage as ACS} from "./AccessControlledStorage.sol";

contract AccessControlled {
  constructor(address admin_) {
    require(admin_ != address(0), "accessControlled/0xAdmin");
    ACS.get_storage().admin = admin_;
  }

  modifier onlyCaller(address caller) {
    require(
      caller == address(0) || msg.sender == caller,
      "AccessControlled/Invalid"
    );
    _;
  }

  function admin() public view returns (address) {
    return ACS.get_storage().admin;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin(), "AccessControlled/Invalid");
    _;
  }

  function setAdmin(address _admin) public onlyAdmin {
    require(_admin != address(0), "AccessControlled/0xAdmin");
    ACS.get_storage().admin = _admin;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

library AccessControlledStorage {
  struct Layout {
    address admin;
  }

  function get_storage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.AccessControlledStorage");
    assembly {
      st.slot := storagePosition
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// SimpleOrale.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../interfaces/IEIP20.sol";

library TransferLib {
  // utils
  function transferToken(
    IEIP20 token,
    address recipient,
    uint amount
  ) internal returns (bool) {
    if (amount == 0 || recipient == address(this)) {
      return true;
    }
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, recipient, amount)
    );
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }

  function transferTokenFrom(
    IEIP20 token,
    address spender,
    address recipient,
    uint amount
  ) internal returns (bool) {
    if (amount == 0 || spender == recipient) {
      return true;
    }
    (bool success, bytes memory data) = address(token).call(
      abi.encodeWithSelector(
        token.transferFrom.selector,
        spender,
        recipient,
        amount
      )
    );
    return (success && (data.length == 0 || abi.decode(data, (bool))));
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvReader.sol

// Copyright (C) 2021 Giry SAS.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, P} from "../MgvLib.sol";

interface MangroveLike {
  function best(address, address) external view returns (uint);

  function offers(
    address,
    address,
    uint
  ) external view returns (P.Offer.t);

  function offerDetails(
    address,
    address,
    uint
  ) external view returns (P.OfferDetail.t);

  function offerInfo(
    address,
    address,
    uint
  ) external view returns (P.OfferStruct memory, P.OfferDetailStruct memory);

  function config(address, address)
    external
    view
    returns (P.Global.t, P.Local.t);
}

contract MgvReader {
  MangroveLike immutable mgv;

  constructor(address _mgv) {
    mgv = MangroveLike(payable(_mgv));
  }

  /*
   * Returns two uints.
   *
   * `startId` is the id of the best live offer with id equal or greater than
   * `fromId`, 0 if there is no such offer.
   *
   * `length` is 0 if `startId == 0`. Other it is the number of live offers as good or worse than the offer with
   * id `startId`.
   */
  function offerListEndPoints(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  ) public view returns (uint startId, uint length) {
    unchecked {
      if (fromId == 0) {
        startId = mgv.best(outbound_tkn, inbound_tkn);
      } else {
        startId = mgv.offers(outbound_tkn, inbound_tkn, fromId).gives() > 0
          ? fromId
          : 0;
      }

      uint currentId = startId;

      while (currentId != 0 && length < maxOffers) {
        currentId = mgv.offers(outbound_tkn, inbound_tkn, currentId).next();
        length = length + 1;
      }

      return (startId, length);
    }
  }

  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in packed form. First number is id of next offer (0 is we're done). First array is ids, second is offers (as bytes32), third is offerDetails (as bytes32). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function packedOfferList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.Offer.t[] memory,
      P.OfferDetail.t[] memory
    )
  {
    unchecked {
      (uint currentId, uint length) = offerListEndPoints(
        outbound_tkn,
        inbound_tkn,
        fromId,
        maxOffers
      );

      uint[] memory offerIds = new uint[](length);
      P.Offer.t[] memory offers = new P.Offer.t[](length);
      P.OfferDetail.t[] memory details = new P.OfferDetail.t[](length);

      uint i = 0;

      while (currentId != 0 && i < length) {
        offerIds[i] = currentId;
        offers[i] = mgv.offers(outbound_tkn, inbound_tkn, currentId);
        details[i] = mgv.offerDetails(outbound_tkn, inbound_tkn, currentId);
        currentId = offers[i].next();
        i = i + 1;
      }

      return (currentId, offerIds, offers, details);
    }
  }

  // Returns the orderbook for the outbound_tkn/inbound_tkn pair in unpacked form. First number is id of next offer (0 if we're done). First array is ids, second is offers (as structs), third is offerDetails (as structs). Array will be of size `min(# of offers in out/in list, maxOffers)`.
  function offerList(
    address outbound_tkn,
    address inbound_tkn,
    uint fromId,
    uint maxOffers
  )
    public
    view
    returns (
      uint,
      uint[] memory,
      P.OfferStruct[] memory,
      P.OfferDetailStruct[] memory
    )
  {
    unchecked {
      (uint currentId, uint length) = offerListEndPoints(
        outbound_tkn,
        inbound_tkn,
        fromId,
        maxOffers
      );

      uint[] memory offerIds = new uint[](length);
      P.OfferStruct[] memory offers = new P.OfferStruct[](length);
      P.OfferDetailStruct[] memory details = new P.OfferDetailStruct[](length);

      uint i = 0;
      while (currentId != 0 && i < length) {
        offerIds[i] = currentId;
        (offers[i], details[i]) = mgv.offerInfo(
          outbound_tkn,
          inbound_tkn,
          currentId
        );
        currentId = offers[i].next;
        i = i + 1;
      }

      return (currentId, offerIds, offers, details);
    }
  }

  function getProvision(
    address outbound_tkn,
    address inbound_tkn,
    uint ofr_gasreq,
    uint ofr_gasprice
  ) external view returns (uint) {
    unchecked {
      (P.Global.t global, P.Local.t local) = mgv.config(
        outbound_tkn,
        inbound_tkn
      );
      uint _gp;
      uint global_gasprice = global.gasprice();
      if (global_gasprice > ofr_gasprice) {
        _gp = global_gasprice;
      } else {
        _gp = ofr_gasprice;
      }
      return (ofr_gasreq + local.offer_gasbase()) * _gp * 10**9;
    }
  }
}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

import "./MgvStructs.post.sol";

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

//some type safety for each struct
type t is uint;
using Library for t global;

uint constant monitor_bits   = 160;
uint constant useOracle_bits = 8;
uint constant notify_bits    = 8;
uint constant gasprice_bits  = 16;
uint constant gasmax_bits    = 24;
uint constant dead_bits      = 8;

uint constant monitor_before   = 0;
uint constant useOracle_before = monitor_before   + monitor_bits  ;
uint constant notify_before    = useOracle_before + useOracle_bits;
uint constant gasprice_before  = notify_before    + notify_bits   ;
uint constant gasmax_before    = gasprice_before  + gasprice_bits ;
uint constant dead_before      = gasmax_before    + gasmax_bits   ;

uint constant monitor_mask   = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant useOracle_mask = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant notify_mask    = 0xffffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffff;
uint constant gasprice_mask  = 0xffffffffffffffffffffffffffffffffffffffffffff0000ffffffffffffffff;
uint constant gasmax_mask    = 0xffffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffff;
uint constant dead_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffff00ffffffff;

library Library {
  function to_struct(t __packed) internal pure returns (GlobalStruct memory __s) { unchecked {
    __s.monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __s.useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __s.notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __s.gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __s.dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function unpack(t __packed) internal pure returns (address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) { unchecked {
    __monitor = address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
    __useOracle = (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
    __notify = (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
    __gasmax = (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
    __dead = (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}

  function monitor(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << monitor_before) >> (256-monitor_bits)));
  }}
  function monitor(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & monitor_mask)
                  | ((uint(uint160(val)) << (256-monitor_bits) >> monitor_before)));
  }}
  function useOracle(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << useOracle_before) >> (256-useOracle_bits)) > 0);
  }}
  function useOracle(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & useOracle_mask)
                  | ((uint_of_bool(val) << (256-useOracle_bits) >> useOracle_before)));
  }}
  function notify(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << notify_before) >> (256-notify_bits)) > 0);
  }}
  function notify(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & notify_mask)
                  | ((uint_of_bool(val) << (256-notify_bits) >> notify_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
  function gasmax(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasmax_before) >> (256-gasmax_bits);
  }}
  function gasmax(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasmax_mask)
                  | ((val << (256-gasmax_bits) >> gasmax_before)));
  }}
  function dead(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << dead_before) >> (256-dead_bits)) > 0);
  }}
  function dead(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & dead_mask)
                  | ((uint_of_bool(val) << (256-dead_bits) >> dead_before)));
  }}
}

function t_of_struct(GlobalStruct memory __s) pure returns (t) { unchecked {
  return pack(__s.monitor, __s.useOracle, __s.notify, __s.gasprice, __s.gasmax, __s.dead);
}}

function pack(address __monitor, bool __useOracle, bool __notify, uint __gasprice, uint __gasmax, bool __dead) pure returns (t) { unchecked {
  return t.wrap(((((((0
                | ((uint(uint160(__monitor)) << (256-monitor_bits)) >> monitor_before))
                | ((uint_of_bool(__useOracle) << (256-useOracle_bits)) >> useOracle_before))
                | ((uint_of_bool(__notify) << (256-notify_bits)) >> notify_before))
                | ((__gasprice << (256-gasprice_bits)) >> gasprice_before))
                | ((__gasmax << (256-gasmax_bits)) >> gasmax_before))
                | ((uint_of_bool(__dead) << (256-dead_bits)) >> dead_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

import "./MgvStructs.post.sol";

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

//some type safety for each struct
type t is uint;
using Library for t global;

uint constant active_bits        = 8;
uint constant fee_bits           = 16;
uint constant density_bits       = 112;
uint constant offer_gasbase_bits = 24;
uint constant lock_bits          = 8;
uint constant best_bits          = 32;
uint constant last_bits          = 32;

uint constant active_before        = 0;
uint constant fee_before           = active_before        + active_bits       ;
uint constant density_before       = fee_before           + fee_bits          ;
uint constant offer_gasbase_before = density_before       + density_bits      ;
uint constant lock_before          = offer_gasbase_before + offer_gasbase_bits;
uint constant best_before          = lock_before          + lock_bits         ;
uint constant last_before          = best_before          + best_bits         ;

uint constant active_mask        = 0x00ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant fee_mask           = 0xff0000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant density_mask       = 0xffffff0000000000000000000000000000ffffffffffffffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffff000000ffffffffffffffffffffffff;
uint constant lock_mask          = 0xffffffffffffffffffffffffffffffffffffffff00ffffffffffffffffffffff;
uint constant best_mask          = 0xffffffffffffffffffffffffffffffffffffffffff00000000ffffffffffffff;
uint constant last_mask          = 0xffffffffffffffffffffffffffffffffffffffffffffffffff00000000ffffff;

library Library {
  function to_struct(t __packed) internal pure returns (LocalStruct memory __s) { unchecked {
    __s.active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __s.fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __s.density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __s.best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __s.last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function unpack(t __packed) internal pure returns (bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) { unchecked {
    __active = (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
    __fee = (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
    __density = (t.unwrap(__packed) << density_before) >> (256-density_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __lock = (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
    __best = (t.unwrap(__packed) << best_before) >> (256-best_bits);
    __last = (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}

  function active(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << active_before) >> (256-active_bits)) > 0);
  }}
  function active(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & active_mask)
                  | ((uint_of_bool(val) << (256-active_bits) >> active_before)));
  }}
  function fee(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << fee_before) >> (256-fee_bits);
  }}
  function fee(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & fee_mask)
                  | ((val << (256-fee_bits) >> fee_before)));
  }}
  function density(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << density_before) >> (256-density_bits);
  }}
  function density(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & density_mask)
                  | ((val << (256-density_bits) >> density_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function lock(t __packed) internal pure returns(bool) { unchecked {
    return (((t.unwrap(__packed) << lock_before) >> (256-lock_bits)) > 0);
  }}
  function lock(t __packed,bool val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & lock_mask)
                  | ((uint_of_bool(val) << (256-lock_bits) >> lock_before)));
  }}
  function best(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << best_before) >> (256-best_bits);
  }}
  function best(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & best_mask)
                  | ((val << (256-best_bits) >> best_before)));
  }}
  function last(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << last_before) >> (256-last_bits);
  }}
  function last(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & last_mask)
                  | ((val << (256-last_bits) >> last_before)));
  }}
}

function t_of_struct(LocalStruct memory __s) pure returns (t) { unchecked {
  return pack(__s.active, __s.fee, __s.density, __s.offer_gasbase, __s.lock, __s.best, __s.last);
}}

function pack(bool __active, uint __fee, uint __density, uint __offer_gasbase, bool __lock, uint __best, uint __last) pure returns (t) { unchecked {
  return t.wrap((((((((0
                | ((uint_of_bool(__active) << (256-active_bits)) >> active_before))
                | ((__fee << (256-fee_bits)) >> fee_before))
                | ((__density << (256-density_bits)) >> density_before))
                | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                | ((uint_of_bool(__lock) << (256-lock_bits)) >> lock_before))
                | ((__best << (256-best_bits)) >> best_before))
                | ((__last << (256-last_bits)) >> last_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

import "./MgvStructs.post.sol";

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

//some type safety for each struct
type t is uint;
using Library for t global;

uint constant prev_bits  = 32;
uint constant next_bits  = 32;
uint constant wants_bits = 96;
uint constant gives_bits = 96;

uint constant prev_before  = 0;
uint constant next_before  = prev_before  + prev_bits ;
uint constant wants_before = next_before  + next_bits ;
uint constant gives_before = wants_before + wants_bits;

uint constant prev_mask  = 0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant next_mask  = 0xffffffff00000000ffffffffffffffffffffffffffffffffffffffffffffffff;
uint constant wants_mask = 0xffffffffffffffff000000000000000000000000ffffffffffffffffffffffff;
uint constant gives_mask = 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000;

library Library {
  function to_struct(t __packed) internal pure returns (OfferStruct memory __s) { unchecked {
    __s.prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __s.next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __s.wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __s.gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function unpack(t __packed) internal pure returns (uint __prev, uint __next, uint __wants, uint __gives) { unchecked {
    __prev = (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
    __next = (t.unwrap(__packed) << next_before) >> (256-next_bits);
    __wants = (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
    __gives = (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}

  function prev(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << prev_before) >> (256-prev_bits);
  }}
  function prev(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & prev_mask)
                  | ((val << (256-prev_bits) >> prev_before)));
  }}
  function next(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << next_before) >> (256-next_bits);
  }}
  function next(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & next_mask)
                  | ((val << (256-next_bits) >> next_before)));
  }}
  function wants(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << wants_before) >> (256-wants_bits);
  }}
  function wants(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & wants_mask)
                  | ((val << (256-wants_bits) >> wants_before)));
  }}
  function gives(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gives_before) >> (256-gives_bits);
  }}
  function gives(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gives_mask)
                  | ((val << (256-gives_bits) >> gives_before)));
  }}
}

function t_of_struct(OfferStruct memory __s) pure returns (t) { unchecked {
  return pack(__s.prev, __s.next, __s.wants, __s.gives);
}}

function pack(uint __prev, uint __next, uint __wants, uint __gives) pure returns (t) { unchecked {
  return t.wrap(((((0
                | ((__prev << (256-prev_bits)) >> prev_before))
                | ((__next << (256-next_bits)) >> next_before))
                | ((__wants << (256-wants_bits)) >> wants_before))
                | ((__gives << (256-gives_bits)) >> gives_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

// fields are of the form [name,bits,type]

import "./MgvStructs.post.sol";

// struct_defs are of the form [name,obj]

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

//some type safety for each struct
type t is uint;
using Library for t global;

uint constant maker_bits         = 160;
uint constant gasreq_bits        = 24;
uint constant offer_gasbase_bits = 24;
uint constant gasprice_bits      = 16;

uint constant maker_before         = 0;
uint constant gasreq_before        = maker_before         + maker_bits        ;
uint constant offer_gasbase_before = gasreq_before        + gasreq_bits       ;
uint constant gasprice_before      = offer_gasbase_before + offer_gasbase_bits;

uint constant maker_mask         = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
uint constant gasreq_mask        = 0xffffffffffffffffffffffffffffffffffffffff000000ffffffffffffffffff;
uint constant offer_gasbase_mask = 0xffffffffffffffffffffffffffffffffffffffffffffff000000ffffffffffff;
uint constant gasprice_mask      = 0xffffffffffffffffffffffffffffffffffffffffffffffffffff0000ffffffff;

library Library {
  function to_struct(t __packed) internal pure returns (OfferDetailStruct memory __s) { unchecked {
    __s.maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __s.gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __s.offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __s.gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function eq(t __packed1, t __packed2) internal pure returns (bool) { unchecked {
    return t.unwrap(__packed1) == t.unwrap(__packed2);
  }}

  function unpack(t __packed) internal pure returns (address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) { unchecked {
    __maker = address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
    __gasreq = (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
    __offer_gasbase = (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
    __gasprice = (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}

  function maker(t __packed) internal pure returns(address) { unchecked {
    return address(uint160((t.unwrap(__packed) << maker_before) >> (256-maker_bits)));
  }}
  function maker(t __packed,address val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & maker_mask)
                  | ((uint(uint160(val)) << (256-maker_bits) >> maker_before)));
  }}
  function gasreq(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasreq_before) >> (256-gasreq_bits);
  }}
  function gasreq(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasreq_mask)
                  | ((val << (256-gasreq_bits) >> gasreq_before)));
  }}
  function offer_gasbase(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << offer_gasbase_before) >> (256-offer_gasbase_bits);
  }}
  function offer_gasbase(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & offer_gasbase_mask)
                  | ((val << (256-offer_gasbase_bits) >> offer_gasbase_before)));
  }}
  function gasprice(t __packed) internal pure returns(uint) { unchecked {
    return (t.unwrap(__packed) << gasprice_before) >> (256-gasprice_bits);
  }}
  function gasprice(t __packed,uint val) internal pure returns(t) { unchecked {
    return t.wrap((t.unwrap(__packed) & gasprice_mask)
                  | ((val << (256-gasprice_bits) >> gasprice_before)));
  }}
}

function t_of_struct(OfferDetailStruct memory __s) pure returns (t) { unchecked {
  return pack(__s.maker, __s.gasreq, __s.offer_gasbase, __s.gasprice);
}}

function pack(address __maker, uint __gasreq, uint __offer_gasbase, uint __gasprice) pure returns (t) { unchecked {
  return t.wrap(((((0
                | ((uint(uint160(__maker)) << (256-maker_bits)) >> maker_before))
                | ((__gasreq << (256-gasreq_bits)) >> gasreq_before))
                | ((__offer_gasbase << (256-offer_gasbase_bits)) >> offer_gasbase_before))
                | ((__gasprice << (256-gasprice_bits)) >> gasprice_before)));
}}

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

import "./MgvStructs.post.sol";

import "./MgvOffer.post.sol" as Offer;
import "./MgvOfferDetail.post.sol" as OfferDetail;
import "./MgvGlobal.post.sol" as Global;
import "./MgvLocal.post.sol" as Local;

pragma solidity ^0.8.13;

// SPDX-License-Identifier: Unlicense

// MgvPack.sol

// This is free and unencumbered software released into the public domain.

// Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

// In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// For more information, please refer to <https://unlicense.org/>

/* ************************************************** *
            GENERATED FILE. DO NOT EDIT.
 * ************************************************** */

/* since you can't convert bool to uint in an expression without conditionals,
 * we add a file-level function and rely on compiler optimization
 */
function uint_of_bool(bool b) pure returns (uint u) {
  assembly { u := b }
}

// struct_defs are of the form [name,obj]

// before: Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// now: Won't put all structs under a 'Structs' namespace because Mangrove & peripheral code now uses the current namespacing.
struct OfferStruct {
  uint prev;
  uint next;
  uint wants;
  uint gives;
}

// before: Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// now: Won't put all structs under a 'Structs' namespace because Mangrove & peripheral code now uses the current namespacing.
struct OfferDetailStruct {
  address maker;
  uint gasreq;
  uint offer_gasbase;
  uint gasprice;
}

// before: Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// now: Won't put all structs under a 'Structs' namespace because Mangrove & peripheral code now uses the current namespacing.
struct GlobalStruct {
  address monitor;
  bool useOracle;
  bool notify;
  uint gasprice;
  uint gasmax;
  bool dead;
}

// before: Can't put all structs under a 'Structs' library due to bad variable shadowing rules in Solidity
// (would generate lots of spurious warnings about a nameclash between Structs.Offer and library Offer for instance)
// now: Won't put all structs under a 'Structs' namespace because Mangrove & peripheral code now uses the current namespacing.
struct LocalStruct {
  bool active;
  uint fee;
  uint density;
  uint offer_gasbase;
  bool lock;
  uint best;
  uint last;
}