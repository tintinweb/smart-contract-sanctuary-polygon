/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File contracts/dependencies/openzeppelin/contracts/IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


// File contracts/dependencies/openzeppelin/upgradeability/Clones.sol


// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), 'ERC1167: create failed');
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), 'ERC1167: create2 failed');
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}


// File contracts/dependencies/upgradeability/VersionedInitializable.sol


pragma solidity ^0.8.17;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(
            initializing || isConstructor() || revision > lastInitializedRevision,
            'Contract instance has already been initialized'
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     */
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     */
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}


// File contracts/lib/Errors.sol


pragma solidity ^0.8.17;

/**
 * @title Errors library
 * @author FlashFlow
 * @notice Defines the error messages emitted by the different contracts of the FlashFlow protocol
 */
library Errors {
    // The caller of the function is not a account owner
    string public constant CALLER_NOT_ACCOUNT_OWNER = '1';
    // The caller of the function is not a account contract
    string public constant CALLER_NOT_RECEIVER = '2';
    // The caller of the function is not a flash aggregatoor contract
    string public constant CALLER_NOT_FLASH_AGGREGATOR = '3';
    // The caller of the function is not a position owner
    string public constant CALLER_NOT_POSITION_OWNER = '4';
    // The address of the pool addresses provider is invalid
    string public constant INVALID_ADDRESSES_PROVIDER = '5';
    // The initiator of the flashloan is not a account contract
    string public constant INITIATOR_NOT_ACCOUNT = '6';
    // Failed to charge the protocol fee
    string public constant CHARGE_FEE_NOT_COMPLETED = '7';
    // The sender does not have an account
    string public constant ACCOUNT_DOES_NOT_EXIST = '9';
    // Invalid amount to charge fee
    string public constant INVALID_CHARGE_AMOUNT = '10';
    // There is no connector with this name
    string public constant NOT_CONNECTOR = '11';
    // The address of the connector is invalid
    string public constant INVALID_CONNECTOR_ADDRESS = '12';
    // The length of the connector array and their names are different
    string public constant INVALID_CONNECTORS_LENGTH = '13';
    // A connector with this name already exists
    string public constant CONNECTOR_ALREADY_EXIST = '14';
    // A connector with this name does not exist
    string public constant CONNECTOR_DOES_NOT_EXIST = '15';
    // The caller of the function is not a configurator
    string public constant CALLER_NOT_CONFIGURATOR = '16';
    // The fee amount is invalid
    string public constant INVALID_FEE_AMOUNT = '17';
    // The address of the implementation is invalid
    string public constant INVALID_IMPLEMENTATION_ADDRESS = '18';
    // 'ACL admin cannot be set to the zero address'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = '19';
    // 'The caller of the function is not a router admin'
    string public constant CALLER_NOT_ROUTER_ADMIN = '20';
    // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = '21';
    // 'The caller of the function is not an connector admin'
    string public constant CALLER_NOT_CONNECTOR_ADMIN = '22';
    // Address should be not zero address
    string public constant ADDRESS_IS_ZERO = '23';
    // The caller of the function is not a router contract
    string public constant CALLER_NOT_ROUTER = '24';
    // The call to the open/close callback function failed
    string public constant EXECUTE_OPERATION_FAILED = '25';
    // Invalid amount to leverage
    string public constant LEVERAGE_IS_INVALID = '26';
}


// File contracts/lib/DataTypes.sol


pragma solidity ^0.8.17;

library DataTypes {
    struct Position {
        address account;
        address debt;
        address collateral;
        uint256 amountIn;
        uint256 leverage;
        uint256 collateralAmount;
        uint256 borrowAmount;
    }
}


// File contracts/interfaces/IConnectors.sol


pragma solidity ^0.8.17;

interface IConnectors {
    function addConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function updateConnectors(string[] calldata _names, address[] calldata _connectors) external;

    function removeConnectors(string[] calldata _names) external;

    function isConnector(string calldata _name) external view returns (bool isOk, address _connector);
}


// File contracts/interfaces/IAddressesProvider.sol


pragma solidity ^0.8.17;

