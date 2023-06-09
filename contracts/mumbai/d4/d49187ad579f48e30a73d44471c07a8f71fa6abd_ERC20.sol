/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

contract ERC20 {
    using SafeMath for uint256;

    string  public Name;
    string  public symbol;
    uint8   public decimals;
    uint256 public totalSupply;
    uint256 public realtotalSupply;
    
    uint256 public feePercents;
    bool    public _feeSwitch;

    uint256 public rewardPercents;
    uint256 public rewardHoldersPercents;
    uint256 public rewardCoolTimer;
    uint256 public rewardCoolTimeSecond;
    bool    public rewardCoolTimeEnd;
    bool    public _rewardSwitch;

    address[] public holders;
    address   public rewardWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {

    Name = "Surprise Token";
    symbol = "STOKEN";
    decimals = 9;
    totalSupply = 1000*(10**uint256(decimals));
    realtotalSupply = totalSupply/(10**uint256(decimals));

    rewardWallet = 0xfd5C73D61c6e953dAE4c8fd684D4002e2BeA3864;
    
    feePercents = 2 ;
    _feeSwitch = false;

    rewardPercents = 20 ;
    rewardHoldersPercents = 30 ;
    rewardCoolTimeSecond = 300 ;
    rewardCoolTimeEnd = false;
    _rewardSwitch = false;

        balanceOf[msg.sender] = totalSupply;
        holders.push(msg.sender);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        autoReward();

        if(_feeSwitch){
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value*(100-feePercents)/100);
            balanceOf[_to] = balanceOf[_to].add(_value*(100-feePercents)/100);

            balanceOf[rewardWallet] = balanceOf[rewardWallet].add(_value*feePercents/100);
        }
        else{
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
            balanceOf[_to] = balanceOf[_to].add(_value);
        }


    if (balanceOf[_to] == _value) {
        holders.push(_to);
    }
    if (balanceOf[msg.sender] == 0) {
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == msg.sender) {
                holders[i] = holders[holders.length - 1];
                holders.pop();
                break;
            }
        }
    
        }
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Not allowed to transfer");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);


        emit Transfer(_from, _to, _value);
        return true;
    }

    function autoReward() private  {

    if(block.timestamp >= rewardCoolTimer){rewardCoolTimeEnd = true;}
          else {rewardCoolTimeEnd = false;}

    require(holders.length >= 2, "Insufficient holders");

    if(_rewardSwitch){
            if(rewardCoolTimeEnd){
            rewardCoolTimer = block.timestamp + rewardCoolTimeSecond;
       
    uint256 _randomholders = holders.length*rewardHoldersPercents/100;
    uint256 amount1 = balanceOf[rewardWallet] * rewardPercents/100;
    uint256 rewardamountper1 = amount1 / _randomholders;


    for(uint256 i=0;i<_randomholders;i++){
        
    uint256 randomholders = uint256(keccak256(abi.encodePacked(block.timestamp, balanceOf[msg.sender]))) % holders.length;

    address from = rewardWallet;
    address to = holders[randomholders];

    require(balanceOf[from] >= 1, "Insufficient balance");

    balanceOf[from] = balanceOf[from].sub(rewardamountper1);
    balanceOf[to] = balanceOf[to].add(rewardamountper1);     }
        }
    }
    
    }

    function feeSwitch () public {
        if(_feeSwitch==true){_feeSwitch=false;}
         else {_feeSwitch=true;}
    }

    function rewardSwitch () public {
        if(_rewardSwitch==true){_rewardSwitch=false;}
         else {_rewardSwitch=true;
            if(block.timestamp >= rewardCoolTimer){
                rewardCoolTimer = block.timestamp + rewardCoolTimeSecond;
            }
        }
                }
    function setrewardPercents (uint256 _rewardPercents) public {
        rewardPercents = _rewardPercents;
    }
    function setfeePercents (uint256 _feePercents) public {
        feePercents = _feePercents;
    }
    function setrewardHoldersPercents (uint256 _rewardHoldersPercents) public {
        rewardHoldersPercents = _rewardHoldersPercents;
    }
    function setrewardCoolTimeSecond (uint256 _seconds) public {
        rewardCoolTimeSecond = _seconds;
    }
    function setrewardAddress (address _rewardWallet) public {
        rewardWallet = _rewardWallet;
    }

}