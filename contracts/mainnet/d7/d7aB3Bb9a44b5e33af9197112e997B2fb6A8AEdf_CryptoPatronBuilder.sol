// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./CryptoPatronPool.sol";


contract CryptoPatronBuilder {

    address public constant EMPTY_ADDRESS_FACTORY = address(0);

    address public immutable poolAddressProvider;

    struct Pool {
        address newPool;
        address newUnderlying;
    }
        
    mapping(address => Pool[]) public ownerPools;
    mapping(address => Pool) public mapPools;
    
    mapping(address => uint) public moneyMarkets; 
    
    Pool[] public factoryPools;

    uint public counterPools;
    uint public cycleLotteryFactory;
    uint public factoryRNGgenerator;

    address public factoryOwner;
    address public factoryDeveloper;
    address public factoryPriceFeed;
    
    bool public lockFactory;

    uint public developerFeeJackpot;
    uint public developerFeeWithdraw;
    uint public jackpotPercentage;
 
    event ChildCreated(address indexed childAddress, address indexed underlying, address indexed owner);
    event ChangeFactoryDeveloper(address indexed olddeveloper, address indexed newdeveloper);
    event ChangeFactoryOwner(address indexed oldowner, address indexed newowner);
    event ChangeFactoryLock(bool newlock);
    event ChangeCycleLotteryFactory(uint oldcycle, uint newcycle);
    event ChangePriceFeedFactory(address indexed oldpricefeed, address indexed newpricefeed);
    event ChangeRNGgeneratorFactory(uint newRNG);
    event ChangePercentages(uint oldfee, uint newfee, uint feetype);
    event ChangeMoneyMarkets(address market, uint state);


    constructor(
        address _developer,
        uint _cycleLotteryFactory,
        address _priceFeed,
        uint _factoryRNG,
        uint _jackpotFee,
        uint _withdrawFee,
        uint _jackpotPercentage,
        address _poolAddressProvider) {
              
        require(_factoryRNG == 1 || _factoryRNG == 2);
        require(_jackpotFee > 0 && _jackpotFee < 100);
        require(_withdrawFee > 0 && _withdrawFee < 100);
        require(_jackpotPercentage > 0 && _jackpotPercentage < 100);
        require(_cycleLotteryFactory > 0);
        require(_priceFeed != EMPTY_ADDRESS_FACTORY);
        require(_developer != EMPTY_ADDRESS_FACTORY);
        require(_poolAddressProvider != EMPTY_ADDRESS_FACTORY);

        factoryOwner = msg.sender;
        factoryDeveloper = _developer;
        cycleLotteryFactory = _cycleLotteryFactory;
        factoryPriceFeed = _priceFeed;
        factoryRNGgenerator = _factoryRNG;
        developerFeeJackpot = _jackpotFee;
        developerFeeWithdraw = _withdrawFee;
        jackpotPercentage = _jackpotPercentage;
        poolAddressProvider = _poolAddressProvider;
    }    
   

    // Changes the factory developer address

    function changeDeveloper(address _newDeveloper) external {
        
        require(_newDeveloper != EMPTY_ADDRESS_FACTORY && msg.sender == factoryDeveloper);
        address oldDeveloper = factoryDeveloper;
        factoryDeveloper = _newDeveloper;
    
        emit ChangeFactoryDeveloper(oldDeveloper, factoryDeveloper);
    }


    // Changes the factory owner address

    function changeOwner(address _newOwner) external {
        
        require(_newOwner != EMPTY_ADDRESS_FACTORY && msg.sender == factoryOwner);
        address oldOwner = factoryOwner;
        factoryOwner = _newOwner;
    
        emit ChangeFactoryOwner(oldOwner, factoryOwner);
    }


    // Changes the factory lottery cycle

    function changeCycleLottery(uint _newCycle) external {
        
        require(_newCycle > 0 && msg.sender == factoryOwner);
        uint oldCycle = cycleLotteryFactory;
        cycleLotteryFactory = _newCycle;
    
        emit ChangeCycleLotteryFactory(oldCycle, cycleLotteryFactory);
    }


    // Changes address Chainlink Price Feed

    function changePriceFeed(address _newPriceFeed) external {
        
        require(_newPriceFeed != EMPTY_ADDRESS_FACTORY && msg.sender == factoryOwner);
        address oldPriceFeed = factoryPriceFeed;
        factoryPriceFeed = _newPriceFeed;
    
        emit ChangePriceFeedFactory(oldPriceFeed, factoryPriceFeed);
    }


    // Changes the RNG generator method
    // 1 = CHAINLINK PRICE FEED
    // 2 = FUTURE BLOCKHASH

    function changeRNGgenerator() external {
        
        require(msg.sender == factoryOwner);
        
        if (factoryRNGgenerator == 1) {
            factoryRNGgenerator = 2;
        }
        
        if (factoryRNGgenerator == 2) {
            factoryRNGgenerator = 1;
        }

        emit ChangeRNGgeneratorFactory(factoryRNGgenerator);
    }


    // Locks and unlocks the factory 
    // false = unlocked
    // true = locked
    

    function changeLockFactory() external {
        
        require(msg.sender == factoryOwner);
        
        if (lockFactory) {
            lockFactory = false;
        }
        
        if (!lockFactory) {
            lockFactory = true;
        }
        
        emit ChangeFactoryLock(lockFactory);
    }


    // Changes Percentages for new pools
    //1= Developer Jackpot Feed
    //2= Developer Withdraw Feed
    //3= Lottery Percentage

    function changePoolPercentages(uint _newFee, uint _type) external {
        
        require(msg.sender == factoryOwner);
        require(_type == 1 || _type == 2 || _type == 3);
        require(_newFee > 0 && _newFee < 100);

        uint oldFee;
        
        if (_type == 1) {
            oldFee = developerFeeJackpot;
            developerFeeJackpot = _newFee;
        }

        if (_type == 2) {
            oldFee = developerFeeWithdraw;
            developerFeeWithdraw = _newFee;
        }

        if (_type == 3) {
            oldFee = jackpotPercentage;
            jackpotPercentage = _newFee;
        }

        emit ChangePercentages(oldFee, _newFee, _type);
    }


    // Update underlying tokens authorized to use
    // 1 = Authorized
    // 2 = Not Authorized

    function updateMoneyMarkets(address _market, uint _state) external {    
        
        require(msg.sender == factoryOwner);
        require(_market != EMPTY_ADDRESS_FACTORY);
        require(_state == 1 || _state == 2); 

        moneyMarkets[_market] = _state;

        emit ChangeMoneyMarkets(_market, _state);
    }    


    // Creates a new pool
    // _underlying = Money Market Address

    function newCryptoPatronPool(address _underlying) external {
        
        require(!lockFactory);
        require(_underlying != EMPTY_ADDRESS_FACTORY);
        require(moneyMarkets[_underlying] == 1);
        
        counterPools++;

        CryptoPatronPool newPool = new CryptoPatronPool(
            msg.sender,
            _underlying,
            poolAddressProvider,
            factoryDeveloper,
            cycleLotteryFactory,
            factoryPriceFeed,
            factoryRNGgenerator,
            developerFeeJackpot,
            developerFeeWithdraw,
            jackpotPercentage);
          
       
        ownerPools[msg.sender].push(Pool(address(newPool), _underlying));
        mapPools[address(newPool)] = Pool(address(newPool), _underlying);
        
        factoryPools.push(Pool(address(newPool), _underlying));
        
        emit ChildCreated(address(newPool), _underlying, msg.sender);
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