//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./SafeMath.sol";
import "./Auth.sol";
import "./IUniswap.sol";
import "./IERC20.sol";
//                            :
//                            :::
//     '::                   ::::
//     '::::.     .....:::.:::::::
//     '::::::::::::::::::::::::::::
//     ::::::XUWWWWWU:::::XW$$$$$$WX:
//     ::::X$$$$$$$$$$W::X$$$$$$$$$$Wh
//    ::::t$$$$$$$$$$$$W:$$$$$$P*$$$$M::
//    :::X$$$$$$""""$$$$X$$$$$   ^$$$$X:::
//   ::::M$$$$$$    ^$$$RM$$$L    <$$$X::::
// .:::::M$$$$$$     $$$R:$$$$.   d$$R:::`
//'~::::::?$$$$$$...d$$$X$6R$$$$$$$$RXW$X:'`
//  '~:[email protected]$$$#:   
contract Felix is IERC20, Auth {
    using SafeMath for uint256;
    using Address for address;

    IERC20 ALTERNATE_REWARDS_CONTRACT;
    IERC20 WETH;

    string constant _name = "FELIX";
    string constant _symbol = "FELIX";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 10_000_000 * (10 ** _decimals);
    uint256 public _transferUpperLimit = _totalSupply.div(200); // 0.125%
    uint256 public autoSwapTrigger = _totalSupply / 2000; // 0.005%
    uint256 targetLiquidityDenominator = 100;
    uint256 reflectionDonation = 200;
    uint256 liquidityDonation = 400;
    uint256 totalNetworkFees = 1000;
    uint256 feeDenominator = 10000;
    uint256 rationalize = 10000;
    uint256 teamDonation = 400;
    uint256 minBuyPercent = 100;
    uint256 maxRebateToken = 100000 * (10**_decimals); // 1%
    uint256 minSellToken = 1 * (10**_decimals);
    uint256 minContribution = 0.01 ether;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address payable public autoLiquidityReceiver;
    address payable public teamDonationHolder;

    IUniswapV2Router02 public router;
    address public pair;
    address payable public felixContract;

    bool public autoSwapDoOp;
    bool internal locked;
    bool midSwap;

    mapping (address => mapping (address => uint256)) _allowances;
    mapping(address => uint) private _limitInteraction;
    mapping (address => bool) isTransactionExempt;
    mapping (address => bool) isRebateExempt;
    mapping (address => bool) isDonorExempt;
    mapping (address => uint256) _balances;
    mapping (address => bool) public amm;

    event AddAMM(address amm);
    event RemoveAMM(address amm);
    event AutoLiquify(uint256 amountETH, uint256 amountLiquidity);

    modifier processing() { midSwap = true; _; midSwap = false; }

    modifier nonReentrancy() {
        require(!locked, "No reentrancy allowed");

        locked = true;
        _;
        locked = false;
    }
    
    constructor () Auth(payable(msg.sender)) {
        felixContract = payable(this);
        minContribution = 0.01 ether;
        maxRebateToken = 100000 * (10**_decimals);
        _totalSupply = 10_000_000 * (10 ** _decimals);
        _transferUpperLimit = _totalSupply.div(200); // 0.125%
        autoSwapTrigger = _totalSupply / 2000; // 0.005%
        targetLiquidityDenominator = 100;
        reflectionDonation = 200;
        liquidityDonation = 400;
        totalNetworkFees = 1000;
        feeDenominator = 10000;
        rationalize = 10000;
        autoSwapDoOp = true;
        teamDonation = 400;
        minSellToken = 100 * (10 ** _decimals);
        minBuyPercent = 100;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
        );
        router = _uniswapV2Router;
        WETH = IERC20(router.WETH());
        pair = IUniswapV2Factory(router.factory()).createPair(address(felixContract), router.WETH());

        _allowances[address(felixContract)][address(router)] = _totalSupply;
        _allowances[address(felixContract)][address(pair)] = _totalSupply;

        autoLiquidityReceiver = payable(0xB9F96789D98407B1b98005Ed53e8D8824D42A756);
        teamDonationHolder = payable(0x49e6a9eA17D0E8e62b59Bd9C0C4D40e9A1c45bdC);

        isDonorExempt[msg.sender] = true;
        _limitInteraction[msg.sender] = block.timestamp + 1 minutes;
        isDonorExempt[address(felixContract)] = true;
        isDonorExempt[address(pair)] = true;
        isDonorExempt[address(router)] = true;
        isDonorExempt[address(autoLiquidityReceiver)] = true;
        isDonorExempt[address(teamDonationHolder)] = true;
        isTransactionExempt[msg.sender] = true;
        isTransactionExempt[address(felixContract)] = true;
        isTransactionExempt[address(pair)] = true;
        isTransactionExempt[address(router)] = true;
        isTransactionExempt[address(autoLiquidityReceiver)] = true;
        isTransactionExempt[address(teamDonationHolder)] = true;
        isRebateExempt[msg.sender] = true;
        isRebateExempt[address(felixContract)] = true;
        isRebateExempt[address(pair)] = true;
        isRebateExempt[address(router)] = true;
        isRebateExempt[address(autoLiquidityReceiver)] = true;
        isRebateExempt[address(teamDonationHolder)] = true;
        isRebateExempt[address(DEAD)] = true;
        
        addAMM(address(pair));
        authorize(msg.sender);

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

    function _approve(
        address holder,
        address spender,
        uint256 amount
    ) private {
        require(address(holder) == address(msg.sender));
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
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
    
    function checkOwedReflections(address payable receiver) public view returns(uint256){
        uint256 baseReceiverBalance = _balances[address(receiver)];
        uint256 baseReceiverOwnership = baseReceiverBalance / _totalSupply;
        uint256 contractTokenBalance = IERC20(address(this)).balanceOf(address(felixContract));

        uint256 baseRebatePerReceiver = contractTokenBalance * baseReceiverOwnership;
        return baseRebatePerReceiver;
    }

    function claimReflections(address payable recipient) external payable authorized nonReentrancy returns(bool) {
        require(msg.value >= minContribution,"Donation amount is 0");
        require(address(recipient) == address(msg.sender),"Must call from owned EOA");
        uint contractETHBalance = address(felixContract).balance;
        require(contractETHBalance > 0,"Contract needs some Ether, send direct or contact operators");
        bool doAutoSwap = block.timestamp >= (_limitInteraction[recipient] + 12 hours);
        require(doAutoSwap == true,"EOA does not qualify to claim reflections, try again in 12 hours");
        (bool success, ) = address(felixContract).call{value: msg.value}("");
        require(success, "Failed to transfer Ether");
        //uint ETHIN_amount = address(felixContract).balance - contractETHBalance;

        uint256 baseReceiverBalance = _balances[address(recipient)];
        require(baseReceiverBalance > 0);
        uint256 baseReceiverOwnership = baseReceiverBalance / _totalSupply;
        uint256 contractTokenBalance = IERC20(address(this)).balanceOf(address(felixContract));
        require(contractTokenBalance > 0);
        uint256 baseRebatePerReceiver = contractTokenBalance * baseReceiverOwnership;
        if(baseRebatePerReceiver > maxRebateToken){
            baseRebatePerReceiver = maxRebateToken;
        }
        require(baseRebatePerReceiver <= contractTokenBalance, "Request exceeds contract token balance.");
        _balances[address(this)] = _balances[address(this)].sub(baseRebatePerReceiver, "Insufficient Balance");
        _balances[address(recipient)] += baseRebatePerReceiver;
        emit Transfer(address(this), address(recipient), baseRebatePerReceiver);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 senderFelixBalance = IERC20(address(felixContract)).balanceOf(address(sender));
        require(amount <= senderFelixBalance, "Request exceeds sender FELIX balance.");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(midSwap){ return _basicTransfer(sender, recipient, amount); }

        monitorTransferRequirement(sender, amount);
        if(shouldAutoSwap(address(sender))){ autoSwap(address(sender),address(recipient)); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldDonateToNetwork(sender) ? takeDonations(payable(sender), amount) : amount;

        _balances[recipient] += amountReceived; 
        
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] += amount;
        return true;
    }
    
    function setMinAMMMarketTriggers(uint256 _sell, uint256 _buy) public authorized {
        minSellToken = _sell;
        minBuyPercent = _buy;
    }

    function rescueStuckTokens(address _tok, address payable recipient, uint256 amount) public payable authorized {
        uint256 contractTokenBalance = IERC20(_tok).balanceOf(address(felixContract));
        require(amount <= contractTokenBalance, "Request exceeds contract token balance.");
        // rescue stuck tokens 
        IERC20(_tok).transfer(recipient, amount);
    }

    function rescueStuckNative(address payable recipient) public payable authorized {
        // get the amount of Ether stored in this contract
        uint contractETHBalance = address(felixContract).balance;
        // rescue Ether to recipient
        (bool success, ) = recipient.call{value: contractETHBalance}("");
        require(success, "Failed to rescue Ether");
    }

    function monitorTransferRequirement(address sender, uint256 amount) internal view {
        require(amount <= _transferUpperLimit || isTransactionExempt[sender], "Transaction Exceeds Maximum Transfer Limitations! Contact operators");
    }

    function shouldDonateToNetwork(address sender) internal view returns (bool) {
        return !isDonorExempt[sender];
    }

    function getLiquidity(uint256 _value) internal view returns (uint) {
        return _value.mul(liquidityDonation).div(feeDenominator);
    }

    function getTeam(uint256 _value) internal view returns (uint) {
        return _value.mul(teamDonation).div(feeDenominator);
    }

    function getReflection(uint256 _value) internal view returns (uint) {
        return _value.mul(reflectionDonation).div(feeDenominator);
    }

    function takeDonations(address payable sender, uint256 amount) internal returns (uint256) {
        uint256 amB = amount;
        uint256 lA = getLiquidity(amB);
        uint256 ltA = amB-lA;
        uint256 tA = getTeam(ltA);
        uint256 rtA = ltA-tA;
        uint256 rA = getReflection(rtA);
        uint256 faB = rtA-rA;
        uint256 anF = (lA + tA) + rA;
        require(faB == (amount-anF),"Improper accounting error: Contact Operators");
        _balances[address(this)] += anF;
        swapAndSendToTeam(tA);
        emit Transfer(sender, address(felixContract), anF);

        return amount.sub(anF);
    }

    function shouldAutoSwap(address from) internal view returns (bool) {
        uint256 contractFelixBalance = IERC20(address(felixContract)).balanceOf(address(this));
        bool minTokenBalance = contractFelixBalance >= minSellToken;
        if (minTokenBalance && block.timestamp >= (_limitInteraction[from] + 10 minutes)){
            if (!midSwap && autoSwapDoOp && !amm[from] && _balances[address(felixContract)] >= autoSwapTrigger){
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    function swapTokensForETH(uint256 tokenToSwap) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenToSwap);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenToSupply, uint256 ethToSupply) private {
        _approve(address(this), address(router), tokenToSupply);

        router.addLiquidityETH{value: ethToSupply}(
            address(this),
            tokenToSupply,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
    }
    
    function addLiquidityPublic(uint256 tokenToSupply) public payable {
        uint256 etherBalance = address(this).balance;
        require(msg.value <= etherBalance,"Too much");
        _approve(address(this), address(router), tokenToSupply);

        router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenToSupply,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        );
    }

    function swapAndSendToTeam(uint256 tokens) private {
        _approve(address(this), address(router), tokens);
        uint256 initialBalance = address(this).balance;
        swapTokensForETH(tokens);
        uint256 amountETHTeam = address(this).balance - initialBalance;
        payable(teamDonationHolder).transfer(amountETHTeam);
    }

    function autoSwap(address sender, address receiver) internal processing {
        // uint256 contractTokenBalance = IERC20(address(felixContract)).balanceOf(address(this));
        uint256 initialBalance = address(this).balance;
        uint256 sellAmount = minSellToken / 2;
        uint256 buyAmount = (initialBalance * minBuyPercent) / rationalize;
        uint256 liquidityAmount = minSellToken - sellAmount;

        // buy
        if (amm[sender] == true) {
            liquidityAmount = minSellToken - sellAmount;
            swapTokensForETH(sellAmount);
            uint256 amountETH = address(this).balance - initialBalance;
            addLiquidity(liquidityAmount, amountETH);
            emit AutoLiquify(amountETH, liquidityAmount);
        }

        // sell
        if (amm[receiver] == true) {
            liquidityAmount = minBuyPercent - buyAmount;
            //try buyTokensToContract{value: buyAmount}() {} catch {}
        }

    }

    function buyTokensToBurn() public payable processing {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            payable(DEAD),
            block.timestamp
        );
    }

    function buyTokensToContract() external payable processing {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            payable(felixContract),
            block.timestamp
        );
    }

    function buyTokens(address payable _receiver) public payable processing {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            payable(_receiver),
            block.timestamp
        );
    }

    function adjustTransferLimit(uint256 amount) external authorized {
        _transferUpperLimit = amount;
    }

    function setRebateExemptFor(address payable holder, bool status) external authorized {
        require(holder != address(felixContract) && holder != pair);
        isRebateExempt[address(holder)] = status;
    }

    function markDonorExempt(address holder, bool exempt) external authorized {
        isDonorExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTransactionExempt[holder] = exempt;
    }

    function getCirculatingSupply() public view returns (uint256) {
        uint256 burned = IERC20(address(felixContract)).balanceOf(address(DEAD));
        return (_totalSupply - burned);
    }

    function getMaxSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setDonations(uint256 _liquidityDonations, uint256 _reflectionDonations, uint256 _teamDonations, uint256 _feeDenominator) external authorized returns (bool) {
        liquidityDonation = _liquidityDonations;
        reflectionDonation = _reflectionDonations;
        teamDonation = _teamDonations;
        totalNetworkFees = (_liquidityDonations + _reflectionDonations + _teamDonations);
        feeDenominator = _feeDenominator;
        require(totalNetworkFees < feeDenominator/4);
        return true;
    }

    function setDonationsHolders(address payable _LPHolder, address payable _teamHolder) public authorized {
        autoLiquidityReceiver = _LPHolder;
        teamDonationHolder = _teamHolder;
    }

    function setAutoSwapCriteria(bool _enabled, uint256 _amount) public authorized {
        autoSwapDoOp = _enabled;
        autoSwapTrigger = _amount;
    }

    function newUniRouter(address _newRouter) external authorized {        
        IUniswapV2Router02 _newUniswapRouter = IUniswapV2Router02(_newRouter);
        pair = IUniswapV2Factory(_newUniswapRouter.factory()).createPair(address(felixContract), _newUniswapRouter.WETH());
        router = _newUniswapRouter;
    }

    function addAMM(address _amm) public authorized {
        amm[_amm] = true;
        emit AddAMM(_amm);
    }
    
    function removeAMM(address _amm) public authorized {
        amm[_amm] = false;
        emit RemoveAMM(_amm);
    }

    /**
     * Transfer ownership to new address. Caller must be owner. 
     * Deauthorizes old owner, and sets fee receivers to new owner, while disabling autoSwap()
     * New owner must reset fees, and re-enable autoSwap()
     */
    function transferOwnership(address payable adr) public virtual override authorized returns (bool) {
        setDonationsHolders(adr, adr);
        setAutoSwapCriteria(false, 0);
        authorizations[owner] = false;
        owner = adr;
        authorizations[adr] = true;
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
        authorizations[adr] = false;
        authorizations[owner] = false;
        authorizations[_owner] = false;
        _owner = payable(adr);
        owner = _owner;
        emit OwnershipTransferred(adr);
        return true;
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