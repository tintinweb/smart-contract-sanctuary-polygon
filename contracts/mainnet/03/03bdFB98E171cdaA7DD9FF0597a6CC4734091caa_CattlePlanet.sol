// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../other/divestor_upgradeable.sol";
import "../interface/IERC_721.sol";
import "../interface/IERC_1155.sol";

contract AirDrop is OwnableUpgradeable, DivestorUpgradeable, ERC1155HolderUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    struct Meta {
        address banker;
        bool isOpen;
    }

    Meta public meta;

    mapping(uint => address) public addrList;
    mapping(uint => bool) public airdropped;
    mapping(uint => uint) public count;

    modifier onlyBanker () {
        require(_msgSender() == meta.banker || _msgSender() == owner(), "not banker's calling");
        _;
    }

    modifier isOpen {
        require(meta.isOpen, "not open yet");
        _;
    }

    function initialize() initializer public {
        meta.isOpen = true;
        __Ownable_init_unchained();
        meta.banker = 0x468a045212eE6eBe7b832c44970Dd0C66C33AEbb;
        // addrList[0] = null 
        // addrList[1] = "usdt";
        // addrList[1] = "bvg";
        // addrList[2] = "bvt";
        // addrList[3] = "item";
    }

    function setAddr(uint addrId_, address address_) public onlyOwner {
        addrList[addrId_] = address_;
    }

    function setAirdrop(uint[] calldata airdropIds_, bool[] calldata flags_) public onlyBanker returns (bool) {
        for (uint i = 0; i < airdropIds_.length; i++) {
            airdropped[airdropIds_[i]] = flags_[i];
        }
        return true;
    }

    function setBanker(address banker_) public onlyOwner {
        meta.banker = banker_;
    }

    function setIsOpen(bool b_) public onlyOwner {
        meta.isOpen = b_;
    }


    event Airdrop(uint indexed airdropId, address indexed account);
    event ClaimERC20(uint indexed airdropId, address indexed account, uint indexed amount);
    event ClaimERC721(uint indexed airdropId, address indexed account, uint indexed amount);
    event ClaimERC1155(uint indexed airdropId, address indexed account, uint indexed amount);


    function _claimERC20(uint airdropId_, uint fromAddrId_, uint amount_) private {
        IERC20Upgradeable(addrList[fromAddrId_]).transfer(_msgSender(), amount_);
        emit ClaimERC20(airdropId_, _msgSender(), amount_);
    }

    function _claimERC721(uint airdropId_, uint fromAddrId_, uint cardId_, uint amount_) private {
        I721 ERC721 = I721(addrList[fromAddrId_]);
        ERC721.mintMulti(_msgSender(), cardId_, amount_);
        emit ClaimERC721(airdropId_, _msgSender(), amount_);
    }

    function _claimERC1155(uint airdropId_, uint fromAddrId_, uint cardId_, uint amouns_) private {
        I1155(addrList[fromAddrId_]).mint(_msgSender(), cardId_, amouns_);
        emit ClaimERC1155(airdropId_, _msgSender(), amouns_);
    }

    function airdrop(uint airdropId_, uint category_, uint fromAddrId_, uint cardId_, uint amounts_, bytes32 r_, bytes32 s_, uint8 v_) isOpen public {
        bytes32 hash = keccak256(abi.encodePacked(airdropId_, category_, fromAddrId_, cardId_, amounts_, _msgSender()));
        address a = ecrecover(hash, v_, r_, s_);
        require(a == meta.banker, "Invalid signature");
        require(!airdropped[airdropId_], "already received");
        require(addrList[fromAddrId_] != address(0), "wrong from id");

        airdropped[airdropId_] = true;
        emit Airdrop(airdropId_, _msgSender());

        count[category_] += 1;
        if (category_ == 1) {
            _claimERC20(airdropId_, fromAddrId_, amounts_ * 1 ether);
            return;
        }
        if (category_ == 2) {
            _claimERC721(airdropId_, fromAddrId_, cardId_, amounts_);
            return;
        }
        if (category_ == 3) {
            _claimERC1155(airdropId_, fromAddrId_, cardId_, amounts_);

            return;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
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

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


abstract contract DivestorUpgradeable is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    event Divest(address token, address payee, uint value);

    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20Upgradeable(token_).safeTransfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function setApprovalForAll(address token_, address _account) external onlyOwner {
        IERC721(token_).setApprovalForAll(_account, true);
    }
    
    function setApprovalForAll1155(address token_, address _account) external onlyOwner {
        IERC1155(token_).setApprovalForAll(_account, true);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface I721 {
    function balanceOf(address owner) external view returns(uint256);
    function cardIdMap(uint) external view returns(uint); // tokenId => cardId
    function cardInfoes(uint) external returns(uint cardId, string memory name, uint currentAmount, uint maxAmount, string memory _tokenURI);
    function tokenURI(uint256 tokenId_) external view returns(string memory);
    function mint(address player_, uint cardId_) external returns(uint256);
    function mintWithId(address player_, uint id_, uint tokenId_) external returns (bool);
    function mintMulti(address player_, uint cardId_, uint amount_) external returns(uint256);
    function burn(uint tokenId_) external returns (bool);
    function burnMulti(uint[] calldata tokenIds_) external returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function burned() external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function cid(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface I1155 {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);
    function mint(address to_, uint cardId_, uint amount_) external returns (bool);
    function safeTransferFrom(address from, address to, uint256 cardId, uint256 amount, bytes memory data_) external;
    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function balanceOf(address account, uint256 tokenId) external view returns (uint);
    function burned(uint) external view returns (uint);
    function cardInfoes(uint) external view returns(uint cardId, string memory name, uint currentAmount, uint burnedAmount, uint maxAmount, string memory _tokenURI);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interface/IERC_721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "../interface/IBVG.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTStaking is ERC721HolderUpgradeable, OwnableUpgradeable {
    IBEP20 public BVG;
    uint public startTime;
    uint constant miningTime = 30 days;
    uint public totalClaimed;
    uint constant totalSupply = 50000000 ether;
    uint public rate;
    uint constant acc = 1e10;
    I721 public OAT;
    I721 public IGO;
    I721 public info;
    mapping(address => mapping(uint => address)) public cardOwner;
    uint public IGOPower;
    mapping(uint => uint) public OATPower;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        rate = totalSupply / miningTime;
        OATPower[1658] = 585;
        OATPower[1473] = 375;
        OATPower[1423] = 846;
        OATPower[1300] = 1270;
        OATPower[1196] = 274;
        OAT = I721(0x9F471abCddc810E561873b35b8aad7d78e21a48e);
        IGO = I721(0x927a7f35587BC7E59991CCCdd2D4aDd1f0e7bc66);
        info = I721(0xaf84c52D2117dADBD22FC440825e901E8d4E3BD2);
        BVG = IBEP20(0x96cB0Ade2e254c598b12179503C00b007EeB7861);
        IGOPower = 12700;
    }

    struct UserInfo {
        uint power;
        uint debt;
        uint toClaim;
        uint claimed;
        uint[] IGOList;
        uint[] OATList;
    }

    mapping(address => UserInfo) public userInfo;
    uint public debt;
    uint public totalPower;
    uint public lastTime;
    uint public lastDebt;


    mapping(uint => bool)public isOld;
    uint public ssss;
    event Claim(address indexed player, uint indexed amount);
    event Stake(address indexed player, uint indexed tokenId);
    event UnStake(address indexed player, uint indexed tokenId);

    modifier checkEnd(){
        if (block.timestamp >= startTime + miningTime && lastDebt == 0) {
            lastDebt = coutingDebt();
        }
        _;
    }
    function calculateReward(address player) public view returns (uint){
        UserInfo storage user = userInfo[player];
        if (user.power == 0 && user.toClaim == 0) {
            return 0;
        }
        uint rew = user.power * (coutingDebt() - user.debt) / acc;
        return (rew + user.toClaim);
    }

    function setStartTime(uint time_) external onlyOwner {
        require(startTime == 0, 'starting');
        require(block.timestamp < time_ + miningTime, 'out of time');
        require(time_ != 0, 'startTime can not be zero');
        startTime = time_;
    }

    function newOat(uint cid_, uint power, bool b) external onlyOwner {
        OATPower[cid_] = power;
        isOld[cid_] = b;
    }

    function coutingDebt() public view returns (uint _debt){
        if (lastDebt != 0) {
            return lastDebt;
        }
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function stakeIGO(uint tokenId) external {
        require(block.timestamp >= startTime && startTime != 0, 'not start');
        require(cardOwner[address(IGO)][tokenId] == address(0), 'staked');
        require(block.timestamp < startTime + miningTime, 'mining over');
        IGO.safeTransferFrom(msg.sender, address(this), tokenId);
        cardOwner[address(IGO)][tokenId] = msg.sender;
        if (userInfo[msg.sender].power > 0) {
            userInfo[msg.sender].toClaim = calculateReward(msg.sender);
        }
        userInfo[msg.sender].IGOList.push(tokenId);
        uint tempDebt = coutingDebt();
        userInfo[msg.sender].debt = tempDebt;
        userInfo[msg.sender].power += IGOPower;
        debt = tempDebt;
        totalPower += IGOPower;
        lastTime = block.timestamp;
        emit Stake(msg.sender, tokenId);
    }

    function stakeOAT(uint tokenId) external checkEnd{
        require(block.timestamp >= startTime && startTime != 0, 'not start');
        require(cardOwner[address(OAT)][tokenId] == address(0), 'staked');
        require(block.timestamp < startTime + miningTime, 'mining over');
        OAT.safeTransferFrom(msg.sender, address(this), tokenId);
        cardOwner[address(OAT)][tokenId] = msg.sender;
        if (userInfo[msg.sender].power > 0) {
            userInfo[msg.sender].toClaim = calculateReward(msg.sender);
        }
        uint _cid = info.cid(tokenId);
        if (_cid == 0) {
            _cid = OAT.cid(tokenId);
        }
        uint tempPower = OATPower[_cid];
        require(tempPower > 0, 'wrong cid');
        userInfo[msg.sender].OATList.push(tokenId);
        uint tempDebt = coutingDebt();
        userInfo[msg.sender].debt = tempDebt;
        userInfo[msg.sender].power += tempPower;
        debt = tempDebt;
        totalPower += tempPower;
        lastTime = block.timestamp;
        emit Stake(msg.sender, tokenId);
    }

    function unStakeIGO(uint tokenId) external checkEnd{
        require(cardOwner[address(IGO)][tokenId] == msg.sender, 'not card owner');
        delete cardOwner[address(IGO)][tokenId];
        uint tempRew = calculateReward(msg.sender);
        if (tempRew > 0) {
            userInfo[msg.sender].toClaim = tempRew;
        }
        uint tempDebt = coutingDebt();
        userInfo[msg.sender].debt = tempDebt;
        userInfo[msg.sender].power -= IGOPower;
        debt = tempDebt;
        totalPower -= IGOPower;
        lastTime = block.timestamp;
        uint index;
        uint length = userInfo[msg.sender].IGOList.length;
        for (uint i = 0; i < length; i ++) {
            if (userInfo[msg.sender].IGOList[i] == tokenId) {
                index = i;
                break;
            }
        }
        userInfo[msg.sender].IGOList[index] = userInfo[msg.sender].IGOList[length - 1];
        userInfo[msg.sender].IGOList.pop();
        IGO.safeTransferFrom(address(this), msg.sender, tokenId);
        emit UnStake(msg.sender, tokenId);
    }

    function unStakeOAT(uint tokenId) external checkEnd{
        require(cardOwner[address(OAT)][tokenId] == msg.sender, 'not card owner');
        delete cardOwner[address(OAT)][tokenId];
        uint tempRew = calculateReward(msg.sender);
        if (tempRew > 0) {
            userInfo[msg.sender].toClaim = tempRew;
        }
        uint tempDebt = coutingDebt();
        uint _cid = info.cid(tokenId);
        if (_cid == 0) {
            _cid = OAT.cid(tokenId);
        }
        uint tempPower = OATPower[_cid];
        userInfo[msg.sender].debt = tempDebt;
        userInfo[msg.sender].power -= tempPower;
        debt = tempDebt;
        totalPower -= tempPower;
        lastTime = block.timestamp;
        uint index;
        uint length = userInfo[msg.sender].OATList.length;
        for (uint i = 0; i < length; i ++) {
            if (userInfo[msg.sender].OATList[i] == tokenId) {
                index = i;
                break;
            }
        }
        userInfo[msg.sender].OATList[index] = userInfo[msg.sender].OATList[length - 1];
        userInfo[msg.sender].OATList.pop();
        OAT.safeTransferFrom(address(this), msg.sender, tokenId);
        emit UnStake(msg.sender, tokenId);
    }

    function claimReward() external checkEnd{
        uint rew;
        rew = calculateReward(msg.sender);
        require(rew > 0, 'no reward');
        userInfo[msg.sender].claimed += rew;
        userInfo[msg.sender].debt = coutingDebt();
        userInfo[msg.sender].toClaim = 0;
        totalClaimed += rew;
        BVG.mint(msg.sender, rew);
        emit Claim(msg.sender, rew);
    }

    function checkUserOATList(address addr) public view returns (uint[] memory, uint[] memory){
        uint[] memory list = new uint[](userInfo[addr].OATList.length);

        for (uint i = 0; i < list.length; i ++) {
            list[i] = info.cid(userInfo[addr].OATList[i]);
            if(list[i] == 0){
                list[i] = OAT.cid(userInfo[addr].OATList[i]);
            }
        }
        return (userInfo[addr].OATList, list);
    }

    function checkUserIGOList(address addr) public view returns (uint[] memory){
        return userInfo[addr].IGOList;
    }

    function withDrawToken(address token_, address wallet, uint amount) external onlyOwner {
        IERC20(token_).transfer(wallet, amount);
    }

    function withDrawBNB(address wallet) external onlyOwner {
        payable(wallet).transfer(address(this).balance);
    }

    function checkUserOATCid(address addr, uint cid_) public view returns (uint[] memory){
        uint[] memory list;
        uint balance = OAT.balanceOf(addr);
        if (balance == 0) {
            return list;
        }
        uint amount;
        uint id;
        if (isOld[cid_]) {
            for (uint i = 0; i < balance; i ++) {
                id = OAT.tokenOfOwnerByIndex(addr, i);
                if (OAT.cid(id) == cid_) {
                    amount++;
                }
            }
            list = new uint[](amount);
            for (uint i = 0; i < balance; i ++) {
                id = OAT.tokenOfOwnerByIndex(addr, i);
                if (OAT.cid(id) == cid_) {
                    amount--;
                    list[amount] = id;
                }
            }
            return list;
        } else {
            for (uint i = 0; i < balance; i ++) {
                id = OAT.tokenOfOwnerByIndex(addr, i);
                if (info.cid(id) == cid_) {
                    amount++;
                }
            }
            list = new uint[](amount);
            for (uint i = 0; i < balance; i ++) {
                id = OAT.tokenOfOwnerByIndex(addr, i);
                if (info.cid(id) == cid_) {
                    amount--;
                    list[amount] = id;
                }
            }
            return list;
        }

    }

    function checkUserCid(address NFTAddr, address addr, uint cid_) public view returns (uint[] memory){
        uint[] memory list;
        uint balance = I721(NFTAddr).balanceOf(addr);
        if (balance == 0) {
            return list;
        }
        uint amount;
        uint id;
        for (uint i = 0; i < balance; i ++) {
            id = I721(NFTAddr).tokenOfOwnerByIndex(addr, i);
            if (I721(NFTAddr).cid(id) == cid_) {
                amount++;
            }
        }
        list = new uint[](amount);
        for (uint i = 0; i < balance; i ++) {
            id = I721(NFTAddr).tokenOfOwnerByIndex(addr, i);
            if (I721(NFTAddr).cid(id) == cid_) {
                amount--;
                list[amount] = id;
            }
        }
        return list;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.4;
interface IBEP20 {
    function decimals() external view returns (uint8);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    function mint(address addr_, uint amount_) external;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
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
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract Divestor is Ownable {
    using SafeERC20 for IERC20;
    event Divest(address token, address payee, uint value);

    function divest(address token_, address payee_, uint value_) external onlyOwner {
        if (token_ == address(0)) {
            payable(payee_).transfer(value_);
            emit Divest(address(0), payee_, value_);
        } else {
            IERC20(token_).safeTransfer(payee_, value_);
            emit Divest(address(token_), payee_, value_);
        }
    }

    function setApprovalForAll(address token_, address _account) external onlyOwner {
        IERC721(token_).setApprovalForAll(_account, true);
    }
    
    function setApprovalForAll1155(address token_, address _account) external onlyOwner {
        IERC1155(token_).setApprovalForAll(_account, true);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../interface/IHalo.sol";

contract HaloBox is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public cardIdMap;
    struct Types{
        uint ID;
        string name;
        uint currentAmount;
        uint maxAmount;
        string uri;
    }
    mapping(uint => Types) public types;
    constructor() ERC721('HALO Box', 'HALO') {
        myBaseURI = "123456";
        superMinter = _msgSender();
        newTypes(1,'halo box',20000,'box');
        newTypes(2,'CreationTicket',40,'creation');
        newTypes(3,'CattleTicket',1500,'cattle');
        newTypes(4,'BoxTicket',2000,'cattleBox');
        newTypes(5,'HomePlanetTicket',2,'homePlanet');
    }

    function newTypes(uint id,string memory name,uint maxAmount,string memory uri)public onlyOwner{
        require(types[id].ID == 0,'exist tokenId');
        types[id] = Types({
        ID : id,
        name : name,
        currentAmount: 0,
        maxAmount : maxAmount,
        uri : uri
        });

    }

    function editTypes(uint id,string memory name,uint maxAmount,string memory uri)public onlyOwner{
        require(types[id].ID != 0,'nonexistent tokenId');
        types[id] = Types({
        ID : id,
        currentAmount : types[id].currentAmount,
        name : name,
        maxAmount : maxAmount,
        uri : uri
        });

    }
    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint ID) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(types[ID].currentAmount < types[ID].maxAmount,'out of limit');
        cardIdMap[currentId] = ID;
        types[ID].currentAmount ++;
        _mint(player, currentId);
        currentId ++;
    }


    function checkUserCardList(address player,uint ID) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint amount;
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(types[cardIdMap[token]].ID == ID){
                amount ++;
            }
        }
        uint[] memory list = new uint[](amount);
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(types[cardIdMap[token]].ID == ID){
                list[amount - 1] = token;
                amount --;
            }
        }
        return list;

    }

    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,'/',types[cardIdMap[tokenId_]].uri));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHalo{
    function mint(address player, uint ID) external;
    
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function burn(uint tokenId_) external returns (bool);

    function cardIdMap(uint tokenID) external view returns(uint);
}
interface IHalo1155{

    function mint(address to_, uint cardId_, uint amount_) external returns (bool);

    function balanceOf(address account, uint256 tokenId) external view returns (uint);

    function burn(address account, uint256 id, uint256 value) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IHalo.sol";
import "../interface/IBVG.sol";
contract HaloOpen is OwnableUpgradeable {
    IHalo public box;
    IHalo1155 public shred;
    IBEP20 public BVG;
    IERC20 public U;
    uint creationAmount;
    uint normalAmount;
    uint boxAmount;
    uint shredAmount;
    uint public homePlanet;
    uint public pioneerPlanet;
    uint public totalBox;
    uint public BvgPrice;
    uint randomSeed;
    uint[] extractNeed;
    mapping(address => uint) public extractTimes;
    uint public extractCreationAmount;
    uint public lastDay;
    uint public currentDay;
    uint public boxPrice;

    struct OpenInfo {
        address mostOpen;
        uint openAmount;
        address mostCost;
        uint costAmount;
        address lastExtract;

    }

    struct UserInfo {
        uint openAmount;
        uint costAmount;
    }

    struct NormalInfo {
        bool isRefer;
        address invitor;
        uint buyAmount;
    }

    mapping(address => bool) public whiteList;
    mapping(uint => uint) public rewardPool;
    mapping(uint => OpenInfo) public openInfo;
    mapping(uint => mapping(address => UserInfo)) public userInfo;
    mapping(address => NormalInfo) public normalInfo;
    mapping(uint => mapping(address => bool)) public isClaimed;

    event Reward(address indexed addr, uint indexed reward, uint indexed amount);//0 for bvg 1 for shred 2 for creation 3 for normal 4 for box  5 for home 6 for pioneer
    mapping(uint => uint) public openTime;
    uint public buyLimit;
    mapping(address => uint) public userClaimed;
    bool public status;
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        BvgPrice = 1e14;
        totalBox = 20000;
        boxAmount = 2000;
        creationAmount = 20;
        normalAmount = 1000;
        shredAmount = 16980;
        homePlanet = 2;
        pioneerPlanet = 8;
        extractCreationAmount = 20;
        extractNeed = [10, 20, 40, 80];
        boxPrice = 20 ether;
    }
    modifier refreshTime(){
        uint time = block.timestamp - (block.timestamp % 86400);
        if (time != currentDay) {
            lastDay = currentDay;
            currentDay = time;
        }
        _;
    }
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setExtractNeed(uint[] memory need) external onlyOwner {
        extractNeed = need;
    }

    function setBVG(address addr) external onlyOwner {
        BVG = IBEP20(addr);
    }

    function setTicket(address addr) external onlyOwner {
        shred = IHalo1155(addr);
    }

    function setU(address addr) external onlyOwner {
        U = IERC20(addr);
    }

    function setBox(address addr) external onlyOwner {
        box = IHalo(addr);
    }

    function setStatus(bool b) external onlyOwner{
        status = b;
    }

    function setWhiteList(address[] memory addrs, bool b) external onlyOwner {
        for (uint i = 0; i < addrs.length; i++) {
            whiteList[addrs[i]] = b;
        }
    }

    function setBuyLimit(uint limit_) external onlyOwner {
        buyLimit = limit_;
    }

    function buyBox(uint amount, address addr) external {
        require(status,'not open');
        if (buyLimit == 0) {
            buyLimit = 20;
        }
        require(amount <= buyLimit, 'out of limit');
        require(amount <= totalBox, 'out of limit amount');
        totalBox -= amount;
        uint cost = amount * boxPrice;
        if (addr != address(0) && normalInfo[msg.sender].invitor == address(0)) {
            require(normalInfo[addr].isRefer, 'not refer');
            require(addr != msg.sender, 'refer can not be self');
            require(normalInfo[addr].invitor != msg.sender, 'wrong invitor');
            normalInfo[msg.sender].invitor = addr;
        }
        if (whiteList[msg.sender]) {
            cost = cost * 9 / 10;
            whiteList[msg.sender] = false;
        }
        U.transferFrom(msg.sender, address(this), cost);
        if (normalInfo[msg.sender].invitor != address(0)) {
            U.transfer(normalInfo[msg.sender].invitor, cost * 2 / 10);
        }
        for (uint i = 0; i < amount; i++) {
            box.mint(msg.sender, 1);
        }
        if (!normalInfo[msg.sender].isRefer) {
            normalInfo[msg.sender].isRefer = true;
        }
        normalInfo[msg.sender].buyAmount += amount;
    }


    function _processOpenHalo(uint tokenID) internal {
        box.burn(tokenID);
        uint res = rand(boxAmount + creationAmount + normalAmount + shredAmount);
        if (res > shredAmount + boxAmount + normalAmount) {
            box.mint(msg.sender, 2);
            creationAmount --;
            emit Reward(msg.sender, 2, 1);
        } else if (res > shredAmount + boxAmount) {
            box.mint(msg.sender, 3);
            normalAmount --;
            emit Reward(msg.sender, 3, 1);
        } else if (res > shredAmount) {
            box.mint(msg.sender, 4);
            boxAmount --;
            emit Reward(msg.sender, 4, 1);
        } else {
            shred.mint(msg.sender, 1, 1);
            shredAmount --;
            emit Reward(msg.sender, 1, 1);
        }
        userInfo[currentDay][msg.sender].openAmount++;
        if (userInfo[currentDay][msg.sender].openAmount > openInfo[currentDay].openAmount) {
            openInfo[currentDay].mostOpen = msg.sender;
            openInfo[currentDay].openAmount = userInfo[currentDay][msg.sender].openAmount;
        }
        rewardPool[currentDay] += 5000 ether;
    }

    function openBox(uint[] memory tokenIDs) external refreshTime {
        for (uint i = 0; i < tokenIDs.length; i++) {
            _processOpenHalo(tokenIDs[i]);
        }

    }

    function extractNormal(uint amount) external refreshTime {
        require(amount == 5 || amount == 10, 'wrong amount');
        shred.burn(msg.sender, 1, amount);
        if (amount == 5) {
            uint out = rand(100);
            if (out > 80) {
                box.mint(msg.sender, 4);
                emit Reward(msg.sender, 4, 1);
            } else {
                shred.mint(msg.sender, 1, 1);
                BVG.mint(msg.sender, 5 ether * 1e18 / BvgPrice);
                emit Reward(msg.sender, 1, 1);
                emit Reward(msg.sender, 0, 5 ether * 1e18 / BvgPrice / 1e18);
            }
        } else {
            uint out = rand(100);
            if (out > 85) {
                box.mint(msg.sender, 3);
                emit Reward(msg.sender, 3, 1);
            } else {
                shred.mint(msg.sender, 1, 2);
                emit Reward(msg.sender, 1, 2);
                BVG.mint(msg.sender, 10 ether * 1e18 / BvgPrice);
                emit Reward(msg.sender, 0, 10 ether * 1e18 / BvgPrice / 1e18);
            }
        }
        userInfo[currentDay][msg.sender].costAmount += amount;
        if (userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount) {
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        openInfo[currentDay].lastExtract = msg.sender;
        rewardPool[currentDay] += 2000 ether;
        openTime[currentDay] = block.timestamp;
    }

    function extractCreation() external refreshTime {
        require(extractCreationAmount > 0, 'no creationAmount');
        uint times = extractTimes[msg.sender];
        uint need = extractNeed[times];
        shred.burn(msg.sender, 1, need);
        uint out = rand(100);
        if (times == 0) {
            if (out > 95 && extractCreationAmount > 0) {
                box.mint(msg.sender, 2);
                extractCreationAmount --;
                emit Reward(msg.sender, 2, 1);
            } else {
                BVG.mint(msg.sender, 5 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender, 0, 5 ether * 1e18 / BvgPrice / 1e18);
            }
        } else if (times == 1) {
            if (out > 80 && extractCreationAmount > 0) {
                box.mint(msg.sender, 2);
                extractCreationAmount --;
                extractTimes[msg.sender] = 0;
                emit Reward(msg.sender, 2, 1);
            } else {
                BVG.mint(msg.sender, 10 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender, 0, 10 ether * 1e18 / BvgPrice / 1e18);
            }
        } else if (times == 2) {
            if (out > 50 && extractCreationAmount > 0) {
                box.mint(msg.sender, 2);
                extractCreationAmount --;
                extractTimes[msg.sender] = 0;
                emit Reward(msg.sender, 2, 1);
            } else {
                BVG.mint(msg.sender, 20 ether * 1e18 / BvgPrice);
                extractTimes[msg.sender]++;
                emit Reward(msg.sender, 0, 20 ether * 1e18 / BvgPrice / 1e18);
            }
        } else {
            box.mint(msg.sender, 2);
            extractCreationAmount --;
            extractTimes[msg.sender] = 0;
            emit Reward(msg.sender, 2, 1);
        }
        userInfo[currentDay][msg.sender].costAmount += need;
        if (userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount) {
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        openInfo[currentDay].lastExtract = msg.sender;
        openTime[currentDay] = block.timestamp;
        rewardPool[currentDay] += 2000 ether;
    }

    function extractPioneerPlanet(uint amount) external refreshTime {
        amount = 50;
        uint out = rand(1000);
        shred.burn(msg.sender, 1, amount);

        if (out > 925) {
            box.mint(msg.sender, 5);
            homePlanet--;
            emit Reward(msg.sender, 5, 1);
        } else {
            BVG.mint(msg.sender, 50 ether * 1e18 / BvgPrice);
            emit Reward(msg.sender, 0, 50 ether * 1e18 / BvgPrice / 1e18);
        }

        userInfo[currentDay][msg.sender].costAmount += amount;
        if (userInfo[currentDay][msg.sender].costAmount > openInfo[currentDay].costAmount) {
            openInfo[currentDay].costAmount = userInfo[currentDay][msg.sender].costAmount;
            openInfo[currentDay].mostCost = msg.sender;
        }
        rewardPool[currentDay] += 2000 ether;
        openInfo[currentDay].lastExtract = msg.sender;
        openTime[currentDay] = block.timestamp;
    }

    function countingReward(address addr) public view returns (uint){

        uint _lastDay = lastDay;
        uint time = block.timestamp - (block.timestamp % 86400);
        if (time != currentDay) {
            _lastDay = currentDay;
        }
        uint rew;
        if (isClaimed[_lastDay][addr]) {
            return 0;
        }
        if (addr == openInfo[_lastDay].lastExtract) {
            rew += rewardPool[_lastDay] / 2;
        }
        if (addr == openInfo[_lastDay].mostCost) {
            rew += rewardPool[_lastDay] * 3 / 10;
        }
        if (addr == openInfo[_lastDay].mostOpen) {
            rew += rewardPool[_lastDay] * 2 / 10;
        }
        return rew;
    }

    function _processOpen() internal {
        uint out = rand(100);
        if (out > 50) {
            box.mint(msg.sender, 3);
            emit Reward(msg.sender, 3, 1);
        } else {
            shred.mint(msg.sender, 1, 1);
            emit Reward(msg.sender, 1, 1);
        }
    }

    function openCattleBox(uint[] memory tokenID) external {
        for (uint i = 0; i < tokenID.length; i++) {
            require(box.cardIdMap(tokenID[i]) == 4, 'wrong token');
            _processOpen();
            box.burn(tokenID[i]);
        }
    }

    function claimReward() refreshTime external {
        uint rew = countingReward(msg.sender);
        require(rew > 0, 'no reward');
        userClaimed[msg.sender] += rew;
        BVG.mint(msg.sender, rew);
        isClaimed[lastDay][msg.sender] = true;
    }

    function checkInfo(address addr) public view returns (uint, uint, uint, uint){
        return (extractTimes[addr], extractCreationAmount, homePlanet, pioneerPlanet);
    }

    function safePull(address token,address wallet, uint amount) external onlyOwner{
        IERC20(token).transfer(wallet,amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IBVG.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IPlanet721.sol";
contract ClaimTest is OwnableUpgradeable{
    IERC20 public BVT;
    IBEP20 public BVG;
    ICOW public cattle;
    IBOX public box;
    IPlanet721 public planet;
    mapping(address => bool) public planetWhite;
    mapping(address => bool) public cattleWhite;
    uint public planetAmount;
    uint public cattleAmount;
    struct UserInfo{
        bool planetClaimed;
        bool cattleClaimed;
        bool boxClaimed;
        bool bvtClaimed;
        bool bvgClaimed;
    }
    mapping(address => UserInfo) public userInfo;
    uint public bvgClaimAmount;
    uint public bvtClaimAmount;
    uint public bvtClaimedAmount;
    uint public bvgClaimedAmount;
    uint public boxClaimedAmount;
    uint public planetClaimedAmount;
    uint public cattleClaimedAmount;
    mapping(address => bool) public done;
    event ClaimBox(address indexed addr);
    event ClaimCattle(address indexed addr);
    event ClaimPlanet(address indexed addr);
    event ClaimBVT(address indexed addr);
    event ClaimBVG(address indexed addr);
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        bvgClaimAmount = 100000 ether;
        bvtClaimAmount = 5000 ether;
        cattleAmount = 514;
        planetAmount = 100;
    }
    
    function setBvgClaimAmount(uint amount) external onlyOwner{
        bvgClaimAmount = amount;
    }
    
    function setBvtClaimAmount(uint amount) external onlyOwner{
        bvtClaimAmount = amount;
    }
    
    function setAmount(uint catttle_, uint planet_) external onlyOwner{
        cattleAmount = catttle_;
        planetAmount = planet_;
    }
    
    function setBVG(address addr) external onlyOwner{
        BVG = IBEP20(addr);
    }
    
    function setBVT(address addr) external onlyOwner{
        BVT = IERC20(addr);
    }
    
    function setCattle(address addr_) external onlyOwner{
        cattle = ICOW(addr_);
    }
    
    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet721(addr_);
    }
    
    function setBox(address addr) external onlyOwner{
        box = IBOX(addr);
    }
    
    function addPlanetWhite(address[] memory addr,bool b) external onlyOwner{
        for(uint i = 0;i < addr.length; i ++){
            planetWhite[addr[i]] = b;
        }
    }
    
    function addCattleWhite(address[] memory addr,bool b) external onlyOwner{
        for(uint i = 0;i < addr.length; i ++){
            cattleWhite[addr[i]] = b;
        }
    }
    
    function claimPlanet()external{
        require(planetAmount >0,'out of amount');
//        require(planetWhite[msg.sender],'not white list');
//        require(!userInfo[msg.sender].planetClaimed,'claimed');
        planet.mint(msg.sender,1);
        userInfo[msg.sender].planetClaimed = true;
        planetAmount --;
        planetClaimedAmount ++;
        emit ClaimPlanet(msg.sender);
    } 
    
    function claimCattle() external{
        if(!done[msg.sender] && userInfo[msg.sender].cattleClaimed){
            userInfo[msg.sender].cattleClaimed = false;
        }
        require(cattleAmount > 0,'out of amount');
//        require(cattleWhite[msg.sender],'not white list');

//        require(!userInfo[msg.sender].cattleClaimed,'claimed');
        cattle.mint(msg.sender);
        userInfo[msg.sender].cattleClaimed = true;
        cattleClaimedAmount ++;
        cattleAmount--;
        done[msg.sender] = true;
        emit ClaimCattle(msg.sender);
    }
    
    function claimBVG() external{
//        require(!userInfo[msg.sender].bvgClaimed,'claimed');
        BVG.mint(msg.sender,bvgClaimAmount);
        userInfo[msg.sender].bvgClaimed = true;
        bvgClaimedAmount += bvgClaimAmount;
        emit ClaimBVG(msg.sender);
    }

    function setBvgClaimedAmount(uint amount) external onlyOwner{
        bvgClaimedAmount = amount;
    }
    
    function claimBVT() external{
        require(BVT.balanceOf(address(this)) >= bvtClaimAmount,'out of amount');
//        require(!userInfo[msg.sender].bvtClaimed,'claimed');
        BVT.transfer(msg.sender,100000 ether);
        userInfo[msg.sender].bvtClaimed = true;
        bvtClaimedAmount += 100000 ether;
        emit ClaimBVT(msg.sender);
    }
    
    function claimBox() external{
//        require(!userInfo[msg.sender].boxClaimed,'claimed');
        uint[2] memory par;
        box.mint(msg.sender,par);
        box.mint(msg.sender,par);
        userInfo[msg.sender].boxClaimed = true;
        boxClaimedAmount += 2;
        emit ClaimBox(msg.sender);
    }

    function init() external onlyOwner{
        cattleAmount = 514;
        cattleClaimedAmount = 0;
        cattle = ICOW(0x904ff0644C6254DB78c6a8F2f1e53ec3053Dc142);
    }

    function checkInfo(address addr) external view returns(bool[7] memory info1,uint[5] memory info2,uint[5] memory info3){
        info1[0] = userInfo[addr].boxClaimed;
        info1[1] = done[addr];
        info1[2] = userInfo[addr].bvgClaimed;
        info1[3] = userInfo[addr].bvtClaimed;
        info1[4] = userInfo[addr].planetClaimed;
        info1[5] = cattleWhite[addr];
        info1[6] = planetWhite[addr];
        info2[0] = planetAmount;
        info2[1] = cattleAmount;
        info2[2] = bvgClaimAmount;
        info2[3] = bvtClaimAmount;
        info2[4] = BVT.balanceOf(address(this));
        info3[0] = bvtClaimedAmount;
        info3[1] = bvgClaimedAmount;
        info3[2] = boxClaimedAmount;
        info3[3] = planetClaimedAmount;
        info3[4] = cattleClaimedAmount;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICOW {
    function getGender(uint tokenId_) external view returns (uint);

    function getEnergy(uint tokenId_) external view returns (uint);

    function getAdult(uint tokenId_) external view returns (bool);

    function getAttack(uint tokenId_) external view returns (uint);

    function getStamina(uint tokenId_) external view returns (uint);

    function getDefense(uint tokenId_) external view returns (uint);

    function getPower(uint tokenId_) external view returns (uint);

    function getLife(uint tokenId_) external view returns (uint);

    function getBronTime(uint tokenId_) external view returns (uint);

    function getGrowth(uint tokenId_) external view returns (uint);

    function getMilk(uint tokenId_) external view returns (uint);

    function getMilkRate(uint tokenId_) external view returns (uint);
    
    function getCowParents(uint tokenId_) external view returns(uint[2] memory);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function mintNormall(address player, uint[2] memory parents) external;

    function mint(address player) external;

    function setApprovalForAll(address operator, bool approved) external;

    function growUp(uint tokenId_) external;

    function isCreation(uint tokenId_) external view returns (bool);

    function burn(uint tokenId_) external returns (bool);

    function deadTime(uint tokenId_) external view returns (uint);

    function addDeadTime(uint tokenId, uint time_) external;

    function checkUserCowListType(address player,bool creation_) external view returns (uint[] memory);
    
    function checkUserCowList(address player) external view returns(uint[] memory);
    
    function getStar(uint tokenId_) external view returns(uint);
    
    function mintNormallWithParents(address player) external;
    
    function currentId() external view returns(uint);
    
    function upGradeStar(uint tokenId) external;
    
    function starLimit(uint stars) external view returns(uint);
    
    function creationIndex(uint tokenId) external view returns(uint);
    
    
}

interface IBOX {
    function mint(address player, uint[2] memory parents_) external;

    function burn(uint tokenId_) external returns (bool);

    function checkParents(uint tokenId_) external view returns (uint[2] memory);

    function checkGrow(uint tokenId_) external view returns (uint[2] memory);

    function checkLife(uint tokenId_) external view returns (uint[2] memory);
    
    function checkEnergy(uint tokenId_) external view returns (uint[2] memory);
}

interface IStable {
    function isStable(uint tokenId) external view returns (bool);
    
    function rewardRate(uint level) external view returns(uint);

    function isUsing(uint tokenId) external view returns (bool);

    function changeUsing(uint tokenId, bool com_) external;

    function CattleOwner(uint tokenId) external view returns (address);

    function getStableLevel(address addr_) external view returns (uint);

    function energy(uint tokenId) external view returns (uint);

    function grow(uint tokenId) external view returns (uint);

    function costEnergy(uint tokenId, uint amount) external;
    
    function addStableExp(address addr, uint amount) external;
    
    function userInfo(address addr) external view returns(uint,uint);
    
    function checkUserCows(address addr_) external view returns (uint[] memory);
    
    function growAmount(uint time_, uint tokenId) external view returns(uint);
    
    function refreshTime() external view returns(uint);
    
    function feeding(uint tokenId) external view returns(uint);
    
    function levelLimit(uint index) external view returns(uint);
    
    function compoundCattle(uint tokenId) external;

}

interface IMilk{
    function userInfo(address addr) external view returns(uint,uint);
    
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet721 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256 balance);

    function planetIdMap(uint tokenId) external view returns (uint256 cardId);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function mint(address player_, uint type_) external returns (uint256);
    
    function changeType(uint tokenId, uint type_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IPlanet721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IBvInfo.sol";
import "../interface/ICattle1155.sol";
contract CattlePlanet is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVG;
    IERC20Upgradeable public BVT;
    IPlanet721 public planet;
    IBvInfo public bvInfo;
    uint public febLimit;
    uint public battleTaxRate;
    uint public federalPrice;
    uint[] public currentPlanet;
    uint public upGradePlanetPrice;
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        battleTaxRate = 30;
        federalPrice = 500 ether;
        upGradePlanetPrice = 500 ether;
        setPlanetType(1,10000,100,20);
        setPlanetType(3,5000,10,10);
        setPlanetType(2,1000,0,10);
    }

    struct PlanetInfo {
        address owner;
        uint tax;
        uint population;
        uint normalTaxAmount;
        uint battleTaxAmount;
        uint motherPlanet;
        uint types;
        uint membershipFee;
        uint populationLimit;
        uint federalLimit;
        uint federalAmount;
        uint totalTax;
    }

    struct PlanetType {
        uint populationLimit;
        uint federalLimit;
        uint planetTax;
    }

    struct UserInfo {
        uint level;
        uint planet;
        uint taxAmount;
    }

    struct ApplyInfo {
        uint applyAmount;
        uint applyTax;
        uint lockAmount;

    }

    mapping(uint => PlanetInfo) public planetInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => uint) public ownerOfPlanet;
    mapping(address => ApplyInfo) public applyInfo;
    mapping(address => bool) public admin;
    mapping(uint => PlanetType) public planetType;
    mapping(uint => uint) public battleReward;
    address public banker;
    address public mail;
    ICattle1155 public item;
    event BondPlanet(address indexed player, uint indexed tokenId);
    event ApplyFederalPlanet (address indexed player, uint indexed amount, uint indexed tax);
    event CancelApply(address indexed player);
    event NewPlanet(address indexed addr, uint indexed tokenId, uint indexed motherPlanet,uint types);
    event UpGradeTechnology(uint indexed tokenId, uint indexed tecNum);
    event UpGradePlanet(uint indexed tokenId);
    event AddTaxAmount(uint indexed PlanetID, address indexed player, uint indexed amount);
    event SetPlanetFee(uint indexed PlanetID, uint indexed fee);
    event BattleReward(uint[2] indexed planetID);
    event DeployBattleReward(uint indexed id, uint indexed amount);
    event DeployPlanetReward(uint indexed id, uint indexed amount);
    event ReplacePlanet(address indexed newOwner, uint indexed tokenId);
    event PullOutCard(address indexed player, uint indexed id);
    event AddArmor(uint indexed tokenID);
    modifier onlyPlanetOwner(uint tokenId) {
        require(msg.sender == planetInfo[tokenId].owner, 'not planet Owner');
        _;
    }

    modifier onlyAdmin(){
        require(admin[msg.sender], 'not admin');
        _;

    }

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setToken(address BVG_, address BVT_) external onlyOwner {
        BVG = IERC20Upgradeable(BVG_);
        BVT = IERC20Upgradeable(BVT_);
    }

    function setMail(address addr) external onlyOwner {
        mail = addr;
    }

    function setPlanet721(address planet721_) external onlyOwner {
        planet = IPlanet721(planet721_);
    }

    function setBvInfo(address BvInfo) external onlyOwner {
        bvInfo = IBvInfo(BvInfo);
    }

    function setPlanetType(uint types_, uint populationLimit_, uint federalLimit_, uint planetTax_) public onlyOwner {
        planetType[types_] = PlanetType({
        populationLimit : populationLimit_,
        federalLimit : federalLimit_,
        planetTax : planetTax_
        });
    }

    function setItem(address addr) external onlyOwner{
        item = ICattle1155(addr);
    }

    function getBVTPrice() public view returns (uint){
        if (address(bvInfo) == address(0)) {
            return 1e16;
        }
        return bvInfo.getBVTPrice();
    }


    function bondPlanet(uint tokenId) external {
        require(userInfo[msg.sender].planet == 0, 'already bond');
        require(planetInfo[tokenId].tax > 0, 'none exits planet');
        require(planetInfo[tokenId].population < planetInfo[tokenId].populationLimit, 'out of population limit');
        if (planetInfo[tokenId].membershipFee > 0) {
            uint need = planetInfo[tokenId].membershipFee * 1e18 / getBVTPrice();
            BVT.safeTransferFrom(msg.sender, planet.ownerOf(tokenId), need);
        }
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit BondPlanet(msg.sender, tokenId);
    }

    function userTaxAmount(address addr) external view returns (uint){
        return userInfo[addr].taxAmount;
    }

    function setPlanetPopLimit(uint id,uint limit) external onlyOwner{
        planetInfo[id].populationLimit = limit;
    }

    function applyFederalPlanet(uint amount, uint tax_) external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].applyAmount == 0, 'have apply, cancel first');
        require(tax_ < 20, 'tax must lower than 20%');
        applyInfo[msg.sender].applyTax = tax_;
        applyInfo[msg.sender].applyAmount = amount;
        applyInfo[msg.sender].lockAmount = federalPrice * 1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender, address(this), amount + applyInfo[msg.sender].lockAmount);
        emit ApplyFederalPlanet(msg.sender, amount, tax_);
    }

    function cancelApply() external {
        require(userInfo[msg.sender].planet != 0, 'not bond planet');
        require(applyInfo[msg.sender].lockAmount > 0, 'have apply, cancel first');
        BVT.safeTransfer(msg.sender, applyInfo[msg.sender].applyAmount + applyInfo[msg.sender].lockAmount);
        delete applyInfo[msg.sender];
        emit CancelApply(msg.sender);

    }

    function addPlanetTax(uint tokenId, uint normalAmount, uint battleAmount) external onlyOwner {
        planetInfo[tokenId].normalTaxAmount += normalAmount;
        planetInfo[tokenId].battleTaxAmount += battleAmount;
    }

    function setBattleReward(uint tokenID,uint amount) external onlyOwner {
        battleReward[tokenID] = amount;
    }

    function claimTax(uint amount) external {
        uint tokenID = ownerOfPlanet[msg.sender];
        require(tokenID != 0, 'you are not owner');
        require(planetInfo[tokenID].normalTaxAmount >= amount, 'out of tax amount');
        BVT.safeTransfer(msg.sender, amount);
        planetInfo[tokenID].normalTaxAmount -= amount;
    }

    function approveFedApply(address addr_, uint tokenId) onlyPlanetOwner(tokenId) external {
        require(applyInfo[addr_].lockAmount > 0, 'wrong apply address');
        require(planetInfo[tokenId].federalAmount < planetInfo[tokenId].federalLimit, 'out of federal Planet limit');
        BVT.safeTransfer(msg.sender, applyInfo[addr_].applyAmount);
        BVT.safeTransfer(address(0), applyInfo[addr_].lockAmount);
        uint id = planet.mint(addr_, 2);
        uint temp = ownerOfPlanet[addr_];
        require(temp == 0, 'already have 1 planet');
        planetInfo[id].tax = applyInfo[addr_].applyTax;
        planetInfo[id].motherPlanet = tokenId;
        planetInfo[tokenId].federalAmount ++;
        ownerOfPlanet[addr_] = id;
        planetInfo[id].federalLimit = 0;
        planetInfo[id].populationLimit = 1000;
        planetInfo[id].owner = addr_;
        planetInfo[id].types = 2;
        currentPlanet.push(id);
        delete applyInfo[addr_];
        emit NewPlanet(addr_, id, tokenId,2);
    }

    function setPlanetOwner(uint id,address addr) external onlyOwner{
        planetInfo[id].owner = addr;
    }

    function setPlanetType(uint id,uint type_) external onlyOwner{
    planetInfo[id].types = type_;
    }

    function claimBattleReward(uint[2] memory planetId, bytes32 r, bytes32 s, uint8 v) public {//index 0 for winner
        bytes32 hash = keccak256(abi.encodePacked(planetId));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(msg.sender == planetInfo[planetId[0]].owner, 'not planet owner');
        require(planetInfo[planetId[1]].battleTaxAmount > 0 || planetInfo[planetId[0]].battleTaxAmount > 0, 'no reward');
        battleReward[planetId[0]] += planetInfo[planetId[0]].battleTaxAmount + planetInfo[planetId[1]].battleTaxAmount;
        planetInfo[planetId[0]].battleTaxAmount = 0;
        planetInfo[planetId[1]].battleTaxAmount = 0;
        emit BattleReward(planetId);
    }

    function deployBattleReward(uint id, uint amount) public {
        require(msg.sender == planetInfo[id].owner, 'not planet owner');
        require(battleReward[id] >= amount, 'out of reward');
        BVT.safeTransfer(mail, amount);
        if (battleReward[id] > amount) {
            BVT.safeTransfer(msg.sender, battleReward[id] - amount);
        }
        battleReward[id] = 0;
        emit DeployBattleReward(id, amount);
    }

    function deployPlanetReward(uint id, uint amount) public {
        require(msg.sender == planetInfo[id].owner, 'not planet owner');
        require(amount <= planetInfo[id].normalTaxAmount, 'out of tax amount');
        BVT.safeTransfer(mail, amount);
        planetInfo[id].normalTaxAmount -= amount;
        emit DeployPlanetReward(id, amount);
    }

    function setBanker(address addr) external onlyOwner {
        banker = addr;
    }

    function createNewPlanet(uint tokenId) external {
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0, 'must not bond');
        require(planetInfo[tokenId].tax == 0, 'created');
        uint temp = ownerOfPlanet[msg.sender];
        require(temp == 0, 'already have 1 planet');
        uint types = planet.planetIdMap(tokenId);
        require(planetType[types].planetTax > 0, 'set Tax');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].tax = planetType[planet.planetIdMap(tokenId)].planetTax;
        planetInfo[tokenId].types = types;
        planetInfo[tokenId].federalLimit = planetType[types].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[types].populationLimit;
        ownerOfPlanet[msg.sender] = tokenId;
        planetInfo[tokenId].owner = msg.sender;
        currentPlanet.push(tokenId);
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit NewPlanet(msg.sender, tokenId, 0,types);
        emit BondPlanet(msg.sender, tokenId);

    }


    function pullOutPlanetCard(uint tokenId) external {
        require(msg.sender == planetInfo[tokenId].owner, 'not the owner');
        planet.safeTransferFrom(address(this), msg.sender, tokenId);
        ownerOfPlanet[msg.sender] = 0;
        planetInfo[tokenId].owner = address(0);
        emit PullOutCard(msg.sender, tokenId);
    }

    function replaceOwner(uint tokenId) external {
        require(msg.sender == planet.ownerOf(tokenId), 'not planet owner');
        require(userInfo[msg.sender].planet == 0, 'must not bond');
        require(planetInfo[tokenId].tax != 0, 'new planet need create');
        require(ownerOfPlanet[msg.sender] == 0, 'already have 1 planet');
        planet.safeTransferFrom(msg.sender, address(this), tokenId);
        planetInfo[tokenId].owner = msg.sender;
        ownerOfPlanet[msg.sender] = tokenId;
        planetInfo[tokenId].population ++;
        userInfo[msg.sender].planet = tokenId;
        emit ReplacePlanet(msg.sender, tokenId);
        emit BondPlanet(msg.sender, tokenId);
    }

    function setMemberShipFee(uint tokenId, uint price_) onlyPlanetOwner(tokenId) external {
        planetInfo[tokenId].membershipFee = price_;
        emit SetPlanetFee(tokenId, price_);
    }


    function addTaxAmount(address addr, uint amount) external onlyAdmin {
        uint tokenId = userInfo[addr].planet;
        userInfo[addr].taxAmount += amount;
        if (planetInfo[tokenId].motherPlanet == 0) {
            planetInfo[tokenId].battleTaxAmount += amount * battleTaxRate / 100;
            planetInfo[tokenId].normalTaxAmount += amount * (100 - battleTaxRate) / 100;
        } else {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            uint feb = planetInfo[tokenId].tax;
            uint home = planetInfo[motherPlanet].tax;
            uint temp = amount * feb / home;
            planetInfo[motherPlanet].normalTaxAmount +=  amount * (100 - battleTaxRate) / 100;
            planetInfo[motherPlanet].battleTaxAmount += home * battleTaxRate / 100;
            planetInfo[tokenId].totalTax += temp;
            planetInfo[tokenId].normalTaxAmount += temp;
        }

        emit AddTaxAmount(tokenId, addr, amount);

    }

    function upGradePlanet(uint tokenId) external onlyPlanetOwner(tokenId) {
        require(planetInfo[tokenId].types == 3, 'can not upgrade');
        uint cost = upGradePlanetPrice * 1e18 / getBVTPrice();
        BVT.safeTransferFrom(msg.sender, address(0), cost);
        IPlanet721(planet).changeType(tokenId, 1);
        planetInfo[tokenId].types = 1;
        planetInfo[tokenId].tax = planetType[1].planetTax;
        planetInfo[tokenId].federalLimit = planetType[1].federalLimit;
        planetInfo[tokenId].populationLimit = planetType[1].populationLimit;
        emit UpGradePlanet(tokenId);
    }


    function findTax(address addr_) public view returns (uint){
        uint tokenId = userInfo[addr_].planet;
        if (planetInfo[tokenId].motherPlanet != 0) {
            uint motherPlanet = planetInfo[tokenId].motherPlanet;
            return planetInfo[motherPlanet].tax;
        }
        return planetInfo[tokenId].tax;
    }

    function addArmor() external {
        uint tokenID = ownerOfPlanet[msg.sender];
        require(tokenID != 0 && planetInfo[tokenID].types != 2,'wrong token');
        item.burn(msg.sender,20005,1);
        emit AddArmor(tokenID);
    }


    function isBonding(address addr_) external view returns (bool){
        return userInfo[addr_].planet != 0;
    }


    function getUserPlanet(address addr_) external view returns (uint){
        return userInfo[addr_].planet;
    }

    function addPlanet(uint id) external onlyOwner{
        currentPlanet.push(id);
    }

    function checkPlanetOwner() external view returns (uint[] memory, address[] memory){
        address[] memory list = new address[](currentPlanet.length);
        for (uint i = 0; i < currentPlanet.length; i++) {
            list[i] = planetInfo[currentPlanet[i]].owner;
        }
        return (currentPlanet, list);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBvInfo{
    function addPrice() external;
    function getBVTPrice() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICattle1155 {
    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) external returns (bool);

    function mint(address to_, uint cardId_, uint amount_) external returns (bool);

    function safeTransferFrom(address from, address to, uint256 cardId, uint256 amount, bytes memory data_) external;

    function safeBatchTransferFrom(address from_, address to_, uint256[] memory ids_, uint256[] memory amounts_, bytes memory data_) external;

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function balanceOf(address account, uint256 tokenId) external view returns (uint);

    function burned(uint) external view returns (uint);

    function burn(address account, uint256 id, uint256 value) external;

    function checkItemEffect(uint id_) external view returns (uint[3] memory);
    
    function itemLevel(uint id_) external view returns (uint);
    
    function itemExp(uint id_) external view returns(uint);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TechnologyTree is OwnableUpgradeable {
    IStable public stable;
    IERC20 public BVT;
    mapping(address => mapping(uint => uint)) public userTec;

    struct TecInfo {
        uint levelLimit;
        uint types;
        uint[] effect;
        uint[] upgradeLimit;
    }

    mapping(uint => TecInfo) public tecInfo;
    uint[] tecList;
    mapping(uint => uint) tecIndex;

    event FullTecLevel(address indexed player, uint indexed tecId);

    function setStable(address addr) external onlyOwner {
        stable = IStable(addr);
    }

    function setBVT(address addr) external onlyOwner {
        BVT = IERC20(addr);
    }

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        // newTechnology(3001,1,1,[100,95,90,80,70,50],[100,250,450,700,1000]);
        // newTechnology(3002,1,3,[0,4*3600,9*3600,16*3600,25*3600,36*3600],[100,250,450,700,1000]);
        // newTechnology(1001,2,1,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1002,2,3,[100,102,105,109,114,120],[100,250,450,700,1000]);
        // newTechnology(1003,2,5,[0,2,5,9,14,20],[100,250,450,700,1000]);
        // newTechnology(4001,3,1,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4003,3,3,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
        // newTechnology(4004,3,3,[0,4,9,15,22,30],[100,250,450,700,1000]);
        // newTechnology(4002,3,5,[1000,1010,1025,1045,1070,1100],[100,250,450,700,1000]);
    }

    function newTechnology(uint ID, uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner {
        require(tecIndex[ID] == 0, 'exist ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
        tecIndex[ID] = tecList.length;
        tecList.push(ID);
    }

    function editTechnology(uint ID, uint types_, uint levelLimit_, uint[] memory effect, uint[] memory upgradeLimit) public onlyOwner {
        require(tecIndex[ID] != 0, 'nonexistent ID');
        tecInfo[ID].types = types_;
        tecInfo[ID].levelLimit = levelLimit_;
        tecInfo[ID].effect = effect;
        tecInfo[ID].upgradeLimit = upgradeLimit;
    }

    function buyTec(uint ID, uint amount) external {
        require(tecInfo[ID].types != 0, 'nonexistent ID');
        uint level = stable.getStableLevel(msg.sender);
        uint oldLevel = getUserTecLevel(msg.sender, ID);
        require(level >= tecInfo[ID].levelLimit, 'not enough level');
        BVT.transferFrom(msg.sender, address(this), amount);
        userTec[msg.sender][ID] += amount;
        uint newLevel = getUserTecLevel(msg.sender, ID);
        if (newLevel > oldLevel && newLevel == 5) {
            emit FullTecLevel(msg.sender, ID);
        }
    }


    function buyTecBatch(uint[] memory ids, uint[] memory amounts) external {
        require(ids.length == amounts.length, 'wrong length');
        uint level = stable.getStableLevel(msg.sender);
        uint total;
        uint oldLevel;
        uint newLevel;
        for (uint i = 0; i < ids.length; i ++) {
            require(tecInfo[ids[i]].types != 0, 'nonexistent ID');
            require(level >= tecInfo[ids[i]].levelLimit, 'not enough level');
            oldLevel = getUserTecLevel(msg.sender, ids[i]);
            total += amounts[i];
            userTec[msg.sender][ids[i]] += amounts[i];
            newLevel = getUserTecLevel(msg.sender, ids[i]);
            if (newLevel > oldLevel && newLevel == 5) {
                emit FullTecLevel(msg.sender, ids[i]);
            }
        }
        BVT.transferFrom(msg.sender, address(this), total);

    }

    function getUserTecLevel(address addr, uint ID) public view returns (uint out){
        uint amount = userTec[addr][ID];
        uint[] memory list = tecInfo[ID].upgradeLimit;

        for (uint i = 0; i < list.length; i ++) {
            if (amount < list[i] * 1e18) {
                out = i;
                return out;
            }
        }
        out = 5;
    }

    function checkTecEffet(uint ID) external view returns (uint[] memory){
        return tecInfo[ID].effect;
    }

    function checkUserTecEffet(address addr, uint ID) external view returns (uint){
        return tecInfo[ID].effect[getUserTecLevel(addr, ID)];
    }

    function getUserTecLevelBatch(address addr, uint[] memory list) external view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = getUserTecLevel(addr, list[i]);
        }
    }

    function checkUserExpBatch(address addr, uint[] memory list) public view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = userTec[addr][list[i]];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPlanet{
    
    function isBonding(address addr_) external view returns(bool);
    
    function addTaxAmount(address addr,uint amount) external;
    
    function getUserPlanet(address addr_) external view returns(uint);
    
    function findTax(address addr_) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "../interface/IPlanet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract StarShop is OwnableUpgradeable{
    struct NormalItem{
        string name;
        uint price;
        uint totalBuy;
        IERC20 payToken;
    }
    struct LimitItem{
        string name;
        uint limitTime;
        uint price;
        uint totalBuy;
        IERC20 payToken;
        uint[] itemList;
        uint[] itemAmount;

    }
    mapping(uint => NormalItem)public normalItem;
    mapping(uint => LimitItem) public limitItem;
    mapping(address => mapping(uint => uint)) public balanceOf;
    uint[] normalOnSaleList;
    uint[] limitOnSaleList;
    ICattle1155 public item;
    IPlanet public planet;

    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    function setPlanet(address addr) external onlyOwner{
        planet = IPlanet(addr);
    }
    
    function setItem(address addr)external onlyOwner{
        item = ICattle1155(addr);
    }
    function setNormalPrice(uint[] memory ids,uint[] memory prices) external onlyOwner{
        for(uint i = 0; i < ids.length; i ++){
            normalItem[ids[i]].price = prices[i];
        }
    }
    function newNormalItem(uint itemID,string memory name,uint price,address payToken) external onlyOwner{
        normalItem[itemID] = NormalItem({
            name : name,
            price : price,
            totalBuy : 0,
            payToken : IERC20(payToken)
        });
        normalOnSaleList.push(itemID);
    }
    
    function editNormalItem(uint itemID,string memory name,uint price,address payToken) external onlyOwner{
        normalItem[itemID] = NormalItem({
            name : name,
            price : price,
            totalBuy :normalItem[itemID].totalBuy ,
            payToken : IERC20(payToken)
        });
    }
    
    function reSetList(uint[] memory lists) external onlyOwner{
        normalOnSaleList = lists;
    }
    
    function newLimitItem(uint itemID,string memory name,uint price,address payToken,uint limitTime,uint[] memory itemList,uint[] memory itemAmount) external onlyOwner{
        limitItem[itemID] = LimitItem({
            name : name,
            price : price,
            payToken : IERC20(payToken),
            limitTime : limitTime,
            itemList : itemList,
            itemAmount: itemAmount,
            totalBuy : 0
        });
        limitOnSaleList.push(itemID);
    }
    function editLimitItem(uint itemID,string memory name,uint price,address payToken,uint limitTime,uint[] memory itemList,uint[] memory itemAmount) external onlyOwner{
        limitItem[itemID] = LimitItem({
            name : name,
            price : price,
            payToken : IERC20(payToken),
            limitTime : limitTime,
            itemList : itemList,
            itemAmount:itemAmount,
            totalBuy : limitItem[itemID].totalBuy
        });
    }

    function editLimitTime(uint[] memory list_,uint[] memory limitTime_) external onlyOwner{
        for(uint i = 0; i < list_.length; i++){
            limitItem[list_[i]].limitTime = limitTime_[i];
        }
    }
    
    function buyNormal(uint itemID,uint amount) external {
        NormalItem storage info = normalItem[itemID];
        require(info.price > 0,'wrong itemID');
        if(itemID == 20){
            require(item.balanceOf(msg.sender,20) == 0 && amount <=1,'our of limit');
        }
        info.payToken.transferFrom(msg.sender,address(this),info.price * amount);
        item.mint(msg.sender,itemID,amount);
        info.totalBuy += amount;
    }
    
    function buyLimit(uint itemID, uint amount) external {
        LimitItem storage info = limitItem[itemID];
        require(block.timestamp < info.limitTime,'out of time');
        require(info.price > 0,'wrong itemID');
        info.payToken.transferFrom(msg.sender,address(this),info.price * amount);
        for(uint i = 0; i < info.itemList.length; i++){
            item.mint(msg.sender,info.itemList[i],info.itemAmount[i] * amount);
        }
        info.totalBuy += amount;
    }
    
    function checkNormalOnSaleList() public view returns(uint[] memory){
        return normalOnSaleList;
    }

    function checkUp() internal pure{
        return;
    }

    function setLimitPrice(uint[] memory ids,uint[] memory prices) external onlyOwner{
        for (uint i = 0; i < ids.length; i ++) {
            limitItem[ids[i]].price = prices[i];
        }
    }


    function checkLimitItemlistAmount(uint limitId) public view returns(uint[] memory,uint[] memory){
        return (limitItem[limitId].itemList,limitItem[limitId].itemAmount);
    }
    
    function checkLimitOnSaleList() public view returns(uint[] memory){
        return limitOnSaleList;
    }

    function resetLimitItemList(uint[] memory list_) public onlyOwner{
        limitOnSaleList = list_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "../interface/IPlanet.sol";
import "../interface/Iprofile_photo.sol";
contract Stable is OwnableUpgradeable , ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    IPlanet public planet;
    IProfilePhoto public photo;
    uint[] public stablePrice;
    uint public forageId;
    mapping(uint => bool) public isStable;
    mapping(uint => bool) _isUsing;
    mapping(uint => address) public CattleOwner;
    mapping(address => bool) public admin;
    mapping(uint => uint) public feeding;
    mapping(uint => uint) public feedingTime;
    ICattle1155 public cattleItem;
    uint public maxGrowAmount;
    uint public refreshTime;
    uint public upLevelPrice;
    uint[] public levelLimit ;
    struct UserInfo {
        uint stableAmount;
        uint stableExp;
        uint[] cows;
    }
    mapping(uint => uint) public energy;
    mapping(uint => uint) public grow;
    mapping(uint => mapping(uint => uint)) public growAmount;
    mapping(address => mapping(address => mapping(uint => bool))) public approves;
    mapping(address => UserInfo)public userInfo;
   // ------------------upgrade
    uint[] public stableAmountExp;
    uint[] public rewardRate;
    mapping(address => uint) stableLevel;
    mapping(uint => uint) public addLifeAmount;
    mapping(address => uint) public userPower;
    event Feed(uint indexed tokenId,uint indexed amount);
    event Grow(uint indexed tokenId,uint indexed amount);
    event Charge(address indexed player, uint indexed amount);
    event PutIn(address indexed player,uint indexed tokenId);
    event PutOut(address indexed player,uint indexed tokenId);
    event BuyStable(address indexed player);
    event UpStableLevel(address indexed player,uint indexed newLevel);
    event GrowUp(address indexed player, uint indexed tokenID);
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        levelLimit = [200,300,450,675,1350];
        rewardRate = [100,105,110,115,120,130];
        stableAmountExp = [50,60,80];
        stablePrice = [1500 ether,2000e18,3000e18];
        upLevelPrice = 100e18;
        maxGrowAmount = 10000;
        feedingTime[0] = 600;
        feedingTime[1] = 15 * 60;
        feedingTime[2] = 20 * 60;
    }


    function setCow(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setLevelLimit (uint[] calldata list_) external onlyOwner{
        levelLimit = list_;
    }
    function setForageId(uint Id_) external onlyOwner{
        forageId = Id_;
    }
    
    function setPhoto(address photo_) external onlyOwner{
        photo = IProfilePhoto(photo_);
    }
    
    function setRewardRate(uint[] memory list) external onlyOwner{
        rewardRate  = list;
    }
    function setStableAmountExp (uint[] memory list) external onlyOwner{
        stableAmountExp = list;
    }
    
    function setCattlePlanet(address planet_)external onlyOwner {
        planet = IPlanet(planet_);
    }
    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }
    
    function setCattle1155(address Cattle1155_) external onlyOwner{
        cattleItem = ICattle1155(Cattle1155_);
    }

    function findOnwer(uint tokenId) public view returns (address out){
        return cattle.ownerOf(tokenId);
    }


    function setStablePrice(uint[] memory price) public onlyOwner {
        stablePrice = price;
    }

    function checkUserCows(address addr_) external view returns (uint[] memory){
        return userInfo[addr_].cows;
    }

    function changeUsing(uint tokenId, bool com_) external {
        require(admin[_msgSender()], "not admin");
        _isUsing[tokenId] = com_;
    }

    function setAdmin(address addr_, bool com_) external onlyOwner {
        admin[addr_] = com_;
        cattle.setApprovalForAll(addr_,com_);
    }


    function putIn(uint tokenId) external {
        require(planet.isBonding(msg.sender),'not bonding planet');
        UserInfo storage user = userInfo[_msgSender()];
        if (user.stableAmount < 2) {
            user.stableAmount = 2;
        }
        require(cattle.deadTime(tokenId) > block.timestamp,'cattle is dead');
        require(user.cows.length < user.stableAmount, 'out of stableAmount');
        require(findOnwer(tokenId) == _msgSender(), 'not owner');
        cattle.safeTransferFrom(msg.sender,address(this),tokenId);
        CattleOwner[tokenId] = msg.sender;
        isStable[tokenId] = true;
        user.cows.push(tokenId);
        emit PutIn(msg.sender,tokenId);
    }

    function findIndex(uint[] storage list_, uint tokenId_) internal view returns (uint){
        for (uint i = 0; i < list_.length; i++) {
            if (list_[i] == tokenId_) {
                return i;
            }
        }
        return 1e18;
    }
    
    function isUsing(uint tokenId_) public view returns(bool){
        if (_isUsing[tokenId_]){
            return _isUsing[tokenId_];
        }
        return (block.timestamp < feeding[tokenId_]);
    }

    function putOut(uint tokenId) external {
        require(!isUsing(tokenId), "is Using");
        UserInfo storage user = userInfo[_msgSender()];
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(isStable[tokenId], 'not in stable');
        require(user.cows.length > 0, ' no cows in stable');
        uint temp = findIndex(user.cows, tokenId);
        require(temp != 1e18,'wrong tokenId');
        user.cows[temp] = user.cows[user.cows.length - 1];
        user.cows.pop();
        CattleOwner[tokenId] = address(0);
        isStable[tokenId] = false;
        if (block.timestamp < cattle.deadTime(tokenId)){
            cattle.safeTransferFrom(address(this),msg.sender,tokenId);
        }else{
            cattle.burn(tokenId);
        }
        emit PutOut(msg.sender,tokenId);
        
    }

    function feed(uint tokenId, uint amount_,uint types) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(types <= 3 && types != 0,'wrong types');
        require(!isUsing(tokenId),'this cattle is using');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        uint[3]memory effect = cattleItem.checkItemEffect(types);
        cattleItem.burn(msg.sender,types,amount_);
        uint energyLimit = cattle.getEnergy(tokenId);
        require(energy[tokenId] + amount_ <= energyLimit,'out of energyLimit');
        energy[tokenId] += amount_ * effect[0];
        feeding[tokenId] = block.timestamp + (feedingTime[types - 1] * amount_);
        emit Feed(tokenId,amount_);
    }


    function growUp(uint tokenId, uint amount_) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(amount_ <= energy[tokenId],'out of energy');
        
        uint refresh = block.timestamp - (block.timestamp % 86400);
        if (refresh != refreshTime){
            refreshTime = refresh;
        }
        require(!cattle.isCreation(tokenId),'creation Cattle Can not grow');
        require(growAmount[refreshTime][tokenId] + amount_ <= maxGrowAmount,'out limit');
        growAmount[refreshTime][tokenId] += amount_;
        energy[tokenId] -= amount_;
        grow[tokenId] += amount_;
        if (grow[tokenId] >= 30000){
            cattle.growUp(tokenId);
            emit GrowUp(msg.sender,tokenId);
            _addStableExp(msg.sender,20);
        }
        emit Grow(tokenId,amount_);
    }
    function charge(uint tokenId,uint amount_) external {
        require(CattleOwner[tokenId] == msg.sender, 'not owner');
        require(isStable[tokenId],'not in stable');
        require(energy[tokenId] >= amount_,'not enough energy');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        require(cattle.getGender(tokenId) == 1,'not bull');
        energy[tokenId] -= amount_;
        userPower[msg.sender] += amount_;
        require(amount_ <= 20000,'out of limit');
        emit Charge(msg.sender,amount_);
    }
    
    function chargeWithItem(uint itemId, uint amount_) external {
        require(itemId > 3 ,'wrong itemId');
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0 ,'wrong IitemId');
        userPower[msg.sender] += effect[0] * amount_;
        require(effect[0] * amount_ <= 20000 ,'out of limit');
        _addStableExp(msg.sender,cattleItem.itemExp(itemId) * amount_);
        cattleItem.burn(msg.sender,itemId,amount_);
    }
    
    function useItem(uint tokenId, uint itemId, uint amount_) external {
        require(isStable[tokenId], 'not in stable');
        require(CattleOwner[tokenId] == _msgSender(), 'not owner');
        require(itemId > 3 ,'wrong itemId');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        if (effect[0] > 0){
            uint energyLimit = cattle.getEnergy(tokenId);
            energy[tokenId] += effect[0] * amount_;
            if(energy[tokenId] > energyLimit){
                energy[tokenId] = energyLimit;
            }
        }
        if (effect[1] > 0){
            uint refresh = block.timestamp - (block.timestamp % 86400);
            if (refresh != refreshTime){
                refreshTime = refresh;
            }
//            require(growAmount[refreshTime][tokenId] + (effect[1] * amount_) <= maxGrowAmount + 5000,'out limit');
            grow[tokenId] += effect[1] * amount_;
            if (grow[tokenId] >= 30000){
                
                cattle.growUp(tokenId);
                emit GrowUp(msg.sender,tokenId);
                _addStableExp(msg.sender,20);
                uint gender = cattle.getGender(tokenId);
                if(gender == 1){
                    photo.mintAdultBull(msg.sender);
                }else{
                    photo.mintAdultCow(msg.sender);
                }
            }
        }
        if (effect[2] > 0){
            require(addLifeAmount[tokenId] < 10 days,'out of add Life amount');
            uint total = effect[2] * amount_;
            if(total >(10 days - addLifeAmount[tokenId])){
                cattle.addDeadTime(tokenId,10 days - addLifeAmount[tokenId]);
                addLifeAmount[tokenId] = 10 days;
            }else{
                addLifeAmount[tokenId] += total;
                cattle.addDeadTime(tokenId,total);
            }
            
            
            
        }
        _addStableExp(msg.sender,cattleItem.itemExp(itemId) * amount_);
        cattleItem.burn(msg.sender,itemId,amount_);
        
    }
    
    function costEnergy(uint tokenId, uint amount) external {
        require(admin[_msgSender()], "not admin");
        require(energy[tokenId]>= amount,'out of energy');
        require(block.timestamp < cattle.deadTime(tokenId),'dead cattle');
        energy[tokenId] -= amount;
    }
    
    function getStablePrice(address addr) external view returns(uint){
        uint amount = userInfo[addr].stableAmount;
        if(amount == 0){
            amount =2;
        }
        uint price = stablePrice[amount / 2 - 1];
        return price;
    }


    function buyStable() external {
        if (userInfo[msg.sender].stableAmount < 2) {
            userInfo[msg.sender].stableAmount = 2;
        }
        uint index = userInfo[msg.sender].stableAmount / 2 - 1;
        uint price = stablePrice[index];
        _addStableExp(msg.sender,stableAmountExp[index]);
        BVT.safeTransferFrom(_msgSender(), address(this),price);
        userInfo[_msgSender()].stableAmount ++;
        emit BuyStable(msg.sender);

    }
    
    function addStableExp(address addr, uint amount) external{
        require(admin[_msgSender()], "not admin");
        _addStableExp(addr,amount);
    }
    
    function compoundCattle(uint tokenId) external {
        require(admin[_msgSender()], "not admin");
        require(!isUsing(tokenId),'is using');
        UserInfo storage user = userInfo[CattleOwner[tokenId]];
        require(isStable[tokenId], 'not in stable');
        uint temp = findIndex(user.cows, tokenId);
        require(temp != 1e18,'wrong tokenId');
        user.cows[temp] = user.cows[user.cows.length - 1];
        user.cows.pop();
        CattleOwner[tokenId] = address(0);
        isStable[tokenId] = false;
        cattle.burn(tokenId);
    }
    
    function _addStableExp(address addr,uint amount) internal{
        if (userInfo[addr].stableExp >= 1e17){
            userInfo[addr].stableExp = 0;
        }
        uint level = stableLevel[addr];
        if(level >= 5){
            userInfo[addr].stableExp += amount;
            return;
        }
        if(userInfo[addr].stableExp + amount >= levelLimit[level]){
            uint left = userInfo[addr].stableExp + amount - levelLimit[level];
            userInfo[addr].stableExp = left;
            stableLevel[addr] ++;
            emit UpStableLevel(addr,stableLevel[addr]);
        }else{
            userInfo[addr].stableExp += amount;
        }
        
    }
    
    
    function getStableLevel(address addr_) external view returns(uint){
        return stableLevel[addr_];
    }
    
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProfilePhoto {
    function mintBabyBull(address addr_) external;

    function mintAdultBull(address addr_) external;

    function mintBabyCow(address addr_) external;

    function mintAdultCow(address addr_) external;

    function mintMysteryBox(address addr_) external;

    function getUserPhotos(address addr_) external view returns(uint[]memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "../interface/Iprofile_photo.sol";
import "../interface/ITec.sol";
import "../interface/IRefer.sol";
import "../interface/ICattle1155.sol";

contract Mating is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IBOX public box;
    IERC20Upgradeable public BVT;
    IStable public stable;
    IPlanet public planet;
    IProfilePhoto public photo;
    mapping(uint => bool) public onSale;
    mapping(uint => uint) public price;
    mapping(uint => uint) public matingTime;
    mapping(uint => uint) public lastMatingTime;
    uint public energyCost;
    mapping(uint => uint) public index;
    mapping(address => uint[]) public userUploadList;
    mapping(address => uint) public userMatingTimes;

    event UpLoad(address indexed sender_, uint indexed price, uint indexed tokenId);
    event OffSale(address indexed sender_, uint indexed tokenId);
    event Mate(address indexed player_, uint indexed tokenId, uint indexed targetTokenID);

    IERC20Upgradeable public BVG;
    uint[] mattingCostBVG;
    uint[] mattingCostBVT;
    ITec public tec;
    IRefer public refer;
    ICattle1155 public item;
    mapping(uint => uint) public excessTimes;
    mapping(address => uint) public boxClaimed;
    mapping(address => uint) public totalMatting;

    event RewardBox(address indexed player_, address indexed invitor);
    event RewardCard(address indexed player_, address indexed invitor);
    event SelfMatting(address indexed player, uint indexed tokenID1, uint indexed tokenID2);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        energyCost = 1000;
        mattingCostBVT = [100 ether, 200 ether, 300 ether, 400 ether, 500 ether];
        mattingCostBVG = [100000 ether, 200000 ether, 300000 ether, 400000 ether, 500000 ether];
    }

    function setCow(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setRefer(address addr) external onlyOwner {
        refer = IRefer(addr);
    }

    function setItem(address addr) external onlyOwner {
        item = ICattle1155(addr);
    }

    function setTec(address addr) external onlyOwner {
        tec = ITec(addr);
    }

    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }

    function setBox(address box_) external onlyOwner {
        box = IBOX(box_);
    }

    function setMattingCost(uint[] memory bvgCost_, uint[] memory bvtCost_) external onlyOwner {
        mattingCostBVT = bvtCost_;
        mattingCostBVG = bvgCost_;
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setEnergyCost(uint cost_) external onlyOwner {
        energyCost = cost_;
    }

    function setProfile(address addr_) external onlyOwner {
        photo = IProfilePhoto(addr_);
    }

    function upLoad(uint tokenId, uint price_) external {
        require(block.timestamp - lastMatingTime[tokenId] >= 3 days, 'mating too soon');
        require(!onSale[tokenId], 'already onSale');
        require(price_ > 0, 'price is none');
        require(stable.isStable(tokenId), 'not in stable');
        require(!stable.isUsing(tokenId), 'is using');
        uint gender;
        bool audlt;
        uint hunger;
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        gender = cattle.getGender(tokenId);
        audlt = cattle.getAdult(tokenId);
        hunger = cattle.getEnergy(tokenId);
        costHunger(tokenId);
        if (matingTime[tokenId] == 5 && cattle.isCreation(tokenId)) {
            require(excessTimes[tokenId] > 0, 'out of limit');
        } else {
            require(matingTime[tokenId] <= 5, 'out limit');
        }
        require(hunger >= 1000 && audlt, 'not allowed');
        onSale[tokenId] = true;
        price[tokenId] = price_;
        index[tokenId] = userUploadList[msg.sender].length;
        userUploadList[msg.sender].push(tokenId);

        emit UpLoad(msg.sender, price_, tokenId);
    }

    function offSale(uint tokenId) external {
        require(onSale[tokenId], 'not onSale');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        onSale[tokenId] = false;
        price[tokenId] = 0;
        uint _index;
        for (uint i = 0; i < userUploadList[msg.sender].length; i ++) {
            if (userUploadList[msg.sender][i] == tokenId) {
                _index = i;
                break;
            }
        }
        userUploadList[msg.sender][_index] = userUploadList[msg.sender][userUploadList[msg.sender].length - 1];
        userUploadList[msg.sender].pop();
        emit OffSale(msg.sender, tokenId);
    }

    function checkMatingTime(uint tokenId) public view returns (uint){
        uint nextTime = lastMatingTime[tokenId] + 3 days - (tec.checkUserTecEffet(stable.CattleOwner(tokenId), 3002));
        return nextTime;
    }

    function checkMattingReward(address addr) internal {
        address invitor = refer.checkUserInvitor(addr);
        if (invitor == address(0)) {
            return;
        }
        totalMatting[addr]++;
        if (totalMatting[addr] >= 5) {
            item.mint(refer.checkUserInvitor(addr), 15, 1);
            totalMatting[addr] = 0;
            emit RewardCard(addr, invitor);
        }
    }

    function checkBoxReward(address addr) internal {
        address invitor = refer.checkUserInvitor(addr);
        if (invitor == address(0)) {
            return;
        }
        boxClaimed[addr]++;
        uint[2] memory par;
        if (boxClaimed[addr] >= 5) {
            box.mint(invitor, par);
            boxClaimed[addr] = 0;
            emit RewardBox(addr, invitor);
        }
    }

    function mating(uint myTokenId, uint targetTokenID) external {
        require(checkMatingTime(myTokenId) <= block.timestamp, 'matting too soon');
        require(findGender(myTokenId) != findGender(targetTokenID), 'wrong gender');
        require(findAdult(myTokenId) && findAdult(targetTokenID), 'not adult');
        require(stable.isStable(myTokenId), 'not in stable');
        require(matingTime[myTokenId] < 5 || excessTimes[myTokenId] > 1, 'out limit');
        address rec = findOwner(targetTokenID);
        costHunger(myTokenId);
        uint temp = price[targetTokenID];
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = temp * tax / 100;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.safeTransferFrom(msg.sender, address(planet), taxAmuont);
        BVT.safeTransferFrom(msg.sender, rec, temp - taxAmuont);
        (uint bvgCost,uint bvtCost) = coutingCost(msg.sender, myTokenId);
        BVG.safeTransferFrom(msg.sender, address(this), bvgCost);
        BVT.safeTransferFrom(msg.sender, address(this), bvtCost);
        stable.addStableExp(msg.sender, 20);
        if (matingTime[myTokenId] == 5 && cattle.isCreation(myTokenId)) {
            excessTimes[myTokenId] --;
        } else {
            matingTime[myTokenId]++;
        }
        if (matingTime[targetTokenID] == 5 && cattle.isCreation(targetTokenID)) {
            excessTimes[targetTokenID] --;
        } else {
            matingTime[targetTokenID]++;
        }
        uint[2] memory par = [myTokenId, targetTokenID];
        box.mint(_msgSender(), par);
        checkMattingReward(msg.sender);
        checkMattingReward(rec);
        checkBoxReward(msg.sender);
        onSale[myTokenId] = false;
        onSale[targetTokenID] = false;
        price[myTokenId] = 0;
        price[targetTokenID] = 0;
        userMatingTimes[msg.sender] ++;
        lastMatingTime[myTokenId] = block.timestamp;
        lastMatingTime[targetTokenID] = block.timestamp;
        uint _index;
        for (uint i = 0; i < userUploadList[rec].length; i ++) {
            if (userUploadList[rec][i] == targetTokenID) {
                _index = i;
                break;
            }
        }
        userUploadList[rec][_index] = userUploadList[rec][userUploadList[rec].length - 1];
        userUploadList[rec].pop();


        emit Mate(msg.sender, myTokenId, targetTokenID);
    }

    function addExcessTimes(uint tokenId, uint amount) external {
        require(cattle.isCreation(tokenId), 'not creation');
        item.burn(msg.sender, 15, amount);
        excessTimes[tokenId] += amount;
    }

    function reSetUserList(address addr,uint[] memory lists) external onlyOwner{
        userUploadList[addr] = lists;
    }

    function selfMating(uint tokenId1, uint tokenId2) external {
        require(checkMatingTime(tokenId1) <= block.timestamp, 'matting too soon');
        require(checkMatingTime(tokenId2) <= block.timestamp, 'matting too soon');
        require(findOwner(tokenId2) == findOwner(tokenId1) && findOwner(tokenId1) == _msgSender(), 'not owner');
        require(findGender(tokenId1) != findGender(tokenId2), 'wrong gender');
        require(findAdult(tokenId1) && findAdult(tokenId2), 'not adult');
        require(stable.isStable(tokenId1) && stable.isStable(tokenId2), 'not in stable');
        // require(matingTime[tokenId1] < 5 && matingTime[tokenId2] < 5 , 'out limit');
        costHunger(tokenId2);
        stable.addStableExp(msg.sender, 20);
        (uint bvgCost,uint bvtCost) = coutingSelfCost(msg.sender, tokenId1, tokenId2);
        BVG.safeTransferFrom(msg.sender, address(this), bvgCost);
        BVT.safeTransferFrom(msg.sender, address(this), bvtCost);
        if (matingTime[tokenId1] == 5 && cattle.isCreation(tokenId1)) {
            excessTimes[tokenId1] --;
        } else {
            matingTime[tokenId1]++;
        }
        if (matingTime[tokenId2] == 5 && cattle.isCreation(tokenId2)) {
            excessTimes[tokenId2] --;
        } else {
            matingTime[tokenId2]++;
        }
        costHunger(tokenId1);
        userMatingTimes[msg.sender] ++;
        uint[2] memory par = [tokenId2, tokenId1];
        box.mint(_msgSender(), par);
        checkBoxReward(msg.sender);
        checkMattingReward(msg.sender);

        lastMatingTime[tokenId1] = block.timestamp;
        lastMatingTime[tokenId2] = block.timestamp;
        emit SelfMatting(msg.sender,tokenId1,tokenId2);

    }

    function resetIndex(address addr) external {
        for (uint i = 0; i < userUploadList[addr].length; i ++) {
            index[userUploadList[addr][i]] = i;
        }
    }

    function getUserUploadList(address addr_) external view returns (uint[] memory){
        return userUploadList[addr_];
    }

    function coutingCost(address addr, uint tokenId) public view returns (uint bvg_, uint bvt_){
        uint rate = tec.checkUserTecEffet(addr, 3001);
        return (mattingCostBVG[matingTime[tokenId]] * rate / 100, mattingCostBVT[matingTime[tokenId]] * rate / 100);
    }

    function coutingSelfCost(address addr, uint tokenId1, uint tokenId2) public view returns (uint, uint){

        (uint bvgCost1,uint bvtCost1) = coutingCost(addr, tokenId1);
        (uint bvgCost2,uint bvtCost2) = coutingCost(addr, tokenId2);
        uint bvgCost = (bvgCost1 + bvgCost2) / 2;
        uint bvtCost = (bvtCost1 + bvtCost2) / 2;
        return (bvgCost, bvtCost);
    }

    function checkMatingTimeBatch(uint[] memory list) external view returns (uint[] memory out){
        out = new uint[](list.length);
        for (uint i = 0; i < list.length; i ++) {
            out[i] = matingTime[list[i]];
        }
    }

    function findAdult(uint tokenId) internal view returns (bool out){
        out = cattle.getAdult(tokenId);
    }

    function findGender(uint tokenId) internal view returns (uint gen){
        gen = cattle.getGender(tokenId);
    }

    function costHunger(uint tokenId) internal {
        stable.costEnergy(tokenId, 1000);
    }

    function findOwner(uint tokenId) internal view returns (address out){
        return stable.CattleOwner(tokenId);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ITec{
    
    function getUserTecLevelBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function getUserTecLevel(address addr,uint ID) external view returns(uint out);
    
    function checkUserExpBatch(address addr,uint[] memory list) external view returns(uint[] memory out);
    
    function checkUserTecEffet(address addr, uint ID) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRefer{
    function checkUserInvitor(address addr) external view returns(address);
    
    function checkUserReferList(address addr) external view returns(address[] memory);
    
    function checkUserReferDirect(address addr) external view returns(uint);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ITec.sol";
import "../interface/Ibadge.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract MilkFactory is OwnableUpgradeable, ERC721HolderUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    ICOW public cattle;
    IStable public stable;
    IPlanet public planet;
    IERC20Upgradeable public BVT;
    ICattle1155 public cattleItem;
    uint public daliyOut;
    uint public rate;
    uint public totalPower;
    uint public debt;
    uint public lastTime;
    uint public cowsAmount;
    uint public timePerEnergy;
    uint constant acc = 1e10;
    uint public technologyId;


    struct UserInfo {
        uint totalPower;
        uint[] cattleList;
        uint cliamed;
    }

    struct StakeInfo {
        bool status;
        uint milkPower;
        uint tokenId;
        uint endTime;
        uint starrtTime;
        uint claimTime;
        uint debt;

    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint => StakeInfo) public stakeInfo;

    uint public totalClaimed;
    ITec public tec;
    IBadge public badge;

    struct UserBadge {
        uint tokenID;
        uint badgeID;
        uint power;
    }

    mapping(address => UserBadge) public userBadge;
    uint randomSeed;
    mapping(uint => uint) public compoundRate;
    mapping(uint => uint) public compoundRew;

    event ClaimMilk(address indexed player, uint indexed amount);
    event RenewTime(address indexed player, uint indexed tokenId, uint indexed newEndTIme);
    event Stake(address indexed player, uint indexed tokenId);
    event UnStake(address indexed player, uint indexed tokenId);
    event Reward(address indexed player, uint indexed reward,uint indexed amount);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        daliyOut = 100e18;
        rate = daliyOut / 86400;
        timePerEnergy = 60;
        technologyId = 1;
        compoundRate[40001] = 500;
        compoundRate[40002] = 300;
        compoundRate[40003] = 100;
        compoundRew[40001] = 2;
        compoundRew[40002] = 6;
        compoundRew[40003] = 18;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setCattle(address cattle_) external onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setTec(address addr) external onlyOwner {
        tec = ITec(addr);
    }

    function setBadge(address addr) external onlyOwner {
        badge = IBadge(addr);
    }

    function setItem(address item_) external onlyOwner {
        cattleItem = ICattle1155(item_);
    }

    function setStable(address stable_) external onlyOwner {
        stable = IStable(stable_);
    }

    function setPlanet(address planet_) external onlyOwner {
        planet = IPlanet(planet_);
    }

    function setBVT(address BVT_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
    }

    function checkUserStakeList(address addr_) public view returns (uint[] memory){
        return userInfo[addr_].cattleList;
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = totalPower > 0 ? rate * (block.timestamp - lastTime) * acc / totalPower + debt : 0 + debt;
    }

    function coutingPower(address addr_, uint tokenId) public view returns (uint){
        uint milk = cattle.getMilk(tokenId) * tec.checkUserTecEffet(addr_, 1001) / 100;
        uint milkRate = cattle.getMilkRate(tokenId) * tec.checkUserTecEffet(addr_, 1002) / 100;
        uint power_ = (milkRate + milk) / 2;
        uint level = stable.getStableLevel(addr_);
        uint rates = stable.rewardRate(level);
        uint finalPower = power_ * rates / 100;
        return finalPower;
    }

    function caculeteCow(uint tokenId) public view returns (uint){
        StakeInfo storage info = stakeInfo[tokenId];
        if (!info.status) {
            return 0;
        }

        uint rew;
        uint tempDebt;
        if (info.claimTime < info.endTime && info.endTime < block.timestamp) {
            tempDebt = rate * (info.endTime - info.claimTime) * acc / totalPower;
            rew = info.milkPower * tempDebt / acc;
        } else {
            tempDebt = coutingDebt();
            rew = info.milkPower * (tempDebt - info.debt) / acc;
        }


        return rew;
    }

    function caculeteAllCow(address addr_) public view returns (uint){
        uint[] memory list = checkUserStakeList(addr_);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
        }
        if (userBadge[addr_].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[addr_].tokenID)));
            rew += caculeteCow(id);
        }
        return rew;
    }

    function userItem(uint tokenId, uint itemId, uint amount) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint[3]memory effect = cattleItem.checkItemEffect(itemId);
        require(effect[0] > 0, 'wrong item');
        uint energyLimit = cattle.getEnergy(tokenId);
        uint value;
        if (amount * effect[0] >= energyLimit) {
            value = energyLimit;
        } else {
            value = amount * effect[0];
        }
        stakeInfo[tokenId].endTime += value * timePerEnergy;
        stable.addStableExp(msg.sender, cattleItem.itemExp(itemId) * amount);
        cattleItem.burn(msg.sender, itemId, amount);
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }


    function claimAllMilk() public {
        uint[] memory list = checkUserStakeList(msg.sender);
        uint rew;
        for (uint i = 0; i < list.length; i++) {
            rew += caculeteCow(list[i]);
            if (block.timestamp >= stakeInfo[list[i]].endTime) {
                debt = coutingDebt();
                totalPower -= stakeInfo[list[i]].milkPower;
                lastTime = block.timestamp;
                delete stakeInfo[list[i]];
                stable.changeUsing(list[i], false);
                cowsAmount --;
                for (uint k = 0; k < userInfo[msg.sender].cattleList.length; k ++) {
                    if (userInfo[msg.sender].cattleList[k] == list[i]) {
                        userInfo[msg.sender].cattleList[k] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                        userInfo[msg.sender].cattleList.pop();
                    }
                }
            } else {
                stakeInfo[list[i]].claimTime = block.timestamp;
                stakeInfo[list[i]].debt = coutingDebt();
            }
        }
        if (userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew += caculeteCow(id);
        }
        uint tax = planet.findTax(msg.sender);
        uint taxAmuont = rew * tax / 100;
        totalClaimed += rew;
        planet.addTaxAmount(msg.sender, taxAmuont);
        BVT.transfer(msg.sender, rew - taxAmuont);
        BVT.transfer(address(planet), taxAmuont);
        userInfo[msg.sender].cliamed += rew - taxAmuont;
        emit ClaimMilk(msg.sender, rew);
    }

    function removeList(address addr, uint index) public onlyOwner {
        uint length = userInfo[addr].cattleList.length;
        userInfo[addr].cattleList[index] = userInfo[addr].cattleList[length - 1];
        userInfo[addr].cattleList.pop();
    }

    function coutingEnergyCost(address addr, uint amount) public view returns (uint){
        uint rates = 100 - tec.checkUserTecEffet(addr, 1003);
        return (amount * rates / 100);
    }


    function stake(uint tokenId, uint energyCost) public {
        require(!stable.isUsing(tokenId), 'the cattle is using');
        require(stable.isStable(tokenId), 'not in the stable');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        require(cattle.getAdult(tokenId), 'must bu adult');
        stable.changeUsing(tokenId, true);
        uint tempDebt = coutingDebt();
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }
        userInfo[msg.sender].cattleList.push(tokenId);
        uint power = coutingPower(msg.sender, tokenId);
        require(power > 0, 'only cow can stake');
        totalPower += power;
        lastTime = block.timestamp;
        debt = tempDebt;
        userInfo[msg.sender].totalPower += power;
        stakeInfo[tokenId] = StakeInfo({
        status : true,
        milkPower : power,
        tokenId : tokenId,
        endTime : findEndTime(tokenId, energyCost),
        starrtTime : block.timestamp,
        claimTime : block.timestamp,
        debt : tempDebt
        });
        stable.costEnergy(tokenId, coutingEnergyCost(msg.sender, energyCost));
        cowsAmount ++;
        emit Stake(msg.sender, tokenId);
    }

    function unStake(uint tokenId) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        uint rew = caculeteCow(tokenId);
        uint tempDebt = coutingDebt();
        if (rew != 0) {
            uint tax = planet.findTax(msg.sender);
            uint taxAmuont = rew * tax / 100;
            planet.addTaxAmount(msg.sender, taxAmuont);
            BVT.transfer(msg.sender, rew - taxAmuont);
            BVT.transfer(address(planet), taxAmuont);
            userInfo[msg.sender].cliamed += rew - taxAmuont;
            totalClaimed += rew;
        }
        debt = tempDebt;
        totalPower -= stakeInfo[tokenId].milkPower;
        userInfo[msg.sender].totalPower -= stakeInfo[tokenId].milkPower;
        lastTime = block.timestamp;
        delete stakeInfo[tokenId];
        stable.changeUsing(tokenId, false);
        for (uint i = 0; i < userInfo[msg.sender].cattleList.length; i ++) {
            if (userInfo[msg.sender].cattleList[i] == tokenId) {
                userInfo[msg.sender].cattleList[i] = userInfo[msg.sender].cattleList[userInfo[msg.sender].cattleList.length - 1];
                userInfo[msg.sender].cattleList.pop();
            }
        }
        if (userInfo[msg.sender].cattleList.length == 0 && userBadge[msg.sender].tokenID != 0) {
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;
            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
        }
        cowsAmount--;
        emit UnStake(msg.sender, tokenId);
    }

    function setDaliyOut(uint out_) external onlyOwner {
        daliyOut = out_;
        rate = daliyOut / 86400;
    }

    function addBadge(uint tokenID) external {
        require(userBadge[msg.sender].tokenID == 0, 'had badge');
        badge.safeTransferFrom(msg.sender, address(this), tokenID);
        userBadge[msg.sender].tokenID = tokenID;
        userBadge[msg.sender].badgeID = badge.badgeIdMap(tokenID);
        userBadge[msg.sender].power = badge.checkBadgeEffect(userBadge[msg.sender].badgeID);
        if (userInfo[msg.sender].cattleList.length > 0) {
            uint tempDebt = coutingDebt();
            debt = tempDebt;
            totalPower += userBadge[msg.sender].power;
            userInfo[msg.sender].totalPower += userBadge[msg.sender].power;
            lastTime = block.timestamp;
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, tokenID)));
            stakeInfo[id] = StakeInfo({
            status : true,
            milkPower : userBadge[msg.sender].power,
            tokenId : id,
            endTime : block.timestamp + 86400000,
            starrtTime : block.timestamp,
            claimTime : block.timestamp,
            debt : tempDebt
            });
        }

    }

    function pullOutBadge() external {
        require(userBadge[msg.sender].tokenID != 0, 'have no badge');
        badge.safeTransferFrom(address(this), msg.sender, userBadge[msg.sender].tokenID);

        if(userInfo[msg.sender].cattleList.length > 0){
            uint id = uint256(keccak256(abi.encodePacked(msg.sender, userBadge[msg.sender].tokenID)));
            uint rew = caculeteCow(id);
            if (rew != 0) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = rew * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.transfer(msg.sender, rew - taxAmuont);
                BVT.transfer(address(planet), taxAmuont);
                userInfo[msg.sender].cliamed += rew - taxAmuont;
                totalClaimed += rew;

            }
            userInfo[msg.sender].totalPower -= stakeInfo[id].milkPower;
            debt = coutingDebt();
            totalPower -= stakeInfo[id].milkPower;
            lastTime = block.timestamp;
            delete stakeInfo[id];
        }


        delete userBadge[msg.sender];
    }

    function renewTime(uint tokenId, uint energyCost) public {
        require(stakeInfo[tokenId].status, 'not staking');
        require(stable.CattleOwner(tokenId) == msg.sender, "not cattle's owner");
        stable.costEnergy(tokenId, energyCost);
        stakeInfo[tokenId].endTime += energyCost * timePerEnergy;
        emit RenewTime(msg.sender, tokenId, stakeInfo[tokenId].endTime);
    }

    function setCompoundRate(uint badgeID, uint rates) external onlyOwner {
        compoundRate[badgeID] = rates;
    }

    function setCompoundRew(uint badgeId,uint rews) external onlyOwner{
        compoundRew[badgeId] = rews;
    }

    function findEndTime(uint tokenId, uint energyCost) public view returns (uint){
        uint energyTime = block.timestamp + energyCost * timePerEnergy;
        uint deadTime = cattle.deadTime(tokenId);
        if (energyTime <= deadTime) {
            return energyTime;
        } else {
            return deadTime;
        }
    }

    function compoundBadge(uint[3] memory tokenIDs) external {
        uint badgeID = badge.badgeIdMap(tokenIDs[0]);
        require(badgeID >= 40001 && badgeID <= 40003, 'wrong badge ID');
        require(badgeID == badge.badgeIdMap(tokenIDs[1]) && badge.badgeIdMap(tokenIDs[1]) == badge.badgeIdMap(tokenIDs[2]), 'wrong badgeID');
        badge.burn(tokenIDs[0]);
        badge.burn(tokenIDs[1]);
        badge.burn(tokenIDs[2]);
        uint _rate = compoundRate[badgeID];
        uint out = rand(1000);
        if (out <= _rate) {
            badge.mint(msg.sender, badgeID + 1);
            emit Reward(msg.sender,badgeID + 1,1);
        } else {
            cattleItem.mint(msg.sender,20004,compoundRew[badgeID]);
            emit Reward(msg.sender,20004,compoundRew[badgeID]);
        }
    }

    function compoundBadgeShred() external {
        cattleItem.burn(msg.sender,20004,3);
        uint out = rand(100);
        if(out <= 700){
            badge.mint(msg.sender, 40001);
            emit Reward(msg.sender,40001,1);
        }else{
            emit Reward(msg.sender,0,0);
        }
    }

    function setDebt(uint debt_) external onlyOwner{
        debt = debt_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBadge{
    function mint(address player,uint skinId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function checkUserBadgeList(address player) external view returns (uint[] memory);
    function badgeIdMap(uint tokenID) external view returns(uint);
    function checkUserBadge(address player,uint ID) external view returns(uint[] memory);
    function checkBadgeEffect(uint badgeID) external view returns(uint);
    function checkUserBadgeIDList(address player) external view returns (uint[] memory);
    function burn(uint tokenId_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

contract Market721 is OwnableUpgradeable, ERC721HolderUpgradeable{
    uint private _goodsSeq;
    // handle fee(percentage)
    uint public fee;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // define goods type
    mapping(uint => GoodsInfo) public goodsInfos;

    // support currency. by default,1 is main coin
    mapping(uint => address) public tradeType;

    mapping(uint => mapping(uint => Goods)) public sellingGoods;
    mapping(uint => mapping(address => uint[])) private _sellingList;

    mapping(uint => uint) public _sold;
    mapping(uint => bool) public currencyStatus;
    uint public mainCoinID;


    function init() public initializer {
        __Ownable_init();

        _goodsSeq = 1;
        fee = 2;
    }

    struct Goods {
        uint id;
        uint tradeType;
        uint price;
        address owner;
    }

    struct GoodsInfo {
        ERC721Upgradeable place;
        string name;
    }


    event UpdateGoodsStatus(uint indexed goodsId, bool indexed status, uint goodsType, uint tokenId, uint tradeType, uint price, address seller);
    event Exchanged(uint goodsId, uint goodsType, uint tokenId, uint tradeType, uint price, address seller, address buyer);
    event NewGoods(uint goodsType, string name, address place);


    // ------------------------------  only owner ---------------------------------------
    function newTradeType(uint tradeType_, address bank_) external onlyOwner returns (bool) {
        require(tradeType_ != mainCoinID && tradeType[tradeType_] == address(0),"Wrong trade type");
        tradeType[tradeType_] = bank_;
        currencyStatus[tradeType_] = true;
        return true;
    }

    function changeTradeType(uint id_, address bank) external onlyOwner  {
        require(id_ != mainCoinID && tradeType[id_] != address(0),"Wrong change type");
        tradeType[id_] = bank;
    }


    function changeFee(uint fee_) external onlyOwner returns (bool) {
        require(fee_ > 0 && fee_ != fee,"Invalid fee");
        fee = fee_;
        return true;
    }

    function newGoodsInfo(uint types_, address place_, string memory name_) external onlyOwner returns (bool) {
        require(place_ != address(0) && address(goodsInfos[types_].place) == address(0), "New goods");

        goodsInfos[types_] = GoodsInfo({
        name:name_,
        place:ERC721Upgradeable(place_)
        });

        emit NewGoods(types_, name_, place_);
        return true;
    }

    function divestFee(address payable payee_, uint value_, uint tradeType_) external onlyOwner returns (bool){
        if (tradeType_ == mainCoinID) {
            payee_.transfer(value_);
            return true;
        }
        require(tradeType[tradeType_] != address(0), "Divest type");
        address bank = tradeType[tradeType_];
        IERC20Upgradeable(bank).safeTransfer(payee_, value_);
        return true;
    }

    function queryGoodsSoldData(uint types_) external onlyOwner view returns (uint) {
        return _sold[types_];
    }

    function getGoodsSeq() external onlyOwner view returns (uint) {
        return _goodsSeq;
    }

    function updateCurrencyStatus(uint tradeType_, bool status) external onlyOwner {
        if (tradeType_ != mainCoinID) {
            require(tradeType[tradeType_] != address(0), "Invalid trade type");
        }
        currencyStatus[tradeType_] = status;
    }

    function setMainCoin(uint main) external onlyOwner {
        mainCoinID = main;
    }


    // ------------------------------  only owner end---------------------------------------

    function sell(uint goodsType_, uint tokenId_, uint tradeType_, uint price_) public {
        require(currencyStatus[tradeType_], "forbidden");
        require(price_ < 1e26 && price_ % 1e15 == 0, "Price");
        require(address(goodsInfos[goodsType_].place) != address(0), "Wrong goods");

        if (tradeType_ != mainCoinID) {
            require(tradeType[tradeType_] != address(0), "Invalid trade type");
        }

        goodsInfos[goodsType_].place.safeTransferFrom(_msgSender(), address(this), tokenId_);

        sellingGoods[goodsType_][tokenId_] = Goods ({
        id : _goodsSeq,
        tradeType : tradeType_,
        price : price_,
        owner: _msgSender()
        });

        _sellingList[goodsType_][_msgSender()].push(tokenId_);
        emit UpdateGoodsStatus(_goodsSeq, true, goodsType_, tokenId_, tradeType_, price_, _msgSender());
        _goodsSeq += 1;
    }

    function cancelSell(uint goodsType_, uint tokenID) public {
        uint arrLen = _sellingList[goodsType_][_msgSender()].length;
        bool exist;
        uint idx;
        for (uint i = 0; i < arrLen; i++) {
            if (_sellingList[goodsType_][_msgSender()][i] == tokenID) {
                exist = true;
                idx = i;
                break;
            }
        }

        require(exist, "invalid token ID");
        if (arrLen > 1 && idx < arrLen - 1) {
            _sellingList[goodsType_][_msgSender()][idx] = _sellingList[goodsType_][_msgSender()][arrLen - 1];
        }

        _sellingList[goodsType_][_msgSender()].pop();
        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenID);

        uint goodsId = sellingGoods[goodsType_][tokenID].id;
        delete sellingGoods[goodsType_][tokenID];

        emit UpdateGoodsStatus(goodsId, false, goodsType_, tokenID, 0, 0, address(0));
    }

    function mainCoinPurchase(uint goodsType_, uint tokenId_) public payable {
        Goods memory info = sellingGoods[goodsType_][tokenId_];
        require(info.id > 0, "Not selling");
        require(info.tradeType == mainCoinID, "Main coin");

        require(info.price == msg.value, "Value");
        require(info.owner != _msgSender(), "Own");

        uint handleFee = info.price / 100 * fee;
        uint amount = info.price - handleFee;
        payable(info.owner).transfer(amount);

        purchaseProcess(info.id, info.owner, goodsType_, tokenId_, info.tradeType, info.price);
    }

    function erc20Purchase(uint goodsType_, uint tokenId_) public {
        Goods memory info = sellingGoods[goodsType_][tokenId_];

        require(info.id > 0, "Not selling");
        require(info.tradeType != mainCoinID, "erc20");
        require(info.owner != _msgSender(), "Own");

        uint handleFee =  info.price / 100 * fee;
        uint amount = info.price - handleFee;

        address banker = tradeType[info.tradeType];
        IERC20Upgradeable(banker).safeTransferFrom(_msgSender(), info.owner, amount);
        IERC20Upgradeable(banker).safeTransferFrom(_msgSender(), address(this), handleFee);

        purchaseProcess(info.id, info.owner, goodsType_, tokenId_, info.tradeType, info.price);
    }

    function purchaseProcess(uint goodsId_, address owner_, uint goodsType_, uint tokenId_, uint tradeType_, uint price_) internal {
        popToken(goodsType_, owner_, tokenId_);

        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenId_);
        delete sellingGoods[goodsType_][tokenId_];
        _sold[goodsType_] += 1;

        emit Exchanged(goodsId_, goodsType_, tokenId_, tradeType_, price_, owner_, _msgSender());
    }

    function popToken(uint goodsType_, address owner_, uint tokenID) internal{
        uint length = _sellingList[goodsType_][owner_].length;
        uint lastIdx = length - 1;
        for (uint i = 0; i < lastIdx; i++) {
            if (_sellingList[goodsType_][owner_][i] == tokenID) {
                _sellingList[goodsType_][owner_][i] = _sellingList[goodsType_][owner_][lastIdx];
                break;
            }
        }
        _sellingList[goodsType_][owner_].pop();
    }

    function getUserSaleList(uint goodsType_, address addr_) public view returns (uint[3][] memory data) {
        uint len = _sellingList[goodsType_][addr_].length;
        data = new uint[3][](len);
        for (uint i = 0; i < len; i++) {
            uint[3] memory saleGoods;
            uint tokenId = _sellingList[goodsType_][addr_][i];
            saleGoods[0] = tokenId;
            saleGoods[1] = sellingGoods[goodsType_][tokenId].tradeType;
            saleGoods[2] = sellingGoods[goodsType_][tokenId].price;
            data[i] = saleGoods;
        }
    }

    function getUserSaleTokenId(uint goodsType_,address addr) public view returns(uint[] memory data) {
        return _sellingList[goodsType_][addr];
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract Relationship is OwnableUpgradeable{
    using StringsUpgradeable for uint256;
    // mapping(address => mapping(uint => address)) public applys;//1 for friend, 2 for lover, 3 for bestie, 4 for confidant, 5 for bro
    // mapping(address => mapping(uint => address)) public relation;
    // mapping(address => mapping(uint => uint)) public relationAmount;
    mapping(address => mapping(address => uint)) public relationTypes;
    // mapping(uint => uint) public limit;
    struct UserInfo{
        uint gender;
        mapping(uint => address[]) relationGroup;
    }
    mapping(address => UserInfo) public userInfo;
    address public banker;
    event ApplyRelationship(address indexed player, address indexed target, uint indexed types);
    event AcceptRelationship(address indexed player, address indexed traget, uint indexed types);
    event BondRelationship(uint indexed relationshipID, string indexed couple, uint indexed types);

    mapping(string => uint) relationIdentify;
    uint public rid;

    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();

        rid = 1;
    }

    function bond(address[2] memory addr,uint types, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash = keccak256(abi.encodePacked(addr, types));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(addr[1] != addr[0],'wrong address');
        require(types > 0 && types <= 5,'wrong type');
        relationTypes[addr[0]][addr[1]] = types;
        relationTypes[addr[1]][addr[0]] = types;

        string memory rkey = relationshipKey(addr);
        emit BondRelationship(rid,rkey,types);

        relationIdentify[rkey] = rid;
        rid += 1;
    }


    function relationshipKey(address[2] memory addr) public pure returns(string memory ){
        address [2] memory a;
        if (uint256(uint160(addr[0])) > uint256(uint160(addr[1]))) {
            a[0] = addr[0];
            a[1] = addr[1];
        } else {
            a[0] = addr[1];
            a[1] = addr[0];
        }
        return string(abi.encodePacked(uint256(uint160(addr[0])).toHexString(),"#",uint256(uint160(addr[1])).toHexString()));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


contract ProfilePhoto is OwnableUpgradeable, ERC1155Upgradeable {
    using StringsUpgradeable for uint256;

    uint public photoId;
    address public bank;

    mapping(address => bool) public minters;

    mapping(address => uint[]) public userPhotos;
    mapping(uint => ProfilePhotoDefine) photos;

    struct ProfilePhotoDefine{
        string name;
    }

    string private _name;
    string private _symbol;


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }


    function init() public initializer {
        __Ownable_init();
        __ERC1155_init("");

        _name = "profile photo";
        _symbol = "";

        newProfilePhoto("Baby Bull");      // 1
        newProfilePhoto("Adult Bull");     // 2
        newProfilePhoto("Baby Cow");       // 3
        newProfilePhoto("Adult Cow");      // 4
        newProfilePhoto("Mystery Box");    // 5
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(isApprovedForAll(from, _msgSender()), "ERC721: transfer caller is not owner nor approved");
        require(minters[_msgSender()],"not admin");
        _safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        require(minters[_msgSender()],"not admin");
        _safeBatchTransferFrom(from, to, ids, amounts, data);

    }

    function newMinter(address minter_) public onlyOwner {
        require(!minters[minter_],"exist minter");
        minters[minter_] = true;
    }

    function newProfilePhoto(string memory name_) public onlyOwner {
        photoId++;
        photos[photoId] = ProfilePhotoDefine({
        name:name_
        });
    }

    function mint(address addr_, uint id_) public returns(bool) {
        require(id_ > 0 && id_ <= photoId,"invalid id" );
        require(minters[_msgSender()],"not minter's calling");

        uint balance =  balanceOf(addr_, id_);
        if (balance > 0) {
            return true;
        }

        _mint(addr_, id_, 1, "");
        userPhotos[addr_].push(id_);
        return true;
    }

    function mintBabyBull(address addr_) public {
        mint(addr_,1);
    }

    function mintAdultBull(address addr_) public {
        mint(addr_,2);
    }

    function mintBabyCow(address addr_) public {
        mint(addr_,3);
    }

    function mintAdultCow(address addr_) public {
        mint(addr_,4);
    }

    function mintMysteryBox(address addr_) public {
        mint(addr_,5);
    }

    function getUserPhotos(address addr_) public view returns(uint[]memory){
        return userPhotos[addr_];
    }

    function getPhotoName(uint id_) public view returns(string memory) {
        return photos[id_].name;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract Market1155 is OwnableUpgradeable, ERC1155HolderUpgradeable{
    uint private _goodsId;
    // handle fee(percentage)
    uint public fee;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // define goods type
    mapping(uint => GoodsInfo) public goodsInfos;

    // support currency. by default,1 is main coin
    mapping(uint => address) public tradeType;

    //    mapping(uint => mapping(uint => goods)) public sellingGoods;
    mapping(uint => Goods) public sellingGoods;
    mapping(uint => mapping(address => uint[])) private _sellingList;

    mapping(uint => uint) private _sold;

    function init() public initializer {
        __Ownable_init();

        _goodsId = 1;
        fee = 2;
    }

    struct Goods {
        uint id;
        uint goodsType;
        uint tradeType;
        uint price;
        uint amount;
        address owner;
    }

    struct GoodsInfo {
        IERC1155Upgradeable place;
        string name;
    }


    event UpdateGoodsStatus(uint indexed goodsId, bool indexed status, uint goodsType, uint tokenId, uint amount, uint tradeType, uint price);
    event Exchanged(uint goodsId, uint goodsType, uint tokenId, uint amount, uint tradeType, uint price, address seller, address buyer);
    event NewGoods(uint goodsType, string name, address place);


    // ------------------------------  only owner ---------------------------------------
    function newTradeType(uint id_, address bank_) external onlyOwner returns (bool) {
        require(id_ > 1 && tradeType[id_] == address(0),"Wrong trade type");
        tradeType[id_] = bank_;
        return true;
    }

    function changeFee(uint fee_) external onlyOwner returns (bool) {
        require(fee_ > 0 && fee_ != fee,"Invalid fee");
        fee = fee_;
        return true;
    }

    function newGoodsInfo(uint types_, address place_, string memory name_) external onlyOwner returns (bool) {
        require(place_ != address(0) && address(goodsInfos[types_].place) == address(0), "New goods");

        goodsInfos[types_] = GoodsInfo({
        name:name_,
        place:IERC1155Upgradeable(place_)
        });

        emit NewGoods(types_, name_, place_);
        return true;
    }

    function divestFee(address payable payee_, uint value_, uint tradeType_) external onlyOwner returns (bool){
        if (tradeType_ == 1) {
            payee_.transfer(value_);
            return true;
        }
        require(tradeType[tradeType_] != address(0), "Divest type");
        address bank = tradeType[tradeType_];
        IERC20Upgradeable(bank).safeTransfer(payee_, value_);
        return true;
    }

    function queryGoodsSoldData(uint types_) external onlyOwner view returns (uint) {
        return _sold[types_];
    }

    function getGoodsId() external onlyOwner view returns (uint) {
        return _goodsId;
    }


    // ------------------------------  only owner end---------------------------------------

    function sell(uint goodsType_, uint tokenId_, uint amount_, uint tradeType_, uint price_) public {
        require(price_ >= 1e16 && price_ < 1e26, "Price");
        require(address(goodsInfos[goodsType_].place) != address(0) && amount_ > 0, "Wrong goods");

        if (tradeType_ != 1) {
            require(tradeType[tradeType_] != address(0), "Invalid trade type");
        }

        goodsInfos[goodsType_].place.safeTransferFrom(_msgSender(), address(this), tokenId_, amount_, "");

        sellingGoods[_goodsId] = Goods ({
        id : tokenId_,
        goodsType : goodsType_,
        tradeType : tradeType_,
        price : price_,
        amount : amount_,
        owner: _msgSender()
        });

        _sellingList[goodsType_][_msgSender()].push(tokenId_);

        emit UpdateGoodsStatus(_goodsId, true, goodsType_, tokenId_, amount_, tradeType_, price_);
        _goodsId += 1;
    }

    function cancelSell(uint goodsId_) public {
        require(sellingGoods[goodsId_].id != 0, "Invalid goodsId");

        Goods memory info = sellingGoods[goodsId_];
        uint arrLen = _sellingList[info.goodsType][_msgSender()].length;
        if (arrLen > 2) {
            for (uint i = 0; i + 1 < arrLen; i++) {
                if (_sellingList[info.goodsType][_msgSender()][i] == goodsId_) {
                    _sellingList[info.goodsType][_msgSender()][i] =  _sellingList[info.goodsType][_msgSender()][arrLen - 1];
                    break;
                }
            }
        }

        _sellingList[info.goodsType][_msgSender()].pop();
        goodsInfos[info.goodsType].place.safeTransferFrom(address(this), _msgSender(), info.id, info.amount, "");
        delete sellingGoods[goodsId_];

        emit UpdateGoodsStatus(goodsId_, false, info.goodsType, info.id, info.amount, 0, 0);
    }

    function mainCoinPurchase(uint goodsId_) public payable {
        Goods memory info = sellingGoods[goodsId_];
        require(info.id != 0 && info.tradeType == 1, "Main coin");
        require(info.price == msg.value, "Value");
        require(info.owner != _msgSender(), "Own");

        uint handleFee = info.price / 100 * fee;
        uint amount = info.price - handleFee;

        payable(address(this)).transfer(msg.value);
        payable(info.owner).transfer(amount);

        purchaseProcess(goodsId_, info.owner, info.goodsType, info.id, info.amount, info.tradeType, info.price);
    }

    function erc20Purchase(uint goodsId_) public {
        Goods memory info = sellingGoods[goodsId_];
        require(info.id != 0 && info.tradeType != 1, "erc20");
        require(info.owner != _msgSender(), "Own");

        uint handleFee =  info.price / 100 * fee;
        uint amount = info.price - handleFee;

        address banker = tradeType[info.tradeType];
        IERC20Upgradeable(banker).transferFrom(_msgSender(), info.owner, amount);
        IERC20Upgradeable(banker).transferFrom(_msgSender(), address(this), handleFee);

        purchaseProcess(goodsId_, info.owner, info.goodsType, info.id, info.amount, info.tradeType, info.price);
    }

    function purchaseProcess(uint goodsId_, address owner_, uint goodsType_, uint tokenId_, uint amount_, uint tradeType_, uint price_) internal {
        uint length = _sellingList[goodsType_][owner_].length;

        if (length > 2) {
            for (uint i = 0; i + 1 < length; i++) {
                if (_sellingList[goodsType_][owner_][i] == tokenId_) {
                    _sellingList[goodsType_][owner_][i] = _sellingList[goodsType_][owner_][length - 1];
                    break;
                }
            }
        }
        _sellingList[goodsType_][owner_].pop();

        goodsInfos[goodsType_].place.safeTransferFrom(address(this), _msgSender(), tokenId_, amount_, "");
        delete sellingGoods[goodsId_];
        _sold[goodsType_] += 1;

        emit Exchanged(goodsId_, goodsType_, tokenId_, amount_, tradeType_, price_, owner_, _msgSender());
    }


    function getSellingList(uint goodsType_, address addr_) public view returns (uint[] memory) {
        return _sellingList[goodsType_][addr_];
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "../interface/IMating.sol";
import "../interface/Iprofile_photo.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interface/ICompound.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Mail is OwnableUpgradeable {
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    ICOW public cattle;
    IPlanet public planet;
    ICattle1155 public item;
    IStable public stable;
    IMating public mating;
    IProfilePhoto public avatar;
    IBOX public box;
    //------------------------
    ICompound public compound;
    IMilk public milk;
    address public banker;
    mapping(uint => address) public idClaim;
    mapping(address => uint) public bvgClaimed;
    mapping(address => uint) public bvtClaimed;
    mapping(address => mapping(address => uint)) public relationTypes;
    mapping(uint => address[2]) public relationIdentify;
    uint public rid;
    uint public times;
    event ClaimMail(address indexed player, uint indexed id);
    event BondRelationship(address indexed player1, address indexed player2, uint indexed types, uint relationshipID);
    event UnBondRelationship(uint indexed relationshipID);
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function setCattle(address addr_) external onlyOwner {
        cattle = ICOW(addr_);
    }

    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet(addr_);
    }

    function setTimes(uint times_) external onlyOwner{
        times = times_;
    }

    function setItem(address addr_) external onlyOwner {
        item = ICattle1155(addr_);
    }

    function setStable(address addr_) external onlyOwner {
        stable = IStable(addr_);
    }

    function setMating(address addr) external onlyOwner {
        mating = IMating(addr);
    }

    function setProfilePhoto(address addr) external onlyOwner {
        avatar = IProfilePhoto(addr);
    }

    function setCompound(address addr) external onlyOwner {
        compound = ICompound(addr);
    }

    function setMilk(address addr) external onlyOwner {
        milk = IMilk(addr);
    }

    function setBox(address addr) external onlyOwner {
        box = IBOX(addr);
    }

    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }

    function setBanker(address addr) external onlyOwner {
        banker = addr;
    }
    //  rewardType : 1 for cattle,           2 for item, 3 for skin, 4 for box, 5 for BVT, 6 for BVG
    //rewardId :     1 for creation, 2 for nomral,   
    function bond(address addr1,address addr2, uint types, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash1 = keccak256(abi.encodePacked(addr1,addr2));
        bytes32 hash2 = keccak256(abi.encodePacked(types));
        bytes32 hash = keccak256(abi.encodePacked(hash1,hash2));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(addr1 != addr2, 'wrong address');
        require(types > 0 && types <= 5, 'wrong type');
        require(relationTypes[addr1][addr2] == 0, "bonded");
        relationTypes[addr1][addr2] = types;
        relationTypes[addr2][addr1] = types;

        rid += 1;

        address[2] memory couple;
        couple[0] = addr1;
        couple[1] = addr2;
        relationIdentify[rid] = couple;

        emit BondRelationship(addr1,addr2,types,rid);
    }

    function unBond(uint relationID) external {
        address another;
        if (relationIdentify[relationID][0] == _msgSender()) {
            another = relationIdentify[relationID][1];
        } else if (relationIdentify[relationID][1] == _msgSender()){
            another = relationIdentify[relationID][0];
        }

        require(another != address(0),'no type');
        relationTypes[msg.sender][another] = 0;
        relationTypes[another][msg.sender] = 0;

        emit UnBondRelationship(relationID);
    }

    function claimMail(uint[] memory rewardType, uint[] memory rewardId, uint[] memory rewardAmount, bool isTax, uint id, bytes32 r, bytes32 s, uint8 v) public {
        bytes32 hash1 = keccak256(abi.encodePacked(rewardType, rewardId));
        bytes32 hash2 = keccak256(abi.encodePacked(rewardAmount));
        bytes32 hash3 = keccak256(abi.encodePacked(id, msg.sender));
        bytes32 hash4 = keccak256(abi.encodePacked(isTax));
        bytes32 hash = keccak256(abi.encodePacked(hash1, hash2, hash3, hash4));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "not banker");
        require(idClaim[id] == address(0), 'claimed');
        require(rewardType.length == rewardId.length && rewardId.length == rewardAmount.length, 'wrong length');
        for (uint i = 0; i < rewardType.length; i ++) {
            if (rewardType[i] == 0) {
                break;
            }
            _processMail(rewardType[i], rewardId[i], rewardAmount[i],isTax);
        }
        idClaim[id] = msg.sender;
        emit ClaimMail(msg.sender, id);
    }

    function _processMail(uint types, uint rewardId, uint amount, bool isTax) internal {
        if (types == 1) {
            if (rewardId == 1) {
                cattle.mint(msg.sender);
            } else {
                cattle.mintNormallWithParents(msg.sender);
            }
        } else if (types == 2) {
            item.mint(msg.sender, rewardId, amount);
        } else if (types == 3) {

        } else if (types == 4) {
            uint[2] memory par;
            for(uint i = 0; i < amount; i++){
                box.mint(msg.sender, par);
            }

        } else if (types == 5) {
            if (isTax) {
                uint tax = planet.findTax(msg.sender);
                uint taxAmuont = amount * tax / 100;
                planet.addTaxAmount(msg.sender, taxAmuont);
                BVT.safeTransfer(msg.sender, amount - taxAmuont);
                BVT.safeTransfer(address(planet), taxAmuont);
                bvtClaimed[msg.sender] += amount;
            }else{
                BVT.safeTransfer(msg.sender, amount);
            }

        } else if (types == 6) {
            BVG.safeTransfer(msg.sender, amount);
            bvgClaimed[msg.sender] += amount;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IMating {
    function matingTime(uint tokenId) external view returns(uint);
    
    function lastMatingTime(uint tokenId) external view returns(uint);
    
    function userMatingTimes(address addr) external view returns(uint);

    function checkMatingTime(uint tokenId) external view returns (uint);

    function excessTimes(uint tokenId) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICompound{
    function starExp(uint tokenId) external view returns(uint);
    
    function upgradeLimit(uint star_) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import  "../interface/IPlanet.sol";
import "../interface/ICattle1155.sol";
import "../interface/IMating.sol";
import "../interface/Iprofile_photo.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../interface/ICompound.sol";
import "../interface/IMarket.sol";
import "../interface/IMail.sol";
import "../interface/ITec.sol";
import "../interface/IPlanet721.sol";
import "../interface/Ibadge.sol";
import "../interface/ISkin.sol";
contract Info is OwnableUpgradeable{

    using StringsUpgradeable for uint256;
    ICOW public cattle;
    IPlanet public planet;
    ICattle1155 public item;
    IStable public stable;
    IMating public mating;
    IProfilePhoto public avatar;
    //------------------------
    ICompound public compound;
    IMilk public milk;
    IMarket public market;
    IMail public mail;
    ITec public tec;
    IPlanet721 public planet721;
    IBadge public badge;
    ISkin public skin;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    
    function setCattle(address addr_) external onlyOwner{
        cattle = ICOW(addr_);
    }

    function setTec(address addr) external onlyOwner{
        tec = ITec(addr);
    }
    
    function setPlanet(address addr_) external onlyOwner {
        planet = IPlanet(addr_);
    }
    
    function setItem(address addr_) external onlyOwner {
        item = ICattle1155(addr_);
    }
    function setSkin(address addr) external onlyOwner{
        skin = ISkin(addr);
    }
    function setStable(address addr_) external onlyOwner {
        stable = IStable(addr_);
    }
    
    function setMating(address addr) external onlyOwner{
        mating = IMating(addr);
    }

    function setProfilePhoto(address addr) external onlyOwner{
        avatar = IProfilePhoto(addr);
    }
    
    function setCompound(address addr) external onlyOwner{
        compound = ICompound(addr);
    }
    
    function setMilk(address addr) external onlyOwner{
        milk = IMilk(addr);
    }
    
    function setMail(address addr) external onlyOwner{
        mail = IMail(addr);
    }

    function setPlanet721(address addr)external onlyOwner{
        planet721 = IPlanet721(addr);
    }

    function setBadge(address addr) external onlyOwner{
        badge = IBadge(addr);
    }
    
    function bullPenInfo(address addr_) external view returns(uint,uint,uint,uint[] memory) {
        (uint stableAmount ,uint exp) = stable.userInfo(addr_);
        return(stableAmount,exp,stable.getStableLevel(addr_),stable.checkUserCows(addr_));
    }

    function checkUserPlanet(address player,uint types_) external view returns(uint[] memory){
        uint tempBalance = planet721.balanceOf(player);
        uint token;
        uint count;
        for (uint i = 0; i < tempBalance; i++) {
            token = planet721.tokenOfOwnerByIndex(player, i);
            if(planet721.planetIdMap(token) == types_){
                count++;
            }

        }
        uint[] memory list = new uint[](count);
        uint index = 0;
        for (uint i = 0; i < tempBalance; i++) {
            token = planet721.tokenOfOwnerByIndex(player, i);
            if(planet721.planetIdMap(token) == types_){
                list[index] = token;
                index ++;
            }

        }
        return list;
    }
    
    function cowInfoes(uint tokenId) external view returns(uint[23] memory info1,bool[3] memory info2, uint[2] memory parents){
        info2[0] = cattle.isCreation(tokenId);
        info2[1] = stable.isUsing(tokenId);
        info2[2] = cattle.getAdult(tokenId);
        info1[0] = cattle.getGender(tokenId);
        info1[1] = cattle.getBronTime(tokenId);
        info1[2] = cattle.getEnergy(tokenId);
        info1[3] = cattle.getLife(tokenId);
        info1[4] = cattle.getGrowth(tokenId);
        info1[5] = 0;
        info1[6] = cattle.getAttack(tokenId);
        info1[7] = cattle.getStamina(tokenId);
        info1[8] = cattle.getDefense(tokenId);
        info1[9] = cattle.getMilk(tokenId);
        info1[10] = cattle.getMilkRate(tokenId);
        info1[11] = cattle.getStar(tokenId);
        info1[12] = cattle.deadTime(tokenId);
        info1[13] = stable.energy(tokenId);
        info1[14] = stable.grow(tokenId);
        info1[15] = stable.refreshTime();
        info1[16] = stable.growAmount(info1[15],tokenId);
        info1[17] = stable.feeding(tokenId);
        info1[18] = 5 + mating.excessTimes(tokenId) - mating.matingTime(tokenId);
        info1[19] = mating.lastMatingTime(tokenId);
        info1[20] = compound.starExp(tokenId);
        info1[21] = cattle.creationIndex(tokenId);
        info1[22] = mating.checkMatingTime(tokenId);
        parents = cattle.getCowParents(tokenId);
    }
    
    function _checkUserCows(address player) internal view returns(uint male,uint female,uint creation){
        uint[] memory list1 = cattle.checkUserCowListType(player,true);
        uint[] memory list2 = cattle.checkUserCowList(player);
        creation = list1.length;
        for(uint i = 0; i < list2.length; i ++){
            if(cattle.getGender(list2[i]) == 1){
                male ++;
            }else{
                female ++;
            }
        }
        uint[] memory list3 = stable.checkUserCows(player);
        for(uint i = 0; i < list3.length; i ++){
            if(cattle.isCreation(list3[i])){
                creation ++;
            }
            if (cattle.getGender(list3[i]) == 1){
                male ++;
            }else{
                female ++;
            }
        }
    }
    
    function userCenter(address player) external view returns(uint[10] memory info){
        (info[0],info[1],info[2]) = _checkUserCows(player);
        info[3] = stable.getStableLevel(player);
        (,info[4]) = stable.userInfo(player);
        if(info[3] >= 5){
            info[5] = 0;
        }else{
            info[5] = stable.levelLimit(info[3]);
        }
        
        info[6] = mating.userMatingTimes(player);
        info[7] = planet.getUserPlanet(player);
        (info[9],info[8]) = coutingCoin(player);
    }
    
    function coutingCoin(address addr) internal view returns(uint bvg_, uint bvt_){
        bvg_ += mail.bvgClaimed(addr);
        bvt_ += mail.bvtClaimed(addr);
        (,uint temp) = milk.userInfo(addr);
        bvt_ += temp;
    }
    
    function compoundInfo(uint tokenId, uint[] memory targetId) external view returns(uint[5] memory info){
        info[0] = compound.upgradeLimit(cattle.getStar(tokenId));
        if(targetId.length == 0){
            return info;
        }
        uint star = cattle.getStar(tokenId);
        info[1] = cattle.starLimit(star);
        if (star <3){
            info[2] = cattle.starLimit(star +1);
        }
        for(uint i = 0 ;i < targetId.length; i ++){
            info[3] += cattle.deadTime(targetId[i]) - block.timestamp;
        }
        uint life = cattle.getLife(tokenId);
        uint newDeadTime = block.timestamp + (35 days * life / 10000);
        if (newDeadTime > cattle.deadTime(tokenId)){
            info[4] = newDeadTime - cattle.deadTime(tokenId);
        }else{
            info[4] = 0;
        }
        
        
    }


    function checkCreation(uint[] memory list) public view returns(uint[] memory){
        uint amount;
        for(uint i = 0; i < list.length; i ++){
            if (cattle.isCreation(list[i])){
                amount++;
            }
        }
        uint[] memory list2 = new uint[](amount);
        amount = 0;
        for(uint i = 0; i < list.length; i ++){
            if (cattle.isCreation(list[i])){
                list2[amount] = list[i];
                amount++;
            }
        }
        return list2;
    }
    
    function compoundList(uint[] memory list1, uint[] memory list2) internal pure returns(uint[] memory){
        uint[] memory list = new uint[](list1.length + list2.length);
        for(uint i = 0; i < list1.length; i ++){
            list[i] = list1[i];
        }
        for(uint i = 0; i < list2.length; i ++){
            list[list1.length + i] = list2[i];
        }
        return list;
    }
    
    function battleInfo(uint tokenId)external view returns(uint[3] memory info,bool isDead, address owner_,bool isCreation,uint rewRates){
        owner_ = stable.CattleOwner(tokenId);
        uint level = stable.getStableLevel(owner_);
        uint8[6] memory rewRate = [100,110,115,120,125,140];
        info[0] = cattle.getAttack(tokenId) * tec.checkUserTecEffet(owner_,4002) / 1000;
        info[1] = cattle.getStamina(tokenId)* tec.checkUserTecEffet(owner_,4001) / 1000;
        info[2] = cattle.getDefense(tokenId)* tec.checkUserTecEffet(owner_,4003) / 1000;
        rewRates = rewRate[level];
        isDead = block.timestamp > cattle.deadTime(tokenId);
        isCreation = cattle.isCreation(tokenId);

    }

    function getMattingTimeBatch(uint[] memory tokenId) public view returns(uint[] memory){
        uint[] memory list = new uint[](tokenId.length);
        for(uint i =0;i<tokenId.length;i++){
            list[i] = 5 + mating.excessTimes(tokenId[i]) - mating.matingTime(tokenId[i]);
        }
        return list;
    }

    function checkBadgeInfoBatch(uint[] memory tokenIDs) public view returns(uint[] memory badgeID,uint[] memory effect){
        badgeID = new uint[](tokenIDs.length);
        effect = new uint[](tokenIDs.length);
        for(uint i = 0; i < tokenIDs.length; i ++){
            badgeID[i] = badge.badgeIdMap(tokenIDs[i]);
            effect[i] = badge.checkBadgeEffect(badgeID[i]);
        }
    }
    function checkUserBadgeInfo(address addr) public view returns(uint[] memory tokenID,uint[] memory badgeID,uint[] memory effect){
        tokenID = badge.checkUserBadgeList(addr);
        (badgeID,effect) = checkBadgeInfoBatch(tokenID);
    }

    function checkSkinInfoBatch(uint[] memory tokenIDs) public view returns(uint[] memory skinID,uint[][] memory effect){
        skinID = new uint[](tokenIDs.length);
        effect = new uint[][](tokenIDs.length);
        for(uint i = 0; i < tokenIDs.length; i ++){
            skinID[i] = skin.skinIdMap(tokenIDs[i]);
            effect[i] = skin.checkSkinEffect(skinID[i]);
        }
    }
    function checkUserSkinInfo(address addr) public view returns(uint[] memory tokenID,uint[] memory skinID,uint[][] memory effect){
        tokenID = skin.checkUserSkinList(addr);
        (skinID,effect) = checkSkinInfoBatch(tokenID);
    }

    function getUserProfilePhoto(address addr_) public view returns(string[] memory) {
        uint l;
        uint index;
        // 1.bovine hero
        uint[] memory list1 = checkCreation(stable.checkUserCows(addr_));
        uint[] memory list2 = cattle.checkUserCowListType(addr_, true);

        uint []memory bovineHeroPhoto = compoundList(list1,list2);
        l += bovineHeroPhoto.length;

        // 2.profile photo
        uint []memory profilePhoto = avatar.getUserPhotos(addr_);
        l += profilePhoto.length;

        string[] memory profileIcons = new string[](l);
        for (uint i = 0;i < bovineHeroPhoto.length; i++) {
            profileIcons[index] = (string(abi.encodePacked("Bovine Hero #",bovineHeroPhoto[i].toString())));
            index++;
        }
        for (uint i = 0;i < profilePhoto.length; i++) {
            profileIcons[index] = (string(abi.encodePacked(profilePhoto[i].toString())));
            index++;
        }


        return profileIcons;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMarket{
    function getSellingList(uint goodsType_, address addr_) external view returns (uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMail{
    function bvgClaimed(address addr)external view returns(uint);
    function bvtClaimed(address addr)external view returns(uint);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface ISkin{
    function mint(address player,uint skinId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function skinInfo(uint tokenID) external view returns(string memory,uint,uint,string memory);
    function burn(uint tokenId_) external returns (bool);
    function checkUserSkinIDList(address player) external view returns (uint[] memory);
    function checkUserSkinList(address player) external view returns (uint[] memory);
    function skinIdMap(uint tokenID) external view returns (uint);
    function checkSkinEffect(uint skinID) external view returns(uint[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ISkin.sol";
import "../interface/ICattle1155.sol";
contract SkinShop is OwnableUpgradeable {
    ISkin public skin;
    uint[] list;
    IERC20 public BVT;
    IERC20 public U;
    address public pair;

    struct SkinInfo {
        uint price;
        bool onSale;
        uint totalBuy;
        uint limit;
    }

    mapping(uint => uint) index;
    mapping(uint => SkinInfo)public skinInfo;
    ICattle1155 public item;
    uint randomSeed;
    event skinReward(address indexed sender, uint indexed reward);

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        newSkinInfo(10005, 625 ether, true, 1000);
        newSkinInfo(10006, 625 ether, true, 1000);
        newSkinInfo(10007, 935 ether, true, 1000);
        newSkinInfo(10008, 935 ether, true, 1000);
        newSkinInfo(10009, 1250 ether, true, 1000);
    }
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }
    function setSkin(address addr) external onlyOwner {
        skin = ISkin(addr);
    }

    function setToken(address BVT_, address U_) external onlyOwner {
        BVT = IERC20(BVT_);
        U = IERC20(U_);
    }

    function setPair(address addr) external onlyOwner {
        pair = addr;
    }

    function getBVTPrice() public view returns (uint){
        if (pair == address(0)) {
            return 1 ether;
        }
        uint balance1 = BVT.balanceOf(pair);
        uint balance2 = U.balanceOf(pair);
        return (balance2 * 1e18 / balance1);
    }

    function newSkinInfo(uint skinId, uint price, bool onSale, uint limit) public onlyOwner {
        require(skinInfo[skinId].price == 0, 'already on sale');
        skinInfo[skinId].price = price;
        skinInfo[skinId].onSale = onSale;
        skinInfo[skinId].limit = limit;
        index[skinId] = list.length;
        list.push(skinId);
    }

    function editSkinInfo(uint skinId, uint price, bool onSale, uint limit) external onlyOwner {
        require(skinInfo[skinId].price != 0, 'not on sale');
        skinInfo[skinId].price = price;
        skinInfo[skinId].onSale = onSale;
        skinInfo[skinId].limit = limit;
    }

    function setOnSale(uint skinId, bool onSale) external onlyOwner {
        require(skinInfo[skinId].price != 0, 'not on sale');
        skinInfo[skinId].onSale = onSale;
    }

    function setSkinPrice(uint[] memory skinID,uint[] memory prices) external onlyOwner{
        for (uint i = 0; i < skinID.length; i ++) {
            skinInfo[skinID[i]].price = prices[i];
        }
    }

    function changeLimit(uint skinId, uint limit) external onlyOwner {
        require(skinInfo[skinId].price != 0, 'not on sale');
        skinInfo[skinId].limit = limit;
    }

    function setItem(address addr) external onlyOwner {
        item = ICattle1155(addr);
    }

    function checkOnSaleList() public view returns (uint[] memory out){
        uint amount;
        for (uint i = 0; i < list.length; i ++) {
            if (skinInfo[list[i]].onSale) {
                amount++;
            }
        }
        out = new uint[](amount);
        for (uint i = 0; i < list.length; i ++) {
            if (skinInfo[list[i]].onSale) {
                amount--;
                out[amount] = list[i];
            }
        }
    }

    function checkSkinList() public view returns (uint[] memory, uint[] memory){
        return (checkOnSaleList(), checkOnSalePrice());
    }

    function checkOnSalePrice() public view returns (uint[] memory out){
        uint[] memory _list = checkOnSaleList();
        out = new uint[](_list.length);
        for (uint i = 0; i < _list.length; i ++) {
            out[i] = skinInfo[_list[i]].price;
        }
    }

    function coutingCost(uint skinId) public view returns (uint){
        uint price = skinInfo[skinId].price;
        return (price * 1e18 / getBVTPrice());
    }

    function buySkin(uint skinId, uint payWith) external {// 1 for usdt 2 for bvt
        require(skinInfo[skinId].price != 0, 'not on Sale');
        require(skinInfo[skinId].onSale, 'not on sale');
        require(skinInfo[skinId].limit > skinInfo[skinId].totalBuy, 'out of limit');
        require(payWith == 1 || payWith == 2, 'wrong pay');
        uint price = skinInfo[skinId].price;
        payWith = 0;
        if (payWith == 1) {
            U.transferFrom(msg.sender, address(this), price);
        } else {
            BVT.transferFrom(msg.sender, address(this), coutingCost(skinId));
        }
        skin.mint(msg.sender, skinId);
    }

    function checkSkinLevel(uint id) public view returns (uint) {
        (,,uint out,) = skin.skinInfo(skin.skinIdMap(id));
        return out;
    }

    function checkSkinLevelBatch(uint[] memory id) public view returns (uint[] memory) {
        uint[] memory lists = new uint[](id.length);
        for (uint i = 0; i < id.length; i++) {
            lists[i] = checkSkinLevel(id[i]);
        }
        return lists;

    }

    function checkRate(uint[] memory ids) public view returns (uint){
        uint[] memory out = checkSkinLevelBatch(ids);
        uint rates;
        for (uint i = 0; i < ids.length; i++) {
            if (out[i] == 1) {
                rates += 8;
            } else if (out[i] == 2) {
                rates += 14;
            } else {
                rates += 22;
            }
        }
        return rates;
    }

    function compoundSkin(uint[] memory skins) external {
        uint rates;
        for (uint i = 0; i < skins[i]; i++) {
            uint level = checkSkinLevel(skins[i]);
            skin.burn(skins[i]);
            if (level == 1) {
                rates += 8;
            } else if (level == 2) {
                rates += 14;
            } else {
                rates += 22;

            }
        }
        uint random = rand(rates);
        if (random > rates) {
            uint out = rand(100);
            if (out >= 90) {
                skin.mint(msg.sender, 10009);
                emit skinReward(msg.sender, 10009);
            } else if (out >= 60) {
                if (block.timestamp % 2 == 1) {
                    skin.mint(msg.sender, 10008);
                    emit skinReward(msg.sender, 10008);
                } else {
                    skin.mint(msg.sender, 10007);
                    emit skinReward(msg.sender, 10007);
                }

            } else {
                if (block.timestamp % 2 == 1) {
                    skin.mint(msg.sender, 10006);
                    emit skinReward(msg.sender, 10006);
                } else {
                    skin.mint(msg.sender, 10005);
                    emit skinReward(msg.sender, 10005);
                }
            }
        } else {
            skin.mint(msg.sender, 10010);
            emit skinReward(msg.sender, 10010);
        }
    }

    function compoundSuperSkin(uint[] memory skins) external {
        require(skins.length == 3, 'wrong skin amount');
        require(skin.skinIdMap(skins[0]) == skin.skinIdMap(skins[1]) && skin.skinIdMap(skins[1]) == skin.skinIdMap(skins[2]), 'wrong skin ID');
        require(skin.skinIdMap(skins[0]) >= 10010 && skin.skinIdMap(skins[0]) < 10013, 'wrong skin');
        for (uint i = 0; i < skins[i]; i++){
            skin.burn(skins[i]);
        }
        skin.mint(msg.sender,skin.skinIdMap(skins[0]) + 1);
    }

    function openSkinBox(uint amount) external {
        item.burn(msg.sender, 20003, amount);
        uint out = rand(100);
        for (uint i = 0; i < amount; i ++) {
            if (out >= 90) {
                emit skinReward(msg.sender, 10009);
            } else if (out >= 60) {
                if (block.timestamp % 2 == 1) {
                    skin.mint(msg.sender, 10008);
                    emit skinReward(msg.sender, 10008);
                } else {
                    skin.mint(msg.sender, 10007);
                    emit skinReward(msg.sender, 10007);
                }

            } else {
                if (block.timestamp % 2 == 1) {
                    skin.mint(msg.sender, 10006);
                    emit skinReward(msg.sender, 10006);
                } else {
                    skin.mint(msg.sender, 10005);
                    emit skinReward(msg.sender, 10005);
                }
            }
        }
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/ICOW721.sol";
import "../interface/Iprofile_photo.sol";
import "../interface/ICattle1155.sol";
import "../interface/ISkin.sol";

contract Compound is OwnableUpgradeable {
    ICOW public cattle;
    ICattle1155 public item;
    IProfilePhoto public photo;
    uint public shredId;
    IStable public stable;
    uint[] public upgradeLimit;
    mapping(uint => uint) public starExp;

    event CompoundCattle(address indexed player, uint indexed tokenId, uint indexed targetId);
    event UpGradeStar(address indexed player, uint indexed tokenId, uint indexed newStar);

    function setAddress(address cattle_, address item_, address photo_, address stable_) external onlyOwner {
        cattle = ICOW(cattle_);
        item = ICattle1155(item_);
        photo = IProfilePhoto(photo_);
        stable = IStable(stable_);
    }
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        upgradeLimit = [30 days, 45 days, 60 days];
    }

    function setShredId(uint ids) external onlyOwner {
        shredId = ids;
    }

    function compoundShred() external {
        require(item.balanceOf(msg.sender, shredId) >= 10, 'not enough shred');
        item.burn(msg.sender, shredId, 10);
        uint id = cattle.currentId();
        cattle.mintNormallWithParents(msg.sender);
        uint gender = cattle.getGender(id);
        if (gender == 1) {
            photo.mintBabyBull(msg.sender);
        } else {
            photo.mintBabyCow(msg.sender);
        }
    }

    function compoundCattle(uint tokenId, uint[] memory target) external {
        for (uint i = 0; i < target.length; i++) {
            _compoundCattle(tokenId, target[i]);
        }

    }

    function _compoundCattle(uint tokenId, uint target) public {
        require(stable.isStable(tokenId), 'not in stable');
        require(stable.CattleOwner(tokenId) == msg.sender, 'not owner');
        require(cattle.deadTime(target) > block.timestamp, 'dead target');
        require(!cattle.isCreation(target) && !cattle.isCreation(tokenId), 'not creation cattle');
        require(cattle.getAdult(tokenId) && cattle.getAdult(target), 'not adult');
        uint exp = cattle.deadTime(target) - block.timestamp;
        uint star = cattle.getStar(tokenId);
        require(star < 3, 'already full');
        if (stable.isStable(target)) {
            require(stable.CattleOwner(target) == msg.sender, 'not owner');
            stable.compoundCattle(target);
        } else {
            require(cattle.ownerOf(target) == msg.sender, 'not owner');
            cattle.burn(target);
        }
        if (starExp[tokenId] + exp >= upgradeLimit[star]) {
            uint left = starExp[tokenId] + exp - upgradeLimit[star];
            cattle.upGradeStar(tokenId);
            emit UpGradeStar(msg.sender, tokenId, cattle.getStar(tokenId));
            for (uint i = 0; i < 3; i++) {
                if (cattle.getStar(tokenId) < 3) {
                    if (left > upgradeLimit[cattle.getStar(tokenId)]) {
                        cattle.upGradeStar(tokenId);
                        emit UpGradeStar(msg.sender, tokenId, cattle.getStar(tokenId));
                        left -= upgradeLimit[cattle.getStar(tokenId)];
                    } else {
                        break;
                    }
                } else {
                    break;
                }
            }
            starExp[tokenId] = left;
        } else {
            starExp[tokenId] += exp;
        }

        emit CompoundCattle(msg.sender, tokenId, target);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interface/ICOW721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract Refer is Ownable{
    IStable public stable;
    struct UserInfo{
        address invitor;
        uint referDirect;
        address[] referList; 
    }
    event Bond(address indexed player, address indexed invitor);
    mapping(address => UserInfo) public userInfo;
    ICOW public cattle;
    
    function setStable(address addr) onlyOwner external{
        stable = IStable(addr);
    }

    function setCattle(address addr) external onlyOwner{
        cattle = ICOW(addr);
    }
    
    function bondInvitor(address addr) external{
        require(stable.checkUserCows(addr).length > 0 || cattle.balanceOf(addr) > 0,'wrong invitor');
        require(userInfo[msg.sender].invitor == address(0),'had invitor');
        userInfo[addr].referList.push(msg.sender);
        userInfo[addr].referDirect++;
        userInfo[msg.sender].invitor = addr;
        emit Bond(msg.sender,addr);
    }
    
    function checkUserInvitor(address addr) external view returns(address){
        return userInfo[addr].invitor;
    }
    
    function checkUserReferList(address addr) external view returns(address[] memory){
        return userInfo[addr].referList;
    }
    
    function checkUserReferDirect(address addr) external view returns(uint){
        return userInfo[addr].referDirect;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Halo1155 is Ownable, ERC1155Burnable {
    using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint))public userBurn;
    uint public burned;
    function setSuperMinter(address newSuperMinter_) public onlyOwner {
        superMinter = newSuperMinter_;
    }

    function setMinter(address newMinter_, uint itemId_, uint amount_) public onlyOwner {
        minters[newMinter_][itemId_] = amount_;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }

    string private _name;
    string private _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    struct ItemInfo{
        string name;
        uint itemId;
        uint burnedAmount;
        string tokenURI;
    }
    mapping(uint => ItemInfo) public itemInfoes;
    string public myBaseURI;
    
    mapping(uint => uint) public itemExp;
    
    constructor() ERC1155("123456") {
        _name = "halo ticket";
        _symbol = "ticket";
        myBaseURI = "123456";
        newItem(1,'shred','shred');
    }
    
    

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }



    function mint(address to_, uint itemId_, uint amount_) public returns (bool) {
        require(amount_ > 0, "K: missing amount");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][itemId_] >= amount_, "Cattle: not minter's calling");
            minters[_msgSender()][itemId_] -= amount_;
        }


        _mint(to_, itemId_, amount_, "");

        return true;
    }
    
    function newItem(uint id_, string memory name_, string memory tokenURI_) public onlyOwner{
        require(itemInfoes[id_].itemId == 0,'exit token');
        itemInfoes[id_].itemId = id_;
        itemInfoes[id_].name = name_;
        itemInfoes[id_].tokenURI = tokenURI_;
    }
    
    function editItem(uint id_, string memory name_, string memory tokenURI_)external onlyOwner{
        require(itemInfoes[id_].itemId != 0,'exit token');
        itemInfoes[id_].itemId = id_;
        itemInfoes[id_].name = name_;
        itemInfoes[id_].tokenURI = tokenURI_;
    }

    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) public returns (bool) {
        require(ids_.length == amounts_.length, "K: ids and amounts length mismatch");

        for (uint i = 0; i < ids_.length; i++) {

            if (superMinter != _msgSender()) {
                require(minters[_msgSender()][ids_[i]] >= amounts_[i], "Cattle: not minter's calling");
                minters[_msgSender()][ids_[i]] -= amounts_[i];
            }


        }

        _mintBatch(to_, ids_, amounts_, "");

        return true;
    }



    function burn(address account, uint256 id, uint256 value) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        burned += value;
        userBurn[account][id] += value;
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        for (uint i = 0; i < ids.length; i++) {
            itemInfoes[i].burnedAmount += values[i];
            userBurn[account][ids[i]] += values[i];
            burned += values[i];
        }
        _burnBatch(account, ids, values);
    }

    function tokenURI(uint256 itemId_) public view returns (string memory) {
        require(itemInfoes[itemId_].itemId != 0, "Cattle: URI query for nonexistent token");

        string memory URI = itemInfoes[itemId_].tokenURI;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, URI))
        : URI;
    }

    function _baseURI() internal view returns (string memory) {
        return myBaseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Burnable is ERC1155 {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


contract BVT_Token is ERC20, Ownable {
    using Address for address;
    mapping(address => bool) public whiteList;
    bool public whiteListStatus;

    constructor () ERC20("Test Bovine Verse Token", "TBVT") {
        _mint(_msgSender(), 1000000000 ether);
    }

    function setWhiteList(address permit, bool b) public onlyOwner returns (bool) {
        whiteList[permit] = b;
        return true;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function setWhiteListStatus(bool b) public onlyOwner returns (bool) {
        whiteListStatus = b;
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if (whiteListStatus) {
            require(!_msgSender().isContract() || whiteList[_msgSender()]);
            require(!recipient.isContract() || whiteList[recipient]);
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (whiteListStatus) {
            require(!_msgSender().isContract() || whiteList[_msgSender()]);
            require(!sender.isContract() || whiteList[sender]);
            require(!recipient.isContract() || whiteList[recipient]);
        }

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function burn(uint256 amount) public returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract Star_Cattle is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint public currentId;
    address public superMinter;
    uint male;
    uint female;
    uint limit;
    uint public maxLife;
    uint public burned;
    uint public maleCreation;
    uint public femaleCreation;
    uint[] public cowLimit;
    uint[] public starLimit;
    mapping(address => bool) public admin;
    mapping(address => uint) public mintersNormal;
    mapping(address => uint) public mintersCreation;
    mapping(address => mapping(address => mapping(uint => bool))) public isApprove;
    uint randomSeed;
    event BornNormalBull(address indexed sender_, uint indexed tokenId, uint life_, uint energy_, uint grow, uint star, uint[2] parents, uint deadTime, uint attack_, uint defense_, uint stamina_);

    event BornNormalCow(address indexed sender_, uint indexed tokenId, uint life_, uint energy_, uint grow, uint star, uint[2] parents, uint deadTime, uint milk_, uint milkRate_);

    event BornCreationBull(address indexed sender_, uint indexed tokenId, uint indexed creationId, uint life_, uint energy_, uint grow, uint deadTime, uint attack_, uint defense_, uint stamina_);

    event BornCreationCow(address indexed sender_, uint indexed tokenId, uint indexed creationId, uint life_, uint energy_, uint grow, uint deadTime, uint milk_, uint milkRate_);

    event AddDeadTime(uint indexed tokenId, uint indexed time);
    
    event GrowUp(uint indexed tokenId);

    event UpGradeStar(uint indexed tokenId,uint indexed stars);
    
     constructor() ERC721('Test Cattle', 'TCattle') {
         currentId = 1;
         superMinter = _msgSender();
         male = 10000;
         female = 10000;
         limit = 500;
         maxLife = 35 days;
         cowLimit = [5000,15000];
         starLimit = [25,40,60,80];
         randomSeed = 1;
     }
    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }
    

    struct CowInfo {
        uint gender; // 1 for male,2 for femal;
        uint bornTime;
        uint energy;
        uint life;
        uint growth;
        uint exp;
        bool isAdult;
        uint attack;
        uint stamina;
        uint defense;
        uint milk;
        uint milkRate;
        uint star;
        uint[2] parents;
        uint deadTime;
    }


    mapping(uint => CowInfo) public cowInfoes;
    mapping(uint => bool) public isCreation;
    
    uint public creationAmount;
    mapping(uint => uint) public creationIndex;
    modifier onlyAdmin(){
        require(admin[_msgSender()], 'not admin');
        _;
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (!isCreation[tokenId]) {
            require(admin[msg.sender], 'not admin');
        }
        _transfer(from, to, tokenId);

    }
    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        if (!isCreation[tokenId]) {
            require(admin[msg.sender], 'not admin');
        }
        safeTransferFrom(from, to, tokenId, "");
    }

    function setMintersNormal(address addr_, uint amount_) external onlyOwner {
        mintersNormal[addr_] = amount_;
    }
    
    function initCreation() external onlyOwner{
        uint bull;
        uint cow;
        for(uint i = 1; i < currentId; i ++){
            if(isCreation[i]){
                if(cowInfoes[i].gender == 1){
                    bull ++;
                    creationIndex[i] = bull;
                }else{
                    cow ++;
                    creationIndex[i] = cow;
                }
                
            }
        }
    }
    
    
    function setLimit(uint[] memory limit_) external onlyOwner{
        cowLimit = limit_;
    }

    function setMintersCreation(address addr_, uint amount_) external onlyOwner {
        mintersCreation[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function setAdmin(address addr_, bool com_) external onlyOwner {
        admin[addr_] = com_;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        isApprove[_msgSender()][to][tokenId] = true;
    }


    function addExp(uint tokenId_, uint amount_) external onlyAdmin {
        cowInfoes[tokenId_].exp += amount_;
    }

    function setGender(uint male_, uint female_) external onlyOwner {
        male = male_;
        female = female_;
    }

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        burned += 1;

        _burn(tokenId_);
        return true;
    }
    
    function mintNormallWithParents(address player) public {
        uint tokenId = currentId;
        uint[2] memory parents;
        if (_msgSender() != superMinter) {
            require(mintersNormal[_msgSender()] > 0, 'no mint amount');
            mintersNormal[_msgSender()] -= 1;
        }
        cowInfoes[currentId].gender = rand(2);
        cowInfoes[currentId].life = 7500 + rand(4000);
        cowInfoes[currentId].bornTime = block.timestamp;
        cowInfoes[currentId].energy = 7500 + rand(4000);
        cowInfoes[currentId].growth = 7500 + rand(4000);
        cowInfoes[currentId].isAdult = false;
        cowInfoes[currentId].deadTime = block.timestamp + (maxLife * cowInfoes[currentId].life / 10000);
        if (cowInfoes[currentId].gender == 1) {
            cowInfoes[currentId].attack = 7500 + rand(4000);
            cowInfoes[currentId].stamina = 7500 + rand(4000);
            cowInfoes[currentId].defense = 7500 + rand(4000);
            emit BornNormalBull(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, 0, parents, cowInfoes[currentId].deadTime, cowInfoes[currentId].attack, cowInfoes[currentId].defense, cowInfoes[currentId].stamina);


        } else {
            cowInfoes[currentId].milk = 7500 + rand(4000);
            cowInfoes[currentId].milkRate = 8000 + rand(4000);
            emit BornNormalCow(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, 0, parents, cowInfoes[currentId].deadTime, cowInfoes[currentId].milk, cowInfoes[currentId].milkRate);
        }
        currentId ++;
        _mint(player, tokenId);
    }

    function mintNormall(address player, uint[2] memory parents) public {
        uint tokenId = currentId;
        require(cowInfoes[parents[0]].gender == 1 && cowInfoes[parents[1]].gender == 2,'wrong parents');
        if (_msgSender() != superMinter) {
            require(mintersNormal[_msgSender()] > 0, 'no mint amount');
            mintersNormal[_msgSender()] -= 1;
        }
        CowInfo storage bull = cowInfoes[parents[0]];
        CowInfo storage cow = cowInfoes[parents[1]];
        cowInfoes[currentId].gender = rand(2);
        cowInfoes[currentId].life = coutintRand((bull.life + cow.life) / 2 );
        cowInfoes[currentId].bornTime = block.timestamp; 
        cowInfoes[currentId].energy = coutintRand((bull.energy + cow.energy) / 2 );
        cowInfoes[currentId].growth = coutintRand((bull.growth + cow.growth) / 2 );
        cowInfoes[currentId].parents = parents;
        cowInfoes[currentId].deadTime = block.timestamp + (maxLife * cowInfoes[currentId].life / 10000);
        if (cowInfoes[currentId].gender == 1) {
            cowInfoes[currentId].attack = coutintRand(bull.attack);
            cowInfoes[currentId].stamina = coutintRand(bull.stamina);
            cowInfoes[currentId].defense = coutintRand(bull.defense);
            emit BornNormalBull(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, 0, parents, cowInfoes[currentId].deadTime, cowInfoes[currentId].attack, cowInfoes[currentId].defense, cowInfoes[currentId].stamina);


        } else {
            cowInfoes[currentId].milk = coutintRand(cow.milk);
            cowInfoes[currentId].milkRate = coutintRand(cow.milk);
            emit BornNormalCow(player, currentId, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, 0, parents, cowInfoes[currentId].deadTime, cowInfoes[currentId].milk, cowInfoes[currentId].milkRate);
        }
        currentId ++;
        _mint(player, tokenId);

    }
    function growUp(uint tokenId) external{
        require(admin[msg.sender],'not admin');
        require(!isCreation[tokenId],'creation can not grow');
        require(!cowInfoes[tokenId].isAdult,'adult is true');
        cowInfoes[tokenId].isAdult = true;
        emit GrowUp(tokenId);
    }
    
    function upGradeStar(uint tokenId) external {
        require(admin[msg.sender], 'not admin');
        require(cowInfoes[tokenId].star < 3,"can't upgrade");
        cowInfoes[tokenId].star ++;
        uint deadTimes = block.timestamp + (maxLife * cowInfoes[tokenId].life / 10000);
        cowInfoes[tokenId].deadTime = deadTimes;
        emit AddDeadTime(tokenId,deadTimes);
        emit UpGradeStar(tokenId,cowInfoes[tokenId].star);

    }

    function mint(address player) public {
        _mint(player, currentId);
        if (_msgSender() != superMinter) {
            require(mintersCreation[_msgSender()] > 0, 'no mint amount');
            mintersCreation[_msgSender()] -= 1;
        }
        cowInfoes[currentId].gender = randGender();
        cowInfoes[currentId].life = 8000 + rand(4000);
        cowInfoes[currentId].bornTime = block.timestamp;
        cowInfoes[currentId].energy = 8000 + rand(4000);
        cowInfoes[currentId].growth = 8000 + rand(4000);
        cowInfoes[currentId].isAdult = true;
        cowInfoes[currentId].deadTime = block.timestamp + 360000 days;
        if (cowInfoes[currentId].gender == 1) {
            cowInfoes[currentId].attack = 8000 + rand(4000);
            cowInfoes[currentId].stamina = 8000 + rand(4000);
            cowInfoes[currentId].defense = 8000 + rand(4000);
            maleCreation++;
            creationIndex[currentId] = maleCreation;
            emit BornCreationBull(player, currentId, maleCreation, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, cowInfoes[currentId].deadTime, cowInfoes[currentId].attack, cowInfoes[currentId].defense, cowInfoes[currentId].stamina);

        } else {
            cowInfoes[currentId].milk = 8000 + rand(4000);
            cowInfoes[currentId].milkRate = 8000 + rand(4000);
            femaleCreation ++;
            creationIndex[currentId] = femaleCreation;
            emit BornCreationCow(player, currentId, femaleCreation, cowInfoes[currentId].life, cowInfoes[currentId].energy, cowInfoes[currentId].growth, cowInfoes[currentId].deadTime, cowInfoes[currentId].milk, cowInfoes[currentId].milkRate);
        }
        isCreation[currentId] = true;
        creationAmount ++;
        currentId ++;
        

    }
    
    function checkUserCowList(address player) public view returns(uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;

    }

    function checkUserCowListType(address player,bool creation_) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint token;
        uint count;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(creation_ && isCreation[token]){
                count++;
            }
            if(!creation_ && !isCreation[token]){
                count++;
            }
        }
        uint[] memory list = new uint[](count);
        uint index;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(creation_ && isCreation[token]){
                list[index] = token;
                index ++;
            }
            if(!creation_ && !isCreation[token]){
                list[index] = token;
                index ++;
            }
        }
        return list;

    }

    function randGender() internal returns (uint gen){
        uint out = rand(male + female);
        if (out > male) {
            female --;
            gen = 2;
        } else {
            male --;
            gen = 1;
        }
    }
    
    function setDeadTime(uint tokenId,uint time_) external onlyOwner{
        cowInfoes[tokenId].deadTime = time_;
    }

    function addDeadTime(uint tokenId, uint time_) external {
        require(admin[msg.sender], 'not admin');
        require(cowInfoes[tokenId].bornTime > 0, 'nonexistent token');
        require(!isCreation[tokenId], 'can not add creation Cattle');
        cowInfoes[tokenId].deadTime += time_;
        emit AddDeadTime(tokenId, cowInfoes[tokenId].deadTime);
    }
    
    function coutintRand(uint com_) internal returns(uint){
        uint out = com_ * (900 + rand(200)) / 1000;
        if(out < cowLimit[0]){
            return cowLimit[0];
        }
        if (out > cowLimit[1]){
            return cowLimit[1];
        }
        return out;
    }


    function tokenURI(uint256 tokenId_) override public view returns (string memory){
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,tokenId_.toString()));
    }

    function setBaseURI(string memory uri) external onlyOwner{
        myBaseURI = uri;
    }

    function getGender(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].gender;
    }

    function getEnergy(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].energy;
    }

    function getAdult(uint tokenId_) external view returns (bool){
        return cowInfoes[tokenId_].isAdult;
    }

    function getLife(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].life;
    }

    function getBronTime(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].bornTime;
    }

    function getGrowth(uint tokenId_) external view returns (uint){
        return cowInfoes[tokenId_].growth;
    }

    function getMilk(uint tokenId_) external view returns (uint){
        if(isCreation[tokenId_]){
            return cowInfoes[tokenId_].milk;
        }
        uint star = cowInfoes[tokenId_].star;
        return cowInfoes[tokenId_].milk * starLimit[star] / 100;
    }

    function getStar(uint tokenId_) external view returns(uint) {
        return cowInfoes[tokenId_].star;
    }

    function getMilkRate(uint tokenId_) external view returns (uint){
        if(isCreation[tokenId_]){
            return cowInfoes[tokenId_].milkRate;
        }
        uint star = cowInfoes[tokenId_].star;
        return cowInfoes[tokenId_].milkRate * starLimit[star] / 100;
    }
    function getAttack(uint tokenId_) external view returns (uint){
        if(isCreation[tokenId_]){
            return cowInfoes[tokenId_].attack;
        }
        uint star = cowInfoes[tokenId_].star;
        return cowInfoes[tokenId_].attack * starLimit[star] / 100;
    }
    function getStamina(uint tokenId_) external view returns (uint){
        if(isCreation[tokenId_]){
            return cowInfoes[tokenId_].stamina;
        }
        uint star = cowInfoes[tokenId_].star;
        return cowInfoes[tokenId_].stamina * starLimit[star] / 100;
    }
    function getDefense(uint tokenId_) external view returns (uint){
        if(isCreation[tokenId_]){
            return cowInfoes[tokenId_].defense;
        }
        uint star = cowInfoes[tokenId_].star;
        return cowInfoes[tokenId_].defense * starLimit[star] / 100;
    }
    function deadTime(uint tokenId_) external view returns(uint){
        return cowInfoes[tokenId_].deadTime;
    }
    function getCowParents(uint tokenId_) external view returns(uint[2] memory){
        return cowInfoes[tokenId_].parents;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract Cattle_Planet721 is Ownable, ERC721Enumerable {
    // for inherit
    
    // using Address for address;
    using Strings for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    uint public burned;
    uint currentID;
    function setSuperMinter(address newSuperMinter_) public onlyOwner returns (bool) {
        superMinter = newSuperMinter_;
        return true;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }


    struct PlanetInfo {
        uint planetType;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        bool tradable;
        string tokenURI;
    }

    mapping(uint => PlanetInfo) public planetInfo;
    mapping(uint => uint) public planetIdMap;
    string public myBaseURI;
    event Mint(address indexed addr,uint indexed types,uint indexed id);
    constructor() ERC721('Test Planet','TPlanet') {
        currentID = 1;
        superMinter = _msgSender();
    }

//    function initialize() public initializer{
//        __Context_init_unchained();
//        __Ownable_init_unchained();
//        __ERC721Enumerable_init();
//        __ERC721_init('plant','Plnat');
//        currentID = 1;
//        myBaseURI = '123456';
//        superMinter = _msgSender();
//
//    }
    
    function setAdmin(address addr_, bool com_) public onlyOwner{
        admin[addr_] = com_;
    }

    function setMyBaseURI(string calldata uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function newCard(string calldata name_, uint type_, uint maxAmount_, string calldata tokenURI_, bool tradable_) public onlyOwner {
        require(type_ != 0 && planetInfo[type_].planetType == 0, "wrong planetType");

        planetInfo[type_] = PlanetInfo({
        planetType : type_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        tradable : tradable_,
        tokenURI : tokenURI_
        });
    }

    function editCard(string calldata name_, uint type_, uint maxAmount_, string calldata tokenURI_, bool tradable_) public onlyOwner {
        require(type_ != 0 && planetInfo[type_].planetType == type_, "wrong planetType");

        planetInfo[type_] = PlanetInfo({
        planetType : type_,
        name : name_,
        currentAmount : planetInfo[type_].currentAmount,
        burnedAmount : planetInfo[type_].burnedAmount,
        maxAmount : maxAmount_,
        tradable : tradable_,
        tokenURI : tokenURI_
        });
    }

    

    

    function mint(address player_, uint type_) public returns (uint256) {
        require(type_ != 0 && planetInfo[type_].planetType != 0, " wrong planetType");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][type_] > 0, " not minter");
            minters[_msgSender()][type_] -= 1;
        }

        require(planetInfo[type_].currentAmount < planetInfo[type_].maxAmount, "cattle: amount out of limit");
        planetInfo[type_].currentAmount += 1;

        uint tokenId = currentID;
        currentID ++;
        planetIdMap[tokenId] = type_;
        _mint(player_, tokenId);
        emit Mint(player_,type_,tokenId);
        return tokenId;
    }

    function mintWithId(address player_, uint id_, uint tokenId_) public returns (bool) {
        require(id_ != 0 && planetInfo[id_].planetType != 0, "wrong planetType");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][id_] > 0, "not minter");
            minters[_msgSender()][id_] -= 1;
        }

        require(planetInfo[id_].currentAmount < planetInfo[id_].maxAmount, "cattle: amount out of limit");
        planetInfo[id_].currentAmount += 1;

        planetIdMap[tokenId_] = id_;
        _mint(player_, tokenId_);
        return true;
    }
    
    function changeType(uint tokenId, uint type_) external {
        require(admin[msg.sender],'not admin');
        planetIdMap[tokenId] = type_;
    }


    

    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");

        uint planetType = planetIdMap[tokenId_];
        planetInfo[planetType].burnedAmount += 1;
        burned += 1;

        _burn(tokenId_);
        return true;
    }
    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        require(planetInfo[planetIdMap[tokenId]].tradable, 'can not transfer This Planet');
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(planetInfo[planetIdMap[tokenId]].tradable, 'can not transfer This Planet');
        safeTransferFrom(from, to, tokenId, "");
    }


    function tokenURIType(uint256 tokenId_) public view returns (bool) {
        string memory tURI = super.tokenURI(tokenId_);
        return bytes(tURI).length > 0;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory){
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,planetInfo[tokenId_].planetType.toString()));
    }

    function _myBaseURI() internal view returns (string memory) {
        return myBaseURI;
    }

    function checkUserPlanet(address player,uint types_) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint token;
        uint count;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(planetIdMap[token] == types_){
                count++;
            }
            
        }
        uint[] memory list = new uint[](count);
        uint index = 0;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if(planetIdMap[token] == types_){
                list[index] = token;
                index ++;
            }
        
        }
        return list;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TESTU is ERC20 {
    uint public time;
    constructor () ERC20('TUSDT', 'TUSDT'){
        _mint(msg.sender, 6000000000 ether);
    }
    function setTime(uint time_) external{
        time = time_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract SERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;


    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;

    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }



    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        // require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}




contract BVG_Token is SERC20,Ownable{
    using Address for address;
    mapping(address => uint) public minter;
    mapping(address => bool) public whiteList;
    bool public whiteListStatus;
    event Mint(address indexed addr, uint indexed amount);
    event SetMinter(address indexed addr, uint indexed amount);

    constructor () SERC20('Bovine Verse Game','BVG'){
        whiteList[0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff] = true;
        whiteList[address(this)] = true;
        whiteListStatus = true;
    }

    function decimals() public view virtual override returns (uint8){
        return 18;
    }
    
    function mint(address addr_, uint amount_) public {
        require(minter[msg.sender] >= amount_,'no mint allowance');
        _mint(addr_, amount_);
        minter[msg.sender] -= amount_;
        emit Mint(addr_,amount_);
    }
    function setWhiteList(address permit, bool b) public onlyOwner returns (bool) {
        whiteList[permit] = b;
        return true;
    }
    function setWhiteListStatus(bool b) public onlyOwner returns (bool) {
        whiteListStatus = b;
        return true;
    }

    function setMinter(address addr, uint allowance_) public onlyOwner{
        require(addr!=address(0),"wrong address");
        minter[addr] = allowance_;
        emit SetMinter(addr,allowance_);
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        if (whiteListStatus) {
            require(!_msgSender().isContract() || whiteList[_msgSender()]);
            require(!recipient.isContract() || whiteList[recipient]);
        }

        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        if (whiteListStatus) {
            require(!_msgSender().isContract() || whiteList[_msgSender()]);
            require(!sender.isContract() || whiteList[sender]);
            require(!recipient.isContract() || whiteList[recipient]);
        }

        _transfer(sender, recipient, amount);

        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interface/IBVG.sol";

contract BVGMining is ReentrancyGuard {
    IBEP20 public BVG = IBEP20(0x96cB0Ade2e254c598b12179503C00b007EeB7861);
    using SafeERC20 for IERC20;
    uint public startTime;
    uint constant miningTime = 30 days;
    uint public totalClaimed;
    uint constant dayliyOut = 5000000 ether;
    uint public rate;
    uint constant acc = 1e10;
    address public owner;
    constructor (){
        rate = dayliyOut / 86400;
        poolInfo[1].rate = 50;
        poolInfo[2].rate = 30;
        poolInfo[3].rate = 20;
        poolInfo[1].limit = 10 ether;
        poolInfo[2].limit = 5000 ether;
        poolInfo[3].limit = 100 ether;
        poolInfo[2].token = 0x55d398326f99059fF775485246999027B3197955;
        //USDT
        poolInfo[3].token = 0x0D8Ce2A99Bb6e3B7Db580eD848240e4a0F9aE153;
        //FIL
        owner = msg.sender;
    }
    struct PoolInfo {
        address token;
        uint TVL;
        uint lastTime;
        uint debt;
        uint claimed;
        uint rate;
        uint limit;
        uint lastDebt;
    }

    struct UserInfo {
        uint stakeAmount;
        uint debt;
        uint toClaim;
    }

    mapping(uint => PoolInfo) public poolInfo;
    mapping(address => mapping(uint => UserInfo)) public userInfo;
    mapping(address => uint) public userClaimed;

    event Claim(address indexed player, uint indexed amount);
    event Stake(address indexed player, uint indexed amount, uint indexed poolId);
    event UnStake(address indexed player, uint poolID);
    
    modifier checkEnd(){
        if(block.timestamp >= startTime + miningTime && poolInfo[1].lastDebt ==0){
            poolInfo[1].lastDebt = coutingDebt(1);
            poolInfo[2].lastDebt = coutingDebt(2);
            poolInfo[3].lastDebt = coutingDebt(3);
        }
        _;
    }

    function coutingDebt(uint poolId) public view returns (uint _debt){
        PoolInfo storage info = poolInfo[poolId];
        if (info.lastDebt != 0){
            return info.lastDebt;
        }
        _debt = info.TVL > 0 ? (rate * info.rate / 100) * (block.timestamp - info.lastTime) * acc / info.TVL + info.debt : 0 + info.debt;
    }

    function calculateReward(address player, uint poolId) public view returns (uint){
        UserInfo storage user = userInfo[player][poolId];
        if (user.stakeAmount == 0) {
            return 0;
        }
        uint rew = user.stakeAmount * (coutingDebt(poolId) - user.debt) / acc;
        return (rew + user.toClaim);
    }

    function calculateAllReward(address player) public view returns (uint){
        uint rew;
        for (uint i = 1; i <= 3; i ++) {
            UserInfo storage user = userInfo[player][i];
            if (user.stakeAmount == 0) {
                continue;
            }
            rew += calculateReward(player, i);
        }
        return rew;
    }
    
    function setStartTime(uint time_) external{
        require(msg.sender == owner,'not owner');
        require(startTime == 0,'starting');
        require(block.timestamp < time_ + miningTime ,'out of time');
        require(time_ != 0 ,'startTime can not be zero');
        startTime = time_;
        owner = address(0);
    }

    function claimReward(uint poolId) internal checkEnd {
        uint rew = calculateReward(msg.sender, poolId);
        if (rew == 0) {
            return;
        }
        UserInfo storage user = userInfo[msg.sender][poolId];
        BVG.mint(msg.sender, rew);
        uint tempDebt = coutingDebt(poolId);
        user.debt = tempDebt;
        user.toClaim = 0;
        userClaimed[msg.sender] += rew;
        totalClaimed += rew;
        emit Claim(msg.sender, rew);

    }

    function claimAllReward() external checkEnd{
        // require(block.timestamp < startTime + miningTime, 'mining over');
        uint rew;
        uint tempDebt;
        for (uint i = 1; i <= 3; i ++) {
            UserInfo storage user = userInfo[msg.sender][i];
            if (user.stakeAmount == 0) {
                continue;
            }
            rew += calculateReward(msg.sender, i);
            tempDebt = coutingDebt(i);
            user.debt = tempDebt;
            user.toClaim = 0;
        }
        require(rew > 0, 'no reward');
        userClaimed[msg.sender] += rew;
        totalClaimed += rew;
        BVG.mint(msg.sender, rew);
        emit Claim(msg.sender, rew);
    }

    function stakeBnb() payable external {
        require(block.timestamp >= startTime && startTime != 0,'not start');
        require(block.timestamp < startTime + miningTime, 'mining over');
        require(msg.value > 0, 'amount can not be zero');
        UserInfo storage user = userInfo[msg.sender][1];
        PoolInfo storage pool = poolInfo[1]; 
        require(user.stakeAmount + msg.value <= pool.limit, 'out of limit');
        if (user.stakeAmount > 0) {
            user.toClaim = calculateReward(msg.sender, 1);
        }
        uint tempDebt = coutingDebt(1);
        pool.TVL += msg.value;
        pool.lastTime = block.timestamp;
        pool.debt = tempDebt;
        user.stakeAmount += msg.value;
        user.debt = tempDebt;
        emit Stake(msg.sender,msg.value,1);
    }

    function unStakeBnb() external nonReentrant checkEnd{
        UserInfo storage user = userInfo[msg.sender][1];
        PoolInfo storage pool = poolInfo[1];
        require(user.stakeAmount > 0, 'no stakeAmount');
        claimReward(1);
        uint tempDebt = coutingDebt(1);
        uint amount = user.stakeAmount;
        pool.TVL -= amount;
        pool.lastTime = block.timestamp;
        pool.debt = tempDebt;
        user.stakeAmount = 0;
        user.debt = tempDebt;
        payable(msg.sender).transfer(amount);
        emit UnStake(msg.sender,amount);
    }

    function stakeToken(uint poolId, uint amount) external  {
        require(block.timestamp >= startTime && startTime != 0,'not start');
        require(poolId == 2 || poolId == 3, 'wrong pool ID');
        require(block.timestamp < startTime + miningTime, 'mining over');
        require(amount > 0, 'amount can not be zero');
        UserInfo storage user = userInfo[msg.sender][poolId];
        PoolInfo storage pool = poolInfo[poolId];
        require(user.stakeAmount + amount <= pool.limit, 'out of limit');
        if (user.stakeAmount > 0) {
            user.toClaim = calculateReward(msg.sender, poolId);
        }
        uint tempDebt = coutingDebt(poolId);
        pool.TVL += amount;
        pool.lastTime = block.timestamp;
        pool.debt = tempDebt;
        user.stakeAmount += amount;
        user.debt = tempDebt;
        IERC20(pool.token).safeTransferFrom(msg.sender, address(this), amount);
        emit Stake(msg.sender,amount,poolId);
    }

    function unStakeToken(uint poolId) external nonReentrant checkEnd{
        require(poolId == 2 || poolId == 3, 'wrong pool ID');
        UserInfo storage user = userInfo[msg.sender][poolId];
        PoolInfo storage pool = poolInfo[poolId];
        require(user.stakeAmount > 0, 'no stakeAmount');
        claimReward(poolId);
        uint tempDebt = coutingDebt(poolId);
        uint amount = user.stakeAmount;
        pool.TVL -= amount;
        pool.lastTime = block.timestamp;
        pool.debt = tempDebt;
        user.stakeAmount = 0;
        user.debt = tempDebt;
        IERC20(pool.token).safeTransfer(msg.sender, amount);
        emit UnStake(msg.sender,amount);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleSkin is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public skinIdMap;
    uint[] eff;
    constructor() ERC721('Cattle Skin', 'Cattle Skin') {
        myBaseURI = "https://bv-test.blockpulse.net/api/nft/skin";
        superMinter = _msgSender();
        eff = [500, 0, 0, 0];
        skinInfo[10005] = SkinInfo({
        name : 'Baby Bomber',
        ID : 10005,
        level : 1,
        effect : eff,
        URI : '10005'
        });
        skinInfo[10006] = SkinInfo({
        name : 'Evil Blaze Dryad',
        ID : 10006,
        level : 1,
        effect : eff,
        URI : '10006'
        });
        skinInfo[10007] = SkinInfo({
        name : 'Space Explorer',
        ID : 10007,
        level : 2,
        effect : eff,
        URI : '10007'
        });
        skinInfo[10008] = SkinInfo({
        name : 'Electric-Arc Spirit',
        ID : 10008,
        level : 2,
        effect : eff,
        URI : '10008'
        });
        skinInfo[10009] = SkinInfo({
        name : 'tHolo Electro-Magnetizer',
        ID : 10009,
        level : 3,
        effect : eff,
        URI : '10009'
        });
    }
    struct SkinInfo{
        string name;
        uint ID;
        uint level; //f 1 for epic 2 for lengend 3 for limit
        uint[] effect;//1 for attack 2 for defense 3 for stamia 4 for life
        string URI;
        
    }
    mapping(uint => SkinInfo) public skinInfo;
    function newSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID == 0,'exist ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_
        });
    }
    
    function editSkin(string memory name, uint ID, uint level, uint[] memory effect,string memory URI_) external onlyOwner{
        require(skinInfo[ID].ID != 0,'nonexistent ID');
        skinInfo[ID] = SkinInfo({
            name : name,
            ID : ID,
            level : level,
            effect : effect,
            URI : URI_
        });
    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }
    
    function checkSkinEffect(uint skinID) public view returns(uint[] memory){
        require(skinInfo[skinID].ID != 0,'wrong skin ID');
        return skinInfo[skinID].effect;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint skinId) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(skinInfo[skinId].ID != 0,'nonexistent ID');
        skinIdMap[currentId] = skinId;
        _mint(player, currentId);
        currentId ++;
    }
    
    function mintBatch(address player, uint[] memory ids) public{
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] >= ids.length, 'no mint amount');
            minters[_msgSender()] -= ids.length;
        }
        for(uint i = 0; i < ids.length; i ++){
            require(skinInfo[ids[i]].ID != 0,'nonexistent ID');
            skinIdMap[currentId] = ids[i];
            _mint(player, currentId);
            currentId ++;
        }
    }

    function checkUserSkinList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;
    }
    
    function checkUserSkinIDList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = skinIdMap[token];
        }
        return list;
    }
    
    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,"/",skinIdMap[tokenId_].toString()));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleBox is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 200;
    address public superMinter;
    mapping(address => uint) public minters;
    constructor() ERC721('Test Cattle Box', 'Tbox') {
        myBaseURI = "123456";
        superMinter = _msgSender();
    }

    struct BoxInfo { 
        uint[2] parents;
    }

    mapping(uint => BoxInfo)  boxInfo;
    mapping(address => bool) public admin;
    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function setBaseUri(string memory uri_) external onlyOwner{
        myBaseURI = uri_;
    }

    function mint(address player, uint[2] memory parents_) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        _mint(player, currentId);
        boxInfo[currentId] = BoxInfo({
        parents : parents_
        });
        currentId ++;

    }
    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }

    function checUserBoxList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;

    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI, "/",'1'));
    }

    function checkParents(uint tokenId_) external view returns (uint[2] memory){
        return boxInfo[tokenId_].parents;
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BvInfo is Ownable {
    uint public price;
    address public pair;
    address public bvt;
    address public usdt;
    uint[] public priceList;
    mapping(address => bool) public admin;

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function setPrice(uint price_) external onlyOwner {
        price = price_;
    }

    function setPair(address pair_) external onlyOwner {
        pair = pair_;
    }

    function setToken(address u_, address bvt_) external onlyOwner {
        usdt = u_;
        bvt = bvt_;
    }

    function rand(uint256 _length, uint seed) internal view returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        return random % _length + 1;
    }

    function addPrice() external {
        require(admin[msg.sender], 'not admin');
        uint seed = gasleft();
        if (rand(3, seed) != 3) {
            return;
        }
        if (priceList.length <= 10) {
            priceList.push(getPairPrice());
            return;
        }
        uint index = rand(10, seed * 2) - 1;
        priceList[index] = priceList[9];
        priceList.pop();
    }

    function getPairPrice() internal view returns (uint){
        uint u = IERC20(usdt).balanceOf(pair);
        uint token = IERC20(bvt).balanceOf(pair);
        return (u * 1e18 / token);
    }

    function getBVTPrice() external view returns (uint){
        if (price != 0) {
            return price;
        }
        uint temp;
        for (uint i = 0; i < priceList.length; i++) {
            temp += priceList[i];
        }
        uint out = temp / priceList.length;
        return out;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CattleBadge is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string public myBaseURI;
    uint currentId = 1;
    address public superMinter;
    mapping(address => uint) public minters;
    mapping(uint => uint) public badgeIdMap;
    constructor() ERC721('Cattle Badge', 'Cattle Badge') {
        myBaseURI = "https://bv-test.blockpulse.net/api/nft/badge";
        superMinter = _msgSender();
        badgeInfo[40001] = BadgeInfo({
        name : 'Bronze',
        ID : 40001,
        power : 1000,
        URI : '40001'
        });
        badgeInfo[40002] = BadgeInfo({
        name : 'Silver',
        ID : 40002,
        power : 2000,
        URI : '40002'
        });
        badgeInfo[40003] = BadgeInfo({
        name : 'Gold',
        ID : 40003,
        power : 6000,
        URI : '40003'
        });
        badgeInfo[40004] = BadgeInfo({
        name : 'Platinum',
        ID : 40004,
        power : 30000,
        URI : '40004'
        });
        badgeInfo[40005] = BadgeInfo({
        name : 'Diamond',
        ID : 40005,
        power : 40000,
        URI : '10009'
        });
        badgeInfo[40006] = BadgeInfo({
        name : 'Master',
        ID : 40006,
        power : 60000,
        URI : '40006'
        });
    }
    struct BadgeInfo{
        string name;
        uint ID;
        uint power;//1 for attack 2 for defense 3 for stamia 4 for life
        string URI;

    }
    mapping(uint => BadgeInfo) public badgeInfo;
    function newBadge(string memory name, uint ID, uint power_,string memory URI_) external onlyOwner{
        require(badgeInfo[ID].ID == 0,'exist ID');
        badgeInfo[ID] = BadgeInfo({
        name : name,
        ID : ID,
        power : power_,
        URI : URI_
        });
    }

    function editBadge(string memory name, uint ID, uint power_,string memory URI_) external onlyOwner{
        require(badgeInfo[ID].ID != 0,'nonexistent ID');
        badgeInfo[ID] = BadgeInfo({
        name : name,
        ID : ID,
        power : power_,
        URI : URI_
        });
    }

    function setMinters(address addr_, uint amount_) external onlyOwner {
        minters[addr_] = amount_;
    }

    function checkBadgeEffect(uint badgeID) public view returns(uint){
        require(badgeInfo[badgeID].ID != 0,'wrong badge ID');
        return badgeInfo[badgeID].power;
    }

    function setSuperMinter(address addr) external onlyOwner {
        superMinter = addr;
    }

    function mint(address player,uint badgeId) public {
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] > 0, 'no mint amount');
            minters[_msgSender()] -= 1;
        }
        require(badgeInfo[badgeId].ID != 0,'nonexistent ID');
        badgeIdMap[currentId] = badgeId;
        _mint(player, currentId);
        currentId ++;
    }

    function mintBatch(address player, uint[] memory ids) public{
        if (_msgSender() != superMinter) {
            require(minters[_msgSender()] >= ids.length, 'no mint amount');
            minters[_msgSender()] -= ids.length;
        }
        for(uint i = 0; i < ids.length; i ++){
            require(badgeInfo[ids[i]].ID != 0,'nonexistent ID');
            badgeIdMap[currentId] = ids[i];
            _mint(player, currentId);
            currentId ++;
        }
    }

    function checkUserBadgeList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = token;
        }
        return list;
    }

    function checkUserBadge(address player,uint ID) public view returns(uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list;
        uint token;
        uint amount;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if( badgeIdMap[token] == ID){
                amount ++;
            }
        }
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            if( badgeIdMap[token] == ID){
                list[amount -1] = token;
                amount--;
            }
        }
        return list;
    }

    function checkUserBadgeIDList(address player) public view returns (uint[] memory){
        uint tempBalance = balanceOf(player);
        uint[] memory list = new uint[](tempBalance);
        uint token;
        for (uint i = 0; i < tempBalance; i++) {
            token = tokenOfOwnerByIndex(player, i);
            list[i] = badgeIdMap[token];
        }
        return list;
    }

    function setBaseUri(string memory uri) public onlyOwner{
        myBaseURI = uri;
    }

    function tokenURI(uint256 tokenId_) override public view returns (string memory) {
        require(_exists(tokenId_), "nonexistent token");
        return string(abi.encodePacked(myBaseURI,"/",badgeIdMap[tokenId_].toString()));
    }


    function burn(uint tokenId_) public returns (bool){
        require(_isApprovedOrOwner(_msgSender(), tokenId_), "burner isn't owner");
        _burn(tokenId_);
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICOW721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/ICattle1155.sol";
import "../interface/Iprofile_photo.sol";
import "../interface/ISkin.sol";

contract Cow_Born is OwnableUpgradeable {
    IBOX public box;
    ICattle1155 public item;
    ICOW public cattle;
    IProfilePhoto public photo;
    uint randomSeed;
    uint creation;
    uint normal;
    uint shred;
    uint shredId;
    ISkin public skin;
    //    event Reward()
    event Born(address indexed sender, uint indexed reward, uint indexed cattleId, uint amount);//1 for creation cattle, 2 for normal ,3 for shred


    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        creation = 1;
        normal = 9000;
        shred = 999;
        shredId = 13;
    }

    function rand(uint256 _length) internal returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, randomSeed)));
        randomSeed ++;
        return random % _length + 1;
    }

    function setCattle(address cattle_) public onlyOwner {
        cattle = ICOW(cattle_);
    }

    function setCattle1155(address item_) external onlyOwner {
        item = ICattle1155(item_);
    }

    function setBox(address box_) external onlyOwner {
        box = IBOX(box_);
    }

    function setProfile(address addr_) external onlyOwner {
        photo = IProfilePhoto(addr_);
    }

    function setShredId(uint id) external onlyOwner {
        shredId = id;
    }

    function getParents(uint id) internal view returns (uint[2] memory){
        uint[2] memory par = box.checkParents(id);
        uint[2] memory out;
        if (par[0] == 0) {
            return par;
        }
        uint gender = cattle.getGender(par[0]);
        if (gender == 1) {
            return par;
        } else {
            out[0] = par[1];
            out[1] = par[0];
            return out;
        }
    }

    function born(uint boxId) external returns (uint, uint, uint){
        uint[2] memory par = getParents(boxId);
        box.burn(boxId);
        uint rew = rand(creation + normal + shred);
        if (rew <= normal) {
            uint id = cattle.currentId();
            if (par[0] != 0) {
                cattle.mintNormall(msg.sender, par);
            } else {
                cattle.mintNormallWithParents(msg.sender);
            }
            uint gender = cattle.getGender(id);
            if (gender == 1) {
                photo.mintBabyBull(msg.sender);
            } else {
                photo.mintBabyCow(msg.sender);
            }
            emit Born(msg.sender, 2, id, 1);
            return (2, 1, id);
        } else if (rew <= normal + shred) {
            uint amount = rand(5);

            item.mint(msg.sender, shredId, amount);
            emit Born(msg.sender, 3, 0, amount);
            return (3, amount, 0);
        } else {
            uint id = cattle.currentId();
            cattle.mint(msg.sender);
            uint gender = cattle.getGender(id);
            if (gender == 1) {
                photo.mintAdultBull(msg.sender);
            } else {
                photo.mintAdultCow(msg.sender);
            }
            emit Born(msg.sender, 1, id, 1);
            return (1, 1, id);
        }

    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/ICattle1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract ItemShop is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    ICattle1155 public item;
    uint[] onSaleList;

    struct ShopInfo {
        bool onSale;
        uint left;
        uint pay;//1 for bvt , 2 for bvg;
        uint price;

    }

    mapping(uint => ShopInfo) public shopInfo;
    mapping(uint => uint) index;
    mapping(address => mapping(uint => uint)) public userBuyed;

    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        setShopInfo(1, true, 1000000, 2, 10 ether);
        setShopInfo(2, true, 1000000, 2, 20 ether);
        setShopInfo(3, true, 1000000, 2, 30 ether);
        setShopInfo(4, true, 1000000, 1, 10 ether);
        setShopInfo(5, true, 1000000, 1, 20 ether);
        setShopInfo(6, true, 1000000, 1, 30 ether);
        setShopInfo(7, true, 1000000, 1, 10 ether);
        setShopInfo(8, true, 1000000, 1, 20 ether);
        setShopInfo(9, true, 1000000, 1, 30 ether);
        setShopInfo(10, true, 1000000, 1, 400 ether);
        setShopInfo(11, true, 1000000, 1, 800 ether);
        setShopInfo(12, true, 1000000, 1, 1200 ether);
        setShopInfo(14, true, 1000000, 1, 30 ether);
    }

    function setItem(address addr_) external onlyOwner {
        item = ICattle1155(addr_);
    }

    function setToken(address BVT_, address BVG_) external onlyOwner {
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }

    function setShopInfo(uint itemId, bool isOnsale, uint sellLimit, uint payWith, uint price_) public onlyOwner {
        uint length = onSaleList.length;
        if (!isOnsale) {
            require(shopInfo[itemId].onSale, 'not onSale');
            onSaleList[index[itemId]] = onSaleList[length - 1];
            onSaleList.pop();

        }
        if (isOnsale) {
            require(!shopInfo[itemId].onSale, 'already onSale');
            index[itemId] = length;
            onSaleList.push(itemId);
        }
        shopInfo[itemId] = ShopInfo({
        onSale : isOnsale,
        left : sellLimit,
        pay : payWith,
        price : price_
        });

    }



    function getOnSaleList() external view returns (uint[] memory){
        return onSaleList;
    }
    function setOnSaleList(uint[] memory lists_) external onlyOwner{
        onSaleList = lists_;
    }
    function buyItem(uint itemId, uint amount) external {
        ShopInfo storage info = shopInfo[itemId];
        require(amount <= info.left, 'out of limit');
        require(info.onSale, 'not onSale');
        uint payAmount = amount * info.price;
        if (info.pay == 1) {
            BVT.safeTransferFrom(msg.sender, address(this), payAmount);
        } else {
            BVG.safeTransferFrom(msg.sender, address(this), payAmount);
        }
        item.mint(msg.sender, itemId, amount);
        info.left -= amount;
    }

    function setItemAmount(uint itemId, uint amount) external onlyOwner {
        shopInfo[itemId].left = amount;
    }

    function setPrice(uint[] memory ids, uint[] memory prices) external onlyOwner {
        for (uint i = 0; i < ids.length; i ++) {
            shopInfo[ids[i]].price = prices[i];
        }
    }

    function setPay(uint[] memory ids,uint[] memory pay) external onlyOwner{
        for (uint i = 0; i < ids.length; i ++) {
            shopInfo[ids[i]].pay = pay[i];
        }
    }

    function getList() external view returns (uint[] memory lists, uint[] memory lefts, uint[] memory pays, uint[] memory prices){
        lists = onSaleList;
        lefts = new uint[](onSaleList.length);
        pays = new uint[](onSaleList.length);
        prices = new uint[](onSaleList.length);
        for (uint i = 0; i < onSaleList.length; i++) {
            uint id = onSaleList[i];
            lefts[i] = shopInfo[id].left;
            pays[i] = shopInfo[id].pay;
            prices[i] = shopInfo[id].price;
        }
        return (lists, lefts, pays, prices);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interface/IPlanet.sol";

contract CheckIn is OwnableUpgradeable{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public BVT;
    IERC20Upgradeable public BVG;
    IPlanet public planet;
    uint public walletLimit;
    uint[7] public BVTreward;
    uint[7] public BVGreward;
    struct UserInfo{
        bool[7] claimTimes;
        uint claimEndTime;
        uint claimStartTime;
        uint lastClaimTime;
        uint nextCheckTime;
    }
    mapping(address => UserInfo) public userInfo;
    event Check(address indexed player, uint indexed index);
    
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
    }
    
    function setToken(address BVT_,address BVG_) external onlyOwner{
        BVT = IERC20Upgradeable(BVT_);
        BVG = IERC20Upgradeable(BVG_);
    }
    
    function setPlanet(address planet_) external onlyOwner{
        planet = IPlanet(planet_);
    }
    
    function setWalletLimit(uint limit) external onlyOwner{
        walletLimit = limit;
    }
    
    function setReward(uint[7] memory BVTrew, uint[7] memory BVGrew) external onlyOwner{
        BVTreward = BVTrew;
        BVGreward = BVGrew;
    }
    
    function check() external {
        require(planet.isBonding(msg.sender),'not bonding planet yet');
        require(msg.sender.balance >= walletLimit,'bnb value not enough');
        UserInfo storage info = userInfo[msg.sender];
        require(info.claimStartTime == 0 || info.claimEndTime > block.timestamp,'claim over');
        if (info.claimStartTime == 0){
            info.claimStartTime = block.timestamp - (block.timestamp % 86400);
            info.claimEndTime = info.claimStartTime + 7 days;
        }
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        require(!info.claimTimes[index],'claimed');
        info.claimTimes[index] = true;
        BVT.safeTransfer(msg.sender,BVTreward[index]);
        BVG.safeTransfer(msg.sender,BVGreward[index]);
        info.lastClaimTime = block.timestamp; 
        info.nextCheckTime = block.timestamp - (block.timestamp % 86400) + 86400;
        emit Check(msg.sender,index);
    }
    
    function checkUserClaimTimes(address addr) public view returns(bool[7] memory){
        return userInfo[addr].claimTimes;
    }
    
    function checkAble(address addr) public view returns(bool){
        UserInfo storage info = userInfo[addr];
        if(!planet.isBonding(addr) || addr.balance < walletLimit){
            return false;
        }
        
        if (info.claimStartTime == 0){
            return true;
        }
        if (block.timestamp > info.claimEndTime){
            return false;
        }
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        return !info.claimTimes[index];
    }
    
    function findIndex(address addr) internal view returns(uint){
        UserInfo storage info = userInfo[addr];
        if (!checkAble(addr)){
            return 0;
        }
        if (info.claimStartTime == 0){
            return 0;
        }
        
        uint index = (block.timestamp - info.claimStartTime) / 86400;
        return index;
    }
    
    function getCheckInfo(address addr) public view returns(uint,bool,uint[2] memory){
         UserInfo storage info = userInfo[addr];
         uint index = findIndex(addr);
         uint[2] memory list = [BVTreward[index],BVGreward[index]];
         return (info.nextCheckTime,checkAble(addr),list);
    }
    
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Cattle1155 is OwnableUpgradeable, ERC1155BurnableUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    mapping(address => mapping(uint => uint)) public minters;
    address public superMinter;
    mapping(address => bool) public admin;
    mapping(address => mapping(uint => uint))public userBurn;
    mapping(uint => uint) public itemType;
    uint public itemAmount;
    uint public burned;
    function setSuperMinter(address newSuperMinter_) public onlyOwner {
        superMinter = newSuperMinter_;
    }

    function setMinter(address newMinter_, uint itemId_, uint amount_) public onlyOwner {
        minters[newMinter_][itemId_] = amount_;
    }

    function setMinterBatch(address newMinter_, uint[] calldata ids_, uint[] calldata amounts_) public onlyOwner returns (bool) {
        require(ids_.length > 0 && ids_.length == amounts_.length, "ids and amounts length mismatch");
        for (uint i = 0; i < ids_.length; ++i) {
            minters[newMinter_][ids_[i]] = amounts_[i];
        }
        return true;
    }

    string private _name;
    string private _symbol;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    struct ItemInfo {
        uint itemId;
        string name;
        uint currentAmount;
        uint burnedAmount;
        uint maxAmount;
        uint[3] effect;
        bool tradeable;
        string tokenURI;
    }

    mapping(uint => ItemInfo) public itemInfoes;
    mapping(uint => uint) public itemLevel;
    string public myBaseURI;
    
    mapping(uint => uint) public itemExp;
    function initialize() public initializer{
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ERC1155_init('123456');
        _name = "Item";
        _symbol = "Item";
        myBaseURI = "123456";
    }
    // constructor() ERC1155("123456") {
    //     _name = "Item";
    //     _symbol = "Item";
    //     myBaseURI = "123456";
    // }
    
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        if (!admin[msg.sender]){
            require(itemInfoes[id].tradeable,'not tradeable');
        }
        
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        if(!admin[msg.sender]){
            for(uint i = 0; i < ids.length; i++){
                require(itemInfoes[ids[i]].tradeable,'not tradeable');
            }
        }
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setMyBaseURI(string memory uri_) public onlyOwner {
        myBaseURI = uri_;
    }

    function checkItemEffect(uint id_) external view returns (uint[3] memory){
        return itemInfoes[id_].effect;
    }

    function newItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_, uint types,bool tradeable_,uint level_,uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == 0, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : 0,
        burnedAmount : 0,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemAmount ++;
        itemExp[itemId_] = itemExp_;
    }
    
    function setAdmin(address addr,bool b) external onlyOwner {
        admin[addr] = b;
    }

    function editItem(string memory name_, uint itemId_, uint maxAmount_, uint[3] memory effect_,uint types, bool tradeable_,uint level_, uint itemExp_, string memory tokenURI_) public onlyOwner {
        require(itemId_ != 0 && itemInfoes[itemId_].itemId == itemId_, "Cattle: wrong itemId");

        itemInfoes[itemId_] = ItemInfo({
        itemId : itemId_,
        name : name_,
        currentAmount : itemInfoes[itemId_].currentAmount,
        burnedAmount : itemInfoes[itemId_].burnedAmount,
        maxAmount : maxAmount_,
        effect : effect_,
        tradeable : tradeable_,
        tokenURI : tokenURI_
        });
        itemType[itemId_] = types;
        itemLevel[itemId_] = level_;
        itemExp[itemId_] = itemExp_;
    }
    
    function checkTypeBatch(uint[] memory ids)external view returns(uint[] memory){
        uint[] memory out = new uint[](ids.length);
        for(uint i = 0; i < ids.length; i++){
            out[i] = itemType[ids[i]];
        }
        return out;
    }

    function mint(address to_, uint itemId_, uint amount_) public returns (bool) {
        require(amount_ > 0, "K: missing amount");
        require(itemId_ != 0 && itemInfoes[itemId_].itemId != 0, "K: wrong itemId");

        if (superMinter != _msgSender()) {
            require(minters[_msgSender()][itemId_] >= amount_, "Cattle: not minter's calling");
            minters[_msgSender()][itemId_] -= amount_;
        }

        require(itemInfoes[itemId_].maxAmount - itemInfoes[itemId_].currentAmount >= amount_, "Cattle: Token amount is out of limit");
        itemInfoes[itemId_].currentAmount += amount_;

        _mint(to_, itemId_, amount_, "");

        return true;
    }


    function mintBatch(address to_, uint256[] memory ids_, uint256[] memory amounts_) public returns (bool) {
        require(ids_.length == amounts_.length, "K: ids and amounts length mismatch");

        for (uint i = 0; i < ids_.length; i++) {
            require(ids_[i] != 0 && itemInfoes[ids_[i]].itemId != 0, "Cattle: wrong itemId");

            if (superMinter != _msgSender()) {
                require(minters[_msgSender()][ids_[i]] >= amounts_[i], "Cattle: not minter's calling");
                minters[_msgSender()][ids_[i]] -= amounts_[i];
            }

            require(itemInfoes[ids_[i]].maxAmount - itemInfoes[ids_[i]].currentAmount >= amounts_[i], "Cattle: Token amount is out of limit");
            itemInfoes[ids_[i]].currentAmount += amounts_[i];
        }

        _mintBatch(to_, ids_, amounts_, "");

        return true;
    }



    function burn(address account, uint256 id, uint256 value) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        itemInfoes[id].burnedAmount += value;
        burned += value;
        userBurn[account][id] += value;
        _burn(account, id, value);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public override {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "Cattle: caller is not owner nor approved"
        );

        for (uint i = 0; i < ids.length; i++) {
            itemInfoes[i].burnedAmount += values[i];
            userBurn[account][ids[i]] += values[i];
            burned += values[i];
        }
        _burnBatch(account, ids, values);
    }

    function tokenURI(uint256 itemId_) public view returns (string memory) {
        require(itemInfoes[itemId_].itemId != 0, "K: URI query for nonexistent token");

        string memory URI = itemInfoes[itemId_].tokenURI;
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, URI))
        : URI;
    }

    function _baseURI() internal view returns (string memory) {
        return myBaseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Burnable_init() internal onlyInitializing {
    }

    function __ERC1155Burnable_init_unchained() internal onlyInitializing {
    }
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}