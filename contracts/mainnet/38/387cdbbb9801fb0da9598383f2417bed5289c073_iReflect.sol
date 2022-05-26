//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Incubator.sol";

contract iReflect is IERC20, Auth {
    using SafeMath for uint256;
    using Address for address;

    IERC20 WETH;
    IERC20 REWARDS;

    Incubator incubator;
    address public incubatorEOA;

    address payable public operator;
    address payable public marketing;

    string constant _name = "iReflect";
    string constant _symbol = "iReflect";

    uint256 _totalSupply = 1_024 * (10 ** _decimals);
    uint256 incubatorGas = 500000;
    uint8 constant _decimals = 9;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    event StartStacking(address indexed staker, uint256 indexed pool, uint256 amount);
    event Unstacked(address indexed staker, uint256 indexed pool, uint256 amount);
    event CreatedReflectionsPool(IERC20 _stakingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _genesisBlock);
    event ClaimedReflections(address indexed stacker, uint256 indexed pool);

    constructor () Auth(payable(msg.sender)) {

        incubator = new Incubator();
        incubatorEOA = address(incubator);

        operator = payable(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        marketing = payable(0x972c56de17466958891BeDE00Fe68d24eAb8c2C4);

        authorize(msg.sender);
        authorize(address(operator));
        authorize(address(marketing));

        _balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function close() public {
        selfdestruct(payable(owner)); 
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != _totalSupply){
            require(_allowances[sender][msg.sender] >= amount, "Request exceeds sender token allowance.");
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 senderTokenBalance = IERC20(address(this)).balanceOf(address(sender));
        require(amount <= senderTokenBalance, "Request exceeds sender token balance.");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Withdraw tokens from ReflectionsPool.
    function leaveStacking(uint256 _amount, uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.leaveStacking(_amount, _pool, payable(foundling));

        emit Unstacked(msg.sender, _amount, _pool);
    }
    

    // Reflection Tracker
    // add user amount staked
    // update stakingBalance / amount 
    // update pastReward to initial stake block
    // Stake tokens to ReflectionsPool
    function enterStacking(uint256 _amount,uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.enterStacking(_amount, _pool, payable(foundling));
        
        emit StartStacking(msg.sender, _amount, _pool);
    }

    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint _precision) public authorized {
        require(address(operator) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        incubator.createReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _minPeriod, _minDist, _genesisBlock, _precision);
        
        emit CreatedReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _genesisBlock);
    }
    
    // Stake tokens to ReflectionsPool
    function claimReflections(uint256 _pool, address payable foundling) public {
        require(address(foundling) == address(msg.sender), "UNAUTHORIZED: if you believe this is an error, contact operators");
        uint256 pending = incubator.pendingIReflect(_pool, payable(foundling), false);
        if(pending > 0){
            incubator.claimReflections(_pool, payable(foundling));
        }
        
        emit ClaimedReflections(address(foundling), _pool);
    }

    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable onlyOwner {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

    function rescueStuckNative(address payable recipient) public payable onlyOwner {
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
    }

    function changeIncubator() external onlyOwner {
        incubator = new Incubator();
        incubatorEOA = address(incubator);
    }

    function transferOwnership(address payable adr) public virtual override onlyOwner returns (bool) {
        address oldOwner = owner;
        owner = adr;
        authorizations[adr] = true;
        authorizations[oldOwner] = false;
        emit OwnershipTransferred(adr);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IDistro.sol";
contract Incubator is IDistro, Auth {
    using SafeMath for uint256;
    using Address for address;

    // Reflection Tracker
    // add user amount sireflectd
    // update stackingBalance / amount 
    // update pastReward to initial stack block
    // calculate reward based on 
    // example: 
    // 100,100 - 100,000           *       1               /    100         /       10      
    // (block.number - pastReward) * pool.blockReflections / (stackingSupply / stackingBalance)
    // after each claim update pastReward == block.number
    struct ReflectionInfo {
        uint256 pool;
        uint256 pastReward; 
        uint256 stackingBalance;
        uint256 reflectionsBalance;
        uint256 reflectionsExcluded;
    }

    // Pool Intel.
    struct PoolIntel {
        IERC20 stackingToken; 
        IERC20 reflectionsToken; 
        uint256 blockReflections; 
        uint256 stackingSupply;
        uint256 reflectionSupply;
        uint256 totalDistributed;
        uint minPeriod;
        uint256 minDistribution;
        uint genesisBlock;
        uint decimals;
    }

    struct Reflection {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 WETH;
    IERC20 REWARDS;
    IERC20 USDT = IERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IUniswapV2Router02 public router = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    address public ireflect;
    address public operator;
    address payable public _token;
    address payable[] foundlings;
    address payable[] reflections_tokens;

    uint256 public ireflectPerBlock;
    uint256 public REFLECTIONS_BASIS = 1;
    uint256 reflectionsBalance;
    uint256 poolCredits;
    uint256 reflectionsPeriod;
    uint256 reflectionsPool;
    uint256 userShare;
    uint256 reflectionsRewards;
    uint256 public reflectionsAccuracyFactor = 10 ** 18;
    uint256 _minimumDistribution;
    uint256 _minimumPeriod;
    uint256 currentIndex;
    uint public genesisBlock;
    uint public _blocksPerDay;

    bool initialized;

    PoolIntel[] public poolIntel;
    mapping (uint256 => mapping (address => ReflectionInfo)) public reflectionInfo;
    mapping (address => Reflection) public reflections;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => mapping (address => uint256)) _balances;

    event ReceivedETH(address, uint);
    event ReceivedETHFallback(address, uint);
    event CreateReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _genesisBlock);
    event StartStacking(address indexed stacker, uint256 indexed pool, uint256 amount);
    event Unstacked(address indexed stacker, uint256 indexed pool, uint256 amount);
    event ClaimedReflections(address indexed stacker, uint256 indexed pool, uint256 amount);
    
    modifier onlyToken() virtual {
        require(msg.sender == _token,"UNAUTHORIZED!"); _;
    }

    modifier onlyOwner() override {
        require(msg.sender == owner,"UNAUTHORIZED!"); _;
    }

    constructor () Auth(payable(msg.sender)) {
        initialized = true;
        genesisBlock = block.number;
        ireflectPerBlock = 1 * (10 ** 9);
        _minimumDistribution = 1 * (10 ** 9);
        _blocksPerDay = block.chainid == 1 ? 5400 : block.chainid == 56 ? 28800 : block.chainid == 137 ? 86400 : block.chainid == 103090 ? 28800 : 5400;
        _minimumPeriod = _blocksPerDay / 24;
        address deployer = address(0x972c56de17466958891BeDE00Fe68d24eAb8c2C4);
        _token = payable(msg.sender);
        ireflect = address(0xd88AD19E67238d8bC7a217913e8D8CcB983d8c30);
        operator = address(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        authorize(deployer);
        authorize(_token);
        authorize(operator);
        // initialize iReflect pool
        poolIntel.push(PoolIntel({
            stackingToken: IERC20(ireflect),
            reflectionsToken: IERC20(ireflect),
            blockReflections: ireflectPerBlock,
            stackingSupply: 0,
            reflectionSupply: 0,
            totalDistributed: 0,
            minPeriod: _minimumPeriod,
            minDistribution: _minimumDistribution,
            genesisBlock: genesisBlock,
            decimals: 1e9
        }));
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
    }

    fallback() external payable {
        emit ReceivedETHFallback(msg.sender, msg.value);
    }

    function getContractAddress() public view returns (address) {
        return address(this);
    }

    function getContractEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getPrecision(uint256 decimals, uint256 amount) public pure returns (uint256) {
        if(decimals==2||decimals==1e2){
            return amount * 1e2;
        } else if(decimals==3||decimals==1e3){
            return amount * 1e3;
        } else if(decimals==4||decimals==1e4){
            return amount * 1e4;
        } else if(decimals==5||decimals==1e5){
            return amount * 1e5;
        } else if(decimals==6||decimals==1e6){
            return amount * 1e6;
        } else if(decimals==7||decimals==1e7){
            return amount * 1e7;
        } else if(decimals==8||decimals==1e8){
            return amount * 1e8;
        } else if(decimals==9||decimals==1e9){
            return amount * 1e9;
        } else if(decimals==10||decimals==1e10){
            return amount * 1e10;
        } else if(decimals==11||decimals==1e11){
            return amount * 1e11;
        } else if(decimals==12||decimals==1e12){
            return amount * 1e12;
        } else if(decimals==13||decimals==1e13){
            return amount * 1e13;
        } else if(decimals==14||decimals==1e14){
            return amount * 1e14;
        } else if(decimals==15||decimals==1e15){
            return amount * 1e15;
        } else if(decimals==16||decimals==1e16){
            return amount * 1e16;
        } else if(decimals==17||decimals==1e17){
            return amount * 1e17;
        } else if(decimals==18||decimals==1e18){
            return amount * 1e18;
        } else {
            return amount * 1e18; 
        }
    }

    function close() public {
        selfdestruct(payable(owner)); 
    }
    
    function getPreciseRewards(uint256 _pool, uint256 amount) public view returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        if(pool.decimals==1e2||pool.decimals==2){
            return amount * 1e2;
        } else if(pool.decimals==1e3||pool.decimals==3){
            return amount * 1e3;
        } else if(pool.decimals==1e4||pool.decimals==4){
            return amount * 1e4;
        } else if(pool.decimals==1e5||pool.decimals==5){
            return amount * 1e5;
        } else if(pool.decimals==1e6||pool.decimals==6){
            return amount * 1e6;
        } else if(pool.decimals==1e7||pool.decimals==7){
            return amount * 1e7;
        } else if(pool.decimals==1e8||pool.decimals==8){
            return amount * 1e8;
        } else if(pool.decimals==1e9||pool.decimals==9){
            return amount * 1e9;
        } else if(pool.decimals==1e10||pool.decimals==10){
            return amount * 1e10;
        } else if(pool.decimals==1e11||pool.decimals==11){
            return amount * 1e11;
        } else if(pool.decimals==1e12||pool.decimals==12){
            return amount * 1e12;
        } else if(pool.decimals==1e13||pool.decimals==13){
            return amount * 1e13;
        } else if(pool.decimals==1e14||pool.decimals==14){
            return amount * 1e14;
        } else if(pool.decimals==1e15||pool.decimals==15){
            return amount * 1e15;
        } else if(pool.decimals==1e16||pool.decimals==16){
            return amount * 1e16;
        } else if(pool.decimals==1e17||pool.decimals==17){
            return amount * 1e17;
        } else if(pool.decimals==1e18||pool.decimals==18){
            return amount * 1e18;
        } else {
            return amount * 1e18; 
        }
    }

    function getContractTokenBalance(address _tok) public view returns (uint256) {
        return IERC20(address(_tok)).balanceOf(address(this));
    }

    function rescueStuckTokens(uint256 _pool, address payable recipient, uint256 amount, uint256 decimalUnits) public returns (bool){
        PoolIntel storage pool = poolIntel[_pool];
        IERC20 _tok = pool.stackingToken;
        require(_balances[payable(recipient)][address(_tok)] >= amount, "UNAUTHORIZED");
        require(address(msg.sender) == address(recipient), "UNAUTHORIZED");
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(recipient)];
        uint256 preciseAmount = getPrecision(decimalUnits, amount);
        uint256 ogContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        require(preciseAmount <= ogContractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        _balances[payable(recipient)][address(_tok)] = _balances[payable(recipient)][address(_tok)].sub(preciseAmount,"Amount exceeds balance! Contact operators.");
        IERC20(_tok).transfer(payable(recipient), preciseAmount);
        uint256 finalContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[payable(recipient)][address(_tok)];
        stacker.pastReward = block.number;
        return true;
    }
    
    function emergencyRescueStuckTokens(uint256 _pool, address payable recipient, uint256 amount, uint256 decimalUnits) public authorized returns (bool){
        require(msg.sender == operator, "UNAUTHORIZED");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(recipient)];
        IERC20 _tok = pool.stackingToken;
        uint256 ogContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 preciseAmount = getPrecision(decimalUnits, amount);
        require(preciseAmount <= ogContractTokenBalance, "Request exceeds contract token balance.");
        require(_balances[payable(recipient)][address(_tok)] >= amount, "UNAUTHORIZED");
        // rescue stuck tokens 
        _balances[payable(recipient)][address(_tok)] = _balances[payable(recipient)][address(_tok)].sub(preciseAmount,"Amount exceeds balance!");
        IERC20(_tok).transfer(recipient, preciseAmount);
        uint256 finalContractTokenBalance = IERC20(_tok).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[payable(recipient)][address(_tok)];
        stacker.pastReward = block.number;
        return true;
    }

    function rescueStuckNative(address payable recipient) public authorized returns (bool) {
        require(msg.sender == operator, "UNAUTHORIZED");
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(this).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
        return true;
    }

    function updateMultiplier(uint256 multiplierNumber) public override authorized {
        REFLECTIONS_BASIS = multiplierNumber;
    }

    function updateBlockReflections(uint256 _pool, uint256 reflectionsAmount) public override authorized {
        PoolIntel storage pool = poolIntel[_pool];
        uint256 pastReflectionsPoints = pool.blockReflections;
        uint256 preciseRewards = getPreciseRewards(_pool, reflectionsAmount);
        if (pastReflectionsPoints != preciseRewards) {
            pool.blockReflections = preciseRewards;
        }
    }
    
    function updateReflectionSupply(uint256 _pool, uint256 reflectionSupply) public authorized {
        PoolIntel storage pool = poolIntel[_pool];
        // to Ether
        uint256 ogContractTokenBalance = IERC20(address(pool.reflectionsToken)).balanceOf(address(this));
        uint256 preciseRewards = getPreciseRewards(_pool, reflectionSupply);
        IERC20(pool.reflectionsToken).transferFrom(msg.sender, address(this), preciseRewards);
        
        uint256 finalContractTokenBalance = IERC20(address(pool.reflectionsToken)).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.reflectionSupply += diff;
    }

    function poolLength() external view returns (uint256) {
        return poolIntel.length;
    }

    // Add new reflections pools. Can only be called by the owner.
    // DO NOT add the same reflections token more than once. 
    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint decimals) public override authorized {
        uint256 _decimals = decimals == 2 ? 1e2 : decimals == 3 ? 1e3 : decimals == 4 ? 1e4 : decimals == 5 ? 1e5 : decimals == 6 ? 1e6 : decimals == 7 ? 1e7 : decimals == 8 ? 1e8 : decimals == 9 ? 1e9 : decimals == 10 ? 1e10 : decimals == 11 ? 1e11 : decimals == 12 ? 1e12 : decimals == 13 ? 1e13 : decimals == 14 ? 1e14 : decimals == 15 ? 1e15 : decimals == 16 ? 1e16 : decimals == 17 ? 1e17 : decimals == 18 ? 1e18 : 1e18;
        uint256 preciseReward = getPrecision(decimals, _blockReflections);
        uint256 genesis = _genesisBlock < block.number ? block.number : _genesisBlock;
        poolIntel.push(PoolIntel({
            stackingToken: IERC20(_stackingToken),
            reflectionsToken: IERC20(_reflectionsToken),
            blockReflections: preciseReward,
            stackingSupply: 0,
            reflectionSupply: 0,
            totalDistributed: 0,
            minPeriod: _minPeriod,
            minDistribution: _minDist * _decimals,
            genesisBlock: genesis,
            decimals: _decimals
        }));
        emit CreateReflectionsPool(_stackingToken, _reflectionsToken, _blockReflections, _genesisBlock);
    }
    
    function removeStackingPool(uint256 _pool) internal {  
        PoolIntel storage pool = poolIntel[_pool];
        pool.blockReflections = 0;
    }
    
    // Update operator address 
    function updateOperationsWallet(address _operatorWallet) public authorized {
        require(msg.sender == operator, "DENIED: Must be current operator");
        operator = _operatorWallet;
        authorize(operator);
    }

    // set reflections period, and minimum claim amount
    function setReflectionCriteria(uint256 _pool, uint256 _minPeriod, uint256 _minDistribution) public override authorized {
        PoolIntel storage pool = poolIntel[_pool];
        pool.minPeriod = _minPeriod;
        pool.minDistribution = _minDistribution;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _pool, uint256 _from, uint256 _to, address payable sender) public view returns (uint256) {
        // PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(sender)];
        uint256 aob = (block.number - stacker.pastReward);
        uint256 ftb = _to.sub(_from);
        if(aob!=ftb){
            return _to.sub(_from).mul(REFLECTIONS_BASIS);
        } else {
            return aob.mul(REFLECTIONS_BASIS);
        }
    }

    // View function to see pending iReflect on frontend.
    function pendingIReflect(uint256 _pool, address payable _stacker, bool test) public view override returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(_stacker)];
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (block.number > stacker.pastReward && rb != 0) {
            uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 
            uint256 multiplier = getMultiplier(_pool, stacker.pastReward, block.number, payable(_stacker));
            uint256 ireflectReward = (multiplier * pool.blockReflections) / (pool.stackingSupply / stackerAmount);
            return ireflectReward;
        } else if (test==true) {
            uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 
            uint256 multiplier = getMultiplier(_pool, stacker.pastReward, block.number, payable(_stacker));
            uint256 ireflectReward = (multiplier * pool.blockReflections) / (pool.stackingSupply / stackerAmount);
            return getPreciseRewards(_pool, ireflectReward);
        } else {
            return 0;
        }
    }
    
    // View function to see stacked tokens on frontend.
    function stackingBalance(uint256 _pool, address payable _stacker) external view override returns (uint256) {
        PoolIntel storage pool = poolIntel[_pool];
        uint256 stackerAmount = _balances[address(_stacker)][address(pool.stackingToken)]; 

        return stackerAmount;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pool, address payable sender) public override {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(sender)];
        IERC20 _tok = pool.stackingToken;
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (rb == 0 || _balances[address(sender)][address(pool.stackingToken)] == 0) {
            stacker.pastReward = block.number;
            return;
        }        
        uint256 pending = pendingIReflect(_pool, payable(sender), false);
        if(pool.totalDistributed + pending >= pool.reflectionSupply){
            if(pool.totalDistributed < pool.reflectionSupply){             
                pending = pool.reflectionSupply - pool.totalDistributed;
                if(pending <= 0){
                    stacker.reflectionsBalance = 0;
                    // stacker.pastReward = block.number;
                    return;
                    // revert("Pool exhausted reflections supply; try another pool, or contact operators");
                }
            }
        }
        if(shouldDistribute(_pool, address(sender))) {
            if(pending > 0) {    
                uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(this));
                stacker.reflectionsBalance = stacker.reflectionsBalance.sub(pending, 'amount exceeds balance');
                if(pending >= contractTokenBalance){
                    IERC20(pool.reflectionsToken).transfer(payable(sender), contractTokenBalance);
                } else {
                    IERC20(pool.reflectionsToken).transfer(payable(sender), pending);
                }
                pool.totalDistributed = pool.totalDistributed.add(pending);
                stacker.pastReward = block.number;
            }
        }
    }

    // add user amount 
    // update stackingBalance / amount 
    // update pastReward to initial stack block
    // stack iReflect tokens
    function enterStacking(uint256 _amount, uint256 _pool, address payable _stacker) public override onlyToken {
        require(_amount > 0, "ERROR: stacking amount must be greater than 0");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][payable(_stacker)];
        uint256 preciseRewards = getPreciseRewards(_pool, _amount);
        updatePool(_pool, payable(_stacker));
        if (block.number <= (stacker.pastReward + pool.minPeriod)) {
            revert("Not enough blocks to claim reflections, keep stacking");
        }
        uint256 rb = pool.reflectionsToken.balanceOf(address(this));
        if (rb == 0) {
            revert("Reflections pool contains no balance. Contact operators");
        }
        if (_balances[payable(_stacker)][address(pool.stackingToken)] == 0) {
            stacker.pastReward = block.number;
        }
        uint256 ogContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        pool.stackingToken.transferFrom(payable(_stacker), address(this), preciseRewards);
        uint256 finalContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply += diff;
        _balances[payable(_stacker)][address(pool.stackingToken)] += preciseRewards;
        stacker.stackingBalance = _balances[payable(_stacker)][address(pool.stackingToken)];
        // pool.stackingSupply += preciseRewards;

        emit StartStacking(payable(_stacker), _pool, preciseRewards);
    }

    // Withdraw ireflect tokens from stacking.
    function leaveStacking(uint256 _amount, uint256 _pool, address payable _stacker) public override onlyToken {
        require(_amount > 0, "ERROR: requested amount must be greater than 0");
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][payable(_stacker)];
        uint256 stackingBal = _balances[payable(_stacker)][address(pool.stackingToken)];
        uint256 preciseRewards = getPreciseRewards(_pool, _amount);
        require(stackingBal > 0, "ERROR: stacking amount must be greater than 0 to claim reflections");
        require(stacker.stackingBalance >= preciseRewards, "DENIED: Expected larger balance, try a smaller amount.");
        updatePool(_pool, payable(_stacker));
        _balances[address(_stacker)][address(pool.stackingToken)] = _balances[address(_stacker)][address(pool.stackingToken)].sub(preciseRewards, 'amount exceeds balance');
        stacker.stackingBalance = _balances[payable(_stacker)][address(pool.stackingToken)];
        uint256 ogContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        pool.stackingToken.transfer(payable(_stacker), preciseRewards);
        uint256 finalContractTokenBalance = IERC20(pool.stackingToken).balanceOf(address(this));
        uint256 diff = finalContractTokenBalance - ogContractTokenBalance;
        pool.stackingSupply -= diff;
        stacker.stackingBalance -= _balances[address(_stacker)][address(pool.stackingToken)];
        stacker.pastReward = block.number;
        emit Unstacked(payable(_stacker), _pool, preciseRewards);
    }

    function shouldDistribute(uint256 _pool, address foundling) internal view returns (bool) {
        PoolIntel storage pool = poolIntel[_pool];
        ReflectionInfo storage stacker = reflectionInfo[_pool][address(foundling)];
        if(_balances[address(foundling)][address(pool.stackingToken)] < pool.minDistribution) {
            return false;
        } else if(pool.totalDistributed >= pool.reflectionSupply){
            return false;
        } else if (block.number <= (stacker.pastReward + pool.minPeriod)) {
            return false;
        } else {
            return true;
        }
    }

    // calculate reward based on 
    // ((block.number - pastReward) * pool.blockReflections) / (stackingSupply / stackingBalance)
    // after each claim update pastReward == block.number
    function distributeReflections(uint256 _pool, address payable foundling) internal {
        PoolIntel storage pool = poolIntel[_pool];
        // ReflectionInfo storage stacker = reflectionInfo[_pool][address(foundling)];
        uint256 stackingBal = _balances[address(foundling)][address(pool.stackingToken)];
        uint256 pending = pendingIReflect(_pool, payable(foundling), false);
        require(pending > 0, "ERROR: pending amount must be greater than 0");
        require(stackingBal > 0, "ERROR: stacking amount must be greater than 0 to exit");
        updatePool(_pool, payable(foundling));
        
        emit ClaimedReflections(payable(foundling), _pool, pending);
    }

    function claimReflections(uint256 _pool, address payable foundling) external override {
        distributeReflections(_pool,payable(foundling));
    }

    function changeTokenContract(address payable _newToken) public virtual onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        _token = payable(_newToken);
        return true;
    }

    function transferOwnership(address payable adr) public virtual override onlyOwner returns (bool) {
        require(msg.sender == owner, "UNAUTHORIZED");
        owner = payable(adr);
        emit OwnershipTransferred(adr);
        return true;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
interface IDistro {
    function setReflectionCriteria(uint256 _pool, uint256 _minPeriod, uint256 _minDistribution) external;
    function updatePool(uint256 _pool, address payable sender) external;
    function enterStacking(uint256 _amount, uint256 _pool, address payable _stacker) external;
    function leaveStacking(uint256 _amount, uint256 _pool, address payable _stacker) external;
    function pendingIReflect(uint256 _pool, address payable _stacker, bool test) external returns (uint256);
    function claimReflections(uint256 _pool, address payable foundling) external;
    function stackingBalance(uint256 _pool, address payable _stacker) external returns (uint256);
    function updateBlockReflections(uint256 _pool, uint256 reflectionsAmount) external;
    function updateMultiplier(uint256 multiplierNumber) external;
    function createReflectionsPool(IERC20 _stackingToken, IERC20 _reflectionsToken, uint256 _blockReflections, uint256 _minPeriod, uint256 _minDist, uint256 _genesisBlock, uint decimals) external;
    // function process(uint256 _pool, uint256 gas) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Address.sol";
abstract contract Auth {
    using Address for address;
    address public owner;
    address public _owner;
    mapping (address => bool) internal authorizations;

    constructor(address payable _maintainer) {
        _owner = payable(_maintainer);
        owner = payable(_owner);
        authorizations[_owner] = true;
        authorize(msg.sender);
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() virtual {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyZero() virtual {
        require(isOwner(address(0)), "!ZERO"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() virtual {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        if(account == owner || account == _owner){
            return true;
        } else {
            return false;
        }
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
    * @dev Leaves the contract without owner. It will not be possible to call
    * `onlyOwner` functions anymore. Can only be called by the current owner.
    *
    * NOTE: Renouncing ownership will leave the contract without an owner,
    * thereby removing any functionality that is only available to the owner.
    */
    function renounceOwnership() public virtual onlyOwner {
        require(isOwner(msg.sender), "Unauthorized!");
        emit OwnershipTransferred(address(0));
        unauthorize(owner);
        unauthorize(_owner);
        _owner = address(0);
        owner = _owner;
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public virtual onlyOwner returns (bool) {
        unauthorize(owner);
        unauthorize(_owner);
        _owner = payable(adr);
        owner = _owner;
        authorize(adr);
        emit OwnershipTransferred(adr);
        return true;
    }    
    
    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function takeOwnership() public virtual {
        require(isOwner(address(0)) || isAuthorized(msg.sender), "Unauthorized! Non-Zero address detected as this contract current owner. Contact this contract current owner to takeOwnership(). ");
        unauthorize(owner);
        unauthorize(_owner);
        _owner = payable(msg.sender);
        owner = _owner;
        authorize(msg.sender);
        emit OwnershipTransferred(msg.sender);
    }

    event OwnershipTransferred(address owner);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}