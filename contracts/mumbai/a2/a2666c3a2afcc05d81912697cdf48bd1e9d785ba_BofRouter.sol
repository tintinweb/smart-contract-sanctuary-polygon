// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./AccountRegistry.sol";
import "./interfaces/VaultAPI.sol";
import "./interfaces/IImmersvePaymentProtocol.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
 *  @title BofRouter
 *  @dev This contract manages the funds of a single user, which are spread across different vaults, including Immersve Protocol.
 *  The contract owner is the only entity that can move the funds around.
 *  This contract emits events for balance changes.
 */
contract BofRouter is Initializable, OwnableUpgradeable {
    //--- public variables ---//
    AccountRegistry public accountRegistry;
    address public pendingAccountRegistry;

    //--- events ---//
    event AccountRegistryUpdated(
        address indexed newAccountRegistry,
        address indexed oldAccountRegistry
    );
    event Transfer(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );
    event Deposit(address indexed token, address indexed vault, uint256 amount);
    event Withdraw(
        address indexed token,
        address indexed vault,
        uint256 amount
    );
    event Sweep(address indexed token, uint256 amount);
    event NewLockImmersve(uint256 amount);

    //--- modifiers ---//

    modifier onlyGov() {
        require(msg.sender == gov(), "!Gov");
        _;
    }

    //--- constructor ---//
    /**
     * @dev Initializes the contract with the address of the owner and the accountRegistry.
     * @param _owner the address that will own this BofWallet
     * @param _accountRegistry address of the accountRegistry
     */
    function initialize(
        address _owner,
        address _accountRegistry
    ) public payable initializer {
        _transferOwnership(_owner);
        accountRegistry = AccountRegistry(_accountRegistry);
    }

    //--- setter functions ---//

    /**
     * @dev This function sets the address of the pending account registry.
     * @param _newAccountRegistry The address of the new account registry.
     */
    function setAccountRegistry(address _newAccountRegistry) external onlyGov {
        pendingAccountRegistry = _newAccountRegistry;
    }

    /**
     * @dev This function accepts the new account registry address and updates the current account registry address.
     */
    function acceptAccountRegistry() external onlyOwner {
        emit AccountRegistryUpdated(
            pendingAccountRegistry,
            address(accountRegistry)
        );
        accountRegistry = AccountRegistry(pendingAccountRegistry);
        pendingAccountRegistry = address(0);
    }

    //--- view functions ---//

    /**
     * @dev Returns the address of the gov of the account registry
     * @return Gov address
     */
    function gov() public view returns (address) {
        return accountRegistry.gov();
    }

    /**
     * @dev Returns the balance of the owner held in a particular vault
     * @param _vault Address of the vault
     * @return Balance of the owner in the specified vault
     */
    function _balanceOf(address _vault) internal view returns (uint256) {
        return
            (VaultAPI(_vault).pricePerShare() *
                VaultAPI(_vault).balanceOf(address(this))) /
            (10 ** VaultAPI(_vault).decimals());
    }

    /**
     * @dev Returns the balance of the specified token in a specified vault
     * @param _token Address of the token
     * @param _vault Address of the vault
     * @return Balance of the owner in the vault
     */
    function balanceOf(
        address _token,
        address _vault
    ) external view returns (uint256) {
        require(VaultAPI(_vault).token() == _token);
        return _balanceOf(_vault);
    }

    /**
     * @dev Returns the balance locked in the immersve contract
     * @notice only usdc is supported by immersve at this time
     * @return The amount locked in the immersve contract
     */
    function balanceImmersveLocked() public view returns (uint256) {
        return
            IImmersvePaymentProtocol(accountRegistry.immersve())
                .getAvailableLockedFundsBalance(address(this));
    }

    /**
     * @dev Returns the balance free in the immersve contract
     * @notice only usdc is supported by immersve at this time
     * @return The amount free in the immersve contract
     */
    function balanceImmersveFree() public view returns (uint256) {
        return
            IImmersvePaymentProtocol(accountRegistry.immersve()).getBalance();
    }

    /**
     * @dev Returns the balance in this wallet
     * @param _token the token to check
     * @return The amount of token ready to be deployed
     */
    function balanceUnallocated(address _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @dev Returns the balance deployed in vaults from this wallet
     * @param _token the token to check
     * @return The amount of token deployed to active vaults
     */
    function balanceInVaults(address _token) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < accountRegistry.getVaultsLength(_token); i++) {
            total += _balanceOf(accountRegistry.vaults(_token, i));
        }
        return total;
    }

    /**
     * @dev Returns the balance deployed in vaults that have been retired, the user should withdraw as soon as possible
     * @param _token the token to check
     * @return The amount of token deployed to legacy vaults
     */
    function balanceInLegacyVaults(
        address _token
    ) public view returns (uint256) {
        uint256 total = 0;
        for (
            uint256 i = 0;
            i < accountRegistry.getLegacyVaultsLength(_token);
            i++
        ) {
            total += _balanceOf(accountRegistry.legacyVaults(_token, i));
        }
        return total;
    }

    /**
     * @dev Returns the total balance of this wallet
     * @param _token the token to check
     * @return total The amount of token either unallocated, in immersve or in vaults
     */
    function balanceOf(address _token) external view returns (uint256 total) {
        if (_token == accountRegistry.usdc()) {
            total += balanceImmersveFree();
            total += balanceImmersveLocked();
        }
        total =
            total +
            balanceUnallocated(_token) +
            balanceInVaults(_token) +
            balanceInLegacyVaults(_token);
    }

    //--- ERC 1271 ---//
    function isValidSignature(
        bytes32 _hash,
        bytes calldata _signature
    ) public view returns (bytes4 magicValue) {
        return
            ECDSA.recover(_hash, _signature) == owner()
                ? this.isValidSignature.selector
                : bytes4(0);
    }

    //--- write functions ---//

    /**
     * @dev Internal function to deposit tokens to a specific vault
     * @param _token Address of the token to be deposited
     * @param _vault Address of the vault to deposit tokens in
     * @param _amount Amount of tokens to be deposited
     */
    function _depositVault(
        address _token,
        address _vault,
        uint256 _amount
    ) internal {
        require(accountRegistry.isSupported(_token, _vault), "!Supported");
        require(balanceUnallocated(_token) >= _amount, "!Enough");
        IERC20(_token).approve(_vault, _amount);
        VaultAPI(_vault).deposit(_amount);
    }

    /**
     * @dev Function to deposit tokens into a specific vault
     * @param _token Address of the token to be deposited
     * @param _vault Address of the vault to deposit tokens in
     * @param _amount Amount of tokens to be deposited
     */
    function deposit(
        address _token,
        address _vault,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        if (_vault == accountRegistry.immersve()) {
            _depositImmersve(_amount);
        } else {
            _depositVault(_token, _vault, _amount);
        }
        emit Deposit(_token, _vault, _amount);
    }

    /**
     * @dev Internal function to withdraw tokens from a specific vault
     * @param _token Address of the token to be withdrawn
     * @param _vault Address of the vault to withdraw tokens from
     * @param _amount Amount of tokens to be withdrawn
     */
    function _withdrawVault(
        address _token,
        address _vault,
        uint256 _amount
    ) internal {
        require(accountRegistry.isSupported(_token, _vault), "!Supported");
        VaultAPI(_vault).withdraw(_amount); //TODO amount is in shares, or do we want to withdraw an amount in # of tokens?
    }

    /**
     @dev Function to withdraw tokens from a specific vault
     @param _token Address of the token to be withdrawn
     @param _vault Address of the vault to withdraw tokens from
     @param _amount Amount of tokens to be withdrawn
     */
    function withdraw(
        address _token,
        address _vault,
        uint256 _amount
    ) external onlyOwner {
        if (_vault == accountRegistry.immersve()) {
            _withdrawImmersve(_amount);
        } else {
            _withdrawVault(_token, _vault, _amount);
        }
        IERC20(_token).transfer(owner(), _amount);
        emit Withdraw(_token, _vault, _amount);
    }

    /**
     @dev Function to withdraw tokens from the router
     @param _token Address of the token to be withdrawn
     @param _amount Amount of tokens to be withdrawn
     */
    function sweep(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
        emit Sweep(_token, _amount);
    }

    /**
     * @dev Internal function to deposit USDC to the Immersve protocol
     * @param _amount Amount of USDC to be deposited
     */
    function _depositImmersve(uint256 _amount) internal {
        require(
            balanceUnallocated(accountRegistry.usdc()) >= _amount,
            "!EnoughDeposit"
        );
        IERC20(accountRegistry.usdc()).approve(
            accountRegistry.immersve(),
            _amount
        );
        IImmersvePaymentProtocol(accountRegistry.immersve()).deposit(_amount);
    }

    /**
     * @dev Internal function to withdraw USDC from Immersve protocol
     * @param _amount Amount of USDC to withdraw
     */
    function _withdrawImmersve(uint256 _amount) internal {
        require(balanceImmersveFree() >= _amount, "!EnoughWithdraw");
        IImmersvePaymentProtocol(accountRegistry.immersve()).withdraw(_amount);
    }

    /**
     * @dev Locks a specified amount of tokens into the Immersve contract
     * @param _amount The amount of tokens to lock
     */
    function _lockAmountImmersve(uint256 _amount) internal {
        require(
            IImmersvePaymentProtocol(accountRegistry.immersve()).getBalance() >=
                _amount,
            "!EnoughLock"
        );
        IImmersvePaymentProtocol(accountRegistry.immersve()).createLockedFund(
            _amount
        );
    }

    /**
     * @dev Allows the contract owner to lock a specified amount of tokens into the Immersve contract
     * @param _amount The amount of tokens to lock
     */
    function lockAmountImmersve(uint256 _amount) external onlyOwner {
        _lockAmountImmersve(_amount);
        emit NewLockImmersve(_amount);
    }

    /**
     * @dev Allows the contract owner to transfer a token from a vault/immersve to another vault/immersve
     * @param _token The address of the token being transferred
     * @param _from The address the tokens are currently held in, this can be either a vault or immersve
     * @param _to The address the tokens must be transferred to, this can be either a vault or immersve
     * @param _amount The amount of tokens to transfer
     */
    function transfer(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        require(_from != _to, "!TransferSameAddresses");
        require(_from != address(0), "!TransferZero");
        require(_to != address(0), "!TransferZero");

        if (_from == accountRegistry.immersve()) {
            // Case 1: _from immersve to a vault
            require(_token == accountRegistry.usdc(), "!Supported");
            _withdrawImmersve(_amount);
            _depositVault(_token, _to, _amount);
        } else if (_to == accountRegistry.immersve()) {
            require(_token == accountRegistry.usdc(), "!Supported");
            // Case 2: from a vault to immersve
            _withdrawVault(_token, _from, _amount);
            _depositImmersve(_amount);
        } else {
            // Case 3: from a vault to another vault
            _withdrawVault(_token, _from, _amount);
            _depositVault(_token, _to, _amount);
        }

        emit Transfer(_token, _from, _to, _amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

import "./interfaces/VaultAPI.sol";

/**
 *   @title AccountRegistry
 *  @dev A smart contract for managing supported tokens and their associated vaults.
 *  The contract is owned by a governance address that can add, retire or reactivate associated vaults. 
 *  Vault status is tracked in two mappings, vaults and legacyVaults. Vaults added to the contract are stored in `vaults` while
 *  retired or inactive vaults are moved to `legacyVaults`. 
 *  The contract has a set of access control modifiers, such as onlyGov and onlyPendingGov, which restrict access to certain functions.
*/
contract AccountRegistry {
    //--- public variables ---//

    address public gov; //the current governance address
    address public pendingGov; //the proposed governance address
    mapping(address => bool) public supportedTokens; //mapping of supported tokens
    mapping(address => address[]) public vaults; //map asset address to list of active vaults
    mapping(address => address[]) public legacyVaults; //map asset address to list of legacy vaults
    address public immersve; //the address of the Immersve contract
    address public usdc; //the address of the USDC contract

    //--- events ---//

    event ImmersveUpdated(address indexed immersve);
    event UsdcUpdated(address indexed usdc);
    event GovernanceUpdated(address indexed newGov, address indexed oldGov);
    event VaultAdded(address indexed token, address indexed vault);
    event VaultRetired(address indexed token, address indexed vault);
    event VaultReactivated(address indexed token, address indexed vault);

    //--- modifiers ---//

    modifier onlyGov() {
        require(msg.sender == gov, "!Gov");
        _;
    }

    modifier onlyPendingGov() {
        require(msg.sender == pendingGov, "!PendingGov");
        _;
    }

    //--- constructor ---//

    /**
     * @dev Initializes the contract with the address of the USDC contract and sets the governance address to the deployer address.
     * @param _usdc The address of the USDC contract.
     * @param _immersve The address of the immersve contract.
     */
    constructor(address _usdc, address _immersve) {
        gov = msg.sender;
        usdc = _usdc;
        immersve = _immersve;
    }

    //--- governance functions ---//

    /**
     * @dev Allows the governance address to set the pending governance address.
     * @param _newGov The proposed new governance address.
     */
    function setGovernance(address _newGov) external onlyGov {
        pendingGov = _newGov;
    }

    /**
     * @dev Allows the pending governance address to accept the governance role.
     */
    function acceptGovernance() external onlyPendingGov {
        emit GovernanceUpdated(pendingGov, gov);
        gov = pendingGov;
        pendingGov = address(0);
    }

    //--- setter functions ---//

    /**
     * @dev Allows the governance address to set the Immersve contract address.
     * @param _immersve The address of the Immersve contract.
     */
    function setImmersve(address _immersve) external onlyGov {
        immersve = _immersve;
        emit ImmersveUpdated(immersve);
    }

    /**
     * @notice Sets the USDC address for the protocol.
     * @param _usdc The address of the USDC token contract.
     */
    function setUsdc(address _usdc) external onlyGov {
        usdc = _usdc;
        emit UsdcUpdated(usdc);
    }

    /**
     * @notice Adds support for a new token to the protocol.
     * @param _token The address of the token contract to add support for.
     */
    function addToken(address _token) external onlyGov {
        require(!supportedTokens[_token], "!AlreadySupported");
        supportedTokens[_token] = true;
    }

    /**
     * @notice Removes support for a token from the protocol. The token should not have any active vaults anymore
     * @param _token The address of the token contract to remove support for.
     */
    function removeToken(address _token) external onlyGov {
        require(supportedTokens[_token], "!NotSupported");
        require(vaults[_token].length == 0, "!StillActiveVaults");
        supportedTokens[_token] = false;
    }

    /**
     * @notice Adds a new vault to the protocol for a specific token.
     * @param _token The address of the token contract the vault is for.
     * @param _vault The address of the vault contract to add.
     */
    function addVault(address _token, address _vault) external onlyGov {
        require(supportedTokens[_token], "!Supported");
        require(VaultAPI(_vault).token() == _token, "!WrongToken");
        //Check that the vault is not already in vaults or in legacyVaults
        for (uint256 i = 0; i < vaults[_token].length; i++) {
            require(vaults[_token][i] != _vault, "!AlreadyAdded");
        }
        for (uint256 i = 0; i < legacyVaults[_token].length; i++) {
            require(legacyVaults[_token][i] != _vault, "!AlreadyAdded");
        }

        vaults[_token].push(_vault);
        emit VaultAdded(_token, _vault);
    }

    /**
     * @dev Retires the given vault for the specified token.
     * @param _token The address of the token to retire the vault for.
     * @param _vault The address of the vault to retire.
     * Emits a VaultRetired event on success.
     */
    function retireVault(address _token, address _vault) external onlyGov {
        require(supportedTokens[_token], "!Supported");
        require(VaultAPI(_vault).token() == _token, "!WrongToken");

        //The vault shouldn't already be retired
        for (uint256 i = 0; i < legacyVaults[_token].length; i++) {
            require(legacyVaults[_token][i] != _vault, "!AlreadyRetired");
        }
        uint256 oldLenght = vaults[_token].length;
        //Retire the vault
        for (uint256 i = 0; i < oldLenght; i++) {
            if (vaults[_token][i] == _vault) {
                vaults[_token][i] = vaults[_token][oldLenght - 1];
                vaults[_token].pop();
                legacyVaults[_token].push(_vault);
                break;
            }
        }
        require(oldLenght == vaults[_token].length + 1, "!NotPresent");
        emit VaultRetired(_token, _vault);
    }

    /**
     * @dev Reactivates the given retired vault for the specified token.
     * @param _token The address of the token to reactivate the vault for.
     * @param _vault The address of the vault to reactivate.
     * Emits a VaultReactivated event on success.
     */
    function reactivateVault(address _token, address _vault) external onlyGov {
        require(supportedTokens[_token], "!Supported");
        require(VaultAPI(_vault).token() == _token, "!WrongToken");

        //The vault shouldn't be active
        for (uint256 i = 0; i < vaults[_token].length; i++) {
            require(vaults[_token][i] != _vault, "!StillActive");
        }
        uint256 oldLenght = legacyVaults[_token].length;
        //Retire the vault
        for (uint256 i = 0; i < oldLenght; i++) {
            if (legacyVaults[_token][i] == _vault) {
                legacyVaults[_token][i] = legacyVaults[_token][oldLenght - 1];
                legacyVaults[_token].pop();
                vaults[_token].push(_vault);
                break;
            }
        }
        require(oldLenght == legacyVaults[_token].length + 1, "!NotPresent");
        emit VaultReactivated(_token, _vault);
    }

    /**
     * @dev Returns the number of active vaults for the specified token.
     * @param _token The address of the token to get the active vaults length for.
     * @return The number of active vaults for the specified token.
     */
    function getVaultsLength(address _token) external view returns (uint256) {
        return vaults[_token].length;
    }

    /**
     * @dev Returns the number of retired vaults for the specified token.
     * @param _token The address of the token to get the retired vaults length for.
     * @return The number of retired vaults for the specified token.
     */
    function getLegacyVaultsLength(address _token)
        external
        view
        returns (uint256)
    {
        return legacyVaults[_token].length;
    }

    /**
     * @dev Checks whether the given vault is supported by the protocol for the specified token.
     * @param _token The address of the token to check the vault support for.
     * @param _vault The address of the vault to check.
     * @return true if the vault is supported by the protocol for the specified token, false otherwise.
     */
    function isSupported(address _token, address _vault)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < vaults[_token].length; i++) {
            if (vaults[_token][i] == _vault) return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/**
 *  @title VaultAPI
 *  @notice Interface for interacting with a Vault contract to deposit and withdraw funds
*/
interface VaultAPI {
    function deposit(uint256 amount) external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function token() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

	function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.18;

/**
 *  @title IImmersvePaymentProtocol
 *  @dev Interface for the Immersve Payment Protocol contract.
 */
interface IImmersvePaymentProtocol {
    function deposit(uint256 tokenAmount) external;

    function depositTo(uint256 tokenAmount, address sender) external;

    function withdraw(uint256 tokenAmount) external;

    function withdrawTo(uint256 tokenAmount, address sender) external;

    function lockFunds(
        uint256 timeout,
        uint256 price
    ) external returns (uint256);

    function lockFundsWithDeposit(
        uint256 timeout,
        uint256 price
    ) external returns (uint256);

    function revokeLockedFunds(uint256 lockedFundId) external;

    function confirmLockedFundsPayment(
        uint256 lockedFundId,
        bytes calldata signature
    ) external;

    function setTimeoutBlocks(uint32 timeoutBlocks) external;

    function setSafetyBlocks(uint16 _safetyBlocks) external;

    function balances(address account) external view returns (uint256);

    function getBalance() external view returns (uint256);

    function lockedFunds(
        address account,
        uint256 index
    ) external view returns (uint256, uint256, uint256);

    function lockedFundsLength(address account) external view returns (uint256);

    function defaultTimeoutBlocks() external view returns (uint32);

    function safetyBlocks() external view returns (uint16);

    function tokenSmartContractAddress() external view returns (address);

    function settlerAddress() external view returns (address);

    function createLockedFund(uint256 tokenAmont) external;

    function getLockedFunds() external view returns (uint256);

    function getAvailableLockedFundsBalance(
        address sender
    ) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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
        InvalidSignatureV // Deprecated in v4.8
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
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
                require(isContract(target), "Address: call to non-contract");
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