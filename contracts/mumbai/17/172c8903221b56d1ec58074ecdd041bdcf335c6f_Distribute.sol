// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

interface Main {
    struct User {
        address referrer;
        uint256 level;
        uint256 start;
        uint256 newbies;
        uint256 revenue;
        uint256 PFIRevenue;
        uint256 leadership;
        uint256 totalTeam;
        uint256 selfDeposit;
        uint256 directTeam;
        uint256 totalBusiness;
        bool isFounder;
        uint256[2] teamLeaders;
        address[6] PFIUpline;
        uint256[6] PFITeam;
    } 
    function getDetails(address _user) external view returns(uint256[5] memory);
    function userInfo(address _user) external view returns(User memory);
}

contract Distribute {
    Main public main;
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    address[5] public users = [0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221, 0x0D9Dc7c097FeD70714C56f8768D723912C84A5f6, 0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a];
    address[5] public users2 = [0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a, 0x0D9Dc7c097FeD70714C56f8768D723912C84A5f6, 0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0x94341c47a7aB0D5DCe248C4c5b776aB14c23DdAB, 0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a];
    address[5] public receivers = [0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221, 0x0D9Dc7c097FeD70714C56f8768D723912C84A5f6, 0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a];
    uint256 public volume;
    address public user = 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221;
    uint256 public target;
    uint256 public lastDist;
    uint256 public baseDivider = 10000;
    uint256[5] public percents = [2500, 2500, 2500, 2500, 0];
    uint256[5] public lastVolume = [0, 0, 0, 0, 0];
    uint256[5] public lastVolume2 = [0, 0, 0, 0, 0];
    address public management;

    modifier onlyUser {
        require(msg.sender == user, "Not Valid");
        _;
    }

    constructor(address _management, address _dev, address _found) {
        volume = 100e6;
        target = 10 minutes;
        management = _management;
        users[0] = _dev;
        users[4] = _found;
        lastDist = block.timestamp;
    } 

    function dist() external {  
        require(block.timestamp - lastDist >= target, "Timestep not completed");
        uint256 balance = usdc.balanceOf(address(this));
        usdc.transfer(receivers[0], (balance*percents[0])/baseDivider);
        usdc.transfer(receivers[4], (balance*percents[4])/baseDivider);

        uint256 _management;
        for(uint256 i=1; i<4; i++) {
            uint256 _toDist = (balance*percents[i])/baseDivider;
            uint256[5] memory _curVol = main.getDetails(users[i]);
            Main.User memory _reduceVol = main.userInfo(users2[i]);
            if(_curVol[0] > _reduceVol.totalBusiness) {
                uint256 _curPercent = ((_curVol[0] - _reduceVol.totalBusiness) * 100)/volume;
                if(_curPercent >= 100) {
                    usdc.transfer(receivers[i], _toDist);
                } else {
                    usdc.transfer(receivers[i], (_toDist*_curPercent)/100);
                    _management += _toDist - ((_toDist*_curPercent)/100);
                }

                lastVolume[i] = _curVol[0];
                lastVolume2[i] = _reduceVol.totalBusiness;
            }
        }

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

    function setAddr(address _addr, uint256 _place, address _volumeReduce) external onlyUser {
        require(_place > 0, "Invalid");
        users[_place] = _addr;
        users2[_place] = _volumeReduce;
        uint256[5] memory _curVol = main.getDetails(_addr);
        Main.User memory _reduceVol = main.userInfo(_volumeReduce);
        lastVolume[_place] = _curVol[0];
        lastVolume2[_place] = _reduceVol.totalBusiness;
    }

    function changePercent(uint256 _percent, uint256 _place) external onlyUser {
        require(_percent >= 1600, "Cannot reduce more than 16 Percent");
        percents[_place] = _percent;
    }

    function setContract(address _new) external {
        require(address(main) == address(0), "Contract already set");
        main = Main(_new);
    }
}