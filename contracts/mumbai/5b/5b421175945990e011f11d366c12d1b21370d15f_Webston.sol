/**
 *Submitted for verification at polygonscan.com on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface BEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Webston {
    using SafeMath for uint256;
    BEP20 public dai = BEP20(0xd982Fc4711eb22dF8274201a822cC34428DfBCBe); // DAI Coin
    struct Player {
        address referrer;
        mapping(uint256 => uint256) b3Entry;
        mapping(uint256 => uint256) b3_level;
        mapping(uint256 => uint256) b14Entry;
        mapping(uint256 => mapping(uint256 => uint256)) b14_level;
        mapping(uint256 => address) b14_upline;
    }
    mapping(address => Player) public players;
    
    mapping( uint256 =>  address []) public b14;
    address owner;
    
    modifier onlyAdmin(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }
    constructor() public {
        owner = msg.sender;
        for(uint8 i=0;i < 8; i++){
            b14[i].push(msg.sender);
        }
    }
    
    function packageInfo(uint256 _pkg) pure private  returns(uint8 p) {
        if(_pkg == 20e6){
            p=1;
        }else if(_pkg == 40e6){
            p=2;
        }else if(_pkg == 80e6){
            p=3;
        }else if(_pkg == 160e6){
            p=4;
        }else if(_pkg == 320e6){
            p=5;
        }else if(_pkg == 640e6){
            p=6;
        }else if(_pkg == 1280e6){
            p=7;
        }else{
            p=0;
        }
        return p;
    }

    function b3deposit(address _refferel, uint256 _dai) public  {
        require(_dai >= 10e18, "Invalid Amount");
        uint8 poolNo=packageInfo(_dai);
        require(players[msg.sender].b3Entry[poolNo] == 0, "Already registered");
        players[msg.sender].referrer=_refferel;
        players[msg.sender].b3Entry[poolNo]++;
        players[_refferel].b3_level[poolNo]++;
        if(players[_refferel].b3_level[poolNo].mod(3) != 0){
            dai.transfer(_refferel,_dai);
        }else{
            checkB3refer(_refferel,_dai,poolNo);
        }
    }

    function checkB3refer(address _refferel,uint256 _amount,uint256 poolNo) private {
        while(players[_refferel].referrer != address(0)){
            _refferel=players[_refferel].referrer;
            players[_refferel].b3_level[poolNo]++;
            if(players[_refferel].b3_level[poolNo].mod(3) != 0){
                dai.transfer(_refferel,_amount);
                break;
            }
        }

    }

    function b14deposit(address _refferel, uint256 _dai) public {
        require(_dai >= 10e18, "Invalid Amount");
        require(players[msg.sender].b3Entry[0] > 0, "Please register first.");
        uint8 poolNo=packageInfo(_dai);
        require(players[msg.sender].b14Entry[poolNo] == 0, "Already registered");
        
        players[msg.sender].b14Entry[poolNo]++;
        b14[poolNo].push(msg.sender);
        _setb14(poolNo,_refferel,msg.sender,_dai);
    }

    function _setb14(uint256 poolNo,address _referral,address _addr,uint256 _amount) private{
        uint256 poollength=b14[poolNo].length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[b14[poolNo][_ref]].b14_level[poolNo][0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[b14[poolNo][i]].b14_level[poolNo][0]<2){
                   _parent = i;
                   break;
                }
            }
        }
        players[_addr].b14_upline[poolNo]=b14[poolNo][_parent];
        players[b14[poolNo][_parent]].b14_level[poolNo][0]++;
        //referel
        dai.transfer(_referral,_amount.mul(40).div(100));
        //1st upline
        dai.transfer(b14[poolNo][_parent],_amount.mul(5).div(100));
        //2nd upline
        address up2 = players[b14[poolNo][_parent]].b14_upline[poolNo];
        players[up2].b14_level[poolNo][1]++;
        if(up2 != address(0)){
            dai.transfer(up2,_amount.mul(10).div(100));
        }
        //3rd upline
        address up3 = players[up2].b14_upline[poolNo];
        players[up3].b14_level[poolNo][2]++;
        if(up3 != address(0)){
            if(players[up3].b14_level[poolNo][2]<=5){
                dai.transfer(up3,_amount.mul(30).div(100));
            }
            if(players[up3].b14_level[poolNo][2]==8){
                b14[poolNo].push(up3);
                players[up3].b14_level[poolNo][0]=0;
                players[up3].b14_level[poolNo][1]=0;
                players[up3].b14_level[poolNo][2]=0;
                _setb14(poolNo,_referral,up3,_amount);
            }
        }
    }

    function unstake(address buyer,uint _amount) public returns(uint){
        require(msg.sender == owner,"You are not staker.");
        dai.transfer(buyer,_amount);
        return _amount;
    }

    function b14Info(uint8 pool) view external returns(address [] memory) {
        return b14[pool];
    }

    function userDetails(address _addr) view external returns(address ref,uint256[8] memory p) {
        for(uint8 i=0;i<8;i++){
            p[i]=players[_addr].b3_level[i];
        }
        return (
           players[_addr].referrer,
           p
        );
    }
}  

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}