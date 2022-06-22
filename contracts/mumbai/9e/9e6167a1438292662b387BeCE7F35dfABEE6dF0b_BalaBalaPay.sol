// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./TransferHelper.sol";
import "./Address.sol";
import "./SafeMath.sol";

contract BalaBalaPay is Initializable, OwnableUpgradeable{

    uint256 public paymentRate = 50;

    event Send(address indexed sender, address token, uint256 amount, uint256 fee);

    event Claim(address indexed payee, address token, uint256 amount);

    receive() payable external {}

    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function sendToken(address token, address[] memory payees, uint256[] memory amounts) external {

        require(Address.isContract(token));

        uint256 amount = 0;

        for(uint i=0; i<payees.length; i++) {

            TransferHelper.safeTransferFrom(token, msg.sender, payees[i], amounts[i]);

            amount = SafeMath.add(amount, amounts[i]);

        }

        uint256 fee = getFee(amount);

        if(fee >= 0) {
            TransferHelper.safeTransferFrom(token, msg.sender, address(this), fee);
        }

        emit Send(msg.sender, token, amount, fee);

    }

    function sendETH(address[] memory payees, uint256[] memory amounts) external payable {

        uint256 amount = 0;

        for(uint i=0; i<payees.length; i++) {

            TransferHelper.safeTransferETH(payees[i], amounts[i]);

            amount = SafeMath.add(amount, amounts[i]);

        }

        uint256 fee = getFee(amount);

        uint256 totalOrderAmount = SafeMath.add(amount, fee);

        require(msg.value >= totalOrderAmount);

        emit Send(msg.sender, address(0), amount, fee);

    }

    function getFee(uint256 amount) public view returns(uint256) {

        if (amount == 0 || paymentRate == 0){
            return 0;
        }

        return SafeMath.div((SafeMath.mul(amount ,paymentRate)), 10000);

    }

    function claimFee(address token) public onlyOwner {
        uint256 balance = 0;
        if (token == address(0)) {
            balance = address(this).balance;
            require(balance > 0);
            TransferHelper.safeTransferETH(msg.sender, balance);
            emit Claim(msg.sender, address(0), balance);
            return;
        }

        balance = IERC20(token).balanceOf(address(this));
        require(balance > 0);

        TransferHelper.safeTransfer(token, address(msg.sender), balance);

        emit Claim(msg.sender, token, balance);

    }

    function changeFee(uint256 newFee) external onlyOwner {
        paymentRate = newFee;
    }

}