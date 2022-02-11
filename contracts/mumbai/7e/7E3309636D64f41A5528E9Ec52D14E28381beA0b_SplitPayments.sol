pragma solidity 0.7.6;

import "./IMinterUpgradeableFPaymentSplitter.sol";

contract SplitPayments {

    IMinterUpgradeableFPaymentSplitter minter;

    constructor() public {
    }

    function setMinterContract(address _minterAddress) public {
        minter = IMinterUpgradeableFPaymentSplitter(_minterAddress);
    }

    receive() external payable {
        minter.recieveRoyaltyStake{value: address(this).balance}();
    }
    fallback() external payable {
        minter.recieveRoyaltyStake{value: address(this).balance}();
    }
}

pragma solidity ^0.7.6;

interface IMinterUpgradeableFPaymentSplitter {
    function recieveRoyaltyStake() external payable;
}