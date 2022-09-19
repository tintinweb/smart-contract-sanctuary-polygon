// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../interfaces/IBaseERC721.sol";
import "../interfaces/ICivilizations.sol";

/**
 * @title Civilizations
 * @notice This contract stores all the [BaseERC721](/docs/base/BaseERC721.md) instances usable on the environmne. The contract
 * is in charge of token ownership verifications and generating/storing composable IDs for each character.
 *
 * @notice Implementation of the [ICivilizations](/docs/interfaces/ICivilizations.md) interface.
 */

contract Civilizations is ICivilizations, Ownable, Pausable {
    using Address for address;

    // =============================================== Storage ========================================================
    /** @notice Map to track the supported [BaseERC721](/docs/base/BaseERC721.md) instances. */
    mapping(uint256 => address) civilizations;

    /** @notice Array to track the [BaseERC721](/docs/base/BaseERC721.md) IDs. */
    uint256[] private _civilizations;

    /** @notice Map to track the count of address mints. */
    mapping(address => uint256) private _minters;

    /** @notice Constant for address of the `ERC20` token used to purchase. */
    address public token;

    /** @notice Map to track the character upgrades. */
    mapping(bytes => mapping(uint256 => bool)) private character_upgrades;

    /** @notice Map to track the upgrades information. */
    mapping(uint256 => Upgrade) public upgrades;

    /** @notice Map to the price to mint characters. */
    uint256 public price;

    // =============================================== Events =========================================================

    /**
     * @notice Event emmited when the [mint](#mint) function is called.
     *
     * Requirements:
     * @param _owner    Owner of the minted token.
     * @param _id       Composed ID of the character.
     */
    event Summoned(address indexed _owner, bytes indexed _id);

    /**
     * @notice Event emmited when the [buyUpgrade](#buyUpgrade) function is called.
     *
     * Requirements:
     * @param _id   Composed ID of the character.
     * @param _upgrade_id   ID of the upgrade purchased.
     */
    event UpgradePurchased(bytes indexed _id, uint256 indexed _upgrade_id);

    // =============================================== Setters ========================================================

    /**
     * @notice Constructor.
     *
     * Requirements:
     * @param _token    Address of the token used to purchase upgrades.
     */
    constructor(address _token) {
        token = _token;
        upgrades[1] = Upgrade(0, false);
        upgrades[2] = Upgrade(0, false);
        upgrades[3] = Upgrade(0, false);
    }

    /** @notice Pauses the contract */
    function pause() public onlyOwner {
        _pause();
    }

    /** @notice Resumes the contract */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Activates or deactivates an upgrade purchase.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade to change.
     * @param _available     Boolean to activate/deactivate.
     */
    function setInitializeUpgrade(uint256 _upgrade_id, bool _available)
        public
        onlyOwner
    {
        require(
            _upgrade_id > 0 && _upgrade_id <= 3,
            "Civilizations: setInitializeUpgrade() invalid upgrade id."
        );
        require(
            upgrades[_upgrade_id].price != 0,
            "Civilizations: setInitializeUpgrade() no price set."
        );
        upgrades[_upgrade_id].available = _available;
    }

    /**
     * @notice Sets the price to purchase an upgrade.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade to change.
     * @param _price     Amount of tokens to pay for the upgrade.
     */
    function setUpgradePrice(uint256 _upgrade_id, uint256 _price)
        public
        onlyOwner
    {
        require(
            _upgrade_id > 0 && _upgrade_id <= 3,
            "Civilizations: setUpgradePrice() invalid upgrade id."
        );
        upgrades[_upgrade_id].price = _price;
    }

    /**
     * @notice Sets the price to mint a character.
     *
     * Requirements:
     * @param _price     Amount of tokens to pay for the upgrade.
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /**
     * @notice Changes the token address to charge.
     *
     * Requirements:
     * @param _token    Address of the new token to charge.
     */
    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    /**
     * @notice Adds a new [BaseERC721](/docs/base/BaseERC721.md) instance to the valid civilizations.
     *
     * Requirements:
     * @param _civilization     Address of the [BaseERC721](/docs/base/BaseERC721.md) instance to add.
     */
    function addCivilization(address _civilization) public onlyOwner {
        require(
            _civilization != address(0),
            "Civilizations: addCivilization() civilization address is empty."
        );
        require(
            msg.sender == Ownable(_civilization).owner(),
            "Civilizations: addCivilization() missing civilization ownership."
        );
        uint256 _civilization_id = _civilizations.length + 1;
        civilizations[_civilization_id] = _civilization;
        _civilizations.push(_civilization_id);
    }

    /**
     * @notice Creates a new token of the valid civilizations list to the `msg.sender`.
     *
     * Requirements:
     * @param _civilization_id     ID of the civilization.
     */
    function mint(uint256 _civilization_id) public whenNotPaused {
        require(
            _civilization_id != 0 && _civilization_id <= _civilizations.length,
            "Civilizations: mint() invalid civilization id."
        );
        require(
            civilizations[_civilization_id] != address(0),
            "Civilizations: mint() invalid civilization address."
        );
        require(
            _canMint(msg.sender),
            "Civilizations: mint() address already minted."
        );
        IERC20(token).transferFrom(msg.sender, owner(), price);
        _addMint(msg.sender);
        emit Summoned(
            msg.sender,
            getTokenID(
                _civilization_id,
                IBaseERC721(civilizations[_civilization_id]).mint(msg.sender)
            )
        );
    }

    /**
     * @notice Purchase an upgrade and marks it as available for the provided composed ID.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     * @param _upgrade_id   ID of the upgrade to purchase.
     */
    function buyUpgrade(bytes memory _id, uint256 _upgrade_id)
        public
        whenNotPaused
    {
        require(
            _upgrade_id > 0 && _upgrade_id <= 3,
            "Civilizations: buyUpgrade() invalid upgrade id."
        );
        require(
            isAllowed(msg.sender, _id),
            "Civilizations: buyUpgrade() msg.sender is not allowed to access this token."
        );
        require(
            upgrades[_upgrade_id].available,
            "Civilizations: buyUpgrade() upgrade is not initialized."
        );
        uint256 _price = upgrades[_upgrade_id].price;
        require(
            IERC20(token).balanceOf(msg.sender) >= _price,
            "Civilizations: buyUpgrade() not enough balance to mint tokens."
        );
        require(
            IERC20(token).allowance(msg.sender, address(this)) >=
                upgrades[_upgrade_id].price,
            "Civilizations: buyUpgrade() not enough allowance to mint tokens."
        );
        IERC20(token).transferFrom(msg.sender, owner(), _price);
        character_upgrades[_id][_upgrade_id] = true;
        emit UpgradePurchased(_id, _upgrade_id);
    }

    // =============================================== Getters ========================================================

    /**
     * @notice External function to return the upgrades for a composed ID.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _upgrades    Array of booleans for each upgrade.
     */
    function getCharacterUpgrades(bytes memory _id)
        public
        view
        returns (bool[3] memory _upgrades)
    {
        return (
            [
                character_upgrades[_id][1],
                character_upgrades[_id][2],
                character_upgrades[_id][3]
            ]
        );
    }

    /**
     * @notice External function to return global status of an upgrade.
     *
     * Requirements:
     * @param _upgrade_id   ID of the upgrade.
     *
     * @return _upgrade     Upgrade information.
     */
    function getUpgradeInformation(uint256 _upgrade_id)
        public
        view
        returns (Upgrade memory _upgrade)
    {
        require(
            _upgrade_id > 0 && _upgrade_id <= 3,
            "Civilizations: getUpgradeInformation() invalid upgrade id."
        );
        return upgrades[_upgrade_id];
    }

    /**
     * @notice Returns the composed ID of a token from a valid civilization.
     *
     * Requirements:
     * @param _civilization_id  ID of the civilization.
     * @param _token_id         ID of the token to get the composed ID.
     *
     * @return _id              Composed ID of the character.
     */
    function getTokenID(uint256 _civilization_id, uint256 _token_id)
        public
        view
        returns (bytes memory _id)
    {
        require(
            _civilization_id != 0 && _civilization_id <= _civilizations.length,
            "Civilizations: getTokenID() invalid civilization id."
        );
        require(
            IBaseERC721(civilizations[_civilization_id]).exists(_token_id),
            "Civilizations: getTokenID() token not minted."
        );
        return abi.encode(_civilization_id, _token_id);
    }

    /**
     * @notice External function to check if the `msg.sender` can access a token.
     *
     * Requirements:
     * @param _spender      Address to check ownership or allowance.
     * @param _id           Composed ID of the character.
     *
     * @return _allowed     Boolean to check if access is valid.
     */
    function isAllowed(address _spender, bytes memory _id)
        public
        view
        returns (bool _allowed)
    {
        (uint256 _civilization_id, uint256 _token_id) = _decodeID(_id);
        require(
            _civilization_id != 0 && _civilization_id <= _civilizations.length,
            "Civilizations: isAllowed() invalid civilization id."
        );
        address _civilization = civilizations[_civilization_id];
        require(
            _civilization != address(0),
            "Civilizations: isAllowed() address of the civilization not found."
        );
        return
            IBaseERC721(_civilization).isApprovedOrOwner(_spender, _token_id);
    }

    /**
     * @notice External function to check a composed ID is already minted.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _exist       Boolean to check if the token is minted.
     */
    function exists(bytes memory _id) public view returns (bool _exist) {
        (uint256 _civilization_id, uint256 _token_id) = _decodeID(_id);
        require(
            _civilization_id != 0 && _civilization_id <= _civilizations.length,
            "Civilizations: exists() invalid civilization id."
        );
        address _civilization = civilizations[_civilization_id];
        require(
            _civilization != address(0),
            "Civilizations: isAllowed() address of the civilization not found."
        );
        return IBaseERC721(_civilization).exists(_token_id);
    }

    /**
     * @notice External function to return the owner a composed ID.
     *
     * Requirements:
     * @param _id           Composed ID of the character.
     *
     * @return _owner       Address of the owner of the token.
     */
    function ownerOf(bytes memory _id) public view returns (address _owner) {
        (uint256 _civilization_id, uint256 _token_id) = _decodeID(_id);
        require(
            _civilization_id != 0 && _civilization_id <= _civilizations.length,
            "Civilizations: ownerOf() invalid civilization id."
        );
        address _civilization = civilizations[_civilization_id];
        require(
            _civilization != address(0),
            "Civilizations: isAllowed() address of the civilization not found."
        );
        return IERC721(_civilization).ownerOf(_token_id);
    }

    // =============================================== Internal ========================================================

    /**
     * @notice Internal function to add a mint count for the `msg.sender`.
     *
     * Requirements:
     * @param _minter       Address of the minter.
     */
    function _addMint(address _minter) internal {
        _minters[_minter] += 1;
    }

    /**
     * @notice Internal function check if the `msg.sender` can mint a token.
     *
     * Requirements:
     * @param _minter       Address of the minter.
     */
    function _canMint(address _minter) internal view returns (bool) {
        require(
            !Address.isContract(_minter),
            "Civilizations: _canMint() contract cannot mint."
        );
        return _minters[_minter] < 5;
    }

    /**
     * @notice Internal function to decode a composed ID to a civilization instance and token ID.
     *
     * Requirements:
     * @param _id           Composed ID.
     *
     * @return _civilization    The internal ID of the civilization.
     * @return _token_id        The token id of the composed ID.
     */
    function _decodeID(bytes memory _id)
        internal
        pure
        returns (uint256 _civilization, uint256 _token_id)
    {
        return abi.decode(_id, (uint256, uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IBaseERC721
 * @notice Interface for the [BaseERC721](/docs/base/BaseERC721.md) contract.
 */
interface IBaseERC721 {
    /** @notice See [BaseERC721#mint](/docs/base/BaseERC721.md#mint) */
    function mint(address _to) external returns (uint256 _token_id);

    /** @notice See [BaseERC721#isApprovedOrOwner](/docs/base/BaseERC721.md#isApprovedOrOwner) */
    function isApprovedOrOwner(address _spender, uint256 _token_id)
        external
        view
        returns (bool _approved);

    /** @notice See [BaseERC721#exists](/docs/base/BaseERC721.md#exists) */
    function exists(uint256 _token_id) external view returns (bool _exist);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title ICivilizations
 * @notice Interface for the [Civilizations](/docs/core/Civilizations.md) contract.
 */
interface ICivilizations {
    /**
     * @notice Internal struct to store the global state of an upgrade.
     *
     * Requirements:
     * @param price         Price to purchase the upgrade.
     * @param available     Status of the purchase mechanism for the upgrade.
     */
    struct Upgrade {
        uint256 price;
        bool available;
    }

    /** @notice See [Civilizations#pause](/docs/core/Civilizations.md#pause) */
    function pause() external;

    /** @notice See [Civilizations#unpause](/docs/core/Civilizations.md#unpause) */
    function unpause() external;

    /** @notice See [Civilizations#setInitializeUpgrade](/docs/core/Civilizations.md#setInitializeUpgrade) */
    function setInitializeUpgrade(uint256 _upgrade_id, bool _available)
        external;

    /** @notice See [Civilizations#setUpgradePrice](/docs/core/Civilizations.md#setUpgradePrice) */
    function setUpgradePrice(uint256 _upgrade_id, uint256 _price) external;

    /** @notice See [Civilizations#setMintPrice](/docs/core/Civilizations.md#setMintPrice) */
    function setMintPrice(uint256 _price) external;

    /** @notice See [Civilizations#setToken](/docs/core/Civilizations.md#setToken) */
    function setToken(address _token) external;

    /** @notice See [Civilizations#addCivilization](/docs/core/Civilizations.md#addCivilization) */
    function addCivilization(address _civilization) external;

    /** @notice See [Civilizations#mint](/docs/core/Civilizations.md#mint) */
    function mint(uint256 _civilization_id) external;

    /** @notice See [Civilizations#buyUpgrade](/docs/core/Civilizations.md#buyUpgrade) */
    function buyUpgrade(bytes memory _id, uint256 _upgrade_id) external;

    /** @notice See [Civilizations#getCharacterUpgrades](/docs/core/Civilizations.md#getCharacterUpgrades) */
    function getCharacterUpgrades(bytes memory _id)
        external
        view
        returns (bool[3] memory _upgrades);

    /** @notice See [Civilizations#getUpgradeInformation](/docs/core/Civilizations.md#getUpgradeInformation) */
    function getUpgradeInformation(uint256 _upgrade_id)
        external
        view
        returns (Upgrade memory _upgrade);

    /** @notice See [Civilizations#getTokenID](/docs/core/Civilizations.md#getTokenID) */
    function getTokenID(uint256 _civilization_id, uint256 _token_id)
        external
        view
        returns (bytes memory _id);

    /** @notice See [Civilizations#isAllowed](/docs/core/Civilizations.md#isAllowed) */
    function isAllowed(address _spender, bytes memory _id)
        external
        view
        returns (bool _allowed);

    /** @notice See [Civilizations#exists](/docs/core/Civilizations.md#exists) */
    function exists(bytes memory _id) external view returns (bool _exist);

    /** @notice See [Civilizations#ownerOf](/docs/core/Civilizations.md#ownerOf) */
    function ownerOf(bytes memory _id) external view returns (address _owner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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