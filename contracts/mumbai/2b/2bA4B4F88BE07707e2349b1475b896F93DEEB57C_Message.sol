// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Message {

    string message;


    function setMessage(string memory _message) public {
        message = _message;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function getMessage() public view returns ( string memory){
        return message;
    }
}