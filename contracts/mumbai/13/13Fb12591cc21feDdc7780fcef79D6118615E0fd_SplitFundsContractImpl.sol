/**
 *Submitted for verification at polygonscan.com on 2023-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

    /**
     * @author Ivan
     */

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(tx.origin);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface ISplitFundsContract {

    function deposit() external payable;
    function withdraw() external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}



contract SplitFundsContractImpl is ISplitFundsContract, Ownable {

    uint256 public balance = address(this).balance;
    uint256 public ercBalance;
    address public tokenAddress;
    address[] private userAddresses;

    string public titleWallet;

     struct User {
        uint256 balance;
        bool exists;
        uint256 ercBalance;
    }

    uint256 public number;

  // ["0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2","0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]
    
    mapping(address => User) public users;
    mapping(address =>  mapping(uint256 => string)) public transaction_details;

    constructor(address[] memory initialUsers, string memory title, address _tokenAddress) {

         titleWallet = title; 
         users[tx.origin] = User({balance: 0, exists: true, ercBalance: 0});
         userAddresses.push(tx.origin);
         tokenAddress = _tokenAddress;

        for (uint256 i = 0; i < initialUsers.length; i++) {
             users[initialUsers[i]] = User({balance: 0, exists: true, ercBalance: 0});
             userAddresses.push(initialUsers[i]);
        }
    }

      modifier onlyAuthorized() {
        require(users[msg.sender].exists || owner() == msg.sender);
        _;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
    tokenAddress = _tokenAddress;
}

    function deposit() external payable override {

        require(users[msg.sender].exists, "User does not exist");

        users[msg.sender].balance += msg.value;
        balance += msg.value;
    }

     function addUser(address userAddress) public onlyAuthorized {
        require(!users[userAddress].exists, "User already exists");
        users[userAddress] = User({balance: 0, exists: true, ercBalance: 0});
        userAddresses.push(userAddress);
    }

    function depositERC(uint256 amount) external payable  {

        IERC20 token = IERC20(tokenAddress);

        require(users[msg.sender].exists, "User does not exist");

        require(token.transferFrom(msg.sender, address(this), amount), "Tnx failed");

        users[msg.sender].ercBalance += amount;
        ercBalance += amount;
    }

    function spend(uint256 amount, address payable recipient, string calldata information) external  onlyAuthorized {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= balance, "Insufficient funds");

        transaction_details[recipient][amount] = information;

        uint256 numUsers = userAddresses.length;
        uint256 amountPerUser = amount / numUsers;

        for (uint256 i = 0; i < numUsers; i++) {
            users[userAddresses[i]].balance -= amountPerUser;
            payable(recipient).transfer(amountPerUser);
            balance -= amountPerUser;
        }
    }

    function spendERC(uint256 amount, address payable recipient, string calldata information) external onlyAuthorized {
    require(amount > 0, "Amount must be greater than zero");
    require(tokenAddress != address(0), "Token address not set");

    transaction_details[recipient][amount] = information;

    uint256 numUsers = userAddresses.length;
    uint256 amountPerUser = amount / numUsers;

    IERC20 token = IERC20(tokenAddress);

    for (uint256 i = 0; i < numUsers; i++) {
        users[userAddresses[i]].ercBalance -= amountPerUser;
        token.transferFrom(msg.sender, recipient, amount);
        ercBalance -= amountPerUser;
    }
 }


    function withdraw() external override onlyAuthorized {
        require(users[msg.sender].balance > 0, "You have no balance to withdraw");

        uint256 amount = users[msg.sender].balance;
        users[msg.sender].balance = 0;
        balance -= amount;

        payable(msg.sender).transfer(amount);
    }


    function withdrawERC() external onlyAuthorized {
        require(users[msg.sender].ercBalance > 0, "You have no balance to withdraw");

        uint256 amount = users[msg.sender].ercBalance;
        users[msg.sender].ercBalance = 0;
        ercBalance -= amount;

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, tx.origin, amount);
        payable(msg.sender).transfer(amount);
    }

  function getBalance(address _myAddress) external view returns (uint256, uint256) {
        return (users[_myAddress].balance, users[_myAddress].ercBalance);
    }

    function getAllUsers() external view returns (address[] memory) {
        return userAddresses;
    }
}


contract SplitFundsContractFactory {

    mapping(string => address) public contractAddr;
    address[] allAddresses; 

    function createContract(address[] memory addresses, string calldata title, address ercAddress) external returns (address) {
        SplitFundsContractImpl newContract = new SplitFundsContractImpl(addresses, title, ercAddress);
        contractAddr[title] = address(newContract);
        allAddresses.push(address(newContract));
        return contractAddr[title];
    }

    function getAllAddresses() public view returns (address[] memory) {
    return allAddresses;
    }


}