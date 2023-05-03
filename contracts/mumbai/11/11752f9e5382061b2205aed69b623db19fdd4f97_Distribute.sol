// SPDX-License-Identifier: Unlicensed

import "./IERC20.sol";

pragma solidity ^0.8.17;

interface Main {
    function getDetails(address _user) external view returns(uint256[5] memory);
}

contract Distribute {
    Main public main;
    IERC20 public usdc = IERC20(0x1f3ca1e22E1A5c83a7820b0e1f2FFb5EcbdD3B9f);
    address[] public users = [0xa2e6876a2f307fa963c52063b9E6Fc95E34e5Fdd, 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221, 0x95D9E7945681D1E7D4F9B9CeeF6a4aEcAe5CD0Ac, 0xF81eA4b6A442921140Ee6453aeDed7052FB4Fe3a];
    uint256[] public volume = [0, 100e6, 100e6, 100e6];
    address public user = 0xC73f68b5a7a68f0fD65c4962f7650250B8b4a221;
    uint256 public target;
    uint256 public lastDist;
    uint256 public baseDivider = 10000;
    uint256[] public percents = [2500, 2500, 2500, 2500];
    uint256[] public lastVolume = [0, 0, 0, 0];
    address public management;

    modifier onlyUser {
        require(msg.sender == user, "Not Valid");
        _;
    }

    constructor(address _management) {
        target = 1 hours;
        management = _management;
    } 

    function dist() external {  
        require(block.timestamp - lastDist >= target, "Timestep not completed");
        uint256 balance = usdc.balanceOf(address(this));
        usdc.transfer(users[0], (balance*percents[0])/baseDivider);

        uint256 _management;
        for(uint256 i=1; i<3; i++) {
            uint256 _toDist = (balance*percents[i])/baseDivider;
            uint256[5] memory _curVol = main.getDetails(users[i]);
            uint256 _curPercent = (_curVol[0] * 100)/volume[i];
            if(_curPercent >= 100) {
                usdc.transfer(users[i], _toDist);
            } else {
                usdc.transfer(users[i], (_toDist*_curPercent)/100);
                _management += _toDist - ((_toDist*_curPercent)/100);
            }
            lastVolume[i] = _curVol[0];
        }

        usdc.transfer(management, _management);
        lastDist = block.timestamp;
    }

    function changeVolume(uint256 _newVol, uint256 _place) external onlyUser {
        require(_place > 0, "Not valid place");
        volume[_place] = _newVol;
    } 

    function changeTime(uint256 _newTime) external onlyUser {
        target = _newTime;
    } 

    function changeToken(address _new) external onlyUser {
        usdc = IERC20(_new);
    }

    function addNew(address _user, uint256 _volume, uint256 _percent) external onlyUser {
        users.push(_user);
        volume.push(_volume);
        percents.push(_percent);
    }

    function changePercent(uint256 _percent, uint256 _place) external onlyUser {
        if(_place == 0) {
            require(_percent >= 1500, "Invalid");
        }
        percents[_place] = _percent;
    }

    function setContract(address _new) external {
        require(address(main) == address(0), "Contract already set");
        main = Main(_new);
    }
}