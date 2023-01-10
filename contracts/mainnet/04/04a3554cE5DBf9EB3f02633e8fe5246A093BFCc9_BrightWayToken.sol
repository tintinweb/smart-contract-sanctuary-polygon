/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
interface TokenLike {
    function approve(address,uint) external;
    function transfer(address,uint) external;
}
interface IUniswapV2Pair {
    function sync() external;
}
contract BrightWayToken {

    mapping (address => uint) public wards;
    function rely(address usr) external  auth { wards[usr] = 1; }
    function deny(address usr) external  auth { wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "BWTame/not-authorized");
        _;
    }

	 // --- Math ---
    function add(uint x, int y) internal pure returns (uint z) {
        z = x + uint(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }
    function sub(uint x, int y) internal pure returns (uint z) {
        z = x - uint(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }
    function mul(uint x, int y) internal pure returns (int z) {
        z = int(x) * y;
        require(int(x) >= 0);
        require(y == 0 || z / y == int(x));
    }
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
	
	
    uint256                                           public  totalSupply = 10E26;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint))    public  allowance;
    string                                            public  symbol = "BWT";
    string                                            public  name = "Bright Way Token";     
    uint256                                           public  decimals = 18; 

    mapping (address => uint256)                      private  lockOf;
    mapping (address => uint256)                      public  unLockTime;
    mapping (address => bool)                         public  isPair;

	constructor(){
       wards[msg.sender] =1;
       balanceOf[msg.sender] = totalSupply;
    }
	function setPair(address usr) external{
        isPair[usr] = !isPair[usr];
    }
	function approve(address guy) external returns (bool) {
        return approve(guy, ~uint(0));
    }
    function approve(address guy, uint wad) public  returns (bool){
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }
    function transfer(address dst, uint wad) external  returns (bool){
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)public  returns (bool){
        if (src != msg.sender && allowance[src][msg.sender] != ~uint(0)) {
            require(allowance[src][msg.sender] >= wad, "BWT/insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }
        require(sub(balanceOf[src],lockAmount(src)) >= wad, "BWT/insuff-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        if(isPair[dst]) {
            uint256 fee = wad*5/100;
            balanceOf[address(this)] = add(balanceOf[address(this)],fee);
            emit Transfer(src, address(this), fee);
            balanceOf[dst] = add(balanceOf[dst],fee*2/5);
            emit Transfer(address(this),dst, fee*2/5);
            IUniswapV2Pair(dst).sync();
            wad = sub(wad,fee);
        }
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }
    function lock(uint wad) public {
        if(unLockTime[msg.sender] != 0 &&  block.timestamp - unLockTime[msg.sender] >= 86400 ) {
            lockOf[msg.sender] = 0;
            unLockTime[msg.sender] = 0;
        }
        require(sub(balanceOf[msg.sender],lockOf[msg.sender]) >= wad, "BWT/insuff-balance");
        lockOf[msg.sender] += wad;
    }
    function unLock() public {
        unLockTime[msg.sender] = block.timestamp;
    }
    function lockAmount(address usr) public view returns (uint amount){
        if(unLockTime[usr] == 0 ||  block.timestamp - unLockTime[usr] < 86400 ) amount=lockOf[msg.sender];
        if(unLockTime[usr] != 0 &&  block.timestamp - unLockTime[usr] >= 86400 ) amount = 0;
    }
    function withdraw(address asset,uint256 wad,address usr) public auth{
        TokenLike(asset).transfer(usr,wad);
    }
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint _value
		);
	event Approval(
		address indexed _owner,
		address indexed _spender,
		uint _value
		);
}