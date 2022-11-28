/**
 *Submitted for verification at polygonscan.com on 2022-11-27
*/

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/ZakatBasic.sol

pragma solidity 0.6.6;

contract ZakatBasic is BasicAccessControl {
    struct ZakatRecord {
        uint256 amount;
        bool doner;
        uint256 recievedAt;
    }

    struct ZakatApproval {
        uint256 requestID;
        bool doner;
    }

    struct ZakatEligible {
        uint256 amount;
        bool eligible;
        bool doner;
        Duration duration;
    }

    enum Duration {
        Every_Month,
        Half_A_Year,
        Every_Year
    }

    uint256 public decimal = 18;

    function setDecimal(uint256 _decimal) external onlyOwner {
        decimal = _decimal;
    }

    event Withdraw(address _from, address _to, uint256 _amount);
    event Deposite(address _from, address _to, uint256 _amount);
}

// File: contracts/ZakatData.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

contract ZakatData is ZakatBasic {
    mapping(address => ZakatEligible) eligible;

    function setEligible(
        address _person,
        uint256 _amount,
        bool _eligible,
        bool _doner,
        Duration _duration
    ) external onlyModerators {
        uint256 duration = uint256(_duration);
        require(duration >= 0 && duration < 3, "Invalid emum value.");
        ZakatEligible storage zktEligible = eligible[_person];
        zktEligible.amount = _amount;
        zktEligible.eligible = _eligible;
        zktEligible.doner = _doner;
        zktEligible.duration = _duration;
    }

    function getEligible(address _doner)
        public
        view
        returns (ZakatEligible memory)
    {
        return eligible[_doner];
    }

    function removeEligible(address _person) external onlyModerators {
        delete eligible[_person];
    }
}