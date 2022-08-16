/**
 *Submitted for verification at polygonscan.com on 2022-08-15
*/

// Sources flattened with hardhat v2.9.2 https://hardhat.org

// File contracts/lib/LibAppStorage.sol

/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2021 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity 0.8.9;

enum AuthorizationState {
    Unused,
    Used,
    Canceled
}

struct AppStorage {
    address owner;
    address pauser;
    bool paused;
    address blacklister;
    mapping(address => bool) blacklisted;
    string name;
    string symbol;
    uint8 decimals;
    string currency;
    address masterMinter;
    bool initialized;
    bool initializing;
    bool initializedV2;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    uint256 totalSupply;
    mapping(address => bool) minters;
    mapping(address => uint256) minterAllowed;
    address rescuer;
    bytes32 domainSeparator;
    mapping(address => mapping(bytes32 => AuthorizationState)) authorizationStates;
    mapping(address => uint256) nonces;
    mapping(address => bool) operators;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

//
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File contracts/lib/LibContext.sol

/**
 *
 *
 * Copyright (c) YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library LibContext {
    function _msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}


// File contracts/lib/LibOwnable.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
library LibOwnable {
    function _requireOnlyOwner() internal view {
        require(
            LibContext._msgSender() == LibAppStorage.diamondStorage().owner,
            "Ownable: caller is not the owner"
        );
    }
}


// File contracts/common/Ownable.sol

/**
 *
 *
 * Copyright (c) 2018 zOS Global Limited.
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
pragma solidity 0.8.9;
/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-labs/blob/3887ab77b8adafba4a26ace002f3a684c1a3388b/upgradeability_ownership/contracts/ownership/Ownable.sol
 * Modifications:
 * 1. Consolidate OwnableStorage into this contract (7/13/18)
 * 2. Reformat, conform to Solidity 0.6 syntax, and add error messages (5/13/20)
 * 3. Make public functions external (5/27/20)
 */
contract Ownable {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() external view returns (address) {
        return LibAppStorage.diamondStorage().owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function setOwner(address newOwner) internal {
        LibAppStorage.diamondStorage().owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        LibOwnable._requireOnlyOwner();
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(LibAppStorage.diamondStorage().owner, newOwner);
        setOwner(newOwner);
    }
}


// File contracts/lib/LibBlacklistable.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
library LibBlacklistable {
    function _requireBlacklister() internal view {
        require(
            msg.sender == LibAppStorage.diamondStorage().blacklister,
            "Blacklistable: caller is not the blacklister"
        );
    }

    function _requireNotBlacklisted(address account) internal view {
        require(
            !LibAppStorage.diamondStorage().blacklisted[account],
            "Blacklistable: account is blacklisted"
        );
    }
}


// File contracts/common/Blacklistable.sol

/**
 *
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title Blacklistable Token
 * @dev Allows accounts to be blacklisted by a "blacklister" role
 */
contract Blacklistable is Ownable {
    event Blacklisted(address indexed account);
    event UnBlacklisted(address indexed account);
    event BlacklisterChanged(address indexed newBlacklister);

    /**
     * @dev Throws if called by any account other than the blacklister
     */
    modifier onlyBlacklister() {
        LibBlacklistable._requireBlacklister();
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param account The address to check
     */
    modifier notBlacklisted(address account) {
        LibBlacklistable._requireNotBlacklisted(account);
        _;
    }

    function blacklister() external view returns (address) {
        return LibAppStorage.diamondStorage().blacklister;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param account The address to check
     */
    function isBlacklisted(address account) external view returns (bool) {
        return LibAppStorage.diamondStorage().blacklisted[account];
    }

    /**
     * @dev Adds account to blacklist
     * @param account The address to blacklist
     */
    function blacklist(address account) external onlyBlacklister {
        LibAppStorage.diamondStorage().blacklisted[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Removes account from blacklist
     * @param account The address to remove from the blacklist
     */
    function unBlacklist(address account) external onlyBlacklister {
        LibAppStorage.diamondStorage().blacklisted[account] = false;
        emit UnBlacklisted(account);
    }

    function updateBlacklister(address newBlacklister) external onlyOwner {
        require(newBlacklister != address(0), "Blacklistable: new blacklister is the zero address");
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        appStorage.blacklister = newBlacklister;
        emit BlacklisterChanged(appStorage.blacklister);
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;


// File contracts/lib/LibERC20.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library LibERC20 {
    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Internal function to set allowance
     * @param owner_    Token owner's address
     * @param spender   Spender's address
     * @param value     Allowance amount
     */
    function _approve(
        address owner_,
        address spender,
        uint256 value
    ) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        appStorage.allowed[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    /**
     * @notice Internal function to increase the allowance by a given increment
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param increment Amount of increase
     */
    function _increaseAllowance(
        address owner,
        address spender,
        uint256 increment
    ) internal {
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        uint256 currentAllowance = appStorage.allowed[owner][spender];
        _approve(owner, spender, currentAllowance.add(increment));
    }

    /**
     * @notice Internal function to decrease the allowance by a given decrement
     * @param owner     Token owner's address
     * @param spender   Spender's address
     * @param decrement Amount of decrease
     */
    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 decrement
    ) internal {
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        _approve(
            owner,
            spender,
            appStorage.allowed[owner][spender].sub(
                decrement,
                "ERC20: decreased allowance below zero"
            )
        );
    }

    /**
     * @notice Internal function to process transfers
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        require(value <= appStorage.balances[from], "ERC20: transfer amount exceeds balance");

        appStorage.balances[from] = appStorage.balances[from].sub(value);
        appStorage.balances[to] = appStorage.balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from   Payer's address
     * @param to     Payee's address
     * @param value  Transfer amount
     * @return True if successful
     */
    function _transferFrom(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        _transfer(from, to, value);

        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        address msgSender = LibContext._msgSender();
        uint256 currentAllowance = appStorage.allowed[from][msgSender];
        require(value <= currentAllowance, "ERC20: transfer amount exceeds allowance");
        appStorage.allowed[from][msgSender] = currentAllowance.sub(value);
        return true;
    }
}


// File contracts/lib/LibPausable.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
library LibPausable {
    function _requireNotPaused() internal view {
        require(!LibAppStorage.diamondStorage().paused, "Pausable: paused");
    }

    function _requireOnlyPauser() internal view {
        require(
            LibContext._msgSender() == LibAppStorage.diamondStorage().pauser,
            "Pausable: caller is not the pauser"
        );
    }
}


// File contracts/common/Pausable.sol

/**
 *
 *
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Copyright (c) 2018-2020 CENTRE SECZ0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @notice Base contract which allows children to implement an emergency stop
 * mechanism
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/feb665136c0dae9912e08397c1a21c4af3651ef3/contracts/lifecycle/Pausable.sol
 * Modifications:
 * 1. Added pauser role, switched pause/unpause to be onlyPauser (6/14/2018)
 * 2. Removed whenNotPause/whenPaused from pause/unpause (6/14/2018)
 * 3. Removed whenPaused (6/14/2018)
 * 4. Switches ownable library to use ZeppelinOS (7/12/18)
 * 5. Remove constructor (7/13/18)
 * 6. Reformat, conform to Solidity 0.6 syntax and add error messages (5/13/20)
 * 7. Make public functions external (5/27/20)
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();
    event PauserChanged(address indexed newAddress);

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        LibPausable._requireNotPaused();
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        LibPausable._requireOnlyPauser();
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyPauser {
        LibAppStorage.diamondStorage().paused = true;
        emit Pause();
    }

    function paused() external view returns (bool) {
        return LibAppStorage.diamondStorage().paused;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyPauser {
        LibAppStorage.diamondStorage().paused = false;
        emit Unpause();
    }

    function pauser() external view returns (address) {
        return LibAppStorage.diamondStorage().pauser;
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address newPauser) external onlyOwner {
        require(newPauser != address(0), "Pausable: new pauser is the zero address");
        LibAppStorage.diamondStorage().pauser = newPauser;
        emit PauserChanged(LibAppStorage.diamondStorage().pauser);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/common/Rescuable.sol

/**
 *
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
contract Rescuable is Ownable {
    using SafeERC20 for IERC20;

    event RescuerChanged(address indexed newRescuer);

    /**
     * @notice Returns current rescuer
     * @return Rescuer's address
     */
    function rescuer() external view returns (address) {
        return LibAppStorage.diamondStorage().rescuer;
    }

    /**
     * @notice Revert if called by any account other than the rescuer.
     */
    modifier onlyRescuer() {
        _requireOnlyRescuer();
        _;
    }

    function _requireOnlyRescuer() internal view {
        require(
            msg.sender == LibAppStorage.diamondStorage().rescuer,
            "Rescuable: caller is not the rescuer"
        );
    }

    /**
     * @notice Rescue ERC20 tokens locked up in this contract.
     * @param tokenContract ERC20 token contract address
     * @param to        Recipient address
     * @param amount    Amount to withdraw
     */
    function rescueERC20(
        IERC20 tokenContract,
        address to,
        uint256 amount
    ) external onlyRescuer {
        tokenContract.safeTransfer(to, amount);
    }

    /**
     * @notice Assign the rescuer role to a given address.
     * @param newRescuer New rescuer's address
     */
    function updateRescuer(address newRescuer) external onlyOwner {
        require(newRescuer != address(0), "Rescuable: new rescuer is the zero address");
        LibAppStorage.diamondStorage().rescuer = newRescuer;
        emit RescuerChanged(newRescuer);
    }
}


// File @openzeppelin/contracts/proxy/beacon/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts/proxy/ERC1967/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;



/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}


// File @openzeppelin/contracts/proxy/utils/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}


// File contracts/common/BaseToken.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title BaseToken
 */
abstract contract BaseToken is
    UUPSUpgradeable,
    IERC165,
    IERC20,
    IERC20Metadata,
    Ownable,
    Pausable,
    Blacklistable,
    Rescuable
{
    using SafeMath for uint256;

    AppStorage internal appStorage;

    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Burn(address indexed burner, address indexed from, uint256 amount);

    function _msgSender() internal view virtual returns (address) {
        return LibContext._msgSender();
    }

    /**
     * @dev Authorizes the contract owner to perform a contract upgrade.
     */
    function _authorizeUpgrade(address) internal virtual override onlyOwner {
        this;
    }

    function implementation() external view returns (address) {
        return _getImplementation();
    }

    function name() external view returns (string memory) {
        return appStorage.name;
    }

    function symbol() external view returns (string memory) {
        return appStorage.symbol;
    }

    function decimals() external view returns (uint8) {
        return appStorage.decimals;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC20).interfaceId ||
            interfaceId == type(IERC20Metadata).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Internal function to mint tokens.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
     */
    function _mint(address to, uint256 amount) internal returns (bool) {
        appStorage.totalSupply = appStorage.totalSupply.add(amount);
        appStorage.balances[to] = appStorage.balances[to].add(amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    /**
     * @notice Amount of remaining tokens spender is allowed to transfer on
     * behalf of the token owner
     * @param tokenOwner    Token owner's address
     * @param spender   Spender's address
     * @return Allowance amount
     */
    function allowance(address tokenOwner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return appStorage.allowed[tokenOwner][spender];
    }

    /**
     * @dev Get totalSupply of token
     */
    function totalSupply() external view override returns (uint256) {
        return appStorage.totalSupply;
    }

    /**
     * @dev Get token balance of an account
     * @param account address The account
     */
    function balanceOf(address account) external view override returns (uint256) {
        return appStorage.balances[account];
    }

    /**
     * @notice Set spender's allowance over the caller's tokens to be a given
     * value.
     * @param spender   Spender's address
     * @param value     Allowance amount
     * @return True if successful
     */
    function approve(address spender, uint256 value)
        external
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        LibERC20._approve(_msgSender(), spender, value);
        return true;
    }

    /**
     * @notice Transfer tokens by spending allowance
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return LibERC20._transferFrom(from, to, value);
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transfer(address to, uint256 value)
        external
        virtual
        override
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(to)
        returns (bool)
    {
        LibERC20._transfer(_msgSender(), to, value);
        return true;
    }

    /**
     * @dev allows a user to burn some of its own tokens
     * Validates that amount is less than or equal to the caller's account balance
     * @param account address from which tokens to be burned
     * @param amount uint256 the amount of tokens to be burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        uint256 balance = appStorage.balances[account];
        require(amount > 0, "BaseToken: burn amount not greater than 0");
        require(balance >= amount, "BaseToken: burn amount exceeds balance");

        appStorage.totalSupply = appStorage.totalSupply.sub(amount);
        appStorage.balances[account] = balance.sub(amount);
        emit Transfer(account, address(0), amount);
    }
}


// File contracts/common/EIP712Domain.sol

/**
 *
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title EIP712 Domain
 */
contract EIP712Domain {
    /**
     * @dev EIP712 Domain Separator
     */
    // solhint-disable-next-line
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return LibAppStorage.diamondStorage().domainSeparator;
    }
}


// File contracts/common/MetaTransaction.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
abstract contract MetaTransaction is EIP712Domain {
    using SafeMath for uint256;

    bytes32 public constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTx {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        AppStorage storage appStorage = LibAppStorage.diamondStorage();
        uint256 nonce = appStorage.nonces[userAddress];
        MetaTx memory metaTx = MetaTx({
            nonce: nonce,
            from: userAddress,
            functionSignature: functionSignature
        });

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        // increase nonce for user (to avoid re-use)
        appStorage.nonces[userAddress] = nonce.add(1);

        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);

        // Append userAddress and relayer address at the end to extract it from calling context
        // solhint-disable-next-line
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTx memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    /**
     * @notice Nonces for meta transaction (shared with permit)
     * @dev Nonces is shared for permits and meta transaction nonces.  The nonces and getNonce
     * methods both return the same nonce sequence, but are both kept for compatability
     * @param user Token owner's address (Authorizer)
     * @return Next nonce
     */
    function getNonce(address user) external view returns (uint256) {
        return LibAppStorage.diamondStorage().nonces[user];
    }

    function verify(
        address signer,
        MetaTx memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer == ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    LibAppStorage.diamondStorage().domainSeparator,
                    messageHash
                )
            );
    }
}


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363.sol)

pragma solidity ^0.8.0;


interface IERC1363 is IERC165, IERC20 {
    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) external returns (bool);
}


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Receiver.sol)

pragma solidity ^0.8.0;

interface IERC1363Receiver {
    /*
     * Note: the ERC-165 identifier for this interface is 0x88a7ca5c.
     * 0x88a7ca5c === bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))
     */

