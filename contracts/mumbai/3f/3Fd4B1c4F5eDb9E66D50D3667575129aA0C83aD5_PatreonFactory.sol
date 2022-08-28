//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Patreon.sol";

contract PatreonFactory {
    address[] public deployedPatreons;

    function createPatreon(uint256 _membershipCharges) public {
        Patreon newPatreon = new Patreon(_membershipCharges);

        deployedPatreons.push(address(newPatreon));
    }

    function getDeployedPatreon() public view returns (address[] memory) {
        return deployedPatreons;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Patreon {
    error ContractCalling();
    error TransactionFailed();

    uint public contributors;
    address public manager;
    address[] public members;
    uint256 patreonMembershipCharges;

    constructor(uint256 _membershipCharges) {
        manager = msg.sender;
        patreonMembershipCharges = _membershipCharges;
    }

    function subscribe() external payable {
        if (tx.origin != msg.sender) {
            revert ContractCalling();
        }
        (
            bool sent, /*memory data*/

        ) = manager.call{value: (msg.value * 975) / 1000}("");

        if (!sent) {
            revert TransactionFailed();
        }

        contributors = contributors + 1;
        members.push(msg.sender);
    }

    //    function destroy() public {
    //         require(msg.sender == manager);
    //         selfdestruct(manager);
    //     }

    function getInfo()
        public
        view
        returns (
            address[] memory,
            uint256,
            uint256,
            address
        )
    {
        return (members, patreonMembershipCharges, contributors, manager);
    }
}