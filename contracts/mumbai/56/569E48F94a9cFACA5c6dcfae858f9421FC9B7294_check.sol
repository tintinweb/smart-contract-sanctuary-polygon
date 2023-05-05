/**
 *Submitted for verification at polygonscan.com on 2023-05-04
*/

/// @knowledgePoint create2
/// @level 困难
/// @description 1.check合约余额大于0。2.disposal合约余额归零。
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract disposal {
    address public owner;
    address public dep;

    constructor(address _owner) payable {
        owner = _owner;
        dep = msg.sender;
    }

    function withdraw() public {
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract deployer {
    constructor(bytes32 salt) payable {
        disposal dis = new disposal{value: msg.value, salt: salt}(msg.sender);
    }
}

contract check {
    uint256 public score;

    function isCompleted(address _addr) public payable {
        score = 0;
        require(msg.value > 0);
        bytes32 salt = blockhash(block.number - 1);
        deployer dep = new deployer{value: msg.value, salt: salt}(salt);

        (bool success,bytes memory data)=msg.sender.call("cuit()");
        require(success,string(data));
        if (address(this).balance > 0) {
            score += 25;
        }
        if (
            disposal(_addr).owner() == address(this) &&
            disposal(_addr).dep() == address(dep) &&
            _addr.balance == 0
        ) {
            score += 75;
        }
    }
}