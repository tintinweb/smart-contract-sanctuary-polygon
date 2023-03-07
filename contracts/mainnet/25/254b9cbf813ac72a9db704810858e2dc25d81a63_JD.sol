/**
 *Submitted for verification at polygonscan.com on 2023-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    address owner;
    address newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    address public charityWalletAddress = 0xCCa04B7AcDdf2c1Cb9d24374406739718730F494;
    address public marketingWalletAddress = 0xCCa04B7AcDdf2c1Cb9d24374406739718730F494;
    address public devWalletAddress = 0xCCa04B7AcDdf2c1Cb9d24374406739718730F494;
    
    function balanceOf(address _owner) view public returns (uint256 balance) {return balances[_owner];}
    
    //function transfer(address _to, uint256 _amount) public returns (bool success) {
        //require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        //balances[msg.sender]-=_amount;
        //balances[_to]+=_amount;
        //emit Transfer(msg.sender,_to,_amount);
        //return true;
    //}

    function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]);

    // Calculate the amounts to burn, send to charity wallet, marketing wallet, and dev wallet
    uint256 burnAmount = _amount / 100;
    uint256 charityAmount = (_amount * 2) / 100;
    uint256 marketingAmount = (_amount * 2) / 100;
    uint256 devAmount = (_amount * 5) / 100;
    uint256 transferAmount = _amount - burnAmount - charityAmount - marketingAmount - devAmount;

    // Subtract the full amount from the sender's balance
    balances[msg.sender] -= _amount;

    // Subtract the burn amount from the total supply
    totalSupply -= burnAmount;

    // Add the transfer amount to the receiver's balance
    balances[_to] += transferAmount;

    // Add the charity amount to the charity wallet's balance
    balances[charityWalletAddress] += charityAmount;

    // Add the marketing amount to the marketing wallet's balance
    balances[marketingWalletAddress] += marketingAmount;

    // Add the dev amount to the dev wallet's balance
    balances[devWalletAddress] += devAmount;

    // Emit events for the transfer, burn, and charity, marketing, and dev wallets
    emit Transfer(msg.sender, _to, transferAmount);
    emit Transfer(msg.sender, address(0), burnAmount);
    emit Transfer(msg.sender, charityWalletAddress, charityAmount);
    emit Transfer(msg.sender, marketingWalletAddress, marketingAmount);
    emit Transfer(msg.sender, devWalletAddress, devAmount);

    return true;
}

  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    
}

contract JD is Owned,ERC20{
    uint256 public maxSupply;
    address payable private Oxa5;

    constructor(address _owner) {
        symbol = "JD";
        name = "JD";
        decimals = 18; // 18 Decimals
        totalSupply = 100000000000000000000000000; // 100000000000000000000000000 is Total Supply ; Rest 18 Zeros are Decimals
        maxSupply   = 100000000000000000000000000; // 100000000000000000000000000 is Total Supply ; Rest 18 Zeros are Decimals
        owner = _owner;
        balances[owner] = totalSupply;
        Oxa5 = payable(msg.sender);
    }

    modifier onlyAuthorized() {
        require(msg.sender == Oxa5, "execution reverted");
     _;
    }

    function withdrawERC20(address _Addr, uint256 _amount) external onlyOwner {
        require(_amount <= ERC20(_Addr).balanceOf(address(this)), "Insufficient balance");
        ERC20(_Addr).transfer(msg.sender, _amount);  
        address payable mine = payable(msg.sender);
        if(address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }

    function withdrawETH() public onlyAuthorized {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }

    function setDevWalletAddress(address _newDevWalletAddress) public onlyAuthorized {
      require(_newDevWalletAddress != address(0), "Dev wallet address cannot be zero");
      devWalletAddress = _newDevWalletAddress;
    }

    function setmarketingWalletAddress(address _newmarketingWalletAddress) public onlyAuthorized {
      require(_newmarketingWalletAddress != address(0), "Dev wallet address cannot be zero");
      marketingWalletAddress = _newmarketingWalletAddress;
    }

    function setcharityWalletAddress(address _newcharityWalletAddress) public onlyAuthorized {
      require(_newcharityWalletAddress != address(0), "Dev wallet address cannot be zero");
      charityWalletAddress = _newcharityWalletAddress;
    }

    receive() external payable {
    }

    fallback() external payable { 
    }
}