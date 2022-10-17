/**
 *Submitted for verification at polygonscan.com on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBEP20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract OPTFund is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    address public devWallet = 0x17400Ca22b75870bea1b3Ff9F2276c13d516FF32;

    address public constant OPT3 = 0xCf630283E8Ff2e30C29093bC8aa58CADD8613039;
    address public constant OPT3Pair = 0xCFeADF2671F85674c6377E2FDD2593985adFA8C5;
    address public constant USDT = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
    address public constant wOPT = 0x676fcD577d0C8705F9f81577C4bFC4cc7979E69B;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;

    uint256 public priceDivisor = 1000000;

    uint256 public USDTDecimals = 6;
    uint256 public OPT3Decimals = 18;

    uint256 public maxDiscountBuy = 100;

    uint256 public dailyStakingReward = 200; // 2%
    uint256 public rewardPeriod = 1 days; // 86400
    uint256 public stakingFee = 800; // 8%
    uint256 public devFee = 500;
    uint256 public OPT3BurnFee = 300;
    uint256 public percentRate = 10000;

    uint256 public minimumDaily = 50;
    uint256 public maximumDaily = 300;

    uint256 public discountPercent = 30;

    struct stakeStruct {
        uint256 id;
        uint256 stakedAmount;
        address depositor;
        uint256 lastClaim;
    }

    stakeStruct[] public deposits;

    uint256 public totalDeposits = 0;

    bool public depositingOpen;
    bool public LQBuildingOpen;
    bool public borrowingOpen;

    uint256 public lastPayout;
    uint256 public nextPayout;

    mapping(address => uint256) public adrToID;
    mapping(uint256 => stakeStruct) public idToDeposit;

    mapping(address => bool) public depositedBefore;

    mapping(address => uint256) public adrToDiscountOPT;

    function changeDevWallet(address _new) external onlyOwner {
        devWallet = _new;
    }

    function switchDepositingStatus() external onlyOwner {
        if(depositingOpen) {
            depositingOpen = false;
        }
        if(!depositingOpen) {
            depositingOpen = true;
        }
    }

    
    function switchLQBuildingStatus() external onlyOwner {
        if(LQBuildingOpen) {
            LQBuildingOpen = false;
        }

        if(!LQBuildingOpen) {
            LQBuildingOpen = true;
        }
    }

    
    function switchBorrowingStatus() external onlyOwner {
        if(borrowingOpen) {
            borrowingOpen = false;
        }

        if(!borrowingOpen) {
            borrowingOpen = true;
        }
    }

    function changeMaxDiscountBuy(uint256 _newValue) external onlyOwner {
        maxDiscountBuy = _newValue;
    }

    function calculateRewards(uint256 _id) public view returns (uint256) {

        uint256 lastRoiTime = block.timestamp - idToDeposit[_id].lastClaim;

        uint256 allClaimableAmount = (lastRoiTime * idToDeposit[_id].stakedAmount * dailyStakingReward).div(percentRate * rewardPeriod);

        return allClaimableAmount;
    }

    function getOPT3Price() public view returns (uint256) {

        IUniswapV2Pair pair = IUniswapV2Pair(OPT3Pair);

        IBEP20 token1 = IBEP20(pair.token1());

        (uint Res0, uint Res1,) = pair.getReserves();

        uint res0 = Res0*(10**token1.decimals());

        return((1*res0) / Res1);
    }

    function changeDailyReward(uint256 _new) external onlyOwner {
        require(_new >= minimumDaily && _new <= maximumDaily); // minimum daily reward = 0.5% | maximum daily reward = 3%
        dailyStakingReward = _new;
    }

    function changeDiscountPercent(uint256 _new) external onlyOwner {
        require(_new >= 1000 && _new <= 4000); // DISCOUNT CAN'T BE LOWER THAN 10% AND CAN'T BE HIGHER THAN 40%
        discountPercent = _new;
    }

    function getIDFromAddr(address _address) public view returns (uint256) {
        return adrToID[_address];
    }

    function getStakeFromID(uint256 _id) public view returns (stakeStruct memory) {
        return idToDeposit[_id];
    }

    function depositOPT3(uint256 _amount) external {
        require(depositingOpen = true);
        require(_amount >= 0);

        if(depositedBefore[msg.sender] = false) {
            uint256 newDepositID = totalDeposits.add(1);
            IBEP20(OPT3).transferFrom(msg.sender, address(this), _amount);

            uint256 depositFee = (_amount * stakingFee).div(percentRate);
            uint256 depositAfterFees = _amount.sub(depositFee);
            uint256 amountForDev = (_amount * devFee).div(percentRate);
            uint256 amountForBurn = (_amount * OPT3BurnFee).div(percentRate);

            IBEP20(OPT3).transfer(devWallet, amountForDev);
            IBEP20(OPT3).transfer(DEAD, amountForBurn);

            adrToID[msg.sender] = newDepositID;
            idToDeposit[newDepositID].id = newDepositID;
            idToDeposit[newDepositID].stakedAmount = depositAfterFees;
            idToDeposit[newDepositID].depositor = msg.sender;
            idToDeposit[newDepositID].lastClaim = block.timestamp;
            depositedBefore[msg.sender] = true;
            totalDeposits.add(1);
        }

        if(depositedBefore[msg.sender] = true) {
            IBEP20(OPT3).transferFrom(msg.sender, address(this), _amount);
            uint256 dID = getIDFromAddr(msg.sender);

            claimRewards(dID);

            uint256 depositFee = (_amount * stakingFee).div(percentRate);
            uint256 depositAfterFees = _amount.sub(depositFee);
            uint256 amountForDev = (_amount * devFee).div(percentRate);
            uint256 amountForBurn = (_amount * OPT3BurnFee).div(percentRate);

            IBEP20(OPT3).transfer(devWallet, amountForDev);
            IBEP20(OPT3).transfer(DEAD, amountForBurn);

            idToDeposit[dID].stakedAmount = idToDeposit[dID].stakedAmount.add(depositAfterFees);
        }
    }

    function claimRewards(uint256 _id) public nonReentrant {
        require(idToDeposit[_id].depositor == msg.sender, "Sender is not the depositor of this ID");

        uint256 rewardsToClaim = calculateRewards(_id);

        idToDeposit[_id].lastClaim = block.timestamp;

        IBEP20(OPT3).transfer(msg.sender, rewardsToClaim);
    }

    function compoundRewards(uint256 _id) public nonReentrant {
        require(idToDeposit[_id].depositor == msg.sender, "Sender is not the depositor of this ID");

        uint256 rewardsToClaim = calculateRewards(_id);

        idToDeposit[_id].lastClaim = block.timestamp;

        idToDeposit[_id].stakedAmount = idToDeposit[_id].stakedAmount.add(rewardsToClaim);
    }

    function withdrawDeposit(uint256 _id, uint256 _amount) public nonReentrant {
        require(idToDeposit[_id].depositor == msg.sender, "Sender is not the depositor of this ID");
        require(idToDeposit[_id].stakedAmount >= _amount, "Cant withdraw more than deposited");

        claimRewards(_id);

        idToDeposit[_id].stakedAmount = idToDeposit[_id].stakedAmount.sub(_amount);

        uint256 amountForDev = (_amount.mul(devFee)).div(percentRate);
        uint256 amountForBurn = (_amount.mul(OPT3BurnFee)).div(percentRate);

        uint256 amountToSend = _amount.sub(amountForDev + amountForBurn);


        IBEP20(OPT3).transfer(devWallet, amountForDev);
        IBEP20(OPT3).transfer(DEAD, amountForBurn);
        
        IBEP20(OPT3).transfer(msg.sender, amountToSend);
    }

    ////////////////////////////////////////////////////////////////////////////////
                        // LIQUIDITY SEED
    ///////////////////////////////////////////////////////////////////////////////

    function buyDiscount(uint256 _USDTAmount) public {
        require(LQBuildingOpen = true, 'Function is closed right now');
        require(_USDTAmount <= maxDiscountBuy);

        IERC20(USDT).transferFrom(msg.sender, address(this), _USDTAmount);

        adrToDiscountOPT[msg.sender] = adrToDiscountOPT[msg.sender].add(_USDTAmount);

    } 

    function redeemDiscount() public nonReentrant {
        require(adrToDiscountOPT[msg.sender] > 0, "No discount tokens bought");

        uint256 discountBought = adrToDiscountOPT[msg.sender];

        adrToDiscountOPT[msg.sender] = 0;

        uint256 currentOPT3Price = getOPT3Price();

        uint256 actualDiscount = discountBought.add((discountBought / 100) * discountPercent);

        uint256 amountToSend = (actualDiscount.div(currentOPT3Price).mul(priceDivisor));

        IBEP20(OPT3).transfer(msg.sender, amountToSend);

    }

    ////////////////////////////////////////////////////
    //        BORROWING
    ///////////////////////////////////////////////////

    struct LoanStruct {
        uint256 id;
        address taker;
        uint256 CollateralOPT3Amount;
        uint256 lastRebaseClaim;
        uint256 USDTBorrowed;
        uint256 OPT3PriceAtBorrowing;
        uint256 liquidationPrice;
        bool paidOff;
    }

    uint256 totalLoans = 0;

    uint256 allowedBorrowingPercentage = 50;

    uint256 dailyRebase = 100; // 1%;

    mapping(address => uint256) public adrToLoanID;
    mapping(uint256 => LoanStruct) public idToLoan;

    mapping(address => bool) public borrowedBefore;

    function getLoanIDFromAddr(address _address) public view returns (uint256) {
        return adrToLoanID[_address];
    }

    function changeBorrowingPercentage(uint256 _new) external onlyOwner {
        allowedBorrowingPercentage = _new;
    }

    function calculateBorrowableAmount(uint256 _coll) public view returns (uint256) {
        uint256 OPTPrice = getOPT3Price();
        //uint256 oToUSD = 1 * OPTPrice;
        //uint256 uToOPT3 = 1 / OPTPrice;

        uint256 collTotalValue = _coll.mul(OPTPrice);

        uint256 availableToBorrow = ((collTotalValue.div(100)).mul(allowedBorrowingPercentage));

        return availableToBorrow;
    }

    function borrowUsingOPT3(uint256 _OPT3Amount) external {
        require(borrowingOpen = true);

        IBEP20(OPT3).transferFrom(msg.sender, address(this), _OPT3Amount);

        uint256 loanAmount = calculateBorrowableAmount(_OPT3Amount);

        uint256 currentPrice = getOPT3Price();

        uint256 liquidPrice = (currentPrice.div(100)).mul(60);

        if(borrowedBefore[msg.sender] = true) {
            uint256 loanID = getLoanIDFromAddr(msg.sender);
            require(idToLoan[loanID].paidOff = true, "You need to pay off your loan first.");

            idToLoan[loanID].CollateralOPT3Amount = _OPT3Amount;
            idToLoan[loanID].lastRebaseClaim = block.timestamp;
            idToLoan[loanID].USDTBorrowed = loanAmount;
            idToLoan[loanID].OPT3PriceAtBorrowing = currentPrice;
            idToLoan[loanID].liquidationPrice = liquidPrice;
            idToLoan[loanID].paidOff = false;

            IERC20(USDT).transfer(msg.sender, loanAmount.div(priceDivisor));

        }

        if(borrowedBefore[msg.sender] = false) {
            uint256 newLoanID = totalLoans.add(1);

            idToLoan[newLoanID].id = newLoanID;
            idToLoan[newLoanID].taker = msg.sender;
            idToLoan[newLoanID].CollateralOPT3Amount = _OPT3Amount;
            idToLoan[newLoanID].lastRebaseClaim = block.timestamp;
            idToLoan[newLoanID].USDTBorrowed = loanAmount;
            idToLoan[newLoanID].OPT3PriceAtBorrowing = currentPrice;
            idToLoan[newLoanID].liquidationPrice = liquidPrice;
            idToLoan[newLoanID].paidOff = false;

            borrowedBefore[msg.sender] = true;

            IERC20(USDT).transfer(msg.sender, loanAmount.div(priceDivisor));

            totalLoans.add(1);
        }
    }

    function calculateAmountToRepay(uint256 _id) public view returns (uint256) {
        uint256 amountToRepay = (idToLoan[_id].USDTBorrowed).add((idToLoan[_id].USDTBorrowed).div(100).mul(8));
        return amountToRepay;
    }

    function calculateRepayingToDev(uint256 _id) public view returns (uint256) {
        uint256 amountToDev = (idToLoan[_id].USDTBorrowed).div(100).mul(4);
        return amountToDev;
    }

    function calculateRepayingForOptimusLQ(uint256 _id) public view returns (uint256) {
        uint256 amountToLQ = (idToLoan[_id].USDTBorrowed).div(100).mul(4);
        return amountToLQ;
    }

    function calculateLoanRebases(uint256 _id) public view returns (uint256) {

        uint256 lastRoiTime = block.timestamp - idToLoan[_id].lastRebaseClaim;

        uint256 allClaimableAmount = (lastRoiTime * idToLoan[_id].CollateralOPT3Amount * dailyRebase).div(percentRate * rewardPeriod);

        return allClaimableAmount;
    }

    function claimLoanRebases(uint256 _id) public nonReentrant {
        require(borrowedBefore[msg.sender] = true);
        require(idToLoan[_id].taker == msg.sender);

        uint256 toClaim = calculateLoanRebases(_id);

        idToLoan[_id].lastRebaseClaim = block.timestamp;

        IBEP20(OPT3).transfer(msg.sender, toClaim);
    }

    function repayLoan(uint256 _id) external nonReentrant {
        require(idToLoan[_id].taker == msg.sender);

        uint256 currentPrice = getOPT3Price();

        require(currentPrice > idToLoan[_id].liquidationPrice, 'Loan is currently locked (price too low)');

        uint256 repayingAmount = calculateAmountToRepay(_id);
        uint256 forDev = calculateRepayingToDev(_id);
        uint256 forLQ = calculateRepayingForOptimusLQ(_id);

        IERC20(USDT).transferFrom(msg.sender, address(this), repayingAmount);

        IERC20(USDT).transfer(devWallet, forDev);
        IERC20(USDT).transfer(OPT3Pair, forLQ);

        uint256 OPT3ToReturn = idToLoan[_id].CollateralOPT3Amount;

        if(calculateLoanRebases(_id) > 1) {
            claimLoanRebases(_id);
        }

        idToLoan[_id].CollateralOPT3Amount = 0;
        idToLoan[_id].USDTBorrowed = 0;
        idToLoan[_id].OPT3PriceAtBorrowing = 0;
        idToLoan[_id].liquidationPrice = 0;
        idToLoan[_id].paidOff = true;

        IBEP20(OPT3).transfer(msg.sender, OPT3ToReturn);
    }

    function liquifyLoan(uint256 _id) external {
        require(borrowedBefore[msg.sender]);
        require(idToLoan[_id].taker == msg.sender);

        idToLoan[_id].CollateralOPT3Amount = 0;
        idToLoan[_id].USDTBorrowed = 0;
        idToLoan[_id].OPT3PriceAtBorrowing = 0;
        idToLoan[_id].liquidationPrice = 0;
        idToLoan[_id].paidOff = true;

    }

    ////////////////////////////////////

    function testingWithdrawOPT3(uint256 _amount) external onlyOwner {
        IBEP20(OPT3).transfer(msg.sender, _amount);
    }

    function testingWithdrawUSDT(uint256 _amount) external onlyOwner {
        IERC20(USDT).transfer(msg.sender, _amount);
    }

}