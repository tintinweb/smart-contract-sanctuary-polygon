// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./MecenasMultisignWalletV6.sol";


contract MecenasMultisignWalletFactoryV6 {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    struct Wallet {
        MecenasMultisignWalletV6 wallet;
        address pool;
        address underlying;
    }
    
    uint public counterwallets;
    address public factoryowner;
    bool public lockfactory;
        
    mapping(address => Wallet[]) public OwnerWallets;
    Wallet[] public FactoryWallets;
     
    event ChildCreated(address indexed childAddress, address indexed pooladdress, address indexed underlyingaddress);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool newlock);


    constructor() {
        factoryowner = msg.sender;
    }    

    
    // Changes the factory owner address

    function changeOwner(address _newowner) public {
        require(_newowner != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldowner = factoryowner;
        factoryowner = _newowner;
    
        emit ChangeFactoryOwner(oldowner, factoryowner);
    }


    // Locks and unlocks de factory 
    // false = unlocked
    // true = locked
    
    function changeLockFactory() public {
        require(msg.sender == factoryowner);
        
        if (lockfactory) {
            lockfactory = false;
        }
        
        if (!lockfactory) {
            lockfactory = true;
        }
    
        emit ChangeFactoryLock(lockfactory);
    }


    // Creates a new Mecenas Multisign Wallet

    function newMecenasWallet(address _owneraddress, address _pooladdress, address _underlyingaddress) external returns (address) {
        require(!lockfactory);
        require(_pooladdress != EMPTY_ADDRESS_FACTORY && _underlyingaddress != EMPTY_ADDRESS_FACTORY);
        require(_owneraddress != EMPTY_ADDRESS_FACTORY);
        
        counterwallets++;
    
        MecenasMultisignWalletV6 newwallet = new MecenasMultisignWalletV6(_owneraddress, _pooladdress, _underlyingaddress);
        
        FactoryWallets.push(Wallet(newwallet, _pooladdress, _underlyingaddress));
        OwnerWallets[_owneraddress].push(Wallet(MecenasMultisignWalletV6(newwallet), address(_pooladdress), address(_underlyingaddress)));

        emit ChildCreated(address(newwallet), _pooladdress, _underlyingaddress);

        return address(newwallet);
    }
    
    
    
    // Returns an array of struct of wallets created by owner

    function getOwnerWallets(address _account) external view returns (Wallet[] memory) {
      return OwnerWallets[_account];
    } 


    // Returns an array of struct of wallets created
    
    function getTotalWallets() external view returns (Wallet[] memory) {
      return FactoryWallets;
    }

}