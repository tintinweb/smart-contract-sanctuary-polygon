// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Partial interface of the ERC20 standard.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function decimals() external view returns (uint8);
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
        address userAddress, uint256 collateralProfileIndex, uint256 amount
    ) external returns (bool);
    function withdrawNetna (
        address userAddress, uint256 collateralProfileIndex, uint256 amount
    ) external returns (bool);
    function isNetnaProfile (
        uint256 collateralProfileIndex
    ) external view returns (bool);
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
contract NftCollateral is IERC721Receiver {
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
    uint256 internal _batchLimit = 100;
    // maximum amount of tokens that can be proceeded within single transaction
    uint256 internal _nEtnaProfileIndex;
    uint256 internal constant YEAR = 365 * 24 * 3600;

    IERC20 internal _nEtnaContract;
    IMarketplace internal _marketplaceContract;
    INFT internal _nftContract;
    ICollateral internal _collateralContract;
    address private _owner;

    constructor (
        address marketplaceAddress,
        address nftAddress,
        address collateralAddress,
        address newOwner,
        uint256 nEtnaProfileIndex
    ) {
        _collateralContract = ICollateral(collateralAddress);
        address nEtnaAddress = _collateralContract.getNEtnaContract();
        require(nEtnaAddress != address(0), 'Token address can not be zero');
        require(marketplaceAddress != address(0), 'Marketplace contract address can not be zero');
        require(nftAddress != address(0), 'NFT token address can not be zero');
        require(newOwner != address(0), 'Owner address can not be zero');

        _nEtnaContract = IERC20(nEtnaAddress);
        _marketplaceContract = IMarketplace(marketplaceAddress);
        _nftContract = INFT(nftAddress);
        require(
            _collateralContract.isNetnaProfile(nEtnaProfileIndex),
                'Wrong NETNA collateral profile index'
        );
        _owner = newOwner;
        _managers[newOwner] = true;
        _nEtnaProfileIndex = nEtnaProfileIndex;
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
        _nEtnaContract.transfer(address(_collateralContract), amount);
        require(
            _collateralContract.depositNetna(msg.sender, _nEtnaProfileIndex, amount),
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
            _collateralContract.withdrawNetna(msg.sender, _nEtnaProfileIndex, amount),
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
        uint256 tokensNumber;
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
            tokensNumber ++;
            _tokenRegistry[tokenIds[i]] = address(0);

            _nftContract.safeTransferFrom(
                address(this),
                userAddress,
                tokenIds[i]
            );
        }
        _deposits[depositIndex].amount -= amount;
        _deposits[depositIndex].tokensNumber -= tokensNumber;
        _tokensNumber -= tokensNumber;

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

    function updateNEtnaContract () external onlyManager returns (bool) {
        address nEtnaAddress = _collateralContract.getNEtnaContract();
        _nEtnaContract = IERC20(nEtnaAddress);
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
        uint256 amount;
        uint256 tokensNumber;
        for (uint256 i; i < tokenIds.length; i ++) {
            if (i >= _batchLimit) break;
            require (
                _tokenRegistry[tokenIds[i]] == address(0),
                    'Token Id is already in use'
            );
            _tokenPrice[tokenIds[i]] = prices[i];
            tokensNumber ++;
            amount += prices[i];
            _userTokenRegistry[userAddress][i + 1] = tokenIds[i];
            _userTokenIndexes[userAddress][tokenIds[i]] = i + 1;
            _tokenRegistry[tokenIds[i]] = userAddress;
        }
        _deposits[_depositsNumber].tokensNumber = tokensNumber;
        _tokensNumber += tokensNumber;
        _deposits[_depositsNumber].amount = amount;
        return true;
    }

    function setNEtnaProfileIndex (
        uint256 nEtnaProfileIndex
    ) external onlyManager returns (bool) {
        require(
            _collateralContract.isNetnaProfile(nEtnaProfileIndex),
            'Wrong NETNA collateral profile index'
        );
        _nEtnaProfileIndex = nEtnaProfileIndex;
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

    function adminWithdrawNEtna (
        uint256 amount
    ) external onlyOwner returns (bool) {
        uint256 balance = _nEtnaContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        _nEtnaContract.transfer(msg.sender, amount);
        return true;
    }

    function adminWithdrawToken (
        address contractAddress, uint256 amount
    ) external onlyOwner returns (bool) {
        require(contractAddress != address(0), 'Contract address should not be zero');
        IERC20 tokenContract = IERC20(contractAddress);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(amount <= balance, 'Not enough contract balance');
        tokenContract.transfer(msg.sender, amount);
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
        uint256 tokensNumber;
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
            tokensNumber ++;
            _tokenRegistry[tokenIds[i]] = address(0);
            _nftContract.safeTransferFrom(
                address(this),
                msg.sender,
                tokenIds[i]
            );
        }
        _deposits[depositIndex].tokensNumber -= tokensNumber;
        _tokensNumber -= tokensNumber;
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

    function getCollateralContract () external view returns (address) {
        return address(_collateralContract);
    }

    function getNEtnaContract () external view returns (address) {
        return address(_nEtnaContract);
    }

    function getMarketplaceContract () external view returns (address) {
        return address(_marketplaceContract);
    }

    function getNftContract () external view returns (address) {
        return address(_nftContract);
    }

    function getNEtnaProfileIndex () external view returns (uint256) {
        return _nEtnaProfileIndex;
    }

    function getBatchLimit () external view returns (uint256) {
        return _batchLimit;
    }

    function getNEtnaBalance () external view returns (uint256) {
        return _nEtnaContract.balanceOf(address(this));
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