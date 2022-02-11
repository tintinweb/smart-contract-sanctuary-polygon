/**
 *Submitted for verification at polygonscan.com on 2022-02-06
*/

// File: Subsidy.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}


contract Subsidy is KeeperCompatibleInterface {
    //Owner of the contract
    address payable private owner;
    //Payments will be made to this address
    address payable public beneficiary;
    //Store the beneficiary here until approved by owner
    address payable private pendingBeneficiary;
    //Time interval between payments
    uint256 public immutable interval;
    //Amount to be paid to beneficiary
    uint256 private immutable amount;
    //Last payment time
    uint256 public lastTimeStamp;

    /* ---------- Modifiers ---------- */
    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    modifier hasBeneficiary() {
        require(beneficiary != address(0));
        _;
    }

    modifier hasPendingBeneficiary() {
        require(pendingBeneficiary != address(0));
        _;
    }

    modifier noPendingBeneficiary() {
        require(pendingBeneficiary == address(0));
        _;
    }

    /* ---------- Constructor ---------- */
    constructor(uint256 subsidy) {
        owner = payable(address(msg.sender));
        interval = 5 minutes;
        amount = subsidy;
        lastTimeStamp = block.timestamp;
    }

    //Check contract balance
    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    //Owner can withdraw everything
    function withdraw() public restricted {
        owner.transfer(address(this).balance);
    }

    //Register as pending beneficiary
    function registerBeneficiary() public noPendingBeneficiary {
        pendingBeneficiary = payable(address(msg.sender));
    }

    //Approve pending beneficiary. Must be called by owner.
    function approveBeneficiary() public restricted hasPendingBeneficiary {
        beneficiary = pendingBeneficiary;
        pendingBeneficiary = payable(address(0));
    }

    //Deposit amount to be paid as subsidy
    function depositSubsidy() public payable restricted {}

    //Called by Chainlink Keepers to check if work needs to be done
    function checkUpkeep(
        bytes calldata /*checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (beneficiary != address(0)) && (block.timestamp - lastTimeStamp) > interval;
        return (upkeepNeeded, bytes(""));
    }

    //Called by Chainlink Keepers to handle work
    function performUpkeep(bytes calldata) external override {
        lastTimeStamp = block.timestamp;
        require(address(this).balance > amount);
        beneficiary.transfer(amount);
    }
}