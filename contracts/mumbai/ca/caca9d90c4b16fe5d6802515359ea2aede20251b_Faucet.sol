/**
 *Submitted for verification at polygonscan.com on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Faucet{

    IERC20 public immutable token0;
    IERC20 public immutable token1;

    address public owner;
    mapping(address => uint256) public timeFaucet;

    uint256 public lockhourPeriods;
    uint256 public amount0;
    uint256 public amount1;
    bool public isOpen;

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        owner = msg.sender;
        lockhourPeriods = 1;
        amount0 = 100 * 10 ** 18;
        amount1 = 1000 * 10 ** 18;
        isOpen =  true;
    }

    function modifyTimeFaucet(address user,uint256 newTime) external onlyOwner {
       require(isOpen,"it Close");
       timeFaucet[user] = newTime;
    }

    function modifyLockHourPeriods(uint256 hoursTime) external onlyOwner {
       require(isOpen,"it Close");
       lockhourPeriods = hoursTime;
    }

    function modifyAmountToken(uint256 _amount0,uint256 _amount1) external onlyOwner {
       require(isOpen,"it Close");
       amount0 = _amount0 * 10 ** 18;
       amount1 = _amount1 * 10 ** 18;
    }


    function togleOpen() external onlyOwner {
        isOpen = !isOpen;
    }

    function getFaucet() external  {
       require(isOpen,"it Close");
       if(timeFaucet[msg.sender]== 0){
           timeFaucet[msg.sender] = block.timestamp;
       }
       require(timeFaucet[msg.sender] <= block.timestamp,"It is not time pls wait");
       timeFaucet[msg.sender] = block.timestamp + (60*60*lockhourPeriods );
       token0.transfer(msg.sender, amount0);
       token1.transfer(msg.sender, amount1);
    }


    modifier onlyOwner {
        require(owner == msg.sender,"Only can call this fucntion");
        _;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}