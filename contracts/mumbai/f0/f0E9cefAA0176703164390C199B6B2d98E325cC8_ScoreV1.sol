/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

pragma solidity ^0.4.21;

// contract Proxy {
//     address private targetAddress;

//     constructor(address _address) public {
//         setTargetAddress(_address);
//     }

//     function setTargetAddress(address _address) public {
//         require(_address != address(0));
//         targetAddress = _address;
//     }

//     function () public {
//         address contractAddr = targetAddress;
//         assembly {
//             let ptr := mload(0x40)
//             calldatacopy(ptr, 0, calldatasize)
//             let result := delegatecall(gas, contractAddr, ptr, calldatasize, 0, 0)
//             let size := returndatasize
//             returndatacopy(ptr, 0, size)

//             switch result
//             case 0 { revert(ptr, size) }
//             default { return(ptr, size) }
//         }
//     }
// }


contract ScoreInterface {
    function hit() public;
    function score() public view returns (uint);
}

contract ScoreV1 is ScoreInterface {
    mapping (address => uint) scoreMap;

    function hit() public {
        scoreMap[msg.sender] = scoreMap[msg.sender] + 10;
    }

    function score() public view returns (uint) {
        return scoreMap[msg.sender];
    }
}

contract ScoreV2 is ScoreInterface {
    mapping (address => uint) scoreMap;

    function hit() public {
        scoreMap[msg.sender] = scoreMap[msg.sender] + 20;
    }

    function score() public view returns (uint) {
        return scoreMap[msg.sender];
    }
}