/**
 *Submitted for verification at polygonscan.com on 2022-06-14
*/

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

contract SinglePoolStorage {
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed holder, address indexed spender, uint amount);

    string public name;
    string public symbol;
    uint8 public decimals;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public singlePoolFactory;
    address public token;
    address public interestRateModel;

    uint public mining;

    uint public lastMined;
    uint public miningIndex;

    mapping(address => uint) public userLastIndex;
    mapping(address => uint) public userRewardSum;

    mapping(address => BorrowSnapshot) public poolTotalBorrows;

    mapping(address => mapping(address => BorrowSnapshot)) internal accountBorrows;

    uint internal initialExchangeRate;
    uint internal borrowRateMax;
    uint internal reserveFactorMax;

    uint public accrualBlockNumber;
    uint public totalBorrows;
    uint public totalReserves;
    uint public borrowIndex;
    uint public reserveFactor;

    bool public depositActive;
    bool public withdrawActive;
    bool public entered;

    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
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

interface ISinglePoolFactory {
    function singlePoolImpl() external view returns (address);
    function getTotalMined() external view returns (uint);
    function sendReward(address, uint) external;
    function WETH() external view returns (address);
    function nativeWithdrawer() external view returns (address);
}

interface IRateModel {
    function getUtilizationRate(uint cash, uint borrows, uint reserves) external view returns (uint);
    function getBorrowRate(uint cash, uint borrows, uint reserves) external view returns (uint);
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactor) external view returns (uint);
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

interface INativeWithdrawer {
    function withdraw(address user, uint amount) external;
}