interface IAddressesProvider {
    function setAddress(bytes32 _id, address _newAddress) external;

    function setRouterImpl(address _newRouterImpl) external;

    function setConfiguratorImpl(address _newConfiguratorImpl) external;

    function getRouter() external view returns (address);

    function getConfigurator() external view returns (address);

    function getACLAdmin() external view returns (address);

    function getACLManager() external view returns (address);

    function getConnectors() external view returns (address);

    function getTreasury() external view returns (address);

    function getAccountImpl() external view returns (address);

    function getAccountProxy() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);
}


// File contracts/lib/ConnectorsCall.sol


pragma solidity ^0.8.17;


library ConnectorsCall {
    /**
     * @dev They will check if the target is a finite connector, and if it is, they will call it.
     * @param _provider Addresses provider contract address.
     * @param _targetName Name of the connector.
     * @param _data Execute calldata.
     * @return response Returns the result of calling the calldata.
     */
    function connectorCall(
        IAddressesProvider _provider,
        string memory _targetName,
        bytes memory _data
    ) internal returns (bytes memory response) {
        address connectors = _provider.getConnectors();
        require(connectors != address(0), Errors.ADDRESS_IS_ZERO);
        response = _connectorCall(connectors, _targetName, _data);
    }

    /**
     * @dev They will check if the target is a finite connector, and if it is, they will call it.
     * @param _connectors Main connectors contract.
     * @param _targetName Name of the connector.
     * @param _data Execute calldata.
     * @return response Returns the result of calling the calldata.
     */
    function _connectorCall(
        address _connectors,
        string memory _targetName,
        bytes memory _data
    ) private returns (bytes memory response) {
        (bool isOk, address _target) = IConnectors(_connectors).isConnector(_targetName);
        require(isOk, Errors.NOT_CONNECTOR);
        response = _delegatecall(_target, _data);
    }

    /**
     * @dev Delegates the current call to `target`.
     * @param _target Name of the connector.
     * @param _data Execute calldata.
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegatecall(address _target, bytes memory _data) private returns (bytes memory response) {
        require(_target != address(0), Errors.INVALID_CONNECTOR_ADDRESS);
        assembly {
            let succeeded := delegatecall(gas(), _target, add(_data, 0x20), mload(_data), 0, 0)
            let size := returndatasize()

            response := mload(0x40)
            mstore(0x40, add(response, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            mstore(response, size)
            returndatacopy(add(response, 0x20), 0, size)

            switch iszero(succeeded)
            case 1 {
                // throw if delegatecall failed
                returndatacopy(0x00, 0x00, size)
                revert(0x00, size)
            }
        }
    }
}


// File contracts/lib/PercentageMath.sol


pragma solidity ^0.8.17;

/**
 * @title PercentageMath library
 * @author FlashFlow
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    function mulTo(uint256 _amount, uint256 _leverage) internal pure returns (uint256 amount) {
        amount = (_amount * _leverage) / PERCENTAGE_FACTOR;
    }
}


// File contracts/dependencies/openzeppelin/contracts/IERC20Metadata.sol


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


// File contracts/dependencies/openzeppelin/contracts/Context.sol


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


// File contracts/dependencies/openzeppelin/contracts/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= subtractedValue, 'ERC20: decreased allowance below zero');
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, 'ERC20: transfer amount exceeds balance');
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
        require(account != address(0), 'ERC20: mint to the zero address');

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
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, 'ERC20: insufficient allowance');
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}


// File contracts/dependencies/openzeppelin/contracts/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{ value: amount }('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), 'Address: call to non-contract');
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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


// File contracts/dependencies/openzeppelin/contracts/IERC20Permit.sol



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}


// File contracts/dependencies/openzeppelin/contracts/SafeERC20.sol



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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, 'SafeERC20: decreased allowance below zero');
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, 'SafeERC20: permit did not succeed');
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
        }
    }
}


// File contracts/lib/UniversalERC20.sol


pragma solidity ^0.8.17;



library UniversalERC20 {
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(to).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, 'Wrong useage of ETH.universalTransferFrom()');
            if (to != address(this)) {
                payable(to).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value - amount);
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            if (amount == 0) {
                token.safeApprove(to, 0);
                return;
            }

            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                if (allowance > 0) {
                    token.safeApprove(to, 0);
                }
                token.safeApprove(to, amount);
            }
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 10000 }(
            abi.encodeWithSignature('decimals()')
        );
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{ gas: 10000 }(abi.encodeWithSignature('DECIMALS()'));
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function universalSymbol(IERC20 token) internal view returns (string memory) {
        if (isETH(token)) {
            return 'ETH';
        } else {
            return ERC20(address(token)).symbol();
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS));
    }
}


// File contracts/interfaces/IRouter.sol


pragma solidity ^0.8.17;

interface IRouter {
    struct SwapParams {
        address fromToken;
        address toToken;
        uint256 amount;
        string targetName;
        bytes data;
    }

    function fee() external view returns (uint256);

    function positionsIndex(address _account) external view returns (uint256);

    function positions(
        bytes32 _key
    ) external view returns (address, address, address, uint256, uint256, uint256, uint256);

    function accounts(address _owner) external view returns (address);

    function setFee(uint256 _fee) external;

    function swapAndOpen(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data,
        SwapParams memory _params
    ) external payable;

    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function swap(SwapParams memory _params) external payable;

    function updatePosition(DataTypes.Position memory _position) external;

    function getOrCreateAccount(address _owner) external returns (address);

    function getKey(address _account, uint256 _index) external pure returns (bytes32);

    function predictDeterministicAddress(address _owner) external view returns (address predicted);

    function getFeeAmount(uint256 _amount) external view returns (uint256 feeAmount);
}


// File contracts/interfaces/IFlashReceiver.sol


pragma solidity ^0.8.17;

interface IFlashReceiver {
    function executeOperation(
        address _token,
        uint256 _amount,
        uint256 _fee,
        address _initiator,
        string memory _targetName,
        bytes calldata _params
    ) external;
}


// File contracts/interfaces/IAccount.sol


pragma solidity ^0.8.17;


interface IAccount is IFlashReceiver {
    function initialize(address _user, IAddressesProvider _provider) external;

    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external;

    function openPositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external;

    function closePositionCallback(
        string[] memory _targetNames,
        bytes[] memory _datas,
        bytes[] calldata _customDatas,
        uint256 _repayAmount,
        address _repayAddress
    ) external;

    function claimTokens(address _token, uint256 _amount) external;
}


// File contracts/Router.sol


pragma solidity ^0.8.17;










/**
 * @title Router contract
 * @author FlashFlow
 * @notice Main point of interaction with an FlashFlow protocol
 * - Users can:
 *   # Open position
 *   # Close position
 *   # Swap their tokens
 *   # Create acconut
 */
contract Router is VersionedInitializable, IRouter {
    using UniversalERC20 for IERC20;
    using ConnectorsCall for IAddressesProvider;
    using PercentageMath for uint256;

    /* ============ Immutables ============ */

    // The contract by which all other contact addresses are obtained.
    IAddressesProvider public immutable ADDRESSES_PROVIDER;

    /* ============ Constants ============ */

    uint256 public constant ROUTER_REVISION = 0x1;

    /* ============ State Variables ============ */

    // Fee of the protocol, expressed in bps
    uint256 public override fee;

    // Count of user position
    mapping(address => uint256) public override positionsIndex;

    // Map of key (user address and position index) to position (key => postion)
    mapping(bytes32 => DataTypes.Position) public override positions;

    // Map of users address and their account (userAddress => userAccount)
    mapping(address => address) public override accounts;

    /* ============ Events ============ */

    /**
     * @dev Emitted when the account will be created.
     * @param account The address of the Account contract.
     * @param owner The address of the owner account.
     */
    event AccountCreated(address indexed account, address indexed owner);

    /**
     * @dev Emitted when the sender swap tokens.
     * @param sender Address who create operation.
     * @param fromToken The address of the token to sell.
     * @param toToken The address of the token to buy.
     * @param amountIn The amount of the token to sell.
     * @param amountOut The amount of the token transfer to sender.
     * @param connectorName Conenctor name.
     */
    event SwapTokens(
        address indexed sender,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut,
        string connectorName
    );

    /**
     * @dev Emitted when the user open position.
     * @param key The key to obtain the current position.
     * @param account The address of the owner position.
     * @param index Count current position.
     * @param position The structure of the current position.
     */
    event OpenPosition(bytes32 indexed key, address indexed account, uint256 index, DataTypes.Position position);

    /**
     * @dev Emitted when the user close position.
     * @param key The key to obtain the current position.
     * @param account The address of the owner position.
     * @param position The structure of the current position.
     */
    event ClosePosition(bytes32 indexed key, address indexed account, DataTypes.Position position);

    /* ============ Modifiers ============ */

    /**
     * @dev Only pool configurator can call functions marked by this modifier.
     */
    modifier onlyConfigurator() {
        require(ADDRESSES_PROVIDER.getConfigurator() == msg.sender, Errors.CALLER_NOT_CONFIGURATOR);
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @dev Constructor.
     * @param _provider The address of the AddressesProvider contract
     */
    constructor(IAddressesProvider _provider) {
        require(address(_provider) != address(0), Errors.ADDRESS_IS_ZERO);
        ADDRESSES_PROVIDER = _provider;
    }

    /* ============ Initializer ============ */

    /**
     * @notice Initializes the Router.
     * @dev Function is invoked by the proxy contract when the Router contract is added to the
     * AddressesProvider.
     * @dev Caching the address of the AddressesProvider in order to reduce gas consumption on subsequent operations
     * @param _provider The address of the AddressesProvider
     */
    function initialize(address _provider) external virtual initializer {
        require(_provider == address(ADDRESSES_PROVIDER), Errors.INVALID_ADDRESSES_PROVIDER);
        fee = 50; // 0.5%
    }

    /* ============ External Functions ============ */

    /**
     * @notice Set a new fee to the router contract.
     * @param _fee The new amount
     */
    function setFee(uint256 _fee) external override onlyConfigurator {
        require(_fee > 0, Errors.INVALID_FEE_AMOUNT);
        fee = _fee;
    }

    /**
     * @dev Exchanges the input token for the necessary token to create a position and opens it.
     * @param _position The structure of the current position.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     * @param _params The additional parameters needed to the exchange.
     */
    function swapAndOpen(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data,
        SwapParams memory _params
    ) external payable override {
        _position.amountIn = _swap(_params);
        _openPosition(_position, _targetName, _data);
    }

    /**
     * @dev Create a position on the lendings protocol.
     * @param _position The structure of the current position.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) external override {
        IERC20(_position.debt).universalTransferFrom(msg.sender, address(this), _position.amountIn);
        _openPosition(_position, _targetName, _data);
    }

    /**
     * @dev Сloses the user's position and deletes it.
     * @param _key The key to obtain the current position.
     * @param _token Flashloan token.
     * @param _amount Flashloan amount.
     * @param _targetName The connector name that will be called are.
     * @param _data Calldata for the openPositionCallback.
     */
    function closePosition(
        bytes32 _key,
        address _token,
        uint256 _amount,
        string memory _targetName,
        bytes calldata _data
    ) external override {
        DataTypes.Position memory position = positions[_key];
        require(msg.sender == position.account, Errors.CALLER_NOT_POSITION_OWNER);

        address account = accounts[msg.sender];
        require(account != address(0), Errors.ACCOUNT_DOES_NOT_EXIST);

        IAccount(account).closePosition(_key, _token, _amount, _targetName, _data);

        emit ClosePosition(_key, account, position);
        delete positions[_key];
    }

    /**
     * @dev Exchanges tokens and sends them to the sender, an auxiliary function for the user interface.
     * @param _params parameters required for the exchange.
     */
    function swap(SwapParams memory _params) external payable override {
        uint256 initialBalance = IERC20(_params.toToken).universalBalanceOf(address(this));
        uint256 value = _swap(_params);
        uint256 finalBalance = IERC20(_params.toToken).universalBalanceOf(address(this));
        require(finalBalance - initialBalance == value, 'value is not valid');

        IERC20(_params.toToken).universalTransfer(msg.sender, value);

        emit SwapTokens(msg.sender, _params.fromToken, _params.toToken, _params.amount, value, _params.targetName);
    }

    /**
     * @dev Updates the current positions required for the callback.
     * @param _position The structure of the current position.
     */
    function updatePosition(DataTypes.Position memory _position) external override {
        address account = _position.account;
        require(msg.sender == accounts[account], Errors.CALLER_NOT_ACCOUNT_OWNER);

        bytes32 key = getKey(account, positionsIndex[account]);
        positions[key] = _position;
    }

    // solhint-disable-next-line
    receive() external payable {}

    /* ============ Public Functions ============ */

    /**
     * @dev Checks if the user has an account otherwise creates and initializes it.
     * @param _owner User address.
     * @return Returns of the user account address.
     */
    function getOrCreateAccount(address _owner) public override returns (address) {
        require(_owner == msg.sender, Errors.CALLER_NOT_ACCOUNT_OWNER);
        address _account = address(accounts[_owner]);

        if (_account == address(0)) {
            _account = Clones.cloneDeterministic(
                ADDRESSES_PROVIDER.getAccountProxy(),
                bytes32(abi.encodePacked(_owner))
            );
            accounts[_owner] = _account;
            IAccount(_account).initialize(_owner, ADDRESSES_PROVIDER);
            emit AccountCreated(_account, _owner);
        }

        return _account;
    }

    /**
     * @dev Create position key.
     * @param _account Position account owner.
     * @param _index Position count account owner.
     * @return Returns the position key
     */
    function getKey(address _account, uint256 _index) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _index));
    }

    /**
     * @dev Returns the future address of the account created through create2, necessary for the user interface.
     * @param _owner User account address, convert to salt.
     * @return predicted Returns of the user account address.
     */
    function predictDeterministicAddress(address _owner) public view override returns (address predicted) {
        return
            Clones.predictDeterministicAddress(
                ADDRESSES_PROVIDER.getAccountProxy(),
                bytes32(abi.encodePacked(_owner)),
                address(this)
            );
    }

    /**
     * @dev Calculates and returns the current commission depending on the amount.
     * @param _amount Amount
     * @return feeAmount Returns the protocol fee amount.
     */
    function getFeeAmount(uint256 _amount) public view override returns (uint256 feeAmount) {
        require(_amount > 0, Errors.INVALID_CHARGE_AMOUNT);
        feeAmount = _amount.mulTo(fee);
    }

    /* ============ Private Functions ============ */

    /**
     * @dev Create user account if user doesn't have it. Update position index and position state.
     * Call openPosition on the user account proxy contract.
     */
    function _openPosition(
        DataTypes.Position memory _position,
        string memory _targetName,
        bytes calldata _data
    ) private {
        require(_position.account == msg.sender, Errors.CALLER_NOT_POSITION_OWNER);
        require(_position.leverage > PercentageMath.PERCENTAGE_FACTOR, Errors.LEVERAGE_IS_INVALID);

        address account = getOrCreateAccount(msg.sender);

        address owner = _position.account;
        uint256 index = positionsIndex[owner] += 1;
        positionsIndex[owner] = index;

        bytes32 key = getKey(owner, index);
        positions[key] = _position;

        IERC20(_position.debt).universalApprove(account, _position.amountIn);
        IAccount(account).openPosition(_position, _targetName, _data);

        // Get the position on the key because, update it in the process of creating
        emit OpenPosition(key, account, index, positions[key]);
    }

    /**
     * @dev Internal function for the exchange, sends tokens to the current contract.
     * @param _params parameters required for the exchange.
     * @return value  Returns the amount of tokens received.
     */
    function _swap(SwapParams memory _params) private returns (uint256 value) {
        IERC20(_params.fromToken).universalTransferFrom(msg.sender, address(this), _params.amount);
        bytes memory response = ADDRESSES_PROVIDER.connectorCall(_params.targetName, _params.data);
        value = abi.decode(response, (uint256));
    }

    /**
     * @notice Returns the version of the Router contract.
     * @return The version is needed to update the proxy.
     */
    function getRevision() internal pure override returns (uint256) {
        return ROUTER_REVISION;
    }
}