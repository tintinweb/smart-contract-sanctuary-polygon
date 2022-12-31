// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Strings.sol";

contract LandRecord {
    uint256 public personCount = 0;
    uint256 public plotCount = 0;
    uint256 public adminCount = 0;
    address public govtGSTAddr;

    constructor(address _govt) {
        govtGSTAddr = _govt;
    }

    struct Person {
        uint256 personId;
        uint256 perAadharno;
        uint256[] inheritChildren;
    }

    event plotAdded(
        string plotId,
        string plotAddr,
        uint256 price,
        uint256[] owner,
        uint256 times
    );
    event plotSale(
        string plotId,
        bool isSelling,
        uint256[] owner,
        uint256 sellingPrice,
        uint256 times
    );
    event plotForBuy(
        string plotId,
        uint256 newowner,
        uint256 price,
        uint256 times
    );
    event plotTransferred(
        string plotId,
        uint256[] oldowner,
        uint256 newowner,
        uint256 sellPrice,
        uint256 times
    );
    event eventConsensus(
        string plotId,
        address sender,
        bool decision,
        uint256 times
    );
    event plotDivided(
        string plotId,
        uint256 divisions,
        uint256[] owner,
        uint256 times
    );

    mapping(uint256 => Person) public personIds;
    mapping(uint256 => Person) public personaadhars;

    struct Plot {
        string plotId; // string plot id
        bool disable; // true => the division ids are in use, false => this id is valid
        string plotaddr;
        uint256 plotprice;
        uint256 taxpercent;
        string typedesc;
        uint256[] owneraadhar;
        bool isSelling;
        uint256 sellingPrice;
        uint256 newowneraadhar;
        string neighbours;
        bool[] consensus;
        string imageurl;
        bool inprocess;
    }

    // plotid => Struct(Plot)
    mapping(string => Plot) public Plots;

    struct Admin {
        uint256 adminId;
        uint256 adminaadharno;
        address adminaddr;
        string role;
    }

    mapping(address => Admin) public Admins;
    mapping(uint256 => address) public AdminIds;
    mapping(uint256 => Admin) public Adminaadhars;

    modifier plotowneroradmin(string memory plotId, uint256 _aadhar) {
        bool x = false;
        for (uint256 i = 0; i < Plots[plotId].owneraadhar.length; i++) {
            if (Plots[plotId].owneraadhar[i] == _aadhar) {
                x = true;
            }
        }
        if (Admins[msg.sender].adminId != 0) {
            x = true;
        }
        require(x == true);
        _;
    }

    modifier adminonly() {
        require(Admins[msg.sender].adminId != 0);
        _;
    }

    modifier notDisable(string memory _plotId) {
        require(Plots[_plotId].disable == false, "Plot id not in use");
        _;
    }

    function addPerson(
        uint256 _perAadharno,
        uint256[] calldata _inheritChildren
    ) public adminonly returns (uint256) {
        uint256 x = personaadhars[_perAadharno].personId;
        if (x == 0) {
            Person memory aux;
            personCount++;
            aux.personId = personCount;
            aux.perAadharno = _perAadharno;
            aux.inheritChildren = _inheritChildren;
            personIds[personCount] = aux;
            personaadhars[_perAadharno] = aux;
            return personCount;
        } else {
            Person memory aux = personaadhars[_perAadharno];
            aux.inheritChildren = _inheritChildren;
            personIds[_perAadharno] = aux;
            personaadhars[aux.personId] = aux;
            return personCount;
        }
    }

    function addAdmin(uint256 _adminaadharno, string memory _role)
        public
        returns (uint256)
    {
        uint256 x = Admins[msg.sender].adminId;
        if (x == 0) {
            adminCount++;
            Admin memory aux;
            aux.adminId = adminCount;
            aux.adminaadharno = _adminaadharno;
            aux.adminaddr = msg.sender;
            aux.role = _role;
            Admins[msg.sender] = aux;
            AdminIds[adminCount] = msg.sender;
            Adminaadhars[_adminaadharno] = aux;
        } else {
            Admin memory aux = Admins[msg.sender];
            aux.adminaadharno = _adminaadharno;
            aux.role = _role;
            Admins[msg.sender] = aux;
        }
        return adminCount;
    }

    function addPlot(
        string memory _plotaddr,
        uint256 _plotprice,
        uint256 _taxpercent,
        string memory _typedesc,
        uint256[] memory _owneraadhar,
        string memory _neighbours,
        string memory _imageurl
    ) public returns (string memory) {
        plotCount++;
        Plot memory aux;
        string memory _plotId = Strings.toString(plotCount);
        aux.disable = false;
        aux.plotId = _plotId;
        aux.plotaddr = _plotaddr;
        aux.plotprice = _plotprice;
        aux.owneraadhar = _owneraadhar;
        aux.taxpercent = _taxpercent;
        aux.typedesc = _typedesc;
        aux.neighbours = _neighbours;
        aux.imageurl = _imageurl;
        aux.inprocess = false;
        Plots[_plotId] = aux;
        emit plotAdded(
            _plotId,
            _plotaddr,
            _plotprice,
            _owneraadhar,
            block.timestamp
        );
        return _plotId;
    }

    function getNewId(string memory currId, uint256 trm)
        private
        pure
        returns (string memory)
    {
        bytes memory output;
        if (trm == 1) {
            output = abi.encodePacked(currId, "/", "1");
        } else if (trm == 2) {
            output = abi.encodePacked(currId, "/", "2");
        } else if (trm == 3) {
            output = abi.encodePacked(currId, "/", "3");
        } else {
            output = abi.encodePacked(currId, "/", "4");
        }
        return string(output);
    }

    // @notice this function will return 2 sub plots from the given plots
    function plotDivison(
        string memory _plotId,
        uint256 _aadhar,
        uint256 _divisionSize,
        string[] memory _plotAddr,
        uint256[] memory _plotprice,
        string[] memory _typedesc,
        string[] memory _neighbours,
        string[] memory _imageurl
    ) public plotowneroradmin(_plotId, _aadhar) {
        require(
            (bytes(Plots[_plotId].plotId)).length != 0,
            "Plot does not exists"
        );
        require(Plots[_plotId].disable == false, "Plot is not in use");
        require(Plots[_plotId].isSelling == false, "Current plot is selling");
        require(
            Plots[_plotId].inprocess == false,
            "Current plot is in process"
        );
        require(
            _divisionSize == 2 || _divisionSize == 3 || _divisionSize == 4,
            "Invalid division size"
        );

        Plots[_plotId].disable = true;

        for (uint256 i = 0; i < _divisionSize; i++) {
            Plot memory aux;
            aux.plotId = getNewId(_plotId, i + 1);
            aux.disable = false;
            aux.plotaddr = _plotAddr[i];
            aux.plotprice = _plotprice[i];
            aux.taxpercent = Plots[_plotId].taxpercent; // from parent plot
            aux.typedesc = _typedesc[i];
            aux.owneraadhar = Plots[_plotId].owneraadhar; // from parent plot
            aux.neighbours = _neighbours[i];
            aux.imageurl = _imageurl[i];

            Plots[aux.plotId] = aux;

            // emit event sub plot added
            emit plotAdded(
                aux.plotId,
                aux.plotaddr,
                aux.plotprice,
                aux.owneraadhar,
                block.timestamp
            );
        }
        emit plotDivided(
            _plotId,
            _divisionSize,
            Plots[_plotId].owneraadhar,
            block.timestamp
        );
    }

    function putForSale(
        string memory _plotId,
        uint256 _price,
        uint256 _aadhar
    ) public plotowneroradmin(_plotId, _aadhar) notDisable(_plotId) {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.isSelling = true;
        aux.sellingPrice = _price;
        Plots[_plotId] = aux;
        emit plotSale(_plotId, true, aux.owneraadhar, _price, block.timestamp);
    }

    function desale(string memory _plotId, uint256 _aadhar)
        public
        plotowneroradmin(_plotId, _aadhar)
        notDisable(_plotId)
    {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.isSelling = false;
        aux.sellingPrice = 0;
        Plots[_plotId] = aux;
        emit plotSale(_plotId, false, aux.owneraadhar, 0, block.timestamp);
    }

    function addTax(string memory _plotId, uint256 _taxpercent) public {
        Plot memory aux = Plots[_plotId];
        aux.taxpercent = _taxpercent;
        Plots[_plotId] = aux;
    }

    function buyLand(string memory _plotId, uint256 _aadhar)
        public
        notDisable(_plotId)
    {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.newowneraadhar = _aadhar;
        aux.inprocess = true;
        Plots[_plotId] = aux;
        emit plotForBuy(_plotId, _aadhar, aux.sellingPrice, block.timestamp);
    }

    function consensus(string memory _plotId, bool _dec)
        public
        notDisable(_plotId)
    {
        Plot storage aux = Plots[_plotId];
        Plots[_plotId].consensus.push(_dec); //push true or false in array of boolean
        emit eventConsensus(_plotId, msg.sender, _dec, block.timestamp);
        uint256 participants = aux.consensus.length; //check for current length of array of boolean
        require(participants <= adminCount);
        if (participants >= ((adminCount / 2) + 1)) {
            //check for more than 50% participants voted or not
            uint256 nostrue;
            for (uint256 i = 0; i < participants; i++) {
                if (aux.consensus[i]) {
                    nostrue++;
                }
            }
            if ((2 * nostrue) >= adminCount) {
                //if more than or equal to 50 % no. of true present // do action
                transfer(_plotId);
            }
        }
    }

    function transfer(string memory _plotId) private {
        Plot memory aux = Plots[_plotId];
        aux.plotprice = aux.sellingPrice;
        aux.isSelling = false;
        aux.sellingPrice = 0;
        aux.inprocess = false;
        uint256[] memory oldowner = aux.owneraadhar;
        uint256 x = aux.newowneraadhar;
        aux.newowneraadhar = 0;
        Plots[_plotId] = aux;
        delete Plots[_plotId].owneraadhar;
        Plots[_plotId].owneraadhar.push(x);
        emit plotTransferred(
            _plotId,
            oldowner,
            x,
            aux.plotprice,
            block.timestamp
        );
    }

    function expirePerson(string memory _plotId, uint256 _aadhar)
        public
        plotowneroradmin(_plotId, _aadhar)
    {
        uint256[] memory x = Plots[_plotId].owneraadhar;
        Person memory aux = personaadhars[x[0]];
        delete Plots[_plotId].owneraadhar;
        Plots[_plotId].owneraadhar = aux.inheritChildren;
    }

    function getowner(string memory _plotId)
        public
        view
        returns (uint256[] memory)
    {
        return Plots[_plotId].owneraadhar;
    }

    function getconsensus(string memory _plotId)
        public
        view
        returns (bool[] memory)
    {
        return Plots[_plotId].consensus;
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