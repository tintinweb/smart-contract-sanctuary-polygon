// SPDX-License-Identifier: MIT
import "RainfallPolicy.sol";

pragma solidity ^0.8.0;

/**
 * @title Manager
 * @dev Contract with the logic of execution for the given policies
 */
contract Manager {
    // Ownwer of the contrac
    address public owner;

    // Insured ID as string
    mapping(string => RainfallPolicy[]) public policiesByInsured;

    // Only the ownwer of the contrac can execute this
    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Only the address that deployed the contract."
        );
        _;
    }

    constructor() {
        // Set the owner as the addres thath deployed the contrct
        owner = msg.sender;
    }

    /**
     * @dev Create a new policy
     * @return bool
     */
    function createPolicy(
        string memory _description,
        uint8 _rainMMRequired,
        string memory insured
    ) public onlyOwner returns (bool) {
        RainfallPolicy p = new RainfallPolicy(
            _description,
            _rainMMRequired,
            insured
        );
        policiesByInsured[insured].push(p);
        return true;
    }

    function checkPaidAction(
        string memory insured,
        uint8 _actualRainMM,
        uint256 index
    ) public onlyOwner returns (string memory) {
        bool paidAction = policiesByInsured[insured][index].checkRainMM(
            _actualRainMM
        );
        require(paidAction, "Not ready to be paid.");
        policiesByInsured[insured][index].setPolicyToPaid();
        return "Should paid.";
    }

    /**
     * @dev Looks for the description of a policy in the given index
     * @return string with description
     */
    function getDescription(string memory insured, uint256 index)
        public
        view
        returns (string memory)
    {
        return policiesByInsured[insured][index].description();
    }

    /**
     * @dev Looks for the status of a policy in the given index
     * @return uint (0 = active, 1 = expired, 2 = paid)
     */
    function getStatus(string memory insured, uint256 index)
        public
        view
        returns (uint8)
    {
        return uint8(policiesByInsured[insured][index].status());
    }
}