// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract simpleBank {
    mapping(address => uint256) public balances;
    address public bankOwner;

    event AmountWithdrawn(
        address  depositer,
        address  contractaddress,
        uint256  money,
        uint256 timestamp
    );
    event AmountDeposited(
        address  depositer,
        address  contractaddress,
        uint256  money,
        uint256 timestamp
    );

    constructor() {
        bankOwner = msg.sender;
    }

    modifier onlyBankOwner() {
        require(
            msg.sender == bankOwner
        );
        _;
    }

    //To check total contract Balance
    function checkEther() external view onlyBankOwner returns (uint256) {
        return address(this).balance;
    }

    //Deposit ether
    function depositEther() external payable {
        balances[msg.sender] += msg.value;
        emit AmountDeposited(
            msg.sender,
            address(this),
            msg.value,
            block.timestamp
        );
    }

    //Withdraw ether
    function withdrawEther(uint256 _amount) external payable {
        require(
            _amount <= balances[msg.sender],
            "Amount should be less than Owner Balance"
        );
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        emit AmountWithdrawn(
            msg.sender,
            address(this),
            _amount,
            block.timestamp
        );
    }
}