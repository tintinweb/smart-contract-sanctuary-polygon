// SPDX-License-Identifier:	BSD-2-Clause

// Persistent.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./MangroveOrder.sol";

contract MangroveOrderEnriched is MangroveOrder {
  // `next[out_tkn][in_tkn][owner][id] = id'` with `next[out_tkn][in_tkn][owner][0]==0` iff owner has now offers on the semi book (out,in)
  mapping(IERC20 => mapping(IERC20 => mapping(address => mapping(uint => uint)))) next;

  constructor(IMangrove _MGV, address deployer) MangroveOrder(_MGV, deployer) {}

  function __logOwnerShipRelation__(
    address owner,
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId
  ) internal virtual override {
    uint head = next[outbound_tkn][inbound_tkn][owner][0];
    next[outbound_tkn][inbound_tkn][owner][0] = offerId;
    if (head != 0) {
      next[outbound_tkn][inbound_tkn][owner][offerId] = head;
    }
  }

  // we let the following view function consume loads of gas units in exchange of a rather minimalistic state bookeeping
  function offersOfOwner(
    address owner,
    IERC20 outbound_tkn,
    IERC20 inbound_tkn
  ) external view returns (uint[] memory live, uint[] memory dead) {
    uint head = next[outbound_tkn][inbound_tkn][owner][0];
    uint id = head;
    uint n_live = 0;
    uint n_dead = 0;
    while (id != 0) {
      if (MGV.isLive(MGV.offers($(outbound_tkn), $(inbound_tkn), id))) {
        n_live++;
      } else {
        n_dead++;
      }
      id = next[outbound_tkn][inbound_tkn][owner][id];
    }
    live = new uint[](n_live);
    dead = new uint[](n_dead);
    id = head;
    n_live = 0;
    n_dead = 0;
    while (id != 0) {
      if (MGV.isLive(MGV.offers($(outbound_tkn), $(inbound_tkn), id))) {
        live[n_live++] = id;
      } else {
        dead[n_dead++] = id;
      }
      id = next[outbound_tkn][inbound_tkn][owner][id];
    }
    return (live, dead);
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
import "mgv_src/strategies/multi_user/abstract/Persistent.sol";
import "mgv_src/strategies/interfaces/IOrderLogic.sol";
import "mgv_src/strategies/routers/SimpleRouter.sol";

contract MangroveOrder is MultiUserPersistent, IOrderLogic {
  // `blockToLive[token1][token2][offerId]` gives block number beyond which the offer should renege on trade.
  mapping(IERC20 => mapping(IERC20 => mapping(uint => uint))) public expiring;

  constructor(IMangrove _MGV, address deployer)
    MultiUserPersistent(_MGV, new SimpleRouter(), 90_000)
  {
    if (deployer != msg.sender) {
      set_admin(deployer);
      router().set_admin(deployer);
    }
  }

  function __lastLook__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool)
  {
    uint exp = expiring[IERC20(order.outbound_tkn)][IERC20(order.inbound_tkn)][
      order.offerId
    ];
    return (exp == 0 || block.number <= exp);
  }

  // revert when order was partially filled and it is not allowed
  function checkCompleteness(
    TakerOrder calldata tko,
    TakerOrderResult memory res
  ) internal pure returns (bool isPartial) {
    // revert if sell is partial and `partialFillNotAllowed` and not posting residual
    if (tko.selling) {
      return res.takerGave >= tko.gives;
    } else {
      return res.takerGot + res.fee >= tko.wants;
    }
  }

  // `this` contract MUST have approved Mangrove for inbound token transfer
  // `msg.sender` MUST have approved `this` contract for at least the same amount
  // provision for posting a resting order MAY be sent when calling this function
  // gasLimit of this `tx` MUST be at least `(retryNumber+1)*gasForMarketOrder`
  // msg.value SHOULD contain enough native token to cover for the resting order provision
  // msg.value MUST be 0 if `!restingOrder` otherwise tranfered WEIs are burnt.

  function take(TakerOrder calldata tko)
    external
    payable
    returns (TakerOrderResult memory res)
  {
    (IERC20 outbound_tkn, IERC20 inbound_tkn) = tko.selling
      ? (tko.quote, tko.base)
      : (tko.base, tko.quote);
    // pulling directly from msg.sender would require caller to approve `this` in addition to the `this.router()`
    // so pulling funds from taker's reserve (note this can be the taker's wallet depending on the router)
    uint pulled = router().pull(inbound_tkn, msg.sender, tko.gives, true);
    require(pulled == tko.gives, "mgvOrder/mo/transferInFail");
    // passing an iterated market order with the transfered funds
    for (uint i = 0; i < tko.retryNumber + 1; i++) {
      if (tko.gasForMarketOrder != 0 && gasleft() < tko.gasForMarketOrder) {
        break;
      }
      (uint takerGot_, uint takerGave_, uint bounty_, uint fee_) = MGV
        .marketOrder({
          outbound_tkn: $(outbound_tkn), // expecting quote (outbound) when selling
          inbound_tkn: $(inbound_tkn),
          takerWants: tko.wants, // `tko.wants` includes user defined slippage
          takerGives: tko.gives,
          fillWants: tko.selling ? false : true // only buy order should try to fill takerWants
        });
      res.takerGot += takerGot_;
      res.takerGave += takerGave_;
      res.bounty += bounty_;
      res.fee += fee_;
      if (takerGot_ == 0 && bounty_ == 0) {
        break;
      }
    }
    bool isComplete = checkCompleteness(tko, res);
    // requiring `partialFillNotAllowed` => `isComplete \/ restingOrder`
    require(
      !tko.partialFillNotAllowed || isComplete || tko.restingOrder,
      "mgvOrder/mo/noPartialFill"
    );

    // sending received tokens to taker's reserve
    if (res.takerGot > 0) {
      router().push(outbound_tkn, msg.sender, res.takerGot);
    }

    // at this points the following invariants hold:
    // 1. taker received `takerGot` outbound tokens
    // 2. `this` contract inbound token balance is now equal to `tko.gives - takerGave`.
    // NB: this amount cannot be redeemed by taker since `creditToken` was not called
    // 3. `this` contract's WEI balance is credited of `msg.value + bounty`

    if (tko.restingOrder && !isComplete) {
      // resting limit order for the residual of the taker order
      // this call will credit offer owner virtual account on Mangrove with msg.value before trying to post the offer
      // `offerId_==0` if mangrove rejects the update because of low density.
      // If user does not have enough funds, call will revert
      res.offerId = newOfferInternal({
        mko: MakerOrder({
          outbound_tkn: inbound_tkn,
          inbound_tkn: outbound_tkn,
          wants: tko.makerWants - (res.takerGot + res.fee), // tko.makerWants is before slippage
          gives: tko.makerGives - res.takerGave,
          gasreq: ofr_gasreq(),
          gasprice: 0,
          pivotId: 0,
          offerId: 0 // irrelevant for new offer
        }), // offer should be best in the book
        owner: msg.sender,
        provision: msg.value
      });

      // if one wants to maintain an inverse mapping owner => offerIds
      __logOwnerShipRelation__({
        owner: msg.sender,
        outbound_tkn: inbound_tkn,
        inbound_tkn: outbound_tkn,
        offerId: res.offerId
      });

      emit OrderSummary({
        mangrove: MGV,
        base: tko.base,
        quote: tko.quote,
        selling: tko.selling,
        taker: msg.sender,
        takerGot: res.takerGot,
        takerGave: res.takerGave,
        penalty: res.bounty,
        restingOrderId: res.offerId
      });

      if (res.offerId == 0) {
        // unable to post resting order
        // reverting when partial fill is not an option
        require(!tko.partialFillNotAllowed, "mgvOrder/mo/noPartialFill");
        // sending partial fill to taker --when partial fill is allowed
        require(
          TransferLib.transferToken(
            inbound_tkn,
            msg.sender,
            tko.gives - res.takerGave
          ),
          "mgvOrder/mo/transferInFail"
        );
        // msg.value is no longer needed so sending it back to msg.sender along with possible collected bounty
        if (msg.value + res.bounty > 0) {
          (bool noRevert, ) = msg.sender.call{value: msg.value + res.bounty}(
            ""
          );
          require(noRevert, "mgvOrder/mo/refundProvisionFail");
        }
        return res;
      } else {
        // offer was successfully posted
        // crediting caller's balance with amount of offered tokens (transfered from caller at the begining of this function)
        // NB `inbount_tkn` is now the outbound token for the resting order
        router().push(inbound_tkn, msg.sender, tko.gives - res.takerGave);

        // setting a time to live for the resting order
        if (tko.blocksToLiveForRestingOrder > 0) {
          expiring[inbound_tkn][outbound_tkn][res.offerId] =
            block.number +
            tko.blocksToLiveForRestingOrder;
        }
        return res;
      }
    } else {
      // either fill was complete or taker does not want to post residual as a resting order
      // transfering remaining inbound tokens to msg.sender
      router().push(inbound_tkn, msg.sender, tko.gives - res.takerGave);

      // transfering potential bounty and msg.value back to the taker
      if (msg.value + res.bounty > 0) {
        // NB this calls gives reentrancy power to caller
        (bool noRevert, ) = msg.sender.call{value: msg.value + res.bounty}("");
        require(noRevert, "mgvOrder/mo/refundFail");
      }
      emit OrderSummary({
        mangrove: MGV,
        base: tko.base,
        quote: tko.quote,
        selling: tko.selling,
        taker: msg.sender,
        takerGot: res.takerGot,
        takerGave: res.takerGave,
        penalty: res.bounty,
        restingOrderId: 0
      });
      return res;
    }
  }

  function __posthookSuccess__(ML.SingleOrder calldata order)
    internal
    virtual
    override
    returns (bool noFailure)
  {
    noFailure = super.__posthookSuccess__(order);
    if (!noFailure) {
      // if offer failed to be reposted, if is now off the book but provision is still locked
      retractOffer(
        IERC20(order.outbound_tkn),
        IERC20(order.inbound_tkn),
        order.offerId,
        true
      );
    }
  }

  function __logOwnerShipRelation__(
    address owner,
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId
  ) internal virtual {
    owner; //ssh
    outbound_tkn; //ssh
    inbound_tkn; //ssh
    offerId; //ssh
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
          outbound_tkn: IERC20(order.outbound_tkn),
          inbound_tkn: IERC20(order.inbound_tkn),
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

// IOrderLogic.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

pragma solidity >=0.8.0;
pragma abicoder v2;
import "mgv_src/IMangrove.sol";
import {IERC20} from "mgv_src/MgvLib.sol";

interface IOrderLogic {
  struct TakerOrder {
    IERC20 base; //identifying Mangrove market
    IERC20 quote;
    bool partialFillNotAllowed; //revert if taker order cannot be filled and resting order failed or is not enabled
    bool selling; // whether this is a selling order (otherwise a buy order)
    uint wants; // if `selling` amount of quote tokens, otherwise amount of base tokens
    uint makerWants; // taker wants before slippage (`makerWants == wants` when `!selling`)
    uint gives; // if `selling` amount of base tokens, otherwise amount of quote tokens
    uint makerGives; // taker gives before slippage (`makerGives == gives` when `selling`)
    bool restingOrder; // whether the complement of the partial fill (if any) should be posted as a resting limit order
    uint retryNumber; // number of times filling the taker order should be retried (0 means 1 attempt).
    uint gasForMarketOrder; // gas limit per market order attempt
    uint blocksToLiveForRestingOrder; // number of blocks the resting order should be allowed to live, 0 means forever
  }

  struct TakerOrderResult {
    uint takerGot;
    uint takerGave;
    uint bounty;
    uint fee;
    uint offerId;
  }

  event OrderSummary(
    IMangrove mangrove,
    IERC20 indexed base,
    IERC20 indexed quote,
    address indexed taker,
    bool selling,
    uint takerGot,
    uint takerGave,
    uint penalty,
    uint restingOrderId
  );

  function expiring(
    IERC20,
    IERC20,
    uint
  ) external returns (uint);

  function take(TakerOrder memory)
    external
    payable
    returns (TakerOrderResult memory);
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

// MultiUser.sol

// Copyright (c) 2021 Giry SAS. All rights reserved.

// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
pragma solidity ^0.8.10;
pragma abicoder v2;
import "../../MangroveOffer.sol";
import "mgv_src/periphery/MgvReader.sol";
import "mgv_src/strategies/interfaces/IOfferLogicMulti.sol";

abstract contract MultiUser is IOfferLogicMulti, MangroveOffer {
  struct OfferData {
    // offer owner address
    address owner;
    // under approx of the portion of this contract's balance on mangrove
    // that can be returned to the user's reserve when this offer is deprovisioned
    uint96 wei_balance;
  }

  ///@dev outbound_tkn => inbound_tkn => offerId => OfferData
  mapping(IERC20 => mapping(IERC20 => mapping(uint => OfferData)))
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint[] calldata offerIds
  ) public view override returns (address[] memory _offerOwners) {
    _offerOwners = new address[](offerIds.length);
    for (uint i = 0; i < offerIds.length; i++) {
      _offerOwners[i] = ownerOf(outbound_tkn, inbound_tkn, offerIds[i]);
    }
  }

  /// @notice assigns an `owner` to `offerId`  on the `(outbound_tkn, inbound_tkn)` offer list
  function addOwner(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId
  ) public view override returns (address owner) {
    owner = offerData[outbound_tkn][inbound_tkn][offerId].owner;
    require(owner != address(0), "multiUser/unkownOffer");
  }

  function reserve() public view override returns (address) {
    address mkr_reserve = _reserve(msg.sender);
    return mkr_reserve == address(0) ? msg.sender : mkr_reserve;
  }

  function set_reserve(address __reserve) public override {
    _set_reserve(msg.sender, __reserve);
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
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
      (bool noRevert, ) = msg.sender.call{value: free_wei}("");
      require(noRevert, "MultiUser/weiTransferFail");
    }
  }

  // NB anyone can call but msg.sender will only be able to withdraw from its reserve
  function withdrawToken(
    IERC20 token,
    address receiver,
    uint amount
  ) external override returns (bool success) {
    require(receiver != address(0), "MultiUser/withdrawToken/0xReceiver");
    return router().withdrawToken(token, reserve(), receiver, amount);
  }

  function tokenBalance(IERC20 token) external view override returns (uint) {
    return router().reserveBalance(token, reserve());
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
    IERC20 outTkn = IERC20(order.outbound_tkn);
    IERC20 inTkn = IERC20(order.inbound_tkn);
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
    IERC20 outTkn = IERC20(order.outbound_tkn);
    IERC20 inTkn = IERC20(order.inbound_tkn);
    address owner = ownerOf(outTkn, inTkn, order.offerId);
    // telling router one is requiring `amount` of `outTkn` for `owner`.
    // because `pull` is strict, `pulled <= amount` (cannot be greater)
    // we do not check local balance here because multi user contracts do not keep more balance than what has been pulled
    address source = _reserve(owner);
    uint pulled = router().pull(
      outTkn,
      source == address(0) ? owner : source,
      amount,
      true
    );
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
    IERC20 outTkn = IERC20(order.outbound_tkn);
    IERC20 inTkn = IERC20(order.inbound_tkn);
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

  function __checkList__(IERC20 token) internal view virtual override {
    router().checkList(token, reserve());
    super.__checkList__(token);
  }
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
    IERC20 indexed outbound_tkn,
    IERC20 indexed inbound_tkn,
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
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint[] calldata offerIds
  ) external view returns (address[] memory __offerOwners);

  function ownerOf(
    IERC20 outbound_tkn,
    IERC20 inbound_tkn,
    uint offerId
  ) external view returns (address owner);
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