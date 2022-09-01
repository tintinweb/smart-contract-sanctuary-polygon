// SPDX-License-Identifier:	BSD-2-Clause

// Mango.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MangoStorage.sol";
import "./MangoImplementation.sol";
import "../../abstract/Persistent.sol";
import "../../../routers/AbstractRouter.sol";
import "../../../routers/SimpleRouter.sol";

/** Discrete automated market making strat */
/** This AMM is headless (no price model) and market makes on `NSLOTS` price ranges*/
/** current `Pmin` is the price of an offer at position `0`, current `Pmax` is the price of an offer at position `NSLOTS-1`*/
/** Initially `Pmin = P(0) = QUOTE_0/BASE_0` and the general term is P(i) = __quote_progression__(i)/BASE_0 */
/** NB `__quote_progression__` is a hook that defines how price increases with positions and is by default an arithmetic progression, i.e __quote_progression__(i) = QUOTE_0 + `delta`*i */
/** When one of its offer is matched on Mangrove, the headless strat does the following: */
/** Each time this strat receives b `BASE` tokens (bid was taken) at price position i, it increases the offered (`BASE`) volume of the ask at position i+1 of 'b'*/
/** Each time this strat receives q `QUOTE` tokens (ask was taken) at price position i, it increases the offered (`QUOTE`) volume of the bid at position i-1 of 'q'*/
/** In case of a partial fill of an offer at position i, the offer residual is reposted (see `Persistent` strat class)*/

contract Trivial {
  event Evt();
  constructor() {
    for (uint i =0; i < 10;i ++) {
      emit Evt();
    }
  }

}

