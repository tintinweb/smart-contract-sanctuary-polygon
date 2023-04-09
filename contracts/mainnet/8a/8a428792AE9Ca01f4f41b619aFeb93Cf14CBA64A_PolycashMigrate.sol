/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface externalcall {
    function viewAddress() external view returns (address[] memory);
    function _direct_team(address addr,uint256 input) external view returns (uint256);
    function _direct_reward(address addr,uint256 input) external view returns (uint256);
    function _level_team(address addr,uint256 input) external view returns (uint256);
    function _level_reward(address addr,uint256 input) external view returns (uint256);
    function registerWithPermit(address referree,address referral) external returns (bool);
    function users(address addr) external view returns (uint256,uint256,uint256,uint256,uint256,address,bool,uint256);
    function records(address addr) external view returns (uint256,uint256,uint256,uint256,uint256);
    function updateUserWithPermit(address addr,uint256[] memory values,address referral,bool flag) external returns (bool);
    function updateRecordWithPermit(address addr,uint256[] memory values) external returns (bool);
    function updateMappingDataWithPermit(address addr,uint256[] memory directteam,uint256[] memory directreward,uint256[] memory levelteam,uint256[] memory levelreward) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
      return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor() {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require( _owner == _msgSender());
      _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
      emit OwnershipTransferred(_owner, account);
      _owner = account;
    }
}

contract PolycashMigrate is Context, Ownable {

    address public PolycashV1 = 0x172e65cD61a573A8eD5916743341bFdE2Fd7a7Ee;
    address public PolycashV2 = 0xfE74Be25FF81B2857983150fbAA5cb626efa13Dd;
    address public PolycashAddress = 0x3A1Dfc562ed28d8e1ab20ee779721167fB219A4f;

    constructor() {}

    function userUpdate() public onlyOwner {
        address[] memory addrs = externalcall(PolycashAddress).viewAddress();
        uint256 i;
        do{
            (
                uint256 deposit,
                uint256 unclaim,
                uint256 commission,
                uint256 lastblock,
                uint256 cooldown,
                address referral,
                bool registerd,
                uint256 teamsize
            ) = externalcall(PolycashV1).users(addrs[i]);
            uint256[] memory input = new uint256[](6);
            input[0] = deposit;
            input[1] = unclaim;
            input[2] = commission;
            input[3] = lastblock;
            input[4] = cooldown;
            input[5] = teamsize;
            externalcall(PolycashV2).registerWithPermit(addrs[i],referral);
            externalcall(PolycashV2).updateUserWithPermit(addrs[i],input,referral,registerd);
            i++;
        }while(i<addrs.length);
    }

    function recordUpdate() public onlyOwner {
        address[] memory addrs = externalcall(PolycashAddress).viewAddress();
        uint256 i;
        do{
            (
                uint256 tEarn,
                uint256 tComision,
                uint256 tMatching,
                uint256 tWitdrawn,
                uint256 partner
            ) = externalcall(PolycashV1).records(addrs[i]);
            uint256[] memory input = new uint256[](5);
            input[0] = tEarn;
            input[1] = tComision;
            input[2] = tMatching;
            input[3] = tWitdrawn;
            input[4] = partner;
            externalcall(PolycashV2).updateRecordWithPermit(addrs[i],input);
            i++;
        }while(i<addrs.length);
    }

    function mappingUpdate() public onlyOwner {
        address[] memory addrs = externalcall(PolycashAddress).viewAddress();
        uint256 i;
        do{
            uint256[] memory inputdirectteam = new uint256[](4);
            inputdirectteam[0] = 0;
            inputdirectteam[1] = 0;
            inputdirectteam[2] = 0;
            inputdirectteam[3] = 0;
            uint256[] memory inputdirectreward = new uint256[](4);
            inputdirectreward[0] = 0;
            inputdirectreward[1] = externalcall(PolycashV1)._direct_reward(addrs[i],1);
            inputdirectreward[2] = externalcall(PolycashV1)._direct_reward(addrs[i],2);
            inputdirectreward[3] = externalcall(PolycashV1)._direct_reward(addrs[i],3);
            uint256[] memory inputlevelteam = new uint256[](16);
            inputlevelteam[0] = 0;
            inputlevelteam[1] = externalcall(PolycashV1)._level_team(addrs[i],1);
            inputlevelteam[2] = externalcall(PolycashV1)._level_team(addrs[i],2);
            inputlevelteam[3] = externalcall(PolycashV1)._level_team(addrs[i],3);
            inputlevelteam[4] = externalcall(PolycashV1)._level_team(addrs[i],4);
            inputlevelteam[5] = externalcall(PolycashV1)._level_team(addrs[i],5);
            inputlevelteam[6] = externalcall(PolycashV1)._level_team(addrs[i],6);
            inputlevelteam[7] = externalcall(PolycashV1)._level_team(addrs[i],7);
            inputlevelteam[8] = externalcall(PolycashV1)._level_team(addrs[i],8);
            inputlevelteam[9] = externalcall(PolycashV1)._level_team(addrs[i],9);
            inputlevelteam[10] = externalcall(PolycashV1)._level_team(addrs[i],10);
            inputlevelteam[11] = externalcall(PolycashV1)._level_team(addrs[i],11);
            inputlevelteam[12] = externalcall(PolycashV1)._level_team(addrs[i],12);
            inputlevelteam[13] = externalcall(PolycashV1)._level_team(addrs[i],13);
            inputlevelteam[14] = externalcall(PolycashV1)._level_team(addrs[i],14);
            inputlevelteam[15] = externalcall(PolycashV1)._level_team(addrs[i],15);
            uint256[] memory inputlevelreward = new uint256[](16);
            inputlevelreward[0] = 0;
            inputlevelreward[1] = externalcall(PolycashV1)._level_reward(addrs[i],1);
            inputlevelreward[2] = externalcall(PolycashV1)._level_reward(addrs[i],2);
            inputlevelreward[3] = externalcall(PolycashV1)._level_reward(addrs[i],3);
            inputlevelreward[4] = externalcall(PolycashV1)._level_reward(addrs[i],4);
            inputlevelreward[5] = externalcall(PolycashV1)._level_reward(addrs[i],5);
            inputlevelreward[6] = externalcall(PolycashV1)._level_reward(addrs[i],6);
            inputlevelreward[7] = externalcall(PolycashV1)._level_reward(addrs[i],7);
            inputlevelreward[8] = externalcall(PolycashV1)._level_reward(addrs[i],8);
            inputlevelreward[9] = externalcall(PolycashV1)._level_reward(addrs[i],9);
            inputlevelreward[10] = externalcall(PolycashV1)._level_reward(addrs[i],10);
            inputlevelreward[11] = externalcall(PolycashV1)._level_reward(addrs[i],11);
            inputlevelreward[12] = externalcall(PolycashV1)._level_reward(addrs[i],12);
            inputlevelreward[13] = externalcall(PolycashV1)._level_reward(addrs[i],13);
            inputlevelreward[14] = externalcall(PolycashV1)._level_reward(addrs[i],14);
            inputlevelreward[15] = externalcall(PolycashV1)._level_reward(addrs[i],15);
            externalcall(PolycashV2).updateMappingDataWithPermit(addrs[i],inputdirectteam,inputdirectreward,inputlevelteam,inputlevelreward);
            i++;
        }while(i<addrs.length);
    }

    function exit() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}