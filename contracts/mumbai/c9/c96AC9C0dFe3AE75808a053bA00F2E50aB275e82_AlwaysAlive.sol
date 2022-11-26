// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Simon Samuel
 */
contract AlwaysAlive {
    uint256 private lastHourStamp;
    uint256 private lastDayStamp;
    uint256 private lastWeekStamp;

    uint256 public MIN_AMOUNT = 0.001 ether;
    uint8 public MAX_NUMBER_OF_CONFIRMATIONS = 5;

    uint16 private HOURLY_INTERVAL = 60 * 60;
    uint32 private DAILY_INTERVAL = 24 * 60 * 60;
    uint64 private WEEKLY_INTERVAL = 7 * 24 * 60 * 60;

    struct Kin {
        address payable kinAddress;
        uint256 kinAmount;
        bool paidKin;
        bool validationOfLife;
        uint8 currNumberOfConfirmations;
    }

    mapping(address => Kin) kinship;
    address[] public users;

    // Core Events
    event registered(address user, uint256 when);
    event invested(address kin, uint256 when);
    event blessed(address kin, uint256 when);

    // Timed Events
    event incrementedConfirmations(uint256 when);
    event paidDailyProfits(address kin, uint256 when);
    event deposited(address payer, uint256 amount);

    constructor() payable {
        lastHourStamp = block.timestamp;
        lastDayStamp = block.timestamp;
        lastWeekStamp = block.timestamp;
    }

    modifier onlyUsers(address _user) {
        bool activeUser = false;
        for (uint8 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                activeUser = true;
            }
        }
        require(activeUser, "User is not registered!");
        _;
    }

    modifier canRegisterOnlyOnce(address _user) {
        bool alreadyRegistered = false;
        for (uint8 i = 0; i < users.length; i++) {
            if (users[i] == _user) {
                alreadyRegistered = true;
            }
        }
        require(!alreadyRegistered, "Already registered!");
        _;
    }

    modifier kinMustBeAnEOA(address _kin) {
        uint size;
        assembly {
            size := extcodesize(_kin)
        }
        require(size == 0, "Kin Address cannot be a smart contract!");
        _;
    }

    // =====    REGISTRATION SECTION   =====
    /**
     * @param _kinAddress The address of the kin that the contract pays deposited funds to.
     */
    function register(address payable _kinAddress)
        public
        payable
        canRegisterOnlyOnce(msg.sender)
        kinMustBeAnEOA(_kinAddress)
    {
        require(msg.value >= MIN_AMOUNT, "Minimum Registration is 0.1 MATIC");

        kinship[msg.sender].currNumberOfConfirmations = 0;
        kinship[msg.sender].kinAddress = _kinAddress;
        kinship[msg.sender].paidKin = false;
        kinship[msg.sender].validationOfLife = true;
        kinship[msg.sender].kinAmount = msg.value;

        users.push(msg.sender);
        emit registered(msg.sender, block.timestamp);
    }

    // =====    INVESTMENT SECTION     =====
    function invest() public view {
        require(
            (block.timestamp - lastWeekStamp) > WEEKLY_INTERVAL,
            "Not up to a Week!"
        );

        // Sends balance to AAVE and collects profit for the day.
    }

    // =====    BLESSING SECTION       =====
    function bless() public {
        require(
            (block.timestamp - lastDayStamp) > DAILY_INTERVAL,
            "Not up to a Day!"
        );
        for (uint8 i = 0; i < users.length; i++) {
            if (
                kinship[users[i]].validationOfLife == false &&
                kinship[users[i]].paidKin == false
            ) {
                (bool sent, ) = kinship[users[i]].kinAddress.call{
                    value: kinship[users[i]].kinAmount
                }("");
                require(sent, "Failed to send blessings.");
                kinship[users[i]].paidKin = true;
            }
        }
    }

    // =====    HELPERS SECTION        =====
    function validateLife() public onlyUsers(msg.sender) {
        kinship[msg.sender].currNumberOfConfirmations = 0;
    }

    function deposit() public payable {
        emit deposited(msg.sender, msg.value);
    }

    function incrementConfirmations() public {
        require(
            (block.timestamp - lastHourStamp) > HOURLY_INTERVAL,
            "Not up to an hour!"
        );

        lastHourStamp = block.timestamp;

        for (uint8 i = 0; i < users.length; i++) {
            kinship[users[i]].currNumberOfConfirmations++;
            if (
                kinship[users[i]].currNumberOfConfirmations >
                MAX_NUMBER_OF_CONFIRMATIONS
            ) {
                kinship[users[i]].validationOfLife = false;
            }
        }

        emit incrementedConfirmations(block.timestamp);
    }

    function getCurrentConfirmations(address _user)
        public
        view
        onlyUsers(_user)
        returns (uint8)
    {
        return kinship[_user].currNumberOfConfirmations;
    }

    receive() external payable {
        emit deposited(msg.sender, msg.value);
    }

    fallback() external payable {
        emit deposited(msg.sender, msg.value);
    }
}