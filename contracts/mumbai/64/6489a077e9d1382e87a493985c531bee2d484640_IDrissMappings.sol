/**
 *Submitted for verification at polygonscan.com on 2022-08-05
*/

/**
 *Submitted for verification at polygonscan.com on 2022-03-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1; 

interface ERC20 {
    function balanceOf(address _tokenOwner) external view returns (uint balance);
    function transfer(address _to, uint _tokens) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _contract, address _spender) external view returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract IDrissMappings {
    uint public countAdding = 0; 
    uint public countDeleting = 0; 
    uint public price = 0;      
    uint public creationTime = block.timestamp;
    address public contractOwner = msg.sender; 
    mapping(string => string) private IDriss;
    mapping(string => string) private IDrissHash;
    mapping(string => address) public IDrissOwners; 
    mapping(string => uint) public payDates;    
    mapping(address => bool) private admins;
    
    event Increment(uint value);
    event Decrement(uint value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event IDrissOwnershipTransferred(address indexed previousIDrissOwner, address indexed newIDrissOwner);
    event IDrissAdded(string indexed hash);
    event IDrissDeleted(string indexed hash);
    event NewPrice(uint price);
    event AdminAdded(address indexed admin);
    event AdminDeleted(address indexed admin);


    function addAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can add admins.");
        admins[adminAddress] = true;
        emit AdminAdded(adminAddress);
    }

    function deleteAdmin(address adminAddress) external {
        require(msg.sender == contractOwner, "Only contractOwner can delete admins.");
        admins[adminAddress] = false;
        emit AdminDeleted(adminAddress);
    }

    function setPrice(uint newPrice) external {
        require(msg.sender == contractOwner, "Only contractOwner can set price.");
        price = newPrice;
        emit NewPrice(price);
    }
    
    function withdraw() external returns (bytes memory) {
        require(admins[msg.sender] == true, "Only trusted admin can withdraw.");
        (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance, gas: 40000}("");
        require(sent, "Failed to  withdraw.");
        return data;
    }

    function withdrawTokens(address tokenContract) external {
        require(admins[msg.sender] == true, "Only trusted admin can withdraw.");
        ERC20 tc = ERC20(tokenContract);
        tc.transfer(msg.sender, tc.balanceOf(address(this)));
    }
    

    function increment() private {
        countAdding += 1;
        emit Increment(countAdding);
    }
    
    function decrement() private {
        countDeleting += 1;
        emit Decrement(countDeleting);
    }

    function addIDriss(string memory hashPub, string memory hashID, string memory address_, address ownerAddress) external payable {
        require(admins[msg.sender] == true, "Only trusted admin can add IDriss.");
        require(keccak256(bytes(IDrissHash[hashPub])) == keccak256(bytes("")), "Cannot change existing binding.");
        require(msg.value >= price, "Not enough MATIC.");
        IDriss[hashID] = address_;
        IDrissHash[hashPub] = hashID;
        IDrissOwners[hashPub] = ownerAddress;
        payDates[hashPub] = block.timestamp;
        increment();
        emit IDrissAdded(hashPub);
    }
    
    function addIDrissToken(string memory hashPub, string memory hashID, string memory address_, address token, uint amount, address ownerAddress) external payable{
        require(admins[msg.sender] == true, "Only trusted admin can add IDriss.");
        require(keccak256(bytes(IDrissHash[hashPub])) == keccak256(bytes("")), "Binding already created.");
        ERC20 paymentTc = ERC20(token);
        require(paymentTc.allowance(msg.sender, address(this)) >= amount,"Insuficient Allowance.");
        require(paymentTc.transferFrom(msg.sender, address(this), amount),"Transfer Failed.");
        IDriss[hashID] = address_;
        IDrissHash[hashPub] = hashID;
        IDrissOwners[hashPub] = ownerAddress;
        payDates[hashPub] = block.timestamp;
        increment();
        emit IDrissAdded(hashPub);
    }
    
    function deleteIDriss(string memory hashPub) external payable {
        require(IDrissOwners[hashPub] == msg.sender, "Only IDrissOwner can delete binding.");
        require(keccak256(bytes(IDrissHash[hashPub])) != keccak256(bytes("")), "Binding does not exist.");
        delete IDriss[IDrissHash[hashPub]];
        delete IDrissHash[hashPub];
        delete IDrissOwners[hashPub];
        delete payDates[hashPub];
        decrement();
        emit IDrissDeleted(hashPub);
    }

    function getIDriss(string memory hashPub) public view returns (string memory){
        require(keccak256(bytes(IDrissHash[hashPub])) != keccak256(bytes("")), "Binding does not exist.");
        return IDriss[IDrissHash[hashPub]];
    }

    function transferIDrissOwnership(string memory hashPub, address newOwner) external payable {
        require(IDrissOwners[hashPub] == msg.sender, "Only IDrissOwner can change ownership.");
        IDrissOwners[hashPub] = newOwner;
        emit IDrissOwnershipTransferred(msg.sender, newOwner);
    }

    function transferContractOwnership(address newOwner) public payable {
        require(msg.sender == contractOwner, "Only contractOwner can change ownership of contract.");
        require(newOwner != address(0), "Ownable: new contractOwner is the zero address.");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = contractOwner;
        contractOwner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}