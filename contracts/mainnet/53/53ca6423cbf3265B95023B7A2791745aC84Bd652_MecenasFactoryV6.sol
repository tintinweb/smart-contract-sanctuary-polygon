// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./MecenasV6.sol";


interface WalletFactory {

    function newMecenasWallet(address _owneraddress, address _pooladdress, address _underlyingaddress) external returns (address);
}


contract MecenasFactoryV6 {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    struct Pool {
        address newpool;
        address newmarket;
        address newunderlying;
        string newnametoken;
        uint pooltype;
    }
    
    WalletFactory public thewalletfactory;

    mapping(address => Pool[]) public ownerPools;
    mapping(address => Pool) public mapPools;
    mapping(address => uint) public moneymarkets; 
  
  
    Pool[] public factoryPools;

    uint public counterpools;
    uint public cyclelotteryfactory;
    uint public factoryRNGgenerator;

    address public factoryowner;
    address public factorydeveloper;
    address public factorypricefeed;
    
    bool public lockfactory;

    uint public developerfeejackpot;
    uint public developerfeewithdraw;
    uint public jackpotpercentage;

 
    event ChildCreated(address childAddress, address indexed yield, address indexed underlying, address indexed owner, uint _thetype);
    event ChangeFactoryDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool newlock);
    event ChangeCycleLotteryFactory(uint oldcycle, uint newcycle);
    event ChangePriceFeedFactory(address indexed oldpricefeed, address indexed newpricefeed);
    event ChangeRNGgeneratorFactory(uint newRNG);
    event ChangeFactoryWallet(address indexed oldfactory, address indexed newfactory);
    event ChangePercentages(uint oldfee, uint newfee, uint feetype);
    event ChangeMoneyMarkets(address market, uint state);


    constructor(address _developer, uint _cyclelotteryfactory, address _pricefeed, uint _factoryRNG, address _walletfactory, uint _jackpotfee, uint _withdrawfee, uint _jackpotpercentage) {
        require(_factoryRNG == 1 || _factoryRNG == 2);
        require(_jackpotfee > 0 && _jackpotfee < 100);
        require(_withdrawfee > 0 && _withdrawfee < 100);
        require(_jackpotpercentage > 0 && _jackpotpercentage < 100);
        require(_cyclelotteryfactory > 0);
        require(_pricefeed != EMPTY_ADDRESS_FACTORY);
        require(_walletfactory != EMPTY_ADDRESS_FACTORY);
        require(_developer != EMPTY_ADDRESS_FACTORY);

        factoryowner = msg.sender;
        factorydeveloper = _developer;
        cyclelotteryfactory = _cyclelotteryfactory;
        factorypricefeed = _pricefeed;
        factoryRNGgenerator = _factoryRNG;
        thewalletfactory = WalletFactory(_walletfactory);
        developerfeejackpot = _jackpotfee;
        developerfeewithdraw = _withdrawfee;
        jackpotpercentage = _jackpotpercentage;
    }    

    
    // Changes the wallet factory address

    function changeWalletFactory(address _newwalletfactory) public {
        require(_newwalletfactory != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldfactory = address(thewalletfactory);
        thewalletfactory = WalletFactory(_newwalletfactory);
    
        emit ChangeFactoryWallet(oldfactory, address(thewalletfactory));
    }


    // Changes the factory developer address

    function changeDeveloper(address _newdeveloper) public {
        require(_newdeveloper != EMPTY_ADDRESS_FACTORY && msg.sender == factorydeveloper);
        address olddeveloper = factorydeveloper;
        factorydeveloper = _newdeveloper;
    
        emit ChangeFactoryDeveloper(olddeveloper, factorydeveloper);
    }


    // Changes the factory owner address

    function changeOwner(address _newowner) public {
        require(_newowner != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldowner = factoryowner;
        factoryowner = _newowner;
    
        emit ChangeFactoryOwner(oldowner, factoryowner);
    }


    // Changes the factory lottery cycle

    function changeCycleLottery(uint _newcycle) public {
        require(_newcycle > 0 && msg.sender == factoryowner);
        uint oldcycle = cyclelotteryfactory;
        cyclelotteryfactory = _newcycle;
    
        emit ChangeCycleLotteryFactory(oldcycle, cyclelotteryfactory);
    }


    // Changes address Price Feed

    function changePriceFeed(address _newpricefeed) public {
        require(_newpricefeed != EMPTY_ADDRESS_FACTORY && msg.sender == factoryowner);
        address oldpricefeed = factorypricefeed;
        factorypricefeed = _newpricefeed;
    
        emit ChangePriceFeedFactory(oldpricefeed, factorypricefeed);
    }


    // Changes the RNG generator method
    // 1 = PRICE FEED
    // 2 = FUTURE BLOCKHASH

    function changeRNGgenerator() public {
        require(msg.sender == factoryowner);
        
        if (factoryRNGgenerator == 1) {
            factoryRNGgenerator = 2;
        }
        
        if (factoryRNGgenerator == 2) {
            factoryRNGgenerator = 1;
        }

        emit ChangeRNGgeneratorFactory(factoryRNGgenerator);
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


    // Changes Percentages for new pools
    //1= Developer Jackpot Feed
    //2= Developer Withdraw Feed
    //3= Lottery Percentage

    function changePoolPercentages(uint _newfee, uint _type) public {
        require(msg.sender == factoryowner);
        require(_type == 1 || _type == 2 || _type == 3);
        require(_newfee > 0 && _newfee < 100);

        uint oldfee;
        
        if (_type == 1) {
            oldfee = developerfeejackpot;
            developerfeejackpot = _newfee;
        }

        if (_type == 2) {
            oldfee = developerfeewithdraw;
            developerfeewithdraw = _newfee;
        }

        if (_type == 3) {
            oldfee = jackpotpercentage;
            jackpotpercentage = _newfee;
        }

        emit ChangePercentages(oldfee, _newfee, _type);
    }


    // Update lending contracts addresses authorized to use
    // 1 = Authorized
    // 2 = Not Authorized

    function updateMoneyMarkets(address _market, uint _state) public {    
        require(msg.sender == factoryowner);
        require(_market != EMPTY_ADDRESS_FACTORY);
        require(_state == 1 || _state == 2); 

        moneymarkets[_market] = _state;

        emit ChangeMoneyMarkets(_market, _state);
    }    


    // Creates a new Mecenas pool
    // Type 1 = Single Signature
    // Type 2 = Multi Signature
    // Yield = Money Market Address

    function newMecenasPool(address _yield, uint _pooltype) external {
        require(!lockfactory);
        require(_yield != EMPTY_ADDRESS_FACTORY);
        require(moneymarkets[_yield] == 1);
        require(_pooltype == 1 || _pooltype == 2);

        counterpools++;
        MecenasV6 newpool;

        if (_pooltype == 1) {
            newpool = new MecenasV6(msg.sender, _yield, factorydeveloper, cyclelotteryfactory, factorypricefeed, factoryRNGgenerator, developerfeejackpot, developerfeewithdraw, jackpotpercentage);
        }

        if (_pooltype == 2) {
            newpool = new MecenasV6(address(this), _yield, factorydeveloper, cyclelotteryfactory, factorypricefeed, factoryRNGgenerator, developerfeejackpot, developerfeewithdraw, jackpotpercentage);    
        }

        CreamYield marketfactory = CreamYield(_yield);
        ERC20 underlyingfactory = ERC20(marketfactory.underlying()); 
        string memory nametokenfactory = underlyingfactory.symbol();
        
        if (_pooltype == 2) {
            address newwallet = thewalletfactory.newMecenasWallet(msg.sender, address(newpool), address(underlyingfactory));
            newpool.transferOwner(newwallet);        
        }

        ownerPools[msg.sender].push(Pool(address(newpool), address(_yield), address(underlyingfactory), nametokenfactory, _pooltype));
        mapPools[address(newpool)] = Pool(address(newpool), address(_yield), address(underlyingfactory), nametokenfactory, _pooltype);
        factoryPools.push(Pool(address(newpool), address(_yield), address(underlyingfactory), nametokenfactory, _pooltype));
        
        emit ChildCreated(address(newpool), address(_yield), address(underlyingfactory), msg.sender, _pooltype);
    }
    

    // Returns an array of pools by owner
    
    function getOwnerPools(address _account) external view returns (Pool[] memory) {
      return ownerPools[_account];
    } 


    // Returns an array of pools

    function getTotalPools() external view returns (Pool[] memory) {
      return factoryPools;
    }

}