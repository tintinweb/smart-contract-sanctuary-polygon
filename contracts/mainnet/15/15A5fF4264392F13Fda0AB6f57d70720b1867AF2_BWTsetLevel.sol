/**
 *Submitted for verification at polygonscan.com on 2023-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface BWTrankLike {
    function setLevel(address usr, uint256 level) external;
}
contract BWTsetLevel  {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWTrankReg/not-authorized");
        _;
    }

    BWTrankLike public bwt = BWTrankLike(0x9Aa8b07098b72AC9B55adb3dD5A91527D6E9B28E);
    constructor() {
        wards[msg.sender] = 1;
    }
    function setLevel(address usr, uint256 level) public auth {
         bwt.setLevel(usr,level);
    }
    function setBwtrank(address ust) public auth {
        bwt = BWTrankLike(ust);
    }
 }