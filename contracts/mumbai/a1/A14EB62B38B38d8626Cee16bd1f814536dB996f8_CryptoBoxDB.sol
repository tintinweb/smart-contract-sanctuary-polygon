/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CryptoBoxDB {
  struct NodeData {
    uint price;
    uint tps;
  }

  struct DAppData {
    uint id;
    uint price;
    uint tps;
    uint liquidityPerBlock;
  }

  NodeData private _node;
  DAppData[] private _dapps;

  constructor() {
    initNode();
    initDApps();
  }

  function initNode() internal {
    _node = NodeData({
      price: 100,
      tps: 10
    });
  }

  function initDApps() internal {
    // dex
    _dapps.push(DAppData({
      id: 0,
      price: 750,
      tps: 1,
      liquidityPerBlock: 5
    }));

    // farm
    _dapps.push(DAppData({
      id: 1,
      price: 5000,
      tps: 3,
      liquidityPerBlock: 50
    }));

    // gamefi
    _dapps.push(DAppData({
      id: 2,
      price: 55000,
      tps: 9,
      liquidityPerBlock: 400
    }));

    // bridge
    _dapps.push(DAppData({
      id: 3,
      price: 600000,
      tps: 27,
      liquidityPerBlock: 2350
    }));

    // dao
    _dapps.push(DAppData({
      id: 4,
      price: 6500000,
      tps: 81,
      liquidityPerBlock: 13000
    }));
  }

  function getNode() public view returns (NodeData memory) {
    return _node;
  }

  function getDAppById(uint id) public view returns (DAppData memory) {
    return _dapps[id];
  }

  function getAllDApps() external view returns (DAppData[] memory dapps) {
    return _dapps;
  }
}