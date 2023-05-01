// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

/**
 * ░█▀█░█▀█░█▄█░█▀▀░█▀▀░█▀█░█▀█░█▀▀░█▀▀
 * ░█░█░█▀█░█░█░█▀▀░▀▀█░█▀▀░█▀█░█░░░█▀▀
 * ░▀░▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
 *
 * @title Namespace Interface
 * @author raldblox.eth (github.com/raldblox)
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of the Namespace.
 */
interface INamespace {
    function version() external pure returns (string memory);

    function createNamespace(string memory, address, bool) external payable;

    function getNamespace(address) external view returns (string memory);

    function getNamespaceAddress(string memory) external view returns (address);
}

/**
 * ░█▀█░█▀█░█▄█░█▀▀░█▀▀░█▀█░█▀█░█▀▀░█▀▀
 * ░█░█░█▀█░█░█░█▀▀░▀▀█░█▀▀░█▀█░█░░░█▀▀
 * ░▀░▀░▀░▀░▀░▀░▀▀▀░▀▀▀░▀░░░▀░▀░▀▀▀░▀▀▀
 *
 * @title Project Namespace
 * @author raldblox.eth (github.com/raldblox)
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./INamespace.sol";

/**
 * @title Namespace
 * @dev Set addresses to human-readable names
 */
contract Namespace is INamespace {
    using SafeMath for uint256;
    address private owner;

    struct NamespaceData {
        address namedBy;
        string name;
        bool isOrganization;
        address[] members;
    }

    mapping(address => NamespaceData) private namespaces;
    mapping(string => address) private namespaceAddresses;
    mapping(address => uint256) private shareFees;

    bool internal locked;
    address private admin;
    uint256 private nameFee;

    event NewNamespace(
        address indexed namespacedAddress,
        string indexed namespace,
        address indexed namedBy,
        uint256 epoch
    );

    event NamespaceUpdated(
        address indexed namespaceAddress,
        address indexed member,
        bool isOrganization,
        uint256 epoch
    );

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    receive() external payable {}

    function version() external pure returns (string memory) {
        return "Namespace v1.0";
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "New admin address cannot be zero");
        admin = newAdmin;
    }

    /**
     * @dev Adjust processing fee
     */
    function newNamingFee(uint256 _value) external onlyAdmin {
        nameFee = _value;
    }

    function newShareFee(address addr, uint256 _value) external onlyAdmin {
        require(50 >= _value, "Sharing fees must not be greater than 50%");
        shareFees[addr] = _value;
    }

    function createNamespace(
        string memory name,
        address addr,
        bool isOrganization
    ) public payable override {
        require(bytes(name).length > 0, "Namespace name must not be empty");
        require(
            namespaceAddresses[name] == address(0),
            "Namespace name already exists"
        );
        if (msg.sender != admin) {
            require(nameFee >= msg.value, "Naming fee not met");
        }

        namespaces[addr] = NamespaceData({
            namedBy: msg.sender,
            name: name,
            isOrganization: isOrganization,
            members: new address[](0)
        });
        namespaceAddresses[name] = msg.sender;
        emit NewNamespace(addr, name, msg.sender, block.timestamp);
    }

    function updateNamespace(
        string memory name,
        address addr,
        bool isOrganization
    ) public payable {
        require(bytes(name).length > 0, "Namespace name must not be empty");
        require(
            namespaceAddresses[name] == address(0),
            "Namespace name already exists"
        );
        if (msg.sender != admin) {
            require(nameFee >= msg.value, "Naming fee not met");
        }
        string memory current = namespaces[addr].name;
        namespaces[addr] = NamespaceData({
            namedBy: msg.sender,
            name: name,
            isOrganization: isOrganization,
            members: new address[](0)
        });
        namespaceAddresses[current] = address(0);
        namespaceAddresses[name] = msg.sender;
        emit NewNamespace(addr, name, msg.sender, block.timestamp);
    }

    function addNamespaceMember(
        address namespaceAddress,
        address member,
        string memory name,
        bool isOrganization
    ) public payable onlyAdmin {
        require(
            namespaceAddress != address(0),
            "Namespace address must not be empty"
        );
        require(member != address(0), "Member address must not be empty");
        require(bytes(name).length > 0, "Namespace name must not be empty");
        require(
            namespaceAddresses[name] == address(0),
            "Namespace name already exists"
        );
        if (msg.sender != admin) {
            require(nameFee >= msg.value, "Naming fee not met");

            uint256 sentToOrg = msg.value.mul(shareFees[namespaceAddress]).div(
                100
            );
            (bool sent, ) = payable(namespaceAddress).call{value: sentToOrg}(
                ""
            );
            require(sent, "Failed to send");
        }

        namespaces[member] = NamespaceData({
            namedBy: msg.sender,
            name: name,
            isOrganization: isOrganization,
            members: new address[](0)
        });

        namespaceAddresses[name] = member;

        emit NewNamespace(member, name, msg.sender, block.timestamp);

        namespaces[namespaceAddress].members.push(member);

        emit NamespaceUpdated(
            namespaceAddress,
            member,
            namespaces[namespaceAddress].isOrganization,
            block.timestamp
        );
    }

    function setNamespaceIsOrganization(
        address namespaceAddress,
        bool isOrganization
    ) public onlyAdmin {
        require(
            namespaceAddress != address(0),
            "Namespace address must not be empty"
        );

        namespaces[namespaceAddress].isOrganization = isOrganization;

        emit NamespaceUpdated(
            namespaceAddress,
            address(0),
            isOrganization,
            block.timestamp
        );
    }

    function removeNamespaceMember(
        address namespaceAddress,
        address member
    ) public onlyAdmin {
        require(
            namespaceAddress != address(0),
            "Namespace address must not be empty"
        );
        require(member != address(0), "Member address must not be empty");

        address[] storage members = namespaces[namespaceAddress].members;

        for (uint i = 0; i < members.length; i++) {
            if (members[i] == member) {
                members[i] = members[members.length - 1];
                members.pop();
                break;
            }
        }

        emit NamespaceUpdated(
            namespaceAddress,
            member,
            namespaces[namespaceAddress].isOrganization,
            block.timestamp
        );
    }

    function getAllMemberAddresses(
        string memory namespace
    ) public view returns (address[] memory) {
        address namespaceAddress = namespaceAddresses[namespace];
        require(namespaceAddress != address(0), "Namespace does not exist");
        return namespaces[namespaceAddress].members;
    }

    function getNamespace(address account) public view returns (string memory) {
        return namespaces[account].name;
    }

    function getNamespaceAddress(
        string memory name
    ) public view returns (address) {
        return namespaceAddresses[name];
    }

    function isNamespaceMember(
        address namespaceAddress,
        address member
    ) public view returns (bool) {
        require(
            namespaceAddress != address(0),
            "Namespace address must not be empty"
        );
        require(member != address(0), "Member address must not be empty");

        address[] memory members = namespaces[namespaceAddress].members;

        for (uint i = 0; i < members.length; i++) {
            if (members[i] == member) {
                return true;
            }
        }

        return false;
    }

    /****** HELPERS ******/

    function recover() external onlyAdmin {
        uint256 amount = address(this).balance;
        (bool recovered, ) = admin.call{value: amount}("");
        require(recovered, "Failed to recover.");
    }
}