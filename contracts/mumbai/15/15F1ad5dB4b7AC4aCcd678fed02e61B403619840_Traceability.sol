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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Base64 {

    bytes constant private base64stdchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    bytes constant private base64urlchars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_=";
                                            
    function encode(string memory _str) internal pure returns (string memory) {
        uint i = 0;                                 // Counters & runners
        uint j = 0;

        uint padlen = bytes(_str).length;           // Lenght of the input string "padded" to next multiple of 3
        if (padlen%3 != 0) padlen+=(3-(padlen%3));

        bytes memory _bs = bytes(_str);
        bytes memory _ms = new bytes(padlen);       // extra "padded" bytes in _ms are zero by default
        // copy the string
        for (i=0; i<_bs.length; i++) {              // _ms = input string + zero padding
            _ms[i] = _bs[i];
        }
 
        uint res_length = (padlen/3) * 4;           // compute the length of the resulting string = 4/3 of input
        bytes memory res = new bytes(res_length);   // create the result string

        for (i=0; i < padlen; i+=3) {
            uint c0 = uint(uint8(_ms[i])) >> 2;
            uint c1 = (uint(uint8(_ms[i])) & 3) << 4 |  uint(uint8(_ms[i+1])) >> 4;
            uint c2 = (uint(uint8(_ms[i+1])) & 15) << 2 | uint(uint8(_ms[i+2])) >> 6;
            uint c3 = (uint(uint8(_ms[i+2])) & 63);

            res[j]   = base64urlchars[c0];
            res[j+1] = base64urlchars[c1];
            res[j+2] = base64urlchars[c2];
            res[j+3] = base64urlchars[c3];

            j += 4;
        }

        // Adjust trailing empty values
        if ((padlen - bytes(_str).length) >= 1) { res[j-1] = base64urlchars[64];}
        if ((padlen - bytes(_str).length) >= 2) { res[j-2] = base64urlchars[64];}
        return string(res);
    }


    function decode(string memory _str) internal pure returns (string memory) {
        require( (bytes(_str).length % 4) == 0, "Length not multiple of 4");
        bytes memory _bs = bytes(_str);

        uint i = 0;
        uint j = 0;
        uint dec_length = (_bs.length/4) * 3;
        bytes memory dec = new bytes(dec_length);

        for (; i< _bs.length; i+=4 ) {
            (dec[j], dec[j+1], dec[j+2]) = dencode4(
                bytes1(_bs[i]),
                bytes1(_bs[i+1]),
                bytes1(_bs[i+2]),
                bytes1(_bs[i+3])
            );
            j += 3;
        }
        while (dec[--j]==0)
            {}

        bytes memory res = new bytes(j+1);
        for (i=0; i<=j;i++)
            res[i] = dec[i];

        return string(res);
    }


    function dencode4 (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) private pure returns (bytes1 a0, bytes1 a1, bytes1 a2)
    {
        uint pos0 = charpos(b0);
        uint pos1 = charpos(b1);
        uint pos2 = charpos(b2)%64;
        uint pos3 = charpos(b3)%64;

        a0 = bytes1(uint8(( pos0 << 2 | pos1 >> 4 )));
        a1 = bytes1(uint8(( (pos1&15)<<4 | pos2 >> 2)));
        a2 = bytes1(uint8(( (pos2&3)<<6 | pos3 )));
    }

    function charpos(bytes1 char) private pure returns (uint pos) {
        for (; base64urlchars[pos] != char; pos++) 
            {}    //for loop body is not necessary
        require (base64urlchars[pos]==char, "Illegal char in string");
        return pos;
    }

}

// SPDX-License-Identifier: MIT

interface RoleManagement {
   function validateRole(address _address, string memory role) external view returns(bool);
}

// SPDX-License-Identifier: MIT
import "erc721a/contracts/IERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./RoleManagementInterface.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import "./Base64.sol";
import "./Util.sol";

