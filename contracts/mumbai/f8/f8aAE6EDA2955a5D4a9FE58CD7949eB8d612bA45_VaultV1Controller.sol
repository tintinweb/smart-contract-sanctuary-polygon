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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFacetCatalog {
  function hasPurchased(
    address user,
    address facetAddress
  ) external returns (bool);

  function purchaseFacet(address facetAddress) external;

  function purchaseFacetFrom(address payer, address facetAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDiamondFacet {
  function getSelectors() external pure returns (bytes4[] memory);

  function getSupportedInterfaceIds()
    external
    pure
    returns (bytes4[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION =
    keccak256('diamond.standard.diamond.storage');

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  function diamondStorage()
    internal
    pure
    returns (DiamondStorage storage ds)
  {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INexusGateway {
  function isReady() external view returns (bool isReady);

  function sendPacketTo(
    uint16 chainId,
    bytes memory payload
  ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';

error MustBeIOUTokenFactory(address factory, address sender);

contract IOUToken is ERC20 {
  address public immutable factory;

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    factory = msg.sender;
  }

  modifier onlyFactory() {
    if (msg.sender != factory) {
      revert MustBeIOUTokenFactory(factory, msg.sender);
    }
    _;
  }

  function mint(address target, uint256 amount) external onlyFactory {
    _mint(target, amount);
  }

  function burn(address target, uint256 amount) external onlyFactory {
    _burn(target, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INexus {
  function nexusName() external returns (string memory);

  function installFacet(address facetAddress) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

abstract contract ERC165Consumer {
  function _supportsERC165Interface(
    address account,
    bytes4 interfaceId
  ) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(
      IERC165.supportsInterface.selector,
      interfaceId
    );
    (bool success, bytes memory result) = account.staticcall{gas: 30000}(
      encodedParams
    );
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library StringToAddress {
  function toAddress(string memory _a) internal pure returns (address) {
    bytes memory tmp = bytes(_a);
    if (tmp.length != 42) return address(0);
    uint160 iaddr = 0;
    uint8 b;
    for (uint256 i = 2; i < 42; i++) {
      b = uint8(tmp[i]);
      if ((b >= 97) && (b <= 102)) b -= 87;
      else if ((b >= 65) && (b <= 70)) b -= 55;
      else if ((b >= 48) && (b <= 57)) b -= 48;
      else return address(0);
      iaddr |= uint160(uint256(b) << ((41 - i) << 2));
    }
    return address(iaddr);
  }
}

library AddressToString {
  function toString(address a) internal pure returns (string memory) {
    bytes memory data = abi.encodePacked(a);
    bytes memory characters = '0123456789abcdef';
    bytes memory byteString = new bytes(2 + data.length * 2);

    byteString[0] = '0';
    byteString[1] = 'x';

    for (uint256 i; i < data.length; ++i) {
      byteString[2 + i * 2] = characters[uint256(uint8(data[i] >> 4))];
      byteString[3 + i * 2] = characters[uint256(uint8(data[i] & 0x0f))];
    }
    return string(byteString);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultController {}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultGatewayAdapater {
  function handlePacket(
    uint16 senderChainId,
    bytes calldata payload
  ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {VaultV1} from '../VaultV1.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {ERC165Consumer} from '../../../utils/ERC165Consumer.sol';

import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotInstalled();

error GatewayNotAccepted(bytes32 nexusId, uint32 gatewayId);
error GatewayBalanceTooLow(
  bytes32 nexusId,
  uint32 vaultId,
  uint32 gatewayId
);
error AvailableBalanceTooLow(bytes32 nexusId, uint32 vaultId);

abstract contract BaseVaultV1Controller is ERC165Consumer, Ownable {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    mapping(uint32 => bool) acceptedGateways;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    bool isDefined;
    VaultV1 vault;
    mapping(V1TokenTypes => mapping(string => TokenRecord)) tokens;
  }
  struct TokenRecord {
    uint256 bridgedBalance;
    mapping(uint32 => uint256) gatewayBalances;
  }

  event NexusAddAcceptedGateway(
    bytes32 indexed nexusId,
    uint32 indexed gatewayId
  );

  mapping(bytes32 => NexusRecord) internal nexusVaults;

  uint16 public immutable currentChainId;

  address public immutable facetAddress;
  IFacetCatalog public immutable facetCatalog;

  mapping(INexusGateway => uint32) public gateways; //Valid if Id != 0
  uint32 internal gatewayCount;
  mapping(uint32 => INexusGateway) public gatewayVersions;

  constructor(
    uint16 _currentChainId,
    IFacetCatalog _facetCatalog,
    address _facetAddress
  ) {
    currentChainId = _currentChainId;
    facetCatalog = _facetCatalog;
    facetAddress = _facetAddress;
  }

  modifier onlyFacetOwners() {
    if (facetCatalog.hasPurchased(msg.sender, facetAddress)) {
      revert FacetNotInstalled();
    }
    _;
  }

  function _enforceAcceptedGateway(
    bytes32 nexusId,
    uint32 gatewayId
  ) internal view {
    if (!nexusVaults[nexusId].acceptedGateways[gatewayId]) {
      revert GatewayNotAccepted(nexusId, gatewayId);
    }
  }

  function _enforceMinimumGatewayBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 minimumBalance,
    uint32 gatewayId
  ) internal view {
    if (
      nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier].gatewayBalances[gatewayId] <
      minimumBalance
    ) {
      revert GatewayBalanceTooLow(nexusId, vaultId, gatewayId);
    }
  }

  function _enforceMinimumAvailableBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 minimumBalance
  ) internal view {
    VaultRecord storage vaultRecord = nexusVaults[nexusId].vaults[vaultId];
    TokenRecord storage tokenRecord = vaultRecord.tokens[tokenType][
      tokenIdentifier
    ];

    uint256 totalBalance = vaultRecord.vault.getBalance(
      tokenType,
      tokenIdentifier
    );

    if (totalBalance - tokenRecord.bridgedBalance < minimumBalance) {
      revert AvailableBalanceTooLow(nexusId, vaultId);
    }
  }

  function _addAcceptedGatewayToNexus(
    bytes32 nexusId,
    uint32 gatewayId
  ) internal {
    emit NexusAddAcceptedGateway(nexusId, gatewayId);

    nexusVaults[nexusId].acceptedGateways[gatewayId] = true;
  }

  function _incrementBridgedBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 amount,
    uint32 gatewayId
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance += amount;
    tokenRecord.gatewayBalances[gatewayId] += amount;
  }

  function _decrementBridgedBalance(
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint256 amount,
    uint32 gatewayId
  ) internal {
    TokenRecord storage tokenRecord = nexusVaults[nexusId]
      .vaults[vaultId]
      .tokens[tokenType][tokenIdentifier];

    tokenRecord.bridgedBalance -= amount;
    tokenRecord.gatewayBalances[gatewayId] -= amount;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';

interface IVaultV1Controller is IVaultController {
  function deployVault(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable;

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable;

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable;

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {INexusGateway} from '../../../../gateway/INexusGateway.sol';
import {V1PacketTypes} from '../../V1PacketTypes.sol';
import {IVaultGatewayAdapater} from '../../../IVaultGatewayAdapater.sol';

error IncompatibleGateway();
error GatewayAlreadyApproved();
error SenderNotApprovedGateway();
error TargetNotApprovedGateway();

abstract contract GatewayAdapterModule is
  BaseVaultV1Controller,
  IVaultGatewayAdapater
{
  event GatewayApproved(uint32 gatewayId, address gatewayAddress);

  function addApprovedGateway(address gatewayAddress) external onlyOwner {
    if (
      !_supportsERC165Interface(
        gatewayAddress,
        type(INexusGateway).interfaceId
      )
    ) {
      revert IncompatibleGateway();
    }
    if (gateways[INexusGateway(gatewayAddress)] != 0) {
      revert GatewayAlreadyApproved();
    }

    gatewayCount++;

    gateways[INexusGateway(gatewayAddress)] = gatewayCount;
    gatewayVersions[gatewayCount] = INexusGateway(gatewayAddress);

    emit GatewayApproved(gatewayCount, gatewayAddress);
  }

  function handlePacket(
    uint16 senderChainId,
    bytes memory payload
  ) external payable {
    uint32 gatewayId = gateways[INexusGateway(msg.sender)];

    if (gatewayId == 0) {
      revert SenderNotApprovedGateway();
    }

    (
      V1PacketTypes packetType,
      bytes32 nexusId,
      bytes memory innerPayload
    ) = abi.decode(payload, (V1PacketTypes, bytes32, bytes));

    assert(packetType != V1PacketTypes.Never);

    _handlePacket(
      senderChainId,
      packetType,
      nexusId,
      innerPayload,
      gatewayId
    );
  }

  function _sendPacket(
    uint16 destinationChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory innerPayload,
    uint32 transmitUsingGatewayId
  ) internal {
    INexusGateway gateway = gatewayVersions[transmitUsingGatewayId];

    _enforceAcceptedGateway(nexusId, transmitUsingGatewayId);

    gateway.sendPacketTo{value: msg.value}(
      destinationChainId,
      abi.encode(packetType, nexusId, innerPayload)
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory payload,
    uint32 gatewayId
  ) internal virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {VaultV1} from '../../VaultV1.sol';

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);

struct VaultInfo {
  uint32 vaultId;
  VaultV1 vault;
}

abstract contract InspectorModule is BaseVaultV1Controller {
  function listVaults(
    bytes32 nexusId
  ) external view returns (VaultInfo[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    VaultInfo[] memory vaults = new VaultInfo[](nexus.vaultIds.length);

    for (uint256 i = 0; i < nexus.vaultIds.length; i++) {
      vaults[i] = VaultInfo({
        vaultId: nexus.vaultIds[i],
        vault: nexus.vaults[nexus.vaultIds[i]].vault
      });
    }

    return vaults;
  }

  function listAcceptedGateways(
    bytes32 nexusId
  ) external view returns (uint32[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    uint256 acceptedGatewayCount = 0;

    for (uint32 i = 1; i <= gatewayCount; i++) {
      if (!nexus.acceptedGateways[i]) {
        continue;
      }

      acceptedGatewayCount++;
    }

    uint32[] memory gatewayIds = new uint32[](acceptedGatewayCount);
    acceptedGatewayCount = 0;

    for (uint32 i = 1; i <= gatewayCount; i++) {
      if (!nexus.acceptedGateways[i]) {
        continue;
      }

      gatewayIds[acceptedGatewayCount] = i;
      acceptedGatewayCount++;
    }

    return gatewayIds;
  }

  function getVault(
    bytes32 nexusId,
    uint32 vaultId
  ) external view returns (VaultV1 vault) {
    VaultRecord storage vaultRecord = nexusVaults[nexusId].vaults[vaultId];

    if (!vaultRecord.isDefined) {
      revert VaultDoesNotExist(nexusId, vaultId);
    }

    return vaultRecord.vault;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from '../../V1TokenTypes.sol';

import {IOUToken} from '../../../../iou/IOUToken.sol';

struct IOUTokenRecord {
  bool isDefined;
  uint16 vaultChainId;
  uint32 gatewayId;
  bytes32 nexusId;
  uint32 vaultId;
  V1TokenTypes tokenType;
  string tokenIdentifier;
}

abstract contract IOUTokenModule {
  mapping(address => IOUTokenRecord) public tokenToRecord;
  mapping(bytes32 => IOUToken) public recordToToken;

  function _makeTokenId(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private pure returns (bytes32 tokenId) {
    return
      keccak256(
        abi.encodePacked(
          vaultChainId,
          gatewayId,
          nexusId,
          vaultId,
          tokenType,
          tokenIdentifier
        )
      );
  }

  function _deployIOU(
    string memory name,
    string memory symbol,
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier
  ) private returns (IOUToken) {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = new IOUToken{salt: tokenId}(name, symbol);

    recordToToken[tokenId] = token;
    tokenToRecord[address(token)] = IOUTokenRecord({
      isDefined: true,
      vaultChainId: vaultChainId,
      gatewayId: gatewayId,
      nexusId: nexusId,
      vaultId: vaultId,
      tokenType: tokenType,
      tokenIdentifier: tokenIdentifier
    });

    return token;
  }

  function _isIOUToken(address tokenAddress) internal view returns (bool) {
    return tokenToRecord[tokenAddress].isDefined;
  }

  function _mintIOU(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address receiver,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        gatewayId,
        nexusId,
        vaultId,
        tokenType,
        tokenIdentifier
      );
    }

    token.mint(receiver, amount);
  }

  function _burnIOU(
    uint16 vaultChainId,
    uint32 gatewayId,
    bytes32 nexusId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    address from,
    uint256 amount
  ) internal {
    bytes32 tokenId = _makeTokenId(
      vaultChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier
    );

    IOUToken token = recordToToken[tokenId];

    if (address(token) == address(0)) {
      token = _deployIOU(
        tokenIdentifier,
        tokenIdentifier,
        vaultChainId,
        gatewayId,
        nexusId,
        vaultId,
        tokenType,
        tokenIdentifier
      );
    }

    token.burn(from, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';

import {VaultV1} from '../../VaultV1.sol';

error VaultAtIdAlreadyExists(bytes32 nexusId, uint256 vaultId);

abstract contract VaultFactoryModule is BaseVaultV1Controller {
  event VaultDeployed(
    bytes32 indexed nexusId,
    uint32 indexed vaultId,
    address indexed vaultAddress
  );

  bytes32 constant FACTORY_SALT = keccak256('VAULT_V1_FACTORY_SALT');

  function _makeContractSalt(
    bytes32 nexusId,
    uint32 vaultId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(FACTORY_SALT, nexusId, vaultId));
  }

  function _deployVault(bytes32 nexusId, uint32 vaultId) internal {
    if (nexusVaults[nexusId].vaults[vaultId].isDefined) {
      revert VaultAtIdAlreadyExists(nexusId, vaultId);
    }

    VaultV1 vault = new VaultV1{
      salt: _makeContractSalt(nexusId, vaultId)
    }();

    VaultRecord storage vaultRecord = nexusVaults[nexusId].vaults[vaultId];

    vaultRecord.isDefined = true;
    vaultRecord.vault = vault;

    nexusVaults[nexusId].vaultIds.push(vaultId);

    emit VaultDeployed(nexusId, vaultId, address(vault));
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';
import {VaultV1Facet} from '../facet/VaultV1Facet.sol';
import {IOUTokenRecord} from './modules/IOUTokenModule.sol';

import {VaultFactoryModule} from './modules/VaultFactoryModule.sol';
import {GatewayAdapterModule} from './modules/GatewayAdapterModule.sol';
import {IOUTokenModule} from './modules/IOUTokenModule.sol';
import {InspectorModule} from './modules/InspectorModule.sol';

import {StringToAddress, AddressToString} from '../../../utils/StringAddressUtils.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error UnsupportedPacket(V1PacketTypes packetType);

contract VaultV1Controller is
  IVaultV1Controller,
  Ownable,
  BaseVaultV1Controller,
  GatewayAdapterModule,
  VaultFactoryModule,
  IOUTokenModule,
  InspectorModule
{
  using StringToAddress for string;
  using AddressToString for address;

  constructor(
    uint16 _currentChainId,
    IFacetCatalog _facetCatalog
  )
    BaseVaultV1Controller(
      _currentChainId,
      _facetCatalog,
      address(new VaultV1Facet(address(this)))
    )
  {}

  function deployVault(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(vaultId);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.CreateVault,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(gatewayIdToAdd);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.AddAcceptedGateway,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      destinationChainId,
      V1PacketTypes.SendPayment,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function redeemPayment(
    address iouTokenAddress,
    string calldata target,
    uint256 amount
  ) external payable {
    IOUTokenRecord storage tokenRecord = tokenToRecord[iouTokenAddress];

    _burnIOU(
      tokenRecord.vaultChainId,
      tokenRecord.gatewayId,
      tokenRecord.nexusId,
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      msg.sender,
      amount
    );

    bytes memory innerPayload = abi.encode(
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      tokenRecord.vaultChainId,
      V1PacketTypes.RedeemPayment,
      tokenRecord.nexusId,
      innerPayload,
      tokenRecord.gatewayId
    );
  }

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationGatewayAddress,
      destinationChainId,
      target,
      amount
    );

    _sendPacket(
      targetChainId,
      V1PacketTypes.BridgeOut,
      nexusId,
      innerPayload,
      transmitUsingGatewayId
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory payload,
    uint32 gatewayId
  ) internal override {
    _enforceAcceptedGateway(nexusId, gatewayId);

    if (packetType == V1PacketTypes.CreateVault) {
      _handleDeployVault(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.AddAcceptedGateway) {
      _handleAddAcceptedGateway(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.SendPayment) {
      _handleSendPayment(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.RedeemPayment) {
      _handleRedeemPayment(nexusId, gatewayId, payload);
      return;
    }
    if (packetType == V1PacketTypes.BridgeOut) {
      _handleBridgeOut(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.MintIOUTokens) {
      _handleMintIOUTokens(senderChainId, nexusId, gatewayId, payload);
      return;
    }

    revert UnsupportedPacket(packetType);
  }

  function _handleDeployVault(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 vaultId = abi.decode(payload, (uint32));

    _deployVault(nexusId, vaultId);
  }

  function _handleAddAcceptedGateway(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 gatewayIdToAdd = abi.decode(payload, (uint32));
    _addAcceptedGatewayToNexus(nexusId, gatewayIdToAdd);
  }

  function _handleSendPayment(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleRedeemPayment(
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumGatewayBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    _decrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleBridgeOut(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      uint32 targetGatewayId,
      uint16 targetChainId,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, uint32, uint16, string, uint256)
      );

    _enforceAcceptedGateway(nexusId, targetGatewayId);
    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _incrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      targetGatewayId
    );
    _sendPacket(
      targetChainId,
      V1PacketTypes.MintIOUTokens,
      nexusId,
      abi.encode(vaultId, tokenType, tokenIdentifier, target, amount),
      targetGatewayId
    );
  }

  function _handleMintIOUTokens(
    uint16 senderChainId,
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _mintIOU(
      senderChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      target.toAddress(),
      amount
    );
  }

  function _makeNexusId(
    address nexusAddress
  ) internal view returns (bytes32) {
    return keccak256(abi.encode(currentChainId, nexusAddress));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from '../V1TokenTypes.sol';

interface IVaultV1Facet {
  function createVaultV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable;

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable;

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable;

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '../../../diamond/IDiamondFacet.sol';
import '../controller/IVaultV1Controller.sol';
import '../../../diamond/LibDiamond.sol';
import './IVaultV1Facet.sol';

error MustBeDelegateCall();
error MustBeContractOwner();

contract VaultV1Facet is IDiamondFacet, IVaultV1Facet {
  bytes32 constant VAULTV1_STORAGE_POSITION =
    keccak256('diamond.standard.vaultv1.storage');

  struct VaultV1Storage {
    mapping(address => mapping(bytes32 => bool)) permissions;
  }

  IVaultV1Controller private immutable vaultController;
  address private immutable self;

  constructor(address _vaultController) {
    vaultController = IVaultV1Controller(_vaultController);
    self = address(this);
  }

  function getSelectors() external pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](4);

    selectors[0] = this.createVaultV1.selector;
    selectors[1] = this.addAcceptedGateway.selector;
    selectors[2] = this.sendPayment.selector;
    selectors[3] = this.bridgeOut.selector;

    return selectors;
  }

  function getSupportedInterfaceIds()
    external
    pure
    returns (bytes4[] memory)
  {
    bytes4[] memory interfaceIds = new bytes4[](5);

    interfaceIds[0] = type(IVaultV1Facet).interfaceId;

    return interfaceIds;
  }

  modifier onlyDelegateCall() {
    if (address(this) == self) {
      revert MustBeDelegateCall();
    }
    _;
  }

  modifier onlyDiamondOwner() {
    if (msg.sender != LibDiamond.diamondStorage().contractOwner) {
      revert MustBeContractOwner();
    }
    _;
  }

  function vaultV1Storage()
    internal
    pure
    returns (VaultV1Storage storage ds)
  {
    bytes32 position = VAULTV1_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function createVaultV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.deployVault{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      vaultId
    );
  }

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.addAcceptedGateway{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      gatewayIdToAdd
    );
  }

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.sendPayment{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      vaultId,
      tokenType,
      tokenIdentifier,
      target,
      amount
    );
  }

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.bridgeOut{value: msg.value}(
      targetChainId,
      transmitUsingGatewayId,
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationChainId,
      destinationGatewayAddress,
      target,
      amount
    );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum V1PacketTypes {
  Never,
  CreateVault,
  AddAcceptedGateway,
  SendPayment,
  RedeemPayment,
  BridgeOut,
  MintIOUTokens
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum V1TokenTypes {
  Never, //This is an error
  Native,
  ERC20
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from './V1TokenTypes.sol';
import {StringToAddress} from '../../utils/StringAddressUtils.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error CallerMustBeVaultFactory(
  address factoryAddress,
  address callerAddress
);

error UnsupportedTokenType(V1TokenTypes tokenType);

contract VaultV1 {
  using StringToAddress for string;

  address public immutable VaultFactoryAddress;

  constructor() {
    VaultFactoryAddress = msg.sender;
  }

  modifier onlyFactory() {
    if (msg.sender != VaultFactoryAddress) {
      revert CallerMustBeVaultFactory(VaultFactoryAddress, msg.sender);
    }
    _;
  }

  function sendTokens(
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    address payable target,
    uint256 amount
  ) external onlyFactory {
    if (
      tokenType == V1TokenTypes.Native &&
      tokenIdentifier.toAddress() == address(0)
    ) {
      target.transfer(amount);
      return;
    }
    if (tokenType == V1TokenTypes.ERC20) {
      address tokenAddress = tokenIdentifier.toAddress();
      IERC20 token = IERC20(tokenAddress);

      token.transfer(target, amount);
      return;
    }

    revert UnsupportedTokenType(tokenType);
  }

  function getBalance(
    V1TokenTypes tokenType,
    string calldata tokenIdentifier
  ) external view returns (uint256) {
    if (tokenType == V1TokenTypes.Native) {
      return address(this).balance;
    }
    if (tokenType == V1TokenTypes.ERC20) {
      address tokenAddress = tokenIdentifier.toAddress();
      IERC20 token = IERC20(tokenAddress);

      return token.balanceOf(address(this));
    }

    revert UnsupportedTokenType(tokenType);
  }
}