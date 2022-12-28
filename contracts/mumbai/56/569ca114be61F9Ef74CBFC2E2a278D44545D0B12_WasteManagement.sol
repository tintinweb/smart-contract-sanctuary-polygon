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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Contract to track waste materials across the supply chain
contract WasteManagement {
    using SafeMath for uint;

    // Struct to represent a waste material
    struct WasteMaterial {
        string materialType;
        string category;
        string subCategory;
        uint quantity;
        uint price;
        string vehicleNumber;
        string imageUrl;
        string gpsLocation;
        address assignedRecycler;
        bool recycled;
        address recycledBy;
    }

    // Mapping of waste material IDs to waste materials
    mapping(bytes32 => WasteMaterial) public wasteMaterials;

    // Event to be emitted when a new waste material is added
    event NewWasteMaterial(bytes32 id, string materialType, string category, string subCategory, uint quantity, uint price, string vehicleNumber, string imageUrl, string gpsLocation);

    // Event to be emitted when a waste material is assigned to a recycler
    event WasteMaterialAssigned(bytes32 id, address recycler);

    // Event to be emitted when a waste material is recycled
    event WasteMaterialRecycled(bytes32 id, address recycler);

    // Event to be emitted when a new NFT is minted
    event NewNFTMinted(bytes32 id, address owner);

    // The platform provider
    address public platformProvider;

    // The symbol for the waste asset token
    string public symbol = "WAT";

    // The name of the waste asset token
    string public name = "Waste Asset Token";

    // The number of decimal places for the waste asset token
    uint8 public decimals = 18;

    // The total supply of waste asset tokens
    uint public totalSupply = 1000000000 * (10 ** uint(decimals));

    // The balance of waste asset tokens for each address
    mapping(address => uint) public balances;

    // Constructor function to set the platform provider
    
    constructor(address _platformProvider) public {
        platformProvider = _platformProvider;
        balances[platformProvider] = totalSupply;
    }

    // Add a new waste material to the supply chain
    function addWasteMaterial(string memory materialType, string memory category, string memory subCategory, uint quantity, uint price, string memory vehicleNumber, string memory imageUrl, string memory gpsLocation) public {
        // Generate a unique ID for the waste material
        bytes32 id = keccak256(abi.encodePacked(block.timestamp, materialType, category, subCategory, quantity, price, vehicleNumber, imageUrl));

        // Create a new waste material with the given data
        WasteMaterial storage wasteMaterial = wasteMaterials[id];
        wasteMaterial.materialType = materialType;
        wasteMaterial.category = category;
        wasteMaterial.subCategory = subCategory;
        wasteMaterial.quantity = quantity;
        wasteMaterial.price = price;
        wasteMaterial.vehicleNumber = vehicleNumber;
        wasteMaterial.imageUrl = imageUrl;
        wasteMaterial.gpsLocation = gpsLocation;
        wasteMaterial.assignedRecycler = address(0);
        wasteMaterial.recycled = false;
        wasteMaterial.recycledBy = address(0);

        // Emit an event to notify the participants in the supply chain
        emit NewWasteMaterial(id, materialType, category, subCategory, quantity, price, vehicleNumber, imageUrl, gpsLocation);
    }

    // Assign a waste material to a recycler
    function assignWasteMaterial(bytes32 id, address recycler) public {
        // Only the platform provider can assign waste materials
        require(msg.sender == platformProvider, "Only the platform provider can assign waste materials");

        // Fetch the waste material
        WasteMaterial storage wasteMaterial = wasteMaterials[id];

        // The waste material cannot already be recycled
        require(!wasteMaterial.recycled, "The waste material has already been recycled");

        // Assign the waste material to the recycler
        wasteMaterial.assignedRecycler = recycler;

        // Emit an event to notify the participants in the supply chain
        emit WasteMaterialAssigned(id, recycler);
    }

    // Mark a waste material as recycled
    function recycleWasteMaterial(bytes32 id) public {
        // Fetch the waste material
        WasteMaterial storage wasteMaterial = wasteMaterials[id];

        // Only the assigned recycler can mark a waste material as recycled
        require(msg.sender == wasteMaterial.assignedRecycler, "Only the assigned recycler can mark a waste material as recycled");

        // The waste material cannot already be recycled
        require(!wasteMaterial.recycled, "The waste material has already been recycled");

        // Mark the waste material as recycled
        wasteMaterial.recycled = true;
        wasteMaterial.recycledBy = msg.sender;

        // Mint a new NFT as a proof of recycling
        mint(id, msg.sender);

        // Emit an event to notify the participants in the supply chain
        emit WasteMaterialRecycled(id, msg.sender);
    }

   // Mint a new NFT for a recycled waste material
    function mint(bytes32 id, address owner) public {
    // Only the platform provider can mint NFTs
    require(msg.sender == platformProvider, "Only the platform provider can mint NFTs");

    // Fetch the waste material
    WasteMaterial storage wasteMaterial = wasteMaterials[id];

    // The waste material must have been recycled
    require(wasteMaterial.recycled, "The waste material has not been recycled");

    // Mint the new NFT
    balances[owner] = balances[owner].add(1);

    // Emit an event to notify the participants in the supply chain
    emit NewNFTMinted(id, owner);
}

    // Transfer waste asset tokens from one address to another
function transfer(address recipient, uint amount) public {
    // Check that the sender has enough balance to transfer the specified amount
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // Transfer the specified amount from the sender to the recipient
    balances[msg.sender] = balances[msg.sender].sub(amount);
    balances[recipient] = balances[recipient].add(amount);
}

    // Check the balance of waste asset tokens for a given address
    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }
}