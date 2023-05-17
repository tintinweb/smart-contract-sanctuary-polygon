// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./operatorfilterer/DefaultOperatorFilterer.sol";

contract MallCard is ERC1155, ERC2981, DefaultOperatorFilterer, Ownable {
    using SafeERC20 for IERC20;

    struct ClaimDefinition {
        bytes32 merkleRootHash;
        uint256 startTime;
        uint256 endTime;
        bool revoked;
    }
    struct ClaimData {
        uint256 claimRecordIndex;
        uint256 silverAmount;
        uint256 goldAmount;
        uint256 diamondAmount;
        uint256 userExpireDate;
        bytes32[] merkleProof;
    }
    struct ReflinkUsage {
        address from;
        address to;
        uint256 token;
        uint256 amount;
        uint256 price;
        uint256 discount;
        string refCode;
    }
    struct Token {
        uint256 maxSupply;
        uint256 totalClaim;
        uint256 totalSale;
        mapping(uint256 => uint256) tierSales;
        uint256[] limits;
        uint256[] prices;
    }
    struct TokenSummary {
        uint256 token;
        uint256 currentPrice;
        uint256 discount;
        uint256 currentTier;
        uint256 maxSupply;
        uint256 totalClaim;
        uint256 totalSale;
        uint256[] tierSales;
        uint256[] limits;
        uint256[] prices;
    }
    struct TokenAmount {
        uint256 token;
        uint256 amount;
    }

    ClaimDefinition[] public claimDefinitions;
    mapping(uint256 => mapping(address => bool)) public claimRecords;

    uint256 public constant SILVER = 0;
    uint256 public constant GOLD = 1;
    uint256 public constant DIAMOND = 2;
    address public constant NATIVE_COIN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint private constant TOKEN_LEN = 3;

    IERC20 public tokenContract;
    ReflinkUsage[] public reflinkRecords;
    mapping(uint256 => bool) public paused;
    mapping(uint256 => Token) public tokens;
    mapping(uint256 => uint256) public discountRates;
    mapping(address => uint256[]) public reflinkSourceRecords;
    mapping(uint256 => string) public tokenURIs;

    bool public useTicketBasedDiscountRates;

    uint256 public publicSaleStart;
    uint256 public transferOpenDate;
    uint256 public discountRate;

    address public mintIncomeWaletContract;

    string public name = "MallCard Genesis Edition";
    string public symbol = "mCard";

    event Claim(address indexed owner, TokenAmount[] claimed);

    event TokenMint(
        address indexed owner,
        uint256 token,
        uint256 amount,
        uint256 price,
        uint256 discount,
        address reflinkOwner,
        string refCode
    );

    event SetPrices(uint256[][] prices);

    event SetLimits(uint256[][] limits);

    event Pause(uint256[] ids);

    event Unpause(uint256[] ids);

    event SetURI(uint256 indexed id, string uri);

    event SetTokenContract(address tokenContract);

    event SetDiscountRate(uint256 discountRate);

    event SetPublicSaleStart(uint256 transferOpenDate);

    event SetTransferOpenDate(uint256 publicSaleStart);

    event SetMaxSupplies(uint256 silver, uint256 gold, uint256 diamond);

    event SetMintIncomeWalletContract(address mintIncomeWaletContract);

    event SetRoyaltyInfo(address receiver, uint96 feeNumerator);

    event CreateClaim(ClaimDefinition claims);

    event RevokeClaim(uint256 indexed index);

    error ZeroAddress();
    error LengthMismatch();
    error InvalidDate();
    error TicketTransferNotOpen();
    error TicketTransferNotAllowed();
    error EmptyURI();
    error InvalidTokenId();
    error InvalidMerkleRootHash();
    error StartTimeMustBeFuture();
    error EndTimeMustBeLaterThenStart();
    error InvalidClaimIndex();
    error ClaimAlreadyRevoked();
    error ClaimExpired();
    error EmptyClaimParamData();
    error InvalidClaimData();
    error AlreadyClaimed();
    error ClaimNotStarted();
    error SaleClosed();
    error PublicSaleNotStarted();
    error InvalidValueInTransaction();
    error InvalidReferralCode();
    error InvalidReferralAddress();
    error InsufficientSupply();
    error SelfReferral();

    constructor(
        address _tokenContract,
        address _royaltyWaletContract,
        address _mintIncomeWalletContract,
        uint256 _publicSaleStart,
        uint96 _royalty,
        uint256 _discountRate
    ) ERC1155("") {
        if (
            _tokenContract == address(0) ||
            _royaltyWaletContract == address(0) ||
            _mintIncomeWalletContract == address(0)
        ) {
            revert ZeroAddress();
        }
        if (_publicSaleStart == 0) {
            setPublicSaleStart(block.timestamp);
        } else {
            setPublicSaleStart(_publicSaleStart);
        }
        discountRate = _discountRate;
        mintIncomeWaletContract = _mintIncomeWalletContract;
        _setDefaultRoyalty(_royaltyWaletContract, _royalty);

        tokenContract = IERC20(_tokenContract);
    }

    // Modifiers
    modifier salesOpen(uint256 _id) {
        if (paused[_id]) {
            revert SaleClosed();
        }
        if (publicSaleStart > block.timestamp) {
            revert PublicSaleNotStarted();
        }
        _;
    }

    // Write Functions
    function setURI(uint256 _id, string calldata _uri) public onlyOwner {
        if (bytes(_uri).length == 0) {
            revert EmptyURI();
        }
        if (_id >= TOKEN_LEN) {
            revert InvalidTokenId();
        }
        tokenURIs[_id] = _uri;
        emit SetURI(_id, _uri);
    }

    function setURIs(string[] calldata _uris) external onlyOwner {
        for (uint256 i = 0; i < _uris.length; i++) {
            setURI(i, _uris[i]);
        }
    }

    function setTokenContract(address _tokenContract, uint256[][] calldata _prices) external onlyOwner {
        if (_tokenContract == address(0)) {
            revert ZeroAddress();
        }
        tokenContract = IERC20(_tokenContract);
        emit SetTokenContract(_tokenContract);
        _setPrices(_prices);
    }

    function setDiscountRate(uint256 _discountRate) external onlyOwner {
        discountRate = _discountRate;
        emit SetDiscountRate(_discountRate);
    }

    function setTicketBasedDiscountRates(uint256[] calldata _discountRates, bool _enabled) external onlyOwner {
        if (_discountRates.length != TOKEN_LEN) {
            revert LengthMismatch();
        }
        useTicketBasedDiscountRates = _enabled;
        for (uint256 r = 0; r < _discountRates.length; r++) {
            discountRates[r] = _discountRates[r];
        }
    }

    function setTransferOpenDate(uint256 _transferOpenDate) external onlyOwner {
        if (_transferOpenDate < block.timestamp) {
            revert InvalidDate();
        }
        transferOpenDate = _transferOpenDate;
        emit SetTransferOpenDate(_transferOpenDate);
    }

    function setPublicSaleStart(uint256 _publicSaleStart) public onlyOwner {
        if (_publicSaleStart < block.timestamp) {
            revert InvalidDate();
        }
        publicSaleStart = _publicSaleStart;
        emit SetPublicSaleStart(_publicSaleStart);
    }

    function _setMaxSupplies(uint256[] memory _maxSupplies) private {
        if (_maxSupplies.length != TOKEN_LEN) {
            revert LengthMismatch();
        }
        tokens[SILVER].maxSupply = _maxSupplies[SILVER];
        tokens[GOLD].maxSupply = _maxSupplies[GOLD];
        tokens[DIAMOND].maxSupply = _maxSupplies[DIAMOND];
        emit SetMaxSupplies(_maxSupplies[SILVER], _maxSupplies[GOLD], _maxSupplies[DIAMOND]);
    }

    function setMaxSupplies(uint256 _silver, uint256 _gold, uint256 _diamond) external onlyOwner {
        uint256[] memory _maxSupplies = new uint256[](TOKEN_LEN);
        _maxSupplies[SILVER] = _silver;
        _maxSupplies[GOLD] = _gold;
        _maxSupplies[DIAMOND] = _diamond;
        _setMaxSupplies(_maxSupplies);
    }

    function setMintIncomeWalletContract(address _mintIncomeWaletContract) external onlyOwner {
        if (_mintIncomeWaletContract == address(0)) {
            revert ZeroAddress();
        }

        mintIncomeWaletContract = _mintIncomeWaletContract;
        emit SetMintIncomeWalletContract(_mintIncomeWaletContract);
    }

    function setRoyaltyInfo(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
        emit SetRoyaltyInfo(_receiver, _feeNumerator);
    }

    function _setPrices(uint256[][] memory _prices) private {
        if (_prices.length != TOKEN_LEN) {
            revert LengthMismatch();
        }
        for (uint256 r = 0; r < _prices.length; r++) {
            tokens[r].prices = _prices[r];
        }

        emit SetPrices(_prices);
    }

    function _setPricesAndLimits(uint256[][] memory _prices, uint256[][] memory _limits) private {
        if (_prices.length != TOKEN_LEN || _limits.length != TOKEN_LEN) {
            revert LengthMismatch();
        }

        for (uint256 r = 0; r < _prices.length; r++) {
            if (_limits[r].length != _prices[r].length) {
                revert LengthMismatch();
            }
            tokens[r].prices = _prices[r];
            tokens[r].limits = _limits[r];
        }
        emit SetPrices(_prices);
        emit SetLimits(_limits);
    }

    function setPrices(uint256[][] calldata _prices) external onlyOwner {
        _setPrices(_prices);
    }

    function setPricesAndLimits(uint256[][] calldata _prices, uint256[][] calldata _limits) external onlyOwner {
        _setPricesAndLimits(_prices, _limits);
    }

    function setPricesAndSupplies(
        uint256[][] calldata _prices,
        uint256[][] calldata _limits,
        uint256[] calldata _maxSupplies
    ) external onlyOwner {
        _setPricesAndLimits(_prices, _limits);
        _setMaxSupplies(_maxSupplies);
    }

    function pause(uint256[] calldata _ids) external onlyOwner {
        if (_ids.length > TOKEN_LEN) {
            revert LengthMismatch();
        }
        for (uint256 r = 0; r < _ids.length; r++) {
            paused[_ids[r]] = true;
        }
        emit Pause(_ids);
    }

    function unpause(uint256[] calldata _ids) external onlyOwner {
        if (_ids.length > TOKEN_LEN) {
            revert LengthMismatch();
        }
        for (uint256 i = 0; i < _ids.length; i++) {
            paused[_ids[i]] = false;
        }
        emit Unpause(_ids);
    }

    function createClaim(bytes32 _merkleRootHash, uint256 _startTime, uint256 _endTime) external onlyOwner {
        if (_merkleRootHash.length == 0) {
            revert InvalidMerkleRootHash();
        }
        if (_startTime < block.timestamp) {
            revert StartTimeMustBeFuture();
        }
        if (_endTime <= _startTime) {
            revert EndTimeMustBeLaterThenStart();
        }
        ClaimDefinition memory _claimRecord = ClaimDefinition({
            merkleRootHash: _merkleRootHash,
            startTime: _startTime,
            endTime: _endTime,
            revoked: false
        });
        claimDefinitions.push(_claimRecord);
        emit CreateClaim(_claimRecord);
    }

    function revokeClaim(uint256 _index) external onlyOwner {
        if (_index >= claimDefinitions.length) {
            revert InvalidClaimIndex();
        }
        if (claimDefinitions[_index].revoked) {
            revert ClaimAlreadyRevoked();
        }
        if (claimDefinitions[_index].endTime <= block.timestamp) {
            revert ClaimExpired();
        }
        claimDefinitions[_index].revoked = true;
        emit RevokeClaim(_index);
    }

    function _transferIncome(uint256 _price) private {
        if (address(tokenContract) == NATIVE_COIN) {
            if (_price != msg.value) {
                revert InvalidValueInTransaction();
            }
            payable(mintIncomeWaletContract).transfer(msg.value);
        } else {
            tokenContract.safeTransferFrom(msg.sender, mintIncomeWaletContract, _price);
        }
    }

    modifier ifSupplySufficient(uint256 _id) {
        uint256 _tier = _currentTier(_id);
        if (tokens[_id].maxSupply != 0) {
            if (_remainingToken(_id) == 0) {
                revert InsufficientSupply();
            }
        }

        if (tokens[_id].limits[_tier] != 0) {
            if (tokens[_id].limits[_tier] == (tokens[_id].tierSales[_tier])) {
                revert InsufficientSupply();
            }
        }
        _;
    }

    function mint(uint256 _id) external payable salesOpen(_id) ifSupplySufficient(_id) {
        (uint256 _price, , uint256 _tier) = getCurrentPrice(_id, address(0));
        _transferIncome(_price);
        _mint(msg.sender, _id, 1, "");
        tokens[_id].totalSale = tokens[_id].totalSale + 1;
        tokens[_id].tierSales[_tier] = tokens[_id].tierSales[_tier] + 1;

        emit TokenMint(msg.sender, _id, 1, _price, 0, address(0), "");
    }

    function mintWithReflink(
        address _referral,
        uint256 _id,
        string calldata _refCode
    ) external payable salesOpen(_id) ifSupplySufficient(_id) {
        if (_referral == address(0)) {
            revert InvalidReferralAddress();
        }
        if (bytes(_refCode).length == 0) {
            revert InvalidReferralCode();
        }
        (uint256 _price, uint256 _discount, uint256 _tier) = getCurrentPrice(_id, _referral);
        _transferIncome(_price - _discount);
        _mint(msg.sender, _id, 1, bytes(_refCode));
        tokens[_id].totalSale = tokens[_id].totalSale + 1;
        tokens[_id].tierSales[_tier] = tokens[_id].tierSales[_tier] + 1;
        if (_discount > 0) {
            ReflinkUsage memory _reflinkRecord = ReflinkUsage({
                from: _referral,
                to: msg.sender,
                token: _id,
                refCode: _refCode,
                amount: 1,
                price: _price,
                discount: _discount
            });
            reflinkSourceRecords[_reflinkRecord.from].push(reflinkRecords.length);
            reflinkRecords.push(_reflinkRecord);
        }
        emit TokenMint(msg.sender, _id, 1, _price, _discount, _referral, _refCode);
    }

    function claim(ClaimData[] calldata _claimDatas) external {
        if (_claimDatas.length == 0) {
            revert EmptyClaimParamData();
        }
        uint256 _claimedSilverAmount = 0;
        uint256 _claimedGoldAmount = 0;
        uint256 _claimedDiamondAmount = 0;
        for (uint i = 0; i < _claimDatas.length; i++) {
            ClaimData memory _claimData = _claimDatas[i];
            uint256 _claimRecordIndex = _claimData.claimRecordIndex;
            if (claimRecords[_claimRecordIndex][msg.sender]) {
                revert AlreadyClaimed();
            }
            claimRecords[_claimRecordIndex][msg.sender] = true;
            if (claimDefinitions[_claimRecordIndex].startTime > block.timestamp) {
                revert ClaimNotStarted();
            }
            if (claimDefinitions[_claimRecordIndex].endTime <= block.timestamp) {
                revert ClaimExpired();
            }
            if (claimDefinitions[_claimRecordIndex].revoked) {
                revert ClaimAlreadyRevoked();
            }

            uint256 _userExpireDate = _claimData.userExpireDate;
            if (_userExpireDate <= block.timestamp) {
                revert ClaimExpired();
            }
            uint256 _silverAmount = _claimData.silverAmount;
            uint256 _goldAmount = _claimData.goldAmount;
            uint256 _diamondAmount = _claimData.diamondAmount;
            bytes32[] memory _merkleProof = _claimData.merkleProof;

            bytes32 _leaf = keccak256(
                abi.encodePacked(
                    msg.sender,
                    _claimRecordIndex,
                    _silverAmount,
                    _goldAmount,
                    _diamondAmount,
                    _userExpireDate
                )
            );
            if (!MerkleProof.verify(_merkleProof, claimDefinitions[_claimRecordIndex].merkleRootHash, _leaf)) {
                revert InvalidClaimData();
            }
            _claimedSilverAmount += _silverAmount;
            _claimedGoldAmount += _goldAmount;
            _claimedDiamondAmount += _diamondAmount;
        }
        _claimedSilverAmount = _minSupply(SILVER, _claimedSilverAmount);
        _claimedGoldAmount = _minSupply(GOLD, _claimedGoldAmount);
        _claimedDiamondAmount = _minSupply(DIAMOND, _claimedDiamondAmount);

        uint256 _totalClaim = _claimedSilverAmount + _claimedGoldAmount + _claimedDiamondAmount;
        if (_totalClaim == 0) {
            revert InsufficientSupply();
        }
        uint256[] memory _amounts = new uint256[](TOKEN_LEN);
        uint256[] memory _ids = new uint256[](TOKEN_LEN);

        _amounts[0] = _claimedSilverAmount;
        _amounts[1] = _claimedGoldAmount;
        _amounts[2] = _claimedDiamondAmount;

        TokenAmount[] memory _claimed = new TokenAmount[](TOKEN_LEN);
        for (uint256 i = 0; i < TOKEN_LEN; i++) {
            if (tokens[i].maxSupply > 0 && _amounts[i] > _remainingToken(i)) {
                revert InsufficientSupply();
            }
            _ids[i] = i;
            _claimed[i] = TokenAmount({token: i, amount: _amounts[i]});
            tokens[i].totalClaim += _amounts[i];
        }

        _mintBatch(msg.sender, _ids, _amounts, "");

        emit Claim(msg.sender, _claimed);
    }

    // View Functions
    function getClaimRecordCount() public view returns (uint256) {
        return claimDefinitions.length;
    }

    function getTokenInfo(
        uint256 _id
    )
        public
        view
        returns (
            uint256 maxSupply,
            uint256 totalClaim,
            uint256 totalSale,
            uint256[] memory tierSales,
            uint256[] memory limits,
            uint256[] memory prices
        )
    {
        maxSupply = tokens[_id].maxSupply;
        totalClaim = tokens[_id].totalClaim;
        totalSale = tokens[_id].totalSale;
        tierSales = new uint256[](tokens[_id].limits.length);
        limits = new uint256[](tokens[_id].limits.length);
        prices = new uint256[](tokens[_id].limits.length);
        for (uint256 i = 0; i < limits.length; i++) {
            tierSales[i] = tokens[_id].tierSales[i];
            limits[i] = tokens[_id].limits[i];
            prices[i] = tokens[_id].prices[i];
        }
    }

    function getTokenSummary(address _referral) public view returns (TokenSummary[] memory total) {
        total = new TokenSummary[](TOKEN_LEN);
        for (uint256 i = 0; i < TOKEN_LEN; i++) {
            (uint256 _price, uint256 _discount, uint256 _tier) = getCurrentPrice(i, _referral);
            (
                uint256 _maxSupply,
                uint256 _totalClaim,
                uint256 _totalSale,
                uint256[] memory _tierSales,
                uint256[] memory _limits,
                uint256[] memory _prices
            ) = getTokenInfo(i);
            TokenSummary memory _s = TokenSummary({
                token: i,
                currentPrice: _price,
                discount: _discount,
                currentTier: _tier,
                maxSupply: _maxSupply,
                totalClaim: _totalClaim,
                totalSale: _totalSale,
                tierSales: _tierSales,
                limits: _limits,
                prices: _prices
            });

            total[i] = _s;
        }
    }

    function getBalanceInfo(address _address) public view returns (TokenAmount[] memory amounts) {
        amounts = new TokenAmount[](TOKEN_LEN);
        for (uint256 i = 0; i < TOKEN_LEN; i++) {
            amounts[i] = TokenAmount({token: i, amount: balanceOf(_address, i)});
        }
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return tokenURIs[_id];
    }

    function reflinkUsageCount() external view returns (uint256) {
        return reflinkRecords.length;
    }

    function userReflinkRecords(address _referral) external view returns (uint256[] memory) {
        return reflinkSourceRecords[_referral];
    }

    function userReflinkCount(address _referral) external view returns (uint256) {
        return reflinkSourceRecords[_referral].length;
    }

    function getCurrentPrice(
        uint256 _id,
        address _referral
    ) public view returns (uint256 price, uint256 discount, uint256 tier) {
        tier = _currentTier(_id);
        price = tokens[_id].prices[tier];

        // discount can only be appliable for public sale prices
        if (_referral != address(0) && tier == (tokens[_id].limits.length - 1)) {
            discount = _getReflinkDiscount(_referral, price);
        }
    }

    function _minSupply(uint256 _id, uint256 _requested) private view returns (uint256 _min) {
        if (_requested > 0) {
            uint256 _max = tokens[_id].maxSupply > 0 ? _remainingToken(_id) : _requested;
            _min = _requested < _max ? _requested : _max;
        }
    }

    function _remainingToken(uint256 _id) private view returns (uint256 _remaining) {
        if (tokens[_id].maxSupply > 0 && tokens[_id].maxSupply > (tokens[_id].totalClaim + tokens[_id].totalSale)) {
            _remaining = tokens[_id].maxSupply - tokens[_id].totalClaim - tokens[_id].totalSale;
        }
    }

    function _getReflinkDiscount(address _from, uint256 _price) private view returns (uint256) {
        if (_from == msg.sender) {
            revert SelfReferral();
        }
        uint256 _discountRate = 0;
        if (useTicketBasedDiscountRates) {
            for (uint256 r = TOKEN_LEN; r > 0; r--) {
                uint256 _balance = balanceOf(_from, r - 1);
                if (_balance > 0) {
                    _discountRate = discountRates[r - 1];
                    break;
                }
            }
        } else {
            _discountRate = discountRate;
        }

        return (_price * _discountRate) / _feeDenominator();
    }

    function _currentTier(uint256 _id) private view returns (uint256 _tier) {
        _tier = tokens[_id].limits.length - 1;
        for (uint256 i = 0; i < tokens[_id].limits.length; i++) {
            if (tokens[_id].limits[i] == 0 || tokens[_id].tierSales[i] < tokens[_id].limits[i]) {
                _tier = i;
                break;
            }
        }
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory ids,
        uint256[] memory,
        bytes memory
    ) internal virtual override(ERC1155) {
        if (from != address(0)) {
            if (transferOpenDate == 0 || transferOpenDate > block.timestamp) {
                revert TicketTransferNotOpen();
            }
            for (uint256 i = 0; i < ids.length; i++) {
                if (ids[i] == SILVER) {
                    revert TicketTransferNotAllowed();
                }
            }
        }
    }

    //Royaltı registry
    function setOperatorFiltering(bool enabled) public onlyOwner {
        _operatorFiltering = enabled;
    }

    function registerOperatorFilter(
        address registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) public onlyOwner {
        _registerOperatorFilter(registry, subscriptionOrRegistrantToCopy, subscribe);
    }

    function unregisterOperatorFilter(address registry) public onlyOwner {
        _unregisterOperatorFilter(registry);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC1155) onlyAllowedOperatorApproval(operator) {
        if (transferOpenDate == 0 || transferOpenDate > block.timestamp) {
            revert TicketTransferNotOpen();
        }
        ERC1155.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override(ERC1155) onlyAllowedOperator(from) {
        ERC1155.safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override(ERC1155) onlyAllowedOperator(from) {
        ERC1155.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    //royalty support
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
     * Emits a {TransferBatch} event.
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
     * Emits a {TransferSingle} event.
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
     * Emits a {TransferBatch} event.
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
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {OperatorFilterer} from "./OperatorFilterer.sol";

contract DefaultOperatorFilterer is OperatorFilterer {
    // constructor(
    //     address registry,
    //     address subscription
    // ) OperatorFilterer(registry, subscription, true) {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import "../v1/util/ArrayFind.sol";
import "../v1/util/Types.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    using ArrayFind for address;
    OperatorRegistry[] public _operatorRegistries;
    bool _operatorFiltering = true;

    /// @dev The constructor that is called when the contract is being deployed.
    // constructor(
    //     address registry,
    //     address subscriptionOrRegistrantToCopy,
    //     bool subscribe
    // ) {
    //     _registerOperatorFilter(registry, subscriptionOrRegistrantToCopy, subscribe);
    // }

    function _registerOperatorFilter(
        address registry,
        address subscriptionOrRegistrantToCopy,
        bool subscribe
    ) internal virtual {
        if (registry.code.length == 0) return;

        IOperatorFilterRegistry filterRegistry = IOperatorFilterRegistry(
            registry
        );

        if (subscribe) {
            filterRegistry.registerAndSubscribe(
                address(this),
                subscriptionOrRegistrantToCopy
            );
        } else {
            if (subscriptionOrRegistrantToCopy != address(0)) {
                filterRegistry.registerAndCopyEntries(
                    address(this),
                    subscriptionOrRegistrantToCopy
                );
            } else {
                filterRegistry.register(address(this));
            }
        }

        _operatorRegistries.push(
            OperatorRegistry(
                registry,
                subscribe ? subscriptionOrRegistrantToCopy : address(0)
            )
        );
    }

    function _unregisterOperatorFilter(address registry) internal virtual {
        IOperatorFilterRegistry(registry).unregister(address(this));

        uint256 ind;
        uint256 len = _operatorRegistries.length;
        for (uint i = 0; i < len; i++) {
            if (_operatorRegistries[i].registry == registry) {
                ind = i + 1;
                break;
            }
        }

        if (ind == 0) return;
        if (ind < len)
            _operatorRegistries[ind - 1] = _operatorRegistries[len - 1];

        _operatorRegistries.pop();
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        if (!_operatorFiltering) return;

        bool ok = false;
        for (uint i = 0; i < _operatorRegistries.length; i++) {
            address registry = _operatorRegistries[i].registry;
            ok = IOperatorFilterRegistry(registry).isOperatorAllowed(
                address(this),
                operator
            );

            // only one operator allowance is enough
            if (ok) break;
        }

        // if there is no operator allowance
        if (!ok) {
            revert OperatorNotAllowed(operator);
        }
    }
}

struct OperatorRegistry {
    address registry;
    address subscription;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function unregister(address addr) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Types.sol";

library ArrayFind {
    function find(
        uint256[] memory arr,
        uint value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function find(
        bytes32[] memory arr,
        bytes32 value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function find(
        address[] memory arr,
        address value
    ) internal pure returns (uint256) {
        uint256 ind = IndexNotFound;
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                ind = i;
                break;
            }
        }

        return ind;
    }

    function exist(
        address[] memory arr,
        address value
    ) internal pure returns (bool) {
        return find(arr, value) != IndexNotFound;
    }

    function checkForDublicates(
        address[] memory arr
    ) internal pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            address _val = arr[i];

            for (uint j = i + 1; j < arr.length; j++) {
                if (arr[j] == _val) return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

uint256 constant IndexNotFound = 2 ^ (256 - 1);