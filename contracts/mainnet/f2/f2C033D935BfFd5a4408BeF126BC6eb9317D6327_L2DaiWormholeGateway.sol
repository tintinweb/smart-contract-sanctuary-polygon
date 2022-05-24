/**
 *Submitted for verification at polygonscan.com on 2022-05-24
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.7.6;
pragma abicoder v2;

// Standard Maker Wormhole GUID
struct WormholeGUID {
  bytes32 sourceDomain;
  bytes32 targetDomain;
  bytes32 receiver;
  bytes32 operator;
  uint128 amount;
  uint80 nonce;
  uint48 timestamp;
}

function bytes32ToAddress(bytes32 addr) pure returns (address) {
  return address(uint160(uint256(addr)));
}

function addressToBytes32(address addr) pure returns (bytes32) {
  return bytes32(uint256(uint160(addr)));
}

interface IL1WormholeRouter {
  function requestMint(
    WormholeGUID calldata wormholeGUID,
    uint256 maxFeePercentage,
    uint256 operatorFee
  ) external returns (uint256 postFeeAmount, uint256 totalFee);

  function settle(bytes32 targetDomain, uint256 batchedDaiToFlush) external;
}

interface IL1WormholeGateway {
  function l1Token() external view returns (address);

  function l1Escrow() external view returns (address);

  function l1WormholeRouter() external view returns (IL1WormholeRouter);

  function l2WormholeGateway() external view returns (address);

  function finalizeFlush(bytes32 targetDomain, uint256 daiToFlush) external;

  function finalizeRegisterWormhole(WormholeGUID calldata wormhole) external;
}

interface IL2WormholeGateway {
  event WormholeInitialized(WormholeGUID wormhole);
  event Flushed(bytes32 indexed targetDomain, uint256 dai);

  function domain() external view returns (bytes32);

  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external;

  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external;

  function initiateWormhole(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external;

  function flush(bytes32 targetDomain) external;
}

interface Mintable {
  function mint(address usr, uint256 wad) external;

  function burn(address usr, uint256 wad) external;
}

contract L2DaiWormholeGateway is IL2WormholeGateway {
  // --- Auth ---
  mapping(address => uint256) public wards;

  function rely(address usr) external auth {
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external auth {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier auth() {
    require(wards[msg.sender] == 1, "L2DaiWormholeGateway/not-authorized");
    _;
  }

  bytes32 public immutable override domain;
  uint256 public isOpen = 1;
  mapping(bytes32 => uint256) public validDomains;
  mapping(bytes32 => uint256) public batchedDaiToFlush;

  event Closed();
  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event File(bytes32 indexed what, bytes32 indexed domain, uint256 data);

  constructor(
    bytes32 _domain
  ) {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
    validDomains[0x0000000000000000000000000000000000000000000000000000000000000002] = 1;
    domain = _domain;
  }

  function close() external auth {
    isOpen = 0;

    emit Closed();
  }


  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount
  ) external override {
    return _initiateWormhole(targetDomain, addressToBytes32(receiver), amount, 0);
  }

  function initiateWormhole(
    bytes32 targetDomain,
    address receiver,
    uint128 amount,
    address operator
  ) external override {
    return
      _initiateWormhole(
        targetDomain,
        addressToBytes32(receiver),
        amount,
        addressToBytes32(operator)
      );
  }

  function initiateWormhole(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) external override {
    return _initiateWormhole(targetDomain, receiver, amount, operator);
  }

  function _initiateWormhole(
    bytes32 targetDomain,
    bytes32 receiver,
    uint128 amount,
    bytes32 operator
  ) private {
    // Disallow initiating new wormhole transfer if gateway is closed
    require(isOpen == 1, "L2DaiWormholeGateway/closed");

    // Disallow initiating new wormhole transfer if targetDomain has not been whitelisted
    require(validDomains[targetDomain] == 1, "L2DaiWormholeGateway/invalid-domain");

    WormholeGUID memory wormhole = WormholeGUID({
      sourceDomain: domain,
      targetDomain: targetDomain,
      receiver: receiver,
      operator: operator,
      amount: amount,
      nonce: uint80(1), // gas optimization, we don't need to maintain our own nonce
      timestamp: uint48(block.timestamp)
    });

    batchedDaiToFlush[targetDomain] += amount;
     
    emit WormholeInitialized(wormhole);
  }

  function flush(bytes32 targetDomain) external override {
    // We do not check for valid domain because previously valid domains still need their DAI flushed
    uint256 daiToFlush = batchedDaiToFlush[targetDomain];
    require(daiToFlush > 0, "L2DaiWormholeGateway/zero-dai-flush");

    batchedDaiToFlush[targetDomain] = 0;
   
    emit Flushed(targetDomain, daiToFlush);
  }
}