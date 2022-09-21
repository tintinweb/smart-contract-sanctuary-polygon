/**
 *Submitted for verification at polygonscan.com on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}
interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
  function performUpkeep(bytes calldata performData) external;
}
abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}
interface Lottery{
    function buy(uint256 ticket) external payable ;
} 
contract Counter is KeeperCompatibleInterface {

    Lottery public lottery;
    uint public counter;
    uint public immutable interval;
    uint public lastTimeStamp;

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      counter = 0;
      lottery = Lottery(0x396e1396588cB58Bc5C69Ae48F3e2652F40FC17e);
    }

    function checkUpkeep(bytes calldata  checkData ) external view override returns (bool upkeepNeeded, bytes memory performData ) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata  performData ) external override {
        if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            counter = counter + 1;
            lottery.buy(5);
            performData;
        }
    }
}