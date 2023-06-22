/**
 *Submitted for verification at polygonscan.com on 2023-06-21
*/

// SPDX-License-Identifier: MIT
		pragma solidity ^0.8.9;

		contract TestContract {
		    string pingResponse = "pong";
            address myaddr;

		    constructor(string memory value, address addr) {
		        pingResponse = value;
                myaddr = addr;
		    }

		    function Ping() public view returns (string memory) {
		        return pingResponse;
		    }
		}