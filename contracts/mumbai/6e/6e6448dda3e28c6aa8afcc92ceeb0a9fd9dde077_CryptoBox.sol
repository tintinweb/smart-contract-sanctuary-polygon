/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface CryptoBoxDB {
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

  function getNode() external view returns (NodeData memory);
  function getDAppById(uint id) external view returns (DAppData memory);
  function getAllDApps() external view returns (DAppData[] memory dapps);
}

contract CryptoBox is Ownable {
  struct Blockchain {
    uint id;
    address owner;
    uint liquidity; // total liquidity of the blockchain
    uint liquidityPerBlock; // liquidity per block
    uint startLiquidityEarnAt;
    uint tps; // total tps of the blockchain
    uint usedTps; // tps uses by the dapps
    uint nodes;
    uint[] dappsIds;
  }

  mapping (address => uint[]) private _userBlockchains; // user_address -> blockchain_id[]
  mapping (uint => mapping (uint => uint)) private _blockchainDAppsAmounts; // blockchain_id -> dapp_id -> amount
  Blockchain[] private _blockchains;

  CryptoBoxDB private _db;

  constructor(CryptoBoxDB db) {
    _db = db;
  }

  function createBlockchain() external {
    CryptoBoxDB.NodeData memory NODE_DATA = _db.getNode();

    uint blockchainId = _blockchains.length;

    _blockchains.push(Blockchain({
      id: blockchainId,
      owner: msg.sender,
      liquidity: 1000,
      liquidityPerBlock: 10,
      startLiquidityEarnAt: block.number,
      tps: NODE_DATA.tps,
      usedTps: 0,
      nodes: 1,
      dappsIds: new uint[](0)
    }));

    _userBlockchains[msg.sender].push(blockchainId);
  }

  function buy(uint blockchainId, uint nodes, uint[] calldata dapps, uint[] calldata dappsAmounts) external {
    Blockchain storage blockchain = _blockchains[blockchainId];

    require(blockchain.owner != address(0), "Blockchain not found");
    require(blockchain.owner == msg.sender, "You are not the owner of this blockchain");

    uint totalLiqudity = blockchain.liquidity + _getBlockchainPendingLiquidity(blockchain);
    uint totalPrice;

    if (nodes > 0) {
      totalPrice += _buyNodes(blockchain, nodes);
    }

    if (dapps.length > 0) {
      totalPrice += _buyDapps(blockchain, dapps, dappsAmounts);
    }

    require(totalLiqudity >= totalPrice, "Not enough liquidity");

    blockchain.liquidity = totalLiqudity - totalPrice;
    blockchain.startLiquidityEarnAt = block.number;
  }

  function _buyNodes(Blockchain storage blockchain, uint amount) internal returns (uint) {
    uint currentNodes = blockchain.nodes;

    CryptoBoxDB.NodeData memory NODE_DATA = _db.getNode();

    uint price = cumulativeCost(NODE_DATA.price, currentNodes, currentNodes + amount);

    blockchain.tps += NODE_DATA.tps * amount;
    blockchain.nodes += amount;

    return price;
  }

  function _buyDapps(Blockchain storage blockchain, uint[] memory dapps, uint[] memory dappsAmounts) internal returns (uint) {
    uint totalPrice = 0;
    uint totalLiquidityPerBlock = 0;
    uint totalTps = 0;

    for (uint i; i < dapps.length; i++) {
      uint dappId = dapps[i];
      CryptoBoxDB.DAppData memory DAPP_DATA = _db.getDAppById(dappId);
      uint amount = dappsAmounts[i];
      uint currentAmount = _blockchainDAppsAmounts[blockchain.id][dappId];

      totalPrice += cumulativeCost(DAPP_DATA.price, currentAmount, currentAmount + amount);
      totalLiquidityPerBlock += DAPP_DATA.liquidityPerBlock * amount;
      totalTps += DAPP_DATA.tps * amount;
      _blockchainDAppsAmounts[blockchain.id][dappId] += amount;

      for (uint j; j < amount; j++) {
        blockchain.dappsIds.push(dappId);
      }
    }

    require((blockchain.tps - blockchain.usedTps) >= totalTps, "Not enough tps");

    blockchain.liquidityPerBlock += totalLiquidityPerBlock;
    blockchain.usedTps += totalTps;

    return totalPrice;
  }

  function cumulativeCost(uint baseCost, uint currentAmount, uint newAmount) internal pure returns (uint) {
    uint b = (115**newAmount) / (100**(newAmount - 1));

    if (currentAmount == 0) {
      return (baseCost * (b - 100)) / 15;
    }
    
    if (currentAmount == 1) {
      return (baseCost * (b - 115**currentAmount)) / 15;
    }

    uint a = (115**currentAmount) / (100**(currentAmount - 1));

    return (baseCost * (b - a)) / 15;
  }

  // onlyOwner methods
  function setDB(CryptoBoxDB db) external onlyOwner {
    _db = db;
  }

  function _getBlockchainPendingLiquidity(Blockchain memory blockchain) private view returns (uint) {
    return (block.number - blockchain.startLiquidityEarnAt) * blockchain.liquidityPerBlock;
  }

  // public view methods
  function getBlockchain(uint blockchainId) external view returns (Blockchain memory blockchain, uint pendingLiquidity) {
    blockchain = _blockchains[blockchainId];
    pendingLiquidity = _getBlockchainPendingLiquidity(blockchain);
  }

  function getUserBlockchains(address user) external view returns (uint[] memory) {
    return _userBlockchains[user];
  }
}