contract Mango is Persistent {
  // emitted when init function has been called and AMM becomes active
  event Initialized(uint from, uint to);

  address private immutable IMPLEMENTATION;

  uint public immutable NSLOTS;
  IERC20 public immutable BASE;
  IERC20 public immutable QUOTE;

  // Asks and bids offer Ids are stored in `ASKS` and `BIDS` arrays respectively.

  constructor(
    IMangrove mgv,
    IERC20 base,
    IERC20 quote,
    uint base_0,
    uint quote_0,
    uint nslots,
    uint price_incr,
    address deployer
  )
    Persistent(
      mgv,
      250_000, // gas cost for trade execution (w/o taking routing specific gas cost)
      new SimpleRouter() // routes liqudity from (to) reserve to (from) this contract
    )
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    // sanity check
    require(
      nslots > 0 &&
        address(mgv) != address(0) &&
        uint16(nslots) == nslots &&
        uint96(base_0) == base_0 &&
        uint96(quote_0) == quote_0,
      "Mango/constructor/invalidArguments"
    );

    NSLOTS = nslots;

    // implementation should have correct immutables
    IMPLEMENTATION = address(
      new MangoImplementation(
        mgv,
        base,
        quote,
        uint96(base_0),
        uint96(quote_0),
        nslots
      )
    );
    BASE = base;
    QUOTE = quote;
    // setting local storage
    mStr.asks = new uint[](nslots);
    mStr.bids = new uint[](nslots);
    mStr.delta = price_incr;
    // logs `BID/ASKatMin/MaxPosition` events when only 1 slot remains
    mStr.min_buffer = 1;

    // activates Mango on `quote` and `base`
    __activate__(base);
    __activate__(quote);

    // in order to let deployer's EOA have control over liquidity
    set_reserve(deployer);

    // `this` deployed the router, letting admin take control over it.
    router().set_admin(deployer);

    // setting admin of contract if a static address deployment was used
    if (deployer != msg.sender) {
      set_admin(deployer);
    }
  }

  // populate mangrove order book with bids or/and asks in the price range R = [`from`, `to`[
  // tokenAmounts are always expressed `gives`units, i.e in BASE when asking and in QUOTE when bidding
  function initialize(
    bool reset,
    uint lastBidPosition, // if `lastBidPosition` is in R, then all offers before `lastBidPosition` (included) will be bids, offers strictly after will be asks.
    uint from, // first price position to be populated
    uint to, // last price position to be populated
    uint[][2] calldata pivotIds, // `pivotIds[0][i]` ith pivots for bids, `pivotIds[1][i]` ith pivot for asks
    uint[] calldata tokenAmounts // `tokenAmounts[i]` is the amount of `BASE` or `QUOTE` tokens (dePENDING on `withBase` flag) that is used to fixed one parameter of the price at position `from+i`.
  ) public mgvOrAdmin {
    // making sure a router has been defined between deployment and initialization
    require(address(router()) != address(0), "Mango/initialize/0xRouter");

    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        MangoImplementation.$initialize.selector,
        reset,
        lastBidPosition,
        from,
        to,
        pivotIds,
        tokenAmounts,
        ofr_gasreq()
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      emit Initialized({from: from, to: to});
    }
  }

  function reset_pending() external onlyAdmin {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    mStr.pending_base = 0;
    mStr.pending_quote = 0;
  }

  /** Setters and getters */
  function delta() external view onlyAdmin returns (uint) {
    return MangoStorage.get_storage().delta;
  }

  function set_delta(uint _delta) public mgvOrAdmin {
    MangoStorage.get_storage().delta = _delta;
  }

  function shift() external view onlyAdmin returns (int) {
    return MangoStorage.get_storage().shift;
  }

  function pending() external view onlyAdmin returns (uint[2] memory) {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    return [mStr.pending_base, mStr.pending_quote];
  }

  // with ba=0:bids only, ba=1: asks only ba>1 all
  function retractOffers(
    uint ba,
    uint from,
    uint to
  ) external onlyAdmin returns (uint collected) {
    // with ba=0:bids only, ba=1: asks only ba>1 all
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    for (uint i = from; i < to; i++) {
      if (ba > 0) {
        // asks or bids+asks
        collected += mStr.asks[i] > 0
          ? retractOffer(BASE, QUOTE, mStr.asks[i], true)
          : 0;
      }
      if (ba == 0 || ba > 1) {
        // bids or bids + asks
        collected += mStr.bids[i] > 0
          ? retractOffer(QUOTE, BASE, mStr.bids[i], true)
          : 0;
      }
    }
  }

  /** Shift the price (induced by quote amount) of n slots down or up */
  /** price at position i will be shifted (up or down dePENDING on the sign of `shift`) */
  /** New positions 0<= i < s are initialized with amount[i] in base tokens if `withBase`. In quote tokens otherwise*/
  function set_shift(
    int s,
    bool withBase,
    uint[] calldata amounts
  ) public mgvOrAdmin {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        MangoImplementation.$set_shift.selector,
        s,
        withBase,
        amounts,
        ofr_gasreq()
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    }
  }

  function set_min_offer_type(uint m) external mgvOrAdmin {
    MangoStorage.get_storage().min_buffer = m;
  }

  function _staticdelegatecall(bytes calldata data)
    external
    onlyCaller(address(this))
  {
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(data);
    if (!success) {
      MangoStorage.revertWithData(retdata);
    }
    assembly {
      return(add(retdata, 32), returndatasize())
    }
  }

  // return Mango offer Ids on Mangrove. If `liveOnly` will only return offer Ids that are live (0 otherwise).
  function get_offers(bool liveOnly)
    external
    view
    returns (uint[][2] memory offers)
  {
    (bool success, bytes memory retdata) = address(this).staticcall(
      abi.encodeWithSelector(
        this._staticdelegatecall.selector,
        abi.encodeWithSelector(
          MangoImplementation.$get_offers.selector,
          liveOnly
        )
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (uint[][2]));
    }
  }

  // starts reneging all offers
  // NB reneged offers will not be reposted
  function pause() public mgvOrAdmin {
    MangoStorage.get_storage().paused = true;
  }

  function restart() external onlyAdmin {
    MangoStorage.get_storage().paused = false;
  }

  function is_paused() external view returns (bool) {
    return MangoStorage.get_storage().paused;
  }

  // this overrides is read during `makerExecute` call (see `MangroveOffer`)
  function __lastLook__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool proceed)
  {
    order; //shh
    proceed = !MangoStorage.get_storage().paused;
  }

  // residual gives is default (i.e offer.gives - order.wants) + PENDING
  // this overrides the corresponding function in `Persistent`
  function __residualGives__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    if (order.outbound_tkn == address(BASE)) {
      // Ask offer
      return super.__residualGives__(order) + mStr.pending_base;
    } else {
      // Bid offer
      return super.__residualGives__(order) + mStr.pending_quote;
    }
  }

  // for reposting partial filled offers one always gives the residual (default behavior)
  // and adapts wants to the new price (if different).
  // this overrides the corresponding function in `Persistent`
  function __residualWants__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint)
  {
    uint residual = __residualGives__(order);
    if (residual == 0) {
      return 0;
    }
    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        MangoImplementation.$residualWants.selector,
        order,
        residual
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (uint));
    }
  }

  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    bool reposted = super.__posthookSuccess__(order);

    if (order.outbound_tkn == address(BASE)) {
      if (!reposted) {
        // residual could not be reposted --either below density or Mango went out of provision on Mangrove
        mStr.pending_base = __residualGives__(order); // this includes previous `pending_base`
      } else {
        mStr.pending_base = 0;
      }
    } else {
      if (!reposted) {
        // residual could not be reposted --either below density or Mango went out of provision on Mangrove
        mStr.pending_quote = __residualGives__(order); // this includes previous `pending_base`
      } else {
        mStr.pending_quote = 0;
      }
    }

    (bool success, bytes memory retdata) = IMPLEMENTATION.delegatecall(
      abi.encodeWithSelector(
        MangoImplementation.$postDualOffer.selector,
        order,
        ofr_gasreq()
      )
    );
    if (!success) {
      MangoStorage.revertWithData(retdata);
    } else {
      return abi.decode(retdata, (bool));
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangoStorage.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "mgv_src/strategies/routers/AbstractRouter.sol";

library MangoStorage {
  /** Strat specific events */

  struct Layout {
    uint[] asks;
    uint[] bids;
    // amount of base (resp quote) tokens that failed to be published on the Market
    uint pending_base;
    uint pending_quote;
    // offerId -> index in ASKS/BIDS maps
    mapping(uint => uint) index_of_bid; // bidId -> index
    mapping(uint => uint) index_of_ask; // askId -> index
    // Price shift is in number of price increments (or decrements when shift < 0) since deployment of the strat.
    // e.g. for arithmetic progression, `shift = -3` indicates that Pmin is now (`QUOTE_0` - 3*`delta`)/`BASE_0`
    int shift;
    // parameter for price progression
    // NB for arithmetic progression, price(i+1) = price(i) + delta/`BASE_0`
    uint delta; // quote increment
    // triggers `__boundariesReached__` whenever amounts of bids/asks is below `min_buffer`
    uint min_buffer;
    // puts the strat into a (cancellable) state where it reneges on all incoming taker orders.
    // NB reneged offers are removed from Mangrove's OB
    bool paused;
    // Base and quote router contract
    AbstractRouter router;
    // reserve address for the router (external treasury -e.g EOA-, Mango or the router itself)
    // if the router is lender based, this is the location of the overlying
    address reserve;
  }

  function get_storage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.MangoStorage.Layout");
    assembly {
      st.slot := storagePosition
    }
  }

  function revertWithData(bytes memory retdata) internal pure {
    if (retdata.length == 0) {
      revert("MangoStorage/revertNoReason");
    }
    assembly {
      revert(add(retdata, 32), mload(retdata))
    }
  }

  function quote_price_jumps(
    uint delta,
    uint position,
    uint quote_min
  ) internal pure returns (uint) {
    return delta * position + quote_min;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// MangoImplementation.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "./MangoStorage.sol";
import "../../abstract/Persistent.sol";
import "mgv_src/strategies/utils/TransferLib.sol";

//import "../routers/AbstractRouter.sol";

/** Discrete automated market making strat */
/** This AMM is headless (no price model) and market makes on `NSLOTS` price ranges*/
/** current `Pmin` is the price of an offer at position `0`, current `Pmax` is the price of an offer at position `NSLOTS-1`*/
/** Initially `Pmin = P(0) = QUOTE_0/BASE_0` and the general term is P(i) = __quote_progression__(i)/BASE_0 */
/** NB `__quote_progression__` is a hook that defines how price increases with positions and is by default an arithmetic progression, i.e __quote_progression__(i) = QUOTE_0 + `delta`*i */
/** When one of its offer is matched on Mangrove, the headless strat does the following: */
/** Each time this strat receives b `BASE` tokens (bid was taken) at price position i, it increases the offered (`BASE`) volume of the ask at position i+1 of 'b'*/
/** Each time this strat receives q `QUOTE` tokens (ask was taken) at price position i, it increases the offered (`QUOTE`) volume of the bid at position i-1 of 'q'*/
/** In case of a partial fill of an offer at position i, the offer residual is reposted (see `Persistent` strat class)*/

contract MangoImplementation {
  event BidAtMaxPosition();
  // emitted when strat has reached max amount of Asks and needs rebalancing (should shift of x<0 positions in order to have ask prices that are better for the taker)
  event AskAtMinPosition();

  modifier delegated() {
    require(address(this) == PROXY, "MangoImplementation/invalidCall");
    _;
  }

  // total number of Asks (resp. Bids)
  uint immutable NSLOTS;
  // initial min price given by `QUOTE_0/BASE_0`
  uint96 immutable BASE_0;
  uint96 immutable QUOTE_0;
  // Market on which Mango will be acting
  IERC20 immutable BASE;
  IERC20 immutable QUOTE;

  address immutable PROXY;
  IMangrove immutable MGV;

  constructor(
    IMangrove mgv,
    IERC20 base,
    IERC20 quote,
    uint96 base_0,
    uint96 quote_0,
    uint nslots
  ) {
    // setting immutable fields to match those of `Mango`
    MGV = mgv;
    BASE = base;
    QUOTE = quote;
    NSLOTS = nslots;
    BASE_0 = base_0;
    QUOTE_0 = quote_0;
    PROXY = msg.sender;
  }

  // populate mangrove order book with bids or/and asks in the price range R = [`from`, `to`[
  // tokenAmounts are always expressed `gives`units, i.e in BASE when asking and in QUOTE when bidding
  function $initialize(
    bool reset,
    uint lastBidPosition, // if `lastBidPosition` is in R, then all offers before `lastBidPosition` (included) will be bids, offers strictly after will be asks.
    uint from, // first price position to be populated
    uint to, // last price position to be populated
    uint[][2] calldata pivotIds, // `pivotIds[0][i]` ith pivots for bids, `pivotIds[1][i]` ith pivot for asks
    uint[] calldata tokenAmounts, // `tokenAmounts[i]` is the amount of `BASE` or `QUOTE` tokens (dePENDING on `withBase` flag) that is used to fixed one parameter of the price at position `from+i`.
    uint gasreq // gas required for new offers
  ) external delegated {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    /** Initializing Asks and Bids */
    /** NB we assume Mangrove is already provisioned for posting NSLOTS asks and NSLOTS bids*/
    /** NB cannot post newOffer with infinite gasreq since fallback ofr_gasreq is not defined yet (and default is likely wrong) */
    require(to > from, "Mango/initialize/invalidSlice");
    require(
      tokenAmounts.length == NSLOTS &&
        pivotIds.length == 2 &&
        pivotIds[0].length == NSLOTS &&
        pivotIds[1].length == NSLOTS,
      "Mango/initialize/invalidArrayLength"
    );
    require(lastBidPosition < NSLOTS - 1, "Mango/initialize/NoSlotForAsks"); // bidding => slice doesn't fill the book
    uint pos;
    for (pos = from; pos < to; pos++) {
      // if shift is not 0, must convert
      uint i = index_of_position(pos);

      if (pos <= lastBidPosition) {
        uint bidPivot = pivotIds[0][pos];
        bidPivot = bidPivot > 0
          ? bidPivot // taking pivot from the user
          : pos > 0
          ? mStr.bids[index_of_position(pos - 1)]
          : 0; // otherwise getting last inserted offer as pivot
        updateBid({
          index: i,
          reset: reset, // overwrites old value
          amount: tokenAmounts[pos],
          pivotId: bidPivot,
          gasreq: gasreq
        });
        if (mStr.asks[i] > 0) {
          // if an ASK is also positioned, remove it to prevent spread crossing
          // (should not happen if this is the first initialization of the strat)
          MGV.retractOffer(address(BASE), address(QUOTE), mStr.asks[i], false);
        }
      } else {
        uint askPivot = pivotIds[1][pos];
        askPivot = askPivot > 0
          ? askPivot // taking pivot from the user
          : pos > 0
          ? mStr.asks[index_of_position(pos - 1)]
          : 0; // otherwise getting last inserted offer as pivot
        updateAsk({
          index: i,
          reset: reset,
          amount: tokenAmounts[pos],
          pivotId: askPivot,
          gasreq: gasreq
        });
        if (mStr.bids[i] > 0) {
          // if a BID is also positioned, remove it to prevent spread crossing
          // (should not happen if this is the first initialization of the strat)
          MGV.retractOffer(address(QUOTE), address(BASE), mStr.bids[i], false);
        }
      }
    }
  }

  /** Shift the price (induced by quote amount) of n slots down or up */
  /** price at position i will be shifted (up or down dePENDING on the sign of `shift`) */
  /** New positions 0<= i < s are initialized with amount[i] in base tokens if `withBase`. In quote tokens otherwise*/
  function $set_shift(
    int s,
    bool withBase,
    uint[] calldata amounts,
    uint gasreq
  ) external delegated {
    require(
      amounts.length == (s < 0 ? uint(-s) : uint(s)),
      "Mango/set_shift/notEnoughAmounts"
    );
    if (s < 0) {
      negative_shift(uint(-s), withBase, amounts, gasreq);
    } else {
      positive_shift(uint(s), withBase, amounts, gasreq);
    }
  }

  // return Mango offer Ids on Mangrove. If `liveOnly` will only return offer Ids that are live (0 otherwise).
  function $get_offers(bool liveOnly)
    external
    view
    returns (uint[][2] memory offers)
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    offers[0] = new uint[](NSLOTS);
    offers[1] = new uint[](NSLOTS);
    for (uint i = 0; i < NSLOTS; i++) {
      uint askId = mStr.asks[index_of_position(i)];
      uint bidId = mStr.bids[index_of_position(i)];

      offers[0][i] = (MGV.offers(address(QUOTE), address(BASE), bidId).gives() >
        0 ||
        !liveOnly)
        ? mStr.bids[index_of_position(i)]
        : 0;
      offers[1][i] = (MGV.offers(address(BASE), address(QUOTE), askId).gives() >
        0 ||
        !liveOnly)
        ? mStr.asks[index_of_position(i)]
        : 0;
    }
  }

  struct WriteData {
    uint index;
    uint wants;
    uint gives;
    uint ofr_gr;
    uint pivotId;
  }

  // posts or updates ask at position of `index`
  // returns the amount of `BASE` tokens that failed to be published at that position
  // `writeOffer` is split into `writeAsk` and `writeBid` to avoid stack too deep exception
  function writeAsk(WriteData memory wd) internal returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    if (mStr.asks[wd.index] == 0) {
      // offer slot not initialized yet
      try
        MGV.newOffer({
          outbound_tkn: address(BASE),
          inbound_tkn: address(QUOTE),
          wants: wd.wants,
          gives: wd.gives,
          gasreq: wd.ofr_gr,
          gasprice: 0,
          pivotId: wd.pivotId
        })
      returns (uint offerId) {
        mStr.asks[wd.index] = offerId;
        mStr.index_of_ask[mStr.asks[wd.index]] = wd.index;
        return 0;
      } catch {
        // `newOffer` can fail when Mango is underprovisioned or if `offer.gives` is below density
        return wd.gives;
      }
    } else {
      try
        MGV.updateOffer({
          outbound_tkn: address(BASE),
          inbound_tkn: address(QUOTE),
          wants: wd.wants,
          gives: wd.gives,
          gasreq: wd.ofr_gr,
          gasprice: 0,
          pivotId: wd.pivotId,
          offerId: mStr.asks[wd.index]
        })
      {
        // updateOffer succeeded
        return 0;
      } catch {
        // update offer might fail because residual is below density (this is OK)
        // it may also fail because there is not enough provision on Mangrove (this is Not OK so we log)
        // updateOffer failed but `offer` might still be live (i.e with `offer.gives>0`)
        uint oldGives = MGV
          .offers(address(BASE), address(QUOTE), mStr.asks[wd.index])
          .gives();
        // if not during initialize we necessarily have gives > oldGives
        // otherwise we are trying to reset the offer and oldGives is irrelevant
        return (wd.gives > oldGives) ? wd.gives - oldGives : wd.gives;
      }
    }
  }

  function writeBid(WriteData memory wd) internal returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    if (mStr.bids[wd.index] == 0) {
      try
        MGV.newOffer({
          outbound_tkn: address(QUOTE),
          inbound_tkn: address(BASE),
          wants: wd.wants,
          gives: wd.gives,
          gasreq: wd.ofr_gr,
          gasprice: 0,
          pivotId: wd.pivotId
        })
      returns (uint offerId) {
        mStr.bids[wd.index] = offerId;
        mStr.index_of_bid[mStr.bids[wd.index]] = wd.index;
        return 0;
      } catch {
        return wd.gives;
      }
    } else {
      try
        MGV.updateOffer({
          outbound_tkn: address(QUOTE),
          inbound_tkn: address(BASE),
          wants: wd.wants,
          gives: wd.gives,
          gasreq: wd.ofr_gr,
          gasprice: 0,
          pivotId: wd.pivotId,
          offerId: mStr.bids[wd.index]
        })
      {
        return 0;
      } catch {
        // updateOffer failed but `offer` might still be live (i.e with `offer.gives>0`)
        uint oldGives = MGV
          .offers(address(QUOTE), address(BASE), mStr.bids[wd.index])
          .gives();
        // if not during initialize we necessarily have gives > oldGives
        // otherwise we are trying to reset the offer and oldGives is irrelevant
        return (wd.gives > oldGives) ? wd.gives - oldGives : wd.gives;
      }
    }
  }

  /** Writes (creates or updates) a maker offer on Mangrove's order book*/
  function safeWriteOffer(
    uint index,
    IERC20 outbound_tkn,
    uint wants,
    uint gives,
    uint ofr_gr,
    bool withPending, // whether `gives` amount includes current pending tokens
    uint pivotId
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    if (outbound_tkn == BASE) {
      uint not_published = writeAsk(
        WriteData({
          index: index,
          wants: wants,
          gives: gives,
          ofr_gr: ofr_gr,
          pivotId: pivotId
        })
      );
      if (not_published > 0) {
        // Ask could not be written on the book (density or provision issue)
        mStr.pending_base = withPending
          ? not_published
          : (mStr.pending_base + not_published);
      } else {
        if (withPending) {
          mStr.pending_base = 0;
        }
      }
    } else {
      uint not_published = writeBid(
        WriteData({
          index: index,
          wants: wants,
          gives: gives,
          ofr_gr: ofr_gr,
          pivotId: pivotId
        })
      );
      if (not_published > 0) {
        mStr.pending_quote = withPending
          ? not_published
          : (mStr.pending_quote + not_published);
      } else {
        if (withPending) {
          mStr.pending_quote = 0;
        }
      }
    }
  }

  // returns the value of x in the ring [0,m]
  // i.e if x>=0 this is just x % m
  // if x<0 this is m + (x % m)
  function modulo(int x, uint m) internal pure returns (uint) {
    if (x >= 0) {
      return uint(x) % m;
    } else {
      return uint(int(m) + (x % int(m)));
    }
  }

  /** Minimal amount of quotes for the general term of the `quote_progression` */
  /** If min price was not shifted this is just `QUOTE_0` */
  /** In general this is QUOTE_0 + shift*delta */
  function quote_min() internal view returns (uint) {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    int qm = int(uint(QUOTE_0)) + mStr.shift * int(mStr.delta);
    require(qm > 0, "Mango/quote_min/ShiftUnderflow");
    return (uint(qm));
  }

  /** Returns the price position in the order book of the offer associated to this index `i` */
  function position_of_index(uint i) internal view returns (uint) {
    // position(i) = (i+shift) % N
    return modulo(int(i) - MangoStorage.get_storage().shift, NSLOTS);
  }

  /** Returns the index in the ring of offers at which the offer Id at position `p` in the book is stored */
  function index_of_position(uint p) internal view returns (uint) {
    return modulo(int(p) + MangoStorage.get_storage().shift, NSLOTS);
  }

  /**Next index in the ring of offers */
  function next_index(uint i) internal view returns (uint) {
    return (i + 1) % NSLOTS;
  }

  /**Previous index in the ring of offers */
  function prev_index(uint i) internal view returns (uint) {
    return i > 0 ? i - 1 : NSLOTS - 1;
  }

  /** Function that determines the amount of quotes that are offered at position i of the OB dePENDING on initial_price and paramater delta*/
  /** Here the default is an arithmetic progression */
  function quote_progression(uint position) internal view returns (uint) {
    return
      MangoStorage.quote_price_jumps(
        MangoStorage.get_storage().delta,
        position,
        quote_min()
      );
  }

  /** Returns the quantity of quote tokens for an offer at position `p` given an amount of Base tokens (eq. 2)*/
  function quotes_of_position(uint p, uint base_amount)
    internal
    view
    returns (uint)
  {
    return (quote_progression(p) * base_amount) / BASE_0;
  }

  /** Returns the quantity of base tokens for an offer at position `p` given an amount of quote tokens (eq. 3)*/
  function bases_of_position(uint p, uint quote_amount)
    internal
    view
    returns (uint)
  {
    return (quote_amount * BASE_0) / quote_progression(p);
  }

  /** Recenter the order book by shifting min price up `s` positions in the book */
  /** As a consequence `s` Bids will be cancelled and `s` new asks will be posted */
  function positive_shift(
    uint s,
    bool withBase,
    uint[] calldata amounts,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    require(s < NSLOTS, "Mango/shift/positiveShiftTooLarge");
    uint index = index_of_position(0);
    mStr.shift += int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    uint cpt = 0;
    while (cpt < s) {
      // slots occupied by [Bids[index],..,Bids[index+`s` % N]] are retracted
      if (mStr.bids[index] != 0) {
        MGV.retractOffer({
          outbound_tkn: address(QUOTE),
          inbound_tkn: address(BASE),
          offerId: mStr.bids[index],
          deprovision: false
        });
      }

      // slots are replaced by `s` Asks.
      // NB the price of Ask[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      uint new_gives;
      uint new_wants;
      if (withBase) {
        // posting new ASKS with base amount fixed
        new_gives = amounts[cpt];
        new_wants = quotes_of_position(pos, amounts[cpt]);
      } else {
        // posting new ASKS with quote amount fixed
        new_wants = amounts[cpt];
        new_gives = bases_of_position(pos, amounts[cpt]);
      }
      safeWriteOffer({
        index: index,
        outbound_tkn: BASE,
        wants: new_wants,
        gives: new_gives,
        ofr_gr: gasreq,
        withPending: false, // don't add pending liqudity in new offers (they are far from mid price)
        pivotId: pos > 0 ? mStr.asks[index_of_position(pos - 1)] : 0
      });
      cpt++;
      index = next_index(index);
    }
  }

  /** Recenter the order book by shifting max price down `s` positions in the book */
  /** As a consequence `s` Asks will be cancelled and `s` new Bids will be posted */
  function negative_shift(
    uint s,
    bool withBase,
    uint[] calldata amounts,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    require(s < NSLOTS, "Mango/shift/NegativeShiftTooLarge");
    uint index = index_of_position(NSLOTS - 1);
    mStr.shift -= int(s); // updating new shift
    // Warning: from now on position_of_index reflects the new shift
    // One must progress relative to index when retracting offers
    uint cpt;
    while (cpt < s) {
      // slots occupied by [Asks[index-`s` % N],..,Asks[index]] are retracted
      if (mStr.asks[index] != 0) {
        MGV.retractOffer({
          outbound_tkn: address(BASE),
          inbound_tkn: address(QUOTE),
          offerId: mStr.asks[index],
          deprovision: false
        });
      }
      // slots are replaced by `s` Bids.
      // NB the price of Bids[index] is computed given the new position associated to `index`
      // because the shift has been updated above

      // `pos` is the offer position in the OB (not the array)
      uint pos = position_of_index(index);
      uint new_gives;
      uint new_wants;
      if (withBase) {
        // amounts in base
        new_wants = amounts[cpt];
        new_gives = quotes_of_position(pos, amounts[cpt]);
      } else {
        // amounts in quote
        new_wants = bases_of_position(pos, amounts[cpt]);
        new_gives = amounts[cpt];
      }
      safeWriteOffer({
        index: index,
        outbound_tkn: QUOTE,
        wants: new_wants,
        gives: new_gives,
        ofr_gr: gasreq,
        withPending: false,
        pivotId: pos < NSLOTS - 1 ? mStr.bids[index_of_position(pos + 1)] : 0
      });
      cpt++;
      index = prev_index(index);
    }
  }

  function $residualWants(ML.SingleOrder calldata order, uint residual)
    external
    view
    returns (uint)
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    if (order.outbound_tkn == address(BASE)) {
      // Ask offer (wants QUOTE)
      uint index = mStr.index_of_ask[order.offerId];
      return quotes_of_position(position_of_index(index), residual);
    } else {
      // Bid order (wants BASE)
      uint index = mStr.index_of_bid[order.offerId];
      return bases_of_position(position_of_index(index), residual);
    }
  }

  // TODO add LogIncident and Bid/AskatMax logs
  function $postDualOffer(ML.SingleOrder calldata order, uint gasreq)
    external
    delegated
    returns (bool success)
  {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();

    // reposting residual of offer using override `__newWants__` and `__newGives__` for new price
    if (order.outbound_tkn == address(BASE)) {
      //// Posting dual bid offer
      uint index = mStr.index_of_ask[order.offerId];

      uint pos = position_of_index(index);
      // bid for some BASE token with the received QUOTE tokens @ pos-1
      if (pos > 0) {
        // updateBid will include PENDING_QUOTES if any
        updateBid({
          index: index_of_position(pos - 1),
          reset: false, // top up old value with received amount
          amount: order.gives, // in QUOTES
          pivotId: 0,
          gasreq: gasreq
        });
        if (pos - 1 <= mStr.min_buffer) {
          emit BidAtMaxPosition();
        }
        return true;
      } else {
        // Ask cannot be at Pmin unless a shift has eliminated all bids
        revert("Mango/BidOutOfRange");
      }
    } else {
      // Bid offer (`this` contract just bought some BASE)

      uint index = mStr.index_of_bid[order.offerId];
      // offer was not posted using newOffer
      uint pos = position_of_index(index);
      // ask for some QUOTE tokens in exchange of the received BASE tokens @ pos+1
      if (pos < NSLOTS - 1) {
        // updateAsk will include mStr.pending_baseS if any
        updateAsk({
          index: index_of_position(pos + 1),
          reset: false, // top up old value with received amount
          amount: order.gives, // in BASE
          pivotId: 0,
          gasreq: gasreq
        });
        if (pos + 1 >= NSLOTS - mStr.min_buffer) {
          emit AskAtMinPosition();
        }
        return true;
      } else {
        revert("Mango/AskOutOfRange");
      }
    }
  }

  function updateBid(
    uint index,
    bool reset, // whether this call is part of an `initialize` procedure
    uint amount, // in QUOTE tokens
    uint pivotId,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    // outbound : QUOTE, inbound: BASE
    P.Offer.t offer = MGV.offers(
      address(QUOTE),
      address(BASE),
      mStr.bids[index]
    );

    uint position = position_of_index(index);

    uint new_gives = reset
      ? amount
      : (amount + offer.gives() + mStr.pending_quote);
    uint new_wants = bases_of_position(position, new_gives);

    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = mStr.bids[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = mStr.bids[index];
    }
    safeWriteOffer({
      index: index,
      outbound_tkn: QUOTE,
      wants: new_wants,
      gives: new_gives,
      ofr_gr: gasreq,
      withPending: !reset,
      pivotId: pivot
    });
  }

  function updateAsk(
    uint index,
    bool reset, // whether this call is part of an `initialize` procedure
    uint amount, // in BASE tokens
    uint pivotId,
    uint gasreq
  ) internal {
    MangoStorage.Layout storage mStr = MangoStorage.get_storage();
    // outbound : BASE, inbound: QUOTE
    P.Offer.t offer = MGV.offers(
      address(BASE),
      address(QUOTE),
      mStr.asks[index]
    );
    uint position = position_of_index(index);

    uint new_gives = reset
      ? amount
      : (amount + offer.gives() + mStr.pending_base); // in BASE
    uint new_wants = quotes_of_position(position, new_gives);

    uint pivot;
    if (offer.gives() == 0) {
      // offer was not live
      if (pivotId != 0) {
        pivot = pivotId;
      } else {
        if (position > 0) {
          pivot = mStr.asks[index_of_position(position - 1)]; // if this offer is no longer in the book will start form best
        } else {
          pivot = offer.prev(); // trying previous offer on Mangrove as a pivot
        }
      }
    } else {
      // offer is live, so reusing its id for pivot
      pivot = mStr.asks[index];
    }
    safeWriteOffer({
      index: index,
      outbound_tkn: BASE,
      wants: new_wants,
      gives: new_gives,
      ofr_gr: gasreq,
      withPending: !reset,
      pivotId: pivot
    });
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
import "./SingleUser.sol";

/** Strat class with specialized hooks that repost offer residual after a partial fill */
/** (Single user variant) */

abstract contract Persistent is SingleUser {
  constructor(
    IMangrove _mgv,
    uint strat_gasreq,
    AbstractRouter _router
  ) SingleUser(_mgv, strat_gasreq, _router) {}

  /** Persistent class specific hooks. */

  // Hook that defines how much inbound tokens the residual offer should ask for when repositing itself on the Offer List.
  // default is to repost the old amount minus the partial fill
  function __residualWants__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.wants() - order.gives;
  }

  // Hook that defines how much outbound tokens the residual offer should promise for when repositing itself on the Offer List.
  // default is to repost the old required amount minus the partial fill
  // NB this could produce an offer below the density. Offer Maker should perform a density check at repost time if not willing to fail reposting.
  function __residualGives__(ML.SingleOrder calldata order)
    internal
    virtual
    returns (uint)
  {
    return order.offer.gives() - order.wants;
  }

  // Specializing this hook to repost offer residual when trade was a success
  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    // flushing inbound and remaining outbound tokens to reserve
    super.__posthookSuccess__(order);

    // now trying to repost residual
    uint new_gives = __residualGives__(order);
    // Density check would be too gas costly.
    // We only treat the special case of `gives==0` (total fill).
    // Offer below the density will cause Mangrove to throw (revert is catched to log information)
    if (new_gives == 0) {
      return true;
    }
    uint new_wants = __residualWants__(order);
    try
      MGV.updateOffer(
        order.outbound_tkn,
        order.inbound_tkn,
        new_wants,
        new_gives,
        order.offerDetail.gasreq(),
        order.offerDetail.gasprice(),
        order.offer.next(),
        order.offerId
      )
    {
      return true;
    } catch (bytes memory reason) {
      // `newOffer` can fail when Mango is under provisioned or if `offer.gives` is below density
      // Log incident only if under provisioned
      if (keccak256(reason) == keccak256("mgv/insufficientProvision")) {
        emit LogIncident(
          MGV,
          IERC20(order.outbound_tkn),
          IERC20(order.inbound_tkn),
          order.offerId,
          "Persistent/hook/outOfProvision"
        );
      }
      return false;
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AbstractRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import "mgv_src/strategies/utils/AccessControlled.sol";
import {AbstractRouterStorage as ARSt} from "./AbstractRouterStorage.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

abstract contract AbstractRouter is AccessControlled {
  modifier onlyMakers() {
    require(makers(msg.sender), "Router/unauthorized");
    _;
  }
  modifier makersOrAdmin() {
    require(msg.sender == admin() || makers(msg.sender), "Router/unauthorized");
    _;
  }

  constructor(uint overhead) AccessControlled(msg.sender) {
    require(uint24(overhead) == overhead, "Router/overheadTooHigh");
    ARSt.get_storage().gas_overhead = overhead;
  }

  ///@notice getter for the `makers: addr => bool` mapping
  ///@param mkr the address of a maker
  ///@return true is `mkr` is bound to this router
  function makers(address mkr) public view returns (bool) {
    return ARSt.get_storage().makers[mkr];
  }

  ///@notice the amount of gas that will be added to `gasreq` of any maker contract using this router
  function gas_overhead() public view returns (uint) {
    return ARSt.get_storage().gas_overhead;
  }

  ///@notice pulls `amount` of `token`s from reserve to calling maker contract's balance
  ///@param token is the ERC20 managing the pulled asset
  ///@param reserve is the address identifying where `amount` of `token` should be pulled from
  ///@param amount of token the maker contract wishes to get
  ///@param strict when the calling maker contract accepts to receive more `token` than required (this may happen for gas optimization)
  function pull(
    IERC20 token,
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

  ///@notice router-dependant implementation of the `pull` function
  function __pull__(
    IERC20 token,
    address reserve,
    address maker,
    uint amount,
    bool strict
  ) internal virtual returns (uint);

  ///@notice pushes assets from maker contract's balance to the specified reserve
  ///@param token is the asset the maker is pushing
  ///@param reserve is the address identifying where the transfered assets should be placed to
  ///@param amount is the amount of asset that should be transfered from the calling maker contract
  function push(
    IERC20 token,
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

  ///@notice router-dependant implementation of the `push` function
  function __push__(
    IERC20 token,
    address reserve,
    address maker,
    uint amount
  ) internal virtual;

  ///@notice gas saving implementation of an iterative `push`
  function flush(IERC20[] calldata tokens, address reserve)
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

  ///@notice returns the amount of `token`s that can be made available for pulling by the maker contract
  ///@dev when this router is pulling from a lender, this must return the amount of asset that can be withdrawn from reserve
  ///@param token is the asset one wishes to know the balance of
  ///@param reserve is the address identifying the location of the assets
  function reserveBalance(IERC20 token, address reserve)
    external
    view
    virtual
    returns (uint);

  ///@notice withdraws `amount` of reserve tokens and sends them to `recipient`
  ///@dev this is called by maker's contract when originator wishes to withdraw funds from it.
  /// this function is necessary because the maker contract is agnostic w.r.t reserve management
  function withdrawToken(
    IERC20 token,
    address reserve,
    address recipient,
    uint amount
  ) public onlyMakers returns (bool) {
    return __withdrawToken__(token, reserve, recipient, amount);
  }

  ///@notice router-dependant implementation of the `withdrawToken` function
  function __withdrawToken__(
    IERC20 token,
    address reserve,
    address to,
    uint amount
  ) internal virtual returns (bool);

  ///@notice adds a maker contract address to the allowed callers of this router
  ///@dev this function is callable by router's admin to bootstrap, but later on an allowed maker contract can add another address
  function bind(address maker) public makersOrAdmin {
    ARSt.get_storage().makers[maker] = true;
  }

  ///@notice removes a maker contract address from the allowed callers of this router
  function unbind(address maker) public makersOrAdmin {
    ARSt.get_storage().makers[maker] = false;
  }

  ///@notice verifies all required approval involving `this` router (either as a spender or owner)
  ///@dev `checkList` returns normally if all needed approval are strictly positive. It reverts otherwise with a reason.
  ///@param token is the asset (and possibly its overlyings) whose approval must be checked
  ///@param reserve the reserve that requires asset pulling/pushing
  function checkList(IERC20 token, address reserve) external view {
    // checking basic requirement
    require(
      token.allowance(msg.sender, address(this)) > 0,
      "Router/NotApprovedByMakerContract"
    );
    __checkList__(token, reserve);
  }

  ///@notice router-dependent implementation of the `checkList` function
  function __checkList__(IERC20 token, address reserve) internal view virtual;

  ///@notice performs necessary approval to activate router function on a particular asset
  ///@param token the asset one wishes to use the router for
  function activate(IERC20 token) external makersOrAdmin {
    __activate__(token);
  }

  ///@notice router-dependent implementation of the `activate` function
  function __activate__(IERC20 token) internal virtual {
    token; //ssh
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//SimpleRouter.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

import "mgv_src/strategies/utils/AccessControlled.sol";
import "mgv_src/strategies/utils/TransferLib.sol";
import "./AbstractRouter.sol";

///@notice `SimpleRouter` instances pull (push) liquidity direclty from (to) the reserve
/// If called by a `SingleUser` contract instance this will be the vault of the contract
/// If called by a `MultiUser` instance, this will be the address of a contract user (typically an EOA)
///@dev Maker contracts using this router must make sur that reserve approves the router for all asset that will be pulled (outbound tokens)
/// Thus contract using a vault that is not an EOA must make sure this vault has approval capacities.

contract SimpleRouter is AbstractRouter(50_000) {
  // requires approval of `reserve`
  function __pull__(
    IERC20 token,
    address reserve,
    address maker,
    uint amount,
    bool strict
  ) internal virtual override returns (uint pulled) {
    strict; // this pull strategy is only strict
    if (TransferLib.transferTokenFrom(token, reserve, maker, amount)) {
      return amount;
    } else {
      return 0;
    }
  }

  // requires approval of Maker
  function __push__(
    IERC20 token,
    address reserve,
    address maker,
    uint amount
  ) internal virtual override {
    require(
      TransferLib.transferTokenFrom(token, maker, reserve, amount),
      "SimpleRouter/push/transferFail"
    );
  }

  function __withdrawToken__(
    IERC20 token,
    address reserve,
    address to,
    uint amount
  ) internal virtual override returns (bool) {
    return TransferLib.transferTokenFrom(token, reserve, to, amount);
  }

  function reserveBalance(IERC20 token, address reserve)
    external
    view
    override
    returns (uint)
  {
    return token.balanceOf(reserve);
  }

  function __checkList__(IERC20 token, address reserve)
    internal
    view
    virtual
    override
  {
    // verifying that `this` router can withdraw tokens from reserve (required for `withdrawToken` and `pull`)
    require(
      reserve == address(this) || token.allowance(reserve, address(this)) > 0,
      "SimpleRouter/NotApprovedByReserve"
    );
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// TransferLib.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import {IERC20} from "mgv_src/MgvLib.sol";

// TODO-foundry-merge explain what this contract does

library TransferLib {
  // utils
  function transferToken(
    IERC20 token,
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
    IERC20 token,
    address spender,
    address recipient,
    uint amount
  ) internal returns (bool) {
    if (amount == 0 || spender == recipient) {
      return true;
    }
    // optim to avoid requiring contract to approve itself
    if (spender == address(this)) {
      return transferToken(token, recipient, amount);
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

// SPDX-License-Identifier:	BSD-2-Clause

// SingleUser.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "../../MangroveOffer.sol";
import "mgv_src/strategies/utils/TransferLib.sol";

/// MangroveOffer is the basic building block to implement a reactive offer that interfaces with the Mangrove
abstract contract SingleUser is MangroveOffer {
  constructor(
    IMangrove _mgv,
    uint strat_gasreq,
    AbstractRouter _router
  ) MangroveOffer(_mgv, strat_gasreq) {
    // default reserve is router's address if router is defined
    // if not then default reserve is `this` contract
    if (address(_router) == address(0)) {
      set_reserve(address(this));
    } else {
      set_reserve(address(_router));
      set_router(_router);
    }
  }

  function reserve() public view override returns (address) {
    return _reserve(address(this));
  }

  function set_reserve(address __reserve) public override onlyAdmin {
    _set_reserve(address(this), __reserve);
  }

  function withdrawToken(
    IERC20 token,
    address receiver,
    uint amount
  ) external override onlyAdmin returns (bool success) {
    require(receiver != address(0), "SingleUser/withdrawToken/0xReceiver");
    if (!has_router()) {
      return TransferLib.transferToken(IERC20(token), receiver, amount);
    } else {
      return router().withdrawToken(token, reserve(), receiver, amount);
    }
  }

  function pull(
    IERC20 outbound_tkn,
    uint amount,
    bool strict
  ) internal returns (uint) {
    AbstractRouter _router = MOS.get_storage().router;
    if (address(_router) == address(0)) {
      return 0; // nothing to do
    } else {
      // letting specific router pull the funds from reserve
      return _router.pull(outbound_tkn, reserve(), amount, strict);
    }
  }

  function push(IERC20 token, uint amount) internal {
    AbstractRouter _router = MOS.get_storage().router;
    if (address(_router) == address(0)) {
      return; // nothing to do
    } else {
      // noop if reserve == address(this)
      _router.push(token, reserve(), amount);
    }
  }

  function tokenBalance(IERC20 token) external view override returns (uint) {
    AbstractRouter _router = MOS.get_storage().router;
    return
      address(_router) == address(0)
        ? token.balanceOf(reserve())
        : _router.reserveBalance(token, reserve());
  }

  function flush(IERC20[] memory tokens) internal {
    AbstractRouter _router = MOS.get_storage().router;
    if (address(_router) == address(0)) {
      return; // nothing to do
    } else {
      _router.flush(tokens, reserve());
    }
  }

  // Posting a new offer on the (`outbound_tkn,inbound_tkn`) Offer List of Mangrove.
  // NB #1: Offer maker maker MUST:
  // * Approve Mangrove for at least `gives` amount of `outbound_tkn`.
  // * Make sure that `this` contract has enough WEI provision on Mangrove to cover for the new offer bounty (function is payable so that caller can increase provision prior to posting the new offer)
  // * Make sure that `gasreq` and `gives` yield a sufficient offer density
  // NB #2: This function will revert when the above points are not met
  function newOffer(MakerOrder memory mko)
    external
    payable
    override
    onlyAdmin
    returns (uint)
  {
    mko.offerId = MGV.newOffer{value: msg.value}(
      address(mko.outbound_tkn),
      address(mko.inbound_tkn),
      mko.wants,
      mko.gives,
      mko.gasreq >= type(uint24).max ? ofr_gasreq() : mko.gasreq,
      mko.gasprice,
      mko.pivotId
    );
    return mko.offerId;
  }

  // Updates offer `offerId` on the (`outbound_tkn,inbound_tkn`) Offer List of Mangrove.
  // NB #1: Offer maker MUST:
  // * Make sure that offer maker has enough WEI provision on Mangrove to cover for the new offer bounty in case Mangrove gasprice has increased (function is payable so that caller can increase provision prior to updating the offer)
  // * Make sure that `gasreq` and `gives` yield a sufficient offer density
  // NB #2: This function will revert when the above points are not met
  function updateOffer(MakerOrder memory mko)
    external
    payable
    override
    onlyAdmin
  {
    return
      MGV.updateOffer{value: msg.value}(
        address(mko.outbound_tkn),
        address(mko.inbound_tkn),
        mko.wants,
        mko.gives,
        mko.gasreq > type(uint24).max ? ofr_gasreq() : mko.gasreq,
        mko.gasprice,
        mko.pivotId,
        mko.offerId
      );
  }

  // Retracts `offerId` from the (`outbound_tkn`,`inbound_tkn`) Offer list of Mangrove.
  // Function call will throw if `this` contract is not the owner of `offerId`.
  // Returned value is the amount of ethers that have been credited to `this` contract balance on Mangrove (always 0 if `deprovision=false`)
  // NB `mgvOrAdmin` modifier guarantees that this function is either called by contract admin or during trade execution by Mangrove
  function retractOffer(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) public override mgvOrAdmin returns (uint free_wei) {
    free_wei = MGV.retractOffer(
      address(outbound_tkn),
      address(inbound_tkn),
      offerId,
      deprovision
    );
    if (free_wei > 0) {
      require(
        MGV.withdraw(free_wei),
        "SingleUser/withdrawFromMgv/withdrawFail"
      );
      (bool noRevert, ) = msg.sender.call{value: free_wei}("");
      require(noRevert, "SingleUser/weiTransferFail");
    }
  }

  function __put__(
    uint, /*amount*/
    ML.SingleOrder calldata
  ) internal virtual override returns (uint missing) {
    // singleUser contract do not need to do anything specific with incoming funds during trade
    // one should overrides this function if one wishes to leverage taker's fund during trade execution
    return 0;
  }

  // default `__get__` hook for `SingleUser` is to pull liquidity from immutable `reserve()`
  // letting router handle the specifics if any
  function __get__(uint amount, ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (uint missing)
  {
    // pulling liquidity from reserve
    // depending on the router, this may result in pulling more/less liquidity than required
    // so one should check local balance to compute missing liquidity
    uint pulled = pull(IERC20(order.outbound_tkn), amount, false);
    if (pulled >= amount) {
      return 0;
    } else {
      uint local_balance = IERC20(order.outbound_tkn).balanceOf(address(this));
      return local_balance >= amount ? 0 : amount - local_balance;
    }
  }

  ////// Customizable post-hooks.

  // Override this post-hook to implement what `this` contract should do when called back after a successfully executed order.
  // In this posthook, contract will flush its liquidity towards the reserve (noop if reserve is this contract)
  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool success)
  {
    IERC20[] memory tokens = new IERC20[](2);
    tokens[0] = IERC20(order.outbound_tkn); // flushing outbound tokens if this contract pulled more liquidity than required during `makerExecute`
    tokens[1] = IERC20(order.inbound_tkn); // flushing liquidity brought by taker
    // sends all tokens to the reserve (noop if reserve() == address(this))
    flush(tokens);
    success = true;
  }

  function __checkList__(IERC20 token) internal view virtual override {
    if (has_router()) {
      router().checkList(token, reserve());
    }
    super.__checkList__(token);
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
import {AccessControlledStorage as ACS} from "./AccessControlledStorage.sol";

// TODO-foundry-merge explain what this contract does

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

  function set_admin(address _admin) public onlyAdmin {
    require(_admin != address(0), "AccessControlled/0xAdmin");
    ACS.get_storage().admin = _admin;
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

//AbstractRouterStorage.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity ^0.8.10;
pragma abicoder v2;

library AbstractRouterStorage {
  struct Layout {
    mapping(address => bool) makers;
    uint gas_overhead;
  }

  function get_storage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256(
      "Mangrove.AbstractRouterStorageLib.Layout"
    );
    assembly {
      st.slot := storagePosition
    }
  }
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
  function decimals() external view returns (uint8);
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

import "mgv_src/strategies/utils/AccessControlled.sol";
import {MangroveOfferStorage as MOS} from "./MangroveOfferStorage.sol";
import "mgv_src/strategies/interfaces/IOfferLogic.sol";
import "mgv_src/IMangrove.sol";

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
        IERC20(order.outbound_tkn),
        IERC20(order.inbound_tkn),
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
  /** `this` contract must be admin of router to do this */
  function set_router(AbstractRouter router_) public override mgvOrAdmin {
    require(address(router_) != address(0), "mgvOffer/set_router/0xRouter");
    MOS.get_storage().router = router_;
    router_.bind(address(this));
    emit SetRouter(router_);
  }

  // maker contract need to approve router for reserve push and pull
  function approveRouter(IERC20 token) public {
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

  function _reserve(address maker) internal view returns (address) {
    return MOS.get_storage().reserves[maker];
  }

  function _set_reserve(address maker, address __reserve) internal {
    require(__reserve != address(0), "SingleUser/0xReserve");
    MOS.get_storage().reserves[maker] = __reserve;
  }

  /// `this` contract needs to approve Mangrove to let it perform outbound token transfer at the end of the `makerExecute` function
  /// NB if anyone can call this function someone could reset it to 0 for griefing
  function approveMangrove(IERC20 outbound_tkn) public {
    require(
      outbound_tkn.approve(address(MGV), type(uint).max),
      "mgvOffer/approveMangrove/Fail"
    );
  }

  ///@notice gas efficient external call to activate several tokens in a single transaction
  function activate(IERC20[] calldata tokens) external override onlyAdmin {
    for (uint i = 0; i < tokens.length; i++) {
      __activate__(tokens[i]);
    }
  }

  ///@notice allows this contract to be a liquidity provider for a particular asset by performing the necessary approvals
  ///@param token the ERC20 one wishes this contract to be a provider of
  function __activate__(IERC20 token) internal virtual {
    // approves Mangrove for pulling funds at the end of `makerExecute`
    approveMangrove(token);
    if (has_router()) {
      // allowing router to pull `token` from this contract (for the `push` function of the router)
      approveRouter(token);
      // letting router performs additional necessary approvals (if any)
      router().activate(token);
    }
  }

  ///@notice verifies that this contract's current state is ready to be used by msg.sender to post offers on Mangrove
  ///@dev throws with a reason when there is a missing approval
  function checkList(IERC20[] calldata tokens) external view override {
    for (uint i = 0; i < tokens.length; i++) {
      __checkList__(tokens[i]);
    }
  }

  function __checkList__(IERC20 token) internal view virtual {
    require(
      token.allowance(address(this), address(MGV)) > 0,
      "MangroveOffer/AdminMustApproveMangrove"
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
  function $(IERC20 token) internal pure returns (address) {
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
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

// AccessedControlled.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

// TODO-foundry-merge explain what this contract does

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

// SPDX-License-Identifier:	BSD-2-Clause

// MangroveOffer.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "mgv_src/strategies/interfaces/IOfferLogic.sol";

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
    mapping(address => address) reserves;
  }

  function get_storage() internal pure returns (Layout storage st) {
    bytes32 storagePosition = keccak256("Mangrove.MangroveOfferStorage");
    assembly {
      st.slot := storagePosition
    }
  }
}

// SPDX-License-Identifier:	BSD-2-Clause

// IOfferLogic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;
pragma abicoder v2;
import "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/MgvLib.sol";
import "mgv_src/strategies/routers/AbstractRouter.sol";

interface IOfferLogic is IMaker {
  ///////////////////
  // MangroveOffer //
  ///////////////////

  /** @notice Events */

  // Log incident (during post trade execution)
  event LogIncident(
    IMangrove mangrove,
    IERC20 indexed outbound_tkn,
    IERC20 indexed inbound_tkn,
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint gasreq,
    uint gasprice,
    uint offerId
  ) external view returns (uint);

  // Changing ofr_gasreq of the logic
  function set_gasreq(uint gasreq) external;

  // changing liqudity router of the logic
  function set_router(AbstractRouter router) external;

  // maker contract approves router for push and pull operations
  function approveRouter(IERC20 token) external;

  // withdraw `amount` `token` form the contract's (owner) reserve and sends them to `receiver`'s balance
  function withdrawToken(
    IERC20 token,
    address receiver,
    uint amount
  ) external returns (bool success);

  ///@notice throws if this maker contract is missing approval to be used by caller to trade on the given asset
  ///@param tokens the assets the caller wishes to trade
  function checkList(IERC20[] calldata tokens) external view;

  ///@return balance the  `token` amount that `msg.sender` has in the contract's reserve
  function tokenBalance(IERC20 token) external returns (uint balance);

  // allow this contract to act as a LP for Mangrove on `outbound_tkn`
  function approveMangrove(IERC20 outbound_tkn) external;

  // contract's activation sequence for a specific ERC
  function activate(IERC20[] calldata tokens) external;

  // pulls available free wei from Mangrove balance to `this`
  function withdrawFromMangrove(uint amount, address payable receiver) external;

  struct MakerOrder {
    IERC20 outbound_tkn; // address of the ERC20 contract managing outbound tokens
    IERC20 inbound_tkn; // address of the ERC20 contract managing outbound tokens
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId,
    bool deprovision // if set to `true`, `this` contract will receive the remaining provision (in WEI) associated to `offerId`.
  ) external returns (uint received);

  // returns the address of the vault holding maker's liquidity
  // for single user maker is simply `this` contract
  // for multi users, the maker is `msg.sender`
  function reserve() external view returns (address);

  // allow one to change the reserve holding maker's liquidity
  function set_reserve(address reserve) external;

  function router() external view returns (AbstractRouter);
}

// SPDX-License-Identifier: UNLICENSED
// This file was manually adapted from a file generated by abi-to-sol. It must
// be kept up-to-date with the actual Mangrove interface. Fully automatic
// generation is not yet possible due to user-generated types in the external
// interface lost in the abi generation.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import {MgvLib as ML, P, IMaker} from "./MgvLib.sol";

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