// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author: Trinity-Legents
import "@openzeppelin/contracts/utils/Strings.sol";


interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    
}
 
contract Casino {
    using Strings for uint256;
    address owner;
    bool isActive = true;
    uint256 public coinPrice = 1;

    struct UserData {
        string name;
        string username;
    }

    /*
     * Public Variables
     */
    // uint256 public env = 0; /* 0 - Dev | 1 - Prod */

    mapping(address => uint256) public userBalance;
    mapping(address => bool) public moderatorAddresses;
    mapping(address => bool) public blackListAddresses;
    mapping(address => bool) public adminAddresses;

    event topupAccount(address _to, uint _amount);
    /*
     * Constructor
     */
    constructor() {
        owner = msg.sender;
    }

    // ======================================================== Getters Functions
    function getBalanceOfUser(address _addressOfUser) public view returns (uint256){
        return userBalance[_addressOfUser];
    }

    function getTokenPrice()  public view returns (uint256){
        return coinPrice;
    }

    // ======================================================== Owner Functions

    function setActiveStatus(bool active)
        external
        onlyAdmin(msg.sender)
    {
        isActive = active;
    }

    function addFundsToUsersBalance(address _addressOfUser, uint256 amount)
        public
        onlyAdmin(msg.sender)
    {
        userBalance[_addressOfUser] += amount;
        emit topupAccount(_addressOfUser, amount);
    }

    function removeFundsFromUsersBalance(address _addressOfUser, uint256 amount)
        external
        onlyAdmin(msg.sender)
    {
        userBalance[_addressOfUser] -= amount;
    }

    function addToBlackList(address _addressToBlackList)
        external
        onlyModerator(msg.sender)
    {
        blackListAddresses[_addressToBlackList] = true;
    }

    function removeFromBlackList(address _addressToBlackList)
        external
        onlyModerator(msg.sender)
    {
        blackListAddresses[_addressToBlackList] = false;
    }

    function addToAdminList(address _addressOfAdmin) external ownerOnly {
        adminAddresses[_addressOfAdmin] = true;
    }

    function removeFromAdminList(address _addressOfAdmin) external ownerOnly {
        adminAddresses[_addressOfAdmin] = false;
    }

    function addToModeratorList(address _addressOfModerator)
        external
        ownerOnly
    {
        moderatorAddresses[_addressOfModerator] = true;
    }

    function removeFromModeratorList(address _addressOfModerator)
        external
        ownerOnly
    {
        moderatorAddresses[_addressOfModerator] = false;
    }

    function executeRandomizer() public view returns (uint256){
         uint256 random = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.gaslimit, block.timestamp)
            )
        );

        return random % 100000000000000000000000;
    }

    function addCredits(uint numberOfTokens) public payable {
        require(isActive, "We cannot accept your payment at the time being. Please try again later.");
        require((coinPrice * numberOfTokens) < msg.value, "Funds sent are not correct");
        addFundsToUsersBalance(msg.sender, numberOfTokens);
    }



    function sendUSDT(address _to, uint256 _amount) private{
         // This is the mainnet USDT contract address
         // Using on other networks (rinkeby, local, ...) would fail
         //  - there's no contract on this address on other networks
        IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));
        
        // transfers USDT that belong to your contract to the specified address
        bool success = usdt.transfer(_to, _amount);
        require(success, "Transfer failed.");
    }

    /// Disburse payments
    /// @dev transfers amounts that correspond to addresses passeed in as args
    /// @param payees_ recipient addresses
    /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disburseUSDT(
        address[] memory payees_,
        uint256[] memory amounts_
    ) external ownerOnly {
        require(
            payees_.length == amounts_.length,
            "Payees and amounts length mismatch"
        );
        for (uint256 i; i < payees_.length; i++) {
            sendUSDT(payees_[i], amounts_[i]);
        }
    }

    /// Disburse payments
    /// @dev transfers amounts that correspond to addresses passeed in as args
    /// @param payees_ recipient addresses
    /// @param amounts_ amount to payout to address with corresponding index in the `payees_` array
    function disbursePayments(
        address[] memory payees_,
        uint256[] memory amounts_
    ) external ownerOnly {
        require(
            payees_.length == amounts_.length,
            "Payees and amounts length mismatch"
        );
        for (uint256 i; i < payees_.length; i++) {
            makePaymentTo(payees_[i], amounts_[i]);
        }
    }

    /// Make a payment
    /// @dev internal fn called by `disbursePayments` to send Ether to an address
    function makePaymentTo(address address_, uint256 amt_) private {
        (bool success, ) = address_.call{value: amt_}("");
        require(success, "Transfer failed.");
    }

    modifier onlyAdmin(address _addressToCheck) {
        require(
            (adminAddresses[_addressToCheck] == true) ||
                owner == _addressToCheck,
            "Only admins can call this function"
        );
        _;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerator(address _addressToCheck) {
        require(
            (moderatorAddresses[_addressToCheck] == true) ||
                (adminAddresses[_addressToCheck] == true) ||
                owner == _addressToCheck,
            "Only moderators can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}