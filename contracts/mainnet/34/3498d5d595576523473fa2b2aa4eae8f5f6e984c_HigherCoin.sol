/**
 *Submitted for verification at polygonscan.com on 2022-03-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IHigherCoinERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address ownder, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}


contract HigherCoin is IHigherCoinERC20 {
    using SafeMath for uint256;

    bytes32 public constant name = "Higher Coin";
    bytes32 public constant symbol = "HIGH";
    uint8 public constant decimals = 18;
    address private ownerAddress_ = address(0x362A6DC6877f61476b852D60d4E8c5273eDb7a2D);
    address private mhcaddress = address(0x5246F4b6b0Fbe5F65EBe6606bbA693C50CbbB74d);
    address private nftloanaddress = address(0xaf629527BB7f7E4330915c2a24B00785a47c96F5);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => bool) whitelistedAddresses;

    uint256 totalSupply_;

    constructor(uint256 total) {
        totalSupply_ = total;
        balances[ownerAddress_] = totalSupply_;
    }

    function _mint(address to, uint value) internal {
        totalSupply_ = totalSupply_.add(value);
        balances[to] = balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balances[from] = balances[from].sub(value);
        totalSupply_ = totalSupply_.sub(value);
        emit Transfer(from, address(0), value);
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        // uint256 mhcfee = (numTokens / 100) * 1; // Calculate 1% MHC fee
        // uint256 nftloanfee = (numTokens / 100) * 2; // Calculate 2% NFT loan fee
        // balances[mhcaddress] = balances[mhcaddress].add(mhcfee);
        // balances[nftloanaddress] = balances[nftloanaddress].add(nftloanfee);

        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

    modifier isWhitelisted(address _address) {
        require(whitelistedAddresses[_address], "You need to be whitelisted");
        _;
    }

    function addUser(address _addressToWhitelist) public onlyOwner {
        whitelistedAddresses[_addressToWhitelist] = true;
    }

    function verifyUser(address _whitelistedAddress) public view returns(bool) {
        bool userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
        return userIsWhitelisted;
    }
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress_, "Ownable: caller is not the owner");
        _;
    }   

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(ownerAddress_, address(0));
        ownerAddress_ = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(ownerAddress_, newOwner);
        ownerAddress_ = newOwner;
    }

}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}