/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts_v2/utils/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

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


// File contracts_v2/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.9;

/**
 * @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
     * Handles the receipt of an NFT.
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     *  otherwise the caller will revert the transaction. The selector to be
     *  returned can be obtained as `this.onERC721Received.selector`. This
     *  function MAY throw to revert and reject the transfer.
     * @dev Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts_v2/token/ERC721/ERC721Receiver.sol



pragma solidity ^0.8.9;


/**
 * @title ERC721 Safe Transfers Receiver Contract.
 * @dev The function `onERC721Received(address,address,uint256,bytes)` needs to be implemented by a child contract.
 */
abstract contract ERC721Receiver is IERC165, IERC721Receiver {
    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;
    bytes4 internal constant _ERC721_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }
}


// File contracts_v2/utils/access/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.9;

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


// File contracts_v2/utils/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.9;

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


// File contracts_v2/utils/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.9;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File contracts_v2/interfaces/IGBotInventory.sol



pragma solidity ^0.8.9;

interface IGBotInventory {
    function mintGBot(address to, uint256 nftId, uint256 metadata, bytes memory data) external;
    function getMetadata(uint256 tokenId) external view returns (uint256 metadata);
    function upgradeGBot(uint256 tokenId, uint256 newMetadata) external;

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

        /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}


// File contracts_v2/game/GBotBreeder/GBotBabyLock.sol



pragma solidity ^0.8.9;

/**
 * @dev An ERC721 token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 */
contract GBotBabyLock {

    // mapping tokenId => releaseTime
    mapping(uint => uint) internal lockedGBots;
    // mapping owner => tokenIds
    mapping(address => uint[]) internal ownerBabyBots;

    function _lockToken(uint256 time, uint256 tokenId) internal virtual {
        require(time > 0, "TokenTimelock: release time is not defined");
        lockedGBots[tokenId] = block.timestamp + time;
    }

    /**
     * @return TokenIds and Release Times for the locked bots
     */
    function getReleaseTime(address owner) public view virtual returns (uint[] memory, uint[] memory) {
        uint[] memory tokenIds = ownerBabyBots[owner];
        uint[] memory releaseTimes = new uint[](tokenIds.length);

        for (uint i=0; i < tokenIds.length; i++) {
               releaseTimes[i] = lockedGBots[tokenIds[i]];
        }
        return (tokenIds,releaseTimes);
    }

    /**
     * @return Array of baby bots for owner
     */
    function getOwnerBabyBots(address owner) public view virtual returns (uint256[] memory) {
        return ownerBabyBots[owner];
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function _releaseLock(uint256 tokenId, address owner) internal virtual {
        require(block.timestamp >= lockedGBots[tokenId], "TokenTimelock: current time is before release time");
        uint[] memory tokenIds = ownerBabyBots[owner];
        // Delete from owners array
        for (uint i=0; i < tokenIds.length; i++) {
            if (tokenIds[i] == tokenId) {
                delete ownerBabyBots[owner][i];
            }
        }
        // Delete release time
        delete lockedGBots[tokenId];
    }
}


// File contracts_v2/interfaces/IGBotMetadataGenerator.sol



pragma solidity ^0.8.9;

interface IGBotMetadataGenerator {
    function generateMetadata(uint256 packTier, uint256 seed, uint256 counter) external view returns (uint256 metadata);
    function validateMetadata(uint256 metadata) external pure returns (bool valid);
    function upgradeMetadata(uint256 metadata, uint256 position, uint256 propertyValue) external pure returns (uint256 newMetadata);
    function generateBabyMetadata(uint256[] memory tokenIds, uint256[] memory parentMetadata, uint256 seed, uint256 counter) external view returns (uint256 metadata);
    function generateEvolutionMetadata(uint256 oldMetadata, uint256 seed) external view returns (uint256 metadata);
    function determineEvolutionRarity(uint256 rarity, uint256 seed) external pure returns (uint256 evolutionRarity);
    function determineEvolutionVisuals(uint256 rarity, uint256 seed) external view returns (uint256 design);
}


// File contracts_v2/token/ERC20/IERC20.sol



pragma solidity ^0.8.9;

/**
 * @title ERC20 Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}


// File contracts_v2/interfaces/IERC20BurnableToken.sol



pragma solidity ^0.8.9;

/**
 * @title ERC20 Token Standard with burnable merged
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20BurnableToken {

        /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * Burns `value` tokens from the message sender, decreasing the total supply.
     * @dev Reverts if the sender owns less than `value` tokens.
     * @dev Emits a {IERC20-Transfer} event with `_to` set to the zero address.
     * @param value the amount of tokens to burn.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function burn(uint256 value) external returns (bool);

    /**
     * Burns `value` tokens from `from`, using the allowance mechanism and decreasing the total supply.
     * @dev Reverts if `from` owns less than `value` tokens.
     * @dev Reverts if `from` is not the sender and the sender is not approved by `from` for at least `value` tokens.
     * @dev Emits a {IERC20-Transfer} event with `_to` set to the zero address.
     * @dev Emits a {IERC20-Approval} event if `from` is not the sender (non-standard).
     * @param from the account to burn the tokens from.
     * @param value the amount of tokens to burn.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function burnFrom(address from, uint256 value) external returns (bool);

    /**
     * Burns `values` tokens from `owners`, decreasing the total supply.
     * @dev Reverts if one `owners` and `values` have different lengths.
     * @dev Reverts if one of `owners` owns less than the corresponding `value` tokens.
     * @dev Reverts if one of `owners` is not the sender and the sender is not approved the corresponding `owner` and `value`.
     * @dev Emits a {IERC20-Transfer} event with `_to` set to the zero address.
     * @dev Emits a {IERC20-Approval} event (non-standard).
     * @param owners the accounts to burn the tokens from.
     * @param values the amounts of tokens to burn.
     * @return a boolean value indicating whether the operation succeeded.
     */
    function batchBurnFrom(address[] calldata owners, uint256[] calldata values) external returns (bool);
}


