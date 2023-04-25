/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/utils.sol



// 888                                 888      d8b          
// 888                                 888      Y8P          
// 888                                 888                   
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.  
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b 
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888 
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P 
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"  
//                        888                       888      
//                   Y8b d88P                       888      
//  

pragma solidity 0.8.19;

library Utils {
    function getMessageHash(
        string memory id,
        address user,
        uint256 price,
        address sa,
        string memory mid
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(id, user, price, sa, mid));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address sa,
        string memory id,
        uint256 price,
        address user,
        bytes memory signature,
        string memory mid
    ) internal pure returns (address) {
        bytes32 messageHash = getMessageHash(id, user, price, sa, mid);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}

// File: contracts/IKeyship.sol



// 888                                 888      d8b          
// 888                                 888      Y8P          
// 888                                 888                   
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.  
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b 
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888 
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P 
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"  
//                        888                       888      
//                   Y8b d88P                       888      
//  

pragma solidity 0.8.19;

interface IKeyship {
    function saveRecord(string memory _id, string memory _mid) external;
}

// File: contracts/IValidators.sol



// 888                                 888      d8b
// 888                                 888      Y8P
// 888                                 888
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"
//                        888                       888
//                   Y8b d88P                       888
//

pragma solidity 0.8.19;

interface IValidators {
    function isValidator(address _validator) external returns (bool);

    function getPayoutAddress(address _validator) external returns (address);
}

// File: contracts/KIERC20.sol



// 888                                 888      d8b
// 888                                 888      Y8P
// 888                                 888
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"
//                        888                       888
//                   Y8b d88P                       888
//

pragma solidity 0.8.19;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/keyshipProxy.sol

// SPDX-License-Identifier: GPL-3.0

// 888                                 888      d8b
// 888                                 888      Y8P
// 888                                 888
// 888  888  .d88b.  888  888 .d8888b  88888b.  888 88888b.
// 888 .88P d8P  Y8b 888  888 88K      888 "88b 888 888 "88b
// 888888K  88888888 888  888 "Y8888b. 888  888 888 888  888
// 888 "88b Y8b.     Y88b 888      X88 888  888 888 888 d88P
// 888  888  "Y8888   "Y88888  88888P' 888  888 888 88888P"
//                        888                       888
//                   Y8b d88P                       888
//

// KEYSHIP PROXY CONTRACT v1.0.0

pragma solidity 0.8.19;






contract KeyshipProxy is Ownable {
    address public KeyshipContract;
    uint256 public validatorFee;
    address public ValidatorsContract;

    event NewProxyRecord(address _from, string id, string mid);

    constructor(address _validatorsContract, address _keyshipContract) {
        ValidatorsContract = _validatorsContract;
        KeyshipContract = _keyshipContract;
        validatorFee = 1;
    }

    function record(
        address _sa,
        string memory _id,
        bytes memory _signature,
        string memory _mid,
        address validator
    ) public payable {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "Error !"
        );
        require(msg.value > 0, "You need to pay");
        require(
            IValidators(ValidatorsContract).isValidator(validator),
            "Invalid Validator"
        );
        require(
            Utils.verify(_sa, _id, msg.value, msg.sender, _signature, _mid) ==
                validator,
            "Invalid signature"
        );
        uint256 value = msg.value;
        uint256 onePercent = SafeMath.div(value, 100);
        uint256 _feeValidator = SafeMath.mul(onePercent, validatorFee);
        uint256 amountToSeller = value - _feeValidator;
        address payable sellerAddress = payable(_sa);
        address _payoutValidatorAddress = IValidators(ValidatorsContract)
            .getPayoutAddress(validator);
        address payable _validatorAddress = payable(_payoutValidatorAddress);
        sellerAddress.transfer(amountToSeller);
        _validatorAddress.transfer(_feeValidator);
        IKeyship(KeyshipContract).saveRecord(_id, _mid);
        emit NewProxyRecord(msg.sender, _id, _mid);
    }

    function setFees(uint256 _feeValidator) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        validatorFee = _feeValidator;
    }

    function setKeyshipContract(address _contract) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        KeyshipContract = _contract;
    }

    function contractBalance() public view returns (uint256) {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        return address(this).balance;
    }

    function withdrawIfAny() public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        address payable addressToPay = payable(msg.sender);
        addressToPay.transfer(address(this).balance);
    }

    function withdrawToken(address _tokenContract) public onlyOwner {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "err 1"
        );
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 balance = tokenContract.balanceOf(address(this));
        tokenContract.transfer(msg.sender, balance);
    }
}