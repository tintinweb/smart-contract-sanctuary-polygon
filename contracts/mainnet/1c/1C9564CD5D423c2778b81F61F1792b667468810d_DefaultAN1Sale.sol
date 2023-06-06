// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (tokens/phygital/DefaultAN1Sale.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "../access/OperatorAccessControlUpgradeable.sol";
import "../tokens/phygital/IPhygitalItems.sol";
import "./IAN1Sale.sol";
import "../lib/Sale.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract DefaultAN1Sale is
    OperatorAccessControlUpgradeable,
    PaymentSplitterUpgradeable,
    IAN1Sale,
    ERC721Holder
{
    IERC20 public erc20;
    AggregatorV3Interface public priceFeed;

    Sale.Period[] public salePeriods;

    Sale.Status public saleStatus;

    address public an1SaleAddress;

    mapping(address => mapping(uint256 => uint256)) numberMintedPerPeriod;

    uint[] heldTokens;

    /**
     * @dev Initializes the contract setting the basic collection parameters and.
     */
    function __DefaultAN1Sale_initialize(
        address _owner,
        address _an1SaleAddress,
        Sale.Period[] memory _salePeriods,
        address _eRC20address,
        address _priceFeedAddress,
        address[] memory payees,
        uint256[] memory shares_
    ) initializer public {
        __OperatorAccessControl_init_unchained(_owner);
        __PaymentSplitter_init_unchained(payees, shares_);
        __Ownable_init_unchained();
        _transferOwnership(_owner);

        __DefaultAN1Sale_initialize_unchained(
            _an1SaleAddress,
            _salePeriods,
            _eRC20address,
            _priceFeedAddress
        );
    }

    function __DefaultAN1Sale_initialize_unchained(
        address _an1SaleAddress,
        Sale.Period[] memory _salePeriods,
        address _eRC20address,
        address _priceFeedAddress
    ) initializer public {
        erc20 = IERC20(_eRC20address);
        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        an1SaleAddress = _an1SaleAddress;
        for (uint256 i = 0; i < _salePeriods.length; i++) {
            _addSalePeriod(_salePeriods[i]);
        }
    }

    /**
     * @dev See {IAN1Sale-mintTo}
     */
    function mint(
        uint256 _salePeriodIndex,
        uint256 _quantity,
        bytes32[] calldata _merkleProof,
        bool _payWithMatic
    ) external payable override {
        _mint(
            _salePeriodIndex,
            msg.sender,
            _quantity,
            _merkleProof,
            _payWithMatic
        );
    }

    /*
     * @dev See {IAN1Sale-mintTo}
     */
    function mintTo(
        uint256 _salePeriodIndex,
        address _beneficiary,
        uint256 _quantity,
        bytes32[] calldata _merkleProof,
        bool _payWithMatic
    ) external payable override {
        _mint(
            _salePeriodIndex,
            _beneficiary,
            _quantity,
            _merkleProof,
            _payWithMatic
        );
    }

    function _handlePayment(uint256 _usdPrice, bool _payWithMatic) internal {
        if (_payWithMatic) {
            uint256 maticPrice = _usdtPriceToMatic(_usdPrice);
            // deviation threshold 0.5%
            maticPrice = (maticPrice / 1000) * 995;
            require(
                msg.value >= maticPrice,
                "DefaultAN1Sale::mint: Value sent is insufficient"
            );
        } else {
            require(
                erc20.balanceOf(msg.sender) >= _usdPrice,
                "DefaultAN1Sale::mint: USDT balance is insufficient"
            );
            require(
                erc20.allowance(msg.sender, address(this)) >= _usdPrice,
                "DefaultAN1Sale::mint: USDT allowance is insufficient"
            );
            erc20.transferFrom(msg.sender, address(this), _usdPrice);
        }
    }

    /*
     * @dev Allow users to mint new tokens to the caller
     */
    function _mint(
        uint256 _salePeriodIndex,
        address _beneficiary,
        uint256 _quantity,
        bytes32[] calldata _merkleProof,
        bool _payWithMatic
    ) internal {
        require(
            saleStatus == Sale.Status.STARTED,
            "DefaultAN1Sale::mint: Sale has not started."
        );
        require(
            _quantity > 0,
            "DefaultAN1Sale::mint: Quantity must be greater than 0."
        );
        require(
            salePeriods.length > _salePeriodIndex,
            "DefaultAN1Sale::mint: Sale period not found."
        );
        Sale.Period memory salePeriod = salePeriods[_salePeriodIndex];
        require(
            salePeriod.timeTo > block.timestamp,
            "DefaultAN1Sale::mint: sale period is already over."
        );
        require(
            salePeriod.timeFrom < block.timestamp,
            "DefaultAN1Sale::mint: sale period hasn't started."
        );

        _handlePayment(salePeriod.price * _quantity, _payWithMatic);

        require(
            _quantity <= salePeriod.maxPerMint,
            "DefaultAN1Sale::mint: Must mint equal or less than maxPerMint."
        );
        require(
            salePeriod.maxAllocation >= salePeriod.totalMinted + _quantity,
            "DefaultAN1Sale::mint: Period allocation is not enough."
        );
        require(
            salePeriod.maxPerPeriod >=
                _quantity +
                    numberMintedPerPeriod[_beneficiary][_salePeriodIndex],
            "DefaultAN1Sale::mint: Address would be minting more than max allowed for this period."
        );

        if (salePeriod.saleType == Sale.Type.PRIVATE) {
            bytes32 node = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProofUpgradeable.verify(
                    _merkleProof,
                    salePeriod.merkleRoot,
                    node
                ),
                "DefaultAN1Sale::mint: Invalid merkle proof for PRIVATE sale."
            );
        }
        salePeriods[_salePeriodIndex].totalMinted += _quantity;
        numberMintedPerPeriod[_beneficiary][_salePeriodIndex] += _quantity;

        IPhygitalItems mintableToken = IPhygitalItems(
            an1SaleAddress
        );
        uint256 toMint = _quantity;

        if (heldTokens.length > 0) {
            uint256 min = _quantity <= heldTokens.length
                ? _quantity
                : heldTokens.length;
            for (uint256 i = 0; i < min; i++) {
                uint256 tokenId = heldTokens[heldTokens.length - 1];
                heldTokens.pop();
                toMint--;
                mintableToken.safeTransferFrom(
                    address(this),
                    _beneficiary,
                    tokenId
                );
            }
        }

        if (toMint > 0) {
            mintableToken.mintAndTransfer(_beneficiary, toMint);
        }
    }

    function requestRedemption(
        uint256 _tokenId,
        bool _payWithMatic,
        Fractal.Credential memory _cred
    ) external payable override {
        IPhygitalItems pi = IPhygitalItems(an1SaleAddress);
        require(
            pi.ownerOf(_tokenId) == msg.sender,
            "DefaultAN1Sale::requestRedemption: Caller must own the redeemed token."
        );

        _handlePayment(pi.getRedemptionWindow().redemptionPrice, _payWithMatic);
        pi.setState(
            _tokenId,
            IPhygitalItems.ItemStatus.MANUFACTURING,
            "",
            _cred
        );
    }

    function getAllowance() external view returns (uint256) {
        return erc20.allowance(msg.sender, address(this));
    }

    function getLatestPrice(uint256 _salePeriodIndex)
        public
        view
        returns (uint256)
    {
        Sale.Period memory salePeriod = salePeriods[_salePeriodIndex];
        return _usdtPriceToMatic(salePeriod.price);
    }

    function _getMaticPrice() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function _usdtPriceToMatic(uint256 usdtPrice)
        internal
        view
        returns (uint256)
    {
        return (usdtPrice * 1e20) / _getMaticPrice();
    }

    /**
     * @dev See {IAN1Sale-changeSaleStatus}
     * - new 'saleStatus' is different than 'NOT_STARTED'
     *
     * Emits {SaleStatusChanged} upon successful execution
     */
    function changeSaleStatus(Sale.Status _saleStatus)
        external
        override
        onlyOperator
    {
        require(
            saleStatus != Sale.Status.ENDED,
            "DefaultAN1Sale::changeSaleStatus: Sale has ended."
        );
        require(
            _saleStatus != Sale.Status.NOT_STARTED,
            "DefaultAN1Sale::changeSaleStatus: New status cannot be non started."
        );
        require(
            saleStatus != _saleStatus,
            "DefaultAN1Sale::changeSaleStatus: Status to change cannot be the same."
        );

        saleStatus = _saleStatus;
        emit SaleStatusChanged(_saleStatus, saleStatus);
    }

    /**
     * @dev See {IAN1Sale-listSalePeriods}
     */
    function listSalePeriods()
        external
        view
        override
        returns (Sale.Period[] memory)
    {
        return salePeriods;
    }

    /**
     * @dev See {IAN1Sale-addSalePeriods}
     */
    function addSalePeriods(Sale.Period[] memory _salePeriods)
        external
        override
        onlyOperator
    {
        require(
            saleStatus != Sale.Status.ENDED,
            "DefaultAN1Sale::addSalePeriods: Sale has ended."
        );

        for (uint256 i = 0; i < _salePeriods.length; i++) {
            _addSalePeriod(_salePeriods[i]);
        }
    }

    function _addSalePeriod(Sale.Period memory salePeriod) internal {
        require(
            salePeriod.timeTo > block.timestamp,
            "DefaultAN1Sale::addSalePeriods: Cannot create a period in the past."
        );
        salePeriod.isValid = true;
        salePeriod.totalMinted = 0;
        salePeriods.push(salePeriod);
        emit SalePeriodCreated(
            salePeriods.length - 1,
            salePeriod.saleType,
            salePeriod.timeFrom,
            salePeriod.timeTo
        );
    }

    /**
     * @dev See {IAN1Sale-disableSalePeriods}
     */
    function disableSalePeriods(uint256[] memory _indexes)
        external
        override
        onlyOperator
    {
        require(
            saleStatus != Sale.Status.ENDED,
            "DefaultAN1Sale::disableSalePeriod: Sale has ended."
        );

        for (uint256 i = 0; i < _indexes.length; i++) {
            require(
                salePeriods.length > _indexes[i],
                "DefaultAN1Sale::disableSalePeriod: Sale period not found."
            );
            Sale.Period memory salePeriod = salePeriods[_indexes[i]];
            require(
                salePeriod.timeTo > block.timestamp,
                "DefaultAN1Sale::disableSalePeriod: Period is already inactive."
            );
            salePeriods[_indexes[i]].isValid = false;
            emit SalePeriodUpdated(_indexes[i]);
        }
    }

    /**
     * @dev See {IAN1Sale-updateSalePeriods}
     */
    function updateSalePeriods(
        uint256[] memory _indexes,
        Sale.Period[] memory _salePeriods
    ) external override onlyOperator {
        require(
            saleStatus != Sale.Status.ENDED,
            "DefaultAN1Sale::updateSalePeriods: Sale has ended."
        );

        for (uint256 i = 0; i < _indexes.length; i++) {
            Sale.Period memory newSalePeriod = _salePeriods[i];
            require(
                salePeriods.length > _indexes[i],
                "DefaultAN1Sale::updateSalePeriods: Sale period not found."
            );
            require(
                salePeriods[_indexes[i]].isValid,
                "DefaultAN1Sale::updateSalePeriods: Period is not valid."
            );
            require(
                newSalePeriod.timeTo > block.timestamp,
                "DefaultAN1Sale::updateSalePeriods: New period should have valid dates."
            );
            require(
                salePeriods[_indexes[i]].totalMinted <=
                    newSalePeriod.maxAllocation,
                "DefaultAN1Sale::updateSalePeriods: New period allocation should be greater or equal than total minted."
            );

            salePeriods[_indexes[i]].timeFrom = newSalePeriod.timeFrom;
            salePeriods[_indexes[i]].timeTo = newSalePeriod.timeTo;
            salePeriods[_indexes[i]].merkleRoot = newSalePeriod.merkleRoot;
            salePeriods[_indexes[i]].maxAllocation = newSalePeriod
                .maxAllocation;
            salePeriods[_indexes[i]].maxPerMint = newSalePeriod.maxPerMint;
            salePeriods[_indexes[i]].maxPerPeriod = newSalePeriod.maxPerPeriod;
            salePeriods[_indexes[i]].price = newSalePeriod.price;
            emit SalePeriodUpdated(_indexes[i]);
        }
    }

    function getSaleInformation(address _userAddress, uint256 _salePeriodIndex)
        external
        view
        override
        returns (Sale.Information memory)
    {
        IPhygitalItems mintableToken = IPhygitalItems(
            an1SaleAddress
        );
        return
            Sale.Information({
                ethBalance: _userAddress.balance,
                erc20Balance: erc20.balanceOf(_userAddress),
                erc20Allowance: erc20.allowance(_userAddress, address(this)),
                userMintedInPeriod: numberMintedPerPeriod[_userAddress][
                    _salePeriodIndex
                ],
                totalMintedInPeriod: salePeriods[_salePeriodIndex].totalMinted,
                totalMintedInCollection: mintableToken.totalSupply(),
                maxMintableInCollection: mintableToken.mintLimit(),
                latestPriceInMatic: getLatestPrice(_salePeriodIndex),
                latestPriceInErc20: salePeriods[_salePeriodIndex].price
            });
    }

    function getRedemptionInformation(address _userAddress) external view returns (Sale.RedemptionInformation memory) {
        IPhygitalItems mintableToken = IPhygitalItems(
            an1SaleAddress
        );
        return
            Sale.RedemptionInformation({
                ethBalance: _userAddress.balance,
                erc20Balance: erc20.balanceOf(_userAddress),
                erc20Allowance: erc20.allowance(_userAddress, address(this)),
                latestPriceInMatic: _usdtPriceToMatic(mintableToken.getRedemptionWindow().redemptionPrice),
                latestPriceInErc20: mintableToken.getRedemptionWindow().redemptionPrice
            });
    }

    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(
            msg.sender == an1SaleAddress,
            "DefaultAN1Sale::onERC721Received: Sale contract only accepts the NFT tokens it sells."
        );
        require(
            IPhygitalItems(an1SaleAddress).ownerOf(tokenId) ==
                address(this),
            "DefaultAN1Sale::onERC721Received: Sale contract is not the owner of passed tokenId."
        );
        heldTokens.push(tokenId);
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (access/OperatorAccessControlUpgradeable.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title OperatorAccessControlUpgradeable contract
 *
 * @dev Contract module which provides operator access control mechanisms, where
 * there is a list of accounts (operators) that can be granted exclusive access to
 * specific priviliged functions.
 *
 * By default, the first operator account will be the one that deploys the contract.
 * This can later be changed by ussing the methods {addOperator}, {removeOperator} or
 * {addOperators}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to the functions with restricted access to
 * the operators.
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
abstract contract OperatorAccessControlUpgradeable is OwnableUpgradeable {

    // Mapping from operator address to status (true/false)
    mapping(address => bool) private operators;
    
    /**
     * @dev Emitted when `operators` values are changed.
     */
    event OperatorAccessChanged(address indexed operator, bool indexed status);

    /**
     * @dev Throws if called by any account other than operator.
     */
    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorAccessControl::onlyOperator: caller is not a operator.");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the owner and first operator.
     */
    function __OperatorAccessControl_init(address _owner) internal onlyInitializing {
        __Ownable_init();
        __OperatorAccessControl_init_unchained(_owner);
    }

    function __OperatorAccessControl_init_unchained(address _owner) internal onlyInitializing {
        _transferOwnership(_owner);
        _addOperator(_owner);
    }

    /**
     * @dev Adds `_operator` to the list of allowed operators.
     */
    function addOperator(address _operator) public onlyOwner {
        _addOperator(_operator);
    }

    /**
     * @dev Adds `_operator` to the list of allowed operators.
     * Internal function without access restriction.
     */
    function _addOperator(address _operator) internal virtual {
        operators[_operator] = true;
        emit OperatorAccessChanged(_operator, true);
    }

    /**
     * @dev Adds `_operators` to the list of allowed 'operators'.
     */
    function addOperators(address[] memory _operators) external onlyOwner {
        for (uint i = 0; i < _operators.length; i++) {
            address operator = _operators[i];
            operators[operator] = true;
            emit OperatorAccessChanged(operator, true);
        }
    }

    /**
     * @dev Revokes `_operator` from the list of allowed 'operators'.
     */
    function removeOperator(address _operator) external onlyOwner {
        operators[_operator] = false;
        emit OperatorAccessChanged(_operator, false);
    }

    /**
     * @dev Returns `true` if `_account` has been granted to operators.
     */
    function isOperator(address _account) public view returns (bool) {
        return operators[_account];
    }

    // gap for future versions
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (sale/IAN1Sale.sol)

pragma solidity ^0.8.4;

import "../lib/Sale.sol";
import "../lib/Fractal.sol";

/**
 * @title AN1 IAN1Sale interface, for AN1 launchpad sales
 *
 * Contains the basic methods and functionalities that will be used during the
 * sale launches of AN1 new collections.
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
interface IAN1Sale {
    /**
     * @dev Emitted when `saleStatus` value is changed from `_previous` to `_current`.
     */
    event SaleStatusChanged(Sale.Status _previous, Sale.Status _current);

    /**
     * @dev Emitted when a new `Sale.Period` is added to 'salePeriods'.
     */
    event SalePeriodCreated(
        uint256 indexed _index,
        Sale.Type indexed _saleType,
        uint256 _from,
        uint256 _to
    );

    /**
     * @dev Emitted when a sale period is changed.
     */
    event SalePeriodUpdated(uint256 indexed _index);

    /**
     * @dev Allow users to mint new tokens to the caller
     *
     * This function is payable and receives 'value' within the same messages.
     *
     * Requires
     * - Sale status must be different than ENDED
     * - There must be an active sale period
     * - 'quantity' must be greater than 0 and lower or equal than Sale.Period 'maxPerMint'
     * - 'quantity' plus 'numberMinted'/p period must be smaller or equal than 'maxPerPeriod'
     * - 'quantity' plus Sale.Period 'totalMinted' must be smaller or equal than 'maxAllocation'
     * - The value 'quantity' plus 'IAN1Mintable.totalSupply()' must be lower or equal than 'IAN1Mintable.mintLimit()' (validation already exists in AN1Mintable)
     * - 'msg.value' must be equal or greater than 'quantity' times Sale.Period 'price'
     * - If it's private sale, merkleProof has to have a value, and the verification
     *   will be done against the merkletree of the sale period
     * - If it's a private sale, and is not successfuly verified from the merkleProof, will check if
     */
    function mint(
        uint256 _salePeriodIndex,
        uint256 _quantity,
        bytes32[] memory _merkleProof,
        bool _mintWithMatic
    ) external payable;

    /*
     * @dev Mint tokens for another user
     *
     * @dev See {mint()}
     */
    function mintTo(
        uint256 _salePeriodIndex,
        address _beneficiary,
        uint256 _quantity,
        bytes32[] memory _merkleProof,
        bool _mintWithMatic
    ) external payable;

    /**
     * @dev Allow users to pay for redemption of the NFT into a physical item
     *
     * This function is payable and receives 'value' within the same messages.
     *
     * Requires
     * - the token needs to be in REDEEMABLE state (see: PhygitalItems contract)
     * - the redemption window needs to be open (see: PhygitalItems contract)
     * - the caller needs to be the owner of the redeemed token
     * - the value passed needs to be greater than usdRedemptionPrice
     */
    function requestRedemption(
        uint256 _tokenId,
        bool _payWithMatic,
        Fractal.Credential calldata _cred
    ) external payable;

    /**
     * @dev List all sale periods
     */
    function listSalePeriods() external view returns (Sale.Period[] memory);

    /**
     * @dev Changes the status of the sale.
     *
     * Requires:
     * - caller is an operator
     * - previous 'saleStatus' is different than new 'saleStatus'
     * - previous 'saleStatus' is different than 'ENDED'
     * - new 'saleStatus' is different than 'NON_STARTED'
     *
     * Emits {SaleStatusChanged} upon successful execution
     */
    function changeSaleStatus(Sale.Status _saleStatus) external;

    /**
     * @dev Allows the addition of multiple new sale periods to the sale.
     *
     * Requires:
     * - caller is operator
     *
     * Emits a {SalePeriodCreated} event per each period
     */
    function addSalePeriods(Sale.Period[] memory _salePeriods) external;

    /**
     * @dev Disables a sale period.
     *
     * Requires:
     * - caller is operator
     * - the index of the period exists
     * - the sale period is still valid
     * - the sale status is different than ENDED
     *
     * Emits {SalePeriodUpdated} upon successful execution
     */
    function disableSalePeriods(uint256[] memory _indexies) external;

    /**
     * @dev Updates a list of sale periods
     *
     * Disabled previous sale period, and creates a new one based on the information provided
     *
     * Requires:
     * - caller is operator
     *
     * Emits {SalePeriodUpdated} upon successful execution
     */
    function updateSalePeriods(
        uint256[] memory _indexes,
        Sale.Period[] memory _salePeriods
    ) external;

    function getSaleInformation(address _userAddress, uint256 _salePeriodIndex)
        external
        returns (Sale.Information memory);
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (lib/SaleLibrary.sol)

pragma solidity ^0.8.4;

/**
 * @title Sale library contract
 *
 * @dev Contract module which provides the basic structures to be used
 * in AN1 launchpad sale smart contracts.
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
library Sale {
    enum Type {
        PRIVATE, // 0
        PUBLIC   // 1
    }

    struct Period {
        Type    saleType;      // sale type
        uint256 timeFrom;      // unixtime start of the period
        uint256 timeTo;        // unixtime finalization of the period
        bytes32 merkleRoot;    // if it contains a whitelist
        uint256 maxAllocation; // max allocation for this period
        uint256 totalMinted;   // indicates the total minted during this period
        uint256 maxPerMint;    // indicates the max of items that a user can mint per transaction
        uint256 maxPerPeriod;  // indicates the max of items that a user can mint per sale period
        uint256 price;         // this value indicates the price in which the sales will be carried out
        bool    isValid;       // if period is invalidated cannot be reenabled, will keep the history
    }

    enum Status {
        NOT_STARTED, // 0
        STARTED,     // 1
        PAUSED,      // 2
        ENDED        // 3
    }

    struct Information {
        uint256 ethBalance;              // balance in matic
        uint256 erc20Balance;            // balance in erc20
        uint256 erc20Allowance;          // allowance in erc20 for the contract
        uint256 userMintedInPeriod;      // minted by user in that period
        uint256 totalMintedInPeriod;     // total minted in the period
        uint256 totalMintedInCollection; // total minted in the collection
        uint256 maxMintableInCollection; // max mintable in the collection
        uint256 latestPriceInMatic;      // price of NFT in matic
        uint256 latestPriceInErc20;      // price of NFT in erc20
    }

    struct RedemptionInformation {
        uint256 ethBalance;              // balance in matic
        uint256 erc20Balance;            // balance in erc20
        uint256 erc20Allowance;          // allowance in erc20 for the contract
        uint256 latestPriceInMatic;      // price of NFT in matic
        uint256 latestPriceInErc20;      // price of NFT in erc20
    }
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (tokens/phygital/IPhygitalItem.sol)

pragma solidity ^0.8.4;

import "../../lib/Fractal.sol";
import "../IMintableUpgradeable.sol";

/**
 * @title AN1 IPhygitalItem interface, standard for AN1 collections which are connected to physical items
 *
 * Contains the set of features that are necessary to handle phygital collections, including control
 * mechanisms for Physically Authenticated Actions (PAA).
 *
 * Phygital Items have a link between the digital reference (tokenId) and a physical reference
 * stored in a NFC chip. NFC chips have NFC ids.
 *
 * The nfcId is considered valid if:
 * - it’s at most 7 bytes (so less than 72,057,594,037,927,935). 7 bytes is NXPs UID size.
 * - it’s not 0x0, because this is how we denote “not assigned” in nfcId(uint tokenId)
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
interface IPhygitalItems is IMintableUpgradeable {

    struct RedemptionWindow {
        uint256 from;
        uint256 to;
        uint256 redemptionPrice;
    }

    /**
     * @dev Emitted whenever the state of a particular 'tokenId' changes.
     */
    event StateChanged(
        uint256 indexed tokenId,
        ItemStatus previousState,
        ItemStatus currentState
    );

    /**
     * @dev Emitted whenever a 'transfer' whitelist address is added or removed.
     */
    event TransferWhitelistChanged(address indexed _address, bool _isAdded);

    /**
     * @dev Emitted whenever a 'custodian' address is added or removed.
     */
    event CustodianListChanged(address indexed _address, bool _isAdded);

    /**
     * @dev Emitted whenever a redemption window is set.
     */
    event RedemptionWindowSet(
        uint256 from,
        uint256 to,
        uint256 redemptionPrice
    );

    /**
     * @dev List of possible item status.
     */
    enum ItemStatus {
        REDEEMABLE,
        MANUFACTURING,
        REDEEMED,
        IN_CUSTODY,
        DECOUPLED
    }

    /**
     * @dev Sets the address of the NfcIdRegistry
     * Requires:
     * - _addr is not zero
     *
     * This method can only be called by the contract owner.
     *
     */
    function setNfcIdRegistry(address _addr) external;

    /**
     * @dev Returns if the token with a given ID exists
     *
     * False on not minted and burned. True otherwise.
     * Return _exists(tokenID)
     *
     */
    function tokenExists(uint256 _tokenId) external view returns (bool);

    /**
     * @dev Returns the 'ItemStatus' of a particular '_tokenId'.
     */
    function stateOf(uint256 _tokenId) external view returns (ItemStatus);

    /**
     * @dev Checks whether a status transition is valid.
     *
     * Based on a list of valid state transition returns true.
     *
     * Returns false on invalid states and on fallthrough.
     */
    function transitionValid(
        ItemStatus _fromState,
        ItemStatus _toState
    ) external view returns (bool);

    /**
     * @dev Checks whether a status transition requires.
     *
     * Based on a list of valid state transition returns true.
     *
     * Returns false on invalid states and on fallthrough.
     */
    function transitionRequiresKyc(
        ItemStatus _fromState,
        ItemStatus _toState
    ) external view returns (bool);

    /**
     * @dev Checks whether a state tarnsition requires auth or not.
     *
     * Returns true for each transition that is a Physically Authenticated Action (PAA) and false otherwise.
     */
    function transitionRequiresAuth(ItemStatus _fromState, ItemStatus _toState)
        external
        pure
        returns (bool);

    /**
     * @dev Sets the state of a specific item identified by '_tokenId' to a new state.
     *
     * For state transitions that are PAAs, requires 'authSig' containing an uint 'expiration' timestamp
     * followed by the contract owner’s signature.
     */
    function setState(
        uint256 _tokenId,
        ItemStatus _state,
        bytes calldata _authSig,
        Fractal.Credential calldata _cred
    ) external;

    /**
     * @dev Returns the NFC ID for a given item '_tokenId'.
     *
     * Returns 0x0 on NFC ID not set.
     * Reverts on token not found.
     */
    function nfcId(uint256 _tokenId) external view returns (uint256);

    /**
     * @dev Returns the tokenId for a given '_nfcId'.
     *
     * Requires a valid NFC id
     */
    function nftFromNfc(uint256 _nfcId) external view returns (uint256);

    /**
     * @dev Checks whether the '_address' is whitelisted for transfers.
     *
     * Returns true if addr is an address whitelisted for transfers while the NFT is in STATE_REDEEMED.
     * The function should return true for address(this), so that claimNft can work correctly.
     * Returns false otherwise.
     */
    function isWhitelistedForTransfer(address _address)
        external
        view
        returns (bool);

    /**
     * @dev Adds '_address' to the transfer whitelist.
     *
     * Requires:
     * - User is not in the whitelist
     * - The caller is contract owner
     *
     * Emits {TransferWhitelistChanged} if a new address has been added.
     */
    function addWhitelistedAddress(address _address) external;

    /**
     * @dev Removes ab '_address' from the transfer whitelist.
     *
     * Requires:
     * - User is in the whitelist
     * - The caller is contract owner
     *
     * Emits {TransferWhitelistChanged} if a new address has been added.
     */
    function removeWhitelistedAddress(address _address) external;

    /**
     * @dev Checks whether the '_address' is in the list of custodians.
     *
     * Returns true if addr is on the authorized custodians list.
     * Returns false otherwise.
     *
     * This method can only be called by the contract owner.
     */
    function isCustodian(address addr) external view returns (bool);

    /**
     * @dev Adds '_address' as an authorized 'custodian'.
     *
     * Requires:
     * - User is not in the whitelist
     * - The caller is contract owner
     *
     * Emits {CustodianListChanged} if a new address has been added.
     *
     * This method can only be called by the contract owner.
     */
    function addCustodian(address _address) external;

    /**
     * @dev Removes '_address' from the authorized custodians list.
     *
     * Requires:
     * - User is already in the whitelist
     * - The caller is contract owner
     *
     * Emits a {CustodianListChanged} if a new address has been removed.
     *
     * This method can only be called by the contract owner.
     */
    function removeCustodian(address addr) external;

    /**
     * @dev Sets the time during which requesting the redemption of the physical items is allowed.
     *
     * The redemption window is the only time when Redeemable NFTs can be transitioned
     * into the Manufacturing state.
     *
     * Emits a {RedemptionWindowSet} event.
     */
    function setRedemptionWindow(
        uint256 from,
        uint256 to,
        uint256 redemptionPrice
    ) external;

    function getRedemptionWindow() external view returns (RedemptionWindow calldata);

    /**
     * @dev Mints '_quantity' items, sets their state to 'STATE_REDEEMED'.
     *
     * The items are minted to this contract.
     *
     * This method will be used to mint NFTs corresponding to off-chain e-commerce sales of the physical items.
     * The items will be claimable by the owner of the physical item through a claimNft PAA defined below.
     *
     * This method is only callable by the contract owner.
     */
    function mintAndHold(uint256 _quantity) external;

    /**
     * @dev Transfers an item that was minted by mintAndHold to msg.sender if the call is valid.
     */
    function claimNft(uint256 tokenId, bytes calldata authSig) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitterUpgradeable is Initializable, ContextUpgradeable {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20Upgradeable indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20Upgradeable => uint256) private _erc20TotalReleased;
    mapping(IERC20Upgradeable => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    function __PaymentSplitter_init(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        __PaymentSplitter_init_unchained(payees, shares_);
    }

    function __PaymentSplitter_init_unchained(address[] memory payees, uint256[] memory shares_) internal onlyInitializing {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20Upgradeable token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20Upgradeable token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(account, totalReceived, released(account));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20Upgradeable token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        AddressUpgradeable.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20Upgradeable token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 payment = releasable(token, account);

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20Upgradeable.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[43] private __gap;
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
library MerkleProofUpgradeable {
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";

library Fractal {
    struct Credential {
        bytes signature;
        uint validUntil;
        uint approvedAt;
        uint maxAge;
        string fractalId;
    }

    function hashCredentials(Credential memory _cred) internal view returns (bytes memory) {
        string memory sender = Strings.toHexString(
            uint256(uint160(tx.origin)),
            20
        );
        return abi.encodePacked(
            sender,
            ";",
            _cred.fractalId,
            ";",
            Strings.toString(_cred.approvedAt),
            ";",
            Strings.toString(_cred.validUntil),
            ";",
            "level:basic+liveness+uniq+wallet;citizenship_not:;residency_not:"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// AN1 Contracts (last updated v1.0.0) (tokens/IMintable.sol)

pragma solidity ^0.8.4;

import "erc721a-upgradeable/contracts/IERC721AUpgradeable.sol";

/**
 * @title AN1 IMintable interface, standard for AN1 collections
 *
 * Contains the basic methods and functionalities that will be used during the minting of
 * assets inside Another-1 collections.
 *
 * @dev See https://github.com/an1official/an1-contracts/
 */
interface IMintableUpgradeable is IERC721AUpgradeable {

    /**
     * @dev Emitted when `mintLimit` value is changed from `_previousLimit` to `_newLimit`.
     */
    event MintLimitChanged(uint256 _previousLimit, uint256 _newLimit);

    /**
     * @dev Returns the total amount of tokens that the contract can store and have minted.
     */
    function mintLimit() external view returns (uint256);

    /**
     * @dev Changes the mint limit of the collection.
     *
     * Requirements:
     *
     * - The `_newLimit` cannot be lower than the 'totalSupply'.
     *
     * Emits an {MintLimitChanged} event.
     */
    function setMintLimit(uint256 _newLimit) external;

    /**
     * @dev Allows Owner and Operators to mint new assets in the collection.
     *
     * Requirements:
     *
     * - The `msg.sender` is the owner or has the 'Minter' role.
     * - The value '_quantity' must be greater than 0.
     * - The value 'mintLimit' is greater or equal than 'totalSupply()' plus '_quantity'.
     * - The value '_to' must be different than a ZERO address.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function mintAndTransfer(address _to, uint256 _quantity) external;

    /**
     * @dev Allows Owner and Operators to batch mint new assets in the collection.
     *
     * Requirements:
     *
     * - The `msg.sender` has the 'Minter' role.
     * - The list '_quantities' must have the same lenght than the '_receivers'.
     * - The values of '_quantities' must be greater than 0.
     * - The value 'mintLimit' is greater or equal than 'totalSupply()' plus the sum of '_quantities' values.
     * - The addresses inside '_receivers' must be different than a ZERO address.
     *
     * Emits a {Transfer} event for every new asset minted.
     */
    function batchMintAndTransfer(address[] memory _receivers, uint256[] memory _quantities) external;
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721AUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safePermit(
        IERC20PermitUpgradeable token,
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
interface IERC20PermitUpgradeable {
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