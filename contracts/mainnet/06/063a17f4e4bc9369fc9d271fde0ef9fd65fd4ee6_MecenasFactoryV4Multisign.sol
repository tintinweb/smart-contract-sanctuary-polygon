// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MecenasV4.sol";


interface WalletFactory {

    function newMecenasWallet(address _owneraddress, address _pooladdress, address _underlyingaddress) external returns (address);
}


contract MecenasFactoryV4Multisign {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    struct Pool {
        MecenasV4 newpool;
        address newmarket;
        address newunderlying;
        string newnametoken;
    }
    
    mapping(address => Pool[]) public OwnerPools;
    mapping(MecenasV4 => uint) public MapPools;
    Pool[] public FactoryPools;

    uint public counterpools;
    uint public cyclelotteryfactory;

    address public factoryowner;
    address public factorydeveloper;
    address public factoryseeker;
    WalletFactory public thewalletfactory;

    bool public lockfactory;

 
    event ChildCreated(address childAddress, address indexed yield, address indexed underlying, address indexed owner);
    event ChangeFactoryDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeFactorySeeker(address indexed oldseeker, address indexed newseeker);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool oldlock, bool newlock);
    event ChangeFactoryWallet(address indexed oldfactory, address indexed newfactory);
    event ChangeCycleLotteryFactory(uint oldcycle, uint newcycle);


    constructor(address _developer, address _seeker, address _walletfactory, uint _cyclelotteryfactory) {
        factoryowner = msg.sender;
        factorydeveloper = _developer;
        factoryseeker = _seeker;
        thewalletfactory = WalletFactory(_walletfactory);
        cyclelotteryfactory = _cyclelotteryfactory;
    }    

    
    // Changes the factory developer address

    function changedeveloper(address _newdeveloper) public {
        require(_newdeveloper != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address olddeveloper = factorydeveloper;
        factorydeveloper = _newdeveloper;
    
        emit ChangeFactoryDeveloper(olddeveloper, factorydeveloper);
    }


    // Changes the wallet factory address

    function changewalletfactory(address _newwalletfactory) public {
        require(_newwalletfactory != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldfactory = address(thewalletfactory);
        thewalletfactory = WalletFactory(_newwalletfactory);
    
        emit ChangeFactoryWallet(oldfactory, address(thewalletfactory));
    }


    // Changes the factory seeker address

    function changeseeker(address _newseeker) public {
        require(_newseeker != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldseeker = factoryseeker;
        factoryseeker = _newseeker;
    
        emit ChangeFactorySeeker(oldseeker, factoryseeker);
    }


    // Changes the factory owner address

    function changeowner(address _newowner) public {
        require(_newowner != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldowner = factoryowner;
        factoryowner = _newowner;
    
        emit ChangeFactoryOwner(oldowner, factoryowner);
    }


    // Locks and unlocks de factory 
    // false = unlock
    // true = lock
    
    function changelockfactory(bool _newlock) public {
        require(_newlock == true || _newlock == false);
        require(msg.sender == factoryowner);
        bool oldlock = lockfactory;
        lockfactory = _newlock;
    
        emit ChangeFactoryLock(oldlock, lockfactory);
    }


    // Changes the factory lottery cycle

    function changecyclelottery(uint _newcycle) public {
        require(_newcycle > 0 && msg.sender == factoryowner);
        uint oldcycle = cyclelotteryfactory;
        cyclelotteryfactory = _newcycle;
    
        emit ChangeCycleLotteryFactory(oldcycle, cyclelotteryfactory);
    }


    // Creates a new Mecenas pool

    function newMecenasPool(address _yield) external {
        require(!lockfactory);
        require(msg.sender != EMPTY_ADDRESS_FACTORY && _yield != EMPTY_ADDRESS_FACTORY);
                
        counterpools++;
    
        MecenasV4 newpool = new MecenasV4(address(this), _yield, factorydeveloper, factoryseeker, cyclelotteryfactory);
    
        CreamYield marketfactory = CreamYield(_yield);
        ERC20 underlyingfactory = ERC20(marketfactory.underlying()); 
        string memory nametokenfactory = underlyingfactory.symbol();
        
        address newwallet = thewalletfactory.newMecenasWallet(msg.sender, address(newpool), address(underlyingfactory));

        newpool.transferowner(newwallet);        

        OwnerPools[msg.sender].push(Pool(MecenasV4(newpool), address(_yield), address(underlyingfactory), nametokenfactory));
        MapPools[newpool] = 1;
        FactoryPools.push(Pool(MecenasV4(newpool), address(_yield), address(underlyingfactory), nametokenfactory));
        
        emit ChildCreated(address(newpool), address(_yield), address(underlyingfactory), msg.sender);
    }
    
    
    // Returns an array of struct of pools created by owner
    
    function getOwnerPools(address _account) external view returns (Pool[] memory) {
      return OwnerPools[_account];
    } 


    // Returns an array of struct of pools created
    
    function getTotalPools() external view returns (Pool[] memory) {
      return FactoryPools;
    }

}