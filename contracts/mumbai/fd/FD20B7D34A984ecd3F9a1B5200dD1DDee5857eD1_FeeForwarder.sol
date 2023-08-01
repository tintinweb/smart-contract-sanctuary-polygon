// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IAutomate} from "./vendor/IAutomate.sol";

contract FeeForwarder {
    IAutomate public automate;

    constructor(address _automate) {
        automate = IAutomate(_automate);
    }

    function transfer(address payable target, uint256 amount) external {
        //(uint256 fee,) = automate.getFeeDetails();
        //_transfer(automate.gelato(), fee);

        _transfer(target, amount);

        uint256 refund = address(this).balance;
        _transfer(payable(msg.sender), refund);
    }

    function getBalances(
        address[] calldata targets
    ) external view returns (uint256[] memory balances) {
        balances = new uint256[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++)
            balances[i] = targets[i].balance;
    }

    function _transfer(address payable to, uint256 amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "FeeForwarder._transfer: transfer failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IAutomate {
    function getFeeDetails() external view returns (uint256, address);
    function gelato() external view returns (address payable);
}