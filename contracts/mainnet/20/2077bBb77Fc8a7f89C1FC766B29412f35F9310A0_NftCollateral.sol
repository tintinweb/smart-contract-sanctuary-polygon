// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '../common/TransferHelper.sol';

/**
 * @dev Partial interface of the ERC20 standard.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @dev Partial interface of the marketplace contract.
 */
interface IMarketplace {
    function adminBurn(uint256 tokenId) external;
    function adminMint(uint32 profileId, address to, uint256 tokenId) external;
    function getProfileIdByTokenId(uint256 tokenId) external returns (uint32);
    function getSellPriceById(uint32 profileID) external  view returns (uint256);
}

/**
 * @dev Partial interface of the NFT contract.
 */
interface INFT {
    function ownerOf(uint256 tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

/**
 * @dev Partial interface of the Collateral contract.
 */
interface ICollateral {
    function depositNetna (
        address userAddress, uint256 amount
    ) external returns (bool);
    function withdrawNetna (
        address userAddress, uint256 amount
    ) external returns (bool);
    function getNEtnaContract () external view returns (address);
    function getLiquidationManager () external view returns (address);
}

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

/**
 * @dev Implementation of using Cyclops NFTs as a collateral in the Collateral contract,
 * function names are self explanatory
 */
contract NftCollateral is IERC721Receiver, Initializable {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier onlyManager() {
        require(_managers[msg.sender], 'Caller is not the manager');
        _;
    }
    modifier onlyCollateralContract() {
        require(msg.sender == address(_collateralContract),
            'Caller is not the Collateral contract');
        _;
    }
    modifier onlyLiquidationManager() {
        require(msg.sender == _collateralContract.getLiquidationManager(),
            'Caller is not the liquidation manager');
        _;
    }
    struct Deposit {
        address userAddress;
        uint256 amount;
        uint256 tokensNumber;
    }
    mapping (uint256 => Deposit) internal _deposits;
    mapping (address => uint256) internal _usersDepositIndex;
    mapping (uint256 => address) internal _tokenRegistry; // tokenId => userAddress
    mapping (address => mapping (uint256 => uint256)) internal _userTokenRegistry;
    // userAddress => RegistryIndex => tokenId
    mapping (address => mapping (uint256 => uint256)) internal _userTokenIndexes;
    // userAddress => tokenId => RegistryIndex
    mapping (uint256 => uint256) internal _tokenPrice;
    mapping (address => uint256) internal _atLiquidationIndex;
    mapping (uint256 => address) internal _atLiquidation;
    // After nft collateral liquidation, before liquidated nft collateral withdrawal
    mapping (address => bool) internal _managers;

    uint256 internal _atLiquidationNumber;
    uint256 internal _depositsNumber;
    uint256 internal _tokensNumber;
    uint256 internal _batchLimit;
    // maximum amount of tokens that can be proceeded within single transaction
    uint256 internal constant _YEAR = 365 * 24 * 3600;

    IMarketplace internal _marketplaceContract;
    INFT internal _nftContract;
    ICollateral internal _collateralContract;
    address private _owner;

    function initialize (
        address marketplaceAddress,
        address nftAddress,
        address collateralAddress,
        address newOwner
    ) public initializer returns (bool) {
        require(collateralAddress != address(0), 'Collateral contract address can not be zero');
        require(marketplaceAddress != address(0), 'Marketplace contract address can not be zero');
        require(nftAddress != address(0), 'NFT token address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');

        _collateralContract = ICollateral(collateralAddress);
        _marketplaceContract = IMarketplace(marketplaceAddress);
        _nftContract = INFT(nftAddress);
        _owner = newOwner;
        _managers[newOwner] = true;
        _batchLimit = 100;
        return true;
    }

    function depositNftCollateral (
        uint256[] memory tokenIds
    ) external returns (bool) {
        require(tokenIds.length > 0, 'No token ids provided');
        require(_atLiquidationIndex[msg.sender] == 0, 'Sender is at liquidation');

        uint256 depositIndex = _usersDepositIndex[msg.sender];
        if (depositIndex == 0) {
            _depositsNumber ++;
            depositIndex = _depositsNumber;
            _deposits[depositIndex].userAddress = msg.sender;
            _usersDepositIndex[msg.sender] = depositIndex;
        }
        uint256 amount = _addTokens(msg.sender, depositIndex, tokenIds);
        address nEtnaAddress = _collateralContract.getNEtnaContract();
        require(nEtnaAddress != address(0), 'Deposit error');
        TransferHelper.safeTransfer(nEtnaAddress, address(_collateralContract), amount);
        require(
            _collateralContract.depositNetna(msg.sender, amount),
                'Deposit error'
        );
        return true;
    }

    function withdrawNftCollateral (
        uint256[] memory tokenIds
    ) external returns (bool) {
        require(tokenIds.length > 0, 'No token ids provided');
        require(_atLiquidationIndex[msg.sender] == 0, 'Sender is at liquidation');

        uint256 depositIndex = _usersDepositIndex[msg.sender];
        require(depositIndex > 0, 'Deposit is not found');

        uint256 amount = _withdrawTokens(msg.sender, depositIndex, tokenIds);
        require(
            _collateralContract.withdrawNetna(msg.sender, amount),
                'Withdraw error'
        );
        return true;
    }

    function _addTokens(
        address userAddress, uint256 depositIndex, uint256[] memory tokenIds
    ) internal returns (uint256) {
        uint256 amount;
        uint256 tokensNumber;
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            if (_tokenRegistry[tokenIds[i]] != address(0)) continue;

            uint32 profileId = _marketplaceContract.getProfileIdByTokenId(tokenIds[i]);
            uint256 price = _marketplaceContract.getSellPriceById(profileId);
            if (!(price > 0)) continue;

            try _nftContract.ownerOf(tokenIds[i]) returns (address tokenOwner) {
                if (tokenOwner != userAddress) continue;

                _nftContract.safeTransferFrom(
                    userAddress,
                    address(this),
                    tokenIds[i]
                );
                _tokenPrice[tokenIds[i]] = price;
                tokensNumber ++;
                amount += price;
                _userTokenRegistry
                    [userAddress]
                    [_deposits[depositIndex].tokensNumber + tokensNumber] = tokenIds[i];
                _userTokenIndexes
                    [userAddress]
                    [tokenIds[i]] = _deposits[depositIndex].tokensNumber + tokensNumber;
                _tokenRegistry[tokenIds[i]] = userAddress;
            } catch {}
        }
        _deposits[depositIndex].tokensNumber += tokensNumber;
        _tokensNumber += tokensNumber;
        _deposits[depositIndex].amount += amount;

        return amount;
    }

    function _withdrawTokens(
        address userAddress, uint256 depositIndex, uint256[] memory tokenIds
    ) internal returns (uint256) {
        uint256 amount;
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            if (_tokenRegistry[tokenIds[i]] != userAddress) continue;

            amount += _tokenPrice[tokenIds[i]];
            uint256 index = _userTokenIndexes[userAddress][tokenIds[i]];
            if (index < _deposits[depositIndex].tokensNumber) {
                _userTokenRegistry[userAddress][index] =
                    _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber];
                _userTokenIndexes[userAddress][_userTokenRegistry[userAddress][index]] = index;
            }
            _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber] = 0;
            _deposits[depositIndex].tokensNumber --;
            _tokenRegistry[tokenIds[i]] = address(0);

