/**
 *Submitted for verification at polygonscan.com on 2022-04-12
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.13;

interface IQuarrantine {
  function quarrantineGENESIS(address toQuarrantine) external returns(uint256);
  function quarrantineGAME(address toQuarrantine) external returns(uint256);
}

interface IAdmin {
  function hasRole(bytes32 role, address account) external returns (bool);
}

interface IERC20 {
  function transfer(address recipient, uint amount) external;
  function balanceOf(address user) external returns (uint256);
}

contract Quarrantine {
  address[] public workers;
  mapping(address => uint256) workerIndex;
  IQuarrantine public quarrantineContract;
  IAdmin public adminContract;
  IERC20 public gameContract;
  IERC20 public genesisContract;

  event QuarrantineToken(address indexed token, address indexed from, uint256 amount);

  modifier onlyWorker {
    require(workerIndex[msg.sender] > 0 || adminContract.hasRole(0x00, msg.sender));
    _;
  }

  modifier onlyAdmin {
    require(adminContract.hasRole(0x00, msg.sender), "must be admin");
    _;
  }

  constructor(address adminContract_, address gameContract_, address genesisContract_) {
    adminContract = IAdmin(adminContract_);
    gameContract = IERC20(gameContract_);
    genesisContract = IERC20(genesisContract_);
    workers.push(address(0));
  }

  function quarrantineGAME(address toQuarrantine) external onlyWorker {
    uint256 amount = quarrantineContract.quarrantineGAME(toQuarrantine);
    emit QuarrantineToken(address(gameContract), toQuarrantine, amount);
  }

  function quarrantineGENESIS(address toQuarrantine) external onlyWorker {
    uint256 amount = quarrantineContract.quarrantineGENESIS(toQuarrantine);
    emit QuarrantineToken(address(genesisContract), toQuarrantine, amount);
  }

  function sendGAME(address to, uint256 amount) external onlyAdmin {
    gameContract.transfer(to, amount);
  }

  function sendGENESIS(address to, uint256 amount) external onlyAdmin {
    genesisContract.transfer(to, amount);
  }

  function setQuarrantine(address quarrantine_) external onlyAdmin {
    quarrantineContract = IQuarrantine(quarrantine_);
  }

  function workerAdd(address worker) public onlyAdmin {
    require(worker != address(0));
    require(workerIndex[worker] == 0);

    workerIndex[worker] = workers.length;
    workers.push(worker);
  }

  function workerRemove(address worker) external onlyAdmin {
    uint256 indexToRemove = workerIndex[worker];
    uint256 indexLastWorker = workers.length - 1;
    address lastWorker = workers[indexLastWorker];

    require(worker != address(0));
    require(indexToRemove > 0);

    workers[indexToRemove] = lastWorker;
    workerIndex[lastWorker] = indexToRemove;

    delete workers[indexLastWorker];
    workers.pop();
    workerIndex[worker] = 0;
  }
}