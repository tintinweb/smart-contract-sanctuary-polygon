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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC1155Internal } from './IERC1155Internal.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 is IERC165Internal {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165Internal } from './IERC165Internal.sol';

/**
 * @title ERC165 interface registration interface
 */
interface IERC165Internal {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC20Internal } from './IERC20Internal.sol';

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 is IERC20Internal {
    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(
        address holder,
        address spender
    ) external view returns (uint256);

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC20 interface needed by internal functions
 */
interface IERC20Internal {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Context.sol';
import "./UpgradeBase.sol";

abstract contract UpgradableOwnableV1 is Context, UpgradeBase {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract UpgradeBase {
    using SafeMath for uint256;
    /**
 * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
 * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    //common function
    function _divRound(uint x, uint y) pure internal returns (uint)  {
        return (x + (y / 2)) / y;
    }

    function currentContractVersion() view external returns (uint8) {
        return _initialized;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@solidstate/contracts/interfaces/IERC1155.sol";
import "@solidstate/contracts/interfaces/IERC721.sol";
import '@solidstate/contracts/interfaces/IERC20.sol';
import '@solidstate/contracts/interfaces/IERC165.sol';
import "../support/UpgradableOwnableV1.sol";

contract TxnTransferV0 is UpgradableOwnableV1 {
    struct NftShare {
        address provider;
        address nftContract;
        uint256 tokenId;
        uint32 balance;
        uint8 contractType;//1=721,2=1155
    }

    struct CoinShare {
        address provider;
        address coinContract;
        uint256 balance;
    }

    mapping(uint256 => NftShare) private _nftShares;
    mapping(uint256 => CoinShare) private _coinShare;
    address private _verifyAccount;
    address private _assetAccount;
    uint256 private _feeBalance;

    event ShareReceivedEvent(uint256 shareId, address receiver);

    function _checkSystemAccount() internal view {
        require(_msgSender() == _verifyAccount, 'Invalid visit');
    }

    modifier onlySystemCall() {
        _checkSystemAccount();
        _;
    }


    function shareInfo(uint256 shareId) view external returns (address provider, address giftContract, uint8 giftType, uint256 tokenId) {
        require(_nftShares[shareId].balance > 0 || _coinShare[shareId].balance > 0, 'Not exists shareid');
        if (_nftShares[shareId].balance > 0) {
            provider = _nftShares[shareId].provider;
            giftContract = _nftShares[shareId].nftContract;
            giftType = _nftShares[shareId].contractType;
            tokenId = _nftShares[shareId].tokenId;
        } else {
            provider = _coinShare[shareId].provider;
            giftContract = address(_coinShare[shareId].coinContract);
            giftType = uint8(10);
            tokenId = 0;
        }
    }

    function recordShareNft(uint256 shareId, address nftContract, uint256 tokenId, uint256 fee, bytes calldata signature) external payable {
        require(_nftShares[shareId].provider == address(0), 'ShareId registered');
        require(_coinShare[shareId].provider == address(0), 'ShareId registered');
        //        require(IERC165(nftContract).supportsInterface(type(IERC721).interfaceId) || IERC165(nftContract).supportsInterface(type(IERC1155).interfaceId), 'Not ERC721 nor ERC1155 contract');
        require(_verifyShareSignature(shareId, _msgSender(), 1, fee, signature), 'Invalid visit');
        require(msg.value >= fee, 'Insufficient fee');
        //        if (IERC165(nftContract).supportsInterface(type(IERC721).interfaceId)) {
        //            require(IERC721(nftContract).ownerOf(tokenId) != _msgSender(), 'Not token owner');
        //            require(IERC721(nftContract).isApprovedForAll(_msgSender(), _msgSender()), 'Not authorized');
        //            _nftShares[shareId] = NftShare(_msgSender(), nftContract, tokenId, uint32(1), uint8(1));
        //        } else if (IERC165(nftContract).supportsInterface(type(IERC1155).interfaceId)) {
        require(IERC1155(nftContract).balanceOf(_msgSender(), tokenId) > 0, 'Not token owner');
        require(IERC1155(nftContract).isApprovedForAll(_msgSender(), address(this)), 'Not authorized');
        _nftShares[shareId] = NftShare(_msgSender(), nftContract, tokenId, uint32(1), uint8(2));
        //        }
        _feeBalance = _feeBalance + fee;
    }

    function recordShareCoin(uint256 shareId, address coinContract, uint256 amount, uint256 fee, bytes calldata signature) external payable {
        require(_nftShares[shareId].provider == address(0), 'ShareId registered');
        require(_coinShare[shareId].provider == address(0), 'ShareId registered');
        require(_verifyShareSignature(shareId, _msgSender(), amount, fee, signature), 'Invalid visit');
        require(msg.value >= fee, 'Insufficient fee');
        require(IERC20(coinContract).totalSupply() > 0, 'Not ERC20 Contract');
        require(IERC20(coinContract).balanceOf(_msgSender()) > amount, 'Not enough balance');
        require(IERC20(coinContract).allowance(_msgSender(), address(this)) >= amount, 'Allowance balance not enough');
        _coinShare[shareId] = CoinShare(_msgSender(), coinContract, amount);
        _feeBalance = _feeBalance + fee;
    }

    function recordShareChainCoin(uint256 shareId, uint256 amount, uint256 fee, bytes calldata signature) external payable {
        require(_nftShares[shareId].provider == address(0), 'ShareId registered');
        require(_coinShare[shareId].provider == address(0), 'ShareId registered');
        require(_verifyShareSignature(shareId, _msgSender(), amount, fee, signature), 'Invalid visit');
        require(msg.value >= amount + fee, 'insufficient amount');
        _coinShare[shareId] = CoinShare(_msgSender(), address(0), amount);
        _feeBalance = _feeBalance + fee;
    }

    function receiveSharedNft(uint256 shareId, bytes calldata signature) external {
        require(_nftShares[shareId].balance > 0, 'Invalid share or expired');
        require(_verifyReceiveSignature(shareId, _nftShares[shareId].provider, _nftShares[shareId].nftContract, signature), 'Not valid request');
        if (_nftShares[shareId].contractType == uint8(1)) {
            IERC721 nft = IERC721(_nftShares[shareId].nftContract);
            require(nft.isApprovedForAll(_nftShares[shareId].provider, address(this)), 'Not authorized');
            require(nft.ownerOf(_nftShares[shareId].tokenId) == _nftShares[shareId].provider, 'Not token owner');
            nft.safeTransferFrom(_nftShares[shareId].provider, _msgSender(), _nftShares[shareId].tokenId);
        } else if (_nftShares[shareId].contractType == uint8(2)) {
            IERC1155 nft = IERC1155(_nftShares[shareId].nftContract);
            require(nft.isApprovedForAll(_nftShares[shareId].provider, address(this)), 'Not Authorized');
            require(nft.balanceOf(_nftShares[shareId].provider, _nftShares[shareId].tokenId) > 0, 'Not token owner');
            nft.safeTransferFrom(_nftShares[shareId].provider, _msgSender(), _nftShares[shareId].tokenId, 1, '0x0');
        }
        emit ShareReceivedEvent(shareId, _msgSender());
    }

    function receiveSharedCoin(uint256 shareId, bytes calldata signature) external {
        require(_coinShare[shareId].balance > 0, 'Invalid share or expired');
        CoinShare memory share = _coinShare[shareId];
        require(_verifyReceiveSignature(shareId, share.provider, address(share.coinContract), signature), 'Not valid request');
        if (share.coinContract != address(0)) {
            require(IERC20(share.coinContract).balanceOf(share.provider) >= share.balance, 'Not enough balance');
            require(IERC20(share.coinContract).allowance(share.provider, address(this)) >= share.balance, 'Allowance balance not enough');
            IERC20(share.coinContract).transferFrom(share.provider, _msgSender(), share.balance);
        } else {
            bool sent = payable(_msgSender()).send(share.balance);
            require(sent, 'send crypto failed');
        }
        emit ShareReceivedEvent(shareId, _msgSender());
    }

    function receiveSharedNftBySystem(uint256 shareId, address receiver) external onlySystemCall {
        require(_nftShares[shareId].balance > 0, 'Invalid share or expired');
        if (_nftShares[shareId].contractType == uint8(1)) {
            IERC721 nft = IERC721(_nftShares[shareId].nftContract);
            require(nft.isApprovedForAll(_nftShares[shareId].provider, address(this)), 'Not authorized');
            require(nft.ownerOf(_nftShares[shareId].tokenId) == _nftShares[shareId].provider, 'Not token owner');
            nft.safeTransferFrom(_nftShares[shareId].provider, receiver, _nftShares[shareId].tokenId);
        } else if (_nftShares[shareId].contractType == uint8(2)) {
            IERC1155 nft = IERC1155(_nftShares[shareId].nftContract);
            require(nft.isApprovedForAll(_nftShares[shareId].provider, address(this)), 'Not Authorized');
            require(nft.balanceOf(_nftShares[shareId].provider, _nftShares[shareId].tokenId) > 0, 'Not token owner');
            nft.safeTransferFrom(_nftShares[shareId].provider, receiver, _nftShares[shareId].tokenId, 1, '0x0');
        }
        emit ShareReceivedEvent(shareId, receiver);
    }

    function receiveSharedCoinBySystem(uint256 shareId, address payable receiver) external onlySystemCall {
        require(_coinShare[shareId].balance > 0, 'Invalid share or expired');
        CoinShare memory share = _coinShare[shareId];
        if (share.coinContract != address(0)) {
            require(IERC20(share.coinContract).balanceOf(share.provider) >= share.balance, 'Not enough balance');
            require(IERC20(share.coinContract).allowance(share.provider, address(this)) >= share.balance, 'Allowance balance not enough');
            IERC20(share.coinContract).transferFrom(share.provider, receiver, share.balance);
        } else {
            bool sent = payable(receiver).send(share.balance);
            require(sent, 'send crypto failed');
        }
        emit ShareReceivedEvent(shareId, receiver);
    }

    function _verifyShareSignature(uint256 shareId, address provider, uint256 amount, uint256 fee, bytes calldata signature) internal view returns (bool) {
        (bool verify, ) = _testShareSignature(shareId, provider, amount, fee, signature);
        return verify;
    }

    function _testShareSignature(uint256 shareId, address provider, uint256 amount, uint256 fee, bytes calldata signature) internal view returns (bool, address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 messageHash = keccak256(abi.encodePacked(shareId, provider, amount, fee));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(prefix, messageHash));
        address signer = _recoverSigner(ethSignedMessageHash, signature);
        return (signer == _verifyAccount, signer);
    }

    function _verifyReceiveSignature(uint256 shareId, address provider, address shareContract, bytes calldata signature) internal view returns (bool) {
        (bool verify,) = _testReceiveSignature(shareId,provider,shareContract,signature);
        return verify;
    }

    function _testReceiveSignature(uint256 shareId, address provider, address shareContract, bytes calldata signature) internal view returns (bool, address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 messageHash = keccak256(abi.encodePacked(shareId, provider, shareContract));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked(prefix, messageHash));
        address signer = _recoverSigner(ethSignedMessageHash, signature);
        return (signer == _verifyAccount, signer);
    }

    function _recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r,bytes32 s,uint8 v) = _splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _splitSignature(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v){
        require(signature.length == 65, 'Invalid signature length');
        assembly{
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
    }

    function initialize(address verifyAccount_) external initializer {
        _verifyAccount = verifyAccount_;
        _transferOwnership(_msgSender());
    }

    function configVerifyAccount(address verifyAccount_) external onlyOwner {
        _verifyAccount = verifyAccount_;
    }

    function currentVerifyAccount() view external returns (address){
        return _verifyAccount;
    }

    function configAssetAccount(address assetAccount_) external onlyOwner {
        _assetAccount = assetAccount_;
    }

    function currentAssetAccount() view external returns (address) {
        return _assetAccount;
    }

    function withdrawBalance(uint256 amount) external {
        require(_msgSender() == _verifyAccount, 'Forbidden call');
        bool sent = payable(_assetAccount).send(amount);
        require(sent, 'withdraw failed');
        if (_feeBalance >= amount) {
            _feeBalance = _feeBalance - amount;
        } else {
            _feeBalance = 0;
        }
    }

    function feeBalance() external view onlySystemCall returns (uint256){
        return _feeBalance;
    }
}