    /**
     * @notice Handle the receipt of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after a `transfer` or a `transferFrom`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param operator address The address which called `transferAndCall` or `transferFromAndCall` function
     * @param from address The address which are token transferred from
     * @param value uint256 The amount of tokens transferred
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onTransferReceived(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onTransferReceived(
        address operator,
        address from,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/interfaces/[email protected]

//
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1363Spender.sol)

pragma solidity ^0.8.0;

interface IERC1363Spender {
    /*
     * Note: the ERC-165 identifier for this interface is 0x7b04a2d0.
     * 0x7b04a2d0 === bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))
     */

    /**
     * @notice Handle the approval of ERC1363 tokens
     * @dev Any ERC1363 smart contract calls this function on the recipient
     * after an `approve`. This function MAY throw to revert and reject the
     * approval. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the token contract address is always the message sender.
     * @param owner address The address which called `approveAndCall` function
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format
     * @return `bytes4(keccak256("onApprovalReceived(address,uint256,bytes)"))`
     *  unless throwing
     */
    function onApprovalReceived(
        address owner,
        uint256 value,
        bytes memory data
    ) external returns (bytes4);
}


// File contracts/lib/LibERC1363.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library LibERC1363 {
    using Address for address;
    using SafeMath for uint256;

    /*
     * Note: the ERC-165 identifier for this interface is 0x4bbee2df.
     * 0x4bbee2df ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)'))
     */
    bytes4 private constant INTERFACE_TRANSFER_AND_CALL = 0x4bbee2df;

