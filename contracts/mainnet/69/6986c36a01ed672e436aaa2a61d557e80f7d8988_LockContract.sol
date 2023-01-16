/**
 *Submitted for verification at polygonscan.com on 2023-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IPinklock{
   function normalLocksForUser(address user) external view returns (Lock[] memory);
}
struct Lock {
        uint256 id;
        address token;
        address owner;
        uint256 amount;
        uint256 lockDate;
        uint256 tgeDate; // TGE date for vesting locks, unlock date for normal locks
        uint256 tgeBps; // In bips. Is 0 for normal locks
        uint256 cycle; // Is 0 for normal locks
        uint256 cycleBps; // In bips. Is 0 for normal locks
        uint256 unlockedAmount;
        string description;
    }
contract LockContract  {

        // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWTrankReg/not-authorized");
        _;
    }

    IPinklock bwtLock = IPinklock(0x6C9A0D8B1c7a95a323d744dE30cf027694710633);
    address public bwt = 0x7EFcf6320b26158C2A09C86eB4B604EBc2a7bFe7;
    constructor() {
        wards[msg.sender] = 1;
    }
    function getLock(address usr) external view returns(uint){
        Lock[] memory locks = bwtLock.normalLocksForUser(usr);
        uint length = locks.length;
        if (length ==0) return 0;
        uint amount;
        for (uint i =0; i <length ; ++i) {
            if(locks[i].token == bwt) {
                amount += locks[i].amount;
                amount -= locks[i].unlockedAmount;
            }
        }
        return amount;
    }

    function setBwt(address ust) public auth {
        bwt = ust;
    }
}