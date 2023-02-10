pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

// This is just an example of how Future Payment Handler contracts will work
// The idea is that these PaymentHandler's will implement a handlePayment function and will only be called from
// within the erc20 token's pay function

contract PrimeEmissionPaymentHandlerExample {
    address payable public contractOwner;
    address public primeEmissionContractAddress = address(0);
    uint256 public paymentCount = 0;
    bool public paymentsDisabled = false;

    event Payment(
        uint256 _paymentCount,
        address _from,
        uint256 _id,
        uint256 _primeValue
    );

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "owner?");
        _;
    }

    constructor() public {
        contractOwner = payable(msg.sender);
    }

    // send prime and/or eth to the contract, perform additional actions via handler contract
    function handleInvokeSpend(
        address _from,
        address _nativeTokenDestination,
        address _primeDestination,
        uint256 _id,
        uint256 _primeValue,
        uint256 _timestamp,
        bytes memory _data
    ) public {
        require(
            msg.sender == primeEmissionContractAddress,
            "Only callable from token contract"
        );
        paymentCount += 1;
        emit Payment(paymentCount, _from, _id, _primeValue);
    }

    function setEmissionContractAddress(address _newAddr) public onlyOwner {
        primeEmissionContractAddress = _newAddr;
    }

    function setPaymentsDisabled(bool _val) public onlyOwner {
        paymentsDisabled = _val;
    }

    function setOwner(address payable _newOwner) public onlyOwner {
        contractOwner = _newOwner;
    }
}