            _nftContract.safeTransferFrom(
                address(this),
                userAddress,
                tokenIds[i]
            );
        }
        _deposits[depositIndex].amount -= amount;
        return amount;
    }

    function transferOwnership(
        address newOwner
    ) external onlyOwner returns (bool) {
        require(newOwner != address(0), "newOwner should not be zero address");
        _owner = newOwner;
        return true;
    }

    function addToManagers (
        address userAddress
    ) external onlyOwner returns (bool) {
        _managers[userAddress] = true;
        return true;
    }

    function removeFromManagers (
        address userAddress
    ) external onlyOwner returns (bool) {
        _managers[userAddress] = false;
        return true;
    }

    function setToLiquidation (
        address userAddress
    ) external onlyCollateralContract returns (bool) {
        if (_atLiquidationIndex[userAddress] == 0) {
            _atLiquidationNumber ++;
            _atLiquidationIndex[userAddress] = _atLiquidationNumber;
            _atLiquidation[_atLiquidationNumber] = userAddress;
        }
        return true;
    }

    function setBatchLimit (
        uint256 batchLimit
    ) external onlyManager returns (bool) {
        require(batchLimit > 0, 'Batch limit should be greater than zero');
        _batchLimit = batchLimit;

        return true;
    }

    function setCollateralContract (
        address contractAddress
    ) external onlyManager returns (bool) {
        require(contractAddress != address(0), 'Contract address can not be zero');
        _collateralContract = ICollateral(contractAddress);
        return true;
    }

    function setMarketplaceContract (
        address tokenAddress
    ) external onlyManager returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _marketplaceContract = IMarketplace(tokenAddress);
        return true;
    }

    function setNftContract (
        address tokenAddress
    ) external onlyManager returns (bool) {
        require(tokenAddress != address(0), 'Token address can not be zero');
        _nftContract = INFT(tokenAddress);
        return true;
    }

    /**
    * Migrating nft collateral data from another contract
    */
    function migrateNftCollaterals (
        address userAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata prices
    ) external onlyManager returns (bool) {
        require(
            tokenIds.length == prices.length,
                'Arrays length mismatch'
        );
        require(
            _usersDepositIndex[userAddress] == 0, "User's deposit already exists"
        );
        _depositsNumber ++;
        _deposits[_depositsNumber].userAddress = userAddress;
        _usersDepositIndex[userAddress] = _depositsNumber;
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            require (
                _tokenRegistry[tokenIds[i]] == address(0),
                    'Token Id is already in use'
            );
            _tokenPrice[tokenIds[i]] = prices[i];
            _deposits[_depositsNumber].amount += prices[i];
            _userTokenRegistry[userAddress][i + 1] = tokenIds[i];
            _userTokenIndexes[userAddress][tokenIds[i]] = i + 1;
            _tokenRegistry[tokenIds[i]] = userAddress;
            _deposits[_depositsNumber].tokensNumber ++;
            _tokensNumber ++;
        }
        return true;
    }

    function adminWithdrawNft (
        uint256[] memory tokenIds
    ) external onlyOwner returns (bool) {
        for (uint256 i; i < tokenIds.length; i ++) {
            try _nftContract.safeTransferFrom(address(this), msg.sender, tokenIds[i]) {} catch {}
        }
        return true;
    }

    function adminWithdrawToken (
        address contractAddress, uint256 amount
    ) external onlyOwner returns (bool) {
        require(contractAddress != address(0), 'Contract address should not be zero');
        uint256 balance = IERC20(contractAddress).balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        TransferHelper.safeTransfer(contractAddress, msg.sender, amount);
        return true;
    }

    function withdrawLiquidatedCollateral (
        address userAddress, uint256[] memory tokenIds
    ) external onlyLiquidationManager returns (bool) {
        require(
            _atLiquidationIndex[userAddress] > 0,
            'User is not at liquidation'
        );
        uint256 depositIndex = _usersDepositIndex[userAddress];
        for (uint256 i = 0; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            if (_tokenRegistry[tokenIds[i]] != userAddress) continue;

            uint256 index = _userTokenIndexes[userAddress][tokenIds[i]];
            if (index < _deposits[depositIndex].tokensNumber) {
                _userTokenRegistry[userAddress][index] =
                    _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber];
                _userTokenIndexes[userAddress][_userTokenRegistry[userAddress][index]] = index;
            }
            _userTokenRegistry[userAddress][_deposits[depositIndex].tokensNumber] = 0;
            _deposits[depositIndex].tokensNumber --;
            _tokenRegistry[tokenIds[i]] = address(0);
            _nftContract.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }

        if (_deposits[depositIndex].tokensNumber == 0) {
            uint256 liquidationIndex = _atLiquidationIndex[userAddress];
            if (liquidationIndex < _atLiquidationNumber) {
                _atLiquidation[liquidationIndex] =
                    _atLiquidation[_atLiquidationNumber];
            }
            _atLiquidationNumber --;
            _atLiquidationIndex[userAddress] = 0;
            _atLiquidation[_atLiquidationNumber] = address(0);
        }

        return true;
    }

    function getDepositsNumber () external view returns (uint256) {
        return _depositsNumber;
    }

    function getDeposit (
        uint256 depositIndex
    ) external view returns (
        address userAddress, uint256 amount, uint256 tokensNumber
    ) {
        return (
            _deposits[depositIndex].userAddress,
            _deposits[depositIndex].amount,
            _deposits[depositIndex].tokensNumber
        );
    }

    function getUserDeposit (
        address userAddress
    ) external view returns (
        uint256 depositIndex,
        uint256 amount,
        uint256 tokensNumber
    ) {
        uint256 _depositIndex = _usersDepositIndex[userAddress];
        return (
            _depositIndex,
            _deposits[_depositIndex].amount,
            _deposits[_depositIndex].tokensNumber
        );
    }

    function getTokenStaker (uint256 tokenId) external view returns (address) {
        return _tokenRegistry[tokenId];
    }

    function getLastTokenPrice (
        uint256 tokenId
    ) external view returns (uint256) {
        return _tokenPrice[tokenId];
    }

    function getTokensNumber () external view returns (uint256) {
        return _tokensNumber;
    }

    function getUserTokensNumber (
        address userAddress
    ) external view returns (uint256) {
        uint256 depositIndex = _usersDepositIndex[userAddress];
        return _deposits[depositIndex].tokensNumber;
    }

    function getUserTokenByIndex (
        address userAddress, uint256 index
    ) external view returns (uint256) {
        return _userTokenRegistry[userAddress][index];
    }

    function getUserTokenIndexByTokenId (
        address userAddress, uint256 tokenId
    ) external view returns (uint256) {
        return _userTokenIndexes[userAddress][tokenId];
    }

    function getCollateralContract () external view returns (address) {
        return address(_collateralContract);
    }

    function getMarketplaceContract () external view returns (address) {
        return address(_marketplaceContract);
    }

    function getNftContract () external view returns (address) {
        return address(_nftContract);
    }

    function getBatchLimit () external view returns (uint256) {
        return _batchLimit;
    }

    function getAtLiquidationNumber () external view returns (uint256) {
        return _atLiquidationNumber;
    }

    function getAtLiquidatedUser (
        uint256 atLiquidationIndex
    ) external view returns (address) {
        return _atLiquidation[atLiquidationIndex];
    }

    function getAtLiquidationIndex (
        address userAddress
    ) external view returns (uint256) {
        return _atLiquidationIndex[userAddress];
    }

    function isAtLiquidation (
        address userAddress
    ) external view returns (bool) {
        return _atLiquidationIndex[userAddress] > 0;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    /**
    * @dev Standard callback fot the ERC721 token receiver.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.2;
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
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