// File contracts_v2/game/GBotBreeder/BreedingProperties.sol



pragma solidity ^0.8.9;

abstract contract BreedingProperties {

// GBots rarity
uint256 internal constant GBOT_RARITY_STARTER = 0;
uint256 internal constant GBOT_RARITY_COMMON = 1;
uint256 internal constant GBOT_RARITY_RARE = 2;
uint256 internal constant GBOT_RARITY_EPIC = 3;
uint256 internal constant GBOT_RARITY_LEGENDARY = 4;
uint256 internal constant GBOT_RARITY_MYTHICAL = 5;
uint256 internal constant GBOT_RARITY_ULTIMATE = 6;
uint256 internal constant RARITY_BITS = 223;

//GBots Type
uint256 internal constant GBOT_TYPE_STARTER = 1;
uint256 internal constant GBOT_TYPE_BABY = 2;
uint256 internal constant GBOT_TYPE_ADULT = 3;
uint256 internal constant GBOT_TYPE_RETIRED = 4;

// Constants bits
uint256 internal constant CLASS_ID_BITS = 231; //8
uint256 internal constant STRENGTH_BITS = 167;
uint256 internal constant SPEED_BITS = 159;
uint256 internal constant BATTERY_BITS = 151;
uint256 internal constant HP_BITS = 143;
uint256 internal constant ATTACK_BITS = 135;
uint256 internal constant DEFENSE_BITS = 127;
uint256 internal constant CRITICAL_BITS = 119;
uint256 internal constant LUCK_BITS = 111;
uint256 internal constant SPECIAL_BITS = 103;
uint256 internal constant TYPE_ID_BITS = 247;
uint256 internal constant ENERGY_CORES_BITS = 191;
uint256 internal constant VISUALS_BITS = 207;
uint256 internal constant COUNTER_BITS = 0;

// MOP MIN Values
uint256 internal constant BABY_MOP_MIN_COMMON = 20;
uint256 internal constant BABY_MOP_MIN_RARE = 35;
uint256 internal constant BABY_MOP_MIN_EPIC = 50;
uint256 internal constant BABY_MOP_MIN_LEGENDARY = 65;
uint256 internal constant BABY_MOP_MIN_MYTHICAL = 79;
uint256 internal constant BABY_MOP_MIN_ULTIMATE = 89;

// MOP MAX Values
uint256 internal constant BABY_MOP_MAX_COMMON = 50;
uint256 internal constant BABY_MOP_MAX_RARE = 65;
uint256 internal constant BABY_MOP_MAX_EPIC = 88;
uint256 internal constant BABY_MOP_MAX_LEGENDARY = 90;
uint256 internal constant BABY_MOP_MAX_MYTHICAL = 95;
uint256 internal constant BABY_MOP_MAX_ULTIMATE = 99;

// Bitwise operations
uint256 internal constant ONE = uint(1);
    uint256 internal constant ONES = ~uint256(0);
}


