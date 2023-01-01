pragma solidity ^0.8.9;

// Interface for validating proposals
interface IProposalValidator {
    function validate(
        address proposerAddress,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external view returns (bool);
}

//TODO: you probably should implement ERC165
contract DefaultProposalValidator is IProposalValidator {
    function validate(
        address /*proposerAddress*/,
        address[] memory /*targets*/,
        uint256[] memory /*values*/,
        bytes[] memory /*calldatas*/,
        string memory /*description*/
    ) external virtual view returns (bool) {
        return false;
    }
}