    /*
     * Note: the ERC-165 identifier for this interface is 0xfb9ec8ce.
     * 0xfb9ec8ce ===
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */
    bytes4 private constant INTERFACE_APPROVE_AND_CALL = 0xfb9ec8ce;

    function _supportsInterface(bytes4 interfaceId) internal pure returns (bool) {
        return
            interfaceId == INTERFACE_TRANSFER_AND_CALL ||
            interfaceId == INTERFACE_APPROVE_AND_CALL ||
            interfaceId == type(IERC1363).interfaceId;
    }

    /**
     * @dev Transfer tokens from `msg.sender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function _transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        address msgSender = LibContext._msgSender();
        LibERC20._transfer(msgSender, to, value);
        require(
            _checkAndCallTransfer(msgSender, to, value, data),
            "ERC1363: _checkAndCallTransfer reverts"
        );
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function _transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        LibERC20._transferFrom(from, to, value);
        require(
            _checkAndCallTransfer(from, to, value, data),
            "ERC1363: _checkAndCallTransfer reverts"
        );
        return true;
    }

    /**
     * @dev Internal function to invoke `onTransferReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param sender address Representing the previous owner of the given token value
     * @param recipient address Target address that will receive the tokens
     * @param amount uint256 The amount mount of tokens to be transferred
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal returns (bool) {
        if (!recipient.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Receiver(recipient).onTransferReceived(
            LibContext._msgSender(),
            sender,
            amount,
            data
        );
        return (retval == IERC1363Receiver(recipient).onTransferReceived.selector);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function _approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        LibERC20._approve(LibContext._msgSender(), spender, value);
        require(
            _checkAndCallApprove(spender, value, data),
            "ERC1363: _checkAndCallApprove reverts"
        );
        return true;
    }

    /**
     * @dev Internal function to invoke `onApprovalReceived` on a target address
     *  The call is not executed if the target address is not a contract
     * @param spender address The address which will spend the funds
     * @param amount uint256 The amount of tokens to be spent
     * @param data bytes Optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkAndCallApprove(
        address spender,
        uint256 amount,
        bytes memory data
    ) internal returns (bool) {
        if (!spender.isContract()) {
            return false;
        }
        bytes4 retval = IERC1363Spender(spender).onApprovalReceived(
            LibContext._msgSender(),
            amount,
            data
        );
        return (retval == IERC1363Spender(spender).onApprovalReceived.selector);
    }
}


// File contracts/common/ERC1363.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
abstract contract ERC1363 is IERC1363, Pausable, Blacklistable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return LibERC1363._supportsInterface(interfaceId);
    }

    /**
     * @dev Transfer tokens from `msgSender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferAndCall(address to, uint256 value)
        external
        virtual
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(to)
        returns (bool)
    {
        return LibERC1363._transferAndCall(to, value, "");
    }

    /**
     * @dev Transfer tokens from `msgSender` to another address and then call `onTransferReceived` on receiver
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferAndCall(
        address to,
        uint256 value,
        bytes memory data
    )
        external
        virtual
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(to)
        returns (bool)
    {
        return LibERC1363._transferAndCall(to, value, data);
    }

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value
    )
        external
        virtual
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return LibERC1363._transferFromAndCall(from, to, value, "");
    }

    /**
     * @dev Transfer tokens from one address to another and then call `onTransferReceived` on receiver
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 The amount of tokens to be transferred
     * @param data bytes Additional data with no specified format, sent in call to `to`
     * @return true unless throwing
     */
    function transferFromAndCall(
        address from,
        address to,
        uint256 value,
        bytes memory data
    )
        external
        virtual
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        return LibERC1363._transferFromAndCall(from, to, value, data);
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msgSender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     */
    function approveAndCall(address spender, uint256 value)
        external
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        return LibERC1363._approveAndCall(spender, value, "");
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msgSender
     * and then call `onApprovalReceived` on spender.
     * @param spender address The address which will spend the funds
     * @param value uint256 The amount of tokens to be spent
     * @param data bytes Additional data with no specified format, sent in call to `spender`
     */
    function approveAndCall(
        address spender,
        uint256 value,
        bytes memory data
    )
        external
        whenNotPaused
        notBlacklisted(LibContext._msgSender())
        notBlacklisted(spender)
        returns (bool)
    {
        return LibERC1363._approveAndCall(spender, value, data);
    }
}