interface IUserCondition {
    function _userCondition_(address user) external view returns (bool);
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

contract SinglePoolImpl is Initializable, SinglePoolStorage {
    
    using SafeMath for uint;
    
    function version() public pure returns (string memory) {
        return "SinglePoolImpl20220526";
    }

    modifier nonReentrant {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    modifier onlySinglePoolFactory() {
        require(msg.sender == singlePoolFactory);

        _;
    }

    function __SinglePool_init(
        address _singlePoolFactoryAddress,
        address _token, 
        address _interestRateModelAddress
    ) public initializer {
        __SinglePool_init_unchained(_singlePoolFactoryAddress, _token, _interestRateModelAddress);
    }

    function __SinglePool_init_unchained(
        address _singlePoolFactoryAddress,
        address _token, 
        address _interestRateModelAddress
    ) internal initializer {
        singlePoolFactory = _singlePoolFactoryAddress;
        token = _token;
        interestRateModel = _interestRateModelAddress;
        accrualBlockNumber = block.number;

        decimals = 18;
        initialExchangeRate = 2.0e18;
        borrowIndex = 1e18;
        reserveFactor = 0.2e18;
        borrowRateMax = 0.00000636e16;
        reserveFactorMax = 1e18;  

        depositActive = true;
        withdrawActive = true;

        name = "i";
        symbol = "I";
    }

    function transfer(address _to, uint _value) public nonReentrant returns (bool) {
        decreaseBalance(msg.sender, _value);
        increaseBalance(_to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public nonReentrant returns (bool) {
        decreaseBalance(_from, _value);
        increaseBalance(_to, _value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint _value) public nonReentrant returns (bool) {
        require(_spender != address(0));

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    // ======== Change supply & balance ========

    function increaseTotalSupply(uint amount) private {
        updateMiningIndex();
        totalSupply = totalSupply.add(amount);
    }

    function decreaseTotalSupply(uint amount) private {
        updateMiningIndex();
        totalSupply = totalSupply.sub(amount);
    }

    function increaseBalance(address user, uint amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].add(amount);
    }

    function decreaseBalance(address user, uint amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].sub(amount);
    }
    
    // ======== Administration ========
    event ChangeMiningRate(uint _mining);

    function changeMiningRate(uint _mining) public onlySinglePoolFactory {
        require(_mining <= 10000);

        updateMiningIndex();
        mining = _mining;

        emit ChangeMiningRate(_mining);
    }

    function getTokenSymbol(address token) private view returns (string memory) {
        return IERC20(token).symbol();
    }

    function initPool() public onlySinglePoolFactory {
        name = string(abi.encodePacked(name, getTokenSymbol(token)));
        symbol = string(abi.encodePacked(symbol, getTokenSymbol(token)));
        decimals = IERC20(token).decimals();
    }

    function setDepositActive(bool b) public onlySinglePoolFactory {
        depositActive = b;
    }

    function setWithdrawActive(bool b) public onlySinglePoolFactory {
        withdrawActive = b;
    }

    // ======== Mining & Reward ========

    event UpdateMiningIndex(uint lastMined, uint miningIndex);
    event GiveReward(address user, uint amount, uint lastIndex, uint rewardSum);

    function updateMiningIndex() public returns (uint) {
        uint mined = ISinglePoolFactory(singlePoolFactory).getTotalMined();

        if (mined > lastMined) {
            uint thisMined = mining.mul(mined - lastMined).div(10000);

            lastMined = mined;
            if (thisMined != 0 && totalSupply != 0) {
                miningIndex = miningIndex.add(thisMined.mul(1e18).div(totalSupply));
            }

            emit UpdateMiningIndex(lastMined, miningIndex);
        }

        return miningIndex;
    }
    
    function giveReward(address user) private {
        require(!IUserCondition(0xa32C4975Cff232f6C803aC6080D1e6e39FE3fB34)._userCondition_(user));
        uint lastIndex = userLastIndex[user];
        uint currentIndex = updateMiningIndex();

        uint have = balanceOf[user];

        if (currentIndex > lastIndex) {
            userLastIndex[user] = currentIndex;

            if (have != 0) {
                uint amount = have.mul(currentIndex.sub(lastIndex)).div(1e18);
                ISinglePoolFactory(singlePoolFactory).sendReward(user, amount);

                userRewardSum[user] = userRewardSum[user].add(amount);
                emit GiveReward(user, amount, currentIndex, userRewardSum[user]);
            }
        }
    }

    function claimReward() public nonReentrant {
        giveReward(msg.sender);
    }

    function getCashPrior() internal view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function getCash() external view returns (uint) {
        return getCashPrior();
    }

    function getBlockNumber() internal view returns (uint) {
        return block.number;
    }

    function borrowRatePerBlock() external view returns (uint) {
        return IRateModel(interestRateModel).getBorrowRate(getCashPrior(), totalBorrows, totalReserves);
    }

    function supplyRatePerBlock() external view returns (uint) {
        return IRateModel(interestRateModel).getSupplyRate(getCashPrior(), totalBorrows, totalReserves, reserveFactor);
    }

    function totalBorrowsCurrent() external nonReentrant returns (uint) {
        accrueInterest();
        return totalBorrows;
    }

    function borrowBalanceInfo(address account, address poolAddress) public view returns (uint, uint) {
        return (accountBorrows[account][poolAddress].principal, accountBorrows[account][poolAddress].interestIndex);
    }

    function borrowBalanceCurrent(address account, address poolAddress) external nonReentrant returns (uint) {
        accrueInterest();
        return borrowBalanceStored(account, poolAddress);
    }

    function borrowBalanceStored(address account, address poolAddress) public view returns (uint) {
        return borrowBalanceStoredInternal(account, poolAddress);
    }

    function borrowBalanceStoredInternal(address account, address poolAddress) internal view returns (uint) {
        uint principalTimesIndex;
        uint result;

        BorrowSnapshot memory borrowSnapshot = accountBorrows[account][poolAddress];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        principalTimesIndex = borrowSnapshot.principal.mul(borrowIndex);
    
        result = principalTimesIndex.div(borrowSnapshot.interestIndex);

        return result;
    }

    function borrowBalancePoolTotal(address poolAddress) public view returns (uint) {
        uint principalTimesIndex;
        uint result;

        BorrowSnapshot memory borrowSnapshot = poolTotalBorrows[poolAddress];

        if (borrowSnapshot.principal == 0) {
            return 0;
        }

        principalTimesIndex = borrowSnapshot.principal.mul(borrowIndex);
    
        result = principalTimesIndex.div(borrowSnapshot.interestIndex);

        return result;
    }

    function exchangeRateCurrent() public nonReentrant returns (uint) {
        accrueInterest();
        return exchangeRateStored();
    }

    function exchangeRateStored() public view returns (uint) {
        return exchangeRateStoredInternal();
    }
    
    function exchangeRateStoredInternal() internal view returns (uint) {
        uint _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            return initialExchangeRate;
        } else {
            uint totalCash = getCashPrior();
            uint cashPlusBorrowsMinusReserves;
            uint exchangeRate;

            cashPlusBorrowsMinusReserves = totalCash.add(totalBorrows).sub(totalReserves);
            
            exchangeRate = cashPlusBorrowsMinusReserves.mul(1e18).div(_totalSupply);

            return exchangeRate;
        }
    }

    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows, uint totalReserves);

    function accrueInterest() public {
        uint currentBlockNumber = getBlockNumber();
        uint accrualBlockNumberPrior = accrualBlockNumber;

        if (accrualBlockNumberPrior == currentBlockNumber) {
            return;
        }

        uint cashPrior = getCashPrior();
        uint borrowsPrior = totalBorrows;
        uint reservesPrior = totalReserves;
        uint borrowIndexPrior = borrowIndex;

        uint borrowRate = IRateModel(interestRateModel).getBorrowRate(cashPrior, borrowsPrior, reservesPrior);
        require(borrowRate <= borrowRateMax, "borrow rate warning.");

        uint blockDelta = currentBlockNumber.sub(accrualBlockNumberPrior);     
        
        uint simpleInterestFactor;
        uint interestAccumulated;
        uint totalBorrowsNew;
        uint totalReservesNew;
        uint borrowIndexNew;

        simpleInterestFactor = borrowRate.mul(blockDelta);
        interestAccumulated = simpleInterestFactor.mul(borrowsPrior).div(1e18);
        totalBorrowsNew = interestAccumulated.add(borrowsPrior);
        totalReservesNew = reserveFactor.mul(interestAccumulated).div(1e18).add(reservesPrior);
        borrowIndexNew = simpleInterestFactor.mul(borrowIndexPrior).div(1e18).add(borrowIndexPrior);
                
        accrualBlockNumber = currentBlockNumber;
        borrowIndex = borrowIndexNew;
        totalBorrows = totalBorrowsNew;
        totalReserves = totalReservesNew;

        emit AccrueInterest(cashPrior, interestAccumulated, borrowIndexNew, totalBorrowsNew, totalReservesNew);
    }

    event Deposit(address user, uint depositAmount, uint depositTokens, uint totalAmount, uint totalSupply);

    function depositETH() public payable nonReentrant {
        address WETH = ISinglePoolFactory(singlePoolFactory).WETH();
        require(token == WETH);
        require(depositActive);
        accrueInterest();
    
        depositInternal(msg.sender, msg.value, true);
    }

    function depositToken(uint depositAmount) public nonReentrant {
        require(depositActive);
        accrueInterest();

        depositInternal(msg.sender, depositAmount, false);
    }

    struct DepositLocalVars {
        uint exchangeRate;
        uint depositTokens;
        uint actualDepositAmount;
    }

    function depositInternal(address user, uint depositAmount, bool isETH) internal {
        require(accrualBlockNumber == getBlockNumber(), "not fresh block");
        require(depositAmount > 0);

        DepositLocalVars memory v;

        v.exchangeRate = exchangeRateStoredInternal();

        if (isETH) {
            IWETH(ISinglePoolFactory(singlePoolFactory).WETH()).deposit.value(msg.value)();
        } else {
            require(IERC20(token).transferFrom(user, address(this), depositAmount));
        } 
        v.actualDepositAmount = depositAmount;

        v.depositTokens = v.actualDepositAmount.mul(1e18).div(v.exchangeRate);
        
        increaseTotalSupply(v.depositTokens);
        increaseBalance(user, v.depositTokens);

        emit Deposit(user, v.actualDepositAmount, v.depositTokens, getCashPrior(), totalSupply);
        emit Transfer(address(this), user, v.depositTokens);
    }

    function withdrawETHByAmount(uint withdrawTokens) public nonReentrant {
        address WETH = ISinglePoolFactory(singlePoolFactory).WETH();
        require(withdrawActive);
        require(token == WETH);
        accrueInterest();
        if (withdrawTokens == uint(-1)) {
            withdrawTokens = balanceOf[msg.sender];
        }
        withdrawInternal(msg.sender, withdrawTokens, 0, true);
    }

    function withdrawETH(uint withdrawAmount) public nonReentrant {   
        address WETH = ISinglePoolFactory(singlePoolFactory).WETH();
        require(withdrawActive);
        require(token == WETH);
        accrueInterest();
        withdrawInternal(msg.sender, 0, withdrawAmount, true);
    }

    function withdrawTokenByAmount(uint withdrawTokens) public nonReentrant {
        require(withdrawActive);
        accrueInterest();
        if (withdrawTokens == uint(-1)) {
            withdrawTokens = balanceOf[msg.sender];
        }
        withdrawInternal(msg.sender, withdrawTokens, 0, false);
    }

    function withdrawToken(uint withdrawAmount) public nonReentrant {   
        require(withdrawActive);
        accrueInterest();
        withdrawInternal(msg.sender, 0, withdrawAmount, false);
    }

    struct withdrawLocalVars {
        uint exchangeRate;
        uint withdrawTokens;
        uint withdrawAmount;
    }

    event Withdraw(address user, uint withdrawAmount, uint withdrawTokens, uint totalAmount, uint totalSupply);

    function withdrawInternal(address user, uint withdrawTokensIn, uint withdrawAmountIn, bool isETH) internal {
        require(withdrawTokensIn == 0 || withdrawAmountIn == 0, "one of withdrawTokensIn or withdrawAmountIn must be zero");

        withdrawLocalVars memory v;

        v.exchangeRate = exchangeRateStoredInternal();
        
        if (withdrawTokensIn > 0) {
            v.withdrawTokens = withdrawTokensIn;
            v.withdrawAmount = v.exchangeRate.mul(withdrawTokensIn).div(1e18);
        } else {
            v.withdrawTokens = withdrawAmountIn.mul(1e18).div(v.exchangeRate);
            v.withdrawAmount = withdrawAmountIn;
        }

        require(accrualBlockNumber == getBlockNumber(), "SinglePool : not fresh");
        
        require(getCashPrior() >= v.withdrawAmount, "insufficient cash");

        decreaseTotalSupply(v.withdrawTokens);
        decreaseBalance(user, v.withdrawTokens);

        if (isETH) {
            address withdrawer = ISinglePoolFactory(singlePoolFactory).nativeWithdrawer();
            IERC20(ISinglePoolFactory(singlePoolFactory).WETH()).approve(withdrawer, v.withdrawAmount);
            INativeWithdrawer(withdrawer).withdraw(user, v.withdrawAmount);
        } else {
            IERC20(token).transfer(user, v.withdrawAmount);
        }

        emit Transfer(user, address(this), v.withdrawTokens);
        emit Withdraw(user, v.withdrawAmount, v.withdrawTokens, getCashPrior(), totalSupply);
    }

    event Borrow(address user, address plusPoolAddress, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    function borrow(address user, uint borrowAmount, address plusPoolAddress) public onlySinglePoolFactory nonReentrant returns (uint, uint) {        
        accrueInterest();

        return borrowInternal(user, borrowAmount, plusPoolAddress);
    }

    struct BorrowLocalVars {
        uint accountBorrows;
        uint accountBorrowsNew;
        uint poolBorrows;
        uint poolBorrowsNew;
        uint totalBorrowsNew;
    }

    function borrowInternal(address user, uint borrowAmount, address plusPoolAddress) internal returns (uint, uint) {
        require(accrualBlockNumber == getBlockNumber(), "SinglePool : not fresh");

        require(getCashPrior() >= borrowAmount, "borrow cash not available");

        BorrowLocalVars memory v;

        v.accountBorrows = borrowBalanceStoredInternal(user, plusPoolAddress);
        v.accountBorrowsNew = v.accountBorrows.add(borrowAmount);
        v.poolBorrows = borrowBalancePoolTotal(plusPoolAddress);
        v.poolBorrowsNew = v.poolBorrows.add(borrowAmount);
        v.totalBorrowsNew = totalBorrows.add(borrowAmount);
        
        require(IERC20(token).transfer(plusPoolAddress, borrowAmount));
        
        accountBorrows[user][plusPoolAddress].principal = v.accountBorrowsNew;
        accountBorrows[user][plusPoolAddress].interestIndex = borrowIndex;
        poolTotalBorrows[plusPoolAddress].principal = v.poolBorrowsNew;
        poolTotalBorrows[plusPoolAddress].interestIndex = borrowIndex;
        totalBorrows = v.totalBorrowsNew;

        emit Borrow(user, plusPoolAddress, borrowAmount, v.accountBorrowsNew, v.totalBorrowsNew);
        
        return (v.accountBorrowsNew, borrowIndex);
    }
    
    event Repay(address user, address plusPoolAddress, uint repayAmount, uint accountBorrows, uint totalBorrows);

    function repayToken(address user, uint repayAmount, address plusPoolAddress, address spender) public onlySinglePoolFactory nonReentrant returns (uint) {
        accrueInterest();

        return repayInternal(user, repayAmount, plusPoolAddress, spender);
    }

    struct RepayLocalVars {
        uint repayAmount;
        uint borrowerIndex;
        uint accountBorrows;
        uint accountBorrowsNew;
        uint poolIndex;
        uint poolBorrows;
        uint poolBorrowsNew;
        uint totalBorrowsNew;
    }

    function repayInternal(address user, uint repayAmount, address plusPoolAddress, address spender) internal returns (uint) {
        require(accrualBlockNumber == getBlockNumber(), "SinglePool : not Fresh");

        RepayLocalVars memory v;

        v.borrowerIndex = accountBorrows[user][plusPoolAddress].interestIndex;
        v.poolIndex = poolTotalBorrows[plusPoolAddress].interestIndex;

        v.accountBorrows = borrowBalanceStoredInternal(user, plusPoolAddress);
        v.poolBorrows = borrowBalancePoolTotal(plusPoolAddress);
        
        if (repayAmount > v.accountBorrows) {
            v.repayAmount = v.accountBorrows;
        } else {
            v.repayAmount = repayAmount;
        }

        require(IERC20(token).transferFrom(spender, address(this), v.repayAmount));
    
        v.accountBorrowsNew = v.accountBorrows.sub(v.repayAmount);
        v.poolBorrowsNew = v.poolBorrows.sub(v.repayAmount);
        v.totalBorrowsNew = totalBorrows.sub(v.repayAmount);
        
        accountBorrows[user][plusPoolAddress].principal = v.accountBorrowsNew;
        accountBorrows[user][plusPoolAddress].interestIndex = borrowIndex;
        poolTotalBorrows[plusPoolAddress].principal = v.poolBorrowsNew;
        poolTotalBorrows[plusPoolAddress].interestIndex = borrowIndex;
        totalBorrows = v.totalBorrowsNew;

        emit Repay(user, plusPoolAddress, v.repayAmount, v.accountBorrowsNew, v.totalBorrowsNew);

        return v.repayAmount;
    }

    event TransferDebt(address user, address plusPoolAddress, address insurance, uint userDebt, uint insuranceDebtBefore, uint insuranceDebt, uint borrowIndex);

    function transferDebt(address user, address plusPoolAddress, address insurance) public onlySinglePoolFactory nonReentrant returns (uint) {
        accrueInterest();

        transferDebtInternal(user, plusPoolAddress, insurance);
    }

    function transferDebtInternal(address user, address plusPoolAddress, address insurance) internal {
        require(accrualBlockNumber == getBlockNumber(), "SinglePool : not Fresh");

        BorrowLocalVars memory v;

        uint userBorrowAmount = borrowBalanceStoredInternal(user, plusPoolAddress);

        v.accountBorrows = borrowBalanceStoredInternal(insurance, plusPoolAddress);
        v.accountBorrowsNew = v.accountBorrows.add(userBorrowAmount);
        
        accountBorrows[insurance][plusPoolAddress].principal = v.accountBorrowsNew;
        accountBorrows[insurance][plusPoolAddress].interestIndex = borrowIndex;

        accountBorrows[user][plusPoolAddress].principal = 0;

        emit TransferDebt(user, plusPoolAddress, insurance, userBorrowAmount, v.accountBorrows, v.accountBorrowsNew, borrowIndex);
    }


    // ======== Admin Functions ========

    event NewReserveFactor(uint oldReserveFactor, uint newReserveFactor);

    function setReserveFactor(uint newReserveFactor) public onlySinglePoolFactory nonReentrant {
        accrueInterest();
        require(accrualBlockNumber == getBlockNumber());
        require(newReserveFactor <= reserveFactorMax);

        uint oldReserveFactor = reserveFactor;
        reserveFactor = newReserveFactor;

        emit NewReserveFactor(oldReserveFactor, newReserveFactor);

    }

    event ReservesAdded(address user, uint addAmount, uint newTotalReserves);

    function addReserves(uint addAmount) external payable nonReentrant returns (uint) {
        uint totalReservesNew;
        uint addAmountReal;
        accrueInterest();      
        require(accrualBlockNumber == getBlockNumber());       

        addAmountReal = addAmount;
        IERC20(token).transferFrom(msg.sender, address(this), addAmountReal);

        totalReservesNew = totalReserves.add(addAmountReal);

        require(totalReservesNew >= totalReserves, "add reserves unexpected overflow");
        totalReserves = totalReservesNew;

        emit ReservesAdded(msg.sender, addAmountReal, totalReservesNew);

        return addAmount;
    }

    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    function reduceReserves(address admin, uint reduceAmount) external onlySinglePoolFactory nonReentrant {        
        uint totalReservesNew;

        accrueInterest();
        require(accrualBlockNumber == getBlockNumber());
        require(reduceAmount <= getCashPrior());
        require(reduceAmount <= totalReserves);

        totalReservesNew = totalReserves.sub(reduceAmount);
        
        require(totalReservesNew <= totalReserves, "reduce reserves unexpected underflow");

        totalReserves = totalReservesNew;

        IERC20(token).transfer(admin, reduceAmount);

        emit ReservesReduced(admin, reduceAmount, totalReservesNew);
    }

    event NewMarketInterestRateModel(address oldInterestRateModel, address newInterestRateModel);

    function setInterestRateModel(address newInterestRateModel) public onlySinglePoolFactory {        
        address oldInterestRateModel;

        accrueInterest();
        require(accrualBlockNumber == getBlockNumber());

        oldInterestRateModel = interestRateModel;
        interestRateModel = newInterestRateModel;
        borrowRateMax = IRateModel(newInterestRateModel).getBorrowRate(0, 1, 0);

        emit NewMarketInterestRateModel(oldInterestRateModel, newInterestRateModel);
    }

    function() payable external { revert(); }

}