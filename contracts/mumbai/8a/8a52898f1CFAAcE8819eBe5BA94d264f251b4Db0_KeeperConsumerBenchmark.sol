/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

pragma solidity 0.7.6;

contract KeeperConsumerBenchmark {
  event PerformingUpkeep(address from, uint256 initialCall, uint256 nextEligible, uint256 blockNumber);

  uint256 public initialCall = 0;
  uint256 public nextEligible = 0;
  uint256 public testRange;
  uint256 public averageEligibilityCadence;
  uint256 public checkGasToBurn;
  uint256 public performGasToBurn;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup

  uint256 public count = 0;
  uint256 private maxCount = 0;

  constructor(uint256 _testRange, uint256 _averageEligibilityCadence, uint256 _checkGasToBurn, uint256 _performGasToBurn) {
    testRange = _testRange;
    averageEligibilityCadence = _averageEligibilityCadence;
    checkGasToBurn = _checkGasToBurn;
    performGasToBurn = _performGasToBurn;
    maxCount = _testRange / (_averageEligibilityCadence *2);
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    bytes32 dummyIndex = blockhash(block.number - 1);
    bool dummy;
    // burn gas
    while (startGas - gasleft() < checkGasToBurn) {
      dummy = dummy && dummyMap[dummyIndex]; // arbitrary storage reads
      dummyIndex = keccak256(abi.encode(dummyIndex, address(this)));
    }
    return (eligible(), abi.encode(dummy));
  }

  function performUpkeep(bytes calldata) external {
    require(eligible());
    uint256 startGas = gasleft();
    if (initialCall == 0) {
      initialCall = block.number;
    }
    nextEligible = (block.number + (rand() % (averageEligibilityCadence * 2))) + 1;
    count++;
    emit PerformingUpkeep( tx.origin, initialCall, nextEligible, block.number);
    // burn gas
    bytes32 dummyIndex = blockhash(block.number - 1);
    bool dummy;
    while (startGas - gasleft() < checkGasToBurn) {
      dummy = dummy && dummyMap[dummyIndex]; // arbitrary storage reads
      dummyIndex = keccak256(abi.encode(dummyIndex, address(this)));
    }
  }

  function setCheckGasToBurn(uint256 value) public {
    checkGasToBurn = value;
  }

  function setPerformGasToBurn(uint256 value) public {
    performGasToBurn = value;
  }

  function getCountPerforms() public view returns (uint256) {
    return count;
  }

  function eligible() internal view returns (bool) {
    return initialCall == 0 || (count < maxCount && block.number > nextEligible);
  }

  function checkEligible() public view returns (bool) {
    return eligible();
  }

  function reset() external {
    initialCall = 0;
    count = 0;
  }

  function setSpread(uint256 _newTestRange, uint256 _newAverageEligibilityCadence) external {
    testRange = _newTestRange;
    averageEligibilityCadence = _newAverageEligibilityCadence;
  }

  function rand() private view returns (uint256) {
    return uint256(keccak256(abi.encode(blockhash(block.number - 1), address(this))));
  }
}