// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./VRFManager.sol";

contract Game is VRFManager {

    uint256 public randomNumber;
    uint256 public requestId;

    constructor(address _VRFOracleContract)
        VRFManager(_VRFOracleContract)
    {}

    function getNewNumber() public {
        requestId = IOracle(VRFOracleContract).requestRandomWords(1);
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
        internal
        override    
    {
        require(requestId == _requestId, "fulfillRandomWords: request id does not match");
        randomNumber = _randomWords[0];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOracle {

    function requestRandomWords(uint256 _numberOfWords) external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IConsumer {

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IOracle.sol";
import "./interfaces/IConsumer.sol";

contract VRFManager is IConsumer {

    address public VRFOracleContract;

    constructor(address _VRFOracleContract){
        VRFOracleContract = _VRFOracleContract; 
    }

    function updateOracleContract(address _VRFOracleContract) external virtual {
        VRFOracleContract = _VRFOracleContract;
    }

    function fulfillRandomWords(uint256, uint256[] memory)
        internal
        virtual
    {}

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        
        require(msg.sender == VRFOracleContract, "rawFulfillRandomWords: only oracle can fulfill random words");

        fulfillRandomWords(requestId, randomWords);

    }

}