// File contracts_v2/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.9;

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


// File contracts_v2/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.9;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File contracts_v2/interfaces/IGBotCalculations.sol



pragma solidity ^0.8.9;

interface IGBotCalculations {
    // Evolution functions
    function determineEvolutionGmeeCost(uint256 rarity) external view returns (uint256 gmeeCost);
    function determineEvolutionOmpCost(uint256 rarity, uint256 currentCop) external view returns (uint256 ompCost);
    function determineEvolutionTime(uint256 rarity) external pure returns (uint256 lockTime);
    // Upgrader functions
    function determineUpgradeTime(uint256 rarity, uint256 currentCop, uint256 upgradeCop) external pure returns (uint256);
    function determineUpgradeGmeeCost(uint256 rarity, uint256 copDifference) external view returns (uint256 cost);
    function determineUpgradeOmpCost(uint256 rarity, uint256 currentCop, uint256 upgradeCop) external view returns (uint256);
    // Breeding functions
    function determineBreedingGmeeCost(uint256[] memory parentsMetadatas) external view returns (uint256 gmeeCost);
    function determineBreedingOmpCost(uint256[] memory parentsMetadatas) external view returns (uint256 ompCost);
    function determineBreedingTime() external view returns (uint256 breedingTime);
}


// File contracts_v2/game/GBotBreeder/GBotBreeder.sol



pragma solidity ^0.8.9;











