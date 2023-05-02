/**
 *Submitted for verification at polygonscan.com on 2023-05-02
*/

/*                                                                                                                                                                                      
 * ARK Credit Card Offboard MATIC
 * 
 * Written by: MrGreenCrypto
 * Co-Founder of CodeCraftrs.com
 * 
 * SPDX-License-Identifier: None
 */

pragma solidity 0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXRouter {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
}

contract CC_OFFRAMP  {
    address public constant CEO = 0x0871aEAD39ca37d3f36455F22Ce2e691775D8D3B;
    address public treasury = 0x0871aEAD39ca37d3f36455F22Ce2e691775D8D3B;
    IBEP20 public constant USDT = IBEP20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);
    IDEXRouter public constant ROUTER = IDEXRouter(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    mapping(string => Deposit) public deposits;

    event DepositDone(string uid, Deposit details);
    uint256 minDeposit = 50 * 10**6;
    uint256 maxDeposit = 5000 * 10**6;

    struct Deposit {
        address user;
        address currency;
        uint256 currencyAmount;
        uint256 depositAmount;
        uint256 timestamp;
    }

    modifier onlyCEO() {
        require(msg.sender == CEO, "Only CEO");
        _;
    }

	constructor() {
        USDT.approve(address(ROUTER), type(uint256).max);
    }

    receive() external payable {}

    function checkIfUidIsUsed(string memory uid) internal view returns (bool) {
        if(deposits[uid].timestamp == 0) return true;
        return false;
    }

    function depositMoneyUSDT(uint256 amount, string memory uid) external {
        uint256 balanceBefore = USDT.balanceOf(address(this));
        require(USDT.transferFrom(msg.sender, address(this), amount), "failed");
        Deposit memory deposit = Deposit(msg.sender, address(USDT), amount, 0, block.timestamp);
        deposits[uid] = deposit;
        _deposit(balanceBefore, uid);
    }

    function depositMoneyBNB(string memory uid, uint256 minOut) public payable {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 balanceBefore = USDT.balanceOf(address(this));
        Deposit memory deposit = Deposit(msg.sender, address(0), msg.value, 0, block.timestamp);
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = WMATIC;
        path[1] = address(USDT);
        
        ROUTER.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            minOut,
            path,
            address(this),
            block.timestamp
        );
        _deposit(balanceBefore, uid);
    }

    function depositMoneyEasy(uint256 amount, address currency, uint256 minOut, string memory uid) external {
        require(IBEP20(currency).transferFrom(msg.sender, address(this), amount), "failed");
        IBEP20(currency).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, currency, amount, 0, block.timestamp);
        deposits[uid] = deposit;

        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);

        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
        _deposit(balanceBefore, uid);
    }

    function depositMoneyExpert(uint256 amount, address[] memory path, uint256 minOut, string memory uid) external {
        require(IBEP20(path[0]).transferFrom(msg.sender, address(this), amount), "failed");
        require(path[path.length - 1] == address(USDT), "wrong");
        IBEP20(path[0]).approve(address(ROUTER), type(uint256).max);

        Deposit memory deposit = Deposit(msg.sender, path[0], amount, 0, block.timestamp);
        deposits[uid] = deposit;
        
        uint256 balanceBefore = USDT.balanceOf(address(this));
        ROUTER.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            minOut,
            path,
            address(this),
            block.timestamp
        );
        _deposit(balanceBefore, uid);
    }

    function _deposit(uint256 balanceBefore, string memory uid) internal {
        require(!checkIfUidIsUsed(uid),"Uid already exists");
        uint256 depositAmount = USDT.balanceOf(address(this)) - balanceBefore;
        require(depositAmount >= minDeposit, "Min deposit");
        require(depositAmount <= maxDeposit, "Max deposit");
        deposits[uid].depositAmount = depositAmount;
        require(USDT.transfer(treasury, depositAmount), "failed");
        emit DepositDone(uid, deposits[uid]);
    }

    function expectedUSDTFromCurrency(uint256 input, address currency) public view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = address(USDT);
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount; 
    }

    function expectedUSDTFromPath(uint256 input, address[] memory path) public view returns(uint256) {
        require(path[path.length-1] == address(USDT), "USDT");
        uint256 usdtAmount = ROUTER.getAmountsOut(input, path)[path.length - 1];
        return usdtAmount;
    }

    function rescueAnyToken(IBEP20 tokenToRescue) external onlyCEO {
        uint256 _balance = tokenToRescue.balanceOf(address(this));
        tokenToRescue.transfer(CEO, _balance);
    }

    function rescueBnb() external onlyCEO {
        (bool success,) = address(CEO).call{value: address(this).balance}("");
        if(success) return;
    } 

    function setLimits(uint256 newMinDeposit, uint256 newMaxDeposit) external onlyCEO {
        minDeposit = newMinDeposit;
        maxDeposit = newMaxDeposit;
    }       
    
    function setTreasury(address newTreasury) external onlyCEO {
        treasury = newTreasury;
    }
}