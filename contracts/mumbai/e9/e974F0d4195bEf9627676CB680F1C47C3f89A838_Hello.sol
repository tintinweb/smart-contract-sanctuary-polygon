pragma solidity ^0.8.17;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}


contract Hello {
uint public oneDay = 0;
 enum GamePhases {
    MINT, 
    TOP32,
    TOP16,
    TOP8,
    TOP4,
    CHOOSE_WINNERS,
    WORLD_CUP_FINISHED
}

   GamePhases public currentPhase;

   constructor() {
   currentPhase = GamePhases.MINT;
}

   function checkUpkeep(bytes calldata /*checkData*/) external view returns (bool upkeepNeeded, bytes memory /*performData*/) {
        bool oneDayPassed = block.timestamp > oneDay;
        bool worldCupFinished = currentPhase != GamePhases.WORLD_CUP_FINISHED;
        bool phaseChanged = currentPhase == GamePhases.TOP32;
        upkeepNeeded = oneDayPassed && worldCupFinished && phaseChanged;
    }

      function performUpkeep(bytes calldata /*performData*/) external {
          oneDay = block.timestamp + 1 minutes;
      }

     function changePhase() public {
        currentPhase = GamePhases.TOP32;
     }
   
}