contract Traceability is IERC721A, Ownable {

    struct WorkFlow{
        string Name;
        uint8 TotalStep;
    }

    struct _WorkFlow{
        string Name;
        bytes32 lastStep;
    }

    struct WorkStep{
        string Name;
        string Role;        
        bytes32 previousStep;
    }

    struct WorkStatus{
        address ApproveBy;
        bytes Signature;
        string URL;
        bytes32 DataHash;
        uint BlockNumber;
        bytes32 previousStep;
    }

    struct Tracker{
        uint8 Workflow;  
        address owner;
        bytes32 lastStep;      
    }

    event Log(uint tokenId, address by);

    mapping(uint8 => _WorkFlow) private _workflow;
    mapping(uint => Tracker) private _tracker;

    mapping(bytes32 => WorkStep) private _workstep;
    mapping (bytes32 => WorkStatus) private _workStatus;

    mapping (address=>bool) private _operators;

    modifier onlyOperator() {
        require(_operators[msg.sender] || msg.sender == owner(), "Only Operator");        
        _;
    }

    uint nextTokenId;
    uint totalBurn;
    uint8 private _nextWorkflow;

     // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    RoleManagement roleManagement;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        nextTokenId++;
        _nextWorkflow++;
        totalBurn = 0;
        // _operators[msg.sender] = true;
    }

    function setRoleManagement(address _address) public onlyOwner{
        roleManagement = RoleManagement(_address);
    }

    // constructor(string memory name_, string memory symbol_, address _roleManagement) {
    // }

    function name() external view returns (string memory){
        return _name;
    }

    function symbol() external view returns (string memory){
        return _symbol;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner){
        return _tracker[tokenId].owner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory){
        if(_tracker[tokenId].Workflow == 0x0){
            return Util.base64JSON('{"error": "None exist token"}');
        }
        uint stepIndex;
        WorkFlow memory workflow;
        WorkStep[] memory workstep;
        WorkStatus[] memory logs;
        (stepIndex, workflow, workstep, logs ) = info(tokenId);
        bytes memory temp = bytes("done");
        if(logs.length < workstep.length) temp = bytes("on progress");
        bytes memory res = abi.encodePacked(
            '{"tokenId":', 
            Strings.toString(tokenId),
            ',"Workflow":"',
            workflow.Name, 
            '","status":"',
            temp,
            '","Logs":[' );
        string memory prefix;        
        for(uint i = 0; i < workstep.length; i++ ){
            if(i>0) prefix = ",";
            temp = abi.encodePacked(prefix, '{"Step":"',
            workstep[i].Name,
            '"' );
            if(i < logs.length){
                temp = abi.encodePacked(temp,
                ',"URL":"', logs[i].URL,
                '","AprovedBy":"',
                Util.toString(logs[i].ApproveBy),
                '", "signature":"',
                Util.toString(logs[i].Signature),
                '","BlockNumber":',
                Strings.toString(logs[i].BlockNumber), 
                '} ' );
            }
            else  temp  = abi.encodePacked(temp ,'}');
            res = abi.encodePacked(res, temp);
        }
        res = abi.encodePacked(res,']}');
        return Util.base64JSON(string(res));
    }

    function setApprovalForAll(address operator, bool _approved) external{
        revert("Non Transferable token");
    }

    function totalSupply() external view returns (uint256){
        return nextTokenId - 1 - totalBurn;
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool){

    }


    function createWorkflow (
        string calldata _nameWorkFlow, 
        WorkStep[] calldata _steps
        ) public payable returns(uint8)
    {
        require(_steps.length>0, "No step");
        bytes32 prevHash = 0x0;
        bytes32 hash;
        for (uint256 i = 0; i < _steps.length; i += 1) {
            hash = keccak256(abi.encode(_nextWorkflow, i));
            _workstep[hash] = WorkStep(_steps[i].Name, _steps[i].Role, prevHash);
            prevHash = hash;
        }
        _workflow[_nextWorkflow] = _WorkFlow( _nameWorkFlow,  hash);
        return _nextWorkflow++;
    }

    function getWorkflow(uint8 _index) 
    public view returns( WorkFlow memory workflow, WorkStep[] memory steps){
        bytes32 previousStep = _workflow[_index].lastStep; 
        uint8 count = 0;
        while(previousStep != 0x0){
            count++;
            previousStep = _workstep[previousStep].previousStep;
        }
        WorkStep[] memory _steps = new WorkStep[](count);
        previousStep = _workflow[_index].lastStep; 
        for(uint i = count; i > 0; i--){
            _steps[i-1] = _workstep[previousStep];
            previousStep = _workstep[previousStep].previousStep;
        }
        steps = _steps;
        workflow =  WorkFlow(_workflow[_index].Name, count);
    }

    function getWorkflow(string memory nameWorkflow) 
        public view returns(WorkFlow memory workflow, WorkStep[] memory steps)
    {
        (workflow, steps) = getWorkflow(_workflowIndex(nameWorkflow));
    }

    function mintTo(address _to, uint8 _indexWorkflow)public onlyOwner{
        _mintTo(_to, _indexWorkflow);
    }

    function mintTo(address _to, string calldata nameWorkflow) public onlyOwner{
        _mintTo(_to, _workflowIndex(nameWorkflow));
    }

    function mintTo(address _to, uint8 _indexWorkflow, bytes calldata signature)public onlyOperator{
         require(getSignatureAddress(signature,  abi.encodePacked(_to, _indexWorkflow)) == owner());
        _mintTo(_to, _indexWorkflow);
    }

    function mintTo(address _to, string calldata nameWorkflow, bytes calldata signature)public onlyOperator(){
        require(getSignatureAddress(signature,  abi.encodePacked(_to, nameWorkflow)) == owner());
        _mintTo(_to, _workflowIndex(nameWorkflow));
    }

    function _mintTo(address _to, uint8 _indexWorkflow ) internal {
        _tracker[nextTokenId] = Tracker(_indexWorkflow, _to, 0x0);
        emit Transfer(address(0x0), _to, nextTokenId);
        nextTokenId++;
    }

    function burn(uint tokenId) public  {
        if(_tracker[tokenId].owner == address(0)) revert("already burn");
        emit Transfer(_tracker[tokenId].owner, address(0x0), nextTokenId);
        _tracker[tokenId] = Tracker(0, address(0), 0x0);
        totalBurn++;      
    }

    // function burn(uint tokenId, bytes calldata signature) public onlyOperator {
    //     if(_tracker[tokenId].owner == address(0)) revert("already burn");
    //     emit Transfer(_tracker[tokenId].owner, address(0x0), nextTokenId);
    //     _tracker[tokenId] = Tracker(0, address(0), 0x0);
    //     totalBurn++;        
    // }

    function submitLog(
        uint tokenId,
        string memory url,
        bytes32 dataHash, 
        bytes memory signature
        ) public 
    {
        Tracker memory t = _tracker[tokenId];
        if(t.Workflow == 0x0) revert("Token not valid");
        WorkFlow memory workflow; 
        WorkStep[] memory steps;
        (workflow, steps) = getWorkflow(t.Workflow);
        WorkStatus[] memory logs = getWorkStatus(tokenId);(tokenId);
        if(logs.length >= steps.length) revert("Finish");        
        address approved = getSignatureAddress(signature, abi.encode(tokenId, url, dataHash));
        if(!validAproved(t.Workflow, logs.length, approved)) 
            revert("Only aproved address for signature");
        if( !(msg.sender==approved || _operators[msg.sender])) 
            revert("Only operator or signature owner");
        bytes32 hash = keccak256(abi.encode(tokenId, url, dataHash, approved, t.lastStep));
        _workStatus[hash] = WorkStatus(approved, signature, url, dataHash, block.number, t.lastStep);
        _tracker[tokenId].lastStep = hash;
        emit Log(tokenId, approved);
    }

    function getWorkStatus(uint tokenId) 
        public view returns(WorkStatus[] memory logs)
    {
        Tracker memory t = _tracker[tokenId];
        if(t.lastStep==0x0){
            return new WorkStatus[](0);
        }
        bytes32 previousStep = t.lastStep;
        uint count = 0;
        while(previousStep!=0){
            previousStep = _workStatus[previousStep].previousStep;
            count++;
        }
        previousStep = t.lastStep;
        logs = new WorkStatus[](count);
        for(uint i = count; i > 0; i--){
            logs[i-1] = _workStatus[previousStep];
            previousStep = _workStatus[previousStep].previousStep;
        }
    }

    function getLastStatus(uint tokenId) 
        public view returns(uint8 stepIndex, WorkStatus memory step, WorkStep memory workStep)
    {
        WorkStatus[] memory logs = getWorkStatus(tokenId);
        stepIndex = uint8(logs.length);
        step = logs[logs.length-1];
        Tracker memory t = _tracker[tokenId];
        WorkFlow memory workflow; 
        WorkStep[] memory steps;
        (workflow, steps) = getWorkflow(t.Workflow);
        workStep = steps[logs.length-1];
    }

    function info(uint tokenId) 
        public view returns(
            uint stepIndex, 
            WorkFlow memory workflow, 
            WorkStep[] memory workstep, 
            WorkStatus[] memory logs
        )
    {
        (logs) = getWorkStatus(tokenId);
        stepIndex = logs.length;
        Tracker memory t = _tracker[tokenId];
        WorkStep[] memory steps;
        (workflow, steps) = getWorkflow(t.Workflow);
        workstep = steps;
    }

    function approve(address to, uint256 tokenId) external payable{
        revertNonTransferableToken();
    }

    function balanceOf(address owner) external view returns (uint256 balance){
        for(uint i = 1; i < nextTokenId; i++){
            if(_tracker[i].owner == owner) balance++;
        }
    }
   
   function getApproved(uint256 tokenId) external view returns (address operator){
       return address(0x0);
   }

   function isApprovedForAll(address owner, address operator) external view returns (bool){
        return false;
   }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable{
        revertNonTransferableToken();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable{
        revertNonTransferableToken();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable{
        revertNonTransferableToken();
    }

    function regOperator(address newOperator) public onlyOwner{
        _operators[newOperator] = true;
    }

    function removeOperator(address operator) public onlyOwner{
        _operators[operator] = false;
    }

    function _workflowIndex(string memory _name) internal view returns(uint8){
        bytes32 hash = keccak256(abi.encode(_name));
        for(uint8 i = 1; i < _nextWorkflow; i++){
            if(keccak256(abi.encode(_workflow[i].Name)) == hash ) return i;
        }
    }

    function getSignatureAddress(
        bytes memory signature, 
        bytes memory data) 
        internal pure returns(address)
    {
        bytes32 hash = keccak256(data);
        bytes32 _messageHash = keccak256(abi.encodePacked(
            '\x19Ethereum Signed Message:\n32', 
            hash
            ));
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {       
            // first 32 bytes, after the length prefix
            r := mload(add(signature, 32))
            // second 32 bytes
            s := mload(add(signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(signature, 96)))
        } 
        return ecrecover(_messageHash, v, r, s);
    }

    function isOperator(address _address) public view returns(bool){
        return _operators[_address];
    }

    function validAproved(
        uint8 _workflowIndex, 
        uint stepIndex,
        address _address) 
        internal view returns(bool)
    {
        WorkFlow memory workflow;
        WorkStep[] memory steps;
        (workflow, steps) = getWorkflow(_workflowIndex);
        if(keccak256(abi.encode(steps[stepIndex].Role)) == keccak256(abi.encode(""))) return true;
        return roleManagement.validateRole(_address, steps[stepIndex].Role);
    }

    function revertNonTransferableToken() internal {
        revert("Non Transferable token");
    }
    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Base64.sol";

library Util {
    function toString(address account) internal pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function base64JSON(string memory str) internal pure returns(string memory){
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(str)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}