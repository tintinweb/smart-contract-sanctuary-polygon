/**
 *Submitted for verification at polygonscan.com on 2021-11-14
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

// File: contracts/GameController.sol


pragma solidity ^0.8.7;


contract gameController is KeeperCompatibleInterface {
    /**
    * Public counter variable
    */
    bool public gameStarted;
    bool public gameEnded;

    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public gameStartTimeStamp;
    
    constructor(uint updateInterval, uint _gameStartTimeStamp) {
      interval = updateInterval;
      gameStartTimeStamp = _gameStartTimeStamp;
    }

    function checkUpkeep(bytes calldata) external override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (gameStarted && !gameEnded && (gameStartTimeStamp - block.timestamp >= interval)) || (!gameStarted && block.timestamp >= gameStartTimeStamp);
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        if(!gameStarted && block.timestamp >= gameStartTimeStamp){
            gameStarted = true;
        }
        if(block.timestamp - gameStartTimeStamp >= interval){
            gameEnded = true;
            
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
    }   
}