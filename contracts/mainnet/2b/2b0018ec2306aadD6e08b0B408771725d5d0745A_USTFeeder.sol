/**
 *Submitted for verification at polygonscan.com on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

contract USTFeeder {
    address private _owner;
    address private _receiverAddr;

    address public _NVBAddr;
    uint256 public _NVBStake;

    address public _USTAddr;
    address public _burnWalled;
    uint256 public _burnedUST;

    constructor() {
        _owner = msg.sender;
        _receiverAddr = 0x12cD95f3e4522Ac657a0B24187835CB2D3999E0B;
        _NVBAddr = 0xc4717C72Dde49F8c66ef2f0A71c12E81680Cb096;
        _USTAddr = 0xE6469Ba6D2fD6130788E0eA9C0a0515900563b59;
        _burnWalled = 0x000000000000000000000000000000000000dEaD;
        _burnedUST = 0;
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
        require(_amount > 1000000, "Amount should be at least 1 UST");

        // burn part of the UST
        if (_burningmultiplier > 90) _burningmultiplier = 90;
        uint256 burned = (_amount * _burningmultiplier) / 100;
        _burnedUST += burned / (10 ** 6);

        // keep the remaining luna
        uint256 remaining = _amount - burned;

        // send NVB back
        uint256 NVBAmount = getNVBamount(remaining);
        require(NVBAmount < _NVBStake, "The rewards are not enought");
        _NVBStake -= NVBAmount * 10 ** 6;
        // end the transactions

        // get UST
        IERC20(_USTAddr).transferFrom(msg.sender, address(this), _amount); 

        // burn luna
        IERC20(_USTAddr).transfer(_burnWalled, burned);

        // transfer the remaining luna to LP walled
        IERC20(_USTAddr).transfer(_receiverAddr, remaining);

        // send NVB back
        IERC20(_NVBAddr).transfer(msg.sender, NVBAmount);
    }

    function getNVBamount (uint256 _amount) public pure returns(uint256) {
        // Let's start about 1 NBV for 0.5 UST
        return _amount / 500000;
    }
}