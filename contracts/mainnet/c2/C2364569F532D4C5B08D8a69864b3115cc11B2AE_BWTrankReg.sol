/**
 *Submitted for verification at polygonscan.com on 2023-01-13
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

    BWTrankLike bwt = BWTrankLike(0xa7CE25557F190d852a46E15cC683986637C25Cf4);
    constructor() {
        wards[msg.sender] = 1;
    }
    function registered(uint256 telephone,address usr,address recommender) public auth {
        bwt.registered(telephone,usr,recommender);
    }
 }