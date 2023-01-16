/**
 *Submitted for verification at polygonscan.com on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface BWTrankLike {
    function registered(uint256 telephone,address usr,address recommender) external;
}
contract BWTrankReg  {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWTrankReg/not-authorized");
        _;
    }

    BWTrankLike public bwt = BWTrankLike(0xbA43031fdc34525ef577593cb1de453B7561748E);
    constructor() {
        wards[msg.sender] = 1;
    }
    function registered(uint256 telephone,address usr,address recommender) public auth {
        bwt.registered(telephone,usr,recommender);
    }
    function setBwtrank(address ust) public auth {
        bwt = BWTrankLike(ust);
    }
 }