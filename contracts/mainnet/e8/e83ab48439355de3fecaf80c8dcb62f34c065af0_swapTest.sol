/**
 *Submitted for verification at polygonscan.com on 2022-10-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function safeApprove(address _target, uint256 amount) external;
    function safeTransferFrom(address _from, address _to, uint256 _amount) external;
    function safeTransfer(address _to, uint256 _amount) external;
    function approve(address _target, uint256 amount) external;
    function transferFrom(address _from, address _to, uint256 _amount) external;
    function transfer(address _to, uint256 _amount) external;
    function balanceOf(address _user) external view returns (uint256);
}

interface IWrappedNative {
    function deposit(uint256 _amount) external;
}

contract swapTest {
    IERC20 public constant W_MATIC = IERC20(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    address public owner;
    address public oneInch;

    mapping (address => bool) public gelato;

    struct SwapInfo {
        bool shouldSwap;
        uint256 amountToSwap;
        address to;
    }

    SwapInfo public swapInfo;

    constructor(
        address _oneInch
    ) {
        oneInch = _oneInch;
        owner = msg.sender;
        //W_MATIC.safeApprove(oneInch, type(uint).max);
        W_MATIC.approve(oneInch, type(uint).max);
    }

    modifier onlyGelato() {
        require(gelato[msg.sender], "Only gelato");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only Owner");
        _;
    }

    function setGelato(address _gelato, bool _activate) external onlyOwner {
        _activate ? gelato[_gelato] = true : gelato[_gelato] = false;
    }

    function swap(uint256 _amount) external payable {
        uint256 bal = address(this).balance;
         if (bal > 0) {
            IWrappedNative(address(W_MATIC)).deposit(bal);
            bal = W_MATIC.balanceOf(address(this));
         } else {
            //W_MATIC.safeTransferFrom(msg.sender, address(this), _amount);
            W_MATIC.transferFrom(msg.sender, address(this), _amount);
            bal = W_MATIC.balanceOf(address(this));
         }

         swapInfo = SwapInfo(true, bal, msg.sender);
    }   

    function swap(bytes calldata swapData) external onlyGelato returns (uint256) {
        (bool success, bytes memory retData) = oneInch.call(swapData);

        require(success == true, "calling 1inch got an error");
        (uint actualAmount, ) = abi.decode(retData, (uint, uint));
        return actualAmount;
    }

    function swapRequested() external view returns (bool swapNeeded, uint256 amount, address user) {
        swapNeeded = swapInfo.shouldSwap;
        amount = swapInfo.amountToSwap;
        user = swapInfo.to;
    }

    function recover() external onlyOwner {
        W_MATIC.transfer(msg.sender, W_MATIC.balanceOf(address(this)));
        delete swapInfo;
    }
}