/**
 *Submitted for verification at polygonscan.com on 2022-07-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title Devoleum
/// @author Lorenzo Zaccagnini Elisa Romondia
/// @notice You can use this contract for your JSONs notarization
/// @dev All function calls are currently implemented without side effects
contract Devoleum {
    address public owner;
    address public prev_sc;

    constructor(address _prev_sc) {
        owner = msg.sender;
        prev_sc = _prev_sc;
    }

    mapping(bytes32 => uint256) public hashToDate;
    mapping(address => bool) public allowed;

    //Modifiers
    modifier noDuplicate(bytes32 _hashOfJson) {
        require(hashToDate[_hashOfJson] == 0, "duplicate");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyAllowed() {
        require(allowed[msg.sender] || msg.sender == owner, "Only allowed");
        _;
    }

    event StepProofCreated(bytes32 _hashOfJson, uint256 _createdAt);

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    /// @notice Toggle allowed address
    /// @param _address Address to toggle
    function toggleAllowed(address _address) external onlyOwner {
        allowed[_address] = !allowed[_address];
    }

    /// @notice Self Toggle allowed address
    function selfDisableAllowed() external {
        require(allowed[msg.sender], "Only allowed");
        allowed[msg.sender] = false;
    }

    /// @notice Notarizes a supply chain Step Proof
    /// @param _hashOfJson The hash proof of the JSON file
    /// @return _createdAt The numeric timestamp of the notarization
    function createStepProof(bytes32 _hashOfJson)
        external
        onlyAllowed
        noDuplicate(_hashOfJson)
        returns (uint256 _createdAt)
    {
        uint256 nowDate = block.timestamp;
        hashToDate[_hashOfJson] = nowDate;
        emit StepProofCreated(_hashOfJson, nowDate);
        return hashToDate[_hashOfJson];
    }
}