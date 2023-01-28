/**
 *Submitted for verification at polygonscan.com on 2023-01-28
*/

/**
穷人会教你如何节衣缩食，小人会教你如何坑蒙拐骗，牌友只会催你打牌，酒友只会催你干杯。那成功的人会让你变得跟他一样？？？？？？？？？
人生最大的运气，不是捡钱，也不是中奖，而是有人可以鼓励你，指引|你，帮助你，发现更好的自己，走向更高的平台。
其实限制你发展的，往往不是智商和学历，而是你所处的生活圈及工作圈和身边的人很重要，所谓的贵人，并不是直接给你带来利益的人，而是开拓你的眼界，纠正你的格局，给你正能量的人，
并且你还要明白，所有浪费了的日子都是要还的。
人生是一场零和游戏，在这场游戏中，有人活得富有、潇洒、坦荡，同时也有人活得艰难， 每天为柴米油盐酱醋茶四处奔波。
或许各位有时找不到人生的意义，有时看不到生活的希望，不过这一切的一切终究会有结束的那天。那天到来的时候各位是否会对自己的一生感到后悔？
当暴风雨到来时，各位是选择躺平等待暴风雨过去，还是在雨中起舞？你不会舞？那就学！学到自己离开的那天。
如果真诚是一种伤害，那就选择谎言；如果谎言是一种伤害，那就选择沉默；如果沉默是一种伤害，那就选择离开。
如果开局得到的并不理想，那就猥琐发育，脚踏实地一步一个脚印的结束游戏，当然这是对于自己。不要相信乾坤未定，你我皆是黑马这种话，他只是成功者说给失败者的谎言。
叹气是浪费时间的，哭泣是浪费力气。以后请少做这两件事！
追求暴富，不如做白日梦。白日梦还可以给你美好的梦境，追求暴富得来的只能是冷冷的冰雨在脸上在身上胡乱的拍。
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
library Address {

    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
           
            if (returndata.length > 0) {

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


pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);


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
}

pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);


    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;





contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    function decimals() public view virtual override returns (uint8) {
        return 8;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

pragma solidity ^0.8.0;


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


pragma solidity 0.8.16;



 
 
interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}
 
interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
 
contract BingoZeroSumGame is ERC20, Ownable{
    using Address for address payable;
 
    IRouter public router;
    address public pair;
 
    bool private swapping;
    bool public swapEnabled;
    bool public lpFilled;
 
    uint256 public swapThreshold = 50_000 * 10e18;
    uint256 public maxBuy;
 
    address public BingoFund;
    address public BingoPrizePool;
 
    struct Taxes {
        uint256 BingoFund;
        uint256 BingoPrizePool;
        uint256 Liquidity; 
    }
 
    Taxes public buyTaxes = Taxes(1,1,2);
    Taxes public sellTaxes = Taxes(1,1,2);
    uint256 totalBuyTax = 4;
    uint256 totalSellTax = 4;
 
    mapping (address => bool) public excludedFromFees;
 
    modifier inSwap() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
 
    constructor() ERC20("Bingo Zero Sum Game", "BINGO") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
        excludedFromFees[msg.sender] = true;
 
        IRouter _router = IRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());
 
        router = _router;
        pair = _pair;
        excludedFromFees[address(this)] = true;
        excludedFromFees[BingoFund] = true;
        excludedFromFees[BingoPrizePool] = true;
    }
 
    function decimals() public pure override returns(uint8){
        return 8;
    }
 
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");
        require(lpFilled || excludedFromFees[sender] || excludedFromFees[recipient], "Trading disabled");
        uint256 fee;
 
        if (swapping || excludedFromFees[sender] || excludedFromFees[recipient]) fee = 0;
 
        else if(recipient == pair) fee = amount * totalSellTax / 10000;
        else if(sender == pair){
            require(amount <= maxBuy, "You are exceeding maxBuy");
            fee = amount * totalBuyTax / 10000;
        }
 
 
        if (swapEnabled && !swapping && sender != pair && fee > 0) swapForFees();
 
        super._transfer(sender, recipient, amount - fee);
        if(fee > 0) super._transfer(sender, address(this) ,fee);
 
    }
 
    function swapForFees() private inSwap {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {

            uint256 denominator = totalSellTax * 2;
            uint256 tokensToAddLiquidityWith = contractBalance * sellTaxes.Liquidity / denominator;
            uint256 toSwap = contractBalance - tokensToAddLiquidityWith;
 
            uint256 initialBalance = address(this).balance;
 
            swapTokensForBnb(toSwap);
 
            uint256 deltaBalance = address(this).balance - initialBalance;
            uint256 unitBalance= deltaBalance / (denominator - sellTaxes.Liquidity);
            uint256 bnbToAddLiquidityWith = unitBalance * sellTaxes.Liquidity;
 
            if(bnbToAddLiquidityWith > 0){

                addLiquidity(tokensToAddLiquidityWith, bnbToAddLiquidityWith);
            }
 
            uint256 BingoFundAmt = unitBalance * 2 * sellTaxes.BingoFund;
            if(BingoFundAmt > 0){
                payable(BingoFund).sendValue(BingoFundAmt);
            }
 
            uint256 BingoPrizePoolAmt = unitBalance * 2 * sellTaxes.BingoPrizePool;
            if(BingoPrizePoolAmt > 0){
                payable(BingoPrizePool).sendValue(BingoPrizePoolAmt);
            }
 
        }
    }
 
 
    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
 
        _approve(address(this), address(router), tokenAmount);
 

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
 
    }
 
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
       
        _approve(address(this), address(router), tokenAmount);
 

        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, 
            0, 
            owner(),
            block.timestamp
        );
    }
 
    function setSwapEnabled(bool state) external onlyOwner {
        swapEnabled = state;
    }
 
    function setSwapThreshold(uint256 new_amount) external onlyOwner {
        swapThreshold = new_amount * 10**decimals();
    }
 
    function setMaxBuy(uint256 amount) external onlyOwner{
        maxBuy = amount * 10**decimals();
    }
 
    function setBuyTaxes(uint256 _BingoFund, uint256 _BingoPrizePool, uint256 _Liquidity) external onlyOwner{
        buyTaxes = Taxes(_BingoFund, _BingoPrizePool, _Liquidity);
        totalBuyTax = _BingoFund + _BingoPrizePool + _Liquidity;
    }
 
    function setSellTaxes(uint256 _BingoFund, uint256 _BingoPrizePool, uint256 _Liquidity) external onlyOwner{
        sellTaxes = Taxes(_BingoFund, _BingoPrizePool, _Liquidity);
        totalSellTax = _BingoFund + _BingoPrizePool + _Liquidity;
    }
 
 
    function updateBingoFund(address newAddress) external onlyOwner{
        BingoFund = newAddress;
    }
 
    function updateBingoPrizePool(address newAddress) external onlyOwner{
        BingoPrizePool = newAddress;
    }
 
 
    function updateRouterAndPair(IRouter _router, address _pair) external onlyOwner{
        require(address(_router) != address(0), "Router cannot be zero");
        require(pair != address(0), "Pair cannot be zero");
        router = _router;
        pair = _pair;
    }
 
    function updateExcludedFromFees(address _address, bool state) external onlyOwner {
        excludedFromFees[_address] = state;
    }
 
    function confirmLpFilled() external onlyOwner{
        lpFilled = true;
        swapEnabled = true;
    }
 
 
    function rescuePolygonToken(address tokenAddress, uint256 amount) external onlyOwner{
        require(tokenAddress != address(this), "Can't take self token");
        IERC20(tokenAddress).transfer(owner(), amount);
    }
 
    function rescueMATIC(uint256 weiAmount) external onlyOwner{
        payable(owner()).sendValue(weiAmount);
    }
 

    receive() external payable {}

}