// File contracts/lib/LibECRecover.sol

/**
 *
 *
 * Copyright (c) 2016-2019 zOS Global Limited
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;

/**
 * @title ECRecover
 * @notice A library that provides a safe ECDSA recovery function
 */
library LibECRecover {
    /**
     * @notice Recover signer's address from a signed message
     * @dev Adapted from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/65e4ffde586ec89af3b7e9140bdc9235d1254853/contracts/cryptography/ECDSA.sol
     * Modifications: Accept v, r, and s as separate arguments
     * @param digest    Keccak-256 hash digest of the signed message
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     * @return Signer address
     */
    function recover(
        bytes32 digest,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ├╖ 2 + 1, and for v in (282): v Γêê {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("ECRecover: invalid signature 's' value");
        }

        if (v != 27 && v != 28) {
            revert("ECRecover: invalid signature 'v' value");
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(digest, v, r, s);
        require(signer != address(0), "ECRecover: invalid signature");

        return signer;
    }
}


// File contracts/lib/LibEIP712.sol

/**
 *
 *
 * Copyright (c) 2018-2020 CENTRE SECZ
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
/**
 * @title EIP712
 * @notice A library that provides EIP712 helper functions
 */
library LibEIP712 {
    /**
     * @notice Make EIP712 domain separator
     * @param name      Contract name
     * @param version   Contract version
     * @return Domain separator
     */
    function makeDomainSeparator(string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encode(
                    0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                    // = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId,
                    address(this)
                )
            );
    }

    /**
     * @notice Recover signer's address from a EIP712 signature
     * @param domainSeparator   Domain separator
     * @param v                 v of the signature
     * @param r                 r of the signature
     * @param s                 s of the signature
     * @param typeHashAndData   Type hash concatenated with data
     * @return Signer's address
     */
    function recover(
        bytes32 domainSeparator,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes memory typeHashAndData
    ) internal pure returns (address) {
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, keccak256(typeHashAndData))
        );
        return LibECRecover.recover(digest, v, r, s);
    }
}


