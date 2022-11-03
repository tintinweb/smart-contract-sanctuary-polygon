// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IWofTokens {
    function transfer(address _to, uint256 _value) external;

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;
}

interface ITunnelContract {
    function isOwner(address _address, uint256 id) 
        external 
        returns (bool);
}

contract LeasingContract is Ownable {
    IWofTokens public wofToken;
    ITunnelContract public tunnelContract;

    address public raceContract;
    address public garageContract;

    address public creator;

    constructor(
        address _wofToken,
        address _tunnelContract,
        address _raceContract,
        address _garageContract
    ){
        wofToken = IWofTokens(_wofToken);
        tunnelContract = ITunnelContract(_tunnelContract);
        raceContract = _raceContract;
        garageContract = _garageContract;
        creator = msg.sender;
    }

    function setRaceContract(address _raceContract) public onlyOwner {
        raceContract = _raceContract;
    }
    
    function setGarageContract(address _garageContract) public onlyOwner {
        garageContract = _garageContract;
    }

    function setTunnelContract(address _tunnelContract) public onlyOwner {
        tunnelContract = ITunnelContract(_tunnelContract);
    }

    function setTokenContract(address _wofToken) public onlyOwner {
        wofToken = IWofTokens(_wofToken);
    }

    //Lease Type = 1 for Fixed race amount leases , 2 for Deadline based Lease
    //Payment Type = 1 for percentage from winnings, 2 fixed cost Lease, 3 hybrid
    struct Lease {
        address owner;
        address leaser;
        bool isLeased;
        bool directLease;
        uint256 leaseDuration; // If lease type is 2, this is the duration of the lease in seconds (for listings only)
        uint256 leaseStart; //If lease type is 2, this is the start time to be leased (30 days for listing, block time for leases)
        uint256 leaseEnd; //If lease type is 2, this is the end time to be leased (block time + duration, calculated on lease)
        uint256 leaseType;
        uint256 paymentType;
        uint256 paymentAmount;
        uint256 winShare;
        uint256 raceAmount;
        uint256 maxRaces;
    }

    //TokenID - LeaseID - Lease data
    mapping(uint256 => mapping(uint256 => Lease)) public leaseRules;
    mapping(uint256 => mapping(uint256 => Lease)) public leaseHistory;

    mapping(uint256 => uint256) public latestLeaseID;
    mapping(address => bool) public allowDirect;

    function useInRace(uint256 _tokenID) external {
        require(msg.sender == raceContract, "Not permitted");
        uint256 leaseID = getLeaseID(_tokenID);
        leaseHistory[_tokenID][leaseID].raceAmount += 1;
        if (
            leaseHistory[_tokenID][leaseID].raceAmount >=
            leaseHistory[_tokenID][leaseID].maxRaces
        ) {
            leaseHistory[_tokenID][leaseID].isLeased = false; 

        }
    }

    function getLeaseID(uint256 _tokenID) public view returns (uint256) {
        return latestLeaseID[_tokenID];
    }

    function isTokenAvailableForLease(uint256 _tokenID)
        public
        view
        returns (bool)
    {
        bool available = true;
        uint256 leaseID = getLeaseID(_tokenID);
        if (leaseRules[_tokenID][leaseID].leaseType == 0) {
            available = false;
        }

        if (leaseRules[_tokenID][leaseID].isLeased == false) {
            available = false;
        }
        if (
            leaseRules[_tokenID][leaseID].leaseType == 2 &&
            leaseRules[_tokenID][leaseID].leaseStart + 30 days < block.timestamp
        ) {
            available = false;
        }
        return available;
    }

    function isTokenLeased(uint256 _tokenID)
        public
        view
        returns (
            bool, // Has the vehicle ever been leased
            bool, // Is it leased at the moment
            uint256, // Lease ID
            address //  Leaser address
        )
    {
        uint256 leaseID = getLeaseID(_tokenID);
        if (leaseHistory[_tokenID][leaseID].isLeased == true) {
            return (true, true, leaseID, leaseHistory[_tokenID][leaseID].leaser);
        } else if (leaseHistory[_tokenID][leaseID].isLeased == false) {
            return (true, false, leaseID, address(0));
        } else {
            return (false, false, 0, address(0));
        }
    }

    function getLeaseData(uint256 _tokenID, uint256 _leaseID)
        public
        view
        returns (
        address,
        address,        
        uint256,
        uint256,
        uint256,
        uint256) 
    {
        require(leaseHistory[_tokenID][_leaseID].isLeased == true, "No lease found");  
        return (
            leaseHistory[_tokenID][_leaseID].owner,
            leaseHistory[_tokenID][_leaseID].leaser,
            leaseHistory[_tokenID][_leaseID].leaseType,
            leaseHistory[_tokenID][_leaseID].paymentType,
            leaseHistory[_tokenID][_leaseID].paymentAmount,
            leaseHistory[_tokenID][_leaseID].winShare
        );
            
    }

    function addForLeasing(
        uint256 _leaseID,
        uint256 _tokenID,
        uint256 _leaseType,
        uint256 _paymentType,
        uint256 _paymentAmount,
        uint256 _winShare,
        uint256 _leaseDuration,
        uint256 _maxRaces,
        bool _directLease,
        address _leaser
    ) public {
        
        require(tunnelContract.isOwner(msg.sender, _tokenID), "Not permitted");
        bool isLeased;
        (,isLeased,,) = isTokenLeased(_tokenID);
        require(isLeased == false, "Token currently leased");
        leaseRules[_tokenID][_leaseID].owner = msg.sender;
        leaseRules[_tokenID][_leaseID].isLeased = true;
        latestLeaseID[_tokenID] = _leaseID;
        leaseRules[_tokenID][_leaseID].leaseType = _leaseType;
        leaseRules[_tokenID][_leaseID].leaseStart = block.timestamp;
        leaseRules[_tokenID][_leaseID].maxRaces = _maxRaces;
        if (_leaseType == 2) {
            leaseRules[_tokenID][_leaseID].leaseDuration = _leaseDuration;
        }
        
        leaseRules[_tokenID][_leaseID].paymentType = _paymentType;
        if (_paymentType == 1) {
            leaseRules[_tokenID][_leaseID].winShare = _winShare;
        } else if (_paymentType == 2) {
            leaseRules[_tokenID][_leaseID].paymentAmount = _paymentAmount;
        } else if (_paymentType == 3) {
            leaseRules[_tokenID][_leaseID].winShare = _winShare;
            leaseRules[_tokenID][_leaseID].paymentAmount = _paymentAmount;
        }
        if (_directLease == true) {
            require(allowDirect[_leaser] == true, "Direct lease not allowed");
            leaseRules[_tokenID][_leaseID].directLease = _directLease;
            leaseVehicle(_tokenID, _leaser);
        }
  
    }

    function removeFromLease(uint256 _tokenID, uint256 _leaseID) public {
        if (leaseRules[_tokenID][_leaseID].owner == msg.sender || creator == msg.sender) {
            leaseRules[_tokenID][_leaseID].isLeased = false;
        } else {
            revert("Only the owner can remove the lease");
        }
    }

    function endLease(uint256 _tokenID, uint256 _leaseID) public {
        if (leaseRules[_tokenID][_leaseID].owner == msg.sender) {
            
            if (
                leaseRules[_tokenID][_leaseID].paymentType == 2 ||
                leaseRules[_tokenID][_leaseID].paymentType == 3
            ) {
                uint256 paymentAmount = (leaseRules[_tokenID][_leaseID].paymentAmount * 95) / 100;
                wofToken.transferFrom(
                    msg.sender,
                    leaseHistory[_tokenID][_leaseID].leaser, 
                    paymentAmount
                );
            }

            leaseHistory[_tokenID][_leaseID].isLeased = false;
        } else if (creator == msg.sender) {
            leaseHistory[_tokenID][_leaseID].isLeased = false;
        } else {
            revert("Only the owner can remove the lease");
        }
    }

    function checkLeaseTime(uint256 _tokenID, uint256 _leaseID) public {
        require(
            leaseHistory[_tokenID][_leaseID].leaseEnd < block.timestamp,
            "Lease has not ended"
        ); 
        leaseHistory[_tokenID][_leaseID].isLeased = false;
    }

    function allowDirectLeases() public {
        allowDirect[msg.sender] = true;
    }

    function denyDirectLeases() public {
        allowDirect[msg.sender] = false;
    }


    function leaseVehicle(uint256 _tokenID, address _leaser) public {
        uint256 leaseID = getLeaseID(_tokenID);
        require(
            isTokenAvailableForLease(_tokenID) == true,
            "Token is not available for lease"
        );
        if (leaseRules[_tokenID][leaseID].directLease == true) {
            leaseRules[_tokenID][leaseID].leaser = _leaser;
        } else {
            if (msg.sender == leaseRules[_tokenID][leaseID].owner) {
                revert ("Cannot lease your own vehicle");
            }
            leaseRules[_tokenID][leaseID].leaser = msg.sender;
        }
   
        leaseRules[_tokenID][leaseID].isLeased = true;

        if (
            leaseRules[_tokenID][leaseID].paymentType == 2 ||
            leaseRules[_tokenID][leaseID].paymentType == 3
        ) {

            uint256 paymentAmount = (leaseRules[_tokenID][leaseID].paymentAmount * 95) / 100;
            if (leaseRules[_tokenID][leaseID].directLease == false) {

                wofToken.transferFrom(
                    msg.sender,
                    leaseRules[_tokenID][leaseID].owner,
                    paymentAmount
                );

                wofToken.transferFrom(
                    msg.sender,
                    address(garageContract),
                    leaseRules[_tokenID][leaseID].paymentAmount - paymentAmount
                );
            } else {
                wofToken.transferFrom(
                    _leaser,
                    leaseRules[_tokenID][leaseID].owner,
                    paymentAmount
                );

                wofToken.transferFrom(
                    _leaser,
                    address(garageContract),
                    leaseRules[_tokenID][leaseID].paymentAmount - paymentAmount
                );
            }

        } 

        //TODO - figure out the index for this mapping, initially the same leaseID works. But if may have issues with multiple leases on the same token if conditions do not change.
        leaseHistory[_tokenID][leaseID] = leaseRules[_tokenID][leaseID];
        if (leaseHistory[_tokenID][leaseID].leaseType == 2) {
            leaseHistory[_tokenID][leaseID].leaseStart = block.timestamp;
            leaseHistory[_tokenID][leaseID].leaseEnd = block.timestamp + leaseHistory[_tokenID][leaseID].leaseDuration;
        }

    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}