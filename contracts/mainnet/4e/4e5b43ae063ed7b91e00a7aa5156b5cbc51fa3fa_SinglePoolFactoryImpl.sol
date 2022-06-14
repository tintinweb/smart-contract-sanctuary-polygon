/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract SinglePoolFactoryStorage {

    // ======== Construction & Init ========
    address public owner;  
    address public nextOwner; 

    address public operator;

    address payable public singlePoolImpl;
    address payable public plusPoolFactory;
    address public interestRateModel;

    // ======== Mining Info ========
    address public governance;
    address public mesh;
    address public WETH;
    uint public totalMined;
    uint public lastMined;
    uint public mining;
    uint internal reserveFactorMax;

    // ======== Pool Info ========
    address[] public singlePools;
    mapping(address => address) public singlePoolVault;
    mapping(address => bool) public singlePoolExist;

    bool public entered;
    
    address public nativeWithdrawer;
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

interface ISinglePoolFactory {
    function singlePoolImpl() external view returns (address);
}

contract SinglePool {

    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    event OwnerChanged(address previousOwner, address newOwner);
    event Upgraded(address implementation);

    modifier onlyOwner {
        require(msg.sender == _owner());
        _;
    }
    
    constructor(address _owner, bytes memory _data) public {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setOwner(_owner);
        
        address impl = ISinglePoolFactory(msg.sender).singlePoolImpl();
        if (_data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success,) = impl.delegatecall(_data);
            require(success);
        }
    }


    function Owner() external view onlyOwner returns (address) {
        return _owner();
    }

    function _owner() internal view returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    function _setOwner(address newOwner) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newOwner)
        }
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Proxy: new Owner is the zero address");
        emit OwnerChanged(_owner(), newOwner);
        _setOwner(newOwner);
    }

    function () payable external { 
        address impl = ISinglePoolFactory(_owner()).singlePoolImpl();
        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IGovernance {
    function getEpochMining(address) external view returns(uint, uint, uint[] memory, uint[] memory);
    function acceptEpoch() external;
    function sendReward(address, uint) external;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface ISinglePool {
    function initPool() external;
    function mining() external view returns (uint);
    function changeMiningRate(uint) external;
    function setReserveFactor(uint newReserveFactor) external; 
    function reduceReserves(address admin, uint reduceAmount) external;
    function setInterestRateModel(address newInterestRateModel) external;

    function repayETH(address user, address plusPoolAddress) external payable returns (uint);
    function repayToken(address user, uint repayAmount, address plusPoolAddress, address spender) external returns (uint);
    function borrow(address user, uint borrowAmount, address plusPoolAddress) external returns (uint, uint);
    function borrowBalanceStored(address account, address poolAddress) external view returns (uint);
    function borrowBalanceCurrent(address account, address poolAddress) external returns (uint);
    function borrowBalanceInfo(address account, address poolAddress) external view returns (uint, uint);
    function transferDebt(address user, address plusPoolAddress, address insurance) external ;

    function setDepositActive(bool b) external;
    function setWithdrawActive(bool b) external;
}

interface IConstructor {
    function mesh() external view returns (address);
    function mined() external view returns (uint);
}

interface IMESH {
    function mined() external view returns (uint);
}

interface IPlusPoolFactory {
    function getPoolExist(address poolAddress) external view returns (bool);
    function fundAddress() external view returns (address);
    function WETH() external view returns (address);
}

contract Initializable {

    bool private initialized;
    bool private initializing;

    modifier initializer() {
        require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    function isConstructor() private view returns (bool) {
        address self = address(this);
        uint256 cs;
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

contract SinglePoolFactoryImpl is Initializable, SinglePoolFactoryStorage {

    using SafeMath for uint;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyOperator {
        require(msg.sender == owner || msg.sender == operator);
        _;
    }
    
    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }


    function __SinglePoolFactory_init(
        address _owner,
        address _governance, 
        address payable _singlePoolImpl, 
        address _interestRateModel
    ) public initializer {
        __SinglePoolFactory_init_unchained(_owner, _governance, _singlePoolImpl, _interestRateModel);
    }

    function __SinglePoolFactory_init_unchained(
        address _owner,
        address _governance, 
        address payable _singlePoolImpl, 
        address _interestRateModel
    ) internal initializer {
        owner = _owner;
        governance = _governance;
        if (governance != address(0)){
            mesh = IConstructor(governance).mesh();
            lastMined = IConstructor(mesh).mined();
        }
        singlePoolImpl = _singlePoolImpl;
        interestRateModel = _interestRateModel;

        reserveFactorMax = 1e18;
    }

    function setSinglePoolImpl(address payable newSinglePoolImpl) public onlyOwner {
        require(singlePoolImpl != newSinglePoolImpl);
        singlePoolImpl = newSinglePoolImpl;
    }

    function version() public pure returns (string memory) {
        return "SinglePoolFactoryImpl20220526";
    }

    // ======== Administration ========

    event ChangeNextOwner(address nextOwner);
    event ChangeOwner(address owner);

    function changeNextOwner(address _nextOwner) public {
        require(msg.sender == owner);
        nextOwner = _nextOwner;

        emit ChangeNextOwner(_nextOwner);
    }

    function changeOwner() public {
        require(msg.sender == nextOwner);
        owner = nextOwner;
        nextOwner = address(0);

        emit ChangeOwner(owner);
    }

    function setPlusPoolFactory(address payable newPlusPoolFactory) public onlyOwner {
        require(plusPoolFactory != newPlusPoolFactory);
        plusPoolFactory = newPlusPoolFactory;
        WETH = IPlusPoolFactory(newPlusPoolFactory).WETH();
    }

    function getPlusPoolFactory() public view returns (address) {
        return plusPoolFactory;
    }

    event ChangeOperator(address newOperator);
    
    function changeOperator(address newOperator) public onlyOperator {
        require(operator != newOperator);
        operator = newOperator;

        emit ChangeOperator(newOperator);
    }
    
    event ChangeInterestRateModel(address newInterestRateModel);

    function changeInterestRateModel(address newInterestRateModel) public onlyOwner {
        require(interestRateModel != newInterestRateModel);
        interestRateModel = newInterestRateModel;

        emit ChangeInterestRateModel(newInterestRateModel);
    }

    event ChangeNativeWithdrawer(address newNativeWithdrawer);

    function changeNativeWithdrawer(address newNativeWithdrawer) public onlyOwner {
        require(nativeWithdrawer != newNativeWithdrawer);
        nativeWithdrawer = newNativeWithdrawer;

        emit ChangeNativeWithdrawer(newNativeWithdrawer);
    }

    // ======== for management ========

    event CreatePool(address token, address pool, uint exid);

    function createPool(address token) public onlyOwner {
        require(singlePoolVault[token] == address(0));
  
        SinglePool pool = new SinglePool(address(this), 
        abi.encodeWithSignature("__SinglePool_init(address,address,address)", 
            address(this), token, interestRateModel));
        
        singlePoolVault[token] = address(pool);
        singlePoolExist[address(pool)] = true;
        ISinglePool(address(pool)).initPool();
        singlePools.push(address(pool));

        emit CreatePool(token, address(pool), singlePools.length - 1);
       
    }

    function getPoolCount() public view returns (uint) {
        return singlePools.length;
    }

    function getPoolAddressByIndex(uint idx) public view returns (address) {
        require(idx < singlePools.length);
        return singlePools[idx];
    }

    function getPoolAddressByToken(address token) public view returns (address) {
        return singlePoolVault[token];
    }

    event SetDepositActive(address poolAddress, bool b);
    event SetWithdrawActive(address poolAddress, bool b);

    function setDepositActive(address tokenAddress, bool b) public onlyOperator {
        address singlePool = singlePoolVault[tokenAddress];
        require(singlePool != address(0));
        
        ISinglePool(singlePool).setDepositActive(b);

        emit SetDepositActive(singlePool, b);
    }

    function setWithdrawActive(address tokenAddress, bool b) public onlyOperator {
        address singlePool = singlePoolVault[tokenAddress];
        require(singlePool != address(0));

        ISinglePool(singlePool).setWithdrawActive(b);
        
        emit SetWithdrawActive(singlePool, b);
    }

    event SetPoolInterestRateModel(address pool, address newInterestRateModel);

    function setPoolInterestRateModel(address tokenAddress, address newInterestRateModel) public onlyOwner {
        address singlePool = singlePoolVault[tokenAddress];
        require(singlePool != address(0));

        ISinglePool(singlePool).setInterestRateModel(newInterestRateModel);

        emit SetPoolInterestRateModel(singlePool, newInterestRateModel);
    }

    // ======== Admin functions ========

    function setPoolReserveFactor(address token, uint newReserveFactor) public onlyOwner {
        require(singlePoolVault[token] != address(0));
        ISinglePool(singlePoolVault[token]).setReserveFactor(newReserveFactor);
    }
    
    function reducePoolReserves(address admin, address token, uint reduceAmount) public onlyOwner {
        require(singlePoolVault[token] != address(0));
        ISinglePool(singlePoolVault[token]).reduceReserves(admin, reduceAmount);
    }

    // ======== functions for PlusPoolFactory ========

    function borrow(address token, address user, uint amount) external returns (uint, uint) {
        require(IPlusPoolFactory(plusPoolFactory).getPoolExist(msg.sender));
        return ISinglePool(singlePoolVault[token]).borrow(user, amount, msg.sender);
    }

    function repay(address token, address user, uint amount) external payable returns (uint) {
        require(IPlusPoolFactory(plusPoolFactory).getPoolExist(msg.sender));
        
        return ISinglePool(singlePoolVault[token]).repayToken(user, amount, msg.sender, msg.sender);
    }

    function transferDebt(address token, address user, address insurance) external {
        require(IPlusPoolFactory(plusPoolFactory).getPoolExist(msg.sender));
        
        ISinglePool(singlePoolVault[token]).transferDebt(user, msg.sender, insurance);
    }

    function repayInsurance(address token, address plusPoolAddress, uint amount) external payable returns (uint) {
        address insurance = IPlusPoolFactory(plusPoolFactory).fundAddress();
        require(msg.sender == insurance);
        require(IPlusPoolFactory(plusPoolFactory).getPoolExist(plusPoolAddress));

        return ISinglePool(singlePoolVault[token]).repayToken(insurance, amount, plusPoolAddress, insurance);
    }

    function borrowBalanceStored(address token, address user, address poolAddress) public view returns (uint) {
        require(singlePoolVault[token] != address(0));
        
        return ISinglePool(singlePoolVault[token]).borrowBalanceStored(user, poolAddress);
    }

    function borrowBalanceCurrent(address token, address user, address poolAddress) public returns (uint) {
        require(singlePoolVault[token] != address(0));

        return ISinglePool(singlePoolVault[token]).borrowBalanceCurrent(user, poolAddress);
    }

     function borrowBalanceInfo(address token, address user, address poolAddress) public view returns (uint, uint) {
        require(singlePoolVault[token] != address(0));

        return ISinglePool(singlePoolVault[token]).borrowBalanceInfo(user, poolAddress);
    }

    // ======== Mining Rate ========

    function changeMiningRate(address[] memory pools, uint[] memory rate) public onlyOwner {
        uint n = pools.length;
        require(rate.length == n);

        address pool;
        uint i = 0;
        uint j = 0;
        uint rateSum = 0;
        for (i = 0; i < n; i++) {
            pool = pools[i];
            require(rate[i] != 0);
            require(singlePoolExist[pool]);

            for (j = 0; j < i; j++) {
                require(pools[j] != pool);
            }

            rateSum = rateSum.add(rate[i]);
        }
        require(rateSum == 10000);

        bool exist = false;
        uint poolCount = singlePools.length;
        
        for (i = 0; i < poolCount; i++) {
            pool = singlePools[i];
            if (ISinglePool(pool).mining() == 0) continue;

            exist = false;
            for (j = 0; j < n; j++) {
                if (pools[j] == pool) {
                    exist = true;
                    break;
                }
            }

            if (!exist) {
                ISinglePool(pool).changeMiningRate(0);
            }
        }

        for (i = 0; i < n; i++) {
            if (ISinglePool(pools[i]).mining() != rate[i]) {
                ISinglePool(pools[i]).changeMiningRate(rate[i]);
            }
        }
    }

    event ChangeMiningRate(uint _mining);
    event UpdateLastMined(uint _lastMined, uint _totalMined);

    function updateEpochMining() internal {
        (uint curEpoch, uint prevEpoch, uint[] memory rates, uint[] memory mined) = IGovernance(governance).getEpochMining(address(1));
        if(curEpoch == prevEpoch) return;

        uint epoch = curEpoch.sub(prevEpoch);
        require(rates.length == epoch);
        require(rates.length == mined.length);

        uint thisMined;
        for(uint i = 0; i < epoch; i++){
            thisMined = mining.mul(mined[i].sub(lastMined)).div(10000);

            require(rates[i] <= 10000);
            mining = rates[i];
            lastMined = mined[i];

            if(thisMined != 0){
                IGovernance(governance).sendReward(address(this), thisMined);
                totalMined = totalMined.add(thisMined);
            }

            emit ChangeMiningRate(mining);
            emit UpdateLastMined(lastMined, totalMined);
        }

        IGovernance(governance).acceptEpoch();
    }

    function updateTotalMined() public {
        updateEpochMining();

        uint mined = IMESH(mesh).mined();
        if(mined > lastMined){
            uint thisMined = mining.mul(mined.sub(lastMined)).div(10000);
            lastMined = mined;
            if(thisMined != 0){
                IGovernance(governance).sendReward(address(this), thisMined);
                totalMined = totalMined.add(thisMined);
            }

            emit UpdateLastMined(lastMined, totalMined);
        }
    }

    function getTotalMined() public view returns (uint) {
        uint curTotalMined = totalMined;
        uint curMining = mining;
        uint curLastMined = lastMined;

        uint thisMined;
        (uint curEpoch, uint prevEpoch, uint[] memory rates, uint[] memory mined) = IGovernance(governance).getEpochMining(address(1));
        if (curEpoch != prevEpoch) {
            uint epoch = curEpoch.sub(prevEpoch);
            require(rates.length == epoch);
            require(rates.length == mined.length);

            for (uint i = 0; i < epoch; i++) {
                thisMined = curMining.mul(mined[i].sub(curLastMined)).div(10000);

                require(rates[i] <= 10000);
                curMining = rates[i];
                curLastMined = mined[i];
                curTotalMined = curTotalMined.add(thisMined);
            }
        }

        uint curMined = IMESH(mesh).mined();
        if (curMined > curLastMined) {
            thisMined = curMining.mul(curMined.sub(curLastMined)).div(10000);
            curTotalMined = curTotalMined.add(thisMined);
        }

        return curTotalMined;
    }

    function sendReward(address user, uint amount) public {
        require(singlePoolExist[msg.sender]);
        updateTotalMined();

        IERC20 MESH = IERC20(mesh);
        require(amount <= MESH.balanceOf(address(this)));
        require(MESH.transfer(user, amount));
    }

    function() payable external { revert(); }
}