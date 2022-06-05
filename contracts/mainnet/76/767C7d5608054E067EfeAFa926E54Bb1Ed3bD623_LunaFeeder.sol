/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract LunaFeeder {
    address private _owner;
    address private _receiverAddr;

    address public _NVBAddr;
    uint256 public _NVBStake;
    uint256 public _rewardmultiplier;

    address public _LunaAddr;
    address public _burnWalled;
    uint256 public _burnedLuna;

    constructor() {
        _owner = msg.sender;
        _receiverAddr = 0x12cD95f3e4522Ac657a0B24187835CB2D3999E0B;
        _NVBAddr = 0x9cD422D74fA04Cac470Dcde9821c473284438152;
        _LunaAddr = 0x9cd6746665D9557e1B9a775819625711d0693439;
        _burnWalled = 0x000000000000000000000000000000000000dEaD;
        _burnedLuna = 0;
        _NVBStake = 0;
    }

    function addNVB(uint256 _amount) public {
        require(msg.sender == _owner, "You are not the owner");
        IERC20(_NVBAddr).transferFrom(msg.sender, address(this), _amount);
        _NVBStake += _amount;
    }

    function retrieveNVB(uint256 _amount) public {
        require(msg.sender == _owner, "You are not the owner");
        IERC20(_NVBAddr).transfer(_owner, _amount);
        _NVBStake -= _amount;
    }

    function getNVB(uint256 _amount, uint256 _burningmultiplier) public {
        require(_amount > 1000000, "you can't send less than 1 Luna");

        // burn part of the luna
        if (_burningmultiplier > 90) _burningmultiplier = 90;
        uint256 burned = (_amount * _burningmultiplier) / 100;
        _burnedLuna += burned / (10 ** 6);

        // keep the remaining luna
        uint256 remaining = _amount - burned;

        // send NVB back
        uint256 NVBAmount = getNVBamount(remaining);
        require(NVBAmount < _NVBStake, "The rewards are not enought");
        _NVBStake -= NVBAmount * 10 ** 6;

        // end the transactions
        // get luna
        IERC20(_LunaAddr).transferFrom(msg.sender, address(this), _amount); 

        // burn luna
        IERC20(_LunaAddr).transfer(_burnWalled, burned);

        // transfer the remaining luna to LP walled
        IERC20(_LunaAddr).transfer(_receiverAddr, remaining);

        // send NVB back
        IERC20(_NVBAddr).transfer(msg.sender, NVBAmount * 10 ** 6);
    }

    function getNVBamount (uint256 _amount) public pure returns(uint256) {
        // Let's start about 1 NBV for 100 luna
        return _amount / 100000000;
    }
}