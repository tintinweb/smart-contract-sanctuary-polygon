// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IGravityGrade.sol";
import "./IGravityGradeGenericBurn.sol";
import "../util/IConditionalProvider.sol";
import "../interfaces/ITrustedMintable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

interface IVRFConsumerBaseV2 {
    function getRandomNumber(uint32 draws) external returns (uint256 requestID);
}

/**
 * @title Gravity Grade Generic Burn
 * @author Jourdan
 * @notice This contract manages burning and custom rewards for any Gravity Grade token
 */
contract GravityGradeGenericBurn is IGravityGradeGenericBurn, OwnableUpgradeable {
    /*------------------- STATE VARIABLES -------------------*/

    /// @notice All category ids belonging to a tokenId, (tokenId => categoryIds)
    mapping(uint256 => uint256[]) private s_tokenCategoryIds;
    /// @notice Total categories belonging to a tokenId, (tokenId => total categories)
    mapping(uint256 => uint256) private s_tokenTotalCategories;
    /// @notice All categories belonging to a tokenId, (tokenId => ContentCategory[])
    mapping(uint256 => ContentCategory[]) private s_tokenCategories;
    /// @notice Shows whether a category is active, (tokenId => categoryId => bool)
    mapping(uint256 => mapping(uint256 => bool)) private s_tokenCategoryActive;
    /// @notice Shows the index where a category can be found, (tokenId => categoryId => index)
    mapping(uint256 => mapping(uint256 => uint256)) private s_tokenCategoryIndex;
    /// @notice Contract with eligibility requirements for category, (tokenId => categoryId => eligibility)
    mapping(uint256 => mapping(uint256 => IConditionalProvider)) private s_tokenEligibility;
    /// @notice Max number of draws any category can have for a particular token (tokenId => maxDraws)
    mapping(uint256 => uint32) maxDrawsPerCategory;

    /// @notice Oracle being used for randomness
    IVRFConsumerBaseV2 private s_randNumOracle;

    /// @notice TokenId for a VRF request
    mapping(uint256 => uint256) s_requestTokenId;
    /// @notice User for a VRF request
    mapping(uint256 => address) private s_requestUser;
    /// @notice Ids of categories a user didn't qualify for on a VRF request
    mapping(uint256 => uint256[]) private s_requestExcludedIds;
    /// @notice Number of openings for a VRF request
    mapping(uint256 => uint256) private s_requestOpenings;
    /// @notice Number of random words needed
    mapping(uint256 => uint256) private s_requestRandWords;

    /// @notice TokenIds which are whitelisted for burning
    mapping(uint256 => bool) private s_whitelistedTokens;
    /// @notice Gravity Grade Contract
    address private gravityGrade;
    /// @notice Governance
    address private s_governance;

    event RewardGranted(address _token, uint256 _tokenId, uint256 _amount);

    /*------------------- MODIFIERS -------------------*/

    modifier onlyGov() {
        if (msg.sender != owner() && msg.sender != s_governance) revert GB__NotGov(msg.sender);
        _;
    }

    modifier onlyOracle() {
        if (msg.sender != address(s_randNumOracle)) revert GB__NotOracle();
        _;
    }

    /*------------------- INITIALIZER -------------------*/

    function initialize() public initializer {
        __Ownable_init();
    }

    /*------------------- ADMIN - ONLY FUNCTIONS -------------------*/

    /// @inheritdoc IGenericBurn
    function whitelistToken(uint256 _tokenId, bool _isWhitelisted) external onlyGov {
        s_whitelistedTokens[_tokenId] = _isWhitelisted;
        emit TokenWhitelisted(_tokenId, _isWhitelisted);
    }

    /**
     * @notice Sets VRF consumer to be used
     * @param _vrfOracle The address of the oracle
     */
    function setVRFOracle(address _vrfOracle) external onlyOwner {
        if (_vrfOracle == address(0)) revert GB__ZeroAddress();
        s_randNumOracle = IVRFConsumerBaseV2(_vrfOracle);
    }

    /// @inheritdoc IGravityGradeGenericBurn
    function setGravityGrade(address _gravityGrade) external onlyGov {
        gravityGrade = _gravityGrade;
        emit GravityGradeSet(_gravityGrade);
    }

    /**
     * @notice Sets governace
     * @param _governance The address of the oracle
     */
    function setGovernance(address _governance) external onlyGov {
        s_governance = _governance;
    }

    /// @inheritdoc IGenericBurn
    function setContentEligibility(
        uint256 _tokenId,
        uint256 _categoryId,
        address _conditionalProvider
    ) external onlyGov {
        if (
            !ERC165CheckerUpgradeable.supportsInterface(
                _conditionalProvider,
                type(IERC165).interfaceId
            ) ||
            !ERC165CheckerUpgradeable.supportsInterface(
                _conditionalProvider,
                type(IConditionalProvider).interfaceId
            )
        ) {
            revert GB__NotConditionalProvider(_conditionalProvider);
        }
        s_tokenEligibility[_tokenId][_categoryId] = IConditionalProvider(_conditionalProvider);
        emit CategoryEligibilitySet(_tokenId, _categoryId, _conditionalProvider);
    }

    /// @inheritdoc IGenericBurn
    function createContentCategory(uint256 _tokenId)
        external
        onlyGov
        returns (uint256 _categoryId)
    {
        unchecked {
            _categoryId = ++s_tokenTotalCategories[_tokenId];
        }

        s_tokenCategories[_tokenId].push(
            ContentCategory({
                id: _categoryId,
                contentAmountsTotalWeight: 0,
                contentsTotalWeight: 0,
                contentAmounts: new uint256[](0),
                contentAmountsWeights: new uint256[](0),
                tokenAmounts: new uint256[](0),
                tokenWeights: new uint256[](0),
                tokens: new address[](0),
                tokenIds: new uint256[](0)
            })
        );
        s_tokenCategoryIds[_tokenId].push(_categoryId);
        s_tokenCategoryIndex[_tokenId][_categoryId] = s_tokenCategories[_tokenId].length - 1;
        s_tokenCategoryActive[_tokenId][_categoryId] = true;

        emit CategoryCreated(_tokenId, _categoryId);
    }

    /// @inheritdoc IGenericBurn
    function deleteContentCategory(uint256 _tokenId, uint256 _contentCategory) external onlyGov {
        if (!s_tokenCategoryActive[_tokenId][_contentCategory])
            revert GB__InvalidCategoryId(_contentCategory);

        uint256 index = s_tokenCategoryIndex[_tokenId][_contentCategory];
        for (uint256 i = index; i < s_tokenCategories[_tokenId].length - 1; ) {
            s_tokenCategories[_tokenId][i] = s_tokenCategories[_tokenId][i + 1];
            s_tokenCategoryIds[_tokenId][i] = s_tokenCategoryIds[_tokenId][i + 1];
            s_tokenCategoryIndex[_tokenId][s_tokenCategories[_tokenId][i].id] = i;

            unchecked {
                ++i;
            }
        }
        s_tokenCategoryActive[_tokenId][_contentCategory] = false;
        s_tokenCategoryIds[_tokenId].pop();
        s_tokenCategories[_tokenId].pop();

        emit CategoryDeleted(_tokenId, _contentCategory);
    }

    /// @inheritdoc IGenericBurn
    function setContentAmounts(
        uint256 _tokenId,
        uint256 _contentCategory,
        uint256[] calldata _amounts,
        uint256[] calldata _weights
    ) external onlyGov {
        if (!s_tokenCategoryActive[_tokenId][_contentCategory])
            revert GB__InvalidCategoryId(_contentCategory);
        if (_amounts.length != _weights.length) revert GB__ArraysNotSameLength();

        uint256 sum;
        for (uint256 i = 0; i < _weights.length; i++) {
            if (_weights[i] == 0) revert GB__ZeroWeight();
            if (_amounts[i] > maxDrawsPerCategory[_tokenId])
                revert GB__MaxDrawsExceeded(_amounts[i]);
            sum += _weights[i];
        }

        uint256 index = s_tokenCategoryIndex[_tokenId][_contentCategory];

        s_tokenCategories[_tokenId][index].contentAmounts = _amounts;
        s_tokenCategories[_tokenId][index].contentAmountsWeights = _arrayToCumulative(_weights);
        s_tokenCategories[_tokenId][index].contentAmountsTotalWeight = sum;

        emit ContentAmountsUpdated(_tokenId, _contentCategory, _amounts, _weights);
    }

    /// @inheritdoc IGenericBurn
    function setContents(
        uint256 _tokenId,
        uint256 _contentCategory,
        address[] calldata _tokens,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts,
        uint256[] calldata _weights
    ) external onlyGov {
        if (!s_tokenCategoryActive[_tokenId][_contentCategory])
            revert GB__InvalidCategoryId(_contentCategory);
        if (
            _amounts.length != _weights.length ||
            _amounts.length != _tokens.length ||
            _amounts.length != _tokenIds.length
        ) revert GB__ArraysNotSameLength();

        uint256 sum;
        for (uint256 i = 0; i < _weights.length; i++) {
            if (_weights[i] == 0) revert GB__ZeroWeight();
            if (_amounts[i] == 0) revert GB_ZeroAmount();
            if (
                !ERC165CheckerUpgradeable.supportsInterface(
                    _tokens[i],
                    type(IERC721).interfaceId
                ) &&
                !ERC165CheckerUpgradeable.supportsInterface(_tokens[i], type(IERC1155).interfaceId)
            ) {
                revert GB__NotERC721or1155(_tokens[i]);
            }

            sum += _weights[i];
        }

        uint256 index = s_tokenCategoryIndex[_tokenId][_contentCategory];

        s_tokenCategories[_tokenId][index].tokenAmounts = _amounts;
        s_tokenCategories[_tokenId][index].tokenWeights = _arrayToCumulative(_weights);
        s_tokenCategories[_tokenId][index].contentsTotalWeight = sum;
        s_tokenCategories[_tokenId][index].tokens = _tokens;
        s_tokenCategories[_tokenId][index].tokenIds = _tokenIds;

        emit ContentsUpdated(_tokenId, _contentCategory, _tokens, _tokenIds, _amounts, _weights);
    }

    /**
     * @notice Function for setting the maximum # of draws any category can have
     * @param _maxDraws The max number of draws any category can have
     */
    function setMaxDraws(uint256 _tokenId, uint32 _maxDraws) external onlyGov {
        maxDrawsPerCategory[_tokenId] = _maxDraws;
    }

    /*------------------- END - USER FUNCTIONS -------------------*/

    /// @inheritdoc IGenericBurn
    function burnPack(
        uint256 _tokenId,
        uint32 _amount,
        bool _optInConditionals
    ) external {
        if (!s_whitelistedTokens[_tokenId]) revert GB__TokenNotWhitelisted(_tokenId);

        uint256[] memory tokenCategoryIds = s_tokenCategoryIds[_tokenId];
        uint256[] memory excludedIds = new uint256[](tokenCategoryIds.length);
        uint256 numRequests;

        _burnTokens(_tokenId, _amount);

        // Testing each category to ensure user qualifies. Perhaps we could shift this
        // responsibility onto fulfillRandomness to lower gas even further for the end user
        if (_optInConditionals) {
            for (uint256 j; j < tokenCategoryIds.length; j++) {
                if (address(s_tokenEligibility[_tokenId][tokenCategoryIds[j]]) != address(0)) {
                    IConditionalProvider conditionalProvider = s_tokenEligibility[_tokenId][
                        tokenCategoryIds[j]
                    ];
                    if (!conditionalProvider.isEligible(msg.sender)) {
                        excludedIds[numRequests] = tokenCategoryIds[j];
                        unchecked {
                            ++numRequests;
                        }
                    }
                }
            }
        }
        uint32 randWordsRequest = _amount > maxDrawsPerCategory[_tokenId]
            ? _amount
            : maxDrawsPerCategory[_tokenId];
        uint256 requestId = s_randNumOracle.getRandomNumber(1);
        s_requestUser[requestId] = msg.sender;
        s_requestTokenId[requestId] = _tokenId;
        s_requestOpenings[requestId] = _amount;
        s_requestRandWords[requestId] = randWordsRequest;

        for (uint256 i; i < excludedIds.length; i++) {
            if (excludedIds[i] != 0) {
                s_requestExcludedIds[requestId].push(excludedIds[i]);
            }
        }

        emit PackOpened(msg.sender, _tokenId, _amount);
    }

    /// @inheritdoc IGenericBurn
    function getContentCategories(uint256 _tokenId)
        external
        view
        returns (ContentCategory[] memory _categories)
    {
        _categories = s_tokenCategories[_tokenId];
    }

    /*------------------- INTERNAL FUNCTIONS -------------------*/

    /**
     * @notice Function for satisfying randomness requests from burnPack
     * @param requestId The particular request being serviced
     * @param randomWords Array of the random numbers requested
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        external
        onlyOracle
    {
        address user = s_requestUser[requestId];
        uint256 tokenId = s_requestTokenId[requestId];
        uint256 openings = s_requestOpenings[requestId];
        uint256[] memory excludedIds = s_requestExcludedIds[requestId];
        uint256 randWordsCount = s_requestRandWords[requestId];

        uint256[] memory expandedValues = new uint256[](randWordsCount);
        for (uint256 i = 0; i < randWordsCount; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomWords[0], i)));
        }

        ContentCategory[] memory categories = s_tokenCategories[tokenId];

        for (uint256 i; i < categories.length; i++) {
            for (uint256 z; z < excludedIds.length; z++) {
                if (categories[i].id == excludedIds[z]) continue;
            }
            for (uint256 j; j < openings; j++) {
                uint256 target = expandedValues[j] % categories[i].contentAmountsTotalWeight;
                uint256 index = _binarySearch(categories[i].contentAmountsWeights, target);
                uint256 draws = categories[i].contentAmounts[index];
                for (uint256 k; k < draws; k++) {
                    uint256 targetContent = expandedValues[k] % categories[i].contentsTotalWeight;
                    uint256 indexContent = _binarySearch(categories[i].tokenWeights, targetContent);
                    _mintReward(user, categories[i], indexContent);
                }
            }
        }

        delete s_requestUser[requestId];
        delete s_requestTokenId[requestId];
        delete s_requestOpenings[requestId];
        delete s_requestExcludedIds[requestId];
    }

    /**
     * @notice Burns a given amount of Gravity Grade tokens
     * @param _tokenId The id of the token to burn
     * @param _amount Amount of the token to burn
     */
    function _burnTokens(uint256 _tokenId, uint256 _amount) internal {
        IGravityGrade(gravityGrade).burn(msg.sender, _tokenId, _amount);
    }

    /**
     * @notice Mints appropriate rewards for the user
     * @param _user The address of the user
     * @param category The category from which the reward should come
     * @param _index Index of the particular contents to mint
     */
    function _mintReward(
        address _user,
        ContentCategory memory category,
        uint256 _index
    ) internal {
        ITrustedMintable(category.tokens[_index]).trustedMint(
            _user,
            category.tokenIds[_index],
            category.tokenAmounts[_index]
        );
        emit RewardGranted(
            category.tokens[_index],
            category.tokenIds[_index],
            category.tokenAmounts[_index]
        );
    }

    /**
     * @notice Converts an array of weights into a cumulative array
     * @param arr The array to convert
     * @return _cumulativeArr The resultant cumulative array
     */
    function _arrayToCumulative(uint256[] memory arr)
        private
        pure
        returns (uint256[] memory _cumulativeArr)
    {
        _cumulativeArr = new uint256[](arr.length);
        _cumulativeArr[0] = arr[0];
        for (uint256 i = 1; i < arr.length; i++) {
            _cumulativeArr[i] = _cumulativeArr[i - 1] + arr[i];
        }
    }

    /**
     * @notice Runs a binary search on an array
     * @param arr The array to search
     * @param target The target value
     * @return _location Index of the result
     */
    function _binarySearch(uint256[] memory arr, uint256 target)
        private
        pure
        returns (uint256 _location)
    {
        uint256 left;
        uint256 mid;
        uint256 right = arr.length;

        while (left < right) {
            mid = Math.average(left, right);

            if (target < arr[mid]) {
                right = mid;
            } else {
                left = mid + 1;
            }
        }

        if (left > 0 && arr[left - 1] == target) {
            return left - 1;
        } else {
            return left;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @title Interface defining Gravity Grade
interface IGravityGrade is IERC1155Upgradeable {
    enum GravityGradeDrops {
        UNUSED,
        CargoDrop3,
        AnniversaryPackMystery,
        AnniversaryPackOutlier,
        AnniversaryPackCommon,
        AnniversaryPackUncommon,
        AnniversaryPackRare,
        AnniversaryPackLegendary,
        StarterPack
    }

    /**
    * @notice Event emitted when a sales state is mutated
    * @param saleId The id of the sale
    * @param isPaused Whether the sale is paused or not
    */
    event SaleState(uint256 saleId, bool isPaused);
    /**
    * @notice Event emitted when a sale is deleted
    * @param saleId The sale id
    */
    event SaleDeleted(uint256 saleId);
    /**
    * @notice Event emitted when a sales parameters are updated
    * @param saleId The sale id
    * @param tokenId The token id that is being sold
    * @param salePrice The price, denoted in the default currency
    * @param totalSupply The cap on the total amount of units to be sold
    * @param userCap The cap per user on units that can be purchased
    * @param defaultCurrency The default currency for the sale.
    */
    event SaleInfoUpdated(
        uint256 saleId,
        uint256 tokenId,
        uint256 salePrice,
        uint256 totalSupply,
        uint256 userCap,
        address defaultCurrency
    );
    /**
    * @notice Event emitted when the beneficiaries are updated
    * @param beneficiaries Array of beneficiary addresses
    * @param basisPoints Array of basis points for each beneficiary (by index)
    */
    event BeneficiariesUpdated(address[] beneficiaries, uint256[] basisPoints);
    /**
    * @notice Event emitted when payment currencies are added
    * @param saleId The sale id
    * @param currencyAddresses The addresses of the currencies that have been added
    */
    event PaymentCurrenciesSet(uint256 saleId, address[] currencyAddresses);
    /**
    * @notice Event emitted when payment currencies are removed
    * @param saleId The sale id
    * @param currencyAddresses The addresses of the currencies that have been removed
    */
    event PaymentCurrenciesRevoked(uint256 saleId, address[] currencyAddresses);

    // Used to classify token types in the ownership rebate struct
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     * @notice Used to provide specifics for ownership based discounts
     * @param tokenType The type of token
     * @param tokenAddress The address of the token contract
     * @param tokenId The token id, ignored if ERC721 is provided for the token type
     * @param basisPoints The discount in basis points
     */
    struct OwnershipRebate {
        TokenType tokenType;
        address tokenAddress;
        uint256 tokenId; // ignored if ERC721
        uint256 basisPoints;
    }

    /**
     * @notice Used to output pack discount info
     * @param originalPrice The original pack price from calculating the salePrice * purchaseQuantity
     * @param discountedPrice The discounted pack price from calculating bulk purchases and rebates
     * @param purchaseQuantity The number of packs to purchase
     * @param tokenAddress The address of the token contract
     */
    struct Discounts {
        uint256 originalPrice;
        uint256 discountedPrice;
        uint256 purchaseQuantity;
        address tokenAddress;
    }

    /**
     * @notice Calculates the discount pack price
     * @param _saleId The sale ID to query the price against
     * @param _numPurchases The number of packs to query against
     * @param _currency Address of currency to use, address(0) for matic
     * @param _tokenAddress The token address for the token claimed to be held
     * @return Discounts The discount details for the pack
     */
    function calculateDiscountedPackPrice(
        uint256 _saleId,
        uint256 _numPurchases,
        address _currency,
        address _tokenAddress
    ) external returns (Discounts memory);

    /**
     * @notice Sets the TokenURI
     * @param _tokenId The tokenId to set for the URI
     * @param _uri The URI to set for the token
     */
    function setTokenUri(uint256 _tokenId, string memory _uri) external;

    /**
     * @notice Create new emissions/sales
     * @param _tokenId The ERC1155 tokenId to sell
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function createNewSale(
        uint256 _tokenId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external returns (uint256 saleId);

    /**
     * @notice Start and pause sales
     * @param _saleId The sale ID to set the status for
     * @param _paused The sale status
     */
    function setSaleState(uint256 _saleId, bool _paused) external;

    /**
     * @notice Modify sale
     * @param _saleId The sale ID to modify
     * @param _salePrice Price in US dollars
     * @param _totalSupplyAmountToSell Cap on total amount to be sold
     * @param _userCap A per-user cap
     * @param _defaultCurrency Default currency (contract address)
     * @param _profitState Whether all sale profits should be instantly exchanged
        for the default currency or stored as is (false to exchange, true otherwise)
     */
    function modifySale(
        uint256 _saleId,
        uint256 _salePrice,
        uint256 _totalSupplyAmountToSell,
        uint256 _userCap,
        address _defaultCurrency,
        bool _profitState
    ) external;

    /**
     * @notice Adds a bulk discount to a sale
     * @param _saleId The sale id
     * @param _breakpoint At what quantity the discount should be applied
     * @param _basisPoints The non cumulative discount in basis point
     */
    function addBulkDiscount(
        uint256 _saleId,
        uint256 _breakpoint,
        uint256 _basisPoints
    ) external;

    /**
     * @notice Adds a token ownership based discount to a sale
     * @param _saleId The sale id
     * @param _info Struct containing specifics regarding the discount
     */
    function addOwnershipDiscount(uint256 _saleId, OwnershipRebate calldata _info) external;

    /**
     * @notice Delete a sale
     * @param _saleId The sale ID to delete
     */
    function deleteSale(uint256 _saleId) external;

    /**
     * @notice Set the whitelist for allowed payment currencies on a per saleId basis
     * @param _saleId The sale ID to set
     * @param _currencyAddresses The addresses of permissible payment currencies
     */
    function setAllowedPaymentCurrencies(uint256 _saleId, address[] calldata _currencyAddresses)
    external;

    /**
     * @notice Set a swap manager to manage the means through which tokens are exchanged
     * @param _swapManager SwapManager address
     */
    function setSwapManager(address _swapManager) external;

    /**
     * @notice Set a oracle manager to manage the means through which token prices are fetched
     * @param _oracleManager OracleManager address
     */
    function setOracleManager(address _oracleManager) external;

    /**
     * @notice Set administrator
     * @param _moderatorAddress The addresse of an allowed admin
     */
    function setModerator(address _moderatorAddress) external;

    /**
     * @notice Adds a trusted party, which is allowed to mint tokens through the airdrop function
     * @param _trusted The address of the trusted party
     * @param _isTrusted Whether the party is trusted or not
     */
    function setTrusted(address _trusted, bool _isTrusted) external;

    /**
     * @notice Empty the treasury into the owners or an arbitrary wallet
     * @param _walletAddress The withdrawal EOA address
     * @param _currency ERC20 currency to withdraw, ZERO address implies MATIC
     */
    function withdraw(address _walletAddress, address _currency) external payable;

    /**
     * @notice  Set Fee Wallets and fee percentages from sales
     * @param _walletAddresses The withdrawal EOA addresses
     * @param _feeBps Represented as basis points e.g. 500 == 5 pct
     */
    function setFeeWalletsAndPercentages(
        address[] calldata _walletAddresses,
        uint256[] calldata _feeBps
    ) external;

    /**
     * @notice Purchase any active sale in any whitelisted currency
     * @param _saleId The sale ID of the pack to purchase
     * @param _numPurchases The number of packs to purchase
     * @param _tokenId The tokenId claimed to be owned (for rebates)
     * @param _tokenAddress The token address for the tokenId claimed to be owned (for rebates)
     * @param _currency Address of currency to use, address(0) for matic
     */
    function buyPacks(
        uint256 _saleId,
        uint256 _numPurchases,
        uint256 _tokenId,
        address _tokenAddress,
        address _currency
    ) external payable;

    /**
     * @notice Airdrop tokens to arbitrary wallets
     * @param _recipients The recipient addresses
     * @param _tokenIds The tokenIds to mint
     * @param _amounts The amount of tokens to mint
     */
    function airdrop(
        address[] calldata _recipients,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /**
     * @notice used to burn tokens by trusted contracts
     * @param _from address to burn tokens from
     * @param _tokenId id of to-be-burnt tokens
     * @param _amount number of tokens to burn
     */
    function burn(
        address _from,
        uint256 _tokenId,
        uint256 _amount
    ) external;
}

pragma solidity ^0.8.0;


// @title Watered down version of IAssetManager, to be used for Gravity Grade
interface ITrustedMintable {

    error TM__NotTrusted(address _caller);
    /**
    * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenId Id of newly minted tokens. MUST be ignored on ERC-721
     * @param _amount Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedMint(
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    /**
     * @notice Used to mint tokens by trusted contracts
     * @param _to Recipient of newly minted tokens
     * @param _tokenIds Ids of newly minted tokens MUST be ignored on ERC-721
     * @param _amounts Number of tokens to mint
     *
     * Throws TM_NotTrusted on caller not being trusted
     */
    function trustedBatchMint(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

}

pragma solidity ^0.8.0;

import "./IGravityGradeBurn.sol";
import "../util/IGenericBurn.sol";

// @title Interface for a generic GG burn contract
// @dev IGenericBurn replaces the previous GG burn interface, though it's backwards compatible
interface IGravityGradeGenericBurn is IGenericBurn {
    /**
     * @notice Event emitted when the GG address is set
     * @param _address GG address
     */
    event GravityGradeSet(address _address);

    /**
     * @notice Sets the address to gravity grade
     * @param _gravityGrade The address
     *
     * Throws GB__NotGov on non gov call
     *
     * Emits GravityGradeSet
     */
    function setGravityGrade(address _gravityGrade) external;
}

pragma solidity ^0.8.0;

/**
* @title Interface used to check eligibility of an address for something
*/
interface IConditionalProvider {
    /**
    * @notice Returns whether the address is eligible
    * @param _address The address
    * @return _isEligible Whether the address is eligible
    */
    function isEligible(address _address) external view returns (bool _isEligible);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Interface defining a burn contract for Gravity Grade tokens
interface IGravityGradeBurn {
    /**
    * @notice Event emitted upon opening packs
    * @param _opener The address of the opener
    * @param _tokenId The tokenid that was "opened"
    * @param _numPacks The number of tokens that were "opened"
    */
    event PackOpened(address _opener, uint _tokenId, uint _numPacks);

    error GravityGradeBurn__InvalidTokenId(uint _tokenId);
    /**
     * @notice Burns Gravity Grade Token Packs
     * @param _tokenId The tokenId of the pack to burn
     * @param _amount The amount of tokens to burn
     */
    function burnPack(uint256 _tokenId, uint _amount) external;

}

pragma solidity ^0.8.0;

// @title Interface for a generic burn contract
interface IGenericBurn {
    /**
    This interface is a little complex.

    When a player burns a token, they are guaranteed one draw from each content category for that token id.

    For a content category, first the amount of contents are drawn. Then, each content is drawn until the drawn amount
    has been reached.

    Here is an example of how it should be used

    The admin wants to players to burn GG token id 18. When they burn it, they have a 50% chance of getting a tokenID 19
    on GG and are guaranteed to get 2-5 additional goodies from the PIX Assets. Further, if you own a gold badge you also
    get 100 Astro Credits

    First, he calls

        let newID = contract.createContentCategory(18);

    Now, he wants there to be a 50% chance of nothing and a 50% chance of 1 token id 19 on GG, so he calls

        contract.setContentAmounts(18, newId, [1, 0], [10,10]);

    Since there is only one possibility for the contents, he calls

        contract.setContents(18, newId, [GG_address], [19], [1], [1]);

    Next, he configures the PIX asset goodies. Thus, he creates a content category

        let newID2 = contract.createContentCategory(18);

    Then, he sets the content amounts

        contract.setContentAmounts(18, newId2, [2, 3, 4, 5], [10,20, 20,10]);

    Finally, he sets the possible contents

        contract.setContents(18, newId2,
                        [asset_address,
                         asset_address,
                         asset_address],
                         [astro_credit_id
                          biomod_legendary_id
                          blueprint_id],
                         [100, 1, 1],
                         [100, 20, 10]);

    For the gold badge = astro credits, the admin has created a conditional provider along the lines of

        function isEligible(address _address) external view returns (bool _isEligible){
            _isEligible = IERC1555(pixAssets).balanceOf(_address, gold_badge_id) > 0;
        }

   He creates a new category with the contents as previously described, then he calls

       contract.setContentEligibility(18, id3, conditionalProvider.address);

    Finally, the admin whitelists the token for burning

        contract.whitelistToken(18, true);

    */

    error GB__ZeroWeight();
    error GB_ZeroAmount();
    error GB__TokenNotWhitelisted(uint256 _tokenId);
    error GB__InvalidCategoryId(uint256 _categoryId);
    error GB__NotERC721or1155(address _tokenAddress);
    error GB__ArraysNotSameLength();
    error GB__NotConditionalProvider(address _address);
    error GB__NotGov(address _address);
    error GB__NotEligible(address _address);
    error GB__NotOracle();
    error GB__ZeroAddress();
    error GB__MaxDrawsExceeded(uint256 _amount);
    /**
     * @notice Event emitted upon opening packs
     * @param _opener The address of the opener
     * @param _tokenId The tokenid that was "opened"
     * @param _numPacks The number of tokens that were "opened"
     */
    event PackOpened(address _opener, uint256 _tokenId, uint256 _numPacks);
    /**
     * @notice Event emitted when a category is whitelisted
     * @param _tokenId The id of the token
     * @param _isWhitelisted Whether it's burnable
     */
    event TokenWhitelisted(uint256 _tokenId, bool _isWhitelisted);
    /**
     * @notice Event emitted when a category is created
     * @param _tokenId The token id a category has been created for
     * @param _categoryId The id of the new category
     */
    event CategoryCreated(uint256 _tokenId, uint256 _categoryId);
    /**
     * @notice Event emitted when a category is deleted
     * @param _tokenId The token id a category has been deleted for
     * @param _categoryId The id of the deleted category
     */
    event CategoryDeleted(uint256 _tokenId, uint256 _categoryId);
    /**
     * @notice Event emitted when a category has its eligibility updated
     * @param _tokenId The token id which the category belongs to
     * @param _categoryId The id of the category
     * @param _provider The address of the eligibility provider
     */
    event CategoryEligibilitySet(uint256 _tokenId, uint256 _categoryId, address _provider);
    /**
     * @notice Event emitted when a categories content amounts are updated
     * @param _tokenId The token id of the token
     * @param _categoryId The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentAmountsUpdated(
        uint256 _tokenId,
        uint256 _categoryId,
        uint256[] _amounts,
        uint256[] _weights
    );
    /**
     * @notice Event emitted when the contents of a category are updated
     * @param _tokenId The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _tokens Array of addresses to the content tokens.
     * @param _tokenIds Tokens ids of contents. Will be ignored if the token is an ERC721
     * @param _amounts Array containing the amounts of each tokens
     * @param _weights Array containing the weights, corresponding by index.
     */
    event ContentsUpdated(
        uint256 _tokenId,
        uint256 _contentCategory,
        address[] _tokens,
        uint256[] _tokenIds,
        uint256[] _amounts,
        uint256[] _weights
    );

    struct ContentCategory {
        uint256 id;
        uint256 contentAmountsTotalWeight;
        uint256 contentsTotalWeight;
        uint256[] contentAmounts;
        uint256[] contentAmountsWeights;
        uint256[] tokenAmounts;
        uint256[] tokenWeights;
        address[] tokens;
        uint256[] tokenIds;
    }

    /**
     * @notice Burns the "pack" thus "opening" it
     * @param _tokenId The tokenId of the pack to burn
     * @param _amount The amount of tokens to burn
     * @param _optIn whether or not the user wants to check eligibility for categories with such requirements
     *
     * Throws GB__TokenNotWhitelisted on non whitelisted token
     *
     */
    function burnPack(
        uint256 _tokenId,
        uint32 _amount,
        bool _optIn
    ) external;

    /**
     * @notice Used to set whether a token is burnable by this contract
     * @param _tokenId The id of the token
     * @param _isWhitelisted Whether it's burnable
     *
     * Throws GB__NotGov on non gov call
     *
     * Emits TokenWhitelisted
     */
    function whitelistToken(uint256 _tokenId, bool _isWhitelisted) external;

    /**
     * @notice Used to create a content category
     * @param _tokenId The token id to create a category for
     * @return _categoryId The new ID of the content category
     *
     * Throws GB__NotGov on non gov call
     *
     * Emits CategoryCreated
     */
    function createContentCategory(uint256 _tokenId) external returns (uint256 _categoryId);

    /**
     * @notice Deletes a content category
     * @param _tokenId The token id
     * @param _contentCategory The content category ID
     *
     * Throws GB__NotGov on non gov call
     * Throws GB__InvalidCategoryId on invalid category ID
     *
     * Emits CategoryDeleted
     */
    function deleteContentCategory(uint256 _tokenId, uint256 _contentCategory) external;

    /**
     * @notice Used to set eligibility conditions for a content category
     * @param _tokenId The token id
     * @param _categoryId The category id
     * @param _conditionalProvider Address to contract implementing ConditionalProvider
     *
     * Throws GB__NotGov on non gov call
     * Throws GB__NotConditionalProvider on _conditionalProvider not implementing ConditionalProvider or erc165
     *
     * Emits CategoryEligibilitySet
     */
    function setContentEligibility(
        uint256 _tokenId,
        uint256 _categoryId,
        address _conditionalProvider
    ) external;

    /**
     * @notice Used to get the content categories for a token
     * @param _tokenId The token id
     * @return _categories Array of ContentCategory structs corresponding to the given id
     */
    function getContentCategories(uint256 _tokenId)
        external
        view
        returns (ContentCategory[] calldata _categories);

    /**
     * @notice Used to edit the content amounts for a content category
     * @param _tokenId The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _amounts Array containing the amounts
     * @param _weights Array containing the weights, corresponding by index.
     *
     * Throws GB__NotGov on non gov call.
     * Throws GB__ZeroWeight on any weight being zero
     * @dev Does not throw anything on zero amounts
     * Throws GB__InvalidCategoryId on invalid category ID
     * Throws GB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentAmountsUpdated
     */
    function setContentAmounts(
        uint256 _tokenId,
        uint256 _contentCategory,
        uint256[] memory _amounts,
        uint256[] memory _weights
    ) external;

    /**
     * @notice Used to edit the contents for a content category
     * @dev _tokens needs to be erc1155 or erc 721 implementing ITrustedMintable
     * @param _tokenId The token id of the token
     * @param _contentCategory The category Id of a token
     * @param _tokens Array of addresses to the content tokens.
     * @param _tokenIds Tokens ids of contents. Will be ignored if the token is an ERC721
     * @param _amounts Array containing the amounts of each tokens
     * @param _weights Array containing the weights, corresponding by index.
     *
     * Throws GB__NotGov on non gov call.
     * Throws GB__ZeroWeight on any weight being zero
     * Throws GB__ZeroAmount on any amount being zero
     * Throws GB__InvalidCategoryId on invalid category ID
     * Throws GB__NotERC721or1155 on any address not being an erc1155 or erc721 token
     * Throws GB__ArraysNotSameLength on arrays not being same length
     *
     * Emits ContentsUpdated
     */
    function setContents(
        uint256 _tokenId,
        uint256 _contentCategory,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts,
        uint256[] memory _weights
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}