// File contracts/tokens/VirtualToken.sol

/**
 *
 *
 * Copyright (c) 2022 YellowHeart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity 0.8.9;
contract VirtualToken is BaseToken, MetaTransaction {
    using SafeMath for uint256;

    // keccak256("MintAuthorization(address account,uint256 amount,uint256 nonce)")
    bytes32 public constant MINT_AUTHORIZATION_TYPEHASH =
        0xcfcfcceac92c6042d8b8ee56efea2148643297cc11358dbf93cec5918cab7260;
    // keccak256("BurnAuthorization(address account,uint256 amount,uint256 nonce)")
    bytes32 public constant BURN_AUTHORIZATION_TYPEHASH =
        0x3c657d13dc549ab41b0df799e590928c2a2746a79f1d653bdf272f5df3356d3b;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event MinterAdded(address indexed minter);
    event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
    event MinterRemoved(address indexed oldMinter);
    event MasterMinterChanged(address indexed newMasterMinter);
    event Withdraw(address indexed owner, uint256 amount);

    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        string memory referenceSymbol_,
        uint8 decimals_,
        address newMasterMinter,
        address newPauser,
        address newBlacklister,
        address newOwner
    ) external {
        require(!appStorage.initialized, "HeartToken: contract is already initialized");
        require(newMasterMinter != address(0), "HeartToken: new masterMinter is the zero address");
        require(newPauser != address(0), "HeartToken: new pauser is the zero address");
        require(newBlacklister != address(0), "HeartToken: new blacklister is the zero address");
        require(newOwner != address(0), "HeartToken: new owner is the zero address");

        appStorage.name = tokenName;
        appStorage.symbol = tokenSymbol;
        appStorage.currency = referenceSymbol_;
        appStorage.decimals = decimals_;
        appStorage.masterMinter = newMasterMinter;
        appStorage.pauser = newPauser;
        appStorage.blacklister = newBlacklister;
        setOwner(newOwner);

        appStorage.domainSeparator = LibEIP712.makeDomainSeparator(tokenName, "1");

        appStorage.initialized = true;
    }

    function referenceTokenSymbol() external view returns (string memory) {
        return appStorage.currency;
    }

    /**
     * @dev Throws if called by any account other than the masterMinter
     */
    modifier onlyMasterMinter() {
        _requireOnlyMasterMinter();
        _;
    }

    function _requireOnlyMasterMinter() internal view {
        require(
            _msgSender() == appStorage.masterMinter,
            "BaseToken: caller is not the masterMinter"
        );
    }

    /**
     * @dev Throws if called by any account other than a minter
     */
    modifier onlyMinters() {
        _requireOnlyMinters();
        _;
    }

    function _requireOnlyMinters() internal view {
        require(appStorage.minters[_msgSender()], "BaseToken: caller is not a minter");
    }

    function masterMinter() external view returns (address) {
        return appStorage.masterMinter;
    }

    function updateMasterMinter(address _newMasterMinter) external onlyOwner {
        require(_newMasterMinter != address(0), "BaseToken: new masterMinter is the zero address");
        appStorage.masterMinter = _newMasterMinter;
        emit MasterMinterChanged(appStorage.masterMinter);
    }

    /**
     * @dev Checks if account is a minter
     * @param account The address to check
     */
    function isMinter(address account) external view returns (bool) {
        return appStorage.minters[account];
    }

    /**
     * @dev Function to add/update a new minter
     * @param minter The address of the minter
     * @return True if the operation was successful.
     */
    function addMinter(address minter) external whenNotPaused onlyMasterMinter returns (bool) {
        require(minter != address(0), "VirtualToken: minter is zero address");
        require(!appStorage.minters[minter], "VirtualToken: already a minter");
        appStorage.minters[minter] = true;
        emit MinterAdded(minter);
        return true;
    }

    /**
     * @dev Function to add/update a new minter
     * @param minters The list of minter addresses
     * @return True if the operation was successful.
     */
    function addMinters(address[] calldata minters)
        external
        whenNotPaused
        onlyMasterMinter
        returns (bool)
    {
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            require(minters[i] != address(0), "VirtualToken: minter is zero address");
            require(!appStorage.minters[minter], "VirtualToken: already a minter");
            appStorage.minters[minter] = true;
            emit MinterAdded(minter);
        }
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minter The address of the minter to remove
     * @return True if the operation was successful.
     */
    function removeMinter(address minter) external onlyMasterMinter returns (bool) {
        require(minter != address(0), "VirtualToken: minter is zero address");
        require(appStorage.minters[minter], "VirtualToken: not a minter");
        appStorage.minters[minter] = false;
        emit MinterRemoved(minter);
        return true;
    }

    /**
     * @dev Function to remove a minter
     * @param minters The list of minter addresses to remove
     * @return True if the operation was successful.
     */
    function removeMinters(address[] calldata minters) external onlyMasterMinter returns (bool) {
        for (uint256 i = 0; i < minters.length; i++) {
            address minter = minters[i];
            require(minter != address(0), "VirtualToken: minter is zero address");
            require(appStorage.minters[minter], "VirtualToken: not a minter");
            appStorage.minters[minter] = false;
            emit MinterRemoved(minter);
        }
        return true;
    }

    /**
     * @dev Function to mint tokens
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint. Must be less than or equal
     * to the minterAllowance of the caller.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address to, uint256 amount)
        external
        whenNotPaused
        onlyMinters
        notBlacklisted(_msgSender())
        notBlacklisted(to)
        returns (bool)
    {
        require(to != address(0), "VirtualToken: mint to the zero address");
        require(amount > 0, "VirtualToken: mint amount not greater than 0");

        address msgSender = _msgSender();
        _mint(to, amount);
        emit Mint(msgSender, to, amount);
        return true;
    }

    /**
     * @dev allows a minter to burn some of its own tokens
     * Validates that caller is a minter and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param amount uint256 the amount of tokens to be burned
     */
    function burn(uint256 amount) external whenNotPaused onlyMinters notBlacklisted(_msgSender()) {
        address msgSender = _msgSender();
        _burn(msgSender, amount);
        emit Burn(msgSender, msgSender, amount);
    }

    /**
     * @notice Transfer tokens by spending allowance.  Allows operator transfers.
     * @param from  Payer's address
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        override(BaseToken)
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(from)
        notBlacklisted(to)
        returns (bool)
    {
        address msgSender = LibContext._msgSender();
        if (appStorage.operators[msgSender]) {
            LibERC20._transfer(from, to, value);
            return true;
        } else {
            _transferNotAllowed(value);
            return false;
        }
    }

    /**
     * @notice Transfer tokens from the caller
     * @param to    Payee's address
     * @param value Transfer amount
     * @return True if successful
     */
    function transfer(address to,uint256 value)
        external
        view
        override(BaseToken)
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(to)
        returns (bool)
    {
        _transferNotAllowed(value);
        return false;
    }

    function addOperator(address operator) external onlyOwner {
        require(!appStorage.operators[operator], "VirtualToken: already an operator");
        appStorage.operators[operator] = true;
        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external onlyOwner {
        require(appStorage.operators[operator], "VirtualToken: not an operator");
        appStorage.operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    function isOperator(address operator) external view returns (bool) {
        return appStorage.operators[operator];
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(BaseToken)
        returns (bool)
    {
        return BaseToken.supportsInterface(interfaceId);
    }

    /**
     * @dev allows a caller to burn some of its own tokens for a withdrawal
     * Validates that the sender is not blacklisted and
     * amount is less than or equal to the minter's account balance
     * @param amount uint256 the amount of tokens to be burned
     */
    function withdraw(uint256 amount) external whenNotPaused notBlacklisted(_msgSender()) {
        address msgSender = _msgSender();
        _burn(msgSender, amount);
        emit Withdraw(msgSender, amount);
    }

    /**
     * @dev allows an operator to burn some tokens for a withdrawal
     * Validates that caller is an operator and that sender is not blacklisted
     * amount is less than or equal to the minter's account balance
     * @param account address from which the tokens will be burned
     * @param amount uint256 the amount of tokens to be burned
     */
    function withdrawFrom(address account, uint256 amount)
        external
        whenNotPaused
        notBlacklisted(_msgSender())
        notBlacklisted(account)
    {
        address msgSender = _msgSender();
        require(appStorage.operators[msgSender], "VirtualToken: not authorized");
        _burn(account, amount);
        emit Withdraw(account, amount);
    }

    /**
     * @dev Mint to an account with authorized signature.  This action requires an EIP712 signature from
     * a minter account.  Anyone can submit the transaction as long as it is signed by a minter.
     * @param account   the account to add credit tokens
     * @param amount    the amount of credit tokens to be added
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function mintWithAuthorization(
        address account,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused notBlacklisted(account) {
        require(account != address(0), "VirtualToken: account is the zero address");
        require(amount > 0, "VirtualToken: amount must be greater than 0");
        bytes memory data = abi.encode(
            MINT_AUTHORIZATION_TYPEHASH,
            account,
            amount,
            appStorage.nonces[account]
        );
        address signer = LibEIP712.recover(appStorage.domainSeparator, v, r, s, data);
        LibBlacklistable._requireNotBlacklisted(signer);
        require(appStorage.minters[signer], "VirtualToken: invalid signature");

        appStorage.nonces[account] = appStorage.nonces[account].add(1);
        _mint(account, amount);
        emit Mint(signer, account, amount);
    }

    /**
     * @dev Burn from an account with authorized signature.  This action requires an EIP712 signature from
     * a minter account.  Anyone can submit the transaction as long as it is signed by a minter.
     * @param account   the account to remove credit tokens
     * @param amount    the amount of credit tokens to be removed
     * @param v         v of the signature
     * @param r         r of the signature
     * @param s         s of the signature
     */
    function burnWithAuthorization(
        address account,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external whenNotPaused notBlacklisted(account) {
        require(account != address(0), "VirtualToken: account is the zero address");
        require(amount > 0, "VirtualToken: amount must be greater than 0");
        bytes memory data = abi.encode(
            BURN_AUTHORIZATION_TYPEHASH,
            account,
            amount,
            appStorage.nonces[account]
        );
        address signer = LibEIP712.recover(appStorage.domainSeparator, v, r, s, data);
        LibBlacklistable._requireNotBlacklisted(signer);
        require(appStorage.minters[signer], "VirtualToken: invalid signature");

        appStorage.nonces[account] = appStorage.nonces[account].add(1);
        _burn(account, amount);
        emit Burn(signer, account, amount);
    }

    function _transferNotAllowed(uint256 value) internal pure {
        require(!(value >= 0), "VirtualToken: transfer is not allowed");
    }
}