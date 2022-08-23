// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./VRFManager.sol";

contract Game is VRFManager {

    mapping(uint256 => bool) requestSet;
    mapping(uint256 => uint256) randomNumbers;

    constructor(address _VRFOracleContract)
        VRFManager(_VRFOracleContract)
    {}

    function getNewNumber() public {
        uint256 requestId = IOracle(VRFOracleContract).requestRandomWords(1);
        requestSet[requestId] = true;
    }
    
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
        internal
        override    
    {
        require(requestSet[_requestId], "fulfillRandomWords: request id does not match");
        randomNumbers[_requestId] = _randomWords[0];
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