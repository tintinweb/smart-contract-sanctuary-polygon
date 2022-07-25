// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TransferHelperTron.sol";
import "./SafeMath.sol";

contract FastPayTron {

    address public owner;

    address public manager;

    event AddMerchantAddress(address indexed merchant, address indexed addr);

    event SweepWithdraw(address indexed merchant, address indexed token, string orderNo);

    event CashSweep(address indexed merchant, address indexed token, uint256 sweepAmt, uint256 sweepCount);

    event ClaimFee(address indexed caller, address indexed token, uint256 amount);


    mapping(address => uint256) totalFeesOf;

    mapping(address => mapping(address => uint256)) public balanceOf;

    mapping(address => address[]) public merchantAddress;

    mapping(string => bool) public ordersOf;


    struct Withdraw {
        string orderNo;
        address token;
        address merchant;
        uint256 merchantAmt;
        address proxy;
        uint256 proxyAmt;
        uint256 fee;
        uint256 deadLine;
    }

    constructor(address _manager) {
        manager = _manager;
        owner = msg.sender;
    }

    function addMerchantAddress(
        address _merchant,
        address _addr
    ) external onlyManager {

        require(_merchant != _addr);
        require(address(0) != _merchant);

        merchantAddress[_merchant].push(_addr);

        emit AddMerchantAddress(_merchant, _addr);

    }

    function cashSweep(
        address _token,
        uint256 _start
    ) external returns (uint256 sweepAmt, uint256 sweepCount) {

        (sweepAmt, sweepCount) = sweep(msg.sender, _token, _start);

        return (sweepAmt, sweepCount);

    }

    function cashSweepAndWithdraw(
        Withdraw memory withdraw
    ) external {

        require(address(0) != withdraw.merchant);
        require(msg.sender == withdraw.merchant);
        require(withdraw.merchantAmt > 0);
        require(withdraw.deadLine > getTimes());

        if(checkBalance(withdraw)) {

            withdrawFromBalance(withdraw);

        } else {

            sweep(withdraw.merchant, withdraw.token, 0);

            require(checkBalance(withdraw));

            withdrawFromBalance(withdraw);

        }

    }

    function checkBalance(
        Withdraw memory withdraw
    ) view internal returns(bool) {
        return balanceOf[withdraw.merchant][withdraw.token] >= withdraw.merchantAmt + withdraw.proxyAmt + withdraw.fee;
    }

    function withdrawFromBalance(
        Withdraw memory withdraw
    ) internal {

        TransferHelperTron.safeTransfer(withdraw.token, withdraw.merchant, withdraw.merchantAmt);
        balanceOf[withdraw.merchant][withdraw.token] -= withdraw.merchantAmt;

        if(address(0) != withdraw.proxy && 0 < withdraw.proxyAmt) {
            TransferHelperTron.safeTransfer(withdraw.token, withdraw.proxy, withdraw.proxyAmt);
            balanceOf[withdraw.merchant][withdraw.token] -= withdraw.proxyAmt;
        }

        balanceOf[withdraw.merchant][withdraw.token] -= withdraw.fee;
        totalFeesOf[withdraw.token] += withdraw.fee;

        require(balanceOf[withdraw.merchant][withdraw.token] >= 0);
        require(totalFeesOf[withdraw.token] >= withdraw.fee);

        ordersOf[withdraw.orderNo] = true;

        emit SweepWithdraw(withdraw.merchant, withdraw.token, withdraw.orderNo);

    }

    function sweep(
        address _merchant,
        address _token,
        uint256 _start
    ) internal returns (uint256,uint256) {

        address [] memory addresses = merchantAddress[_merchant];

        uint256 sweepCount = 0;
        uint256 index = _start;
        uint256 sweepAmount = 0;

        while(true) {

            if(address(0) == addresses[index]) {
                break;
            }

            uint256 balance = IERC20(_token).balanceOf(addresses[index]);
            if(balance <= 0) {
                index ++;
                continue;
            }

            TransferHelperTron.safeTransferFrom(_token, addresses[index], address(this), balance);

            index ++;

            sweepCount += 1;
            sweepAmount =  SafeMath.add(sweepCount, balance);

            if(sweepCount >= 500) {
                break;
            }

        }

        balanceOf[_merchant][_token] += sweepAmount;

        emit CashSweep(_merchant, _token, sweepAmount, index - _start);

        return (sweepAmount, index - _start);

    }

    function getTimes() view public returns(uint256) {
        return block.timestamp;
    }

    function changeManager (
        address _newManager
    ) external onlyOwner {
        manager = _newManager;
    }

    function claimFee(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(totalFeesOf[_token] >= _amount);
        TransferHelperTron.safeTransfer(_token, msg.sender, _amount);
        emit ClaimFee(msg.sender, _token, _amount);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "Manager: caller is not the manager");
        _;
    }

}