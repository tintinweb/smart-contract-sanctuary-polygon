// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @author Simon Samuel
 */

contract Register {
    address public owner;
    uint256 public MIN_AMOUNT = 0.1 ether;

    struct kin {
        address kinAddress; // The Contract address of the next of kin.
        uint256 kinAmount; // The deposited amount to be sent to the next of kin.
        uint256 interval; // The interval for before requestion for a validation of life from the user.
        bool validationOfLife; // This checks to see if the user is still alive.
        uint16 maxNumberOfConfirmations; // Sets the max number of times the user can validate life. Defaults to 5 if input exceeds 5
        uint16 currNumberOfConfirmations; // Will send kinAmount to kinAddress if this == maxNumberOfConfirmations
    }

    mapping(address => kin) kinship;
    address[] public users;

    event registered(string message, uint256 when);
    event validatedLife(string message, uint256 when);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyUsers(address _user) {
        bool found = false;

        for (uint8 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                found = true;
            }
        }
        require(found, "User is not registered!");
        _;
    }

    /**
     * @param _kinAddress Contract Address of the Next of Kin that receives the deposited tokens.
     * @param _interval Specifies the interval between each validation of life, (Month or Hourly).
     * @param _maxNumberOfConfirmations Contract will transfer funds to kin if currNumberOfConfirmations == MaxNumberOfConfirmations.
     *
     */
    function register(
        address _kinAddress,
        uint256 _interval,
        uint8 _maxNumberOfConfirmations
    ) public payable {
        require(
            msg.value >= MIN_AMOUNT,
            "You have to send a minimum of 0.1 MATIC."
        );

        // TODO: Calls a signing function [Signature]

        // Populates kinship

        kinship[msg.sender].kinAddress = _kinAddress;
        kinship[msg.sender].interval = _interval;
        kinship[msg.sender].kinAmount = msg.value;

        kinship[msg.sender].currNumberOfConfirmations = 0;
        kinship[msg.sender].validationOfLife = true;
        if (_maxNumberOfConfirmations < 5) {
            kinship[msg.sender]
                .maxNumberOfConfirmations = _maxNumberOfConfirmations;
        } else {
            kinship[msg.sender].maxNumberOfConfirmations = 5;
        }

        users.push(msg.sender);

        emit registered("Successfully registered", block.timestamp);
    }

    function validateLife() public onlyUsers(msg.sender) {
        kinship[msg.sender].currNumberOfConfirmations = 0;
        emit validatedLife(
            "Validated life and reset confirmations to 0",
            block.timestamp
        );
    }

    function missedLifeValidation(address _user) public onlyUsers(_user) {
        kinship[_user].currNumberOfConfirmations++;
        if (
            kinship[_user].currNumberOfConfirmations ==
            kinship[_user].maxNumberOfConfirmations
        ) {
            kinship[_user].validationOfLife = false;
        }
    }

    function getValidationStatus(address _user)
        public
        view
        onlyUsers(_user)
        returns (bool)
    {
        return kinship[_user].validationOfLife;
    }

    function getKinInfo(address _user)
        public
        view
        onlyUsers(_user)
        returns (address, uint256)
    {
        return (kinship[_user].kinAddress, kinship[_user].kinAmount);
    }
}