/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: query.sol



pragma solidity ^0.8.7;




using SafeMath for uint256;



contract PriceConsumerV3 {

    

    function getLatestPrice() public view  returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice() / 1000000 ;

    }

     function getLatestPrice2() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice2() / 1000000 ;

    }    

     function getLatestPrice3() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice3() ;

    }

     function getLatestPrice4() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice4()  ;

    } 

     function getLatestPrice5() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice5()  ;

    }

         function getLatestPrice6() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice6()  ;

    }

         function getLatestPrice7() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice7()  ;

    }  

         function getLatestPrice8() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice8()  ;

    }  

     function getBlockNumber() public view returns  (uint256) {

        return PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getBlockNumber();

    }             

    function getBlocktimestamp() public view returns   (uint256){

        return  PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getBlocktimestamp();

    }  

   function suma() public view returns   (uint256){

        return  PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getBlocktimestamp() + PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice4() + PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getBlockNumber() + PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice3() + PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice2() + PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice()+ PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice5()+ PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice6()+ PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice7()+ PriceConsumerV3(0x2e45A32c478a0F03173342Bb204857b7D24Ba6D0).getLatestPrice8();

   } 



     

     uint hashDigits = 10;

      

    // Equivalent to 10^10

    uint hashModulus = 10 ** hashDigits; 

  

    // Function to generate the hash value

    function random10() public view returns   (uint256)

        

    {

        // "packing" the string into bytes and 

        // then applying the hash function. 

        // This is then typecasted into uint.

        uint random = 

             uint(keccak256(abi.encodePacked(suma())));

               

        // Returning the generated hash value 

        return random % hashModulus;

    } 

     uint hashDigits2 = 4;

      

    // Equivalent to 10^10

    uint hashModulus2 = 10 ** hashDigits2; 

  

    // Function to generate the hash value

    function random4() public view returns   (uint256)

        

    {

        // "packing" the string into bytes and 

        // then applying the hash function. 

        // This is then typecasted into uint.

        uint random = 

             uint(keccak256(abi.encodePacked(suma())));

               

        // Returning the generated hash value 

        return random % hashModulus2;

    } 



       uint hashDigits3 = 2;

      

    // Equivalent to 10^10

    uint hashModulus3 = 10 ** hashDigits3; 

  

    // Function to generate the hash value

    function random2() public view returns   (uint256)

        

    {

        // "packing" the string into bytes and 

        // then applying the hash function. 

        // This is then typecasted into uint.

        uint random = 

             uint(keccak256(abi.encodePacked(suma())));

               

        // Returning the generated hash value 

        return random % hashModulus3;

    } 

         uint hashDigits4 = 1;

      

    // Equivalent to 10^10

    uint hashModulus4 = 10 ** hashDigits4; 

  

    // Function to generate the hash value

    function random1() public view returns   (uint256)

        

    {

        // "packing" the string into bytes and 

        // then applying the hash function. 

        // This is then typecasted into uint.

        uint random = 

             uint(keccak256(abi.encodePacked(suma())));

               

        // Returning the generated hash value 

        return random % hashModulus4;

    } 



}