contract GBotBreeder is ERC721Receiver, Ownable, Pausable, GBotBabyLock, BreedingProperties {
  using ECDSA for bytes32;


  IGBotInventory private GBotContract;
  IGBotMetadataGenerator private MetadataGenerator;
  IGBotCalculations private GBotCalculations;
  IERC20 gmeeToken;
  IERC20BurnableToken ompToken;
  address payable public payoutWallet;
  mapping(address => uint[]) private babyBotOwners;
  address[] private allOwners;
  mapping(address => uint256) public nonces;
  address public signerKey;
  uint256 private counter = 1;

  //Events
  event GBotReceived(address indexed operator, address indexed from, uint256 tokenId, bytes indexed data);
  event BabyGBotMinted(uint256 indexed tokenId, address indexed owner);
  event BreedingStarted(address indexed owner, uint256[] parentsTokenIds, uint256[] parentMetadata, uint256 tokenId, uint256 lockTimestamp);

    constructor(
        address GBotInventory_,
        address MetadataGenerator_,
        address GBotCalculations_,
        address gmeeToken_,
        address ompToken_,
        address payable payoutWallet_
    )
    {
        require(payoutWallet_ != address(0), "Payout: zero address");
        require(gmeeToken_ != address(0), "GMEE Token: zero address");
        require(ompToken_ != address(0), "OMP Token: zero address");
        payoutWallet = payoutWallet_;
        gmeeToken = IERC20(gmeeToken_);
        ompToken = IERC20BurnableToken(ompToken_);
        GBotContract = IGBotInventory(GBotInventory_);
        MetadataGenerator = IGBotMetadataGenerator(MetadataGenerator_);
        GBotCalculations = IGBotCalculations(GBotCalculations_);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override whenNotPaused returns (bytes4) {
        emit GBotReceived(operator,from,tokenId,data);
        return this.onERC721Received.selector;
    }

    /****************************************************** ADMIN FUNCTIONS **********************************************/

    function setSignerKey(address signerKey_) external onlyOwner {
        signerKey = signerKey_;
    }

    function setPayoutWallet(address payable payoutWallet_) external onlyOwner {
        payoutWallet = payoutWallet_;
    }

    function setMetadataGenerator(address metadataGenerator_) external onlyOwner {
        MetadataGenerator = IGBotMetadataGenerator(metadataGenerator_);
    }

     function setCalculations(address gBotCalculations_) external onlyOwner {
        GBotCalculations = IGBotCalculations(gBotCalculations_);
    }

    function exit() onlyOwner public {
        for (uint i=0; i < allOwners.length; i++) {
            uint[] memory tokenIds = (babyBotOwners[allOwners[i]]);
            for (uint j=0; j < tokenIds.length; j++) {
              if(tokenIds[j] != 0) {
              GBotContract.safeTransferFrom(address(this), _msgSender(), tokenIds[j]);
              }
            }
        }
    } 

    /****************************************************** PUBLIC FUNCTIONS **********************************************/

    function checkSignature(address sender, bytes calldata sig, uint256[] memory tokenIds) public view returns(uint256) {
        require(signerKey != address(0), "GBot Breeding: signer key not set");
        
        // Check for signer key and get seed out of it
        uint256 nonce = nonces[sender];
        bytes32 hash_ = keccak256(abi.encodePacked(sender, tokenIds, nonce));
        require(hash_.toEthSignedMessageHash().recover(sig) == signerKey, "GBot Breeding: invalid signature");
        uint256 seed = uint256(keccak256(sig));
        return seed;
    }
    
    function breed(address sender, bytes calldata sig, uint256[] memory tokenIds) public virtual whenNotPaused {
        require(tokenIds.length >= 2 && tokenIds.length <= 5, "GBot Breeding: Unexpected number of parents provided");
        checkTokenIds(tokenIds);
        uint256 seed = checkSignature(sender, sig, tokenIds);

        uint256[] memory parentMetadata = new uint256[](tokenIds.length);
        uint256[] memory parentsEnergyCores = new uint256[](tokenIds.length);

        // CHECKS
        for (uint i=0; i < tokenIds.length; i++) {
          // Get metadata
          parentMetadata[i] = GBotContract.getMetadata(tokenIds[i]);
          // Check owner
          address owner = GBotContract.ownerOf(tokenIds[i]);
          require(owner==_msgSender(), "GBot Breeding: Not the rightful owner");
          // Check type
          uint256 gBotType = getMetadataForProperty(parentMetadata[i], TYPE_ID_BITS);
          require(gBotType == 3, "GBot Breeding: Not an adult bot");
          // Check energy cores
          uint256 energyCores = getMetadataForProperty(parentMetadata[i], ENERGY_CORES_BITS);
          require(energyCores > 0, "GBot Breeding: Not enough energy cores");
          parentsEnergyCores[i] = getMetadataForProperty(parentMetadata[i], ENERGY_CORES_BITS);
        }
      
        // Calculate cost in gmee, check balance and allowance
        uint256 cost = GBotCalculations.determineBreedingGmeeCost(parentMetadata);
        require(cost <= gmeeToken.balanceOf(_msgSender()), "Not enough GMEE");
        require(gmeeToken.allowance(_msgSender(), address(this)) >= cost, "GMEE: Check the token allowance");        
        
        // Calculate cost in omp, check balance and allowance
        uint ompCost = GBotCalculations.determineBreedingOmpCost(parentMetadata);
        require(ompCost <= ompToken.balanceOf(_msgSender()), "Not enough OMP");
        require(ompToken.allowance(_msgSender(), address(this)) >= ompCost, "OMP: Check the token allowance");        

        // Pay
        gmeeToken.transferFrom(_msgSender(), payoutWallet, cost);
        ompToken.burnFrom(_msgSender(), ompCost);

        // Burn parents energy cores
        for (uint i=0; i < tokenIds.length; i++) {
          uint256 energyCores = getMetadataForProperty(parentMetadata[i], ENERGY_CORES_BITS);
          GBotContract.upgradeGBot(tokenIds[i], upgradeMetadata(parentMetadata[i], ENERGY_CORES_BITS, energyCores -1));
        }        

        // Generate metadata
        uint256 babyBotMetadata = MetadataGenerator.generateBabyMetadata(tokenIds, parentMetadata, seed, counter);
         // If GBot exists
        if (GBotContract.getMetadata(babyBotMetadata) != 0) {
          counter++;
          babyBotMetadata = MetadataGenerator.generateBabyMetadata(tokenIds, parentMetadata, seed, counter);
        }
        uint256 babyLockTime = GBotCalculations.determineBreedingTime();
        // Lock Baby GBot
          _lockToken(babyLockTime, babyBotMetadata);
        // Save Baby GBot tokenId to user
        addRightfulOwner(_msgSender(), babyBotMetadata);

        counter++;
        nonces[_msgSender()] ++;
        emit BreedingStarted(_msgSender(), tokenIds, parentMetadata, babyBotMetadata, block.timestamp + babyLockTime);
    }

    function claimGBot(uint256 tokenId) public virtual {
        require(isRightfulOwner(tokenId) == true, "GBot Breeding: Not the rightful owner");
        _releaseLock(tokenId, _msgSender());
        bytes memory data = "";
        GBotContract.mintGBot(_msgSender(), tokenId, tokenId, data);
        removeOwnerFromQueue(tokenId);
        emit BabyGBotMinted(tokenId,_msgSender());
    }

    /****************************************************** HELPER FUNCTIONS **********************************************/

    function checkTokenIds(uint256[] memory tokenIds) private pure {
        for (uint i=0; i < tokenIds.length - 1; i++) {
          for (uint j=i+1; j < tokenIds.length; j++) {
            require(tokenIds[i] != tokenIds[j], "GBot Breeding: Duplicate GBots found");
          }
        }
    }
    
    function upgradeMetadata(uint256 metadata, uint256 position, uint256 propertyValue) public pure returns (uint256){
       uint bits = 8;
       if (position == VISUALS_BITS) 
            bits = 16;
       if (position == COUNTER_BITS)
            bits = 95;
       
       require(0 < bits && position < 256 && position + bits <= 256, "GetMetadata: Incorrect number of bits in metadata");
       
       uint256 mask = (1 << bits) - 1;
       mask = mask << position;
       mask = ~mask;
       
       metadata = metadata & mask;
       return metadata |= (propertyValue << position);
    }

    function addRightfulOwner(address _owner, uint256 tokenId) private {
        // If owner is not allready in the master list, push it
        if (babyBotOwners[_owner].length == 0){
          allOwners.push(_owner);
        }
        babyBotOwners[_owner].push(tokenId);
    }

    function removeOwnerFromQueue (uint256 tokenId) private {
        uint[] memory tokenIds = babyBotOwners[_msgSender()];
        uint arrayLength = tokenIds.length;
        for (uint i=0; i < arrayLength; i++) {
        if(tokenIds[i]==tokenId){
            delete babyBotOwners[_msgSender()][i];
            }
        }
    }

    function isRightfulOwner(uint256 tokenId) private view returns (bool){
        uint[] memory tokenIds = babyBotOwners[_msgSender()];
        uint arrayLength = tokenIds.length;
        for (uint i=0; i < arrayLength; i++) {
        if(tokenIds[i]==tokenId){
            return true;
            }
        }
        return false;
    }

    function getMetadataForProperty(uint256 metadataId, uint256 position) internal pure returns (uint256) {
        uint bits = 8;
        if (position == VISUALS_BITS) {
            bits = 16;
         }
        require(0 < bits && position < 256 && position + bits <= 256, "GetMetadata: Incorrect number of bits in metadata");
        return metadataId >> position & ONES >> 256 - bits;
    }

    function pause() onlyOwner public {
        _pause();
    } 
     
    function unpause() onlyOwner public {
        _unpause();
    }   
}