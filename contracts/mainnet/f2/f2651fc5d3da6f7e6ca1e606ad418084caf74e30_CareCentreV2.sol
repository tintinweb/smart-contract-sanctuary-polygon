// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import { IAavegotchiFacet } from "IAavegotchiFacet.sol";
import { IAavegotchiGameFacet } from "IAavegotchiGameFacet.sol";
import { IOperator } from "IOperator.sol";
import { ITreasury } from "ITreasury.sol";
import { EnumerableSet } from "EnumerableSet.sol";
import { SafeMath } from "SafeMath.sol";
import { Ownable } from "Ownable.sol";

contract CareCentreV2 is Ownable {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;

  IAavegotchiFacet public immutable gotchiFacet;
  IAavegotchiGameFacet public immutable gameFacet;
  IOperator public operator;
  ITreasury public treasury;

  mapping(address => uint256) public caringOwnerPetCount;
  uint256[] public rateOfTier;
  uint256[] public petCountOfTier;

  EnumerableSet.AddressSet internal executors;
  EnumerableSet.AddressSet internal caringOwners;

  event StartCare(address indexed owner);
  event StopCare(address indexed owner);
  event LogPet(address indexed owner, uint256 gotchis, uint256 pets);

  constructor(
    address _gotchiDiamond,
    address _operator,
    address _treasury,
    address _executor
  ) {
    gotchiFacet = IAavegotchiFacet(_gotchiDiamond);
    gameFacet = IAavegotchiGameFacet(_gotchiDiamond);
    operator = IOperator(_operator);
    treasury = ITreasury(_treasury);
    executors.add(_executor);
  }

  function startCare() external {
    require(
      !caringOwners.contains(msg.sender),
      "CareCentreV2: startCare: Owner already started"
    );

    caringOwners.add(msg.sender);

    emit StartCare(msg.sender);
  }

  function stopCare() external {
    require(
      caringOwners.contains(msg.sender),
      "CareCentreV2: stopCare: Owner did not start"
    );

    delete caringOwnerPetCount[msg.sender];
    caringOwners.remove(msg.sender);

    emit StopCare(msg.sender);
  }

  function exec(
    address caringOwner,
    uint256[] calldata gotchiIds,
    bool isFrenExec
  ) external {
    require(
      executors.contains(msg.sender),
      "CareCentreV2: exec: Sender is not executor"
    );

    if (isFrenExec) {
      _frenExec(caringOwner, gotchiIds);
    } else {
      _exec(caringOwner, gotchiIds);
    }
  }

  function _exec(address caringOwner, uint256[] calldata gotchiIds) internal {
    uint256 petCount = caringOwnerPetCount[caringOwner];

    uint256 rate = calculateRate(petCount);

    treasury.payWages(caringOwner, rate);

    operator.pet(gotchiIds);

    caringOwnerPetCount[caringOwner] = petCount + 1;

    uint256 length = gotchiIds.length;

    LogPet(caringOwner, length, petCount + 1);
  }

  function _frenExec(address caringOwner, uint256[] calldata gotchiIds)
    internal
  {
    uint256 petCount = caringOwnerPetCount[caringOwner];

    operator.pet(gotchiIds);

    uint256 length = gotchiIds.length;

    LogPet(caringOwner, length, petCount);
  }

  function calculateRate(uint256 _petCount) public view returns (uint256) {
    for (uint256 x; x < petCountOfTier.length; x++) {
      if (_petCount <= petCountOfTier[x]) return rateOfTier[x];
    }
    return rateOfTier[rateOfTier.length - 1];
  }

  function rateOfOwner(address _caringOwner) public view returns (uint256) {
    uint256 petCount = caringOwnerPetCount[_caringOwner];

    for (uint256 x; x < petCountOfTier.length; x++) {
      if (petCount <= petCountOfTier[x]) return rateOfTier[x];
    }
    return rateOfTier[rateOfTier.length - 1];
  }

  function setRates(
    uint256[] memory _newTierRates,
    uint256[] memory _newPetCountOfTier
  ) external onlyOwner {
    require(
      _newTierRates.length == _newPetCountOfTier.length + 1,
      "Treasury: setRates: Length error"
    );
    rateOfTier = _newTierRates;
    petCountOfTier = _newPetCountOfTier;
  }

  function addExecutor(address executor) external onlyOwner {
    require(
      !executors.contains(executor),
      "CareCentreV2: addExecutor: Executor already exists"
    );

    executors.add(executor);
  }

  function removeExecutor(address executor) external onlyOwner {
    require(
      executors.contains(executor),
      "CareCentreV2: addExecutor: Executor does not exists"
    );

    executors.remove(executor);
  }

  function getCaringOwners()
    external
    view
    returns (address[] memory _caringOwners)
  {
    uint256 length = caringOwners.length();
    _caringOwners = new address[](length);
    for (uint256 i = 0; i < length; i++) _caringOwners[i] = caringOwners.at(i);
  }

  function getExecutors() external view returns (address[] memory _executors) {
    uint256 length = executors.length();
    _executors = new address[](length);
    for (uint256 i = 0; i < length; i++) _executors[i] = executors.at(i);
  }

  function startCareFor(address caringOwner) external onlyOwner {
    caringOwners.add(caringOwner);

    emit StartCare(caringOwner);
  }

  function stopCareFor(address caringOwner) external onlyOwner {
    caringOwners.remove(caringOwner);

    emit StopCare(caringOwner);
  }
}