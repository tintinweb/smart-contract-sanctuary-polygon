// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./TestContract.sol";

contract CallerContract {
    address public constant TEST_CONTRACT_ADDRESS = 0x4baf7AD315C9EaB352c142f69603E6a981d47b14; // Replace with actual address of TestContract
    
    function callEmitTest() public {
        TestContract testContract = TestContract(TEST_CONTRACT_ADDRESS);
        testContract.emitTest();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract TestContract {
    uint256 public autoIncrement;
    
    event Test(uint256 indexed id);
    
    function emitTest() public {
        autoIncrement++;
        emit Test(autoIncrement);
    }
}