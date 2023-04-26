// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

interface Main {
    struct User {
        address referrer;
        uint256 level;
        uint256 start;
        uint256 newbies;
        uint256 selfDeposit;
        uint256 revenue;
        uint256 APRevenue;
        uint256 leadership;
        uint256 totalTeam;
        uint256 directTeam;
        bool isFounder;
        uint256[2] teamLeaders;
        uint256 totalBusiness;
        address[6] APUpline;
        uint256[6] APTeam;
    } 
    function getDetails(address _user) external view returns(uint256[5] memory);
    function userInfo(address user) external view returns (User memory);
}

contract Distribute {
    Main public main;
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    address[5] public users = [0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221, 0x95D9E7945681D1E7D4F9B9CeeF6a4aEcAe5CD0Ac, 0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a, 0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0x94341c47a7aB0D5DCe248C4c5b776aB14c23DdAB];
    uint256 public volume;
    address public user = 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221;
    uint256 public target;
    uint256 public lastDist;
    uint256 public baseDivider = 10000;
    uint256[5] public percents = [2500, 2500, 2500, 834, 1666];
    uint256[5] public lastVolume;
    address public management;

    modifier onlyUser {
        require(msg.sender == user, "Not Valid");
        _;
    }

    constructor(address _management) {
        target = 1 hours;
        volume = 100e6;
        management = _management;
    } 

    function dist() external {  
        require(block.timestamp - lastDist >= target, "Timestep not completed");
        uint256 balance = usdc.balanceOf(address(this));
        uint256 _management;
        for(uint256 i=0; i<3; i++) {
            uint256 _toDist = (balance*percents[i])/baseDivider;
            uint256[5] memory _curVol = main.getDetails(users[i]);
            uint256 _curPercent = (_curVol[0] * 100)/volume;
            if(_curPercent >= 100) {
                usdc.transfer(users[i], _toDist);
            } else {
                usdc.transfer(users[i], (_toDist*_curPercent)/100);
                _management += _toDist - ((_toDist*_curPercent)/100);
            }
        }
        usdc.transfer(users[3], (balance*percents[3])/baseDivider);
        usdc.transfer(users[4], (balance*percents[4])/baseDivider);
        usdc.transfer(management, _management);
        lastDist = block.timestamp;
    }

    function changeVolume(uint256 _newVol) external onlyUser {
        volume = _newVol;
    } 

    function changeTime(uint256 _newTime) external onlyUser {
        target = _newTime;
    } 

    function changeToken(address _new) external onlyUser {
        usdc = IERC20(_new);
    }

    function setContract(address _new) external {
        require(address(main) == address(0), "Contract already set");
        main = Main(_new);
    }
}