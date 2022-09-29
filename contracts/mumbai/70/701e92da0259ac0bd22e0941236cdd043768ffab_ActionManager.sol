// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IXTokenWrapper.sol";
import "../interfaces/IBFactory.sol";
import "../interfaces/IBPool.sol";
import "../interfaces/IBRegistry.sol";
import "../interfaces/IXTokenFactory.sol";
import "../interfaces/IXToken.sol";
import "../smartPools/interfaces/ICRPFactory.sol";
import "../smartPools/interfaces/ICRPoolProxy.sol";
import "../smartPools/interfaces/ICRPool.sol";

contract ActionManager is
    Initializable,
    AccessControlUpgradeable,
    ERC1155HolderUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Address of BFactory module.
     */
    address public bFactoryAddress;

    /**
     * @dev Address of BRegistry module.
     */
    address public bRegistryAddress;

    /**
     * @dev Address of xToken Factory module.
     */
    address public xTokenFactoryAddress;

    /**
     * @dev Address of xToken Wrapper module.
     */
    address public xTokenWrapperAddress;

    /**
     * @dev Address of authorizationProxyAddress module.
     */
    address public authorizationProxyAddress;

    /**
     * @dev Address of the default price feed.
     */
    address public defaultPriceFeedAddress;

    /**
     * @dev Address of the default price feed denomination.
     */
    address public defaultPriceFeedDenomination;

    /**
     * @dev Address of the Admin for the xToken contracts
     */
    address public xTokenAdminAddress;

    /**
     * @dev String to deploy xToken
     */
    string public constant xSPT = "xSPT";

    /**
     * @dev maxSwapFee
        Extracted from bRegistry (these values are private there)
        constan uint256 BONE = 10**18;
     */
    uint256 public constant maxSwapFee = (3 * 1e18) / 100;

    /**
     * @dev Address of the CRPFactory contract
     */
    address public crpFactoryAddress;

    /**
     * @dev Address of the CRPoolProxy contract
     */
    address public crpoolProxyAddress;

    /**
     * @dev Emitted when `bFactoryAddress` is set.
     */
    event BFactorySet(address indexed _bFactoryAddress);

    /**
     * @dev Emitted when `bRegistryAddress` is set.
     */
    event BRegistrySet(address indexed _bRegistryAddress);

    /**
     * @dev Emitted when `xTokenFactoryAddress` is set.
     */
    event XTokenFactorySet(address indexed _xTokenFactoryAddress);

    /**
     * @dev Emitted when `xTokenWrapperAddress` is set.
     */
    event XTokenWrapperSet(address indexed _xTokenWrapperAddress);

    /**
     * @dev Emitted when `authorizationProxyAddress` is set.
     */
    event AuthorizationProxySet(address indexed _authorizationProxyAddress);

    /**
     * @dev Emitted when `defaultPriceFeed` is set.
     */
    event DefaultPriceFeedSet(address indexed _priceFeedAddress);

    /**
     * @dev Emitted when `defaultPriceFeedDenomination` is set.
     */
    event DefaultPriceFeedDenominationSet(address indexed _priceFeedDenomination);

    /**
     * @dev Emitted when `xTokenAdminAddress` is set.
     */
    event XTokenAdminSet(address indexed _xTokenAdminAddress);

    /**
     * @dev Emitted when `crpFactoryAddress` is set.
     */
    event CRPFactorySet(address indexed _crpFactoryAddress);

    /**
     * @dev Emitted when `crpoolProxyAddress` is set.
     */
    event CRPoolProxySet(address indexed _crpoolProxyAddress);

    /**
     * @dev Emitted after a pool was created correctly
     */
    event PoolCreationSuccess(
        address indexed _msgSender,
        address indexed poolAndTokenAddress,
        address indexed poolXTokenAddress
    );

    /**
     * @dev Emitted after a smart pool was created correctly
     */
    event SmartPoolCreationSuccess(
        address indexed _msgSender,
        address indexed poolAndTokenAddress,
        address indexed poolXTokenAddress
    );

    /**
     * @dev Check if sender has the DEFAULT_ADMIN_ROLE role to execute a function
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        _;
    }

    /**
     * @dev Initalize the contract.
     *
     * @param _bFactoryAddress sets the bfactory address
     * @param _bRegistryAddress sets the bregistry address
     * @param _xTokenFactoryAddress sets the xTokenFactory address
     * @param _xTokenWrapperAddress sets the xTokenWrapper address
     * @param _authorizationProxyAddress sets the authotizationProxy address
     * @param _xTokenAdminAddress sets the xTokenAdminAddress (admin of the xToken contract)
     * @param _priceFeedAddress sets the default priceFeed for the pool token
     * @param _priceFeedDenomination sets the denomination for the priceFeed of the pool token
     * @param _crpFactoryAddress sets the CRPFactory address
     * @param _crpoolProxyAddress sets the CRPoolProxy address
     */
    function initialize(
        address _bFactoryAddress,
        address _bRegistryAddress,
        address _xTokenFactoryAddress,
        address _xTokenWrapperAddress,
        address _authorizationProxyAddress,
        address _xTokenAdminAddress,
        address _priceFeedAddress,
        address _priceFeedDenomination,
        address _crpFactoryAddress,
        address _crpoolProxyAddress
    ) public initializer {
        require(_xTokenAdminAddress != address(0), "_xTokenAdminAddress is zero address");
        require(_priceFeedAddress != address(0), "_priceFeedAddress is zero address");

        xTokenAdminAddress = _xTokenAdminAddress;
        defaultPriceFeedAddress = _priceFeedAddress;
        defaultPriceFeedDenomination = _priceFeedDenomination;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setBFactoryAddress(_bFactoryAddress);
        _setBRegistryAddress(_bRegistryAddress);
        _setXTokenFactoryAddress(_xTokenFactoryAddress);
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
        _setAuthorizationProxyAddress(_authorizationProxyAddress);
        _setCRPFactoryAddress(_crpFactoryAddress);
        _setCRPoolProxyAddress(_crpoolProxyAddress);
    }

    /**
     * @dev Grants DEFAULT_ADMIN_ROLE to set contract parameters.
     *
     * Requirements:
     * - the caller must have admin role.
     */
    function grantAdminRole(address newAdmin) external onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
    }

    /**
     * @dev Sets `_bFactoryAddress` as the BFactory module.
     * @param _bFactoryAddress bFactoryAddress contract
     */
    function setBFactory(address _bFactoryAddress) external onlyAdmin {
        _setBFactoryAddress(_bFactoryAddress);
    }

    /**
     * @dev Sets `_bRegistryAddress` as the RegistryContract module.
     * @param _bRegistryAddress bRegistryAddress contract
     */
    function setBRegistry(address _bRegistryAddress) external onlyAdmin {
        _setBRegistryAddress(_bRegistryAddress);
    }

    /**
     * @dev Sets `_xTokenFactoryAddress` as the xToken Factory module.
     * @param _xTokenFactoryAddress xTokenFactoryAddress contract
     */
    function setXTokenFactory(address _xTokenFactoryAddress) external onlyAdmin {
        _setXTokenFactoryAddress(_xTokenFactoryAddress);
    }

    /**
     * @dev Sets `_xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress  xTokenWrapperAddress contract
     */
    function setXTokenWrapper(address _xTokenWrapperAddress) external onlyAdmin {
        _setXTokenWrapperAddress(_xTokenWrapperAddress);
    }

    /**
     * @dev Sets `_authorizationProxyAddress` as the authorizationProxyAddress module.
     * @param _authorizationProxyAddress  authorizationProxyAddress contract
     */
    function setAuthorizationProxy(address _authorizationProxyAddress) external onlyAdmin {
        _setAuthorizationProxyAddress(_authorizationProxyAddress);
    }

    /**
     * @dev Sets `_priceFeedAddress` as the defaultPriceFeed address.
     * @param _priceFeedAddress  priceFeed address contract
     */
    function setDefaultPriceFeed(address _priceFeedAddress) external onlyAdmin {
        require(_priceFeedAddress != address(0), "_priceFeedAddress is zero address");
        emit DefaultPriceFeedSet(_priceFeedAddress);
        defaultPriceFeedAddress = _priceFeedAddress;
    }

    /**
     * @dev Sets `_priceFeedDenomination` as the defaultPriceFeedDenomination address.
     * @param _priceFeedDenomination priceFeedDenomination to use in the EurPriceFeed contract
     */
    function setDefaultPriceFeedDenomination(address _priceFeedDenomination) external onlyAdmin {
        emit DefaultPriceFeedDenominationSet(_priceFeedDenomination);
        defaultPriceFeedDenomination = _priceFeedDenomination;
    }

    /**
     * @dev Sets `_xTokenAdminAddress` as the xTokenAdmin address
     * @param _xTokenAdminAddress  xToken admin address
     */
    function setXTokenAdmin(address _xTokenAdminAddress) external onlyAdmin {
        require(_xTokenAdminAddress != address(0), "_xTokenAdminAddress is zero address");

        emit XTokenAdminSet(_xTokenAdminAddress);

        xTokenAdminAddress = _xTokenAdminAddress;
    }

    /**
     * @dev Sets `_crpFactoryAddress` as the CRPFactory module.
     * @param _crpFactoryAddress The new CRPFactory module address
     */
    function setCRPFactory(address _crpFactoryAddress) external onlyAdmin {
        _setCRPFactoryAddress(_crpFactoryAddress);
    }

    /**
     * @dev Sets `_crpoolProxyAddress` as the CRPoolProxy module.
     * @param _crpoolProxyAddress The new CRPoolProxy module address
     */
    function setCRPoolProxy(address _crpoolProxyAddress) external onlyAdmin {
        _setCRPoolProxyAddress(_crpoolProxyAddress);
    }

    /**
     * @dev Sets `bFactoryAddress` as the BFactory module.
     * @param _bFactoryAddress bFactoryAddress contract
     */
    function _setBFactoryAddress(address _bFactoryAddress) internal {
        require(_bFactoryAddress != address(0), "_bFactoryAddress is zero address");
        emit BFactorySet(_bFactoryAddress);
        bFactoryAddress = _bFactoryAddress;
    }

    /**
     * @dev Sets `bRegistryAddress` as the RegistryContract module.
     * @param _bRegistryAddress registryAddress contract
     */
    function _setBRegistryAddress(address _bRegistryAddress) internal {
        require(_bRegistryAddress != address(0), "_bRegistryAddress is zero address");
        emit BRegistrySet(_bRegistryAddress);
        bRegistryAddress = _bRegistryAddress;
    }

    /**
     * @dev Sets `xTokenFactoryAddress` as the xToken Factory module.
     * @param _xTokenFactoryAddress xTokenFactoryAddress contract
     */
    function _setXTokenFactoryAddress(address _xTokenFactoryAddress) internal {
        require(_xTokenFactoryAddress != address(0), "_xTokenFactoryAddress is zero address");
        emit XTokenFactorySet(_xTokenFactoryAddress);
        xTokenFactoryAddress = _xTokenFactoryAddress;
    }

    /**
     * @dev Sets `xTokenWrapperAddress` as the xToken Wrapper module.
     * @param _xTokenWrapperAddress The address of the new xToken Wrapper module.
     */
    function _setXTokenWrapperAddress(address _xTokenWrapperAddress) internal {
        require(_xTokenWrapperAddress != address(0), "_xTokenWrapperAddress is zero address");
        emit XTokenWrapperSet(_xTokenWrapperAddress);
        xTokenWrapperAddress = _xTokenWrapperAddress;
    }

    /**
     * @dev Sets `authorizationProxyAddress` as the authorizationProxyAddress module.
     * @param _authorizationProxyAddress The address of the new xToken Wrapper module.
     */
    function _setAuthorizationProxyAddress(address _authorizationProxyAddress) internal {
        require(_authorizationProxyAddress != address(0), "_authorizationProxyAddress is zero address");
        emit AuthorizationProxySet(_authorizationProxyAddress);
        authorizationProxyAddress = _authorizationProxyAddress;
    }

    /**
     * @dev Sets `_crpFactoryAddress` as the crpFactoryAddress module.
     * @param _crpFactoryAddress The address of the new CRPFactory module.
     */
    function _setCRPFactoryAddress(address _crpFactoryAddress) internal {
        require(_crpFactoryAddress != address(0), "_crpFactoryAddress is zero address");
        emit CRPFactorySet(_crpFactoryAddress);
        crpFactoryAddress = _crpFactoryAddress;
    }

    /**
     * @dev Sets `_crpoolProxyAddress` as the crpoolProxyAddress module.
     * @param _crpoolProxyAddress The address of the new CRPoolProxy module.
     */
    function _setCRPoolProxyAddress(address _crpoolProxyAddress) internal {
        require(_crpoolProxyAddress != address(0), "_crpoolProxyAddress is zero address");
        emit CRPoolProxySet(_crpoolProxyAddress);
        crpoolProxyAddress = _crpoolProxyAddress;
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param _tokens The address array of the tokens
     * @param _from   The address of the sender
     * @param _to The address of the receiver
     * @param _amounts The array amounts
     * @return a boolean signaling the completion of the function
     */
    function _tokenTransfer(
        address[] memory _tokens,
        address _from,
        address _to,
        uint256[] memory _amounts
    ) private returns (bool) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20Upgradeable(_tokens[i]).safeTransferFrom(_from, _to, _amounts[i]);
        }
        return true;
    }

    /**
     * @dev Makes the approve n times as tokens defined
     * @param _tokens The address array of the tokens
     * @param _spender The address of the receiver
     * @param _amounts The array amounts
     * @return a boolean signaling the completion of the function
     */
    function _approveTokenTransfer(
        address[] memory _tokens,
        address _spender,
        uint256[] memory _amounts
    ) private returns (bool) {
        bool returnedValue = false;
        for (uint256 i = 0; i < _tokens.length; i++) {
            returnedValue = IERC20Upgradeable(_tokens[i]).approve(_spender, _amounts[i]);
            require(returnedValue, "Approve failed");
        }
        return true;
    }

    /**
     * @dev Makes the wrapping of each token in the array
     * @param _tokenAddresses The address array of the tokens
     * @param _amounts The array amounts
     * @return a boolean signaling the completion of the function
     */
    function _wrapToken(address[] memory _tokenAddresses, uint256[] memory _amounts) private returns (bool) {
        bool returnedValue = false;
        IXTokenWrapper xTokenWrapperContract = IXTokenWrapper(xTokenWrapperAddress);
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            returnedValue = xTokenWrapperContract.wrap(_tokenAddresses[i], _amounts[i]);
            require(returnedValue, "Wrap failed");
        }
        return true;
    }

    /**
     * @dev Makes the actual pool creation
     * @return an IBPOOL contract to handle the pool operations
     */
    function _createNewPool() private returns (IBPool) {
        IBFactory bFactoryContract = IBFactory(bFactoryAddress);
        IBPool poolAndTokenContract = bFactoryContract.newBPool();

        // userToPool[msg.sender] = address(poolAndTokenContract);
        bool txOk = poolAndTokenContract.getController() == address(this);
        require(txOk, "pool creation failed");
        return poolAndTokenContract;
    }

    /**
     * @dev Gets the xToken address for each token
     * @param _tokenAddress The address of the tokens
     * @return an address of the xToken stored in the xTokenWrapper map
     */
    function _getXTokenAddress(address _tokenAddress) private view returns (address) {
        IXTokenWrapper xTokenWrapperContract = IXTokenWrapper(xTokenWrapperAddress);
        address xTokenAddress = xTokenWrapperContract.tokenToXToken(_tokenAddress);
        return xTokenAddress;
    }

    /**
     * @dev builds an array of the xTokens corresponding to the standrad tokens
     * @param _tokenAddresses The address array of the tokens
     * @return an address array containing all the xTokens
     */
    function _buildXTokenArray(address[] memory _tokenAddresses) private view returns (address[] memory) {
        uint256 length = _tokenAddresses.length;
        address[] memory xTokensAddresses = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            xTokensAddresses[i] = _getXTokenAddress(_tokenAddresses[i]);
        }

        require(xTokensAddresses.length == _tokenAddresses.length, "Invalid xTokenArray generated");
        return xTokensAddresses;
    }

    /**
     * @dev Binds each xToken to the pool
     * @param _xTokenAddresses The address array of the xTokens
     * @param _amounts The array amounts
     * @param _xTokensWeight The array of the weight of each token
     * @return a boolean signaling the completion of the function
     */
    function _bindXTokensToPool(
        address[] memory _xTokenAddresses,
        uint256[] memory _amounts,
        uint256[] memory _xTokensWeight,
        IBPool poolAndTokenContract
    ) private returns (bool) {
        for (uint256 i = 0; i < _xTokenAddresses.length; i++) {
            poolAndTokenContract.bind(_xTokenAddresses[i], _amounts[i], _xTokensWeight[i]);
        }
        return true;
    }

    /**
     * @dev Generates the possible combination of each pair to add it to the pool
     * @param _poolAndTokenAddress The address of the created pool/token
     * @param _xTokenAddresses The address array of the xTokens
     * @return a boolean signaling the completion of the function
     */
    function _addPoolPair(address _poolAndTokenAddress, address[] memory _xTokenAddresses) private returns (bool) {
        IBRegistry bRegistryContract = IBRegistry(bRegistryAddress);

        for (uint256 i = 0; i < _xTokenAddresses.length - 1; i++) {
            for (uint256 j = i + 1; j < _xTokenAddresses.length; j++) {
                bRegistryContract.addPoolPair(_poolAndTokenAddress, _xTokenAddresses[i], _xTokenAddresses[j]);
            }
        }
        return true;
    }

    /**
     * @dev Issues the sortPools command
     * @param _xTokenAddresses The address array of the xTokens
     * @return a boolean signaling the completion of the function
     */
    function _sortPools(address[] memory _xTokenAddresses) private returns (bool) {
        IBRegistry bRegistryContract = IBRegistry(bRegistryAddress);
        for (uint256 i = 0; i < _xTokenAddresses.length; i++) {
            bRegistryContract.sortPools(_xTokenAddresses, 10);
        }
        return true;
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param _poolContractAddress The address of the created pool/token
     * @param _poolName The name displayed on the app for the pool
     * @return an address of the new pool xToken deployed
     */
    function _deployXPoolToken(address _poolContractAddress, string memory _poolName) private returns (address) {
        IXTokenFactory xTokenFactoryContract = IXTokenFactory(xTokenFactoryAddress);
        address poolXTokenAddress = xTokenFactoryContract.deployXToken(
            _poolContractAddress,
            _poolName,
            xSPT,
            18,
            xSPT,
            authorizationProxyAddress,
            defaultPriceFeedAddress,
            defaultPriceFeedDenomination
        );

        IXToken xTokenContract = IXToken(poolXTokenAddress);
        bytes32 defaultAdminRole = 0x00;
        xTokenContract.grantRole(defaultAdminRole, xTokenAdminAddress);
        return poolXTokenAddress;
    }

    /**
     * @dev Checks the value of the swapFee to not fail later on
     * @param _swapFee The swapFee value
     */
    function _checkSwapFee(uint256 _swapFee) private pure {
        require(_swapFee > 0, "SwapFee is ZERO");

        require(_swapFee <= maxSwapFee, "SwapFee higher than bRegistry maxSwapFee");
    }

    /**
     * @dev Checks each value of the three arrays
     * @param _tokenAddresses The array for all the tokens
     * @param _amounts  The array for all the amounts
     * @param _xTokensWeight  The array for all the tokens weight
     */
    function _checkArrays(
        address[] memory _tokenAddresses,
        uint256[] memory _amounts,
        uint256[] memory _xTokensWeight
    ) private pure {
        for (uint256 i = 0; i < _tokenAddresses.length; i++) {
            require(_tokenAddresses[i] != address(0), "Invalid tokenAddresses array");
            require(_amounts[i] > 0, "Invalid amounts array");
            require(_xTokensWeight[i] > 0, "Invalid xTokensWeight array");
        }
    }

    /**
     * @dev Converts a single address to an array of one address to use the transfer and approve functions
     * @param _tokenAddress The token address to convert
     * @return an array of 1 element containing the tokenAddress
     */
    function _convertToArrayOfOneAddress(address _tokenAddress) private pure returns (address[] memory) {
        address[] memory tokenAddressArr = new address[](1);
        tokenAddressArr[0] = _tokenAddress;
        return tokenAddressArr;
    }

    /**
     * @dev Converts a single amount to an array of one amount to use the transfer and approve functions
     * @param _amount The amount to convert
     * @return an array of 1 element containing the tokenAddress
     */
    function _convertToArrayOfOneUint(uint256 _amount) private pure returns (uint256[] memory) {
        uint256[] memory amountArr = new uint256[](1);
        amountArr[0] = _amount;
        return amountArr;
    }

    function calcOutGivenIn(
        address poolAddress,
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) private view returns (uint256) {
        IBPool pool = IBPool(poolAddress);
        uint256 tokenBalanceIn = pool.getBalance(_assetIn);
        uint256 tokenBalanceOut = pool.getBalance(_assetOut);
        uint256 tokenWeightIn = pool.getDenormalizedWeight(_assetIn);
        uint256 tokenWeightOut = pool.getDenormalizedWeight(_assetOut);

        return pool.calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, _assetAmountIn, 0);
    }

    /**
     * @dev Makes the token transfer n times as tokens defined
     * @param tokenAddresses The address array of the tokens
     * @param amounts The array amounts
     * @param swapFee The swapFee value
     * @param xTokensWeight The array of the weight of each token
     * @param poolName The name displayed on the app for the pool
     * @return a boolean signaling the completion of the function
     */
    function standardPoolCreation(
        address[] memory tokenAddresses,
        uint256[] memory amounts,
        uint256 swapFee,
        uint256[] memory xTokensWeight,
        string memory poolName
    ) external nonReentrant returns (bool) {
        require(tokenAddresses.length == amounts.length, "Different tknAddress-amounts length");
        require(tokenAddresses.length == xTokensWeight.length, "Different tknAddress-xtknWeight length");
        require(bytes(poolName).length > 3, "Invalid PoolName provided"); // 3 chars pool name ?
        require(defaultPriceFeedAddress != address(0), "defaultPriceFeedAddress is NOT SET");
        require(xTokenAdminAddress != address(0), "xTokenAdminAddress is NOT SET");

        _checkSwapFee(swapFee);
        _checkArrays(tokenAddresses, amounts, xTokensWeight);

        bool txOk = false;

        txOk = _tokenTransfer(tokenAddresses, _msgSender(), address(this), amounts);
        require(txOk, "Transfer 01 - failed");

        _approveTokenTransfer(tokenAddresses, xTokenWrapperAddress, amounts);

        _wrapToken(tokenAddresses, amounts);

        IBPool poolAndTokenContract = _createNewPool();
        poolAndTokenContract.setSwapFee(swapFee);
        address poolAndTokenAddress = address(poolAndTokenContract);

        address[] memory xTokenAddresses = _buildXTokenArray(tokenAddresses);

        _approveTokenTransfer(xTokenAddresses, poolAndTokenAddress, amounts);

        txOk = _bindXTokensToPool(xTokenAddresses, amounts, xTokensWeight, poolAndTokenContract);
        require(txOk, "bind tkns failed");

        poolAndTokenContract.finalize();

        txOk = _addPoolPair(poolAndTokenAddress, xTokenAddresses);
        require(txOk, "addPoolPair failed");

        txOk = _sortPools(xTokenAddresses);
        require(txOk, "sortPools failed");

        address poolXTokenAddress = _deployXPoolToken(poolAndTokenAddress, poolName);
        require(txOk, "deployXPoolToken failed");

        address[] memory poolAndTokenAddressArr = _convertToArrayOfOneAddress(poolAndTokenAddress);
        address[] memory poolXTokenAddressArr = _convertToArrayOfOneAddress(poolXTokenAddress);

        uint256 balanceToken = poolAndTokenContract.balanceOf(address(this));
        uint256[] memory balancePoolTokenArr = _convertToArrayOfOneUint(balanceToken);

        _approveTokenTransfer(poolAndTokenAddressArr, xTokenWrapperAddress, balancePoolTokenArr);
        _wrapToken(poolAndTokenAddressArr, balancePoolTokenArr);

        balanceToken = IERC20Upgradeable(poolXTokenAddress).balanceOf(address(this));
        uint256[] memory balanceXPoolTokenArr = _convertToArrayOfOneUint(balanceToken);

        _approveTokenTransfer(poolXTokenAddressArr, address(this), balanceXPoolTokenArr);

        txOk = _tokenTransfer(poolXTokenAddressArr, address(this), _msgSender(), balanceXPoolTokenArr);
        require(txOk, "Transfer 02 - failed");

        emit PoolCreationSuccess(_msgSender(), poolAndTokenAddress, poolXTokenAddress);

        return true;
    }

    /**
     * @param _poolParams The smart pool parameters
     * @param _rights The smart pool rights
     * @param _initialSupply The smart pool token initial supply
     * @param _minimumWeightChangeBlockPeriod The smart pool minimum weight change block period
     * @param _addTokenTimeLockInBlocks The smart pool add token time lock in blocks
     * @return a boolean signaling the completion of the function
     */
    function smartPoolCreation(
        PoolParams calldata _poolParams,
        RightsManager.Rights calldata _rights,
        uint256 _initialSupply,
        uint256 _minimumWeightChangeBlockPeriod,
        uint256 _addTokenTimeLockInBlocks
    ) external nonReentrant returns (bool) {
        // Compute constituent xToken addresses
        address[] memory xTokenAddresses = _buildXTokenArray(_poolParams.constituentTokens);

        // Setup the new CRPool
        address crpoolAddress = address(
            ICRPFactory(crpFactoryAddress).newCrp(
                bFactoryAddress,
                PoolParams(
                    _poolParams.poolTokenSymbol,
                    _poolParams.poolTokenName,
                    xTokenAddresses,
                    _poolParams.tokenBalances,
                    _poolParams.tokenWeights,
                    _poolParams.swapFee
                ),
                _rights
            )
        );

        // Create the CRPool xToken
        address crpoolXTokenAddress = _deployXPoolToken(crpoolAddress, _poolParams.poolTokenName);

        // Grab the tokens from the sender
        _tokenTransfer(_poolParams.constituentTokens, _msgSender(), address(this), _poolParams.tokenBalances);

        // Wrap the tokens into xTokens for the pool
        _approveTokenTransfer(_poolParams.constituentTokens, xTokenWrapperAddress, _poolParams.tokenBalances);
        _wrapToken(_poolParams.constituentTokens, _poolParams.tokenBalances);

        // Approve the CRPoolProxy to use the xTokens for the pool
        _approveTokenTransfer(xTokenAddresses, crpoolProxyAddress, _poolParams.tokenBalances);

        // Create the CRPool
        ICRPoolProxy(crpoolProxyAddress).createPool(
            crpoolAddress,
            _initialSupply,
            _minimumWeightChangeBlockPeriod,
            _addTokenTimeLockInBlocks
        );

        // Register on the BRegistry
        _addPoolPair(address(ICRPool(crpoolAddress).bPool()), xTokenAddresses);
        _sortPools(xTokenAddresses);

        // Send the xLPT tokens from pool creation to the sender
        uint256 crpoolXTokenBalance = IERC20Upgradeable(crpoolXTokenAddress).balanceOf(address(this));
        IERC20Upgradeable(crpoolXTokenAddress).safeTransferFrom(address(this), _msgSender(), crpoolXTokenBalance);

        emit SmartPoolCreationSuccess(_msgSender(), crpoolAddress, crpoolXTokenAddress);

        return true;
    }

    /**
     * @param _poolParams The smart pool parameters
     * @param _rights The smart pool rights
     * @param _initialSupply The smart pool token initial supply
     * @return a boolean signaling the completion of the function
     */
    function smartPoolCreation(
        PoolParams calldata _poolParams,
        RightsManager.Rights calldata _rights,
        uint256 _initialSupply
    ) external nonReentrant returns (bool) {
        // Compute constituent xToken addresses
        address[] memory xTokenAddresses = _buildXTokenArray(_poolParams.constituentTokens);

        // Setup the new CRPool
        address crpoolAddress = address(
            ICRPFactory(crpFactoryAddress).newCrp(
                bFactoryAddress,
                PoolParams(
                    _poolParams.poolTokenSymbol,
                    _poolParams.poolTokenName,
                    xTokenAddresses,
                    _poolParams.tokenBalances,
                    _poolParams.tokenWeights,
                    _poolParams.swapFee
                ),
                _rights
            )
        );

        // Create the CRPool xToken
        address crpoolXTokenAddress = _deployXPoolToken(crpoolAddress, _poolParams.poolTokenName);

        // Grab the tokens from the sender
        _tokenTransfer(_poolParams.constituentTokens, _msgSender(), address(this), _poolParams.tokenBalances);

        // Wrap the tokens into xTokens for the pool
        _approveTokenTransfer(_poolParams.constituentTokens, xTokenWrapperAddress, _poolParams.tokenBalances);
        _wrapToken(_poolParams.constituentTokens, _poolParams.tokenBalances);

        // Approve the CRPoolProxy to use the xTokens for the pool
        _approveTokenTransfer(xTokenAddresses, crpoolProxyAddress, _poolParams.tokenBalances);

        // Create the CRPool
        ICRPoolProxy(crpoolProxyAddress).createPool(crpoolAddress, _initialSupply);

        // Register on the BRegistry
        _addPoolPair(address(ICRPool(crpoolAddress).bPool()), xTokenAddresses);
        _sortPools(xTokenAddresses);

        // Send the xLPT tokens from pool creation to the sender
        uint256 crpoolXTokenBalance = IERC20Upgradeable(crpoolXTokenAddress).balanceOf(address(this));
        IERC20Upgradeable(crpoolXTokenAddress).safeTransfer(_msgSender(), crpoolXTokenBalance);

        emit SmartPoolCreationSuccess(_msgSender(), crpoolAddress, crpoolXTokenAddress);

        return true;
    }

    function getAvgAmountFromPools(
        address _assetIn,
        address _assetOut,
        uint256 _assetAmountIn
    ) external view returns (uint256) {
        IBRegistry bRegistryContract = IBRegistry(bRegistryAddress);
        address[] memory poolAddresses = bRegistryContract.getBestPoolsWithLimit(_assetIn, _assetOut, 10);

        uint256 totalAmount;
        for (uint256 i = 0; i < poolAddresses.length; i++) {
            totalAmount += calcOutGivenIn(poolAddresses[i], _assetIn, _assetOut, _assetAmountIn);
        }

        uint256 returnValue = 0;
        if (poolAddresses.length > 0 && totalAmount > 0 && totalAmount > poolAddresses.length) {
            returnValue = totalAmount / poolAddresses.length;
        }
        return returnValue;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

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
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @title IXTokenWrapper
 * @author Protofire
 * @dev XTokenWrapper Interface.
 *
 */
interface IXTokenWrapper is IERC1155Receiver {
    /**
     * @dev Token to xToken registry.
     */
    function tokenToXToken(address _token) external view returns (address);

    /**
     * @dev xToken to Token registry.
     */
    function xTokenToToken(address _xToken) external view returns (address);

    /**
     * @dev Wraps `_token` into its associated xToken.
     *
     */
    function wrap(address _token, uint256 _amount) external payable returns (bool);

    /**
     * @dev Unwraps `_xToken`.
     *
     */
    function unwrap(address _xToken, uint256 _amount) external returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "./IBPool.sol";

interface IBFactory {
    event LOG_NEW_POOL(address indexed caller, address indexed pool);

    function isBPool(address b) external view returns (bool);

    function newBPool() external returns (IBPool);

    function setExchProxy(address exchProxy) external;

    function setOperationsRegistry(address operationsRegistry) external;

    function setPermissionManager(address permissionManager) external;

    function setAuthorization(address _authorization) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IBPool
 * @author Protofire
 * @dev Balancer BPool contract interface.
 *
 */
interface IBPool is IERC20 {
    // solhint-disable-next-line func-name-mixedcase
    function EXIT_FEE() external view returns (uint256);

    function isPublicSwap() external view returns (bool);

    function isFinalized() external view returns (bool);

    function isBound(address t) external view returns (bool);

    function getNumTokens() external view returns (uint256);

    function getCurrentTokens() external view returns (address[] memory tokens);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getNormalizedWeight(address token) external view returns (uint256);

    function getBalance(address token) external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function getController() external view returns (address);

    function setSwapFee(uint256 swapFee) external;

    function setController(address manager) external;

    function setPublicSwap(bool public_) external;

    function finalize() external;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external;

    function unbind(address token) external;

    function gulp(address token) external;

    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function getSpotPriceSansFee(address tokenIn, address tokenOut) external view returns (uint256 spotPrice);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;

    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external returns (uint256 poolAmountOut);

    function joinswapPoolAmountOut(
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external returns (uint256 tokenAmountIn);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external returns (uint256 tokenAmountOut);

    function exitswapExternAmountOut(
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external returns (uint256 poolAmountIn);

    function calcSpotPrice(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 swapFee
    ) external pure returns (uint256 spotPrice);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleInGivenPoolOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountIn);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountIn);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IBRegistry
 * @author Protofire
 * @dev Balancer BRegistry contract interface.
 *
 */

interface IBRegistry {
    function getBestPoolsWithLimit(
        address,
        address,
        uint256
    ) external view returns (address[] memory);

    function addPoolPair(
        address,
        address,
        address
    ) external returns (uint256);

    function sortPools(address[] calldata, uint256) external;

    function sortPoolsWithPurge(address[] calldata, uint256) external;
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IXTokenFactory
 * @author Protofire
 * @dev IXTokenFactory Interface.
 *
 */
interface IXTokenFactory {
    /**
     * @dev deployXToken contract
     */
    function deployXToken(
        address,
        string memory,
        string memory,
        uint8,
        string memory,
        address,
        address,
        address
    ) external returns (address);
}

//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IXToken
 * @author Protofire
 * @dev XToken Interface.
 *
 */
interface IXToken is IERC20 {
    /**
     * @dev Triggers stopped state.
     *
     */
    function pause() external;

    /**
     * @dev Returns to normal state.
     */
    function unpause() external;

    /**
     * @dev Sets authorization.
     *
     */
    function setAuthorization(address authorization_) external;

    /**
     * @dev Sets operationsRegistry.
     *
     */
    function setOperationsRegistry(address operationsRegistry_) external;

    /**
     * @dev Sets kya.
     *
     */
    function setKya(string memory kya_) external;

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     */
    function mint(address account, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @dev Grant role to the specified account
     *
     */
    function grantRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

import "../libraries/RightsManager.sol";

import "../CRPoolExtend.sol";

import "./IPoolParams.sol";

interface ICRPFactory {
    function isCrp(address _address) external view returns (bool);

    function newCrp(
        address _bFactoryAddress,
        PoolParams calldata _poolParams,
        RightsManager.Rights calldata _rights
    ) external returns (CRPoolExtend);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

interface ICRPoolProxy {
    function createPool(
        address _pool,
        uint256 _initialSupply,
        uint256 _minimumWeightChangeBlockPeriodParam,
        uint256 _addTokenTimeLockInBlocksParam
    ) external;

    function createPool(address _pool, uint256 _initialSupply) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IBPool.sol";

import "../libraries/SmartPoolManager.sol";

interface ICRPool is IERC20 {
    function bPool() external view returns (IBPool);

    function initialTokens() external view returns (address[] calldata);

    function initialBalances() external view returns (uint256[] calldata);

    function newToken() external view returns (SmartPoolManager.NewTokenParams calldata);

    function getDenormalizedWeight(address token) external view returns (uint256);

    function createPool(
        uint256 _initialSupply,
        uint256 _minimumWeightChangeBlockPeriodParam,
        uint256 _addTokenTimeLockInBlocksParam
    ) external;

    function createPool(uint256 _initialSupply) external;

    function updateWeight(address _token, uint256 _newWeight) external;

    function commitAddToken(
        address _token,
        uint256 _balance,
        uint256 _denormalizedWeight
    ) external;

    function applyAddToken() external;

    function removeToken(address _token) external;

    function joinPool(uint256 _poolAmountOut, uint256[] calldata _maxAmountsIn) external;

    function exitPool(uint256 _poolAmountIn, uint256[] calldata _minAmountsOut) external;

    function joinswapExternAmountIn(
        address _tokenIn,
        uint256 _tokenAmountIn,
        uint256 _minPoolAmountOut
    ) external returns (uint256 _poolAmountOut);

    function joinswapPoolAmountOut(
        address _tokenIn,
        uint256 _poolAmountOut,
        uint256 _maxAmountIn
    ) external returns (uint256 _tokenAmountIn);

    function exitswapPoolAmountIn(
        address _tokenOut,
        uint256 _poolAmountIn,
        uint256 _minAmountOut
    ) external returns (uint256 _tokenAmountOut);

    function exitswapExternAmountOut(
        address _tokenOut,
        uint256 _tokenAmountOut,
        uint256 _maxPoolAmountIn
    ) external returns (uint256 _poolAmountIn);

    // Ownable contract
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

import "./IERC1155ReceiverUpgradeable.sol";
import "../../introspection/ERC165Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
        _registerInterface(
            ERC1155ReceiverUpgradeable(address(0)).onERC1155Received.selector ^
            ERC1155ReceiverUpgradeable(address(0)).onERC1155BatchReceived.selector
        );
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165Upgradeable.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

/**
 * @author Balancer Labs
 * @title Manage Configurable Rights for the smart pool
 *      canPauseSwapping - can setPublicSwap back to false after turning it on
 *                         by default, it is off on initialization and can only be turned on
 *      canChangeSwapFee - can setSwapFee after initialization (by default, it is fixed at create time)
 *      canChangeWeights - can bind new token weights (allowed by default in base pool)
 *      canAddRemoveTokens - can bind/unbind tokens (allowed by default in base pool)
 *      canWhitelistLPs - can limit liquidity providers to a given set of addresses
 *      canChangeCap - can change the BSP cap (max # of pool tokens)
 */
library RightsManager {
    // Type declarations

    enum Permissions {
        PAUSE_SWAPPING,
        CHANGE_SWAP_FEE,
        CHANGE_WEIGHTS,
        ADD_REMOVE_TOKENS,
        WHITELIST_LPS,
        CHANGE_CAP
    }

    struct Rights {
        bool canPauseSwapping;
        bool canChangeSwapFee;
        bool canChangeWeights;
        bool canAddRemoveTokens;
        bool canWhitelistLPs;
        bool canChangeCap;
    }

    // State variables (can only be constants in a library)
    bool public constant DEFAULT_CAN_PAUSE_SWAPPING = false;
    bool public constant DEFAULT_CAN_CHANGE_SWAP_FEE = true;
    bool public constant DEFAULT_CAN_CHANGE_WEIGHTS = true;
    bool public constant DEFAULT_CAN_ADD_REMOVE_TOKENS = false;
    bool public constant DEFAULT_CAN_WHITELIST_LPS = false;
    bool public constant DEFAULT_CAN_CHANGE_CAP = false;

    // Functions

    /**
     * @notice create a struct from an array (or return defaults)
     * @dev If you pass an empty array, it will construct it using the defaults
     * @param a - array input
     * @return Rights struct
     */
    function constructRights(bool[] calldata a) external pure returns (Rights memory) {
        if (a.length == 0) {
            return
                Rights(
                    DEFAULT_CAN_PAUSE_SWAPPING,
                    DEFAULT_CAN_CHANGE_SWAP_FEE,
                    DEFAULT_CAN_CHANGE_WEIGHTS,
                    DEFAULT_CAN_ADD_REMOVE_TOKENS,
                    DEFAULT_CAN_WHITELIST_LPS,
                    DEFAULT_CAN_CHANGE_CAP
                );
        } else {
            return Rights(a[0], a[1], a[2], a[3], a[4], a[5]);
        }
    }

    /**
     * @notice Convert rights struct to an array (e.g., for events, GUI)
     * @dev avoids multiple calls to hasPermission
     * @param rights - the rights struct to convert
     * @return boolean array containing the rights settings
     */
    function convertRights(Rights calldata rights) external pure returns (bool[] memory) {
        bool[] memory result = new bool[](6);

        result[0] = rights.canPauseSwapping;
        result[1] = rights.canChangeSwapFee;
        result[2] = rights.canChangeWeights;
        result[3] = rights.canAddRemoveTokens;
        result[4] = rights.canWhitelistLPs;
        result[5] = rights.canChangeCap;

        return result;
    }

    // Though it is actually simple, the number of branches triggers code-complexity
    /* solhint-disable code-complexity */

    /**
     * @notice Externally check permissions using the Enum
     * @param self - Rights struct containing the permissions
     * @param permission - The permission to check
     * @return Boolean true if it has the permission
     */
    function hasPermission(Rights calldata self, Permissions permission) external pure returns (bool) {
        if (Permissions.PAUSE_SWAPPING == permission) {
            return self.canPauseSwapping;
        } else if (Permissions.CHANGE_SWAP_FEE == permission) {
            return self.canChangeSwapFee;
        } else if (Permissions.CHANGE_WEIGHTS == permission) {
            return self.canChangeWeights;
        } else if (Permissions.ADD_REMOVE_TOKENS == permission) {
            return self.canAddRemoveTokens;
        } else if (Permissions.WHITELIST_LPS == permission) {
            return self.canWhitelistLPs;
        } else if (Permissions.CHANGE_CAP == permission) {
            return self.canChangeCap;
        }

        require(false, "PERMISSION_UNKNOWN");

        // At this point we should have reverted already
        return false;
    }

    /* solhint-enable code-complexity */
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";

import "./interfaces/ICRPool.sol";

contract CRPoolExtend is Proxy, ERC1155Holder {
    address public immutable implementation;
    address public immutable exchangeProxy;

    constructor(
        address _crpoolProxyImplementation,
        address _exchangeProxy,
        bytes memory _data
    ) {
        implementation = _crpoolProxyImplementation;
        exchangeProxy = _exchangeProxy;

        if (_data.length > 0) {
            Address.functionDelegateCall(_crpoolProxyImplementation, _data);
        }
    }

    function _implementation() internal view override returns (address) {
        return implementation;
    }

    function _beforeFallback() internal view override {
        _onlyExchangeProxy();
    }

    function _onlyExchangeProxy() internal view {
        if (
            // createPool signature has to be written manually because of the overload
            // See: https://github.com/ethereum/solidity/issues/3556
            msg.sig == bytes4(keccak256("createPool(uint256,uint256,uint256)")) ||
            msg.sig == bytes4(keccak256("createPool(uint256)")) ||
            msg.sig == ICRPool.updateWeight.selector ||
            msg.sig == ICRPool.applyAddToken.selector ||
            msg.sig == ICRPool.removeToken.selector ||
            msg.sig == ICRPool.joinPool.selector ||
            msg.sig == ICRPool.exitPool.selector ||
            msg.sig == ICRPool.joinswapExternAmountIn.selector ||
            msg.sig == ICRPool.joinswapPoolAmountOut.selector ||
            msg.sig == ICRPool.exitswapPoolAmountIn.selector ||
            msg.sig == ICRPool.exitswapExternAmountOut.selector
        ) {
            require(msg.sender == exchangeProxy, "ERR_NOT_EXCHANGE_PROXY");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

// Needed to handle structures externally
pragma experimental ABIEncoderV2;

struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint256[] tokenBalances;
    uint256[] tokenWeights;
    uint256 swapFee;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.7.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Needed to pass in structs
pragma experimental ABIEncoderV2;

// Imports
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../interfaces/IBPool.sol";

import "../interfaces/IConfigurableRightsPool.sol";

import "./BalancerSafeMath.sol";
import "./SafeApprove.sol";

/**
 * @author Balancer Labs
 * @title Factor out the weight updates
 */
library SmartPoolManager {
    // Type declarations

    struct NewTokenParams {
        address addr;
        bool isCommitted;
        uint256 commitBlock;
        uint256 denorm;
        uint256 balance;
    }

    // For blockwise, automated weight updates
    // Move weights linearly from startWeights to endWeights,
    // between startBlock and endBlock
    struct GradualUpdateParams {
        uint256 startBlock;
        uint256 endBlock;
        uint256[] startWeights;
        uint256[] endWeights;
    }

    // updateWeight and pokeWeights are unavoidably long
    /* solhint-disable function-max-lines */

    /**
     * @notice Update the weight of an existing token
     * @dev Refactored to library to make CRPFactory deployable
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to be reweighted
     * @param newWeight - new weight of the token
     */
    function updateWeight(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token,
        uint256 newWeight
    ) external {
        require(newWeight >= BalancerConstants.MIN_WEIGHT, "ERR_MIN_WEIGHT");
        require(newWeight <= BalancerConstants.MAX_WEIGHT, "ERR_MAX_WEIGHT");

        uint256 currentWeight = bPool.getDenormalizedWeight(token);
        // Save gas; return immediately on NOOP
        if (currentWeight == newWeight) {
            return;
        }

        uint256 currentBalance = bPool.getBalance(token);
        uint256 totalSupply = self.totalSupply();
        uint256 totalWeight = bPool.getTotalDenormalizedWeight();
        uint256 poolShares;
        uint256 deltaBalance;
        uint256 deltaWeight;
        uint256 newBalance;

        if (newWeight < currentWeight) {
            // This means the controller will withdraw tokens to keep price
            // So they need to redeem PCTokens
            deltaWeight = BalancerSafeMath.bsub(currentWeight, newWeight);

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = BalancerSafeMath.bmul(totalSupply, BalancerSafeMath.bdiv(deltaWeight, totalWeight));

            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = BalancerSafeMath.bmul(currentBalance, BalancerSafeMath.bdiv(deltaWeight, currentWeight));

            // New balance cannot be lower than MIN_BALANCE
            newBalance = BalancerSafeMath.bsub(currentBalance, deltaBalance);

            require(newBalance >= BalancerConstants.MIN_BALANCE, "ERR_MIN_BALANCE");

            // First get the tokens from this contract (Pool Controller) to msg.sender
            bPool.rebind(token, newBalance, newWeight);

            // Now with the tokens this contract can send them to msg.sender
            bool xfer = IERC20(token).transfer(msg.sender, deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            self.pullPoolShareFromLib(msg.sender, poolShares);
            self.burnPoolShareFromLib(poolShares);
        } else {
            // This means the controller will deposit tokens to keep the price.
            // They will be minted and given PCTokens
            deltaWeight = BalancerSafeMath.bsub(newWeight, currentWeight);

            require(
                BalancerSafeMath.badd(totalWeight, deltaWeight) <= BalancerConstants.MAX_TOTAL_WEIGHT,
                "ERR_MAX_TOTAL_WEIGHT"
            );

            // poolShares = totalSupply * (deltaWeight / totalWeight)
            poolShares = BalancerSafeMath.bmul(totalSupply, BalancerSafeMath.bdiv(deltaWeight, totalWeight));
            // deltaBalance = currentBalance * (deltaWeight / currentWeight)
            deltaBalance = BalancerSafeMath.bmul(currentBalance, BalancerSafeMath.bdiv(deltaWeight, currentWeight));

            // First gets the tokens from msg.sender to this contract (Pool Controller)
            bool xfer = IERC20(token).transferFrom(msg.sender, address(this), deltaBalance);
            require(xfer, "ERR_ERC20_FALSE");

            // Now with the tokens this contract can bind them to the pool it controls
            bPool.rebind(token, BalancerSafeMath.badd(currentBalance, deltaBalance), newWeight);

            self.mintPoolShareFromLib(poolShares);
            self.pushPoolShareFromLib(msg.sender, poolShares);
        }
    }

    /**
     * @notice External function called to make the contract update weights according to plan
     * @param bPool - Core BPool the CRP is wrapping
     * @param gradualUpdate - gradual update parameters from the CRP
     */
    function pokeWeights(IBPool bPool, GradualUpdateParams storage gradualUpdate) external {
        // Do nothing if we call this when there is no update plan
        if (gradualUpdate.startBlock == 0) {
            return;
        }

        // Error to call it before the start of the plan
        require(block.number >= gradualUpdate.startBlock, "ERR_CANT_POKE_YET");
        // Proposed error message improvement
        // require(block.number >= startBlock, "ERR_NO_HOKEY_POKEY");

        // This allows for pokes after endBlock that get weights to endWeights
        // Get the current block (or the endBlock, if we're already past the end)
        uint256 currentBlock;
        if (block.number > gradualUpdate.endBlock) {
            currentBlock = gradualUpdate.endBlock;
        } else {
            currentBlock = block.number;
        }

        uint256 blockPeriod = BalancerSafeMath.bsub(gradualUpdate.endBlock, gradualUpdate.startBlock);
        uint256 blocksElapsed = BalancerSafeMath.bsub(currentBlock, gradualUpdate.startBlock);
        uint256 weightDelta;
        uint256 deltaPerBlock;
        uint256 newWeight;

        address[] memory tokens = bPool.getCurrentTokens();

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            // Make sure it does nothing if the new and old weights are the same (saves gas)
            // It's a degenerate case if they're *all* the same, but you certainly could have
            // a plan where you only change some of the weights in the set
            if (gradualUpdate.startWeights[i] != gradualUpdate.endWeights[i]) {
                if (gradualUpdate.endWeights[i] < gradualUpdate.startWeights[i]) {
                    // We are decreasing the weight

                    // First get the total weight delta
                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.startWeights[i], gradualUpdate.endWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight - (blocksElapsed * deltaPerBlock)
                    newWeight = BalancerSafeMath.bsub(
                        gradualUpdate.startWeights[i],
                        BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock)
                    );
                } else {
                    // We are increasing the weight

                    // First get the total weight delta
                    weightDelta = BalancerSafeMath.bsub(gradualUpdate.endWeights[i], gradualUpdate.startWeights[i]);
                    // And the amount it should change per block = total change/number of blocks in the period
                    deltaPerBlock = BalancerSafeMath.bdiv(weightDelta, blockPeriod);
                    //deltaPerBlock = bdivx(weightDelta, blockPeriod);

                    // newWeight = startWeight + (blocksElapsed * deltaPerBlock)
                    newWeight = BalancerSafeMath.badd(
                        gradualUpdate.startWeights[i],
                        BalancerSafeMath.bmul(blocksElapsed, deltaPerBlock)
                    );
                }

                uint256 bal = bPool.getBalance(tokens[i]);

                bPool.rebind(tokens[i], bal, newWeight);
            }
        }

        // Reset to allow add/remove tokens, or manual weight updates
        if (block.number >= gradualUpdate.endBlock) {
            gradualUpdate.startBlock = 0;
        }
    }

    /* solhint-enable function-max-lines */

    /**
     * @notice Schedule (commit) a token to be added; must call applyAddToken after a fixed
     *         number of blocks to actually add the token
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - the token to be added
     * @param balance - how much to be added
     * @param denormalizedWeight - the desired token weight
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function commitAddToken(
        IBPool bPool,
        address token,
        uint256 balance,
        uint256 denormalizedWeight,
        NewTokenParams storage newToken
    ) external {
        require(!bPool.isBound(token), "ERR_IS_BOUND");

        require(denormalizedWeight <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
        require(denormalizedWeight >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");
        require(
            BalancerSafeMath.badd(bPool.getTotalDenormalizedWeight(), denormalizedWeight) <=
                BalancerConstants.MAX_TOTAL_WEIGHT,
            "ERR_MAX_TOTAL_WEIGHT"
        );
        require(balance >= BalancerConstants.MIN_BALANCE, "ERR_BALANCE_BELOW_MIN");

        newToken.addr = token;
        newToken.balance = balance;
        newToken.denorm = denormalizedWeight;
        newToken.commitBlock = block.number;
        newToken.isCommitted = true;
    }

    /**
     * @notice Add the token previously committed (in commitAddToken) to the pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param addTokenTimeLockInBlocks -  Wait time between committing and applying a new token
     * @param newToken - NewTokenParams struct used to hold the token data (in CRP storage)
     */
    function applyAddToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 addTokenTimeLockInBlocks,
        NewTokenParams storage newToken
    ) external {
        require(newToken.isCommitted, "ERR_NO_TOKEN_COMMIT");
        require(
            BalancerSafeMath.bsub(block.number, newToken.commitBlock) >= addTokenTimeLockInBlocks,
            "ERR_TIMELOCK_STILL_COUNTING"
        );

        uint256 totalSupply = self.totalSupply();

        // poolShares = totalSupply * newTokenWeight / totalWeight
        uint256 poolShares = BalancerSafeMath.bdiv(
            BalancerSafeMath.bmul(totalSupply, newToken.denorm),
            bPool.getTotalDenormalizedWeight()
        );

        // Clear this to allow adding more tokens
        newToken.isCommitted = false;

        // First gets the tokens from msg.sender to this contract (Pool Controller)
        bool returnValue = IERC20(newToken.addr).transferFrom(self.owner(), address(self), newToken.balance);
        require(returnValue, "ERR_ERC20_FALSE");

        // Now with the tokens this contract can bind them to the pool it controls
        // Approves bPool to pull from this controller
        // Approve unlimited, same as when creating the pool, so they can join pools later
        returnValue = SafeApprove.safeApprove(IERC20(newToken.addr), address(bPool), BalancerConstants.MAX_UINT);
        require(returnValue, "ERR_ERC20_FALSE");

        bPool.bind(newToken.addr, newToken.balance, newToken.denorm);

        self.mintPoolShareFromLib(poolShares);
        self.pushPoolShareFromLib(msg.sender, poolShares);
    }

    /**
     * @notice Remove a token from the pool
     * @dev Logic in the CRP controls when ths can be called. There are two related permissions:
     *      AddRemoveTokens - which allows removing down to the underlying BPool limit of two
     *      RemoveAllTokens - which allows completely draining the pool by removing all tokens
     *                        This can result in a non-viable pool with 0 or 1 tokens (by design),
     *                        meaning all swapping or binding operations would fail in this state
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param token - token to remove
     */
    function removeToken(
        IConfigurableRightsPool self,
        IBPool bPool,
        address token
    ) external {
        uint256 totalSupply = self.totalSupply();

        // poolShares = totalSupply * tokenWeight / totalWeight
        uint256 poolShares = BalancerSafeMath.bdiv(
            BalancerSafeMath.bmul(totalSupply, bPool.getDenormalizedWeight(token)),
            bPool.getTotalDenormalizedWeight()
        );

        // this is what will be unbound from the pool
        // Have to get it before unbinding
        uint256 balance = bPool.getBalance(token);

        // Unbind and get the tokens out of balancer pool
        bPool.unbind(token);

        // Now with the tokens this contract can send them to msg.sender
        bool xfer = IERC20(token).transfer(self.owner(), balance);
        require(xfer, "ERR_ERC20_FALSE");

        self.pullPoolShareFromLib(self.owner(), poolShares);
        self.burnPoolShareFromLib(poolShares);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid
     * @param token - The prospective token to verify
     */
    function verifyTokenCompliance(address token) external {
        verifyTokenComplianceInternal(token);
    }

    /**
     * @notice Non ERC20-conforming tokens are problematic; don't allow them in pools
     * @dev Will revert if invalid - overloaded to save space in the main contract
     * @param tokens - The prospective tokens to verify
     */
    function verifyTokenCompliance(address[] calldata tokens) external {
        for (uint256 i = 0; i < tokens.length; i++) {
            verifyTokenComplianceInternal(tokens[i]);
        }
    }

    /**
     * @notice Update weights in a predetermined way, between startBlock and endBlock,
     *         through external cals to pokeWeights
     * @param bPool - Core BPool the CRP is wrapping
     * @param newWeights - final weights we want to get to
     * @param startBlock - when weights should start to change
     * @param endBlock - when weights will be at their final values
     * @param minimumWeightChangeBlockPeriod - needed to validate the block period
     */
    function updateWeightsGradually(
        IBPool bPool,
        GradualUpdateParams storage gradualUpdate,
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock,
        uint256 minimumWeightChangeBlockPeriod
    ) external {
        require(block.number < endBlock, "ERR_GRADUAL_UPDATE_TIME_TRAVEL");

        if (block.number > startBlock) {
            // This means the weight update should start ASAP
            // Moving the start block up prevents a big jump/discontinuity in the weights
            gradualUpdate.startBlock = block.number;
        } else {
            gradualUpdate.startBlock = startBlock;
        }

        // Enforce a minimum time over which to make the changes
        // The also prevents endBlock <= startBlock
        require(
            BalancerSafeMath.bsub(endBlock, gradualUpdate.startBlock) >= minimumWeightChangeBlockPeriod,
            "ERR_WEIGHT_CHANGE_TIME_BELOW_MIN"
        );

        address[] memory tokens = bPool.getCurrentTokens();

        // Must specify weights for all tokens
        require(newWeights.length == tokens.length, "ERR_START_WEIGHTS_MISMATCH");

        uint256 weightsSum = 0;
        gradualUpdate.startWeights = new uint256[](tokens.length);

        // Check that endWeights are valid now to avoid reverting in a future pokeWeights call
        //
        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            require(newWeights[i] <= BalancerConstants.MAX_WEIGHT, "ERR_WEIGHT_ABOVE_MAX");
            require(newWeights[i] >= BalancerConstants.MIN_WEIGHT, "ERR_WEIGHT_BELOW_MIN");

            weightsSum = BalancerSafeMath.badd(weightsSum, newWeights[i]);
            gradualUpdate.startWeights[i] = bPool.getDenormalizedWeight(tokens[i]);
        }
        require(weightsSum <= BalancerConstants.MAX_TOTAL_WEIGHT, "ERR_MAX_TOTAL_WEIGHT");

        gradualUpdate.endBlock = endBlock;
        gradualUpdate.endWeights = newWeights;
    }

    /**
     * @notice Join a pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountOut - number of pool tokens to receive
     * @param maxAmountsIn - Max amount of asset tokens to spend
     * @return actualAmountsIn - calculated values of the tokens to pull in
     */
    function joinPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external view returns (uint256[] memory actualAmountsIn) {
        address[] memory tokens = bPool.getCurrentTokens();

        require(maxAmountsIn.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = self.totalSupply();
        // Subtract  1 to ensure any rounding errors favor the pool
        uint256 ratio = BalancerSafeMath.bdiv(poolAmountOut, BalancerSafeMath.bsub(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        // We know the length of the array; initialize it, and fill it below
        // Cannot do "push" in memory
        actualAmountsIn = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Add 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountIn = BalancerSafeMath.bmul(ratio, BalancerSafeMath.badd(bal, 1));

            require(tokenAmountIn != 0, "ERR_MATH_APPROX");
            require(tokenAmountIn <= maxAmountsIn[i], "ERR_LIMIT_IN");

            actualAmountsIn[i] = tokenAmountIn;
        }
    }

    /**
     * @notice Exit a pool - redeem pool tokens for underlying assets
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountsOut - minimum amount of asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return pAiAfterExitFee - final amount in (after accounting for exit fee)
     * @return actualAmountsOut - calculated amounts of each token to pull
     */
    function exitPool(
        IConfigurableRightsPool self,
        IBPool bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
        external
        view
        returns (
            uint256 exitFee,
            uint256 pAiAfterExitFee,
            uint256[] memory actualAmountsOut
        )
    {
        address[] memory tokens = bPool.getCurrentTokens();

        require(minAmountsOut.length == tokens.length, "ERR_AMOUNTS_MISMATCH");

        uint256 poolTotal = self.totalSupply();

        // Calculate exit fee and the final amount in
        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
        pAiAfterExitFee = BalancerSafeMath.bsub(poolAmountIn, exitFee);

        uint256 ratio = BalancerSafeMath.bdiv(pAiAfterExitFee, BalancerSafeMath.badd(poolTotal, 1));

        require(ratio != 0, "ERR_MATH_APPROX");

        actualAmountsOut = new uint256[](tokens.length);

        // This loop contains external calls
        // External calls are to math libraries or the underlying pool, so low risk
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            uint256 bal = bPool.getBalance(t);
            // Subtract 1 to ensure any rounding errors favor the pool
            uint256 tokenAmountOut = BalancerSafeMath.bmul(ratio, BalancerSafeMath.bsub(bal, 1));

            require(tokenAmountOut != 0, "ERR_MATH_APPROX");
            require(tokenAmountOut >= minAmountsOut[i], "ERR_LIMIT_OUT");

            actualAmountsOut[i] = tokenAmountOut;
        }
    }

    /**
     * @notice Join by swapping a fixed amount of an external token in (must be present in the pool)
     *         System calculates the pool token amount
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in
     * @param tokenAmountIn - amount of deposit
     * @param minPoolAmountOut - minimum of pool tokens to receive
     * @return poolAmountOut - amount of pool tokens minted and transferred
     */
    function joinswapExternAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external view returns (uint256 poolAmountOut) {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");
        require(
            tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn), BalancerConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );

        poolAmountOut = bPool.calcPoolOutGivenSingleIn(
            bPool.getBalance(tokenIn),
            bPool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountIn,
            bPool.getSwapFee()
        );

        require(poolAmountOut >= minPoolAmountOut, "ERR_LIMIT_OUT");
    }

    /**
     * @notice Join by swapping an external token in (must be present in the pool)
     *         To receive an exact amount of pool tokens out. System calculates the deposit amount
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenIn - which token we're transferring in (system calculates amount required)
     * @param poolAmountOut - amount of pool tokens to be received
     * @param maxAmountIn - Maximum asset tokens that can be pulled to pay for the pool tokens
     * @return tokenAmountIn - amount of asset tokens transferred in to purchase the pool tokens
     */
    function joinswapPoolAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenIn,
        uint256 poolAmountOut,
        uint256 maxAmountIn
    ) external view returns (uint256 tokenAmountIn) {
        require(bPool.isBound(tokenIn), "ERR_NOT_BOUND");

        tokenAmountIn = bPool.calcSingleInGivenPoolOut(
            bPool.getBalance(tokenIn),
            bPool.getDenormalizedWeight(tokenIn),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            poolAmountOut,
            bPool.getSwapFee()
        );

        require(tokenAmountIn != 0, "ERR_MATH_APPROX");
        require(tokenAmountIn <= maxAmountIn, "ERR_LIMIT_IN");

        require(
            tokenAmountIn <= BalancerSafeMath.bmul(bPool.getBalance(tokenIn), BalancerConstants.MAX_IN_RATIO),
            "ERR_MAX_IN_RATIO"
        );
    }

    /**
     * @notice Exit a pool - redeem a specific number of pool tokens for an underlying asset
     *         Asset must be present in the pool, and will incur an EXIT_FEE (if set to non-zero)
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param poolAmountIn - amount of pool tokens to redeem
     * @param minAmountOut - minimum asset tokens to receive
     * @return exitFee - calculated exit fee
     * @return tokenAmountOut - amount of asset tokens returned
     */
    function exitswapPoolAmountIn(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external view returns (uint256 exitFee, uint256 tokenAmountOut) {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");

        tokenAmountOut = bPool.calcSingleOutGivenPoolIn(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            poolAmountIn,
            bPool.getSwapFee()
        );

        require(tokenAmountOut >= minAmountOut, "ERR_LIMIT_OUT");
        require(
            tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut), BalancerConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }

    /**
     * @notice Exit a pool - redeem pool tokens for a specific amount of underlying assets
     *         Asset must be present in the pool
     * @param self - CRPool instance calling the library
     * @param bPool - Core BPool the CRP is wrapping
     * @param tokenOut - which token the caller wants to receive
     * @param tokenAmountOut - amount of underlying asset tokens to receive
     * @param maxPoolAmountIn - maximum pool tokens to be redeemed
     * @return exitFee - calculated exit fee
     * @return poolAmountIn - amount of pool tokens redeemed
     */
    function exitswapExternAmountOut(
        IConfigurableRightsPool self,
        IBPool bPool,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPoolAmountIn
    ) external view returns (uint256 exitFee, uint256 poolAmountIn) {
        require(bPool.isBound(tokenOut), "ERR_NOT_BOUND");
        require(
            tokenAmountOut <= BalancerSafeMath.bmul(bPool.getBalance(tokenOut), BalancerConstants.MAX_OUT_RATIO),
            "ERR_MAX_OUT_RATIO"
        );
        poolAmountIn = bPool.calcPoolInGivenSingleOut(
            bPool.getBalance(tokenOut),
            bPool.getDenormalizedWeight(tokenOut),
            self.totalSupply(),
            bPool.getTotalDenormalizedWeight(),
            tokenAmountOut,
            bPool.getSwapFee()
        );

        require(poolAmountIn != 0, "ERR_MATH_APPROX");
        require(poolAmountIn <= maxPoolAmountIn, "ERR_LIMIT_IN");

        exitFee = BalancerSafeMath.bmul(poolAmountIn, BalancerConstants.EXIT_FEE);
    }

    // Internal functions

    // Check for zero transfer, and make sure it returns true to returnValue
    function verifyTokenComplianceInternal(address token) internal {
        bool returnValue = IERC20(token).transfer(msg.sender, 0);
        require(returnValue, "ERR_NONCONFORMING_TOKEN");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Interface declarations

// Introduce to avoid circularity (otherwise, the CRP and SmartPoolManager include each other)
// Removing circularity allows flattener tools to work, which enables Etherscan verification
interface IConfigurableRightsPool {
    function mintPoolShareFromLib(uint256 amount) external;

    function pushPoolShareFromLib(address to, uint256 amount) external;

    function pullPoolShareFromLib(address from, uint256 amount) external;

    function burnPoolShareFromLib(uint256 amount) external;

    function totalSupply() external view returns (uint256);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Imports

import "./BalancerConstants.sol";

/**
 * @author Balancer Labs
 * @title SafeMath - wrap Solidity operators to prevent underflow/overflow
 * @dev badd and bsub are basically identical to OpenZeppelin SafeMath; mul/div have extra checks
 */
library BalancerSafeMath {
    /**
     * @notice Safe addition
     * @param a - first operand
     * @param b - second operand
     * @dev if we are adding b to a, the resulting sum must be greater than a
     * @return - sum of operands; throws if overflow
     */
    function badd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ERR_ADD_OVERFLOW");
        return c;
    }

    /**
     * @notice Safe unsigned subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction, and check that it produces a positive value
     *      (i.e., a - b is valid if b <= a)
     * @return - a - b; throws if underflow
     */
    function bsub(uint256 a, uint256 b) internal pure returns (uint256) {
        (uint256 c, bool negativeResult) = bsubSign(a, b);
        require(!negativeResult, "ERR_SUB_UNDERFLOW");
        return c;
    }

    /**
     * @notice Safe signed subtraction
     * @param a - first operand
     * @param b - second operand
     * @dev Do a signed subtraction
     * @return - difference between a and b, and a flag indicating a negative result
     *           (i.e., a - b if a is greater than or equal to b; otherwise b - a)
     */
    function bsubSign(uint256 a, uint256 b) internal pure returns (uint256, bool) {
        if (b <= a) {
            return (a - b, false);
        } else {
            return (b - a, true);
        }
    }

    /**
     * @notice Safe multiplication
     * @param a - first operand
     * @param b - second operand
     * @dev Multiply safely (and efficiently), rounding down
     * @return - product of operands; throws if overflow or rounding error
     */
    function bmul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization (see github.com/OpenZeppelin/openzeppelin-contracts/pull/522)
        if (a == 0) {
            return 0;
        }

        // Standard overflow check: a/a*b=b
        uint256 c0 = a * b;
        require(c0 / a == b, "ERR_MUL_OVERFLOW");

        // Round to 0 if x*y < BONE/2?
        uint256 c1 = c0 + (BalancerConstants.BONE / 2);
        require(c1 >= c0, "ERR_MUL_OVERFLOW");
        uint256 c2 = c1 / BalancerConstants.BONE;
        return c2;
    }

    /**
     * @notice Safe division
     * @param dividend - first operand
     * @param divisor - second operand
     * @dev Divide safely (and efficiently), rounding down
     * @return - quotient; throws if overflow or rounding error
     */
    function bdiv(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        require(divisor != 0, "ERR_DIV_ZERO");

        // Gas optimization
        if (dividend == 0) {
            return 0;
        }

        uint256 c0 = dividend * BalancerConstants.BONE;
        require(c0 / dividend == BalancerConstants.BONE, "ERR_DIV_INTERNAL"); // bmul overflow

        uint256 c1 = c0 + (divisor / 2);
        require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require

        uint256 c2 = c1 / divisor;
        return c2;
    }

    /**
     * @notice Safe unsigned integer modulo
     * @dev Returns the remainder of dividing two unsigned integers.
     *      Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * @param dividend - first operand
     * @param divisor - second operand -- cannot be zero
     * @return - quotient; throws if overflow or rounding error
     */
    function bmod(uint256 dividend, uint256 divisor) internal pure returns (uint256) {
        require(divisor != 0, "ERR_MODULO_BY_ZERO");

        return dividend % divisor;
    }

    /**
     * @notice Safe unsigned integer max
     * @dev Returns the greater of the two input values
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the maximum of a and b
     */
    function bmax(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @notice Safe unsigned integer min
     * @dev returns b, if b < a; otherwise returns a
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the lesser of the two input values
     */
    function bmin(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @notice Safe unsigned integer average
     * @dev Guard against (a+b) overflow by dividing each operand separately
     *
     * @param a - first operand
     * @param b - second operand
     * @return - the average of the two values
     */
    function baverage(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @notice Babylonian square root implementation
     * @dev (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
     * @param y - operand
     * @return z - the square root result
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

// Imports

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Libraries

/**
 * @author PieDAO (ported to Balancer Labs)
 * @title SafeApprove - set approval for tokens that require 0 prior approval
 * @dev Perhaps to address the known ERC20 race condition issue
 *      See https://github.com/crytic/not-so-smart-contracts/tree/master/race_condition
 *      Some tokens - notably KNC - only allow approvals to be increased from 0
 */
library SafeApprove {
    /**
     * @notice handle approvals of tokens that require approving from a base of 0
     * @param token - the token we're approving
     * @param spender - entity the owner (sender) is approving to spend his tokens
     * @param amount - number of tokens being approved
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        uint256 currentAllowance = token.allowance(address(this), spender);

        // Do nothing if allowance is already set to this value
        if (currentAllowance == amount) {
            return true;
        }

        // If approval is not zero reset it to zero first
        if (currentAllowance != 0) {
            return token.approve(spender, 0);
        }

        // do the actual approval
        return token.approve(spender, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

/**
 * @author Balancer Labs
 * @title Put all the constants in one place
 */

library BalancerConstants {
    // State variables (must be constant in a library)

    // B "ONE" - all math is in the "realm" of 10 ** 18;
    // where numeric 1 = 10 ** 18
    uint256 public constant BONE = 10**18;
    uint256 public constant MIN_WEIGHT = BONE;
    uint256 public constant MAX_WEIGHT = BONE * 50;
    uint256 public constant MAX_TOTAL_WEIGHT = BONE * 50;
    uint256 public constant MIN_BALANCE = BONE / 10**6;
    uint256 public constant MAX_BALANCE = BONE * 10**12;
    uint256 public constant MIN_POOL_SUPPLY = BONE * 100;
    uint256 public constant MAX_POOL_SUPPLY = BONE * 10**9;
    uint256 public constant MIN_FEE = BONE / 10**6;
    uint256 public constant MAX_FEE = BONE / 10;
    // EXIT_FEE must always be zero, or CRPool._pushUnderlying will fail
    uint256 public constant EXIT_FEE = 0;
    uint256 public constant MAX_IN_RATIO = BONE / 2;
    uint256 public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
    // Must match BConst.MIN_BOUND_TOKENS and BConst.MAX_BOUND_TOKENS
    uint256 public constant MIN_ASSET_LIMIT = 2;
    uint256 public constant MAX_ASSET_LIMIT = 8;
    uint256 public constant MAX_UINT = uint256(-1);
}