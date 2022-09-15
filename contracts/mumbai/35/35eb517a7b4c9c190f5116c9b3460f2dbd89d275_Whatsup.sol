// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.13;

import {ToyENS} from "./lib/ToyENS.sol";
import {MangroveDeployer} from "./lib/MangroveDeployer.sol";
import {Deployer} from "./lib/Deployer.sol";

contract Whatsup { uint i; constructor() { i = 3; }}

contract WhatsupDeploy is Deployer {
  function run() public {
    vm.broadcast();
    new Whatsup();
    outputDeployment();
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract ToyENS {
  mapping(string => address) _addrs;
  mapping(string => bool) _isToken;
  string[] _names;

  function get(string calldata name)
    external
    view
    returns (address addr, bool isToken)
  {
    addr = _addrs[name];
    isToken = _isToken[name];
  }

  function set(string calldata name, address addr) public {
    set(name, addr, false);
  }

  function set(
    string calldata name,
    address addr,
    bool isToken
  ) public {
    _addrs[name] = addr;
    _names.push(name);
    _isToken[name] = isToken;
  }

  function set(
    string[] calldata names,
    address[] calldata addrs,
    bool[] calldata isToken
  ) external {
    for (uint i = 0; i < names.length; i++) {
      set(names[i], addrs[i], isToken[i]);
    }
  }

  function all()
    external
    view
    returns (
      string[] memory names,
      address[] memory addrs,
      bool[] memory isToken
    )
  {
    names = _names;
    addrs = new address[](names.length);
    isToken = new bool[](names.length);
    for (uint i = 0; i < _names.length; i++) {
      addrs[i] = _addrs[names[i]];
      isToken[i] = _isToken[names[i]];
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "mgv_src/Mangrove.sol";
import "mgv_src/periphery/MgvReader.sol";
import {MangroveOrderEnriched} from "mgv_src/periphery/MangroveOrderEnriched.sol";
import {MgvCleaner} from "mgv_src/periphery/MgvCleaner.sol";
import {MgvOracle} from "mgv_src/periphery/MgvOracle.sol";
import {IMangrove} from "mgv_src/IMangrove.sol";
import {Deployer} from "./Deployer.sol";

contract MangroveDeployer is Deployer {
  Mangrove public mgv;
  MgvReader public reader;
  MgvCleaner public cleaner;
  MgvOracle public oracle;
  MangroveOrderEnriched public mgoe;

  function run() public {
    deploy({chief: msg.sender, gasprice: 1, gasmax: 2_000_000});
    outputDeployment();
  }

  function deploy(
    address chief,
    uint gasprice,
    uint gasmax
  ) public {
    vm.broadcast();
    mgv = new Mangrove({governance: chief, gasprice: gasprice, gasmax: gasmax});
    ens.set("Mangrove", address(mgv));

    vm.broadcast();
    reader = new MgvReader({_mgv: payable(mgv)});
    ens.set("MgvReader", address(reader));

    vm.broadcast();
    cleaner = new MgvCleaner({_MGV: address(mgv)});
    ens.set("MgvCleaner", address(cleaner));

    vm.broadcast();
    oracle = new MgvOracle({_governance: chief, _initialMutator: chief});
    ens.set("MgvOracle", address(oracle));

    vm.broadcast();
    mgoe = new MangroveOrderEnriched({
      _MGV: IMangrove(payable(mgv)),
      deployer: chief
    });
    ens.set("MangroveOrderEnriched", address(mgoe));
  }
}

// SPDX-License-Identifier:	AGPL-3.0
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";
import {ToyENS} from "./ToyENS.sol";

/* Outputs deployments as follows:

   To a toy ENS instance. Useful for testing when the server & testing script
   are both spawned in-process. Holds additional info on the contracts (whether
   it's a token). In the future, could be either removed (in favor of a
   file-based solution), or expanded (if an onchain addressProvider appears).

   How to use:
   1. Inherit Deployer.
   2. In run(), call outputDeployment() after deploying.

   Do not inherit other deployer scripts, just instantiate them and call their
   .deploy();
*/
abstract contract Deployer is Script {
  ToyENS ens; // singleton local ens instance
  ToyENS remoteEns; // out-of-band agreed upon toy ens address

  constructor() {
    // enforce singleton ENS, so all deploys can be collected in outputDeployment
    // otherwise Deployer scripts would need to inherit from one another
    // which would prevent deployer script composition
    ens = ToyENS(address(bytes20(hex"decaf1")));
    remoteEns = ToyENS(address(bytes20(hex"decaf0")));

    if (address(ens).code.length == 0) {
      vm.etch(address(ens), address(new ToyENS()).code);
    }
  }

  function outputDeployment() internal {
    (string[] memory names, address[] memory addrs, bool[] memory isToken) = ens
      .all();

    // toy ens is set, use it
    if (address(remoteEns).code.length > 0) {
      vm.broadcast();
      remoteEns.set(names, addrs, isToken);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "./Vm.sol";
import "./console.sol";
import "./console2.sol";

abstract contract Script {
  bool public IS_SCRIPT = true;
  address private constant VM_ADDRESS =
    address(bytes20(uint160(uint(keccak256("hevm cheat code")))));

  Vm public constant vm = Vm(VM_ADDRESS);

  /// @dev Compute the address a contract will be deployed at for a given deployer address and nonce
  /// @notice adapated from Solmate implementation (https://github.com/transmissions11/solmate/blob/main/src/utils/LibRLP.sol)
  function computeCreateAddress(address deployer, uint nonce)
    internal
    pure
    returns (address)
  {
    // The integer zero is treated as an empty byte string, and as a result it only has a length prefix, 0x80, computed via 0x80 + 0.
    // A one byte integer uses its own value as its length prefix, there is no additional "0x80 + length" prefix that comes before it.
    if (nonce == 0x00)
      return
        addressFromLast20Bytes(
          keccak256(
            abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, bytes1(0x80))
          )
        );
    if (nonce <= 0x7f)
      return
        addressFromLast20Bytes(
          keccak256(
            abi.encodePacked(bytes1(0xd6), bytes1(0x94), deployer, uint8(nonce))
          )
        );

    // Nonces greater than 1 byte all follow a consistent encoding scheme, where each value is preceded by a prefix of 0x80 + length.
    if (nonce <= 2**8 - 1)
      return
        addressFromLast20Bytes(
          keccak256(
            abi.encodePacked(
              bytes1(0xd7),
              bytes1(0x94),
              deployer,
              bytes1(0x81),
              uint8(nonce)
            )
          )
        );
    if (nonce <= 2**16 - 1)
      return
        addressFromLast20Bytes(
          keccak256(
            abi.encodePacked(
              bytes1(0xd8),
              bytes1(0x94),
              deployer,
              bytes1(0x82),
              uint16(nonce)
            )
          )
        );
    if (nonce <= 2**24 - 1)
      return
        addressFromLast20Bytes(
          keccak256(
            abi.encodePacked(
              bytes1(0xd9),
              bytes1(0x94),
              deployer,
              bytes1(0x83),
              uint24(nonce)
            )
          )
        );

    // More details about RLP encoding can be found here: https://eth.wiki/fundamentals/rlp
    // 0xda = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x84 ++ nonce)
    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
    // 0x84 = 0x80 + 0x04 (0x04 = the bytes length of the nonce, 4 bytes, in hex)
    // We assume nobody can have a nonce large enough to require more than 32 bytes.
    return
      addressFromLast20Bytes(
        keccak256(
          abi.encodePacked(
            bytes1(0xda),
            bytes1(0x94),
            deployer,
            bytes1(0x84),
            uint32(nonce)
          )
        )
      );
  }

  function addressFromLast20Bytes(bytes32 bytesValue)
    internal
    pure
    returns (address)
  {
    return address(uint160(uint(bytesValue)));
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// Mangrove.sol

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
import {MgvLib as ML, P} from "./MgvLib.sol";

import {AbstractMangrove} from "./AbstractMangrove.sol";

/* <a id="Mangrove"></a> The `Mangrove` contract implements the "normal" version of Mangrove, where the taker flashloans the desired amount to each maker. Each time, makers are called after the loan. When the order is complete, each maker is called once again (with the orderbook unlocked). */
contract Mangrove is AbstractMangrove {
  constructor(
    address governance,
    uint gasprice,
    uint gasmax
  ) AbstractMangrove(governance, gasprice, gasmax, "Mangrove") {}

  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    override
  {}

  function beforePosthook(ML.SingleOrder memory sor) internal override {}

  /* ## Flashloan */
  /*
     `flashloan` is for the 'normal' mode of operation. It:
     1. Flashloans `takerGives` `inbound_tkn` from the taker to the maker and returns false if the loan fails.
     2. Runs `offerDetail.maker`'s `execute` function.
     3. Returns the result of the operations, with optional makerData to help the maker debug.
   */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    override
    returns (uint gasused)
  {
    unchecked {
      /* `flashloan` must be used with a call (hence the `external` modifier) so its effect can be reverted. But a call from the outside would be fatal. */
      require(msg.sender == address(this), "mgv/flashloan/protected");
      /* The transfer taker -> maker is in 2 steps. First, taker->mgv. Then
       mgv->maker. With a direct taker->maker transfer, if one of taker/maker
       is blacklisted, we can't tell which one. We need to know which one:
       if we incorrectly blame the taker, a blacklisted maker can block a pair forever; if we incorrectly blame the maker, a blacklisted taker can unfairly make makers fail all the time. Of course we assume that Mangrove is not blacklisted. This 2-step transfer is incompatible with tokens that have transfer fees (more accurately, it uselessly incurs fees twice). */
      if (transferTokenFrom(sor.inbound_tkn, taker, address(this), sor.gives)) {
        if (
          transferToken(sor.inbound_tkn, sor.offerDetail.maker(), sor.gives)
        ) {
          gasused = makerExecute(sor);
        } else {
          innerRevert([bytes32("mgv/makerReceiveFail"), bytes32(0), ""]);
        }
      } else {
        innerRevert([bytes32("mgv/takerTransferFail"), "", ""]);
      }
    }
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

// SPDX-License-Identifier:	AGPL-3.0

// MgvCleaner.sol

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
  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty
    );

  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  ) external view returns (P.OfferStruct memory, P.OfferStruct memory);
}

/* The purpose of the Cleaner contract is to execute failing offers and collect
 * their associated bounty. It takes an array of offers with same definition as
 * `Mangrove.snipes` and expects them all to fail or not execute. */

/* How to use:
   1) Ensure *your* address approved Mangrove for the token you will provide to the offer (`inbound_tkn`).
   2) Run `collect` on the offers that you detected were failing.

   You can adjust takerWants/takerGives and gasreq as needed.

   Note: in the current version you do not need to set MgvCleaner's allowance in Mangrove.
   TODO: add `collectWith` with an additional `taker` argument.
*/
contract MgvCleaner {
  MangroveLike immutable MGV;

  constructor(address _MGV) {
    MGV = MangroveLike(_MGV);
  }

  receive() external payable {}

  /* Returns the entire balance, not just the bounty collected */
  function collect(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants
  ) external returns (uint bal) {
    unchecked {
      (uint successes, , , ) = MGV.snipesFor(
        outbound_tkn,
        inbound_tkn,
        targets,
        fillWants,
        msg.sender
      );
      require(successes == 0, "mgvCleaner/anOfferDidNotFail");
      bal = address(this).balance;
      bool noRevert;
      (noRevert, ) = msg.sender.call{value: bal}("");
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOracle.sol

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
import "../MgvLib.sol";

/* The purpose of the Oracle contract is to act as a gas price and density
 * oracle for the Mangrove. It bridges to an external oracle, and allows
 * a given sender to update the gas price and density which the oracle
 * reports to Mangrove. */
contract MgvOracle is IMgvMonitor {
  event SetGasprice(uint gasPrice);
  event SetDensity(uint density);

  address governance;
  address mutator;

  uint lastReceivedGasPrice;
  uint lastReceivedDensity;

  constructor(address _governance, address _initialMutator) {
    governance = _governance;
    mutator = _initialMutator;

    /* Set initial density from the MgvOracle to let Mangrove use its internal density by default.

      Mangrove will reject densities from the Monitor that don't fit in 32 bits and use its internal density instead, so setting this contract's density to `type(uint).max` is a way to let Mangrove deal with density on its own. */
    lastReceivedDensity = type(uint).max;
  }

  /* ## `authOnly` check */
  // NOTE: Should use standard auth method, instead of this copy from MgvGovernable

  function authOnly() internal view {
    require(
      msg.sender == governance ||
        msg.sender == address(this) ||
        governance == address(0),
      "MgvOracle/unauthorized"
    );
  }

  function notifySuccess(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    // Do nothing
  }

  function notifyFail(MgvLib.SingleOrder calldata sor, address taker)
    external
    override
  {
    // Do nothing
  }

  function setMutator(address _mutator) external {
    authOnly();

    mutator = _mutator;
  }

  function setGasPrice(uint gasPrice) external {
    // governance or mutator are allowed to update the gasprice
    require(
      msg.sender == governance || msg.sender == mutator,
      "MgvOracle/unauthorized"
    );

    lastReceivedGasPrice = gasPrice;
    emit SetGasprice(gasPrice);
  }

  function setDensity(uint density) external {
    // governance or mutator are allowed to update the density
    require(
      msg.sender == governance || msg.sender == mutator,
      "MgvOracle/unauthorized"
    );

    lastReceivedDensity = density;
    emit SetDensity(density);
  }

  function read(
    address, /*outbound_tkn*/
    address /*inbound_tkn*/
  ) external view override returns (uint gasprice, uint density) {
    return (lastReceivedGasPrice, lastReceivedDensity);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface Vm {
  struct Log {
    bytes32[] topics;
    bytes data;
  }

  // Sets block.timestamp (newTimestamp)
  function warp(uint) external;

  // Sets block.height (newHeight)
  function roll(uint) external;

  // Sets block.basefee (newBasefee)
  function fee(uint) external;

  // Sets block.chainid
  function chainId(uint) external;

  // Loads a storage slot from an address (who, slot)
  function load(address, bytes32) external returns (bytes32);

  // Stores a value to an address' storage slot, (who, slot, value)
  function store(
    address,
    bytes32,
    bytes32
  ) external;

  // Signs data, (privateKey, digest) => (v, r, s)
  function sign(uint, bytes32)
    external
    returns (
      uint8,
      bytes32,
      bytes32
    );

  // Gets the address for a given private key, (privateKey) => (address)
  function addr(uint) external returns (address);

  // Gets the nonce of an account
  function getNonce(address) external returns (uint64);

  // Sets the nonce of an account; must be higher than the current nonce of the account
  function setNonce(address, uint64) external;

  // Performs a foreign function call via the terminal, (stringInputs) => (result)
  function ffi(string[] calldata) external returns (bytes memory);

  // Sets environment variables, (name, value)
  function setEnv(string calldata, string calldata) external;

  // Reads environment variables, (name) => (value)
  function envBool(string calldata) external returns (bool);

  function envUint(string calldata) external returns (uint);

  function envInt(string calldata) external returns (int);

  function envAddress(string calldata) external returns (address);

  function envBytes32(string calldata) external returns (bytes32);

  function envString(string calldata) external returns (string memory);

  function envBytes(string calldata) external returns (bytes memory);

  // Reads environment variables as arrays, (name, delim) => (value[])
  function envBool(string calldata, string calldata)
    external
    returns (bool[] memory);

  function envUint(string calldata, string calldata)
    external
    returns (uint[] memory);

  function envInt(string calldata, string calldata)
    external
    returns (int[] memory);

  function envAddress(string calldata, string calldata)
    external
    returns (address[] memory);

  function envBytes32(string calldata, string calldata)
    external
    returns (bytes32[] memory);

  function envString(string calldata, string calldata)
    external
    returns (string[] memory);

  function envBytes(string calldata, string calldata)
    external
    returns (bytes[] memory);

  // Sets the *next* call's msg.sender to be the input address
  function prank(address) external;

  // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
  function startPrank(address) external;

  // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
  function prank(address, address) external;

  // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
  function startPrank(address, address) external;

  // Resets subsequent calls' msg.sender to be `address(this)`
  function stopPrank() external;

  // Sets an address' balance, (who, newBalance)
  function deal(address, uint) external;

  // Sets an address' code, (who, newCode)
  function etch(address, bytes calldata) external;

  // Expects an error on next call
  function expectRevert(bytes calldata) external;

  function expectRevert(bytes4) external;

  function expectRevert() external;

  // Records all storage reads and writes
  function record() external;

  // Gets all accessed reads and write slot from a recording session, for a given address
  function accesses(address)
    external
    returns (bytes32[] memory reads, bytes32[] memory writes);

  // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
  // Call this function, then emit an event, then call a function. Internally after the call, we check if
  // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
  function expectEmit(
    bool,
    bool,
    bool,
    bool
  ) external;

  function expectEmit(
    bool,
    bool,
    bool,
    bool,
    address
  ) external;

  // Mocks a call to an address, returning specified data.
  // Calldata can either be strict or a partial match, e.g. if you only
  // pass a Solidity selector to the expected calldata, then the entire Solidity
  // function will be mocked.
  function mockCall(
    address,
    bytes calldata,
    bytes calldata
  ) external;

  // Mocks a call to an address with a specific msg.value, returning specified data.
  // Calldata match takes precedence over msg.value in case of ambiguity.
  function mockCall(
    address,
    uint,
    bytes calldata,
    bytes calldata
  ) external;

  // Clears all mocked calls
  function clearMockedCalls() external;

  // Expects a call to an address with the specified calldata.
  // Calldata can either be a strict or a partial match
  function expectCall(address, bytes calldata) external;

  // Expects a call to an address with the specified msg.value and calldata
  function expectCall(
    address,
    uint,
    bytes calldata
  ) external;

  // Gets the code from an artifact file. Takes in the relative path to the json file
  function getCode(string calldata) external returns (bytes memory);

  // Labels an address in call traces
  function label(address, string calldata) external;

  // If the condition is false, discard this run's fuzz inputs and generate new ones
  function assume(bool) external;

  // Sets block.coinbase (who)
  function coinbase(address) external;

  // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
  function broadcast() external;

  // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
  function broadcast(address) external;

  // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
  function startBroadcast() external;

  // Has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
  function startBroadcast(address) external;

  // Stops collecting onchain transactions
  function stopBroadcast() external;

  // Reads the entire content of file to string, (path) => (data)
  function readFile(string calldata) external returns (string memory);

  // Reads next line of file to string, (path) => (line)
  function readLine(string calldata) external returns (string memory);

  // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
  // (path, data) => ()
  function writeFile(string calldata, string calldata) external;

  // Writes line to file, creating a file if it does not exist.
  // (path, data) => ()
  function writeLine(string calldata, string calldata) external;

  // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
  // (path) => ()
  function closeFile(string calldata) external;

  // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
  // - Path points to a directory.
  // - The file doesn't exist.
  // - The user lacks permissions to remove the file.
  // (path) => ()
  function removeFile(string calldata) external;

  // Convert values to a string, (value) => (stringified value)
  // VENDOR EDIT: added `pure`
  function toString(address) external pure returns (string memory);

  function toString(bytes calldata) external pure returns (string memory);

  function toString(bytes32) external pure returns (string memory);

  function toString(bool) external pure returns (string memory);

  function toString(uint) external pure returns (string memory);

  function toString(int) external pure returns (string memory);

  // Record all the transaction logs
  function recordLogs() external;

  // Gets all the recorded logs, () => (logs)
  function getRecordedLogs() external returns (Log[] memory);

  // Snapshot the current state of the evm.
  // Returns the id of the snapshot that was created.
  // To revert a snapshot use `revertTo`
  function snapshot() external returns (uint);

  // Revert the state of the evm to a previous snapshot
  // Takes the snapshot id to revert to.
  // This deletes the snapshot and all snapshots taken after the given snapshot id.
  function revertTo(uint) external returns (bool);

  // Creates a new fork with the given endpoint and block and returns the identifier of the fork
  function createFork(string calldata, uint) external returns (uint);

  // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
  function createFork(string calldata) external returns (uint);

  // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
  function createSelectFork(string calldata, uint) external returns (uint);

  // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
  function createSelectFork(string calldata) external returns (uint);

  // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
  function selectFork(uint) external;

  /// Returns the currently active fork
  /// Reverts if no fork is currently active
  function activeFork() external returns (uint);

  // Updates the currently active fork to given block number
  // This is similar to `roll` but for the currently active fork
  function rollFork(uint) external;

  // Updates the given fork to given block number
  function rollFork(uint forkId, uint blockNumber) external;

  /// Returns the RPC url for the given alias

  // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
  // Meaning, changes made to the state of this account will be kept when switching forks
  function makePersistent(address) external;

  function makePersistent(address, address) external;

  function makePersistent(
    address,
    address,
    address
  ) external;

  function makePersistent(address[] calldata) external;

  // Revokes persistent status from the address, previously added via `makePersistent`
  function revokePersistent(address) external;

  function revokePersistent(address[] calldata) external;

  // Returns true if the account is marked as persistent
  function isPersistent(address) external returns (bool);

  function rpcUrl(string calldata) external returns (string memory);

  /// Returns all rpc urls and their aliases `[alias, url][]`
  function rpcUrls() external returns (string[2][] memory);

  // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
  function deriveKey(string calldata, uint32) external returns (uint);

  // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path {path}{index}
  function deriveKey(
    string calldata,
    string calldata,
    uint32
  ) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
  address constant CONSOLE_ADDRESS =
    address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    /// @solidity memory-safe-assembly
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(
        gas(),
        consoleAddress,
        payloadStart,
        payloadLength,
        0,
        0
      )
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
  }

  function logUint(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
  }

  function log(uint p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
  }

  function log(uint p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
  }

  function log(uint p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
  }

  function log(string memory p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(
    uint p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
  }

  function log(
    uint p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
  }

  function log(
    uint p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
  }

  function log(
    uint p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
  }

  function log(
    uint p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,bool,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,uint,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,uint)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,uint,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,uint)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,uint)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,bool,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,uint)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// The orignal console.sol uses `int` and `uint` for computing function selectors, but it should
// use `int256` and `uint256`. This modified version fixes that. This version is recommended
// over `console.sol` if you don't need compatibility with Hardhat as the logs will show up in
// forge stack traces. If you do need compatibility with Hardhat, you must use `console.sol`.
// Reference: https://github.com/NomicFoundation/hardhat/issues/2178

library console2 {
  address constant CONSOLE_ADDRESS =
    address(0x000000000000000000636F6e736F6c652e6c6f67);

  function _sendLogPayload(bytes memory payload) private view {
    uint payloadLength = payload.length;
    address consoleAddress = CONSOLE_ADDRESS;
    assembly {
      let payloadStart := add(payload, 32)
      let r := staticcall(
        gas(),
        consoleAddress,
        payloadStart,
        payloadLength,
        0,
        0
      )
    }
  }

  function log() internal view {
    _sendLogPayload(abi.encodeWithSignature("log()"));
  }

  function logInt(int p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
  }

  function logUint(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function logString(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function logBool(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function logAddress(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function logBytes(bytes memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
  }

  function logBytes1(bytes1 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
  }

  function logBytes2(bytes2 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
  }

  function logBytes3(bytes3 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
  }

  function logBytes4(bytes4 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
  }

  function logBytes5(bytes5 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
  }

  function logBytes6(bytes6 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
  }

  function logBytes7(bytes7 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
  }

  function logBytes8(bytes8 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
  }

  function logBytes9(bytes9 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
  }

  function logBytes10(bytes10 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
  }

  function logBytes11(bytes11 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
  }

  function logBytes12(bytes12 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
  }

  function logBytes13(bytes13 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
  }

  function logBytes14(bytes14 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
  }

  function logBytes15(bytes15 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
  }

  function logBytes16(bytes16 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
  }

  function logBytes17(bytes17 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
  }

  function logBytes18(bytes18 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
  }

  function logBytes19(bytes19 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
  }

  function logBytes20(bytes20 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
  }

  function logBytes21(bytes21 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
  }

  function logBytes22(bytes22 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
  }

  function logBytes23(bytes23 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
  }

  function logBytes24(bytes24 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
  }

  function logBytes25(bytes25 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
  }

  function logBytes26(bytes26 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
  }

  function logBytes27(bytes27 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
  }

  function logBytes28(bytes28 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
  }

  function logBytes29(bytes29 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
  }

  function logBytes30(bytes30 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
  }

  function logBytes31(bytes31 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
  }

  function logBytes32(bytes32 p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
  }

  function log(uint p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
  }

  function log(string memory p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
  }

  function log(bool p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
  }

  function log(address p0) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
  }

  function log(uint p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
  }

  function log(uint p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
  }

  function log(uint p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
  }

  function log(uint p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
  }

  function log(string memory p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
  }

  function log(string memory p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
  }

  function log(string memory p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
  }

  function log(string memory p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
  }

  function log(bool p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
  }

  function log(bool p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
  }

  function log(bool p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
  }

  function log(bool p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
  }

  function log(address p0, uint p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
  }

  function log(address p0, string memory p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
  }

  function log(address p0, bool p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
  }

  function log(address p0, address p1) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
  }

  function log(
    uint p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
  }

  function log(
    bool p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    uint p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    uint p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    bool p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
    );
  }

  function log(
    address p0,
    address p1,
    address p2
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,string,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,bool,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,uint256,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,bool,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,string,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,bool,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    uint p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    uint p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(uint256,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,uint256,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,bool,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,bool,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,bool,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,bool,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    string memory p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    string memory p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(string,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,uint256,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,string,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,string,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,string,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    bool p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(bool,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,string,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,bool,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    uint p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    uint p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,uint256,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    string memory p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    string memory p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,string,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    bool p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,bool,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint256,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint256,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint256,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    uint p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,uint256,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    string memory p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,string,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,bool,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,bool,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3)
    );
  }

  function log(
    address p0,
    address p1,
    bool p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,bool,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    uint p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,uint256)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    string memory p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,string)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    bool p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,bool)",
        p0,
        p1,
        p2,
        p3
      )
    );
  }

  function log(
    address p0,
    address p1,
    address p2,
    address p3
  ) internal view {
    _sendLogPayload(
      abi.encodeWithSignature(
        "log(address,address,address,address)",
        p0,
        p1,
        p2,
        p3
      )
    );
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

// SPDX-License-Identifier:	AGPL-3.0

// AbstractMangrove.sol

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
import {MgvLib as ML} from "./MgvLib.sol";

import {MgvOfferMaking} from "./MgvOfferMaking.sol";
import {MgvOfferTakingWithPermit} from "./MgvOfferTakingWithPermit.sol";
import {MgvGovernable} from "./MgvGovernable.sol";

/* `AbstractMangrove` inherits the three contracts that implement generic Mangrove functionality (`MgvGovernable`,`MgvOfferTakingWithPermit` and `MgvOfferMaking`) but does not implement the abstract functions. */
abstract contract AbstractMangrove is
  MgvGovernable,
  MgvOfferTakingWithPermit,
  MgvOfferMaking
{
  constructor(
    address governance,
    uint gasprice,
    uint gasmax,
    string memory contractName
  )
    MgvOfferTakingWithPermit(contractName)
    MgvGovernable(governance, gasprice, gasmax)
  {}
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

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferMaking.sol

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
import {IMaker, HasMgvEvents, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

/* `MgvOfferMaking` contains market-making-related functions. */
contract MgvOfferMaking is MgvHasOffers {
  /* # Public Maker operations
     ## New Offer */
  //+clear+
  /* In the Mangrove, makers and takers call separate functions. Market makers call `newOffer` to fill the book, and takers call functions such as `marketOrder` to consume it.  */

  //+clear+

  /* The following structs holds offer creation/update parameters in memory. This frees up stack space for local variables. */
  struct OfferPack {
    address outbound_tkn;
    address inbound_tkn;
    uint wants;
    uint gives;
    uint id;
    uint gasreq;
    uint gasprice;
    uint pivotId;
    P.Global.t global;
    P.Local.t local;
    // used on update only
    P.Offer.t oldOffer;
  }

  /* The function `newOffer` is for market makers only; no match with the existing book is done. A maker specifies how much `inbound_tkn` it `wants` and how much `outbound_tkn` it `gives`.

     It also specify with `gasreq` how much gas should be given when executing their offer.

     `gasprice` indicates an upper bound on the gasprice at which the maker is ready to be penalised if their offer fails. Any value below the Mangrove's internal `gasprice` configuration value will be ignored.

    `gasreq`, together with `gasprice`, will contribute to determining the penalty provision set aside by the Mangrove from the market maker's `balanceOf` balance.

  Offers are always inserted at the correct place in the book. This requires walking through offers to find the correct insertion point. As in [Oasis](https://github.com/daifoundation/maker-otc/blob/f2060c5fe12fe3da71ac98e8f6acc06bca3698f5/src/matching_market.sol#L493), the maker should find the id of an offer close to its own and provide it as `pivotId`.

  An offer cannot be inserted in a closed market, nor when a reentrancy lock for `outbound_tkn`,`inbound_tkn` is on.

  No more than $2^{32}-1$ offers can ever be created for one `outbound_tkn`,`inbound_tkn` pair.

  The actual contents of the function is in `writeOffer`, which is called by both `newOffer` and `updateOffer`.
  */
  function newOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId
  ) external payable returns (uint) {
    unchecked {
      /* In preparation for calling `writeOffer`, we read the `outbound_tkn`,`inbound_tkn` pair configuration, check for reentrancy and market liveness, fill the `OfferPack` struct and increment the `outbound_tkn`,`inbound_tkn` pair's `last`. */
      OfferPack memory ofp;
      (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
      unlockedMarketOnly(ofp.local);
      activeMarketOnly(ofp.global, ofp.local);
      if (msg.value > 0) {
        creditWei(msg.sender, msg.value);
      }

      ofp.id = 1 + ofp.local.last();
      require(uint32(ofp.id) == ofp.id, "mgv/offerIdOverflow");

      ofp.local = ofp.local.last(ofp.id);

      ofp.outbound_tkn = outbound_tkn;
      ofp.inbound_tkn = inbound_tkn;
      ofp.wants = wants;
      ofp.gives = gives;
      ofp.gasreq = gasreq;
      ofp.gasprice = gasprice;
      ofp.pivotId = pivotId;

      /* The second parameter to writeOffer indicates that we are creating a new offer, not updating an existing one. */
      writeOffer(ofp, false);

      /* Since we locally modified a field of the local configuration (`last`), we save the change to storage. Note that `writeOffer` may have further modified the local configuration by updating the current `best` offer. */
      locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
      return ofp.id;
    }
  }

  /* ## Update Offer */
  //+clear+
  /* Very similar to `newOffer`, `updateOffer` prepares an `OfferPack` for `writeOffer`. Makers should use it for updating live offers, but also to save on gas by reusing old, already consumed offers.

     A `pivotId` should still be given to minimise reads in the offer book. It is OK to give the offers' own id as a pivot.


     Gas use is minimal when:
     1. The offer does not move in the book
     2. The offer does not change its `gasreq`
     3. The (`outbound_tkn`,`inbound_tkn`)'s `offer_gasbase` has not changed since the offer was last written
     4. `gasprice` has not changed since the offer was last written
     5. `gasprice` is greater than the Mangrove's gasprice estimation
  */
  function updateOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint wants,
    uint gives,
    uint gasreq,
    uint gasprice,
    uint pivotId,
    uint offerId
  ) external payable {
    unchecked {
      OfferPack memory ofp;
      (ofp.global, ofp.local) = config(outbound_tkn, inbound_tkn);
      unlockedMarketOnly(ofp.local);
      activeMarketOnly(ofp.global, ofp.local);
      if (msg.value > 0) {
        creditWei(msg.sender, msg.value);
      }
      ofp.outbound_tkn = outbound_tkn;
      ofp.inbound_tkn = inbound_tkn;
      ofp.wants = wants;
      ofp.gives = gives;
      ofp.id = offerId;
      ofp.gasreq = gasreq;
      ofp.gasprice = gasprice;
      ofp.pivotId = pivotId;
      ofp.oldOffer = offers[outbound_tkn][inbound_tkn][offerId];
      // Save local config
      P.Local.t oldLocal = ofp.local;
      /* The second argument indicates that we are updating an existing offer, not creating a new one. */
      writeOffer(ofp, true);
      /* We saved the current pair's configuration before calling `writeOffer`, since that function may update the current `best` offer. We now check for any change to the configuration and update it if needed. */
      if (!oldLocal.eq(ofp.local)) {
        locals[ofp.outbound_tkn][ofp.inbound_tkn] = ofp.local;
      }
    }
  }

  /* ## Retract Offer */
  //+clear+
  /* `retractOffer` takes the offer `offerId` out of the book. However, `deprovision == true` also refunds the provision associated with the offer. */
  function retractOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    bool deprovision
  ) external returns (uint provision) {
    unchecked {
      (, P.Local.t local) = config(outbound_tkn, inbound_tkn);
      unlockedMarketOnly(local);
      P.Offer.t offer = offers[outbound_tkn][inbound_tkn][offerId];
      P.OfferDetail.t offerDetail = offerDetails[outbound_tkn][inbound_tkn][
        offerId
      ];
      require(
        msg.sender == offerDetail.maker(),
        "mgv/retractOffer/unauthorized"
      );

      /* Here, we are about to un-live an offer, so we start by taking it out of the book by stitching together its previous and next offers. Note that unconditionally calling `stitchOffers` would break the book since it would connect offers that may have since moved. */
      if (isLive(offer)) {
        P.Local.t oldLocal = local;
        local = stitchOffers(
          outbound_tkn,
          inbound_tkn,
          offer.prev(),
          offer.next(),
          local
        );
        /* If calling `stitchOffers` has changed the current `best` offer, we update the storage. */
        if (!oldLocal.eq(local)) {
          locals[outbound_tkn][inbound_tkn] = local;
        }
      }
      /* Set `gives` to 0. Moreover, the last argument depends on whether the user wishes to get their provision back (if true, `gasprice` will be set to 0 as well). */
      dirtyDeleteOffer(
        outbound_tkn,
        inbound_tkn,
        offerId,
        offer,
        offerDetail,
        deprovision
      );

      /* If the user wants to get their provision back, we compute its provision from the offer's `gasprice`, `offer_gasbase` and `gasreq`. */
      if (deprovision) {
        provision =
          10**9 *
          offerDetail.gasprice() * //gasprice is 0 if offer was deprovisioned
          (offerDetail.gasreq() + offerDetail.offer_gasbase());
        // credit `balanceOf` and log transfer
        creditWei(msg.sender, provision);
      }
      emit OfferRetract(outbound_tkn, inbound_tkn, offerId);
    }
  }

  /* ## Provisioning
  Market makers must have enough provisions for possible penalties. These provisions are in ETH. Every time a new offer is created or an offer is updated, `balanceOf` is adjusted to provision the offer's maximum possible penalty (`gasprice * (gasreq + offer_gasbase)`).

  For instance, if the current `balanceOf` of a maker is 1 ether and they create an offer that requires a provision of 0.01 ethers, their `balanceOf` will be reduced to 0.99 ethers. No ethers will move; this is just an internal accounting movement to make sure the maker cannot `withdraw` the provisioned amounts.

  */
  //+clear+

  /* Fund should be called with a nonzero value (hence the `payable` modifier). The provision will be given to `maker`, not `msg.sender`. */
  function fund(address maker) public payable {
    unchecked {
      (P.Global.t _global, ) = config(address(0), address(0));
      liveMgvOnly(_global);
      creditWei(maker, msg.value);
    }
  }

  function fund() external payable {
    unchecked {
      fund(msg.sender);
    }
  }

  /* A transfer with enough gas to the Mangrove will increase the caller's available `balanceOf` balance. _You should send enough gas to execute this function when sending money to the Mangrove._  */
  receive() external payable {
    unchecked {
      fund(msg.sender);
    }
  }

  /* Any provision not currently held to secure an offer's possible penalty is available for withdrawal. */
  function withdraw(uint amount) external returns (bool noRevert) {
    unchecked {
      /* Since we only ever send money to the caller, we do not need to provide any particular amount of gas, the caller should manage this herself. */
      debitWei(msg.sender, amount);
      (noRevert, ) = msg.sender.call{value: amount}("");
    }
  }

  /* # Low-level Maker functions */

  /* ## Write Offer */

  function writeOffer(OfferPack memory ofp, bool update) internal {
    unchecked {
      /* `gasprice`'s floor is Mangrove's own gasprice estimate, `ofp.global.gasprice`. We first check that gasprice fits in 16 bits. Otherwise it could be that `uint16(gasprice) < global_gasprice < gasprice`, and the actual value we store is `uint16(gasprice)`. */
      require(checkGasprice(ofp.gasprice), "mgv/writeOffer/gasprice/16bits");

      if (ofp.gasprice < ofp.global.gasprice()) {
        ofp.gasprice = ofp.global.gasprice();
      }

      /* * Check `gasreq` below limit. Implies `gasreq` at most 24 bits wide, which ensures no overflow in computation of `provision` (see below). */
      require(
        ofp.gasreq <= ofp.global.gasmax(),
        "mgv/writeOffer/gasreq/tooHigh"
      );
      /* * Make sure `gives > 0` -- division by 0 would throw in several places otherwise, and `isLive` relies on it. */
      require(ofp.gives > 0, "mgv/writeOffer/gives/tooLow");
      /* * Make sure that the maker is posting a 'dense enough' offer: the ratio of `outbound_tkn` offered per gas consumed must be high enough. The actual gas cost paid by the taker is overapproximated by adding `offer_gasbase` to `gasreq`. */
      require(
        ofp.gives >=
          (ofp.gasreq + ofp.local.offer_gasbase()) * ofp.local.density(),
        "mgv/writeOffer/density/tooLow"
      );

      /* The following checks are for the maker's convenience only. */
      require(uint96(ofp.gives) == ofp.gives, "mgv/writeOffer/gives/96bits");
      require(uint96(ofp.wants) == ofp.wants, "mgv/writeOffer/wants/96bits");

      /* The position of the new or updated offer is found using `findPosition`. If the offer is the best one, `prev == 0`, and if it's the last in the book, `next == 0`.

       `findPosition` is only ever called here, but exists as a separate function to make the code easier to read.

    **Warning**: `findPosition` will call `better`, which may read the offer's `offerDetails`. So it is important to find the offer position _before_ we update its `offerDetail` in storage. We waste 1 (hot) read in that case but we deem that the code would get too ugly if we passed the old `offerDetail` as argument to `findPosition` and to `better`, just to save 1 hot read in that specific case.  */
      (uint prev, uint next) = findPosition(ofp);

      /* Log the write offer event. */
      emit OfferWrite(
        ofp.outbound_tkn,
        ofp.inbound_tkn,
        msg.sender,
        ofp.wants,
        ofp.gives,
        ofp.gasprice,
        ofp.gasreq,
        ofp.id,
        prev
      );

      /* We now write the new `offerDetails` and remember the previous provision (0 by default, for new offers) to balance out maker's `balanceOf`. */
      uint oldProvision;
      {
        P.OfferDetail.t offerDetail = offerDetails[ofp.outbound_tkn][
          ofp.inbound_tkn
        ][ofp.id];
        if (update) {
          require(
            msg.sender == offerDetail.maker(),
            "mgv/updateOffer/unauthorized"
          );
          oldProvision =
            10**9 *
            offerDetail.gasprice() *
            (offerDetail.gasreq() + offerDetail.offer_gasbase());
        }

        /* If the offer is new, has a new `gasprice`, `gasreq`, or if the Mangrove's `offer_gasbase` configuration parameter has changed, we also update `offerDetails`. */
        if (
          !update ||
          offerDetail.gasreq() != ofp.gasreq ||
          offerDetail.gasprice() != ofp.gasprice ||
          offerDetail.offer_gasbase() != ofp.local.offer_gasbase()
        ) {
          uint offer_gasbase = ofp.local.offer_gasbase();
          offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = P
            .OfferDetail
            .pack({
              __maker: msg.sender,
              __gasreq: ofp.gasreq,
              __offer_gasbase: offer_gasbase,
              __gasprice: ofp.gasprice
            });
        }
      }

      /* With every change to an offer, a maker may deduct provisions from its `balanceOf` balance. It may also get provisions back if the updated offer requires fewer provisions than before. */
      {
        uint provision = (ofp.gasreq + ofp.local.offer_gasbase()) *
          ofp.gasprice *
          10**9;
        if (provision > oldProvision) {
          debitWei(msg.sender, provision - oldProvision);
        } else if (provision < oldProvision) {
          creditWei(msg.sender, oldProvision - provision);
        }
      }
      /* We now place the offer in the book at the position found by `findPosition`. */

      /* First, we test if the offer has moved in the book or is not currently in the book. If `!isLive(ofp.oldOffer)`, we must update its prev/next. If it is live but its prev has changed, we must also update them. Note that checking both `prev = oldPrev` and `next == oldNext` would be redundant. If either is true, then the updated offer has not changed position and there is nothing to update.

    As a note for future changes, there is a tricky edge case where `prev == oldPrev` yet the prev/next should be changed: a previously-used offer being brought back in the book, and ending with the same prev it had when it was in the book. In that case, the neighbor is currently pointing to _another_ offer, and thus must be updated. With the current code structure, this is taken care of as a side-effect of checking `!isLive`, but should be kept in mind. The same goes in the `next == oldNext` case. */
      if (!isLive(ofp.oldOffer) || prev != ofp.oldOffer.prev()) {
        /* * If the offer is not the best one, we update its predecessor; otherwise we update the `best` value. */
        if (prev != 0) {
          offers[ofp.outbound_tkn][ofp.inbound_tkn][prev] = offers[
            ofp.outbound_tkn
          ][ofp.inbound_tkn][prev].next(ofp.id);
        } else {
          ofp.local = ofp.local.best(ofp.id);
        }

        /* * If the offer is not the last one, we update its successor. */
        if (next != 0) {
          offers[ofp.outbound_tkn][ofp.inbound_tkn][next] = offers[
            ofp.outbound_tkn
          ][ofp.inbound_tkn][next].prev(ofp.id);
        }

        /* * Recall that in this branch, the offer has changed location, or is not currently in the book. If the offer is not new and already in the book, we must remove it from its previous location by stitching its previous prev/next. */
        if (update && isLive(ofp.oldOffer)) {
          ofp.local = stitchOffers(
            ofp.outbound_tkn,
            ofp.inbound_tkn,
            ofp.oldOffer.prev(),
            ofp.oldOffer.next(),
            ofp.local
          );
        }
      }

      /* With the `prev`/`next` in hand, we finally store the offer in the `offers` map. */
      P.Offer.t ofr = P.Offer.pack({
        __prev: prev,
        __next: next,
        __wants: ofp.wants,
        __gives: ofp.gives
      });
      offers[ofp.outbound_tkn][ofp.inbound_tkn][ofp.id] = ofr;
    }
  }

  /* ## Find Position */
  /* `findPosition` takes a price in the form of a (`ofp.wants`,`ofp.gives`) pair, an offer id (`ofp.pivotId`) and walks the book from that offer (backward or forward) until the right position for the price is found. The position is returned as a `(prev,next)` pair, with `prev` or `next` at 0 to mark the beginning/end of the book (no offer ever has id 0).

  If prices are equal, `findPosition` will put the newest offer last. */
  function findPosition(OfferPack memory ofp)
    internal
    view
    returns (uint, uint)
  {
    unchecked {
      uint prevId;
      uint nextId;
      uint pivotId = ofp.pivotId;
      /* Get `pivot`, optimizing for the case where pivot info is already known */
      P.Offer.t pivot = pivotId == ofp.id
        ? ofp.oldOffer
        : offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];

      /* In case pivotId is not an active offer, it is unusable (since it is out of the book). We default to the current best offer. If the book is empty pivot will be 0. That is handled through a test in the `better` comparison function. */
      if (!isLive(pivot)) {
        pivotId = ofp.local.best();
        pivot = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotId];
      }

      /* * Pivot is better than `wants/gives`, we follow `next`. */
      if (better(ofp, pivot, pivotId)) {
        P.Offer.t pivotNext;
        while (pivot.next() != 0) {
          uint pivotNextId = pivot.next();
          pivotNext = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotNextId];
          if (better(ofp, pivotNext, pivotNextId)) {
            pivotId = pivotNextId;
            pivot = pivotNext;
          } else {
            break;
          }
        }
        // gets here on empty book
        (prevId, nextId) = (pivotId, pivot.next());

        /* * Pivot is strictly worse than `wants/gives`, we follow `prev`. */
      } else {
        P.Offer.t pivotPrev;
        while (pivot.prev() != 0) {
          uint pivotPrevId = pivot.prev();
          pivotPrev = offers[ofp.outbound_tkn][ofp.inbound_tkn][pivotPrevId];
          if (better(ofp, pivotPrev, pivotPrevId)) {
            break;
          } else {
            pivotId = pivotPrevId;
            pivot = pivotPrev;
          }
        }

        (prevId, nextId) = (pivot.prev(), pivotId);
      }

      return (
        prevId == ofp.id ? ofp.oldOffer.prev() : prevId,
        nextId == ofp.id ? ofp.oldOffer.next() : nextId
      );
    }
  }

  /* ## Better */
  /* The utility method `better` takes an offer represented by `ofp` and another represented by `offer1`. It returns true iff `offer1` is better or as good as `ofp`.
    "better" is defined on the lexicographic order $\textrm{price} \times_{\textrm{lex}} \textrm{density}^{-1}$. This means that for the same price, offers that deliver more volume per gas are taken first.

      In addition to `offer1`, we also provide its id, `offerId1` in order to save gas. If necessary (ie. if the prices `wants1/gives1` and `wants2/gives2` are the same), we read storage to get `gasreq1` at `offerDetails[...][offerId1]. */
  function better(
    OfferPack memory ofp,
    P.Offer.t offer1,
    uint offerId1
  ) internal view returns (bool) {
    unchecked {
      if (offerId1 == 0) {
        /* Happens on empty book. Returning `false` would work as well due to specifics of `findPosition` but true is more consistent. Here we just want to avoid reading `offerDetail[...][0]` for nothing. */
        return true;
      }
      uint wants1 = offer1.wants();
      uint gives1 = offer1.gives();
      uint wants2 = ofp.wants;
      uint gives2 = ofp.gives;
      uint weight1 = wants1 * gives2;
      uint weight2 = wants2 * gives1;
      if (weight1 == weight2) {
        uint gasreq1 = offerDetails[ofp.outbound_tkn][ofp.inbound_tkn][offerId1]
          .gasreq();
        uint gasreq2 = ofp.gasreq;
        return (gives1 * gasreq2 >= gives2 * gasreq1);
      } else {
        return weight1 < weight2;
      }
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTakingWithPermit.sol

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
import {HasMgvEvents} from "./MgvLib.sol";

import {MgvOfferTaking} from "./MgvOfferTaking.sol";

abstract contract MgvOfferTakingWithPermit is MgvOfferTaking {
  /* Takers may provide allowances on specific pairs, so other addresses can execute orders in their name. Allowance may be set using the usual `approve` function, or through an [EIP712](https://eips.ethereum.org/EIPS/eip-712) `permit`.

  The mapping is `outbound_tkn => inbound_tkn => owner => spender => allowance` */
  mapping(address => mapping(address => mapping(address => mapping(address => uint))))
    public allowances;
  /* Storing nonces avoids replay attacks. */
  mapping(address => uint) public nonces;
  /* Following [EIP712](https://eips.ethereum.org/EIPS/eip-712), structured data signing has `keccak256("Permit(address outbound_tkn,address inbound_tkn,address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")` in its prefix. */
  bytes32 public constant PERMIT_TYPEHASH =
    0xb7bf278e51ab1478b10530c0300f911d9ed3562fc93ab5e6593368fe23c077a2;
  /* Initialized in the constructor, `DOMAIN_SEPARATOR` avoids cross-application permit reuse. */
  bytes32 public immutable DOMAIN_SEPARATOR;

  constructor(string memory contractName) {
    /* Initialize [EIP712](https://eips.ethereum.org/EIPS/eip-712) `DOMAIN_SEPARATOR`. */
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(contractName)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
      )
    );
  }

  /* # Delegation public functions */

  /* Adapted from [Uniswap v2 contract](https://github.com/Uniswap/uniswap-v2-core/blob/55ae25109b7918565867e5c39f1e84b7edd19b2a/contracts/UniswapV2ERC20.sol#L81) */
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
  ) external {
    unchecked {
      require(deadline >= block.timestamp, "mgv/permit/expired");

      uint nonce = nonces[owner]++;
      bytes32 digest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          DOMAIN_SEPARATOR,
          keccak256(
            abi.encode(
              PERMIT_TYPEHASH,
              outbound_tkn,
              inbound_tkn,
              owner,
              spender,
              value,
              nonce,
              deadline
            )
          )
        )
      );
      address recoveredAddress = ecrecover(digest, v, r, s);
      require(
        recoveredAddress != address(0) && recoveredAddress == owner,
        "mgv/permit/invalidSignature"
      );

      allowances[outbound_tkn][inbound_tkn][owner][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, owner, spender, value);
    }
  }

  function approve(
    address outbound_tkn,
    address inbound_tkn,
    address spender,
    uint value
  ) external returns (bool) {
    unchecked {
      allowances[outbound_tkn][inbound_tkn][msg.sender][spender] = value;
      emit Approval(outbound_tkn, inbound_tkn, msg.sender, spender, value);
      return true;
    }
  }

  /* The delegate version of `marketOrder` is `marketOrderFor`, which takes a `taker` address as additional argument. Penalties incurred by failed offers will still be sent to `msg.sender`, but exchanged amounts will be transferred from and to the `taker`. If the `msg.sender`'s allowance for the given `outbound_tkn`,`inbound_tkn` and `taker` are strictly less than the total amount eventually spent by `taker`, the call will fail. */

  /* *Note:* `marketOrderFor` and `snipesFor` may emit ERC20 `Transfer` events of value 0 from `taker`, but that's already the case with common ERC20 implementations. */
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
      uint feePaid
    )
  {
    unchecked {
      (takerGot, takerGave, bounty, feePaid) = generalMarketOrder(
        outbound_tkn,
        inbound_tkn,
        takerWants,
        takerGives,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that `takerGave` rather than `takerGives` is checked against the allowance. The former may be lower. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* The delegate version of `snipes` is `snipesFor`, which takes a `taker` address as additional argument. */
  function snipesFor(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    external
    returns (
      uint successes,
      uint takerGot,
      uint takerGave,
      uint bounty,
      uint feePaid
    )
  {
    unchecked {
      (successes, takerGot, takerGave, bounty, feePaid) = generalSnipes(
        outbound_tkn,
        inbound_tkn,
        targets,
        fillWants,
        taker
      );
      /* The sender's allowance is verified after the order complete so that the actual amounts are checked against the allowance, instead of the declared `takerGives`. The former may be lower.
    
    An immediate consequence is that any funds availale to Mangrove through `approve` can be used to clean offers. After a `snipesFor` where all offers have failed, all token transfers have been reverted, so `takerGave=0` and the check will succeed -- but the sender will still have received the bounty of the failing offers. */
      deductSenderAllowance(outbound_tkn, inbound_tkn, taker, takerGave);
    }
  }

  /* # Misc. low-level functions */

  /* Used by `*For` functions, its both checks that `msg.sender` was allowed to use the taker's funds, and decreases the former's allowance. */
  function deductSenderAllowance(
    address outbound_tkn,
    address inbound_tkn,
    address owner,
    uint amount
  ) internal {
    unchecked {
      uint allowed = allowances[outbound_tkn][inbound_tkn][owner][msg.sender];
      require(allowed >= amount, "mgv/lowAllowance");
      allowances[outbound_tkn][inbound_tkn][owner][msg.sender] =
        allowed -
        amount;

      emit Approval(
        outbound_tkn,
        inbound_tkn,
        owner,
        msg.sender,
        allowed - amount
      );
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvGovernable.sol

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
import {HasMgvEvents, P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

contract MgvGovernable is MgvRoot {
  /* The `governance` address. Governance is the only address that can configure parameters. */
  address public governance;

  constructor(
    address _governance,
    uint _gasprice,
    uint gasmax
  ) MgvRoot() {
    unchecked {
      emit NewMgv();

      /* Initially, governance is open to anyone. */

      /* Initialize vault to governance address, and set initial gasprice and gasmax. */
      setVault(_governance);
      setGasprice(_gasprice);
      setGasmax(gasmax);
      /* Initialize governance to `_governance` after parameter setting. */
      setGovernance(_governance);
    }
  }

  /* ## `authOnly` check */

  function authOnly() internal view {
    unchecked {
      require(
        msg.sender == governance ||
          msg.sender == address(this) ||
          governance == address(0),
        "mgv/unauthorized"
      );
    }
  }

  /* # Set configuration and Mangrove state */

  /* ## Locals */
  /* ### `active` */
  function activate(
    address outbound_tkn,
    address inbound_tkn,
    uint fee,
    uint density,
    uint offer_gasbase
  ) public {
    unchecked {
      authOnly();
      locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn]
        .active(true);
      emit SetActive(outbound_tkn, inbound_tkn, true);
      setFee(outbound_tkn, inbound_tkn, fee);
      setDensity(outbound_tkn, inbound_tkn, density);
      setGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
    }
  }

  function deactivate(address outbound_tkn, address inbound_tkn) public {
    authOnly();
    locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn]
      .active(false);
    emit SetActive(outbound_tkn, inbound_tkn, false);
  }

  /* ### `fee` */
  function setFee(
    address outbound_tkn,
    address inbound_tkn,
    uint fee
  ) public {
    unchecked {
      authOnly();
      /* `fee` is in basis points, i.e. in percents of a percent. */
      require(fee <= 500, "mgv/config/fee/<=500"); // at most 5%
      locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn].fee(
        fee
      );
      emit SetFee(outbound_tkn, inbound_tkn, fee);
    }
  }

  /* ### `density` */
  /* Useless if `global.useOracle != 0` */
  function setDensity(
    address outbound_tkn,
    address inbound_tkn,
    uint density
  ) public {
    unchecked {
      authOnly();

      require(checkDensity(density), "mgv/config/density/112bits");
      //+clear+
      locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn]
        .density(density);
      emit SetDensity(outbound_tkn, inbound_tkn, density);
    }
  }

  /* ### `gasbase` */
  function setGasbase(
    address outbound_tkn,
    address inbound_tkn,
    uint offer_gasbase
  ) public {
    unchecked {
      authOnly();
      /* Checking the size of `offer_gasbase` is necessary to prevent a) data loss when copied to an `OfferDetail` struct, and b) overflow when used in calculations. */
      require(
        uint24(offer_gasbase) == offer_gasbase,
        "mgv/config/offer_gasbase/24bits"
      );
      //+clear+
      locals[outbound_tkn][inbound_tkn] = locals[outbound_tkn][inbound_tkn]
        .offer_gasbase(offer_gasbase);
      emit SetGasbase(outbound_tkn, inbound_tkn, offer_gasbase);
    }
  }

  /* ## Globals */
  /* ### `kill` */
  function kill() public {
    unchecked {
      authOnly();
      internal_global = internal_global.dead(true);
      emit Kill();
    }
  }

  /* ### `gasprice` */
  /* Useless if `global.useOracle is != 0` */
  function setGasprice(uint gasprice) public {
    unchecked {
      authOnly();
      require(checkGasprice(gasprice), "mgv/config/gasprice/16bits");

      //+clear+

      internal_global = internal_global.gasprice(gasprice);
      emit SetGasprice(gasprice);
    }
  }

  /* ### `gasmax` */
  function setGasmax(uint gasmax) public {
    unchecked {
      authOnly();
      /* Since any new `gasreq` is bounded above by `config.gasmax`, this check implies that all offers' `gasreq` is 24 bits wide at most. */
      require(uint24(gasmax) == gasmax, "mgv/config/gasmax/24bits");
      //+clear+
      internal_global = internal_global.gasmax(gasmax);
      emit SetGasmax(gasmax);
    }
  }

  /* ### `governance` */
  function setGovernance(address governanceAddress) public {
    unchecked {
      authOnly();
      require(governanceAddress != address(0), "mgv/config/gov/not0");
      governance = governanceAddress;
      emit SetGovernance(governanceAddress);
    }
  }

  /* ### `vault` */
  function setVault(address vaultAddress) public {
    unchecked {
      authOnly();
      vault = vaultAddress;
      emit SetVault(vaultAddress);
    }
  }

  /* ### `monitor` */
  function setMonitor(address monitor) public {
    unchecked {
      authOnly();
      internal_global = internal_global.monitor(monitor);
      emit SetMonitor(monitor);
    }
  }

  /* ### `useOracle` */
  function setUseOracle(bool useOracle) public {
    unchecked {
      authOnly();
      internal_global = internal_global.useOracle(useOracle);
      emit SetUseOracle(useOracle);
    }
  }

  /* ### `notify` */
  function setNotify(bool notify) public {
    unchecked {
      authOnly();
      internal_global = internal_global.notify(notify);
      emit SetNotify(notify);
    }
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

// SPDX-License-Identifier:	AGPL-3.0

// MgvHasOffers.sol

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
import {MgvLib as ML, HasMgvEvents, IMgvMonitor, P} from "./MgvLib.sol";
import {MgvRoot} from "./MgvRoot.sol";

/* `MgvHasOffers` contains the state variables and functions common to both market-maker operations and market-taker operations. Mostly: storing offers, removing them, updating market makers' provisions. */
contract MgvHasOffers is MgvRoot {
  /* # State variables */
  /* Given a `outbound_tkn`,`inbound_tkn` pair, the mappings `offers` and `offerDetails` associate two 256 bits words to each offer id. Those words encode information detailed in [`structs.js`](#structs.js).

     The mappings are `outbound_tkn => inbound_tkn => offerId => P.Offer.t|P.OfferDetail.t`.
   */
  mapping(address => mapping(address => mapping(uint => P.Offer.t)))
    public offers;
  mapping(address => mapping(address => mapping(uint => P.OfferDetail.t)))
    public offerDetails;

  /* Makers provision their possible penalties in the `balanceOf` mapping.

       Offers specify the amount of gas they require for successful execution ([`gasreq`](#structs.js/gasreq)). To minimize book spamming, market makers must provision a *penalty*, which depends on their `gasreq` and on the pair's [`offer_gasbase`](#structs.js/gasbase). This provision is deducted from their `balanceOf`. If an offer fails, part of that provision is given to the taker, as retribution. The exact amount depends on the gas used by the offer before failing.

       The Mangrove keeps track of their available balance in the `balanceOf` map, which is decremented every time a maker creates a new offer, and may be modified on offer updates/cancelations/takings.
     */
  mapping(address => uint) public balanceOf;

  /* # Read functions */
  /* Convenience function to get best offer of the given pair */
  function best(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (uint)
  {
    unchecked {
      P.Local.t local = locals[outbound_tkn][inbound_tkn];
      return local.best();
    }
  }

  /* Returns information about an offer in ABI-compatible structs. Do not use internally, would be a huge memory-copying waste. Use `offers[outbound_tkn][inbound_tkn]` and `offerDetails[outbound_tkn][inbound_tkn]` instead. */
  function offerInfo(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId
  )
    external
    view
    returns (P.OfferStruct memory offer, P.OfferDetailStruct memory offerDetail)
  {
    unchecked {
      P.Offer.t _offer = offers[outbound_tkn][inbound_tkn][offerId];
      offer = _offer.to_struct();

      P.OfferDetail.t _offerDetail = offerDetails[outbound_tkn][inbound_tkn][
        offerId
      ];
      offerDetail = _offerDetail.to_struct();
    }
  }

  /* # Provision debit/credit utility functions */
  /* `balanceOf` is in wei of ETH. */

  function debitWei(address maker, uint amount) internal {
    unchecked {
      uint makerBalance = balanceOf[maker];
      require(makerBalance >= amount, "mgv/insufficientProvision");
      balanceOf[maker] = makerBalance - amount;
      emit Debit(maker, amount);
    }
  }

  function creditWei(address maker, uint amount) internal {
    unchecked {
      balanceOf[maker] += amount;
      emit Credit(maker, amount);
    }
  }

  /* # Misc. low-level functions */
  /* ## Offer deletion */

  /* When an offer is deleted, it is marked as such by setting `gives` to 0. Note that provision accounting in the Mangrove aims to minimize writes. Each maker `fund`s the Mangrove to increase its balance. When an offer is created/updated, we compute how much should be reserved to pay for possible penalties. That amount can always be recomputed with `offerDetail.gasprice * (offerDetail.gasreq + offerDetail.offer_gasbase)`. The balance is updated to reflect the remaining available ethers.

     Now, when an offer is deleted, the offer can stay provisioned, or be `deprovision`ed. In the latter case, we set `gasprice` to 0, which induces a provision of 0. All code calling `dirtyDeleteOffer` with `deprovision` set to `true` must be careful to correctly account for where that provision is going (back to the maker's `balanceOf`, or sent to a taker as compensation). */
  function dirtyDeleteOffer(
    address outbound_tkn,
    address inbound_tkn,
    uint offerId,
    P.Offer.t offer,
    P.OfferDetail.t offerDetail,
    bool deprovision
  ) internal {
    unchecked {
      offer = offer.gives(0);
      if (deprovision) {
        offerDetail = offerDetail.gasprice(0);
      }
      offers[outbound_tkn][inbound_tkn][offerId] = offer;
      offerDetails[outbound_tkn][inbound_tkn][offerId] = offerDetail;
    }
  }

  /* ## Stitching the orderbook */

  /* Connect the offers `betterId` and `worseId` through their `next`/`prev` pointers. For more on the book structure, see [`structs.js`](#structs.js). Used after executing an offer (or a segment of offers), after removing an offer, or moving an offer.

  **Warning**: calling with `betterId = 0` will set `worseId` as the best. So with `betterId = 0` and `worseId = 0`, it sets the book to empty and loses track of existing offers.

  **Warning**: may make memory copy of `local.best` stale. Returns new `local`. */
  function stitchOffers(
    address outbound_tkn,
    address inbound_tkn,
    uint betterId,
    uint worseId,
    P.Local.t local
  ) internal returns (P.Local.t) {
    unchecked {
      if (betterId != 0) {
        offers[outbound_tkn][inbound_tkn][betterId] = offers[outbound_tkn][
          inbound_tkn
        ][betterId].next(worseId);
      } else {
        local = local.best(worseId);
      }

      if (worseId != 0) {
        offers[outbound_tkn][inbound_tkn][worseId] = offers[outbound_tkn][
          inbound_tkn
        ][worseId].prev(betterId);
      }

      return local;
    }
  }

  /* ## Check offer is live */
  /* Check whether an offer is 'live', that is: inserted in the order book. The Mangrove holds a `outbound_tkn => inbound_tkn => id => P.Offer.t` mapping in storage. Offer ids that are not yet assigned or that point to since-deleted offer will point to an offer with `gives` field at 0. */
  function isLive(P.Offer.t offer) public pure returns (bool) {
    unchecked {
      return offer.gives() > 0;
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvOfferTaking.sol

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
import {IERC20, HasMgvEvents, IMaker, IMgvMonitor, MgvLib as ML, P} from "./MgvLib.sol";
import {MgvHasOffers} from "./MgvHasOffers.sol";

abstract contract MgvOfferTaking is MgvHasOffers {
  /* # MultiOrder struct */
  /* The `MultiOrder` struct is used by market orders and snipes. Some of its fields are only used by market orders (`initialWants, initialGives`). We need a common data structure for both since low-level calls are shared between market orders and snipes. The struct is helpful in decreasing stack use. */
  struct MultiOrder {
    uint initialWants; // used globally by market order, not used by snipes
    uint initialGives; // used globally by market order, not used by snipes
    uint totalGot; // used globally by market order, per-offer by snipes
    uint totalGave; // used globally by market order, per-offer by snipes
    uint totalPenalty; // used globally
    address taker; // used globally
    bool fillWants; // used globally
    uint feePaid; // used globally
  }

  /* # Market Orders */

  /* ## Market Order */
  //+clear+

  /* A market order specifies a (`outbound_tkn`,`inbound_tkn`) pair, a desired total amount of `outbound_tkn` (`takerWants`), and an available total amount of `inbound_tkn` (`takerGives`). It returns four `uint`s: the total amount of `outbound_tkn` received, the total amount of `inbound_tkn` spent, the penalty received by msg.sender (in wei), and the fee paid by the taker (in wei).

     The `takerGives/takerWants` ratio induces a maximum average price that the taker is ready to pay across all offers that will be executed during the market order. It is thus possible to execute an offer with a price worse than the initial (`takerGives`/`takerWants`) ratio given as argument to `marketOrder` if some cheaper offers were executed earlier in the market order.

  The market order stops when the price has become too high, or when the end of the book has been reached, or:
  * If `fillWants` is true, the market order stops when `takerWants` units of `outbound_tkn` have been obtained. With `fillWants` set to true, to buy a specific volume of `outbound_tkn` at any price, set `takerWants` to the amount desired and `takerGives` to $2^{160}-1$.
  * If `fillWants` is false, the taker is filling `gives` instead: the market order stops when `takerGives` units of `inbound_tkn` have been sold. With `fillWants` set to false, to sell a specific volume of `inbound_tkn` at any price, set `takerGives` to the amount desired and `takerWants` to $0$. */
  function marketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint,
      uint
    )
  {
    unchecked {
      return
        generalMarketOrder(
          outbound_tkn,
          inbound_tkn,
          takerWants,
          takerGives,
          fillWants,
          msg.sender
        );
    }
  }

  /* # General Market Order */
  //+clear+
  /* General market orders set up the market order with a given `taker` (`msg.sender` in the most common case). Returns `(totalGot, totalGave, penaltyReceived, feePaid)`.
  Note that the `taker` can be anyone. This is safe when `taker == msg.sender`, but `generalMarketOrder` must not be called with `taker != msg.sender` unless a security check is done after (see [`MgvOfferTakingWithPermit`](#mgvoffertakingwithpermit.sol)`. */
  function generalMarketOrder(
    address outbound_tkn,
    address inbound_tkn,
    uint takerWants,
    uint takerGives,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint,
      uint,
      uint,
      uint
    )
  {
    unchecked {
      /* Since amounts stored in offers are 96 bits wide, checking that `takerWants` and `takerGives` fit in 160 bits prevents overflow during the main market order loop. */
      require(
        uint160(takerWants) == takerWants,
        "mgv/mOrder/takerWants/160bits"
      );
      require(
        uint160(takerGives) == takerGives,
        "mgv/mOrder/takerGives/160bits"
      );

      /* `SingleOrder` is defined in `MgvLib.sol` and holds information for ordering the execution of one offer. */
      ML.SingleOrder memory sor;
      sor.outbound_tkn = outbound_tkn;
      sor.inbound_tkn = inbound_tkn;
      (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);
      /* Throughout the execution of the market order, the `sor`'s offer id and other parameters will change. We start with the current best offer id (0 if the book is empty). */
      sor.offerId = sor.local.best();
      sor.offer = offers[outbound_tkn][inbound_tkn][sor.offerId];
      /* `sor.wants` and `sor.gives` may evolve, but they are initially however much remains in the market order. */
      sor.wants = takerWants;
      sor.gives = takerGives;

      /* `MultiOrder` (defined above) maintains information related to the entire market order. During the order, initial `wants`/`gives` values minus the accumulated amounts traded so far give the amounts that remain to be traded. */
      MultiOrder memory mor;
      mor.initialWants = takerWants;
      mor.initialGives = takerGives;
      mor.taker = taker;
      mor.fillWants = fillWants;

      /* For the market order to even start, the market needs to be both active, and not currently protected from reentrancy. */
      activeMarketOnly(sor.global, sor.local);
      unlockedMarketOnly(sor.local);

      /* ### Initialization */
      /* The market order will operate as follows : it will go through offers from best to worse, starting from `offerId`, and: */
      /* * will maintain remaining `takerWants` and `takerGives` values. The initial `takerGives/takerWants` ratio is the average price the taker will accept. Better prices may be found early in the book, and worse ones later.
       * will not set `prev`/`next` pointers to their correct locations at each offer taken (this is an optimization enabled by forbidding reentrancy).
       * after consuming a segment of offers, will update the current `best` offer to be the best remaining offer on the book. */

      /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
      sor.local = sor.local.lock(true);
      locals[outbound_tkn][inbound_tkn] = sor.local;

      emit OrderStart();

      /* Call recursive `internalMarketOrder` function.*/
      internalMarketOrder(mor, sor, true);

      /* Over the course of the market order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
      sendPenalty(mor.totalPenalty);

      emit OrderComplete(
        outbound_tkn,
        inbound_tkn,
        taker,
        mor.totalGot,
        mor.totalGave,
        mor.totalPenalty,
        mor.feePaid
      );

      //+clear+
      return (mor.totalGot, mor.totalGave, mor.totalPenalty, mor.feePaid);
    }
  }

  /* ## Internal market order */
  //+clear+
  /* `internalMarketOrder` works recursively. Going downward, each successive offer is executed until the market order stops (due to: volume exhausted, bad price, or empty book). Then the [reentrancy lock is lifted](#internalMarketOrder/liftReentrancy). Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book.

    The last argument is a boolean named `proceed`. If an offer was not executed, it means the price has become too high. In that case, we notify the next recursive call that the market order should end. In this initial call, no offer has been executed yet so `proceed` is true. */
  function internalMarketOrder(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    bool proceed
  ) internal {
    unchecked {
      /* #### Case 1 : End of order */
      /* We execute the offer currently stored in `sor`. */
      if (
        proceed &&
        (mor.fillWants ? sor.wants > 0 : sor.gives > 0) &&
        sor.offerId > 0
      ) {
        uint gasused; // gas used by `makerExecute`
        bytes32 makerData; // data returned by maker

        /* <a id="MgvOfferTaking/statusCodes"></a> `mgvData` is an internal Mangrove status code. It may appear in an [`OrderResult`](#MgvLib/OrderResult). Its possible values are:
      * `"mgv/notExecuted"`: offer was not executed.
      * `"mgv/tradeSuccess"`: offer execution succeeded. Will appear in `OrderResult`.
      * `"mgv/notEnoughGasForMakerTrade"`: cannot give maker close enough to `gasreq`. Triggers a revert of the entire order.
      * `"mgv/makerRevert"`: execution of `makerExecute` reverted. Will appear in `OrderResult`.
      * `"mgv/makerTransferFail"`: maker could not send outbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/makerReceiveFail"`: maker could not receive inbound_tkn tokens. Will appear in `OrderResult`.
      * `"mgv/takerTransferFail"`: taker could not send inbound_tkn tokens. Triggers a revert of the entire order.

      `mgvData` should not be exploitable by the maker! */
        bytes32 mgvData;

        /* Load additional information about the offer. We don't do it earlier to save one storage read in case `proceed` was false. */
        sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
          sor.offerId
        ];

        /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way, [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/notExecuted","mgv/tradeSuccess"]` means the failure is the maker's fault. */
        /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. We will need it after the recursive call, so we save it in local variables. Same goes for `offerId`, `sor.offer` and `sor.offerDetail`. */

        (gasused, makerData, mgvData) = execute(mor, sor);

        /* Keep cached copy of current `sor` values. */
        uint takerWants = sor.wants;
        uint takerGives = sor.gives;
        uint offerId = sor.offerId;
        P.Offer.t offer = sor.offer;
        P.OfferDetail.t offerDetail = sor.offerDetail;

        /* If an execution was attempted, we move `sor` to the next offer. Note that the current state is inconsistent, since we have not yet updated `sor.offerDetails`. */
        if (mgvData != "mgv/notExecuted") {
          sor.wants = mor.initialWants > mor.totalGot
            ? mor.initialWants - mor.totalGot
            : 0;
          /* It is known statically that `mor.initialGives - mor.totalGave` does not underflow since
           1. `mor.totalGave` was increased by `sor.gives` during `execute`,
           2. `sor.gives` was at most `mor.initialGives - mor.totalGave` from earlier step,
           3. `sor.gives` may have been clamped _down_ during `execute` (to "`offer.wants`" if the offer is entirely consumed, or to `makerWouldWant`, cf. code of `execute`).
        */
          sor.gives = mor.initialGives - mor.totalGave;
          sor.offerId = sor.offer.next();
          sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
        }

        /* note that internalMarketOrder may be called twice with same offerId, but in that case `proceed` will be false! */
        internalMarketOrder(
          mor,
          sor,
          /* `proceed` value for next call. Currently, when an offer did not execute, it's because the offer's price was too high. In that case we interrupt the loop and let the taker leave with less than they asked for (but at a correct price). We could also revert instead of breaking; this could be a configurable flag for the taker to pick. */
          mgvData != "mgv/notExecuted"
        );

        /* Restore `sor` values from to before recursive call */
        sor.offerId = offerId;
        sor.wants = takerWants;
        sor.gives = takerGives;
        sor.offer = offer;
        sor.offerDetail = offerDetail;

        /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
        if (mgvData != "mgv/notExecuted") {
          postExecute(mor, sor, gasused, makerData, mgvData);
        }

        /* #### Case 2 : End of market order */
        /* If `proceed` is false, the taker has gotten its requested volume, or we have reached the end of the book, we conclude the market order. */
      } else {
        /* During the market order, all executed offers have been removed from the book. We end by stitching together the `best` offer pointer and the new best offer. */
        sor.local = stitchOffers(
          sor.outbound_tkn,
          sor.inbound_tkn,
          0,
          sor.offerId,
          sor.local
        );
        /* <a id="internalMarketOrder/liftReentrancy"></a>Now that the market order is over, we can lift the lock on the book. In the same operation we

      * lift the reentrancy lock, and
      * update the storage

      so we are free from out of order storage writes.
      */
        sor.local = sor.local.lock(false);
        locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

        /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
        payTakerMinusFees(mor, sor);

        /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
        executeEnd(mor, sor);
      }
    }
  }

  /* # Sniping */
  /* ## Snipes */
  //+clear+

  /* `snipes` executes multiple offers. It takes a `uint[4][]` as penultimate argument, with each array element of the form `[offerId,takerWants,takerGives,offerGasreq]`. The return parameters are of the form `(successes,snipesGot,snipesGave,bounty,feePaid)`. 
  Note that we do not distinguish further between mismatched arguments/offer fields on the one hand, and an execution failure on the other. Still, a failed offer has to pay a penalty, and ultimately transaction logs explicitly mention execution failures (see `MgvLib.sol`). */
  function snipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants
  )
    external
    returns (
      uint,
      uint,
      uint,
      uint,
      uint
    )
  {
    unchecked {
      return
        generalSnipes(
          outbound_tkn,
          inbound_tkn,
          targets,
          fillWants,
          msg.sender
        );
    }
  }

  /*
     From an array of _n_ `[offerId, takerWants,takerGives,gasreq]` elements, execute each snipe in sequence. Returns `(successes, takerGot, takerGave, bounty, feePaid)`. 

     Note that if this function is not internal, anyone can make anyone use Mangrove.
     Note that unlike general market order, the returned total values are _not_ `mor.totalGot` and `mor.totalGave`, since those are reset at every iteration of the `targets` array. Instead, accumulators `snipesGot` and `snipesGave` are used. */
  function generalSnipes(
    address outbound_tkn,
    address inbound_tkn,
    uint[4][] calldata targets,
    bool fillWants,
    address taker
  )
    internal
    returns (
      uint successCount,
      uint snipesGot,
      uint snipesGave,
      uint totalPenalty,
      uint feePaid
    )
  {
    unchecked {
      ML.SingleOrder memory sor;
      sor.outbound_tkn = outbound_tkn;
      sor.inbound_tkn = inbound_tkn;
      (sor.global, sor.local) = config(outbound_tkn, inbound_tkn);

      MultiOrder memory mor;
      mor.taker = taker;
      mor.fillWants = fillWants;

      /* For the snipes to even start, the market needs to be both active and not currently protected from reentrancy. */
      activeMarketOnly(sor.global, sor.local);
      unlockedMarketOnly(sor.local);

      emit OrderStart();

      /* ### Main loop */
      //+clear+

      /* Call `internalSnipes` function. */
      (successCount, snipesGot, snipesGave) = internalSnipes(mor, sor, targets);

      /* Over the course of the snipes order, a penalty reserved for `msg.sender` has accumulated in `mor.totalPenalty`. No actual transfers have occured yet -- all the ethers given by the makers as provision are owned by the Mangrove. `sendPenalty` finally gives the accumulated penalty to `msg.sender`. */
      sendPenalty(mor.totalPenalty);
      //+clear+

      emit OrderComplete(
        sor.outbound_tkn,
        sor.inbound_tkn,
        taker,
        snipesGot,
        snipesGave,
        mor.totalPenalty,
        mor.feePaid
      );
      totalPenalty = mor.totalPenalty;
      feePaid = mor.feePaid;
    }
  }

  /* ## Internal snipes */
  //+clear+
  /* `internalSnipes` works by looping over targets. Each successive offer is executed under a [reentrancy lock](#internalSnipes/liftReentrancy), then its posthook is called. Going upward, each offer's `maker` contract is called again with its remaining gas and given the chance to update its offers on the book. */
  function internalSnipes(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint[4][] calldata targets
  )
    internal
    returns (
      uint successCount,
      uint snipesGot,
      uint snipesGave
    )
  {
    unchecked {
      for (uint i = 0; i < targets.length; i++) {
        /* Reset these amounts since every snipe is treated individually. Only the total penalty is sent at the end of all snipes. */
        mor.totalGot = 0;
        mor.totalGave = 0;

        /* Initialize single order struct. */
        sor.offerId = targets[i][0];
        sor.offer = offers[sor.outbound_tkn][sor.inbound_tkn][sor.offerId];
        sor.offerDetail = offerDetails[sor.outbound_tkn][sor.inbound_tkn][
          sor.offerId
        ];

        /* If we removed the `isLive` conditional, a single expired or nonexistent offer in `targets` would revert the entire transaction (by the division by `offer.gives` below since `offer.gives` would be 0). We also check that `gasreq` is not worse than specified. A taker who does not care about `gasreq` can specify any amount larger than $2^{24}-1$. A mismatched price will be detected by `execute`. */
        if (!isLive(sor.offer) || sor.offerDetail.gasreq() > targets[i][3]) {
          /* We move on to the next offer in the array. */
          continue;
        } else {
          require(
            uint96(targets[i][1]) == targets[i][1],
            "mgv/snipes/takerWants/96bits"
          );
          require(
            uint96(targets[i][2]) == targets[i][2],
            "mgv/snipes/takerGives/96bits"
          );
          sor.wants = targets[i][1];
          sor.gives = targets[i][2];

          /* We start be enabling the reentrancy lock for this (`outbound_tkn`,`inbound_tkn`) pair. */
          sor.local = sor.local.lock(true);
          locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

          /* `execute` will adjust `sor.wants`,`sor.gives`, and may attempt to execute the offer if its price is low enough. It is crucial that an error due to `taker` triggers a revert. That way [`mgvData`](#MgvOfferTaking/statusCodes) not in `["mgv/tradeSuccess","mgv/notExecuted"]` means the failure is the maker's fault. */
          /* Post-execution, `sor.wants`/`sor.gives` reflect how much was sent/taken by the offer. */
          (uint gasused, bytes32 makerData, bytes32 mgvData) = execute(
            mor,
            sor
          );

          if (mgvData == "mgv/tradeSuccess") {
            successCount += 1;
          }

          /* In the market order, we were able to avoid stitching back offers after every `execute` since we knew a continuous segment starting at best would be consumed. Here, we cannot do this optimisation since offers in the `targets` array may be anywhere in the book. So we stitch together offers immediately after each `execute`. */
          if (mgvData != "mgv/notExecuted") {
            sor.local = stitchOffers(
              sor.outbound_tkn,
              sor.inbound_tkn,
              sor.offer.prev(),
              sor.offer.next(),
              sor.local
            );
          }

          /* <a id="internalSnipes/liftReentrancy"></a> Now that the current snipe is over, we can lift the lock on the book. In the same operation we
        * lift the reentrancy lock, and
        * update the storage

        so we are free from out of order storage writes.
        */
          sor.local = sor.local.lock(false);
          locals[sor.outbound_tkn][sor.inbound_tkn] = sor.local;

          /* `payTakerMinusFees` sends the fee to the vault, proportional to the amount purchased, and gives the rest to the taker */
          payTakerMinusFees(mor, sor);

          /* In an inverted Mangrove, amounts have been lent by each offer's maker to the taker. We now call the taker. This is a noop in a normal Mangrove. */
          executeEnd(mor, sor);

          /* After an offer execution, we may run callbacks and increase the total penalty. As that part is common to market orders and snipes, it lives in its own `postExecute` function. */
          if (mgvData != "mgv/notExecuted") {
            postExecute(mor, sor, gasused, makerData, mgvData);
          }

          snipesGot += mor.totalGot;
          snipesGave += mor.totalGave;
        }
      }
    }
  }

  /* # General execution */
  /* During a market order or a snipes, offers get executed. The following code takes care of executing a single offer with parameters given by a `SingleOrder` within a larger context given by a `MultiOrder`. */

  /* ## Execute */
  /* This function will compare `sor.wants` `sor.gives` with `sor.offer.wants` and `sor.offer.gives`. If the price of the offer is low enough, an execution will be attempted (with volume limited by the offer's advertised volume).

     Summary of the meaning of the return values:
    * `gasused` is the gas consumed by the execution
    * `makerData` is the data returned after executing the offer
    * `mgvData` is an [internal Mangrove status code](#MgvOfferTaking/statusCodes).
  */
  function execute(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    returns (
      uint gasused,
      bytes32 makerData,
      bytes32 mgvData
    )
  {
    unchecked {
      /* #### `Price comparison` */
      //+clear+
      /* The current offer has a price `p = offerWants ÷ offerGives` and the taker is ready to accept a price up to `p' = takerGives ÷ takerWants`. Comparing `offerWants * takerWants` and `offerGives * takerGives` tels us whether `p < p'`.
       */
      {
        uint offerWants = sor.offer.wants();
        uint offerGives = sor.offer.gives();
        uint takerWants = sor.wants;
        uint takerGives = sor.gives;
        /* <a id="MgvOfferTaking/checkPrice"></a>If the price is too high, we return early.

         Otherwise we now know we'll execute the offer. */
        if (offerWants * takerWants > offerGives * takerGives) {
          return (0, bytes32(0), "mgv/notExecuted");
        }

        /* ### Specification of value transfers:

      Let $o_w$ be `offerWants`, $o_g$ be `offerGives`, $t_w$ be `takerWants`, $t_g$ be `takerGives`, and `f ∈ {w,g}` be $w$ if `fillWants` is true, $g$ otherwise.

      Let $\textrm{got}$ be the amount that the taker will receive, and $\textrm{gave}$ be the amount that the taker will pay.

      #### Case $f = w$

      If $f = w$, let $\textrm{got} = \min(o_g,t_w)$, and let $\textrm{gave} = \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil$. This is well-defined since, for live offers, $o_g > 0$.

      In plain english, we only give to the taker up to what they wanted (or what the offer has to give), and follow the offer price to determine what the taker will give.

      Since $\textrm{gave}$ is rounded up, the price might be overevaluated. Still, we cannot spend more than what the taker specified as `takerGives`. At this point [we know](#MgvOfferTaking/checkPrice) that $o_w t_w \leq o_g t_g$, so since $t_g$ is an integer we have
      
      $t_g \geq \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil \geq \left\lceil\dfrac{o_w \textrm{got}}{o_g}\right\rceil = \textrm{gave}$.


      #### Case $f = g$

      If $f = g$, let $\textrm{gave} = \min(o_w,t_g)$, and $\textrm{got} = o_g$ if $o_w = 0$, $\textrm{got} = \left\lfloor\dfrac{o_g \textrm{gave}}{o_w}\right\rfloor$ otherwise.

      In plain english, we spend up to what the taker agreed to pay (or what the offer wants), and follow the offer price to determine what the taker will get. This may exceed $t_w$.

      #### Price adjustment

      Prices are rounded up to ensure maker is not drained on small amounts. It's economically unlikely, but `density` protects the taker from being drained anyway so it is better to default towards protecting the maker here.
      */

        /*
      ### Implementation

      First we check the cases $(f=w \wedge o_g < t_w)\vee(f_g \wedge o_w < t_g)$, in which case the above spec simplifies to $\textrm{got} = o_g, \textrm{gave} = o_w$.

      Otherwise the offer may be partially consumed.
      
      In the case $f=w$ we don't touch $\textrm{got}$ (which was initialized to $t_w$) and compute $\textrm{gave} = \left\lceil\dfrac{o_w t_w}{o_g}\right\rceil$. As shown above we have $\textrm{gave} \leq t_g$.

      In the case $f=g$ we don't touch $\textrm{gave}$ (which was initialized to $t_g$) and compute $\textrm{got} = o_g$ if $o_w = 0$, and $\textrm{got} = \left\lfloor\dfrac{o_g t_g}{o_w}\right\rfloor$ otherwise.
      */
        if (
          (mor.fillWants && offerGives < takerWants) ||
          (!mor.fillWants && offerWants < takerGives)
        ) {
          sor.wants = offerGives;
          sor.gives = offerWants;
        } else {
          if (mor.fillWants) {
            uint product = offerWants * takerWants;
            sor.gives =
              product /
              offerGives +
              (product % offerGives == 0 ? 0 : 1);
          } else {
            if (offerWants == 0) {
              sor.wants = offerGives;
            } else {
              sor.wants = (offerGives * takerGives) / offerWants;
            }
          }
        }
      }
      /* The flashloan is executed by call to `flashloan`. If the call reverts, it means the maker failed to send back `sor.wants` `outbound_tkn` to the taker. Notes :
       * `msg.sender` is the Mangrove itself in those calls -- all operations related to the actual caller should be done outside of this call.
       * any spurious exception due to an error in Mangrove code will be falsely blamed on the Maker, and its provision for the offer will be unfairly taken away.
       */
      (bool success, bytes memory retdata) = address(this).call(
        abi.encodeWithSelector(this.flashloan.selector, sor, mor.taker)
      );

      /* `success` is true: trade is complete */
      if (success) {
        /* In case of success, `retdata` encodes the gas used by the offer. */
        gasused = abi.decode(retdata, (uint));
        /* `mgvData` indicates trade success */
        mgvData = bytes32("mgv/tradeSuccess");
        emit OfferSuccess(
          sor.outbound_tkn,
          sor.inbound_tkn,
          sor.offerId,
          mor.taker,
          sor.wants,
          sor.gives
        );

        /* If configured to do so, the Mangrove notifies an external contract that a successful trade has taken place. */
        if (sor.global.notify()) {
          IMgvMonitor(sor.global.monitor()).notifySuccess(sor, mor.taker);
        }

        /* We update the totals in the multiorder based on the adjusted `sor.wants`/`sor.gives`. */
        /* overflow: sor.{wants,gives} are on 96bits, sor.total{Got,Gave} are on 256 bits. */
        mor.totalGot += sor.wants;
        mor.totalGave += sor.gives;
      } else {
        /* In case of failure, `retdata` encodes a short [status code](#MgvOfferTaking/statusCodes), the gas used by the offer, and an arbitrary 256 bits word sent by the maker.  */
        (mgvData, gasused, makerData) = innerDecode(retdata);
        /* Note that in the `if`s, the literals are bytes32 (stack values), while as revert arguments, they are strings (memory pointers). */
        if (
          mgvData == "mgv/makerRevert" ||
          mgvData == "mgv/makerTransferFail" ||
          mgvData == "mgv/makerReceiveFail"
        ) {
          emit OfferFail(
            sor.outbound_tkn,
            sor.inbound_tkn,
            sor.offerId,
            mor.taker,
            sor.wants,
            sor.gives,
            mgvData
          );

          /* If configured to do so, the Mangrove notifies an external contract that a failed trade has taken place. */
          if (sor.global.notify()) {
            IMgvMonitor(sor.global.monitor()).notifyFail(sor, mor.taker);
          }
          /* It is crucial that any error code which indicates an error caused by the taker triggers a revert, because functions that call `execute` consider that `mgvData` not in `["mgv/notExecuted","mgv/tradeSuccess"]` should be blamed on the maker. */
        } else if (mgvData == "mgv/notEnoughGasForMakerTrade") {
          revert("mgv/notEnoughGasForMakerTrade");
        } else if (mgvData == "mgv/takerTransferFail") {
          revert("mgv/takerTransferFail");
        } else {
          /* This code must be unreachable. **Danger**: if a well-crafted offer/maker pair can force a revert of `flashloan`, the Mangrove will be stuck. */
          revert("mgv/swapError");
        }
      }

      /* Delete the offer. The last argument indicates whether the offer should be stripped of its provision (yes if execution failed, no otherwise). We cannot partially strip an offer provision (for instance, remove only the penalty from a failing offer and leave the rest) since the provision associated with an offer is always deduced from the (gasprice,gasbase,gasreq) parameters and not stored independently. We delete offers whether the amount remaining on offer is > density or not for the sake of uniformity (code is much simpler). We also expect prices to move often enough that the maker will want to update their price anyway. To simulate leaving the remaining volume in the offer, the maker can program their `makerPosthook` to `updateOffer` and put the remaining volume back in. */
      dirtyDeleteOffer(
        sor.outbound_tkn,
        sor.inbound_tkn,
        sor.offerId,
        sor.offer,
        sor.offerDetail,
        mgvData != "mgv/tradeSuccess"
      );
    }
  }

  /* ## flashloan (abstract) */
  /* Externally called by `execute`, flashloan lends money (from the taker to the maker, or from the maker to the taker, depending on the implementation) then calls `makerExecute` to run the maker liquidity fetching code. If `makerExecute` is unsuccessful, `flashloan` reverts (but the larger orderbook traversal will continue). 

  All `flashloan` implementations must `require(msg.sender) == address(this))`. */
  function flashloan(ML.SingleOrder calldata sor, address taker)
    external
    virtual
    returns (uint gasused);

  /* ## Maker Execute */
  /* Called by `flashloan`, `makerExecute` runs the maker code and checks that it can safely send the desired assets to the taker. */

  function makerExecute(ML.SingleOrder calldata sor)
    internal
    returns (uint gasused)
  {
    unchecked {
      bytes memory cd = abi.encodeWithSelector(
        IMaker.makerExecute.selector,
        sor
      );

      uint gasreq = sor.offerDetail.gasreq();
      address maker = sor.offerDetail.maker();
      uint oldGas = gasleft();
      /* We let the maker pay for the overhead of checking remaining gas and making the call, as well as handling the return data (constant gas since only the first 32 bytes of return data are read). So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
      /* Note : as a possible future feature, we could stop an order when there's not enough gas left to continue processing offers. This could be done safely by checking, as soon as we start processing an offer, whether `63/64(gasleft-offer_gasbase) > gasreq`. If no, we could stop and know by induction that there is enough gas left to apply fees, stitch offers, etc for the offers already executed. */
      if (!(oldGas - oldGas / 64 >= gasreq)) {
        innerRevert([bytes32("mgv/notEnoughGasForMakerTrade"), "", ""]);
      }

      (bool callSuccess, bytes32 makerData) = controlledCall(maker, gasreq, cd);

      gasused = oldGas - gasleft();

      if (!callSuccess) {
        innerRevert([bytes32("mgv/makerRevert"), bytes32(gasused), makerData]);
      }

      bool transferSuccess = transferTokenFrom(
        sor.outbound_tkn,
        maker,
        address(this),
        sor.wants
      );

      if (!transferSuccess) {
        innerRevert(
          [bytes32("mgv/makerTransferFail"), bytes32(gasused), makerData]
        );
      }
    }
  }

  /* ## executeEnd (abstract) */
  /* Called by `internalSnipes` and `internalMarketOrder`, `executeEnd` may run implementation-specific code after all makers have been called once. In [`InvertedMangrove`](#InvertedMangrove), the function calls the taker once so they can act on their flashloan. In [`Mangrove`], it does nothing. */
  function executeEnd(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
    virtual;

  /* ## Post execute */
  /* At this point, we know `mgvData != "mgv/notExecuted"`. After executing an offer (whether in a market order or in snipes), we
     1. Call the maker's posthook and sum the total gas used.
     2. If offer failed: sum total penalty due to msg.sender and give remainder to maker.
   */
  function postExecute(
    MultiOrder memory mor,
    ML.SingleOrder memory sor,
    uint gasused,
    bytes32 makerData,
    bytes32 mgvData
  ) internal {
    unchecked {
      if (mgvData == "mgv/tradeSuccess") {
        beforePosthook(sor);
      }

      uint gasreq = sor.offerDetail.gasreq();

      /* We are about to call back the maker, giving it its unused gas (`gasreq - gasused`). Since the gas used so far may exceed `gasreq`, we prevent underflow in the subtraction below by bounding `gasused` above with `gasreq`. We could have decided not to call back the maker at all when there is no gas left, but we do it for uniformity. */
      if (gasused > gasreq) {
        gasused = gasreq;
      }

      gasused =
        gasused +
        makerPosthook(sor, gasreq - gasused, makerData, mgvData);

      if (mgvData != "mgv/tradeSuccess") {
        mor.totalPenalty += applyPenalty(sor, gasused);
      }
    }
  }

  /* ## beforePosthook (abstract) */
  /* Called by `makerPosthook`, this function can run implementation-specific code before calling the maker has been called a second time. In [`InvertedMangrove`](#InvertedMangrove), all makers are called once so the taker gets all of its money in one shot. Then makers are traversed again and the money is sent back to each taker using `beforePosthook`. In [`Mangrove`](#Mangrove), `beforePosthook` does nothing. */

  function beforePosthook(ML.SingleOrder memory sor) internal virtual;

  /* ## Maker Posthook */
  function makerPosthook(
    ML.SingleOrder memory sor,
    uint gasLeft,
    bytes32 makerData,
    bytes32 mgvData
  ) internal returns (uint gasused) {
    unchecked {
      /* At this point, mgvData can only be `"mgv/tradeSuccess"`, `"mgv/makerRevert"`, `"mgv/makerTransferFail"` or `"mgv/makerReceiveFail"` */
      bytes memory cd = abi.encodeWithSelector(
        IMaker.makerPosthook.selector,
        sor,
        ML.OrderResult({makerData: makerData, mgvData: mgvData})
      );

      address maker = sor.offerDetail.maker();

      uint oldGas = gasleft();
      /* We let the maker pay for the overhead of checking remaining gas and making the call. So the `require` below is just an approximation: if the overhead of (`require` + cost of `CALL`) is $h$, the maker will receive at worst $\textrm{gasreq} - \frac{63h}{64}$ gas. */
      if (!(oldGas - oldGas / 64 >= gasLeft)) {
        revert("mgv/notEnoughGasForMakerPosthook");
      }

      (bool callSuccess, bytes32 posthookData) = controlledCall(
        maker,
        gasLeft,
        cd
      );

      gasused = oldGas - gasleft();

      if (!callSuccess) {
        emit PosthookFail(
          sor.outbound_tkn,
          sor.inbound_tkn,
          sor.offerId,
          posthookData
        );
      }
    }
  }

  /* ## `controlledCall` */
  /* Calls an external function with controlled gas expense. A direct call of the form `(,bytes memory retdata) = maker.call{gas}(selector,...args)` enables a griefing attack: the maker uses half its gas to write in its memory, then reverts with that memory segment as argument. After a low-level call, solidity automaticaly copies `returndatasize` bytes of `returndata` into memory. So the total gas consumed to execute a failing offer could exceed `gasreq + offer_gasbase` where `n` is the number of failing offers. In case of success, we read the first 32 bytes of returndata (the signature of `makerExecute` is `bytes32`). Otherwise, for compatibility with most errors that bubble up from contract calls and Solidity's `require`, we read 32 bytes of returndata starting from the 69th (4 bytes of method sig + 32 bytes of offset + 32 bytes of string length). */
  function controlledCall(
    address callee,
    uint gasreq,
    bytes memory cd
  ) internal returns (bool success, bytes32 data) {
    unchecked {
      bytes32[4] memory retdata;

      /* if success, read returned bytes 1..32, otherwise read returned bytes 69..100. */
      assembly {
        success := call(gasreq, callee, 0, add(cd, 32), mload(cd), retdata, 100)
        data := mload(add(mul(iszero(success), 68), retdata))
      }
    }
  }

  /* # Penalties */
  /* Offers are just promises. They can fail. Penalty provisioning discourages from failing too much: we ask makers to provision more ETH than the expected gas cost of executing their offer and penalize them accoridng to wasted gas.

     Under normal circumstances, we should expect to see bots with a profit expectation dry-running offers locally and executing `snipe` on failing offers, collecting the penalty. The result should be a mostly clean book for actual takers (i.e. a book with only successful offers).

     **Incentive issue**: if the gas price increases enough after an offer has been created, there may not be an immediately profitable way to remove the fake offers. In that case, we count on 3 factors to keep the book clean:
     1. Gas price eventually comes down.
     2. Other market makers want to keep the Mangrove attractive and maintain their offer flow.
     3. Mangrove governance (who may collect a fee) wants to keep the Mangrove attractive and maximize exchange volume. */

  //+clear+
  /* After an offer failed, part of its provision is given back to the maker and the rest is stored to be sent to the taker after the entire order completes. In `applyPenalty`, we _only_ credit the maker with its excess provision. So it looks like the maker is gaining something. In fact they're just getting back a fraction of what they provisioned earlier. */
  /*
     Penalty application summary:

   * If the transaction was a success, we entirely refund the maker and send nothing to the taker.
   * Otherwise, the maker loses the cost of `gasused + offer_gasbase` gas. The gas price is estimated by `gasprice`.
   * To create the offer, the maker had to provision for `gasreq + offer_gasbase` gas at a price of `offerDetail.gasprice`.
   * We do not consider the tx.gasprice.
   * `offerDetail.gasbase` and `offerDetail.gasprice` are the values of the Mangrove parameters `config.offer_gasbase` and `config.gasprice` when the offer was created. Without caching those values, the provision set aside could end up insufficient to reimburse the maker (or to retribute the taker).
   */
  function applyPenalty(ML.SingleOrder memory sor, uint gasused)
    internal
    returns (uint)
  {
    unchecked {
      uint gasreq = sor.offerDetail.gasreq();

      uint provision = 10**9 *
        sor.offerDetail.gasprice() *
        (gasreq + sor.offerDetail.offer_gasbase());

      /* We set `gasused = min(gasused,gasreq)` since `gasreq < gasused` is possible e.g. with `gasreq = 0` (all calls consume nonzero gas). */
      if (gasused > gasreq) {
        gasused = gasreq;
      }

      /* As an invariant, `applyPenalty` is only called when `mgvData` is not in `["mgv/notExecuted","mgv/tradeSuccess"]` */
      uint penalty = 10**9 *
        sor.global.gasprice() *
        (gasused + sor.local.offer_gasbase());

      if (penalty > provision) {
        penalty = provision;
      }

      /* Here we write to storage the new maker balance. This occurs _after_ possible reentrant calls. How do we know we're not crediting twice the same amounts? Because the `offer`'s provision was set to 0 in storage (through `dirtyDeleteOffer`) before the reentrant calls. In this function, we are working with cached copies of the offer as it was before it was consumed. */
      creditWei(sor.offerDetail.maker(), provision - penalty);

      return penalty;
    }
  }

  function sendPenalty(uint amount) internal {
    unchecked {
      if (amount > 0) {
        (bool noRevert, ) = msg.sender.call{value: amount}("");
        require(noRevert, "mgv/sendPenaltyReverted");
      }
    }
  }

  /* Post-trade, `payTakerMinusFees` sends what's due to the taker and the rest (the fees) to the vault. Routing through the Mangrove like that also deals with blacklisting issues (separates the maker-blacklisted and the taker-blacklisted cases). */
  function payTakerMinusFees(MultiOrder memory mor, ML.SingleOrder memory sor)
    internal
  {
    unchecked {
      /* Should be statically provable that the 2 transfers below cannot return false under well-behaved ERC20s and a non-blacklisted, non-0 target. */

      uint concreteFee = (mor.totalGot * sor.local.fee()) / 10_000;
      if (concreteFee > 0) {
        mor.totalGot -= concreteFee;
        mor.feePaid = concreteFee;
        require(
          transferToken(sor.outbound_tkn, vault, concreteFee),
          "mgv/feeTransferFail"
        );
      }
      if (mor.totalGot > 0) {
        require(
          transferToken(sor.outbound_tkn, mor.taker, mor.totalGot),
          "mgv/MgvFailToPayTaker"
        );
      }
    }
  }

  /* # Misc. functions */

  /* Regular solidity reverts prepend the string argument with a [function signature](https://docs.soliditylang.org/en/v0.7.6/control-structures.html#revert). Since we wish to transfer data through a revert, the `innerRevert` function does a low-level revert with only the required data. `innerCode` decodes this data. */
  function innerDecode(bytes memory data)
    internal
    pure
    returns (
      bytes32 mgvData,
      uint gasused,
      bytes32 makerData
    )
  {
    unchecked {
      /* The `data` pointer is of the form `[mgvData,gasused,makerData]` where each array element is contiguous and has size 256 bits. */
      assembly {
        mgvData := mload(add(data, 32))
        gasused := mload(add(data, 64))
        makerData := mload(add(data, 96))
      }
    }
  }

  /* <a id="MgvOfferTaking/innerRevert"></a>`innerRevert` reverts a raw triple of values to be interpreted by `innerDecode`.    */
  function innerRevert(bytes32[3] memory data) internal pure {
    unchecked {
      assembly {
        revert(data, 96)
      }
    }
  }

  /* `transferTokenFrom` is adapted from [existing code](https://soliditydeveloper.com/safe-erc20) and in particular avoids the
  "no return value" bug. It never throws and returns true iff the transfer was successful according to `tokenAddress`.

    Note that any spurious exception due to an error in Mangrove code will be falsely blamed on `from`.
  */
  function transferTokenFrom(
    address tokenAddress,
    address from,
    address to,
    uint value
  ) internal returns (bool) {
    unchecked {
      bytes memory cd = abi.encodeWithSelector(
        IERC20.transferFrom.selector,
        from,
        to,
        value
      );
      (bool noRevert, bytes memory data) = tokenAddress.call(cd);
      return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
    }
  }

  function transferToken(
    address tokenAddress,
    address to,
    uint value
  ) internal returns (bool) {
    unchecked {
      bytes memory cd = abi.encodeWithSelector(
        IERC20.transfer.selector,
        to,
        value
      );
      (bool noRevert, bytes memory data) = tokenAddress.call(cd);
      return (noRevert && (data.length == 0 || abi.decode(data, (bool))));
    }
  }
}

// SPDX-License-Identifier:	AGPL-3.0

// MgvRoot.sol

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

/* `MgvRoot` and its descendants describe an orderbook-based exchange ("the Mangrove") where market makers *do not have to provision their offer*. See `structs.js` for a longer introduction. In a nutshell: each offer created by a maker specifies an address (`maker`) to call upon offer execution by a taker. In the normal mode of operation, the Mangrove transfers the amount to be paid by the taker to the maker, calls the maker, attempts to transfer the amount promised by the maker to the taker, and reverts if it cannot.

   There is one Mangrove contract that manages all tradeable pairs. This reduces deployment costs for new pairs and lets market makers have all their provision for all pairs in the same place.

   The interaction map between the different actors is as follows:
   <img src="./contactMap.png" width="190%"></img>

   The sequence diagram of a market order is as follows:
   <img src="./sequenceChart.png" width="190%"></img>

   There is a secondary mode of operation in which the _maker_ flashloans the sold amount to the taker.

   The Mangrove contract is `abstract` and accomodates both modes. Two contracts, `Mangrove` and `InvertedMangrove` inherit from it, one per mode of operation.

   The contract structure is as follows:
   <img src="./modular_mangrove.svg" width="180%"> </img>
 */

pragma solidity ^0.8.10;
pragma abicoder v2;
import {MgvLib as ML, HasMgvEvents, IMgvMonitor, P} from "./MgvLib.sol";

/* `MgvRoot` contains state variables used everywhere in the operation of the Mangrove and their related function. */
contract MgvRoot is HasMgvEvents {

  /* # State variables */
  //+clear+
  /* The `vault` address. If a pair has fees >0, those fees are sent to the vault. */
  address public vault;

  /* Global mgv configuration, encoded in a 256 bits word. The information encoded is detailed in [`structs.js`](#structs.js). */
  P.Global.t internal internal_global;
  /* Configuration mapping for each token pair of the form `outbound_tkn => inbound_tkn => P.Local.t`. The structure of each `P.Local.t` value is detailed in [`structs.js`](#structs.js). It fits in one word. */
  mapping(address => mapping(address => P.Local.t)) internal locals;

  /* Checking the size of `density` is necessary to prevent overflow when `density` is used in calculations. */
  function checkDensity(uint density) internal pure returns (bool) {
    unchecked {
      return uint112(density) == density;
    }
  }

  /* Checking the size of `gasprice` is necessary to prevent a) data loss when `gasprice` is copied to an `OfferDetail` struct, and b) overflow when `gasprice` is used in calculations. */
  function checkGasprice(uint gasprice) internal pure returns (bool) {
    unchecked {
      return uint16(gasprice) == gasprice;
    }
  }

  /* # Configuration Reads */
  /* Reading the configuration for a pair involves reading the config global to all pairs and the local one. In addition, a global parameter (`gasprice`) and a local one (`density`) may be read from the oracle. */
  function config(address outbound_tkn, address inbound_tkn)
    public
    view
    returns (P.Global.t _global, P.Local.t _local)
  {
    unchecked {
      _global = internal_global;
      _local = locals[outbound_tkn][inbound_tkn];
      if (_global.useOracle()) {
        (uint gasprice, uint density) = IMgvMonitor(_global.monitor()).read(
          outbound_tkn,
          inbound_tkn
        );
        if (checkGasprice(gasprice)) {
          _global = _global.gasprice(gasprice);
        }
        if (checkDensity(density)) {
          _local = _local.density(density);
        }
      }
    }
  }

  /* Returns the configuration in an ABI-compatible struct. Should not be called internally, would be a huge memory copying waste. Use `config` instead. */
  function configInfo(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (P.GlobalStruct memory global, P.LocalStruct memory local)
  {
    unchecked {
      (P.Global.t _global, P.Local.t _local) = config(
        outbound_tkn,
        inbound_tkn
      );
      global = _global.to_struct();
      local = _local.to_struct();
    }
  }

  /* Convenience function to check whether given pair is locked */
  function locked(address outbound_tkn, address inbound_tkn)
    external
    view
    returns (bool)
  {
    P.Local.t local = locals[outbound_tkn][inbound_tkn];
    return local.lock();
  }

  /*
  # Gatekeeping

  Gatekeeping functions are safety checks called in various places.
  */

  /* `unlockedMarketOnly` protects modifying the market while an order is in progress. Since external contracts are called during orders, allowing reentrancy would, for instance, let a market maker replace offers currently on the book with worse ones. Note that the external contracts _will_ be called again after the order is complete, this time without any lock on the market.  */
  function unlockedMarketOnly(P.Local.t local) internal pure {
    require(!local.lock(), "mgv/reentrancyLocked");
  }

  /* <a id="Mangrove/definition/liveMgvOnly"></a>
     In case of emergency, the Mangrove can be `kill`ed. It cannot be resurrected. When a Mangrove is dead, the following operations are disabled :
       * Executing an offer
       * Sending ETH to the Mangrove the normal way. Usual [shenanigans](https://medium.com/@alexsherbuck/two-ways-to-force-ether-into-a-contract-1543c1311c56) are possible.
       * Creating a new offer
   */
  function liveMgvOnly(P.Global.t _global) internal pure {
    require(!_global.dead(), "mgv/dead");
  }

  /* When the Mangrove is deployed, all pairs are inactive by default (since `locals[outbound_tkn][inbound_tkn]` is 0 by default). Offers on inactive pairs cannot be taken or created. They can be updated and retracted. */
  function activeMarketOnly(P.Global.t _global, P.Local.t _local)
    internal
    pure
  {
    liveMgvOnly(_global);
    require(_local.active(), "mgv/inactive");
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