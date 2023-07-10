/**
 *Submitted for verification at polygonscan.com on 2023-07-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OtherContract {
    function getEmail(address walletAddress) external view returns (string memory);
}

contract EmailRegistration {
    function callOtherContractFunction( address walletAddress) public view {
        // Specify the address of the other contract on the Polygon network
        address otherContractAddress = 0x0EF07323aFC9003038D3f1AEF13BFCD668c1C0E3;

        // Create an instance of the other contract using the interface
        OtherContract otherContract = OtherContract(otherContractAddress);

        // Call the getEmail function on the other contract
        string memory email = otherContract.getEmail(msg.sender);

        // Process the email data as needed
        // ...
    }
}